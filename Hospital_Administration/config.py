import os
import firebase_admin
from firebase_admin import credentials, firestore

# Get the directory of the current file (config.py)
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
key_path = os.path.join(BASE_DIR, "serviceAccountKey.json")

cred = credentials.Certificate(key_path)
firebase_admin.initialize_app(cred)

db = firestore.client()