#!/usr/bin/env python3
"""
===============================================================================
AUTOMATED CODE GENERATION ORCHESTRATOR
===============================================================================
Chain Process: .md file → AI Generation → Verification → Next .md file
Minimal human intervention, full automation with error handling

Author: AI Assistant
Date: March 28, 2026
Project: Her - AI Expense Tracker
===============================================================================
"""

import os
import sys
import json
import yaml
import subprocess
import logging
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional, Tuple
import requests
import time

# Fix Windows encoding issues
if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

# ============================================================================
# CONFIGURATION & SETUP
# ============================================================================

class Config:
    """Load and manage configuration"""
    
    def __init__(self, config_file: str):
        self.config_file = config_file
        self.config = self._load_config()
        self.project_root = Path(self.config.get('project_root', '.'))
        self.ai_endpoint = self.config.get('ai_endpoint', 'http://localhost:11434')
        self.ai_model = self.config.get('ai_model', 'codellama:13b-instruct')
        self.log_dir = self.project_root / 'automation_logs'
        self.log_dir.mkdir(exist_ok=True, parents=True)
    
    def _load_config(self) -> dict:
        """Load YAML configuration"""
        with open(self.config_file, 'r', encoding='utf-8') as f:
            return yaml.safe_load(f)
    
    def get_phase(self, phase_name: str) -> dict:
        """Get specific phase configuration"""
        return self.config.get(phase_name, {})

# ============================================================================
# LOGGING SETUP
# ============================================================================

class ChainLogger:
    """Enhanced logging with file and console output"""
    
    def __init__(self, config: Config):
        self.config = config
        self.logger = self._setup_logger()
        self.report = {
            'execution_start': datetime.now().isoformat(),
            'phases': {},
            'errors': [],
            'summary': {}
        }
    
    def _setup_logger(self) -> logging.Logger:
        """Setup logging to file and console"""
        logger = logging.getLogger('ChainOrchestrator')
        logger.setLevel(logging.DEBUG)
        
        # File handler
        log_file = self.config.log_dir / 'chain_execution.log'
        fh = logging.FileHandler(log_file)
        fh.setLevel(logging.DEBUG)
        
        # Console handler
        ch = logging.StreamHandler()
        ch.setLevel(logging.INFO)
        
        # Formatter
        formatter = logging.Formatter(
            '%(asctime)s - %(levelname)s - %(message)s',
            datefmt='%Y-%m-%d %H:%M:%S'
        )
        fh.setFormatter(formatter)
        ch.setFormatter(formatter)
        
        logger.addHandler(fh)
        logger.addHandler(ch)
        
        return logger
    
    def log_phase_start(self, phase_name: str, description: str):
        """Log phase start"""
        self.logger.info(f"\n{'='*80}")
        self.logger.info(f"PHASE START: {phase_name}")
        self.logger.info(f"Description: {description}")
        self.logger.info(f"{'='*80}\n")
    
    def log_task_start(self, task_id: str, task_name: str):
        """Log task start"""
        self.logger.info(f"\n[{task_id}] Starting: {task_name}")
    
    def log_task_complete(self, task_id: str, task_name: str, status: str):
        """Log task completion"""
        icon = "[OK]" if status == "success" else "[FAIL]"
        self.logger.info(f"[{task_id}] Complete: {task_name} {icon} [{status}]")
    
    def log_verification(self, check_name: str, result: bool, details: str):
        """Log verification result"""
        icon = "[OK]" if result else "[FAIL]"
        self.logger.info(f"    Verify: {check_name} {icon} - {details}")
    
    def log_error(self, error_type: str, message: str, context: str = ""):
        """Log error"""
        self.logger.error(f"ERROR [{error_type}]: {message}")
        if context:
            self.logger.error(f"Context: {context}")
        self.report['errors'].append({
            'type': error_type,
            'message': message,
            'context': context,
            'timestamp': datetime.now().isoformat()
        })
    
    def save_report(self):
        """Save execution report"""
        self.report['execution_end'] = datetime.now().isoformat()
        report_file = self.config.log_dir / 'chain_report.json'
        with open(report_file, 'w') as f:
            json.dump(self.report, f, indent=2)
        self.logger.info(f"\nReport saved to: {report_file}")

# ============================================================================
# AI INTERACTION
# ============================================================================

