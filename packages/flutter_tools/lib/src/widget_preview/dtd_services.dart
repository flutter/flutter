// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:dtd/dtd.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:meta/meta.dart';
import 'package:package_config/package_config_types.dart';
import 'package:process/process.dart';
import 'package:uuid/uuid.dart';

import '../artifacts.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../base/utils.dart';
import '../convert.dart';
import '../dart/analysis.dart';
import '../dart/package_map.dart';
import '../project.dart';
import 'analytics.dart';
import 'dtd_types.dart';
import 'persistent_preferences.dart';

typedef DtdService = (String, DTDServiceCallback);

/// Provides services, streams, and RPC invocations to interact with the Widget Preview Scaffold.
class WidgetPreviewDtdServices {
  WidgetPreviewDtdServices({
    required this.addUuidToServiceName,
    required this.dtdLauncher,
    required this.fs,
    required this.logger,
    required this.onHotRestartPreviewerRequest,
    required this.previewAnalytics,
    required this.project,
    required this.shutdownHooks,
    this.onClearSyntheticPreviews,
    this.onHotReloadPreviewerRequest,
    this.onRegisterSyntheticPreview,
    this.onUnregisterSyntheticPreview,
    this.webPreviewUri,
  }) {
    shutdownHooks.addShutdownHook(() async {
      await _dtd?.close();
      await dtdLauncher.dispose();
    });
  }

  /// The name of the widget preview service, without a UUID.
  @visibleForTesting
  static const kWidgetPreviewServiceRoot = 'widget-preview';

  /// The actual name of the registered widget preview service.
  late final String widgetPreviewService = _withUuid(kWidgetPreviewServiceRoot);

  /// The name of the widget preview stream, without a UUID.
  @visibleForTesting
  static const kWidgetPreviewScaffoldStreamRoot = 'WidgetPreviewScaffold';

  /// The actual name of the widget preview stream.
  late final String widgetPreviewScaffoldStream = _withUuid(kWidgetPreviewScaffoldStreamRoot);

  /// The unique identifier added to registered service and stream names if [addUuidToServiceName]
  /// is true.
  late final String serviceUuid = const Uuid().v4();

  /// Adds a unique identifier to the service and stream registered by the widget previewer to
  /// avoid conflicts with other widget previewer instances connected to DTD.
  ///
  /// If false, no UUID is added to the registered service and stream names.
  final bool addUuidToServiceName;

  /// The name of the language server protocol stream written to by the analysis server.
  static const kLspStream = 'Lsp';

  /// The name of the event sent from the analysis server for widget preview updates.
  static const kLspWidgetPreviewEventKind = 'dart/textDocument/publishFlutterWidgetPreviews';

  // WARNING: Keep these constants and services in sync with those defined in the widget preview
  // scaffold's dtd_services.dart.
  //
  // START KEEP SYNCED

  static const kIsWindows = 'isWindows';
  static const kHotRestartPreviewer = 'hotRestartPreviewer';
  static const kHotReloadPreviewer = 'hotReloadPreviewer';
  static const kResolveUri = 'resolveUri';
  static const kSetPreference = 'setPreference';
  static const kGetPreference = 'getPreference';
  static const kGetDevToolsUri = 'getDevToolsUri';
  static const kGetWebPreviewUrl = 'getWebPreviewUrl';
  static const kGetServiceInfo = 'getServiceInfo';
  static const kRegisterSyntheticPreview = 'registerSyntheticPreview';
  static const kUnregisterSyntheticPreview = 'unregisterSyntheticPreview';
  static const kClearSyntheticPreviews = 'clearSyntheticPreviews';

  static const kWidgetPreviewConnectedEvent = 'Connected';
  static const kLayoutExceptionEvent = 'LayoutException';
  static const kCompilationSucceededEvent = 'CompilationSucceeded';
  static const kCompilationFailedEvent = 'CompilationFailed';
  static const kPreviewsUpdatedEvent = 'PreviewsUpdated';
  static const kSyntheticPreviewStateChangedEvent = 'SyntheticPreviewStateChanged';

  static const kClearedCount = 'clearedCount';
  static const kCount = 'count';
  static const kDiagnostic = 'diagnostic';
  static const kDurationMs = 'durationMs';
  static const kError = 'error';
  static const kPreviewId = 'previewId';
  static const kPreviews = 'previews';
  static const kRegistered = 'registered';
  static const kSuccess = 'success';

  /// Protocol version for agent widget preview services.

