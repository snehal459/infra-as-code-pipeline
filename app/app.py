import os
from flask import Flask

app = Flask(__name__)

@app.route("/")
def home():
    return "Hello from ECS 🚀"

@app.route("/health")
def health():
    return "OK", 200

if __name__ == "__main__":
    app.run(host=os.getenv("FLASK_HOST", "127.0.0.1"), port=5000)