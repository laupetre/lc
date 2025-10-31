import os
import json
from typing import Optional, List
from fastapi import FastAPI, HTTPException, Header, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from boxsdk import OAuth2, Client


from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate


OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
if not OPENAI_API_KEY:
    raise RuntimeError("OPENAI_API_KEY is required (no Key Vault in this setup)")


MODEL = os.getenv("OPENAI_MODEL", "gpt-4o-mini")
ALLOWED_ORIGIN = os.getenv("ALLOWED_ORIGIN", "*") # set to your SWA URL in prod


llm = ChatOpenAI(model=MODEL, temperature=0)
SYSTEM = "You are a concise, helpful assistant."
prompt = ChatPromptTemplate.from_messages([("system", SYSTEM), ("human", "{input}")])
chain = prompt | llm | (lambda msg: msg.content)

# Initialize Box client
BOX_CLIENT_ID = os.getenv("BOX_CLIENT_ID")
BOX_CLIENT_SECRET = os.getenv("BOX_CLIENT_SECRET")
BOX_ACCESS_TOKEN = os.getenv("BOX_ACCESS_TOKEN")

box_client = None
if BOX_CLIENT_ID and BOX_CLIENT_SECRET and BOX_ACCESS_TOKEN:
    oauth2 = OAuth2(
        client_id=BOX_CLIENT_ID,
        client_secret=BOX_CLIENT_SECRET,
        access_token=BOX_ACCESS_TOKEN
    )
    box_client = Client(oauth2)


app = FastAPI(title="LangChain Chat API")
app.add_middleware(CORSMiddleware, allow_origins=[ALLOWED_ORIGIN] if ALLOWED_ORIGIN != "*" else ["*"],
allow_methods=["*"], allow_headers=["*"], allow_credentials=True)


# Optional: Authentication dependency (pass through if not configured)
async def get_current_user(x_ms_client_principal: Optional[str] = Header(None)):
    """Extract user information from SWA authentication header"""
    if not x_ms_client_principal:
        return None
    try:
        return json.loads(x_ms_client_principal)
    except:
        return None


class ChatIn(BaseModel):
    input: str
    system: Optional[str] = None


class ChatOut(BaseModel):
    output: str
    model: str


class BoxFile(BaseModel):
    id: str
    name: str
    type: str
    size: Optional[int] = None
    modified_at: Optional[str] = None


@app.get("/healthz")
def healthz():
    box_status = "enabled" if box_client else "disabled"
    return {"status": "ok", "model": MODEL, "box": box_status}


@app.post("/chat", response_model=ChatOut)
async def chat(body: ChatIn, user: Optional[dict] = Depends(get_current_user)):
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


@app.get("/box/files", response_model=List[BoxFile])
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


@app.post("/box/chat")
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