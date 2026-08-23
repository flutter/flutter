---
name: rebuilding-flutter-tool
description: Rebuilds the Flutter tool and CLI. Use when a user asks to compile, update, regenerate, or rebuild the Flutter tool or CLI.
---

# Rebuild Flutter Tool Workflow

You must strictly follow this workflow to rebuild the Flutter tool.

## Step 1: Execute
* **Action:** Run the rebuild script: `dart .agents/skills/rebuilding-flutter-tool/scripts/rebuild.dart`

## Step 2: Verification & Error Handling
After execution, verify the build output.
* If the script succeeds, print only "**Flutter tool rebuilt successfully!**" and then **STOP**.
* If the script fails, provide the user with the exact error output and **STOP**.
