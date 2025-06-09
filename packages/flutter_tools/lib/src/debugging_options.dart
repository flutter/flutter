// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import 'build_info.dart' show BuildInfo, EnvironmentType;
import 'web/compile.dart' show WebRendererMode;

enum ImpellerStatus {
  platformDefault._(null),
  enabled._(true),
  disabled._(false);

  const ImpellerStatus._(this.asBool);

  factory ImpellerStatus.fromBool(bool? b) => switch (b) {
    true => enabled,
    false => disabled,
    null => platformDefault,
  };

  final bool? asBool;
}

/// How a device is connected.
enum DeviceConnectionInterface { attached, wireless }

@immutable
class DebuggingOptions {
  DebuggingOptions.enabled(
    this.buildInfo, {
    this.startPaused = false,
    this.disableServiceAuthCodes = false,
    this.enableDds = true,
    this.cacheStartupProfile = false,
    this.dartEntrypointArgs = const <String>[],
    this.dartFlags = '',
    this.enableSoftwareRendering = false,
    this.skiaDeterministicRendering = false,
    this.traceSkia = false,
    this.traceAllowlist,
    this.traceSkiaAllowlist,
    this.traceSystrace = false,
    this.traceToFile,
    this.endlessTraceBuffer = false,
    this.purgePersistentCache = false,
    this.useTestFonts = false,
    this.verboseSystemLogs = false,
    this.hostVmServicePort,
    this.disablePortPublication = false,
    this.deviceVmServicePort,
    this.ddsPort,
    this.devToolsServerAddress,
    this.hostname,
    this.port,
    this.tlsCertPath,
    this.tlsCertKeyPath,
    this.webEnableExposeUrl,
    this.webUseSseForDebugProxy = true,
    this.webUseSseForDebugBackend = true,
    this.webUseSseForInjectedClient = true,
    this.webRunHeadless = false,
    this.webBrowserDebugPort,
    this.webBrowserFlags = const <String>[],
    this.webEnableExpressionEvaluation = false,
    this.webHeaders = const <String, String>{},
    this.webLaunchUrl,
    WebRendererMode? webRenderer,
    this.webUseWasm = false,
    this.vmserviceOutFile,
    this.fastStart = false,
    this.nativeNullAssertions = false,
    this.enableImpeller = ImpellerStatus.platformDefault,
    this.enableVulkanValidation = false,
    this.uninstallFirst = false,
    this.enableDartProfiling = true,
    this.enableEmbedderApi = false,
    this.usingCISystem = false,
    this.debugLogsDirectoryPath,
    this.enableDevTools = true,
    this.ipv6 = false,
    this.google3WorkspaceRoot,
    this.printDtd = false,
  }) : debuggingEnabled = true,
       webRenderer = webRenderer ?? WebRendererMode.getDefault(useWasm: webUseWasm);

  DebuggingOptions.disabled(
    this.buildInfo, {
    this.dartEntrypointArgs = const <String>[],
    this.port,
    this.hostname,
    this.tlsCertPath,
    this.tlsCertKeyPath,
    this.webEnableExposeUrl,
    this.webUseSseForDebugProxy = true,
    this.webUseSseForDebugBackend = true,
    this.webUseSseForInjectedClient = true,
    this.webRunHeadless = false,
    this.webBrowserDebugPort,
    this.webBrowserFlags = const <String>[],
    this.webLaunchUrl,
    this.webHeaders = const <String, String>{},
    WebRendererMode? webRenderer,
    this.webUseWasm = false,
    this.traceAllowlist,
    this.enableImpeller = ImpellerStatus.platformDefault,
    this.enableVulkanValidation = false,
    this.uninstallFirst = false,
    this.enableDartProfiling = true,
    this.enableEmbedderApi = false,
    this.usingCISystem = false,
    this.debugLogsDirectoryPath,
  }) : debuggingEnabled = false,
       useTestFonts = false,
       startPaused = false,
       dartFlags = '',
       disableServiceAuthCodes = false,
       enableDds = false,
       cacheStartupProfile = false,
       enableSoftwareRendering = false,
       skiaDeterministicRendering = false,
       traceSkia = false,
       traceSkiaAllowlist = null,
       traceSystrace = false,
       traceToFile = null,
       endlessTraceBuffer = false,
       purgePersistentCache = false,
       verboseSystemLogs = false,
       hostVmServicePort = null,
       disablePortPublication = false,
       deviceVmServicePort = null,
       ddsPort = null,
       devToolsServerAddress = null,
       vmserviceOutFile = null,
       fastStart = false,
       webEnableExpressionEvaluation = false,
       nativeNullAssertions = false,
       enableDevTools = false,
       ipv6 = false,
       google3WorkspaceRoot = null,
       printDtd = false,
       webRenderer = webRenderer ?? WebRendererMode.getDefault(useWasm: webUseWasm);

