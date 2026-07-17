"""
JARVIS — Gesture Model Training Script
Trains a TensorFlow classifier on hand landmark data and exports to TFLite.

Pipeline:
  1. Load landmark CSV (63 features + label)
  2. Encode labels → integers
  3. Train/test split
  4. Build Dense neural network (63 → 128 → 64 → 20)
  5. Train with early stopping
  6. Evaluate (accuracy, confusion matrix, classification report)
  7. Export to TFLite with float16 quantization
  8. Save label map as JSON

Usage:
    python train_gesture_model.py
    python train_gesture_model.py --data gesture_landmarks.csv --epochs 100
"""

import argparse
import json
import os
import sys
from pathlib import Path

import numpy as np
import pandas as pd
import matplotlib
matplotlib.use("Agg")  # Non-interactive backend
import matplotlib.pyplot as plt
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
from sklearn.metrics import classification_report, confusion_matrix, ConfusionMatrixDisplay

os.environ["TF_CPP_MIN_LOG_LEVEL"] = "2"  # Suppress TF info logs
import tensorflow as tf


def load_data(csv_path: str) -> tuple[np.ndarray, np.ndarray, list[str]]:
    """Load landmark data from CSV. Returns X, y_encoded, label_names."""
    print(f"  Loading data from {csv_path}...")
    df = pd.read_csv(csv_path)

    # Separate features and labels
    X = df.drop(columns=["label"]).values.astype(np.float32)
    y_raw = df["label"].values

    # Encode labels to integers
    le = LabelEncoder()
    y = le.fit_transform(y_raw)
    label_names = le.classes_.tolist()

    print(f"  Loaded {len(X)} samples, {X.shape[1]} features, {len(label_names)} classes")
    return X, y, label_names


def build_model(num_features: int, num_classes: int) -> tf.keras.Model:
    """Build a lightweight Dense classifier."""
    model = tf.keras.Sequential([
        tf.keras.layers.Input(shape=(num_features,)),
        tf.keras.layers.Dense(128, activation="relu"),
        tf.keras.layers.BatchNormalization(),
        tf.keras.layers.Dropout(0.3),
        tf.keras.layers.Dense(64, activation="relu"),
        tf.keras.layers.BatchNormalization(),
        tf.keras.layers.Dropout(0.2),
        tf.keras.layers.Dense(num_classes, activation="softmax"),
    ])

    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=0.001),
        loss="sparse_categorical_crossentropy",
        metrics=["accuracy"],
    )

    return model


def train_model(
    model: tf.keras.Model,
    X_train: np.ndarray,
    y_train: np.ndarray,
    X_val: np.ndarray,
    y_val: np.ndarray,
    epochs: int = 100,
    batch_size: int = 32,
) -> tf.keras.callbacks.History:
    """Train the model with early stopping and learning rate reduction."""
    callbacks = [
        tf.keras.callbacks.EarlyStopping(
            monitor="val_accuracy",
            patience=15,
            restore_best_weights=True,
            verbose=1,
        ),
        tf.keras.callbacks.ReduceLROnPlateau(
            monitor="val_loss",
            factor=0.5,
            patience=7,
            min_lr=1e-6,
            verbose=1,
        ),
    ]

    history = model.fit(
        X_train, y_train,
        validation_data=(X_val, y_val),
        epochs=epochs,
        batch_size=batch_size,
        callbacks=callbacks,
        verbose=1,
    )

    return history


def evaluate_model(
    model: tf.keras.Model,
    X_test: np.ndarray,
    y_test: np.ndarray,
    label_names: list[str],
    output_dir: str,
) -> float:
    """Evaluate model and save visualizations."""
    # Predict
    y_pred_probs = model.predict(X_test, verbose=0)
    y_pred = np.argmax(y_pred_probs, axis=1)

    # Classification report
    report = classification_report(y_test, y_pred, target_names=label_names)
    print(f"\n{'='*60}")
    print("Classification Report:")
    print(f"{'='*60}")
    print(report)

    # Accuracy
    accuracy = np.mean(y_pred == y_test)
    print(f"Test Accuracy: {accuracy:.4f} ({accuracy*100:.1f}%)")

    # Confusion matrix
    cm = confusion_matrix(y_test, y_pred)
    fig, ax = plt.subplots(figsize=(14, 12))
    disp = ConfusionMatrixDisplay(confusion_matrix=cm, display_labels=label_names)
    disp.plot(ax=ax, cmap="Blues", xticks_rotation=45)
    plt.title("JARVIS Gesture Classifier — Confusion Matrix")
    plt.tight_layout()
    cm_path = os.path.join(output_dir, "confusion_matrix.png")
    plt.savefig(cm_path, dpi=150)
    plt.close()
    print(f"  Confusion matrix saved to {cm_path}")

    return accuracy


