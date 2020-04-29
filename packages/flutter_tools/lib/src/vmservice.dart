// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart' show required;
import 'package:vm_service/vm_service.dart' as vm_service;

import 'base/context.dart';
import 'base/io.dart' as io;
import 'base/utils.dart';
import 'convert.dart' show base64, json, utf8;
import 'device.dart';
import 'globals.dart' as globals;
import 'version.dart';

const String kGetSkSLsMethod = '_flutter.getSkSLs';
const String kSetAssetBundlePathMethod = '_flutter.setAssetBundlePath';
const String kFlushUIThreadTasksMethod = '_flutter.flushUIThreadTasks';
const String kRunInViewMethod = '_flutter.runInView';
const String kListViewsMethod = '_flutter.listViews';

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

  /// Application specific error codes.s
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
typedef VMServiceConnector = Future<VMService> Function(Uri httpUri, {
  ReloadSources reloadSources,
  Restart restart,
  CompileExpression compileExpression,
  ReloadMethod reloadMethod,
  io.CompressionOptions compression,
  Device device,
});

/// A connection to the Dart VM Service.
///
/// This also implements the package:vm_service API to enable a gradual migration.
class VMService implements vm_service.VmService {
  VMService(
    this.httpAddress,
    this.wsAddress,
    ReloadSources reloadSources,
    Restart restart,
    CompileExpression compileExpression,
    Device device,
    ReloadMethod reloadMethod,
    this._delegateService,
    this.streamClosedCompleter,
    Stream<dynamic> secondary,
  ) {
    _vm = VM._empty(this);

    // TODO(jonahwilliams): this is temporary to support the current vm_service
    // semantics of update-in-place.
    secondary.listen((dynamic rawData) {
      final String message = rawData as String;
      final dynamic map = json.decode(message);
      if (map != null && map['method'] == 'streamNotify') {
        _handleStreamNotify(map['params'] as Map<String, dynamic>);
      }
    });

    if (reloadSources != null) {
      _delegateService.registerServiceCallback('reloadSources', (Map<String, dynamic> params) async {
        final String isolateId = params['isolateId'].value as String;
        final bool force = params['force'] as bool ?? false;
        final bool pause = params['pause'] as bool ?? false;

        if (isolateId.isEmpty) {
          throw vm_service.RPCError(
            "Invalid 'isolateId': $isolateId",
            RPCErrorCodes.kInvalidParams,
            '',
          );
        }
        try {
          await reloadSources(isolateId, force: force, pause: pause);
          return <String, String>{'type': 'Success'};
        } on vm_service.RPCError {
          rethrow;
        } on Exception catch (e, st) {
          throw vm_service.RPCError(
            'Error during Sources Reload: $e\n$st',
            RPCErrorCodes.kServerError,
            '',
          );
        }
      });
      _delegateService.registerService('reloadSources', 'Flutter Tools');

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
      _delegateService.registerServiceCallback('reloadMethod', (Map<String, dynamic> params) async {
        final String libraryId = params['library'] as String;
        final String classId = params['class'] as String;

        if (libraryId.isEmpty) {
          throw vm_service.RPCError(
            "Invalid 'libraryId': $libraryId",
            RPCErrorCodes.kInvalidParams,
            '',
          );
        }
        if (classId.isEmpty) {
          throw vm_service.RPCError(
            "Invalid 'classId': $classId",
            RPCErrorCodes.kInvalidParams,
            '',
          );
        }

        globals.printTrace('reloadMethod not yet supported, falling back to hot reload');

        try {
          await reloadMethod(
            libraryId: libraryId,
            classId: classId,
          );
          return <String, String>{'type': 'Success'};
        } on vm_service.RPCError {
          rethrow;
        } on Exception catch (e, st) {
          throw vm_service.RPCError('Error during Sources Reload: $e\n$st', -32000, '');
        }
      });
      _delegateService.registerService('reloadMethod', 'Flutter Tools');
    }

    if (restart != null) {
      _delegateService.registerServiceCallback('hotRestart', (Map<String, dynamic> params) async {
        final bool pause = params['pause'] as bool ?? false;
        try {
          await restart(pause: pause);
          return <String, String>{'type': 'Success'};
        } on vm_service.RPCError {
          rethrow;
        } on Exception catch (e, st) {
          throw vm_service.RPCError(
            'Error during Hot Restart: $e\n$st',
            RPCErrorCodes.kServerError,
            '',
          );
        }
      });
      _delegateService.registerService('hotRestart', 'Flutter Tools');
    }

    _delegateService.registerServiceCallback('flutterVersion', (Map<String, dynamic> params) async {
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
    _delegateService.registerService('flutterVersion', 'Flutter Tools');

    if (compileExpression != null) {
      _delegateService.registerServiceCallback('compileExpression', (Map<String, dynamic> params) async {
        final String isolateId = params['isolateId'] as String;
        if (isolateId is! String || isolateId.isEmpty) {
          throw throw vm_service.RPCError(
            "Invalid 'isolateId': $isolateId",
            RPCErrorCodes.kInvalidParams,
            '',
          );
        }
        final String expression = params['expression'] as String;
        if (expression is! String || expression.isEmpty) {
          throw throw vm_service.RPCError(
            "Invalid 'expression': $expression",
            RPCErrorCodes.kInvalidParams,
            '',
          );
        }
        final List<String> definitions = List<String>.from(params['definitions'] as List<dynamic>);
        final List<String> typeDefinitions = List<String>.from(params['typeDefinitions'] as List<dynamic>);
        final String libraryUri = params['libraryUri'] as String;
        final String klass = params['klass'] as String;
        final bool isStatic = params['isStatic'] as bool ?? false;
        try {
          final String kernelBytesBase64 = await compileExpression(isolateId,
              expression, definitions, typeDefinitions, libraryUri, klass,
              isStatic);
          return <String, dynamic>{
            'type': 'Success',
            'result': <String, dynamic>{
              'result': <String, dynamic>{'kernelBytes': kernelBytesBase64},
            },
          };
        } on vm_service.RPCError {
          rethrow;
        } on Exception catch (e, st) {
          throw vm_service.RPCError(
            'Error during expression compilation: $e\n$st',
            RPCErrorCodes.kServerError,
            '',
          );
        }
      });
      _delegateService.registerService('compileExpression', 'Flutter Tools');
    }
    if (device != null) {
      _delegateService.registerServiceCallback('flutterMemoryInfo', (Map<String, dynamic> params) async {
        try {
          final MemoryInfo result = await device.queryMemoryInfo();
          return <String, dynamic>{
            'result': <String, Object>{
              'type': 'Success',
              ...result.toJson(),
            }
          };
        } on Exception catch (e, st) {
          throw vm_service.RPCError(
            'Error during memory info query $e\n$st',
            RPCErrorCodes.kServerError,
            '',
          );
        }
      });
      _delegateService.registerService('flutterMemoryInfo', 'Flutter Tools');
    }
  }

  /// Connect to a Dart VM Service at [httpUri].
  ///
  /// If the [reloadSources] parameter is not null, the 'reloadSources' service
  /// will be registered. The VM Service Protocol allows clients to register
  /// custom services that can be invoked by other clients through the service
  /// protocol itself.
  ///
  /// See: https://github.com/dart-lang/sdk/commit/df8bf384eb815cf38450cb50a0f4b62230fba217
  static Future<VMService> connect(
    Uri httpUri, {
      ReloadSources reloadSources,
      Restart restart,
      CompileExpression compileExpression,
      ReloadMethod reloadMethod,
      io.CompressionOptions compression = io.CompressionOptions.compressionDefault,
      Device device,
    }) async {
    final VMServiceConnector connector = context.get<VMServiceConnector>() ?? VMService._connect;
    return connector(httpUri,
      reloadSources: reloadSources,
      restart: restart,
      compileExpression: compileExpression,
      compression: compression,
      device: device,
      reloadMethod: reloadMethod,
    );
  }

  static Future<VMService> _connect(
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
    final StreamController<dynamic> primary = StreamController<dynamic>();
    final StreamController<dynamic> secondary = StreamController<dynamic>();

    // Create an instance of the package:vm_service API in addition to the flutter
    // tool's to allow gradual migration.
    final Completer<void> streamClosedCompleter = Completer<void>();

    channel.listen((dynamic data) {
      primary.add(data);
      secondary.add(data);
    }, onDone: ()  {
      primary.close();
      secondary.close();
      if (!streamClosedCompleter.isCompleted) {
        streamClosedCompleter.complete();
      }
    }, onError: (dynamic error, StackTrace stackTrace) {
      primary.addError(error, stackTrace);
      secondary.addError(error, stackTrace);
    });
    final vm_service.VmService delegateService = vm_service.VmService(
      primary.stream,
      channel.add,
      log: null,
      disposeHandler: () async {
        if (!streamClosedCompleter.isCompleted) {
          streamClosedCompleter.complete();
        }
        await channel.close();
      },
    );

    final VMService service = VMService(
      httpUri,
      wsUri,
      reloadSources,
      restart,
      compileExpression,
      device,
      reloadMethod,
      delegateService,
      streamClosedCompleter,
      secondary.stream,
    );

    // This call is to ensure we are able to establish a connection instead of
    // keeping on trucking and failing farther down the process.
    await delegateService.getVersion();
    return service;
  }

  final vm_service.VmService _delegateService;
  final Uri httpAddress;
  final Uri wsAddress;
  final Completer<void> streamClosedCompleter;

  VM _vm;
  /// The singleton [VM] object. Owns [Isolate] and [FlutterView] objects.
  VM get vm => _vm;

  final Map<String, StreamController<ServiceEvent>> _eventControllers =
      <String, StreamController<ServiceEvent>>{};

  /// Whether our connection to the VM service has been closed;
  bool get isClosed => streamClosedCompleter.isCompleted;

  Future<void> get done async {
    return streamClosedCompleter.future;
  }

  @override
  Stream<vm_service.Event> get onDebugEvent => onEvent('Debug');

  @override
  Stream<vm_service.Event> get onExtensionEvent => onEvent('Extension');

  @override
  Stream<vm_service.Event> get onIsolateEvent => onEvent('Isolate');

  @override
  Stream<vm_service.Event> get onTimelineEvent => onEvent('Timeline');

  @override
  Stream<vm_service.Event> get onStdoutEvent => onEvent('Stdout');

  @override
  Future<vm_service.Success> streamListen(String streamId) {
    return _delegateService.streamListen(streamId);
  }

  @override
  Stream<vm_service.Event> onEvent(String streamId) {
    return _delegateService.onEvent(streamId);
  }

  @override
  Future<vm_service.Response> callMethod(String method, {
    String isolateId,
    Map<dynamic, dynamic> args,
  }) {
    return _delegateService.callMethod(method, isolateId: isolateId, args: args);
  }

  @override
  Future<void> get onDone => _delegateService.onDone;

  @override
  Future<vm_service.Response> callServiceExtension(String method,
      {String isolateId, Map<Object, Object> args}) {
    return _delegateService.callServiceExtension(method, isolateId: isolateId, args: args);
  }

  @override
  Future<vm_service.VM> getVM() => _delegateService.getVM();

  StreamController<ServiceEvent> _getEventController(String eventName) {
    StreamController<ServiceEvent> controller = _eventControllers[eventName];
    if (controller == null) {
      controller = StreamController<ServiceEvent>.broadcast();
      _eventControllers[eventName] = controller;
    }
    return controller;
  }

  void _handleStreamNotify(Map<String, dynamic> data) {
    final String streamId = data['streamId'] as String;
    final Map<String, dynamic> eventData = castStringKeyedMap(data['event']);
    final Map<String, dynamic> eventIsolate = castStringKeyedMap(eventData['isolate']);

    // Log event information.
    globals.printTrace('Notification from VM: $data');

    ServiceEvent event;
    if (eventIsolate != null) {
      // getFromMap creates the Isolate if necessary.
      final Isolate isolate = vm.getFromMap(eventIsolate) as Isolate;
      event = ServiceObject._fromMap(isolate, eventData) as ServiceEvent;
      if (event.kind == vm_service.EventKind.kIsolateExit) {
        vm._isolateCache.remove(isolate.id);
        vm._buildIsolateList();
      } else if (event.kind == vm_service.EventKind.kIsolateRunnable) {
        // Force reload once the isolate becomes runnable so that we
        // update the root library.
        isolate.reload();
      }
    } else {
      // The event doesn't have an isolate, so it is owned by the VM.
      event = ServiceObject._fromMap(vm, eventData) as ServiceEvent;
    }
    _getEventController(streamId).add(event);
  }

  @override
  Future<vm_service.ScriptList> getScripts(String isolateId) {
    return _delegateService.getScripts(isolateId);
  }

  /// Reloads the VM.
  Future<void> getVMOld() async => await vm.reload();

  Future<void> close() async {
    _delegateService?.dispose();
  }

  @override
  Future<vm_service.ReloadReport> reloadSources(
    String isolateId, {
    bool force,
    bool pause,
    String rootLibUri,
    String packagesUri,
  }) {
    return _delegateService.reloadSources(
      isolateId,
      force: force,
      pause: pause,
      rootLibUri: rootLibUri,
      packagesUri: packagesUri,
    );
  }

  @override
  Future<vm_service.Isolate> getIsolate(String isolateId) {
    return _delegateService.getIsolate(isolateId);
  }

  @override
  Future<vm_service.Success> resume(String isolateId, {String step, int frameIndex}) {
    return _delegateService.resume(isolateId, step: step, frameIndex: frameIndex);
  }

  @override
  Future<vm_service.Success> kill(String isolateId) {
    return _delegateService.kill(isolateId);
  }

  // To enable a gradual migration to package:vm_service
  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnsupportedError('${invocation.memberName} is not currently supported');
  }
}

/// An error that is thrown when constructing/updating a service object.
class VMServiceObjectLoadError {
  VMServiceObjectLoadError(this.message, this.map);
  final String message;
  final Map<String, dynamic> map;
}

bool _isServiceMap(Map<String, dynamic> m) {
  return (m != null) && (m['type'] != null);
}
bool _hasRef(String type) => (type != null) && type.startsWith('@');
String _stripRef(String type) => _hasRef(type) ? type.substring(1) : type;

/// Given a raw response from the service protocol and a [ServiceObjectOwner],
/// recursively walk the response and replace values that are service maps with
/// actual [ServiceObject]s. During the upgrade the owner is given a chance
/// to return a cached / canonicalized object.
void _upgradeCollection(
  dynamic collection,
  ServiceObjectOwner owner,
) {
  if (collection is ServiceMap) {
    return;
  }
  if (collection is Map<String, dynamic>) {
    _upgradeMap(collection, owner);
  } else if (collection is List) {
    _upgradeList(collection, owner);
  }
}

void _upgradeMap(Map<String, dynamic> map, ServiceObjectOwner owner) {
  map.forEach((String k, Object v) {
    if ((v is Map<String, dynamic>) && _isServiceMap(v)) {
      map[k] = owner.getFromMap(v);
    } else if (v is List) {
      _upgradeList(v, owner);
    } else if (v is Map<String, dynamic>) {
      _upgradeMap(v, owner);
    }
  });
}

void _upgradeList(List<dynamic> list, ServiceObjectOwner owner) {
  for (int i = 0; i < list.length; i += 1) {
    final Object v = list[i];
    if ((v is Map<String, dynamic>) && _isServiceMap(v)) {
      list[i] = owner.getFromMap(v);
    } else if (v is List) {
      _upgradeList(v, owner);
    } else if (v is Map<String, dynamic>) {
      _upgradeMap(v, owner);
    }
  }
}

/// Base class of all objects received over the service protocol.
abstract class ServiceObject {
  ServiceObject._empty(this._owner);

