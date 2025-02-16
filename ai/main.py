from fastapi import FastAPI, HTTPException, Security, Depends
from fastapi.security import APIKeyHeader
from typing import Dict, List
from pydantic import BaseModel, Field
from fastapi.responses import JSONResponse
import logging
from openai import OpenAI
from textwrap import dedent
import json
import os
from dotenv import load_dotenv
from pymongo import MongoClient
import numpy as np

# Load environment variables
load_dotenv()

# Initialize MongoDB client
MONGO_URI = os.getenv('MONGO_URI', 'mongodb://localhost:27017')
client_mongo = MongoClient(MONGO_URI)
db = client_mongo['trusty_social']
professionals_collection = db['professionals']

# Initialize OpenAI client
client = OpenAI(api_key=os.getenv('OPENAI_API_KEY'))
MODEL = "gpt-4o-mini"
EMBEDDING_MODEL = "text-embedding-3-small"

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="Trusty Social API",
    description="API for searching professionals based on their capabilities",
    version="1.0.0",
    openapi_tags=[
        {
            "name": "Search Professionals",
            "description": "Operations for searching professionals"
        }
    ]
)

# Configure API Key security scheme
app.openapi_tags = [
    {
        "name": "Search Professionals",
        "description": "Search operations"
    }
]

app.openapi_components = {
    "securitySchemes": {
        "ApiKeyAuth": {
            "type": "apiKey",
            "in": "header",
            "name": "Authorization",
            "description": "Enter your API key with Bearer prefix, e.g.: 'Bearer your-api-key'"
        }
    }
}

app.openapi_security = [
    {
        "ApiKeyAuth": []
    }
]


API_KEY = os.getenv('API_KEY')
if not API_KEY:
    raise ValueError("API_KEY environment variable is not set")

api_key_header = APIKeyHeader(name="Authorization", auto_error=True)

class SearchResponse(BaseModel):
    response: str
    users: List[Dict[str, str]]

class SearchQuery(BaseModel):
    query: str = Field(
        description="Search query to find professionals",
        examples=["I need a software developer with AI experience", "Looking for an SEO specialist"]
    )

async def verify_api_key(api_key: str = Security(api_key_header)):
    """Verifies the API key."""
    if not api_key.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Invalid API key format")
    token = api_key.split(" ")[1]
    if token != API_KEY:
        raise HTTPException(status_code=401, detail="Invalid API key")
    return token

async def get_embedding(text: str) -> List[float]:
    """Get embedding for the given text using OpenAI's API."""
    try:
        response = client.embeddings.create(
            model=EMBEDDING_MODEL,
            input=text
        )
        return response.data[0].embedding
    except Exception as e:
        logger.error(f"Error getting embedding: {e}")
        raise HTTPException(status_code=500, detail="Error getting embedding")

async def get_similar_professionals(query: str) -> Dict[str, str]:
    """Get similar professionals using vector similarity search."""
    try:
        # Get query embedding
        query_embedding = await get_embedding(query)
        
        # Perform vector similarity search
        similar_professionals = professionals_collection.aggregate([
            {
                "$search": {
                    "index": "default",
                    "knnBeta": {
                        "vector": query_embedding,
                        "path": "embedding",
                        "k": 10
                    }
                }
            }
        ])

        # Convert results to knowledge base format
        knowledge_base = {}
        for prof in similar_professionals:
            knowledge_base[prof['userId']] = prof['description']
        
        return knowledge_base
    except Exception as e:
        logger.error(f"Error in vector search: {e}")
        return {}

