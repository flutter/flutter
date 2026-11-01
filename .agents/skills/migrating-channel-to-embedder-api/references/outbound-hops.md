# Outbound Hops (framework → embedder)

Do the hops in order. Each has an ID used by `check_hops.dart`. Templates are taken
from flutter/flutter#175100 (`setApplicationLocale`) and flutter/flutter#163930 (view
focus requests). `{api}` is lowerCamelCase of `{Api}` (for example
`setApplicationLocale`). Replace `{T} value` with the internal C++ parameter.

Every new declaration gets a `///` doc comment, placed next to the most similar
existing member.

## dart:ui

### `dart-ui-native`

`$ENGINE/lib/ui/platform_dispatcher.dart`:

```dart
  /// <Doc: what the framework tells the embedder.>
  void {api}({DartType} value) => _{api}(<convert to native-friendly value>);

  @Native<Void Function(<FFI types>)>(symbol: 'PlatformConfigurationNativeApi::{Api}')
  external static void _{api}(<native types> value);
```

FFI parameter types: `Handle` for `String`, `Bool` for `bool`, `Int32`/`Int64` for
enum indexes and integers, `Double` for doubles.

### `dart-ui-native-registration`

`$ENGINE/lib/ui/dart_ui.cc`, in the `FFI_METHOD_LIST` next to the other
`PlatformConfigurationNativeApi` entries:

```cpp
  V(PlatformConfigurationNativeApi::{Api})                                     \
```

### `platform-configuration-native`, `platform-configuration-client`

`$ENGINE/lib/ui/window/platform_configuration.h` and `.cc`.

```cpp
// class PlatformConfigurationClient
  //--------------------------------------------------------------------------
  /// @brief      <Doc.>
  ///
  /// @param[in]  value  <Doc.>
  ///
  virtual void {Api}({T} value) = 0;

// class PlatformConfigurationNativeApi
  static void {Api}({T} value);

// platform_configuration.cc
void PlatformConfigurationNativeApi::{Api}({T} value) {
  UIDartState::ThrowIfUIOperationsProhibited();
  UIDartState::Current()->platform_configuration()->client()->{Api}(
      std::move(value));
}
```

### `client-implementors`

Every `PlatformConfigurationClient` implementor (for example in
`$ENGINE/runtime/dart_isolate_unittests.cc`) must implement it. The check script lists
them.

## Runtime

### `runtime-controller`

`$ENGINE/runtime/runtime_controller.h` and `.cc`:

```cpp
  // |PlatformConfigurationClient|
  void {Api}({T} value) override;

// |PlatformConfigurationClient|
void RuntimeController::{Api}({T} value) {
  client_.{Api}(std::move(value));
}
```

### `runtime-delegate`, `runtime-delegate-implementors`

`$ENGINE/runtime/runtime_delegate.h`: `virtual void {Api}({T} value) = 0;`

Implementors include `Engine` and the test delegates in
`$ENGINE/runtime/runtime_controller_unittests.cc` and
`$ENGINE/shell/common/engine_unittests.cc`. Test mocks use `MOCK_METHOD`.

## Shell

### `engine`, `engine-delegate`, `engine-delegate-implementors`

`$ENGINE/shell/common/engine.h` and `.cc`:

```cpp
// class Engine::Delegate
    //--------------------------------------------------------------------------
    /// @brief      <Doc.>
    ///
    /// @param[in]  value  <Doc.>
    ///
    virtual void OnEngine{Api}({T} value) = 0;

// class Engine
  // |RuntimeDelegate|
  void {Api}({T} value) override;

void Engine::{Api}({T} value) {
  delegate_.OnEngine{Api}(std::move(value));
}
```

Implementors include `Shell` and the mocks in `$ENGINE/shell/common/engine_unittests.cc`
and `$ENGINE/shell/common/engine_animator_unittests.cc`.

### `shell`

`$ENGINE/shell/common/shell.h` and `.cc`. UI thread → platform thread.

