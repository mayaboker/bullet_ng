# Hands-On Lab: Optimize a Neural Network Using Netron

## Goal

Inspect a neural network in **Netron**, identify an expensive operation, replace it with a more efficient implementation, and measure the change in compute, parameters, inference latency, and (optionally) RK3566 NPU performance.

**Tools:** Python, PyTorch, ONNX, Netron, ONNX Runtime; optional RKNN-Toolkit2 and Radxa Zero 3W (RK3566).

> **Important:** Netron visualizes the computational graph. It does not measure runtime, NPU scheduling, or per-layer latency. MAC reductions are theoretical until benchmarked. A depthwise-separable convolution is not generally mathematically equivalent to the standard convolution it replaces; for meaningful accuracy comparison, train or fine-tune both networks.

## Workflow

```text
Create baseline CNN
       ↓
Export ONNX → inspect in Netron
       ↓
Identify expensive layer (shapes / weights / MACs)
       ↓
Replace layer in PyTorch
       ↓
Export updated ONNX → inspect again
       ↓
Compare parameters and MACs
       ↓
Benchmark with ONNX Runtime
       ↓
(Optional) Convert to RKNN and profile on RK3566
       ↓
Train/evaluate accuracy before selecting a final design
```

## Lab 1 — Create and Export the Networks

Install dependencies:

```bash
pip install torch onnx onnxruntime netron
```

Create `network.py`:

```python
import torch
import torch.nn as nn


class SimpleCNN(nn.Module):
    def __init__(self, optimized=False):
        super().__init__()

        self.stem = nn.Sequential(
            nn.Conv2d(3, 32, kernel_size=3, stride=2, padding=1),
            nn.ReLU(),
        )

        if optimized:
            self.conv = nn.Sequential(
                nn.Conv2d(32, 32, kernel_size=3, padding=1,
                          groups=32, bias=False),
                nn.Conv2d(32, 64, kernel_size=1),
            )
        else:
            self.conv = nn.Conv2d(32, 64, kernel_size=3, padding=1)

        self.relu = nn.ReLU()
        self.pool = nn.AdaptiveAvgPool2d(1)
        self.fc = nn.Linear(64, 10)

    def forward(self, x):
        x = self.relu(self.conv(self.stem(x)))
        x = self.pool(x)
        x = torch.flatten(x, 1)
        return self.fc(x)


def export(model, filename):
    model.eval()
    example = torch.randn(1, 3, 224, 224)
    torch.onnx.export(
        model,
        (example,),
        filename,
        input_names=["input"],
        output_names=["output"],
        opset_version=17,
        dynamo=False,
    )


original = SimpleCNN(optimized=False)
optimized = SimpleCNN(optimized=True)

export(original, "original.onnx")
export(optimized, "optimized.onnx")

for label, model in [("Original", original), ("Optimized", optimized)]:
    count = sum(p.numel() for p in model.parameters())
    print(f"{label}: {count:,} parameters")
```

Run:

```bash
python network.py
```

### Baseline architecture

```text
Input                [1, 3, 224, 224]
  ↓ Conv 3×3 s=2, 3→32
                     [1, 32, 112, 112]
  ↓ Conv 3×3 s=1, 32→64  ← target
                     [1, 64, 112, 112]
  ↓ GlobalAvgPool
  ↓ Flatten
  ↓ Linear 64→10
Output               [1, 10]
```

## Lab 2 — Inspect Original ONNX in Netron

```bash
netron original.onnx
```

Select the **second Conv** operator and record:

| Attribute | Expected |
|---|---|
| Input shape | `[1, 32, 112, 112]` |
| Output shape | `[1, 64, 112, 112]` |
| Kernel | `3×3` |
| Stride | `1` |
| Groups | `1` |
| Weight shape | `[64, 32, 3, 3]` |

Calculate weights (excluding bias):

\[
P=C_{out}C_{in}K_hK_w=64\cdot32\cdot3\cdot3=18{,}432.
\]

Calculate multiply-accumulate operations (MACs):

\[
M=H_{out}W_{out}C_{out}(C_{in}/groups)K_hK_w.
\]

\[
M=112\cdot112\cdot64\cdot32\cdot9=231{,}211{,}008\ \mathrm{MACs}.
\]

**Questions:** Which operations change spatial dimensions? What determines the weight tensor shape? Which layer likely dominates MACs?

## Lab 3 — Optimize the Expensive Layer

Original:

```python
nn.Conv2d(32, 64, kernel_size=3, padding=1)
```

Replace with depthwise + pointwise convolutions:

```python
nn.Sequential(
    nn.Conv2d(32, 32, kernel_size=3, padding=1, groups=32, bias=False),
    nn.Conv2d(32, 64, kernel_size=1),
)
```

The depthwise layer performs spatial filtering independently on each channel. The pointwise layer mixes channels.

