---
name: engine-whats-new
description: Generates the "what's new" release summary and diff file for changes in the Flutter engine (//engine/src/flutter) between two releases (e.g., 3.47 vs 3.44). Use when asked to generate what's new in the engine, diff engine releases, or summarize engine changes for a Flutter release.
---

# Flutter Engine What's New & Diff Skill

This skill generates a complete diff and structured "What's New" release summary for changes made in the Flutter engine directory (//engine/src/flutter) between a target Flutter release and its predecessor release (e.g., comparing 3.47 to 3.44).

It uses the [generate_engine_whats_new.dart](scripts/generate_engine_whats_new.dart) script to automate git reference resolution, diff generation, commit categorization, and Markdown summary generation. For more information on the tool options, see the [README.md](scripts/README.md).

## Workflow

### 1. Identify Inputs

Extract the following from the user's request:
* **Target Release (`<TARGET_RELEASE>`):** The Flutter release version to analyze (e.g., `3.47`, `3.47.0`, or `flutter-3.47-candidate.0`).
* **Base Release (`<BASE_RELEASE>`):** Optional. The prior Flutter release to compare against (e.g., `3.44`). If omitted by the user, the script will automatically calculate the predecessor release (e.g., for `3.47` it automatically selects `3.44`).

### 2. Run the Generator Tool

Execute the Dart script from the Flutter repository root:

```bash
dart .agents/skills/engine-whats-new/scripts/generate_engine_whats_new.dart --release <TARGET_RELEASE>
```

If the user specifies a custom base release or output paths:

```bash
dart .agents/skills/engine-whats-new/scripts/generate_engine_whats_new.dart --release <TARGET_RELEASE> --from <BASE_RELEASE> --output-diff engine_diff_<BASE_RELEASE>_to_<TARGET_RELEASE>.diff --output-summary engine_whats_new_<TARGET_RELEASE>.md
```

To output structured JSON for programmatic consumption:

```bash
dart .agents/skills/engine-whats-new/scripts/generate_engine_whats_new.dart --release <TARGET_RELEASE> --format json
```

### 3. Review Generated Artifacts & Present to User

The tool produces two primary artifacts in the repository root:
1. **Diff File (`engine_diff_<BASE_RELEASE>_to_<TARGET_RELEASE>.diff`):** The full unified git diff of all changes in //engine/src/flutter between the two releases.
2. **Summary Document (`engine_whats_new_<TARGET_RELEASE>.md`):** A categorized Markdown summary covering:
   * **Overview & Statistics:** Total engine commits, files changed, additions, and deletions.
   * **🚀 Impeller & Graphics Rendering:** Vulkan, Metal, OpenGL, shaders, and display list updates.
   * **🌐 Web Engine & Wasm:** Web SDK, CanvasKit, and WebAssembly changes.
   * **📱 Android Embedding:** Gradle/AGP updates, Android view rendering, and Java/Kotlin embedding changes.
   * **🍎 iOS & macOS Embeddings:** Darwin platform view lifecycle, Metal views, and macOS/iOS updates.
   * **🪟 Windows & Linux Desktop Embeddings:** Win32 compositor, Linux GTK embedding, and desktop shell fixes.
   * **🔤 Text, Typography & Accessibility:** Semantics, IME, font fallback, and text layout improvements.
   * **🔄 Dependency Rolls:** Skia, Dart SDK, ICU, HarfBuzz, and ANGLE rolls.
   * **🛠️ Build System, CI & Tooling:** GN build files, luci scripts, and testing utilities.

Provide the user with a concise overview of the results and links to the generated diff and markdown summary files.

## Examples

- **User:** "Generate what's new in the engine for Flutter 3.47."
- **Agent:**
  1. Identifies target release `3.47`.
  2. Runs `dart .agents/skills/engine-whats-new/scripts/generate_engine_whats_new.dart --release 3.47`.
  3. Reports the summary statistics (e.g., 354 commits, 1179 files changed) and shares the generated `engine_diff_3.44_to_3.47.diff` and `engine_whats_new_3.47.md`.

- **User:** "Diff the engine changes between Flutter 3.41 and 3.44."
- **Agent:**
  1. Identifies base release `3.41` and target release `3.44`.
  2. Runs `dart .agents/skills/engine-whats-new/scripts/generate_engine_whats_new.dart --from 3.41 --to 3.44`.
  3. Presents the breakdown of engine changes and the diff file.
