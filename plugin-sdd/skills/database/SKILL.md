---
name: database
description: Database design, migrations, and query optimization. Auto-triggers for schema changes, migrations, database queries, or data modeling.
---

# Database Skill

## When to Use
- Designing database schemas
- Writing migrations
- Optimizing queries
- Data modeling

## Schema Design with Specs

### 1. Define Data Invariants

```markdown
# SPEC-DATA-001: User Table

## Invariants
- Email is unique across all users
- User ID is immutable after creation
- Deleted users have deleted_at set
- Password is never stored in plaintext

## Behaviors
| Given | When | Then |
|-------|------|------|
| Valid user data | Insert | User created with timestamps |
| Duplicate email | Insert | Constraint violation error |
| Soft delete | Delete user | deleted_at set, data retained |
```

### 2. Create Schema

```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_deleted ON users(deleted_at) WHERE deleted_at IS NULL;
```

### 3. Write Migration

```python
"""
Migration: Create users table
REQ: REQ-001
SPEC: SPEC-DATA-001
"""

def upgrade():
    """Create users table with constraints."""
    ...

def downgrade():
    """Drop users table."""
    ...
```

## Query Optimization

### Common Issues

1. **N+1 Queries**
```python
# Bad: N+1
for user in users:
    orders = get_orders(user.id)

# Good: Join or eager load
users_with_orders = get_users_with_orders()
```

2. **Missing Indexes**
```sql
-- Add index for frequently queried columns
CREATE INDEX idx_orders_user_id ON orders(user_id);
```

3. **Over-fetching**
```python
# Bad: SELECT *
users = db.query("SELECT * FROM users")

# Good: Select only needed columns
users = db.query("SELECT id, email FROM users")
```

## Migration Best Practices

1. **Reversible** - Always have downgrade
2. **Atomic** - One logical change per migration
3. **Tested** - Evals for data integrity
4. **Documented** - Link to REQ/SPEC IDs

## Output Format

```markdown
## Database Change: [description]

### Schema
[table/column changes]

### Migration
[up/down operations]

### Indexes
[new indexes]

### Traceability
- REQ: [ID]
- SPEC: [ID]

### Verification
- [ ] Migration reversible
- [ ] Indexes added for queries
- [ ] Constraints enforce invariants
```
