---
name: database
description: Database design, migrations, and query optimization. Auto-triggers for schema changes, writing migrations, optimizing queries, or designing data models. Ensures safe database changes.
---

# Database Skill

## When to Use
- Designing database schemas
- Writing migrations
- Optimizing slow queries
- Adding indexes
- Data model changes

## Migration Safety Rules

### 1. Always Reversible
Every migration should have a rollback plan.

```python
# migrations/001_add_users_table.py

def upgrade():
    op.create_table(
        'users',
        sa.Column('id', sa.Integer(), primary_key=True),
        sa.Column('email', sa.String(255), nullable=False, unique=True),
        sa.Column('created_at', sa.DateTime(), server_default=sa.func.now())
    )

def downgrade():
    op.drop_table('users')
```

### 2. No Data Loss
Never drop columns/tables with data without:
1. Backing up data
2. Confirming with stakeholder
3. Having restore procedure

### 3. Backward Compatible
For zero-downtime deployments:
1. Add new column (nullable)
2. Deploy code that writes to both
3. Backfill data
4. Deploy code that reads from new
5. Remove old column (separate migration)

## Schema Design

### Naming Conventions
```sql
-- Tables: plural, snake_case
users, order_items, user_sessions

-- Columns: snake_case
created_at, updated_at, user_id

-- Indexes: table_column_idx
users_email_idx

-- Foreign keys: table_column_fk
orders_user_id_fk
```

### Required Columns
```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    -- ... your columns ...
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

### Indexes
Add indexes for:
- Foreign keys
- Columns in WHERE clauses
- Columns in ORDER BY
- Columns in JOIN conditions

```sql
-- Single column
CREATE INDEX users_email_idx ON users(email);

-- Composite (order matters!)
CREATE INDEX orders_user_date_idx ON orders(user_id, created_at);

-- Partial index
CREATE INDEX orders_pending_idx ON orders(status) WHERE status = 'pending';
```

## Query Optimization

### Check Query Plans
```sql
EXPLAIN ANALYZE SELECT * FROM orders WHERE user_id = 123;
```

### Common Issues

#### N+1 Queries
❌ Bad:
```python
users = User.all()
for user in users:
    orders = Order.filter(user_id=user.id)  # N queries!
```

✅ Good:
```python
users = User.all().prefetch_related('orders')  # 2 queries
```

#### Missing Index
```sql
-- Slow: full table scan
SELECT * FROM orders WHERE status = 'pending';

-- Add index
CREATE INDEX orders_status_idx ON orders(status);
```

#### SELECT *
❌ Bad:
```sql
SELECT * FROM users WHERE id = 1;
```

✅ Good:
```sql
SELECT id, email, name FROM users WHERE id = 1;
```

## Migration Workflow

```bash
# 1. Create migration
alembic revision -m "add_users_email_verified"

# 2. Write upgrade/downgrade

# 3. Test locally
alembic upgrade head
alembic downgrade -1
alembic upgrade head

# 4. Run tests
uv run pytest tests/ -v

# 5. Review SQL
alembic upgrade head --sql

# 6. Apply to staging first
```

## Safety Checklist

Before Migration:
- [ ] Has downgrade path
- [ ] Tested locally (up and down)
- [ ] No data loss
- [ ] Backward compatible (if needed)
- [ ] Indexes for new columns in queries
- [ ] Tests updated

After Migration:
- [ ] Verify data integrity
- [ ] Check query performance
- [ ] Monitor for errors

## Output Format

```markdown
## Database Change: [description]

### Migration
`migrations/002_add_email_verified.py`

### Schema Change
```sql
ALTER TABLE users ADD COLUMN email_verified BOOLEAN DEFAULT FALSE;
CREATE INDEX users_email_verified_idx ON users(email_verified);
```

### Rollback
```sql
DROP INDEX users_email_verified_idx;
ALTER TABLE users DROP COLUMN email_verified;
```

### Safety
- [x] Reversible: Yes
- [x] Data loss: None
- [x] Backward compatible: Yes
- [x] Indexes: Added

### Traceability
REQ-001
```