# SAMPLE KNOWLEDGE BASE
# KNOWLEDGE_BASE = {
#     "QiAQMXOTPkPaHVs8XipZkw0hJH52": (
#         "Can Göymen is an expert in artificial intelligence and modern software "
#         "development technologies. He uses Django and FastAPI for backend development and "
#         "React and Flutter for frontend. He effectively manages cloud technologies with tools "
#         "like AWS, Docker, and Kubernetes. In AI projects, he is highly skilled in data processing, "
#         "model training, customizing models like YOLO, and even developing AI as a Service (AIaaS) solutions. "
#         "He applies the Scrum methodology using Jira and Slack for project management and works across a wide range "
#         "of areas, from social media platforms to Telco projects. Additionally, he has experience with system monitoring "
#         "tools (Prometheus, Grafana) and SSL security configurations."
#     ),
#     "lOBA2aMmlGZNQxRRCLtZfWbBtp12": (
#         "Nurgül Göymen is an experienced Senior SEO Specialist with over six years of expertise in digital marketing "
#         "and SEO. She currently holds a senior position at NMQ Digital, where she has been instrumental in enhancing search "
#         "engine optimization strategies for renowned clients like Philips. With a strong academic background in Translation "
#         "and Interpreting from Beykent University, Nurgül combines her linguistic skills in English, Italian, and Turkish with "
#         "her technical expertise to deliver impactful results. She is certified in advanced SEO techniques, including link building, "
#         "e-commerce site optimization, and using Semrush SEO tools. Her diverse experience includes roles as a content specialist "
#         "and translator, showcasing her ability to adapt and excel in various facets of digital services and marketing."
#     ),
#     "GOESkP2m9zfKNc6btmkgmEHo9Cy2": (
#         "Osman Emre Çalışkan is a dedicated and solution-oriented developer with a strong academic foundation in computer "
#         "science from Bilecik Şeyh Edebali University. His professional experience includes internships at Turkcell, where he worked "
#         "on Ansible automation, storage solutions, and developed REST APIs using Python. Emre has hands-on expertise in technologies "
#         "such as Python, Django, Linux, REST API, and data analysis with Pandas, complemented by his knowledge of Java, C++, and Spring Boot. "
#         "He also contributed to web development projects, such as creating the website for Nart Plastik. With a passion for learning and a "
#         "strong work ethic, Emre continues to build his technical skills while pursuing innovative projects."
#     ),
# }

# Structured output schema for OpenAI
SEARCH_PROMPT = '''
    You are an Trusty Social Mobile App assistant helping match users with professionals based on their capabilities.
    You will be given a query and a knowledge base. Your task is to return a JSON object
    containing:
    - `response`: A natural language explanation about the most relevant professionals for the query. Max 200 character.
    - `users`: A list of user IDs (userId) that match the query.

    Here is the knowledge base:
    {knowledge_base}
'''

SEARCH_SCHEMA = {
    "type": "json_schema",
    "json_schema": {
        "name": "search_response",
        "schema": {
            "type": "object",
            "properties": {
                "response": {"type": "string"},
                "users": {
                    "type": "array",
                    "items": {
                        "type": "object",
                        "properties": {
                            "userId": {"type": "string"}
                        },
                        "required": ["userId"],
                        "additionalProperties": False  # Disallow additional properties
                    }
                }
            },
            "required": ["response", "users"],
            "additionalProperties": False  # Disallow additional properties in the root object
        },
        "strict": True
    }
}

async def query_openai(query: str) -> Dict:
    """Queries OpenAI API and returns structured output."""
    # Get similar professionals using vector search
    knowledge_base = await get_similar_professionals(query)
    
    # Format prompt with knowledge base
    prompt = dedent(SEARCH_PROMPT.format(knowledge_base=knowledge_base))
    try:
        response = client.chat.completions.create(
            model=MODEL,
            messages=[
                {"role": "system", "content": prompt},
                {"role": "user", "content": query}
            ],
            response_format=SEARCH_SCHEMA
        )
        raw_content = response.choices[0].message.content
        logger.info(f"Raw AI response: {raw_content}")
        parsed_content = json.loads(raw_content)  # Convert JSON string to Python dict

        return parsed_content
    except OpenAI.error.AuthenticationError:
        logger.error("Invalid OpenAI API key.")
        raise HTTPException(status_code=401, detail="Invalid OpenAI API key.")
    except OpenAI.error.RateLimitError:
        logger.error("Rate limit exceeded.")
        raise HTTPException(status_code=429, detail="Rate limit exceeded.")
    except OpenAI.error.Timeout:
        logger.error("Request timed out.")
        raise HTTPException(status_code=504, detail="OpenAI API request timed out.")
    except Exception as e:
        logger.error(f"Unexpected OpenAI API error: {e}")
        raise HTTPException(status_code=500, detail=f"Unexpected OpenAI error: {e}")

