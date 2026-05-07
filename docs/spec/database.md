# Database Schema

SQLite database at `~/Library/Application Support/Tora/tora.db`, managed by GRDB.swift.

## Tables

### sources

Connected channels Tora watches.

```sql
CREATE TABLE sources (
  id          TEXT PRIMARY KEY,    -- e.g. "slack:T04XXXXX", "gmail:me"
  type        TEXT NOT NULL,       -- "slack" | "gmail"
  label       TEXT NOT NULL,       -- Display name
  config      TEXT,                -- JSON blob (tokens, channel filters)
  active      INTEGER DEFAULT 1,
  created_at  TEXT DEFAULT (datetime('now'))
);
```

### customers

Companies/organizations tasks relate to.

```sql
CREATE TABLE customers (
  id          TEXT PRIMARY KEY,
  name        TEXT NOT NULL,       -- e.g. "Megaflis", "VPG"
  notes       TEXT,
  created_at  TEXT DEFAULT (datetime('now'))
);
```

### products

Products/projects within customers.

```sql
CREATE TABLE products (
  id          TEXT PRIMARY KEY,
  name        TEXT NOT NULL,       -- e.g. "Ticket Agent", "Shop Assistant"
  customer_id TEXT REFERENCES customers(id),
  notes       TEXT,
  created_at  TEXT DEFAULT (datetime('now'))
);
```

### suggestions

AI-extracted potential tasks, pending user action.

```sql
CREATE TABLE suggestions (
  id              TEXT PRIMARY KEY,
  source_id       TEXT NOT NULL REFERENCES sources(id),
  title           TEXT NOT NULL,
  source_person   TEXT,
  source_channel  TEXT,
  urgency         TEXT DEFAULT 'medium',  -- low | medium | high
  suggested_due   TEXT,
  context_snippet TEXT,
  customer_id     TEXT REFERENCES customers(id),
  product_id      TEXT REFERENCES products(id),
  raw_signal_hash TEXT,            -- SHA256 of original message (dedup, no raw storage)
  status          TEXT DEFAULT 'pending',  -- pending | accepted | dismissed
  created_at      TEXT DEFAULT (datetime('now')),
  acted_at        TEXT
);
```

### tasks

Accepted suggestions promoted to tasks.

```sql
CREATE TABLE tasks (
  id              TEXT PRIMARY KEY,
  suggestion_id   TEXT REFERENCES suggestions(id),
  title           TEXT NOT NULL,
  notes           TEXT,
  priority        INTEGER DEFAULT 2,  -- 1=high, 2=medium, 3=low
  due_date        TEXT,
  customer_id     TEXT REFERENCES customers(id),
  product_id      TEXT REFERENCES products(id),
  completed       INTEGER DEFAULT 0,
  completed_at    TEXT,
  created_at      TEXT DEFAULT (datetime('now')),
  updated_at      TEXT DEFAULT (datetime('now'))
);
```

### settings

Key-value app settings.

```sql
CREATE TABLE settings (
  key   TEXT PRIMARY KEY,
  value TEXT
);
```

## Customer/Product Matching

The AI returns free-text customer and product names. Tora fuzzy-matches against local `customers` and `products` tables. If no match is found, the user can create a new entry when accepting. Over time the local database builds a map of your customers and products.
