"""
JARVIS — Real Gesture Data Collection Tool
Captures hand landmarks via webcam + MediaPipe for training with real gestures.

Usage:
    python collect_real_data.py
    python collect_real_data.py --gesture HELLO --samples 50 --output gesture_landmarks.csv

Controls:
    SPACE  — Capture current hand pose as a sample
    N      — Move to next gesture
    Q/ESC  — Quit and save

The tool uses MediaPipe Hands to extract 21 hand landmarks from each frame,
normalizes them (wrist-relative, scale-invariant), and appends rows to the
output CSV in the same format as generate_landmark_data.py.
"""

import argparse
import csv
import os
import sys
from pathlib import Path

import cv2
import mediapipe as mp
import numpy as np

# Import normalize function from the generator
from generate_landmark_data import (
    GESTURE_LABELS,
    NUM_LANDMARKS,
    COORDS_PER_LANDMARK,
    TOTAL_FEATURES,
    normalize_landmarks,
)


def setup_mediapipe():
    """Initialize MediaPipe Hands."""
    mp_hands = mp.solutions.hands
    mp_drawing = mp.solutions.drawing_utils
    mp_drawing_styles = mp.solutions.drawing_styles

    hands = mp_hands.Hands(
        static_image_mode=False,
        max_num_hands=1,
        min_detection_confidence=0.7,
        min_tracking_confidence=0.5,
    )
    return hands, mp_hands, mp_drawing, mp_drawing_styles


def extract_landmarks(hand_landmarks) -> np.ndarray:
    """Extract 21 landmarks as (21, 3) numpy array."""
    landmarks = np.zeros((NUM_LANDMARKS, COORDS_PER_LANDMARK), dtype=np.float32)
    for i, lm in enumerate(hand_landmarks.landmark):
        landmarks[i] = [lm.x, lm.y, lm.z]
    return landmarks


def append_to_csv(filepath: str, features: np.ndarray, label: str, write_header: bool = False) -> None:
    """Append a single sample to the CSV file."""
    header = [f"lm{i}_{c}" for i in range(NUM_LANDMARKS) for c in ("x", "y", "z")]
    header.append("label")

    mode = "w" if write_header else "a"
    with open(filepath, mode, newline="") as f:
        writer = csv.writer(f)
        if write_header:
            writer.writerow(header)
        row = list(features) + [label]
        writer.writerow(row)


def main():
    parser = argparse.ArgumentParser(description="Collect real hand gesture data via webcam")
    parser.add_argument("--gesture", type=str, default=None, help="Specific gesture to collect (default: cycle through all)")
    parser.add_argument("--samples", type=int, default=50, help="Target samples per gesture")
    parser.add_argument("--output", type=str, default="gesture_landmarks.csv", help="Output CSV path")
    parser.add_argument("--append", action="store_true", help="Append to existing CSV instead of overwriting")
    parser.add_argument("--camera", type=int, default=0, help="Camera device index")
    args = parser.parse_args()

    # Determine which gestures to collect
    if args.gesture:
        if args.gesture.upper() not in GESTURE_LABELS:
            print(f"Unknown gesture: {args.gesture}")
            print(f"Available: {GESTURE_LABELS}")
            sys.exit(1)
        gestures_to_collect = [args.gesture.upper()]
    else:
        gestures_to_collect = GESTURE_LABELS.copy()

    # Check if we need to write header
    write_header = not args.append or not os.path.exists(args.output)

    # Setup MediaPipe
    hands, mp_hands, mp_drawing, mp_drawing_styles = setup_mediapipe()

    # Open camera
    cap = cv2.VideoCapture(args.camera)
    if not cap.isOpened():
        print("Error: Cannot open camera")
        sys.exit(1)

    cap.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)

    print(f"\n{'='*60}")
    print("JARVIS — Real Gesture Data Collection")
    print(f"{'='*60}")
    print(f"Output: {args.output}")
    print(f"Gestures: {len(gestures_to_collect)}")
    print(f"Target samples per gesture: {args.samples}")
    print(f"\nControls:")
    print(f"  SPACE  — Capture current hand pose")
    print(f"  N      — Skip to next gesture")
    print(f"  Q/ESC  — Quit and save")
    print(f"{'='*60}\n")

    gesture_idx = 0
    samples_collected = 0
    total_collected = 0
    first_write = write_header

    while gesture_idx < len(gestures_to_collect):
        current_gesture = gestures_to_collect[gesture_idx]
        ret, frame = cap.read()
        if not ret:
            break

        # Flip for selfie view
        frame = cv2.flip(frame, 1)
        rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)

        # Process with MediaPipe
        results = hands.process(rgb_frame)
        hand_detected = False
        current_landmarks = None

        if results.multi_hand_landmarks:
            for hand_landmarks in results.multi_hand_landmarks:
                # Draw landmarks on frame
                mp_drawing.draw_landmarks(
                    frame,
                    hand_landmarks,
                    mp_hands.HAND_CONNECTIONS,
                    mp_drawing_styles.get_default_hand_landmarks_style(),
                    mp_drawing_styles.get_default_hand_connections_style(),
                )
                current_landmarks = extract_landmarks(hand_landmarks)
                hand_detected = True

        # Draw UI overlay
        cv2.rectangle(frame, (0, 0), (640, 80), (0, 0, 0), -1)
        cv2.putText(
            frame,
            f"Gesture: {current_gesture}",
            (10, 30),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.9,
            (0, 255, 255),
            2,
        )
        cv2.putText(
            frame,
            f"Collected: {samples_collected}/{args.samples}  |  Total: {total_collected}",
            (10, 60),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.6,
            (200, 200, 200),
            1,
        )

        status_color = (0, 255, 0) if hand_detected else (0, 0, 255)
        status_text = "Hand Detected ✓" if hand_detected else "No Hand Detected"
        cv2.putText(frame, status_text, (400, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.6, status_color, 1)

        cv2.putText(
            frame,
            f"[{gesture_idx+1}/{len(gestures_to_collect)}] SPACE=capture, N=next, Q=quit",
            (10, 470),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.5,
            (150, 150, 150),
            1,
        )

        cv2.imshow("JARVIS — Gesture Data Collection", frame)
        key = cv2.waitKey(1) & 0xFF

        # SPACE: Capture
        if key == ord(" ") and hand_detected and current_landmarks is not None:
            normalized = normalize_landmarks(current_landmarks)
            features = normalized.flatten()
            append_to_csv(args.output, features, current_gesture, write_header=first_write)
            first_write = False
            samples_collected += 1
            total_collected += 1
            print(f"  ✅ {current_gesture}: sample {samples_collected}/{args.samples}")

            if samples_collected >= args.samples:
                print(f"  ✓ Completed {current_gesture}!")
                gesture_idx += 1
                samples_collected = 0

        # N: Next gesture
        elif key == ord("n"):
            print(f"  ⏭️  Skipping {current_gesture} ({samples_collected} collected)")
            gesture_idx += 1
            samples_collected = 0

        # Q/ESC: Quit
        elif key == ord("q") or key == 27:
            break

    cap.release()
    cv2.destroyAllWindows()
    hands.close()

    print(f"\n{'='*60}")
    print(f"✅ Data collection complete!")
    print(f"   Total samples collected: {total_collected}")
    print(f"   Output file: {args.output}")
    print(f"{'='*60}\n")


if __name__ == "__main__":
    main()
