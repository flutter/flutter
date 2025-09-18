// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:browser_launcher/browser_launcher.dart';
import 'package:dds/dds.dart';
import 'package:dds/dds_launcher.dart';
import 'package:meta/meta.dart';

import '../artifacts.dart';
import '../build_info.dart';
import '../device.dart';
import '../globals.dart' as globals;
import '../resident_runner.dart';
import '../vmservice.dart';
import 'io.dart' as io;
import 'logger.dart';
import 'utils.dart';

export 'package:dds/dds.dart'
    show DartDevelopmentServiceException, ExistingDartDevelopmentServiceException;

typedef DDSLauncherCallback =
    Future<DartDevelopmentServiceLauncher> Function({
      required Uri remoteVmServiceUri,
      Uri? serviceUri,
      bool enableAuthCodes,
      bool serveDevTools,
      Uri? devToolsServerAddress,
      bool enableServicePortFallback,
      List<String> cachedUserTags,
      String? dartExecutable,
      String? google3WorkspaceRoot,
    });

// TODO(fujino): This should be direct injected, rather than mutable global state.
/// Used by tests to override the DDS spawn behavior for mocking purposes.
@visibleForTesting
DDSLauncherCallback ddsLauncherCallback = DartDevelopmentServiceLauncher.start;

/// Helper class to launch a [DartDevelopmentServiceLauncher]. Allows for us to
/// mock out this functionality for testing purposes.
class DartDevelopmentService with DartDevelopmentServiceLocalOperationsMixin {
  DartDevelopmentService({required Logger logger}) : _logger = logger;

  DartDevelopmentServiceLauncher? _ddsInstance;

  @override
  Uri? get uri => _ddsInstance?.uri ?? _existingDdsUri;
  Uri? _existingDdsUri;

  @override
  Uri? get devToolsUri => _ddsInstance?.devToolsUri;

  Uri? get dtdUri => _ddsInstance?.dtdUri;

  Future<void> get done => _completer.future;
  final _completer = Completer<void>();

  @override
  final Logger _logger;

  @override
  Future<void> startDartDevelopmentService(
    Uri vmServiceUri, {
    int? ddsPort,
    bool? disableServiceAuthCodes,
    bool? ipv6,
    bool enableDevTools = true,
    bool cacheStartupProfile = false,
    String? google3WorkspaceRoot,
    Uri? devToolsServerAddress,
  }) async {
    assert(_ddsInstance == null);
    final ddsUri = Uri(
      scheme: 'http',
      host: ((ipv6 ?? false) ? io.InternetAddress.loopbackIPv6 : io.InternetAddress.loopbackIPv4)
          .host,
      port: ddsPort ?? 0,
    );
    _logger.printTrace(
      'Launching a Dart Developer Service (DDS) instance at $ddsUri, '
      'connecting to VM service at $vmServiceUri.',
    );
    void completeFuture() {
      if (!_completer.isCompleted) {
        _completer.complete();
      }
    }

    try {
      _ddsInstance = await ddsLauncherCallback(
        remoteVmServiceUri: vmServiceUri,
        serviceUri: ddsUri,
        enableAuthCodes: disableServiceAuthCodes != true,
        // Enables caching of CPU samples collected during application startup.
        cachedUserTags: cacheStartupProfile ? const <String>['AppStartUp'] : const <String>[],
        serveDevTools: enableDevTools,
        devToolsServerAddress: devToolsServerAddress,
        google3WorkspaceRoot: google3WorkspaceRoot,
        dartExecutable: globals.artifacts!.getArtifactPath(Artifact.engineDartBinary),
      );
      unawaited(_ddsInstance!.done.whenComplete(completeFuture));
    } on DartDevelopmentServiceException catch (e) {
      _logger.printTrace('Warning: Failed to start DDS: ${e.message}');
      if (e is ExistingDartDevelopmentServiceException) {
        _existingDdsUri = e.ddsUri;
      }
      completeFuture();
      rethrow;
    }
  }

  void shutdown() => _ddsInstance?.shutdown();
}

