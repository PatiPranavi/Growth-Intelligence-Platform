import json
import os

from sentence_transformers import SentenceTransformer
import numpy as np


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

texts = [
    f"{doc['topic']}: {doc['content']}"
    for doc in documents
]


# Load embedding model
model = SentenceTransformer("all-MiniLM-L6-v2")


# Generate embeddings
embeddings = model.encode(
    texts,
    convert_to_numpy=True,
    normalize_embeddings=True
)


# Save embeddings
np.save(EMBEDDINGS_PATH, embeddings)

print(f"Created embeddings for {len(texts)} documents.")
print(f"Embedding shape: {embeddings.shape}")
print(f"Saved to: {EMBEDDINGS_PATH}")