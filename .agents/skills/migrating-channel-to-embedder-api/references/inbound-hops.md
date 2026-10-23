# Inbound Hops (embedder → framework)

Do the hops in order. Each has an ID used by `check_hops.dart`. Templates are taken
from flutter/flutter#194837; replace placeholders, and replace `{T} value` with the
internal C++ parameter (for example `LifecycleState state`, `bool enabled`,
`const UserSettings& settings`).

Insert each new member next to the most similar existing one (for example next to
`SetAccessibilityFeatures`), and copy that member's doc comment style. Every new
declaration gets a `///` doc comment.

## Embedder C API

### `embedder-h-type` (only if a new enum or struct is needed)

`$ENGINE/shell/platform/embedder/embedder.h`, next to similar types.

```c
/// <What this is.>
///
/// Must match the `{Name}` enum in dart:ui.
typedef enum {
  /// <Doc for each value.>
  kFlutter{Name}Foo,
  kFlutter{Name}Bar,
} Flutter{Name};
```

### `embedder-h-function`, `embedder-h-fnptr`, `embedder-h-proctable`

`embedder.h`. Declaration next to similar functions; `FnPtr` typedef next to similar
typedefs; proc table field **appended as the last field** of `FlutterEngineProcTable`.

```c
//------------------------------------------------------------------------------
/// @brief      <What it does.>
///
///             This replaces sending <payload> on the `flutter/<channel>`
///             platform channel, which is deprecated.
///
/// @param[in]  engine  A running engine instance.
/// @param[in]  value   <Doc.>
///
/// @return     The result of the call.
///
FLUTTER_EXPORT
FlutterEngineResult FlutterEngine{Api}(FLUTTER_API_SYMBOL(FlutterEngine) engine,
                                       {CType} value);

typedef FlutterEngineResult (*FlutterEngine{Api}FnPtr)(
    FLUTTER_API_SYMBOL(FlutterEngine) engine,
    {CType} value);

  // Last field of FlutterEngineProcTable:
  FlutterEngine{Api}FnPtr {Api};
```

### `embedder-cc-function`, `embedder-cc-setproc`

`$ENGINE/shell/platform/embedder/embedder.cc`.

```cpp
FlutterEngineResult FlutterEngine{Api}(FLUTTER_API_SYMBOL(FlutterEngine) engine,
                                       {CType} value) {
  if (engine == nullptr) {
    return LOG_EMBEDDER_ERROR(kInvalidArguments, "Invalid engine handle.");
  }

  // Convert and validate. For enums: switch over every value, default returns
  // LOG_EMBEDDER_ERROR(kInvalidArguments, ...). For struct pointers: null check,
  // then STRUCT_HAS_MEMBER(value, last_field_of_first_version).
  {T} internal_value = ...;

  if (!reinterpret_cast<flutter::EmbedderEngine*>(engine)->{Api}(
          internal_value)) {
    return LOG_EMBEDDER_ERROR(kInternalInconsistency,
                              "Could not <do the thing>.");
  }
  return kSuccess;
}

// In FlutterEngineGetProcAddresses, last entry before #undef SET_PROC:
  SET_PROC({Api}, FlutterEngine{Api});
```

### `embedder-engine`

`$ENGINE/shell/platform/embedder/embedder_engine.h` and `.cc`.

```cpp
bool {Api}({T} value);

bool EmbedderEngine::{Api}({T} value) {
  if (!IsValid()) {
    return false;
  }
  auto platform_view = shell_->GetPlatformView();
  if (!platform_view) {
    return false;
  }
  platform_view->{Api}(value);
  return true;
}
```

## Shell

### `platform-view`, `platform-view-delegate`

`$ENGINE/shell/common/platform_view.h` and `.cc`. Add a pure virtual to
`PlatformView::Delegate` and a non-virtual forwarding method to `PlatformView`.

```cpp
// PlatformView::Delegate
    //--------------------------------------------------------------------------
    /// @brief      Notifies the delegate that the embedder has <...>.
    ///
    /// @param[in]  value  <Doc.>
    ///
    virtual void OnPlatformView{Api}({T} value) = 0;

// PlatformView
  //----------------------------------------------------------------------------
  /// @brief      Used by embedders to <...>.
  ///
  /// @param[in]  value  <Doc.>
  ///
  void {Api}({T} value);

// platform_view.cc
void PlatformView::{Api}({T} value) {
  delegate_.OnPlatformView{Api}(value);
}
```

### `delegate-implementors`

Every `PlatformView::Delegate` implementor must implement the new method. The check
script lists them. Known ones:

