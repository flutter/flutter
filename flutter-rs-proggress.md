# Flutter Rust Shell Progress (WIP)

This file records implementation progress for the architecture in
[`flutter-rs.md`](flutter-rs.md). It is an implementation log, not a replacement
for the architectural plan.

## Current focus

Phase 0, the Phase 1 host, and the Phase 2 shared-GPU/texture proof are complete
for Linux. The current cross-cutting focus is generated Cargo application and
plugin aggregation; the next platform phase is Windows. Pointer,
window metrics, display updates, lifecycle, raw keyboard events, and a rendered
Impeller/wgpu frame are working. The explicit Vulkan semaphore broker is now
implemented and passes rapid-resize and in-flight teardown stress. Typed text
input/IME plumbing and compositor-driven Wayland vsync are implemented and
validated. The current milestone is single-engine multi-view: one Flutter
engine and Dart isolate per application, with one native winit window and GPU
presentation surface per Flutter view. Regular, dialog, tooltip, popup, and
satellite windows now work through the typed Rust backend; main-thread dispatch
is now wired through the plugin SDK and winit host queue, and deterministic
startup/shutdown ownership is covered in both unit and repeated native tests.
The engine-side `RustExternalTexture` seam, private registration ABI, and a
triple-buffered wgpu texture ring are implemented. An opt-in internal producer
has rendered continuously changing zero-copy frames in a real Flutter
`Texture` widget. The ring now implements the safe SDK handle and frame backend
using a bounded Tokio channel for asynchronous slot availability. Its creation
factory is installed in `PluginRegistrar` after shell startup, and the animated
proof now registers as a normal source-linked plugin using only public SDK
operations. Both hardware and CPU pixel-buffer fixtures are checked in and pass
locally. Texture lifecycle hardening now shuts down frame production, wakes
asynchronous slot waiters, and reclaims each retained ring after raster-thread
unregister completes. The real-runner lifecycle fixture also injects the
texture registry's context-destroyed/context-created sequence midway through
live texture replacement and proves presentation resumes afterward. The
general application plugin-registration entry point is now wired: a generated
Cargo application can pass `register_application` to the host, which invokes
it exactly once after the engine, implicit view, dispatcher, and GPU capability
are live. The end-to-end FRB fixture now proves root-isolate synchronous calls,
background-isolate worker calls, deferred non-reentrant dispatch, main-thread
execution, response delivery, and clean native shutdown through that entry
point.
The winit host is no longer hidden inside a Linux-only module: shared event-loop,
input, lifecycle, window bookkeeping, texture, and plugin code compiles at the
crate root. Native operations use statically dispatched platform traits, with
the current Linux implementation isolated under `platform/linux.rs`.
The Rust-shell SDK (crates plus prebuilt engine libraries) is now distributed
through a rolling BETA GitHub release built by CI from every push, so an
FVM-installed Flutter fork can use `flutter.shell: rust` without a local engine
checkout; a checked-out engine tree is still preferred automatically when
present. `flutter run -d rust` now supports `--release` in addition to debug:
the tool AOT-compiles the Dart app, builds `runner-rs` with `cargo build
--release`, and links it against a second, precompiled-runtime engine build
that the CI workflow now produces alongside the existing debug one.

Android work (milestones 1–2) has separately proved a GameActivity cdylib that
dynamically links a GN-built engine and renders a real Dart isolate, but only
in debug/JIT mode. Milestone 3 brings the same native release/AOT support
Linux already has to that Android scaffold: fixed a `build_rust.py` bug that
silently built every Cargo GN action's debug profile regardless of
`FLUTTER_RUNTIME_MODE`, added `aot_library_path` derivation to the Android
runner, and validated a real release-mode `app.so` rendering interactively on
a physical device with no `kernel_blob.bin` present (proving the AOT path,
not a silent JIT fallback). A generalized `AndroidRustShellDevice` in
flutter_tools (matching `RustShellDevice` for Linux) — generated-app Android
templates, real Gradle-driven `flutter run -d <android>`, and `AAssetManager`
asset loading instead of the adb-push placeholder — remains future work, the
same way Linux's own flutter_tools integration followed its native runner.

## Status