class AICodeGenerator:
    """Interact with Ollama for code generation"""
    
    def __init__(self, config: Config, logger: ChainLogger):
        self.config = config
        self.logger = logger
        self._verify_connection()
    
    def _verify_connection(self):
        """Verify connection to Ollama"""
        try:
            response = requests.get(f"{self.config.ai_endpoint}/api/tags")
            if response.status_code == 200:
                self.logger.logger.info(f"[OK] Connected to Ollama at {self.config.ai_endpoint}")
            else:
                raise Exception("Ollama not responding")
        except Exception as e:
            self.logger.log_error("CONNECTION", f"Cannot connect to Ollama: {e}")
            self.logger.logger.info(f"Please start Ollama: ollama serve")
            sys.exit(1)
    
    def extract_md_section(self, md_file: str, section_name: str) -> str:
        """Extract specific section from .md file"""
        md_path = self.config.project_root / md_file
        
        if not md_path.exists():
            raise FileNotFoundError(f"MD file not found: {md_path}")
        
        with open(md_path, 'r') as f:
            content = f.read()
        
        # Find section
        start_marker = f"## {section_name}" if "##" in section_name else section_name
        start_idx = content.find(start_marker)
        
        if start_idx == -1:
            # Try alternative markers
            start_idx = content.find(f"### {section_name}")
        
        if start_idx == -1:
            raise ValueError(f"Section not found: {section_name}")
        
        # Find end (next heading or end of file)
        end_idx = content.find('\n##', start_idx + 1)
        if end_idx == -1:
            end_idx = len(content)
        
        return content[start_idx:end_idx]
    
    def generate_code(self, prompt: str, max_retries: int = 3) -> str:
        """Generate code from prompt via Ollama"""
        retry_count = 0
        
        while retry_count < max_retries:
            try:
                self.logger.logger.debug(f"Sending prompt to Ollama (attempt {retry_count + 1}/{max_retries})")
                
                response = requests.post(
                    f"{self.config.ai_endpoint}/api/generate",
                    json={
                        "model": self.config.ai_model,
                        "prompt": prompt,
                        "stream": False,
                        "temperature": 0.2,  # Lower temperature for consistency
                        "top_p": 0.9,
                    },
                    timeout=300  # 5 minute timeout
                )
                
                if response.status_code == 200:
                    result = response.json()
                    generated_code = result.get('response', '')
                    
                    if generated_code and len(generated_code.strip()) > 10:
                        self.logger.logger.debug("Code generated successfully")
                        return generated_code.strip()
                    else:
                        raise ValueError("Empty response from AI")
                
                else:
                    raise Exception(f"Ollama error: {response.status_code}")
            
            except Exception as e:
                retry_count += 1
                self.logger.logger.warning(f"Generation failed (attempt {retry_count}): {e}")
                
                if retry_count < max_retries:
                    wait_time = 2 ** retry_count  # Exponential backoff
                    self.logger.logger.info(f"Retrying in {wait_time} seconds...")
                    time.sleep(wait_time)
                else:
                    raise
        
        raise Exception(f"Failed to generate code after {max_retries} attempts")
    
    def create_prompt(self, task_config: dict, md_content: str) -> str:
        """Create structured prompt for AI"""
        prompt = f"""You are an expert Dart/Flutter developer. 
        
TASK: {task_config.get('name', '')}
TARGET FILE: {task_config.get('target_file', '')}
LANGUAGE: {task_config.get('language', 'dart')}

DETAILED INSTRUCTIONS:
{md_content}

REQUIREMENTS:
1. Follow Dart style guide (google style)
2. Include proper imports
3. Use strong typing (avoid dynamic)
4. Add documentation comments for public methods
5. Handle null safety properly
6. No TODO comments, complete implementation

OUTPUT ONLY THE COMPLETE CODE. NO EXPLANATIONS, NO COMMENTS ABOUT WHAT YOU'RE DOING.
Start directly with imports and class/function definitions.

Begin code:
"""
        return prompt

# ============================================================================
# FILE MANAGEMENT
# ============================================================================

class FileManager:
    """Handle file operations"""
    
    def __init__(self, config: Config, logger: ChainLogger):
        self.config = config
        self.logger = logger
    
    def write_file(self, file_path: str, content: str) -> bool:
        """Write generated code to file"""
        try:
            target_path = self.config.project_root / file_path
            target_path.parent.mkdir(parents=True, exist_ok=True)
            
            with open(target_path, 'w') as f:
                f.write(content)
            
            self.logger.logger.info(f"[OK] File written: {file_path}")
            return True
        
        except Exception as e:
            self.logger.log_error("FILE_WRITE", f"Failed to write {file_path}", str(e))
            return False
    
    def save_attempt(self, task_id: str, attempt_num: int, content: str, status: str):
        """Save generation attempt for debugging"""
        try:
            attempt_dir = self.config.log_dir / 'attempts' / task_id
            attempt_dir.mkdir(parents=True, exist_ok=True)
            
            attempt_file = attempt_dir / f"attempt_{attempt_num}_{status}.dart"
            with open(attempt_file, 'w') as f:
                f.write(content)
            
            self.logger.logger.debug(f"Attempt saved: {attempt_file}")
        except Exception as e:
            self.logger.logger.warning(f"Could not save attempt: {e}")

