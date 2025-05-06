from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from sentence_transformers import SentenceTransformer
import uvicorn
import subprocess
import threading
import time
import requests

app = FastAPI()
model = SentenceTransformer("all-MiniLM-L6-v2")

# Pydantic model
class EmbeddingRequest(BaseModel):
    user_id: str
    text: str
    type: str

@app.post("/generate-embedding")
async def generate_embedding(request: EmbeddingRequest):
    text = request.text
    if not text:
        raise HTTPException(status_code=400, detail="Text is required to generate embedding")
    
    try:
        embedding = model.encode(text).tolist()
        return {"embedding": embedding}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error generating embedding: {str(e)}")

def start_ngrok():
    try:
        # Start ngrok on port 8000
        subprocess.Popen(["ngrok", "http", "8000", "--domain=muskrat-star-midge.ngrok-free.app"])

        time.sleep(2)  # Wait for ngrok to initialize

        # Fetch the public URL from the ngrok API
        tunnel_info = requests.get("http://127.0.0.1:4040/api/tunnels").json()
        public_url = tunnel_info['tunnels'][0]['public_url']
        print(f"\n🌐 ngrok tunnel is live at: {public_url}/generate-embedding\n")
    except Exception as e:
        print(f"❌ Error starting ngrok: {e}")

if __name__ == "__main__":
    threading.Thread(target=start_ngrok).start()
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
 

# from fastapi import FastAPI, Request, HTTPException
# from pydantic import BaseModel
# from sentence_transformers import SentenceTransformer
# import uvicorn

# app = FastAPI()
# model = SentenceTransformer("all-MiniLM-L6-v2")

# # Define a Pydantic model for request validation
# class EmbeddingRequest(BaseModel):
#     user_id: str
#     text: str
#     type: str

# @app.post("/generate-embedding")
# async def generate_embedding(request: EmbeddingRequest):
#     text = request.text
#     # user_id = request.user_id
#     # type = request.type
#     if not text:
#         raise HTTPException(status_code=400, detail="Text is required to generate embedding")
    
#     try:
#         embedding = model.encode(text).tolist()
#         return {"embedding": embedding}
#     except Exception as e:
#         raise HTTPException(status_code=500, detail=f"Error generating embedding: {str(e)}")

# if __name__ == "__main__":
#     uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