| Area | Status | Evidence |
| --- | --- | --- |
| Existing shells remain available | Complete | The Rust target is opt-in and is not added to the existing platform-selection group. |
| In-tree Rust platform target | Complete | `//flutter/shell/platform/rust:flutter_rust_shell` builds. |
| Internal PlatformView adapter | Complete | `PlatformViewRust` builds and its focused tests pass. |
| Rust/C++ ABI | External-texture extension complete | ABI v10 retains the multi-view/windowing contract and adds engine-generated external-texture IDs plus acquire, mark-frame-available, release, and unregister operations for borrowed Vulkan image/image-view handles and semaphore pairs. Raster unregister reports completion so Rust can reclaim callback owners safely; a private test-only entry point injects texture-registry context destruction/recreation on the raster runner. |
| Rust workspace and `flutter-plugin-sdk` | Complete for foundation | Workspace uses Rust edition 2024, concrete toolchain 1.93.1, and passes its tests. |
| Winit event loop | Complete for phase 0 | Linux host owns the window and event loop, dispatches Flutter task batons, and drives the Rust-owned Vulkan presentation loop end to end. |
| Cross-platform host boundary | Linux adapter extracted | Shared host code is unconditionally compiled. `PlatformBackend` statically selects native popup creation, transient parenting, window attributes, compositor detection, and legacy key encoding; `LinuxPlatform` contains the Wayland/X11 implementation. `EngineBridge` similarly centralizes the C++ task-runner boundary and its test fake. No shell-owned backend trait uses dynamic dispatch, and test configuration is confined to the engine implementation selector plus `mod tests`. |
| Merged UI/platform task runner | Complete for phase 0 | `RustTaskRunner` queues batons for the Rust host, winit returns due batons through opaque C++ handles, and it now also drives Dart's per-task microtask flush (see below). |
| Impeller/wgpu interop | Explicit synchronization implemented and stress-tested | wgpu owns the Vulkan device/surface; C++ creates `ContextVK` from borrowed handles plus the in-tree Impeller Vulkan shader bundle. Per-frame binary semaphores now order wgpu acquire → Impeller render → wgpu present, synchronization objects stay alive through the consuming submission, and resize waits for that submission before swapchain replacement. A repeatable 500-resize compositor stress run, including hide/restore, fullscreen, and immediate teardown, exits cleanly with no wgpu or Impeller synchronization diagnostics. |
| Linux runnable shell | Complete for rendered-frame proof | `flutter_rust_shell_runner` boots a real kernel-snapshot Flutter app; a live Hyprland capture shows the Flutter title, text field, button, and debug banner rendered in the Rust shell. |
| Pointer input | Complete for phase 1 plumbing | Winit mouse, wheel, and touch events cross the private ABI and are converted into Flutter `PointerDataPacket`s; Rust translation and C++ conversion tests pass. |
| Window and display metrics | Complete for phase 1 plumbing | Initial, resize, and scale-factor changes report physical viewport size, the real device-pixel ratio, and current-monitor size/refresh rate; zero-sized surfaces are not configured. |
| Lifecycle | Complete for phase 1 plumbing | Focus, minimize/restore, winit suspend/resume, and shutdown are deduplicated in Rust and forwarded through `flutter/lifecycle`; Rust transition and C++ ABI conversion tests pass. |
| Keyboard input | Complete for phase 1 raw events | Winit physical/logical keys, down/up/repeat, characters, modifier sides, and synthesized state cross the private ABI as Flutter `KeyData` packets. |
| Text input and IME | Complete for phase 1 plumbing | The Rust host handles the standard `flutter/textinput` protocol with typed commands and validated UTF-16 editing state, controls winit IME activation/cursor geometry, translates preedit/commit events, and sends `TextInputClient.updateEditingState` back to Flutter. Ordinary typing, Backspace, and Ctrl+A were verified interactively; a legacy `flutter/keyevent` terminator keeps Flutter's modern key-data queue moving. |
| Vsync | Complete for the Linux Wayland host | Flutter's waiter requests a winit redraw through the private ABI. Wayland `RedrawRequested` pulses are throttled by compositor frame callbacks registered immediately before actual wgpu presentation; C++ timestamps each pulse in the FML clock domain and uses the active monitor's nominal interval as its target. Non-Wayland backends retain `VsyncWaiterFallback`. |
| Multi-window | All five controller kinds implemented | View `0` remains the implicit engine view. Positive-ID winit windows share one engine, root isolate, plugin registry, task runner, and wgpu device while owning independent surfaces, metrics, input, and presentation state. Flutter's experimental window controllers select the Rust owner automatically in the Rust runner. Dialogs and satellites use native transient relationships. On Wayland, tooltip and popup views use real compositor-positioned `xdg_popup` roles; popup grabs are serial-bound and compositor dismissal enters the normal asynchronous Flutter view-removal path. Satellites support creation, shrink-wrap, reparenting, parent-driven teardown, and parent maximize/fullscreen visibility. Standard Wayland does not permit clients to choose absolute toplevel positions, so the initial satellite positioner is honored on X11 but compositor-selected on Wayland. |
| Main-thread dispatch | SDK, host, and Dart/FRB path complete | `flutter-plugin-sdk` exposes a cloneable worker-safe dispatcher through `PluginRegistrar`. Work is always queued rather than invoked inline, executes through winit's owning thread, is limited to 64 callbacks per event-loop turn, and is rejected after shell shutdown. Unit coverage verifies worker posting, thread identity, nested non-reentrant dispatch, starvation bounds, and shutdown. A real application-level FRB fixture verifies root and background Dart isolates through the Cargo-owned runner while displaying SDK wgpu and pixel-buffer textures. |
| Startup and shutdown ownership | Complete for merged runner | The dispatcher rejects work during bootstrap, starts only after the C++ shell and implicit view are installed, stops before shell/window teardown, and suppresses already queued callbacks after shutdown. A native lifecycle task requires 20 consecutive mapped-window startup, compositor-close, and status-zero shutdown cycles. |
| Application plugin registration | Runtime and Flutter-tool generation complete | `flutter-shell-winit::run_application` accepts `register_application(&mut PluginRegistrar)` and invokes it once after startup capabilities are installed. For `flutter.shell: rust` projects, the Flutter tool discovers source-linked Rust plugins from the resolved Pub graph, updates the marked dependency block in `runner-rs/Cargo.toml`, generates `flutter_plugins.rs`, and validates a single resolved plugin SDK. |
| Flutter CLI launch | Linux x64 debug and release complete | `flutter run -d rust` discovers the Rust shell as a built-in local device for `flutter.shell: rust` applications. Debug mode builds `build/flutter_assets` and the generated Cargo runner and uses the normal resident-runner lifecycle for logs, hot reload, and shutdown. Release mode AOT-compiles the Dart app to `app.so`, builds `runner-rs` with `cargo build --release`, and launches the release runner directly (no VM-service/resident-runner support, matching other release desktop targets). Profile mode is not yet supported. |
| Rust-shell SDK distribution | BETA channel complete | CI (`flutter-rust-beta.yml`) configures and builds the engine in both `debug` and `release` runtime modes, packages the workspace crates plus each engine's `libflutter_rust_engine.so`/`icudtl.dat` under `lib/debug/` and `lib/release/`, and republishes them to a rolling `BETA` GitHub release tagged to the latest imported Flutter version. `flutter pub get` on a `flutter.shell: rust` project prefers a local engine checkout's `out/host_debug`/`out/host_release` when present and otherwise downloads and unpacks the BETA tarball into `.dart_tool/flutter_rs/sdk/`; `runner-rs/build.rs` links whichever profile directory matches Cargo's own build profile. |
| Android scaffold (native) | AOT/release mode complete, debug/JIT already worked | The GameActivity cdylib (`crates/flutter-shell-android-runner`) dynamically links a GN-built `libflutter_rust_engine.so` and renders a real Dart isolate/Impeller frame in both runtime modes. `aot_library_path` now derives from `cfg!(debug_assertions)` instead of being hardcoded empty, matching `runner-rs/src/main.rs.tmpl`'s approach on Linux. Asset loading is still an adb-pushed placeholder (`flutter_assets/`/`icudtl.dat`/`app.so` copied into the app's private files dir before launch); real `AAssetManager`-backed loading and a flutter_tools-driven `AndroidRustShellDevice` remain future work. |
| Rust external texture | Engine seam complete | `RustExternalTexture` uses Flutter's existing texture registry and dirty-frame scheduling path. It retains the last good image, honors freeze, retries failed acquisition, imports borrowed wgpu Vulkan image/view handles without taking ownership, and brackets Impeller sampling with producer/consumer semaphores. Context loss, unregister, and repeated teardown are covered by focused tests. |
| Engine-owned wgpu texture | SDK runtime path complete | `WgpuTextureRing` owns three RGBA8 textures, views, and reusable semaphore pairs on the application's shared device. A bounded Tokio channel carries available slot IDs: `try_next_frame` applies immediate backpressure, `next_frame().await` sleeps until Flutter releases a slot, an unpresented reservation returns its slot on drop, and shutdown wakes waiters with `Shutdown`. Ready frames remain queue-serialized through Flutter's acquire callback. The opt-in animated proof now runs through normal `FlutterRustPlugin` registration and public SDK operations. |
| `WgpuTexture` plugin API | Public contract and Linux runtime adapter complete | `flutter-plugin-sdk` exposes validated texture descriptors, `GpuTextures::create_texture`, stable Flutter texture IDs, nonblocking `try_next_frame`, asynchronous `next_frame().await`, single-record frame reservations, consuming `present(self)`, and its pinned API crate at `gpu::wgpu` so plugins do not duplicate the Git dependency. The hidden backend uses `async-trait`; no manual `Future` or `Poll` API leaks into the SDK. The winit factory registers the callback-owning ring, routes dirty notifications and handle-drop unregister through the main thread, and releases each retained ring after C++ confirms raster-thread registry removal. The recording closure receives a device, encoder, and view—but no queue—so plugins cannot violate shared-queue external synchronization. |
| CPU pixel-buffer texture | Linux runtime path complete | `PixelBufferTexture` reserves one of three reusable shell-owned RGBA8 buffers through the same bounded channel/backpressure model. `write_pixels` lends the plugin that allocation and its row stride directly, eliminating a plugin-to-shell CPU copy; acquire performs the unavoidable wgpu CPU-to-GPU upload into the existing Vulkan external-texture ring. Registration, notification, freeze, release, unregister, and teardown reuse the proven hardware-texture seam. The permanent Dart fixture passes under Vulkan validation with changing pixels. |

## Implementation log

### Phase 0 — PlatformView seam

- Added `engine/src/flutter/shell/platform/rust/`.
- Added the standalone GN target
  `//flutter/shell/platform/rust:flutter_rust_shell` and the convenience group
  `//flutter/shell/platform:rust`.
- Added `PlatformViewRust`, an internal C++ `PlatformView` subclass. It keeps
  Flutter C++ inheritance on the engine side and accepts callbacks that the
  future Rust bridge will own.
- Implemented safe default platform-message behavior: messages with no Rust
  handler complete an empty response, matching Flutter's existing platform-view
  behavior.
- Added `flutter_rust_shell_unittests` covering callback forwarding, the
  empty platform-message response fallback.
- Added an edition-2024 Cargo workspace with the private `flutter-shell-core`
  runtime crate and the public `flutter-plugin-sdk` crate.
- Added ABI v1 in Rust and C++ header form, including a GN-linked ABI discovery
  test. Callback ownership remains the next ABI increment.
- Added a GN Cargo action that builds the Rust static library for the private
  ABI test.
- Added the `flutter-shell-winit` Linux runtime crate with a winit-owned window
  and event loop. It is intentionally not connected to Flutter task runners
  until the callback ABI has ownership semantics.
- Added `RustTaskRunner`, a private C++ task runner that gives the host loop
  opaque batons and runs them when winit returns the baton on its main thread.
  It is the basis for sharing the UI and platform task runner without using the
  Embedder task-runner API.
- Extended ABI v1 with a Rust-owned task-runner callback table and opaque C++
  runner handle. The C++ side converts `fml::TimePoint` to a relative delay;
  the Rust host queues the baton against `Instant`, so no clock epoch crosses
  the boundary.
- Added Rust task-runner host state with thread-affinity and destruction
  tracking. Its stable boxed address is the callback `user_data` owned by the
  winit host.
- Bound the Rust host queue to winit's user-event wake and monotonic
  `WaitUntil` timer. Production builds return due batons through the private
  opaque C++ runner handle; standalone Cargo tests use test-only FFI stubs.
- Added a GN action that produces the separate `flutter-shell-winit` static
  archive, keeping its platform system-library link requirements out of the
  core ABI archive.