  static const kProtocolVersion = '1.0.0';

  /// Error code for RpcException thrown when attempting to load a key from
  /// persistent preferences that doesn't have an entry.
  static const kNoValueForKey = 200;

  /// The list of DTD service methods registered by the tool.
  late final services = <DtdService>[
    (kHotRestartPreviewer, _hotRestart),
    (kHotReloadPreviewer, _hotReload),
    (kIsWindows, _isWindows),
    (kResolveUri, _resolveUri),
    (kSetPreference, _setPreference),
    (kGetPreference, _getPreference),
    (kGetDevToolsUri, _getDevToolsUri),
    (kGetWebPreviewUrl, _getWebPreviewUrl),
    (kGetServiceInfo, _getServiceInfo),
    (kRegisterSyntheticPreview, _registerSyntheticPreview),
    (kUnregisterSyntheticPreview, _unregisterSyntheticPreview),
    (kClearSyntheticPreviews, _clearSyntheticPreviews),
  ];

  // END KEEP SYNCED

  @visibleForTesting
  late final preferences = PersistentPreferences(fs: fs);

  final WidgetPreviewAnalytics previewAnalytics;
  final FileSystem fs;
  final Logger logger;
  final ShutdownHooks shutdownHooks;
  final DtdLauncher dtdLauncher;

  /// Invoked when the [kHotRestartPreviewer] service method is invoked by the widget preview
  /// scaffold.
  final VoidCallback onHotRestartPreviewerRequest;

  /// Invoked when the [kHotReloadPreviewer] service method is invoked.
  final Future<void> Function()? onHotReloadPreviewerRequest;

  /// Invoked when a synthetic preview is registered dynamically.
  final Future<bool> Function(SyntheticPreviewDetails details)? onRegisterSyntheticPreview;

  /// Invoked when a synthetic preview is unregistered.
  final Future<bool> Function(String previewId)? onUnregisterSyntheticPreview;

  /// Invoked when all synthetic previews are cleared.
  final Future<int> Function()? onClearSyntheticPreviews;

  /// Returns the URI of the running web preview application, if available.
  final Uri Function()? webPreviewUri;

  /// The widget_preview_scaffold project.
  final FlutterProject project;

  PackageConfig? _packageConfig;

  DartToolingDaemon? _dtd;

  @visibleForTesting
  Future<Uri> get devToolsServerAddress => _devToolsServerAddress.future;
  final _devToolsServerAddress = Completer<Uri>();

  /// The [Uri] pointing to the currently connected DTD instance.
  ///
  /// Returns `null` if there is no DTD connection.
  Uri? get dtdUri => _dtdUri;
  Uri? _dtdUri;

  /// Returns true if the LSP service is registered with the connected DTD instance.
  bool get lspServiceAvailable => _lspServiceAvailable;
  bool _lspServiceAvailable = false;

  /// Starts DTD in a child process before invoking [connect] with a [Uri] pointing to the new
  /// DTD instance.
  Future<void> launchAndConnect({required AnalysisServer analysisServer}) async {
    final Uri dtdUri = await dtdLauncher.launch();
    logger.printStatus('Connecting to DTD');
    await analysisServer.connectToDtd(dtdUri: dtdUri);
    logger.printStatus('Connected to DTD');
    // Connect to the new DTD instance.
    await connect(dtdWsUri: dtdUri);
  }

  /// Connects to an existing DTD instance and registers any relevant services.
  Future<void> connect({required Uri dtdWsUri}) async {
    _dtdUri = dtdWsUri;
    _dtd = await DartToolingDaemon.connect(dtdWsUri);

    _lspServiceAvailable = false;
    final RegisteredServicesResponse registeredServices = await _dtd!.getRegisteredServices();
    _lspServiceAvailable =
        registeredServices.dtdServices.contains(kLspStream) ||
        registeredServices.clientServices.any((service) => service.name == kLspStream);

    await _registerServices();
    logger.printTrace('Connected to DTD and registered services.');
  }

  Future<FlutterWidgetPreviews> getFlutterWidgetPreviews() async {
    await _waitForLspService();
    const maxAttempts = 50;
    for (var attempts = 0; attempts < maxAttempts; attempts++) {
      try {
        final DTDResponse result = await _dtd!.call(
          'Lsp',
          'dart/workspace/getFlutterWidgetPreviews',
        );
        return FlutterWidgetPreviews.fromJson(result.result['result']! as Map<String, Object?>);
      } on RpcException catch (e) {
        if (e.code == -32601 && attempts < maxAttempts - 1) {
          // Method not found
          await Future<void>.delayed(const Duration(milliseconds: 200));
          continue;
        }
        rethrow;
      }
    }
    throw StateError('Failed to call getFlutterWidgetPreviews after $maxAttempts attempts.');
  }

