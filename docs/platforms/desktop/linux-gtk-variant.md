# Linux GTK Variant Selection

## Engine and Application Layers

The engine has separate GTK3 and GTK4 library targets:

- `libflutter_linux_gtk.so` links GTK3.
- `libflutter_linux_gtk4.so` links GTK4.

The engine build can produce both. The application's Linux runner selects one
at build time; do not load both GTK majors into the same process. This is not a
global GTK selection for the Flutter framework.

The unified runner template defines `FLUTTER_LINUX_GTK3` or
`FLUTTER_LINUX_GTK4`. Engine source selection uses the GTK4 define for GTK4
paths; do not assume every GTK3 engine target defines the GTK3 macro.

## Tool Selection

The Flutter tool resolves the variant in this order:

1. Explicit `--linux-gtk=gtk3|gtk4`.
2. Project `flutter.config.linux-gtk-default` in `pubspec.yaml`.
3. Global `flutter config --linux-gtk-default=gtk3|gtk4`.
4. GTK3.

For a project default:

```yaml
flutter:
  config:
    linux-gtk-default: gtk4
```

For an individual build or run:

```bash
flutter build linux --linux-gtk=gtk4
flutter run -d linux --linux-gtk=gtk3
```

The tool propagates its resolved value to CMake and the
`FLUTTER_LINUX_GTK` Dart define. A manually supplied conflicting Dart define
is rejected. GTK3 app output uses `build/linux`; GTK4 uses `build/linux-gtk4`.

The unified CMake template accepts the `FLUTTER_LINUX_GTK` environment variable,
then `LINUX_GTK_VARIANT`, then GTK3 when configured directly. This is a
lower-level entrypoint, not an environment override of Flutter's selection:
the Flutter tool sets that environment variable to its resolved variant.
Prefer the CLI or project setting so Dart, native assets, and CMake agree.

## Templates

`flutter create` supports three Linux template choices:

```bash
flutter create --platforms=linux --linux-gtk=gtk3 example_gtk3
flutter create --platforms=linux --linux-gtk=gtk4 example_gtk4
flutter create --platforms=linux --linux-gtk=linux-gtk-unified example_unified
```

The unified template carries both runner configurations in one Linux project.
GTK-specific templates preconfigure their corresponding runner. Selecting a
different variant does not automatically port an existing runner or its
plugins: native code and dependencies must support the selected GTK major.

## Local Engine Builds

GTK selection and local-engine selection are separate. Selecting GTK4 does not
build the engine or install a GTK4 library into the SDK cache. When using a
locally built engine, pass matching engine and host output names, for example:

```bash
flutter run -d linux --linux-gtk=gtk4 \
  --local-engine-src-path=/path/to/flutter/engine/src \
  --local-engine=host_debug_unopt \
  --local-engine-host=host_debug_unopt
```

Use the actual output names produced by your engine build, including any
sysroot/configuration suffix. The engine, host Dart compiler, and patched SDK
must be compatible; do not repair missing artifacts by mixing cached SDK
files with an unrelated local engine.

## Related Documentation

- [Linux Native Windowing Helpers](linux-popup-windowing.md)
- [Linux GTK Rendering Paths](linux-gtk-rendering.md)
- [GTK4 Runtime API Compatibility](linux-gtk4-runtime-api.md)
