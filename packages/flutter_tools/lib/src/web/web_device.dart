// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:process/process.dart';

import '../application_package.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../base/version.dart';
import '../build_info.dart';
import '../build_system/tools/shader_compiler.dart';
import '../compile.dart';
import '../context/tool_context.dart';
import '../context/web_context.dart';
import '../device.dart';
import '../device_port_forwarder.dart';
import '../features.dart';
import '../project.dart';
import '../resident_runner.dart';
import 'chrome.dart';
import 'web_debug_config.dart';
import 'web_flutter_device.dart';

class WebApplicationPackage extends ApplicationPackage {
  WebApplicationPackage(this.flutterProject) : super(id: flutterProject.manifest.appName);

  final FlutterProject flutterProject;

  @override
  String get name => flutterProject.manifest.appName;

  /// The location of the web source assets.
  Directory get webSourcePath => flutterProject.directory.childDirectory('web');
}

abstract class WebDevice extends Device {
  WebDevice(super.id, {required super.logger, this._webFlutterDeviceFactory})
    : super(category: Category.web, platformType: PlatformType.web, ephemeral: false);

  final WebFlutterDeviceFactory? _webFlutterDeviceFactory;

  @override
  Uri? get devToolsUri => _devToolsUri;
  Uri? _devToolsUri;

  set devToolsUri(Uri? uri) => _devToolsUri = uri;

  @override
  Future<CpuArch> get cpuArch async => CpuArch.unknown;

  @override
  Future<FlutterDevice> createFlutterDevice({
    required BuildInfo buildInfo,
    required ToolContext toolContext,
    DebuggingOptions? debuggingOptions,
    FlutterProject? flutterProject,
    Map<String, Object?> platformArgs = const <String, Object?>{},
    TargetModel? targetModelOverride,
    String? userIdentifier,
  }) async {
    if (_webFlutterDeviceFactory == null) {
      throw StateError('webFlutterDeviceFactory is required for web devices.');
    }
    if (flutterProject == null) {
      throw StateError('flutterProject is required when webFlutterDeviceFactory is provided.');
    }
    final WebDebugConfig webConfig = debuggingOptions?.webConfig ?? const WebDebugConfig();
    final (
      :DevelopmentShaderCompiler developmentShaderCompiler,
      :ResidentCompiler? generator,
      :TargetPlatform targetPlatform,
    ) = await FlutterDevice.createCompilers(
      this,
      buildInfo: buildInfo,
      createGenerator: buildInfo.isDebug && !webConfig.useWasm,
      targetModelOverride: targetModelOverride,
      toolContext: toolContext,
    );
    return _webFlutterDeviceFactory.createWebFlutterDevice(
      this,
      buildInfo: buildInfo,
      developmentShaderCompiler: developmentShaderCompiler,
      flutterProject: flutterProject,
      generator: generator,
      platformArgs: platformArgs,
      targetPlatform: targetPlatform,
      toolContext: toolContext,
      userIdentifier: userIdentifier,
      webConfig: webConfig,
    );
  }
}

/// A web device that supports a chromium browser.
abstract class ChromiumDevice extends WebDevice {
  ChromiumDevice({
    required String name,
    required this.chromeLauncher,
    required this._fileSystem,
    required super.logger,
    super.webFlutterDeviceFactory,
  }) : _logger = logger,
       super(name);

  final ChromiumLauncher chromeLauncher;

  final FileSystem _fileSystem;
  final Logger _logger;

  /// The active chrome instance.
  Chromium? _chrome;

  // This device does not actually support hot reload, but the current implementation of the resident runner
  // requires both supportsHotReload and supportsHotRestart to be true in order to allow hot restart.
  @override
  bool get supportsHotReload => true;

  @override
  bool get supportsHotRestart => true;

  @override
  bool get supportsStartPaused => true;

  @override
  bool get supportsFlutterExit => false;

  @override
  bool get supportsScreenshot => false;

  @override
  bool supportsRuntimeMode(BuildMode buildMode) => buildMode != BuildMode.jitRelease;

  @override
  void clearLogs() {}

  DeviceLogReader? _logReader;

