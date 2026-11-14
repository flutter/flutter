# Linux GTK frame pacing

GTK3 and GTK4 select a pacing policy once, when each engine starts. The policy
is independent of the Flutter renderer and GTK's GSK renderer.

| `FLUTTER_LINUX_FRAME_PACER` | Behavior |
| --- | --- |
| Unset or `gtk` | Use the implicit view's GTK frame clock, with timer recovery when the view is unmapped or its clock stalls. This preserves the pacing branch's existing default. |
| `engine` | Leave `FlutterProjectArgs.vsync_callback` unset. The engine's current fallback schedules on a fixed 60 Hz phase; it does not follow monitor refresh or physical presentation. |

For example, compare the same executable with:

```sh
FLUTTER_LINUX_FRAME_PACER=engine ./my_app
FLUTTER_LINUX_FRAME_PACER=gtk ./my_app
```

An explicit selection writes `Flutter Linux frame pacer: engine` or
`Flutter Linux frame pacer: gtk` to the application log. Invalid values,
including an empty string, fail engine startup rather than silently selecting a
benchmark policy. Changes to the environment after startup do not change the
running engine's policy. There is no live-switching or renderer-specific policy.

## Ownership and boundaries

`FlGtkFramePacer` owns GTK subscriptions, main-context dispatch, fallback timers,
and the list of outstanding requests. Its delivery callback and cleanup callback
keep engine API calls and engine lifetime management in `fl_engine.cc`. No
renderer, Vulkan device, texture, or GPU fence enters the pacing API.

Requests may arrive on an engine worker. Delivery occurs on the GTK platform
thread; a worker that owns the default main context still marshals delivery.
The default main context must be dispatched on the GTK platform thread.

Each request's callback data is released immediately after its baton is returned.
A retained tick keeps GTK's animation clock continuous for one idle tick without
retaining the callback recipient or its widget. It observes the widget weakly;
widget destruction removes the tick. Engine disposal stops the pacer before calling
`FlutterEngineShutdown`. Stop returns pending batons and removes dispatch sources,
timers, and retained ticks. The owner must stop issuing requests before stopping
the pacer; it cannot restart a stopped pacer. Stop supports reentrant calls from
request delivery or callback-data cleanup.

The extraction adds no worker thread or additional event-loop hop. The lifecycle
fix adds request tracking and reference-count protection for reentrant teardown.
Its performance cost has not been benchmarked; passing lifecycle tests is not
performance evidence.

## Remaining limitations

- One implicit view supplies the engine's clock. Visible secondary views do not
  currently replace an unmapped implicit view as the timing source.
- The GTK unmapped fallback waits 16 ms from a request; it is distinct from the
  engine fallback's phase-aligned 60 Hz scheduling.
- A mapped clock's progress guard waits four refresh intervals, with a 20 ms
  minimum. This is recovery from a stalled clock, not a presentation deadline.
- GTK history provides a predicted presentation time. Tick delivery and engine
  frame completion do not establish actual compositor presentation or scanout.

Record the selected policy, Flutter renderer, GSK renderer, viewport, display
refresh, and build identity with benchmarks. Compare actual presentation feedback,
application/compositor CPU and GPU activity, and memory. Keep reports and raw
results in the sibling plans repository under `gtk4/test-results/`.

## Tests

The standalone targets exercise real GTK clocks without constructing a Flutter
engine or renderer. GTK3's normal engine test executable replaces GTK functions,
so it cannot substitute for the real clock lifecycle tests.

```sh
ninja -C engine/src/out/host_debug_unopt \
  flutter_linux_gtk3_frame_pacer_tests flutter_linux_gtk4_frame_pacer_tests \
  flutter_linux_unittests flutter_linux_gtk4_unittests

xvfb-run -a env GDK_BACKEND=x11 \
  engine/src/out/host_debug_unopt/flutter_linux_gtk3_frame_pacer_tests
xvfb-run -a env GDK_BACKEND=x11 GTK_A11Y=none GSK_RENDERER=cairo \
  GDK_DISABLE=gl,vulkan \
  engine/src/out/host_debug_unopt/flutter_linux_gtk4_frame_pacer_tests
```

The GTK3 lifecycle target is registered in the standard native test runner.
GTK4 lifecycle tests remain an explicit target, like the GTK4 engine tests.
Run the engine targets with
`--gtest_filter=FlEnginePacerPolicyTest.*:FlEngineVsyncTest.*:FlEngineTest.*:FlVsyncTimingTest.*`
to cover policy selection, engine lifetime, callback delivery, and timing conversion.

Lifecycle coverage includes delivery cleanup, retained subscriptions on stalled
clocks, pending worker dispatch, timer fallback, unmapping, stalled-clock recovery,
reentrant stop, repeated stop, and final pacer release on both GTK versions.
The GTK4 engine suite also verifies engine finalization immediately after its
last pending baton is delivered.

## Presentation feedback for benchmarks

