"""
Configuration and initialization for the application
"""
import os
from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate


# Environment variables
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
if not OPENAI_API_KEY:
    raise RuntimeError("OPENAI_API_KEY is required (no Key Vault in this setup)")

MODEL = os.getenv("OPENAI_MODEL", "gpt-4o-mini")
ALLOWED_ORIGIN = os.getenv("ALLOWED_ORIGIN", "*")

# Box configuration
BOX_CLIENT_ID = os.getenv("BOX_CLIENT_ID")
BOX_CLIENT_SECRET = os.getenv("BOX_CLIENT_SECRET")
BOX_ACCESS_TOKEN = os.getenv("BOX_ACCESS_TOKEN")

# Initialize LangChain
llm = ChatOpenAI(model=MODEL, temperature=0)
SYSTEM = "You are a concise, helpful assistant."
prompt = ChatPromptTemplate.from_messages([("system", SYSTEM), ("human", "{input}")])
chain = prompt | llm | (lambda msg: msg.content)

# Initialize Box client (optional)
box_client = None
if BOX_CLIENT_ID and BOX_CLIENT_SECRET and BOX_ACCESS_TOKEN:
    try:
        from boxsdk import OAuth2, Client
        oauth2 = OAuth2(
            client_id=BOX_CLIENT_ID,
            client_secret=BOX_CLIENT_SECRET,
            access_token=BOX_ACCESS_TOKEN
        )
        box_client = Client(oauth2)
    except ImportError:
        print("Warning: boxsdk not installed. Box integration disabled.")
        box_client = None

