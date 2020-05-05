// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart' show required, visibleForTesting;
import 'package:vm_service/vm_service.dart' as vm_service;

import 'base/context.dart';
import 'base/io.dart' as io;
import 'device.dart';
import 'globals.dart' as globals;
import 'version.dart';

const String kGetSkSLsMethod = '_flutter.getSkSLs';
const String kSetAssetBundlePathMethod = '_flutter.setAssetBundlePath';
const String kFlushUIThreadTasksMethod = '_flutter.flushUIThreadTasks';
const String kRunInViewMethod = '_flutter.runInView';
const String kListViewsMethod = '_flutter.listViews';
const String kScreenshotSkpMethod = '_flutter.screenshotSkp';
const String kScreenshotMethod = '_flutter.screenshot';

/// The error response code from an unrecoverable compilation failure.
const int kIsolateReloadBarred = 1005;

/// Override `WebSocketConnector` in [context] to use a different constructor
/// for [WebSocket]s (used by tests).
typedef WebSocketConnector = Future<io.WebSocket> Function(String url, {io.CompressionOptions compression});

WebSocketConnector _openChannel = _defaultOpenChannel;

/// The error codes for the JSON-RPC standard.
///
/// See also: https://www.jsonrpc.org/specification#error_object
abstract class RPCErrorCodes {
  /// The method does not exist or is not available.
  static const int kMethodNotFound = -32601;

  /// Invalid method parameter(s), such as a mismatched type.
  static const int kInvalidParams = -32602;

  /// Internal JSON-RPC error.
  static const int kInternalError = -32603;

  /// Application specific error codes.
  static const int kServerError = -32000;
}

/// A function that reacts to the invocation of the 'reloadSources' service.
///
/// The VM Service Protocol allows clients to register custom services that
/// can be invoked by other clients through the service protocol itself.
///
/// Clients like Observatory use external 'reloadSources' services,
/// when available, instead of the VM internal one. This allows these clients to
/// invoke Flutter HotReload when connected to a Flutter Application started in
/// hot mode.
///
/// See: https://github.com/dart-lang/sdk/issues/30023
typedef ReloadSources = Future<void> Function(
  String isolateId, {
  bool force,
  bool pause,
});

typedef Restart = Future<void> Function({ bool pause });

typedef CompileExpression = Future<String> Function(
  String isolateId,
  String expression,
  List<String> definitions,
  List<String> typeDefinitions,
  String libraryUri,
  String klass,
  bool isStatic,
);

typedef ReloadMethod = Future<void> Function({
  String classId,
  String libraryId,
});

Future<io.WebSocket> _defaultOpenChannel(String url, {
  io.CompressionOptions compression = io.CompressionOptions.compressionDefault
}) async {
  Duration delay = const Duration(milliseconds: 100);
  int attempts = 0;
  io.WebSocket socket;

  Future<void> handleError(dynamic e) async {
    globals.printTrace('Exception attempting to connect to Observatory: $e');
    globals.printTrace('This was attempt #$attempts. Will retry in $delay.');

    if (attempts == 10) {
      globals.printStatus('This is taking longer than expected...');
    }

    // Delay next attempt.
    await Future<void>.delayed(delay);

    // Back off exponentially, up to 1600ms per attempt.
    if (delay < const Duration(seconds: 1)) {
      delay *= 2;
    }
  }

  final WebSocketConnector constructor = context.get<WebSocketConnector>() ?? io.WebSocket.connect;
  while (socket == null) {
    attempts += 1;
    try {
      socket = await constructor(url, compression: compression);
    } on io.WebSocketException catch (e) {
      await handleError(e);
    } on io.SocketException catch (e) {
      await handleError(e);
    }
  }
  return socket;
}

/// Override `VMServiceConnector` in [context] to return a different VMService
/// from [VMService.connect] (used by tests).
typedef VMServiceConnector = Future<vm_service.VmService> Function(Uri httpUri, {
  ReloadSources reloadSources,
  Restart restart,
  CompileExpression compileExpression,
  ReloadMethod reloadMethod,
  io.CompressionOptions compression,
  Device device,
});

final Expando<Uri> _httpAddressExpando = Expando<Uri>();

