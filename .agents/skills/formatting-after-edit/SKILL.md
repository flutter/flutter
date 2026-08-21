---
name: formatting-after-edit
description: Formats files right before concluding a task. Use at the very end of your workflow, after all file edits are complete and you are preparing to finish the task.
---

## Step 1: Identify Modified Files
Review the list of files you have edited or created during the current task.

## Step 2: Apply Formatting Rules
Apply the corresponding formatting command based on the file type or location.

* **Engine Files:** If you edited any files located within the `flutter/engine` directory, you must run `engine/src/flutter/bin/et format`.
* **Dart Files:** If you edited any `.dart` file (outside of the engine directory), you must run `dart analyze <filename>` and fix any issues. Afterwards, run `dart format <filename>`.
