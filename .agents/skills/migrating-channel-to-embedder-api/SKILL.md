---
name: migrating-channel-to-embedder-api
description: >
  Migrates a Flutter system platform channel (for example flutter/lifecycle or
  flutter/settings) to a typed engine API: an embedder API function or callback,
  plumbing through the engine shell, and a dart:ui PlatformDispatcher member,
  then updates every in-tree embedder and the framework to use it.

  When to use:
  - The user asks to migrate, replace, or convert a "flutter/..." platform channel
    to the embedder API, dart:ui, or a direct engine API.

  When not to use:
  - Adding a brand new platform channel or plugin channel.
  - Channels used only between the framework and a plugin, with no engine or
    embedder involvement.
---

# Migrating a Channel to the Embedder API

Replaces a string or JSON platform channel between the embedders and the framework
with a typed API that runs through the engine. The reference implementation is
flutter/flutter#194837 (`flutter/lifecycle`).

If you cannot ask the user (for example in an unattended run), wherever this skill
says to ask or confirm: make the most conservative choice, record it in the
classification and the PR description, and continue.

Run the scripts in `scripts/`; you do not need to read their source.

## Path conventions

All paths in this skill use these prefixes. Never write them out as repo-root paths.

| Prefix | Location |
|---|---|
| `$ENGINE/` | The engine source root, engine/src/flutter in the repository. |
| `$FRAMEWORK/` | The framework package, packages/flutter. |
| `$FLUTTER_TEST/` | The test package, packages/flutter_test. |

## Placeholders

Decide these in step 2 and use them exactly. Every hop is named from them, which is
what lets the check script verify the work.

| Placeholder | Meaning | Lifecycle example |
|---|---|---|
| `{Name}` | PascalCase concept name. | `AppLifecycleState` |
| `{name}` | lowerCamelCase of `{Name}`, used in Dart. | `appLifecycleState` |
| `{name_snake}` | snake_case of `{Name}`. | `app_lifecycle_state` |
| `{Api}` | Verb + `{Name}`, the C++ method name on every hop. | `SetAppLifecycleState` |

Verb rules: use `Set` for inbound state, `Send` for inbound events, and `Set` or
`Request` for outbound calls.

## Hard rules

1. **Never break the embedder ABI.** In `$ENGINE/shell/platform/embedder/embedder.h`,
   only append: new enums, new functions, new `FnPtr` typedefs, new fields at the end
   of `FlutterEngineProcTable` and `FlutterProjectArgs`. Never reorder or renumber.
   Structs passed across the ABI start with `size_t struct_size`.
2. **Never remove the old channel.** Third-party embedders and apps still use it.
   Follow the deprecation pattern in step 6.
3. **One source of truth per enum, in the right layer.** Core code (`$ENGINE/lib/ui/`,
   `$ENGINE/runtime/`, `$ENGINE/shell/common/`) must not depend on
   `$ENGINE/shell/platform/`. Reuse an existing core C++ enum if there is one;
   otherwise define it in `$ENGINE/lib/ui/window/platform_configuration.h`, as
   flutter/flutter#194837 did with `LifecycleState`. Enums in
   `$ENGINE/shell/platform/common/` are converted at the platform boundary, never
   included from core. Every enum that mirrors a dart:ui enum must be compared in
   `$ENGINE/tools/api_check/test/apicheck_test.dart`, with an `isNotEmpty` check
   (two empty lists compare equal, so a broken parser passes silently).
4. **Threading.** Inbound calls enter `PlatformView` on the platform thread and `Shell`
   moves them to the UI thread. Outbound calls leave dart:ui on the UI thread and
   `Shell` moves them to the platform thread. Never call across threads any other way.
5. **State must survive isolate startup.** Inbound *state* (not events) is cached in
   `PlatformData` and replayed in `RuntimeController::FlushRuntimeStateToIsolate`.
