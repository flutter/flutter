# Autonomous Multi-Agent Execution Workflow

This document defines the strict multi-agent state machine utilized to migrate the Android Embedder to the C-API. To prevent LLM context exhaustion ("amnesia") and ensure deep specialization, the Orchestrator (Main Agent) will spawn specific sub-agents for distinct phases of the migration ledger.

## 1. Agent Archetypes & Context Boundaries

### The Orchestrator (Main Agent)
*   **Role**: Maintains the `MIGRATION_LEDGER.md` state tracking, checks out git branch stubs, and spawns the sub-agents. 
*   **Context**: The ledger structure and overall git tree state.

### `implementation-agent` (The Coder)
*   **Role**: Writes C++, Java, Dart, and GN logic for a single atomic ledger step.
*   **Context**: `MIGRATION_PLAN.md`, architectural guardrails, and specific feedback from analyzers/reviewers.

### `validation-agent` (The Build & Test Engineer)
*   **Role**: Compiles and executes tests (e.g., `ninja`, `flutter test`, `devicelab`).
*   **Context**: Build rules and target names. Does not require historical architecture context. Reports PASS/FAIL along with raw terminal output and logs.

### `analyzer-agent` (The Debugger / Triage)
*   **Role**: Triages complex failures (C++ segfaults, memory leaks, JNI exhaustion) and frame-pacing regressions.
*   **Context**: 
    *   Raw compiler logs, stack traces, tombstones, and logcat dumps.
    *   **Perfetto Traces**: Specifically tasked with parsing and analyzing Perfetto timeline profiles. The analyzer uses trace visualization output to debug threading bottlenecks, lock contention, UI/Raster thread synchronization, and Android `AChoreographer` / VSync pacing latency.
*   **Output**: Produces a synthesized "Root Cause & Fix Plan" to feed back into the Implementation Agent.

### `review-agent` (The Adversarial Reviewer)
*   **Role**: Enforces structural guardrails (running as the rigorous `reidbaker-agent` archetype).
*   **Context**: The incremental diff strictly bounding the work of the current phase (comparing the current branch against its immediate parent branch or baseline commit—*NOT* the accumulated diff against `master`). Bounding the context prevents review exhaustion. Verifies C-ABI invariants, ensures Perfetto trace instrumentation is present, and blocks GN target bleed.

## 2. The Execution State Machine

For every task explicitly laid out in `MIGRATION_LEDGER.md`, the Orchestrator will execute the following loop:

1.  **Checkout Target Branch** -> (Based on Ledger branch stub).
2.  **Spawn Implementation** -> `implementation-agent` writes code and commits.
3.  **Spawn Validation** -> `validation-agent` runs suite.
    *   *If Pass:* Proceed to step (5).
    *   *If Fail:* Proceed to step (4).
4.  **Spawn Analyzer** -> `analyzer-agent` parses logs, tombstones, and **Perfetto traces**. Synthesizes a fix plan and sends it to Implementation (Loop back to 2).
5.  **Spawn Review** -> `review-agent` conducts brutal architectural review on the committed diff.
    *   *If Pass:* Orchestrator marks ledger step complete and pushes branch.
    *   *If Fail:* Rejects branch; sends architectural corrections back to Implementation (Loop back to 2).
