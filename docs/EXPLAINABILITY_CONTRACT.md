# Repository-grounded explainability contract

## Required outcome

Every significant architectural or behavioral decision MUST be explainable to a new engineer or AI agent using only the repository at a specific commit. No access to previous chats, the original author, private notes, or undocumented agent memory may be required.

This is a **documentation and traceability rule**, not an instruction to rewrite working code or produce exhaustive line-by-line commentary.

## Sources of truth

1. `docs/USER_SPEC_RU.md` — user intent and acceptance criteria; never retroactively redefine it.
2. Checked-in source and tests at a named commit — **what actually executes**.
3. `docs/ARCHITECTURE.md` — current components, boundaries, dependencies, and data/control flows.
4. `docs/DECISION_INDEX.md` and linked ADR files — rationale, alternatives, trade-offs, and supersession.
5. `docs/DEVELOPMENT_HISTORY.md`, merged PRs and evidence — how the implementation evolved.
6. `docs/STATUS.md`, `docs/REQUIREMENTS_TRACEABILITY.md` and `docs/ROADMAP.md` — implemented versus unverified or outstanding behavior.

When these disagree, do **not** silently reconcile or invent an explanation: cite the discrepancy and identify the current source behavior and unresolved historical reason. An ADR documents intent at its date, not necessarily current code.

## Module-level documentation

For each nontrivial module, maintain enough information in architecture docs or a module README to answer:

- What responsibility does the module own? What is explicitly out of scope?
- Which public interfaces, entry points, and invariants does it expose?
- Which modules and services does it depend on? Which direction may dependencies flow?
- What are the security, platform, performance, lifecycle, and data constraints?
- What tests demonstrate its observable contract, and what remains unverified?

Prefer links to paths and tests over duplicating code. Do not add trivial function-by-function prose.

## Decision records

For any significant new or revised behavior, architecture, cross-platform integration, dependency, or persistent data format, record the decision before or in the implementing PR. Each ADR should specify:

- Problem/context and the actual constraints.
- Considered alternatives and why they were rejected or deferred.
- Chosen design and its rationale, including trade-offs and known limits.
- Affected modules/interfaces, implementation PR or commit, and relevant tests.
- Status (proposed/accepted/superseded) and a link to the superseding decision when applicable.

Use a uniquely numbered ADR; avoid the historical 0006/0007 collisions documented in `docs/DECISION_INDEX.md`. Update the index when adding or superseding an ADR.

## Answering "why is it done this way?"

An agent answering a repository-specific question MUST:

1. Inspect the **current** source for the named function or module and identify the examined commit/ref.
2. Consult architecture docs, applicable ADRs, related merged PRs, and tests as needed.
3. Cite exact repository paths/symbols and decision/PR links for factual claims. Distinguish current behavior, historical rationale, explicit requirements, and inference.
4. Say **"not documented"** where the reason is absent; do not manufacture a rationale from plausible engineering conventions.
5. Flag uncertainty, contradictions, superseded documents and missing real-device evidence.
6. Never use green CI as proof of physical-device playback or infer implementation solely from a specification.

Example response pattern: **Current behavior** (source path/symbol) → **Reason** (ADR/requirement/PR) → **Alternatives and trade-offs** (ADR) → **Verification and gaps** (test, status or explicit unknown).

## Change and review gate

Every PR that materially changes a module contract or a design decision must update the relevant architecture, ADR/index, tests and status/traceability in that **same PR**, or explicitly state why no documentation change is required. In the PR review, ask: could an unfamiliar agent answer *what/where/how/why* solely from the checked-in sources? If not, request the minimum missing explanation before merge.

Documentation-only cleanups should be small. Do not block urgent correctness/security fixes merely to author long prose: record a minimal rationale and link a follow-up issue for noncritical detail.

## Handover spot-check

Periodically choose three representative questions: an architectural boundary, a nontrivial function, and a rejected/superseded approach. Ask a fresh agent to answer using only repository contents, with links. Verify the answers against actual code and mark unsupported assertions as gaps to correct. This spot-check is a documentation audit, **not** an expensive runtime stress test.