  const DebuggingOptions._({
    required this.buildInfo,
    required this.debuggingEnabled,
    required this.startPaused,
    required this.dartFlags,
    required this.dartEntrypointArgs,
    required this.disableServiceAuthCodes,
    required this.enableDds,
    required this.cacheStartupProfile,
    required this.enableSoftwareRendering,
    required this.skiaDeterministicRendering,
    required this.traceSkia,
    required this.traceAllowlist,
    required this.traceSkiaAllowlist,
    required this.traceSystrace,
    required this.traceToFile,
    required this.endlessTraceBuffer,
    required this.purgePersistentCache,
    required this.useTestFonts,
    required this.verboseSystemLogs,
    required this.hostVmServicePort,
    required this.deviceVmServicePort,
    required this.disablePortPublication,
    required this.ddsPort,
    required this.devToolsServerAddress,
    required this.port,
    required this.hostname,
    required this.tlsCertPath,
    required this.tlsCertKeyPath,
    required this.webEnableExposeUrl,
    required this.webUseSseForDebugProxy,
    required this.webUseSseForDebugBackend,
    required this.webUseSseForInjectedClient,
    required this.webRunHeadless,
    required this.webBrowserDebugPort,
    required this.webBrowserFlags,
    required this.webEnableExpressionEvaluation,
    required this.webHeaders,
    required this.webLaunchUrl,
    required this.webRenderer,
    required this.webUseWasm,
    required this.vmserviceOutFile,
    required this.fastStart,
    required this.nativeNullAssertions,
    required this.enableImpeller,
    required this.enableVulkanValidation,
    required this.uninstallFirst,
    required this.enableDartProfiling,
    required this.enableEmbedderApi,
    required this.usingCISystem,
    required this.debugLogsDirectoryPath,
    required this.enableDevTools,
    required this.ipv6,
    required this.google3WorkspaceRoot,
    required this.printDtd,
  });

  final bool debuggingEnabled;

  final BuildInfo buildInfo;
  final bool startPaused;
  final String dartFlags;
  final List<String> dartEntrypointArgs;
  final bool disableServiceAuthCodes;
  final bool enableDds;
  final bool cacheStartupProfile;
  final bool enableSoftwareRendering;
  final bool skiaDeterministicRendering;
  final bool traceSkia;
  final String? traceAllowlist;
  final String? traceSkiaAllowlist;
  final bool traceSystrace;
  final String? traceToFile;
  final bool endlessTraceBuffer;
  final bool purgePersistentCache;
  final bool useTestFonts;
  final bool verboseSystemLogs;
  final int? hostVmServicePort;
  final int? deviceVmServicePort;
  final bool disablePortPublication;
  final int? ddsPort;
  final Uri? devToolsServerAddress;
  final String? port;
  final String? hostname;
  final String? tlsCertPath;
  final String? tlsCertKeyPath;
  final bool? webEnableExposeUrl;
  final bool webUseSseForDebugProxy;
  final bool webUseSseForDebugBackend;
  final bool webUseSseForInjectedClient;
  final ImpellerStatus enableImpeller;
  final bool enableVulkanValidation;
  final bool enableDartProfiling;
  final bool enableEmbedderApi;
  final bool usingCISystem;
  final String? debugLogsDirectoryPath;
  final bool enableDevTools;
  final bool ipv6;
  final String? google3WorkspaceRoot;
  final bool printDtd;