- Added `CreateRustVulkanContext`, the internal C++ factory that validates
  borrowed Vulkan instance/device/queue handles and creates Impeller
  `ContextVK` with its in-tree `EmbedderData` mechanism. It is not exposed as
  Flutter's public Embedder API.
- Added a pinned `flutter-shell-wgpu` broker crate that owns wgpu's Vulkan
  instance, adapter, device, queue, and winit surface, and exposes raw Vulkan
  values only through a scoped wgpu-hal handoff.
- Left existing platform shells unmodified and unselected. The Rust runner
  selects its own target explicitly.

### Phase 0 — completing the seam

- Implemented real swapchain acquire/present in `GpuBroker`: `acquire_image`
  calls `Surface::get_current_texture`, extracts the raw `VkImage` through
  wgpu-hal, and holds the acquired `SurfaceTexture` until `present_image` hands
  it back to `Queue::present`. `configure` picks a swapchain format from a
  fixed preference list (`Bgra8Unorm`, then `Rgba8Unorm`) rather than the
  surface's first-reported format, because Impeller's Vulkan backend
  (`VkFormatToImpellerFormat`) only recognizes those two formats and silently
  rejects sRGB/other variants at frame-acquire time.
- Added the FFI-safe mirror of `RustVulkanContextData`/`FlutterVulkanImage`/
  presentation callbacks/settings in `flutter-shell-core`, plus C ABI functions
  `FlutterRustShellCreateShell`, `FlutterRustShellRunShell`,
  `FlutterRustShellSetViewportMetrics`, and `FlutterRustShellDestroyShell` in
  `cpp/rust_shell.cc`.
- Wired `flutter-shell-winit`'s `resumed()`/`window_event()` to actually create
  and run the `RustShell`: it extracts Vulkan handles via
  `GpuBroker::with_vulkan_context`, builds the presentation callback table from
  `GpuBroker::presentation_callbacks`, and calls the new shell lifecycle FFI.
- Added `cpp/main.cc` and the `flutter_rust_shell_runner` GN executable: a
  two-line C++ process entry point that calls straight into Rust's
  `FlutterRustShellRun` (in `flutter-shell-winit`), which owns the winit event
  loop for the rest of the process lifetime. See "Who owns the final link" in
  `flutter-rs.md` for why this is a GN-owned executable rather than a Cargo
  `bin` crate, and why that is a phase 0 expedient rather than the intended
  shape of generated apps' `runner-rs/`.
- Linked the Dart VM, Impeller's Vulkan shader bundle, and
  `//flutter/shell/gpu:gpu_surface_vulkan` into the runner; added
  `export_dynamic_symbols` so the Dart VM's "look inside the currently loaded
  process" JIT snapshot resolution can find the statically linked snapshot
  symbols despite the engine's default hidden-visibility build config.
- Set `Settings::application_kernel_asset = "kernel_blob.bin"` for the JIT-only
  phase 0 path, and `Settings::enable_impeller = true` explicitly — this only
  defaults to true on Android/iOS; every other platform (including Linux)
  defaults to false, and leaving it unset makes the Dart-level paragraph/text
  layer build Skia-flavored `DlText` objects that crash the moment anything
  draws text against an Impeller-only surface.
- Added `RustShell::SetViewportMetrics`, called once after the shell starts
  running and again on every winit resize. Without it the engine has no valid
  implicit view to schedule frames for, so `PlatformView::NotifyCreated` alone
  produces a working surface but no frame is ever requested.
