# ⛓️ AUTOMATED CODE GENERATION CHAIN SETUP & USAGE GUIDE

**Date:** March 28, 2026  
**Project:** Her - AI Expense Tracker  
**Status:** Automation System Ready

---

## 🎯 WHAT THIS SYSTEM DOES

This automated system will:

✅ **Read** your `.md` instruction files  
✅ **Generate** complete Dart code via Ollama (offline)  
✅ **Write** code to correct file paths  
✅ **Verify** compilation with `flutter analyze`  
✅ **Chain** each task to the next automatically  
✅ **Log** everything in detailed reports  
✅ **Recover** from errors with retries  
✅ **Minimize** human intervention  

**Result:** Day 1 complete in ~2-3 hours (mostly automated)

---

## 📋 PREREQUISITES

### Required Software

- ✅ Python 3.8+ (for orchestrator)
- ✅ Ollama (for offline AI)
- ✅ Flutter SDK (for verification)
- ✅ Dart SDK (included with Flutter)

### Installation

#### 1. Install Python (if not already)

**Windows:**
```bash
# Download from python.org
# Or use PowerShell:
winget install Python.Python.3.11

# Verify:
python --version
```

#### 2. Install Ollama

**Windows:**
```bash
# Download from ollama.ai
# Or use PowerShell:
winget install Ollama.Ollama

# Start Ollama service
ollama serve

# In another terminal, download model:
ollama pull codellama:13b-instruct

# Verify:
curl http://localhost:11434/api/tags
```

#### 3. Install Flutter (if not already)

```bash
# Follow https://flutter.dev/docs/get-started/install
# Verify:
flutter --version
```

---

## 🚀 QUICK START (5 MINUTES)

### Step 1: Install Python Dependencies

**Windows:**
```bash
cd c:\Users\Avinash-Pro\Documents\work_space\expense_ai_agent
pip install -r automation/requirements.txt
```

**Or use PowerShell:**
```powershell
python -m pip install -r automation/requirements.txt --user
```

### Step 2: Start Ollama

Open **Command Prompt** or **PowerShell**:
```bash
ollama serve
```

Keep this window open. You'll see:
```
Listening on 127.0.0.1:11434
```

### Step 3: Verify Ollama Model

In **another terminal**, check if model exists:
```bash
ollama list
```

If `codellama:13b-instruct` is not listed, pull it:
```bash
ollama pull codellama:13b-instruct
```

This takes ~10-15 minutes first time (5GB download).

### Step 4: Run the Chain

**Windows CMD:**
```bash
cd c:\Users\Avinash-Pro\Documents\work_space\expense_ai_agent
automation\run_chain.bat
```

**Or PowerShell:**
```powershell
cd c:\Users\Avinash-Pro\Documents\work_space\expense_ai_agent
python automation\orchestrator.py
```

### Step 5: Watch the Magic

The orchestrator will:
1. Read `EXACT_CODE_CHANGES_DAY1.md`
2. Extract instructions
3. Send to Ollama
4. Generate code
5. Write to files
6. Verify compilation
7. Move to next task
8. Repeat until done

**Estimated time:** 30-45 minutes for Phase 1

---

## 🔧 UNDERSTANDING THE SYSTEM

### Architecture

```
┌─────────────────────────────────────┐
│   chain_config.yaml                 │
│   (7 phases, 15+ tasks defined)     │
└────────────┬────────────────────────┘
             │
             ↓
┌─────────────────────────────────────┐
│   orchestrator.py                   │
│   (Main controller)                 │
└────────────┬────────────────────────┘
             │
      ┌──────┴──────┐
      ↓             ↓
┌──────────┐   ┌──────────┐
│ Ollama   │   │ Flutter  │
│ (AI Gen) │   │ (Verify) │
└──────────┘   └──────────┘
      ↓             ↓
      └──────┬──────┘
             ↓
      ┌─────────────┐
      │ Generated   │
      │ Code Files  │
      └─────────────┘
```

### File Structure

```
automation/
├── chain_config.yaml      ← Configuration file (7 phases)
├── orchestrator.py        ← Main orchestration script
├── requirements.txt       ← Python dependencies
├── run_chain.bat          ← Windows launcher
├── logs/
│   ├── chain_execution.log      ← Detailed log
│   ├── chain_report.json        ← JSON summary
│   └── errors.log              ← Error log
├── generated_code/             ← Backup of generated code
└── attempts/                   ← Failed attempts (for debugging)
```

---

## ⚙️ CONFIGURATION

### `chain_config.yaml` Structure

The file has 7 phases:

