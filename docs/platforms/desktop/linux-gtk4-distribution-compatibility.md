# GTK4 Runtime Capabilities by Linux Distribution

Package versions checked on 2026-11-14. This document describes the proposed
GTK4 Linux embedder and its current implementation. It is a deployment reference,
not a declaration of upstream Flutter support for these distributions.

Versions refer to the linked package repositories. Installed systems, minor/EUS
channels, backports, containers, and Flatpak runtimes can differ. The table shows
API eligibility; it does not establish cross-distribution runtime test coverage
or complete accessibility parity. The final minimum supported GTK version
remains a proposal decision; 4.8 is the current implementation's build baseline.

The runtime binding layer lets one engine built against GTK 4.8 use selected
newer APIs when the loaded library exports them. It does not supply missing GTK
libraries, lower the 4.8 floor, or guarantee graphics-driver/compositor support.
The runtime checks test version and required symbols; distro names do not select
features. glibc, GLib, runner, architecture, and plugin compatibility remain
separate requirements. The column entries below are API eligibility, not results
from running this engine on each OS.

| Distribution / repository | GTK4 version | Meets 4.8 build baseline | Native accessibility tree 4.10 | Text, announcements, DMA-BUF and offload 4.14 | Platform-state notifications 4.18 | AT caret/selection commands 4.22 | Frame outcome telemetry 4.24 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| [Ubuntu 22.04 LTS, updates](https://packages.ubuntu.com/jammy-updates/libgtk-4-1) | 4.6.9 | Below baseline | — | — | — | — | — |
| [Ubuntu 24.04 LTS, updates](https://packages.ubuntu.com/noble-updates/libgtk-4-1) | 4.14.5 | Yes | Yes | Eligible | No | No | No |
| [Ubuntu 26.04 LTS, updates](https://packages.ubuntu.com/resolute-updates/libgtk-4-1) | 4.22.4 | Yes | Yes | Eligible | Yes | Yes | No |
| [Ubuntu 26.10](https://packages.ubuntu.com/stonking/libgtk-4-1) | 4.24.1 | Yes | Yes | Eligible | Yes | Yes | Yes |
| [RHEL 9.4 update record¹](https://linux.web.cern.ch/updates/rhel9/prod/2024/05/monthly_updates/) | 4.12.3 | Yes | Yes | No | No | No | No |
| [RHEL 10.2 update record²](https://linux.web.cern.ch/updates/rhel10/prod/2026/10/monthly_updates/) | 4.16.7 | Yes | Yes | Eligible | No | No | No |
| [Fedora 43, stable package](https://packages.fedoraproject.org/pkgs/gtk4/gtk4/) | 4.20.4 | Yes | Yes | Eligible | Yes | No | No |
| [Fedora 44, stable package](https://packages.fedoraproject.org/pkgs/gtk4/gtk4/) | 4.22.5 | Yes | Yes | Eligible | Yes | Yes | No |
| [Fedora 45, stable package](https://packages.fedoraproject.org/pkgs/gtk4/gtk4/) | 4.24.1 | Yes | Yes | Eligible | Yes | Yes | Yes |
| [Debian 12, bookworm](https://packages.debian.org/bookworm/libgtk-4-1) | 4.8.3 | Yes | Fallback | No | No | No | No |
| [Debian 13, trixie](https://packages.debian.org/trixie/libgtk-4-1) | 4.18.6 | Yes | Yes | Eligible | Yes | No | No |

¹ CERN's RHEL 9 repository update record identifies `gtk4-4.12.3-2.el9`
and links Red Hat advisory RHBA-2024:2248. This confirms the package in that
RHEL update stream, rather than inferring it solely from a rebuild distribution.
Do not assume every minor/EUS channel has the same package; older EL9 systems
can be below 4.8. CentOS Stream 9 and Rocky 9.4 also publish the 4.12.3 line.

² CERN's October 2026 RHEL 10 update record identifies
`gtk4-4.16.7-5.el10_2` with Red Hat advisory RHBA-2026:76616. The 4.16.7 line is
also verified in the official CentOS Stream 10 spec and Oracle Linux advisory.
This does not assign that exact build to every RHEL 10 EUS channel.
RHEL 8 is deliberately not assigned a GTK4 version here: a stock supported GTK4
package was not verified. The GTK3 engine remains a separate deployment option.

## What the optional features provide

See [GTK4 runtime API compatibility](linux-gtk4-runtime-api.md#implementation)
for the capability groups, required symbols, interface ABI checks, and fallbacks.
Fractional surface scale uses GTK 4.12; fractional monitor scale uses GTK 4.14.
The runtime selection is independent of the
[GTK major selected for the application](linux-gtk-variant.md).

GTK 4.16 adds text geometry vfuncs to the interface ABI; this branch mirrors
and checks their layout but does not currently install `get_extents`/`get_offset`
callbacks. They are not counted as an implemented runtime benefit here.

Text and tree access still depend on Flutter semantics and a working accessibility
bus. API availability does not establish correct Orca behavior for every widget.

DMA-BUF eligibility still requires supported formats/modifiers, renderer/driver
interop, and a working display backend. Graphics offload is opt-in with
`FLUTTER_GTK4_ENABLE_GRAPHICS_OFFLOAD=1`; GTK decides acceptance per scene. A
wrapper or newer GTK version does not prove offload, direct scanout, or a speedup.
Vulkan rendering and Flutter GPU compute are separate engine/driver capabilities;
they are not unlocked merely by crossing a GTK version threshold.

Frame telemetry uses `FLUTTER_LINUX_FRAME_TIMINGS=1` with GTK pacing and a captured
engine timeline. The collector exists only in debug/profile builds. Release and
JIT-release contain none of this collector or its environment/symbol checks.
Presented/discarded outcomes concern the GTK surface, not an exact map of Flutter
frames or input-to-photon latency. Older GTK3/GTK4 runs can still report engine
FrameTiming and resource measurements, with explicit unknown presentation outcomes.

## Runtime versus host distribution

For Flatpak, use the GTK inside the selected runtime, not the host OS row. An
AppImage or other bundle may likewise ship a different GTK. The same Fedora host
can run applications with different capabilities if their loaded runtimes differ.

Inspect the actual loaded GTK version in the process or record it with the test
harness. Package-manager queries are useful for native installs:

```sh
rpm -q gtk4                       # Fedora / RHEL-family native package
dpkg-query -W libgtk-4-1           # Debian / Ubuntu native package
pkg-config --modversion gtk4      # Development metadata, not proof of loaded DSO
```

The compatibility validator and the frame benchmark should keep loaded library
paths, build IDs, dependency versions, runtime API observations, and fallback
results with each run. Do not present this eligibility matrix as cross-distro
runtime test coverage. A build sysroot can contain a different GTK version from its namesake
distribution; inspect its package contents separately.

## API references and code

- [GtkAccessible tree API](https://docs.gtk.org/gtk4/method.Accessible.get_first_accessible_child.html)
- [GtkAccessibleText](https://docs.gtk.org/gtk4/iface.AccessibleText.html)
- [GtkGraphicsOffload](https://docs.gtk.org/gtk4/class.GraphicsOffload.html)
- [GdkDmabufTextureBuilder](https://docs.gtk.org/gdk4/class.DmabufTextureBuilder.html)
- [Native text selection callback](https://docs.gtk.org/gtk4/vfunc.AccessibleText.set_selection.html)
- [Frame result API](https://docs.gtk.org/gdk4/method.FrameTimings.get_result.html)
- [Runtime bindings](../../../engine/src/flutter/shell/platform/linux/fl_gtk4_runtime_api.cc)
- [Runtime interface declarations](../../../engine/src/flutter/shell/platform/linux/fl_gtk4_runtime_api.h)
- [Frame timing collector](../../../engine/src/flutter/shell/platform/linux/fl_vsync_timing.cc)
- [Graphics offload wrapper](../../../engine/src/flutter/shell/platform/linux/fl_graphics_offload_gtk4.cc)