  /// Whether the tool should try to uninstall a previously installed version of the app.
  ///
  /// This is not implemented for every platform.
  final bool uninstallFirst;

  /// Whether to run the browser in headless mode.
  ///
  /// Some CI environments do not provide a display and fail to launch the
  /// browser with full graphics stack. Some browsers provide a special
  /// "headless" mode that runs the browser with no graphics.
  final bool webRunHeadless;

  /// The port the browser should use for its debugging protocol.
  final int? webBrowserDebugPort;

  /// Arbitrary browser flags.
  final List<String> webBrowserFlags;

  /// Enable expression evaluation for web target.
  final bool webEnableExpressionEvaluation;

  /// Allow developers to customize the browser's launch URL
  final String? webLaunchUrl;

  /// Allow developers to add custom headers to web server
  final Map<String, String> webHeaders;

  /// Which web renderer to use for the debugging session
  final WebRendererMode webRenderer;

  /// Whether to compile to webassembly
  final bool webUseWasm;

  /// A file where the VM Service URL should be written after the application is started.
  final String? vmserviceOutFile;
  final bool fastStart;

  /// Additional null runtime checks inserted for web applications.
  ///
  /// See also:
  ///   * https://github.com/dart-lang/sdk/blob/main/sdk/lib/html/doc/NATIVE_NULL_ASSERTIONS.md
  final bool nativeNullAssertions;