  @override
  DeviceLogReader getLogReader({ApplicationPackage? app, bool includePastLogs = false}) {
    return _logReader ??= NoOpDeviceLogReader(app?.name);
  }

  @override
  Future<bool> installApp(ApplicationPackage app, {String? userIdentifier}) async => true;

  @override
  Future<bool> isAppInstalled(ApplicationPackage app, {String? userIdentifier}) async => true;

  @override
  Future<bool> isLatestBuildInstalled(ApplicationPackage app) async => true;

  @override
  Future<bool> get isLocalEmulator async => false;

  @override
  Future<String?> get emulatorId async => null;

  @override
  Future<bool> isSupported() async => chromeLauncher.canFindExecutable();

  @override
  DevicePortForwarder? get portForwarder => const NoOpDevicePortForwarder();

  @override
  Future<LaunchResult> startApp(
    ApplicationPackage? package, {
    String? mainPath,
    String? route,
    required DebuggingOptions debuggingOptions,
    Map<String, Object?> platformArgs = const <String, Object?>{},
    bool prebuiltApplication = false,
    String? userIdentifier,
  }) async {
    // See [WebFlutterDevice] in flutter_tools/lib/src/isolated/web_flutter_device.dart
    // for the web initialization and server logic.
    final WebDebugConfig(
      :String? launchUrl,
      :bool runHeadless,
      :int? browserDebugPort,
      :List<String> browserFlags,
    ) = debuggingOptions.webConfig;
    String url;
    if (launchUrl != null) {
      if (_isLaunchUrlValid(launchUrl)) {
        url = launchUrl;
      } else {
        throwToolExit('"$launchUrl" is not a valid HTTP URL.');
      }
    } else {
      url = platformArgs['uri']! as String;
    }
    final launchChrome = platformArgs['no-launch-chrome'] != true;
    if (launchChrome) {
      _chrome = await chromeLauncher.launch(
        url,
        cacheDir: _fileSystem.currentDirectory
            .childDirectory('.dart_tool')
            .childDirectory('chrome-device'),
        headless: runHeadless,
        debugPort: browserDebugPort,
        webBrowserFlags: browserFlags,
      );
    }
    _logger.sendEvent('app.webLaunchUrl', <String, Object>{'url': url, 'launched': launchChrome});
    return LaunchResult.succeeded(vmServiceUri: Uri.parse(url));
  }

  bool _isLaunchUrlValid(String url) {
    final pattern = RegExp(r'^(https?:\/\/)[^\s]+');
    return pattern.hasMatch(url);
  }

  @override
  Future<bool> stopApp(ApplicationPackage? app, {String? userIdentifier}) async {
    final Future<void>? future = _chrome?.close();
    _chrome = null;
    await future;
    return true;
  }

  @override
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.web_javascript;

  @override
  Future<bool> uninstallApp(ApplicationPackage app, {String? userIdentifier}) async => true;

  @override
  bool isSupportedForProject(FlutterProject flutterProject) {
    return flutterProject.web.existsSync();
  }

  @override
  Future<void> dispose() async {
    await Future.wait(<Future<void>>[?_logReader?.dispose(), ?portForwarder?.dispose()]);
  }
}

/// The Google Chrome browser based on Chromium.
class GoogleChromeDevice extends ChromiumDevice {
  GoogleChromeDevice({
    required this._platform,
    required this._processManager,
    required ChromiumLauncher chromiumLauncher,
    required super.logger,
    required super.fileSystem,
    super.webFlutterDeviceFactory,
  }) : super(name: 'chrome', chromeLauncher: chromiumLauncher);

  final Platform _platform;
  final ProcessManager _processManager;

  static const kChromeDeviceId = 'chrome';
  static const kChromeDeviceName = 'Chrome';

  @override
  String get name => kChromeDeviceName;

  @override
  late final Future<String> sdkNameAndVersion = _computeSdkNameAndVersion();

