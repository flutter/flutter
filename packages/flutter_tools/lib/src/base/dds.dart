// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:browser_launcher/browser_launcher.dart';
import 'package:meta/meta.dart';

import '../build_info.dart';
import '../convert.dart';
import '../device.dart';
import '../resident_runner.dart';
import '../vmservice.dart';
import 'io.dart' as io;
import 'logger.dart';
import 'platform.dart' as p;

typedef DartDevelopmentServiceInstance = ({
  io.Process? process,
  Uri? serviceUri,
  Uri? devToolsUri,
  Uri? dtdUri,
});

Future<DartDevelopmentServiceInstance> defaultStartDartDevelopmentService(
  Uri remoteVmServiceUri, {
  required bool enableAuthCodes,
  required bool ipv6,
  required bool enableDevTools,
  required List<String> cachedUserTags,
  Uri? serviceUri,
  String? google3WorkspaceRoot,
}) async {
  final String exe = const p.LocalPlatform().resolvedExecutable;
  final io.Process process = await io.Process.start(
    exe,
    <String>[
      'development-service',
      '--vm-service-uri=$remoteVmServiceUri',
      if (serviceUri != null) ...<String>[
        '--bind-address=${serviceUri.host}',
        '--bind-port=${serviceUri.port}',
      ],
      if (!enableAuthCodes) '--disable-service-auth-codes',
      if (enableDevTools) '--serve-devtools',
      if (google3WorkspaceRoot != null) '--google3-workspace-root=$google3WorkspaceRoot',
      for (final String tag in cachedUserTags)
        '--cached-user-tags=$tag',
    ],
  );
  final Completer<DartDevelopmentServiceInstance> completer =
      Completer<DartDevelopmentServiceInstance>();
  late StreamSubscription<String> stderrSub;
  stderrSub = process.stderr.transform(utf8.decoder).listen((String event) {
    final Map<String, dynamic> result =
        json.decode(event) as Map<String, dynamic>;
    if (result
        case {
          'state': 'started',
          'ddsUri': final String ddsUriStr,
          'devToolsUri': final String? devToolsUriStr,
          'dtd': final Map<String, Object?>? dtdInfo,
        }) {
      final Uri ddsUri = Uri.parse(ddsUriStr);
      final Uri? devToolsUri =
          devToolsUriStr == null ? null : Uri.parse(devToolsUriStr);
      final String? dtdUriStr = dtdInfo?['uri'] as String?;
      final Uri? dtdUri = dtdUriStr == null ? null : Uri.parse(dtdUriStr);

      completer.complete((
        process: process,
        serviceUri: ddsUri,
        devToolsUri: devToolsUri,
        dtdUri: dtdUri,
      ));
    } else if (result
        case {
          'state': 'error',
          'error': final String? error,
          'ddsExceptionDetails': final Map<String, Object?>? exceptionDetails,
        }) {
      completer.completeError(
        exceptionDetails != null
            ? DartDevelopmentServiceException.fromJson(exceptionDetails)
            : StateError(error ?? event),
      );
    } else {
      throw StateError('Unexpected result from DDS: $result');
    }
    stderrSub.cancel();
  });
  return completer.future;
}

typedef DDSLauncherCallback = Future<DartDevelopmentServiceInstance> Function(
  Uri remoteVmServiceUri, {
  required bool enableAuthCodes,
  required bool ipv6,
  required bool enableDevTools,
  required List<String> cachedUserTags,
  Uri? serviceUri,
  String? google3WorkspaceRoot,
});

// TODO(fujino): This should be direct injected, rather than mutable global state.
@visibleForTesting
DDSLauncherCallback ddsLauncherCallback = defaultStartDartDevelopmentService;

class DartDevelopmentServiceException implements Exception {
  factory DartDevelopmentServiceException.fromJson(Map<String, Object?> json) {
    if (json
        case {
          'ddsExceptionDetails': {
            'error_code': final int errorCode,
            'message': final String message,
            'uri': final String? uri
          }
        }) {
      return switch (errorCode) {
        existingDdsInstanceError =>
          DartDevelopmentServiceException.existingDdsInstance(
            message,
            ddsUri: Uri.parse(uri!),
          ),
        failedToStartError => DartDevelopmentServiceException.failedToStart(),
        connectionError =>
          DartDevelopmentServiceException.connectionIssue(message),
        _ => throw StateError(
            'Invalid DartDevelopmentServiceException error_code: $errorCode',
          ),
      };
    }
    throw StateError('Invalid DartDevelopmentServiceException JSON: $json');
  }

