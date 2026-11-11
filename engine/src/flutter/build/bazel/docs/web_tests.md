# The web engine's unit tests

## The web engine's unit tests: felt's suites

`lib/web_ui/test` -- about 190 files in six test sets (`engine`, `ui`, `canvaskit`,
`webparagraph`, `skwasm`, `fallbacks`) -- is run by felt
(`lib/web_ui/dev`): a compile step (dart2js or dart2wasm per bundle, one
compile per file, into `out/web_tests/test_bundles/<bundle>/` with a
`results.json`), a copy step that lays the artifacts the tests load
(`out/web_tests/artifacts/`: CanvasKit's variants and skwasm from the web
build, flutter.js, test fonts, Skia's test images, the harness's host page)
and a run step: package:test's runner in process, its browser platform
replaced by felt's own (a shelf server serving the bundle, the artifacts and
a generated page per test; Chrome driven over the DevTools protocol for
uncaught exceptions and screenshots), one suite at a time,
`--concurrency=1`. `lib/web_ui/test/felt_config.yaml` names the sets, the
bundles (set × compiler × renderer), the run configurations (browser,
CanvasKit variant, cross-origin isolation, flags) and the suites; CI's web
test builders compile the bundles from the prebuilt SDK and run the Chrome,
Firefox and Safari suites.

