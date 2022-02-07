// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';

import 'package:browser_launcher/browser_launcher.dart';
import 'package:meta/meta.dart';

import 'base/common.dart';
import 'base/logger.dart';
import 'build_info.dart';
import 'resident_runner.dart';
import 'vmservice.dart';

typedef ResidentDevtoolsHandlerFactory = ResidentDevtoolsHandler Function(DevtoolsLauncher, ResidentRunner, Logger);

ResidentDevtoolsHandler createDefaultHandler(DevtoolsLauncher launcher, ResidentRunner runner, Logger logger) {
  return FlutterResidentDevtoolsHandler(launcher, runner, logger);
}

/// Helper class to manage the life-cycle of devtools and its interaction with
/// the resident runner.
abstract class ResidentDevtoolsHandler {
  /// The current devtools server, or null if one is not running.
  DevToolsServerAddress get activeDevToolsServer;

  /// Whether it's ok to announce the [activeDevToolsServer].
  ///
  /// This should only return true once all the devices have been notified
  /// of the DevTools.
  bool get readyToAnnounce;

  Future<void> hotRestart(List<FlutterDevice> flutterDevices);

  Future<void> serveAndAnnounceDevTools({
    Uri devToolsServerAddress,
    @required List<FlutterDevice> flutterDevices,
  });

  bool launchDevToolsInBrowser({@required List<FlutterDevice> flutterDevices});

  Future<void> shutdown();
}

class FlutterResidentDevtoolsHandler implements ResidentDevtoolsHandler {
  FlutterResidentDevtoolsHandler(this._devToolsLauncher, this._residentRunner, this._logger);

  static const Duration launchInBrowserTimeout = Duration(seconds: 15);

  final DevtoolsLauncher _devToolsLauncher;
  final ResidentRunner _residentRunner;
  final Logger _logger;
  bool _shutdown = false;
  bool _served = false;

  @visibleForTesting
  bool launchedInBrowser = false;

  @override
  DevToolsServerAddress get activeDevToolsServer => _devToolsLauncher?.activeDevToolsServer;

  @override
  bool get readyToAnnounce => _readyToAnnounce;
  bool _readyToAnnounce = false;

  // This must be guaranteed not to return a Future that fails.
  @override
  Future<void> serveAndAnnounceDevTools({
    Uri devToolsServerAddress,
    @required List<FlutterDevice> flutterDevices,
  }) async {
    if (!_residentRunner.supportsServiceProtocol || _devToolsLauncher == null) {
      return;
    }
    if (devToolsServerAddress != null) {
      _devToolsLauncher.devToolsUrl = devToolsServerAddress;
    } else {
      await _devToolsLauncher.serve();
      _served = true;
    }
    await _devToolsLauncher.ready;
    // Do not attempt to print debugger list if the connection has failed.
    if (_devToolsLauncher.activeDevToolsServer == null) {
      return;
    }
    final List<FlutterDevice> devicesWithExtension = await _devicesWithExtensions(flutterDevices);
    await _maybeCallDevToolsUriServiceExtension(devicesWithExtension);
    await _callConnectedVmServiceUriExtension(devicesWithExtension);
    _readyToAnnounce = true;
    if (_residentRunner.reportedDebuggers) {
      // Since the DevTools only just became available, we haven't had a chance to
      // report their URLs yet. Do so now.
      _residentRunner.printDebuggerList(includeObservatory: false);
    }
  }

  // This must be guaranteed not to return a Future that fails.
  @override
  bool launchDevToolsInBrowser({@required List<FlutterDevice> flutterDevices}) {
    if (!_residentRunner.supportsServiceProtocol || _devToolsLauncher == null) {
      return false;
    }
    if (_devToolsLauncher.devToolsUrl == null) {
      _logger.startProgress('Waiting for Flutter DevTools to be served...');
      unawaited(_devToolsLauncher.ready.then((_) {
        _launchDevToolsForDevices(flutterDevices);
      }));
    } else {
      _launchDevToolsForDevices(flutterDevices);
    }
    return true;
  }

  void _launchDevToolsForDevices(List<FlutterDevice> flutterDevices) {
    assert(activeDevToolsServer != null);
    for (final FlutterDevice device in flutterDevices) {
      final String devToolsUrl = activeDevToolsServer.uri?.replace(
        queryParameters: <String, dynamic>{'uri': '${device.vmService.httpAddress}'},
      ).toString();
      _logger.printStatus('Launching Flutter DevTools for ${device.device.name} at $devToolsUrl');
      unawaited(Chrome.start(<String>[devToolsUrl]));
    }
    launchedInBrowser = true;
  }

  Future<void> _maybeCallDevToolsUriServiceExtension(
    List<FlutterDevice> flutterDevices,
  ) async {
    if (_devToolsLauncher?.activeDevToolsServer == null) {
      return;
    }
    await Future.wait(<Future<void>>[
      for (final FlutterDevice device in flutterDevices)
        if (device.vmService != null) _callDevToolsUriExtension(device),
    ]);
  }

