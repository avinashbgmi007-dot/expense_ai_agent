@echo off
REM ============================================================================
REM AUTOMATED CODE GENERATION CHAIN - WINDOWS LAUNCHER
REM ============================================================================
REM This script sets up and runs the entire automation pipeline
REM
REM Usage: run_chain.bat
REM ============================================================================

setlocal enabledelayedexpansion

echo.
echo ============================================================================
echo  AUTOMATED CODE GENERATION CHAIN - ORCHESTRATOR
echo ============================================================================
echo.

REM Get current directory
set PROJECT_ROOT=%~dp0..
cd %PROJECT_ROOT%

echo [1/5] Checking prerequisites...

REM Check Python
"C:\Program Files\Python314\python.exe" --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python not found. Please install Python 3.8+
    pause
    exit /b 1
)
echo ✓ Python installed

REM Set Python path for use in rest of script
set PYTHON_PATH=C:\Program Files\Python314\python.exe

REM Check Flutter
flutter --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Flutter not found. Please install Flutter
    pause
    exit /b 1
)
echo ✓ Flutter installed

REM Check Ollama
echo Checking Ollama connection...
"%PYTHON_PATH%" -c "import requests; requests.get('http://localhost:11434/api/tags', timeout=5)" >nul 2>&1
if errorlevel 1 (
    echo ERROR: Ollama not running on localhost:11434
    echo Please start Ollama:
    echo   1. Open Command Prompt
    echo   2. Run: ollama serve
    echo   3. In another window, run: ollama pull codellama:13b-instruct
    pause
    exit /b 1
)
echo ✓ Ollama is running

echo.
echo [2/5] Installing Python dependencies...
"%PYTHON_PATH%" -m pip install -r automation\requirements.txt --quiet
if errorlevel 1 (
    echo ERROR: Failed to install dependencies
    pause
    exit /b 1
)
echo ✓ Dependencies installed

echo.
echo [3/5] Creating automation directories...
if not exist "automation\logs" mkdir automation\logs
if not exist "automation\generated_code" mkdir automation\generated_code
if not exist "automation\attempts" mkdir automation\attempts
echo ✓ Directories prepared

echo.
echo [4/5] Verifying configuration...
if not exist "automation\chain_config.yaml" (
    echo ERROR: chain_config.yaml not found
    pause
    exit /b 1
)
echo ✓ Configuration file found

echo.
echo [5/5] Running orchestrator...
echo.
echo ============================================================================
"%PYTHON_PATH%" automation\orchestrator.py
set ORCHESTRATOR_EXIT=%ERRORLEVEL%
echo ============================================================================

echo.
echo Orchestrator exit code: %ORCHESTRATOR_EXIT%

if %ORCHESTRATOR_EXIT% equ 0 (
    echo.
    echo ✓✓✓ CHAIN EXECUTION SUCCESSFUL ✓✓✓
    echo.
    echo Next steps:
    echo 1. Review generated code in the project files
    echo 2. Check logs in: automation\logs\chain_execution.log
    echo 3. Run: flutter run
    echo.
) else (
    echo.
    echo ✗✗✗ CHAIN EXECUTION FAILED ✗✗✗
    echo.
    echo Check error log:
    echo   automation\logs\chain_execution.log
    echo.
)

pause
exit /b %ORCHESTRATOR_EXIT%
