# Visual Neural Networks — Course Syllabus

**Learning approach:** Beginner-friendly, visual and intuitive explanations, minimal mathematics, and practical examples using MNIST, CIFAR-10, and PyTorch.

**Scope:** 15 lessons across four stages. This document is a syllabus only; it does not contain lesson materials, code implementations, or exercises.

## Course overview

| Stage | Lessons | Module | Goal |
|---|---|---|---|
| 1 | 1–6 | CNN Fundamentals | Understand how images are represented, processed, and learned from by a basic CNN. |
| 2 | 7–10 | Modern CNNs | Understand richer image data, deeper architectures, ResNet, and transfer learning. |
| 3 | 11–13 | Modern Computer Vision | Learn the central ideas behind Vision Transformers, self-supervised learning, and object detection. |
| 4 | 14–15 | Practical Computer Vision | Understand inference optimization and deployment in real-time systems. |

## Stage 1 — CNN Fundamentals (Lessons 1–6)

**Dataset focus:** MNIST  
**Learning objective:** Build an intuitive mental model of a CNN, how training works, and how to interpret its outputs.

| Lesson | Title | Description / key concepts | Intended outcome |
|---|---|---|---|
| 1 | How Neural Networks See Images | Pixels, grayscale values, image tensors, MNIST digits, classification predictions, and a high-level view of CNNs. | Explain how an image becomes numerical input and a predicted class. |
| 2 | How CNN Filters Learn Patterns | Convolutional kernels, local patterns, learned weights, loss, gradients, backpropagation, and optimization. | Explain how useful filters emerge from training rather than being hand-programmed. |
| 3 | How CNN Layers Transform Images | Feature maps, channels, ReLU, max pooling, flattening, logits, softmax, and tensor shapes through a small CNN. | Trace the dimensions and purpose of each major CNN layer. |
| 4 | Build Your First CNN in PyTorch | MNIST loading, a simple two-layer CNN, forward pass, training loop, evaluation, saving weights, and visualizing feature maps. | Understand the components of a complete MNIST classification workflow. |
| 5 | What Does a CNN Actually Learn? | Random versus trained filters, activations, feature-map visualization, feature composition, and comparisons before/after training. | Interpret what changes inside a CNN as it learns visual patterns. |
| 6 | Training, Overfitting, and Improving Accuracy | Training versus test accuracy, generalization, epochs, learning rate, overfitting, and basic improvement strategies. | Diagnose common training behaviors and understand how to improve a baseline. |

## Stage 2 — Understanding Modern CNNs (Lessons 7–10)

**Dataset focus:** CIFAR-10  
**Learning objective:** Understand how CNNs scale to more complex images and why modern architectural techniques matter.

| Lesson | Title | Description / key concepts | Intended outcome |
|---|---|---|---|
| 7 | From MNIST to CIFAR-10 | RGB inputs, three channels, richer image content, data augmentation, and increased classification difficulty. | Describe why color images and more varied objects require stronger models. |
| 8 | Building Deeper CNNs | Network depth and width, receptive fields, Batch Normalization, training stability, and feature hierarchy. | Explain the trade-offs and benefits of adding layers to a CNN. |
| 9 | Understanding ResNet | Residual blocks, skip connections, gradient flow, and why residual learning enables deeper networks. | Understand the main design idea behind ResNet. |
| 10 | Transfer Learning | Pretraining, feature reuse, frozen backbones, linear probing, fine-tuning, and adapting classification heads. | Distinguish common strategies for adapting a pretrained vision model. |

## Stage 3 — Modern Computer Vision (Lessons 11–13)

**Learning objective:** Develop a conceptual understanding of important architectures and learning methods beyond traditional CNN classification.

| Lesson | Title | Description / key concepts | Intended outcome |
|---|---|---|---|
| 11 | Vision Transformers (ViT) | Image patches, patch embeddings, tokens, self-attention, and CNN–Transformer differences. | Explain how a Transformer can process an image. |
| 12 | Self-Supervised Learning | Learning visual representations without manual class labels, DINO, student–teacher ideas, and using learned embeddings. | Understand why useful image features can be learned without standard classification labels. |
| 13 | Object Detection | Image classification versus localization, bounding boxes, object classes, and the high-level ideas behind YOLO. | Explain what changes when a model must find and classify multiple objects in an image. |

## Stage 4 — Practical Computer Vision (Lessons 14–15)

**Learning objective:** Understand what is required to run vision models efficiently outside the training environment.

| Lesson | Title | Description / key concepts | Intended outcome |
|---|---|---|---|
| 14 | Model Optimization | Model size, inference performance, floating-point precision, FP16, INT8 quantization, and TensorRT. | Understand basic techniques and trade-offs for accelerating inference. |
| 15 | Real-Time Computer Vision | Latency, throughput, FPS, batch size, preprocessing, GPU inference, and deployment on edge hardware. | Identify the main factors affecting real-time vision-system performance. |

## Milestones

| After lesson | Milestone |
|---|---|
| 6 | Understand, train, and evaluate a basic MNIST CNN. |
| 10 | Understand foundational techniques in modern CNNs and pretrained-model adaptation. |
| 13 | Understand the conceptual differences among CNNs, Vision Transformers, self-supervised learning, and object detection. |
| 15 | Understand the fundamentals of optimizing and deploying vision models for real-time inference. |

---

*This syllabus defines course structure only. Lesson content will be developed separately.*