Under Bazel (`build_defs/web/web_ui_tests.bzl`; `lib/web_ui/BUILD.bazel`),
the same three steps are the build's. The tests import `package:ui`, never
`dart:ui`, so the compile needs no engine build: `web_ui_test_bundle` runs
felt's exact command from `@dart_sdk_linux_x64` over a package
configuration of package:ui, its path packages and the hosted packages of
**lib/web_ui's own `pubspec.lock`** (its versions differ from the
workspace's; `pub.lock.bzl`'s `PUB_LOCKS`, `pub_package_config(lock =
...)`), one action per file into a directory shaped as the bundle with a
one-file `results.json` -- `bundles/<bundle>/<file>`. Every file of
`test/` is an input of every compile (test files import other test files),
but the compilers say what they read (dart2js's `.deps`, dart2wasm's
`--depfile`) and the action hands Bazel the rest as its unused-inputs
list, so a test edit recompiles what imports it and no more. The run is
felt itself: `dart_vm_kernel` compiles `dev/felt.dart` and puts the kernel at
`dev/felt.dill`, where felt's path derivation (engine/src is five
directories above its script) makes the runfiles' `engine/src/out/web_tests`
its build directory; `web_ui_test` lays the bundle and the artifacts there
(CanvasKit, skwasm and flutter.js straight from
`flutter_web_sdk_archive_release`'s entries -- the web SDK's layout is
felt's -- the five fonts with a `FontManifest.json`, `@google_fonts_for_unit_tests`
as the fallback fonts, `@skia//:resources_images_tree` less the invalid
files, the host page with `web_ui_host_page`'s dart2js of `host.dart`), puts
felt's package configuration at the package's `.dart_tool` for its server,
and runs `felt test --run --suite=<suite>` on the pinned `@chrome`
(`CHROME_NO_SANDBOX=true` inside Bazel's sandbox) with cwd `lib/web_ui`.
One test target per file and suite, `<suite>/<file>`, a `test_suite` per
felt suite, `:chrome_tests` over the sixteen Chrome suites -- the CanvasKit
`chromium` and `full` variants, skwasm's cross-origin-isolated and
single-threaded runs, wimp, WebParagraph, dart2wasm's engine suite, the
three fallbacks suites (whose bundle compiles a file twice, dart2wasm-skwasm
and dart2js-canvaskit side by side) -- `:firefox_tests` over the nine
Firefox suites (`@firefox`, the release the lock pins, through
`FIREFOX_EXECUTABLE`; felt starts an X display itself, the host's Xvfb,
inside the sandbox) and `:tests` over both; the files run in parallel
(felt's browsers take a free debugger port now, not a constant). The tests
run with no network (`block-network`): felt's Skia Gold client finds Gold
unreachable and the goldens compare nothing, as for a developer offline --
with the network the verdict depended on the host's fonts against CI's
baselines (`web_paragraph.locales.png` is 10 px wider here, under felt on
the checkout just the same) and on Gold; CI's Gold comparison and upload
stay felt's job. A file that declares no test on a suite's browser is left
out of that suite (`exclude`: semantics_test on Firefox), since a run of
the file alone would report that no test ran.

The BUILD file does not repeat felt's configuration. `tools/gn_to_bazel`
reads `test/felt_config.yaml` -- the web team's source of truth, as felt's
own `dev/felt_config.dart` reads it -- and writes `lib/web_ui/felt_config.bzl`
beside the BUILD file: `FELT_CONFIG`, one dict of the five tables (compile
configurations, test sets with their directories, bundles with their set
and compile configurations, run configurations with their browser, suites
with their bundle, run configuration and artifact dependencies), the names
and the references among them; a run configuration's flags and variant
stay felt's, read from the YAML by suite name at run time. `--check`
compares the two files as it compares the generated BUILD files. One macro
call, `web_ui_tests(name = "tests", config = FELT_CONFIG, browsers =
{...})`, declares everything above: the suites whose run configuration
names one of the browsers given (Chrome's and Firefox's: Chrome for
Testing's build for the host, Mozilla's Linux tarball or, on a Mac, its disk
image mounted with hdiutil as felt installs it -- CI runs the Firefox suites
on Linux, and on a Mac they are `manual`, run by name, until a Mac's run of
them is on record: a corporate Mac whose endpoint policy admits no browser
but Chrome cannot run them, and the build does not re-sign the bundle to get
around that; Safari's and Edge's need other hosts), the bundles those
suites run, one test per file
and suite -- the test sets' files are globbed from their directories, so a
new test file is a new target with no edit -- and the suites per browser
and whole. What the BUILD file still says is this host's: the browsers
(`@chrome`, `@firefox`, their variables and sandbox environment), the
files a suite leaves out, the files that need the network. A new suite,
bundle or set is an edit to felt_config.yaml and a run of the converter.

The browsers' system libraries come from the build, not the host. Chrome
and Firefox ship their own libraries but load the platform's from the
system -- GTK, NSS, X11, ALSA, D-Bus, fontconfig, some eighty shared
objects (`LD_DEBUG=libs`) -- and a test took them from whatever the host
had. The build sysroot the engine compiles against (`@sysroot_linux_x64`,
Chromium's Debian bullseye tarball) names every one of them but cannot
supply them: Chromium strips its sysroot's shared objects to stubs for
linking (`libgtk-3.so.0` is 403 KB there, 8 MB whole), and a loader given
one asserts or faults. So the build fetches the same packages whole: the
build sysroot carries dpkg's metadata for its 640 packages
(`debian/<package>/DEBIAN/{control,md5sums}`), from which
`build_defs/repositories/debian_runtime_lock.py` maps the browsers' `NEEDED`
sonames to packages, adds Mesa (Firefox's WebGL on Xvfb is Mesa's
llvmpipe, which Firefox loads by `dlopen` rather than `NEEDED`; Chrome
brings its own ANGLE and SwiftShader) and Debian's fonts (DejaVu, and
Liberation, the metric-compatible stand-ins for Arial, Times and Courier,
with fontconfig's own rules, `fontconfig-config`), closes
over `Depends` (140 packages at the build sysroot's versions -- Mesa's
LLVM 11 the largest; architecture-independent data packages other than
those three, and the C library and compiler runtime, left out), finds each
file in snapshot.debian.org's immutable archive and pins its sha256 into
`debian_runtime.lock.bzl`; the `debian_runtime` extension
(`debian_runtime.bzl`) downloads them and unpacks each `data.tar` with
the engine's own llvm-ar into `@sysroot_linux_x64_runtime` (253 MB
unpacked; about a minute to fetch), then makes the two `conf.d` links
fontconfig-config's postinst would have made for the debconf defaults
(`10-hinting-slight.conf`, `70-no-bitmaps.conf`: unpacking runs no
postinst). `browser_launcher`
(`build_defs/web/browser_launcher.bzl`) writes a script in the browser's
name that puts that tree's `lib/x86_64-linux-gnu` and
`usr/lib/x86_64-linux-gnu` first on `LD_LIBRARY_PATH`, points Mesa at its
drivers (`LIBGL_DRIVERS_PATH`), GLVND at its EGL vendor
(`__EGL_VENDOR_LIBRARY_DIRS`) and GLib at its GIO modules
(`GIO_MODULE_DIR`) -- all found by absolute path otherwise, the host's
modules into the sysroot's GLib -- writes a `fonts.conf` confining
fontconfig to the sysroot's
`usr/share/fonts`, including its `etc/fonts/conf.d`, with a cache
directory of the test's own
(`FONTCONFIG_FILE`: a rendering depends on no font of the host, and
fontconfig scans twenty files rather than the host's hundreds), and execs the
browser: the browser process alone, so that felt's Dart VM and the Xvfb
it starts keep the host's libraries. `web_ui_test` and
`dart_test` take the launcher as their `browser` (flutter_tools' web shard
also wraps chromedriver). Under it Chrome loads 80 libraries from the
sysroot and 8 from the host: `ld-linux`, `libc`, `libm`, `libdl`,
`libpthread`, `librt`, `libresolv` and `libgcc_s`, by design -- the host's
dynamic loader must match its own libc, and a library built against glibc
2.31 runs on any newer one. What stays the host's: those eight, xkbcomp
(below), and the configuration the sysroot's other libraries read
by absolute path (GTK's settings). Firefox's
policies file, which felt writes beside the executable it resolves, is
written beside the launcher's script by the rule. The label flag
`--//build_defs/web:browser_libraries` names a `browser_libraries` target:
`//build_defs/web:sysroot_libraries` by default,
`//build_defs/web:host_libraries` for the host's (the script then sets
nothing). Without Mesa, Firefox's WebGL suites fail as "Skwasm requires
WebGL support": the host's Mesa cannot load beside the sysroot's older
`libdrm` and `libexpat`, which is the general hazard of mixing the two --
the closure must be complete. Measured on this host, the 923 tests with
`--local_test_jobs=6`: with the sysroot's libraries but the host's fonts
(the first form of this), 923 pass in 2,071 s of wall time, the per-test
sums Chrome 4,028 s (545 tests, median 5.7 s) and Firefox 4,764 s (375,
median 12.0 s); with the host's libraries (the flag) 923 pass in 2,295 s
(a few minutes of it re-checking the action cache under the changed
flag), Chrome 3,955 s (median 5.8 s), Firefox 3,560 s (median 8.0 s) --
Firefox paid about 4 s per test under the sysroot, the sysroot's
fontconfig 2.13 rebuilding a cache over the host's hundreds of fonts in
every test's HOME (it cannot read the host's caches, a newer format),
which is why the fonts joined the sysroot. Which fonts matters: the
WebParagraph suite measures `Arial` (this host has it, Microsoft's core
fonts). With DejaVu alone, four of its files fail, a line of Arial at
20 px measuring 24 rather than 22 (DejaVu Sans is taller); with
Liberation Sans answering for Arial but no hinting style set, three
cases of `paragraph_get_position_test` are a pixel off (fontconfig's
default is hintfull, under which the TrueType hints of Liberation Sans
1.07 move its advances); with the postinst's `hintslight`, 923 pass in
1,989 s of wall time, the fastest of the three forms: Chrome 3,802 s (546
tests, median 5.1 s), Firefox 3,994 s (377, median 9.3 s -- the cache it
rebuilds per test now covers 22 files; 1.3 s above the host's libraries
and caches).

The X display comes from the build as well. felt starts `Xvfb` by name
for Firefox when there is no `DISPLAY` (headless Firefox initializes
WebGL only on a display), and took the host's. Xvfb is a program the
build sysroot has no trace of, so `debian_runtime_lock.py` reads, for
what the sysroot lacks, bullseye's own `Packages` index as
snapshot.debian.org had it at `--index`'s timestamp (`20240901T000000Z`,
the month of the sysroot's newest package): a package's version,
dependencies, file and sha256 come from the index, and a package the
sysroot has keeps the sysroot's version. `--package xvfb` closes to eight
more packages (xvfb, libxfont2, libfontenc1, libunwind8, libaudit1,
libcap-ng0, libbz2-1.0 and, as data, xkb-data: 148 in all, 262 MB
unpacked). `display_launcher` writes a script named `Xvfb` that runs the
sysroot's on the sysroot's libraries with the server's built-in fonts and
the sysroot's keyboard data (`-fp built-ins -xkbdir`), and `web_ui_test`
puts it first on the test's PATH (`tools`; the `_BROWSERS` entry for
Firefox names it). One thing of X stays the host's: `xkbcomp`, the keymap
compiler Xvfb runs at the path built into it, `/usr/bin/xkbcomp`
(x11-xkb-utils; without it the server falls back to its pre-XKB keymap,
with a warning). Under `--//build_defs/web:browser_libraries=//build_defs/web:host_libraries`
the script hands over to the host's Xvfb, the next on PATH. Measured: the
923 tests pass in 1,488 s of wall time, Firefox's 377 at a median of 7.9 s
(9.3 s on the host's Xvfb, which scans the host's font directories at
start; the host-libraries form's 8.0), Chrome's 546 at 5.0 s (unchanged
path; 5.1 before). The sysroot's Xvfb loads 29 libraries from the sysroot
and glibc's 6 from the host.

```sh
bazel test //engine/src/flutter/lib/web_ui:tests                              # Chrome's sixteen suites and Firefox's nine (923 tests with the eight before the roll)
bazel test --//build_defs/web:browser_libraries=//build_defs/web:host_libraries //engine/src/flutter/lib/web_ui:tests   # the host's libraries
bazel test //engine/src/flutter/lib/web_ui:chrome_tests                       # 546 tests
bazel test //engine/src/flutter/lib/web_ui:chrome-dart2js-canvaskit-engine   # 86 files; felt's suite of that name
bazel test //engine/src/flutter/lib/web_ui:chrome-dart2js-canvaskit-engine/alarm_clock_test
bazel build //engine/src/flutter/lib/web_ui:bundles/dart2js-canvaskit-engine   # the compiles alone
```

`chrome-dart2js-canvaskit-engine`: 86 of 86 files, 1,274 cases and 13
skipped, in 4m18s from cold (the compiles included) -- what `felt test
--suite=chrome-dart2js-canvaskit-engine` counts. Chrome's sixteen: 546
files, 10,448 cases and 121 skipped, 19 minutes from cold with the 336
compiles; Firefox's eight before the roll (nine since, with
`firefox-dart2wasm-wimp-ui`): 377 files, 6,504 cases and 247 skipped, 19
minutes of runs. Safari and Edge (other hosts) stay felt's.