```yaml
phase_1:  # Data Models & Database (Day 1)
  tasks:
    - task_id: "1.1"
      name: "Update TransactionModel"
      target_file: "lib/models/transaction.dart"
      
phase_2:  # Categorization Service (Day 2)
  dependencies: ["phase_1"]
  tasks: [...]
  
phase_3:  # Leak Detection (Day 3)
  dependencies: ["phase_2"]
  tasks: [...]

... and so on
```

### Customizing Tasks

To modify a task:

1. Edit `automation/chain_config.yaml`
2. Update the task section:
   ```yaml
   - task_id: "1.1"
     name: "Update TransactionModel"
     target_file: "lib/models/transaction.dart"
     source_section: "FILE 1: Update lib/models/transaction.dart"
     verify:
       - command: "flutter analyze"
         expected: "0 errors"
   ```
3. Save and re-run: `automation\run_chain.bat`

---

## 📊 MONITORING EXECUTION

### Real-Time Logs

The orchestrator prints to console:

```
============================================================================
PHASE START: Data Models & Database Extension
Description: Create foundation models and extend database schema
============================================================================

[1.1] Starting: Update TransactionModel
    Extracting: EXACT_CODE_CHANGES_DAY1.md → FILE 1: Update lib/models/transaction.dart
    Generating code via Ollama (codellama:13b-instruct)...
    ✓ File written: lib/models/transaction.dart
    Running verification...
    Verify: flutter analyze ✅ - pass
[1.1] Complete: Update TransactionModel ✅ [success]

[1.2] Starting: Create SubscriptionModel
    ...
```

### Log Files

After execution, check:

**Detailed log:**
```bash
cat automation/logs/chain_execution.log
```

**JSON report:**
```bash
cat automation/logs/chain_report.json
```

---

## ✅ PHASE 1 EXECUTION (DETAILED)

### What Happens When You Run

```
Phase 1: Data Models & Database Extension
├─ Task 1.1: Update TransactionModel
│  ├─ Extract section from EXACT_CODE_CHANGES_DAY1.md
│  ├─ Send to Ollama with prompt
│  ├─ Receive generated code
│  ├─ Write to lib/models/transaction.dart
│  ├─ Run: flutter analyze
│  └─ ✅ If no errors, mark complete
│
├─ Task 1.2: Create SubscriptionModel
│  ├─ Create new file
│  ├─ Generate code
│  ├─ Write to lib/models/subscription.dart
│  └─ Verify compilation
│
├─ Task 1.3: Create MonthlySummary
│  └─ Same process...
│
├─ Task 1.4: Create SpendingCategory
│  └─ Same process...
│
├─ Task 1.5: Update DatabaseService
│  ├─ Update existing file (add methods)
│  ├─ Run verify
│  └─ Check for errors
│
├─ Task 1.6: Update main.dart
│  └─ Add imports
│
└─ Task 1.7: Verify Entire Phase
   ├─ Run: flutter analyze (0 errors expected)
   ├─ Run: flutter pub get
   └─ Results saved to logs/chain_report.json
```

### Expected Timeline

```
Task 1.1: 3-5 min (update existing file)
Task 1.2: 3-5 min (create new file)
Task 1.3: 3-5 min (create new file)
Task 1.4: 3-5 min (create new file)
Task 1.5: 5-7 min (update complex file)
Task 1.6: 1-2 min (simple imports)
Task 1.7: 5-10 min (final verification)

Total Phase 1: 25-40 minutes
```

---

## ❌ ERROR HANDLING

### Common Issues

#### Issue 1: "Ollama not running"

**Error Message:**
```
ERROR [CONNECTION]: Cannot connect to Ollama: Connection refused
```

**Solution:**
```bash
# Terminal 1: Start Ollama
ollama serve

# Terminal 2: Check connection
curl http://localhost:11434/api/tags
```

#### Issue 2: "Model not downloaded"

**Error Message:**
```
ollama model not found: codellama:13b-instruct
```

**Solution:**
```bash
ollama pull codellama:13b-instruct
```

Patience required: 5-15 minutes for download.

#### Issue 3: "Flutter analyze failed"

**Error Message:**
```
ERROR [ANALYZE]: compilation error
```

**Solution:**
1. Check detailed log: `automation/logs/chain_execution.log`
2. The system will automatically retry (up to 3 times)
3. If still failing, check specific error in logs
4. Edit the problematic section in `.md` file or config

#### Issue 4: "Code generation failed"

**Error Message:**
```
ERROR [TASK_EXECUTION]: Failed to generate code after 3 attempts
```