- Gave `RustTaskRunner` its own task-observer registry
  (`AddTaskObserver`/`RemoveTaskObserver`), invoked after every `RunTask` call.
  The winit-owned UI thread never installs a real `fml::MessageLoop`, so
  `Settings::task_observer_add/remove` (which `UIDartState` uses to flush the
  root isolate's microtask queue after each task) had nowhere to go; this
  mirrors `fml::MessageLoopImpl::FlushTasks`'s run-task-then-notify-observers
  order.
- Fixed a real identity-confusion bug in `FlutterRustShellRunTask`: it cast its
  `task_runner` argument to `RustTaskRunnerHandle*` (the wrapper returned by
  `FlutterRustShellCreateTaskRunner`), but the value that actually flows
  through `schedule_task` and back is the raw `RustTaskRunner*` (`this`, from
  `PostTaskForTime`) — a different pointer to a different object. The old code
  only appeared to work because the one test exercising it happened to pass
  the handle both ways; rewrote that test (`OwnsOpaqueRunnerHandleForRustHost`)
  to post through the real `fml::TaskRunner` interface so it exercises the
  actual identity contract.
- Fixed a real dangling-pointer bug in `flutter-shell-winit`: the presentation
  callback table's `user_data` was captured as `&gpu_broker` while `gpu_broker`
  was still a local stack variable in `resumed()`, then that local was moved
  into `self.gpu_broker` afterward — invalidating the address C++ holds for the
  shell's entire lifetime. Reordered so the broker moves into its final,
  stable location (a field of `ShellApplication`, which winit never moves once
  `run_app` starts using it by `&mut`) before anything takes its address.
- Verified end to end against a real Flutter counter app (a fork checkout's
  `build/flutter_assets`, JIT `kernel_blob.bin`): the runner boots the Dart VM,
  runs the root isolate, acquires and presents real Vulkan swapchain images
  every frame with no crashes or errors, and Hyprland (the Wayland compositor
  in the dev environment) reports the "Flutter Rust Shell" window `mapped: 1`,
  `visible: 1`, at the requested size. A screenshot could not be captured in
  this session (the desktop session was locked), so this is confirmed by
  process stability plus compositor window state rather than a rendered image.

### Phase 1 — pointer input

- Added a private, value-only pointer event to the Rust/C++ ABI with explicit
  phase, device-kind, and signal-kind translation on the engine side. Invalid
  enum values are dropped instead of being cast into Flutter's internal enums.
- Added winit mouse state tracking for add/remove, hover/drag motion, primary,
  secondary, middle, back, and forward button masks.
- Forwarded wheel input as Flutter scroll signals. Winit line deltas use the
  Linux shell's 53-physical-pixel line unit, and vertical deltas are normalized
  from winit's positive-up convention to Flutter's positive-down convention.
- Forwarded winit touch started/moved/ended/cancelled phases with stable touch
  device identifiers and contact button state.
- Added Rust tests for synthesized mouse entry, hover/drag transitions, button
  state, and scroll normalization, plus C++ tests for private-ABI conversion and
  rejection of unknown enum values.
- Declared directly linked Rust archives as GN inputs so Rust-only changes
  reliably relink the native runner and ABI test executable.

### Phase 1 — window metrics and lifecycle

- Replaced the hardcoded `1.0` viewport device-pixel ratio with winit's real
  window scale factor, including `ScaleFactorChanged` handling.
- Added current-monitor physical size and refresh rate to the private metrics
  call. C++ publishes those through `Shell::OnDisplayUpdates` before updating
  the implicit view's viewport metrics.
- Kept Vulkan surface configuration gated on non-zero physical dimensions and
  used zero-sized resize events to represent a hidden/minimized window.
- Added a Rust lifecycle state machine that combines application activity,
  window visibility, and focus into deduplicated resumed, inactive, hidden,
  paused, and detached transitions.
- Added an explicitly translated private lifecycle enum and forwarded valid
  states through the engine's `flutter/lifecycle` channel. Unknown values are
  ignored rather than cast across the ABI.
- Added Rust lifecycle transition tests and C++ lifecycle enum conversion
  coverage.

### Phase 1 — keyboard input

- Added a value-only private key-event ABI and dispatched validated Flutter
  `KeyDataPacket`s over the engine's `flutter/keydata` channel.
- Translated the common winit `KeyCode` set to Flutter USB HID physical key
  IDs, including left/right modifier identity, and used Flutter logical key
  constants for named and numpad keys.
- Forwarded down, up, repeat, character, and synthesized-event state. Unknown
  XKB keys use the same private GTK key plane convention as Flutter's Linux
  keyboard implementation; unrepresentable native keys are dropped.
- Added Rust translation tests and C++ packet-layout/invalid-input tests. Text
  editing and IME composition remain the next, separate input layer.

### Phase 1 — rendered frame and resize safety

- Added the missing Rust-engine export script and assigned a stable engine ID
  during `RustShell::Run`, allowing Flutter's Linux windowing initialization to
  complete in the standalone Rust shell.
- Added a wgpu acquire barrier/initialization submission before handing a raw
  swapchain image to Impeller. This fixes the previously observed black frame.
- Serialized surface state, deferred resize configuration while a frame is in
  flight, rejected overlapping acquisitions, and recovered once from an
  `Outdated` surface result.
- Verified a rendered Flutter window and a 100-event resize smoke test. The
  remaining fence/invalid-image messages under aggressive resize are tracked as
  incomplete GPU interop synchronization rather than hidden as success.

### Phase 1 — Vulkan synchronization broker

- Bumped the lockstep private shell ABI to v2 and carried broker-owned acquire
  and render-complete Vulkan semaphore handles alongside each borrowed image.
- Made wgpu's acquire/initialization submission signal the acquire semaphore;
  `RustVulkanPresentation` consumes that semaphore on Impeller's graphics queue
  before returning the image to the rasterizer.
- Made Impeller signal the render-complete semaphore after its final image
  layout transition. The broker's final load/store submission waits on that
  semaphore and touches the `SurfaceTexture`, ensuring wgpu's actual present
  semaphore is not signalled before Impeller completes.
- Retained semaphore pairs until the consuming wgpu submission completes,
  bounded normal-operation retirement to three frames, and waited/drained all
  retired pairs before deferred resize reconfiguration. Teardown waits for the
  borrowed Vulkan device to become idle before destroying any remaining pairs.

### Phase 1 — text input and IME

- Bumped the lockstep private shell ABI to v3 and added generic, borrowed-byte
  platform-message callbacks in both directions. C++ owns Flutter's
  `PlatformMessage` objects and response completion; Rust copies and decodes
  messages before the callback returns.
- Installed a queued `flutter/textinput` handler so framework calls cannot
  re-enter mutable winit application state while the merged UI/platform runner
  is executing a Flutter task.
- Decoded the JSON method codec immediately into typed Rust commands, client
  IDs, editing states, affinities, and cursor rectangles. Malformed commands,
  non-finite rectangles, out-of-range offsets, and offsets that split UTF-16
  surrogate pairs are rejected at the boundary.
- Implemented `setClient`, `setEditingState`, `show`, `hide`, `clearClient`,
  caret/marked-text rectangles, and safe no-op handling for current geometry,
  style, selection-rectangle, configuration, and autofill calls.
- Connected show/hide to `Window::set_ime_allowed`, geometry updates to
  `Window::set_ime_cursor_area`, and winit preedit/commit events to a
  UTF-16-aware editing model. Framework updates use the standard
  `TextInputClient.updateEditingState` method call.
- Kept raw key-data delivery separate from committed text, preventing the host
  from inserting the same character through both keyboard and IME paths.
- Added the legacy Linux `flutter/keyevent` compatibility message after every
  modern key-data packet so Flutter dispatches queued `HardwareKeyboard`
  events. Interactive checks confirmed ordinary editing, Backspace, and
  Ctrl+A selection.
- Validated non-Latin preedit and commit through Fcitx 5's Wayland frontend and
  Mozc. `nihongo` produced the composing string `にほんご`; Backspace changed it
  to `にほん`; conversion and commit produced `日本語`; and left-arrow followed
  by Backspace edited the committed value to `日語` without corrupting the
  UTF-16 selection state.

### Phase 1 — compositor-driven vsync

- Bumped the lockstep private shell ABI to v4 and added a typed vsync request
  callback. Rust returns only the frame interval; C++ records frame start in
  the FML monotonic clock domain, so unrelated clock epochs never cross FFI.
- Routed Wayland requests through `Window::request_redraw`. Requests are
  coalesced until winit observes them, while `Window::pre_present_notify` is
  issued at the broker's actual presentation boundary immediately before
  `SurfaceTexture` presentation.
- Fixed a frame-liveness bug in the first implementation: registering the
  Wayland frame callback at every vsync pulse could arm one for Flutter's
  secondary, non-rendering vsync requests. With no following surface commit,
  winit correctly throttled every later redraw, making resize and input appear
  frozen even though their events reached the engine.
- Kept Flutter's timer waiter when the active winit backend is not Wayland or
  cannot provide compositor-aligned redraws.
- Active Vulkan validation exposed two previously hidden hazards. Borrowed
  swapchain images now return to wgpu in `PRESENT_SRC_KHR`, Impeller's incoming
  render-pass dependency includes early depth/stencil writes, and resize
  configurations are coalesced and applied only at a safe acquire boundary.
- Frame-liveness validation then exposed a resize-generation race: a newer
  deferred swapchain size could be paired with depth/stencil attachments from
  an older Flutter layer tree. The acquire callback now treats Flutter's
  requested dimensions as the current frame generation, configures exactly
  that size, and preserves a newer winit resize for the following frame.
- Pinned the complete wgpu workspace to upstream revision
  `014d9e84813a2946febfa4888694c0b70565b2f5` until the fix after 30.0.0 is
  released. That revision stops Linux from passing wgpu's Windows-only reusable
  fence to `vkAcquireNextImageKHR`; pinning the whole workspace keeps its
  internal Rust types coherent.

### Phase 1 — single-engine multi-view seam

- Defined multi-window as Flutter multi-view: view `0` is the implicit main
  window and every additional native window is a positive view ID inside the
  same `Shell`, engine, root isolate, plugin registry, and task runner.
- Bumped the private ABI to v5 and added layout-compatible Rust/C types for
  view IDs, physical metrics, focus state/direction, and asynchronous
  add/remove completion callbacks.
- Routed viewport metrics and pointer packets by view ID and forwarded native
  focus changes through Flutter's `ViewFocusEvent` API.
- Added engine-private `PlatformView::AddView` and `RemoveView` entry points;
  duplicate or invalid presentation registration fails before a Flutter view
  can be left without a render target, and failed Flutter additions roll their
  presentation registration back.
- Added a default-no-op active-view hook to `Surface`, forwarded it through
  `GPUSurfaceVulkanImpeller`, and made `RustVulkanPresentation` select separate
  callback and semaphore state for each view. This preserves all existing
  single-view surfaces while allowing one rasterizer to acquire and present
  the swapchain belonging to the layer tree's view ID.
- Replaced the single winit window with bidirectional view/window maps. Every
  positive view owns a stable `GpuBroker`, native window, pointer state, and
  keyboard state; all brokers share one application-wide wgpu instance,
  adapter, device, and queue.
- Added a typed Dart FFI regular-window contract for creation, destruction,
  state queries, sizing, constraints, titles, activation, maximize/minimize,
  and fullscreen. The standalone runner explicitly exports only that window
  surface plus the VM snapshot symbols needed by `DynamicLibrary.process()`.
- Added `WindowingOwnerRust` and `WindowControllerRust`. The ordinary
  `WindowController` factory selects them only when the Rust-shell symbol is
  present, preserving the GTK Linux owner in existing Linux embedders.
- Routed state, close-requested, and destroyed events through one typed
  `NativeCallable.listener` per engine. Close requests honor the framework
  delegate and retain the native window and presentation surface until
  Flutter's asynchronous `RemoveView` completion succeeds.
- Removed registry borrows from every call into C++ and from native window
  destruction. This permits Dart delegate callbacks, engine view removal, and
  synchronous winit destruction events to re-enter the host without RefCell
  panics.
- Extended the typed platform-message boundary to handle
  `System.exitApplication` and `SystemNavigator.pop`. Required exits are queued
  through winit before the event loop terminates; cancelable exits remain
  conservatively canceled until the shell implements the framework's
  `System.requestAppExit` response round trip.
- Added a typed dialog request alongside the regular-window request. The Dart
  controller accepts only Rust-owned parents, while the host independently
  verifies that the parent is a live view in the same engine.
- Applied native transient relationships with `xdg_toplevel.set_parent` on
  Wayland and `XSetTransientForHint` plus the dialog window type on X11. The
  host retains the parent's native window handle for the child's lifetime and
  removes descendants before their parent, so asynchronous Flutter view
  teardown cannot leave a dangling compositor relationship.
- Migrated the host from winit 0.30 to exact `0.31.0-beta.2`, including the
  beta's object-safe windows, surface lifecycle callback, unified pointer
  events, and untyped wake proxy. Kept a narrowly vendored copy of only
  `winit-wayland` so the Rust shell can add the missing role-aware constructor
  without forking the rest of winit.
- Bumped the private ABI to v6 and added a validated popup request carrying
  kind, parent view, layout constraints, anchor rectangle, parent/child
  anchors, offset, and the six xdg constraint-adjustment flags. Dart enum
  values are checked before becoming Rust enums, and parents must be live
  views in the same engine.
- Implemented real Wayland `xdg_positioner`/`xdg_popup` roles for tooltip and
  popup controllers. Render and input use the popup's actual `wl_surface`;
  interactive popups use the pointer's latest nonzero button serial for
  `xdg_popup.grab`, and compositor `popup_done` requests normal controller
  destruction.
- Carried loose min/max viewport constraints into Flutter instead of making
  child views permanently tight at their bootstrap surface size. This lets
  tooltip and popup widget trees choose their content dimensions, which flow
  through the existing layer-tree-sized Vulkan acquire path.
- Replaced the test-only create/destroy callback implementations with a
  `WindowingCallbackHost` seam. The production extern callbacks and Cargo tests
  now share the same request decoding and dispatch functions; injected-host
  tests use named creation records instead of positional tuple vectors.
- Bumped the private ABI to v7 and added a typed satellite request plus native
  reparent operation. Satellite controllers accept only regular or dialog
  parents, use utility/transient native relationships, participate in the
  existing descendant teardown ordering, and retain absolute position across
  reparenting where the platform exposes it.
- Added shrink-wrap constraints for regular-style views, initial satellite
  positioning on X11, and automatic satellite hiding while its parent is
  maximized or fullscreen. Standard Wayland deliberately leaves persistent
  toplevel placement to the compositor; unlike tooltip/popup surfaces, a
  movable, resizable, keyboard-focusable satellite cannot use an `xdg_popup`
  role.
- Implemented the cancelable desktop shutdown handshake without another ABI
  version increment. The host recognizes `System.initializationComplete`,
  retains asynchronous framework-to-host responses with an opaque one-shot
  handle, invokes `System.requestAppExit`, and completes the original
  `System.exitApplication` call with the framework's `cancel` or `exit`
  response. Native close requests use the same coordinator, duplicate requests
  are coalesced, and required exits still terminate immediately.
- Added an injectable regular-window binding seam to the Rust framework owner
  and automated its production lifecycle dispatcher. Framework tests now cover
  typed creation parameters, synchronous native state, every regular-window
  mutation, delegated close cancellation and acceptance, duplicate close
  coalescing, and the asynchronous transition from a requested removal to a
  host-confirmed destroyed window.

### Phase 1 — main-thread dispatch

- Added `MainThreadDispatcher` to the semantically versioned plugin SDK and
  exposed it through `PluginRegistrar`. Clones are `Send`/`Sync`, retain no
  private engine objects, and accept ordinary `FnOnce + Send + 'static` work
  from Rust workers or background-isolate FFI entry points.
- Routed dispatcher work through a typed winit host event. Dispatch is always
  asynchronous, even from the main thread, so plugin callbacks cannot
  unexpectedly re-enter Dart or mutably borrowed platform state in the middle
  of a synchronous FFI call.
- Bounded host-event draining to 64 callbacks per event-loop turn and re-wake
  winit when work remains. This preserves FIFO order while allowing window
  input, Flutter tasks, and lifecycle events to make progress during a worker
  callback flood.
- Retained the dispatcher and registrar for the shell lifetime and disable all
  dispatcher clones before native window and engine teardown begins.
- Replaced the dispatcher's Boolean acceptance flag with explicit starting,
  running, and shutdown states. Calls made before the implicit view exists fail
  with `NotReady`; startup is one-shot; shutdown is terminal; and every queued
  callback rechecks the shared state before touching plugin or shell data.
- Added `task test-rust-shell-lifecycle`, which launches the real GN runner,
  identifies its mapped Wayland window by PID, requests compositor close,
  records the actual process status through a wrapper, and repeats the complete
  ownership cycle 20 times. Failure cleanup is bounded and force-stops only the
  exact runner PID.
- Added an application-level FRB 2.12 fixture outside the shell crates. Its
  Cargo binary links `libflutter_rust_engine.so`, registers through
  `run_application`, and exports generated FRB symbols from the process. Dart
  makes a synchronous call on the root isolate and a normal call from a named
  background isolate; the Rust worker posts through `MainThreadDispatcher` and
  reports whether its callback ran on winit's owning thread.
- Added a synchronous-reentrancy probe that marks the FFI frame active, queues
  main-thread work, and proves the callback observes the frame already
  unwound. The worker probe also blocks only its FRB worker—not the winit
  thread—while awaiting main-thread completion.
- Extended the same application fixture with one engine-owned wgpu texture and
  one CPU-written pixel-buffer texture. Both IDs cross FRB from the root and
  background isolates and are displayed side by side as real Dart `Texture`
  widgets. Dart starts the Rust producer after its first frame so publication
  cannot fill the three-slot rings before their `TextureLayer`s exist.

### Phase 2 — Rust external texture seam

- Bumped the lockstep private ABI to v8 and added a Vulkan external-texture
  frame descriptor containing borrowed image and image-view handles, dimensions,
  format, and an acquire/render binary-semaphore pair.
- Added engine-generated texture registration, frame notification, and
  idempotent unregister calls. They route through `PlatformView` and Flutter's
  existing `TextureRegistry`, so notifications schedule frames without a Dart
  widget rebuild or a parallel compositor protocol.
- Added `RustExternalTexture`. On the raster thread it waits for the producer,
  wraps the borrowed image/view in an Impeller `TextureVK`, preserves the last
  good frame across failed acquisition and frozen paints, then signals and
  releases replaced frames. Rust remains owner of all Vulkan objects.
- Added focused native tests for notified/frozen rotation, failed-acquire retry,
  context loss, repeated unregister, and post-unregister suppression.
- Added an engine-owned triple-buffered wgpu texture ring. Each slot retains
  its wgpu texture/view and binary semaphore pair, explicitly transitions from
  color-target to shader-resource state, and is not reused until Flutter has
  returned it through the ABI release callback.
- Added an opt-in `FLUTTER_RUST_TEXTURE_DEMO` producer to validate the private
  path before making it public SDK surface. Rendering is deferred to Flutter's
  acquire callback so wgpu and Impeller submissions to their shared `VkQueue`
  remain externally serialized.
- Fixed a Vulkan submit-info lifetime bug found by validation: the wait
  semaphore/stage arrays must remain alive through `vkQueueSubmit`. Also retain
  the texture ring through C++ shell destruction so asynchronous unregister on
  the raster runner completes before its semaphores are destroyed.
- Added the semver-facing `WgpuTexture` SDK contract and hidden runtime backend
  traits. Plugins record commands against an engine-owned target and call
  `present`; only the shell may submit the command buffer or notify Flutter.
  The SDK deliberately does not expose `wgpu::Queue`, preventing plugins from
  racing Impeller on the shared Vulkan queue.
- Refined the contract around explicit frame reservations. Producers may use
  `try_next_frame()` for immediate backpressure or `next_frame().await` without
  blocking a thread. A reserved `WgpuTextureFrame` records at most once and is
  consumed by `present(self)`; presenting before render and recording twice are
  rejected before reaching the runtime backend.
- Implemented those reservation traits on the real `WgpuTextureRing`. Its
  three available slot IDs live in a bounded Tokio `mpsc` channel; releases
  wake asynchronous waiters, nonblocking reservation reports `Busy`, and
  dropping an unpublished frame returns its slot. `async-trait` supplies the
  object-safe hidden async backend method, so the public SDK contains no manual
  polling implementation. `present` queues the recorded closure, dispatches
  Flutter's dirty notification through the main thread, and leaves actual wgpu
  submission in the raster acquire callback to preserve shared-queue ordering.
- Added the Linux `WgpuTextureBackend` factory and install it in the registrar
  once the engine and implicit view exist. Each public handle delegates to a
  stable callback-owning ring; drop shuts down producers and schedules
  idempotent unregister on the main thread. ABI v9 posts a completion behind
  raster registry removal, allowing the host retention list to release each
  callback owner promptly and safely. The animated demo is now a
  source-linked `FlutterRustPlugin` that creates, records, and presents frames
  entirely through the public SDK.
- Added `PixelBufferTexture` as the CPU producer path. Each ring slot owns a
  reusable, fallibly allocated RGBA8 buffer only when the pixel-buffer
  constructor is selected. `write_pixels` invokes the plugin directly against
  that storage with a validated tight row stride; `present` queues it and the
  raster acquire callback performs the single necessary CPU-to-GPU upload on
  the shared wgpu queue. Dropped reservations recycle normally, and no
  plugin-owned `Vec` is copied into a second shell allocation.
- Kept `WgpuTexture` unconditional in the public plugin SDK. Instead of hiding
  core API behind a Cargo feature, removed `flutter-shell-core`'s SDK dependency
  and let the lockstep ABI core own its expected numeric SDK version. The
  existing C++/Rust ABI assertion checks that value while the ABI archive stays
  independent of the full wgpu graph.
- Added deterministic lifecycle coverage for bounded-slot backpressure, slot
  reuse, and shutdown while an asynchronous producer is waiting. Shutdown
  closes the only channel sender, wakes the waiter with `PluginError::Shutdown`,
  prevents new reservations/presents, and leaves already acquired Flutter
  frames alive until their normal release callback.

### Phase 3 — Flutter-tool distribution, CLI device, and release mode

- Added `refreshRustPlugins`/`rust_plugins.dart`: for `flutter.shell: rust`
  projects, discovers source-linked Rust plugins from the resolved Pub graph,
  symlinks each into `.dart_tool/flutter_rs/plugins/`, rewrites the marked
  dependency block in `runner-rs/Cargo.toml`, regenerates
  `runner-rs/src/flutter_plugins.rs` calling each plugin's declared registrar,
  and validates via `cargo metadata` that exactly one `flutter-plugin-sdk`
  resolves across the whole workspace.
- Added `_ensureRustShellSdk`: materializes `.dart_tool/flutter_rs/sdk/` either
  by symlinking a local engine checkout's crates/engine libraries (fast path
  for engine development) or by downloading and unpacking the BETA SDK
  tarball, and `runner-rs/build.rs.tmpl` links the engine library out of that
  directory rather than requiring a hand-authored path.