  Future<void> _callDevToolsUriExtension(
    FlutterDevice device,
  ) async {
    try {
      await _invokeRpcOnFirstView(
        'ext.flutter.activeDevToolsServerAddress',
        device: device,
        params: <String, dynamic>{
          'value': _devToolsLauncher.activeDevToolsServer.uri.toString(),
        },
      );
    } on Exception catch (e) {
      _logger.printError(
        'Failed to set DevTools server address: ${e.toString()}. Deep links to'
        ' DevTools will not show in Flutter errors.',
      );
    }
  }

  Future<List<FlutterDevice>> _devicesWithExtensions(List<FlutterDevice> flutterDevices) async {
    final List<FlutterDevice> devices = await Future.wait(<Future<FlutterDevice>>[
      for (final FlutterDevice device in flutterDevices) _waitForExtensionsForDevice(device)
    ]);
    return devices.where((FlutterDevice device) => device != null).toList();
  }

  /// Returns null if the service extension cannot be found on the device.
  Future<FlutterDevice> _waitForExtensionsForDevice(FlutterDevice flutterDevice) async {
    const String extension = 'ext.flutter.connectedVmServiceUri';
    try {
      await flutterDevice.vmService?.findExtensionIsolate(
        extension,
      );
      return flutterDevice;
    } on VmServiceDisappearedException {
      _logger.printTrace(
        'The VM Service for ${flutterDevice.device} disappeared while trying to'
        ' find the $extension service extension. Skipping subsequent DevTools '
        'setup for this device.',
      );
      return null;
    }
  }

  Future<void> _callConnectedVmServiceUriExtension(List<FlutterDevice> flutterDevices) async {
    await Future.wait(<Future<void>>[
      for (final FlutterDevice device in flutterDevices)
        if (device.vmService != null) _callConnectedVmServiceExtension(device),
    ]);
  }

  Future<void> _callConnectedVmServiceExtension(FlutterDevice device) async {
    final Uri uri = device.vmService.httpAddress ?? device.vmService.wsAddress;
    if (uri == null) {
      return;
    }
    try {
      await _invokeRpcOnFirstView(
        'ext.flutter.connectedVmServiceUri',
        device: device,
        params: <String, dynamic>{
          'value': uri.toString(),
        },
      );
    } on Exception catch (e) {
      _logger.printError(e.toString());
      _logger.printError(
        'Failed to set vm service URI: ${e.toString()}. Deep links to DevTools'
        ' will not show in Flutter errors.',
      );
    }
  }

  Future<void> _invokeRpcOnFirstView(
    String method, {
    @required FlutterDevice device,
    @required Map<String, dynamic> params,
  }) async {
    if (device.targetPlatform == TargetPlatform.web_javascript) {
      return device.vmService.callMethodWrapper(
        method,
        args: params,
      );
    }
    final List<FlutterView> views = await device.vmService.getFlutterViews();
    if (views.isEmpty) {
      return;
    }
    await device.vmService.invokeFlutterExtensionRpcRaw(
      method,
      args: params,
      isolateId: views.first.uiIsolate.id,
    );
  }

  @override
  Future<void> hotRestart(List<FlutterDevice> flutterDevices) async {
    final List<FlutterDevice> devicesWithExtension = await _devicesWithExtensions(flutterDevices);
    await Future.wait(<Future<void>>[
      _maybeCallDevToolsUriServiceExtension(devicesWithExtension),
      _callConnectedVmServiceUriExtension(devicesWithExtension),
    ]);
  }

  @override
  Future<void> shutdown() async {
    if (_devToolsLauncher == null || _shutdown || !_served) {
      return;
    }
    _shutdown = true;
    await _devToolsLauncher.close();
  }
}

@visibleForTesting
NoOpDevtoolsHandler createNoOpHandler(DevtoolsLauncher launcher, ResidentRunner runner, Logger logger) {
  return NoOpDevtoolsHandler();
}

@visibleForTesting
class NoOpDevtoolsHandler implements ResidentDevtoolsHandler {
  bool wasShutdown = false;

  @override
  DevToolsServerAddress get activeDevToolsServer => null;

  @override
  bool get readyToAnnounce => false;

  @override
  Future<void> hotRestart(List<FlutterDevice> flutterDevices) async {
    return;
  }

  @override
  Future<void> serveAndAnnounceDevTools({Uri devToolsServerAddress, List<FlutterDevice> flutterDevices}) async {
    return;
  }

  @override
  bool launchDevToolsInBrowser({List<FlutterDevice> flutterDevices}) {
    return false;
  }

  @override
  Future<void> shutdown() async {
    wasShutdown = true;
    return;
  }
}

/// Convert a [URI] with query parameters into a display format instead
/// of the default URI encoding.
String urlToDisplayString(Uri uri) {
  final StringBuffer base = StringBuffer(uri.replace(
    queryParameters: <String, String>{},
  ).toString());
  base.write(uri.queryParameters.keys.map((String key) => '$key=${uri.queryParameters[key]}').join('&'));
  return base.toString();
}
