# Lesson 5: What Does a CNN Actually Learn?

**Course:** Visual Neural Networks — From Basics to Modern Computer Vision  
**Stage:** 1 — CNN Fundamentals  
**Level:** Beginner  
**Dataset:** MNIST  
**Mathematics:** Minimal  
**Prerequisites:** Lessons 1–4

## Learning Objectives

In Lesson 4, we built and trained a CNN to recognize handwritten digits. Now we explore what happens **inside** the network as it learns.

By the end of this lesson, you should understand:

1. What changes inside a CNN during training.
2. How convolutional filters respond to different visual patterns.
3. What feature maps represent.
4. How a second convolutional layer combines features from the first.
5. How to visualize learned filters and feature maps.

---

## Part 1 — What Changes During Training?

### 1. A CNN starts with random weights

Recall the CNN from Lesson 4:

```text
Input Image (28 × 28)
        │
        ▼
   Convolution 1 (16 filters)
        │
       ReLU
        │
     MaxPooling
        │
   Convolution 2 (32 filters)
        │
       ReLU
        │
     MaxPooling
        │
     Classifier
        │
   Prediction (0–9)
```

When we create the model:

```python
model = SimpleCNN()
```

PyTorch initializes its filters and classifier weights. Initially, the network has not learned how to recognize digits. A 3 × 3 filter might look like this:

```text
BEFORE TRAINING
 0.12  -0.24   0.08
-0.18   0.31  -0.11
 0.05  -0.09   0.21
```

After training, a filter might look like this:

```text
AFTER TRAINING (illustrative)
-0.82   1.24  -0.75
-0.91   1.53  -0.88
-0.71   1.18  -0.67
```

This example filter tends to respond strongly to a bright vertical stroke surrounded by darker pixels. The numbers are illustrative, not measured values from a trained model.

During training, the network repeatedly performs:

```text
MNIST Image → Prediction → Loss → Backpropagation → Weight Update
```

**Key concept:** The network learns by changing numerical weights, not by storing explicit instructions for recognizing digits.

---

## Part 2 — Understanding Feature Maps

### 2. A filter detects where a pattern appears

Consider a simplified image containing a vertical line:

```text
0 0 1 0 0
0 0 1 0 0
0 0 1 0 0
0 0 1 0 0
0 0 1 0 0
```

And a filter:

```text
-1  2 -1
-1  2 -1
-1  2 -1
```

At a position centered on the vertical line, the filter response is `2 + 2 + 2 = 6`. At other positions, its response changes. The collection of responses over the image is called a **feature map**.

A feature map answers this question:

> How strongly does this filter respond at each location?

Conceptually:

```text
INPUT IMAGE              FEATURE MAP (schematic)
0 0 1 0 0                0 0 6 0 0
0 0 1 0 0                0 0 6 0 0
0 0 1 0 0       →        0 0 6 0 0
0 0 1 0 0                0 0 6 0 0
0 0 1 0 0                0 0 6 0 0
```

**Note:** This is a conceptual illustration, not the exact result of convolution; numerical values depend on padding, bias, and neighboring pixels.

---

## Part 3 — Why Do We Need Multiple Filters?

### 3. One filter cannot recognize everything

A handwritten 8 may contain curves, vertical and horizontal edges, and two connected loops. The first convolutional layer has **16 independent filters**, each with its own weights, so it can produce 16 representations of the same image.

```text
                    MNIST Image
                         │
           ┌─────────────┼─────────────┐
           ▼             ▼             ▼
        Filter 1      Filter 2      Filter 3 ...
           │             │             │
       Feature Map   Feature Map   Feature Map
```

Possible responses include vertical strokes, horizontal strokes, curved edges, diagonal edges, and stroke intersections. **These roles are not assigned manually.** Some learned filters respond to multiple patterns, and some are difficult to interpret.

The first convolution outputs a tensor of shape:

```text
[16, 28, 28]
```

These are **not** 16 identical copies of the input. They are 16 different learned feature maps.

---

## Part 4 — How Deeper Layers Learn More Complex Patterns

### 4. The second layer receives feature maps, not raw pixels

The first convolution transforms:

```text
[1, 28, 28] → Conv1 (16 filters) → [16, 28, 28]
```

After ReLU and pooling:

```text
[16, 28, 28] → [16, 14, 14]
```

The second convolution takes all 16 channels as input. A typical standard convolutional filter in this layer has a kernel of shape `[16, 3, 3]`, letting it combine evidence from many first-layer features.

```text
Vertical stroke ────┐
Curved stroke ──────┼──► Second-layer filter ──► More complex pattern
Horizontal stroke ──┘
```

A second-layer filter might respond strongly to a spatial combination forming a partial loop.

### 5. Why depth helps

```text
Input image
     ↓
First layer: edges, strokes, curves
     ↓
Second layer: combinations and partial shapes
     ↓
Classifier: ten digit scores
     ↓
Predicted digit
```

This hierarchy is a useful mental model, not a guarantee that each filter has one human-readable purpose. Training optimizes the **classification objective**, not interpretability.

---

## Part 5 — Visualize What Your CNN Has Learned

The following code uses the `SimpleCNN` architecture, `test_dataset`, and the checkpoint `mnist_cnn.pth` created in Lesson 4.

### 6. Load your trained model

```python
import torch
import matplotlib.pyplot as plt

model = SimpleCNN()
model.load_state_dict(
    torch.load('mnist_cnn.pth', map_location='cpu', weights_only=True)
)
model.eval()
```

