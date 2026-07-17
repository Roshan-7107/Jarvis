from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from services.gesture_service import gesture_service
import cv2
import numpy as np
import base64
import json

router = APIRouter(prefix="/ws", tags=["gesture"])

@router.websocket("/gesture")
async def gesture_endpoint(websocket: WebSocket):
    await websocket.accept()
    
    try:
        while True:
            # Receive base64 string from client
            data = await websocket.receive_text()
            
            # Decode base64 to bytes
            image_bytes = base64.b64decode(data)
            
            # Convert bytes to numpy array
            nparr = np.frombuffer(image_bytes, np.uint8)
            
            # Decode numpy array into OpenCV image
            img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
            
            if img is not None:
                # Process the frame
                coords, gesture, confidence = gesture_service.process_frame(img)
                
                # Send result back
                await websocket.send_json({
                    "landmarks": coords,
                    "gesture": gesture,
                    "confidence": confidence
                })
            else:
                await websocket.send_json({"error": "Invalid frame"})
                
    except WebSocketDisconnect:
        print("Client disconnected")
    except Exception as e:
        print(f"Error in gesture websocket: {e}")
        try:
            await websocket.close()
        except:
            pass
