# GTK4 Runtime API Compatibility

The Linux GTK4 embedder can build against GTK 4.8 headers while using selected
newer APIs on the machine running the application. This document describes
that internal compatibility layer and the requirements for extending it.
It does not describe runtime selection between GTK3 and GTK4: each engine
library links one GTK major.

## Compatibility Boundary

Build-time headers determine which declarations the compiler can use.
The loaded GTK library determines which optional functions and interfaces the
application can use. A compile-time `GTK_CHECK_VERSION` check alone cannot
establish runtime availability.

The compatibility layer resolves newer functions without creating direct
linker imports for those functions. It does not lower the glibc or other
dependency requirements of the finished binary. Building against a newer
sysroot and enabling runtime lookup is not equivalent to building against
the older compatibility baseline.

APIs already available in the baseline, such as the value-based accessible
state/property/relation updates, remain ordinary direct calls.

## Implementation

[fl_gtk4_runtime_api.h](../../../engine/src/flutter/shell/platform/linux/fl_gtk4_runtime_api.h)
declares the internal function table, wrappers, opaque types, and private
interface layouts.
[fl_gtk4_runtime_api.cc](../../../engine/src/flutter/shell/platform/linux/fl_gtk4_runtime_api.cc)
owns lookup and capability checks.

`fl_gtk_runtime_api_get()` initializes a function-local static table once,
using `gtk_check_version()` and `dlsym(RTLD_DEFAULT, ...)`. Subsequent calls
reuse that table. Normal wrapper calls perform capability checks and indirect
calls, not repeated symbol lookup. This does not remove the cost of the GTK
operation itself or of rendering synchronization.

In compatibility mode, capability checks require both the version threshold
and the complete symbol set used by that capability:

| Capability | Runtime threshold | Behavior when unavailable |
| --- | --- | --- |
| Native accessible tree | GTK 4.10 | View exports the widget-backed render surface instead of the native semantics tree |
| Accessible text | GTK 4.14 | No native text interface; text notification wrappers do nothing |
| Announcements | GTK 4.14 | Announcement wrapper does nothing |
| DMA-BUF texture APIs | GTK 4.14 | Compositor cannot select the DMA-BUF texture route |

These are the implementation's capability groups, not a claim of complete
accessibility support at each version. DMA-BUF API availability is also only
one prerequisite: display formats, EGL support, synchronization, and buffer
ownership are checked by the rendering code.

Callers should use the wrappers and feature predicates rather than adding
ad-hoc lookups or testing a single pointer from a multi-function group.
Unavailable operations have explicit null, invalid-type, or no-op results.
Rendering callers must still handle operational failures after a capability
check succeeds.

## Build Modes

The GN arguments are declared in
[the Linux BUILD.gn](../../../engine/src/flutter/shell/platform/linux/BUILD.gn).
They affect the GTK4 engine build, not an application's Dart defines.

The default compatibility configuration is:

```gn
gtk4_runtime_api_compat = true
gtk4_native_accessibility_tree = false
gtk4_native_accessibility_tree_compat = true
```

Either native-tree argument includes the native backend. The compatibility
tree argument requires runtime API compatibility. Consequently,
`gtk4_native_accessibility_tree=false` alone does not disable native export.
To omit it, set both native-tree arguments to false.

For a direct-call reference build, use suitable newer headers and libraries
(GTK 4.14 or newer for the current text and DMA-BUF paths):

```gn
gtk4_runtime_api_compat = false
gtk4_native_accessibility_tree = true
gtk4_native_accessibility_tree_compat = false
```

Keep reference builds in a separate engine output directory. Direct-call
branches introduce ordinary GTK imports and are not intended to run with
libraries missing those symbols. Disabling compatibility is not a guarantee
that no lookup code exists in the binary: the table remains available, and
some wrappers retain lookup branches when newer declarations are absent.

## Interface Layouts

Function lookup does not provide C struct layouts, macros, or inline
implementations. Opaque pointer declarations suffice only when the caller
does not access the pointed-to layout.

Native accessibility is a deliberate exception to opaque-only handling.
The layer maintains private GTK 4.10 accessible and GTK 4.14 text interface
mirrors. The accessibility implementation installs callbacks only after its
runtime capability gate succeeds. With suitable newer headers, compile-time
size and offset assertions check parts of those layouts against GTK.

These mirrors are handwritten ABI contracts, not generated replacements for
GTK headers. A new field needs an exact signature, offset/size review, runtime
gate, and tests against both the baseline and newer libraries. Existing layout
assertions do not prove every member or every runtime is compatible. Never
write newer interface fields merely because the application compiled.

## Loader and Security Assumptions

`RTLD_DEFAULT` searches the process's existing symbol scope; this layer does
not open another GTK library by filename. It therefore avoids introducing a
second library search/load operation, but does not authenticate symbol origin
or prevent `LD_PRELOAD` interposition. The application trusts its loader
environment and already-loaded native code.

Keep lookup centralized, names fixed, and C signatures exact. Version checks
do not replace null checks. A partially resolved group must remain unavailable.
Do not load GTK3 into a GTK4 process as a fallback.

## Extending and Testing

When adding an optional API:

1. Confirm that it is absent from the build baseline and that a fallback is
   useful. Keep baseline APIs direct.
2. Add the exact declaration, lookup, wrapper, and capability-group check.
   Review ownership, callback lifetime, and error behavior as well as types.
3. Test unsupported versions, missing symbols, partial groups, and successful
   calls. Installed-runtime smoke tests alone do not exercise missing-symbol
   behavior on a newer host.
4. Build with baseline and newer headers. Run the same compatibility binary
   with old and new runtime library closures; test the direct-call build
   separately.
5. Inspect undefined symbols and dependencies in the resulting library.
   Optional newer APIs must not become direct imports in compatibility mode,
   and a process must not acquire both GTK majors.

[Runtime API tests](../../../engine/src/flutter/shell/platform/linux/fl_gtk4_runtime_api_test.cc)
cover installed-runtime capabilities and conditional fallbacks.
[The compatibility validation helper](../../../dev/tools/validate_gtk4_runtime_compat.py)
supports build and runtime checks; use its `--help` for invocation options.
Its optional-symbol audit currently covers only part of the table, so extend
the audit alongside new bindings rather than treating it as exhaustive.

## Related Documentation

- [Linux GTK Variant Selection](linux-gtk-variant.md)
- [Linux GTK Rendering Paths](linux-gtk-rendering.md)