| File | Form |
|---|---|
| `$ENGINE/shell/common/shell_unittests.cc` | `MOCK_METHOD(void, OnPlatformView{Api}, ({T} value), (override));` |
| `$ENGINE/shell/platform/embedder/platform_view_embedder_unittests.cc` | `MOCK_METHOD` as above |
| `$ENGINE/shell/platform/fuchsia/flutter/tests/platform_view_unittest.cc` | `void OnPlatformView{Api}(flutter::{T} value) {}` with `// \|flutter::PlatformView::Delegate\|` |
| iOS test `.mm` files under `$ENGINE/shell/platform/darwin/ios/` | `void OnPlatformView{Api}({T} value) override {}` |

### `shell`

`$ENGINE/shell/common/shell.h` and `.cc`. Platform thread → UI thread.

```cpp
  // |PlatformView::Delegate|
  void OnPlatformView{Api}({T} value) override;

// |PlatformView::Delegate|
void Shell::OnPlatformView{Api}({T} value) {
  FML_DCHECK(is_set_up_);
  FML_DCHECK(task_runners_.GetPlatformTaskRunner()->RunsTasksOnCurrentThread());

  fml::TaskRunner::RunNowAndFlushMessages(
      task_runners_.GetUITaskRunner(), [engine = engine_->GetWeakPtr(), value] {
        if (engine) {
          engine->{Api}(value);
        }
      });
}
```

Capture large values by move (`value = std::move(value)`).

### `engine`

`$ENGINE/shell/common/engine.h` and `.cc`.

```cpp
  //----------------------------------------------------------------------------
  /// @brief      Notifies the engine that <...>. This originates in the
  ///             platform view and is forwarded to the engine here on the UI
  ///             task runner by the shell.
  ///
  /// @param[in]  value  <Doc.>
  ///
  void {Api}({T} value);

void Engine::{Api}({T} value) {
  runtime_controller_->{Api}(value);
}
```

If the old channel handler did extra work (for example `ScheduleFrame()`), do the
same work here so both paths behave identically.

## Runtime

### `runtime-controller`

`$ENGINE/runtime/runtime_controller.h` and `.cc`.

```cpp
  //----------------------------------------------------------------------------
  /// @brief      Forward <...> to the running isolate. If the isolate is not
  ///             running, the value will be saved and flushed to the isolate
  ///             when it starts running.
  ///
  /// @param[in]  value  <Doc.>
  ///
  /// @return     If the value was forwarded to the running isolate.
  ///
  bool {Api}({T} value);

bool RuntimeController::{Api}({T} value) {
  platform_data_.{name_snake} = value;  // state only

  if (auto* platform_configuration = GetPlatformConfigurationIfAvailable()) {
    platform_configuration->Update{Name}(value);  // event: ->{Api}(value)
    return true;
  }
  return false;
}
```

### `platform-data`, `flush` (state only)

`$ENGINE/runtime/platform_data.h`: add `std::optional<{T}> {name_snake};` (optional
means "not yet reported"; use a plain field with a default if a default is
meaningful).

`RuntimeController::FlushRuntimeStateToIsolate` in `runtime_controller.cc`: add

```cpp
         (!platform_data_.{name_snake}.has_value() ||
          {Api}(platform_data_.{name_snake}.value())) &&
```

## dart:ui

### `platform-configuration`

`$ENGINE/lib/ui/window/platform_configuration.h` and `.cc`. For events use `{Api}`
instead of `Update{Name}` and `_{api}` instead of `_update{Name}` throughout.

```cpp
  //----------------------------------------------------------------------------
  /// @brief      Updates <...> in the framework.
  ///
  /// @param[in]  value  <Doc.>
  ///
  void Update{Name}({T} value);

  tonic::DartPersistentValue update_{name_snake}_;

// In DidCreateIsolate:
  update_{name_snake}_.Set(
      tonic::DartState::Current(),
      Dart_GetField(library, tonic::ToDart("_update{Name}")));

void PlatformConfiguration::Update{Name}({T} value) {
  std::shared_ptr<tonic::DartState> dart_state =
      update_{name_snake}_.dart_state().lock();
  if (!dart_state) {
    return;
  }
  tonic::DartState::Scope scope(dart_state);
  tonic::CheckAndHandleError(tonic::DartInvoke(
      update_{name_snake}_.Get(),
      {tonic::ToDart(static_cast<int32_t>(value))}));  // one ToDart per field
}
```

If a new internal C++ enum is needed and nothing reusable exists, define it in
`platform_configuration.h` with the comment `Must match the {Name} enum in dart:ui.`

### `hooks`

`$ENGINE/lib/ui/hooks.dart`:

```dart
@pragma('vm:entry-point')
void _update{Name}(int value) {
  PlatformDispatcher.instance._update{Name}(value);
}
```

