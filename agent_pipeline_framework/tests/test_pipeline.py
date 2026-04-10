"""
Tests for the agent pipeline framework.
"""

import pytest
import asyncio
from unittest.mock import AsyncMock

from agent_pipeline_framework.core.agent import AgentConfig, AgentResult
from agent_pipeline_framework.core.pipeline import Pipeline, PipelineConfig
from agent_pipeline_framework.scenarios.simulator import ScenarioSimulator, MockAgent


class TestMockAgent:
    """Test the mock agent."""

    @pytest.mark.asyncio
    async def test_mock_agent_success(self):
        config = AgentConfig(name="TestAgent")
        agent = MockAgent(config, success_rate=1.0, delay=0.01)

        result = await agent.execute({})

        assert result.success is True
        assert result.agent_name == "TestAgent"
        assert "mock_output" in result.data

    @pytest.mark.asyncio
    async def test_mock_agent_failure(self):
        config = AgentConfig(name="TestAgent")
        agent = MockAgent(config, success_rate=0.0, delay=0.01)

        result = await agent.execute({})

        assert result.success is False
        assert result.error is not None


class TestPipeline:
    """Test the pipeline functionality."""

    def test_pipeline_creation(self):
        config = PipelineConfig(
            name="test_pipeline",
            agents=[
                AgentConfig(name="Agent1"),
                AgentConfig(name="Agent2"),
            ],
        )

        agents = [
            MockAgent(AgentConfig(name="Agent1")),
            MockAgent(AgentConfig(name="Agent2")),
        ]

        pipeline = Pipeline(config, agents)

        assert pipeline.config.name == "test_pipeline"
        assert len(pipeline.agents) == 2

    @pytest.mark.asyncio
    async def test_pipeline_execution_success(self):
        config = PipelineConfig(
            name="test_pipeline",
            agents=[
                AgentConfig(name="Agent1"),
                AgentConfig(name="Agent2"),
            ],
        )

        agents = [
            MockAgent(AgentConfig(name="Agent1"), success_rate=1.0),
            MockAgent(AgentConfig(name="Agent2"), success_rate=1.0),
        ]

        pipeline = Pipeline(config, agents)
        results = await pipeline.execute()

        assert len(results) == 2
        assert all(r.success for r in results)

    @pytest.mark.asyncio
    async def test_pipeline_execution_with_failure(self):
        config = PipelineConfig(
            name="test_pipeline",
            agents=[
                AgentConfig(name="Agent1"),
                AgentConfig(name="Agent2"),
            ],
            fail_fast=True,
        )

        agents = [
            MockAgent(AgentConfig(name="Agent1"), success_rate=1.0),
            MockAgent(AgentConfig(name="Agent2"), success_rate=0.0),
        ]

        pipeline = Pipeline(config, agents)
        results = await pipeline.execute()

        assert len(results) == 2
        assert results[0].success is True
        assert results[1].success is False


class TestScenarioSimulator:
    """Test the scenario simulator."""

    @pytest.mark.asyncio
    async def test_scenario_simulation(self):
        simulator = ScenarioSimulator(success_rate=1.0, agent_delay=0.01)

        config = PipelineConfig(
            name="test_pipeline",
            agents=[
                AgentConfig(name="Agent1"),
                AgentConfig(name="Agent2"),
            ],
        )

        results = await simulator.simulate_pipeline(config)

        assert len(results) == 2
        assert all(r.success for r in results)

    @pytest.mark.asyncio
    async def test_failure_scenario(self):
        simulator = ScenarioSimulator()

        config = PipelineConfig(
            name="test_pipeline",
            agents=[
                AgentConfig(name="Agent1"),
                AgentConfig(name="Agent2"),
            ],
        )

        results = await simulator.simulate_failure_scenario(config, ["Agent2"])

        assert len(results) == 2
        assert results[0].success is True
        assert results[1].success is False