final Expando<Uri> _wsAddressExpando = Expando<Uri>();

@visibleForTesting
void setHttpAddress(Uri uri, vm_service.VmService vmService) {
  _httpAddressExpando[vmService] = uri;
}

@visibleForTesting
void setWsAddress(Uri uri, vm_service.VmService vmService) {
  _wsAddressExpando[vmService] = uri;
}

/// A connection to the Dart VM Service.
vm_service.VmService setUpVmService(
  ReloadSources reloadSources,
  Restart restart,
  CompileExpression compileExpression,
  Device device,
  ReloadMethod reloadMethod,
  vm_service.VmService vmService
) {
  if (reloadSources != null) {
    vmService.registerServiceCallback('reloadSources', (Map<String, dynamic> params) async {
      final String isolateId = _validateRpcStringParam('reloadSources', params, 'isolateId');
      final bool force = _validateRpcBoolParam('reloadSources', params, 'force');
      final bool pause = _validateRpcBoolParam('reloadSources', params, 'pause');

      await reloadSources(isolateId, force: force, pause: pause);

      return <String, dynamic>{
        'result': <String, Object>{
          'type': 'Success',
        }
      };
    });
    vmService.registerService('reloadSources', 'Flutter Tools');
  }

  if (reloadMethod != null) {
    // Register a special method for hot UI. while this is implemented
    // currently in the same way as hot reload, it leaves the tool free
    // to change to a more efficient implementation in the future.
    //
    // `library` should be the file URI of the updated code.
    // `class` should be the name of the Widget subclass to be marked dirty. For example,
    // if the build method of a StatelessWidget is updated, this is the name of class.
    // If the build method of a StatefulWidget is updated, then this is the name
    // of the Widget class that created the State object.
    vmService.registerServiceCallback('reloadMethod', (Map<String, dynamic> params) async {
      final String libraryId = _validateRpcStringParam('reloadMethod', params, 'library');
      final String classId = _validateRpcStringParam('reloadMethod', params, 'class');

      globals.printTrace('reloadMethod not yet supported, falling back to hot reload');

      await reloadMethod(libraryId: libraryId, classId: classId);
      return <String, dynamic>{
        'result': <String, Object>{
          'type': 'Success',
        }
      };
    });
    vmService.registerService('reloadMethod', 'Flutter Tools');
  }

  if (restart != null) {
    vmService.registerServiceCallback('hotRestart', (Map<String, dynamic> params) async {
      final bool pause = _validateRpcBoolParam('compileExpression', params, 'pause');
      await restart(pause: pause);
      return <String, dynamic>{
        'result': <String, Object>{
          'type': 'Success',
        }
      };
    });
    vmService.registerService('hotRestart', 'Flutter Tools');
  }

  vmService.registerServiceCallback('flutterVersion', (Map<String, dynamic> params) async {
    final FlutterVersion version = context.get<FlutterVersion>() ?? FlutterVersion();
    final Map<String, Object> versionJson = version.toJson();
    versionJson['frameworkRevisionShort'] = version.frameworkRevisionShort;
    versionJson['engineRevisionShort'] = version.engineRevisionShort;
    return <String, dynamic>{
      'result': <String, Object>{
        'type': 'Success',
        ...versionJson,
      }
    };
  });
  vmService.registerService('flutterVersion', 'Flutter Tools');

  if (compileExpression != null) {
    vmService.registerServiceCallback('compileExpression', (Map<String, dynamic> params) async {
      final String isolateId = _validateRpcStringParam('compileExpression', params, 'isolateId');
      final String expression = _validateRpcStringParam('compileExpression', params, 'expression');
      final List<String> definitions = List<String>.from(params['definitions'] as List<dynamic>);
      final List<String> typeDefinitions = List<String>.from(params['typeDefinitions'] as List<dynamic>);
      final String libraryUri = params['libraryUri'] as String;
      final String klass = params['klass'] as String;
      final bool isStatic = _validateRpcBoolParam('compileExpression', params, 'isStatic');

      final String kernelBytesBase64 = await compileExpression(isolateId,
          expression, definitions, typeDefinitions, libraryUri, klass,
          isStatic);
      return <String, dynamic>{
        'type': 'Success',
        'result': <String, dynamic>{
          'result': <String, dynamic>{'kernelBytes': kernelBytesBase64},
        },
      };
    });
    vmService.registerService('compileExpression', 'Flutter Tools');
  }
  if (device != null) {
    vmService.registerServiceCallback('flutterMemoryInfo', (Map<String, dynamic> params) async {
      final MemoryInfo result = await device.queryMemoryInfo();
      return <String, dynamic>{
        'result': <String, Object>{
          'type': 'Success',
          ...result.toJson(),
        }
      };
    });
    vmService.registerService('flutterMemoryInfo', 'Flutter Tools');
  }
  return vmService;
}

