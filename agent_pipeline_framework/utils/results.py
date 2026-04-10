"""
Result aggregation and reporting utilities.
"""

import json
from pathlib import Path
from typing import Dict, List, Any
from datetime import datetime

from ..core.agent import AgentResult


class ResultAggregator:
    """Aggregates and reports on pipeline execution results."""

    def __init__(self):
        self.results: Dict[str, List[AgentResult]] = {}

    def add_pipeline_results(self, pipeline_name: str, results: List[AgentResult]):
        """Add results for a pipeline."""
        self.results[pipeline_name] = results

    def get_summary_report(self) -> Dict[str, Any]:
        """Generate a summary report of all results."""
        report = {
            "timestamp": datetime.now().isoformat(),
            "total_pipelines": len(self.results),
            "pipeline_summaries": {},
        }

        total_agents = 0
        total_successful = 0

        for pipeline_name, results in self.results.items():
            successful = sum(1 for r in results if r.success)
            total_agents += len(results)
            total_successful += successful

            report["pipeline_summaries"][pipeline_name] = {
                "total_agents": len(results),
                "successful_agents": successful,
                "failed_agents": len(results) - successful,
                "success_rate": successful / len(results) if results else 0,
            }

        report["overall"] = {
            "total_agents": total_agents,
            "successful_agents": total_successful,
            "failed_agents": total_agents - total_successful,
            "success_rate": total_successful / total_agents if total_agents > 0 else 0,
        }

        return report

    def save_report(self, output_path: str, format: str = "json"):
        """
        Save the summary report to a file.

        Args:
            output_path: Path to save the report
            format: Format to save in ('json' or 'txt')
        """
        report = self.get_summary_report()

        if format == "json":
            with open(output_path, "w") as f:
                json.dump(report, f, indent=2)
        elif format == "txt":
            with open(output_path, "w") as f:
                f.write("Pipeline Execution Report\n")
                f.write("=" * 50 + "\n")
                f.write(f"Generated: {report['timestamp']}\n\n")

                f.write(f"Total Pipelines: {report['total_pipelines']}\n")
                overall = report["overall"]
                f.write(f"Overall Success Rate: {overall['success_rate']:.2%}\n")
                f.write(f"Total Agents: {overall['total_agents']}\n")
                f.write(f"Successful: {overall['successful_agents']}\n")
                f.write(f"Failed: {overall['failed_agents']}\n\n")

                for pipeline, summary in report["pipeline_summaries"].items():
                    f.write(f"Pipeline: {pipeline}\n")
                    f.write(f"  Success Rate: {summary['success_rate']:.2%}\n")
                    f.write(
                        f"  Agents: {summary['successful_agents']}/{summary['total_agents']}\n"
                    )
                    f.write("\n")
        else:
            raise ValueError(f"Unsupported format: {format}")

    def get_failed_agents(self) -> List[Dict[str, Any]]:
        """Get list of failed agent executions."""
        failed = []
        for pipeline_name, results in self.results.items():
            for result in results:
                if not result.success:
                    failed.append(
                        {
                            "pipeline": pipeline_name,
                            "agent": result.agent_name,
                            "error": result.error,
                            "duration": result.duration,
                        }
                    )
        return failed
