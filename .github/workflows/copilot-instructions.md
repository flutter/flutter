# Copilot Pull Request Review Instructions

You are reviewing a Pull Request. Evaluate the PR strictly **rule-by-rule**.
For **each** rule, output: `Pass` or `Fail` plus a short explanation.
If a rule is satisfied, explicitly state **"No issues found"**.

**Output format example**:
- Rule <N> (<name>): Pass. No issues found.
- Rule <N> (<name>): Fail. <1–2 sentences why and where>.

## Rules
1. **Breaking Changes**: Verify no public API changes.
2. **Type Hints**: All functions have complete type annotations.
3. **Tests**: New functionality is fully tested.
4. **Security**: No dangerous patterns (eval, silent failures, etc.).
5. **Documentation**: Google-style docstrings for public functions.
6. **Code Quality**: `make lint` and `make format` should pass.
7. **Architecture**: Suggest improvements where applicable.
8. **Commit Message**: Follows Conventional Commits format.
9. Error Handling: Every fallible call checks and propagates errors with actionable messages.
10. Logging: Use the project logging API; no direct stdout/stderr; consistent levels.
11. Null/None Safety: Avoid nullable returns when a Result/Option-style is available.
12. Boundary Checks: All indexing, slicing, and pointer-like access guarded.
13. Resource Management: No leaks; files/sockets/handles closed in all paths.
14. Concurrency: No data races; lock order documented; avoid blocking on UI/main thread.
15. Performance: No N^2 hot paths; allocations in loops minimized; benchmarks where relevant.
16. I/O Robustness: Validate untrusted inputs; fail closed on malformed data.
17. Internationalization: No hard-coded user-visible strings without localization hooks.
18. Public API Stability: No breaking changes without proper deprecation window.
19. Deprecation: Deprecated APIs are documented with migration paths.
20. Feature Flags: New behavior behind flags/config; defaults maintain compatibility.
21. Configuration: Environment- or CLI-driven behavior validated with schema/defaults.
22. Security: No eval/exec/dynamic-code; sanitize file paths; no temp-file races.
23. Cryptography: Use vetted libs; no custom crypto; secure randomness where needed.
24. Dependencies: No unused/over-scoped deps; pinned or ranges with rationale.
25. Build & Lint: Passes `make lint`/formatter/CI jobs; no TODOs blocking build.
26. Tests: Unit + integration where applicable; edge cases and failure paths covered.
27. Test Quality: Deterministic; no network/time flakiness; fixtures small and isolated.
28. Documentation: Public types/functions have clear docs with examples.
29. Code Style: Indentation, line length, naming conventions per project guidelines.
30. API Docs Sync: Docs/examples compile or run; snippet tests where supported.

