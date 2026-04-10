"""
Scenario simulation utilities for testing pipelines.
"""

import asyncio
import random
from typing import Dict, List, Any, Optional
from loguru import logger

from ..core.agent import BaseAgent, AgentConfig, AgentResult
from ..core.pipeline import Pipeline, PipelineConfig


class MockAgent(BaseAgent):
    """Mock agent for simulation purposes."""

    def __init__(
        self, config: AgentConfig, success_rate: float = 0.9, delay: float = 0.1
    ):
        super().__init__(config)
        self.success_rate = success_rate
        self.delay = delay

    async def execute(self, context: Dict[str, Any]) -> AgentResult:
        """Simulate agent execution."""
        await asyncio.sleep(self.delay)

        success = random.random() < self.success_rate
        data = {"mock_output": f"Output from {self.config.name}"} if success else {}
        error = None if success else f"Simulated failure in {self.config.name}"

        return AgentResult(
            agent_name=self.config.name,
            success=success,
            data=data,
            error=error,
            duration=self.delay,
        )


class ScenarioSimulator:
    """Simulates pipeline execution scenarios."""

    def __init__(self, success_rate: float = 0.9, agent_delay: float = 0.1):
        self.success_rate = success_rate
        self.agent_delay = agent_delay

    def create_mock_pipeline(self, pipeline_config: PipelineConfig) -> Pipeline:
        """
        Create a pipeline with mock agents for simulation.

        Args:
            pipeline_config: Configuration for the pipeline

        Returns:
            Pipeline with mock agents
        """
        mock_agents = []
        for agent_config in pipeline_config.agents:
            mock_agent = MockAgent(agent_config, self.success_rate, self.agent_delay)
            mock_agents.append(mock_agent)

        return Pipeline(pipeline_config, mock_agents)

    async def simulate_pipeline(
        self,
        pipeline_config: PipelineConfig,
        initial_context: Optional[Dict[str, Any]] = None,
    ) -> List[AgentResult]:
        """
        Simulate execution of a pipeline.

        Args:
            pipeline_config: Pipeline configuration
            initial_context: Initial context

        Returns:
            List of simulated agent results
        """
        logger.info(f"Simulating pipeline: {pipeline_config.name}")
        pipeline = self.create_mock_pipeline(pipeline_config)
        results = await pipeline.execute(initial_context)
        logger.info(f"Simulation completed for pipeline: {pipeline_config.name}")
        return results

    async def simulate_failure_scenario(
        self, pipeline_config: PipelineConfig, failing_agents: List[str]
    ) -> List[AgentResult]:
        """
        Simulate a scenario where specific agents fail.

        Args:
            pipeline_config: Pipeline configuration
            failing_agents: List of agent names that should fail

        Returns:
            List of simulated agent results
        """
        logger.info(f"Simulating failure scenario for pipeline: {pipeline_config.name}")

        # Create mock agents with forced failures
        mock_agents = []
        for agent_config in pipeline_config.agents:
            success_rate = 0.0 if agent_config.name in failing_agents else 1.0
            mock_agent = MockAgent(agent_config, success_rate, self.agent_delay)
            mock_agents.append(mock_agent)

        pipeline = Pipeline(pipeline_config, mock_agents)
        results = await pipeline.execute()
        return results

    async def stress_test_pipeline(
        self, pipeline_config: PipelineConfig, iterations: int = 10
    ) -> Dict[str, Any]:
        """
        Run multiple iterations of pipeline simulation for stress testing.

        Args:
            pipeline_config: Pipeline configuration
            iterations: Number of iterations to run

        Returns:
            Summary statistics from stress test
        """
        logger.info(
            f"Running stress test for pipeline: {pipeline_config.name} ({iterations} iterations)"
        )

        all_results = []
        for i in range(iterations):
            logger.debug(f"Stress test iteration {i + 1}/{iterations}")
            results = await self.simulate_pipeline(pipeline_config)
            all_results.append(results)

        # Calculate statistics
        total_runs = iterations
        successful_runs = sum(
            1 for results in all_results if all(r.success for r in results)
        )

        agent_success_counts = {}
        for agent_config in pipeline_config.agents:
            agent_name = agent_config.name
            successes = sum(
                1
                for results in all_results
                for r in results
                if r.agent_name == agent_name and r.success
            )
            agent_success_counts[agent_name] = successes

        return {
            "total_iterations": total_runs,
            "successful_iterations": successful_runs,
            "success_rate": successful_runs / total_runs,
            "agent_success_rates": {
                name: count / total_runs for name, count in agent_success_counts.items()
            },
        }
