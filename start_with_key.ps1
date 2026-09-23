$env:GEMINI_API_KEY = [System.Environment]::GetEnvironmentVariable('GEMINI_API_KEY', 'User')
if ($env:GEMINI_API_KEY -and $env:GEMINI_API_KEY.Length -ge 10) {
    Write-Host "GEMINI_API_KEY loaded: $($env:GEMINI_API_KEY.Substring(0,10))..."
}
Set-Location "$PSScriptRoot\backend"
& ".\venv\Scripts\Activate.ps1"
uvicorn main:app --reload --host 127.0.0.1 --port 8001

