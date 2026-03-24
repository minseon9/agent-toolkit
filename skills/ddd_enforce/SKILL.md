---
name: ddd-enforce
description: Validate ubiquitous language compliance across project artifacts (code, stories, docs, APIs). Use to enforce domain language consistency.
---

Validate that project artifacts comply with the ubiquitous language defined in the domain model.

If `$ARGUMENTS` is provided, scan that specific path. Otherwise, scan the entire project for known artifact locations.

## Prerequisites

1. Load `docs/domain/index.yaml` — if missing, stop and tell user to run domain discovery first.
2. Load ALL `language.yaml` files from each bounded context listed in the index.
3. Build a complete term registry (term → definition → context).

## What to Validate

### Source Code
- Class/interface names must use ubiquitous language terms
- Method names should reflect domain operations (commands, queries)
- Variable names for domain concepts must match registered terms
- Comments and docstrings must not introduce unofficial synonyms

### Stories & Requirements
- Story titles and acceptance criteria must use registered terms
- No invented domain terms that aren't in the language registry
- Terms must be used in the correct bounded context

### Documentation
- Technical specs, PRDs, design docs
- Consistent terminology across all documents

### API Contracts
- Endpoint names, request/response field names
- Error messages that reference domain concepts

## Validation Rules

1. **Undefined term**: A domain-like noun/verb is used but not in any `language.yaml`
   - Severity: **ERROR**
   - Action: Add to language registry or replace with registered term

2. **Wrong context**: A term from context A is used in context B's code/docs
   - Severity: **ERROR**
   - Action: Use the term defined in context B, or define a shared term

3. **Synonym usage**: An unofficial synonym of a registered term is used
   - Severity: **ERROR**
   - Action: Replace with the canonical term

4. **Ambiguous usage**: A shared term is used without clarifying which context's meaning
   - Severity: **WARNING**
   - Action: Qualify with context (e.g., "Order (fulfillment)" vs "Order (payment)")

5. **Stale term**: Code uses a term that was deprecated or renamed in the language registry
   - Severity: **ERROR**
   - Action: Update to current term

## Output

Print a violation report:

```
## Ubiquitous Language Compliance Report

**Scanned**: <path or "full project">
**Date**: <today>
**Total files scanned**: <n>
**Violations found**: <n>

### Errors (<n>)

| # | File | Line | Term Used | Issue | Suggested Fix |
|---|------|------|-----------|-------|---------------|
| 1 | src/order/Order.kt | 42 | `purchaseOrder` | Undefined term | Use `Order` (order context) |
| 2 | docs/stories/S-001.md | 15 | `buyer` | Synonym of `Customer` | Use `Customer` |

### Warnings (<n>)

| # | File | Line | Term Used | Issue | Suggested Fix |
|---|------|------|-----------|-------|---------------|
| 1 | src/api/routes.ts | 8 | `Order` | Ambiguous (shared term) | Qualify: `Order (fulfillment)` |

### Summary
- <key finding 1>
- <key finding 2>
- **Recommendation**: <next action>
```

If no violations found, report clean status with scan coverage summary.