/// Connect to a Dart VM Service at [httpUri].
///
/// If the [reloadSources] parameter is not null, the 'reloadSources' service
/// will be registered. The VM Service Protocol allows clients to register
/// custom services that can be invoked by other clients through the service
/// protocol itself.
///
/// See: https://github.com/dart-lang/sdk/commit/df8bf384eb815cf38450cb50a0f4b62230fba217
Future<vm_service.VmService> connectToVmService(
  Uri httpUri, {
    ReloadSources reloadSources,
    Restart restart,
    CompileExpression compileExpression,
    ReloadMethod reloadMethod,
    io.CompressionOptions compression = io.CompressionOptions.compressionDefault,
    Device device,
  }) async {
  final VMServiceConnector connector = context.get<VMServiceConnector>() ?? _connect;
  return connector(httpUri,
    reloadSources: reloadSources,
    restart: restart,
    compileExpression: compileExpression,
    compression: compression,
    device: device,
    reloadMethod: reloadMethod,
  );
}

Future<vm_service.VmService> _connect(
  Uri httpUri, {
  ReloadSources reloadSources,
  Restart restart,
  CompileExpression compileExpression,
  ReloadMethod reloadMethod,
  io.CompressionOptions compression = io.CompressionOptions.compressionDefault,
  Device device,
}) async {
  final Uri wsUri = httpUri.replace(scheme: 'ws', path: globals.fs.path.join(httpUri.path, 'ws'));
  final io.WebSocket channel = await _openChannel(wsUri.toString(), compression: compression);
  // Create an instance of the package:vm_service API in addition to the flutter
  // tool's to allow gradual migration.
  final Completer<void> streamClosedCompleter = Completer<void>();
  final vm_service.VmService delegateService = vm_service.VmService(
    channel,
    channel.add,
    log: null,
    disposeHandler: () async {
      if (!streamClosedCompleter.isCompleted) {
        streamClosedCompleter.complete();
      }
      await channel.close();
    },
  );

  final vm_service.VmService service = setUpVmService(
    reloadSources,
    restart,
    compileExpression,
    device,
    reloadMethod,
    delegateService,
  );
  _httpAddressExpando[service] = httpUri;
  _wsAddressExpando[service] = wsUri;

  // This call is to ensure we are able to establish a connection instead of
  // keeping on trucking and failing farther down the process.
  await delegateService.getVersion();
  return service;
}

String _validateRpcStringParam(String methodName, Map<String, dynamic> params, String paramName) {
  final dynamic value = params[paramName];
  if (value is! String || (value as String).isEmpty) {
    throw vm_service.RPCError(
      methodName,
      RPCErrorCodes.kInvalidParams,
      "Invalid '$paramName': $value",
    );
  }
  return value as String;
}

bool _validateRpcBoolParam(String methodName, Map<String, dynamic> params, String paramName) {
  final dynamic value = params[paramName];
  if (value != null && value is! bool) {
    throw vm_service.RPCError(
      methodName,
      RPCErrorCodes.kInvalidParams,
      "Invalid '$paramName': $value",
    );
  }
  return (value as bool) ?? false;
}

/// Peered to an Android/iOS FlutterView widget on a device.
class FlutterView {
  FlutterView({
    @required this.id,
    @required this.uiIsolate,
  });

