// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../artifacts.dart';
import '../convert.dart';
import '../device.dart';
import '../globals.dart' as globals;
import 'io.dart' as io;
import 'logger.dart';

/// A representation of the current DDS state including:
///
/// - The process the external DDS instance is running in
/// - The service URI DDS is being served on
/// - The URI DevTools is being served on, if applicable
/// - The URI DTD is being served on, if applicable
typedef DartDevelopmentServiceInstance = ({
  io.Process? process,
  Uri? serviceUri,
  Uri? devToolsUri,
  Uri? dtdUri,
});

/// The default DDSLauncherCallback used to spawn DDS.
Future<DartDevelopmentServiceInstance> defaultStartDartDevelopmentService(
  Uri remoteVmServiceUri, {
  required bool enableAuthCodes,
  required bool ipv6,
  required bool enableDevTools,
  required List<String> cachedUserTags,
  Uri? serviceUri,
  String? google3WorkspaceRoot,
  Uri? devToolsServerAddress,
}) async {
  final String exe = globals.artifacts!.getArtifactPath(
    Artifact.engineDartBinary,
  );
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
      if (google3WorkspaceRoot != null)
        '--google3-workspace-root=$google3WorkspaceRoot',
      for (final String tag in cachedUserTags) '--cached-user-tags=$tag',
    ],
  );
  final Completer<DartDevelopmentServiceInstance> completer =
      Completer<DartDevelopmentServiceInstance>();
  late StreamSubscription<Object?> stderrSub;
  stderrSub = process.stderr
      .transform(utf8.decoder)
      .transform(json.decoder)
      .listen((Object? result) {
    if (result
        case {
          'state': 'started',
          'ddsUri': final String ddsUriStr,
        }) {
      final Uri ddsUri = Uri.parse(ddsUriStr);
      final String? devToolsUriStr = result['devToolsUri'] as String?;
      final Uri? devToolsUri =
          devToolsUriStr == null ? null : Uri.parse(devToolsUriStr);
      final String? dtdUriStr =
          (result['dtd'] as Map<String, Object?>?)?['uri'] as String?;
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
          'error': final String error,
        }) {
      final Map<String, Object?>? exceptionDetails =
          result['ddsExceptionDetails'] as Map<String, Object?>?;
      completer.completeError(
        exceptionDetails != null
            ? DartDevelopmentServiceException.fromJson(exceptionDetails)
            : StateError(error),
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
  Uri? devToolsServerAddress,
});

// TODO(fujino): This should be direct injected, rather than mutable global state.
/// Used by tests to override the DDS spawn behavior for mocking purposes.
@visibleForTesting
DDSLauncherCallback ddsLauncherCallback = defaultStartDartDevelopmentService;

/// Thrown by DDS during initialization failures, unexpected connection issues,
/// and when attempting to spawn DDS when an existing DDS instance exists.
class DartDevelopmentServiceException implements Exception {
  factory DartDevelopmentServiceException.fromJson(Map<String, Object?> json) {
    if (json
        case {
          'error_code': final int errorCode,
          'message': final String message,
          'uri': final String? uri
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

  /// Thrown when `DartDeveloperService.startDartDevelopmentService` is called
  /// and the target VM service already has a Dart Developer Service instance
  /// connected.
  factory DartDevelopmentServiceException.existingDdsInstance(
    String message, {
    Uri? ddsUri,
  }) {
    return ExistingDartDevelopmentServiceException._(
      message,
      ddsUri: ddsUri,
    );
  }

  /// Thrown when the connection to the remote VM service terminates unexpectedly
  /// during Dart Development Service startup.
  factory DartDevelopmentServiceException.failedToStart() {
    return DartDevelopmentServiceException._(
      failedToStartError,
      'Failed to start Dart Development Service',
    );
  }

  /// Thrown when a connection error has occurred after startup.
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

/// Thrown when attempting to start a new DDS instance when one already exists.
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
  /// This URI is the base HTTP URI such as `http://127.0.0.1:1234/AbcDefg=/`,
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

  Future<void> get done => _completer.future;
  final Completer<void> _completer = Completer<void>();

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
        devToolsServerAddress: devToolsServerAddress,
      );
      final io.Process? process = _ddsInstance?.process;

      // Complete the future if the DDS process is null, which happens in
      // testing.
      if (process != null) {
        unawaited(process.exitCode.whenComplete(completeFuture));
      }
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

/// Contains common functionality that can be used with any implementation of
/// [DartDevelopmentService].
mixin DartDevelopmentServiceLocalOperationsMixin {
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
  }) =>
      startDartDevelopmentService(
        vmServiceUri,
        ddsPort: debuggingOptions.ddsPort,
        disableServiceAuthCodes: debuggingOptions.disableServiceAuthCodes,
        ipv6: debuggingOptions.ipv6,
        enableDevTools: debuggingOptions.enableDevTools,
        cacheStartupProfile: debuggingOptions.cacheStartupProfile,
        google3WorkspaceRoot: debuggingOptions.google3WorkspaceRoot,
        devToolsServerAddress: debuggingOptions.devToolsServerAddress,
      );
}
