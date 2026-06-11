---
name: flutter-cp-stable
description: Cherry-pick a merged PR from master to the stable channel. Use when the user requests to cherry-pick a fix to stable.
---

# Cherry-Pick to Stable

This skill automates the process of requesting a cherry-pick of a merged PR from the `master` branch to the `stable` channel.

## Quick Start

Trigger this skill by providing a merged PR number or URL:
* "Cherry pick PR 186952 to stable"
* "Request CP to stable for https://github.com/flutter/flutter/pull/186952"

## Workflows

1. **Delegate to Common Workflow:**
   - Load and execute the [flutter-cp-common](../flutter-cp-common/SKILL.md) skill.
   - Set the target channel parameter `<CHANNEL>` to `stable`.
   - Pass the user-provided PR number or URL as `<ORIGINAL_PR>`.
2. Follow the steps in `flutter-cp-common` to completion.
