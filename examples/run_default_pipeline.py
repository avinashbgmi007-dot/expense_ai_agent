#!/usr/bin/env python3
"""
Example usage of the Agent Pipeline Framework.

This script demonstrates running the default pipeline with the PL-AR-DEV-CR-QA-TW-DO sequence.
"""

import asyncio
import sys
import os

# Add the package to path for direct execution
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from agent_pipeline_framework.core.engine import ExecutionEngine, EngineConfig
from agent_pipeline_framework.utils.results import ResultAggregator


async def main():
    """Run the example pipeline."""

    # Configure the engine
    config = EngineConfig(
        pipelines_dir="agent_pipeline_framework/config/pipelines",
        agents_dir="agent_pipeline_framework/agents",
        logging_level="INFO",
        enable_progress_tracking=True,
    )

    # Create engine and load pipeline
    engine = ExecutionEngine(config)

    try:
        print("Starting Agent Pipeline Framework Demo")
        print("=" * 50)

        # Execute the default pipeline
        results = await engine.execute_pipeline("default")

        print(f"\nPipeline completed! {len(results)} agents executed.")

        # Display results
        for i, result in enumerate(results, 1):
            status = "SUCCESS" if result.success else "FAILED"
            print(f"{i}. {result.agent_name}: {status}")
            if not result.success:
                print(f"   Error: {result.error}")

        # Generate summary report
        aggregator = ResultAggregator()
        aggregator.add_pipeline_results("default", results)
        summary = aggregator.get_summary_report()

        print("\nSummary:")
        print(f"   Success Rate: {summary['overall']['success_rate']:.2%}")
        print(f"   Successful Agents: {summary['overall']['successful_agents']}")
        print(f"   Failed Agents: {summary['overall']['failed_agents']}")

        # Save detailed report
        aggregator.save_report("pipeline_report.json", "json")
        aggregator.save_report("pipeline_report.txt", "txt")
        print("\nReports saved: pipeline_report.json, pipeline_report.txt")
    except Exception as e:
        print(f"Pipeline execution failed: {e}")
        return 1

    return 0


if __name__ == "__main__":
    exit_code = asyncio.run(main())
    sys.exit(exit_code)
