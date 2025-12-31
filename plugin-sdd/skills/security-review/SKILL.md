---
name: security-review
description: Security-focused code review and vulnerability assessment. Auto-triggers for security audits, vulnerability checks, authentication/authorization review, or sensitive data handling.
---

# Security Review Skill

## When to Use
- Reviewing authentication/authorization code
- Checking for vulnerabilities
- Auditing sensitive data handling
- Pre-release security assessment

## Security Checklist

### 1. Authentication
- [ ] Passwords properly hashed (bcrypt, argon2)
- [ ] Secure session management
- [ ] Token expiration implemented
- [ ] No credentials in code or logs

### 2. Authorization
- [ ] Role-based access control
- [ ] Resource ownership verification
- [ ] Proper permission checks
- [ ] No privilege escalation paths

### 3. Input Validation
- [ ] All external input validated
- [ ] SQL/NoSQL injection prevention
- [ ] XSS prevention
- [ ] Command injection prevention
- [ ] Path traversal prevention

### 4. Data Protection
- [ ] Sensitive data encrypted at rest
- [ ] Secure transport (HTTPS)
- [ ] PII handling compliant
- [ ] Secure data deletion

### 5. Error Handling
- [ ] No sensitive info in errors
- [ ] Generic error messages to users
- [ ] Detailed logs for debugging (not exposed)

## Security Specs

When writing security-related specs:

```markdown
# SPEC-SEC-001: Authentication

## Invariants (MUST always hold)
- Passwords are NEVER stored in plaintext
- Failed login attempts are rate-limited
- Session tokens expire after inactivity
- Logout invalidates all session tokens

## Behaviors
| Given | When | Then |
|-------|------|------|
| Valid credentials | Login attempt | Session created |
| Invalid password | Login attempt | Generic error, no detail leak |
| 5 failed attempts | Login attempt | Account temporarily locked |
```

## Security Commands

```bash
# Check for secrets in code
grep -rn "password\|secret\|api_key\|token" src/ --include="*.py"

# Check for debug statements
grep -rn "print\|console.log\|debugger" src/

# Run security-focused tests
uv run pytest tests/security/ -v
```

## Output Format

```markdown
## Security Review: [component]

### Risk Level
[low/medium/high/critical]

### Vulnerabilities Found
- [description and location]

### Recommendations
- [specific fixes]

### Compliance
- [ ] OWASP Top 10 checked
- [ ] Input validation complete
- [ ] No sensitive data exposed
```
