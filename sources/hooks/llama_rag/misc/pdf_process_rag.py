from flask import Flask, request, jsonify
import os
import requests
import PyPDF2
import faiss
from sentence_transformers import SentenceTransformer

# Initialize the Flask app
flask_app = Flask(__name__)

# Configuration for the LLAMA vLLM endpoint
LLAMA_API_ENDPOINT = "http://130.61.28.203:8000/v1/completions"  # Replace with your vLLM endpoint
MODEL_NAME = "meta-llama/Llama-3.3-70B-Instruct"  # Specify your LLAMA model name from vLLM /v1/models

# Load the embedding model
embedder = SentenceTransformer('all-MiniLM-L6-v2')

# Directory for PDF documents
PDF_DIR = "pdf_documents"  # Replace with your directory containing PDF files

@flask_app.route('/llama/qa', methods=['POST'])
def document_question_answering():
    try:
        # Check if question is provided
        if 'question' not in request.form:
            return jsonify({"error": "Please provide a question."}), 400

        question = request.form['question']
        max_tokens = int(request.form.get('max_tokens', 200))
        temperature = float(request.form.get('temperature', 0.7))

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
            return jsonify({"error": f"LLAMA API error: {response.text}"}), response.status_code

        # Parse the response
        llama_response = response.json()
        answer = llama_response.get("choices", [{}])[0].get("text", "").strip()

        # Return the answer and relevant document names
        return jsonify({
            "question": question,
            "answer": answer,
            "relevant_documents": relevant_docs
        })

    except Exception as e:
        return jsonify({"error": str(e)}), 500


if __name__ == '__main__':
    flask_app.run(host='0.0.0.0', port=3000)

