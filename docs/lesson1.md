# Lesson 1 - Getting Started

A **database** stores data in tables made of rows and columns.

## Your first query

```sql
SELECT id, name
FROM users
WHERE active = 1
ORDER BY name;
```

| Column | Meaning              |
|--------|----------------------|
| id     | Unique row identifier |
| name   | User's display name   |
