"""
JARVIS — Synthetic Hand Landmark Data Generator
Generates training data for the gesture classifier.

Each sample represents 21 MediaPipe hand landmarks (x, y, z) = 63 features.
Landmarks are normalized relative to the wrist (landmark 0) and scaled
so that the hand spans roughly [0, 1] in both x and y.

Usage:
    python generate_landmark_data.py
    python generate_landmark_data.py --samples 500 --output gesture_landmarks.csv
"""

import argparse
import csv
import os
import sys
from pathlib import Path

import numpy as np

# ── MediaPipe Hand Landmark Indices ──
# 0: WRIST
# 1-4: THUMB (CMC, MCP, IP, TIP)
# 5-8: INDEX (MCP, PIP, DIP, TIP)
# 9-12: MIDDLE (MCP, PIP, DIP, TIP)
# 13-16: RING (MCP, PIP, DIP, TIP)
# 17-20: PINKY (MCP, PIP, DIP, TIP)

GESTURE_LABELS = [
    "HELLO", "THANK_YOU", "YES", "NO", "HELP",
    "HOSPITAL", "POLICE", "FIRE", "WATER", "FOOD",
    "PAIN", "EMERGENCY", "PLEASE", "SORRY", "GOODBYE",
    "I", "YOU", "WANT", "NEED", "WHERE",
]

NUM_LANDMARKS = 21
COORDS_PER_LANDMARK = 3  # x, y, z
TOTAL_FEATURES = NUM_LANDMARKS * COORDS_PER_LANDMARK  # 63


def _base_hand() -> np.ndarray:
    """
    Returns a canonical relaxed open-hand landmark array (21, 3).
    Palm facing camera, fingers pointing up, wrist at origin.
    Coordinates are roughly in [0, 1] range.
    """
    landmarks = np.zeros((21, 3), dtype=np.float32)

    # Wrist at origin
    landmarks[0] = [0.5, 0.9, 0.0]

    # Thumb (angled outward to the left)
    landmarks[1] = [0.35, 0.80, -0.02]   # CMC
    landmarks[2] = [0.25, 0.70, -0.03]   # MCP
    landmarks[3] = [0.18, 0.60, -0.02]   # IP
    landmarks[4] = [0.12, 0.52, -0.01]   # TIP

    # Index finger (straight up)
    landmarks[5] = [0.38, 0.65, 0.0]     # MCP
    landmarks[6] = [0.36, 0.48, 0.0]     # PIP
    landmarks[7] = [0.35, 0.33, 0.0]     # DIP
    landmarks[8] = [0.34, 0.20, 0.0]     # TIP

    # Middle finger (straight up, slightly right of index)
    landmarks[9]  = [0.48, 0.62, 0.0]    # MCP
    landmarks[10] = [0.48, 0.44, 0.0]    # PIP
    landmarks[11] = [0.48, 0.28, 0.0]    # DIP
    landmarks[12] = [0.48, 0.14, 0.0]    # TIP

    # Ring finger
    landmarks[13] = [0.58, 0.65, 0.0]    # MCP
    landmarks[14] = [0.59, 0.48, 0.0]    # PIP
    landmarks[15] = [0.60, 0.33, 0.0]    # DIP
    landmarks[16] = [0.60, 0.20, 0.0]    # TIP

    # Pinky finger
    landmarks[17] = [0.67, 0.70, 0.0]    # MCP
    landmarks[18] = [0.69, 0.55, 0.0]    # PIP
    landmarks[19] = [0.70, 0.43, 0.0]    # DIP
    landmarks[20] = [0.71, 0.33, 0.0]    # TIP

    return landmarks


def _curl_finger(landmarks: np.ndarray, finger_start: int) -> np.ndarray:
    """Curl a finger (4 landmarks starting from MCP) into a fist position."""
    lm = landmarks.copy()
    mcp = lm[finger_start].copy()
    # Curl PIP, DIP, TIP towards the MCP
    lm[finger_start + 1] = mcp + [0.02, 0.08, 0.04]
    lm[finger_start + 2] = mcp + [0.03, 0.12, 0.06]
    lm[finger_start + 3] = mcp + [0.02, 0.14, 0.05]
    return lm


