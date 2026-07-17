import cv2
import mediapipe as mp
import numpy as np
import tensorflow as tf
import os
import json

class GestureService:
    def __init__(self):
        # Initialize MediaPipe Hands
        self.mp_hands = mp.solutions.hands
        self.hands = self.mp_hands.Hands(
            static_image_mode=False,
            max_num_hands=1,
            min_detection_confidence=0.5,
            min_tracking_confidence=0.5
        )
        
        # Load TFLite Model
        model_path = os.path.join(os.path.dirname(__file__), '..', 'gesture_training', 'output', 'gesture_classifier.tflite')
        self.interpreter = tf.lite.Interpreter(model_path=model_path)
        self.interpreter.allocate_tensors()
        self.input_details = self.interpreter.get_input_details()
        self.output_details = self.interpreter.get_output_details()
        
        # Load Labels
        labels_path = os.path.join(os.path.dirname(__file__), '..', 'gesture_training', 'output', 'gesture_labels.json')
        with open(labels_path, 'r') as f:
            self.labels = json.load(f)
            
    def process_frame(self, image_np):
        """
        Process a BGR image numpy array.
        Returns:
            - landmarks: list of (x, y) dicts
            - gesture: string label or None
            - confidence: float
        """
        # Convert BGR to RGB
        image_rgb = cv2.cvtColor(image_np, cv2.COLOR_BGR2RGB)
        
        # Process with MediaPipe
        results = self.hands.process(image_rgb)
        
        if not results.multi_hand_landmarks:
            return None, None, 0.0
            
        hand_landmarks = results.multi_hand_landmarks[0]
        
        # Extract coordinates for UI
        coords = [{'x': lm.x, 'y': lm.y} for lm in hand_landmarks.landmark]
        
        # Extract normalized features for TFLite
        features = self._normalize_landmarks(hand_landmarks.landmark)
        
        # Run TFLite inference
        input_data = np.array([features], dtype=np.float32)
        self.interpreter.set_tensor(self.input_details[0]['index'], input_data)
        self.interpreter.invoke()
        output_data = self.interpreter.get_tensor(self.output_details[0]['index'])[0]
        
        # Get top prediction
        max_idx = np.argmax(output_data)
        confidence = float(output_data[max_idx])
        gesture = self.labels[max_idx]
        
        return coords, gesture, confidence
        
    def _normalize_landmarks(self, landmarks):
        """Convert landmarks to relative distances from wrist (same as training data)"""
        wrist_x = landmarks[0].x
        wrist_y = landmarks[0].y
        wrist_z = landmarks[0].z
        
        features = []
        for lm in landmarks:
            features.extend([
                lm.x - wrist_x,
                lm.y - wrist_y,
                lm.z - wrist_z
            ])
            
        return features

gesture_service = GestureService()
