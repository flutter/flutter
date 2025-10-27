// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:dtd/dtd.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:meta/meta.dart';
import 'package:package_config/package_config_types.dart';
import 'package:process/process.dart';

import '../artifacts.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../convert.dart';
import '../dart/package_map.dart';
import '../project.dart';
import 'persistent_preferences.dart';

typedef DtdService = (String, DTDServiceCallback);

/// Provides services, streams, and RPC invocations to interact with the Widget Preview Scaffold.
class WidgetPreviewDtdServices {
  WidgetPreviewDtdServices({
    required this.fs,
    required this.logger,
    required this.shutdownHooks,
    required this.dtdLauncher,
    required this.onHotRestartPreviewerRequest,
    required this.project,
  }) {
    shutdownHooks.addShutdownHook(() async {
      await _dtd?.close();
      await dtdLauncher.dispose();
    });
  }

  // WARNING: Keep these constants and services in sync with those defined in the widget preview
  // scaffold's dtd_services.dart.
  //
  // START KEEP SYNCED

  static const kWidgetPreviewService = 'widget-preview';
  static const kIsWindows = 'isWindows';
  static const kHotRestartPreviewer = 'hotRestartPreviewer';
  static const kResolveUri = 'resolveUri';
  static const kSetPreference = 'setPreference';
  static const kGetPreference = 'getPreference';

  /// Error code for RpcException thrown when attempting to load a key from
  /// persistent preferences that doesn't have an entry.
  static const kNoValueForKey = 200;

  /// The list of DTD service methods registered by the tool.
  late final services = <DtdService>[
    (kHotRestartPreviewer, _hotRestart),
    (kIsWindows, _isWindows),
    (kResolveUri, _resolveUri),
    (kSetPreference, _setPreference),
    (kGetPreference, _getPreference),
  ];

  // END KEEP SYNCED

  @visibleForTesting
  late final preferences = PersistentPreferences(fs: fs);

  final FileSystem fs;
  final Logger logger;
  final ShutdownHooks shutdownHooks;
  final DtdLauncher dtdLauncher;

  /// Invoked when the [kHotRestartPreviewer] service method is invoked by the widget preview
  /// scaffold.
  final VoidCallback onHotRestartPreviewerRequest;

  /// The widget_preview_scaffold project.
  final FlutterProject project;

  PackageConfig? _packageConfig;

  DartToolingDaemon? _dtd;

  /// The [Uri] pointing to the currently connected DTD instance.
  ///
  /// Returns `null` if there is no DTD connection.
  Uri? get dtdUri => _dtdUri;
  Uri? _dtdUri;

  /// Starts DTD in a child process before invoking [connect] with a [Uri] pointing to the new
  /// DTD instance.
  Future<void> launchAndConnect() async {
    // Connect to the new DTD instance.
    await connect(dtdWsUri: await dtdLauncher.launch());
  }

  /// Connects to an existing DTD instance and registers any relevant services.
  Future<void> connect({required Uri dtdWsUri}) async {
    _dtdUri = dtdWsUri;
    _dtd = await DartToolingDaemon.connect(dtdWsUri);
    await _registerServices();
    logger.printTrace('Connected to DTD and registered services.');
  }

  Future<void> _registerServices() async {
    final DartToolingDaemon dtd = _dtd!;
    await Future.wait(<Future<void>>[
      for (final (String method, DTDServiceCallback callback) in services)
        dtd
            .registerService(kWidgetPreviewService, method, callback)
            .then((_) => logger.printTrace('Registered DTD method: $method')),
    ]);
  }

  Future<Map<String, Object?>> _hotRestart(Parameters params) async {
    onHotRestartPreviewerRequest();
    return const Success().toJson();
  }

  Future<Map<String, Object?>> _isWindows(Parameters _) async {
    return BoolResponse(const LocalPlatform().isWindows).toJson();
  }

  Future<Map<String, Object?>> _resolveUri(Parameters params) async {
    _packageConfig ??= await loadPackageConfigWithLogging(project.packageConfig, logger: logger);
    final Uri? result = _packageConfig!.resolve(Uri.parse(params.asMap['uri'] as String));
    return StringResponse(result.toString()).toJson();
  }

  Future<Map<String, Object?>> _setPreference(Parameters params) async {
    final String key = params['key'].asString;
    final Object? value = params['value'].value;
    preferences[key] = value;
    return const Success().toJson();
  }

  Future<Map<String, Object?>> _getPreference(Parameters params) async {
    final String key = params['key'].asString;
    final Object? value = preferences[key];
    if (value == null) {
      throw RpcException(kNoValueForKey, 'No entry for $key in preferences.');
    }
    if (value is String) {
      return StringResponse(value).toJson();
    }
    if (value is bool) {
      return BoolResponse(value).toJson();
    }
    throw UnimplementedError('Unexpected preference value: ${value.runtimeType}');
  }
}

/// Manages the lifecycle of a Dart Tooling Daemon (DTD) instance.
class DtdLauncher {
  DtdLauncher({required this.logger, required this.artifacts, required this.processManager});

  /// Starts a new DTD instance and returns the web socket URI it's available on.
  Future<Uri> launch() async {
    if (_dtdProcess != null) {
      throw StateError('Attempted to launch DTD twice.');
    }

    // Start DTD.
    _dtdProcess = await processManager.start(<Object>[
      artifacts.getArtifactPath(Artifact.engineDartBinary),
      'tooling-daemon',
      '--machine',
    ]);

    // Wait for the DTD connection information.
    final dtdUri = Completer<Uri>();
    late final StreamSubscription<String> sub;
    sub = _dtdProcess!.stdout.transform(const Utf8Decoder()).listen((String data) async {
      await sub.cancel();
      final jsonData = json.decode(data) as Map<String, Object?>;
      if (jsonData case {'tooling_daemon_details': {'uri': final String dtdUriString}}) {
        dtdUri.complete(Uri.parse(dtdUriString));
      } else {
        throwToolExit('Unable to start the Dart Tooling Daemon.');
      }
    });
    return dtdUri.future;
  }

  /// Kills the spawned DTD instance.
  Future<void> dispose() async {
    _dtdProcess?.kill();
    _dtdProcess = null;
  }

  final Logger logger;
  final Artifacts artifacts;
  final ProcessManager processManager;

  Process? _dtdProcess;
}