6. **Do not change public platform headers** (iOS/macOS `Headers/`, Linux public
   `fl_*.h`, Windows `public/`) unless the user asks. Use the internal headers.
7. **Never commit, push, or open a PR** unless the user asks.

## Workflow

### 1. Inventory

```bash
dart .agents/skills/migrating-channel-to-embedder-api/scripts/find_channel_usages.dart flutter/<channel>
```

Read every result, including the "Users of wrappers" section: classes and properties
that wrap the channel (for example iOS `lifecycleChannel`) are used by files that
never mention the channel name. Then open the engine's intercept for the channel (if any) in
`$ENGINE/shell/common/engine.cc` (`Engine::DispatchPlatformMessage`).

### 2. Classify

Follow [classify.md](references/classify.md). Write down the classification
(direction, payload, state or event, intercepted or not, users, placeholders) and
show it to the user before editing anything. **Stop** if classify.md says the
channel is not suitable, and explain why.

### 3. Reuse before adding

For every hop in the checklist, search for an existing method that already does the
job (for example `RuntimeController::SetUserSettingsData`). Reuse it rather than
adding a parallel path. Record each reused hop; it is passed to the check script
with `--skip`.

Run the check script (step 9) now as well. Its `delegate-implementors` line lists
every mock and real implementor that will need the new method, including iOS and
Fuchsia files you cannot build.

If you will run framework tests (step 10), start the full `host_debug` build now in
the background; see [testing.md](references/testing.md).

### 4. Core hops

Follow [inbound-hops.md](references/inbound-hops.md) or
[outbound-hops.md](references/outbound-hops.md) in order. Each hop has a template.

### 5. Embedder C API

Part of the hop checklist. Re-read hard rule 1 before editing `embedder.h`.

### 6. Deprecate the channel

Follow the deprecation section of the hop checklist. The old channel keeps working,
logs a one-time warning, and is translated onto the new path.

### 7. Adopt in every in-tree embedder

Follow [platform-adoption.md](references/platform-adoption.md) for Linux, Windows,
macOS, iOS, Android, web and Fuchsia. Only change embedders that use the channel
(from step 1).

### 8. Framework and test bindings

Switch `$FRAMEWORK` to the dart:ui API, keep the channel as a fallback, and update
`TestPlatformDispatcher` in `$FLUTTER_TEST/lib/src/window.dart`. See the framework
section of the hop checklist.

Once the engine consumes the channel, Dart code that listened to it directly with
`channelBuffers.setListener` or `setMessageHandler` and has no framework binding only
sees it if something re-pushes it. Find these in the inventory (engine fixtures, the
iOS scenario app, web tests) and switch them to the new dart:ui callback.

### 9. Check every hop

```bash
dart .agents/skills/migrating-channel-to-embedder-api/scripts/check_hops.dart \
  --direction in|out --name {Name} --api {Api} [--kind state|event] \
  [--channel <SystemChannels getter>] [--skip hop,hop]
```

It finds every implementor of each delegate interface (including iOS, Fuchsia and
test mocks), checks new embedder enums are covered by `api_check`, and diffs
`embedder.h` against the merge-base with main for removed lines (`--base` overrides).
Each hop is `OK`, `MISSING` (exit code 1), `WARN` (read it and decide) or `SKIP`.
Fix every `MISSING`. Only `--skip` a hop that was reused in step 3 or genuinely does
not apply (for example `platform-macos` when macOS never used the channel), and say
why in the PR. Platform hop IDs are `platform-linux`, `platform-windows`,
`platform-macos`, `platform-ios` and `platform-android`.

### 10. Test

Follow [testing.md](references/testing.md): add tests for each layer, format, build
and run host tests, `api_check`, and framework tests. Record which platforms could
not be built or tested locally.

### 11. Report

Write the PR description using [pr-description.md](references/pr-description.md).
Present it to the user with the list of unverified platforms. Do not commit.
