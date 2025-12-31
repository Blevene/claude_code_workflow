---
name: api-design
description: REST/GraphQL API design patterns and best practices. Auto-triggers for designing endpoints, defining contracts, creating API specs, or implementing HTTP handlers. Ensures consistent API conventions.
---

# API Design Skill

## When to Use
- Designing new API endpoints
- Defining request/response contracts
- Creating OpenAPI/Swagger specs
- Implementing HTTP handlers
- API versioning decisions

## REST Conventions

### URL Structure
```
GET    /api/v1/users           # List users
POST   /api/v1/users           # Create user
GET    /api/v1/users/{id}      # Get user
PUT    /api/v1/users/{id}      # Update user (full)
PATCH  /api/v1/users/{id}      # Update user (partial)
DELETE /api/v1/users/{id}      # Delete user

# Nested resources
GET    /api/v1/users/{id}/orders
POST   /api/v1/users/{id}/orders

# Actions (when CRUD doesn't fit)
POST   /api/v1/users/{id}/activate
POST   /api/v1/orders/{id}/cancel
```

### HTTP Status Codes
| Code | Meaning | When to Use |
|------|---------|-------------|
| 200 | OK | Successful GET, PUT, PATCH |
| 201 | Created | Successful POST |
| 204 | No Content | Successful DELETE |
| 400 | Bad Request | Invalid input |
| 401 | Unauthorized | Missing/invalid auth |
| 403 | Forbidden | Valid auth, no permission |
| 404 | Not Found | Resource doesn't exist |
| 409 | Conflict | Duplicate/state conflict |
| 422 | Unprocessable | Validation failed |
| 500 | Server Error | Unexpected error |

### Request/Response Format

**Success Response:**
```json
{
  "data": {
    "id": "123",
    "email": "user@example.com",
    "created_at": "2024-01-15T10:30:00Z"
  }
}
```

**List Response:**
```json
{
  "data": [...],
  "pagination": {
    "page": 1,
    "per_page": 20,
    "total": 100,
    "total_pages": 5
  }
}
```

**Error Response:**
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid email format",
    "details": [
      {"field": "email", "message": "Must be valid email"}
    ]
  }
}
```

## Contract Definition

### OpenAPI Template
```yaml
openapi: 3.0.3
info:
  title: API Name
  version: 1.0.0

paths:
  /users:
    post:
      summary: Create user
      operationId: createUser
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/CreateUserRequest'
      responses:
        '201':
          description: User created
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/User'
        '400':
          $ref: '#/components/responses/BadRequest'

components:
  schemas:
    CreateUserRequest:
      type: object
      required: [email, password]
      properties:
        email:
          type: string
          format: email
        password:
          type: string
          minLength: 8
```

## Best Practices

### Naming
- Use plural nouns for collections: `/users` not `/user`
- Use kebab-case for multi-word: `/order-items`
- Avoid verbs in URLs (use HTTP methods instead)

### Versioning
- Include version in URL: `/api/v1/...`
- Support old versions during migration
- Document deprecation timeline

### Pagination
- Default page size (e.g., 20)
- Maximum page size (e.g., 100)
- Include total count for UI

### Filtering
```
GET /api/v1/orders?status=pending&created_after=2024-01-01
```

### Security
- Always validate input
- Sanitize output
- Use HTTPS only
- Rate limiting
- Authentication on all endpoints

## Output Format

```markdown
## API Contract: [endpoint]

### Endpoint
`POST /api/v1/users`

### Request
```json
{
  "email": "string (required)",
  "password": "string (required, min 8)"
}
```

### Response (201)
```json
{
  "data": {
    "id": "string",
    "email": "string",
    "created_at": "ISO8601"
  }
}
```

### Errors
- 400: Invalid request body
- 409: Email already exists
- 422: Validation failed

### Traceability
REQ-001
```

