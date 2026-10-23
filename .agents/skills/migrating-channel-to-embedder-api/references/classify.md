# Classifying a Channel

Answer every question in order. Record the answers; they are the plan shown to the
user in step 2 and the inputs to the check script.

## 1. Is the channel suitable?

**Stop and explain** to the user if any of these are true:

| Condition | Why | Examples |
|---|---|---|
| The framework needs a data reply from the embedder (method call with a result). | Embedder API calls are fire-and-forget. A reply needs a callback design that should be agreed first. | `flutter/platform` `Clipboard.getData` |
| The channel is a large protocol of many unrelated methods with platform-specific behaviour. | It is a plugin-style API, not engine state. It needs its own design doc. | `flutter/textinput`, `flutter/platform_views`, `flutter/keyboard`, `flutter/mousecursor` |
| The engine and embedders never see the channel; only the framework and an app plugin do. | There is nothing to move into the engine. | Plugin channels |

**Reduce scope** (do not stop) if:

| Condition | Action |
|---|---|
| A typed embedder API already exists for the same data. | Only do deprecation (step 6), adoption (step 7) and framework (step 8). Example: `flutter/localization` and `FlutterEngineUpdateLocales`. |
| The channel is a `MethodChannel` with several methods. | Migrate one method per run. List the others as follow-ups. |
| The channel carries both directions. | Migrate one direction per run. |

## 2. Direction

| If | Direction |
|---|---|
| Embedders send on the channel and the framework (or engine) handles it. | **inbound** |
| The framework sends on the channel and embedders handle it. | **outbound** |

## 3. State or event (inbound only)

| If | Kind | Consequence |
|---|---|---|
| Only the latest value matters, and the framework must be able to read it at startup. | **state** | Cached in `PlatformData`, replayed on isolate start, exposed as a dart:ui getter plus `on{Name}Changed`. |
| Every message is a separate occurrence. | **event** | Not cached. Exposed as a dart:ui callback `on{Name}`. |

## 4. Payload

Map the channel payload to three types: the C type in `embedder.h`, the internal C++
type, and the Dart type.

| Channel payload | C (`embedder.h`) | Internal C++ | Dart hook argument | Dart public type |
|---|---|---|---|---|
| String naming an enum value | `typedef enum { kFlutter{Name}Foo, ... } Flutter{Name};` | `enum class` (reuse if one exists) | `int` index | dart:ui enum |
| Bool | `bool` | `bool` | `bool` | `bool` |
| Number | `double` or `int64_t` | same | `double` or `int` | same |
| String | `const char*` | `std::string` | `String` | `String` |
| JSON object | `typedef struct { size_t struct_size; ... } Flutter{Name};` | `struct` | one argument per field, or the existing internal path (see below) | class or several getters |

Rules for enums:

- C enum values must have the same order as the dart:ui enum, so ordinals can be cast.
- Convert between C, C++ and Dart with a `switch` that has a case for every value and
  rejects unknown values (C input is untrusted).
- Add every new enum copy to `$ENGINE/tools/api_check/test/apicheck_test.dart`.

Rules for structs:

- `struct_size` is the first field. Validate it with `STRUCT_HAS_MEMBER` for the last
  field in the first version, and read later fields with `SAFE_ACCESS`.
- A key that only one embedder sends, and that embedder does not use the embedder API
  (Android, iOS), does not go in `embedder.h`. Pass it through that platform's own
  hop. Example: Android's `configurationId` in `flutter/settings`.
- Nullable or optional fields need an explicit representation (a `has_` flag or a
  documented sentinel). Never rely on zero meaning "unset" unless zero is invalid.

## 5. Existing internal path

Look in `$ENGINE/shell/common/engine.cc` for a `k*Channel` constant matching the
channel, and for an `Engine::Handle*PlatformMessage` method.

| If | Then |
|---|---|
| The engine intercepts the channel. | The deprecated-channel translation goes in that handler. Check what the handler calls below `Engine` (for example `RuntimeController::SetUserSettingsData`) and reuse it. |
| The engine does not intercept it. | Add an intercept in `Engine::DispatchPlatformMessage` for the deprecation shim. |

If a lower hop already carries the value in another representation (for example
settings as a JSON string all the way into Dart), choose one and record it:

- **A. Convert at the boundary (default).** Typed API from the embedder down to the
  lowest new hop, then convert to the existing representation and reuse the lower
  hops. Smaller change; list a typed follow-up in the PR.
- **B. Typed throughout.** Replace the lower hops too. Only if the user asks.

## 6. Users

From the inventory, list each embedder that sends or handles the channel today:
Linux, Windows, macOS, iOS, Android, web, Fuchsia. These are the `--platforms` for the
check script. Note test files that send on the channel; they need updating.

## 7. Placeholders

Fill in `{Name}`, `{name}`, `{name_snake}` and `{Api}` from the SKILL.md table. Check
that `{Api}` does not already exist:

```bash
grep -rn "{Api}" engine/src/flutter/shell engine/src/flutter/runtime engine/src/flutter/lib/ui
```

## Output

Show the user a summary in this form before editing:

```text
Channel:     flutter/<channel>
Suitable:    yes | reduced scope (<why>) | no (<why>)
Direction:   inbound | outbound
Kind:        state | event
Payload:     <C type> / <C++ type> / <Dart type>
Intercepted: yes (Engine::Handle...) | no
Internal:    A (convert at <hop>) | B
Users:       linux, windows, macos, ios, android, web, fuchsia
Names:       {Name}=..., {name}=..., {name_snake}=..., {Api}=...
Reused hops: <hop ids, or none>
Follow-ups:  <other methods, other direction, typed follow-up>
```
