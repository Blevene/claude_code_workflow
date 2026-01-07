---
name: adk-development
description: Agent Development Kit (ADK) patterns and best practices for building multi-agent systems. Auto-triggers for agent architecture, tool integration, session management, evaluation, or ADK deployment.
---

# ADK Development Skill

## When to Use
- Building AI agents with Google's Agent Development Kit
- Designing multi-agent systems
- Integrating tools and callbacks
- Managing sessions and state
- Implementing agent evaluation
- Deploying agents to production
- Working with artifacts and memory

## Core Concepts

### Agent Types

**LlmAgent**: Language model-powered agents for complex reasoning
- Use for conversational agents
- Handles natural language understanding
- Supports planning and tool use

**Workflow Agents**: Deterministic controllers
- `SequentialAgent`: Execute steps in order
- `ParallelAgent`: Execute steps concurrently
- `LoopAgent`: Repeat steps until condition met

### Key Primitives

**Agent**: Fundamental worker unit for specific tasks
- Can be specialized for domains
- Supports hierarchical composition
- Can delegate to other agents

**Tool**: Extends agent capabilities
- `FunctionTool`: Custom functions
- `AgentTool`: Use other agents as tools
- Built-in tools: Search, Code Execution, Databases
- Supports long-running/async operations

**Session & State**: Conversation context
- `Session`: Single conversation instance
- `State`: Working memory for that session
- `Events`: Conversation history (messages, tool calls, replies)

**Memory**: Long-term user context
- Recalls information across multiple sessions
- Distinct from short-term session `State`
- Enables personalized experiences

**Artifact**: File and binary data management
- Save/load files during execution
- Version control for artifacts
- Supports images, PDFs, documents

**Callbacks**: Custom code at execution points
- Pre/post tool execution
- State modification hooks
- Logging and monitoring

## Architecture Patterns

### 1. Single Agent Pattern

```python
from google.adk import LlmAgent
from google.adk.model import GeminiModel

# Simple conversational agent
agent = LlmAgent(
    name="assistant",
    model=GeminiModel("gemini-2.0-flash-exp"),
    instruction="You are a helpful assistant."
)
```

### 2. Multi-Agent System

```python
# Hierarchical agent composition
orchestrator = LlmAgent(
    name="orchestrator",
    tools=[
        AgentTool(backend_agent),
        AgentTool(frontend_agent),
        AgentTool(analyst_agent)
    ]
)

# Agents can delegate to specialized agents
backend_agent = LlmAgent(
    name="backend",
    instruction="Implement backend APIs"
)
```

### 3. Workflow Orchestration

```python
from google.adk import SequentialAgent, ParallelAgent

# Sequential pipeline
pipeline = SequentialAgent([
    data_collection_agent,
    processing_agent,
    analysis_agent
])

# Parallel execution
parallel = ParallelAgent([
    feature_a_agent,
    feature_b_agent,
    feature_c_agent
])
```

## Tool Integration

### Custom Function Tools

```python
from google.adk.tool import FunctionTool

def calculate_total(items):
    """Calculate total price of items."""
    return sum(item['price'] for item in items)

tool = FunctionTool(
    name="calculate_total",
    func=calculate_total,
    description="Calculates total price"
)

agent = LlmAgent(
    tools=[tool]
)
```

### Agent as Tool

```python
from google.adk.tool import AgentTool

# Use specialized agent as a tool
code_reviewer = LlmAgent(
    name="code_reviewer",
    instruction="Review code for quality and security"
)

main_agent = LlmAgent(
    tools=[AgentTool(code_reviewer)]
)
```

### Built-in Tools

- **Google Search**: `geminitool.GoogleSearch`
- **Code Execution**: Built-in code runner
- **Database Tools**: Query and update databases
- **Vertex AI Search**: Enterprise document grounding

## Session Management

### Creating Sessions

```python
from google.adk import Session

session = Session(
    user_id="user123",
    session_id="session456"
)

# Run agent with session
events = agent.run(
    session=session,
    message="What's the weather?"
)
```

### State Management

```python
# Access session state
state = session.state

# Update state
state["user_preferences"] = {"theme": "dark"}

# State persists across turns
```

### Event Handling

```python
for event in events:
    if event.is_user_message():
        print(f"User: {event.content}")
    elif event.is_agent_response():
        print(f"Agent: {event.content}")
    elif event.is_tool_call():
        print(f"Tool: {event.tool_name}")
```

## Memory Integration

### Long-term Memory

