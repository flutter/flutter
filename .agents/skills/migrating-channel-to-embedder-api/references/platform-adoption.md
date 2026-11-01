# Adopting the New API in Each Embedder

Only change embedders that use the channel today (from the inventory). For each one:
switch the sender (inbound) or handler (outbound) to the new API, remove code that
only existed to feed the channel, and update its tests.

Prefer passing the existing platform enum or type to a single conversion function
over writing a new `switch` at every call site. If two embedders need the same
conversion, put it once in `$ENGINE/shell/platform/common/`.

## Linux (`$ENGINE/shell/platform/linux/`)

Uses the embedder API through `self->embedder_api`.

**Inbound.** Add to `fl_engine_private.h` and `fl_engine.cc`:

```c
/**
 * fl_engine_{verb}_{name_snake}:
 * @engine: an #FlEngine.
 * @value: <doc>.
 *
 * <Doc.>
 */
void fl_engine_{verb}_{name_snake}(FlEngine* engine, {CType} value);
```

```cpp
void fl_engine_{verb}_{name_snake}(FlEngine* self, {CType} value) {
  g_return_if_fail(FL_IS_ENGINE(self));

  if (self->engine == nullptr) {
    return;
  }

  if (self->embedder_api.{Api}(self->engine, value) != kSuccess) {
    g_warning("Failed to <...>");
  }
}
```

Replace the channel sender (often an `fl_*_channel.cc` or a `*_monitor.cc`) with calls
to this function. If an `Fl*Channel` class exists only to send this message, leave it
in place but unused only if removing it breaks public API; otherwise delete it and
its test and remove them from `BUILD.gn`.

**Outbound.** In `fl_engine_start`, set `args.{name_snake}_callback` to a static
function that recovers `FlEngine*` from `user_data` and emits a signal or calls the
owner.

**Tests.** `testing/mock_engine.cc` has its own proc table with only the procs
Linux tests need. If a test reaches the new call without overriding it, add a stub
there (`table->{Api} = &FlutterEngine{Api};`), or the test calls a null pointer.
Otherwise mock the proc in the `*_test.cc` file:

```cpp
fl_engine_get_embedder_api(engine)->{Api} = MOCK_ENGINE_PROC(
    {Api}, ([&called](auto engine, {CType} value) {
      called = true;
      return kSuccess;
    }));
```

## Windows (`$ENGINE/shell/platform/windows/`)

Uses the embedder API through `embedder_api_` and `engine_` in
`FlutterWindowsEngine`.

**Inbound.** Add `void {Api}(<platform type> value);` to `flutter_windows_engine.h`
and implement it with `embedder_api_.{Api}(engine_, converted_value);`. Point the old
sender (for example `windows_lifecycle_manager.cc` or `settings_plugin.cc`) at it.
Remove any "is the framework listening yet" gating that only existed for the channel
(the engine now caches state until the isolate starts). Grep tests and
`windows/fixtures/main.dart` for the gating method: mocks that override it, tests
that enable it, and tests that only test it need updating or removing. Note the
behaviour change in the PR.

**Outbound.** In `FlutterWindowsEngine::Run`, set `args.{name_snake}_callback` next
to `args.view_focus_change_request_callback`, casting `user_data` to
`FlutterWindowsEngine*`.