- Added `.github/workflows/flutter-rust-beta.yml`: on every push, imports the
  latest upstream Flutter version tag, builds the Rust shell against the
  engine, packages the Cargo workspace and prebuilt engine artifacts into a
  tarball alongside the built `flutter_tools.snapshot`, and republishes them to
  a rolling `BETA` GitHub release so an FVM-installed fork can consume prebuilt
  artifacts without a local engine checkout.
- Added `RustShellDevice`/`RustShellDevices` (`rust_device.dart`): registers
  `rust` as a built-in `DesktopDevice` for `flutter.shell: rust` projects,
  building the generated Cargo runner and launching it with Flutter's normal
  desktop VM-service environment, hot reload, and shutdown lifecycle in debug
  mode.
- Extended the private engine ABI with an optional `aot_library_path` in
  `FlutterRustShellSettings`/`FlutterRustShellRun`: when the linked engine was
  itself built to run precompiled code (`DartVM::IsRunningPrecompiledCode()`,
  decided at GN `--runtime-mode` build time, not by the Dart app or
  `runner-rs`'s own Cargo profile), `rust_shell.cc` wires that path into
  `Settings.application_library_paths` instead of the JIT
  `kernel_blob.bin` asset. Threaded the same optional path through
  `flutter-shell-core`, `flutter-shell-winit`, `main.cc`, and `rust_runner.h`.
- Made `RustShellDevice` support `BuildMode.release`: `buildForDevice` runs a
  small custom `Target` (`AotElfRelease` plus a copy step) to AOT-compile the
  Dart app to `app.so`, since the tool's generic bundle-builder target does not
  do AOT compilation on its own, and builds `runner-rs` with
  `cargo build --release`. `executablePathForDevice` and
  `launchArgumentsForDevice` select `target/release` and pass the compiled
  `app.so` path to the runner. Fixed a latent bug found while doing this: the
  device previously never passed `icu_data_path` at all and instead forwarded
  `debuggingOptions.dartEntrypointArgs` (which the private ABI has no field
  for and which broke `main.cc`'s positional `argc` check whenever any
  dart-entrypoint args were present); launch arguments are now always
  `<assets_path> <icu_data_path> [app.so]`.
- Made `runner-rs/build.rs.tmpl` link `sdk/lib/<profile>/libflutter_rust_engine.so`,
  keyed off Cargo's own `PROFILE` env var, and extended `_ensureRustShellSdk`
  to maintain separate `sdk/lib/debug/` and `sdk/lib/release/` engine
  directories from either a local engine checkout (`out/host_debug` and
  `out/host_release`) or the downloaded BETA tarball.
- Extended `flutter-rust-beta.yml` to configure and build the engine a second
  time with `--runtime-mode release` into `out/host_release`, and to package
  both engine variants into the BETA tarball under `lib/debug/` and
  `lib/release/`.
- Split `flutter-rust-beta.yml` into three jobs so the debug and release engine
  builds run concurrently instead of sequentially in one job: `build-tool`
  resolves/validates the Flutter version tag and builds `flutter_tools.snapshot`;
  `build-engine` is a `[debug, release]` matrix, each leg doing its own
  checkout/`gclient sync`/`gn`/`ninja` and uploading its engine artifacts;
  `publish` downloads both plus the tool snapshot, packages the tarball, and
  publishes the rolling BETA release as before.
- Fixed two bugs found while actually running a generated application in
  release mode end to end (not just compiling it):
  - The real generated-app entry point is `runner-rs/src/main.rs.tmpl`, which
    is entirely separate from `cpp/main.cc`/`flutter_rust_shell_runner` (the
    phase-0 GN test executable). It hardcodes its own ICU path at compile time
    and never referenced an AOT library path at all, so passing those as
    process arguments from `rust_device.dart` was dead code that the real
    runner never read. Fixed by having `main.rs.tmpl` self-derive both paths:
    `cfg!(debug_assertions)` (true for Cargo's `dev` profile, false for
    `release`) selects `sdk/lib/<debug|release>/icudtl.dat` and, in release,
    the AOT library at `<assets-path>/app.so`. Simplified
    `RustShellDevice.launchArgumentsForDevice` back down to just the assets
    directory, matching what the runner actually reads from `argv`.
  - `_RustAotBundle`'s dependencies were only `AotElfRelease` (compiles
    `app.so`), skipping the normal release asset-copy target
    (`ReleaseCopyFlutterBundle`/`InstallCodeAssets`) that does icon-font
    tree-shaking in sync with the compiled kernel. This left `build/flutter_assets`
    with whatever a prior build (e.g. debug) had left behind, so an icon like
    the counter FAB's `Icons.add` rendered as a mismatched glyph (`å`) instead
    of a plus sign under a real run. Fixed by adding
    `const ReleaseCopyFlutterBundle()` alongside `AotElfRelease` in
    `_RustAotBundle.dependencies`, so both share the same `KernelSnapshot` and
    assets stay consistent with the AOT-compiled code.

