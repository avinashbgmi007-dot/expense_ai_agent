#!/usr/bin/env python3
"""
Simulation scenarios for the Agent Pipeline Framework.

Runs three different scenarios:
1. Positive: All agents succeed
2. Negative: Multiple agent failures
3. Neutral: Mixed successes and failures
"""

import asyncio
import sys
import os
from pathlib import Path

# Add the package to path for direct execution
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from agent_pipeline_framework.core.pipeline import PipelineConfig
from agent_pipeline_framework.core.agent import AgentConfig
from agent_pipeline_framework.scenarios.simulator import ScenarioSimulator
from agent_pipeline_framework.utils.results import ResultAggregator
from agent_pipeline_framework.utils.logging import setup_logging


def create_pipeline_config() -> PipelineConfig:
    """Create the PL-AR-DEV-CR-QA-TW-DO pipeline configuration."""
    return PipelineConfig(
        name="pl_ar_dev_cr_qa_tw_do_simulation",
        description="PL-AR-DEV-CR-QA-TW-DO sequence simulation",
        agents=[
            AgentConfig(name="Planning", timeout=30, retry_count=1, retry_delay=1.0),
            AgentConfig(
                name="AnalysisRequirements", timeout=45, retry_count=1, retry_delay=1.0
            ),
            AgentConfig(
                name="Development", timeout=120, retry_count=2, retry_delay=2.0
            ),
            AgentConfig(name="CodeReview", timeout=60, retry_count=1, retry_delay=1.5),
            AgentConfig(name="QA", timeout=90, retry_count=2, retry_delay=1.0),
            AgentConfig(name="Testing", timeout=75, retry_count=1, retry_delay=2.0),
            AgentConfig(name="Deployment", timeout=60, retry_count=3, retry_delay=3.0),
            AgentConfig(name="Operations", timeout=30, retry_count=1, retry_delay=1.0),
        ],
        fail_fast=False,  # Continue on failures for analysis
        max_total_time=600,
    )


async def run_scenario(
    scenario_name: str,
    pipeline_config: PipelineConfig,
    agent_success_rates: dict,
    description: str,
) -> dict:
    """
    Run a simulation scenario.

    Args:
        scenario_name: Name of the scenario
        pipeline_config: Pipeline configuration
        agent_success_rates: Dict mapping agent names to success rates
        description: Description of the scenario

    Returns:
        Dict with scenario results and analysis
    """
    print(f"\n{'=' * 60}")
    print(f"Running Scenario: {scenario_name}")
    print(f"{'=' * 60}")
    print(f"Description: {description}")
    print()

    # Create mock agents with specific success rates
    from agent_pipeline_framework.scenarios.simulator import MockAgent

    mock_agents = []
    for agent_config in pipeline_config.agents:
        success_rate = agent_success_rates.get(agent_config.name, 0.9)
        mock_agent = MockAgent(agent_config, success_rate, 0.5)
        mock_agents.append(mock_agent)

    # Create pipeline with mock agents
    from agent_pipeline_framework.core.pipeline import Pipeline

    pipeline = Pipeline(pipeline_config, mock_agents)

    # Run simulation
    print("Executing pipeline simulation...")
    results = await pipeline.execute()

    # Generate analysis
    successful_agents = sum(1 for r in results if r.success)
    total_agents = len(results)
    success_rate = successful_agents / total_agents if total_agents > 0 else 0

    total_execution_time = sum(r.duration or 0 for r in results)
    avg_execution_time = total_execution_time / total_agents if total_agents > 0 else 0

    failed_agents = [r.agent_name for r in results if not r.success]

    # Create detailed report
    aggregator = ResultAggregator()
    aggregator.add_pipeline_results(scenario_name, results)
    summary = aggregator.get_summary_report()

    # Save reports
    report_dir = Path("simulation_reports")
    report_dir.mkdir(exist_ok=True)
    json_file = report_dir / f"{scenario_name}_report.json"
    txt_file = report_dir / f"{scenario_name}_report.txt"

    aggregator.save_report(str(json_file), "json")
    aggregator.save_report(str(txt_file), "txt")

    analysis = {
        "scenario_name": scenario_name,
        "description": description,
        "agent_success_rates": agent_success_rates,
        "results": results,
        "summary": summary,
        "metrics": {
            "total_agents": total_agents,
            "successful_agents": successful_agents,
            "failed_agents": len(failed_agents),
            "success_rate": success_rate,
            "total_execution_time": total_execution_time,
            "avg_execution_time": avg_execution_time,
            "failed_agent_names": failed_agents,
        },
        "reports": {"json": str(json_file), "txt": str(txt_file)},
    }

    return analysis