**Solution:**
1. Check prompt format in `orchestrator.py`
2. Verify Ollama is running (`ollama serve`)
3. Try with smaller model: `ollama pull mistral:7b`
4. Update `chain_config.yaml`: `ai_model: "mistral:7b"`

---

## 🔍 DEBUGGING

### Enable Debug Logging

Edit `chain_config.yaml`:
```yaml
logging:
  level: "DEBUG"  # Changed from INFO
  console_output: true
  file_output: true
```

Re-run to get detailed debug logs.

### Check Generated Code

After execution, review generated files:

```bash
# View a specific file
cat lib/models/subscription.dart

# Check compilation
flutter analyze

# Run app
flutter run
```

### Review Failed Attempts

If a task failed, check the attempt files:

```bash
# List failed attempts
dir automation/attempts/1.1/

# Review specific attempt
cat automation/attempts/1.1/attempt_1_failed.dart
```

---

## 🎯 RUNNING SPECIFIC PHASES

### Run Only Phase 1

Edit `chain_config.yaml`:
```yaml
# Comment out phases you don't want
# phase_2:
#   ...

# phase_3:
#   ...
```

Then run:
```bash
automation\run_chain.bat
```

### Run From Phase 2 Onward

Ensure Phase 1 is already complete, then:
```bash
# Modify orchestrator.py to start from phase_2
phases = ['phase_2', 'phase_3', ...]
```

Or comment out Phase 1 in config.

---

## 📊 FINAL REPORT

After execution, check `automation/logs/chain_report.json`:

```json
{
  "execution_start": "2026-03-28T10:30:00",
  "execution_end": "2026-03-28T11:15:00",
  "phases": {
    "phase_1": {
      "name": "Data Models & Database Extension",
      "status": "completed",
      "tasks_completed": 7,
      "tasks_failed": 0
    }
  },
  "errors": [],
  "summary": {
    "total_tasks": 7,
    "completed": 7,
    "failed": 0,
    "success_rate": "100%"
  }
}
```

---

## 🚀 NEXT STEPS AFTER PHASE 1

Once Phase 1 succeeds:

1. **Verify manually:**
   ```bash
   flutter analyze    # Should be 0 errors
   flutter run        # Should compile and launch
   ```

2. **Review generated code:**
   - Open each file in VS Code
   - Check for any red squiggles
   - Review formatting

3. **Commit to git:**
   ```bash
   git add -A
   git commit -m "Day 1: Data models & database (auto-generated)"
   ```

4. **Run Phase 2:**
   ```bash
   # Update chain_config.yaml to start from phase_2
   # Uncomment phase_2 onwards
   automation\run_chain.bat
   ```

---

## 💡 TIPS & TRICKS

### Speed Up Generation

Use faster model:
```yaml
ai_model: "mistral:7b"  # Instead of codellama:13b
```

Faster but slightly less accurate.

### Skip Verification (Not Recommended)

```yaml
tasks:
  - task_id: "1.1"
    ...
    verify: []  # Skip verification
```

### Run Multiple Chains in Parallel

Use different terminals:
```bash
# Terminal 1: Phase 1-2
automation\run_chain.bat

# Terminal 2: (after Phase 2 done) Phase 3-4
automation\run_chain.bat
```

---

## 🆘 TROUBLESHOOTING

| Problem | Solution |
|---------|----------|
| Ollama crashes | Reduce retry timeout in orchestrator.py, or use 7B model |
| Takes too long | Use faster model (Mistral 7B) |
| Out of memory | Run on machine with 16GB+ RAM, or smaller model |
| Can't find .md file | Verify file exists in project root |
| Generated code has errors | Check logs, enable DEBUG logging |
| Stuck on verification | Check `flutter analyze` manually |

---

## 📞 GETTING HELP

1. **Check logs:** `automation/logs/chain_execution.log`
2. **Review generated code:** Check target files in project
3. **Manual verification:** `flutter analyze`
4. **Model quality:** Might need better model or prompt adjustment

---

## ✨ SUCCESS CRITERIA

You'll know it worked when:

```
✅ No errors in automation/logs/chain_execution.log
✅ All 7 tasks in Phase 1 marked "success"
✅ flutter analyze returns 0 errors
✅ flutter run compiles and shows HomeScreen
✅ All generated files present in lib/models/
✅ Database schema updated in database_service.dart
✅ automation/logs/chain_report.json shows 100% success
```

---

**Ready?** Run: `automation\run_chain.bat` ✨

**Questions?** Check `automation/logs/chain_execution.log` first!