/// Contains common functionality that can be used with any implementation of
/// [DartDevelopmentService].
mixin DartDevelopmentServiceLocalOperationsMixin {
  Uri? get uri;
  Uri? get devToolsUri;
  Logger get _logger;

  /// Used to confirm `launchDevToolsInBrowser` is called in tests.
  @visibleForTesting
  bool get calledLaunchDevToolsInBrowser => _calledLaunchDevToolsInBrowser;
  var _calledLaunchDevToolsInBrowser = false;

  Future<void> startDartDevelopmentService(
    Uri vmServiceUri, {
    int? ddsPort,
    bool? disableServiceAuthCodes,
    bool? ipv6,
    bool enableDevTools = true,
    bool cacheStartupProfile = false,
    String? google3WorkspaceRoot,
    Uri? devToolsServerAddress,
  });

  /// A convenience method used to create a [DartDevelopmentService] instance
  /// from a [DebuggingOptions] instance.
  Future<void> startDartDevelopmentServiceFromDebuggingOptions(
    Uri vmServiceUri, {
    required DebuggingOptions debuggingOptions,
  }) => startDartDevelopmentService(
    vmServiceUri,
    ddsPort: debuggingOptions.ddsPort,
    disableServiceAuthCodes: debuggingOptions.disableServiceAuthCodes,
    ipv6: debuggingOptions.ipv6,
    enableDevTools: debuggingOptions.enableDevTools,
    cacheStartupProfile: debuggingOptions.cacheStartupProfile,
    google3WorkspaceRoot: debuggingOptions.google3WorkspaceRoot,
    devToolsServerAddress: debuggingOptions.devToolsServerAddress,
  );

  /// Launches a DevTools instance connected to the DDS instance connected to
  /// [device] in Chrome.
  bool launchDevToolsInBrowser(FlutterDevice device) {
    _calledLaunchDevToolsInBrowser = true;
    if (devToolsUri == null) {
      return false;
    }
    assert(devToolsUri != null);
    _logger.printStatus('Launching Flutter DevTools for ${device.device!.name} at $devToolsUri');
    unawaited(Chrome.start(<String>[devToolsUri!.toString()]));
    return true;
  }

  /// Re-initializes Flutter framework service extension state after a hot
  /// restart.
  Future<void> handleHotRestart(FlutterDevice? device) => invokeServiceExtensions(device);

  /// Initializes Flutter framework service extension state related to DevTools
  /// and VM service connection information.
  Future<void> invokeServiceExtensions(FlutterDevice? device) async {
    await Future.wait(<Future<void>>[
      maybeCallDevToolsUriServiceExtension(device: device, uri: devToolsUri),
      _callConnectedVmServiceUriExtension(device),
    ]);
  }

  /// Returns null if the service extension cannot be found on the device.
  Future<bool> _waitForExtensionsForDevice(FlutterDevice flutterDevice, String extension) async {
    try {
      await flutterDevice.vmService?.findExtensionIsolate(extension);
      return true;
    } on VmServiceDisappearedException {
      _logger.printTrace(
        'The VM Service for ${flutterDevice.device} disappeared while trying to'
        ' find the $extension service extension. Skipping subsequent DevTools '
        'setup for this device.',
      );
      return false;
    }
  }

  /// Sets the DevTools URI in the Flutter framework, used for deep linking
  /// support.
  Future<void> maybeCallDevToolsUriServiceExtension({
    required FlutterDevice? device,
    required Uri? uri,
  }) async {
    if (uri != null && device?.vmService != null) {
      // We're only setting the URI pointing to where DevTools is being served from. Don't include
      // any query parameters, including those used to automatically connect to the application.
      if (uri.hasQuery) {
        uri = uri.withoutQueryParameters();
      }
      await _callDevToolsUriExtension(device!, uri);
    }
  }

  Future<void> _callDevToolsUriExtension(FlutterDevice device, Uri uri) async {
    try {
      await _invokeRpcOnFirstView(
        'ext.flutter.activeDevToolsServerAddress',
        device: device,
        params: <String, dynamic>{'value': uri.toString()},
      );
    } on Exception catch (e) {
      _logger.printError(
        'Failed to set DevTools server address: $e. Deep links to'
        ' DevTools will not show in Flutter errors.',
      );
    }
  }

  Future<void> _callConnectedVmServiceUriExtension(FlutterDevice? device) async {
    if (device == null || uri == null) {
      return;
    }
    try {
      await _invokeRpcOnFirstView(
        'ext.flutter.connectedVmServiceUri',
        device: device,
        params: <String, dynamic>{'value': uri.toString()},
      );
    } on Exception catch (e) {
      _logger.printError(e.toString());
      _logger.printError(
        'Failed to set vm service URI: $e. Deep links to DevTools'
        ' will not show in Flutter errors.',
      );
    }
  }

  Future<void> _invokeRpcOnFirstView(
    String method, {
    required FlutterDevice device,
    required Map<String, dynamic> params,
  }) async {
    if (!(await _waitForExtensionsForDevice(device, method))) {
      return;
    }
    if (device.targetPlatform == TargetPlatform.web_javascript) {
      await device.vmService!.callMethodWrapper(method, args: params);
      return;
    }
    final List<FlutterView> views = await device.vmService!.getFlutterViews();
    if (views.isEmpty) {
      return;
    }
    await device.vmService!.invokeFlutterExtensionRpcRaw(
      method,
      args: params,
      isolateId: views.first.uiIsolate!.id,
    );
  }
}