def analyze_scenario(analysis: dict) -> str:
    """Generate detailed analysis text for a scenario."""
    metrics = analysis["metrics"]
    scenario = analysis["scenario_name"]

    analysis_text = f"""
SCENARIO ANALYSIS: {scenario.upper()}

Configuration:
- Agent Success Rates: {analysis["agent_success_rates"]}

Performance Metrics:
- Total Agents: {metrics["total_agents"]}
- Successful Agents: {metrics["successful_agents"]}
- Failed Agents: {metrics["failed_agents"]}
- Success Rate: {metrics["success_rate"]:.1%}
- Total Execution Time: {metrics["total_execution_time"]:.2f}s
- Average Execution Time per Agent: {metrics["avg_execution_time"]:.2f}s

Failed Agents: {", ".join(metrics["failed_agent_names"]) if metrics["failed_agent_names"] else "None"}

Detailed Results:
"""

    for i, result in enumerate(analysis["results"], 1):
        status = "SUCCESS" if result.success else "FAILED"
        analysis_text += f"{i}. {result.agent_name}: {status}"
        if result.duration:
            analysis_text += f" ({result.duration:.2f}s)"
        if not result.success and result.error:
            analysis_text += f" - Error: {result.error}"
        analysis_text += "\n"

    # Recommendations
    recommendations = []
    if metrics["success_rate"] == 1.0:
        recommendations.append("Perfect execution - no improvements needed")
    elif metrics["success_rate"] >= 0.75:
        recommendations.append("Good success rate - monitor failed agents for patterns")
        if metrics["failed_agents"] > 0:
            recommendations.append(
                f"Investigate failures in: {', '.join(metrics['failed_agent_names'])}"
            )
    else:
        recommendations.append(
            "Low success rate - review agent configurations and retry policies"
        )
        recommendations.append(
            "Consider increasing timeout values or reducing agent complexity"
        )
        recommendations.append("Check for systemic issues in failed agents")

    if metrics["avg_execution_time"] > 10.0:
        recommendations.append(
            "High execution times - consider optimizing agent implementations"
        )
    elif metrics["avg_execution_time"] < 1.0:
        recommendations.append(
            "Very fast execution - ensure agents are performing adequate work"
        )

    analysis_text += f"\nRecommendations:\n" + "\n".join(
        f"- {rec}" for rec in recommendations
    )

    analysis_text += f"\n\nReports saved to: {analysis['reports']['txt']}"

    return analysis_text


async def main():
    """Run all simulation scenarios."""
    setup_logging("INFO")

    print("Agent Pipeline Framework - Simulation Scenarios")
    print("=" * 60)

    # Create pipeline configuration
    pipeline_config = create_pipeline_config()

    # Define scenarios
    scenarios = [
        {
            "name": "positive_scenario",
            "description": "All agents succeed with high reliability",
            "agent_success_rates": {
                "Planning": 1.0,
                "AnalysisRequirements": 1.0,
                "Development": 1.0,
                "CodeReview": 1.0,
                "QA": 1.0,
                "Testing": 1.0,
                "Deployment": 1.0,
                "Operations": 1.0,
            },
        },
        {
            "name": "negative_scenario",
            "description": "Multiple agent failures testing error handling",
            "agent_success_rates": {
                "Planning": 0.9,
                "AnalysisRequirements": 0.7,
                "Development": 0.5,
                "CodeReview": 0.8,
                "QA": 0.3,
                "Testing": 0.6,
                "Deployment": 0.2,
                "Operations": 0.4,
            },
        },
        {
            "name": "neutral_scenario",
            "description": "Mixed successes and failures with recovery",
            "agent_success_rates": {
                "Planning": 1.0,
                "AnalysisRequirements": 0.8,
                "Development": 1.0,
                "CodeReview": 0.6,
                "QA": 1.0,
                "Testing": 0.7,
                "Deployment": 0.9,
                "Operations": 1.0,
            },
        },
    ]

    # Run all scenarios
    all_analyses = []
    for scenario in scenarios:
        analysis = await run_scenario(
            scenario["name"],
            pipeline_config,
            scenario["agent_success_rates"],
            scenario["description"],
        )
        all_analyses.append(analysis)

    # Print comprehensive analysis
    print("\n" + "=" * 80)
    print("COMPREHENSIVE SIMULATION ANALYSIS")
    print("=" * 80)

    for analysis in all_analyses:
        print(analyze_scenario(analysis))
        print("\n" + "-" * 80)

    # Overall summary
    print("\nOVERALL SUMMARY ACROSS SCENARIOS")
    print("-" * 40)

    total_scenarios = len(all_analyses)
    avg_success_rate = (
        sum(a["metrics"]["success_rate"] for a in all_analyses) / total_scenarios
    )
    total_failed_agents = sum(a["metrics"]["failed_agents"] for a in all_analyses)
    avg_execution_time = (
        sum(a["metrics"]["total_execution_time"] for a in all_analyses)
        / total_scenarios
    )

    print(f"Total Scenarios Run: {total_scenarios}")
    print(f"Average Success Rate: {avg_success_rate:.1%}")
    print(f"Total Failed Agents Across Scenarios: {total_failed_agents}")
    print(f"Average Total Execution Time: {avg_execution_time:.2f}s")

    print(f"\nSimulation completed successfully!")
    print(f"Individual reports saved in: simulation_reports/")

    return 0


if __name__ == "__main__":
    exit_code = asyncio.run(main())
    sys.exit(exit_code)