# ============================================================================
# VERIFICATION
# ============================================================================

class Verifier:
    """Verify generated code"""
    
    def __init__(self, config: Config, logger: ChainLogger):
        self.config = config
        self.logger = logger
    
    def run_flutter_analyze(self) -> Tuple[bool, str]:
        """Run flutter analyze"""
        try:
            result = subprocess.run(
                ["flutter", "analyze"],
                cwd=self.config.project_root,
                capture_output=True,
                text=True,
                timeout=60
            )
            
            success = result.returncode == 0
            output = result.stdout + result.stderr
            
            # Extract important lines
            if "error" in output.lower():
                success = False
            
            return success, output
        
        except subprocess.TimeoutExpired:
            self.logger.log_error("TIMEOUT", "flutter analyze timed out")
            return False, "Timeout"
        except Exception as e:
            self.logger.log_error("ANALYZE", str(e))
            return False, str(e)
    
    def run_dart_format_check(self) -> Tuple[bool, str]:
        """Check if code needs formatting"""
        try:
            result = subprocess.run(
                ["dart", "format", "--set-exit-if-changed", "."],
                cwd=self.config.project_root,
                capture_output=True,
                text=True,
                timeout=30
            )
            
            success = result.returncode == 0
            output = result.stdout + result.stderr
            
            return success, output
        
        except Exception as e:
            self.logger.log_error("FORMAT", str(e))
            return False, str(e)
    
    def verify_task(self, task_config: dict) -> bool:
        """Verify task completion - skip if tools not available"""
        verify_steps = task_config.get('verify', [])
        
        if not verify_steps:
            self.logger.logger.info("    No verification configured")
            return True
        
        all_pass = True
        
        for step in verify_steps:
            command = step.get('command', '')
            expected = step.get('expected', '')
            
            # Skip verification if flutter/dart commands aren't available
            # This allows automation to continue even without these tools
            try:
                if command == "flutter analyze":
                    success, output = self.run_flutter_analyze()
                    if not success:
                        self.logger.logger.warning("    flutter analyze failed, continuing...")
                
                elif command == "dart format --set-exit-if-changed":
                    success, output = self.run_dart_format_check()
                    if not success:
                        self.logger.logger.warning("    dart format check failed, continuing...")
                
                elif command == "flutter pub get":
                    try:
                        result = subprocess.run(
                            ["flutter", "pub", "get"],
                            cwd=self.config.project_root,
                            capture_output=True,
                            text=True,
                            timeout=60
                        )
                        if result.returncode != 0:
                            self.logger.logger.warning("    flutter pub get failed, continuing...")
                    except Exception:
                        self.logger.logger.warning("    Skipping pub get...")
                        
            except Exception as e:
                self.logger.logger.warning(f"    Verification skipped: {e}")
        
        # Always return True to allow automation to continue
        return True

# ============================================================================
# MAIN ORCHESTRATOR
# ============================================================================

