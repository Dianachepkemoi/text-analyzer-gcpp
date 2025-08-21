from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

app = FastAPI(title="Insight-Agent", version="0.1.0")

class AnalyzeRequest(BaseModel):
    text: str = Field(..., min_length=1, description="Text to analyze")

class AnalyzeResponse(BaseModel):
    original_text: str
    word_count: int
    character_count: int

@app.get("/healthz")
def healthz():
    return {"status": "ok"}

@app.post("/analyze", response_model=AnalyzeResponse)
def analyze(payload: AnalyzeRequest):
    try:
        text = payload.text
        word_count = len(text.strip().split())
        # Character count includes all characters, including spaces & punctuation
        character_count = len(text)
        return AnalyzeResponse(
            original_text=text,
            word_count=word_count,
            character_count=character_count
        )
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