The collector and its call site are compiled only into debug and profile builds.
Release and JIT-release builds contain no collector, environment check, optional
symbol lookup, or history storage from this feature.

Set `FLUTTER_LINUX_FRAME_TIMINGS=1` before launch and capture a Flutter engine
trace (for example, with the engine's startup tracing options). With the `gtk`
pacer, `LinuxFrameTiming` instant events contain a JSON `sample` argument:
`clock`, `frame`, `result`, `complete`, `frame_time_us`, `predicted_us`,
`presentation_us`, and `refresh_interval_us`. Times are GDK monotonic
microseconds; the trace event timestamp is the observation time, not presentation.

The optional GTK 4.24 `gdk_frame_timings_get_result` symbol is resolved at runtime,
independently of build headers. GTK3 and older GTK4 report `result=-1` (unknown),
while still recording their available timing fields. The compatibility validator
rejects direct imports of this symbol. This binding lives with the timing code so
standalone pacer tests need no renderer or accessibility runtime bindings.

| Result | Meaning | Benchmark treatment |
| --- | --- | --- |
| -1 | Result API unavailable | Keep separate; completion does not prove display |
| 0 | Preparing | Pending |
| 1 | Skipped, no visual change | Exclude from rendered-frame drop rate |
| 2 | Empty, no visual change | Timestamp is hypothetical; exclude from presented intervals |
| 3 | Submitted, no further feedback | Outcome unknown |
| 4 | Outstanding compositor feedback | Pending |
| 5 | Discarded by display server | Known rendered frame not displayed |
| 6 | Presented | Actual presentation timestamp |

Deduplicate by `(process, clock, frame)`, keeping the last observation. History is
revisited on each pacer tick, including its final idle tick, and only changed
observations are emitted. Clock IDs are process-local and are not reused. For
confirmed outcomes, report `discarded / (presented + discarded)` alongside the
counts of unknown and pending frames. Compute presentation intervals only from
result 6 with nonzero timestamps, within the same clock. Do not treat skipped,
empty, or unavailable feedback as missed frames.

This is GTK surface feedback, not a one-to-one mapping to Flutter frames or proof
of direct scanout. Sampling adds no timer or extra requested frames. Consequently,
feedback arriving after the last tick, or falling out of GTK's bounded history,
can remain unresolved. Report this coverage limitation, exclude benchmark edges,
and do not compare engine-pacer runs using this collector (they have no GTK pacer
ticks). Keep CPU/GPU/memory measurements alongside feedback and measure tracing
cost before treating a performance difference as meaningful. Pacing behavior is
unchanged; these observations support a measured feedback loop for later changes.

## Application engine shutdown

Application shutdown synchronously stops the whole native engine on the GTK
thread, independent of GObject reference counts. This is an internal lifecycle
operation, not a new public Linux API. It is idempotent, cannot be
undone by starting the engine again, and emits `shutdown-complete` after
successful embedder shutdown. Destroying or removing one view does not invoke
this operation on an engine shared with other views.

At engine start, the default GApplication (if any) gets a normal `shutdown`
signal handler. GApplication emits that signal after its main loop has stopped;
the engine handler runs before the RUN_LAST class handler, including a runner's
shutdown override. It does not require further GTK main-loop dispatch.
Hosts without a default GApplication retain the existing disposal-driven
lifecycle; no new custom-host shutdown API is introduced here. Other normal
signal handlers that tear resources down must coordinate their ordering
explicitly.

Shutdown closes admission under the same lock used by worker vsync registration,
external texture notifications, and asynchronous platform message responses.
The lock is released before native Shutdown joins worker threads. It returns
accepted pending batons before embedder shutdown, cancels dispatch/tick/timer sources, and clears the native
handle before calling synchronous embedder Shutdown. Returning those batons may
schedule rendering; the embedder's shell/raster and thread-host teardown is the
completion barrier, not the end of the pacer stop operation. Newly arriving
requests are ignored after admission closes. Their opaque tokens are reclaimed
by the shared embedder waiter during destruction. Its token registry also
rejects duplicate/stale delivery and owns queued UI callbacks by value, so
cancelling a request or discarding a task does not leak a raw baton allocation.
This shared-embedder ownership change affects other embedders too and is tested
separately from Linux lifecycle integration.

Retained stopped engines reject texture operations, message responses, and new views, ignore queued
engine tasks/display updates, and allow view removal without calling a dead
native handle. Existing input/message methods already handle a null native
engine. Plugin-owned graphics resources still need their own orderly cleanup.

For shutdown reproduction, set `FLUTTER_LINUX_SHUTDOWN_DIAGNOSTICS=1` and keep
GTK pacing selected. The begin/complete messages include monotonic timestamps.
Completion must precede runner teardown/process exit; weak engine destruction
can happen later because messenger idles or plugins still own references.
This change does not destroy detached GTK4 toplevels or drain arbitrary plugin
idles. Validate removal of runner workarounds separately using the candidate
engine and matching Dart AOT artifacts.
