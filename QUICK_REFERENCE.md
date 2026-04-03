# ⚡ QUICK REFERENCE CARD

## 🚀 FASTEST START (Copy & Paste)

**Step 1: Install dependencies (5 min)**
```bash
pip install -r automation/requirements.txt
ollama pull codellama:13b-instruct
```

**Step 2: Start Ollama (keep running)**
```bash
ollama serve
```

**Step 3: Run automation (in NEW terminal)**
```bash
automation\run_chain.bat
```

**Step 4: Watch the magic! ✨**

---

## 📊 WHAT GETS GENERATED

| What | Where | Size | Time |
|---|---|---|---|
| Transaction Model | lib/models/transaction.dart | Updated | 3-5 min |
| 3 New Models | lib/models/*.dart | 800 LOC | 10-15 min |
| Database Service | lib/services/database_service.dart | Updated | 3-5 min |
| Categorization Service | lib/services/categorization_service.dart | 300 LOC | 8-10 min |
| Leak Detection | lib/services/leak_detection_service.dart | 350 LOC | 8-10 min |
| Insight Generator | lib/services/insight_generator_service.dart | 300 LOC | 8-10 min |
| Analytics Provider | lib/providers/analytics_provider.dart | 400 LOC | 5-8 min |
| 2 New Screens | lib/screens/*.dart | 350 LOC | 10-15 min |
| 6 Widgets | lib/widgets/*.dart | 400 LOC | 10-15 min |
| 50+ Tests | test/ | 1000+ LOC | 15-20 min |
| **TOTAL** | **30+ files** | **5,000+ LOC** | **90-135 min** |

---

## 🔄 EXECUTION TIMELINE

```
10:30 - Start (automated)
10:45 - Phase 1 complete (models)
11:00 - Phase 2 complete (categorization)
11:15 - Phase 3 complete (leak detection)
11:30 - Phase 4 complete (insights)
11:45 - Phase 5 complete (state mgmt)
12:00 - Phase 6 complete (screens)
12:15 - Phase 7 complete (tests)
12:20 - DONE! ✅
```

**Total: ~110 minutes (less than 2 hours)**

---

## 📁 KEY FILES YOU CREATED

| File | Purpose | When to refer |
|---|---|---|
| `automation/chain_config.yaml` | All task definitions | Customizing tasks |
| `automation/orchestrator.py` | Automation engine | Debugging issues |
| `automation/run_chain.bat` | Windows launcher | Running automation |
| `AUTOMATION_SETUP_GUIDE.md` | Detailed setup | First setup only |
| `COMPLETE_AUTOMATION_WORKFLOW.md` | This workflow | Understanding flow |
| `QUICK_REFERENCE.md` | Quick lookup (THIS) | During execution |

---

## ⚠️ BEFORE YOU RUN

Checklist:
- [ ] Python 3.8+ installed (`python --version`)
- [ ] Ollama installed and running (`ollama serve`)
- [ ] Model downloaded (`ollama pull codellama:13b-instruct`)
- [ ] Project directory is correct
- [ ] You have the .md instruction files:
  - [ ] `EXACT_CODE_CHANGES_DAY1.md`
  - [ ] `DETAILED_IMPLEMENTATION_PLAN.md`
- [ ] At least 8GB RAM available
- [ ] 20GB free disk space
- [ ] VS Code open (optional, for reviewing generated code)

---

## 🟢 RUNNING: WHAT TO EXPECT

### Console Output
```
✓ Phase 1 started...
[1.1] Generating code...
✓ File written
✓ Verified
[1.2] Generating code...
✓ File written
✓ Verified
... continues ...
✓ Phase 1 complete
... phases 2-7 ...
✓ CHAIN COMPLETE
```

### Success Indicators
- ✅ No error messages
- ✅ All tasks marked `[success]`
- ✅ JSON report generated
- ✅ Files exist in lib/ and test/

### Error Indicators
- ❌ Task marked `[failed]`
- ❌ Error message with details
- ❌ Check log file for debugging

---

## 🔧 IF SOMETHING FAILS

**Check log file (real-time):**
```bash
# PowerShell
Get-Content automation/logs/chain_execution.log -Tail 20 -Wait

# Or just open in VS Code:
automation/logs/chain_execution.log
```

**Common fixes:**

| Error | Fix |
|---|---|
| "Connection refused" | Start Ollama: `ollama serve` |
| "Model not pulled" | Download: `ollama pull codellama:13b-instruct` |
| Timeout (>300s) | Close other apps, try lighter model |
| Memory errors | Close other apps, restart Ollama |
| Syntax errors in generated code | Check log, increase retry count |

---

## ✅ AFTER AUTOMATION COMPLETES

1. **Verify build:**
   ```bash
   flutter analyze
   ```

2. **Check generated files:**
   - `lib/models/subscription.dart` exists?
   - `lib/services/categorization_service.dart` exists?
   - `lib/providers/analytics_provider.dart` exists?
   - All tests in `test/` folder?

3. **Run app (optional):**
   ```bash
   flutter run
   ```

4. **Commit to git:**
   ```bash
   git add -A
   git commit -m "Days 1-7: Automated generation complete"
   ```

---

## 📊 SUCCESS METRICS

| Metric | Target | How to Check |
|---|---|---|
| Files created | 30+ | `dir /s lib/ test/` |
| Lines generated | 5,000+ | Count all .dart files |
| Compilation | 0 errors | `flutter analyze` |
| Tests | 50+ | `grep -r "void test" test/` |
| Duration | <150 min | Check console timestamp |

---

## 🆘 GETTING STUCK?

1. **Check log:** `automation/logs/chain_execution.log`
2. **Check report:** `automation/logs/chain_report.json`
3. **Review config:** `automation/chain_config.yaml`
4. **Check generated files:** `lib/` and `test/`
5. **Try again:** Higher retry count in config

---

## 🎯 ONE-LINER COMMANDS

```bash
# Full setup + run
pip install -r automation/requirements.txt && ollama serve &
automation\run_chain.bat

# Check progress (while running)
Get-Content automation/logs/chain_execution.log -Tail 10 -Wait

# Check final report
Get-Content automation/logs/chain_report.json | jq .

# Verify compilation
flutter analyze

# Count generated code
(Get-ChildItem lib/*.dart -Recurse | Measure-Object -Line).Lines
```

---

## 🚀 YOU'RE READY!

Everything is configured. Just run:

```
automation\run_chain.bat
```

Then **go get coffee** ☕ and come back in 2 hours!

---

**Questions?** Check `COMPLETE_AUTOMATION_WORKFLOW.md`  
**Setup issues?** Check `AUTOMATION_SETUP_GUIDE.md`  
**Code issues?** Check `automation/logs/chain_execution.log`

**Good luck! 🎉**