  /// Factory constructor given a [ServiceObjectOwner] and a service map,
  /// upgrade the map into a proper [ServiceObject]. This function always
  /// returns a new instance and does not interact with caches.
  factory ServiceObject._fromMap(
    ServiceObjectOwner owner,
    Map<String, dynamic> map,
  ) {
    if (map == null) {
      return null;
    }

    if (!_isServiceMap(map)) {
      throw VMServiceObjectLoadError('Expected a service map', map);
    }

    final String type = _stripRef(map['type'] as String);

    ServiceObject serviceObject;
    switch (type) {
      case 'Event':
        serviceObject = ServiceEvent._empty(owner);
        break;
      case 'Isolate':
        serviceObject = Isolate._empty(owner.vm);
        break;
    }
    // If we don't have a model object for this service object type, as a
    // fallback return a ServiceMap object.
    serviceObject ??= ServiceMap._empty(owner);
    // We have now constructed an empty service object, call update to populate it.
    serviceObject.updateFromMap(map);
    return serviceObject;
  }

  final ServiceObjectOwner _owner;
  ServiceObjectOwner get owner => _owner;

  /// The id of this object.
  String get id => _id;
  String _id;

  /// The user-level type of this object.
  String get type => _type;
  String _type;

  /// The vm-level type of this object. Usually the same as [type].
  String get vmType => _vmType;
  String _vmType;

