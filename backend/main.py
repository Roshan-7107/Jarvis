"""
JARVIS Backend — FastAPI Application
Main entry point for the JARVIS AI backend server.
"""

import os
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
from models.schemas import HealthResponse

load_dotenv()


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifecycle management."""
    print("[JARVIS] Backend starting...")
    print("[JARVIS] Loading AI services...")

    # Import routers here to trigger LLM initialization
    from routers import interpret, reverse, translate, gesture
    app.include_router(interpret.router)
    app.include_router(reverse.router)
    app.include_router(translate.router)
    app.include_router(gesture.router)

    print("[JARVIS] Backend ready!")
    yield
    print("[JARVIS] Backend shutting down...")


app = FastAPI(
    title="JARVIS Backend",
    description=(
        "Just-in-time AI Recognition & Vision-based Interaction System — "
        "Backend API for sign-language gesture interpretation, reverse communication, "
        "and multilingual translation."
    ),
    version="1.0.0",
    lifespan=lifespan,
)

# CORS configuration — allow Flutter app to connect
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, restrict to specific origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health", response_model=HealthResponse, tags=["system"])
async def health_check():
    """Health check endpoint."""
    return HealthResponse()


@app.get("/", tags=["system"])
async def root():
    """Root endpoint with service info."""
    return {
        "service": "JARVIS Backend",
        "version": "1.0.0",
        "description": "AI-powered sign-language communication assistant",
        "endpoints": {
            "health": "/health",
            "interpret": "POST /api/interpret",
            "reverse": "POST /api/reverse",
            "translate": "POST /api/translate",
            "docs": "/docs",
        },
    }


if __name__ == "__main__":
    import uvicorn

    host = os.getenv("HOST", "0.0.0.0")
    port = int(os.getenv("PORT", "8000"))
    uvicorn.run("main:app", host=host, port=port, reload=True)
