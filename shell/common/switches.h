// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <string_view>

#include "flutter/common/settings.h"
#include "flutter/fml/command_line.h"

#ifndef SHELL_COMMON_SWITCHES_H_
#define SHELL_COMMON_SWITCHES_H_

namespace flutter {

// clang-format off
#ifndef DEF_SWITCHES_START
#define DEF_SWITCHES_START enum class Switch {
#endif
#ifndef DEF_SWITCH
#define DEF_SWITCH(swtch, flag, help) swtch,
#endif
#ifndef DEF_SWITCHES_END
#define DEF_SWITCHES_END Sentinel, } ;
#endif
// clang-format on

DEF_SWITCHES_START
DEF_SWITCH(AotSharedLibraryName,
           "aot-shared-library-name",
           "Name of the *.so containing AOT compiled Dart assets.")
DEF_SWITCH(SnapshotAssetPath,
           "snapshot-asset-path",
           "Path to the directory containing the four files specified by "
           "VmSnapshotData, VmSnapshotInstructions, "
           "VmSnapshotInstructions and IsolateSnapshotInstructions.")
DEF_SWITCH(VmSnapshotData,
           "vm-snapshot-data",
           "The VM snapshot data that will be memory mapped as read-only. "
           "SnapshotAssetPath must be present.")
DEF_SWITCH(VmSnapshotInstructions,
           "vm-snapshot-instr",
           "The VM instructions snapshot that will be memory mapped as read "
           "and executable. SnapshotAssetPath must be present.")
DEF_SWITCH(IsolateSnapshotData,
           "isolate-snapshot-data",
           "The isolate snapshot data that will be memory mapped as read-only. "
           "SnapshotAssetPath must be present.")
DEF_SWITCH(IsolateSnapshotInstructions,
           "isolate-snapshot-instr",
           "The isolate instructions snapshot that will be memory mapped as "
           "read and executable. SnapshotAssetPath must be present.")
DEF_SWITCH(CacheDirPath,
           "cache-dir-path",
           "Path to the cache directory. "
           "This is different from the persistent_cache_path in embedder.h, "
           "which is used for Skia shader cache.")
DEF_SWITCH(ICUDataFilePath, "icu-data-file-path", "Path to the ICU data file.")
DEF_SWITCH(ICUSymbolPrefix,
           "icu-symbol-prefix",
           "Prefix for the symbols representing ICU data linked into the "
           "Flutter library.")
DEF_SWITCH(ICUNativeLibPath,
           "icu-native-lib-path",
           "Path to the library file that exports the ICU data.")
DEF_SWITCH(DartFlags,
           "dart-flags",
           "Flags passed directly to the Dart VM without being interpreted "
           "by the Flutter shell.")
DEF_SWITCH(DeviceObservatoryHost,
           "observatory-host",
           "The hostname/IP address on which the Dart Observatory should "
           "be served. If not set, defaults to 127.0.0.1 or ::1 depending on "
           "whether --ipv6 is specified.")
DEF_SWITCH(DeviceObservatoryPort,
           "observatory-port",
           "A custom Dart Observatory port. The default is to pick a randomly "
           "available open port.")
DEF_SWITCH(DisableObservatory,
           "disable-observatory",
           "Disable the Dart Observatory. The observatory is never available "
           "in release mode.")
DEF_SWITCH(IPv6,
           "ipv6",
           "Bind to the IPv6 localhost address for the Dart Observatory. "
           "Ignored if --observatory-host is set.")
DEF_SWITCH(EnableDartProfiling,
           "enable-dart-profiling",
           "Enable Dart profiling. Profiling information can be viewed from "
           "the observatory.")
DEF_SWITCH(EndlessTraceBuffer,
           "endless-trace-buffer",
           "Enable an endless trace buffer. The default is a ring buffer. "
           "This is useful when very old events need to viewed. For example, "
           "during application launch. Memory usage will continue to grow "
           "indefinitely however.")
DEF_SWITCH(EnableSoftwareRendering,
           "enable-software-rendering",
           "Enable rendering using the Skia software backend. This is useful"
           "when testing Flutter on emulators. By default, Flutter will"
           "attempt to either use OpenGL or Vulkan.")
DEF_SWITCH(SkiaDeterministicRendering,
           "skia-deterministic-rendering",
           "Skips the call to SkGraphics::Init(), thus avoiding swapping out"
           "some Skia function pointers based on available CPU features. This"
           "is used to obtain 100% deterministic behavior in Skia rendering.")
DEF_SWITCH(FlutterAssetsDir,
           "flutter-assets-dir",
           "Path to the Flutter assets directory.")
DEF_SWITCH(Help, "help", "Display this help text.")
DEF_SWITCH(LogTag, "log-tag", "Tag associated with log messages.")
DEF_SWITCH(DisableServiceAuthCodes,
           "disable-service-auth-codes",
           "Disable the requirement for authentication codes for communicating"
           " with the VM service.")
DEF_SWITCH(StartPaused,
           "start-paused",
           "Start the application paused in the Dart debugger.")
DEF_SWITCH(EnableCheckedMode, "enable-checked-mode", "Enable checked mode.")
DEF_SWITCH(TraceStartup,
           "trace-startup",
           "Trace early application lifecycle. Automatically switches to an "
           "endless trace buffer.")
DEF_SWITCH(TraceSkia,
           "trace-skia",
           "Trace Skia calls. This is useful when debugging the GPU threed."
           "By default, Skia tracing is not enabled to reduce the number of "
           "traced events")
DEF_SWITCH(DumpSkpOnShaderCompilation,
           "dump-skp-on-shader-compilation",
           "Automatically dump the skp that triggers new shader compilations. "
           "This is useful for writing custom ShaderWarmUp to reduce jank. "
           "By default, this is not enabled to reduce the overhead. ")
DEF_SWITCH(
    TraceSystrace,
    "trace-systrace",
    "Trace to the system tracer (instead of the timeline) on platforms where "
    "such a tracer is available. Currently only supported on Android and "
    "Fuchsia.")
DEF_SWITCH(UseTestFonts,
           "use-test-fonts",
           "Running tests that layout and measure text will not yield "
           "consistent results across various platforms. Enabling this option "
           "will make font resolution default to the Ahem test font on all "
           "platforms (See https://www.w3.org/Style/CSS/Test/Fonts/Ahem/). "
           "This option is only available on the desktop test shells.")
DEF_SWITCH(VerboseLogging,
           "verbose-logging",
           "By default, only errors are logged. This flag enabled logging at "
           "all severity levels. This is NOT a per shell flag and affect log "
           "levels for all shells in the process.")
DEF_SWITCH(RunForever,
           "run-forever",
           "In non-interactive mode, keep the shell running after the Dart "
           "script has completed.")
DEF_SWITCH(DisableDartAsserts,
           "disable-dart-asserts",
           "Dart code runs with assertions enabled when the runtime mode is "
           "debug. In profile and release product modes, assertions are "
           "disabled. This flag may be specified if the user wishes to run "
           "with assertions disabled in the debug product mode (i.e. with JIT "
           "or DBC).")
DEF_SWITCHES_END

void PrintUsage(const std::string& executable_name);

const std::string_view FlagForSwitch(Switch swtch);

Settings SettingsFromCommandLine(const fml::CommandLine& command_line);

}  // namespace flutter

#endif  // SHELL_COMMON_SWITCHES_H_
