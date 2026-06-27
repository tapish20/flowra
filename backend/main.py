from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
# pyrefly: ignore [missing-import]
from pydantic import BaseModel
import os
# pyrefly: ignore [missing-import]
import httpx
from pathlib import Path
from typing import List

app = FastAPI(title="Flowra AI Insights")

app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"^https?://(localhost|127\.0\.0\.1)(:\d+)?$",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class HealthLog(BaseModel):
    timestamp: str
    mood: str | int
    moodIntensity: int | None = None
    energy: int
    painIntensity: int
    painLocation: str = ""
    notes: str = ""


class Cycle(BaseModel):
    id: str | None = None
    startDate: str
    cycleLength: int
    periodLength: int


class AIRequest(BaseModel):
    logs: list[HealthLog]
    cycles: list[Cycle]


class ChatRequest(BaseModel):
    message: str
    context: str | None = None


GEMINI_API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"


async def call_gemini(prompt: str) -> str:
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        raise HTTPException(status_code=500, detail="GEMINI_API_KEY not set on server")

    url = f"{GEMINI_API_URL}?key={api_key}"
    body = {
        "contents": [{"parts": [{"text": prompt}]}],
        "generationConfig": {"maxOutputTokens": 500, "temperature": 0.7},
    }
    async with httpx.AsyncClient(timeout=30) as client:
        resp = await client.post(url, json=body)
        if resp.status_code != 200:
            raise HTTPException(status_code=502, detail=f"Gemini API error: {resp.text}")
        data = resp.json()
        try:
            return data["candidates"][0]["content"]["parts"][0]["text"]
        except Exception:
            raise HTTPException(status_code=502, detail="Unexpected Gemini response format")


@app.post("/ai/insights")
async def ai_insights(req: AIRequest):
    total_logs = len(req.logs)

    # Calculate averages
    mood_intensities = []
    for l in req.logs:
        if l.moodIntensity is not None:
            mood_intensities.append(l.moodIntensity)
        elif isinstance(l.mood, int):
            mood_intensities.append(l.mood)
        else:
            mood_intensities.append(3)

    avg_mood = (sum(mood_intensities) / total_logs) if total_logs else None
    avg_energy = (sum([l.energy for l in req.logs]) / total_logs) if total_logs else None
    avg_pain = (sum([l.painIntensity for l in req.logs]) / total_logs) if total_logs else None

    prompt_lines = [
        "You are a compassionate women's health insights assistant for the Flowra app.",
        f"Total health logs: {total_logs}",
    ]
    if avg_mood is not None:
        prompt_lines.append(f"Average mood intensity (1-10): {avg_mood:.1f}")
    if avg_energy is not None:
        prompt_lines.append(f"Average energy level (1-10): {avg_energy:.1f}")
    if avg_pain is not None:
        prompt_lines.append(f"Average pain intensity (1-10): {avg_pain:.1f}")

    recent_notes = [l.notes for l in req.logs if l.notes]
    if recent_notes:
        prompt_lines.append("Recent user notes:")
        prompt_lines.extend([f"- {n}" for n in recent_notes[-5:]])

    if req.cycles:
        avg_cycle_len = sum([c.cycleLength for c in req.cycles]) / len(req.cycles)
        prompt_lines.append(f"Average cycle length: {avg_cycle_len:.1f} days")

    prompt_lines.append(
        "Based on this data, provide exactly 3 concise personalized health insights "
        "and 3 practical self-care suggestions. Be warm, supportive and specific."
    )
    prompt = "\n".join(prompt_lines)

    text = await call_gemini(prompt)
    return {"insights": text}


@app.post("/ai/chat")
async def ai_chat(req: ChatRequest):
    system_prompt = (
        "You are Flowra's AI wellness assistant — a warm, knowledgeable, and supportive companion "
        "for women's health. You help users understand their menstrual cycles, mood patterns, "
        "pain management, wellness routines, and personal safety. Always be concise, empathetic, "
        "and evidence-based. Never give medical diagnoses."
    )
    full_prompt = f"{system_prompt}\n\n"
    if req.context:
        full_prompt += f"User context: {req.context}\n\n"
    full_prompt += f"User: {req.message}\nFlowra AI:"

    text = await call_gemini(full_prompt)
    return {"response": text}


# --- Trusted contacts sync endpoints (simple file-backed storage) ---

DATA_DIR = Path(__file__).resolve().parent / 'data'
DATA_DIR.mkdir(exist_ok=True)


class Contact(BaseModel):
    id: str | None = None
    name: str
    phone: str
    relation: str | None = None
    trusted: bool | None = False


@app.get("/trusted/{uid}")
async def get_trusted(uid: str) -> List[Contact]:
    f = DATA_DIR / f"trusted_{uid}.json"
    if not f.exists():
        return []
    import json
    data = json.loads(f.read_text(encoding="utf-8"))
    return [Contact(**c) for c in data]


@app.post("/trusted/{uid}")
async def set_trusted(uid: str, contacts: List[Contact]):
    f = DATA_DIR / f"trusted_{uid}.json"
    import json
    f.write_text(json.dumps([c.model_dump() for c in contacts], ensure_ascii=False), encoding="utf-8")
    return {"status": "ok", "count": len(contacts)}


# --- SOS trigger endpoint (stub/sends via provider if configured) ---

class SosRequest(BaseModel):
    contacts: List[Contact]
    message: str | None = None
    latitude: float | None = None
    longitude: float | None = None


@app.post("/sos/{uid}")
async def trigger_sos(uid: str, req: SosRequest):
    # Try to use Twilio if configured, otherwise simulate
    TW_SID = os.getenv("TWILIO_SID")
    TW_TOKEN = os.getenv("TWILIO_TOKEN")
    FROM_NUMBER = os.getenv("TWILIO_FROM")
    sent = []
    if TW_SID and TW_TOKEN and FROM_NUMBER:
        # send SMS via Twilio REST API
        async with httpx.AsyncClient() as client:
            for c in req.contacts:
                to = c.phone
                body = req.message or f"Emergency alert from Flowra user {uid}"
                if req.latitude is not None and req.longitude is not None:
                    body += f"\nLocation: https://www.google.com/maps/search/?api=1&query={req.latitude},{req.longitude}"
                payload = {"From": FROM_NUMBER, "To": to, "Body": body}
                url = f"https://api.twilio.com/2010-04-01/Accounts/{TW_SID}/Messages.json"
                resp = await client.post(url, data=payload, auth=(TW_SID, TW_TOKEN))
                sent.append({"to": to, "status": resp.status_code})
    else:
        # Simulate sending
        for c in req.contacts:
            msg = req.message or f"Emergency alert from Flowra user {uid}"
            if req.latitude is not None and req.longitude is not None:
                msg += f"\nLocation: https://www.google.com/maps/search/?api=1&query={req.latitude},{req.longitude}"
            sent.append({"to": c.phone, "status": "simulated", "message": msg})

    return {"status": "ok", "sent": sent}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8001)