def _curl_thumb(landmarks: np.ndarray) -> np.ndarray:
    """Curl thumb across the palm."""
    lm = landmarks.copy()
    lm[2] = [0.38, 0.75, 0.03]
    lm[3] = [0.42, 0.72, 0.05]
    lm[4] = [0.45, 0.70, 0.04]
    return lm


def _make_fist(landmarks: np.ndarray) -> np.ndarray:
    """Close all fingers into a fist."""
    lm = landmarks.copy()
    lm = _curl_thumb(lm)
    for start in [5, 9, 13, 17]:  # index, middle, ring, pinky
        lm = _curl_finger(lm, start)
    return lm


def _point_index_only(landmarks: np.ndarray) -> np.ndarray:
    """Point with index finger, curl all others."""
    lm = _make_fist(landmarks)
    # Extend index finger
    base = landmarks.copy()
    lm[5] = base[5]
    lm[6] = base[6]
    lm[7] = base[7]
    lm[8] = base[8]
    return lm


def _thumbs_up(landmarks: np.ndarray) -> np.ndarray:
    """Thumb extended upward, all fingers curled."""
    lm = _make_fist(landmarks)
    # Extend thumb upward
    lm[1] = [0.38, 0.75, -0.02]
    lm[2] = [0.35, 0.62, -0.03]
    lm[3] = [0.33, 0.50, -0.02]
    lm[4] = [0.32, 0.40, -0.01]
    return lm


def _flat_palm_forward(landmarks: np.ndarray) -> np.ndarray:
    """Open palm pushed slightly forward (stop/halt gesture)."""
    lm = landmarks.copy()
    # Push all fingertips slightly forward in z
    for i in [4, 8, 12, 16, 20]:
        lm[i][2] -= 0.05
    return lm


def _wave_hand(landmarks: np.ndarray, phase: float = 0.0) -> np.ndarray:
    """Open hand tilted for waving gesture."""
    lm = landmarks.copy()
    angle = 0.15 * np.sin(phase)
    # Rotate fingers slightly around the wrist
    wrist = lm[0].copy()
    for i in range(1, 21):
        dx = lm[i][0] - wrist[0]
        dy = lm[i][1] - wrist[1]
        lm[i][0] = wrist[0] + dx * np.cos(angle) - dy * np.sin(angle)
        lm[i][1] = wrist[1] + dx * np.sin(angle) + dy * np.cos(angle)
    return lm


def _two_fingers_v(landmarks: np.ndarray) -> np.ndarray:
    """V-sign: index and middle extended, others curled."""
    lm = _make_fist(landmarks)
    base = landmarks.copy()
    # Extend index
    for i in [5, 6, 7, 8]:
        lm[i] = base[i]
    # Extend middle
    for i in [9, 10, 11, 12]:
        lm[i] = base[i]
    # Spread them apart slightly
    lm[8][0] -= 0.04
    lm[12][0] += 0.04
    return lm


def _palm_on_chest(landmarks: np.ndarray) -> np.ndarray:
    """Flat palm pressed to chest (I/me gesture)."""
    lm = landmarks.copy()
    # Bring hand closer to center, flatten
    for i in range(21):
        lm[i][0] = lm[i][0] * 0.6 + 0.2
        lm[i][2] += 0.1
    return lm


def _point_forward(landmarks: np.ndarray) -> np.ndarray:
    """Point forward (you gesture)."""
    lm = _point_index_only(landmarks)
    # Index finger points forward (z direction)
    lm[6][2] -= 0.08
    lm[7][2] -= 0.14
    lm[8][2] -= 0.20
    return lm


def _cupped_hand(landmarks: np.ndarray) -> np.ndarray:
    """Slightly cupped hand (water/drink gesture)."""
    lm = landmarks.copy()
    # Curl fingers slightly inward
    for start in [5, 9, 13, 17]:
        tip = start + 3
        lm[tip][0] = lm[tip][0] * 0.85 + lm[0][0] * 0.15
        lm[tip][1] = lm[tip][1] * 0.9 + 0.05
    return lm