### Milestone 3 — Android AOT/release mode

- Fixed `build_rust.py`: it derived `profile_dir` from
  `FLUTTER_RUNTIME_MODE` to decide where to look for the built artifact, but
  never actually passed `--release` to the `cargo build` invocation itself —
  so cargo always produced a debug binary regardless of the requested mode,
  and the script would then fail to find it under `target/release`. This
  affected every platform's Cargo GN action (`flutter_shell_core_rust`,
  `flutter_shell_winit_rust`, `flutter_shell_android_runner_rust`, ...), not
  only Android.
- Replaced the Android runner's hardcoded `aot_library_path: String::new()`
  with a `cfg!(debug_assertions)` derivation mirroring
  `runner-rs/src/main.rs.tmpl`: JIT (empty path) in debug, `{files_dir}/app.so`
  in release, keeping the existing adb-pushed `flutter_assets/`/`icudtl.dat`
  placeholder convention.
- Added a `release` Gradle build type to `android_shell_app/app/build.gradle`
  (debug-signed, since this milestone-scaffold app has no release keystore)
  and disabled `lintVital`, which otherwise blocks `assembleRelease` under
  this environment's JDK independent of anything in this source tree. Left
  `debuggable true` on the release build type deliberately: it only controls
  the manifest attribute that gates `adb run-as` access to the app's private
  files directory (needed to push the placeholder assets/AOT library into a
  non-rooted device), not the Rust cdylib itself, which is always a genuine
  `cargo build --release` artifact regardless of this flag.
- Gated the Android runner crate's body with `#![cfg(target_os = "android")]`
  to match its already-`cfg(target_os = "android")`-gated dependencies in
  `Cargo.toml`. Without it, `cargo test --workspace` on a host Linux checkout
  failed to compile the crate (unresolved `android_logger`/`log`/
  `flutter-shell-winit` imports) — a pre-existing gap since the crate was
  first added, not something introduced by this milestone's other changes,
  but it blocked running the workspace test suite as a regression check.
- Configured `out/android_release_arm64` (`--android --android-cpu arm64
  --runtime-mode release`) and built `flutter_shell_android_runner_rust`,
  `flutter_rust_engine`, and the host-side `clang_x64/gen_snapshot` cross
  tool, plus `dart_sdk`/`frontend_server_aot` in `out/host_release` (needed
  to produce a real AOT snapshot; they were not already built there).

