// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show BASE64;
import 'dart:io';

import 'package:json_rpc_2/json_rpc_2.dart' as rpc;
import 'package:json_rpc_2/error_code.dart' as rpc_error_code;
import 'package:web_socket_channel/io.dart';

import 'globals.dart';

/// A connection to the Dart VM Service.
class VMService {
  VMService._(this.peer, this.port, this.httpAddress) {
    _vm = new VM._empty(this);

    peer.registerMethod('streamNotify', (rpc.Parameters event) {
      _handleStreamNotify(event.asMap);
    });
  }

  /// Connect to '127.0.0.1' at [port].
  static Future<VMService> connect(int port) async {
    Uri uri = new Uri(scheme: 'ws', host: '127.0.0.1', port: port, path: 'ws');
    WebSocket ws = await WebSocket.connect(uri.toString());
    rpc.Peer peer = new rpc.Peer(new IOWebSocketChannel(ws).cast());
    peer.listen();
    Uri httpAddress = new Uri(scheme: 'http', host: '127.0.0.1', port: port);
    return new VMService._(peer, port, httpAddress);
  }
  final Uri httpAddress;
  final int port;
  final rpc.Peer peer;

  VM _vm;
  /// The singleton [VM] object. Owns [Isolate] and [FlutterView] objects.
  VM get vm => _vm;

  final Map<String, StreamController<ServiceEvent>> _eventControllers =
      <String, StreamController<ServiceEvent>>{};

  Set<String> _listeningFor = new Set<String>();

  bool get isClosed => peer.isClosed;
  Future<Null> get done => peer.done;

  // Events
  Stream<ServiceEvent> get onDebugEvent => onEvent('Debug');
  Stream<ServiceEvent> get onExtensionEvent => onEvent('Extension');
  // IsolateStart, IsolateRunnable, IsolateExit, IsolateUpdate, ServiceExtensionAdded
  Stream<ServiceEvent> get onIsolateEvent => onEvent('Isolate');
  Stream<ServiceEvent> get onTimelineEvent => onEvent('Timeline');
  // TODO(johnmccutchan): Add FlutterView events.

  // Listen for a specific event name.
  Stream<ServiceEvent> onEvent(String streamId) {
    _streamListen(streamId);
    return _getEventController(streamId).stream;
  }

  StreamController<ServiceEvent> _getEventController(String eventName) {
    StreamController<ServiceEvent> controller = _eventControllers[eventName];
    if (controller == null) {
      controller = new StreamController<ServiceEvent>.broadcast();
      _eventControllers[eventName] = controller;
    }
    return controller;
  }

  void _handleStreamNotify(Map<String, dynamic> data) {
    final String streamId = data['streamId'];
    final Map<String, dynamic> eventData = data['event'];
    final Map<String, dynamic> eventIsolate = eventData['isolate'];
    ServiceEvent event;
    if (eventIsolate != null) {
      // getFromMap creates the Isolate if necessary.
      Isolate isolate = vm.getFromMap(eventIsolate);
      event = new ServiceObject._fromMap(isolate, eventData);
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
      event = new ServiceObject._fromMap(vm, eventData);
    }
    _getEventController(streamId).add(event);
  }

  Future<Null> _streamListen(String streamId) async {
    if (!_listeningFor.contains(streamId)) {
      _listeningFor.add(streamId);
      await peer.sendRequest('streamListen',
                             <String, dynamic>{ 'streamId': streamId });
    }
  }

