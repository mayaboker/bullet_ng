# Lesson 7 — From MNIST to CIFAR-10

**Course:** Visual Neural Networks — From Basics to Modern Computer Vision  
**Stage 2:** Modern CNNs  
**Level:** Beginner → Intermediate  
**Dataset:** CIFAR-10  
**Mathematics:** Minimal  
**Prerequisites:** Lessons 1–6

## Learning objectives

In Lessons 1–6, we built a CNN that recognizes handwritten digits using MNIST. Now we move from grayscale digits to objects in color photographs. By the end, you should understand why CIFAR-10 is harder, how RGB channels and multi-channel convolution work, how deeper layers combine features, and how to build and inspect a CIFAR-10 CNN in PyTorch.

---

## Part 1 — Why move beyond MNIST?

MNIST is a comparatively simple task: images are grayscale, digits are typically centered on a uniform background, and there are only ten classes. A small CNN often achieves around 98–99% accuracy.

A cat, by contrast, can appear at different scales, poses, orientations, and lighting conditions, against many different backgrounds. Recognizing objects requires more robust visual representations.

## Part 2 — Introducing CIFAR-10

CIFAR-10 contains **60,000 RGB images**, each **32 × 32 pixels**, with **50,000 training** and **10,000 test** images. There are ten classes (6,000 images per class across the entire dataset).

| Class ID | Object |
|---|---|
| 0 | Airplane |
| 1 | Automobile |
| 2 | Bird |
| 3 | Cat |
| 4 | Deer |
| 5 | Dog |
| 6 | Frog |
| 7 | Horse |
| 8 | Ship |
| 9 | Truck |

### MNIST vs. CIFAR-10

| Property | MNIST | CIFAR-10 |
|---|---|---|
| Image size | 28 × 28 | 32 × 32 |
| Channels | 1 | 3 |
| Image type | Grayscale | RGB color |
| Classes | 10 digits | 10 object categories |
| Background | Usually simple | Often complex |
| Object variations | Relatively limited | Much greater |
| Main challenge | Recognizing shapes | Recognizing objects despite variation |

Although the resolutions are similar, CIFAR-10 is harder because of variability in shape, color, lighting, scale, pose, and background.

## Part 3 — How does a network see color?

An MNIST image has PyTorch shape `[1, 28, 28]`: one grayscale channel. CIFAR-10 images have shape `[3, 32, 32]`: three channels for red, green, and blue.

Examples of RGB values before normalization:

| Color | Red | Green | Blue |
|---|---:|---:|---:|
| Red | 255 | 0 | 0 |
| Blue | 0 | 0 | 255 |
| Yellow | 255 | 255 | 0 |

Think of an RGB image as three 32 × 32 matrices stacked together:

```text
             RGB IMAGE
                 │
       ┌─────────┼─────────┐
       ▼         ▼         ▼
       RED      GREEN     BLUE
      32×32     32×32     32×32
       └─────────┼─────────┘
                 ▼
             [3,32,32]
```

## Part 4 — Convolution with RGB images

Our first MNIST layer was:

```python
nn.Conv2d(in_channels=1, out_channels=16, kernel_size=3, padding=1)
```

For CIFAR-10, it becomes:

```python
nn.Conv2d(in_channels=3, out_channels=16, kernel_size=3, padding=1)
```

Each standard filter now has shape `[3, 3, 3]`: one 3 × 3 weight matrix **for each of the three input channels**. That is 27 weights plus one bias per output filter.

```text
      Red 3×3 weights ───┐
    Green 3×3 weights ───┼──► SUM + bias ──► one feature map
     Blue 3×3 weights ───┘
```

One RGB filter produces **one output feature map**, not three. Sixteen filters produce output shape `[16, 32, 32]` when stride is 1 and padding is 1.

## Part 5 — What new patterns can RGB filters learn?

Filters can respond to shapes and color relationships, such as edges, brightness changes, red–green contrast, blue–yellow contrast, or texture. These are possible learned responses, not roles that we assign beforehand.

Color helps distinguish some scenes (for example, blue sky and green grass), but color alone cannot reliably distinguish objects such as dogs and horses. The network must also learn structure and spatial relationships.

## Part 6 — Why deeper networks?

A digit might be classified from strokes and loops. Complex objects often require combining local features into larger arrangements.

```text
Edges and colors
       ↓
Textures and corners
       ↓
Small object parts
       ↓
Larger combinations
       ↓
Object class
```

This hierarchy is conceptual: actual learned features may not have simple human-readable interpretations.

