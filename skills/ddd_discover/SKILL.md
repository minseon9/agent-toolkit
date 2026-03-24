---
name: ddd-discover
description: Discover and define domain model through DDD strategic and tactical design. Use when starting domain modeling or exploring a new domain area.
---

Discover and define the domain model for the given area using Domain-Driven Design.

If `$ARGUMENTS` is provided, focus on that specific domain area. Otherwise, start from the top-level domain.

## Prerequisites

Check if `docs/domain/index.yaml` exists:
- **Exists**: Load it to understand what's already defined. Avoid duplicating existing bounded contexts.
- **Does not exist**: This is a fresh start. You will create it.

## Phase 1: Problem Space Discovery

Collaborate with the user through questions. Do NOT assume — ASK.

### 1.1 Core Domain Identification
- What is the core business problem this system solves?
- What makes this domain unique compared to off-the-shelf solutions?
- What are the subdomains? Classify each as: **core** / **supporting** / **generic**

### 1.2 Domain Events
- What are the key things that "happen" in this domain?
- Map events chronologically (event storming lite)
- Identify commands that trigger events and actors who issue commands

### 1.3 Business Rules & Invariants
- What rules must NEVER be violated?
- What constraints exist between domain concepts?

## Phase 2: Solution Space — Strategic Design

### 2.1 Bounded Context Definition
For each identified context:
- Name (must be a noun phrase from the domain, not technical jargon)
- Responsibility (what it owns)
- Boundary (what it does NOT own)
- Type: core / supporting / generic

### 2.2 Context Relationships
Identify how contexts relate:
- Upstream/downstream
- Integration patterns: Shared Kernel, Customer-Supplier, Conformist, ACL, Open Host, Published Language

### 2.3 Ubiquitous Language
For each bounded context, define terms:
```yaml
terms:
  - term: "Order"
    definition: "A customer's request to purchase one or more products"
    examples:
      - "Customer places an order"
      - "Order is confirmed after payment"
    related: [OrderItem, Customer, Payment]
    invariants:
      - "An order must have at least one item"
```

## Phase 3: Solution Space — Tactical Design

For each bounded context, define:

### 3.1 Aggregates
- Aggregate root entity
- Consistency boundary
- Invariants enforced

### 3.2 Entities
- Identity, lifecycle, key attributes
- Which aggregate they belong to

### 3.3 Value Objects
- Immutable, equality by value
- Validation rules

### 3.4 Domain Services
- Operations that don't belong to a single entity
- Cross-aggregate coordination

### 3.5 Domain Events
- Events published by this context
- Events consumed from other contexts

## Output

After each phase, save results incrementally. Do NOT wait until the end.

### Files to create/update:

1. **`docs/domain/index.yaml`** — Domain overview
```yaml
domain: <project-name>
version: 1
updated: <today>
bounded_contexts:
  - name: <context>
    type: core|supporting|generic
    description: "<one-line>"
    term_count: <n>
shared_terms:
  - term: <Term>
    contexts: [<ctx1>, <ctx2>]
    note: "<how meaning differs>"
```

2. **`docs/domain/bounded-contexts/<name>/language.yaml`** — Per-context ubiquitous language
```yaml
bounded_context: <name>
version: 1
updated: <today>
terms:
  - term: "<Term>"
    definition: "<clear, unambiguous>"
    examples: ["<usage>"]
    related: [<terms>]
    invariants: ["<rule>"]
```

3. **`docs/domain/bounded-contexts/<name>/model.yaml`** — Tactical design
```yaml
bounded_context: <name>
aggregates:
  - name: <Aggregate>
    root: <RootEntity>
    entities: [<Entity>]
    value_objects: [<VO>]
    invariants: ["<rule>"]
    events_published: [<Event>]
    events_consumed: [<Event>]
domain_services:
  - name: <Service>
    responsibility: "<what it does>"
    depends_on: [<Aggregate>]
```

4. **`docs/domain/bounded-contexts/<name>/context.md`** — Context narrative
```markdown
# <Context Name>

## Responsibility
<what this context owns>

## Boundary
<what this context does NOT own>

## Key Business Rules
- <rule 1>
- <rule 2>
```

5. **`docs/domain/context-map.yaml`** — Context relationships
```yaml
relationships:
  - upstream: <context-a>
    downstream: <context-b>
    pattern: shared-kernel|customer-supplier|conformist|acl|open-host|published-language
    description: "<how they interact>"
```
