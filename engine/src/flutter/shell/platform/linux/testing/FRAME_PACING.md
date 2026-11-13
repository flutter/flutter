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
