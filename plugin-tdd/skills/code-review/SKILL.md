---
name: code-review
description: Systematic code review focusing on quality, security, and maintainability. Auto-triggers for PR reviews, code quality checks, reviewing changes, or assessing code before merge. Complements @overseer governance checks.
---

# Code Review Skill

## When to Use
- Reviewing pull requests or diffs
- Assessing code quality before merge
- Finding security vulnerabilities
- Checking for common anti-patterns
- Pre-commit validation

## Review Checklist

### 1. Correctness
- [ ] Logic is correct and handles edge cases
- [ ] Error handling is comprehensive
- [ ] No race conditions or concurrency issues
- [ ] State mutations are intentional and safe

### 2. Security
- [ ] No hardcoded secrets or credentials
- [ ] Input validation on all external data
- [ ] SQL/NoSQL injection prevention
- [ ] XSS prevention (frontend)
- [ ] Proper authentication/authorization checks
- [ ] Sensitive data not logged

### 3. Quality
- [ ] Code is readable and self-documenting
- [ ] Functions are focused (single responsibility)
- [ ] No code duplication (DRY)
- [ ] Appropriate error messages
- [ ] No TODO/FIXME left unaddressed

### 4. Performance
- [ ] No N+1 queries
- [ ] Appropriate caching considered
- [ ] No unnecessary loops or allocations
- [ ] Async operations where beneficial

### 5. Testing
- [ ] Tests cover happy path
- [ ] Tests cover error cases
- [ ] Tests cover edge cases
- [ ] No flaky test patterns

## Review Commands

```bash
# View recent changes
git diff HEAD~1

# Check for debug statements
grep -rn "console.log\|print(\|debugger\|pdb" src/

# Check for TODOs
grep -rn "TODO\|FIXME\|XXX\|HACK" src/

# Run tests
uv run pytest tests/ -v
```

## Output Format

```markdown
## Code Review: [file/PR]

### Summary
[1-2 sentence overview]

### Critical Issues 🔴
- [Must fix before merge]

### Warnings 🟡  
- [Should fix, but not blocking]

### Suggestions 🟢
- [Nice to have improvements]

### Positive Notes ✅
- [What's done well]

**Verdict:** APPROVE / REQUEST CHANGES / NEEDS DISCUSSION
```