  /// Is it safe to cache this object?
  bool _canCache = false;
  bool get canCache => _canCache;

  /// Has this object been fully loaded?
  bool get loaded => _loaded;
  bool _loaded = false;

  /// Is this object immutable after it is [loaded]?
  bool get immutable => false;

  String get name => _name;
  String _name;

  String get vmName => _vmName;
  String _vmName;

  /// If this is not already loaded, load it. Otherwise reload.
  Future<ServiceObject> load() async {
    if (loaded) {
      return this;
    }
    return reload();
  }

  /// Fetch this object from vmService and return the response directly.
  Future<Map<String, dynamic>> _fetchDirect() {
    final Map<String, dynamic> params = <String, dynamic>{
      'objectId': id,
    };
    return _owner.isolate.invokeRpcRaw('getObject', params: params);
  }

  Future<ServiceObject> _inProgressReload;
  /// Reload the service object (if possible).
  Future<ServiceObject> reload() async {
    final bool hasId = (id != null) && (id != '');
    final bool isVM = this is VM;
    // We should always reload the VM.
    // We can't reload objects without an id.
    // We shouldn't reload an immutable and already loaded object.
    if (!isVM && (!hasId || (immutable && loaded))) {
      return this;
    }

    if (_inProgressReload == null) {
      final Completer<ServiceObject> completer = Completer<ServiceObject>();
      _inProgressReload = completer.future;
      try {
        final Map<String, dynamic> response = await _fetchDirect();
        if (_stripRef(response['type'] as String) == 'Sentinel') {
          // An object may have been collected.
          completer.complete(ServiceObject._fromMap(owner, response));
        } else {
          updateFromMap(response);
          completer.complete(this);
        }
      // Catches all exceptions to propagate to the completer.
      } catch (e, st) { // ignore: avoid_catches_without_on_clauses
        completer.completeError(e, st);
      }
      _inProgressReload = null;
      return await completer.future;
    }

    return await _inProgressReload;
  }