### Validation — Milestone 3

- Ran `cargo +1.93.1 test --workspace --locked` after the `build_rust.py` and
  `cfg` fixes: all crate and documentation tests pass (3 + 28 unit tests
  across `flutter-shell-core`/`flutter-shell-winit`, 0 doc tests, no
  regressions).
- Rebuilt `flutter_shell_android_runner_rust` for `out/android_release_arm64`
  and confirmed cargo actually invokes `--release` now (`Finished \`release\`
  profile [optimized] target(s)` in the build log, where it previously always
  built debug).
- Produced a real release AOT snapshot (`app.so`) and tree-shaken
  `flutter_assets/` for an existing multi-window sample app by invoking
  `gen_snapshot --deterministic --snapshot_kind=app-aot-elf` directly against
  the kernel dill `flutter build bundle --release --target-platform
  android-arm64` produced, using the locally built `out/android_release_arm64`
  engine and `out/host_release`'s frontend server via `--local-engine`.
- Built a release-signed APK (`android_shell_app`'s Gradle project, JDK from
  Android Studio's bundled JBR since the system default was too new for this
  Gradle/AGP version) with both `libflutter_shell_android_runner.so` and
  `libflutter_rust_engine.so` staged into `jniLibs/arm64-v8a/`, installed it
  on a physical Android device over adb, and adb-pushed `flutter_assets/`,
  `app.so`, and `icudtl.dat` into its private files directory — deliberately
  without a `kernel_blob.bin`, so a successful boot could only mean the AOT
  path engaged, not a silent JIT fallback.
