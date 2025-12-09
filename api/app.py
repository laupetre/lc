"""
Main FastAPI application
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from config import ALLOWED_ORIGIN
from routers import health, chat, box

app = FastAPI(title="LangChain Chat API")

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=[ALLOWED_ORIGIN] if ALLOWED_ORIGIN != "*" else ["*"],
    allow_methods=["*"],
    allow_headers=["*"],
    allow_credentials=True
)

# Include routers
app.include_router(health.router)
app.include_router(chat.router)
app.include_router(box.router)