  /// Update [this] using [map] as a source. [map] can be a service reference.
  void updateFromMap(Map<String, dynamic> map) {
    // Don't allow the type to change on an object update.
    final bool mapIsRef = _hasRef(map['type'] as String);
    final String mapType = _stripRef(map['type'] as String);

    if ((_type != null) && (_type != mapType)) {
      throw VMServiceObjectLoadError('ServiceObject types must not change',
                                         map);
    }
    _type = mapType;
    _vmType = map.containsKey('_vmType') ? _stripRef(map['_vmType'] as String) : _type;

    _canCache = map['fixedId'] == true;
    if ((_id != null) && (_id != map['id']) && _canCache) {
      throw VMServiceObjectLoadError('ServiceObject id changed', map);
    }
    _id = map['id'] as String;

    // Copy name properties.
    _name = map['name'] as String;
    _vmName = map.containsKey('_vmName') ? map['_vmName'] as String : _name;

    // We have now updated all common properties, let the subclasses update
    // their specific properties.
    _update(map, mapIsRef);
  }

  /// Implemented by subclasses to populate their model.
  void _update(Map<String, dynamic> map, bool mapIsRef);
}

class ServiceEvent extends ServiceObject {
  ServiceEvent._empty(ServiceObjectOwner owner) : super._empty(owner);