### 7. Visualize the first-layer feature maps

```python
image, label = test_dataset[0]
print('Digit:', label)

plt.imshow(image.squeeze(), cmap='gray')
plt.axis('off')
plt.show()

with torch.no_grad():
    features = model.relu(model.conv1(image.unsqueeze(0)))

print(features.shape)  # [1, 16, 28, 28]

fig, axes = plt.subplots(4, 4, figsize=(8, 8))
for i, ax in enumerate(axes.flat):
    feature_map = features[0, i]
    ax.imshow(feature_map, cmap='gray')
    ax.set_title(f'Filter {i + 1}')
    ax.axis('off')
plt.tight_layout()
plt.show()
```

Different maps may highlight edges, stroke orientations, or other structures. A bright location indicates stronger activation *relative to the displayed map*, not recognition of a whole object.

---

## Part 6 — Compare the First and Second Layers

### 8. Visualize second-layer feature maps

```python
with torch.no_grad():
    x = image.unsqueeze(0)
    x = model.conv1(x)
    x = model.relu(x)
    x = model.pool(x)
    x = model.conv2(x)
    x = model.relu(x)
    features2 = x

print(features2.shape)  # [1, 32, 14, 14]

fig, axes = plt.subplots(4, 4, figsize=(8, 8))
for i, ax in enumerate(axes.flat):
    feature_map = features2[0, i]
    ax.imshow(feature_map, cmap='gray')
    ax.set_title(f'Filter {i + 1}')
    ax.axis('off')
plt.tight_layout()
plt.show()
```

Compared with first-layer maps, these have lower spatial resolution, combine information across previous channels, and may respond to more complex patterns. The resolution reduction comes from pooling between the convolutions.

---

## Part 7 — Compare Before and After Training

### 9. Same architecture, different weights

```python
random_model = SimpleCNN()
random_model.eval()

trained_model = SimpleCNN()
trained_model.load_state_dict(
    torch.load('mnist_cnn.pth', map_location='cpu', weights_only=True)
)
trained_model.eval()

input_image = image.unsqueeze(0)

with torch.no_grad():
    random_features = random_model.relu(random_model.conv1(input_image))
    trained_features = trained_model.relu(trained_model.conv1(input_image))

fig, axes = plt.subplots(1, 2, figsize=(8, 4))
axes[0].imshow(random_features[0, 0], cmap='gray')
axes[0].set_title('Random initialization')
axes[1].imshow(trained_features[0, 0], cmap='gray')
axes[1].set_title('Trained network')
for ax in axes:
    ax.axis('off')
plt.tight_layout()
plt.show()
```

The maps generally differ. However, **filter 1 in a newly initialized model does not correspond directly to filter 1 in a separately trained model**. To measure how a particular filter changes, save a copy of that model's initialization before training, then compare the same filter afterward.

```text
BEFORE TRAINING          AFTER TRAINING
Same CNN architecture    Same CNN architecture
Random weights           Learned weights
Poor predictions         Better predictions
```

---

## Part 8 — Are Learned Features Always Interpretable?

### 10. Does every filter have a specific meaning?

Not necessarily. Some learned filters resemble edge detectors; others respond to several patterns or are hard to explain. Different filters may learn similar features. The model is trained to **minimize prediction error**, not to construct an easy-to-read inventory of image features.

This distinction matters even more for deeper CNNs and Vision Transformers.

---

## Part 9 — Practical Exercises

| Exercise | Task | What you'll discover |
|---|---|---|
| 1 | Visualize all 16 first-layer maps | Filters respond to different patterns |
| 2 | Compare first- and second-layer maps | Deeper layers combine features |
| 3 | Compare initial and trained weights | Learning changes numerical parameters |
| 4 | Pass digits 1, 5, and 8 through one filter | One filter responds differently to different inputs |
| 5 | Visualize the 3 × 3 learned kernel values | Each filter is a small numerical matrix |

**Recommended experiment:** Pass a digit 1 and a digit 8 through the same trained filter. Their different shapes can produce different activations. The filter responds to image structure rather than directly to the digit label.

---

## Lesson 5 Summary

1. **Training changes weights**, not the network architecture.
2. **Filters respond to patterns** in the input.
3. **Feature maps show where responses occur**.
4. **Deeper layers combine earlier representations**.
5. **Useful features are learned automatically** from image labels.

### Check Your Understanding

**Q1.** Will two networks with the same architecture but different random initializations necessarily learn identical filters?  
**Answer:** No. Their learned representations can differ even if accuracy is similar.

**Q2.** Does a filter responding strongly to a vertical line mean it has detected digit 1?  
**Answer:** No. Vertical strokes also occur in other digits; the classifier combines multiple features.

**Q3.** Why can the second convolution learn more complex patterns?  
**Answer:** It combines information from multiple feature maps produced by the first convolution.

---

## Next: Lesson 6 — Training, Overfitting, and Improving Accuracy

| Topic | What we'll learn |
|---|---|
| Training vs. test accuracy | Why training success doesn't guarantee generalization |
| Overfitting | Why a network can fit training data too closely |
| Underfitting | Why a network may fail to learn useful patterns |
| Learning rate | How update size affects training |
| Epochs and batch size | How training duration and batches influence learning |
| Data augmentation | How modified training images can improve generalization |
| Training curves | How to interpret loss and accuracy graphs |

**Lesson 6 completes Stage 1: CNN Fundamentals.** Then we'll move from grayscale MNIST to CIFAR-10 color images.