```python
from google.adk.memory import MemoryService

# Store user information
memory_service.store(
    user_id="user123",
    key="preferences",
    value={"language": "en", "timezone": "UTC"}
)

# Retrieve across sessions
preferences = memory_service.retrieve(
    user_id="user123",
    key="preferences"
)
```

## Artifact Management

### Saving Artifacts

```python
# Agent can save files
artifact = session.save_artifact(
    name="report.pdf",
    content=pdf_bytes,
    metadata={"type": "report", "version": "1.0"}
)
```

### Loading Artifacts

```python
# Load artifact in later session
artifact = session.load_artifact("report.pdf")
```

## Planning Capabilities

### ReAct Planning

```python
# Agent can break down complex goals
agent = LlmAgent(
    name="planner",
    enable_planning=True,
    instruction="Break down tasks into steps"
)

# Agent will create and execute plans
events = agent.run(
    message="Build a web application with auth and billing"
)
```

## Evaluation

### Creating Evaluation Datasets

```python
from google.adk.eval import EvaluationDataset

dataset = EvaluationDataset([
    {
        "input": "What is the weather?",
        "expected_output": "I can help you check the weather.",
        "context": {}
    }
])
```

### Running Evaluations

```bash
# CLI evaluation
adk eval run --dataset eval_dataset.json --agent my_agent

# Programmatic evaluation
results = agent.evaluate(dataset)
```

### Evaluation Metrics

- Response quality
- Tool usage correctness
- Multi-turn coherence
- Safety and guardrails

## Deployment

### Local Development

```bash
# Run agent locally
adk run --agent my_agent

# Developer UI
adk dev --port 8000
```

### REST API Server

```python
from google.adk.server import ADKServer

server = ADKServer(
    agent_loader=agent_loader,
    port=8000
)
server.start()
```

### API Endpoints

- `POST /run`: Execute agent run
- `POST /run_sse`: Streaming execution
- `GET /docs`: API documentation

## Streaming Support

### Bidirectional Streaming

```python
# Text streaming
for chunk in agent.run_stream(session, message):
    print(chunk, end="", flush=True)

# Audio streaming (Multimodal Live API)
events = agent.run(
    session=session,
    audio_input=audio_bytes,
    stream_audio=True
)
```

## Grounding with Vertex AI Search

### Enterprise Document Grounding

```python
from google.adk.grounding import VertexAISearchGrounding

grounding = VertexAISearchGrounding(
    project_id="your-project",
    datastore_id="your-datastore"
)

agent = LlmAgent(
    grounding=grounding,
    instruction="Answer using company documents"
)
```

### Grounding Metadata

```python
for event in events:
    if event.grounding_metadata:
        # Access source documents
        chunks = event.grounding_metadata.grounding_chunks
        supports = event.grounding_metadata.grounding_supports
        
        # Display citations
        for chunk in chunks:
            print(f"Source: {chunk.title}")
```

## Best Practices

### 1. Agent Design
- Single responsibility per agent
- Clear instructions and descriptions
- Appropriate tool selection
- Error handling in tools

### 2. Multi-Agent Coordination
- Use workflow agents for predictable pipelines
- Use LLM agents for dynamic routing
- Pass context between agents
- Avoid circular dependencies

### 3. State Management
- Keep state minimal and focused
- Use memory for cross-session data
- Clear state when appropriate
- Version state schemas

### 4. Tool Design
- Idempotent operations when possible
- Clear error messages
- Validate inputs
- Handle async operations properly

### 5. Evaluation
- Test multi-turn conversations
- Include edge cases
- Measure real-world scenarios
- Iterate based on results

### 6. Security
- Validate all inputs
- Sanitize tool outputs
- Implement rate limiting
- Protect sensitive data in state/memory

## Output Format

```markdown
## ADK Agent Design: [agent_name]

### Architecture
- Type: [LlmAgent/SequentialAgent/ParallelAgent]
- Purpose: [description]

### Tools
- [tool_name]: [description]
- [tool_name]: [description]

### Session & State
- State schema: [key fields]
- Memory requirements: [what to persist]

### Evaluation Plan
- Test scenarios: [list]
- Success criteria: [metrics]

### Deployment
- Environment: [local/production]
- Configuration: [key settings]
```

## Quick Reference

### Supported Languages
- Python (primary)
- Go
- Java
- TypeScript

### Model Support
- Optimized for Google Gemini models
- Extensible via `BaseLlm` interface
- Supports open-source/fine-tuned models

### Key Resources
- [ADK Documentation](https://google.github.io/adk-docs/)
- [Python API Reference](https://google.github.io/adk-docs/api-reference/python/)
- [Quickstart Guides](https://google.github.io/adk-docs/get-started/)