  String _kind;
  String get kind => _kind;
  DateTime _timestamp;
  DateTime get timestamp => _timestamp;
  String _extensionKind;
  String get extensionKind => _extensionKind;
  Map<String, dynamic> _extensionData;
  Map<String, dynamic> get extensionData => _extensionData;
  List<Map<String, dynamic>> _timelineEvents;
  List<Map<String, dynamic>> get timelineEvents => _timelineEvents;
  String _message;
  String get message => _message;

  @override
  void _update(Map<String, dynamic> map, bool mapIsRef) {
    _loaded = true;
    _upgradeCollection(map, owner);
    _kind = map['kind'] as String;
    assert(map['isolate'] == null || owner == map['isolate']);
    _timestamp =
        DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int);
    if (map['extensionKind'] != null) {
      _extensionKind = map['extensionKind'] as String;
      _extensionData = castStringKeyedMap(map['extensionData']);
    }
    // map['timelineEvents'] is List<dynamic> which can't be assigned to
    // List<Map<String, dynamic>> directly. Unfortunately, we previously didn't
    // catch this exception because json_rpc_2 is hiding all these exceptions
    // on a Stream.
    final List<dynamic> dynamicList = map['timelineEvents'] as List<dynamic>;
    _timelineEvents = dynamicList?.cast<Map<String, dynamic>>();

