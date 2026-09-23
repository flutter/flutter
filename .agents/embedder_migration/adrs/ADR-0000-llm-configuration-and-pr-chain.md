# ADR-0000: LLM Configuration, Specialized Skills, and Stacked PR Chain

## Status
ACCEPTED

## Context & Problem Statement
The Flutter Android Embedder C-API migration (RFC 410.0000) is a massive multi-quarter refactor spanning 9 subsystems and 98 internal engine headers. When working with LLM agents on migrations of this magnitude, agents suffer from decision drift, context amnesia, and git branch fragmentation.

We need a deterministic operational framework that:
1. Embeds domain-specific skills directly in `//.agents/skills/`.
2. Establishes a strict branch slug convention (`android-embedder-migration-v10/*`) for all stacked PRs.
3. Automates cascading rebases so that any change in an upstream branch propagates downstream without manual cherry-picking or broken histories.
4. Manages externalized state via `session_state.json` and `MIGRATION_MATRIX.md`.

## Non-Negotiable Invariants
1. **Branch Slug**: Every branch in this migration must follow `android-embedder-migration-v10/<version>-<name>`.
2. **Topological Order**: Branch $N$ must always have branch $N-1$ as its direct ancestor.
3. **Automated Cascading Rebase**: Whenever commits are added or amended on branch $k$, all downstream branches ($k+1 \dots M$) must be rebased using `pr_chain.dart rebase`.
4. **Push Policy**: Pushes to origin must use `--force-with-lease`.

## Decision
1. Implemented `pr-chain-manager` with an executable Dart CLI tool (`.agents/skills/pr-chain-manager/scripts/pr_chain.dart`).
2. Installed 7 RFC 410 domain skills under `.agents/skills/`:
   - `dependency-ratchet-manager`
   - `proc-table-and-firewall-auditor`
   - `host-embedder-unit-tester`
   - `embedder-concurrency-characterizer`
   - `sync-fence-and-fd-auditor`
   - `multiview-frame-state-auditor`
   - `zero-copy-buffer-lifecycle-checker`
3. Established working memory in `.agents/embedder_migration/` (`MIGRATION_MATRIX.md`, `INVARIANTS.md`, `session_state.json`).

## Verification Contract
- `dart .agents/skills/pr-chain-manager/scripts/pr_chain.dart verify` exits with code 0.
- All Dart scripts pass `dart format` and `dart analyze --fatal-infos`.
