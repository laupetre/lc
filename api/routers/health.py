"""
Health check endpoint
"""
from fastapi import APIRouter
from config import MODEL, box_client

router = APIRouter()


@router.get("/healthz")
def healthz():
    """Health check endpoint"""
    box_status = "enabled" if box_client else "disabled"
    return {"status": "ok", "model": MODEL, "box": box_status}

