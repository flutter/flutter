# Real Wayland renderer tests

`flutter_linux_wayland_unittests` links the real GTK, EGL, and Wayland embedding.
It uses an unstarted engine and real renderer presentation, without starting Dart.
The executable is a dependency of the engine's `unittests` group when LTO is
disabled. Build with `--no-lto`: the test barriers require ELF linker wrapping
between separate production translation units.

For a native Linux arm64 debug build, run from `engine/src`:

```sh
flutter/tools/gn --target-os=linux --linux-cpu=arm64 --runtime-mode=debug --unoptimized --enable-unittests --no-lto --no-rbe --no-stripped --no-build-embedder-examples
ninja -C out/linux_debug_unopt_arm64 flutter_linux_wayland_unittests
```

Start a real compositor with an input seat before running. The unstarted engine
still initializes its keyboard manager, which requires a `wl_seat`; a plain
Weston headless backend does not provide one. For local CPU testing with Weston
13, set `XDG_RUNTIME_DIR` to a private directory with mode 0700, then start:

```sh
xvfb-run -a weston --backend=x11 --renderer=pixman --socket=renderer-test --idle-time=0
```

Once the socket is available, use the focused engine runner in another terminal
with the same `XDG_RUNTIME_DIR`:

```sh
dbus-run-session -- env WAYLAND_DISPLAY=renderer-test GSETTINGS_BACKEND=memory NO_AT_BRIDGE=1 LIBGL_ALWAYS_SOFTWARE=1 GALLIUM_DRIVER=llvmpipe GTEST_OUTPUT=xml:out/linux_debug_unopt_arm64/wayland-results.xml python3 flutter/testing/run_tests.py --variant=linux_debug_unopt_arm64 --type=engine --engine-filter=flutter_linux_wayland_unittests
```

Here Xvfb supplies input to the compositor; the test client still connects to
Weston using real Wayland, EGL, and subsurfaces. The focused selection runs
serially without starting another Xvfb. The runner sets `GDK_BACKEND=wayland`
only for this executable. The regular Linux unit tests
continue to use X11; the default suite and mixed selections still start Xvfb.
The runner also accepts other build variants through `--variant`.

Missing Wayland causes explicit GTest skips. Native fence cases skip if the
driver lacks `EGL_KHR_fence_sync`; fallback cases still exercise `glFinish`.
A skip is not evidence of realized Wayland or fence coverage. Successful setup
requires a nonzero-layer presentation using an actual parent surface, child EGL
context, and EGL window surface. The tests print GTK, GLib, and EGL versions;
GTest properties in `wayland-results.xml` identify the selected fence path.

These tests cover renderer disposal and unrealize during presentation, the
post-unlock runner/fence tail, queued redraw cleanup, and hide/show parent
replacement after an explicit GTK allocation request. Same-size hide/show
without subsequent allocation can leave this direct renderer without a child
surface on both the original and patched renderer; that separate scheduling
gap is not fixed here. These tests do not start a native engine or qualify
native engine shutdown.
Re-realizing the same renderer is excluded because its existing task-runner
reference overwrite is a separate lifetime issue.