  Future<FlutterWidgetPreviews> getFlutterWidgetPreviewsForFile({required String filePath}) async {
    await _waitForLspService();
    const maxAttempts = 50;
    for (var attempts = 0; attempts < maxAttempts; attempts++) {
      try {
        final DTDResponse result = await _dtd!.call(
          'Lsp',
          'dart/textDocument/getFlutterWidgetPreviews',
          params: {'uri': Uri.file(filePath).toString()},
        );
        return FlutterWidgetPreviews.fromJson(result.result['result']! as Map<String, Object?>);
      } on RpcException catch (e) {
        if (e.code == -32601 && attempts < maxAttempts - 1) {
          // Method not found
          await Future<void>.delayed(const Duration(milliseconds: 200));
          continue;
        }
        rethrow;
      }
    }
    throw StateError('Failed to call getFlutterWidgetPreviewsForFile after $maxAttempts attempts.');
  }

  Future<void> _waitForLspService() async {
    if (_lspServiceAvailable) {
      return;
    }

    final lspRegisteredCompleter = Completer<void>();

    const kServiceStream = 'Service';
    await _dtd!.streamListen(kServiceStream);
    final StreamSubscription<DTDEvent> serviceSubscription = _dtd!.onEvent(kServiceStream).listen((
      DTDEvent event,
    ) {
      if (lspRegisteredCompleter.isCompleted) {
        return;
      }
      if (event case DTDEvent(kind: 'ServiceRegistered', data: {'service': kLspStream})) {
        _lspServiceAvailable = true;
        lspRegisteredCompleter.complete();
      }
    });

    try {
      final RegisteredServicesResponse registeredServices = await _dtd!.getRegisteredServices();
      final bool alreadyRegistered =
          registeredServices.dtdServices.contains(kLspStream) ||
          registeredServices.clientServices.any((service) => service.name == kLspStream);
      if (alreadyRegistered) {
        _lspServiceAvailable = true;
        lspRegisteredCompleter.complete();
      } else {
        logger.printStatus('Waiting for analysis server to register Lsp service with DTD...');
        await lspRegisteredCompleter.future.timeout(const Duration(seconds: 30));
      }
    } on TimeoutException {
      logger.printWarning('Timed out waiting for the Lsp service to be registered with DTD.');
      rethrow;
    } finally {
      await serviceSubscription.cancel();
    }
  }

  /// Set the DevTools server URI to be used to embed the widget inspector within the
  /// widget previewer.
  ///
  /// This must be called, otherwise the widget previewer will hang waiting for a DevTools URI.
  void setDevToolsServerAddress({required Uri devToolsServerAddress, required Uri applicationUri}) {
    if (_devToolsServerAddress.isCompleted) {
      throw StateError('DevTools server address has already been set.');
    }
    _devToolsServerAddress.complete(
      devToolsServerAddress.replace(
        pathSegments: [
          ...devToolsServerAddress.pathSegments.whereNot((s) => s.isEmpty),
          'inspector',
        ],
        queryParameters: {
          ...devToolsServerAddress.queryParameters,
          'embedMode': 'one',
          'uri': applicationUri.toString(),
        },
      ),
    );
  }

  String _withUuid(String name) => addUuidToServiceName ? '$name-$serviceUuid' : name;

