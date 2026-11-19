# Lesson 1: How Does a Neural Network Recognize an Image?

We'll learn how a **visual neural network works**, using MNIST (handwritten digits) as our example.

We'll focus on intuition, visual explanations, and simple examples—without heavy mathematics.

## 1. What does a neural network actually see?

Imagine we give a neural network this image:

```text
   █████
       █
      █
     █
    █
```

You immediately recognize the digit **7**.

But a neural network doesn't see a "7". It sees a grid of numbers.

MNIST images are 28 × 28 pixels, and each pixel has a brightness value:

- 0 = Black
- 255 = White
- Values between 0 and 255 = Shades of gray

For example:

```text
Image (simplified):

  0    0  255  255  255
  0    0    0    0  255
  0    0    0  255    0
  0    0  255    0    0
  0  255    0    0    0
```

The network receives **784 numbers (28 × 28)** representing the image.

Its objective is to transform these numbers into a prediction:

```text
Input Image
     ↓
Neural Network
     ↓
Predictions:

0 → 0.01
1 → 0.02
2 → 0.03
3 → 0.01
4 → 0.01
5 → 0.01
6 → 0.01
7 → 0.88  ← Highest probability
8 → 0.01
9 → 0.01
```

The network predicts **7**. But how does it learn to do that?

---

## 2. The key idea: Learning patterns

Humans recognize digits because we understand their shapes.

For example:

- **1** has a long vertical stroke.
- **0** has a closed loop.
- **7** usually has a horizontal stroke and a diagonal stroke.
- **8** usually has two loops.

A neural network learns to recognize similar visual patterns.

However, it doesn't start by knowing what a line or curve is.

**It learns useful patterns automatically from examples.**

This is where convolutional neural networks (CNNs) become interesting.

---

## 3. What is a convolution?

A CNN uses small filters, also called **kernels**, to examine local regions of an image.

Imagine our image contains this pattern:

```text
0 0 1 0 0
0 0 1 0 0
0 0 1 0 0
0 0 1 0 0
0 0 1 0 0
```

There is a vertical white line in the middle.

Now imagine we have a small 3 × 3 filter that is particularly sensitive to vertical lines.

```text
Filter:

-1  2 -1
-1  2 -1
-1  2 -1
```

We slide this filter over the image.

At every position, the filter examines a small 3 × 3 region and produces one number.

When the filter encounters a vertical line, it produces a strong positive response.

When it encounters a different pattern, the response is generally weaker or negative.

The result is another image-like grid called a **feature map**.

### Why is this useful?

Instead of looking at individual pixels, the network can start detecting meaningful structures.

For example:

```text
Original Image
      ↓
Convolutional Filters
      ↓
Feature Maps

Filter 1 → Vertical lines
Filter 2 → Horizontal lines
Filter 3 → Diagonal lines
Filter 4 → Curves
```

These are illustrative examples. In an actual CNN, the filters aren't necessarily this interpretable.

**Important:** We don't manually tell the network which filters to use.

The network learns the values inside its filters during training.

---

## 4. How do multiple layers help?

One of the most important ideas in deep learning is that **different layers can learn different levels of visual complexity**.

Imagine recognizing the digit 8.

### Layer 1 — Simple features

The first convolutional layer detects simple patterns:

```text
Vertical edges
Horizontal edges
Diagonal edges
Small curves
```

### Layer 2 — More complex features

The second layer combines information from the first layer.

It might respond to:

```text
Rounded shapes
Corners
Partial loops
Connected strokes
```

### Layer 3 — Digit-level patterns

Deeper layers can combine these features into more complex structures.

For example:

```text
Two connected loops
        ↓
Likely digit 8
```

Conceptually:

```text
        Input Image
             ↓
    [Lines and Edges]
             ↓
    [Curves and Loops]
             ↓
     [Digit Patterns]
             ↓
       Prediction
```

This is why stacking layers is useful.

Each layer can build on information learned by previous layers.

---

## 5. But how does the network LEARN the filters?

This is the most important part.

Imagine we create a CNN with random filter values.

Initially, it doesn't know anything about digits.

We show it an image of **7**.

### Step 1 — Forward pass

The image passes through the network.

```text
Image: 7
    ↓
CNN
    ↓
Prediction: 3
```

The network makes a mistake.

### Step 2 — Calculate the error

We tell the network that the correct answer is 7.

A function called the **loss function** measures how wrong the network's prediction was.

### Step 3 — Adjust the network

Using a process called **backpropagation**, the network determines how changing its parameters would affect the loss.

An optimizer then makes small adjustments to the parameters.

These parameters include the values inside the convolutional filters.

### Step 4 — Repeat

We show the network thousands of handwritten digits.

```text
Image → Prediction → Error → Adjustment
Image → Prediction → Error → Adjustment
Image → Prediction → Error → Adjustment
...
```

Over time, the filters become better at extracting patterns useful for distinguishing digits.

**The network is not memorizing instructions for drawing each digit. It is learning numerical patterns that help it classify previously unseen images.**

---

## 6. The complete picture

Here is a simplified CNN for MNIST:

```text
           MNIST Image
             28×28
                │
                ▼
        ┌──────────────┐
        │ Convolution  │
        │ 16 filters   │
        └──────────────┘
                │
                ▼
        ┌──────────────┐
        │     ReLU     │
        └──────────────┘
                │
                ▼
        ┌──────────────┐
        │    Pooling   │
        └──────────────┘
                │
                ▼
        ┌──────────────┐
        │ Convolution  │
        │ 32 filters   │
        └──────────────┘
                │
                ▼
        ┌──────────────┐
        │     ReLU     │
        └──────────────┘
                │
                ▼
        ┌──────────────┐
        │  Classifier  │
        └──────────────┘
                │
                ▼
          Predicted Digit
              0–9
```

We've introduced two additional components:

**ReLU:** Keeps positive values and replaces negative values with zero. This introduces nonlinearity, allowing the network to learn more complex relationships.

**Pooling:** Reduces the spatial size of feature maps. For example, a 2 × 2 max-pooling operation keeps the largest value from each 2 × 2 region, reducing the amount of information the next layer needs to process.

---

## 7. The most important concept to understand

A CNN does not contain explicit instructions such as:

> If you find two loops, predict 8.

Instead, it contains **millions, thousands, or even just hundreds of numerical parameters**, depending on its architecture.

During training, those parameters are adjusted so the network becomes better at recognizing digits.

This leads to an interesting question:

**If the network initially has completely random filters, how does it discover that detecting vertical lines, curves, and loops is useful?**

That's what I recommend exploring next, because understanding **how a single filter learns** is the foundation for understanding the entire neural network.

Next lesson: **One 3 × 3 filter learning to detect a vertical line**, step by step, without complicated mathematics.