## Part 7 — Receptive fields

A neuron's **receptive field** is the region of input pixels that could affect its activation.

With consecutive 3 × 3 convolutions, stride 1, and no dilation:

| Number of convolutions | Theoretical receptive field |
|---:|---|
| 1 | 3 × 3 |
| 2 | 5 × 5 |
| 3 | 7 × 7 |

Pooling or strided convolutions can enlarge the receptive field faster. Larger receptive fields help detect parts and relationships spread over a wider image area. A theoretical receptive field does not guarantee equal use of every input pixel.

## Part 8 — Adapt the MNIST CNN

For MNIST, we used two convolutional layers, pooling, flattening, and a classifier. For CIFAR-10, we'll start with a slightly larger learning-oriented model:

```text
CIFAR-10 image [3, 32, 32]
         │
    Conv 3→32, ReLU, Pool
         ▼
     [32, 16, 16]
         │
    Conv 32→64, ReLU, Pool
         ▼
      [64, 8, 8]
         │
    Conv 64→128, ReLU, Pool
         ▼
      [128, 4, 4]
         │
       Flatten
         ▼
        [2048]
         │
     Linear 2048→10
         ▼
     Ten class logits
```

We now have three input channels, more filters, and an additional convolutional layer. This is a teaching baseline, not an optimized design.

## Part 9 — Load and visualize CIFAR-10 in PyTorch

```python
import torch
import matplotlib.pyplot as plt
from torchvision import datasets, transforms
from torch.utils.data import DataLoader

transform = transforms.ToTensor()

train_dataset = datasets.CIFAR10(
    root="./data", train=True, download=True, transform=transform
)
test_dataset = datasets.CIFAR10(
    root="./data", train=False, download=True, transform=transform
)

train_loader = DataLoader(train_dataset, batch_size=64, shuffle=True)

image, label = train_dataset[0]
print(image.shape)  # torch.Size([3, 32, 32])
```

### Display ten images

```python
classes = train_dataset.classes
fig, axes = plt.subplots(2, 5, figsize=(12, 5))

for i, ax in enumerate(axes.flat):
    image, label = train_dataset[i]
    # PyTorch uses [C, H, W]; matplotlib uses [H, W, C].
    image = image.permute(1, 2, 0)
    ax.imshow(image)
    ax.set_title(classes[label])
    ax.axis("off")

plt.tight_layout()
plt.show()
```

`permute(1, 2, 0)` changes `[3, 32, 32]` into `[32, 32, 3]` without changing pixel values.

## Part 10 — Implement the CIFAR-10 CNN

```python
import torch.nn as nn

class CIFAR10CNN(nn.Module):
    def __init__(self):
        super().__init__()

        self.features = nn.Sequential(
            nn.Conv2d(3, 32, 3, padding=1),
            nn.ReLU(),
            nn.MaxPool2d(2),

            nn.Conv2d(32, 64, 3, padding=1),
            nn.ReLU(),
            nn.MaxPool2d(2),

            nn.Conv2d(64, 128, 3, padding=1),
            nn.ReLU(),
            nn.MaxPool2d(2),
        )
        self.classifier = nn.Sequential(
            nn.Flatten(),
            nn.Linear(128 * 4 * 4, 10),
        )

    def forward(self, x):
        x = self.features(x)
        return self.classifier(x)
```

Each convolution learns features; ReLU adds nonlinearity; each 2 × 2 max-pool halves spatial dimensions; the linear layer produces ten classification scores.

### Inspect tensor shapes

```python
model = CIFAR10CNN()
x = torch.randn(1, 3, 32, 32)
print("Input:", x.shape)

for layer in model.features:
    x = layer(x)
    print(layer.__class__.__name__, x.shape)

x = model.classifier(x)
print("Output:", x.shape)
```

Expected output:

```text
Input:      [1, 3, 32, 32]
Conv2d     [1, 32, 32, 32]
ReLU       [1, 32, 32, 32]
MaxPool2d  [1, 32, 16, 16]
Conv2d     [1, 64, 16, 16]
ReLU       [1, 64, 16, 16]
MaxPool2d  [1, 64, 8, 8]
Conv2d     [1, 128, 8, 8]
ReLU       [1, 128, 8, 8]
MaxPool2d  [1, 128, 4, 4]
Output:    [1, 10]
```

Notice how spatial dimensions decrease while the number of channels increases, a common CNN design pattern.

## Part 11 — Train the network

The process is the same as for MNIST: forward pass → loss → backpropagation → optimizer update.

