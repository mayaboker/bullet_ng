# Lesson 4: Build Your First CNN in PyTorch

**Goal:** Build, train, and understand a CNN that recognizes handwritten digits from MNIST.

In the previous lessons, we learned:

- **Lesson 1:** How neural networks see images.
- **Lesson 2:** How convolutional filters learn patterns.
- **Lesson 3:** How images pass through convolution, ReLU, pooling, and classification layers.

Now we'll connect these concepts to actual Python code. We'll keep the mathematics simple and focus on understanding what each line does.

## 1. What are we building?

Our network will receive an image of a handwritten digit and predict which digit it represents.

```text
MNIST Image (28 × 28)
        ↓
Convolution (16 filters)
        ↓
       ReLU
        ↓
    MaxPooling
        ↓
Convolution (32 filters)
        ↓
       ReLU
        ↓
    MaxPooling
        ↓
      Flatten
        ↓
   Linear Layer
        ↓
 Prediction (0–9)
```

This is the same network from Lesson 3, containing **20,490 trainable parameters**.

## 2. Load the MNIST dataset

First, install the necessary libraries:

```bash
pip install torch torchvision matplotlib
```

Now let's load MNIST.

```python
import torch
from torchvision import datasets, transforms
from torch.utils.data import DataLoader

transform = transforms.ToTensor()

train_dataset = datasets.MNIST(
    root="./data",
    train=True,
    download=True,
    transform=transform
)

test_dataset = datasets.MNIST(
    root="./data",
    train=False,
    download=True,
    transform=transform
)
```

### What does this code do?

**`datasets.MNIST`** downloads the MNIST dataset, which contains 60,000 training images, 10,000 test images, and 10 classes (digits 0–9).

**`transforms.ToTensor()`** converts each image into a PyTorch tensor and scales pixel values from 0–255 to 0–1.

```text
Original pixel: 255 → Tensor value: 1.0
Original pixel: 128 → Tensor value: 0.502
Original pixel:   0 → Tensor value: 0.0
```

Each image has shape `[1, 28, 28]` (channels, height, width).

## 3. Visualize an MNIST image

```python
import matplotlib.pyplot as plt

image, label = train_dataset[0]

print("Image shape:", image.shape)
print("Correct label:", label)

plt.imshow(image.squeeze(), cmap="gray")
plt.title(f"Digit: {label}")
plt.axis("off")
plt.show()
```

Here, `squeeze()` removes the channel dimension for visualization: `[1, 28, 28] → [28, 28]`. The CNN itself still receives the channel dimension.

## 4. Create the CNN

```python
import torch.nn as nn

class SimpleCNN(nn.Module):

    def __init__(self):
        super().__init__()

        self.conv1 = nn.Conv2d(
            in_channels=1,
            out_channels=16,
            kernel_size=3,
            padding=1
        )

        self.conv2 = nn.Conv2d(
            in_channels=16,
            out_channels=32,
            kernel_size=3,
            padding=1
        )

        self.relu = nn.ReLU()
        self.pool = nn.MaxPool2d(2)
        self.flatten = nn.Flatten()
        self.fc = nn.Linear(32 * 7 * 7, 10)

    def forward(self, x):
        x = self.conv1(x)
        x = self.relu(x)
        x = self.pool(x)

        x = self.conv2(x)
        x = self.relu(x)
        x = self.pool(x)

        x = self.flatten(x)
        x = self.fc(x)
        return x
```

**`nn.Module`** is the base class for neural networks in PyTorch. **`__init__()`** defines layers and trainable parameters. **`forward()`** defines the sequence of operations applied to the input. We reuse ReLU and pooling objects because they have no trainable parameters.

## 5. Inspect what happens inside the CNN

```python
model = SimpleCNN()

x = torch.randn(1, 1, 28, 28)

print("Input:", x.shape)

x = model.conv1(x)
print("After Conv1:", x.shape)

x = model.relu(x)
print("After ReLU:", x.shape)

x = model.pool(x)
print("After Pool1:", x.shape)

x = model.conv2(x)
print("After Conv2:", x.shape)

x = model.relu(x)
x = model.pool(x)
print("After Pool2:", x.shape)

x = model.flatten(x)
print("After Flatten:", x.shape)

x = model.fc(x)
print("Output:", x.shape)
```

Expected output:

```text
Input:         [1, 1, 28, 28]
After Conv1:   [1, 16, 28, 28]
After ReLU:    [1, 16, 28, 28]
After Pool1:   [1, 16, 14, 14]
After Conv2:   [1, 32, 14, 14]
After Pool2:   [1, 32, 7, 7]
After Flatten: [1, 1568]
Output:        [1, 10]
```

The final output has **10 scores (logits)**, one for each digit.

## 6. Prepare the training data

Neural networks often process several images together in a **batch**.

```python
train_loader = DataLoader(
    train_dataset,
    batch_size=64,
    shuffle=True
)

test_loader = DataLoader(
    test_dataset,
    batch_size=64,
    shuffle=False
)
```

Each training batch contains images with shape `[64, 1, 28, 28]` and labels with shape `[64]` (except possibly the last batch). An **epoch** means processing the entire training dataset once. Training data is shuffled between epochs.

## 7. Define the loss function and optimizer

The loss function measures how poorly the network predicts the correct digit.

```python
criterion = nn.CrossEntropyLoss()
```

Suppose the true digit is 8, but the network assigns it only 10% probability and assigns digit 3 70%. The loss will be relatively high. If the network instead assigns digit 8 95% probability, the loss will be much lower.

The **optimizer** updates trainable weights using gradients calculated during backpropagation.

