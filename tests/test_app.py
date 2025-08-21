from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_healthz():
    resp = client.get("/healthz")
    assert resp.status_code == 200
    assert resp.json()["status"] == "ok"

def test_analyze():
    payload = {"text": "I love cloud engineering!"}
    resp = client.post("/analyze", json=payload)
    assert resp.status_code == 200
    data = resp.json()
    assert data["original_text"] == payload["text"]
    assert data["word_count"] == 4
    # Character count includes spaces & punctuation
    assert data["character_count"] == len(payload["text"])
