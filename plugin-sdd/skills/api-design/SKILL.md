---
name: api-design
description: API design patterns and best practices. Auto-triggers for designing endpoints, API contracts, REST/GraphQL design, or service interfaces.
---

# API Design Skill

## When to Use
- Designing new API endpoints
- Defining service contracts
- REST or GraphQL API design
- Documenting API behavior

## API Design with Specs

### 1. Start with Behavioral Contract

```markdown
## Endpoint: POST /api/users

### Given/When/Then

| Scenario | Given | When | Then |
|----------|-------|------|------|
| Valid creation | Valid user data | POST request | 201 + user object |
| Duplicate email | Email exists | POST request | 409 Conflict |
| Invalid data | Missing required | POST request | 400 Bad Request |
```

### 2. Define Contract

```yaml
POST /api/users:
  request:
    body:
      email: string (required)
      name: string (required)
      role: string (optional, default: "user")

  responses:
    201:
      body: { id, email, name, role, created_at }
    400:
      body: { error: "validation_error", details: [...] }
    409:
      body: { error: "duplicate_email" }
```

### 3. Create Spec Document

```markdown
# SPEC-API-001: User Creation Endpoint

## Overview
Create a new user in the system.

## Request
- Method: POST
- Path: /api/users
- Content-Type: application/json

## Input
| Field | Type | Required | Constraints |
|-------|------|----------|-------------|
| email | string | Yes | Valid email format |
| name | string | Yes | 1-100 chars |
| role | string | No | "user" or "admin" |

## Expected Behavior

### Success (201)
Given valid user data not already in system
When POST request is made
Then return 201 with created user object

### Validation Error (400)
Given invalid or missing required fields
When POST request is made
Then return 400 with validation details

### Duplicate (409)
Given email already exists
When POST request is made
Then return 409 with duplicate_email error
```

## REST Best Practices

- Use nouns for resources (`/users`, not `/getUsers`)
- Use HTTP methods correctly (GET, POST, PUT, DELETE)
- Return appropriate status codes
- Use consistent error format
- Version your API (`/v1/users`)

## Output Format

```markdown
## API Design: [endpoint]

### Contract
[request/response definition]

### Behavioral Spec
[Given/When/Then scenarios]

### Integration with Traceability
- REQ: [requirement ID]
- SPEC: [spec ID]
```
