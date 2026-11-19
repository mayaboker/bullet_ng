# Lesson 3: How CNN Layers Transform an MNIST Image

In Lesson 2, we learned how convolutional filters recognize patterns and how training adjusts their weights. Now we'll follow a **28 × 28 MNIST image** through an entire CNN, without heavy mathematics.

## 1. Input image

MNIST images are grayscale, so each pixel has one brightness value. A single image in PyTorch has shape `[1, 28, 28]`: `[channels, height, width]`. A batch of 32 images has shape `[32, 1, 28, 28]`: `[batch, channels, height, width]`.

## 2. First convolutional layer

We apply **16 filters**, each with a **3 × 3** spatial kernel. Every filter scans the image and produces its own *feature map*.

```text
Input [1, 28, 28]
    ↓ Conv2D(1 → 16, kernel_size=3, padding=1, stride=1)
Output [16, 28, 28]
```

Padding of 1 preserves height and width. The 16 output channels are 16 learned representations of the input, potentially emphasizing different edges and strokes.

## 3. ReLU activation

ReLU keeps positive values and replaces negative values with zero:

```text
Before ReLU:       After ReLU:
-2   3  -1         0   3   0
 4  -5   2         4   0   2
-1   6  -3         0   6   0
```

ReLU provides **nonlinearity**, which lets stacked layers learn more complex relationships. It does not change shape: `[16, 28, 28] → [16, 28, 28]`.

## 4. Max pooling

A **2 × 2 max-pooling** operation with stride 2 keeps the strongest value in each non-overlapping 2 × 2 region.

```text
Input feature map:   Output after pooling:
1  3  2  4           6  4
5  6  1  2           4  8
2  1  8  3
4  2  5  7
```

For our CNN, pooling reduces `[16, 28, 28] → [16, 14, 14]`. It reduces later computation and provides some tolerance to small shifts, at the cost of losing spatial detail.

## 5. Second convolutional layer

The second layer receives **16 input channels** and produces **32 output channels**. Each of its 32 filters spans *all 16* input channels and covers a 3 × 3 spatial region.

```text
One filter:             [16, 3, 3]
Entire weight tensor:   [32, 16, 3, 3]
Input:                  [16, 14, 14]
Output:                 [32, 14, 14]
```

By combining information across previous feature maps, deeper filters can respond to more complex structures, such as curves and connected strokes.

## 6. Second ReLU and pooling

```text
[32, 14, 14]
    ↓ ReLU
[32, 14, 14]
    ↓ MaxPool2D(2)
[32, 7, 7]
```

We now have 32 feature maps, each 7 × 7.

## 7. Flattening

Flatten turns all feature-map values into a single vector without learning new parameters or changing the values.

```text
[32, 7, 7] → [1568]
```

For a batch of 32 images, that becomes `[32, 1568]`.

## 8. Fully connected classifier

A final linear layer maps 1,568 features to **10 output scores**, one for each digit (0–9):

```text
[1568] → Linear(1568, 10) → [10 logits]
```

Example scores:

| Digit | Logit |
|---|---:|
| 0 | -1.2 |
| 1 | -2.5 |
| 2 | 0.8 |
| 3 | 1.1 |
| 4 | -1.8 |
| 5 | 0.4 |
| 6 | -0.3 |
| 7 | -2.1 |
| **8** | **4.7** |
| 9 | 0.6 |

The largest logit belongs to digit 8, so the network predicts **8**.

## 9. Softmax and probabilities

**Softmax** converts logits into probabilities that add up to 1. It does not change which class has the highest score. When training with PyTorch `CrossEntropyLoss`, pass the **raw logits**; the loss function handles the required log-softmax computation internally.

## 10. Complete architecture

```text
MNIST image       [1, 28, 28]
    ↓ Conv2D(1 → 16, kernel=3, padding=1)
                  [16, 28, 28]
    ↓ ReLU        [16, 28, 28]
    ↓ MaxPool2D(2)
                  [16, 14, 14]
    ↓ Conv2D(16 → 32, kernel=3, padding=1)
                  [32, 14, 14]
    ↓ ReLU        [32, 14, 14]
    ↓ MaxPool2D(2)
                  [32, 7, 7]
    ↓ Flatten     [1568]
    ↓ Linear      [10 logits]
    ↓ Argmax      predicted digit (0–9)
```

## 11. Learnable parameters

Assuming biases are enabled:

| Layer | Output shape | Learnable parameters |
|---|---|---:|
| Input | 1 × 28 × 28 | 0 |
| Conv2D (1 → 16) | 16 × 28 × 28 | 160 |
| ReLU | 16 × 28 × 28 | 0 |
| MaxPool | 16 × 14 × 14 | 0 |
| Conv2D (16 → 32) | 32 × 14 × 14 | 4,640 |
| ReLU | 32 × 14 × 14 | 0 |
| MaxPool | 32 × 7 × 7 | 0 |
| Flatten | 1,568 | 0 |
| Linear (1568 → 10) | 10 | 15,690 |
| **Total** | | **20,490** |

The final linear layer contains most of this model's parameters. Later we'll explore **global average pooling**, a common way to reduce them.

## 12. Three key ideas

1. **Channels:** Each output channel is a learned feature representation. Here: `1 → 16 → 32`.
2. **Spatial resolution:** Pooling reduces height and width: `28 × 28 → 14 × 14 → 7 × 7`.
3. **Joint learning:** Backpropagation adjusts weights in both the convolutional layers and the final classifier.

## Quick understanding check

**Q1:** What is the output of `Conv2D(1 → 8, kernel=3, padding=1, stride=1)` on `[1, 28, 28]`?  
**A:** `[8, 28, 28]`.

**Q2:** What happens after `MaxPool2D(2)`?  
**A:** `[8, 14, 14]`.

**Q3:** What if we next apply `Conv2D(8 → 16, kernel=3, padding=1)`?  
**A:** `[16, 14, 14]`.

## Next: Lesson 4 — Build your first CNN in PyTorch

We'll load MNIST, implement these layers, inspect the tensor shapes, train the model, and visualize what its filters detect.
