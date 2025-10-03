import os
from typing import Optional
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel


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


app = FastAPI(title="LangChain Chat API")
app.add_middleware(CORSMiddleware, allow_origins=[ALLOWED_ORIGIN] if ALLOWED_ORIGIN != "*" else ["*"],
allow_methods=["*"], allow_headers=["*"], allow_credentials=False)


class ChatIn(BaseModel):
input: str
system: Optional[str] = None


class ChatOut(BaseModel):
output: str
model: str


@app.get("/healthz")
def healthz():
return {"status": "ok", "model": MODEL}


@app.post("/chat", response_model=ChatOut)
async def chat(body: ChatIn):
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