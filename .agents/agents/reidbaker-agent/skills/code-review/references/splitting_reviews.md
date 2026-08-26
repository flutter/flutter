# Splitting Reviews

This reference document provides guidance on how to subdivide a large or complex code review into smaller, manageable chunks to maintain high quality and avoid context overload.

## When to Split a Review

Consider splitting a review when:
- The diff is large (e.g., > 500 lines or > 10 files).
- The changes span multiple distinct components or layers (e.g., frontend, backend, database).
- The PR contains multiple unrelated features or bug fixes (though ideally these should be separate PRs, sometimes they are combined).
- You notice that your review comments are becoming superficial or missing details in later files.

## Strategies for Splitting

### 1. By File or Component
The most common approach is to review files in logical groups:
- **By Directory**: Review files folder by folder if the project is well-organized by feature or component.
- **By Layer**: Review database changes first, then backend logic, then frontend UI, then tests. This helps build context sequentially.
- **By File Type**: Review core logic files (.ts, .java, .go) separately from configuration files or documentation.

### 2. By Concern or Perspective
You can also make multiple passes over the same set of changes focusing on different concerns:
- **Pass 1: Correctness and Architecture**: Focus solely on whether the code does what it is supposed to do and fits the overall design.
- **Pass 2: Style and Maintainability**: Focus on readability, naming conventions, and adherence to style guides.
- **Pass 3: Security and Performance**: Focus on potential vulnerabilities and optimization opportunities.

## Tooling Support

To assist with splitting large diffs, use the provided Python script:
`scripts/split_diff.py` (inside the directory the SKILL.md is in)

This script can:
- Read a diff from stdin or a file.
- Extract a diff from a JSON file (useful if the diff is wrapped in JSON).
- Split the diff into separate files per changed file in a specified output directory.

**Usage Example:**
```bash
python3 agents/skills/code-review/scripts/split_diff.py --output-dir scratch/diff_chunks < diff.txt
```

For JSON inputs:
```bash
python3 agents/skills/code-review/scripts/split_diff.py --json --json-key diff --output-dir scratch/diff_chunks < input.json
```

## How to Combine Subdivided Reviews

After performing subdivided reviews, use the **Synthesis** step to create the final output:
1. **Deduplicate**: Ensure that the same issue found in multiple passes or files is not reported multiple times unless it manifests differently.
2. **Prioritize**: Group comments by severity. Ensure critical and high-severity issues are highlighted at the top.
3. **Cohesiveness**: Ensure the tone and style of all comments are consistent, following the [natural writing](../../natural-writing/SKILL.md) skill.