     final String base64Bytes = map['bytes'] as String;
     if (base64Bytes != null) {
       _message = utf8.decode(base64.decode(base64Bytes)).trim();
     }
  }
}

/// A ServiceObjectOwner is either a [VM] or an [Isolate]. Owners can cache
/// and/or canonicalize service objects received over the wire.
abstract class ServiceObjectOwner extends ServiceObject {
  ServiceObjectOwner._empty(ServiceObjectOwner owner) : super._empty(owner);

  /// Returns the owning VM.
  VM get vm => null;

  /// Returns the owning isolate (if any).
  Isolate get isolate => null;

  /// Returns the vmService connection.
  VMService get vmService => null;

  /// Builds a [ServiceObject] corresponding to the [id] from [map].
  /// The result may come from the cache. The result will not necessarily
  /// be [loaded].
  ServiceObject getFromMap(Map<String, dynamic> map);
}

/// There is only one instance of the VM class. The VM class owns [Isolate]
/// and [FlutterView] objects.
class VM extends ServiceObjectOwner {
  VM._empty(this._vmService) : super._empty(null);

  /// Connection to the VMService.
  final VMService _vmService;
  @override
  VMService get vmService => _vmService;

  @override
  VM get vm => this;

  @override
  Future<Map<String, dynamic>> _fetchDirect() => invokeRpcRaw('getVM');

  @override
  void _update(Map<String, dynamic> map, bool mapIsRef) {
    if (mapIsRef) {
      return;
    }

    // Upgrade the collection. A side effect of this call is that any new
    // isolates in the map are created and added to the isolate cache.
    _upgradeCollection(map, this);
    _loaded = true;

    if (map['_heapAllocatedMemoryUsage'] != null) {
      _heapAllocatedMemoryUsage = map['_heapAllocatedMemoryUsage'] as int;
    }
    _maxRSS = map['_maxRSS'] as int;
    _embedder = map['_embedder'] as String;

    // Remove any isolates which are now dead from the isolate cache.
    _removeDeadIsolates((map['isolates'] as List<dynamic>).cast<Isolate>());
  }

  final Map<String, ServiceObject> _cache = <String,ServiceObject>{};
  final Map<String,Isolate> _isolateCache = <String,Isolate>{};

  /// The list of live isolates, ordered by isolate start time.
  final List<Isolate> isolates = <Isolate>[];

  /// The number of bytes allocated (e.g. by malloc) in the native heap.
  int _heapAllocatedMemoryUsage;
  int get heapAllocatedMemoryUsage => _heapAllocatedMemoryUsage ?? 0;

  /// The peak resident set size for the process.
  int _maxRSS;
  int get maxRSS => _maxRSS ?? 0;

  // The embedder's name, Flutter or dart_runner.
  String _embedder;
  String get embedder => _embedder;
  bool get isFlutterEngine => embedder == 'Flutter';
  bool get isDartRunner => embedder == 'dart_runner';

  int _compareIsolates(Isolate a, Isolate b) {
    final DateTime aStart = a.startTime;
    final DateTime bStart = b.startTime;
    if (aStart == null) {
      if (bStart == null) {
        return 0;
      } else {
        return 1;
      }
    }
    if (bStart == null) {
      return -1;
    }
    return aStart.compareTo(bStart);
  }

  void _buildIsolateList() {
    final List<Isolate> isolateList = _isolateCache.values.toList();
    isolateList.sort(_compareIsolates);
    isolates.clear();
    isolates.addAll(isolateList);
  }

  void _removeDeadIsolates(List<Isolate> newIsolates) {
    // Build a set of new isolates.
    final Set<String> newIsolateSet = <String>{};
    for (final Isolate iso in newIsolates) {
      newIsolateSet.add(iso.id);
    }

    // Remove any old isolates which no longer exist.
    final List<String> toRemove = <String>[];
    _isolateCache.forEach((String id, _) {
      if (!newIsolateSet.contains(id)) {
        toRemove.add(id);
      }
    });
    toRemove.forEach(_isolateCache.remove);
    _buildIsolateList();
  }

