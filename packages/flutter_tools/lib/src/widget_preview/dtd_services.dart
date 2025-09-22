// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:dtd/dtd.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:process/process.dart';

import '../artifacts.dart';
import '../base/common.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/process.dart';
import '../convert.dart';

typedef DtdService = (String, DTDServiceCallback);

/// Provides services, streams, and RPC invocations to interact with the Widget Preview Scaffold.
class WidgetPreviewDtdServices {
  WidgetPreviewDtdServices({
    required this.logger,
    required this.shutdownHooks,
    required this.dtdLauncher,
    required this.onHotRestartPreviewerRequest,
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
  static const kHotRestartPreviewer = 'hotRestartPreviewer';

  /// The list of DTD service methods registered by the tool.
  late final services = <DtdService>[(kHotRestartPreviewer, _hotRestart)];

  // END KEEP SYNCED

  final Logger logger;
  final ShutdownHooks shutdownHooks;
  final DtdLauncher dtdLauncher;

  /// Invoked when the [kHotRestartPreviewer] service method is invoked by the widget preview
  /// scaffold.
  final VoidCallback onHotRestartPreviewerRequest;

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
