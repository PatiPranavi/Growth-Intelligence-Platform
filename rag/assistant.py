import os
import streamlit as st

from google import genai

from .retriever import retrieve


# Connect to Gemini using the API key
api_key = os.environ.get("GEMINI_API_KEY")

if not api_key:
    api_key = st.secrets["GEMINI_API_KEY"]

client = genai.Client(
    api_key=api_key
)


MODEL_NAME = "gemini-3.7-flash"


def ask_assistant(question, top_k=3):
    """
    Retrieve relevant project knowledge and
    generate an answer using Gemini.
    """

    # Step 1: Retrieve relevant knowledge
    results = retrieve(question, top_k=top_k)

    # Step 2: Build the context for Gemini
    context = "\n\n".join(
        [
            f"Topic: {result['topic']}\n"
            f"Information: {result['content']}"
            for result in results
        ]
    )

    # Step 3: Create the prompt
    prompt = f"""
You are the Analytics Intelligence Assistant
for the Growth Intelligence Platform.

Answer the user's question using ONLY the
project knowledge provided below.

If the provided knowledge does not contain
enough information to answer the question,
say that the information is not available
in the project knowledge.

Do not invent numbers, metrics, or business
facts.

Project knowledge:
{context}

User question:
{question}
"""

    # Step 4: Ask Gemini to generate the answer
    try:
        response = client.models.generate_content(
            model=MODEL_NAME,
            contents=prompt
        )

        return response.text

    except Exception as e:
        print(f"\nGemini API error: {e}")
        return "Gemini is temporarily unavailable. Please try again in a moment."

   