---
name: find-release
description: A skill to find the lowest Dart and Flutter release containing a given commit. Use this skill whenever users ask about when a commit landed in Flutter or Dart releases, inquire about release versions for specific SHAs, or want to know if a commit is included in stable, beta, or dev channels for Flutter/Dart projects.
---

## Instructions

1.  **Extract Information:**
    - Identify the commit SHA from the user's request (e.g., `02abc57`).
    - Identify the target channel (one of: `stable`, `beta`, `dev`). If not specified, try each.

2.  **Execute Search:**
    - Ensure the `find_release.dart` tool is available. The tool is typically located at `engine/src/flutter/third_party/dart/tools/find_release.dart` relative to the Flutter workspace root. If the workspace root is not the default, set the environment variable `FIND_RELEASE_TOOL_PATH` to the absolute path of the tool.
    - Run the tool using the path to ensure it works from any directory within the workspace.
    - Command: `dart run ${FIND_RELEASE_TOOL_PATH:-engine/src/flutter/third_party/dart/tools/find_release.dart} --commit=<SHA> --channel=<CHANNEL>`

3.  **Interpret and Report Results:**
    - The tool will report which repository (`dart-lang/sdk` or `flutter/flutter`) the commit was found in.
    - It will provide the "Lowest release tag" (the git tag containing the commit).
    - It will provide the "Lowest Flutter release" and/or "Lowest Dart release" version for the specified channel.
    - Present these findings clearly to the user. If the commit is not found or not yet in a release for that channel, inform the user accordingly.
    - Handle edge cases: If the SHA is invalid or not found, suggest checking the SHA. If the channel is invalid, default to stable and notify the user.

## Examples

- **User:** "When did commit 02abc57 land in stable?"
- **Agent:** Runs `dart run ${FIND_RELEASE_TOOL_PATH:-engine/src/flutter/third_party/dart/tools/find_release.dart} --commit=02abc57 --channel=stable` and reports the release version.

- **User:** "Is 02abc57 in beta?"
- **Agent:** Runs the command with `--channel=beta`.
