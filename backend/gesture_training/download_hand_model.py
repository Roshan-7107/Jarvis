"""
JARVIS — Download MediaPipe Hand Landmark TFLite Models
Downloads the palm_detection and hand_landmark TFLite models separately
for direct use with tflite_flutter.

Usage:
    python download_hand_model.py
"""

import argparse
import os
import sys
import urllib.request

# MediaPipe Palm Detection model (TFLite, ~2MB)
# Detects hand presence and bounding box in the frame
PALM_DETECTION_URL = (
    "https://storage.googleapis.com/mediapipe-assets/"
    "palm_detection_lite.tflite"
)

# MediaPipe Hand Landmark model (TFLite, ~3MB)
# Extracts 21 3D landmarks from a cropped hand region
HAND_LANDMARK_URL = (
    "https://storage.googleapis.com/mediapipe-assets/"
    "hand_landmark_lite.tflite"
)


def download_file(url: str, output_path: str) -> None:
    """Download a file with progress reporting."""
    print(f"  Downloading: {url}")
    print(f"  Saving to:   {output_path}")

    os.makedirs(os.path.dirname(output_path) or ".", exist_ok=True)

    def progress_hook(block_num, block_size, total_size):
        downloaded = block_num * block_size
        if total_size > 0:
            percent = min(100, downloaded * 100 / total_size)
            mb_downloaded = downloaded / (1024 * 1024)
            mb_total = total_size / (1024 * 1024)
            print(f"\r  Progress: {percent:.1f}% ({mb_downloaded:.1f}/{mb_total:.1f} MB)", end="", flush=True)

    try:
        urllib.request.urlretrieve(url, output_path, reporthook=progress_hook)
        print()  # newline after progress

        size_kb = os.path.getsize(output_path) / 1024
        print(f"  [OK] Downloaded ({size_kb:.1f} KB)")
    except Exception as e:
        print(f"\n  [ERROR] Download failed: {e}")
        print(f"  You may need to download manually from:")
        print(f"    {url}")
        return


def main():
    parser = argparse.ArgumentParser(description="Download MediaPipe hand models")
    parser.add_argument(
        "--output-dir",
        type=str,
        default="../../assets/models",
        help="Output directory for model files",
    )
    args = parser.parse_args()

    print(f"\n{'='*60}")
    print("JARVIS -- Download MediaPipe Hand Detection Models")
    print(f"{'='*60}\n")

    # Download palm detection model
    palm_path = os.path.join(args.output_dir, "palm_detection_lite.tflite")
    print("[1/2] Palm Detection Model:")
    download_file(PALM_DETECTION_URL, palm_path)

    # Download hand landmark model
    landmark_path = os.path.join(args.output_dir, "hand_landmark_lite.tflite")
    print(f"\n[2/2] Hand Landmark Model:")
    download_file(HAND_LANDMARK_URL, landmark_path)

    print(f"\n{'='*60}")
    print("Done! Models are ready in the Flutter assets directory.")
    print(f"{'='*60}\n")

    # Also remove the old .task file if it exists
    old_task = os.path.join(args.output_dir, "hand_landmarker.tflite")
    if os.path.exists(old_task) and os.path.getsize(old_task) > 5 * 1024 * 1024:
        os.remove(old_task)
        print(f"  Removed old task bundle: {old_task}")


if __name__ == "__main__":
    main()
