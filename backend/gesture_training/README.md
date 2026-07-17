# JARVIS — Gesture Model Training Pipeline

Train a TFLite gesture classifier from MediaPipe hand landmarks (21 keypoints × 3 coordinates = 63 features).

## Quick Start

```bash
# 1. Install dependencies
pip install -r requirements.txt

# 2. Generate synthetic training data
python generate_landmark_data.py --samples 300

# 3. Train the model
python train_gesture_model.py --epochs 100

# 4. Copy outputs to Flutter
cp output/gesture_classifier.tflite ../../assets/models/
cp output/gesture_labels.json ../../assets/models/
```

## Files

| File | Purpose |
|------|---------|
| `generate_landmark_data.py` | Generates synthetic landmark data with augmentation |
| `train_gesture_model.py` | Trains TensorFlow classifier, exports TFLite |
| `collect_real_data.py` | Webcam-based real gesture data collection |
| `requirements.txt` | Python dependencies |

## Pipeline Overview

```
Synthetic Data Generator          Real Data Collector
         ↓                                ↓
    gesture_landmarks.csv (63 features + label)
                    ↓
           Training Script
                    ↓
    gesture_classifier.tflite  (on-device inference)
    gesture_labels.json        (label index mapping)
    confusion_matrix.png       (evaluation)
    training_history.png       (training curves)
```

## Supported Gestures (20)

HELLO, THANK_YOU, YES, NO, HELP, HOSPITAL, POLICE, FIRE, WATER, FOOD,
PAIN, EMERGENCY, PLEASE, SORRY, GOODBYE, I, YOU, WANT, NEED, WHERE

## Training with Real Data

To improve accuracy with real hand data:

```bash
# Option A: Collect fresh dataset
python collect_real_data.py --samples 50 --output real_landmarks.csv

# Option B: Append to existing synthetic data
python collect_real_data.py --samples 30 --output gesture_landmarks.csv --append

# Retrain
python train_gesture_model.py --data gesture_landmarks.csv
```

### Data Collection Controls
- **SPACE** — Capture current hand pose
- **N** — Skip to next gesture
- **Q/ESC** — Quit and save

## Model Architecture

```
Input (63 features)
    ↓
Dense(128, ReLU) + BatchNorm + Dropout(0.3)
    ↓
Dense(64, ReLU) + BatchNorm + Dropout(0.2)
    ↓
Dense(20, Softmax)
```

Exported with float16 quantization (~50-200 KB).

## Output Files

After training, the `output/` directory contains:

- `gesture_classifier.tflite` — Quantized model for Flutter
- `gesture_labels.json` — Class index → label mapping
- `gesture_classifier.keras` — Full Keras model for fine-tuning
- `confusion_matrix.png` — Evaluation visualization
- `training_history.png` — Accuracy/loss curves
