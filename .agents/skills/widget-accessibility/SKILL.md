---
name: widget-accessibility
description: Guidelines and instructions for implementing and testing widget accessibility in Flutter.
---

# Widget Accessibility Skill

This skill provides instructions and best practices for ensuring Flutter widgets comply with accessibility guidelines.

## Guidelines

- **Avoid redundant tooltips and labels**: Do not wrap widgets that already support a `tooltip` or `semanticLabel` property directly in a `Tooltip` or `Semantics` widget with the same message. This creates duplicate semantic nodes.
- **Ensure minimum tap target size**: Interactive elements should have a minimum tap target size of 48x48 logical pixels to accommodate users with limited dexterity.
- **Provide semantic labels**: Tappable widgets must have a non-empty semantic label or tooltip.

## Testing

- Use `meetsGuideline` with `textContrastGuideline`, `androidTapTargetGuideline`, `iOSTapTargetGuideline`, and `labeledTapTargetGuideline` to verify accessibility in tests.
- Use `debugDumpSemanticsTree()` to inspect the semantics tree when diagnosing failures related to missing or incorrect labels.