  @override
  ServiceObject getFromMap(Map<String, dynamic> map) {
    if (map == null) {
      return null;
    }
    final String type = _stripRef(map['type'] as String);
    if (type == 'VM') {
      // Update this VM object.
      updateFromMap(map);
      return this;
    }

    final String mapId = map['id'] as String;

    switch (type) {
      case 'Isolate':
        // Check cache.
        Isolate isolate = _isolateCache[mapId];
        if (isolate == null) {
          // Add new isolate to the cache.
          isolate = ServiceObject._fromMap(this, map) as Isolate;
          _isolateCache[mapId] = isolate;
          _buildIsolateList();

          // Eagerly load the isolate.
          isolate.load().catchError((dynamic e, StackTrace stack) {
            globals.printTrace('Eagerly loading an isolate failed: $e\n$stack');
          });
        } else {
          // Existing isolate, update data.
          isolate.updateFromMap(map);
        }
        return isolate;
      default:
        // If we don't have a model object for this service object type, as a
        // fallback return a ServiceMap object.
        final ServiceObject serviceObject = ServiceMap._empty(owner);
        // We have now constructed an empty service object, call update to populate it.
        serviceObject.updateFromMap(map);
        return serviceObject;
    }
  }

  // This function does not reload the isolate if it's found in the cache.
  Future<Isolate> getIsolate(String isolateId) {
    if (!loaded) {
      // Trigger a VM load, then get the isolate. Ignore any errors.
      return load().then<Isolate>((ServiceObject serviceObject) => getIsolate(isolateId)).catchError((dynamic error) => null);
    }
    return Future<Isolate>.value(_isolateCache[isolateId]);
  }

  /// Invoke the RPC and return the raw response.
  Future<Map<String, dynamic>> invokeRpcRaw(
    String method, {
    Map<String, dynamic> params = const <String, dynamic>{},
    bool truncateLogs = true,
  }) async {
    final vm_service.Response response = await _vmService
      ._delegateService.callServiceExtension(method, args: params);
    return response.json;
  }

  /// Invoke the RPC and return a [ServiceObject] response.
  Future<T> invokeRpc<T extends ServiceObject>(
    String method, {
    Map<String, dynamic> params = const <String, dynamic>{},
    bool truncateLogs = true,
  }) async {
    final Map<String, dynamic> response = await invokeRpcRaw(
      method,
      params: params,
      truncateLogs: truncateLogs,
    );
    final T serviceObject = ServiceObject._fromMap(this, response) as T;
    if ((serviceObject != null) && (serviceObject._canCache)) {
      final String serviceObjectId = serviceObject.id;
      _cache.putIfAbsent(serviceObjectId, () => serviceObject);
    }
    return serviceObject;
  }

  /// Create a new development file system on the device.
  Future<Map<String, dynamic>> createDevFS(String fsName) {
    return invokeRpcRaw('_createDevFS', params: <String, dynamic>{'fsName': fsName});
  }

  /// Delete an existing file system.
  Future<Map<String, dynamic>> deleteDevFS(String fsName) {
    return invokeRpcRaw('_deleteDevFS', params: <String, dynamic>{'fsName': fsName});
  }

  Future<Map<String, dynamic>> clearVMTimeline() {
    return invokeRpcRaw('clearVMTimeline');
  }

  Future<Map<String, dynamic>> setVMTimelineFlags(List<String> recordedStreams) {
    assert(recordedStreams != null);
    return invokeRpcRaw(
      'setVMTimelineFlags',
      params: <String, dynamic>{
        'recordedStreams': recordedStreams,
      },
    );
  }

  Future<Map<String, dynamic>> getVMTimeline() {
    return invokeRpcRaw('getVMTimeline');
  }
}

/// An isolate running inside the VM. Instances of the Isolate class are always
/// canonicalized.
class Isolate extends ServiceObjectOwner {
  Isolate._empty(VM owner) : super._empty(owner);

  @override
  VM get vm => owner as VM;

  @override
  VMService get vmService => vm.vmService;

  @override
  Isolate get isolate => this;

  DateTime startTime;

  /// The last pause event delivered to the isolate. If the isolate is running,
  /// this will be a resume event.
  ServiceEvent pauseEvent;