  factory FlutterView.parse(Map<String, Object> json) {
    final Map<String, Object> rawIsolate = json['isolate'] as Map<String, Object>;
    vm_service.IsolateRef isolate;
    if (rawIsolate != null) {
      rawIsolate['number'] = rawIsolate['number']?.toString();
      isolate = vm_service.IsolateRef.parse(rawIsolate);
    }
    return FlutterView(
      id: json['id'] as String,
      uiIsolate: isolate,
    );
  }

  final vm_service.IsolateRef uiIsolate;
  final String id;

  bool get hasIsolate => uiIsolate != null;

  @override
  String toString() => id;

  Map<String, Object> toJson() {
    return <String, Object>{
      'id': id,
      'isolate': uiIsolate?.toJson(),
    };
  }
}

/// Flutter specific VM Service functionality.
extension FlutterVmService on vm_service.VmService {
  Uri get wsAddress => _wsAddressExpando[this];

  Uri get httpAddress => _httpAddressExpando[this];

  /// Set the asset directory for the an attached Flutter view.
  Future<void> setAssetDirectory({
    @required Uri assetsDirectory,
    @required String viewId,
    @required String uiIsolateId,
  }) async {
    assert(assetsDirectory != null);
    await callMethod(kSetAssetBundlePathMethod,
      isolateId: uiIsolateId,
      args: <String, dynamic>{
        'viewId': viewId,
        'assetDirectory': assetsDirectory.toFilePath(windows: false),
      });
  }

  /// Retreive the cached SkSL shaders from an attached Flutter view.
  ///
  /// This method will only return data if `--cache-sksl` was provided as a
  /// flutter run agument, and only then on physical devices.
  Future<Map<String, Object>> getSkSLs({
    @required String viewId,
  }) async {
    final vm_service.Response response = await callMethod(
      kGetSkSLsMethod,
      args: <String, String>{
        'viewId': viewId,
      },
    );
    return response.json['SkSLs'] as Map<String, Object>;
  }

  /// Flush all tasks on the UI thead for an attached Flutter view.
  ///
  /// This method is currently used only for benchmarking.
  Future<void> flushUIThreadTasks({
    @required String uiIsolateId,
  }) async {
    await callMethod(
      kFlushUIThreadTasksMethod,
      args: <String, String>{
        'isolateId': uiIsolateId,
      },
    );
  }

  /// Launch the Dart isolate with entrypoint [main] in the Flutter engine [viewId]
  /// with [assetsDirectory] as the devFS.
  ///
  /// This method is used by the tool to hot restart an already running Flutter
  /// engine.
  Future<void> runInView({
    @required String viewId,
    @required Uri main,
    @required Uri assetsDirectory,
  }) async {
    try {
      await streamListen('Isolate');
    } on vm_service.RPCError {
      // Do nothing, since the tool is already subscribed.
    }
    final Future<void> onRunnable = onIsolateEvent.firstWhere((vm_service.Event event) {
      return event.kind == vm_service.EventKind.kIsolateRunnable;
    });
    await callMethod(
      kRunInViewMethod,
      args: <String, Object>{
        'viewId': viewId,
        'mainScript': main.toString(),
        'assetDirectory': assetsDirectory.toString(),
      },
    );
    await onRunnable;
  }

  Future<Map<String, dynamic>> flutterDebugDumpApp({
    @required String isolateId,
  }) {
    return invokeFlutterExtensionRpcRaw(
      'ext.flutter.debugDumpApp',
      isolateId: isolateId,
    );
  }

  Future<Map<String, dynamic>> flutterDebugDumpRenderTree({
    @required String isolateId,
  }) {
    return invokeFlutterExtensionRpcRaw(
      'ext.flutter.debugDumpRenderTree',
      isolateId: isolateId,
    );
  }

  Future<Map<String, dynamic>> flutterDebugDumpLayerTree({
    @required String isolateId,
  }) {
    return invokeFlutterExtensionRpcRaw(
      'ext.flutter.debugDumpLayerTree',
      isolateId: isolateId,
    );
  }

  Future<Map<String, dynamic>> flutterDebugDumpSemanticsTreeInTraversalOrder({
    @required String isolateId,
  }) {
    return invokeFlutterExtensionRpcRaw(
      'ext.flutter.debugDumpSemanticsTreeInTraversalOrder',
      isolateId: isolateId,
    );
  }