```python
device = "cuda" if torch.cuda.is_available() else "cpu"
model = CIFAR10CNN().to(device)
criterion = nn.CrossEntropyLoss()
optimizer = torch.optim.Adam(model.parameters(), lr=0.001)

for epoch in range(10):
    model.train()
    total_loss = 0
    correct = 0
    total = 0

    for images, labels in train_loader:
        images = images.to(device)
        labels = labels.to(device)

        optimizer.zero_grad()
        outputs = model(images)
        loss = criterion(outputs, labels)
        loss.backward()
        optimizer.step()

        batch_size = labels.size(0)
        total_loss += loss.item() * batch_size
        predictions = outputs.argmax(dim=1)
        correct += (predictions == labels).sum().item()
        total += batch_size

    avg_loss = total_loss / total
    accuracy = 100 * correct / total
    print(f"Epoch {epoch + 1}: Loss={avg_loss:.4f}, Train Acc={accuracy:.2f}%")
```

A simple three-convolution CNN might reach roughly 65–75% **test** accuracy with suitable training, but that is only a rough expectation—not a measurement for the exact code above. Evaluate the test set separately; training accuracy is not the same as test accuracy.

## Part 12 — Visualize the first RGB filters

The first convolution's weight tensor has shape `[32, 3, 3, 3]`: 32 filters, each with three 3 × 3 channel-specific weight matrices.

```python
weights = model.features[0].weight.detach().cpu()
print(weights.shape)

fig, axes = plt.subplots(4, 8, figsize=(12, 6))
for i, ax in enumerate(axes.flat):
    kernel = weights[i].permute(1, 2, 0)  # [H, W, RGB]
    # Scale for visualization, not for model inference.
    kernel = kernel - kernel.min()
    kernel = kernel / (kernel.max() + 1e-8)
    ax.imshow(kernel)
    ax.axis("off")

plt.tight_layout()
plt.show()
```

Some may resemble color-contrast detectors or edge filters; others may be hard to interpret. A 3 × 3 first-layer filter sees only a local patch, not a whole object.

## Part 13 — Limitations of the baseline

| Limitation | Why it matters |
|---|---|
| Only three convolutional layers | Limited depth for complex feature extraction |
| No Batch Normalization | Training may be less stable or slower |
| No residual connections | Very deep versions may be harder to optimize |
| No data augmentation | Generalization may suffer |
| Flatten + Linear classifier | Comparatively large classifier |

These motivate Lessons 8 and 9: deeper CNNs, BatchNorm, global average pooling, and ResNet.

## Part 14 — Practical exercises

| Exercise | Experiment | What you'll learn |
|---|---|---|
| 1 | Visualize ten CIFAR-10 images | Image complexity |
| 2 | Display RGB channels separately | Color representation |
| 3 | Visualize first-layer filters | What RGB filters can learn |
| 4 | Increase number of filters | Network width |
| 5 | Remove the third convolution | Network depth |
| 6 | Monitor training in TensorBoard | Convergence and overfitting |

**Recommended comparison:** Train a small two-convolution network (`3→16→32`) and a three-convolution network (`3→32→64→128`) for the same number of epochs. Adjust classifier dimensions accordingly and compare **validation** accuracy. The goal is understanding capacity, not simply maximizing accuracy.

## Lesson 7 summary

1. RGB images have three channels, unlike MNIST grayscale images.
2. A standard convolutional filter spans **all** input channels and produces one output feature map.
3. CIFAR-10 classification is harder due to greater object and background variation.
4. Deeper CNNs can combine local features into larger patterns.
5. Training still uses forward propagation, loss, backpropagation, and optimizer updates.

### Check your understanding

**Q1:** How many scalar values does a `[3, 32, 32]` image contain?  
**A:** 3 × 32 × 32 = **3,072**.

**Q2:** With three input channels and 32 output filters, how many output feature maps?  
**A:** **32**.

**Q3:** Why can't a first-layer 3 × 3 filter recognize an entire cat?  
**A:** It examines only a small local region; larger structures require combining features across positions and layers.

## Next — Lesson 8: Building Deeper CNNs

| Topic | What we'll learn |
|---|---|
| Network depth | Why more layers may help |
| Network width | Why increasing channel counts matters |
| Batch Normalization | How to stabilize training |
| Receptive fields | How deeper networks capture larger patterns |
| Global Average Pooling | How to replace large classifiers |
| CNN design | How to build a more effective architecture |

Lesson 8 will prepare us for **Lesson 9: ResNet and Residual Connections**.
