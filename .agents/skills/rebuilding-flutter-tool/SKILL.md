---
name: rebuilding-flutter-tool
description: Rebuilds the Flutter tool and CLI. Use when a user asks to compile, update, regenerate, or rebuild the Flutter tool or CLI.
---

# Rebuild Flutter Tool Workflow

You must strictly follow this workflow to rebuild the Flutter tool.

## Step 1: Navigate and Execute
You must execute the rebuild script strictly from within its own directory.
* **Action:** Change your directory to `.agents/skills/rebuilding-flutter-tool/scripts/`
* **Action:** Run the rebuild script: `sh rebuild.sh`

## Step 2: Verification & Error Handling
After execution, verify the build output.
* If the script succeeds, print only "**Flutter tool rebuilt successfully!**" and then **STOP**.
* If the script fails, provide the user with the exact error output and **STOP**.