@app.post("/trusty/api/v1/searchprofessional", response_model=SearchResponse, tags=["Search Professionals"])
async def search_professional(query: SearchQuery, api_key: str = Depends(verify_api_key)):
    """Searches for professionals based on the query."""
    ai_response = await query_openai(query.get("query"))

    # Parse the response
    response_data = {
        "response": ai_response["response"],
        "users": ai_response["users"]
    }
    return JSONResponse(
        content=response_data,
        headers={"Content-Type": "application/json; charset=utf-8"}
    )

# Checklist Schema for OpenAI
CHECKLIST_SCHEMA = {
    "type": "json_schema",
    "json_schema": {
        "name": "checklist_response",
        "schema": {
            "type": "object",
            "properties": {
                "title": {"type": "string"},
                "description": {"type": "string"},
                "items": {
                    "type": "array",
                    "items": {
                        "type": "object",
                        "properties": {
                            "id": {"type": "string"},
                            "task": {"type": "string"},
                            "category": {"type": "string"},
                            "priority": {"type": "string", "enum": ["high", "medium", "low"]}
                        },
                        "required": ["id", "task", "category", "priority"],
                        "additionalProperties": False
                    }
                }
            },
            "required": ["title", "description", "items"],
            "additionalProperties": False
        },
        "strict": True
    }
}

CHECKLIST_PROMPT = '''
    You are a helpful assistant creating detailed checklists based on user queries.
    Generate a comprehensive checklist with relevant items organized by categories.
    Return a JSON object containing:
    - `title`: A short title for the checklist
    - `description`: A brief description of the checklist (max 200 characters)
    - `items`: An array of checklist items, each with:
        - `id`: A unique string identifier
        - `task`: The specific task or item to check
        - `category`: The category this item belongs to
        - `priority`: Priority level (high/medium/low)

    Make sure to:
    1. Be specific and practical
    2. Cover all important aspects
    3. Organize items logically by categories
    4. Assign appropriate priority levels
    5. Include essential safety considerations for each relevant category:
       - Personal safety (emergency contacts, medical needs)
       - Transportation safety (vehicle checks, safe routes)
       - Accommodation safety (hotel security, emergency exits)
       - Document safety (copies of important documents)
       - Health safety (first aid kit, medications)
       - Location safety (local emergency numbers, safe areas)
'''

class ChecklistQuery(BaseModel):
    query: str = Field(
        description="Query to generate a checklist",
        examples=["What should I check before going on vacation?", "Moving to a new house checklist"]
    )

class ChecklistItem(BaseModel):
    id: str
    task: str
    category: str
    priority: str

class ChecklistResponse(BaseModel):
    title: str
    description: str
    items: List[ChecklistItem]

async def query_openai_checklist(query: str) -> Dict:
    """Queries OpenAI API and returns structured checklist output."""
    try:
        response = client.chat.completions.create(
            model=MODEL,
            messages=[
                {"role": "system", "content": CHECKLIST_PROMPT},
                {"role": "user", "content": query}
            ],
            response_format=CHECKLIST_SCHEMA
        )
        raw_content = response.choices[0].message.content
        logger.info(f"Raw AI checklist response: {raw_content}")
        return json.loads(raw_content)
    except Exception as e:
        logger.error(f"Error in checklist generation: {e}")
        raise HTTPException(status_code=500, detail=f"Error generating checklist: {str(e)}")

@app.post("/trusty/api/v1/checklist", response_model=ChecklistResponse, tags=["Checklists"])
async def generate_checklist(query: ChecklistQuery, api_key: str = Depends(verify_api_key)):
    """Generates a checklist based on the user's query."""
    try:
        checklist = await query_openai_checklist(query.query)
        return JSONResponse(
            content=checklist,
            headers={"Content-Type": "application/json; charset=utf-8"}
        )
    except Exception as e:
        logger.error(f"Error in checklist endpoint: {e}")
        raise HTTPException(status_code=500, detail=str(e))