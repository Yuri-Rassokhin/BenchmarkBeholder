from fastapi import FastAPI, HTTPException, Request, Form
from pydantic import BaseModel
import os
import requests
import PyPDF2
import faiss
from sentence_transformers import SentenceTransformer
from fastapi.responses import JSONResponse

# Initialize the FastAPI app
app = FastAPI()

# Configuration for the LLAMA vLLM endpoint
LLAMA_API_ENDPOINT = "http://130.61.28.203:8000/v1/completions"  # Replace with your vLLM endpoint
MODEL_NAME = "meta-llama/Llama-3.3-70B-Instruct"  # Specify your LLAMA model name from vLLM /v1/models

# Load the embedding model
embedder = SentenceTransformer('all-MiniLM-L6-v2', device='cpu')

# Directory for PDF documents
PDF_DIR = "pdf_documents"  # Replace with your directory containing PDF files

# Input schema for validation
class QuestionRequest(BaseModel):
    question: str
    max_tokens: int = 100
    temperature: float = 0.1

@app.post("/llama/qa")
async def document_question_answering(request: QuestionRequest):
    try:
        question = request.question
        max_tokens = request.max_tokens
        temperature = request.temperature

        # Load FAISS index and metadata
        index = faiss.read_index("document_index.faiss")
        with open("file_metadata.txt", "r") as f:
            file_names = f.read().splitlines()

        # Generate embedding for the question
        question_embedding = embedder.encode([question])

        # Perform similarity search
        k = 3  # Number of top documents to retrieve
        distances, indices = index.search(question_embedding, k)
        relevant_docs = [file_names[i] for i in indices[0]]

        # Extract relevant document content
        context = ""
        for doc_file in relevant_docs:
            file_path = os.path.join(PDF_DIR, doc_file)
            with open(file_path, 'rb') as pdf_file:
                pdf_reader = PyPDF2.PdfReader(pdf_file)
                for page in pdf_reader.pages:
                    context += page.extract_text() + "\n"

        # Create the prompt for LLAMA
        prompt = f"""
You are an AI assistant trained to answer questions based on the provided documents. 
Here are the most relevant documents:

{context}

Now, answer the following question:

{question}
"""

        # Prepare the payload for the LLAMA API
        llama_payload = {
            "model": MODEL_NAME,
            "prompt": prompt,
            "max_tokens": max_tokens,
            "temperature": temperature,
            "stop": ["\n"]
        }

        # Send the request to the vLLM LLAMA endpoint
        response = requests.post(LLAMA_API_ENDPOINT, json=llama_payload)

        # Check for errors in the response
        if response.status_code != 200:
            raise HTTPException(status_code=response.status_code, detail=f"LLAMA API error: {response.text}")

        # Parse the response
        llama_response = response.json()
        answer = llama_response.get("choices", [{}])[0].get("text", "").strip()

        # Return the answer and relevant document names
        return {
            "question": question,
            "answer": answer,
            "relevant_documents": relevant_docs
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=3000)

