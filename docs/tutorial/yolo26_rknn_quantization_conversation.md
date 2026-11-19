# YOLO26, RKNN, Quantization and Calibration — Conversation Archive

**Date:** November 19, 2026  
**Platform:** Radxa Zero 3W / Rockchip RK3566, with follow-up comparisons on PC, NVIDIA GPU, and TensorRT.

> This Markdown archive preserves the technical content of the conversation in chronological order, including questions, explanations, code and tables. Links and technical assertions reflect the discussion and should be verified against current toolkit documentation before deployment.

---

## 1. YOLO26 inference on Radxa Zero 3W

**User:** using radxa zero 3w with rk3566 how to implement yolo 26 inference. list highlight task like convert , quatization and other tuning to run the model as optimal on the npu in best performance

**Assistant:**

# YOLO26 on Radxa Zero 3W (RK3566) — NPU Optimization Guide

**Goal:** Run YOLO26 with maximum inference performance on the RK3566 NPU, minimizing CPU utilization, latency, and memory transfers.

The Ultralytics RKNN workflow supports exporting YOLO models to Rockchip NPU formats. Confirm specific YOLO26 export compatibility for your installed versions in the [Ultralytics RKNN guide](https://docs.ultralytics.com/integrations/rockchip-rknn).

### Recommended deployment architecture

```text
Development PC (x86 Linux)
        |
        v
YOLO26n PyTorch (.pt)
        |
        v
Export to RKNN
        |
        v
INT8 Quantization + Calibration
        |
        v
RKNN Graph Optimization
        |
        v
Optimized .rknn model
        |
        | Transfer to Radxa
        v
Radxa Zero 3W (RK3566)
        |
        v
Camera / Video (V4L2)
        |
        v
Preprocessing (RGA / CPU)
        |
        v
RK3566 NPU Inference
        |
        v
Postprocessing (CPU)
        |
        v
Detection Results
```

### Hardware considerations

| Component | RK3566 |
|---|---|
| NPU | 0.8 TOPS |
| NPU cores | 1 |
| CPU | Quad-core Cortex-A55 |
| Recommended model | YOLO26n |
| Recommended precision | INT8, subject to benchmarking |
| Inference runtime | RKNN Runtime C/C++ |
| Development toolkit | RKNN-Toolkit2 |
| Input resolution | Start with 320×320, compare 416 and 640 |
| Processing | Batch size 1 |

RK3566 is substantially less powerful than RK3588; optimize resolution, NPU execution and memory movement.

### Optimization task checklist

| # | Task | Priority | Expected benefit |
|---|---|---|---|
| 1 | Select YOLO26n | Critical | Lowest model complexity |
| 2 | Export PyTorch → RKNN | Critical | Enable NPU execution |
| 3 | Quantize FP16 → INT8 | Critical | Lower latency and memory potential |
| 4 | Calibrate using representative images | Critical | Preserve INT8 accuracy |
| 5 | Validate NPU operator placement | Critical | Avoid CPU fallback |
| 6 | Optimize YOLO26 postprocessing | Critical | Reduce CPU overhead |
| 7 | Benchmark input sizes (320/416/640) | High | Reduce latency |
| 8 | Use C/C++ RKNN Runtime | High | Lower runtime overhead |
| 9 | Use RGA for preprocessing | High | Reduce CPU usage |
| 10 | Optimize memory copies / DMA-BUF | High | Reduce end-to-end latency |
| 11 | Tune NPU and CPU frequency | High | Improve sustained performance |
| 12 | Optimize model graph and fusion | High | Improve NPU efficiency |
| 13 | Tune quantization and sensitive layers | Medium | Recover accuracy |
| 14 | Pipeline capture, inference, postprocessing | Medium | Improve throughput |
| 15 | Profile NPU, CPU, memory | Critical | Identify bottlenecks |

NPU latency and full processing latency are different. Resizing, decoding and memory transfers can dominate.

### Conversion on Ubuntu development PC

```bash
python3 -m venv rknn-env
source rknn-env/bin/activate
pip install ultralytics
pip install rknn-toolkit2==2.3.2
```

Use a supported Python version and dependency set. RKNN-Toolkit2 versions evolve; verify runtime/driver/exporter compatibility before upgrading.

FP16 baseline:

```python
from ultralytics import YOLO
model = YOLO("yolo26n.pt")
model.export(format="rknn", name="rk3566", imgsz=320, batch=1, quantize=16)
```

INT8 export:

```python
from ultralytics import YOLO
model = YOLO("yolo26n.pt")
model.export(
    format="rknn",
    name="rk3566",
    imgsz=320,
    batch=1,
    quantize=8,
    data="custom_dataset.yaml",
    fraction=1.0,
)
```

**Calibration data:** representative day/night images, small/large objects, different backgrounds, and scenes without objects. Start with several hundred for production and evaluate accuracy.

**YOLO26 INT8 export caveat discussed:** an export may separate backbone/neck/head convolutions into RKNN inference and floating-point decoding into `tail.onnx` on CPU, with NMS also on CPU. Benchmark the whole pipeline; C++ postprocessing may improve performance.

### Graph and quantization optimization

| Optimization | Recommendation |
|---|---|
| Operator fusion | Enable toolkit graph optimizations |
| INT8 quantization | Quantize weights/activations |
| Calibration | Use representative input data |
| Hybrid quantization | Keep sensitive layers at higher precision |
| Static shape | Fixed batch=1 and fixed image size |
| Layer-wise error analysis | Compare intermediate FP16/INT8 outputs |
| Unsupported operators | Replace or investigate CPU fallback |
| Model simplification | Benchmark before/after graph changes |
| Quantization-aware training | Consider if PTQ loses excessive accuracy |

**INT8 is not guaranteed to be faster end-to-end than FP16**, especially with extra CPU postprocessing.

### Pipeline optimization

- Prefer production C/C++ RKNN Runtime over full Python inference.
- Use Rockchip RGA for resizing, color conversion, and letterboxing where practical.
- Explore DMA-BUF and RKNN zero-copy buffers, subject to layout/alignment/synchronization compatibility.
- Reuse input/output buffers and avoid repeated conversions/copies.
- Decode boxes, filter confidence and apply NMS in efficient C++.
- Use bounded queues and overlap camera capture, preprocessing, inference and postprocessing.

```text
Thread 1: Camera capture
Thread 2: Preprocessing
Thread 3: NPU inference
Thread 4: Postprocessing
```

Overlapping stages improves throughput when possible; it may not decrease single-frame latency.

### Hardware tuning

| Task | Action |
|---|---|
| NPU frequency | Inspect NPU devfreq controls |
| CPU governor | Benchmark performance governor |
| NPU utilization | Monitor frequency/load |
| Thermal throttling | Monitor sustained temperatures |
| Memory bandwidth | Minimize copies and competing workloads |
| Background services | Minimize CPU contention |
| Runtime version | Match toolkit/runtime/kernel driver |
| Thread affinity | Experiment with CPU allocation |

```bash
cat /sys/kernel/debug/rknpu/version
find /sys/class/devfreq -maxdepth 2 -type f \
  \( -name available_frequencies -o -name cur_freq -o -name governor \)
```

RK3566 has **one NPU core**, unlike RK3588 multi-core tuning.

### Initial benchmark matrix

| Model | Precision | Input size |
|---|---|---|
| YOLO26n | FP16 | 320 |
| YOLO26n | INT8 | 320 |
| YOLO26n | FP16 | 416 |
| YOLO26n | INT8 | 416 |
| YOLO26n | FP16 | 640 |
| YOLO26n | INT8 | 640 |

Measure NPU latency, preprocessing, postprocessing, total latency, sustained FPS, CPU use, NPU frequency, RAM use, mAP50-95 and recall. Warm up the model and report median/p95 under stabilized thermal conditions.

### Recommended order

1. **Working baseline:** export FP16 YOLO26n at 320 and validate results.
2. **Quantization:** export calibrated INT8 and compare accuracy/total latency.
3. **Runtime:** C++ RKNN inference, C++ decode/NMS, RGA and less copying.
4. **Final tuning:** resolution comparison, toolkit/graph optimization, mixed precision, clocks, temperature and pipelining.

Recommended starting candidate: YOLO26n + INT8 + 320×320 + C++ RKNN Runtime + optimized CPU decoding, with FP16 retained as baseline.

References: [Ultralytics RKNN](https://docs.ultralytics.com/integrations/rockchip-rknn), [Rockchip RKNN-Toolkit2](https://github.com/airockchip/rknn-toolkit2).

---

## 2. Understanding quantization and calibration

**User:** explain more on quantization and calibration data . how to use them

**Assistant:**

# INT8 Quantization and Calibration for YOLO26 on RK3566

**Quantization** converts high-precision floating-point values into lower-precision representations. **Calibration** estimates numerical ranges so INT8 conversion retains as much accuracy as possible.

### What INT8 means

Example original activations:

```text
FP32 values: 0.125, 0.347, 1.256, 2.145, 4.789
INT8 codes:       3,     9,    32,    55,   122  (illustrative)
```

INT8 stores 256 possible values (signed range -128 to 127). A common mapping is:

\[
q = \operatorname{clip}\left(\operatorname{round}(x/s)+z,\ q_{\min},q_{\max}\right)
\]

- `x`: floating-point value
- `q`: integer code
- `s`: scale
- `z`: zero point
- `qmin`, `qmax`: allowed integer range

With scale 0.02 and zero point 0, `1.50 / 0.02 = 75`.

| Property | FP32 | FP16 | INT8 |
|---|---|---|---|
| Bits per value | 32 | 16 | 8 |
| Storage for 1M values | 4 MB | 2 MB | 1 MB |
| Precision | High | Medium | Lower |
| Calibration | No | No | Yes for static PTQ |
| NPU speed | Hardware-dependent | Good candidate | Often best candidate |

### Why calibration is necessary

A given layer can generate different numerical ranges in different scenes:

```text
Daylight:       min -2.1, max +3.5
Night:          min -4.3, max +5.2
Strong sun:     min -6.8, max +8.1
```

If calibration only covers [-2,+2], an activation of +8.1 gets clipped to +2 and information is lost.

```text
Calibration Images
       |
       v
  YOLO26 Model
       |
       v
Measure intermediate activation distributions
       |
       v
Determine scales and zero points
       |
       v
Quantized RKNN model
```

**Calibration is not training**; it estimates representable ranges, not new network weights. This is **post-training quantization (PTQ)**.

### Which images?

Use deployment-like images: bright daylight, low light, shadows, small and large objects, roads, vegetation, empty scenes, motion blur, varied camera angles.

Example deployment distribution: 70% daylight, 20% cloudy, 10% low light. A 500-image set could include 350 daylight, 100 cloudy, 50 low-light images, but intentionally cover rare critical conditions too.

| Calibration set size | Purpose |
|---|---|
| 10–20 | Conversion smoke test |
| 50–100 | Small experiment |
| 300–500 | Practical starting point |
| 500–1,000 | More environmental diversity |
| 2,000+ | Only if extra diversity adds value |

More data does not automatically improve quantization; diversity matters.

**Calibration images do not need labels.** The tool observes activations, not ground-truth boxes. Include images with zero, one or multiple targets.

### Calibration dataset layout

```text
project/
├── yolo26n.pt
├── calibration.yaml
└── dataset/
    └── calibration/
        ├── image_001.jpg
        ├── image_002.jpg
        └── ...
```

Illustrative dataset YAML:

```yaml
path: /home/user/project/dataset
train: calibration
val: calibration
names:
  0: person
  1: bicycle
  2: car
```

Class names must match the actual trained model. For COCO YOLO, use the correct 80 classes. Labels are unnecessary for numerical calibration but needed for conventional model validation.

Export:

```python
from ultralytics import YOLO
model = YOLO("yolo26n.pt")
model.export(
    format="rknn",
    name="rk3566",
    imgsz=320,
    batch=1,
    quantize=8,
    data="calibration.yaml",
    fraction=1.0,
)
```

During export: load model → preprocess calibration images → measure layer ranges → compute scales/zero points → quantize supported ops → build `.rknn` for RK3566.

To select a count of images (subject to exporter version):

```python
model.export(
    format="rknn", name="rk3566", imgsz=320,
    quantize=8, data="calibration.yaml", fraction=500,
)
```

To choose training split explicitly:

```python
model.export(
    format="rknn", name="rk3566", imgsz=320,
    quantize=8, data="calibration.yaml", split="train", fraction=500,
)
```

### What if calibration data is unrepresentative?

A daytime-calibrated model might see [-3,+4] while nighttime activations reach [-8,+9]. Clipping can cause lost confidence, missed small objects, false detections, and lower mAP/recall. Prefer images from the deployment camera.

### Dataset purposes

| Dataset | Purpose | Labels? |
|---|---|---|
| Training | Learn weights | Yes |
| Calibration | Estimate INT8 ranges | No |
| Validation/test | Measure detection quality | Yes |

Keep final test images separate from calibration.

### Compare FP16 and INT8

```python
from ultralytics import YOLO

fp16_model = YOLO("./yolo26_fp16_rknn_model")
int8_model = YOLO("./yolo26_int8_rknn_model")

fp16_results = fp16_model.val(data="validation.yaml", imgsz=320)
int8_results = int8_model.val(data="validation.yaml", imgsz=320)

print("FP16 mAP50-95:", fp16_results.box.map)
print("INT8 mAP50-95:", int8_results.box.map)
```

Model paths are illustrative. Evaluation must use valid exported model folders on a supported system.

Illustrative (not measured) numbers:

| Metric | FP16 | INT8 |
|---|---:|---:|
| mAP50 | 0.82 | 0.81 |
| mAP50-95 | 0.61 | 0.59 |
| Recall | 0.85 | 0.82 |
| Model size | 7 MB | 4 MB |

Track recall especially where missing a target is costly.

### Recovering INT8 accuracy

| Method | Purpose |
|---|---|
| Better calibration diversity | Representative activation ranges |
| More samples | Compare 300/500/1000 |
| Preprocessing match | Match camera resolution/color/pixel distribution |
| Analyze clipping/errors | Find sensitive layers |
| Mixed precision | Keep sensitive layers FP16 |
| Adjust calibration algorithm | Try available estimators |
| QAT | Train with simulated quantization if PTQ is inadequate |

Example mixed precision:

```text
Conv1 -> INT8
Conv2 -> INT8
Conv3 -> FP16 (sensitive)
Detection Output
```

Automatic hybrid precision may be supported depending on RKNN chipset/toolkit/exporter version.

### Suggested experiment

Build four versions, all 320×320:

| Version | Precision | Calibration images |
|---|---|---:|
| A | FP16 | None |
| B | INT8 | 100 |
| C | INT8 | 500 |
| D | INT8 | 1000 |

Record accuracy (mAP, recall), NPU-only latency and total latency. Calibration does not teach new object categories.

---

## 3. Is a small calibration dataset enough for learning?

**User:** for learning and tutorial with small dataset is enough with calibration set is good for above lesson

**Assistant:** Yes. A small calibration dataset is sufficient for a tutorial; 500–1,000 images are not required just to learn the workflow.

| Calibration images | Purpose |
|---|---|
| 5–10 | Conversion smoke test |
| 20–50 | Good learning experiment |
| 100 | Basic quantization accuracy comparison |
| 300–500 | More realistic deployment calibration |

Recommended tutorial: YOLO26n pretrained on COCO, 320×320 input, 30–50 calibration images, 20–30 separate labeled validation images, INT8, RKNN Runtime.

What you learn: export PT→RKNN, static INT8 PTQ, scales/zero points, RK3566 inference, FP16 vs INT8 latency, influence of calibration size.

```python
from ultralytics import YOLO
model = YOLO("yolo26n.pt")
model.export(
    format="rknn", name="rk3566", imgsz=320,
    quantize=8, data="calibration.yaml", fraction=30,
)
```

A small-calibration warning may appear; accuracy can be poor. Start with 30 images and then try 100.

---

## 4. How to download a tutorial dataset

**User:** how to download the dataset

**Assistant:** Use **COCO128**, an Ultralytics tutorial dataset with 128 images and 80 COCO classes, approximately 7 MB, including object detection annotations.

```bash
mkdir -p ~/yolo26_tutorial
cd ~/yolo26_tutorial
wget https://github.com/ultralytics/assets/releases/download/v0.0.0/coco128.zip
unzip coco128.zip
```

```text
yolo26_tutorial/
├── coco128/
│   ├── images/
│   │   └── train2017/
│   └── labels/
│       └── train2017/
└── coco128.zip
```

Ultralytics has a `coco128.yaml` config and may download the dataset itself when needed.

```python
from ultralytics import YOLO
model = YOLO("yolo26n.pt")
model.export(
    format="rknn", name="rk3566", imgsz=320,
    quantize=8, data="coco128.yaml", fraction=30,
)
```

Repeat with 10, 30, and 100 calibration images; save each export separately. Compare accuracy, latency and quantization effects, using an **independent test set**. More calibration images typically do not change inference runtime for the same architecture/quantization strategy.

Reference: [Ultralytics COCO128](https://docs.ultralytics.com/datasets/detect/coco128).

---

## 5. Do I need calibration when quantizing INT8 on the PC?

**User:** when i quantization to int 8 on pc i need the same calibration process

**Assistant:** **Yes for static INT8 PTQ.** Quantization and calibration happen on the development PC using RKNN-Toolkit2; deployment and inference happen on the Radxa. You do not recalibrate on the Radxa.

```text
Ubuntu PC
  YOLO26n (.pt)
       |
       v
RKNN-Toolkit2  <--- Calibration images
       |
       v
Calculate INT8 scales and zero points
       |
       v
YOLO26n (.rknn)
       |
    copy
       v
Radxa RK3566 NPU inference
```

```python
from ultralytics import YOLO
model = YOLO("yolo26n.pt")
model.export(
    format="rknn", name="rk3566", imgsz=320,
    quantize=8, data="coco128.yaml", fraction=30,
)
```

| Quantization method | Calibration required? |
|---|---|
| FP32→FP16 | No |
| FP32→INT8 static PTQ | Yes |
| INT8 quantization-aware training (QAT) | Not necessarily separate PTQ calibration |
| Dynamic INT8 | Typically no representative calibration set |

The `.rknn` stores scales/zero points. If targeting **TensorRT INT8 on PC**, use that runtime's quantization workflow; calibration images may be reused, but caches and quantized model files are not interchangeable across runtimes.

---

## 6. Can I quantize below INT8 on RK3566?

**User:** can i quantize less that int 8

**Assistant:** Theoretically yes: INT4, INT2, even INT1 are possible numerical representations. Hardware support determines whether inference accelerates.

| Precision | Bits | Theoretical storage vs FP32 | RK3566 practical path |
|---|---:|---:|---|
| FP32 | 32 | 100% | Not preferred NPU format |
| FP16 | 16 | 50% | Supported |
| INT8 | 8 | 25% | Supported |
| INT4 | 4 | 12.5% | Not a standard supported RK3566 NPU path |
| INT2 | 2 | 6.25% | No standard RKNN acceleration path |
| INT1 | 1 | 3.125% | No standard RKNN acceleration path |

These ratios exclude metadata, mixed-precision layers and other overhead.

Discussed RKNN schemes: W8A8 (8-bit weights/activations) is practical on RK3566; newer chips may offer particular W4A16 variants. Packing weights to INT4 in software does not imply native RK3566 INT4 execution—unpacking/CPU processing can eliminate any benefit.

Recommendation: optimize W8A8, calibration, resolution and postprocessing first. Use mixed precision if needed to preserve quality.

---

## 7. Can I compare FP16, INT8, and INT2 on the PC?

**User:** on pc cam i compare fp16 int8 or int2

**Assistant:** Yes for *accuracy*, with the important distinction that **INT2 generally requires simulation or custom kernels**, whereas FP16 and INT8 may be natively accelerated depending on hardware/runtime.

| Precision | Accuracy comparison | Speed comparison | Calibration |
|---|---|---|---|
| FP32 | Yes | Yes | No |
| FP16 | Yes | GPU dependent | No |
| INT8 | Yes | Supported hardware | Static PTQ: yes |
| INT4 | Yes | Backend dependent | Often for PTQ |
| INT2 | Simulate/custom | Limited native execution | Often for PTQ |

### Simplified PyTorch fake quantization example

```python
import torch

def fake_quantize(tensor, bits=8):
    qmin = -(2 ** (bits - 1))
    qmax = (2 ** (bits - 1)) - 1

    max_abs = tensor.abs().max().clamp(min=1e-8)
    scale = max_abs / max(abs(qmin), abs(qmax))

    quantized = torch.round(tensor / scale)
    quantized = torch.clamp(quantized, qmin, qmax)
    return quantized * scale

x = torch.tensor([-1.0, -0.5, 0.0, 0.5, 1.0])
print("FP32:", x)
print("INT8:", fake_quantize(x, bits=8))
print("INT4:", fake_quantize(x, bits=4))
print("INT2:", fake_quantize(x, bits=2))
```

This is a numerical demonstration, **not a complete calibrated RKNN model quantizer**. It returns floating-point tensor values and is not a native INT2 performance benchmark.

### Comparison variants

| Model | Weights | Activations |
|---|---|---|
| FP16 | FP16 | FP16 |
| W8A8 | INT8 | INT8 |
| W4A8 | INT4 | INT8 |
| W2A8 | INT2 | INT8 |
| W2A2 | INT2 | INT2 |

W2A8 may preserve more accuracy than W2A2. Benchmark mAP50, mAP50-95, recall, model storage and native GPU latency where implementations exist. For fake-quantized models, timing reflects simulated execution, not native INT2 speed.

For the RTX GPU, FP16 and INT8 are standard candidates; INT2 needs specialist kernels. Compare accuracy on PC, then deploy standard W8A8 RKNN to the Radxa.

---

## 8. Is INT4 relevant to TensorRT?

**User:** int4 is relevant to tensortrt

**Assistant:** Yes, but the common TensorRT INT4 route is **weight-only quantization (WoQ)**, especially for GEMM/linear layers, not general W4A4 YOLO convolution inference.

| Precision | Weights | Activations | Computation | Typical use |
|---|---|---|---|---|
| FP16 | FP16 | FP16 | FP16 | YOLO, CNNs, LLMs |
| INT8 | INT8 | INT8 | INT8 arithmetic | YOLO, CNNs, LLMs |
| INT4 | INT4 | FP16/BF16 | Higher precision after dequantization | LLM, GEMM |
| FP4 | FP4 | FP4 | Architecture-dependent | New GPUs |

```text
FP16 activations
      |
INT4 compressed weights
      |
Dequantize weights
      |
FP16/BF16 GEMM
      |
Output
```

INT4 saves weight storage and bandwidth but is not guaranteed to accelerate compute, particularly for YOLO convolution layers. FP4 is a separate floating-point representation, not identical to INT4.

### Suggested deployment choice

| Application | Suggested starting precision |
|---|---|
| YOLO26 on RTX | FP16 or INT8 |
| YOLO26 on RK3566 | INT8 |
| LLM on RTX | INT4 WoQ or FP16 |
| LLM on Jetson Orin | INT4 WoQ or INT8 where backend supports |

For RTX 5080: benchmark FP16, INT8 and FP8 first; investigate FP4 as a separate precision-specific experiment with supported TensorRT/hardware combinations.

Reference: [TensorRT quantization schemes](https://docs.nvidia.com/deeplearning/tensorrt/latest/inference-library/quantized-types-schemes.html).

---

## 9. Save request

**User:** save all the conversation as md file

This document is the Markdown archive of the above conversation.

---

## Quick reference

| Goal | First choice |
|---|---|
| RK3566 acceleration | YOLO26n → RKNN, INT8 W8A8 |
| First learning calibration set | 30 COCO128 images |
| More useful calibration comparison | 30 vs 100 images |
| Practical deployment calibration | Representative hundreds of images |
| Validate conversion | Compare FP16 vs INT8 on separate labeled images |
| PC precision study | FP16 vs INT8 vs fake-quantized INT4/INT2 |
| TensorRT INT4 | Primarily weight-only GEMM/linear uses |
| Performance measurement | NPU-only and end-to-end latency separately |
