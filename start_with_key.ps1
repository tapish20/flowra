$env:GEMINI_API_KEY = [System.Environment]::GetEnvironmentVariable('GEMINI_API_KEY', 'User')
Write-Host "GEMINI_API_KEY loaded: $($env:GEMINI_API_KEY.Substring(0,10))..."
& "$PSScriptRoot\venv\Scripts\Activate.ps1"
Set-Location "$PSScriptRoot\backend"
uvicorn main:app --reload --host 127.0.0.1 --port 8001
