# from fastapi import FastAPI, Request
# from sentence_transformers import SentenceTransformer
# import numpy as np
# import uvicorn

# app = FastAPI()
# model = SentenceTransformer("all-MiniLM-L6-v2")

# @app.post("/generate-embedding")
# async def generate_embedding(request: Request):
#     data = await request.json()
#     text = data.get("text", "")
#     embedding = model.encode(text).tolist()
#     return {"embedding": embedding}

# if __name__ == "__main__":
#     uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)

from fastapi import FastAPI, Request, HTTPException
from pydantic import BaseModel
from sentence_transformers import SentenceTransformer
import uvicorn

app = FastAPI()
model = SentenceTransformer("all-MiniLM-L6-v2")

# Define a Pydantic model for request validation
class EmbeddingRequest(BaseModel):
    user_id: str
    text: str
    type: str

@app.post("/generate-embedding")
async def generate_embedding(request: EmbeddingRequest):
    text = request.text
    # user_id = request.user_id
    # type = request.type
    if not text:
        raise HTTPException(status_code=400, detail="Text is required to generate embedding")
    
    try:
        embedding = model.encode(text).tolist()
        return {"embedding": embedding}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error generating embedding: {str(e)}")

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