  Future<Map<String, dynamic>> flutterDebugDumpSemanticsTreeInInverseHitTestOrder({
    @required String isolateId,
  }) {
    return invokeFlutterExtensionRpcRaw(
      'ext.flutter.debugDumpSemanticsTreeInInverseHitTestOrder',
      isolateId: isolateId,
    );
  }

  Future<Map<String, dynamic>> _flutterToggle(String name, {
    @required String isolateId,
  }) async {
    Map<String, dynamic> state = await invokeFlutterExtensionRpcRaw(
      'ext.flutter.$name',
      isolateId: isolateId,
    );
    if (state != null && state.containsKey('enabled') && state['enabled'] is String) {
      state = await invokeFlutterExtensionRpcRaw(
        'ext.flutter.$name',
        isolateId: isolateId,
        args: <String, dynamic>{
          'enabled': state['enabled'] == 'true' ? 'false' : 'true',
        },
      );
    }

    return state;
  }

  Future<Map<String, dynamic>> flutterToggleDebugPaintSizeEnabled({
    @required String isolateId,
  }) => _flutterToggle('debugPaint', isolateId: isolateId);

  Future<Map<String, dynamic>> flutterToggleDebugCheckElevationsEnabled({
    @required String isolateId,
  }) => _flutterToggle('debugCheckElevationsEnabled', isolateId: isolateId);

  Future<Map<String, dynamic>> flutterTogglePerformanceOverlayOverride({
    @required String isolateId,
  }) => _flutterToggle('showPerformanceOverlay', isolateId: isolateId);

  Future<Map<String, dynamic>> flutterToggleWidgetInspector({
    @required String isolateId,
  }) => _flutterToggle('inspector.show', isolateId: isolateId);

  Future<Map<String, dynamic>> flutterToggleProfileWidgetBuilds({
    @required String isolateId,
  }) => _flutterToggle('profileWidgetBuilds', isolateId: isolateId);

  Future<Map<String, dynamic>> flutterDebugAllowBanner(bool show, {
    @required String isolateId,
  }) {
    return invokeFlutterExtensionRpcRaw(
      'ext.flutter.debugAllowBanner',
      isolateId: isolateId,
      args: <String, dynamic>{'enabled': show ? 'true' : 'false'},
    );
  }

  Future<Map<String, dynamic>> flutterReassemble({
    @required String isolateId,
  }) {
    return invokeFlutterExtensionRpcRaw(
      'ext.flutter.reassemble',
      isolateId: isolateId,
    );
  }

  Future<Map<String, dynamic>> flutterFastReassemble(String classId, {
   @required String isolateId,
  }) {
    return invokeFlutterExtensionRpcRaw(
      'ext.flutter.fastReassemble',
      isolateId: isolateId,
      args: <String, Object>{
        'class': classId,
      },
    );
  }

  Future<bool> flutterAlreadyPaintedFirstUsefulFrame({
    @required String isolateId,
  }) async {
    final Map<String, dynamic> result = await invokeFlutterExtensionRpcRaw(
      'ext.flutter.didSendFirstFrameRasterizedEvent',
      isolateId: isolateId,
    );
    // result might be null when the service extension is not initialized
    return result != null && result['enabled'] == 'true';
  }

  Future<Map<String, dynamic>> uiWindowScheduleFrame({
    @required String isolateId,
  }) {
    return invokeFlutterExtensionRpcRaw(
      'ext.ui.window.scheduleFrame',
      isolateId: isolateId,
    );
  }

  Future<Map<String, dynamic>> flutterEvictAsset(String assetPath, {
   @required String isolateId,
  }) {
    return invokeFlutterExtensionRpcRaw(
      'ext.flutter.evict',
      isolateId: isolateId,
      args: <String, dynamic>{
        'value': assetPath,
      },
    );
  }

