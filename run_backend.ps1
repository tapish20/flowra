#!/usr/bin/env pwsh
# run_backend.ps1
Set-StrictMode -Version Latest
# Ensure script operates from the backend directory
Set-Location -Path (Join-Path $PSScriptRoot "backend")

if (-not (Test-Path venv)) {
    py -m venv venv
}

# Activate virtual environment
& .\venv\Scripts\Activate.ps1

# Install dependencies (idempotent)
& ".\venv\Scripts\python.exe" -m pip install -r requirements.txt

if (-not $env:GEMINI_API_KEY) {
    Write-Host "Warning: GEMINI_API_KEY is not set in this session. Set it with:`n`$env:GEMINI_API_KEY=`"your_gemini_key_here`"`nor use setx to persist.`nContinuing without it will make /ai/insights and /ai/chat return an error when called."
}

Write-Host "Starting backend (uvicorn) on http://127.0.0.1:8001"
& ".\venv\Scripts\python.exe" -m uvicorn main:app --reload --host 127.0.0.1 --port 8001


