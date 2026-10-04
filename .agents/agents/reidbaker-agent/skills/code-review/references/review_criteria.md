# Review Criteria

This reference document outlines the criteria to prioritize when performing a code review, as well as guidelines for severity and constraints to ensure high-quality feedback.

## Prioritized Criteria

### 1. Correctness
Verify code functionality, handle edge cases, and ensure alignment between function descriptions and implementations.
- **Logic errors**: Check for flawed logic or incorrect algorithms.
- **Error handling**: Ensure errors are handled gracefully and not swallowed.
- **Race conditions**: Look for potential concurrency issues.
- **Data validation**: Verify that inputs are validated correctly.
- **API usage**: Ensure APIs are used correctly and efficiently.

### 2. Efficiency
Identify performance bottlenecks and optimize for efficiency.
- Avoid unnecessary loops, iterations, or calculations.
- Watch for memory leaks or inefficient data structures.
- Avoid excessive logging in performance-critical paths.

### 3. Maintainability
Assess code readability, modularity, and adherence to language idioms.
- **Naming**: Ensure variables, functions, and classes have descriptive names.
- **Complexity**: Identify overly complex functions that should be refactored.
- **Code duplication**: Look for opportunities to reuse code.
- **Style**: Adhere to specified style guides. Violations should be noted.
- **Style Guide Conflict**: If Organization-level and Repository-level style guides conflict, always prefer and enforce the rule specified in the Repository-level style guide.

### 4. Security
Identify potential vulnerabilities.
- Insecure storage of sensitive data.
- Injection attacks (SQL, command, etc.).
- Insufficient access controls or validation.

## Severity Levels

Use these severity levels to categorize your findings:

- **critical**: Must be addressed immediately. Could lead to serious consequences for correctness, security, or performance.
- **high**: Should be addressed soon. Likely to cause problems in the future.
- **medium**: Should be considered for future improvement. Not critical or urgent.
- **low**: Minor or stylistic issues. Can be addressed at the author's discretion.

## Critical Constraints

- **Only comment on changed lines**: Your comments should only refer to lines that begin with a `+` or `-` character in the diff.
- **No fluff**: DO NOT add review comments to tell the user that they made a "good" or "appropriate" improvement. Only comment when there is an improvement opportunity.
- **No explanations**: DO NOT add review comments to explain what the code change does or validate that it works. The author knows what they wrote.
- **Succinct suggestions**: Aim to make code suggestions succinct and directly applicable.
- **Compilable suggestions**: Ensure code suggestions are valid code snippets that can be directly applied.