  Future<void> _registerServices() async {
    final DartToolingDaemon dtd = _dtd!;
    dtd.onEvent(widgetPreviewScaffoldStream).listen((DTDEvent event) {
      if (event.kind == kWidgetPreviewConnectedEvent) {
        previewAnalytics.reportPreviewerConnected();
      }
    });
    await Future.wait(<Future<void>>[
      dtd.streamListen(widgetPreviewScaffoldStream),
      for (final (String method, DTDServiceCallback callback) in services)
        dtd
            .registerService(widgetPreviewService, method, callback)
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
    return switch (value) {
      final String s => StringResponse(s).toJson(),
      final bool b => BoolResponse(b).toJson(),
      _ => throw UnimplementedError('Unexpected preference value: ${value.runtimeType}'),
    };
  }

  Future<Map<String, Object?>> _getDevToolsUri(Parameters _) async {
    return StringResponse((await _devToolsServerAddress.future).toString()).toJson();
  }

  Future<Map<String, Object?>> _hotReload(Parameters _) async {
    if (onHotReloadPreviewerRequest != null) {
      await onHotReloadPreviewerRequest!();
    }
    return const Success().toJson();
  }

  Future<Map<String, Object?>> _getWebPreviewUrl(Parameters _) async {
    final Uri? uri = webPreviewUri?.call();
    if (uri == null) {
      throw RpcException(kNoValueForKey, 'Web preview server URL is not currently available.');
    }
    return WebPreviewUrlResult(host: uri.host, port: uri.port, url: uri.toString()).toJson();
  }

  Future<Map<String, Object?>> _getServiceInfo(Parameters _) async {
    final Uri? uri = webPreviewUri?.call();
    return PreviewServiceInfo(
      dtdUri: _dtdUri?.toString() ?? '',
      serviceName: widgetPreviewService,
      version: kProtocolVersion,
      webPreviewUrl: uri?.toString(),
    ).toJson();
  }

  Future<Map<String, Object?>> _registerSyntheticPreview(Parameters params) async {
    final SyntheticPreviewDetails details = SyntheticPreviewDetails.fromJson(
      params.asMap.cast<String, Object?>(),
    );
    final bool success =
        onRegisterSyntheticPreview == null || await onRegisterSyntheticPreview!(details);
    if (success) {
      await postSyntheticPreviewStateChangedEvent(previewId: details.previewId, registered: true);
    }
    return BoolResponse(success).toJson();
  }

  Future<Map<String, Object?>> _unregisterSyntheticPreview(Parameters params) async {
    final String previewId = params[SyntheticPreviewDetails.kPreviewId].asString;
    final bool success =
        onUnregisterSyntheticPreview == null || await onUnregisterSyntheticPreview!(previewId);
    if (success) {
      await postSyntheticPreviewStateChangedEvent(previewId: previewId, registered: false);
    }
    return BoolResponse(success).toJson();
  }

  Future<Map<String, Object?>> _clearSyntheticPreviews(Parameters _) async {
    final int count = onClearSyntheticPreviews != null ? await onClearSyntheticPreviews!() : 0;
    return <String, Object?>{kClearedCount: count};
  }

  /// Posts a [kLayoutExceptionEvent] to the widget preview stream.
  Future<void> postLayoutExceptionEvent({
    required String previewId,
    required Map<String, Object?> diagnostic,
  }) async {
    final DartToolingDaemon? dtd = _dtd;
    if (dtd == null) {
      return;
    }
    await dtd.postEvent(widgetPreviewScaffoldStream, kLayoutExceptionEvent, <String, Object?>{
      kPreviewId: previewId,
      kDiagnostic: diagnostic,
    });
  }

  /// Posts a [kPreviewsUpdatedEvent] to the widget preview stream.
  Future<void> postPreviewsUpdatedEvent({required List<Map<String, Object?>> previews}) async {
    final DartToolingDaemon? dtd = _dtd;
    if (dtd == null) {
      return;
    }
    await dtd.postEvent(widgetPreviewScaffoldStream, kPreviewsUpdatedEvent, <String, Object?>{
      kCount: previews.length,
      kPreviews: previews,
    });
  }

  /// Posts a compilation status event to the widget preview stream.
  Future<void> postCompilationEvent({required bool success, int? durationMs, String? error}) async {
    final DartToolingDaemon? dtd = _dtd;
    if (dtd == null) {
      return;
    }
    await dtd.postEvent(
      widgetPreviewScaffoldStream,
      success ? kCompilationSucceededEvent : kCompilationFailedEvent,
      <String, Object?>{
        kSuccess: success,
        if (durationMs != null) kDurationMs: durationMs,
        if (error != null) kError: error,
      },
    );
  }

  /// Posts a [kSyntheticPreviewStateChangedEvent] to the widget preview stream.
  Future<void> postSyntheticPreviewStateChangedEvent({
    required String previewId,
    required bool registered,
  }) async {
    final DartToolingDaemon? dtd = _dtd;
    if (dtd == null) {
      return;
    }
    await dtd.postEvent(
      widgetPreviewScaffoldStream,
      kSyntheticPreviewStateChangedEvent,
      <String, Object?>{kPreviewId: previewId, kRegistered: registered},
    );
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
    sub = _dtdProcess!.stdout.transformWithCallSite(utf8.decoder).listen((String data) async {
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
