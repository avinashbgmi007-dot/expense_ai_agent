"""
Pipeline class for executing a sequence of agents.
"""

import asyncio
import time
from typing import Dict, List, Any, Optional
from pydantic import BaseModel
from loguru import logger

from .agent import BaseAgent, AgentResult, AgentConfig


class PipelineConfig(BaseModel):
    """Configuration for a pipeline."""

    name: str
    description: Optional[str] = None
    agents: List[AgentConfig]
    fail_fast: bool = True  # Stop on first failure
    max_total_time: Optional[int] = None  # in seconds


class Pipeline:
    """Pipeline for executing agents in sequence."""

    def __init__(self, config: PipelineConfig, agents: List[BaseAgent]):
        self.config = config
        self.agents = agents
        self.results: List[AgentResult] = []
        self.context: Dict[str, Any] = {}

        # Validate agents match config
        if len(agents) != len(config.agents):
            raise ValueError("Number of agents does not match pipeline config")

        for i, (agent, agent_config) in enumerate(zip(agents, config.agents)):
            if agent.get_name() != agent_config.name:
                raise ValueError(
                    f"Agent {i} name mismatch: {agent.get_name()} vs {agent_config.name}"
                )

    async def execute(
        self, initial_context: Optional[Dict[str, Any]] = None
    ) -> List[AgentResult]:
        """
        Execute the pipeline.

        Args:
            initial_context: Initial context to start with

        Returns:
            List of agent results
        """
        self.context = initial_context or {}
        self.results = []

        start_time = time.time()
        logger.info(f"Starting pipeline: {self.config.name}")

        for i, agent in enumerate(self.agents):
            agent_config = self.config.agents[i]
            logger.info(
                f"Executing agent {i + 1}/{len(self.agents)}: {agent.get_name()}"
            )

            result = await self._execute_agent_with_retry(agent, agent_config)

            self.results.append(result)
            self.context.update(result.data)  # Merge result data into context

            if not result.success and self.config.fail_fast:
                logger.error(f"Agent {agent.get_name()} failed, stopping pipeline")
                break

            # Check total time limit
            if (
                self.config.max_total_time
                and (time.time() - start_time) > self.config.max_total_time
            ):
                logger.warning("Pipeline exceeded max total time")
                break

        logger.info(f"Pipeline completed: {len(self.results)} agents executed")
        return self.results

    async def _execute_agent_with_retry(
        self, agent: BaseAgent, config: AgentConfig
    ) -> AgentResult:
        """Execute an agent with retry logic."""
        last_error = None

        for attempt in range(config.retry_count + 1):
            try:
                if attempt > 0:
                    logger.info(f"Retrying agent {config.name}, attempt {attempt + 1}")
                    await asyncio.sleep(config.retry_delay)

                start_time = time.time()
                result = await agent.execute(
                    self.context.copy()
                )  # Pass copy to avoid mutation
                result.duration = time.time() - start_time

                if result.success:
                    logger.info(f"Agent {config.name} succeeded")
                    return result
                else:
                    last_error = result.error or "Unknown error"
                    logger.warning(f"Agent {config.name} failed: {last_error}")

            except Exception as e:
                last_error = str(e)
                logger.error(f"Agent {config.name} raised exception: {last_error}")

        # All attempts failed
        return AgentResult(
            agent_name=config.name,
            success=False,
            data={},
            error=last_error,
            metadata={"attempts": config.retry_count + 1},
        )

    def get_summary(self) -> Dict[str, Any]:
        """Get a summary of the pipeline execution."""
        successful = sum(1 for r in self.results if r.success)
        total = len(self.results)
        return {
            "pipeline_name": self.config.name,
            "total_agents": len(self.agents),
            "executed_agents": total,
            "successful_agents": successful,
            "failed_agents": total - successful,
            "success_rate": successful / total if total > 0 else 0,
            "results": [r.dict() for r in self.results],
        }
