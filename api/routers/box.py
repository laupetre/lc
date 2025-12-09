"""
Box integration endpoints
"""
from typing import Optional, List
from fastapi import APIRouter, HTTPException
from models import ChatIn, ChatOut, BoxFile
from config import box_client, llm, chain, MODEL
from langchain_core.prompts import ChatPromptTemplate

router = APIRouter()


@router.get("/box/files", response_model=List[BoxFile])
async def get_box_files(folder_id: str = "0"):
    """List files in a Box folder"""
    if not box_client:
        raise HTTPException(status_code=503, detail="Box integration not configured")
    try:
        folder = box_client.folder(folder_id)
        items = folder.get_items()
        files = []
        for item in items:
            files.append(BoxFile(
                id=item.id,
                name=item.name,
                type=item.type,
                size=getattr(item, 'size', None),
                modified_at=str(item.modified_at) if hasattr(item, 'modified_at') else None
            ))
        return files
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/box/chat")
async def chat_with_box(body: ChatIn, file_id: Optional[str] = None):
    """Chat with AI using Box file context"""
    if not box_client:
        raise HTTPException(status_code=503, detail="Box integration not configured")
    
    try:
        context = ""
        if file_id:
            file = box_client.file(file_id)
            # Get file content (if text file)
            if file.content and hasattr(file, 'content'):
                content = file.get_content().decode('utf-8')
                context = f"Box File Context:\n{content}\n\n"
        
        prompt_text = f"{context}User Question: {body.input}"
        
        if body.system:
            local_prompt = ChatPromptTemplate.from_messages([("system", body.system), ("human", "{input}")])
            local_chain = local_prompt | llm | (lambda msg: msg.content)
            out = await local_chain.ainvoke({"input": prompt_text})
        else:
            out = await chain.ainvoke({"input": prompt_text})
        
        return ChatOut(output=out, model=MODEL)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