```python
optimizer = torch.optim.Adam(
    model.parameters(),
    lr=0.001
)
```

`model.parameters()` identifies the trainable parameters. `lr` is the learning rate, which influences update size.

## 8. Train the CNN

```python
device = torch.device(
    "cuda" if torch.cuda.is_available() else "cpu"
)

model = model.to(device)
epochs = 5

for epoch in range(epochs):
    model.train()
    total_loss = 0

    for images, labels in train_loader:
        images = images.to(device)
        labels = labels.to(device)

        # Step 1: Reset old gradients
        optimizer.zero_grad()

        # Step 2: Forward pass
        outputs = model(images)

        # Step 3: Calculate loss
        loss = criterion(outputs, labels)

        # Step 4: Backpropagation
        loss.backward()

        # Step 5: Update weights
        optimizer.step()

        total_loss += loss.item()

    avg_loss = total_loss / len(train_loader)
    print(f"Epoch {epoch + 1}: Loss = {avg_loss:.4f}")
```

### Understanding the five training steps

1. **`optimizer.zero_grad()`** clears previously accumulated gradients.
2. **`outputs = model(images)`** runs the forward pass. A full batch yields scores of shape `[64, 10]`.
3. **`loss = criterion(outputs, labels)`** measures prediction error.
4. **`loss.backward()`** calculates gradients for the trainable weights.
5. **`optimizer.step()`** updates those weights using the gradients.

An illustrative loss progression could look like:

```text
Epoch 1: Loss = 0.3500
Epoch 2: Loss = 0.1100
Epoch 3: Loss = 0.0750
Epoch 4: Loss = 0.0580
Epoch 5: Loss = 0.0460
```

Actual values will vary. A declining training loss indicates better performance on the training data, but we still need to evaluate the model on unseen images.

## 9. Test the CNN on unseen images

```python
model.eval()
correct = 0
total = 0

with torch.no_grad():
    for images, labels in test_loader:
        images = images.to(device)
        labels = labels.to(device)

        outputs = model(images)
        predictions = outputs.argmax(dim=1)

        correct += (predictions == labels).sum().item()
        total += labels.size(0)

accuracy = 100 * correct / total
print(f"Test Accuracy: {accuracy:.2f}%")
```

**`model.eval()`** switches the network into evaluation mode, important for models with layers like Dropout and BatchNorm. **`torch.no_grad()`** avoids tracking gradients, reducing memory and computational overhead. A small CNN like this can often reach approximately **98–99% MNIST test accuracy** after suitable training, though results vary.

## 10. Visualize what the CNN detects

Let's examine the **16 feature maps** produced by the first convolutional layer.

```python
model.eval()

image, label = test_dataset[0]
image = image.unsqueeze(0).to(device)

with torch.no_grad():
    features = model.relu(model.conv1(image))

features = features.cpu()
fig, axes = plt.subplots(4, 4, figsize=(8, 8))

for i, ax in enumerate(axes.flat):
    feature_map = features[0, i]
    ax.imshow(feature_map, cmap="gray")
    ax.set_title(f"Filter {i + 1}")
    ax.axis("off")

plt.tight_layout()
plt.show()
```

The output shape is `[1, 16, 28, 28]`. Each of the 16 filters has different weights, so its feature map can emphasize different learned image patterns, such as strokes, curves, boundaries, or less easily interpreted structures.

## 11. Visualize the learned filter weights

We can inspect the actual 3 × 3 kernels.

```python
weights = model.conv1.weight.detach().cpu()
print("Filter weight shape:", weights.shape)

fig, axes = plt.subplots(4, 4, figsize=(8, 8))

for i, ax in enumerate(axes.flat):
    kernel = weights[i, 0]
    ax.imshow(kernel, cmap="gray")
    ax.set_title(f"Kernel {i + 1}")
    ax.axis("off")

plt.tight_layout()
plt.show()
```

The weights have shape `[16, 1, 3, 3]`: 16 output filters, one input channel, and 3 × 3 kernel weights. Each filter also has one bias parameter. Run this visualization **before and after training** to compare the weights; the plotting colormap rescales values for visualization.

## 12. Save the trained model

```python
torch.save(
    model.state_dict(),
    "mnist_cnn.pth"
)
```

To load it later:

```python
model = SimpleCNN()
model.load_state_dict(
    torch.load(
        "mnist_cnn.pth",
        map_location="cpu",
        weights_only=True
    )
)
model.eval()
```

## 13. Three experiments to understand CNNs better

| Experiment | Change | What to observe |
|---|---|---|
| 1 | First convolution: 16 → 4 filters | Does accuracy decrease? |
| 2 | Kernel size: 3 × 3 → 5 × 5 | Do feature maps look different? |
| 3 | Remove the second convolution | Can a shallower network still classify digits accurately? |

For Experiment 2, set `padding=2` for the 5 × 5 convolution to preserve spatial dimensions. For Experiment 3, adjust the classifier's input size as needed.

These experiments help reveal why networks use multiple filters and layers: depth and width affect the complexity and variety of patterns a model can learn, but more is not always better.

## 14. What you've learned

```text
TRAINING
MNIST Dataset → CNN → Predictions → Loss → Backpropagation → Weight updates
                                                         ↖ repeat for epochs

INFERENCE
New image → Trained CNN → 10 logits → Predicted digit
```

**Training** changes the network's parameters. **Inference** uses the learned parameters to make predictions without updating them.

## Next: Lesson 5 — What Does a CNN Actually Learn?

We'll compare the same network **before and after training**, explore how individual filters respond to a digit, and see how a second convolutional layer combines simpler patterns into higher-level feature representations.