  factory DartDevelopmentServiceException.existingDdsInstance(
    String message, {
    Uri? ddsUri,
  }) {
    return ExistingDartDevelopmentServiceException._(
      message,
      ddsUri: ddsUri,
    );
  }

  factory DartDevelopmentServiceException.failedToStart() {
    return DartDevelopmentServiceException._(
      failedToStartError,
      'Failed to start Dart Development Service',
    );
  }

  factory DartDevelopmentServiceException.connectionIssue(String message) {
    return DartDevelopmentServiceException._(connectionError, message);
  }

  DartDevelopmentServiceException._(this.errorCode, this.message);

  /// Set when `DartDeveloperService.startDartDevelopmentService` is called and
  /// the target VM service already has a Dart Developer Service instance
  /// connected.
  static const int existingDdsInstanceError = 1;

  /// Set when the connection to the remote VM service terminates unexpectedly
  /// during Dart Development Service startup.
  static const int failedToStartError = 2;

  /// Set when a connection error has occurred after startup.
  static const int connectionError = 3;

  @override
  String toString() => 'DartDevelopmentServiceException: $message';

  final int errorCode;
  final String message;
}

class ExistingDartDevelopmentServiceException
    extends DartDevelopmentServiceException {
  ExistingDartDevelopmentServiceException._(
    String message, {
    this.ddsUri,
  }) : super._(
          DartDevelopmentServiceException.existingDdsInstanceError,
          message,
        );

  /// The URI of the existing DDS instance, if available.
  ///
  /// This URL is the base HTTP URI such as `http://127.0.0.1:1234/AbcDefg=/`,
  /// not the WebSocket URI (which can be obtained by mapping the scheme to
  /// `ws` (or `wss`) and appending `ws` to the path segments).
  final Uri? ddsUri;
}

/// Helper class to launch a [dds.DartDevelopmentService]. Allows for us to
/// mock out this functionality for testing purposes.
class DartDevelopmentService with DartDevelopmentServiceLocalOperationsMixin {
  DartDevelopmentService({required Logger logger}) : _logger = logger;

  DartDevelopmentServiceInstance? _ddsInstance;

  Uri? get uri => _ddsInstance?.serviceUri ?? _existingDdsUri;
  Uri? _existingDdsUri;

  @override
  Uri? get devToolsUri => _ddsInstance?.devToolsUri;

  Uri? get dtdUri => _ddsInstance?.dtdUri;

  @override
  FlutterDevice? _device;

  Future<void> get done => _completer.future;
  final Completer<void> _completer = Completer<void>();

  @override
  final Logger _logger;

  @override
  Future<void> startDartDevelopmentService(
    Uri vmServiceUri, {
    FlutterDevice? device,
    int? ddsPort,
    bool? disableServiceAuthCodes,
    bool? ipv6,
    bool enableDevTools = true,
    bool cacheStartupProfile = false,
    String? google3WorkspaceRoot,
  }) async {
    assert(_ddsInstance == null);
    _device = device;
    final Uri ddsUri = Uri(
      scheme: 'http',
      host: ((ipv6 ?? false)
              ? io.InternetAddress.loopbackIPv6
              : io.InternetAddress.loopbackIPv4)
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
        vmServiceUri,
        serviceUri: ddsUri,
        enableAuthCodes: disableServiceAuthCodes != true,
        ipv6: ipv6 ?? false,
        enableDevTools: enableDevTools,
        // Enables caching of CPU samples collected during application startup.
        cachedUserTags: cacheStartupProfile
            ? const <String>['AppStartUp']
            : const <String>[],
        google3WorkspaceRoot: google3WorkspaceRoot,
      );
      final io.Process? process = _ddsInstance?.process;

      // Complete the future if the DDS process is null, which happens in
      // testing.
      if (process != null) {
        unawaited(process.exitCode.whenComplete(completeFuture));
      }

      await invokeServiceExtensions(device);
    } on DartDevelopmentServiceException catch (e) {
      _logger.printTrace('Warning: Failed to start DDS: ${e.message}');
      if (e is ExistingDartDevelopmentServiceException) {
        _existingDdsUri = e.ddsUri;
      } else {
        _logger.printError(
            'DDS has failed to start and there is not an existing DDS instance '
            'available to connect to. Please file an issue at https://github.com/flutter/flutter/issues '
            'with the following error message:\n\n ${e.message}.');
        // DDS was unable to start for an unknown reason. Raise a StateError
        // so it can be reported by the crash reporter.
        throw StateError(e.message);
      }
      completeFuture();
      rethrow;
    }
  }

  void shutdown() => _ddsInstance?.process?.kill();
}

