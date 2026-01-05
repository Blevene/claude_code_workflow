---
name: validate-implementation
description: Pre-implementation validation that checks tech choices against best practices and past precedent. Use BEFORE implementing to catch issues early.
---

# Validate Implementation Plan

Validate technical choices in a plan against current best practices and past precedent before implementation. This catches issues early—before you've written code that needs to be rewritten.

> **Note:** The current year is 2025. When validating tech choices, check against 2024-2025 best practices.

## When to Use

- Before starting `/implement` on a new module
- When a plan uses unfamiliar libraries/patterns
- After creating a design document
- When tech stack decisions feel uncertain
- Before major architectural changes

## Process

### Step 1: Extract Tech Choices

Review the plan and identify all technical decisions:

- Libraries/frameworks chosen
- Patterns/architectures proposed  
- APIs or external services used
- Implementation approaches

Create a checklist:

```markdown
## Tech Choices to Validate
1. [Library X] for [purpose]
2. [Pattern Y] for [purpose]
3. [API Z] for [purpose]
```

### Step 2: Check Past Precedent

Query the artifact index for similar past work:

```bash
# Search for relevant past work
uv run python tools/artifact_query.py "[library/pattern name]"

# Find only successful approaches
uv run python tools/artifact_query.py "[approach]" --outcome SUCCEEDED

# Find what failed (to avoid repeating mistakes)
uv run python tools/artifact_query.py "[approach]" --outcome FAILED
```

Review results for:
- **Succeeded patterns** - Follow these approaches
- **Failed patterns** - Avoid these, note why they failed
- **Similar specs** - Ensure alignment

### Step 3: Research Current Best Practices

For each tech choice, use web search to validate:

```
"[library/pattern] best practices 2024 2025"
"[library] vs alternatives comparison"
"[pattern] deprecated OR recommended"
"[library] security vulnerabilities"
```

Check for:
- Is this still the recommended approach?
- Are there better alternatives now?
- Any known deprecations or issues?
- Security concerns?

### Step 4: Assess Each Choice

For each tech choice, determine status:

| Status | Meaning | Action |
|--------|---------|--------|
| **VALID** | Current best practice | Proceed |
| **OUTDATED** | Better alternatives exist | Consider updating |
| **DEPRECATED** | Should not use | Must change |
| **RISKY** | Security/stability concerns | Review carefully |
| **UNKNOWN** | Couldn't verify | Note as assumption |

### Step 5: Create Validation Report

Document your findings:

```markdown
# Plan Validation: [Plan Name]

## Overall Status: [VALIDATED | NEEDS REVIEW]

## Past Precedent Check

### Relevant Past Work:
- [Session that succeeded with similar approach]
- [Session that failed - pattern to avoid]

### Gaps Identified:
- [Gap 1 if any]

## Tech Choices Validated

### 1. [Tech Choice]
**Purpose:** [What it's used for]
**Status:** VALID | OUTDATED | DEPRECATED | RISKY | UNKNOWN
**Findings:**
- [Finding 1]
- [Finding 2]
**Recommendation:** Keep as-is | Consider alternative | Must change

### 2. [Tech Choice]
...

## Summary

### Validated (Safe to Proceed):
- [Choice 1] ✓
- [Choice 2] ✓

### Needs Review:
- [Choice 3] - [reason]

### Must Change:
- [Choice 4] - [reason and alternative]
```

## Validation Thresholds

**VALIDATED** - Return when:
- All choices are valid, OR
- Only minor suggestions (not blockers)

**NEEDS REVIEW** - Return when:
- Any choice is DEPRECATED
- Any choice is RISKY (security)
- Any choice is significantly OUTDATED
- Critical architectural concerns

## What Doesn't Need Validation

Standard library and well-established tools are always valid:

- Python stdlib: `argparse`, `asyncio`, `json`, `os`, `pathlib`
- Standard patterns: REST APIs, JSON config, environment variables
- Established tools: `pytest`, `git`, `make`, `uv`
- Core frameworks in use: Next.js, React, Tailwind (if already in project)

Focus validation on:
- Third-party libraries (especially newer ones)
- Specific version requirements
- External APIs/services
- Novel architectural patterns
- Libraries you haven't used before

## Example Validation

```markdown
# Plan Validation: Auth Module

## Overall Status: NEEDS REVIEW

## Past Precedent Check

### Relevant Past Work:
- ✓ session-abc: JWT auth succeeded with refresh tokens
- ✗ session-xyz: Cookie-only auth failed (CSRF issues)

## Tech Choices Validated

### 1. jose library for JWT
**Purpose:** Token signing/verification
**Status:** VALID
**Findings:** Active maintenance, 2M+ weekly downloads, no CVEs
**Recommendation:** Keep as-is

### 2. bcrypt for password hashing  
**Purpose:** Password storage
**Status:** VALID
**Findings:** Industry standard, OWASP recommended
**Recommendation:** Keep as-is

### 3. passport.js for OAuth
**Purpose:** Social login
**Status:** OUTDATED
**Findings:** Maintenance mode since 2023, Auth.js (NextAuth) is recommended for Next.js
**Recommendation:** Consider Auth.js instead

## Summary

### Validated: jose ✓, bcrypt ✓
### Needs Review: passport.js → suggest Auth.js
```

## Integration with Workflow

Use this skill:

1. **After `/design`** - Validate architectural choices
2. **Before `/implement`** - Ensure plan is sound
3. **When errors occur** - Check if deprecated patterns are the cause
4. **During code review** - Validate external dependencies

