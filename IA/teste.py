import requests
from sentence_transformers import SentenceTransformer

print("Requests OK")

modelo = SentenceTransformer("paraphrase-multilingual-MiniLM-L12-v2")

print("Modelo OK")