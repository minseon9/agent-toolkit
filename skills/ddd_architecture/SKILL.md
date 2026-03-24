---
name: ddd-architecture
description: Explore architecture candidates based on domain model, analyze trade-offs, and make architecture decisions. Use after domain discovery is complete.
---

Explore architecture candidates for the defined domain model, analyze trade-offs, and make a decision.

## Prerequisites

1. Load `docs/domain/index.yaml` — if it doesn't exist, tell user to run domain discovery first.
2. Load `docs/domain/context-map.yaml` for context relationships.
3. Scan bounded context `model.yaml` files to understand aggregate complexity.

## Phase 1: Domain Characteristics Analysis

Analyze the domain model and identify key architectural drivers:

- **Domain complexity**: How many bounded contexts? How interconnected?
- **Consistency requirements**: Which aggregates need strong consistency? Which can be eventual?
- **Scale characteristics**: Read-heavy? Write-heavy? Event-heavy?
- **Team topology**: How many teams? How do they map to bounded contexts?
- **Integration patterns**: What does the context map tell us about coupling?

Summarize findings as a characteristics matrix.

## Phase 2: Architecture Candidates

Based on the domain characteristics, propose **at least 2, at most 4** candidates from:

- Modular Monolith
- Microservices
- Event-Driven Architecture
- CQRS / Event Sourcing
- Hexagonal (Ports & Adapters)
- Clean Architecture
- Layered Architecture
- Hybrid approaches (e.g., Modular Monolith + Event-Driven)

For each candidate, describe:
- How bounded contexts map to modules/services
- How context relationships are implemented
- How aggregates communicate across boundaries

## Phase 3: Trade-off Analysis

Create a comparison table:

| Criteria | Candidate A | Candidate B | ... |
|---|---|---|---|
| Domain fit | How well does it express the domain model? | | |
| Consistency model | Strong/eventual/mixed — does it match needs? | | |
| Complexity budget | Implementation + operational complexity | | |
| Team autonomy | Can teams work independently? | | |
| Evolvability | How easy to split/merge contexts later? | | |
| Testability | Unit, integration, e2e — how natural? | | |

**Scoring**: Rate each criterion 1-5 with brief justification.

**Critical rule**: The primary criterion is **domain fit** — how naturally the architecture expresses the domain model. Technical convenience is secondary.

## Phase 4: Recommendation & Decision

- State the recommended architecture with clear reasoning
- Identify risks and mitigation strategies
- Define the migration path if starting simple and evolving later
- Get user confirmation before finalizing

## Output

**`docs/domain/architecture-decision.md`**:

```markdown
# Architecture Decision Record

## Date
<today>

## Status
Proposed | Accepted | Superseded

## Context
<domain characteristics summary>

## Candidates Considered
### <Candidate A>
<description, how it maps to domain>

### <Candidate B>
<description, how it maps to domain>

## Trade-off Analysis
<comparison table>

## Decision
<chosen architecture and why>

## Consequences
### Positive
- <benefit>

### Negative
- <trade-off accepted>

### Risks & Mitigation
- <risk → mitigation>

## Bounded Context → Module/Service Mapping
| Bounded Context | Module/Service | Communication |
|---|---|---|
| <context> | <module> | <sync/async/event> |
```

Also update `docs/domain/index.yaml` with:
```yaml
architecture:
  style: <chosen-style>
  decided: <date>
  record: docs/domain/architecture-decision.md
```