  /// Exit the application by calling [exit] from `dart:io`.
  ///
  /// This method is only supported by certain embedders. This is
  /// described by [Device.supportsFlutterExit].
  Future<void> flutterExit({
    @required String isolateId,
  }) {
    return invokeFlutterExtensionRpcRaw(
      'ext.flutter.exit',
      isolateId: isolateId,
    ).catchError((dynamic error, StackTrace stackTrace) {
      globals.logger.printTrace('Failure in ext.flutter.exit: $error\n$stackTrace');
      // Do nothing on sentinel or exception, the isolate already exited.
    }, test: (dynamic error) => error is vm_service.SentinelException || error is vm_service.RPCError);
  }

  /// Return the current platform override for the flutter view running with
  /// the main isolate [isolateId].
  ///
  /// If a non-null value is provided for [platform], the platform override
  /// is updated with this value.
  Future<String> flutterPlatformOverride({
    String platform,
    @required String isolateId,
  }) async {
    final Map<String, dynamic> result = await invokeFlutterExtensionRpcRaw(
      'ext.flutter.platformOverride',
      isolateId: isolateId,
      args: platform != null
        ? <String, dynamic>{'value': platform}
        : <String, String>{},
    );
    if (result != null && result['value'] is String) {
      return result['value'] as String;
    }
    return 'unknown';
  }

  /// Invoke a flutter extension method, if the flutter extension is not
  /// available, returns null.
  Future<Map<String, dynamic>> invokeFlutterExtensionRpcRaw(
    String method, {
    @required String isolateId,
    Map<String, dynamic> args,
  }) async {
    try {

      final vm_service.Response response = await callServiceExtension(
        method,
        args: <String, Object>{
          'isolateId': isolateId,
          ...?args,
        },
      );
      return response.json;
    } on vm_service.RPCError catch (err) {
      // If an application is not using the framework
      if (err.code == RPCErrorCodes.kMethodNotFound) {
        return null;
      }
      rethrow;
    }
  }

  /// List all [FlutterView]s attached to the current VM.
  Future<List<FlutterView>> getFlutterViews() async {
    final vm_service.Response response = await callMethod(
      kListViewsMethod,
    );
    final List<Object> rawViews = response.json['views'] as List<Object>;
    return <FlutterView>[
      for (final Object rawView in rawViews)
        FlutterView.parse(rawView as Map<String, Object>)
    ];
  }

  /// Attempt to retrieve the isolate with id [isolateId], or `null` if it has
  /// been collected.
  Future<vm_service.Isolate> getIsolateOrNull(String isolateId) {
    return getIsolate(isolateId)
      .catchError((dynamic error, StackTrace stackTrace) {
        return null;
      }, test: (dynamic error) => error is vm_service.SentinelException);
  }

  /// Create a new development file system on the device.
  Future<vm_service.Response> createDevFS(String fsName) {
    return callServiceExtension('_createDevFS', args: <String, dynamic>{'fsName': fsName});
  }

  /// Delete an existing file system.
  Future<vm_service.Response> deleteDevFS(String fsName) {
    return callServiceExtension('_deleteDevFS', args: <String, dynamic>{'fsName': fsName});
  }

  Future<vm_service.Response> screenshot() {
    return callServiceExtension(kScreenshotMethod);
  }

  Future<vm_service.Response> screenshotSkp() {
    return callServiceExtension(kScreenshotSkpMethod);
  }

  /// Set the VM timeline flags
  Future<vm_service.Response> setVMTimelineFlags(List<String> recordedStreams) {
    assert(recordedStreams != null);
    return callServiceExtension(
      'setVMTimelineFlags',
      args: <String, dynamic>{
        'recordedStreams': recordedStreams,
      },
    );
  }

  Future<vm_service.Response> getVMTimeline() {
    return callServiceExtension('getVMTimeline');
  }
}

/// Whether the event attached to an [Isolate.pauseEvent] should be considered
/// a "pause" event.
bool isPauseEvent(String kind) {
  return kind == vm_service.EventKind.kPauseStart ||
         kind == vm_service.EventKind.kPauseExit ||
         kind == vm_service.EventKind.kPauseBreakpoint ||
         kind == vm_service.EventKind.kPauseInterrupted ||
         kind == vm_service.EventKind.kPauseException ||
         kind == vm_service.EventKind.kPausePostRequest ||
         kind == vm_service.EventKind.kNone;
}