  Future<String> _computeSdkNameAndVersion() async {
    if (!await isSupported()) {
      return 'unknown';
    }
    // See https://bugs.chromium.org/p/chromium/issues/detail?id=158372
    var version = 'unknown';
    if (_platform.isWindows) {
      if (_processManager.canRun('reg')) {
        final ProcessResult result = await _processManager.run(<String>[
          r'reg',
          'query',
          r'HKEY_CURRENT_USER\Software\Google\Chrome\BLBeacon',
          '/v',
          'version',
        ]);
        if (result.exitCode == 0) {
          final List<String> parts = (result.stdout as String).split(RegExp(r'\s+'));
          if (parts.length > 2) {
            version = 'Google Chrome ${parts[parts.length - 2]}';
          }
        }
      }
    } else {
      final String chrome = chromeLauncher.findExecutable();
      final ProcessResult result = await _processManager.run(<String>[chrome, '--version']);
      if (result.exitCode == 0) {
        version = result.stdout as String;
      }
    }
    return version.trim();
  }
}

/// The Microsoft Edge browser based on Chromium.
class MicrosoftEdgeDevice extends ChromiumDevice {
  MicrosoftEdgeDevice({
    required ChromiumLauncher chromiumLauncher,
    required super.logger,
    required super.fileSystem,
    required this._processManager,
    super.webFlutterDeviceFactory,
  }) : super(name: 'edge', chromeLauncher: chromiumLauncher);

  final ProcessManager _processManager;

  // The first version of Edge with chromium support.
  static const _kFirstChromiumEdgeMajorVersion = 79;

  static const kEdgeDeviceId = 'edge';
  static const kEdgeDeviceName = 'Edge';

  @override
  String get name => kEdgeDeviceName;

  Future<bool> _meetsVersionConstraint() async {
    final String rawVersion = (await sdkNameAndVersion).replaceFirst('Microsoft Edge ', '');
    final Version? version = Version.parse(rawVersion);
    if (version == null) {
      return false;
    }
    return version.major >= _kFirstChromiumEdgeMajorVersion;
  }

  @override
  late final Future<String> sdkNameAndVersion = _getSdkNameAndVersion();

  Future<String> _getSdkNameAndVersion() async {
    if (_processManager.canRun('reg')) {
      final ProcessResult result = await _processManager.run(<String>[
        r'reg',
        'query',
        r'HKEY_CURRENT_USER\Software\Microsoft\Edge\BLBeacon',
        '/v',
        'version',
      ]);
      if (result.exitCode == 0) {
        final List<String> parts = (result.stdout as String).split(RegExp(r'\s+'));
        if (parts.length > 2) {
          return 'Microsoft Edge ${parts[parts.length - 2]}';
        }
      }
    }
    // Return a non-null string so that the tool can validate the version
    // does not meet the constraint above in _meetsVersionConstraint.
    return '';
  }
}

class WebDevices extends PollingDeviceDiscovery {
  WebDevices({
    required this._featureFlags,
    required this._fileSystem,
    required this._logger,
    required this._platform,
    required this._processManager,
    required this._webContext,
  }) : super(GoogleChromeDevice.kChromeDeviceName);

  final FeatureFlags _featureFlags;
  final FileSystem _fileSystem;
  final Logger _logger;
  final Platform _platform;
  final ProcessManager _processManager;
  final WebContext _webContext;

  late final GoogleChromeDevice _chromeDevice = GoogleChromeDevice(
    fileSystem: _fileSystem,
    logger: _logger,
    platform: _platform,
    processManager: _processManager,
    chromiumLauncher: _webContext.chromiumLauncher,
    webFlutterDeviceFactory: _webContext.webFlutterDeviceFactory,
  );
  late final WebServerDevice _webServerDevice = WebServerDevice(
    logger: _logger,
    webFlutterDeviceFactory: _webContext.webFlutterDeviceFactory,
  );
  late final MicrosoftEdgeDevice? _edgeDevice = _platform.isWindows
      ? MicrosoftEdgeDevice(
          chromiumLauncher: ChromiumLauncher(
            browserFinder: findEdgeExecutable,
            fileSystem: _fileSystem,
            platform: _platform,
            processManager: _processManager,
            operatingSystemUtils: OperatingSystemUtils(
              fileSystem: _fileSystem,
              platform: _platform,
              logger: _logger,
              processManager: _processManager,
            ),
            logger: _logger,
          ),
          processManager: _processManager,
          logger: _logger,
          fileSystem: _fileSystem,
          webFlutterDeviceFactory: _webContext.webFlutterDeviceFactory,
        )
      : null;

