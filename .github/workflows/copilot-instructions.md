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