**Tests.** In `flutter_windows_engine_unittests.cc` (and the plugin's own test):

```cpp
EngineModifier modifier(engine.get());
modifier.embedder_api().{Api} = MOCK_ENGINE_PROC(
    {Api}, ([&](auto engine, {CType} value) { ...; return kSuccess; }));
```

Update Dart fixtures in `windows/fixtures/main.dart` that listened on the channel.

## macOS (`$ENGINE/shell/platform/darwin/macos/framework/Source/`)

Uses the embedder API through `_embedderAPI` and `_engine` in `FlutterEngine.mm`.

**Inbound.** Replace `[self sendOnChannel:@"flutter/<channel>" ...]` with
`_embedderAPI.{Api}(_engine, converted_value);`. Delete the channel name constant if
it is now unused.

**Outbound.** In `runWithEntrypoint:`, set `flutterArguments.{name_snake}_callback`
next to `view_focus_change_request_callback`, bridging `user_data` to
`FlutterEngine*`.

**Tests.** In `FlutterEngineTest.mm`:

```objc
engine.embedderAPI.{Api} = MOCK_ENGINE_PROC({Api}, ([&](auto engine, auto value) {
  ...;
  return kSuccess;
}));
```

## iOS (`$ENGINE/shell/platform/darwin/ios/framework/Source/`)

Does **not** use the embedder C API. It calls `flutter::PlatformView` directly.

**Inbound.** Add an internal method to `FlutterEngine_Internal.h` and `FlutterEngine.mm`:

```objc
- (void){api}:({T})value {
  if (self.platformView) {
    self.platformView->{Api}(value);
  }
}
```

Replace `[self.<channel>Channel sendMessage:...]` calls (in `FlutterEngine.mm`,
`FlutterViewController.mm` and others; see the "Users of wrappers" inventory
section) with it. Internal helpers that take the old string payload (for example
`goToApplicationLifecycle:(NSString*)`, used by `performSelector` and many OCMock
tests) can keep their signature and convert to the new type inside. Keep the public channel property on
`FlutterEngine` (public API), but stop sending on it.

**Outbound.** Override `{Api}` in `$ENGINE/shell/platform/darwin/ios/platform_view_ios.h`
and `.mm`, forwarding to the owner (usually the `FlutterViewController` or an
internal bridge).

**Tests.** Update XCTest files that stubbed or verified the channel
(`FlutterViewControllerTest.mm`, `FlutterEngineTest.mm`) to verify the new method.
Mock `PlatformView::Delegate` classes in iOS tests are covered by `check_hops.dart`.

## Android (`$ENGINE/shell/platform/android/`)

Does **not** use the embedder C API. Java calls into C++ through `FlutterJNI`.

**Inbound.**

1. `io/flutter/embedding/engine/FlutterJNI.java`:

   ```java
   /** <Doc.> */
   @UiThread
   public void {api}(<java type> value) {
     ensureRunningOnMainThread();
     if (isAttached()) {
       native{Api}(nativeShellHolderId, value);
     }
   }

   private native void native{Api}(long nativeShellHolderId, <java type> value);
   ```

2. `platform_view_android_jni_impl.cc`: a static function that validates, converts
   and calls `ANDROID_SHELL_HOLDER->GetPlatformView()->{Api}(...)`, plus an entry in
   `RegisterApi` with `.name = "native{Api}"` and the matching JNI `.signature`
   (for example `"(JI)V"` for `long, int`).
3. Make the `systemchannels/*Channel.java` class call `flutterJNI.{api}(...)` when it
   was constructed with a `FlutterJNI`, keeping the old `DartExecutor` constructor
   working (and `@Deprecated`). Update where `FlutterEngine.java` constructs it.

**Outbound.**

1. `jni/platform_view_android_jni.h`: `virtual void FlutterView{Api}({T} value) = 0;`
2. `jni/jni_mock.h`: `MOCK_METHOD(void, FlutterView{Api}, ({T} value), (override));`
3. `platform_view_android_jni_impl.h` and `.cc`: implement it by calling a Java method
   on `FlutterJNI`, looked up with the `V(g_..._method, {api}, "(...)V")` list near
   the top of `platform_view_android_jni_impl.cc`.
4. `platform_view_android.h` and `.cc`: override `PlatformView::{Api}` and forward to
   `jni_facade_->FlutterView{Api}(value)`.
5. `FlutterJNI.java`: the `@SuppressWarnings("unused")` method called from native code.

**Tests.** Robolectric tests under `test/io/flutter/` for the Java side (for example
verify `flutterJNI.{api}` is called), and `android_shell_holder_unittests.cc` or
`platform_view_android_unittests.cc` for the C++ side.

## Web (`$ENGINE/lib/web_ui/`)

No embedder API. Covered by the `web-ui-*` hops in the hop checklists: the web
engine sets the value on `EnginePlatformDispatcher` and invokes the callback
directly instead of calling `invokeOnPlatformMessage('flutter/<channel>', ...)`.
Update tests under `test/engine/platform_dispatcher/`.

## Fuchsia (`$ENGINE/shell/platform/fuchsia/flutter/`)

Does not use the embedder API. If `platform_view.cc` sends on the channel, call
`PlatformView::{Api}` instead. The mock `PlatformView::Delegate` in
`tests/platform_view_unittest.cc` is covered by `check_hops.dart`. Fuchsia cannot be
built on most hosts; list it as unverified.
