"""
Base agent classes and interfaces for the agent pipeline framework.
"""

from abc import ABC, abstractmethod
from typing import Any, Dict, Optional
from pydantic import BaseModel


class AgentConfig(BaseModel):
    """Base configuration for agents."""

    name: str
    description: Optional[str] = None
    timeout: Optional[int] = None  # in seconds
    retry_count: int = 0
    retry_delay: float = 1.0  # in seconds


class AgentResult(BaseModel):
    """Result from an agent execution."""

    agent_name: str
    success: bool
    data: Dict[str, Any]
    error: Optional[str] = None
    duration: Optional[float] = None  # in seconds
    metadata: Dict[str, Any] = {}


class BaseAgent(ABC):
    """Abstract base class for all agents."""

    def __init__(self, config: AgentConfig):
        self.config = config

    @abstractmethod
    async def execute(self, context: Dict[str, Any]) -> AgentResult:
        """
        Execute the agent with the given context.

        Args:
            context: Input context containing data from previous agents

        Returns:
            AgentResult: The result of the agent execution
        """
        pass

    def get_name(self) -> str:
        """Get the agent name."""
        return self.config.name

    def get_description(self) -> str:
        """Get the agent description."""
        return self.config.description or f"Agent: {self.config.name}"
