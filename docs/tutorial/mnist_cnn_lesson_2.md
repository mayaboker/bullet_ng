# Lesson 2: How Does a CNN Learn to Detect Patterns?

In Lesson 1, we learned that a CNN uses **filters (kernels)** to identify visual patterns such as edges, lines, and curves.

Now we'll explore the most important question:

**How does a CNN learn these filters automatically, starting from random numbers?**

We'll continue using MNIST, without heavy mathematics.

## 1. Start with a simple image

Imagine we have this 5 × 5 image containing a vertical white line:

```text
0  0  1  0  0
0  0  1  0  0
0  0  1  0  0
0  0  1  0  0
0  0  1  0  0
```

The network doesn't know this is a vertical line. It only sees numbers.

Our goal is to understand how a filter might become sensitive to this pattern.

## 2. The filter starts with random numbers

A convolutional filter is a small matrix of weights.

For example, a 3 × 3 filter might initially contain:

```text
 0.2  -0.3   0.1
-0.1   0.4   0.2
 0.3  -0.2   0.1
```

These numbers are the **learnable parameters**. During training, the network changes them.

Initially, they don't necessarily detect anything useful.

## 3. How does the filter process an image?

The filter examines a small region of the image.

For our vertical line, one 3 × 3 region looks like:

```text
Image region:          Filter:

0  1  0                0.2  -0.3   0.1
0  1  0               -0.1   0.4   0.2
0  1  0                0.3  -0.2   0.1
```

The filter multiplies each image value by its corresponding weight and adds the results.

Because the image contains zeros everywhere except the middle column, only three weights contribute:

```text
-0.3 + 0.4 - 0.2 = -0.1
```

The filter produces a response of **−0.1**.

**The filter's response depends on how well its weights match the image pattern.**

A larger positive response can indicate a stronger match to a pattern the filter has learned to detect.

---

## 4. What would a useful vertical-line filter look like?

Imagine the filter eventually learns these weights:

```text
-1   2  -1
-1   2  -1
-1   2  -1
```

When applied to our vertical line:

```text
Image region:          Filter:

0  1  0               -1   2  -1
0  1  0               -1   2  -1
0  1  0               -1   2  -1
```

The result is:

```text
2 + 2 + 2 = 6
```

This is a strong positive response.

For a completely white region:

```text
1  1  1
1  1  1
1  1  1
```

The result would be:

```text
(-1 + 2 - 1) × 3 = 0
```

Therefore, this filter responds strongly to a vertical line surrounded by darker pixels but not to a uniformly white region.

This is the basic idea behind feature detection.

**However, we still haven't explained how the network learns these weights.**

---

# 5. How does learning happen?

Suppose we're training a CNN to recognize handwritten digits.

We show it an image of the digit **1**.

### Step A — Make a prediction

```text
       Image: 1
           │
           ▼
    Convolution Filter
           │
           ▼
       Classifier
           │
           ▼
     Prediction: 7
```

The network predicts 7, but the correct answer is 1.

### Step B — Measure the error

The loss function measures how poorly the network predicted the correct digit.

For classification, we commonly use **cross-entropy loss**.

A lower loss means the network is assigning more probability to the correct digit.

### Step C — Determine which weights to change

This is where **backpropagation** comes in.

Think of backpropagation as a mechanism that answers:

> If I slightly change this weight, will the prediction error increase or decrease?

For each weight, the network calculates a value called a **gradient**.

The gradient tells us which direction to change that weight to reduce the loss locally.

### Step D — Update the weights

Imagine a weight currently equals:

```text
Weight = 0.2
```

The optimizer determines that decreasing it should reduce the loss.

After an update:

```text
Weight = 0.18
```

The next training example might cause another adjustment:

```text
Weight = 0.17
```

Other weights might increase instead.

The network repeats this process across many examples.

---

## 6. An important distinction: Nobody tells the filter to detect lines

During normal MNIST training, we never tell the network:

- This filter should detect vertical lines.
- That filter should detect horizontal lines.
- Another filter should detect circles.

We only provide an image and its correct digit label.

For example:

```text
Image: handwritten 8

Correct answer: 8
```

The learning process adjusts all trainable parameters to improve digit classification.

Some filters may naturally become sensitive to lines, curves, loops, or other useful patterns.

**The filters learn because those patterns help reduce the classification error—not because we explicitly teach them what an edge looks like.**

This is called *end-to-end learning*.

---

# 7. How does the CNN learn multiple patterns?

A convolutional layer usually contains multiple filters.

For example:

```text
              Input Image
                   │
          ┌────────┼────────┐
          ▼        ▼        ▼
       Filter 1  Filter 2  Filter 3
          │        │        │
          ▼        ▼        ▼
       Feature   Feature   Feature
        Map 1     Map 2     Map 3
```

Each filter has its own learnable weights.

During training, different filters can become sensitive to different visual structures.

For example:

| Filter | Possible learned response |
|---|---|
| Filter 1 | Vertical lines |
| Filter 2 | Horizontal lines |
| Filter 3 | Diagonal edges |
| Filter 4 | Curves |
| Filter 5 | Stroke intersections |

These are possible interpretations, not predefined roles.

A layer with 16 filters produces **16 feature maps**.

The next convolutional layer can combine information from all 16 feature maps to recognize more complex patterns.

---

# 8. Why are thousands of examples necessary?

Imagine training a network using only one handwritten digit 7.

The network might learn to recognize that specific image.

But what happens when someone writes 7 differently?

```text
Example A:       Example B:

█████            █████
    █               █
   █               █
  █                █
 █                 █
```

The network needs to learn which patterns are consistent across many different handwriting styles.

This is why we use datasets such as MNIST, which provides **60,000 training images and 10,000 test images**.

By learning from many examples, the CNN can recognize digits it has never seen before.

This ability is called **generalization**.

---

# 9. Putting everything together

Here is the complete learning cycle:

```text
       MNIST Training Image
                │
                ▼
       Convolutional Layers
         (Learnable Filters)
                │
                ▼
           Classifier
                │
                ▼
            Prediction
                │
                ▼
      Compare with True Label
                │
                ▼
         Calculate Loss
                │
                ▼
         Backpropagation
                │
                ▼
       Calculate Gradients
                │
                ▼
       Update Filter Weights
                │
                ▼
       Repeat with More Images
```

The **forward pass** produces the prediction, while **backpropagation and the optimizer** update the learnable parameters.

When training is finished, we can use the trained CNN to classify new images without updating its weights.

---

## 10. Check your understanding

Imagine we have a CNN trained to recognize MNIST digits.

One of its filters responds strongly to vertical lines.

Now we show the network an image of the digit **1**, which contains a long vertical stroke.

**Question:** Does that filter directly decide that the image contains the digit 1?

**Answer:** No.

The filter produces a feature map indicating where it detects its preferred pattern.

Other layers combine that information with many other features to produce the final digit prediction.

A vertical line could also appear in digits such as 4 or 7, so detecting one feature alone is usually insufficient.

---

## What's next? Lesson 3

**Lesson 3: How CNN Layers Transform an MNIST Image**

We'll follow an actual **28 × 28 image through a CNN**, exploring:

1. Why a convolution produces a feature map.
2. What happens when we use 16 different filters.
3. How ReLU changes the output.
4. Why max pooling reduces image size.
5. How the final layer produces 10 digit scores.

The goal is to understand **exactly what happens to the image at every stage of a CNN**, visually and without heavy mathematics.
