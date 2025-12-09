"""
FastAPI dependencies
"""
import json
from typing import Optional
from fastapi import Header


async def get_current_user(x_ms_client_principal: Optional[str] = Header(None)):
    """Extract user information from SWA authentication header"""
    if not x_ms_client_principal:
        return None
    try:
        return json.loads(x_ms_client_principal)
    except:
        return None

