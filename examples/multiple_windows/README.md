# multiple_windows

A reference application demonstrating multi-window support for Flutter using a
rich semantics windowing API.

## Running

Enable experimental windowing once for this Flutter checkout:

```sh
../../bin/flutter config --enable-windowing
```

After building the local engine, run the default GTK3 runner from this
directory:

```sh
../../bin/flutter run -d linux \
  --local-engine=host_debug_unopt \
  --local-engine-host=host_debug_unopt \
  --local-engine-src-path=../../engine/src
```

To exercise the GTK4 runner with a locally built engine:

```sh
../../bin/flutter run -d linux \
  --linux-gtk=gtk4 \
  --local-engine=host_debug_unopt \
  --local-engine-host=host_debug_unopt \
  --local-engine-src-path=../../engine/src
```

Build the required local engine first from the repository root:

```sh
./engine/src/build.sh
```

The GTK4 path supports all four controller types. Regular and dialog
controllers use `GtkWindow`; tooltip and popup controllers use `GtkPopover`,
which GTK4 can anchor to the parent Flutter view without relying on removed
`GdkWindow` positioning APIs. GTK owns the final compositor-safe placement,
including flipping the popover to stay on screen.

GTK4 popovers are transient widget surfaces, not independent toplevel windows.
Consequently, their host handle is a `GtkPopover`, and the GTK4 backend cannot
report a compositor-adjusted final offset in the same way as GTK3's
`moved-to-rect` signal.