mixin DartDevelopmentServiceLocalOperationsMixin {
  Uri? get devToolsUri;
  Logger get _logger;
  FlutterDevice? get _device;

  @visibleForTesting
  bool get calledLaunchDevToolsInBrowser => _calledLaunchDevToolsInBrowser;
  bool _calledLaunchDevToolsInBrowser = false;

  Future<void> startDartDevelopmentService(
    Uri vmServiceUri, {
    FlutterDevice? device,
    int? ddsPort,
    bool? disableServiceAuthCodes,
    bool? ipv6,
    bool enableDevTools = true,
    bool cacheStartupProfile = false,
    String? google3WorkspaceRoot,
  });

  Future<void> startDartDevelopmentServiceFromDebuggingOptions(
    Uri vmServiceUri, {
    required DebuggingOptions debuggingOptions,
    FlutterDevice? device,
  }) =>
      startDartDevelopmentService(
        vmServiceUri,
        device: device,
        ddsPort: debuggingOptions.ddsPort,
        disableServiceAuthCodes: debuggingOptions.disableServiceAuthCodes,
        ipv6: debuggingOptions.ipv6,
        enableDevTools: debuggingOptions.enableDevTools,
        cacheStartupProfile: debuggingOptions.cacheStartupProfile,
        google3WorkspaceRoot: debuggingOptions.google3WorkspaceRoot,
      );

  bool launchDevToolsInBrowser() {
    _calledLaunchDevToolsInBrowser = true;
    if (devToolsUri == null) {
      return false;
    }
    assert(devToolsUri != null);
    _logger.printStatus(
        'Launching Flutter DevTools for ${_device!.device!.name} at $devToolsUri');
    unawaited(Chrome.start(<String>[devToolsUri!.toString()]));
    return true;
  }

  Future<void> handleHotRestart(FlutterDevice? device) =>
      invokeServiceExtensions(device);

  Future<void> invokeServiceExtensions(FlutterDevice? device) async {
    await Future.wait(<Future<void>>[
      _maybeCallDevToolsUriServiceExtension(device),
      _callConnectedVmServiceUriExtension(device),
    ]);
  }

  Future<void> _maybeCallDevToolsUriServiceExtension(
    FlutterDevice? device,
  ) async {
    if (devToolsUri != null && device?.vmService != null) {
      await _callDevToolsUriExtension(device!);
    }
  }

  Future<void> _callDevToolsUriExtension(
    FlutterDevice device,
  ) async {
    try {
      await _invokeRpcOnFirstView(
        'ext.flutter.activeDevToolsServerAddress',
        device: device,
        params: <String, dynamic>{
          'value': devToolsUri.toString(),
        },
      );
    } on Exception catch (e) {
      _logger.printError(
        'Failed to set DevTools server address: $e. Deep links to'
        ' DevTools will not show in Flutter errors.',
      );
    }
  }

  Future<void> _callConnectedVmServiceUriExtension(
      FlutterDevice? device) async {
    if (device == null) {
      return;
    }
    // TODO(bkonyi): can this just be set from the local DDS URI?
    final Uri? uri =
        device.vmService!.httpAddress ?? device.vmService!.wsAddress;
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
    if (device.targetPlatform == TargetPlatform.web_javascript) {
      await device.vmService!.callMethodWrapper(
        method,
        args: params,
      );
      return;
    }
    final List<FlutterView> views = await device.vmService!.getFlutterViews();
    if (views.isEmpty) {
      return;
    }
    await device.vmService!.invokeFlutterExtensionRpcRaw(
      method,
      args: params,
      isolateId: views.first.uiIsolate!.id!,
    );
  }
}