def _cross_arms_marker(landmarks: np.ndarray) -> np.ndarray:
    """Both hands crossing (represented as compressed hand for single-hand model)."""
    lm = landmarks.copy()
    # Move fingers towards center and overlap
    for i in range(1, 21):
        lm[i][0] = lm[i][0] * 0.5 + 0.25
    return lm


def _rubbing_motion(landmarks: np.ndarray) -> np.ndarray:
    """Rubbing/circular motion (please gesture)."""
    lm = landmarks.copy()
    # Flat palm with slight circular offset
    center_x = np.mean([lm[i][0] for i in range(21)])
    for i in range(1, 21):
        lm[i][0] += (lm[i][0] - center_x) * 0.1
        lm[i][2] += 0.03
    return lm


def _shaking_hand(landmarks: np.ndarray) -> np.ndarray:
    """Side-to-side motion (no gesture)."""
    lm = _flat_palm_forward(landmarks)
    # Shift hand to the side
    for i in range(21):
        lm[i][0] += 0.1
    return lm


def _nodding_fist(landmarks: np.ndarray) -> np.ndarray:
    """Fist moving up/down (yes gesture)."""
    lm = _make_fist(landmarks)
    # Slight upward shift
    for i in range(21):
        lm[i][1] -= 0.05
    return lm


# ── Gesture → Canonical Landmark Mapping ──
def get_canonical_landmarks(gesture: str) -> np.ndarray:
    """Return a canonical (noiseless) landmark pattern for a gesture."""
    base = _base_hand()

    gesture_map = {
        "HELLO": lambda: _wave_hand(base),
        "THANK_YOU": lambda: _flat_palm_forward(base),
        "YES": lambda: _nodding_fist(base),
        "NO": lambda: _shaking_hand(base),
        "HELP": lambda: _cross_arms_marker(base),
        "HOSPITAL": lambda: _cross_arms_marker(
            _flat_palm_forward(base)
        ),
        "POLICE": lambda: _point_index_only(
            _flat_palm_forward(base)
        ),
        "FIRE": lambda: _wave_hand(
            _flat_palm_forward(base), phase=1.0
        ),
        "WATER": lambda: _cupped_hand(base),
        "FOOD": lambda: _cupped_hand(
            _make_fist(base)
        ),
        "PAIN": lambda: _make_fist(base),
        "EMERGENCY": lambda: _wave_hand(
            _cross_arms_marker(base), phase=2.0
        ),
        "PLEASE": lambda: _rubbing_motion(base),
        "SORRY": lambda: _rubbing_motion(
            _make_fist(base)
        ),
        "GOODBYE": lambda: _wave_hand(base, phase=3.14),
        "I": lambda: _palm_on_chest(base),
        "YOU": lambda: _point_forward(base),
        "WANT": lambda: _cupped_hand(
            _point_forward(base)
        ),
        "NEED": lambda: _nodding_fist(
            _point_index_only(base)
        ),
        "WHERE": lambda: _shaking_hand(
            _point_index_only(base)
        ),
    }

    if gesture not in gesture_map:
        raise ValueError(f"Unknown gesture: {gesture}")

    return gesture_map[gesture]()


def normalize_landmarks(landmarks: np.ndarray) -> np.ndarray:
    """
    Normalize landmarks: translate wrist to origin, scale by max distance.
    This makes the data invariant to hand position and scale in the frame.
    """
    wrist = landmarks[0].copy()
    centered = landmarks - wrist

    # Scale by max distance from wrist
    max_dist = np.max(np.linalg.norm(centered, axis=1))
    if max_dist > 1e-6:
        centered = centered / max_dist

    return centered


def add_noise(landmarks: np.ndarray, noise_std: float = 0.02) -> np.ndarray:
    """Add Gaussian noise to simulate real-world variation."""
    noise = np.random.normal(0, noise_std, landmarks.shape).astype(np.float32)
    return landmarks + noise


