"""
Main execution engine for running pipelines.
"""

import asyncio
import yaml
from pathlib import Path
from typing import Dict, List, Any, Optional
from pydantic import BaseModel
from loguru import logger

from .pipeline import Pipeline, PipelineConfig
from .agent import BaseAgent, AgentConfig, AgentResult
from ..utils.logging import setup_logging
from ..utils.progress import ProgressTracker


class EngineConfig(BaseModel):
    """Configuration for the engine."""

    pipelines_dir: str = "config/pipelines"
    agents_dir: str = "agents"
    logging_level: str = "INFO"
    enable_progress_tracking: bool = True


class ExecutionEngine:
    """Main engine for executing agent pipelines."""

    def __init__(self, config: EngineConfig):
        self.config = config
        self.pipelines: Dict[str, Pipeline] = {}
        self.progress_tracker = (
            ProgressTracker() if config.enable_progress_tracking else None
        )

        setup_logging(config.logging_level)

    def load_pipeline(self, pipeline_name: str) -> Pipeline:
        """
        Load a pipeline configuration and create the pipeline instance.

        Args:
            pipeline_name: Name of the pipeline to load

        Returns:
            Pipeline: The loaded pipeline
        """
        config_path = Path(self.config.pipelines_dir) / f"{pipeline_name}.yaml"
        if not config_path.exists():
            raise FileNotFoundError(f"Pipeline config not found: {config_path}")

        with open(config_path, "r") as f:
            config_data = yaml.safe_load(f)

        pipeline_config = PipelineConfig(**config_data)

        # Load agents
        agents = []
        for agent_config_data in config_data["agents"]:
            agent_config = AgentConfig(**agent_config_data)
            agent = self._load_agent(agent_config)
            agents.append(agent)

        pipeline = Pipeline(pipeline_config, agents)
        self.pipelines[pipeline_name] = pipeline
        return pipeline

    def _load_agent(self, config: AgentConfig) -> BaseAgent:
        """Load an agent instance from configuration."""
        # Dynamic import of agent class
        # Assume agents are in agents/ directory with class name matching config.name
        try:
            # Convert camel case to snake case for module name
            import re

            # Simple camel to snake: insert _ before uppercase, but handle consecutive uppercase
            s1 = re.sub("(.)([A-Z][a-z]+)", r"\1_\2", config.name)
            module_name_part = re.sub("([a-z0-9])([A-Z])", r"\1_\2", s1).lower()
            module_name = f"agent_pipeline_framework.agents.{module_name_part}"
            module = __import__(module_name, fromlist=[config.name])
            agent_class = getattr(module, config.name)
            return agent_class(config)
        except (ImportError, AttributeError) as e:
            raise ValueError(f"Failed to load agent {config.name}: {e}")

    async def execute_pipeline(
        self, pipeline_name: str, context: Optional[Dict[str, Any]] = None
    ) -> List[AgentResult]:
        """
        Execute a pipeline by name.

        Args:
            pipeline_name: Name of the pipeline to execute
            context: Initial context

        Returns:
            List of agent results
        """
        if pipeline_name not in self.pipelines:
            self.load_pipeline(pipeline_name)

        pipeline = self.pipelines[pipeline_name]

        if self.progress_tracker:
            self.progress_tracker.start_pipeline(pipeline_name, len(pipeline.agents))

        try:
            results = await pipeline.execute(context)

            if self.progress_tracker:
                self.progress_tracker.complete_pipeline(pipeline_name)

            return results

        except Exception as e:
            logger.error(f"Pipeline execution failed: {e}")
            if self.progress_tracker:
                self.progress_tracker.fail_pipeline(pipeline_name)
            raise

    async def execute_all_pipelines(
        self, context: Optional[Dict[str, Any]] = None
    ) -> Dict[str, List[AgentResult]]:
        """
        Execute all available pipelines.

        Args:
            context: Initial context for all pipelines

        Returns:
            Dict mapping pipeline names to their results
        """
        results = {}

        # Load all pipeline configs
        pipelines_dir = Path(self.config.pipelines_dir)
        if not pipelines_dir.exists():
            logger.warning(f"Pipelines directory not found: {pipelines_dir}")
            return results

        for config_file in pipelines_dir.glob("*.yaml"):
            pipeline_name = config_file.stem
            try:
                logger.info(f"Executing pipeline: {pipeline_name}")
                pipeline_results = await self.execute_pipeline(pipeline_name, context)
                results[pipeline_name] = pipeline_results
            except Exception as e:
                logger.error(f"Failed to execute pipeline {pipeline_name}: {e}")
                results[pipeline_name] = []

        return results

    def get_pipeline_summary(self, pipeline_name: str) -> Dict[str, Any]:
        """Get summary of a pipeline execution."""
        if pipeline_name not in self.pipelines:
            raise ValueError(f"Pipeline {pipeline_name} not loaded")

        return self.pipelines[pipeline_name].get_summary()