  @override
  bool get canListAnything => _featureFlags.isWebEnabled;

  @override
  Future<List<Device>> pollingGetDevices({
    Duration? timeout,
    bool forWirelessDiscovery = false,
  }) async {
    if (!_featureFlags.isWebEnabled) {
      return <Device>[];
    }
    final MicrosoftEdgeDevice? edgeDevice = _edgeDevice;
    return <Device>[
      if (WebServerDevice.showWebServerDevice) _webServerDevice,
      if (await _chromeDevice.isSupported()) _chromeDevice,
      if (edgeDevice != null && await edgeDevice._meetsVersionConstraint()) edgeDevice,
    ];
  }

  @override
  bool get supportsPlatform => _featureFlags.isWebEnabled;

  @override
  List<String> get wellKnownIds => const <String>['chrome', 'web-server', 'edge'];
}

/// A special device type to allow serving for arbitrary browsers.
class WebServerDevice extends WebDevice {
  WebServerDevice({required super.logger, super.webFlutterDeviceFactory})
    : _logger = logger,
      super('web-server');

  static const kWebServerDeviceId = 'web-server';
  static bool showWebServerDevice = false;

  final Logger _logger;

  @override
  void clearLogs() {}

  @override
  Future<String?> get emulatorId async => null;

  DeviceLogReader? _logReader;

  @override
  DeviceLogReader getLogReader({ApplicationPackage? app, bool includePastLogs = false}) {
    return _logReader ??= NoOpDeviceLogReader(app?.name);
  }

  @override
  Future<bool> installApp(ApplicationPackage app, {String? userIdentifier}) async => true;

  @override
  Future<bool> isAppInstalled(ApplicationPackage app, {String? userIdentifier}) async => true;

  @override
  Future<bool> isLatestBuildInstalled(ApplicationPackage app) async => true;

  @override
  bool get supportsFlutterExit => false;

  @override
  bool supportsRuntimeMode(BuildMode buildMode) => buildMode != BuildMode.jitRelease;

  @override
  Future<bool> get isLocalEmulator async => false;

  @override
  Future<bool> isSupported() async => true;

  @override
  bool isSupportedForProject(FlutterProject flutterProject) {
    return flutterProject.web.existsSync();
  }

  @override
  String get name => 'Web Server';

  @override
  DevicePortForwarder? get portForwarder => const NoOpDevicePortForwarder();

  @override
  Future<String> get sdkNameAndVersion async => 'Flutter Tools';

  @override
  Future<LaunchResult> startApp(
    ApplicationPackage? package, {
    String? mainPath,
    String? route,
    required DebuggingOptions debuggingOptions,
    Map<String, Object?> platformArgs = const <String, Object?>{},
    bool prebuiltApplication = false,
    String? userIdentifier,
  }) async {
    final url = platformArgs['uri'] as String?;
    if (debuggingOptions.startPaused) {
      _logger.printStatus(
        'Waiting for connection from Dart debug extension at $url',
        emphasis: true,
      );
    } else {
      _logger.printStatus('$mainPath is being served at $url', emphasis: true);
    }
    _logger.printStatus(
      'The web-server device requires the Dart Debug Chrome extension for debugging. '
      'Consider using the Chrome or Edge devices for an improved development workflow.',
    );
    _logger.sendEvent('app.webLaunchUrl', <String, Object?>{'url': url, 'launched': false});
    return LaunchResult.succeeded(vmServiceUri: url != null ? Uri.parse(url) : null);
  }

  @override
  Future<bool> stopApp(ApplicationPackage? app, {String? userIdentifier}) async {
    return true;
  }

  @override
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.web_javascript;

  @override
  Future<bool> uninstallApp(ApplicationPackage app, {String? userIdentifier}) async {
    return true;
  }

  @override
  Future<void> dispose() async {
    await Future.wait(<Future<void>>[?_logReader?.dispose(), ?portForwarder?.dispose()]);
  }
}