```cpp
  // |Engine::Delegate|
  void OnEngine{Api}({T} value) override;

// |Engine::Delegate|
void Shell::OnEngine{Api}({T} value) {
  FML_DCHECK(is_set_up_);
  FML_DCHECK(task_runners_.GetUITaskRunner()->RunsTasksOnCurrentThread());

  fml::TaskRunner::RunNowOrPostTask(
      task_runners_.GetPlatformTaskRunner(),
      [view = platform_view_->GetWeakPtr(), value = std::move(value)] {
        if (view) {
          view->{Api}(value);
        }
      });
}
```

### `platform-view`

`$ENGINE/shell/common/platform_view.h` and `.cc`: a virtual with an empty default, so
platforms that do not care need no change.

```cpp
  //----------------------------------------------------------------------------
  /// @brief      Used by the framework to <...> in the embedding.
  ///
  /// @param[in]  value  <Doc.>
  ///
  virtual void {Api}({T} value);

void PlatformView::{Api}({T} value) {}
```

Add `// NOLINT(performance-unnecessary-value-param)` on by-value parameters if
clang-tidy flags them.

## Embedder C API

### `embedder-h-callback`

`$ENGINE/shell/platform/embedder/embedder.h`:

```c
/// <Doc: what the engine is telling the embedder.>
typedef struct {
  /// The size of this struct.
  /// Must be sizeof(Flutter{Name}).
  size_t struct_size;
  <fields>
} Flutter{Name};

typedef void (*Flutter{Name}Callback)(const Flutter{Name}* /* value */,
                                      void* /* user data */);

  // Last field of FlutterProjectArgs:
  /// The callback invoked by the engine when <...>. The callback is invoked
  /// from a task posted to the platform thread. Optional.
  Flutter{Name}Callback {name_snake}_callback;
```

For a single scalar, the callback may take the scalar directly instead of a struct.

### `embedder-cc-callback`

`$ENGINE/shell/platform/embedder/embedder.cc`, in `FlutterEngineInitialize` next to
`view_focus_change_request_callback`:

```cpp
  flutter::PlatformViewEmbedder::{Name}Callback {name_snake}_callback = nullptr;
  if (SAFE_ACCESS(args, {name_snake}_callback, nullptr) != nullptr) {
    {name_snake}_callback = [ptr = args->{name_snake}_callback,
                             user_data]({T} value) {
      Flutter{Name} embedder_value = {
          .struct_size = sizeof(Flutter{Name}),
          ...
      };
      ptr(&embedder_value, user_data);
    };
  }
```

Then append `{name_snake}_callback,` as the last entry of the
`platform_dispatch_table` initializer.

### `embedder-platform-view`

`$ENGINE/shell/platform/embedder/platform_view_embedder.h` and `.cc`:

```cpp
  using {Name}Callback = std::function<void({T})>;
  // Last field of PlatformDispatchTable:
  {Name}Callback {name_snake}_callback;  // optional

  // |PlatformView|
  void {Api}({T} value) override;

void PlatformViewEmbedder::{Api}({T} value) {
  if (platform_dispatch_table_.{name_snake}_callback != nullptr) {
    platform_dispatch_table_.{name_snake}_callback(value);
  }
}
```

## dart:ui implementations

### `web-ui-abstract`, `test-dispatcher`

- `$ENGINE/lib/web_ui/lib/platform_dispatcher.dart`: add `void {api}({DartType} value)`.
  Give it a body if the web engine has nothing to do; otherwise make it abstract and
  implement it in `$ENGINE/lib/web_ui/lib/src/engine/platform_dispatcher.dart`
  where the web engine handled the channel.
- `TestPlatformDispatcher` in `$FLUTTER_TEST/lib/src/window.dart`: forward
  `{api}` to the real dispatcher.

## Deprecated channel

### `deprecation`

Outbound channels are handled by each embedder, not the engine. Keep each embedder's
channel handler working (old frameworks still send on it), and add a comment that it
is deprecated in favour of `{name_snake}_callback` / `PlatformView::{Api}`. Do not log
a warning: the embedder cannot tell whether the framework is old.

## Framework

### `framework`

In `$FRAMEWORK/lib/src/`, replace the channel call with
`ui.PlatformDispatcher.instance.{api}(...)` (or `platformDispatcher.{api}` on a
binding). Update `SystemChannels.<channel>` docs to say the framework no longer sends
this message and what replaced it.