  /// Reloads the VM.
  Future<VM> getVM() {
    return _vm.reload();
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
String _stripRef(String type) => (_hasRef(type) ? type.substring(1) : type);

/// Given a raw response from the service protocol and a [ServiceObjectOwner],
/// recursively walk the response and replace values that are service maps with
/// actual [ServiceObject]s. During the upgrade the owner is given a chance
/// to return a cached / canonicalized object.
void _upgradeCollection(dynamic collection,
                        ServiceObjectOwner owner) {
  if (collection is ServiceMap) {
    return;
  }
  if (collection is Map) {
    _upgradeMap(collection, owner);
  } else if (collection is List) {
    _upgradeList(collection, owner);
  }
}

void _upgradeMap(Map<String, dynamic> map, ServiceObjectOwner owner) {
  map.forEach((String k, dynamic v) {
    if ((v is Map) && _isServiceMap(v)) {
      map[k] = owner.getFromMap(v);
    } else if (v is List) {
      _upgradeList(v, owner);
    } else if (v is Map) {
      _upgradeMap(v, owner);
    }
  });
}

void _upgradeList(List<dynamic> list, ServiceObjectOwner owner) {
  for (int i = 0; i < list.length; i++) {
    dynamic v = list[i];
    if ((v is Map) && _isServiceMap(v)) {
      list[i] = owner.getFromMap(v);
    } else if (v is List) {
      _upgradeList(v, owner);
    } else if (v is Map) {
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
  factory ServiceObject._fromMap(ServiceObjectOwner owner,
                                 Map<String, dynamic> map) {
    if (map == null)
      return null;

    if (!_isServiceMap(map))
      throw new VMServiceObjectLoadError("Expected a service map", map);

    String type = _stripRef(map['type']);

    ServiceObject serviceObject;
    switch (type) {
      case 'Event':
        serviceObject = new ServiceEvent._empty(owner);
      break;
      case 'FlutterView':
        serviceObject = new FlutterView._empty(owner.vm);
      break;
      case 'Isolate':
        serviceObject = new Isolate._empty(owner.vm);
      break;
      default:
        printTrace("Unsupported service object type: $type");
    }
    if (serviceObject == null) {
      // If we don't have a model object for this service object type, as a
      // fallback return a ServiceMap object.
      serviceObject = new ServiceMap._empty(owner);
    }
    // We have now constructed an emtpy service object, call update to
    // populate it.
    serviceObject.update(map);
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
    Map<String, dynamic> params = <String, dynamic>{
      'objectId': id,
    };
    return _owner.isolate.invokeRpcRaw('getObject', params);
  }

  Future<ServiceObject> _inProgressReload;
  /// Reload the service object (if possible).
  Future<ServiceObject> reload() async {
    bool hasId = (id != null) && (id != '');
    bool isVM = this is VM;
    // We should always reload the VM.
    // We can't reload objects without an id.
    // We shouldn't reload an immutable and already loaded object.
    bool skipLoad = !isVM && (!hasId || (immutable && loaded));
    if (skipLoad) {
      return this;
    }

    if (_inProgressReload == null) {
      Completer<ServiceObject> completer = new Completer<ServiceObject>();
      _inProgressReload = completer.future;

      try {
        Map<String, dynamic> response = await _fetchDirect();
        if (_stripRef(response['type']) == 'Sentinel') {
          // An object may have been collected.
          completer.complete(new ServiceObject._fromMap(owner, response));
        } else {
          update(response);
          completer.complete(this);
        }
      } catch (e, st) {
        completer.completeError(e, st);
      }
      _inProgressReload = null;
    }

    return _inProgressReload;
  }

  /// Update [this] using [map] as a source. [map] can be a service reference.
  void update(Map<String, dynamic> map) {
    // Don't allow the type to change on an object update.
    final bool mapIsRef = _hasRef(map['type']);
    final String mapType = _stripRef(map['type']);

    if ((_type != null) && (_type != mapType)) {
      throw new VMServiceObjectLoadError("ServiceObject types must not change",
                                         map);
    }
    _type = mapType;
    _vmType = map.containsKey('_vmType') ? _stripRef(map['_vmType']) : _type;

    _canCache = map['fixedId'] == true;
    if ((_id != null) && (_id != map['id']) && _canCache) {
      throw new VMServiceObjectLoadError("ServiceObject id changed", map);
    }
    _id = map['id'];

    // Copy name properties.
    _name = map['name'];
    _vmName = map.containsKey('_vmName') ? map['_vmName'] : _name;

    // We have now updated all common properties, let the subclasses update
    // their specific properties.
    _update(map, mapIsRef);
  }

  /// Implemented by subclasses to populate their model.
  void _update(Map<String, dynamic> map, bool mapIsRef);
}

class ServiceEvent extends ServiceObject {
  /// The possible 'kind' values.
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

  ServiceEvent._empty(ServiceObjectOwner owner) : super._empty(owner);

  String _kind;
  String get kind => _kind;
  DateTime _timestamp;
  DateTime get timestmap => _timestamp;
  String _extensionKind;
  String get extensionKind => _extensionKind;
  Map<String, dynamic> _extensionData;
  Map<String, dynamic> get extensionData => _extensionData;
  List<Map<String, dynamic>> _timelineEvents;
  List<Map<String, dynamic>> get timelineEvents => _timelineEvents;

  @override
  void _update(Map<String, dynamic> map, bool mapIsRef) {
    _loaded = true;
    _upgradeCollection(map, owner);
    _kind = map['kind'];
    assert(map['isolate'] == null || owner == map['isolate']);
    _timestamp =
        new DateTime.fromMillisecondsSinceEpoch(map['timestamp']);
    if (map['extensionKind'] != null) {
      _extensionKind = map['extensionKind'];
      _extensionData = map['extensionData'];
    }
    _timelineEvents = map['timelineEvents'];
  }

  bool get isPauseEvent {
    return (kind == kPauseStart ||
            kind == kPauseExit ||
            kind == kPauseBreakpoint ||
            kind == kPauseInterrupted ||
            kind == kPauseException ||
            kind == kNone);
  }
}

/// A ServiceObjectOwner is either a [VM] or an [Isolate]. Owners can cache
/// and/or canonicalize service objets received over the wire.
abstract class ServiceObjectOwner extends ServiceObject {
  ServiceObjectOwner._empty(ServiceObjectOwner owner) : super._empty(owner);

  /// Returns the owning VM.
  VM get vm => null;

  /// Returns the owning isolate (if any).
  Isolate get isolate => null;

  /// Returns the vmService connection.
  VMService get vmService => null;

  /// Builds a [ServiceObject] corresponding to the [id] from [map].
  /// The result may come from the cache.  The result will not necessarily
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
  Future<Map<String, dynamic>> _fetchDirect() async {
    return invokeRpcRaw('getVM', <String, dynamic> {});
  }

  @override
  void _update(Map<String, dynamic> map, bool mapIsRef) {
    if (mapIsRef)
      return;

    // Upgrade the collection. A side effect of this call is that any new
    // isolates in the map are created and added to the isolate cache.
    _upgradeCollection(map, this);
    _loaded = true;

    // TODO(johnmccutchan): Extract any properties we care about here.

    // Remove any isolates which are now dead from the isolate cache.
    _removeDeadIsolates(map['isolates']);
  }

  final Map<String, ServiceObject> _cache = new Map<String,ServiceObject>();
  final Map<String,Isolate> _isolateCache = new Map<String,Isolate>();

  /// The list of live isolates, ordered by isolate start time.
  final List<Isolate> isolates = new List<Isolate>();

  /// The set of live views.
  final Map<String, FlutterView> _viewCache = new Map<String, FlutterView>();

  int _compareIsolates(Isolate a, Isolate b) {
    DateTime aStart = a.startTime;
    DateTime bStart = b.startTime;
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
    List<Isolate> isolateList = _isolateCache.values.toList();
    isolateList.sort(_compareIsolates);
    isolates.clear();
    isolates.addAll(isolateList);
  }

  void _removeDeadIsolates(List<Isolate> newIsolates) {
    // Build a set of new isolates.
    Set<String> newIsolateSet = new Set<String>();
    newIsolates.forEach((Isolate iso) => newIsolateSet.add(iso.id));

    // Remove any old isolates which no longer exist.
    List<String> toRemove = <String>[];
    _isolateCache.forEach((String id, _) {
      if (!newIsolateSet.contains(id)) {
        toRemove.add(id);
      }
    });
    toRemove.forEach((String id) => _isolateCache.remove(id));
    _buildIsolateList();
  }

  @override
  ServiceObject getFromMap(Map<String, dynamic> map) {
    if (map == null) {
      return null;
    }
    String type = _stripRef(map['type']);
    if (type == 'VM') {
      // Update this VM object.
      update(map);
      return this;
    }

    String mapId = map['id'];

    switch (type) {
      case 'Isolate': {
        // Check cache.
        Isolate isolate = _isolateCache[mapId];
        if (isolate == null) {
          // Add new isolate to the cache.
          isolate = new ServiceObject._fromMap(this, map);
          _isolateCache[mapId] = isolate;
          _buildIsolateList();

          // Eagerly load the isolate.
          isolate.load().catchError((dynamic e, StackTrace stack) {
            printTrace('Eagerly loading an isolate failed: $e\n$stack');
          });
        } else {
          // Existing isolate, update data.
          isolate.update(map);
        }
        return isolate;
      }
      break;
      case 'FlutterView': {
        FlutterView view = _viewCache[mapId];
        if (view == null) {
          // Add new view to the cache.
          view = new ServiceObject._fromMap(this, map);
          _viewCache[mapId] = view;
        } else {
          view.update(map);
        }
        return view;
      }
      break;
      default:
        throw new VMServiceObjectLoadError(
            'VM.getFromMap called for something other than an isolate', map);
    }
  }

  // Note that this function does not reload the isolate if it found
  // in the cache.
  Future<Isolate> getIsolate(String isolateId) {
    if (!loaded) {
      // Trigger a VM load, then get the isolate. Ignore any errors.
      return load().then((_) => getIsolate(isolateId)).catchError((_) => null);
    }
    return new Future<Isolate>.value(_isolateCache[isolateId]);
  }

  /// Invoke the RPC and return the raw response.
  Future<Map<String, dynamic>> invokeRpcRaw(
      String method, [Map<String, dynamic> params]) async {
    if (params == null) {
      params = <String, dynamic>{};
    }
    Map<String, dynamic> result =
        await _vmService.peer.sendRequest(method, params);
    return result;
  }

  /// Invoke the RPC and return a ServiceObject response.
  Future<ServiceObject> invokeRpc(
      String method, [Map<String, dynamic> params]) async {
    Map<String, dynamic> response = await invokeRpcRaw(method, params);
    ServiceObject serviceObject = new ServiceObject._fromMap(this, response);
    if ((serviceObject != null) && (serviceObject._canCache)) {
      String serviceObjectId = serviceObject.id;
      _cache.putIfAbsent(serviceObjectId, () => serviceObject);
    }
    return serviceObject;
  }

  /// Create a new development file system on the device.
  Future<Map<String, dynamic>> createDevFS(String fsName) async {
    Map<String, dynamic> response =
        await invokeRpcRaw('_createDevFS', <String, dynamic> {
                           'fsName': fsName
                         });
    return response;
  }

  /// List the development file system son the device.
  Future<List<String>> listDevFS() async {
    Map<String, dynamic> response =
        await invokeRpcRaw('_listDevFS', <String, dynamic>{});
    return response['fsNames'];
  }

  // Write one file into a file system.
  Future<Map<String, dynamic>> writeDevFSFile(String fsName, {
    String path,
    List<int> fileContents
  }) {
    assert(path != null);
    assert(fileContents != null);

    return invokeRpcRaw('_writeDevFSFile', <String, dynamic> {
      'fsName': fsName,
      'path': path,
      'fileContents': BASE64.encode(fileContents)
    });
  }

  // Read one file from a file system.
  Future<List<int>> readDevFSFile(String fsName, String path) {
    return invokeRpcRaw('_readDevFSFile', <String, dynamic> {
      'fsName': fsName,
      'path': path
    }).then((Map<String, dynamic> response) {
      return BASE64.decode(response['fileContents']);
    });
  }

  /// The complete list of a file system.
  Future<List<String>> listDevFSFiles(String fsName) {
    return invokeRpcRaw('_listDevFSFiles', <String, dynamic> {
      'fsName': fsName
    }).then((Map<String, dynamic> response) {
      return response['files'];
    });
  }

  /// Delete an existing file system.
  Future<Map<String, dynamic>> deleteDevFS(String fsName) {
    return invokeRpcRaw('_deleteDevFS',  <String, dynamic> { 'fsName': fsName });
  }

  Future<ServiceMap> runInView(String viewId,
                               String main,
                               String packages,
                               String assetsDirectory) {
    return invokeRpc('_flutter.runInView',
                    <String, dynamic> {
                      'viewId': viewId,
                      'mainScript': main,
                      'packagesFile': packages,
                      'assetDirectory': assetsDirectory
                    });
  }

  Future<Map<String, dynamic>> clearVMTimeline() {
    return invokeRpcRaw('_clearVMTimeline', <String, dynamic>{});
  }

  Future<Map<String, dynamic>> setVMTimelineFlags(
      List<String> recordedStreams) {
    assert(recordedStreams != null);

    return invokeRpcRaw('_setVMTimelineFlags', <String, dynamic> {
      'recordedStreams': recordedStreams
    });
  }

  Future<Map<String, dynamic>> getVMTimeline() {
    return invokeRpcRaw('_getVMTimeline', <String, dynamic> {});
  }

  Future<Null> refreshViews() async {
    await vmService.vm.invokeRpc('_flutter.listViews');
  }

  FlutterView get mainView {
    return _viewCache.values.first;
  }
}

/// An isolate running inside the VM. Instances of the Isolate class are always
/// canonicalized.
class Isolate extends ServiceObjectOwner {
  Isolate._empty(ServiceObjectOwner owner) : super._empty(owner);

  @override
  VM get vm => owner;

  @override
  VMService get vmService => vm.vmService;

  @override
  Isolate get isolate => this;

  DateTime startTime;

  final Map<String, ServiceObject> _cache = new Map<String, ServiceObject>();

  @override
  ServiceObject getFromMap(Map<String, dynamic> map) {
    if (map == null) {
      return null;
    }
    String mapType = _stripRef(map['type']);
    if (mapType == 'Isolate') {
      // There are sometimes isolate refs in ServiceEvents.
      return vm.getFromMap(map);
    }

    String mapId = map['id'];
    ServiceObject serviceObject = (mapId != null) ? _cache[mapId] : null;
    if (serviceObject != null) {
      serviceObject.update(map);
      return serviceObject;
    }
    // Build the object from the map directly.
    serviceObject = new ServiceObject._fromMap(this, map);
    if ((serviceObject != null) && serviceObject.canCache) {
      _cache[mapId] = serviceObject;
    }
    return serviceObject;
  }

  @override
  Future<Map<String, dynamic>> _fetchDirect() {
    return invokeRpcRaw('getIsolate', <String, dynamic>{});
  }

  /// Invoke the RPC and return the raw response.
  Future<Map<String, dynamic>> invokeRpcRaw(
      String method, [Map<String, dynamic> params]) {
    // Inject the 'isolateId' parameter.
    if (params == null) {
      params = <String, dynamic>{
        'isolateId': id
      };
    } else {
      params['isolateId'] = id;
    }
    return vm.invokeRpcRaw(method, params);
  }

  /// Invoke the RPC and return a ServiceObject response.
  Future<ServiceObject> invokeRpc(
      String method, Map<String, dynamic> params) async {
    Map<String, dynamic> response = await invokeRpcRaw(method, params);
    return getFromMap(response);
  }

  @override
  void _update(Map<String, dynamic> map, bool mapIsRef) {
    if (mapIsRef) {
      return;
    }
    _loaded = true;

    int startTimeMillis = map['startTime'];
    startTime = new DateTime.fromMillisecondsSinceEpoch(startTimeMillis);

    // TODO(johnmccutchan): Extract any properties we care about here.
    _upgradeCollection(map, this);
  }

  static final int kIsolateReloadBarred = 1005;

  Future<Map<String, dynamic>> reloadSources() async {
    try {
      Map<String, dynamic> response = await invokeRpcRaw('_reloadSources');
      return response;
    } on rpc.RpcException catch(e) {
      return new Future<Map<String, dynamic>>.error(<String, dynamic>{
        'code': e.code,
        'message': e.message,
        'data': e.data,
      });
    }
  }

  // Flutter extension methods.

  // Invoke a flutter extension method, if the flutter extension is not
  // available, returns null.
  Future<Map<String, dynamic>> invokeFlutterExtensionRpcRaw(
      String method, [Map<String, dynamic> params]) async {
    try {
      return await invokeRpcRaw(method, params);
    } catch (e) {
      // If an application is not using the framework
      if (_isMethodNotFoundException(e))
        return null;
      rethrow;
    }
  }

  // Debug dump extension methods.

  Future<Map<String, dynamic>> flutterDebugDumpApp() {
    return invokeFlutterExtensionRpcRaw('ext.flutter.debugDumpApp');
  }

  Future<Map<String, dynamic>> flutterDebugDumpRenderTree() {
    return invokeFlutterExtensionRpcRaw('ext.flutter.debugDumpRenderTree');
  }

  // Loader page extension methods.

  void flutterLoaderShowMessage(String message) {
    // Invoke loaderShowMessage; ignore any returned errors.
    invokeRpcRaw('ext.flutter.loaderShowMessage', <String, dynamic> {
      'value': message
    }).catchError((dynamic error) => null);
  }

  void flutterLoaderSetProgress(double progress) {
    // Invoke loaderSetProgress; ignore any returned errors.
    invokeRpcRaw('ext.flutter.loaderSetProgress', <String, dynamic>{
      'loaderSetProgress': progress
    }).catchError((dynamic error) => null);
  }

  void flutterLoaderSetProgressMax(double max) {
    // Invoke loaderSetProgressMax; ignore any returned errors.
    invokeRpcRaw('ext.flutter.loaderSetProgressMax', <String, dynamic>{
      'loaderSetProgressMax': max
    }).catchError((dynamic error) => null);
  }

  static bool _isMethodNotFoundException(dynamic e) {
    return (e is rpc.RpcException) &&
           (e.code == rpc_error_code.METHOD_NOT_FOUND);
  }

  // Reload related extension methods.
  Future<Map<String, dynamic>> flutterReassemble() async {
    return await invokeFlutterExtensionRpcRaw('ext.flutter.reassemble');
  }

  Future<bool> flutterFrameworkPresent() async {
    return (await invokeFlutterExtensionRpcRaw('ext.flutter.frameworkPresent') != null);
  }

  Future<Map<String, dynamic>> uiWindowScheduleFrame() async {
    return await invokeFlutterExtensionRpcRaw('ext.ui.window.scheduleFrame');
  }

  Future<Map<String, dynamic>> flutterEvictAsset(String assetPath) async {
    return await invokeFlutterExtensionRpcRaw('ext.flutter.evict',
        <String, dynamic>{
          'value': assetPath
        }
    );
  }

  // Application control extension methods.
  Future<Map<String, dynamic>> flutterExit() async {
    return await invokeFlutterExtensionRpcRaw('ext.flutter.exit').timeout(
          const Duration(seconds: 2), onTimeout: () => null);
  }
}

class ServiceMap extends ServiceObject implements Map<String, dynamic> {
  ServiceMap._empty(ServiceObjectOwner owner) : super._empty(owner);

  final Map<String, dynamic> _map = new Map<String, dynamic>();

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
  bool containsKey(String k) => _map.containsKey(k);
  @override
  void forEach(Function f) => _map.forEach(f);
  @override
  dynamic putIfAbsent(String key, Function ifAbsent) => _map.putIfAbsent(key, ifAbsent);
  @override
  void remove(String key) => _map.remove(key);
  @override
  dynamic operator [](String k) => _map[k];
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
}

/// Peered to a Android/iOS FlutterView widget on a device.
class FlutterView extends ServiceObject {
  FlutterView._empty(ServiceObjectOwner owner) : super._empty(owner);

  Isolate _uiIsolate;
  Isolate get uiIsolate => _uiIsolate;

  @override
  void _update(Map<String, dynamic> map, bool mapIsRef) {
    _loaded = !mapIsRef;
    _upgradeCollection(map, owner);
    _uiIsolate = map['isolate'];
  }

  // TODO(johnmccutchan): Report errors when running failed.
  Future<Null> runFromSource(String entryPath,
                             String packagesPath,
                             String assetsDirectoryPath) async {
    final String viewId = id;
    // When this completer completes the isolate is running.
    final Completer<Null> completer = new Completer<Null>();
    final StreamSubscription<ServiceEvent> subscription =
      owner.vm.vmService.onIsolateEvent.listen((ServiceEvent event) {
      // TODO(johnmccutchan): Listen to the debug stream and catch initial
      // launch errors.
      if (event.kind == ServiceEvent.kIsolateRunnable) {
        printTrace('Isolate is runnable.');
        completer.complete(null);
      }
    });
    await owner.vm.runInView(viewId,
                             entryPath,
                             packagesPath,
                             assetsDirectoryPath);
    await completer.future;
    await owner.vm.refreshViews();
    await subscription.cancel();
  }

  bool get hasIsolate => _uiIsolate != null;

  @override
  String toString() => id;
}