  List<String> getIOSLaunchArguments(
    EnvironmentType environmentType,
    String? route,
    Map<String, Object?> platformArgs, {
    DeviceConnectionInterface interfaceType = DeviceConnectionInterface.attached,
    bool isCoreDevice = false,
  }) {
    return <String>[
      if (enableDartProfiling) '--enable-dart-profiling',
      if (disableServiceAuthCodes) '--disable-service-auth-codes',
      if (disablePortPublication) '--disable-vm-service-publication',
      if (startPaused) '--start-paused',
      // Wrap dart flags in quotes for physical devices
      if (environmentType == EnvironmentType.physical && dartFlags.isNotEmpty)
        '--dart-flags="$dartFlags"',
      if (environmentType == EnvironmentType.simulator && dartFlags.isNotEmpty)
        '--dart-flags=$dartFlags',
      if (useTestFonts) '--use-test-fonts',
      // Core Devices (iOS 17 devices) are debugged through Xcode so don't
      // include these flags, which are used to check if the app was launched
      // via Flutter CLI and `ios-deploy`.
      if (debuggingEnabled && !isCoreDevice) ...<String>[
        '--enable-checked-mode',
        '--verify-entry-points',
      ],
      if (enableSoftwareRendering) '--enable-software-rendering',
      if (traceSystrace) '--trace-systrace',
      if (traceToFile != null) '--trace-to-file="$traceToFile"',
      if (skiaDeterministicRendering) '--skia-deterministic-rendering',
      if (traceSkia) '--trace-skia',
      if (traceAllowlist != null) '--trace-allowlist="$traceAllowlist"',
      if (traceSkiaAllowlist != null) '--trace-skia-allowlist="$traceSkiaAllowlist"',
      if (endlessTraceBuffer) '--endless-trace-buffer',
      if (verboseSystemLogs) '--verbose-logging',
      if (purgePersistentCache) '--purge-persistent-cache',
      if (route != null) '--route=$route',
      if (platformArgs['trace-startup'] as bool? ?? false) '--trace-startup',
      if (enableImpeller == ImpellerStatus.enabled) '--enable-impeller=true',
      if (enableImpeller == ImpellerStatus.disabled) '--enable-impeller=false',
      if (environmentType == EnvironmentType.physical && deviceVmServicePort != null)
        '--vm-service-port=$deviceVmServicePort',
      // The simulator "device" is actually on the host machine so no ports will be forwarded.
      // Use the suggested host port.
      if (environmentType == EnvironmentType.simulator && hostVmServicePort != null)
        '--vm-service-port=$hostVmServicePort',
      // Tell the VM service to listen on all interfaces, don't restrict to the loopback.
      if (interfaceType == DeviceConnectionInterface.wireless)
        '--vm-service-host=${ipv6 ? '::0' : '0.0.0.0'}',
      if (enableEmbedderApi) '--enable-embedder-api',
    ];
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'debuggingEnabled': debuggingEnabled,
    'startPaused': startPaused,
    'dartFlags': dartFlags,
    'dartEntrypointArgs': dartEntrypointArgs,
    'disableServiceAuthCodes': disableServiceAuthCodes,
    'enableDds': enableDds,
    'cacheStartupProfile': cacheStartupProfile,
    'enableSoftwareRendering': enableSoftwareRendering,
    'skiaDeterministicRendering': skiaDeterministicRendering,
    'traceSkia': traceSkia,
    'traceAllowlist': traceAllowlist,
    'traceSkiaAllowlist': traceSkiaAllowlist,
    'traceSystrace': traceSystrace,
    'traceToFile': traceToFile,
    'endlessTraceBuffer': endlessTraceBuffer,
    'purgePersistentCache': purgePersistentCache,
    'useTestFonts': useTestFonts,
    'verboseSystemLogs': verboseSystemLogs,
    'hostVmServicePort': hostVmServicePort,
    'deviceVmServicePort': deviceVmServicePort,
    'disablePortPublication': disablePortPublication,
    'ddsPort': ddsPort,
    'devToolsServerAddress': devToolsServerAddress.toString(),
    'port': port,
    'hostname': hostname,
    'tlsCertPath': tlsCertPath,
    'tlsCertKeyPath': tlsCertKeyPath,
    'webEnableExposeUrl': webEnableExposeUrl,
    'webUseSseForDebugProxy': webUseSseForDebugProxy,
    'webUseSseForDebugBackend': webUseSseForDebugBackend,
    'webUseSseForInjectedClient': webUseSseForInjectedClient,
    'webRunHeadless': webRunHeadless,
    'webBrowserDebugPort': webBrowserDebugPort,
    'webBrowserFlags': webBrowserFlags,
    'webEnableExpressionEvaluation': webEnableExpressionEvaluation,
    'webLaunchUrl': webLaunchUrl,
    'webHeaders': webHeaders,
    'webRenderer': webRenderer.name,
    'webUseWasm': webUseWasm,
    'vmserviceOutFile': vmserviceOutFile,
    'fastStart': fastStart,
    'nativeNullAssertions': nativeNullAssertions,
    'enableImpeller': enableImpeller.asBool,
    'enableVulkanValidation': enableVulkanValidation,
    'enableDartProfiling': enableDartProfiling,
    'enableEmbedderApi': enableEmbedderApi,
    'usingCISystem': usingCISystem,
    'debugLogsDirectoryPath': debugLogsDirectoryPath,
    'enableDevTools': enableDevTools,
    'ipv6': ipv6,
    'google3WorkspaceRoot': google3WorkspaceRoot,
    'printDtd': printDtd,
    // TODO(jsimmons): This field is required for backward compatibility with
    // the flutter_tools binary that is currently checked into Google3.
    // Remove this when that binary has been updated.
    'webUseLocalCanvaskit': false,
    // See above: these fields are required for backwards compatibility
    // with the google3 checked in binary.
    'dumpSkpOnShaderCompilation': false,
    'cacheSkSL': false,
  };