def plot_training_history(history: tf.keras.callbacks.History, output_dir: str) -> None:
    """Save training curves."""
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 5))

    # Accuracy
    ax1.plot(history.history["accuracy"], label="Train")
    ax1.plot(history.history["val_accuracy"], label="Validation")
    ax1.set_title("Model Accuracy")
    ax1.set_xlabel("Epoch")
    ax1.set_ylabel("Accuracy")
    ax1.legend()
    ax1.grid(True, alpha=0.3)

    # Loss
    ax2.plot(history.history["loss"], label="Train")
    ax2.plot(history.history["val_loss"], label="Validation")
    ax2.set_title("Model Loss")
    ax2.set_xlabel("Epoch")
    ax2.set_ylabel("Loss")
    ax2.legend()
    ax2.grid(True, alpha=0.3)

    plt.suptitle("JARVIS Gesture Classifier — Training History")
    plt.tight_layout()
    history_path = os.path.join(output_dir, "training_history.png")
    plt.savefig(history_path, dpi=150)
    plt.close()
    print(f"  Training history saved to {history_path}")


def export_tflite(
    model: tf.keras.Model,
    output_path: str,
    quantize: bool = True,
) -> None:
    """Export model to TFLite format with optional float16 quantization."""
    converter = tf.lite.TFLiteConverter.from_keras_model(model)

    if quantize:
        converter.optimizations = [tf.lite.Optimize.DEFAULT]
        converter.target_spec.supported_types = [tf.float16]

    tflite_model = converter.convert()

    with open(output_path, "wb") as f:
        f.write(tflite_model)

    size_kb = len(tflite_model) / 1024
    print(f"  TFLite model saved to {output_path} ({size_kb:.1f} KB)")


def save_label_map(label_names: list[str], output_path: str) -> None:
    """Save label names as JSON for Flutter to load."""
    with open(output_path, "w") as f:
        json.dump(label_names, f, indent=2)
    print(f"  Label map saved to {output_path}")


def main():
    parser = argparse.ArgumentParser(description="Train JARVIS gesture classifier")
    parser.add_argument("--data", type=str, default="gesture_landmarks.csv", help="Input CSV path")
    parser.add_argument("--epochs", type=int, default=100, help="Max training epochs")
    parser.add_argument("--batch-size", type=int, default=32, help="Training batch size")
    parser.add_argument("--test-split", type=float, default=0.2, help="Test split ratio")
    parser.add_argument("--output-dir", type=str, default="output", help="Output directory")
    parser.add_argument("--no-quantize", action="store_true", help="Skip quantization")
    args = parser.parse_args()

    # Create output directory
    os.makedirs(args.output_dir, exist_ok=True)

    print(f"\n{'='*60}")
    print("JARVIS — Gesture Model Training")
    print(f"{'='*60}")

    # Step 1: Load data
    if not os.path.exists(args.data):
        print(f"\n[!] Data file not found: {args.data}")
        print("   Run 'python generate_landmark_data.py' first.")
        sys.exit(1)

    X, y, label_names = load_data(args.data)

    # Step 2: Train/test split
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=args.test_split, random_state=42, stratify=y
    )
    print(f"  Train: {len(X_train)}, Test: {len(X_test)}")

    # Step 3: Build model
    print(f"\n  Building model...")
    model = build_model(X.shape[1], len(label_names))
    model.summary()

    # Step 4: Train
    print(f"\n{'='*60}")
    print("Training...")
    print(f"{'='*60}\n")
    history = train_model(
        model, X_train, y_train, X_test, y_test,
        epochs=args.epochs, batch_size=args.batch_size,
    )

    # Step 5: Evaluate
    accuracy = evaluate_model(model, X_test, y_test, label_names, args.output_dir)

    # Step 6: Save training plots
    plot_training_history(history, args.output_dir)

    # Step 7: Export TFLite
    tflite_path = os.path.join(args.output_dir, "gesture_classifier.tflite")
    export_tflite(model, tflite_path, quantize=not args.no_quantize)

    # Step 8: Save label map
    labels_path = os.path.join(args.output_dir, "gesture_labels.json")
    save_label_map(label_names, labels_path)

    # Also save Keras model for potential fine-tuning
    keras_path = os.path.join(args.output_dir, "gesture_classifier.keras")
    model.save(keras_path)
    print(f"  Keras model saved to {keras_path}")

    # Summary
    print(f"\n{'='*60}")
    print("[OK] Training Complete!")
    print(f"{'='*60}")
    print(f"  Accuracy: {accuracy*100:.1f}%")
    print(f"  TFLite Model: {tflite_path}")
    print(f"  Label Map: {labels_path}")
    print(f"  Keras Model: {keras_path}")
    print(f"\n  Next steps:")
    print(f"  1. Copy '{tflite_path}' to Flutter 'assets/models/gesture_classifier.tflite'")
    print(f"  2. Copy '{labels_path}' to Flutter 'assets/models/gesture_labels.json'")
    print(f"{'='*60}\n")


if __name__ == "__main__":
    main()
