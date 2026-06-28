from fastapi import FastAPI
from pydantic import BaseModel
from transformers import AutoTokenizer, AutoModelForSequenceClassification
from fastapi.middleware.cors import CORSMiddleware
import torch
import json

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

model = AutoModelForSequenceClassification.from_pretrained("./complaintDesk_model")
tokenizer = AutoTokenizer.from_pretrained("./complaintDesk_model")
model.eval()

with open("./complaintDesk_model/label_map.json", "r") as f:
    label_map = json.load(f)

class Complaint(BaseModel):
    text: str

@app.post("/predict")
def predict(complaint: Complaint):
    inputs = tokenizer(
        complaint.text,
        return_tensors="pt",
        truncation=True,
        max_length=128
    )
    with torch.no_grad():
        output = model(**inputs)
        predicted = torch.argmax(output.logits, dim=1).item()

    priority = label_map[str(predicted)]
    return {"priority": priority}