  final Map<String, ServiceObject> _cache = <String, ServiceObject>{};

  @override
  ServiceObject getFromMap(Map<String, dynamic> map) {
    if (map == null) {
      return null;
    }
    final String mapType = _stripRef(map['type'] as String);
    if (mapType == 'Isolate') {
      // There are sometimes isolate refs in ServiceEvents.
      return vm.getFromMap(map);
    }

    final String mapId = map['id'] as String;
    ServiceObject serviceObject = (mapId != null) ? _cache[mapId] : null;
    if (serviceObject != null) {
      serviceObject.updateFromMap(map);
      return serviceObject;
    }
    // Build the object from the map directly.
    serviceObject = ServiceObject._fromMap(this, map);
    if ((serviceObject != null) && serviceObject.canCache) {
      _cache[mapId] = serviceObject;
    }
    return serviceObject;
  }

  @override
  Future<Map<String, dynamic>> _fetchDirect() => invokeRpcRaw('getIsolate');

  /// Invoke the RPC and return the raw response.
  Future<Map<String, dynamic>> invokeRpcRaw(
    String method, {
    Map<String, dynamic> params,
  }) {
    // Inject the 'isolateId' parameter.
    if (params == null) {
      params = <String, dynamic>{
        'isolateId': id,
      };
    } else {
      params['isolateId'] = id;
    }
    return vm.invokeRpcRaw(method, params: params);
  }

  @override
  void _update(Map<String, dynamic> map, bool mapIsRef) {
    if (mapIsRef) {
      return;
    }
    _loaded = true;

    final int startTimeMillis = map['startTime'] as int;
    startTime = DateTime.fromMillisecondsSinceEpoch(startTimeMillis);

    _upgradeCollection(map, this);

    pauseEvent = map['pauseEvent'] as ServiceEvent;
  }

  @override
  String toString() => 'Isolate $id';
}

class ServiceMap extends ServiceObject implements Map<String, dynamic> {
  ServiceMap._empty(ServiceObjectOwner owner) : super._empty(owner);

  final Map<String, dynamic> _map = <String, dynamic>{};

  @override
  void _update(Map<String, dynamic> map, bool mapIsRef) {
    _loaded = !mapIsRef;
    _upgradeCollection(map, owner);
    _map.clear();
    _map.addAll(map);
  }

  // Forward Map interface calls.
  @override
  void addAll(Map<String, dynamic> other) => _map.addAll(other);
  @override
  void clear() => _map.clear();
  @override
  bool containsValue(dynamic v) => _map.containsValue(v);
  @override
  bool containsKey(Object k) => _map.containsKey(k);
  @override
  void forEach(void f(String key, dynamic value)) => _map.forEach(f);
  @override
  dynamic putIfAbsent(String key, dynamic ifAbsent()) => _map.putIfAbsent(key, ifAbsent);
  @override
  void remove(Object key) => _map.remove(key);
  @override
  dynamic operator [](Object k) => _map[k];
  @override
  void operator []=(String k, dynamic v) => _map[k] = v;
  @override
  bool get isEmpty => _map.isEmpty;
  @override
  bool get isNotEmpty => _map.isNotEmpty;
  @override
  Iterable<String> get keys => _map.keys;
  @override
  Iterable<dynamic> get values => _map.values;
  @override
  int get length => _map.length;
  @override
  String toString() => _map.toString();
  @override
  void addEntries(Iterable<MapEntry<String, dynamic>> entries) => _map.addEntries(entries);
  @override
  Map<RK, RV> cast<RK, RV>() => _map.cast<RK, RV>();
  @override
  void removeWhere(bool test(String key, dynamic value)) => _map.removeWhere(test);
  @override
  Map<K2, V2> map<K2, V2>(MapEntry<K2, V2> transform(String key, dynamic value)) => _map.map<K2, V2>(transform);
  @override
  Iterable<MapEntry<String, dynamic>> get entries => _map.entries;
  @override
  void updateAll(dynamic update(String key, dynamic value)) => _map.updateAll(update);
  Map<RK, RV> retype<RK, RV>() => _map.cast<RK, RV>();
  @override
  dynamic update(String key, dynamic update(dynamic value), { dynamic ifAbsent() }) => _map.update(key, update, ifAbsent: ifAbsent);
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