### `dart-ui-dispatcher`

`$ENGINE/lib/ui/platform_dispatcher.dart`. State form shown; for events drop the
getter and name the callback `on{Name}`.

```dart
  /// <Doc.> This is null until the embedder reports a value.
  ///
  /// The [on{Name}Changed] callback is called whenever this value changes.
  {DartType}? get {name} => _{name};
  {DartType}? _{name};

  /// A callback that is invoked whenever [{name}] changes.
  ///
  /// The framework invokes this callback in the same zone in which the
  /// callback was set.
  VoidCallback? get on{Name}Changed => _on{Name}Changed;
  VoidCallback? _on{Name}Changed;
  Zone _on{Name}ChangedZone = Zone.root;
  set on{Name}Changed(VoidCallback? callback) {
    _on{Name}Changed = callback;
    _on{Name}ChangedZone = Zone.current;
  }

  // Called from the engine, via hooks.dart
  void _update{Name}(int value) {
    // Validate (enum index range), convert, ignore if unchanged.
    ...
    _{name} = newValue;
    _invoke(on{Name}Changed, _on{Name}ChangedZone);
  }
```

### `web-ui-abstract`, `web-ui-impl`

`$ENGINE/lib/web_ui/lib/platform_dispatcher.dart` (abstract members) and
`$ENGINE/lib/web_ui/lib/src/engine/platform_dispatcher.dart`
(`EnginePlatformDispatcher`). The web engine has no embedder API: where it used to
call `invokeOnPlatformMessage('flutter/<channel>', ...)`, set the field and invoke
the callback directly.

```dart
  @override
  ui.{DartType}? get {name} => _{name};
  ui.{DartType}? _{name};

  @override
  ui.VoidCallback? get on{Name}Changed => _on{Name}Changed;
  ui.VoidCallback? _on{Name}Changed;
  Zone? _on{Name}ChangedZone;
  @override
  set on{Name}Changed(ui.VoidCallback? callback) {
    _on{Name}Changed = callback;
    _on{Name}ChangedZone = Zone.current;
  }
```

Update web test helpers that spied on the channel (for example
`$ENGINE/lib/web_ui/test/common/spy.dart`).

### `test-dispatcher`

`TestPlatformDispatcher` in `$FLUTTER_TEST/lib/src/window.dart`: forward the getter
and callback to the real dispatcher, add a `{name}TestValue` setter that also calls
the callback, a `clear{Name}TestValue()`, and call it from `clearAllTestValues()`.

## Deprecated channel

### `deprecation-warning`

In the engine's handler for the old channel (`Engine::Handle*PlatformMessage` in
`$ENGINE/shell/common/engine.cc`, adding an intercept in `DispatchPlatformMessage` if
there is none):

```cpp
// Deprecated: Embedders should use |PlatformView::{Api}|
// (|FlutterEngine{Api}| in the embedder API) instead of sending messages on the
// flutter/<channel> channel.
// TODO(<github-username>): Remove once embedders have migrated.
bool Engine::Handle<Channel>PlatformMessage(PlatformMessage* message) {
  static std::once_flag deprecation_warning;
  std::call_once(deprecation_warning, []() {
    // Logged as an error as warnings are hidden once the engine is running.
    FML_LOG(ERROR) << "Sending messages on the " << k<Channel>Channel
                   << " channel is deprecated, use FlutterEngine{Api} in the "
                      "embedder API instead.";
  });

  // Parse the old payload. On failure, return false (message is forwarded
  // unchanged, preserving old behaviour).
  ...
  {Api}(value);
  if (message->response()) {
    message->response()->CompleteEmpty();
  }
  return true;  // Handled: the framework now receives it through dart:ui.
}
```

Ask the user for the `TODO` username if it is not obvious from git config.

## Framework

### `framework`

In `$FRAMEWORK/lib/src/`:

1. Where the binding registered a handler for the channel, also set
   `platformDispatcher.on{Name}Changed = _handle{Name}Changed;` and, at startup, read
   `platformDispatcher.{name}` first, falling back to the old initial value.
2. Keep the existing channel handler working: tests and old embedders still send on
   it.
3. If `SystemChannels.<channel>` is public, apps may listen to it. Keep delivering
   each change to listeners:

   ```dart
   ui.channelBuffers.push(
     SystemChannels.<channel>.name,
     SystemChannels.<channel>.codec.encodeMessage(<old payload>),
     (ByteData? reply) {},
   );
   ```

4. Update the `SystemChannels.<channel>` doc comment to say it is deprecated, how
   compatibility works, and what to use instead. Update doc comments elsewhere that
   say the value comes from the channel.
