"""
Configuration loading utilities.
"""

import yaml
from pathlib import Path
from typing import Dict, Any, Optional


def load_config(config_path: str) -> Dict[str, Any]:
    """
    Load configuration from YAML file.

    Args:
        config_path: Path to the YAML configuration file

    Returns:
        Configuration dictionary
    """
    path = Path(config_path)
    if not path.exists():
        raise FileNotFoundError(f"Configuration file not found: {config_path}")

    with open(path, "r") as f:
        return yaml.safe_load(f)


def load_project_config(
    project_name: str, config_dir: str = "config/projects"
) -> Dict[str, Any]:
    """
    Load project-specific configuration.

    Args:
        project_name: Name of the project
        config_dir: Directory containing project configs

    Returns:
        Project configuration dictionary
    """
    return load_config(f"{config_dir}/{project_name}.yaml")


def merge_configs(
    base_config: Dict[str, Any], override_config: Dict[str, Any]
) -> Dict[str, Any]:
    """
    Merge two configuration dictionaries.

    Args:
        base_config: Base configuration
        override_config: Configuration to override with

    Returns:
        Merged configuration
    """
    merged = base_config.copy()
    for key, value in override_config.items():
        if isinstance(value, dict) and key in merged and isinstance(merged[key], dict):
            merged[key] = merge_configs(merged[key], value)
        else:
            merged[key] = value
    return merged
