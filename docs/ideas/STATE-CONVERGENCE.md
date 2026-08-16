# State Convergence

> **Status: Concept / Long-term direction**

This document explores possible long-term evolution of Mac Bootstrap Toolkit.
It is not an implementation contract, roadmap, or specification for the next
development stage. Current implemented architecture is defined in
[ARCHITECTURE.md](../toolkit/ARCHITECTURE.md), scheduled development in
[ROADMAP.md](../../ROADMAP.md), and immediate technical work in
[TODO.md](../../TODO.md).

## Purpose

The Toolkit can evolve from reproducing selected parts of a Mac into making the
resulting state intentionally converge on a user-selected target:

```text
Discover → Describe → Select → Plan → Apply → Verify
```

This direction is useful because it keeps discovery, user intent, planned
actions, application, and confirmation understandable as separate concerns.

## Status boundaries

Implemented on `develop`:

- Discovery and Generated Configuration;
- Blueprint MVP with category and item selection;
- Bootstrap filtering through Blueprint;
- legacy all-inclusive Bootstrap when Blueprint is absent;
- Bootstrap as the current application mechanism.

Planned in the Roadmap, but not implemented:

- Dry-run / Preview;
- Verification.

Long-term concepts, not committed implementation:

- multiple named Blueprints / Profiles;
- richer restore planning and useful portability;
- possible import / export;
- a possible separate Restore Engine.

## Conceptual model

```text
                    Current Mac
                        │
                        ▼
                    Discovery                 [implemented]
                        │
                        ▼
                  Observed State
                        │
                        ▼
             Generated Configuration          [implemented]
                        │
                        ▼
                    Blueprint                 [MVP implemented]
                  /      |      \
          Default*     Dev*    Server*         [conceptual profiles]
                  \      |      /
                        ▼
                  Desired State
                        │
                        ▼
                  Plan / Preview               [planned]
                        │
                        ▼
                       Apply                   [Bootstrap today]
                        │
                        ▼
                  Verification                 [planned]
                        │
                        ▼
                 Converged State

* Examples only; multiple named Blueprints are not implemented.
```

## Observed and desired state

Generated Configuration contains observed, machine-specific values. Blueprint
expresses desired selection without unnecessarily copying those values:

```text
Observed State
    ↓
Generated Configuration
    ↓
Blueprint selection
    ↓
Desired State
```

Keeping observation and selection separate avoids turning Blueprint into a
second configuration store and preserves a clear source for discovered data.

## Named Blueprints / Profiles

A useful long-term interpretation is:

```text
Profile ≈ named Blueprint
```

A Blueprint answers “What from the observed state should become part of the
desired state?” A named Blueprint, or Profile, additionally answers “For which
machine role or usage scenario?” Examples might include Default, Development,
Personal, Server, or Full.

One possible layout is:

```text
config/
└── blueprints/
    ├── default.conf
    ├── development.conf
    ├── personal.conf
    └── server.conf
```

This layout is an example only and is not implemented. Profiles should reuse
Blueprint semantics rather than require a separate Profile Engine, and they are
not scheduled for the next release.

## Plan / Preview

Dry-run / Preview may eventually become more useful than merely running
Bootstrap without changes. A human-readable plan of desired changes could be
produced from the Blueprint and later executed by Apply:

```text
Blueprint → Restore Plan / Preview → Apply
```

The plan might describe outcomes such as Install, Configure, Create, Already
satisfied, Skip, Warning, and Error. Exact formats and APIs are intentionally
undefined. Preview remains unimplemented, and its actual design belongs to its
future Roadmap stage.

The important long-term principle is that Preview and Apply should describe and
execute the same desired change plan, rather than calculate different behavior
independently.

Plan computation should remain separable from terminal presentation where
practical:

```text
Desired State
    ↓
Plan logic
    ↓
Structured result
    ├── CLI rendering
    └── future GUI rendering
```

This does not require a public API, JSON format, framework, GUI backend, or
planner abstraction now. It preserves the possibility of presenting the same
plan through different interfaces without duplicating planning logic.

## Apply and Bootstrap

Bootstrap remains the current application mechanism. A possible evolution is
for it to coordinate related phases:

```text
Bootstrap / Apply
    ├── Plan
    ├── Apply
    └── Verify
```

This is conceptual, not current architecture. Apply must remain idempotent,
check state before changing it, protect user data, and verify applied changes
where supported.

## Verification

Verification should eventually answer: “Did the resulting Mac reach the
selected desired state?”

```text
Observed / resulting state
            ↕
       Desired state
```

This is distinct from pre-apply checks and from command success alone.
Verification is planned but currently unimplemented; no specific framework is
defined here.

## Presentation layers

The same Toolkit behavior may eventually be exposed through different
presentation layers:

```text
Toolkit Core
    ├── CLI
    ├── Unified interactive workflow
    └── Future GUI
```

CLI remains a first-class interface for advanced use, automation, development,
and diagnostics. A future GUI would be a presentation layer over the same
Toolkit logic, not a separate implementation of Discovery, Blueprint, Apply,
or other operations. GUI remains conceptual and is not planned for a specific
release.

## Unified workflow

A wizard or GUI may eventually orchestrate the individual operations as one
user-facing flow:

```text
Discover → Select → Preview → Confirm → Apply → Verify
```

Today's separate CLI modes remain useful and should not be removed. The unified
workflow is conceptual; it does not define commands, flags, screens, or GUI
technology.

## Optional Restore Engine

The original concept envisioned a separate Restore Engine. Blueprint makes a
simpler direction possible: Bootstrap may naturally evolve into a
Plan → Apply → Verify orchestration layer.

A separate `modules/restore/` is neither required nor inevitable. Its necessity
should be evaluated only after real Preview and Verification implementations
exist, and only if their orchestration cannot remain clean inside Bootstrap.

## Design principles

1. Observed state and desired state remain separate.
2. Selection does not duplicate machine-specific data unnecessarily.
3. Every new layer builds on working lower layers.
4. Preview and Apply should eventually share the same plan.
5. Apply remains idempotent and safe.
6. Verification evaluates resulting state, not merely command success.
7. Profiles reuse Blueprint semantics instead of creating another engine.
8. A separate Restore Engine appears only if complexity justifies it.
9. Backward compatibility is preserved where practical.
10. Optional capabilities do not prematurely complicate the MVP architecture.

## Relation to the original concept

[MAC-BLUEPRINT.md](MAC-BLUEPRINT.md) records the original historical idea.
State Convergence modernizes that direction using lessons from implementing
Discovery, Generated Configuration, Bootstrap, and Blueprint. It preserves the
ambition of intentional state convergence without turning speculative
capabilities into current commitments.
