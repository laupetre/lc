"""
Chat endpoints
"""
from typing import Optional
from fastapi import APIRouter, HTTPException, Depends
from models import ChatIn, ChatOut
from dependencies import get_current_user
from config import llm, chain, MODEL
from langchain_core.prompts import ChatPromptTemplate

router = APIRouter()


@router.post("/chat", response_model=ChatOut)
async def chat(body: ChatIn, user: Optional[dict] = Depends(get_current_user)):
    """Chat with AI assistant"""
    # Optional: Log authenticated user
    if user:
        print(f"Authenticated request from: {user.get('userDetails', 'Unknown')}")
    try:
        if body.system:
            local_prompt = ChatPromptTemplate.from_messages([("system", body.system), ("human", "{input}")])
            local_chain = local_prompt | llm | (lambda msg: msg.content)
            out = await local_chain.ainvoke({"input": body.input})
        else:
            out = await chain.ainvoke({"input": body.input})
        return ChatOut(output=out, model=MODEL)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