def add_scale_variation(landmarks: np.ndarray, scale_range: tuple = (0.8, 1.2)) -> np.ndarray:
    """Simulate different hand sizes / distances from camera."""
    scale = np.random.uniform(*scale_range)
    return landmarks * scale


def add_rotation_variation(landmarks: np.ndarray, max_angle_deg: float = 15.0) -> np.ndarray:
    """Apply small random rotation around the wrist (z-axis)."""
    angle = np.radians(np.random.uniform(-max_angle_deg, max_angle_deg))
    cos_a, sin_a = np.cos(angle), np.sin(angle)

    rotated = landmarks.copy()
    wrist = rotated[0].copy()

    for i in range(1, len(rotated)):
        dx = rotated[i][0] - wrist[0]
        dy = rotated[i][1] - wrist[1]
        rotated[i][0] = wrist[0] + dx * cos_a - dy * sin_a
        rotated[i][1] = wrist[1] + dx * sin_a + dy * cos_a

    return rotated


def generate_sample(gesture: str, noise_std: float = 0.02) -> np.ndarray:
    """Generate a single augmented sample for a gesture."""
    landmarks = get_canonical_landmarks(gesture)
    landmarks = add_rotation_variation(landmarks, max_angle_deg=15.0)
    landmarks = add_scale_variation(landmarks, scale_range=(0.8, 1.2))
    landmarks = add_noise(landmarks, noise_std=noise_std)
    landmarks = normalize_landmarks(landmarks)
    return landmarks.flatten()  # (63,)


def generate_dataset(
    samples_per_gesture: int = 300,
    noise_std: float = 0.02,
) -> tuple[np.ndarray, np.ndarray]:
    """
    Generate the full dataset.
    Returns (X, y) where X is (N, 63) and y is (N,) with string labels.
    """
    X_list = []
    y_list = []

    for gesture in GESTURE_LABELS:
        print(f"  Generating {samples_per_gesture} samples for '{gesture}'...")
        for _ in range(samples_per_gesture):
            sample = generate_sample(gesture, noise_std=noise_std)
            X_list.append(sample)
            y_list.append(gesture)

    X = np.array(X_list, dtype=np.float32)
    y = np.array(y_list)
    return X, y


def save_csv(X: np.ndarray, y: np.ndarray, filepath: str) -> None:
    """Save dataset as CSV with feature columns and label column."""
    header = [f"lm{i}_{c}" for i in range(NUM_LANDMARKS) for c in ("x", "y", "z")]
    header.append("label")

    with open(filepath, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(header)
        for features, label in zip(X, y):
            row = list(features) + [label]
            writer.writerow(row)

    print(f"  Saved {len(X)} samples to {filepath}")


def main():
    parser = argparse.ArgumentParser(description="Generate synthetic hand landmark data for gesture training")
    parser.add_argument("--samples", type=int, default=300, help="Samples per gesture (default: 300)")
    parser.add_argument("--noise", type=float, default=0.02, help="Noise std deviation (default: 0.02)")
    parser.add_argument("--output", type=str, default="gesture_landmarks.csv", help="Output CSV file path")
    args = parser.parse_args()

    print(f"\n{'='*60}")
    print("JARVIS — Synthetic Hand Landmark Data Generator")
    print(f"{'='*60}")
    print(f"Gestures: {len(GESTURE_LABELS)}")
    print(f"Samples per gesture: {args.samples}")
    print(f"Total samples: {len(GESTURE_LABELS) * args.samples}")
    print(f"Features per sample: {TOTAL_FEATURES}")
    print(f"Noise std: {args.noise}")
    print(f"Output: {args.output}")
    print(f"{'='*60}\n")

    X, y = generate_dataset(samples_per_gesture=args.samples, noise_std=args.noise)
    save_csv(X, y, args.output)

    print(f"\n[OK] Dataset generation complete!")
    print(f"   Shape: {X.shape}")
    print(f"   Labels: {np.unique(y).tolist()}")


if __name__ == "__main__":
    main()
