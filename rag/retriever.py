import json
import os

import faiss
import numpy as np
from sentence_transformers import SentenceTransformer


# Paths
BASE_DIR = os.path.dirname(os.path.abspath(__file__))

KNOWLEDGE_PATH = os.path.join(
    BASE_DIR,
    "knowledge_base",
    "analytics_knowledge.json"
)

EMBEDDINGS_PATH = os.path.join(
    BASE_DIR,
    "knowledge_base",
    "embeddings.npy"
)


# Load knowledge base
with open(KNOWLEDGE_PATH, "r", encoding="utf-8") as file:
    knowledge_base = json.load(file)

documents = knowledge_base["documents"]


# Load saved embeddings
embeddings = np.load(EMBEDDINGS_PATH).astype("float32")


# Create FAISS index
dimension = embeddings.shape[1]

index = faiss.IndexFlatIP(dimension)
index.add(embeddings)


# Load embedding model
model = SentenceTransformer("all-MiniLM-L6-v2")


def retrieve(query, top_k=3):
    """
    Retrieve the most relevant knowledge documents
    for a user's question.
    """

    # Convert user question into an embedding
    query_embedding = model.encode(
        [query],
        convert_to_numpy=True,
        normalize_embeddings=True
    ).astype("float32")

    # Search FAISS
    scores, indices = index.search(query_embedding, top_k)

    results = []

    for score, idx in zip(scores[0], indices[0]):
        if idx == -1:
            continue

        results.append({
            "score": float(score),
            "topic": documents[idx]["topic"],
            "content": documents[idx]["content"]
        })

    return results


# Test retrieval
if __name__ == "__main__":

    question = "Which category performs best?"

    results = retrieve(question, top_k=3)

    print("\nQuery:", question)
    print("\nRetrieved knowledge:\n")

    for result in results:
        print(f"Score: {result['score']:.4f}")
        print(f"Topic: {result['topic']}")
        print(f"Content: {result['content']}")
        print("-" * 60)