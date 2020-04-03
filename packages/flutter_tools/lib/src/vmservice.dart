// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:meta/meta.dart' show required;
import 'package:vm_service/vm_service.dart' as vm_service;

import 'base/common.dart';
import 'base/context.dart';
import 'base/io.dart' as io;
import 'base/utils.dart';
import 'convert.dart' show base64, json, utf8;
import 'device.dart';
import 'globals.dart' as globals;
import 'version.dart';

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
      return versionJson;
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
        final MemoryInfo result = await device.queryMemoryInfo();
        return result.toJson();
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
    // Create an instance of the package:vm_service API in addition to the flutter
    // tool's to allow gradual migration.
    final Completer<void> streamClosedCompleter = Completer<void>();

    final Uri wsUri = httpUri.replace(scheme: 'ws', path: globals.fs.path.join(httpUri.path, 'ws'));
    final io.WebSocket channel = await _openChannel(wsUri.toString(), compression: compression);
    final StreamController<dynamic> primary = StreamController<dynamic>();
    final StreamController<dynamic> secondary = StreamController<dynamic>();
    channel.listen((dynamic data) {
      primary.add(data);
      secondary.add(data);
    }, onDone: ()  {
      primary.close();
      secondary.close();
      streamClosedCompleter.complete();
    }, onError: (dynamic error, StackTrace stackTrace) {
      primary.addError(error, stackTrace);
      secondary.addError(error, stackTrace);
    });

    final vm_service.VmService delegateService = vm_service.VmService(
      primary.stream,
      channel.add,
      log: null,
      disposeHandler: () async {
        streamClosedCompleter.complete();
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
      if (event.kind == ServiceEvent.kIsolateExit) {
        vm._isolateCache.remove(isolate.id);
        vm._buildIsolateList();
      } else if (event.kind == ServiceEvent.kIsolateRunnable) {
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

  /// Reloads the VM.
  Future<void> getVMOld() async => await vm.reload();

  Future<void> refreshViews({ bool waitForViews = false }) => vm.refreshViews(waitForViews: waitForViews);

  Future<void> close() async {
    _delegateService?.dispose();
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
      case 'FlutterView':
        serviceObject = FlutterView._empty(owner.vm);
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

  // The possible 'kind' values.
  static const String kVMUpdate               = 'VMUpdate';
  static const String kIsolateStart           = 'IsolateStart';
  static const String kIsolateRunnable        = 'IsolateRunnable';
  static const String kIsolateExit            = 'IsolateExit';
  static const String kIsolateUpdate          = 'IsolateUpdate';
  static const String kIsolateReload          = 'IsolateReload';
  static const String kIsolateSpawn           = 'IsolateSpawn';
  static const String kServiceExtensionAdded  = 'ServiceExtensionAdded';
  static const String kPauseStart             = 'PauseStart';
  static const String kPauseExit              = 'PauseExit';
  static const String kPauseBreakpoint        = 'PauseBreakpoint';
  static const String kPauseInterrupted       = 'PauseInterrupted';
  static const String kPauseException         = 'PauseException';
  static const String kPausePostRequest       = 'PausePostRequest';
  static const String kNone                   = 'None';
  static const String kResume                 = 'Resume';
  static const String kBreakpointAdded        = 'BreakpointAdded';
  static const String kBreakpointResolved     = 'BreakpointResolved';
  static const String kBreakpointRemoved      = 'BreakpointRemoved';
  static const String kGraph                  = '_Graph';
  static const String kGC                     = 'GC';
  static const String kInspect                = 'Inspect';
  static const String kDebuggerSettingsUpdate = '_DebuggerSettingsUpdate';
  static const String kConnectionClosed       = 'ConnectionClosed';
  static const String kLogging                = '_Logging';
  static const String kExtension              = 'Extension';

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

  bool get isPauseEvent {
    return kind == kPauseStart ||
           kind == kPauseExit ||
           kind == kPauseBreakpoint ||
           kind == kPauseInterrupted ||
           kind == kPauseException ||
           kind == kPausePostRequest ||
           kind == kNone;
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

    _pid = map['pid'] as int;
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

  /// The set of live views.
  final Map<String, FlutterView> _viewCache = <String, FlutterView>{};

  /// The pid of the VM's process.
  int _pid;
  int get pid => _pid;

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
      case 'FlutterView':
        FlutterView view = _viewCache[mapId];
        if (view == null) {
          // Add new view to the cache.
          view = ServiceObject._fromMap(this, map) as FlutterView;
          _viewCache[mapId] = view;
        } else {
          view.updateFromMap(map);
        }
        return view;
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

  /// List the development file system son the device.
  Future<List<String>> listDevFS() async {
    return (await invokeRpcRaw('_listDevFS'))['fsNames'] as List<String>;
  }

  // Write one file into a file system.
  Future<Map<String, dynamic>> writeDevFSFile(
    String fsName, {
    @required String path,
    @required List<int> fileContents,
  }) {
    assert(path != null);
    assert(fileContents != null);
    return invokeRpcRaw(
      '_writeDevFSFile',
      params: <String, dynamic>{
        'fsName': fsName,
        'path': path,
        'fileContents': base64.encode(fileContents),
      },
    );
  }

  // Read one file from a file system.
  Future<List<int>> readDevFSFile(String fsName, String path) async {
    final Map<String, dynamic> response = await invokeRpcRaw(
      '_readDevFSFile',
      params: <String, dynamic>{
        'fsName': fsName,
        'path': path,
      },
    );
    return base64.decode(response['fileContents'] as String);
  }

  /// The complete list of a file system.
  Future<List<String>> listDevFSFiles(String fsName) async {
    return (await invokeRpcRaw('_listDevFSFiles', params: <String, dynamic>{'fsName': fsName}))['files'] as List<String>;
  }

  /// Delete an existing file system.
  Future<Map<String, dynamic>> deleteDevFS(String fsName) {
    return invokeRpcRaw('_deleteDevFS', params: <String, dynamic>{'fsName': fsName});
  }

  Future<ServiceMap> runInView(
    String viewId,
    Uri main,
    Uri assetsDirectory,
  ) {
    return invokeRpc<ServiceMap>('_flutter.runInView',
      params: <String, dynamic>{
        'viewId': viewId,
        'mainScript': main.toString(),
        'assetDirectory': assetsDirectory.toString(),
    });
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

  Future<void> refreshViews({ bool waitForViews = false }) async {
    assert(waitForViews != null);
    assert(loaded);
    if (!isFlutterEngine) {
      return;
    }
    int failCount = 0;
    while (true) {
      _viewCache.clear();
      // When the future returned by invokeRpc() below returns,
      // the _viewCache will have been updated.
      // This message updates all the views of every isolate.
      await vmService.vm.invokeRpc<ServiceObject>(
          '_flutter.listViews', truncateLogs: false);
      if (_viewCache.values.isNotEmpty || !waitForViews) {
        return;
      }
      failCount += 1;
      if (failCount == 5) { // waited 200ms
        globals.printStatus('Flutter is taking longer than expected to report its views. Still trying...');
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await reload();
    }
  }

  Iterable<FlutterView> get views => _viewCache.values;

  FlutterView get firstView {
    return _viewCache.values.isEmpty ? null : _viewCache.values.first;
  }

  List<FlutterView> allViewsWithName(String isolateFilter) {
    if (_viewCache.values.isEmpty) {
      return null;
    }
    return _viewCache.values.where(
      (FlutterView v) => v.uiIsolate.name.contains(isolateFilter)
    ).toList();
  }
}

class HeapSpace extends ServiceObject {
  HeapSpace._empty(ServiceObjectOwner owner) : super._empty(owner);

  int _used = 0;
  int _capacity = 0;
  int _external = 0;
  int _collections = 0;
  double _totalCollectionTimeInSeconds = 0.0;
  double _averageCollectionPeriodInMillis = 0.0;

  int get used => _used;
  int get capacity => _capacity;
  int get external => _external;

  Duration get avgCollectionTime {
    final double mcs = _totalCollectionTimeInSeconds *
      Duration.microsecondsPerSecond /
      math.max(_collections, 1);
    return Duration(microseconds: mcs.ceil());
  }

  Duration get avgCollectionPeriod {
    final double mcs = _averageCollectionPeriodInMillis *
                       Duration.microsecondsPerMillisecond;
    return Duration(microseconds: mcs.ceil());
  }

  @override
  void _update(Map<String, dynamic> map, bool mapIsRef) {
    _used = map['used'] as int;
    _capacity = map['capacity'] as int;
    _external = map['external'] as int;
    _collections = map['collections'] as int;
    _totalCollectionTimeInSeconds = map['time'] as double;
    _averageCollectionPeriodInMillis = map['avgCollectionPeriodMillis'] as double;
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

  HeapSpace _newSpace;
  HeapSpace _oldSpace;

  HeapSpace get newSpace => _newSpace;
  HeapSpace get oldSpace => _oldSpace;

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

  /// Invoke the RPC and return a ServiceObject response.
  Future<ServiceObject> invokeRpc(String method, Map<String, dynamic> params) async {
    return getFromMap(await invokeRpcRaw(method, params: params));
  }

  void _updateHeaps(Map<String, dynamic> map, bool mapIsRef) {
    _newSpace ??= HeapSpace._empty(this);
    _newSpace._update(castStringKeyedMap(map['new']), mapIsRef);
    _oldSpace ??= HeapSpace._empty(this);
    _oldSpace._update(castStringKeyedMap(map['old']), mapIsRef);
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

    _updateHeaps(castStringKeyedMap(map['_heaps']), mapIsRef);
  }

  static const int kIsolateReloadBarred = 1005;

  Future<Map<String, dynamic>> reloadSources({
    bool pause = false,
    Uri rootLibUri,
  }) async {
    try {
      final Map<String, dynamic> arguments = <String, dynamic>{
        'pause': pause,
      };
      if (rootLibUri != null) {
        arguments['rootLibUri'] = rootLibUri.toString();
      }
      final Map<String, dynamic> response = await invokeRpcRaw('_reloadSources', params: arguments);
      return response;
    } on vm_service.RPCError catch (e) {
      return Future<Map<String, dynamic>>.value(<String, dynamic>{
        'code': e.code,
        'message': e.message,
        'data': e.data,
      });
    } on vm_service.SentinelException catch (e) {
      throwToolExit('Unexpected Sentinel while reloading sources: $e');
    }
    assert(false);
    return null;
  }

  Future<Map<String, dynamic>> getObject(Map<String, dynamic> objectRef) {
    return invokeRpcRaw('getObject',
                        params: <String, dynamic>{'objectId': objectRef['id']});
  }

  /// Resumes the isolate.
  Future<Map<String, dynamic>> resume() {
    return invokeRpcRaw('resume');
  }

  // Flutter extension methods.

  // Invoke a flutter extension method, if the flutter extension is not
  // available, returns null.
  Future<Map<String, dynamic>> invokeFlutterExtensionRpcRaw(
    String method, {
    Map<String, dynamic> params,
  }) async {
    try {
      return await invokeRpcRaw(method, params: params);
    } on vm_service.RPCError catch (err) {
      // If an application is not using the framework
      if (err.code == RPCErrorCodes.kMethodNotFound) {
        return null;
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> flutterDebugDumpApp() {
    return invokeFlutterExtensionRpcRaw('ext.flutter.debugDumpApp');
  }

  Future<Map<String, dynamic>> flutterDebugDumpRenderTree() {
    return invokeFlutterExtensionRpcRaw('ext.flutter.debugDumpRenderTree');
  }

  Future<Map<String, dynamic>> flutterDebugDumpLayerTree() {
    return invokeFlutterExtensionRpcRaw('ext.flutter.debugDumpLayerTree');
  }

  Future<Map<String, dynamic>> flutterDebugDumpSemanticsTreeInTraversalOrder() {
    return invokeFlutterExtensionRpcRaw('ext.flutter.debugDumpSemanticsTreeInTraversalOrder');
  }

  Future<Map<String, dynamic>> flutterDebugDumpSemanticsTreeInInverseHitTestOrder() {
    return invokeFlutterExtensionRpcRaw('ext.flutter.debugDumpSemanticsTreeInInverseHitTestOrder');
  }

  Future<Map<String, dynamic>> _flutterToggle(String name) async {
    Map<String, dynamic> state = await invokeFlutterExtensionRpcRaw('ext.flutter.$name');
    if (state != null && state.containsKey('enabled') && state['enabled'] is String) {
      state = await invokeFlutterExtensionRpcRaw(
        'ext.flutter.$name',
        params: <String, dynamic>{'enabled': state['enabled'] == 'true' ? 'false' : 'true'},
      );
    }
    return state;
  }

  Future<Map<String, dynamic>> flutterToggleDebugPaintSizeEnabled() => _flutterToggle('debugPaint');

  Future<Map<String, dynamic>> flutterToggleDebugCheckElevationsEnabled() => _flutterToggle('debugCheckElevationsEnabled');

  Future<Map<String, dynamic>> flutterTogglePerformanceOverlayOverride() => _flutterToggle('showPerformanceOverlay');

  Future<Map<String, dynamic>> flutterToggleWidgetInspector() => _flutterToggle('inspector.show');

  Future<Map<String, dynamic>> flutterToggleProfileWidgetBuilds() => _flutterToggle('profileWidgetBuilds');

  Future<Map<String, dynamic>> flutterDebugAllowBanner(bool show) {
    return invokeFlutterExtensionRpcRaw(
      'ext.flutter.debugAllowBanner',
      params: <String, dynamic>{'enabled': show ? 'true' : 'false'},
    );
  }

  Future<Map<String, dynamic>> flutterReassemble() {
    return invokeFlutterExtensionRpcRaw('ext.flutter.reassemble');
  }

  Future<Map<String, dynamic>> flutterFastReassemble(String classId) {
    return invokeFlutterExtensionRpcRaw('ext.flutter.fastReassemble', params: <String, Object>{
      'class': classId,
    });
  }

  Future<bool> flutterAlreadyPaintedFirstUsefulFrame() async {
    final Map<String, dynamic> result = await invokeFlutterExtensionRpcRaw('ext.flutter.didSendFirstFrameRasterizedEvent');
    // result might be null when the service extension is not initialized
    return result != null && result['enabled'] == 'true';
  }

  Future<Map<String, dynamic>> uiWindowScheduleFrame() {
    return invokeFlutterExtensionRpcRaw('ext.ui.window.scheduleFrame');
  }

  Future<Map<String, dynamic>> flutterEvictAsset(String assetPath) {
    return invokeFlutterExtensionRpcRaw(
      'ext.flutter.evict',
      params: <String, dynamic>{
        'value': assetPath,
      },
    );
  }

  Future<List<int>> flutterDebugSaveCompilationTrace() async {
    final Map<String, dynamic> result =
      await invokeFlutterExtensionRpcRaw('ext.flutter.saveCompilationTrace');
    if (result != null && result['value'] is List<dynamic>) {
      return (result['value'] as List<dynamic>).cast<int>();
    }
    return null;
  }

  // Application control extension methods.
  Future<Map<String, dynamic>> flutterExit() {
    return invokeFlutterExtensionRpcRaw('ext.flutter.exit');
  }

  Future<String> flutterPlatformOverride([ String platform ]) async {
    final Map<String, dynamic> result = await invokeFlutterExtensionRpcRaw(
      'ext.flutter.platformOverride',
      params: platform != null ? <String, dynamic>{'value': platform} : <String, String>{},
    );
    if (result != null && result['value'] is String) {
      return result['value'] as String;
    }
    return 'unknown';
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
class FlutterView extends ServiceObject {
  FlutterView._empty(ServiceObjectOwner owner) : super._empty(owner);

  Isolate _uiIsolate;
  Isolate get uiIsolate => _uiIsolate;

  @override
  void _update(Map<String, dynamic> map, bool mapIsRef) {
    _loaded = !mapIsRef;
    _upgradeCollection(map, owner);
    _uiIsolate = map['isolate'] as Isolate;
  }

  // TODO(johnmccutchan): Report errors when running failed.
  Future<void> runFromSource(
    Uri entryUri,
    Uri assetsDirectoryUri,
  ) async {
    final String viewId = id;
    // When this completer completes the isolate is running.
    final Completer<void> completer = Completer<void>();
    try {
      await owner.vm.vmService.streamListen('Isolate');
    } on vm_service.RPCError {
      // Do nothing, since the tool is already subscribed.
    }
    final StreamSubscription<vm_service.Event> subscription =
      owner.vm.vmService.onIsolateEvent.listen((vm_service.Event event) {
        if (event.kind == ServiceEvent.kIsolateRunnable) {
          globals.printTrace('Isolate is runnable.');
          if (!completer.isCompleted) {
            completer.complete();
          }
        }
      });
    await owner.vm.runInView(viewId,
                             entryUri,
                             assetsDirectoryUri);
    await completer.future;
    await owner.vm.refreshViews(waitForViews: true);
    await subscription.cancel();
  }

  Future<void> setAssetDirectory(Uri assetsDirectory) async {
    assert(assetsDirectory != null);
    await owner.vmService.vm.invokeRpc<ServiceObject>('_flutter.setAssetBundlePath',
        params: <String, dynamic>{
          'isolateId': _uiIsolate.id,
          'viewId': id,
          'assetDirectory': assetsDirectory.toFilePath(windows: false),
        });
  }

  Future<void> setSemanticsEnabled(bool enabled) async {
    assert(enabled != null);
    await owner.vmService.vm.invokeRpc<ServiceObject>('_flutter.setSemanticsEnabled',
        params: <String, dynamic>{
          'isolateId': _uiIsolate.id,
          'viewId': id,
          'enabled': enabled,
        });
  }

  bool get hasIsolate => _uiIsolate != null;

  Future<void> flushUIThreadTasks() async {
    await owner.vm.invokeRpcRaw('_flutter.flushUIThreadTasks',
      params: <String, dynamic>{'isolateId': _uiIsolate.id});
  }

  @override
  String toString() => id;
}