- Launched the app: it rendered real interactive UI (a modal dialog, live
  text field, and soft keyboard from the sample's windowing/IME test screen),
  stayed alive and responsive, and produced no `FATAL`/panic in `logcat` for
  the whole session. A screenshot confirmed the rendered content matched the
  sample app, not a blank or crashed surface.

## Validation

- Created a fresh generated Rust-shell application and ran it through `flutter
  run -d rust`. The tool discovered the built-in device, generated the initial
  Cargo lockfile, built and launched the runner, attached to its VM service,
  completed hot reload and hot restart, and terminated the native process with
  the standard `q` command.
- `git diff --check` passes.
- Added focused Flutter-tool coverage for `flutter.shell: rust`, strict generated
  Cargo section replacement, and `flutter create --shell=rust`. A real generated
  application with a source-linked Pub/Cargo plugin resolved one shared SDK and
  completed `cargo +1.93.1 build`; the template-manifest check also passes.
- After adding the application registration entry point, ran
  `cargo +1.93.1 test --workspace --locked`: all 34 Rust unit tests and all
  documentation tests pass. Rebuilt the GN runner, shared engine, and native
  test binary; all 17 C++ tests pass. The real Wayland wgpu texture fixture
  also passed through the new registration path with changing frames and a
  clean shutdown.
- Ran `task test-rust-shell-frb-dispatch`. It built the generated Dart and Rust
  FRB 2.12 bindings, linked the Cargo-owned fixture runner to the host-debug
  engine, called Rust from both root and named background isolates, verified
  the FRB worker was not the winit thread, verified both queued callbacks ran
  on the winit thread after synchronous FFI unwound, verified both texture IDs
  from both isolates, waited for both frame counters, compared changing
  compositor captures from each half of the window under Vulkan validation,
  then closed through the compositor and exited with status zero.
- C++ sources were formatted with `clang-format`.
- Built `//flutter/shell/platform/rust:flutter_rust_shell`,
  `//flutter/shell/platform/rust:flutter_rust_shell_unittests`,
  `//flutter/shell/platform/rust:flutter_shell_winit_rust`, and
  `//flutter/shell/platform/rust:flutter_rust_shell_runner` with the
  host-debug GN configuration (`et build`-managed `out/host_debug`).
- Ran `flutter_rust_shell_unittests`: 17 tests passed.
- Rebuilt `flutter_rust_shell_runner`, `flutter_rust_shell_unittests`, and
  `libflutter_rust_engine.so` after installing the public SDK texture factory;
  the final Rust/C++ static link succeeds using the repository's bundled
  depot_tools environment.
- Added and ran `task test-rust-shell-texture`. It builds the permanent
  `examples/texture/lib/rust_shell_main.dart` entry point, launches the real
  Rust runner and source-linked plugin under Vulkan validation when available,
  verifies engine texture ID `1`, waits for continued presentation, compares
  two compositor captures after ten additional frames, scans synchronization
  diagnostics, and closes cleanly. The recorded run passed with 32 presented
  frames and visibly changing texture pixels.
- Added and ran `task test-rust-shell-pixel-buffer-texture`, using the same
  real Dart `Texture` widget, compositor capture comparison, Vulkan diagnostic
  scan, and clean-shutdown checks. The CPU direct-write path passed with 30
  presented frames.
- Ran `cargo +1.93.1 test --workspace --locked`: all crate and documentation
  tests pass, including typed text-input decoding, invalid UTF-16 range
  rejection, Unicode selection replacement, hidden-cursor composition, and
  framework update serialization. The winit crate now has 24 passing tests,
  including monitor-refresh-to-frame-interval conversion, target-view
  preservation for pointer events, and application-exit decoding.
- Ran the focused Vulkan surface test proving that the raster surface forwards
  the selected Flutter view ID to its presentation delegate.
- Compiled the changed Rust Vulkan presentation C++ translation unit and its
  ABI consumers with the host-debug compile commands, then completed a full
  `flutter_rust_shell_runner` host-debug build using the engine's bundled
  depot_tools and the locally managed Python bypass.
- Added `task build-rust-shell` and `task stress-rust-shell`. With the opt-in
  `FLUTTER_RUST_PRESENTATION_STATS` stream, the stress task now proves an
  initial presentation, a new presentation after a compositor-delivered Tab
  key, and a newly sized presentation after 500 Hyprland resizes with periodic
  hide/restore and fullscreen transitions. It then closes immediately to
  overlap teardown with queued work and rejects known Vulkan, wgpu, and
  Impeller synchronization diagnostics. This liveness assertion caught both
  the compositor frame-callback deadlock and the layer-tree/swapchain resize
  race that process-only stress had missed. After installing
  `vulkan-validation-layers` 1.4.350.1-1, the current 500-resize run passed
  with `VK_LAYER_KHRONOS_validation` explicitly enabled and no Vulkan, wgpu,
  or Impeller synchronization diagnostics, including no acquire-fence reuse
  VUIDs. Three consecutive synchronization-and-liveness runs passed.
- Rebuilt both the standalone runner and `libflutter_rust_engine.so`, then
  rebuilt and launched the sample's `runner-rs` target against the then-current
  ABI v4 (multi-view work subsequently advances the lockstep ABI to v5).
  Ordinary typing, Backspace, and Ctrl+A selection work in the visible text
  field.
- Repeated the interactive check with compositor vsync enabled after moving
  `pre_present_notify` to the actual wgpu presentation boundary. Input-driven
  frames and window-size changes remain live; temporarily selecting
  `VsyncWaiterFallback` was used only to isolate the original freeze.
- Ran `task run-flutter` through the app's `runner-rs` Cargo target against a
  real JIT kernel snapshot: the process stays alive, the Rust-shell window is
  mapped and visible, and a live capture shows rendered Flutter content. No
  public Embedder API is involved; the existing GTK Linux shell target remains
  untouched. The synchronization broker and validation-layer stress run above
  supersede the GPU handoff errors observed before explicit semaphores were
  added.
- Built and ran the repository's unmodified `examples/multiple_windows` app
  with windowing enabled. Its initial regular window rendered through the Rust
  shell as Flutter view `1`, including the reference app's controls and window
  registry UI.
- Built a temporary two-controller smoke entry point from the same example.
  Two mapped native windows (views `1` and `2`) rendered simultaneously in one
  process; closing view `1` left view `2` alive, and closing view `2` completed
  both asynchronous removals without a panic. The temporary source was removed
  after validation.
- Closed the unmodified reference app's delegated main window and verified
  that its subsequent required `System.exitApplication` request terminates the
  Rust-shell process without an external signal.
- Built a temporary dialog smoke target with one regular parent, one modal
  dialog, and one modeless dialog. All three rendered concurrently as views in
  one engine. Hyprland treated the Wayland transient as a native floating
  dialog; closing the parent removed the modal child while the modeless dialog
  remained alive. The temporary source was removed after validation.
- Rebuilt and ran the unmodified `examples/multiple_windows` app after the
  winit migration and ABI v6 change. The regular view remained live, and its
  Show Popup control created a compositor-positioned, independently rendered
  child surface whose content size exceeded the one-pixel bootstrap size.
- Re-ran `task stress-rust-shell` after the winit 0.31 migration: keyboard
  frame liveness, 500 compositor resizes, hide/restore, fullscreen changes,
  immediate teardown, and Vulkan validation all passed.
- Built a temporary cancelable-exit smoke target whose first
  `didRequestAppExit` response was `cancel` and whose second was `exit`. The
  first `ServicesBinding.exitApplication(cancelable)` future completed with
  `cancel`; the second terminated the Rust-shell process cleanly with status
  zero. The temporary source was removed after validation.
- Re-ran `task stress-rust-shell` with the native-close path routed through
  `System.requestAppExit`; its default `exit` response still completed the
  500-resize validation run and in-flight teardown cleanly.
- Ran the focused Rust-window framework tests together with the existing
  windowing suite: 98 tests passed. Static analysis of the Rust framework
  backend and its new test reports no issues.
- Ran an interactive Japanese IME check against the real Rust-shell window
  using Fcitx 5/Mozc over Wayland. Preedit, candidate conversion, Backspace
  during composition, commit, cursor movement, and editing after commit all
  remained live and produced the expected character counts and candidates.
  The sample's bundled font rendered Japanese as missing-glyph boxes, so the
  Fcitx candidate UI and controlled edit transitions were used to verify the
  values independently of glyph rendering.
- Ran `cargo +1.93.1 test --workspace --locked`: all 29 crate and documentation
  tests pass. New tests post from a real worker thread, assert execution on the
  recorded main thread, prove nested dispatch is deferred to a later queue
  turn, reject dispatch after shutdown, and cap a 65-callback flood at 64
  callbacks in its first event-loop turn. One hundred repeated lifecycle-unit
  cycles also verify bootstrap rejection, one-shot activation, terminal
  shutdown, and suppression of a callback queued before teardown.
- Rebuilt `flutter_rust_shell_runner` and `libflutter_rust_engine.so` through
  the host-debug GN build after wiring the SDK dependency into the real winit
  host; the final native link passes. A live post-build launch mapped the
  Rust-shell window normally, and immediate process teardown completed without
  a dispatcher or registrar diagnostic.
- Ran `task test-rust-shell-lifecycle`: 20 consecutive real runner processes
  mapped their Wayland windows, handled compositor close through the framework
  exit path, and terminated with status zero. No iteration hung or required
  failure cleanup.
- Rebuilt `flutter_rust_shell_runner`, `libflutter_rust_engine.so`, and the
  native test binary against ABI v8. All 17 native tests and all 29 Rust tests
  pass; strict rustdoc, Cargo formatting, and `git diff --check` pass.
- Built a temporary Dart bundle containing `Texture(textureId: 1)`, then
  restored the test application's source. With `FLUTTER_RUST_TEXTURE_DEMO=1`,
  the real Wayland runner displayed the 256×256 wgpu texture; successive screen
  captures differed as the producer changed color. The final validation run
  emitted no Vulkan or queue-threading diagnostics, and compositor-driven
  unregister/shutdown exited cleanly. No CPU readback was used.
- Added SDK fake-backend coverage; the workspace now has 30 passing Rust tests.
  `flutter-shell-core` now has an empty dependency tree and remains free of
  both the SDK implementation and wgpu.
- Built the runner and shared engine against ABI v9 after adding raster-thread
  unregister completion. The focused wgpu/winit suites pass: 3 wgpu tests and
  24 host tests, including the new blocked-waiter shutdown case.
- Re-ran the real Wayland hardware-texture fixture against ABI v9 under Vulkan
  validation. It produced 30 presentations with changing captures, then
  completed raster unregister, reclaimed the ring, and exited without a Vulkan
  diagnostic.
- Added `task test-rust-shell-texture-lifecycle`. A private fixture handshake
  prevents dirty notification from racing ahead of Dart's replacement
  `TextureLayer`: Dart reports readiness, Rust registers and announces the new
  ID, Dart acknowledges after `endOfFrame`, and only then does Rust publish.
  The real Wayland runner completes 40 live generations with varied dimensions,
  alternating wgpu and CPU pixel-buffer producers, while the harness resizes
  the window every five generations. Each generation is acquired and released
  by Flutter before its predecessor unregisters. The validation-layer run
  produced 468 presentations, reclaimed all retired rings, and exited cleanly.
- Advanced the private bridge to ABI v10 and added a raster-runner lifecycle
  hook that delivers `OnGrContextDestroyed` followed by `OnGrContextCreated` to
  the external-texture registry. The 40-generation real Wayland fixture invokes
  it once at generation 20, blocks new producers until its completion callback,
  then completes the remaining wgpu/pixel-buffer replacements. The validation
  run produced 472 presentations after the injection and exited without a
  Vulkan or teardown diagnostic.
- Removed the crate-wide Linux guard and the transitional `host` wrapper from
  `flutter-shell-winit`. Platform operations now cross a statically dispatched
  `PlatformBackend`, selected as `CurrentPlatform = LinuxPlatform`; the native
  implementation owns all direct Wayland/X11 imports. Legacy Linux/GTK key
  metadata and fallback key-plane policy moved behind the same boundary. The
  private task-runner FFI is similarly selected through `EngineBridge`, with
  its only test `cfg` declarations centralized in `engine.rs`. Shared host code
  contains no production `cfg(test)` branches, and windowing test helpers are
  generic rather than trait objects.
- Added `flutter-shell-winit::run_application` as the application-facing
  registration entry point. It accepts the generated Cargo application's
  registration function after the engine, implicit view, main-thread
  dispatcher, and GPU capability exist, invokes it exactly once, and reports
  `PluginError` through `RunError`. The opt-in texture fixture now supplies its
  `DemoTexturePlugin` through this path rather than registering directly from
  the host's surface-creation callback.
- Rebuilt `flutter_rust_shell_runner` and `libflutter_rust_engine.so` in both
  `out/host_debug` and a freshly configured `out/host_release`
  (`--runtime-mode release`) after the `aot_library_path`/ABI change; the full
  engine closure, including the changed `rust_shell.cc` and `main.cc`
  translation units, compiles and links successfully in both modes.
  `cargo check -p flutter-shell-core -p flutter-shell-winit` passes. `dart
  analyze` and `dart test test/general.shard/rust_device_test.dart` pass for
  the Flutter-tool changes.
- Ran a fresh generated application through `flutter run --release -d rust`
  end to end against the real `out/host_release` engine: the tool AOT-compiled
  the app, built `runner-rs` with `cargo build --release`, and the release
  runner launched, stayed live and interactive for the full test window
  (including responding to input), and exited cleanly with status zero — no
  ICU or AOT-loading crash. This surfaced and led to fixing the two
  `main.rs.tmpl`/`_RustAotBundle` bugs described above (paths the real runner
  never read, and a stale/un-tree-shaken assets directory that rendered the
  counter FAB's `Icons.add` as a mismatched glyph). After both fixes, a clean
  rebuild renders the plus icon correctly.

## Next implementation steps

1. Add profile mode, which needs the same AOT plumbing as release plus an
   `out/host_profile` engine build.
2. Begin Phase 3 with a Windows platform adapter and the existing Vulkan GPU
   path once the generated application workflow is usable without hand-written
   Cargo glue.
3. Generalize Android from a fixed milestone-scaffold app to generated
   applications: a flutter_tools `AndroidRustShellDevice` (matching
   `RustShellDevice`'s role for Linux), per-project `runner-rs` Android
   templates, real Gradle-driven `flutter run -d <android-device>`, and real
   `AAssetManager`-backed asset loading in place of the adb-push placeholder.

## Constraints carried into implementation

- The Rust shell is optional; existing Flutter shells remain buildable.
- Impeller remains Flutter's renderer permanently.
- The public Flutter Embedder API is not used.
- Multi-window means Flutter multi-view: one engine/root isolate per
  application, never one engine per native window.
- Plugin-facing GPU types come from the semantically versioned
  `flutter-plugin-sdk` crate.
- `flutter_rust_shell_runner`'s `main.cc` is a phase 0 expedient (GN owns the
  final link so it can pull in the Dart VM/Impeller/Skia archives); it is not
  the tooling model generated applications will use. See "Who owns the final
  link" in `flutter-rs.md`.