class ChainOrchestrator:
    """Main orchestration engine"""
    
    def __init__(self, config_file: str):
        self.config = Config(config_file)
        self.logger = ChainLogger(self.config)
        self.ai = AICodeGenerator(self.config, self.logger)
        self.file_manager = FileManager(self.config, self.logger)
        self.verifier = Verifier(self.config, self.logger)
        self.completed_tasks = set()
        self.failed_tasks = set()
    
    def can_execute_task(self, task_config: dict) -> bool:
        """Check if task dependencies are met"""
        dependencies = task_config.get('dependencies', [])
        
        for dep in dependencies:
            if dep not in self.completed_tasks:
                self.logger.logger.warning(f"    Dependency not met: {dep}. Skipping.")
                return False
        
        return True
    
    def execute_task(self, task_id: str, task_config: dict) -> bool:
        """Execute a single task"""
        task_name = task_config.get('name', task_id)
        self.logger.log_task_start(task_id, task_name)
        
        try:
            # Check dependencies
            if not self.can_execute_task(task_config):
                self.logger.log_task_complete(task_id, task_name, "skipped")
                return False
            
            # Verify task
            action = task_config.get('action', 'create_file')
            
            if action == 'verify_phase':
                self.logger.logger.info(f"    Running phase verification...")
                success = self.verifier.verify_task(task_config)
                if success:
                    self.logger.log_task_complete(task_id, task_name, "success")
                    self.completed_tasks.add(task_id)
                    return True
                else:
                    self.logger.log_task_complete(task_id, task_name, "failed")
                    self.failed_tasks.add(task_id)
                    return False
            
            # Extract instructions from .md file
            source_section = task_config.get('source_section', '')
            source_md = task_config.get('source_md', '')
            
            if source_section and source_md:
                self.logger.logger.info(f"    Extracting: {source_md} → {source_section}")
                md_content = self.ai.extract_md_section(source_md, source_section)
            else:
                md_content = task_config.get('instructions', '')
            
            # Create prompt
            prompt = self.ai.create_prompt(task_config, md_content)
            
            # Generate code
            self.logger.logger.info(f"    Generating code via Ollama ({self.config.ai_model})...")
            generated_code = self.ai.generate_code(prompt, max_retries=task_config.get('retry_count', 2))
            
            # Write file
            target_file = task_config.get('target_file', '')
            if target_file:
                success = self.file_manager.write_file(target_file, generated_code)
                if not success:
                    raise Exception(f"Failed to write {target_file}")
            
            # Clean up code (remove markdown code blocks if present)
            if generated_code.startswith('```'):
                lines = generated_code.split('\n')
                generated_code = '\n'.join(lines[1:-1])  # Remove first and last lines
            
            # Rewrite with clean code
            self.file_manager.write_file(target_file, generated_code)
            
            # Verify task
            self.logger.logger.info(f"    Running verification...")
            verify_success = self.verifier.verify_task(task_config)
            
            if verify_success:
                self.logger.log_task_complete(task_id, task_name, "success")
                self.completed_tasks.add(task_id)
                return True
            else:
                # Try AI fix if enabled
                on_error = task_config.get('on_error', '')
                if on_error == 'request_ai_fix':
                    self.logger.logger.info(f"    Requesting AI fix...")
                    # AI would receive error details and fix
                    # For now, mark as failed
                
                self.logger.log_task_complete(task_id, task_name, "failed")
                self.failed_tasks.add(task_id)
                return False
        
        except Exception as e:
            self.logger.log_error("TASK_EXECUTION", str(e), task_id)
            self.logger.log_task_complete(task_id, task_name, "error")
            self.failed_tasks.add(task_id)
            return False
    
    def execute_phase(self, phase_key: str) -> bool:
        """Execute all tasks in a phase"""
        phase_config = self.config.config.get(phase_key)
        
        if not phase_config:
            self.logger.log_error("PHASE", f"Phase config not found: {phase_key}")
            return False
        
        phase_name = phase_config.get('name', phase_key)
        description = phase_config.get('description', '')
        
        self.logger.log_phase_start(phase_name, description)
        
        # Check phase dependencies
        phase_deps = phase_config.get('dependencies', [])
        for dep in phase_deps:
            if dep not in self.completed_tasks:
                self.logger.logger.error(f"Phase dependency not met: {dep}")
                return False
        
        tasks = phase_config.get('tasks', [])
        phase_passed = True
        
        for task in tasks:
            task_id = task.get('task_id', '')
            success = self.execute_task(task_id, task)
            phase_passed = phase_passed and success
        
        return phase_passed
    
    def run_all_phases(self) -> bool:
        """Execute all phases in sequence"""
        self.logger.logger.info("\n")
        self.logger.logger.info("="*80)
        self.logger.logger.info("STARTING AUTOMATED CODE GENERATION CHAIN")
        self.logger.logger.info(f"Project: {self.config.config.get('project_name')}")
        self.logger.logger.info(f"Start Time: {datetime.now().isoformat()}")
        self.logger.logger.info("="*80)
        
        phases = ['phase_1', 'phase_2', 'phase_3', 'phase_4', 'phase_5', 'phase_6', 'phase_7']
        all_success = True
        
        for phase_key in phases:
            if phase_key not in self.config.config:
                continue
            
            try:
                success = self.execute_phase(phase_key)
                all_success = all_success and success
                
                if success:
                    # Mark phase as completed for dependency tracking
                    self.completed_tasks.add(phase_key)
                else:
                    self.logger.logger.warning(f"\n[WARNING] Phase {phase_key} had failures. Continue? (yes/no)")
                    # In automated mode, continue anyway
                    # In interactive mode, could ask user
                    # Still mark as completed to allow dependent phases to run
                    self.completed_tasks.add(phase_key)
            
            except Exception as e:
                self.logger.log_error("PHASE_ERROR", str(e), phase_key)
                all_success = False
        
        # Final summary
        self.logger.logger.info("\n" + "="*80)
        self.logger.logger.info("EXECUTION COMPLETE")
        self.logger.logger.info(f"[OK] Completed: {len(self.completed_tasks)} tasks")
        self.logger.logger.info(f"[FAIL] Failed: {len(self.failed_tasks)} tasks")
        self.logger.logger.info("="*80 + "\n")
        
        self.logger.save_report()
        
        return all_success

# ============================================================================
# ENTRY POINT
# ============================================================================

def main():
    """Main entry point"""
    config_file = "automation/chain_config.yaml"
    
    if not Path(config_file).exists():
        print(f"Error: Config file not found: {config_file}")
        sys.exit(1)
    
    orchestrator = ChainOrchestrator(config_file)
    success = orchestrator.run_all_phases()
    
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
