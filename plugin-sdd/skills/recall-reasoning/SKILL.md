---
name: recall-reasoning
description: Search past work for relevant decisions, patterns, and approaches. Auto-triggers when discussing similar work, debugging recurring issues, or asking "what did we do before?"
---

# Recall Past Work

Search through previous sessions to find relevant decisions, approaches that worked, and approaches that failed. This skill helps you learn from past experience instead of repeating mistakes.

## When to Use

- Starting work similar to past sessions
- "What did we do last time with X?"
- Looking for patterns that worked before
- Investigating why something was done a certain way
- Debugging an issue encountered previously
- Before implementing something new (check for prior art)

## Usage

### Two Search Systems

| System | Data Source | Purpose |
|--------|-------------|---------|
| **Artifact Index** | Handoffs, specs, plans, ledgers | Session-level learnings |
| **Commit Reasoning** | `.git/claude/commits/*/reasoning.md` | Build attempt history per commit |

### 1. Artifact Index Query (Session Learnings)

```bash
# Search for relevant past work
uv run python tools/artifact_query.py "<query>"

# Search only successful approaches (follow these patterns)
uv run python tools/artifact_query.py "implement agent" --outcome SUCCEEDED

# Search only failed approaches (avoid these patterns)  
uv run python tools/artifact_query.py "hook implementation" --outcome FAILED

# Search specific artifact types
uv run python tools/artifact_query.py "API design" --type specs
uv run python tools/artifact_query.py "login flow" --type handoffs
uv run python tools/artifact_query.py "authentication" --type plans

# Get more results
uv run python tools/artifact_query.py "database schema" --limit 10

# Output as JSON for further processing
uv run python tools/artifact_query.py "OAuth" --json
```

### 2. Commit Reasoning Search (Build Attempts)

Search what was tried during development, keyed to specific commits:

```bash
# Search all commit reasoning
./plugin-sdd/scripts/search-reasoning.sh "authentication"

# Find failed attempts (patterns to AVOID)
./plugin-sdd/scripts/search-reasoning.sh "ImportError" --failed

# Find first-try successes (patterns that work)
./plugin-sdd/scripts/search-reasoning.sh "validation" --passed

# Limit results
./plugin-sdd/scripts/search-reasoning.sh "rate limiting" --limit 5
```

**When to use which:**
- **Artifact Index** - "How did we design X?" / "What was the approach for Y?"
- **Commit Reasoning** - "What failed when we tried X?" / "How many attempts for Y?"

### If Artifact Index is Empty

First, build the index:

```bash
uv run python tools/artifact_index.py --all
```

This indexes:
- `thoughts/shared/handoffs/` - Task handoffs with post-mortems
- `thoughts/shared/plans/` - Implementation plans
- `specs/` - Behavioral specifications
- `thoughts/ledgers/` - Continuity ledgers

### If Commit Reasoning is Empty

Reasoning files are created when using `/commit` instead of `git commit`. Start using:

```
/commit "feat: add login validation"
```

This creates `.git/claude/commits/{hash}/reasoning.md` capturing build attempts.

## What Gets Searched

### Artifact Index Sources

| Source | Content | Why It Matters |
|--------|---------|----------------|
| **Handoffs** | Task summaries, what worked, what failed | Direct learnings from past work |
| **Specs** | Behavioral specs, expected behaviors | Prior requirements and constraints |
| **Plans** | Design documents, approaches | Architectural decisions |
| **Continuity** | Session goals, key learnings | Cross-session insights |
| **Past Queries** | Previous Q&A | Compound learning |

### Commit Reasoning Sources

| Source | Content | Why It Matters |
|--------|---------|----------------|
| **reasoning.md** | Failed attempts, error messages | What NOT to do again |
| **reasoning.md** | Build/test pass counts | Effort estimation |
| **reasoning.md** | Files changed per commit | Code relationship mapping |
| **reasoning.md** | SDD artifacts per commit | Spec/eval coverage |

## Interpreting Results

**Outcome Icons:**
- `✓` = SUCCEEDED - Pattern to **follow**
- `◐` = PARTIAL - Mixed results, review details
- `✗` = FAILED - Pattern to **avoid**
- `?` = UNKNOWN - Not yet evaluated

**Post-Mortem Sections:**
- **What worked** - Approaches that succeeded, repeat these
- **What failed** - Dead ends and why, avoid these
- **Key decisions** - Choices made with rationale

## Process

1. **Query the index first** before implementing something new
2. **Review succeeded handoffs** - Follow patterns that worked
3. **Review failed handoffs** - Avoid patterns that failed
4. **Check related specs** - Ensure alignment with existing specs
5. **Apply learnings** - Incorporate insights into current work

## Examples

### Artifact Index Queries (Design & Approach)

```bash
# Before implementing authentication
uv run python tools/artifact_query.py "authentication login session"

# Finding how we structured something before
uv run python tools/artifact_query.py "database migration schema"

# Checking if we've built similar features
uv run python tools/artifact_query.py "user registration signup"
```

### Commit Reasoning Queries (Build History)

```bash
# Debugging a recurring error - what was tried before?
./plugin-sdd/scripts/search-reasoning.sh "ModuleNotFoundError" --failed

# Before implementing - what patterns worked?
./plugin-sdd/scripts/search-reasoning.sh "validation" --passed

# How many attempts did similar work take?
./plugin-sdd/scripts/search-reasoning.sh "rate limiting"

# Find commits related to specific module
./plugin-sdd/scripts/search-reasoning.sh "src/auth"
```

### Combined Search Strategy

For comprehensive recall, search both systems:

```bash
# 1. Check high-level approach from artifacts
uv run python tools/artifact_query.py "OAuth implementation"

# 2. Check specific build failures from reasoning
./plugin-sdd/scripts/search-reasoning.sh "OAuth" --failed

# 3. Apply learnings to current implementation
```

## Maintaining the Index

The index should be updated when:
- After completing major tasks (handoffs created)
- After creating new specs
- Periodically during long sessions

```bash
# Re-index everything
uv run python tools/artifact_index.py --all

# Index specific types
uv run python tools/artifact_index.py --handoffs
uv run python tools/artifact_index.py --specs
```

## Creating Good Handoffs for Future Recall

When completing tasks, include post-mortem sections:

```markdown
## What Worked
- Approach X succeeded because...
- Pattern Y was effective for...

## What Failed
- Tried Z but it failed because...
- Avoid W approach due to...

## Key Decisions
- Chose A over B because...
- Constraint C drove decision D...
```

This ensures future sessions can learn from your experience.