| Target operation | Original | Optimized total |
|---|---:|---:|
| Weight count (excluding biases) | 18,432 | 288 + 2,048 = **2,336** |
| MACs | 231,211,008 | 3,612,672 + 25,690,112 = **29,302,784** |
| Output tensor | `[1,64,112,112]` | `[1,64,112,112]` |
| Number of Conv ops | 1 | 2 |
| MAC reduction | — | **87.3%** |

The table is for the **modified target layer**, not the full model. Bias parameters are included in the Python model's total parameter count.

## Lab 4 — Reopen and Compare in Netron

```bash
netron optimized.onnx
```

Inspect both new operators:

| Attribute | Depthwise Conv | Pointwise Conv |
|---|---|---|
| Input | `[1,32,112,112]` | `[1,32,112,112]` |
| Output | `[1,32,112,112]` | `[1,64,112,112]` |
| Kernel | `3×3` | `1×1` |
| Groups | `32` | `1` |
| Weight shape | `[32,1,3,3]` | `[64,32,1,1]` |

**Record:** Operator counts, weight tensor shapes, total parameters, and whether the final model output shape stays the same.

## Lab 5 — Benchmark ONNX Runtime on CPU

Create `benchmark.py`:

```python
import time
import numpy as np
import onnxruntime as ort


def benchmark(path):
    options = ort.SessionOptions()
    options.intra_op_num_threads = 1

    session = ort.InferenceSession(
        path,
        sess_options=options,
        providers=["CPUExecutionProvider"],
    )
    x = np.random.randn(1, 3, 224, 224).astype(np.float32)

    for _ in range(20):
        session.run(None, {"input": x})

    times = []
    for _ in range(100):
        start = time.perf_counter()
        session.run(None, {"input": x})
        times.append((time.perf_counter() - start) * 1000)

    return np.median(times)


original_ms = benchmark("original.onnx")
optimized_ms = benchmark("optimized.onnx")

print(f"Original:  {original_ms:.3f} ms")
print(f"Optimized: {optimized_ms:.3f} ms")
print(f"Speedup:   {original_ms / optimized_ms:.2f}x")
```

Run:

```bash
python benchmark.py
```

**Analysis:** Does the observed CPU speedup match the theoretical MAC reduction? Why might memory access, implementation overhead, or CPU vectorization change the outcome?

## Lab 6 — Convert Both ONNX Models to RKNN (Optional)

Run with a compatible RKNN-Toolkit2 installation on the host:

```python
from rknn.api import RKNN

for name in ["original", "optimized"]:
    rknn = RKNN(verbose=True)
    rknn.config(target_platform="rk3566")
    rknn.load_onnx(model=f"{name}.onnx")
    rknn.build(do_quantization=False)
    rknn.export_rknn(f"{name}.rknn")
    rknn.release()
```

Start without quantization to isolate the architecture change. Next, benchmark both models **on an RK3566 device** and use the RKNN profiling facilities supported by your Toolkit2/runtime version. Actual per-operator timing and NPU scheduling are **not available from Netron or the PC simulator alone**.

| Metric | Original | Optimized |
|---|---|---|
| Parameter count | Fill in | Fill in |
| Model file size | Fill in | Fill in |
| Target-layer MACs | 231.2M | 29.3M |
| CPU latency, median | Measure | Measure |
| RK3566 latency | Measure | Measure |
| RK3566 operator latency | Profile | Profile |
| Accuracy on held-out validation set | Evaluate after training | Evaluate after training |

> The models created by this lab have randomly initialized weights. Their classification accuracy is not meaningful until trained. Training both versions with a matched dataset, schedule, and evaluation procedure is needed to assess any accuracy tradeoff.

## Additional Experiments

| Lab | Change | Learning objective |
|---|---|---|
| 1 | Standard Conv → Depthwise + Pointwise | MAC/parameter efficiency |
| 2 | 64 channels → 32 | Width vs. compute/accuracy |
| 3 | 5×5 Conv → two 3×3 Conv | Receptive field and compute |
| 4 | Stride 1 → stride 2 | Resolution and compute |
| 5 | Conv + BatchNorm + ReLU | Graph/operator fusion |
| 6 | FP / unquantized → INT8 RKNN | Quantization/calibration/accuracy |
| 7 | Modify MobileNetV2 bottleneck | Real-world NPU-aware optimization |

## Final Challenge — Optimize MobileNetV2

1. Export a pretrained MobileNetV2 to ONNX.
2. Open it in Netron and inspect the weight dimensions, grouped convolutions, tensor shapes, and residual branches.
3. Estimate per-layer MACs and identify the three most expensive layers.
4. Modify one bottleneck in the PyTorch source.
5. Export and compare the updated model in Netron.
6. Train/fine-tune if needed and measure validation accuracy.
7. Convert both to RKNN, benchmark on RK3566, and profile bottlenecks.
8. Decide whether the change is worth keeping based on **latency, memory, and accuracy**, not MACs alone.

**Core learning loop:** Inspect → Hypothesize → Modify → Export → Compare → Benchmark → Validate.
