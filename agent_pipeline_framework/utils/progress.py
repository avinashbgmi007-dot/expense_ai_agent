"""
Progress tracking utilities.
"""

from typing import Dict, Any
from tqdm.asyncio import tqdm
from loguru import logger


class ProgressTracker:
    """Tracks progress of pipeline executions."""

    def __init__(self):
        self.active_pipelines: Dict[str, tqdm] = {}

    def start_pipeline(self, pipeline_name: str, total_agents: int):
        """Start tracking a pipeline."""
        if pipeline_name in self.active_pipelines:
            logger.warning(f"Pipeline {pipeline_name} already being tracked")

        progress_bar = tqdm(
            total=total_agents,
            desc=f"Pipeline: {pipeline_name}",
            unit="agent",
            ncols=80,
        )
        self.active_pipelines[pipeline_name] = progress_bar

    def update_pipeline(self, pipeline_name: str, increment: int = 1):
        """Update progress for a pipeline."""
        if pipeline_name in self.active_pipelines:
            self.active_pipelines[pipeline_name].update(increment)

    def complete_pipeline(self, pipeline_name: str):
        """Mark a pipeline as completed."""
        if pipeline_name in self.active_pipelines:
            self.active_pipelines[pipeline_name].close()
            del self.active_pipelines[pipeline_name]
            logger.info(f"Pipeline {pipeline_name} completed")

    def fail_pipeline(self, pipeline_name: str):
        """Mark a pipeline as failed."""
        if pipeline_name in self.active_pipelines:
            self.active_pipelines[pipeline_name].close()
            del self.active_pipelines[pipeline_name]
            logger.error(f"Pipeline {pipeline_name} failed")
