---
name: security-review
description: Security-focused code review and vulnerability assessment. Auto-triggers for security audits, checking for vulnerabilities, reviewing authentication code, or assessing data handling. Critical for pre-release checks.
---

# Security Review Skill

## When to Use
- Before deploying to production
- Reviewing authentication/authorization code
- Assessing data handling
- Checking for OWASP vulnerabilities
- Security-focused code review

## Security Checklist

### 1. Authentication
- [ ] Passwords properly hashed (bcrypt, argon2)
- [ ] Secure session management
- [ ] MFA support where appropriate
- [ ] Secure password reset flow
- [ ] Account lockout after failed attempts

### 2. Authorization
- [ ] Proper access controls on all endpoints
- [ ] No privilege escalation paths
- [ ] Role-based access correctly implemented
- [ ] Resource ownership verified

### 3. Data Protection
- [ ] Sensitive data encrypted at rest
- [ ] Sensitive data encrypted in transit (HTTPS)
- [ ] PII handling compliant
- [ ] Proper data retention/deletion

### 4. Input Validation
- [ ] All external input validated
- [ ] SQL injection prevention (parameterized queries)
- [ ] XSS prevention (output encoding)
- [ ] Command injection prevention
- [ ] Path traversal prevention

### 5. Secrets Management
- [ ] No hardcoded credentials
- [ ] Secrets in environment/vault
- [ ] API keys properly scoped
- [ ] Secrets rotation capability

### 6. Logging & Monitoring
- [ ] Security events logged
- [ ] No sensitive data in logs
- [ ] Log injection prevention
- [ ] Alerting on suspicious activity

## Common Vulnerabilities

### SQL Injection
❌ Bad:
```python
query = f"SELECT * FROM users WHERE id = {user_id}"
```

✅ Good:
```python
query = "SELECT * FROM users WHERE id = %s"
cursor.execute(query, (user_id,))
```

### XSS (Cross-Site Scripting)
❌ Bad:
```html
<div>{user_input}</div>
```

✅ Good:
```html
<div>{escape(user_input)}</div>
```

### Insecure Direct Object Reference
❌ Bad:
```python
def get_order(order_id):
    return Order.get(order_id)  # No ownership check
```

✅ Good:
```python
def get_order(order_id, user):
    order = Order.get(order_id)
    if order.user_id != user.id:
        raise Forbidden()
    return order
```

### Hardcoded Secrets
❌ Bad:
```python
API_KEY = "sk-1234567890abcdef"
```

✅ Good:
```python
API_KEY = os.environ.get("API_KEY")
```

## Search Commands

```bash
# Find potential hardcoded secrets
grep -rn "password\s*=\|secret\s*=\|api_key\s*=\|token\s*=" src/

# Find SQL string formatting
grep -rn "f\".*SELECT\|f\".*INSERT\|f\".*UPDATE\|f\".*DELETE" src/

# Find dangerous functions
grep -rn "eval(\|exec(\|system(\|shell_exec(" src/

# Find unescaped output
grep -rn "innerHTML\|dangerouslySetInnerHTML" src/
```

## Output Format

```markdown
## Security Review: [component/PR]

### Summary
[Overview of security posture]

### Critical 🔴
- [Must fix - active vulnerability]

### High 🟠
- [Should fix - potential vulnerability]

### Medium 🟡
- [Consider fixing - defense in depth]

### Low 🟢
- [Nice to have - hardening]

### Positive Notes ✅
- [Security measures done well]

**Verdict:** SECURE / NEEDS REMEDIATION / CRITICAL ISSUES
```

