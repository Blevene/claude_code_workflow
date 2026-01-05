-- Artifact Index Schema for SDD Plugin
-- Database location: .claude/cache/artifact-index/context.db
--
-- This schema supports indexing and querying session artifacts:
-- - Handoffs (completed tasks with post-mortems)
-- - Plans (design documents)
-- - Specs (behavioral specifications)
-- - Continuity ledgers (session state snapshots)
-- - Queries (compound learning from Q&A)
--
-- FTS5 is used for full-text search with porter stemming.

-- Handoffs (completed tasks with post-mortems)
CREATE TABLE IF NOT EXISTS handoffs (
    id TEXT PRIMARY KEY,
    session_name TEXT NOT NULL,
    task_number INTEGER,
    file_path TEXT NOT NULL,
    
    -- Core content
    task_summary TEXT,
    what_worked TEXT,
    what_failed TEXT,
    key_decisions TEXT,
    files_modified TEXT,  -- JSON array
    
    -- Outcome (from user annotation or inference)
    outcome TEXT CHECK(outcome IN ('SUCCEEDED', 'PARTIAL', 'FAILED', 'UNKNOWN')),
    outcome_notes TEXT,
    
    -- Metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    indexed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Plans (design documents)
CREATE TABLE IF NOT EXISTS plans (
    id TEXT PRIMARY KEY,
    session_name TEXT,
    title TEXT NOT NULL,
    file_path TEXT NOT NULL,
    
    -- Content
    overview TEXT,
    approach TEXT,
    phases TEXT,  -- JSON array
    constraints TEXT,
    
    -- Metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    indexed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Specs (behavioral specifications - SDD specific)
CREATE TABLE IF NOT EXISTS specs (
    id TEXT PRIMARY KEY,
    spec_id TEXT NOT NULL,  -- e.g., SPEC-001
    req_id TEXT,            -- linked requirement, e.g., REQ-001
    title TEXT NOT NULL,
    file_path TEXT NOT NULL,
    
    -- Content
    behavior_summary TEXT,
    expected_behaviors TEXT,  -- JSON array
    eval_criteria TEXT,       -- JSON array
    
    -- Status
    has_eval BOOLEAN DEFAULT FALSE,
    eval_path TEXT,
    
    -- Metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    indexed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Continuity snapshots (session state at key moments)
CREATE TABLE IF NOT EXISTS continuity (
    id TEXT PRIMARY KEY,
    session_name TEXT NOT NULL,
    
    -- State
    goal TEXT,
    state_done TEXT,  -- JSON array
    state_now TEXT,
    state_next TEXT,
    key_learnings TEXT,
    key_decisions TEXT,
    
    -- Context
    snapshot_reason TEXT CHECK(snapshot_reason IN ('phase_complete', 'session_end', 'milestone', 'manual')),
    
    -- Metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Queries (compound learning from Q&A)
CREATE TABLE IF NOT EXISTS queries (
    id TEXT PRIMARY KEY,
    question TEXT NOT NULL,
    answer TEXT NOT NULL,
    
    -- Matches
    handoffs_matched TEXT,  -- JSON array of IDs
    plans_matched TEXT,
    specs_matched TEXT,
    continuity_matched TEXT,
    
    -- Feedback
    was_helpful BOOLEAN,
    
    -- Metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- FTS5 indexes for full-text search
CREATE VIRTUAL TABLE IF NOT EXISTS handoffs_fts USING fts5(
    task_summary, what_worked, what_failed, key_decisions, files_modified,
    content='handoffs', content_rowid='rowid',
    tokenize='porter ascii',
    prefix='2 3'
);

CREATE VIRTUAL TABLE IF NOT EXISTS plans_fts USING fts5(
    title, overview, approach, phases, constraints,
    content='plans', content_rowid='rowid',
    tokenize='porter ascii',
    prefix='2 3'
);

CREATE VIRTUAL TABLE IF NOT EXISTS specs_fts USING fts5(
    spec_id, title, behavior_summary, expected_behaviors, eval_criteria,
    content='specs', content_rowid='rowid',
    tokenize='porter ascii',
    prefix='2 3'
);

CREATE VIRTUAL TABLE IF NOT EXISTS continuity_fts USING fts5(
    goal, key_learnings, key_decisions, state_now,
    content='continuity', content_rowid='rowid',
    tokenize='porter ascii'
);

CREATE VIRTUAL TABLE IF NOT EXISTS queries_fts USING fts5(
    question, answer,
    content='queries', content_rowid='rowid',
    tokenize='porter ascii'
);

-- Triggers to keep FTS5 in sync

-- HANDOFFS triggers
CREATE TRIGGER IF NOT EXISTS handoffs_ai AFTER INSERT ON handoffs BEGIN
    INSERT INTO handoffs_fts(rowid, task_summary, what_worked, what_failed, key_decisions, files_modified)
    VALUES (NEW.rowid, NEW.task_summary, NEW.what_worked, NEW.what_failed, NEW.key_decisions, NEW.files_modified);
END;

CREATE TRIGGER IF NOT EXISTS handoffs_ad AFTER DELETE ON handoffs BEGIN
    INSERT INTO handoffs_fts(handoffs_fts, rowid, task_summary, what_worked, what_failed, key_decisions, files_modified)
    VALUES('delete', OLD.rowid, OLD.task_summary, OLD.what_worked, OLD.what_failed, OLD.key_decisions, OLD.files_modified);
END;

CREATE TRIGGER IF NOT EXISTS handoffs_au AFTER UPDATE ON handoffs BEGIN
    INSERT INTO handoffs_fts(handoffs_fts, rowid, task_summary, what_worked, what_failed, key_decisions, files_modified)
    VALUES('delete', OLD.rowid, OLD.task_summary, OLD.what_worked, OLD.what_failed, OLD.key_decisions, OLD.files_modified);
    INSERT INTO handoffs_fts(rowid, task_summary, what_worked, what_failed, key_decisions, files_modified)
    VALUES (NEW.rowid, NEW.task_summary, NEW.what_worked, NEW.what_failed, NEW.key_decisions, NEW.files_modified);
END;

-- PLANS triggers
CREATE TRIGGER IF NOT EXISTS plans_ai AFTER INSERT ON plans BEGIN
    INSERT INTO plans_fts(rowid, title, overview, approach, phases, constraints)
    VALUES (NEW.rowid, NEW.title, NEW.overview, NEW.approach, NEW.phases, NEW.constraints);
END;

CREATE TRIGGER IF NOT EXISTS plans_ad AFTER DELETE ON plans BEGIN
    INSERT INTO plans_fts(plans_fts, rowid, title, overview, approach, phases, constraints)
    VALUES('delete', OLD.rowid, OLD.title, OLD.overview, OLD.approach, OLD.phases, OLD.constraints);
END;

CREATE TRIGGER IF NOT EXISTS plans_au AFTER UPDATE ON plans BEGIN
    INSERT INTO plans_fts(plans_fts, rowid, title, overview, approach, phases, constraints)
    VALUES('delete', OLD.rowid, OLD.title, OLD.overview, OLD.approach, OLD.phases, OLD.constraints);
    INSERT INTO plans_fts(rowid, title, overview, approach, phases, constraints)
    VALUES (NEW.rowid, NEW.title, NEW.overview, NEW.approach, NEW.phases, NEW.constraints);
END;

-- SPECS triggers
CREATE TRIGGER IF NOT EXISTS specs_ai AFTER INSERT ON specs BEGIN
    INSERT INTO specs_fts(rowid, spec_id, title, behavior_summary, expected_behaviors, eval_criteria)
    VALUES (NEW.rowid, NEW.spec_id, NEW.title, NEW.behavior_summary, NEW.expected_behaviors, NEW.eval_criteria);
END;

CREATE TRIGGER IF NOT EXISTS specs_ad AFTER DELETE ON specs BEGIN
    INSERT INTO specs_fts(specs_fts, rowid, spec_id, title, behavior_summary, expected_behaviors, eval_criteria)
    VALUES('delete', OLD.rowid, OLD.spec_id, OLD.title, OLD.behavior_summary, OLD.expected_behaviors, OLD.eval_criteria);
END;

CREATE TRIGGER IF NOT EXISTS specs_au AFTER UPDATE ON specs BEGIN
    INSERT INTO specs_fts(specs_fts, rowid, spec_id, title, behavior_summary, expected_behaviors, eval_criteria)
    VALUES('delete', OLD.rowid, OLD.spec_id, OLD.title, OLD.behavior_summary, OLD.expected_behaviors, OLD.eval_criteria);
    INSERT INTO specs_fts(rowid, spec_id, title, behavior_summary, expected_behaviors, eval_criteria)
    VALUES (NEW.rowid, NEW.spec_id, NEW.title, NEW.behavior_summary, NEW.expected_behaviors, NEW.eval_criteria);
END;

-- CONTINUITY triggers
CREATE TRIGGER IF NOT EXISTS continuity_ai AFTER INSERT ON continuity BEGIN
    INSERT INTO continuity_fts(rowid, goal, key_learnings, key_decisions, state_now)
    VALUES (NEW.rowid, NEW.goal, NEW.key_learnings, NEW.key_decisions, NEW.state_now);
END;

CREATE TRIGGER IF NOT EXISTS continuity_ad AFTER DELETE ON continuity BEGIN
    INSERT INTO continuity_fts(continuity_fts, rowid, goal, key_learnings, key_decisions, state_now)
    VALUES('delete', OLD.rowid, OLD.goal, OLD.key_learnings, OLD.key_decisions, OLD.state_now);
END;

CREATE TRIGGER IF NOT EXISTS continuity_au AFTER UPDATE ON continuity BEGIN
    INSERT INTO continuity_fts(continuity_fts, rowid, goal, key_learnings, key_decisions, state_now)
    VALUES('delete', OLD.rowid, OLD.goal, OLD.key_learnings, OLD.key_decisions, OLD.state_now);
    INSERT INTO continuity_fts(rowid, goal, key_learnings, key_decisions, state_now)
    VALUES (NEW.rowid, NEW.goal, NEW.key_learnings, NEW.key_decisions, NEW.state_now);
END;

-- QUERIES triggers
CREATE TRIGGER IF NOT EXISTS queries_ai AFTER INSERT ON queries BEGIN
    INSERT INTO queries_fts(rowid, question, answer)
    VALUES (NEW.rowid, NEW.question, NEW.answer);
END;

CREATE TRIGGER IF NOT EXISTS queries_ad AFTER DELETE ON queries BEGIN
    INSERT INTO queries_fts(queries_fts, rowid, question, answer)
    VALUES('delete', OLD.rowid, OLD.question, OLD.answer);
END;

CREATE TRIGGER IF NOT EXISTS queries_au AFTER UPDATE ON queries BEGIN
    INSERT INTO queries_fts(queries_fts, rowid, question, answer)
    VALUES('delete', OLD.rowid, OLD.question, OLD.answer);
    INSERT INTO queries_fts(rowid, question, answer)
    VALUES (NEW.rowid, NEW.question, NEW.answer);
END;

