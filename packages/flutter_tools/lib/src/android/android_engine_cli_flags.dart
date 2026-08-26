// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// TODO(camsim99): Migrate to a shared file with Dart/Kotlin/Java once constants are
// defined cross-language; see https://github.com/flutter/flutter/pull/190236.
/// The command line flags that are passed directly to the Android engine.
abstract final class AndroidEngineCliFlags {
  static const String traceStartup = 'trace-startup';
  static const String profileStartup = 'profile-startup';
  static const String route = 'route';
  static const String traceSkia = 'trace-skia';
  static const String traceAllowlist = 'trace-allowlist';
  static const String traceSkiaAllowlist = 'trace-skia-allowlist';
  static const String traceSystrace = 'trace-systrace';
  static const String traceToFile = 'trace-to-file';
  static const String enableDartProfiling = 'enable-dart-profiling';
  static const String enableSoftwareRendering = 'enable-software-rendering';
  static const String skiaDeterministicRendering = 'skia-deterministic-rendering';
  static const String endlessTraceBuffer = 'endless-trace-buffer';
  static const String profileMicrotasks = 'profile-microtasks';
  static const String purgePersistentCache = 'purge-persistent-cache';
  static const String enableImpeller = 'enable-impeller';
  static const String enableVulkanValidation = 'enable-vulkan-validation';
  static const String enableFlutterGpu = 'enable-flutter-gpu';
  static const String enableHcpp = 'enable-hcpp';
  static const String testFlag = 'test-flag';
  static const String startPaused = 'start-paused';
  static const String disableServiceAuthCodes = 'disable-service-auth-codes';
  static const String disableServiceOriginCheck = 'disable-service-origin-check';
  static const String dartFlags = 'dart-flags';
  static const String useTestFonts = 'use-test-fonts';
  static const String verboseLogging = 'verbose-logging';
  static const String verboseSystemLogs = 'verbose-system-logs';

  static const List<String> allFlags = <String>[
    route,
    traceStartup,
    profileStartup,
    traceSkia,
    traceAllowlist,
    traceSkiaAllowlist,
    traceSystrace,
    traceToFile,
    enableDartProfiling,
    enableSoftwareRendering,
    skiaDeterministicRendering,
    endlessTraceBuffer,
    profileMicrotasks,
    purgePersistentCache,
    enableImpeller,
    enableVulkanValidation,
    enableFlutterGpu,
    enableHcpp,
    testFlag,
    startPaused,
    disableServiceAuthCodes,
    disableServiceOriginCheck,
    dartFlags,
    useTestFonts,
    verboseSystemLogs,
  ];
}