  static DebuggingOptions fromJson(Map<String, Object?> json, BuildInfo buildInfo) =>
      DebuggingOptions._(
        buildInfo: buildInfo,
        debuggingEnabled: json['debuggingEnabled']! as bool,
        startPaused: json['startPaused']! as bool,
        dartFlags: json['dartFlags']! as String,
        dartEntrypointArgs: (json['dartEntrypointArgs']! as List<dynamic>).cast<String>(),
        disableServiceAuthCodes: json['disableServiceAuthCodes']! as bool,
        enableDds: json['enableDds']! as bool,
        cacheStartupProfile: json['cacheStartupProfile']! as bool,
        enableSoftwareRendering: json['enableSoftwareRendering']! as bool,
        skiaDeterministicRendering: json['skiaDeterministicRendering']! as bool,
        traceSkia: json['traceSkia']! as bool,
        traceAllowlist: json['traceAllowlist'] as String?,
        traceSkiaAllowlist: json['traceSkiaAllowlist'] as String?,
        traceSystrace: json['traceSystrace']! as bool,
        traceToFile: json['traceToFile'] as String?,
        endlessTraceBuffer: json['endlessTraceBuffer']! as bool,
        purgePersistentCache: json['purgePersistentCache']! as bool,
        useTestFonts: json['useTestFonts']! as bool,
        verboseSystemLogs: json['verboseSystemLogs']! as bool,
        hostVmServicePort: json['hostVmServicePort'] as int?,
        deviceVmServicePort: json['deviceVmServicePort'] as int?,
        disablePortPublication: json['disablePortPublication']! as bool,
        ddsPort: json['ddsPort'] as int?,
        devToolsServerAddress:
            json['devToolsServerAddress'] != null
                ? Uri.parse(json['devToolsServerAddress']! as String)
                : null,
        port: json['port'] as String?,
        hostname: json['hostname'] as String?,
        tlsCertPath: json['tlsCertPath'] as String?,
        tlsCertKeyPath: json['tlsCertKeyPath'] as String?,
        webEnableExposeUrl: json['webEnableExposeUrl'] as bool?,
        webUseSseForDebugProxy: json['webUseSseForDebugProxy']! as bool,
        webUseSseForDebugBackend: json['webUseSseForDebugBackend']! as bool,
        webUseSseForInjectedClient: json['webUseSseForInjectedClient']! as bool,
        webRunHeadless: json['webRunHeadless']! as bool,
        webBrowserDebugPort: json['webBrowserDebugPort'] as int?,
        webBrowserFlags: (json['webBrowserFlags']! as List<dynamic>).cast<String>(),
        webEnableExpressionEvaluation: json['webEnableExpressionEvaluation']! as bool,
        webHeaders: (json['webHeaders']! as Map<dynamic, dynamic>).cast<String, String>(),
        webLaunchUrl: json['webLaunchUrl'] as String?,
        webRenderer: WebRendererMode.values.byName(json['webRenderer']! as String),
        webUseWasm: json['webUseWasm']! as bool,
        vmserviceOutFile: json['vmserviceOutFile'] as String?,
        fastStart: json['fastStart']! as bool,
        nativeNullAssertions: json['nativeNullAssertions']! as bool,
        enableImpeller: ImpellerStatus.fromBool(json['enableImpeller'] as bool?),
        enableVulkanValidation: (json['enableVulkanValidation'] as bool?) ?? false,
        uninstallFirst: (json['uninstallFirst'] as bool?) ?? false,
        enableDartProfiling: (json['enableDartProfiling'] as bool?) ?? true,
        enableEmbedderApi: (json['enableEmbedderApi'] as bool?) ?? false,
        usingCISystem: (json['usingCISystem'] as bool?) ?? false,
        debugLogsDirectoryPath: json['debugLogsDirectoryPath'] as String?,
        enableDevTools: (json['enableDevTools'] as bool?) ?? true,
        ipv6: (json['ipv6'] as bool?) ?? false,
        google3WorkspaceRoot: json['google3WorkspaceRoot'] as String?,
        printDtd: (json['printDtd'] as bool?) ?? false,
      );
}
