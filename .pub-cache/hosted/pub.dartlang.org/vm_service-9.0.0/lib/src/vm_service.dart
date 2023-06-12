// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This is a generated file.

/// A library to access the VM Service API.
///
/// The main entry-point for this library is the [VmService] class.

import 'dart:async';
import 'dart:convert' show base64, jsonDecode, jsonEncode, utf8;
import 'dart:typed_data';

import 'service_extension_registry.dart';

export 'service_extension_registry.dart' show ServiceExtensionRegistry;
export 'snapshot_graph.dart'
    show
        HeapSnapshotClass,
        HeapSnapshotExternalProperty,
        HeapSnapshotField,
        HeapSnapshotGraph,
        HeapSnapshotObject,
        HeapSnapshotObjectLengthData,
        HeapSnapshotObjectNoData,
        HeapSnapshotObjectNullData;

const String vmServiceVersion = '3.58.0';

/// @optional
const String optional = 'optional';

/// Decode a string in Base64 encoding into the equivalent non-encoded string.
/// This is useful for handling the results of the Stdout or Stderr events.
String decodeBase64(String str) => utf8.decode(base64.decode(str));

// Returns true if a response is the Dart `null` instance.
bool _isNullInstance(Map json) =>
    ((json['type'] == '@Instance') && (json['kind'] == 'Null'));

Object? createServiceObject(dynamic json, List<String> expectedTypes) {
  if (json == null) return null;

  if (json is List) {
    return json.map((e) => createServiceObject(e, expectedTypes)).toList();
  } else if (json is Map<String, dynamic>) {
    String? type = json['type'];

    // Not a Response type.
    if (type == null) {
      // If there's only one expected type, we'll just use that type.
      if (expectedTypes.length == 1) {
        type = expectedTypes.first;
      } else {
        return Response.parse(json);
      }
    } else if (_isNullInstance(json) &&
        (!expectedTypes.contains('InstanceRef'))) {
      // Replace null instances with null when we don't expect an instance to
      // be returned.
      return null;
    }
    final typeFactory = _typeFactories[type];
    if (typeFactory == null) {
      return null;
    } else {
      return typeFactory(json);
    }
  } else {
    // Handle simple types.
    return json;
  }
}

dynamic _createSpecificObject(
    dynamic json, dynamic creator(Map<String, dynamic> map)) {
  if (json == null) return null;

  if (json is List) {
    return json.map((e) => creator(e)).toList();
  } else if (json is Map) {
    return creator({
      for (String key in json.keys) key: json[key],
    });
  } else {
    // Handle simple types.
    return json;
  }
}

void _setIfNotNull(Map<String, dynamic> json, String key, Object? value) {
  if (value == null) return;
  json[key] = value;
}

Future<T> extensionCallHelper<T>(VmService service, String method, Map args) {
  return service._call(method, args);
}

typedef ServiceCallback = Future<Map<String, dynamic>> Function(
    Map<String, dynamic> params);

void addTypeFactory(String name, Function factory) {
  if (_typeFactories.containsKey(name)) {
    throw StateError('Factory already registered for $name');
  }
  _typeFactories[name] = factory;
}

Map<String, Function> _typeFactories = {
  'AllocationProfile': AllocationProfile.parse,
  'BoundField': BoundField.parse,
  'BoundVariable': BoundVariable.parse,
  'Breakpoint': Breakpoint.parse,
  '@Class': ClassRef.parse,
  'Class': Class.parse,
  'ClassHeapStats': ClassHeapStats.parse,
  'ClassList': ClassList.parse,
  '@Code': CodeRef.parse,
  'Code': Code.parse,
  '@Context': ContextRef.parse,
  'Context': Context.parse,
  'ContextElement': ContextElement.parse,
  'CpuSamples': CpuSamples.parse,
  'CpuSamplesEvent': CpuSamplesEvent.parse,
  'CpuSample': CpuSample.parse,
  '@Error': ErrorRef.parse,
  'Error': Error.parse,
  'Event': Event.parse,
  'ExtensionData': ExtensionData.parse,
  '@Field': FieldRef.parse,
  'Field': Field.parse,
  'Flag': Flag.parse,
  'FlagList': FlagList.parse,
  'Frame': Frame.parse,
  '@Function': FuncRef.parse,
  'Function': Func.parse,
  '@Instance': InstanceRef.parse,
  'Instance': Instance.parse,
  '@Isolate': IsolateRef.parse,
  'Isolate': Isolate.parse,
  'IsolateFlag': IsolateFlag.parse,
  '@IsolateGroup': IsolateGroupRef.parse,
  'IsolateGroup': IsolateGroup.parse,
  'InboundReferences': InboundReferences.parse,
  'InboundReference': InboundReference.parse,
  'InstanceSet': InstanceSet.parse,
  '@Library': LibraryRef.parse,
  'Library': Library.parse,
  'LibraryDependency': LibraryDependency.parse,
  'LogRecord': LogRecord.parse,
  'MapAssociation': MapAssociation.parse,
  'MemoryUsage': MemoryUsage.parse,
  'Message': Message.parse,
  'NativeFunction': NativeFunction.parse,
  '@Null': NullValRef.parse,
  'Null': NullVal.parse,
  '@Object': ObjRef.parse,
  'Object': Obj.parse,
  'Parameter': Parameter.parse,
  'PortList': PortList.parse,
  'ProfileFunction': ProfileFunction.parse,
  'ProtocolList': ProtocolList.parse,
  'Protocol': Protocol.parse,
  'ProcessMemoryUsage': ProcessMemoryUsage.parse,
  'ProcessMemoryItem': ProcessMemoryItem.parse,
  'ReloadReport': ReloadReport.parse,
  'RetainingObject': RetainingObject.parse,
  'RetainingPath': RetainingPath.parse,
  'Response': Response.parse,
  'Sentinel': Sentinel.parse,
  '@Script': ScriptRef.parse,
  'Script': Script.parse,
  'ScriptList': ScriptList.parse,
  'SourceLocation': SourceLocation.parse,
  'SourceReport': SourceReport.parse,
  'SourceReportCoverage': SourceReportCoverage.parse,
  'SourceReportRange': SourceReportRange.parse,
  'Stack': Stack.parse,
  'Success': Success.parse,
  'Timeline': Timeline.parse,
  'TimelineEvent': TimelineEvent.parse,
  'TimelineFlags': TimelineFlags.parse,
  'Timestamp': Timestamp.parse,
  '@TypeArguments': TypeArgumentsRef.parse,
  'TypeArguments': TypeArguments.parse,
  'TypeParameters': TypeParameters.parse,
  'UnresolvedSourceLocation': UnresolvedSourceLocation.parse,
  'UriList': UriList.parse,
  'Version': Version.parse,
  '@VM': VMRef.parse,
  'VM': VM.parse,
};

Map<String, List<String>> _methodReturnTypes = {
  'addBreakpoint': const ['Breakpoint'],
  'addBreakpointWithScriptUri': const ['Breakpoint'],
  'addBreakpointAtEntry': const ['Breakpoint'],
  'clearCpuSamples': const ['Success'],
  'clearVMTimeline': const ['Success'],
  'invoke': const ['InstanceRef', 'ErrorRef'],
  'evaluate': const ['InstanceRef', 'ErrorRef'],
  'evaluateInFrame': const ['InstanceRef', 'ErrorRef'],
  'getAllocationProfile': const ['AllocationProfile'],
  'getAllocationTraces': const ['CpuSamples'],
  'getClassList': const ['ClassList'],
  'getCpuSamples': const ['CpuSamples'],
  'getFlagList': const ['FlagList'],
  'getInboundReferences': const ['InboundReferences'],
  'getInstances': const ['InstanceSet'],
  'getIsolate': const ['Isolate'],
  'getIsolateGroup': const ['IsolateGroup'],
  'getMemoryUsage': const ['MemoryUsage'],
  'getIsolateGroupMemoryUsage': const ['MemoryUsage'],
  'getScripts': const ['ScriptList'],
  'getObject': const ['Obj'],
  'getPorts': const ['PortList'],
  'getRetainingPath': const ['RetainingPath'],
  'getProcessMemoryUsage': const ['ProcessMemoryUsage'],
  'getStack': const ['Stack'],
  'getSupportedProtocols': const ['ProtocolList'],
  'getSourceReport': const ['SourceReport'],
  'getVersion': const ['Version'],
  'getVM': const ['VM'],
  'getVMTimeline': const ['Timeline'],
  'getVMTimelineFlags': const ['TimelineFlags'],
  'getVMTimelineMicros': const ['Timestamp'],
  'pause': const ['Success'],
  'kill': const ['Success'],
  'lookupResolvedPackageUris': const ['UriList'],
  'lookupPackageUris': const ['UriList'],
  'registerService': const ['Success'],
  'reloadSources': const ['ReloadReport'],
  'removeBreakpoint': const ['Success'],
  'requestHeapSnapshot': const ['Success'],
  'resume': const ['Success'],
  'setBreakpointState': const ['Breakpoint'],
  'setExceptionPauseMode': const ['Success'],
  'setIsolatePauseMode': const ['Success'],
  'setFlag': const ['Success', 'Error'],
  'setLibraryDebuggable': const ['Success'],
  'setName': const ['Success'],
  'setTraceClassAllocation': const ['Success'],
  'setVMName': const ['Success'],
  'setVMTimelineFlags': const ['Success'],
  'streamCancel': const ['Success'],
  'streamCpuSamplesWithUserTag': const ['Success'],
  'streamListen': const ['Success'],
};

/// A class representation of the Dart VM Service Protocol.
///
/// Both clients and servers should implement this interface.
abstract class VmServiceInterface {
  /// Returns the stream for a given stream id.
  ///
  /// This is not a part of the spec, but is needed for both the client and
  /// server to get access to the real event streams.
  Stream<Event> onEvent(String streamId);

  /// Handler for calling extra service extensions.
  Future<Response> callServiceExtension(String method,
      {String? isolateId, Map<String, dynamic>? args});

  /// The `addBreakpoint` RPC is used to add a breakpoint at a specific line of
  /// some script.
  ///
  /// The `scriptId` parameter is used to specify the target script.
  ///
  /// The `line` parameter is used to specify the target line for the
  /// breakpoint. If there are multiple possible breakpoints on the target line,
  /// then the VM will place the breakpoint at the location which would execute
  /// soonest. If it is not possible to set a breakpoint at the target line, the
  /// breakpoint will be added at the next possible breakpoint location within
  /// the same function.
  ///
  /// The `column` parameter may be optionally specified. This is useful for
  /// targeting a specific breakpoint on a line with multiple possible
  /// breakpoints.
  ///
  /// If no breakpoint is possible at that line, the `102` (Cannot add
  /// breakpoint) [RPC error] code is returned.
  ///
  /// Note that breakpoints are added and removed on a per-isolate basis.
  ///
  /// If `isolateId` refers to an isolate which has exited, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// See [Breakpoint].
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  Future<Breakpoint> addBreakpoint(
    String isolateId,
    String scriptId,
    int line, {
    int? column,
  });

  /// The `addBreakpoint` RPC is used to add a breakpoint at a specific line of
  /// some script. This RPC is useful when a script has not yet been assigned an
  /// id, for example, if a script is in a deferred library which has not yet
  /// been loaded.
  ///
  /// The `scriptUri` parameter is used to specify the target script.
  ///
  /// The `line` parameter is used to specify the target line for the
  /// breakpoint. If there are multiple possible breakpoints on the target line,
  /// then the VM will place the breakpoint at the location which would execute
  /// soonest. If it is not possible to set a breakpoint at the target line, the
  /// breakpoint will be added at the next possible breakpoint location within
  /// the same function.
  ///
  /// The `column` parameter may be optionally specified. This is useful for
  /// targeting a specific breakpoint on a line with multiple possible
  /// breakpoints.
  ///
  /// If no breakpoint is possible at that line, the `102` (Cannot add
  /// breakpoint) [RPC error] code is returned.
  ///
  /// Note that breakpoints are added and removed on a per-isolate basis.
  ///
  /// If `isolateId` refers to an isolate which has exited, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// See [Breakpoint].
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  Future<Breakpoint> addBreakpointWithScriptUri(
    String isolateId,
    String scriptUri,
    int line, {
    int? column,
  });

  /// The `addBreakpointAtEntry` RPC is used to add a breakpoint at the
  /// entrypoint of some function.
  ///
  /// If no breakpoint is possible at the function entry, the `102` (Cannot add
  /// breakpoint) [RPC error] code is returned.
  ///
  /// If `isolateId` refers to an isolate which has exited, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// See [Breakpoint].
  ///
  /// Note that breakpoints are added and removed on a per-isolate basis.
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  Future<Breakpoint> addBreakpointAtEntry(String isolateId, String functionId);

  /// Clears all CPU profiling samples.
  ///
  /// If `isolateId` refers to an isolate which has exited, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// See [Success].
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  Future<Success> clearCpuSamples(String isolateId);

  /// Clears all VM timeline events.
  ///
  /// See [Success].
  Future<Success> clearVMTimeline();

  /// The `invoke` RPC is used to perform regular method invocation on some
  /// receiver, as if by dart:mirror's ObjectMirror.invoke. Note this does not
  /// provide a way to perform getter, setter or constructor invocation.
  ///
  /// `targetId` may refer to a [Library], [Class], or [Instance].
  ///
  /// Each elements of `argumentId` may refer to an [Instance].
  ///
  /// If `disableBreakpoints` is provided and set to true, any breakpoints hit
  /// as a result of this invocation are ignored, including pauses resulting
  /// from a call to `debugger()` from `dart:developer`. Defaults to false if
  /// not provided.
  ///
  /// If `targetId` or any element of `argumentIds` is a temporary id which has
  /// expired, then the `Expired` [Sentinel] is returned.
  ///
  /// If `targetId` or any element of `argumentIds` refers to an object which
  /// has been collected by the VM's garbage collector, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// If `isolateId` refers to an isolate which has exited, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// If invocation triggers a failed compilation then [RPC error] 113
  /// "Expression compilation error" is returned.
  ///
  /// If a runtime error occurs while evaluating the invocation, an [ErrorRef]
  /// reference will be returned.
  ///
  /// If the invocation is evaluated successfully, an [InstanceRef] reference
  /// will be returned.
  ///
  /// The return value can be one of [InstanceRef] or [ErrorRef].
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  Future<Response> invoke(
    String isolateId,
    String targetId,
    String selector,
    List<String> argumentIds, {
    bool? disableBreakpoints,
  });

  /// The `evaluate` RPC is used to evaluate an expression in the context of
  /// some target.
  ///
  /// `targetId` may refer to a [Library], [Class], or [Instance].
  ///
  /// If `targetId` is a temporary id which has expired, then the `Expired`
  /// [Sentinel] is returned.
  ///
  /// If `targetId` refers to an object which has been collected by the VM's
  /// garbage collector, then the `Collected` [Sentinel] is returned.
  ///
  /// If `isolateId` refers to an isolate which has exited, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// If `scope` is provided, it should be a map from identifiers to object ids.
  /// These bindings will be added to the scope in which the expression is
  /// evaluated, which is a child scope of the class or library for
  /// instance/class or library targets respectively. This means bindings
  /// provided in `scope` may shadow instance members, class members and
  /// top-level members.
  ///
  /// If `disableBreakpoints` is provided and set to true, any breakpoints hit
  /// as a result of this evaluation are ignored. Defaults to false if not
  /// provided.
  ///
  /// If the expression fails to parse and compile, then [RPC error] 113
  /// "Expression compilation error" is returned.
  ///
  /// If an error occurs while evaluating the expression, an [ErrorRef]
  /// reference will be returned.
  ///
  /// If the expression is evaluated successfully, an [InstanceRef] reference
  /// will be returned.
  ///
  /// The return value can be one of [InstanceRef] or [ErrorRef].
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  Future<Response> evaluate(
    String isolateId,
    String targetId,
    String expression, {
    Map<String, String>? scope,
    bool? disableBreakpoints,
  });

  /// The `evaluateInFrame` RPC is used to evaluate an expression in the context
  /// of a particular stack frame. `frameIndex` is the index of the desired
  /// [Frame], with an index of `0` indicating the top (most recent) frame.
  ///
  /// If `scope` is provided, it should be a map from identifiers to object ids.
  /// These bindings will be added to the scope in which the expression is
  /// evaluated, which is a child scope of the frame's current scope. This means
  /// bindings provided in `scope` may shadow instance members, class members,
  /// top-level members, parameters and locals.
  ///
  /// If `disableBreakpoints` is provided and set to true, any breakpoints hit
  /// as a result of this evaluation are ignored. Defaults to false if not
  /// provided.
  ///
  /// If the expression fails to parse and compile, then [RPC error] 113
  /// "Expression compilation error" is returned.
  ///
  /// If an error occurs while evaluating the expression, an [ErrorRef]
  /// reference will be returned.
  ///
  /// If the expression is evaluated successfully, an [InstanceRef] reference
  /// will be returned.
  ///
  /// If `isolateId` refers to an isolate which has exited, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// The return value can be one of [InstanceRef] or [ErrorRef].
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  Future<Response> evaluateInFrame(
    String isolateId,
    int frameIndex,
    String expression, {
    Map<String, String>? scope,
    bool? disableBreakpoints,
  });

  /// The `getAllocationProfile` RPC is used to retrieve allocation information
  /// for a given isolate.
  ///
  /// If `reset` is provided and is set to true, the allocation accumulators
  /// will be reset before collecting allocation information.
  ///
  /// If `gc` is provided and is set to true, a garbage collection will be
  /// attempted before collecting allocation information. There is no guarantee
  /// that a garbage collection will be actually be performed.
  ///
  /// If `isolateId` refers to an isolate which has exited, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  Future<AllocationProfile> getAllocationProfile(String isolateId,
      {bool? reset, bool? gc});

  /// The `getAllocationTraces` RPC allows for the retrieval of allocation
  /// traces for objects of a specific set of types (see
  /// [setTraceClassAllocation]). Only samples collected in the time range
  /// `[timeOriginMicros, timeOriginMicros + timeExtentMicros]` will be
  /// reported.
  ///
  /// If `classId` is provided, only traces for allocations with the matching
  /// `classId` will be reported.
  ///
  /// If the profiler is disabled, an RPC error response will be returned.
  ///
  /// If isolateId refers to an isolate which has exited, then the Collected
  /// Sentinel is returned.
  ///
  /// See [CpuSamples].
  Future<CpuSamples> getAllocationTraces(
    String isolateId, {
    int? timeOriginMicros,
    int? timeExtentMicros,
    String? classId,
  });

  /// The `getClassList` RPC is used to retrieve a `ClassList` containing all
  /// classes for an isolate based on the isolate's `isolateId`.
  ///
  /// If `isolateId` refers to an isolate which has exited, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// See [ClassList].
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  Future<ClassList> getClassList(String isolateId);

  /// The `getCpuSamples` RPC is used to retrieve samples collected by the CPU
  /// profiler. Only samples collected in the time range `[timeOriginMicros,
  /// timeOriginMicros + timeExtentMicros]` will be reported.
  ///
  /// If the profiler is disabled, an [RPC error] response will be returned.
  ///
  /// If `isolateId` refers to an isolate which has exited, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// See [CpuSamples].
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  Future<CpuSamples> getCpuSamples(
      String isolateId, int timeOriginMicros, int timeExtentMicros);

  /// The `getFlagList` RPC returns a list of all command line flags in the VM
  /// along with their current values.
  ///
  /// See [FlagList].
  Future<FlagList> getFlagList();

  /// Returns a set of inbound references to the object specified by `targetId`.
  /// Up to `limit` references will be returned.
  ///
  /// The order of the references is undefined (i.e., not related to allocation
  /// order) and unstable (i.e., multiple invocations of this method against the
  /// same object can give different answers even if no Dart code has executed
  /// between the invocations).
  ///
  /// The references may include multiple `objectId`s that designate the same
  /// object.
  ///
  /// The references may include objects that are unreachable but have not yet
  /// been garbage collected.
  ///
  /// If `targetId` is a temporary id which has expired, then the `Expired`
  /// [Sentinel] is returned.
  ///
  /// If `targetId` refers to an object which has been collected by the VM's
  /// garbage collector, then the `Collected` [Sentinel] is returned.
  ///
  /// If `isolateId` refers to an isolate which has exited, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// See [InboundReferences].
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  Future<InboundReferences> getInboundReferences(
      String isolateId, String targetId, int limit);

  /// The `getInstances` RPC is used to retrieve a set of instances which are of
  /// a specific class. This does not include instances of subclasses of the
  /// given class.
  ///
  /// The order of the instances is undefined (i.e., not related to allocation
  /// order) and unstable (i.e., multiple invocations of this method against the
  /// same class can give different answers even if no Dart code has executed
  /// between the invocations).
  ///
  /// The set of instances may include objects that are unreachable but have not
  /// yet been garbage collected.
  ///
  /// `objectId` is the ID of the `Class` to retrieve instances for. `objectId`
  /// must be the ID of a `Class`, otherwise an [RPC error] is returned.
  ///
  /// `limit` is the maximum number of instances to be returned.
  ///
  /// If `isolateId` refers to an isolate which has exited, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// See [InstanceSet].
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  Future<InstanceSet> getInstances(
      String isolateId, String objectId, int limit);

  /// The `getIsolate` RPC is used to lookup an `Isolate` object by its `id`.
  ///
  /// If `isolateId` refers to an isolate which has exited, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// See [Isolate].
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  Future<Isolate> getIsolate(String isolateId);

  /// The `getIsolateGroup` RPC is used to lookup an `IsolateGroup` object by
  /// its `id`.
  ///
  /// If `isolateGroupId` refers to an isolate group which has exited, then the
  /// `Expired` [Sentinel] is returned.
  ///
  /// `IsolateGroup` `id` is an opaque identifier that can be fetched from an
  /// `IsolateGroup`. List of active `IsolateGroup`'s, for example, is available
  /// on `VM` object.
  ///
  /// See [IsolateGroup], [VM].
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  Future<IsolateGroup> getIsolateGroup(String isolateGroupId);

  /// The `getMemoryUsage` RPC is used to lookup an isolate's memory usage
  /// statistics by its `id`.
  ///
  /// If `isolateId` refers to an isolate which has exited, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// See [Isolate].
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  Future<MemoryUsage> getMemoryUsage(String isolateId);

  /// The `getIsolateGroupMemoryUsage` RPC is used to lookup an isolate group's
  /// memory usage statistics by its `id`.
  ///
  /// If `isolateGroupId` refers to an isolate group which has exited, then the
  /// `Expired` [Sentinel] is returned.
  ///
  /// See [IsolateGroup].
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  Future<MemoryUsage> getIsolateGroupMemoryUsage(String isolateGroupId);

  /// The `getScripts` RPC is used to retrieve a `ScriptList` containing all
  /// scripts for an isolate based on the isolate's `isolateId`.
  ///
  /// If `isolateId` refers to an isolate which has exited, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// See [ScriptList].
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  Future<ScriptList> getScripts(String isolateId);

  /// The `getObject` RPC is used to lookup an `object` from some isolate by its
  /// `id`.
  ///
  /// If `objectId` is a temporary id which has expired, then the `Expired`
  /// [Sentinel] is returned.
  ///
  /// If `isolateId` refers to an isolate which has exited, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// If `objectId` refers to a heap object which has been collected by the VM's
  /// garbage collector, then the `Collected` [Sentinel] is returned.
  ///
  /// If `objectId` refers to a non-heap object which has been deleted, then the
  /// `Collected` [Sentinel] is returned.
  ///
  /// If the object handle has not expired and the object has not been
  /// collected, then an [Obj] will be returned.
  ///
  /// The `offset` and `count` parameters are used to request subranges of
  /// Instance objects with the kinds: String, List, Map, Uint8ClampedList,
  /// Uint8List, Uint16List, Uint32List, Uint64List, Int8List, Int16List,
  /// Int32List, Int64List, Flooat32List, Float64List, Inst32x3List,
  /// Float32x4List, and Float64x2List. These parameters are otherwise ignored.
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  Future<Obj> getObject(
    String isolateId,
    String objectId, {
    int? offset,
    int? count,
  });

  /// The `getPorts` RPC is used to retrieve the list of `ReceivePort` instances
  /// for a given isolate.
  ///
  /// See [PortList].
  Future<PortList> getPorts(String isolateId);

  /// The `getRetainingPath` RPC is used to lookup a path from an object
  /// specified by `targetId` to a GC root (i.e., the object which is preventing
  /// this object from being garbage collected).
  ///
  /// If `isolateId` refers to an isolate which has exited, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// If `targetId` refers to a heap object which has been collected by the VM's
  /// garbage collector, then the `Collected` [Sentinel] is returned.
  ///
  /// If `targetId` refers to a non-heap object which has been deleted, then the
  /// `Collected` [Sentinel] is returned.
  ///
  /// If the object handle has not expired and the object has not been
  /// collected, then an [RetainingPath] will be returned.
  ///
  /// The `limit` parameter specifies the maximum path length to be reported as
  /// part of the retaining path. If a path is longer than `limit`, it will be
  /// truncated at the root end of the path.
  ///
  /// See [RetainingPath].
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  Future<RetainingPath> getRetainingPath(
      String isolateId, String targetId, int limit);

  /// Returns a description of major uses of memory known to the VM.
  ///
  /// Adding or removing buckets is considered a backwards-compatible change for
  /// the purposes of versioning. A client must gracefully handle the removal or
  /// addition of any bucket.
  Future<ProcessMemoryUsage> getProcessMemoryUsage();

  /// The `getStack` RPC is used to retrieve the current execution stack and
  /// message queue for an isolate. The isolate does not need to be paused.
  ///
  /// If `limit` is provided, up to `limit` frames from the top of the stack
  /// will be returned. If the stack depth is smaller than `limit` the entire
  /// stack is returned. Note: this limit also applies to the
  /// `asyncCausalFrames` and `awaiterFrames` stack representations in the
  /// `Stack` response.
  ///
  /// If `isolateId` refers to an isolate which has exited, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// See [Stack].
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  Future<Stack> getStack(String isolateId, {int? limit});

  /// The `getSupportedProtocols` RPC is used to determine which protocols are
  /// supported by the current server.
  ///
  /// The result of this call should be intercepted by any middleware that
  /// extends the core VM service protocol and should add its own protocol to
  /// the list of protocols before forwarding the response to the client.
  ///
  /// See [ProtocolList].
  Future<ProtocolList> getSupportedProtocols();

  /// The `getSourceReport` RPC is used to generate a set of reports tied to
  /// source locations in an isolate.
  ///
  /// The `reports` parameter is used to specify which reports should be
  /// generated. The `reports` parameter is a list, which allows multiple
  /// reports to be generated simultaneously from a consistent isolate state.
  /// The `reports` parameter is allowed to be empty (this might be used to
  /// force compilation of a particular subrange of some script).
  ///
  /// The available report kinds are:
  ///
  /// report kind | meaning
  /// ----------- | -------
  /// Coverage | Provide code coverage information
  /// PossibleBreakpoints | Provide a list of token positions which correspond
  /// to possible breakpoints.
  ///
  /// The `scriptId` parameter is used to restrict the report to a particular
  /// script. When analyzing a particular script, either or both of the
  /// `tokenPos` and `endTokenPos` parameters may be provided to restrict the
  /// analysis to a subrange of a script (for example, these can be used to
  /// restrict the report to the range of a particular class or function).
  ///
  /// If the `scriptId` parameter is not provided then the reports are generated
  /// for all loaded scripts and the `tokenPos` and `endTokenPos` parameters are
  /// disallowed.
  ///
  /// The `forceCompilation` parameter can be used to force compilation of all
  /// functions in the range of the report. Forcing compilation can cause a
  /// compilation error, which could terminate the running Dart program. If this
  /// parameter is not provided, it is considered to have the value `false`.
  ///
  /// The `reportLines` parameter changes the token positions in
  /// `SourceReportRange.possibleBreakpoints` and `SourceReportCoverage` to be
  /// line numbers. This is designed to reduce the number of RPCs that need to
  /// be performed in the case that the client is only interested in line
  /// numbers. If this parameter is not provided, it is considered to have the
  /// value `false`.
  ///
  /// The `libraryFilters` parameter is intended to be used when gathering
  /// coverage for the whole isolate. If it is provided, the `SourceReport` will
  /// only contain results from scripts with URIs that start with one of the
  /// filter strings. For example, pass `["package:foo/"]` to only include
  /// scripts from the foo package.
  ///
  /// If `isolateId` refers to an isolate which has exited, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// See [SourceReport].
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  Future<SourceReport> getSourceReport(
    String isolateId,
    /*List<SourceReportKind>*/ List<String> reports, {
    String? scriptId,
    int? tokenPos,
    int? endTokenPos,
    bool? forceCompile,
    bool? reportLines,
    List<String>? libraryFilters,
  });

  /// The `getVersion` RPC is used to determine what version of the Service
  /// Protocol is served by a VM.
  ///
  /// See [Version].
  Future<Version> getVersion();

  /// The `getVM` RPC returns global information about a Dart virtual machine.
  ///
  /// See [VM].
  Future<VM> getVM();

  /// The `getVMTimeline` RPC is used to retrieve an object which contains VM
  /// timeline events.
  ///
  /// The `timeOriginMicros` parameter is the beginning of the time range used
  /// to filter timeline events. It uses the same monotonic clock as
  /// dart:developer's `Timeline.now` and the VM embedding API's
  /// `Dart_TimelineGetMicros`. See [getVMTimelineMicros] for access to this
  /// clock through the service protocol.
  ///
  /// The `timeExtentMicros` parameter specifies how large the time range used
  /// to filter timeline events should be.
  ///
  /// For example, given `timeOriginMicros` and `timeExtentMicros`, only
  /// timeline events from the following time range will be returned:
  /// `(timeOriginMicros, timeOriginMicros + timeExtentMicros)`.
  ///
  /// If `getVMTimeline` is invoked while the current recorder is one of Fuchsia
  /// or Macos or Systrace, an [RPC error] with error code `114`, `invalid
  /// timeline request`, will be returned as timeline events are handled by the
  /// OS in these modes.
  Future<Timeline> getVMTimeline(
      {int? timeOriginMicros, int? timeExtentMicros});

  /// The `getVMTimelineFlags` RPC returns information about the current VM
  /// timeline configuration.
  ///
  /// To change which timeline streams are currently enabled, see
  /// [setVMTimelineFlags].
  ///
  /// See [TimelineFlags].
  Future<TimelineFlags> getVMTimelineFlags();

  /// The `getVMTimelineMicros` RPC returns the current time stamp from the
  /// clock used by the timeline, similar to `Timeline.now` in `dart:developer`
  /// and `Dart_TimelineGetMicros` in the VM embedding API.
  ///
  /// See [Timestamp] and [getVMTimeline].
  Future<Timestamp> getVMTimelineMicros();

  /// The `pause` RPC is used to interrupt a running isolate. The RPC enqueues
  /// the interrupt request and potentially returns before the isolate is
  /// paused.
  ///
  /// When the isolate is paused an event will be sent on the `Debug` stream.
  ///
  /// If `isolateId` refers to an isolate which has exited, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// See [Success].
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  Future<Success> pause(String isolateId);

  /// The `kill` RPC is used to kill an isolate as if by dart:isolate's
  /// `Isolate.kill(IMMEDIATE)`.
  ///
  /// The isolate is killed regardless of whether it is paused or running.
  ///
  /// If `isolateId` refers to an isolate which has exited, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// See [Success].
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  Future<Success> kill(String isolateId);

  /// The `lookupResolvedPackageUris` RPC is used to convert a list of URIs to
  /// their resolved (or absolute) paths. For example, URIs passed to this RPC
  /// are mapped in the following ways:
  ///
  /// - `dart:io` -&gt; `org-dartlang-sdk:///sdk/lib/io/io.dart`
  /// - `package:test/test.dart` -&gt;
  /// `file:///$PACKAGE_INSTALLATION_DIR/lib/test.dart`
  /// - `file:///foo/bar/bazz.dart` -&gt; `file:///foo/bar/bazz.dart`
  ///
  /// If a URI is not known, the corresponding entry in the [UriList] response
  /// will be `null`.
  ///
  /// If `local` is true, the VM will attempt to return local file paths instead
  /// of relative paths, but this is not guaranteed.
  ///
  /// See [UriList].
  Future<UriList> lookupResolvedPackageUris(String isolateId, List<String> uris,
      {bool? local});

  /// The `lookupPackageUris` RPC is used to convert a list of URIs to their
  /// unresolved paths. For example, URIs passed to this RPC are mapped in the
  /// following ways:
  ///
  /// - `org-dartlang-sdk:///sdk/lib/io/io.dart` -&gt; `dart:io`
  /// - `file:///$PACKAGE_INSTALLATION_DIR/lib/test.dart` -&gt;
  /// `package:test/test.dart`
  /// - `file:///foo/bar/bazz.dart` -&gt; `file:///foo/bar/bazz.dart`
  ///
  /// If a URI is not known, the corresponding entry in the [UriList] response
  /// will be `null`.
  ///
  /// See [UriList].
  Future<UriList> lookupPackageUris(String isolateId, List<String> uris);

  /// Registers a service that can be invoked by other VM service clients, where
  /// `service` is the name of the service to advertise and `alias` is an
  /// alternative name for the registered service.
  ///
  /// Requests made to the new service will be forwarded to the client which
  /// originally registered the service.
  ///
  /// See [Success].
  Future<Success> registerService(String service, String alias);

  /// The `reloadSources` RPC is used to perform a hot reload of an Isolate's
  /// sources.
  ///
  /// if the `force` parameter is provided, it indicates that all of the
  /// Isolate's sources should be reloaded regardless of modification time.
  ///
  /// if the `pause` parameter is provided, the isolate will pause immediately
  /// after the reload.
  ///
  /// if the `rootLibUri` parameter is provided, it indicates the new uri to the
  /// Isolate's root library.
  ///
  /// if the `packagesUri` parameter is provided, it indicates the new uri to
  /// the Isolate's package map (.packages) file.
  ///
  /// If `isolateId` refers to an isolate which has exited, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  Future<ReloadReport> reloadSources(
    String isolateId, {
    bool? force,
    bool? pause,
    String? rootLibUri,
    String? packagesUri,
  });

  /// The `removeBreakpoint` RPC is used to remove a breakpoint by its `id`.
  ///
  /// Note that breakpoints are added and removed on a per-isolate basis.
  ///
  /// If `isolateId` refers to an isolate which has exited, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// See [Success].
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  Future<Success> removeBreakpoint(String isolateId, String breakpointId);

  /// Requests a dump of the Dart heap of the given isolate.
  ///
  /// This method immediately returns success. The VM will then begin delivering
  /// binary events on the `HeapSnapshot` event stream. The binary data in these
  /// events, when concatenated together, conforms to the [SnapshotGraph] type.
  /// The splitting of the SnapshotGraph into events can happen at any byte
  /// offset.
  ///
  /// If `isolateId` refers to an isolate which has exited, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  Future<Success> requestHeapSnapshot(String isolateId);

  /// The `resume` RPC is used to resume execution of a paused isolate.
  ///
  /// If the `step` parameter is not provided, the program will resume regular
  /// execution.
  ///
  /// If the `step` parameter is provided, it indicates what form of
  /// single-stepping to use.
  ///
  /// step | meaning
  /// ---- | -------
  /// Into | Single step, entering function calls
  /// Over | Single step, skipping over function calls
  /// Out | Single step until the current function exits
  /// Rewind | Immediately exit the top frame(s) without executing any code.
  /// Isolate will be paused at the call of the last exited function.
  ///
  /// The `frameIndex` parameter is only used when the `step` parameter is
  /// Rewind. It specifies the stack frame to rewind to. Stack frame 0 is the
  /// currently executing function, so `frameIndex` must be at least 1.
  ///
  /// If the `frameIndex` parameter is not provided, it defaults to 1.
  ///
  /// If `isolateId` refers to an isolate which has exited, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// See [Success], [StepOption].
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  Future<Success> resume(String isolateId,
      {/*StepOption*/ String? step, int? frameIndex});

  /// The `setBreakpointState` RPC allows for breakpoints to be enabled or
  /// disabled, without requiring for the breakpoint to be completely removed.
  ///
  /// If `isolateId` refers to an isolate which has exited, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// The returned [Breakpoint] is the updated breakpoint with its new values.
  ///
  /// See [Breakpoint].
  Future<Breakpoint> setBreakpointState(
      String isolateId, String breakpointId, bool enable);

  /// The `setExceptionPauseMode` RPC is used to control if an isolate pauses
  /// when an exception is thrown.
  ///
  /// mode | meaning
  /// ---- | -------
  /// None | Do not pause isolate on thrown exceptions
  /// Unhandled | Pause isolate on unhandled exceptions
  /// All  | Pause isolate on all thrown exceptions
  ///
  /// If `isolateId` refers to an isolate which has exited, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  @Deprecated('Use setIsolatePauseMode instead')
  Future<Success> setExceptionPauseMode(
      String isolateId, /*ExceptionPauseMode*/ String mode);

  /// The `setIsolatePauseMode` RPC is used to control if or when an isolate
  /// will pause due to a change in execution state.
  ///
  /// The `shouldPauseOnExit` parameter specify whether the target isolate
  /// should pause on exit.
  ///
  /// The `setExceptionPauseMode` RPC is used to control if an isolate pauses
  /// when an exception is thrown.
  ///
  /// mode | meaning
  /// ---- | -------
  /// None | Do not pause isolate on thrown exceptions
  /// Unhandled | Pause isolate on unhandled exceptions
  /// All  | Pause isolate on all thrown exceptions
  ///
  /// If `isolateId` refers to an isolate which has exited, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  Future<Success> setIsolatePauseMode(String isolateId,
      {/*ExceptionPauseMode*/ String? exceptionPauseMode,
      bool? shouldPauseOnExit});

  /// The `setFlag` RPC is used to set a VM flag at runtime. Returns an error if
  /// the named flag does not exist, the flag may not be set at runtime, or the
  /// value is of the wrong type for the flag.
  ///
  /// The following flags may be set at runtime:
  ///
  /// - pause_isolates_on_start
  /// - pause_isolates_on_exit
  /// - pause_isolates_on_unhandled_exceptions
  /// - profile_period
  /// - profiler
  ///
  /// Notes:
  ///
  /// - `profile_period` can be set to a minimum value of 50. Attempting to set
  /// `profile_period` to a lower value will result in a value of 50 being set.
  /// - Setting `profiler` will enable or disable the profiler depending on the
  /// provided value. If set to false when the profiler is already running, the
  /// profiler will be stopped but may not free its sample buffer depending on
  /// platform limitations.
  /// - Isolate pause settings will only be applied to newly spawned isolates.
  ///
  /// See [Success].
  ///
  /// The return value can be one of [Success] or [Error].
  Future<Response> setFlag(String name, String value);

  /// The `setLibraryDebuggable` RPC is used to enable or disable whether
  /// breakpoints and stepping work for a given library.
  ///
  /// If `isolateId` refers to an isolate which has exited, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// See [Success].
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  Future<Success> setLibraryDebuggable(
      String isolateId, String libraryId, bool isDebuggable);

  /// The `setName` RPC is used to change the debugging name for an isolate.
  ///
  /// If `isolateId` refers to an isolate which has exited, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// See [Success].
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  Future<Success> setName(String isolateId, String name);

  /// The `setTraceClassAllocation` RPC allows for enabling or disabling
  /// allocation tracing for a specific type of object. Allocation traces can be
  /// retrieved with the `getAllocationTraces` RPC.
  ///
  /// If `enable` is true, allocations of objects of the class represented by
  /// `classId` will be traced.
  ///
  /// If `isolateId` refers to an isolate which has exited, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// See [Success].
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  Future<Success> setTraceClassAllocation(
      String isolateId, String classId, bool enable);

  /// The `setVMName` RPC is used to change the debugging name for the vm.
  ///
  /// See [Success].
  Future<Success> setVMName(String name);

  /// The `setVMTimelineFlags` RPC is used to set which timeline streams are
  /// enabled.
  ///
  /// The `recordedStreams` parameter is the list of all timeline streams which
  /// are to be enabled. Streams not explicitly specified will be disabled.
  /// Invalid stream names are ignored.
  ///
  /// A `TimelineStreamSubscriptionsUpdate` event is sent on the `Timeline`
  /// stream as a result of invoking this RPC.
  ///
  /// To get the list of currently enabled timeline streams, see
  /// [getVMTimelineFlags].
  ///
  /// See [Success].
  Future<Success> setVMTimelineFlags(List<String> recordedStreams);

  /// The `streamCancel` RPC cancels a stream subscription in the VM.
  ///
  /// If the client is not subscribed to the stream, the `104` (Stream not
  /// subscribed) [RPC error] code is returned.
  ///
  /// See [Success].
  Future<Success> streamCancel(String streamId);

  /// The `streamCpuSamplesWithUserTag` RPC allows for clients to specify which
  /// CPU samples collected by the profiler should be sent over the `Profiler`
  /// stream. When called, the VM will stream `CpuSamples` events containing
  /// `CpuSample`'s collected while a user tag contained in `userTags` was
  /// active.
  ///
  /// See [Success].
  Future<Success> streamCpuSamplesWithUserTag(List<String> userTags);

  /// The `streamListen` RPC subscribes to a stream in the VM. Once subscribed,
  /// the client will begin receiving events from the stream.
  ///
  /// If the client is already subscribed to the stream, the `103` (Stream
  /// already subscribed) [RPC error] code is returned.
  ///
  /// The `streamId` parameter may have the following published values:
  ///
  /// streamId | event types provided
  /// -------- | -----------
  /// VM | VMUpdate, VMFlagUpdate
  /// Isolate | IsolateStart, IsolateRunnable, IsolateExit, IsolateUpdate,
  /// IsolateReload, ServiceExtensionAdded
  /// Debug | PauseStart, PauseExit, PauseBreakpoint, PauseInterrupted,
  /// PauseException, PausePostRequest, Resume, BreakpointAdded,
  /// BreakpointResolved, BreakpointRemoved, BreakpointUpdated, Inspect, None
  /// Profiler | CpuSamples, UserTagChanged
  /// GC | GC
  /// Extension | Extension
  /// Timeline | TimelineEvents, TimelineStreamsSubscriptionUpdate
  /// Logging | Logging
  /// Service | ServiceRegistered, ServiceUnregistered
  /// HeapSnapshot | HeapSnapshot
  ///
  /// Additionally, some embedders provide the `Stdout` and `Stderr` streams.
  /// These streams allow the client to subscribe to writes to stdout and
  /// stderr.
  ///
  /// streamId | event types provided
  /// -------- | -----------
  /// Stdout | WriteEvent
  /// Stderr | WriteEvent
  ///
  /// It is considered a `backwards compatible` change to add a new type of
  /// event to an existing stream. Clients should be written to handle this
  /// gracefully, perhaps by warning and ignoring.
  ///
  /// See [Success].
  Future<Success> streamListen(String streamId);
}

class _PendingServiceRequest {
  Future<Map<String, Object?>> get future => _completer.future;
  final _completer = Completer<Map<String, Object?>>();

  final dynamic originalId;

  _PendingServiceRequest(this.originalId);

  void complete(Map<String, Object?> response) {
    response['id'] = originalId;
    _completer.complete(response);
  }
}

/// A Dart VM Service Protocol connection that delegates requests to a
/// [VmServiceInterface] implementation.
///
/// One of these should be created for each client, but they should generally
/// share the same [VmServiceInterface] and [ServiceExtensionRegistry]
/// instances.
class VmServerConnection {
  final Stream<Map<String, Object>> _requestStream;
  final StreamSink<Map<String, Object?>> _responseSink;
  final ServiceExtensionRegistry _serviceExtensionRegistry;
  final VmServiceInterface _serviceImplementation;

  /// Used to create unique ids when acting as a proxy between clients.
  int _nextServiceRequestId = 0;

  /// Manages streams for `streamListen` and `streamCancel` requests.
  final _streamSubscriptions = <String, StreamSubscription>{};

  /// Completes when [_requestStream] is done.
  Future<void> get done => _doneCompleter.future;
  final _doneCompleter = Completer<void>();

  /// Pending service extension requests to this client by id.
  final _pendingServiceExtensionRequests = <dynamic, _PendingServiceRequest>{};

  VmServerConnection(this._requestStream, this._responseSink,
      this._serviceExtensionRegistry, this._serviceImplementation) {
    _requestStream.listen(_delegateRequest, onDone: _doneCompleter.complete);
    done.then(
        (_) => _streamSubscriptions.values.forEach((sub) => sub.cancel()));
  }

  /// Invoked when the current client has registered some extension, and
  /// another client sends an RPC request for that extension.
  ///
  /// We don't attempt to do any serialization or deserialization of the
  /// request or response in this case
  Future<Map<String, Object?>> _forwardServiceExtensionRequest(
      Map<String, Object?> request) {
    final originalId = request['id'];
    request = Map<String, Object?>.of(request);
    // Modify the request ID to ensure we don't have conflicts between
    // multiple clients ids.
    final newId = '${_nextServiceRequestId++}:$originalId';
    request['id'] = newId;
    var pendingRequest = _PendingServiceRequest(originalId);
    _pendingServiceExtensionRequests[newId] = pendingRequest;
    _responseSink.add(request);
    return pendingRequest.future;
  }

  void _delegateRequest(Map<String, Object?> request) async {
    try {
      var id = request['id'];
      // Check if this is actually a response to a pending request.
      if (_pendingServiceExtensionRequests.containsKey(id)) {
        final pending = _pendingServiceExtensionRequests[id]!;
        pending.complete(Map<String, Object?>.of(request));
        return;
      }
      final method = request['method'] as String?;
      if (method == null) {
        throw RPCError(
            null, RPCError.kInvalidRequest, 'Invalid Request', request);
      }
      final params = request['params'] as Map<String, dynamic>?;
      late Response response;

      switch (method) {
        case 'registerService':
          _serviceExtensionRegistry.registerExtension(params!['service'], this);
          response = Success();
          break;
        case 'addBreakpoint':
          response = await _serviceImplementation.addBreakpoint(
            params!['isolateId'],
            params['scriptId'],
            params['line'],
            column: params['column'],
          );
          break;
        case 'addBreakpointWithScriptUri':
          response = await _serviceImplementation.addBreakpointWithScriptUri(
            params!['isolateId'],
            params['scriptUri'],
            params['line'],
            column: params['column'],
          );
          break;
        case 'addBreakpointAtEntry':
          response = await _serviceImplementation.addBreakpointAtEntry(
            params!['isolateId'],
            params['functionId'],
          );
          break;
        case 'clearCpuSamples':
          response = await _serviceImplementation.clearCpuSamples(
            params!['isolateId'],
          );
          break;
        case 'clearVMTimeline':
          response = await _serviceImplementation.clearVMTimeline();
          break;
        case 'invoke':
          response = await _serviceImplementation.invoke(
            params!['isolateId'],
            params['targetId'],
            params['selector'],
            List<String>.from(params['argumentIds'] ?? []),
            disableBreakpoints: params['disableBreakpoints'],
          );
          break;
        case 'evaluate':
          response = await _serviceImplementation.evaluate(
            params!['isolateId'],
            params['targetId'],
            params['expression'],
            scope: params['scope']?.cast<String, String>(),
            disableBreakpoints: params['disableBreakpoints'],
          );
          break;
        case 'evaluateInFrame':
          response = await _serviceImplementation.evaluateInFrame(
            params!['isolateId'],
            params['frameIndex'],
            params['expression'],
            scope: params['scope']?.cast<String, String>(),
            disableBreakpoints: params['disableBreakpoints'],
          );
          break;
        case 'getAllocationProfile':
          response = await _serviceImplementation.getAllocationProfile(
            params!['isolateId'],
            reset: params['reset'],
            gc: params['gc'],
          );
          break;
        case 'getAllocationTraces':
          response = await _serviceImplementation.getAllocationTraces(
            params!['isolateId'],
            timeOriginMicros: params['timeOriginMicros'],
            timeExtentMicros: params['timeExtentMicros'],
            classId: params['classId'],
          );
          break;
        case 'getClassList':
          response = await _serviceImplementation.getClassList(
            params!['isolateId'],
          );
          break;
        case 'getCpuSamples':
          response = await _serviceImplementation.getCpuSamples(
            params!['isolateId'],
            params['timeOriginMicros'],
            params['timeExtentMicros'],
          );
          break;
        case 'getFlagList':
          response = await _serviceImplementation.getFlagList();
          break;
        case 'getInboundReferences':
          response = await _serviceImplementation.getInboundReferences(
            params!['isolateId'],
            params['targetId'],
            params['limit'],
          );
          break;
        case 'getInstances':
          response = await _serviceImplementation.getInstances(
            params!['isolateId'],
            params['objectId'],
            params['limit'],
          );
          break;
        case 'getIsolate':
          response = await _serviceImplementation.getIsolate(
            params!['isolateId'],
          );
          break;
        case 'getIsolateGroup':
          response = await _serviceImplementation.getIsolateGroup(
            params!['isolateGroupId'],
          );
          break;
        case 'getMemoryUsage':
          response = await _serviceImplementation.getMemoryUsage(
            params!['isolateId'],
          );
          break;
        case 'getIsolateGroupMemoryUsage':
          response = await _serviceImplementation.getIsolateGroupMemoryUsage(
            params!['isolateGroupId'],
          );
          break;
        case 'getScripts':
          response = await _serviceImplementation.getScripts(
            params!['isolateId'],
          );
          break;
        case 'getObject':
          response = await _serviceImplementation.getObject(
            params!['isolateId'],
            params['objectId'],
            offset: params['offset'],
            count: params['count'],
          );
          break;
        case 'getPorts':
          response = await _serviceImplementation.getPorts(
            params!['isolateId'],
          );
          break;
        case 'getRetainingPath':
          response = await _serviceImplementation.getRetainingPath(
            params!['isolateId'],
            params['targetId'],
            params['limit'],
          );
          break;
        case 'getProcessMemoryUsage':
          response = await _serviceImplementation.getProcessMemoryUsage();
          break;
        case 'getStack':
          response = await _serviceImplementation.getStack(
            params!['isolateId'],
            limit: params['limit'],
          );
          break;
        case 'getSupportedProtocols':
          response = await _serviceImplementation.getSupportedProtocols();
          break;
        case 'getSourceReport':
          response = await _serviceImplementation.getSourceReport(
            params!['isolateId'],
            List<String>.from(params['reports'] ?? []),
            scriptId: params['scriptId'],
            tokenPos: params['tokenPos'],
            endTokenPos: params['endTokenPos'],
            forceCompile: params['forceCompile'],
            reportLines: params['reportLines'],
            libraryFilters: params['libraryFilters'],
          );
          break;
        case 'getVersion':
          response = await _serviceImplementation.getVersion();
          break;
        case 'getVM':
          response = await _serviceImplementation.getVM();
          break;
        case 'getVMTimeline':
          response = await _serviceImplementation.getVMTimeline(
            timeOriginMicros: params!['timeOriginMicros'],
            timeExtentMicros: params['timeExtentMicros'],
          );
          break;
        case 'getVMTimelineFlags':
          response = await _serviceImplementation.getVMTimelineFlags();
          break;
        case 'getVMTimelineMicros':
          response = await _serviceImplementation.getVMTimelineMicros();
          break;
        case 'pause':
          response = await _serviceImplementation.pause(
            params!['isolateId'],
          );
          break;
        case 'kill':
          response = await _serviceImplementation.kill(
            params!['isolateId'],
          );
          break;
        case 'lookupResolvedPackageUris':
          response = await _serviceImplementation.lookupResolvedPackageUris(
            params!['isolateId'],
            List<String>.from(params['uris'] ?? []),
            local: params['local'],
          );
          break;
        case 'lookupPackageUris':
          response = await _serviceImplementation.lookupPackageUris(
            params!['isolateId'],
            List<String>.from(params['uris'] ?? []),
          );
          break;
        case 'reloadSources':
          response = await _serviceImplementation.reloadSources(
            params!['isolateId'],
            force: params['force'],
            pause: params['pause'],
            rootLibUri: params['rootLibUri'],
            packagesUri: params['packagesUri'],
          );
          break;
        case 'removeBreakpoint':
          response = await _serviceImplementation.removeBreakpoint(
            params!['isolateId'],
            params['breakpointId'],
          );
          break;
        case 'requestHeapSnapshot':
          response = await _serviceImplementation.requestHeapSnapshot(
            params!['isolateId'],
          );
          break;
        case 'resume':
          response = await _serviceImplementation.resume(
            params!['isolateId'],
            step: params['step'],
            frameIndex: params['frameIndex'],
          );
          break;
        case 'setBreakpointState':
          response = await _serviceImplementation.setBreakpointState(
            params!['isolateId'],
            params['breakpointId'],
            params['enable'],
          );
          break;
        case 'setExceptionPauseMode':
          // ignore: deprecated_member_use_from_same_package
          response = await _serviceImplementation.setExceptionPauseMode(
            params!['isolateId'],
            params['mode'],
          );
          break;
        case 'setIsolatePauseMode':
          response = await _serviceImplementation.setIsolatePauseMode(
            params!['isolateId'],
            exceptionPauseMode: params['exceptionPauseMode'],
            shouldPauseOnExit: params['shouldPauseOnExit'],
          );
          break;
        case 'setFlag':
          response = await _serviceImplementation.setFlag(
            params!['name'],
            params['value'],
          );
          break;
        case 'setLibraryDebuggable':
          response = await _serviceImplementation.setLibraryDebuggable(
            params!['isolateId'],
            params['libraryId'],
            params['isDebuggable'],
          );
          break;
        case 'setName':
          response = await _serviceImplementation.setName(
            params!['isolateId'],
            params['name'],
          );
          break;
        case 'setTraceClassAllocation':
          response = await _serviceImplementation.setTraceClassAllocation(
            params!['isolateId'],
            params['classId'],
            params['enable'],
          );
          break;
        case 'setVMName':
          response = await _serviceImplementation.setVMName(
            params!['name'],
          );
          break;
        case 'setVMTimelineFlags':
          response = await _serviceImplementation.setVMTimelineFlags(
            List<String>.from(params!['recordedStreams'] ?? []),
          );
          break;
        case 'streamCancel':
          var id = params!['streamId'];
          var existing = _streamSubscriptions.remove(id);
          if (existing == null) {
            throw RPCError.withDetails(
              'streamCancel',
              104,
              'Stream not subscribed',
              details: "The stream '$id' is not subscribed",
            );
          }
          await existing.cancel();
          response = Success();
          break;
        case 'streamCpuSamplesWithUserTag':
          response = await _serviceImplementation.streamCpuSamplesWithUserTag(
            List<String>.from(params!['userTags'] ?? []),
          );
          break;
        case 'streamListen':
          var id = params!['streamId'];
          if (_streamSubscriptions.containsKey(id)) {
            throw RPCError.withDetails(
              'streamListen',
              103,
              'Stream already subscribed',
              details: "The stream '$id' is already subscribed",
            );
          }

          var stream = id == 'Service'
              ? _serviceExtensionRegistry.onExtensionEvent
              : _serviceImplementation.onEvent(id);
          _streamSubscriptions[id] = stream.listen((e) {
            _responseSink.add({
              'jsonrpc': '2.0',
              'method': 'streamNotify',
              'params': {
                'streamId': id,
                'event': e.toJson(),
              },
            });
          });
          response = Success();
          break;
        default:
          final registeredClient = _serviceExtensionRegistry.clientFor(method);
          if (registeredClient != null) {
            // Check for any client which has registered this extension, if we
            // have one then delegate the request to that client.
            _responseSink.add(await registeredClient
                ._forwardServiceExtensionRequest(request));
            // Bail out early in this case, we are just acting as a proxy and
            // never get a `Response` instance.
            return;
          } else if (method.startsWith('ext.')) {
            // Remaining methods with `ext.` are assumed to be registered via
            // dart:developer, which the service implementation handles.
            final args =
                params == null ? null : Map<String, dynamic>.of(params);
            final isolateId = args?.remove('isolateId');
            response = await _serviceImplementation.callServiceExtension(method,
                isolateId: isolateId, args: args);
          } else {
            throw RPCError(
                method, RPCError.kMethodNotFound, 'Method not found', request);
          }
      }
      _responseSink.add({
        'jsonrpc': '2.0',
        'id': id,
        'result': response.toJson(),
      });
    } catch (e, st) {
      final error = e is RPCError
          ? e.toMap()
          : {
              'code': RPCError.kInternalError,
              'message': '${request['method']}: $e',
              'data': {'details': '$st'},
            };
      _responseSink.add({
        'jsonrpc': '2.0',
        'id': request['id'],
        'error': error,
      });
    }
  }
}

class _OutstandingRequest<T> {
  _OutstandingRequest(this.method);
  static int _idCounter = 0;
  final String id = '${_idCounter++}';
  final String method;
  final StackTrace _stackTrace = StackTrace.current;
  final Completer<T> _completer = Completer<T>();

  Future<T> get future => _completer.future;

  void complete(T value) => _completer.complete(value);
  void completeError(Object error) =>
      _completer.completeError(error, _stackTrace);
}

class VmService implements VmServiceInterface {
  late final StreamSubscription _streamSub;
  late final Function _writeMessage;
  final Map<String, _OutstandingRequest> _outstandingRequests = {};
  Map<String, ServiceCallback> _services = {};
  late final Log _log;

  StreamController<String> _onSend = StreamController.broadcast(sync: true);
  StreamController<String> _onReceive = StreamController.broadcast(sync: true);

  final Completer _onDoneCompleter = Completer();

  Map<String, StreamController<Event>> _eventControllers = {};

  StreamController<Event> _getEventController(String eventName) {
    StreamController<Event>? controller = _eventControllers[eventName];
    if (controller == null) {
      controller = StreamController.broadcast();
      _eventControllers[eventName] = controller;
    }
    return controller;
  }

  late final DisposeHandler? _disposeHandler;

  VmService(
    Stream<dynamic> /*String|List<int>*/ inStream,
    void writeMessage(String message), {
    Log? log,
    DisposeHandler? disposeHandler,
    Future? streamClosed,
  }) {
    _streamSub = inStream.listen(_processMessage,
        onDone: () => _onDoneCompleter.complete());
    _writeMessage = writeMessage;
    _log = log == null ? _NullLog() : log;
    _disposeHandler = disposeHandler;
    streamClosed?.then((_) {
      if (!_onDoneCompleter.isCompleted) {
        _onDoneCompleter.complete();
      }
    });
  }

  @override
  Stream<Event> onEvent(String streamId) =>
      _getEventController(streamId).stream;

  // VMUpdate, VMFlagUpdate
  Stream<Event> get onVMEvent => _getEventController('VM').stream;

  // IsolateStart, IsolateRunnable, IsolateExit, IsolateUpdate, IsolateReload, ServiceExtensionAdded
  Stream<Event> get onIsolateEvent => _getEventController('Isolate').stream;

  // PauseStart, PauseExit, PauseBreakpoint, PauseInterrupted, PauseException, PausePostRequest, Resume, BreakpointAdded, BreakpointResolved, BreakpointRemoved, BreakpointUpdated, Inspect, None
  Stream<Event> get onDebugEvent => _getEventController('Debug').stream;

  // CpuSamples, UserTagChanged
  Stream<Event> get onProfilerEvent => _getEventController('Profiler').stream;

  // GC
  Stream<Event> get onGCEvent => _getEventController('GC').stream;

  // Extension
  Stream<Event> get onExtensionEvent => _getEventController('Extension').stream;

  // TimelineEvents, TimelineStreamsSubscriptionUpdate
  Stream<Event> get onTimelineEvent => _getEventController('Timeline').stream;

  // Logging
  Stream<Event> get onLoggingEvent => _getEventController('Logging').stream;

  // ServiceRegistered, ServiceUnregistered
  Stream<Event> get onServiceEvent => _getEventController('Service').stream;

  // HeapSnapshot
  Stream<Event> get onHeapSnapshotEvent =>
      _getEventController('HeapSnapshot').stream;

  // WriteEvent
  Stream<Event> get onStdoutEvent => _getEventController('Stdout').stream;

  // WriteEvent
  Stream<Event> get onStderrEvent => _getEventController('Stderr').stream;

  @override
  Future<Breakpoint> addBreakpoint(
    String isolateId,
    String scriptId,
    int line, {
    int? column,
  }) =>
      _call('addBreakpoint', {
        'isolateId': isolateId,
        'scriptId': scriptId,
        'line': line,
        if (column != null) 'column': column,
      });

  @override
  Future<Breakpoint> addBreakpointWithScriptUri(
    String isolateId,
    String scriptUri,
    int line, {
    int? column,
  }) =>
      _call('addBreakpointWithScriptUri', {
        'isolateId': isolateId,
        'scriptUri': scriptUri,
        'line': line,
        if (column != null) 'column': column,
      });

  @override
  Future<Breakpoint> addBreakpointAtEntry(
          String isolateId, String functionId) =>
      _call('addBreakpointAtEntry',
          {'isolateId': isolateId, 'functionId': functionId});

  @override
  Future<Success> clearCpuSamples(String isolateId) =>
      _call('clearCpuSamples', {'isolateId': isolateId});

  @override
  Future<Success> clearVMTimeline() => _call('clearVMTimeline');

  @override
  Future<Response> invoke(
    String isolateId,
    String targetId,
    String selector,
    List<String> argumentIds, {
    bool? disableBreakpoints,
  }) =>
      _call('invoke', {
        'isolateId': isolateId,
        'targetId': targetId,
        'selector': selector,
        'argumentIds': argumentIds,
        if (disableBreakpoints != null)
          'disableBreakpoints': disableBreakpoints,
      });

  @override
  Future<Response> evaluate(
    String isolateId,
    String targetId,
    String expression, {
    Map<String, String>? scope,
    bool? disableBreakpoints,
  }) =>
      _call('evaluate', {
        'isolateId': isolateId,
        'targetId': targetId,
        'expression': expression,
        if (scope != null) 'scope': scope,
        if (disableBreakpoints != null)
          'disableBreakpoints': disableBreakpoints,
      });

  @override
  Future<Response> evaluateInFrame(
    String isolateId,
    int frameIndex,
    String expression, {
    Map<String, String>? scope,
    bool? disableBreakpoints,
  }) =>
      _call('evaluateInFrame', {
        'isolateId': isolateId,
        'frameIndex': frameIndex,
        'expression': expression,
        if (scope != null) 'scope': scope,
        if (disableBreakpoints != null)
          'disableBreakpoints': disableBreakpoints,
      });

  @override
  Future<AllocationProfile> getAllocationProfile(String isolateId,
          {bool? reset, bool? gc}) =>
      _call('getAllocationProfile', {
        'isolateId': isolateId,
        if (reset != null && reset) 'reset': reset,
        if (gc != null && gc) 'gc': gc,
      });

  @override
  Future<CpuSamples> getAllocationTraces(
    String isolateId, {
    int? timeOriginMicros,
    int? timeExtentMicros,
    String? classId,
  }) =>
      _call('getAllocationTraces', {
        'isolateId': isolateId,
        if (timeOriginMicros != null) 'timeOriginMicros': timeOriginMicros,
        if (timeExtentMicros != null) 'timeExtentMicros': timeExtentMicros,
        if (classId != null) 'classId': classId,
      });

  @override
  Future<ClassList> getClassList(String isolateId) =>
      _call('getClassList', {'isolateId': isolateId});

  @override
  Future<CpuSamples> getCpuSamples(
          String isolateId, int timeOriginMicros, int timeExtentMicros) =>
      _call('getCpuSamples', {
        'isolateId': isolateId,
        'timeOriginMicros': timeOriginMicros,
        'timeExtentMicros': timeExtentMicros
      });

  @override
  Future<FlagList> getFlagList() => _call('getFlagList');

  @override
  Future<InboundReferences> getInboundReferences(
          String isolateId, String targetId, int limit) =>
      _call('getInboundReferences',
          {'isolateId': isolateId, 'targetId': targetId, 'limit': limit});

  @override
  Future<InstanceSet> getInstances(
          String isolateId, String objectId, int limit) =>
      _call('getInstances',
          {'isolateId': isolateId, 'objectId': objectId, 'limit': limit});

  @override
  Future<Isolate> getIsolate(String isolateId) =>
      _call('getIsolate', {'isolateId': isolateId});

  @override
  Future<IsolateGroup> getIsolateGroup(String isolateGroupId) =>
      _call('getIsolateGroup', {'isolateGroupId': isolateGroupId});

  @override
  Future<MemoryUsage> getMemoryUsage(String isolateId) =>
      _call('getMemoryUsage', {'isolateId': isolateId});

  @override
  Future<MemoryUsage> getIsolateGroupMemoryUsage(String isolateGroupId) =>
      _call('getIsolateGroupMemoryUsage', {'isolateGroupId': isolateGroupId});

  @override
  Future<ScriptList> getScripts(String isolateId) =>
      _call('getScripts', {'isolateId': isolateId});

  @override
  Future<Obj> getObject(
    String isolateId,
    String objectId, {
    int? offset,
    int? count,
  }) =>
      _call('getObject', {
        'isolateId': isolateId,
        'objectId': objectId,
        if (offset != null) 'offset': offset,
        if (count != null) 'count': count,
      });

  @override
  Future<PortList> getPorts(String isolateId) =>
      _call('getPorts', {'isolateId': isolateId});

  @override
  Future<RetainingPath> getRetainingPath(
          String isolateId, String targetId, int limit) =>
      _call('getRetainingPath',
          {'isolateId': isolateId, 'targetId': targetId, 'limit': limit});

  @override
  Future<ProcessMemoryUsage> getProcessMemoryUsage() =>
      _call('getProcessMemoryUsage');

  @override
  Future<Stack> getStack(String isolateId, {int? limit}) => _call('getStack', {
        'isolateId': isolateId,
        if (limit != null) 'limit': limit,
      });

  @override
  Future<ProtocolList> getSupportedProtocols() =>
      _call('getSupportedProtocols');

  @override
  Future<SourceReport> getSourceReport(
    String isolateId,
    /*List<SourceReportKind>*/ List<String> reports, {
    String? scriptId,
    int? tokenPos,
    int? endTokenPos,
    bool? forceCompile,
    bool? reportLines,
    List<String>? libraryFilters,
  }) =>
      _call('getSourceReport', {
        'isolateId': isolateId,
        'reports': reports,
        if (scriptId != null) 'scriptId': scriptId,
        if (tokenPos != null) 'tokenPos': tokenPos,
        if (endTokenPos != null) 'endTokenPos': endTokenPos,
        if (forceCompile != null) 'forceCompile': forceCompile,
        if (reportLines != null) 'reportLines': reportLines,
        if (libraryFilters != null) 'libraryFilters': libraryFilters,
      });

  @override
  Future<Version> getVersion() => _call('getVersion');

  @override
  Future<VM> getVM() => _call('getVM');

  @override
  Future<Timeline> getVMTimeline(
          {int? timeOriginMicros, int? timeExtentMicros}) =>
      _call('getVMTimeline', {
        if (timeOriginMicros != null) 'timeOriginMicros': timeOriginMicros,
        if (timeExtentMicros != null) 'timeExtentMicros': timeExtentMicros,
      });

  @override
  Future<TimelineFlags> getVMTimelineFlags() => _call('getVMTimelineFlags');

  @override
  Future<Timestamp> getVMTimelineMicros() => _call('getVMTimelineMicros');

  @override
  Future<Success> pause(String isolateId) =>
      _call('pause', {'isolateId': isolateId});

  @override
  Future<Success> kill(String isolateId) =>
      _call('kill', {'isolateId': isolateId});

  @override
  Future<UriList> lookupResolvedPackageUris(String isolateId, List<String> uris,
          {bool? local}) =>
      _call('lookupResolvedPackageUris', {
        'isolateId': isolateId,
        'uris': uris,
        if (local != null) 'local': local,
      });

  @override
  Future<UriList> lookupPackageUris(String isolateId, List<String> uris) =>
      _call('lookupPackageUris', {'isolateId': isolateId, 'uris': uris});

  @override
  Future<Success> registerService(String service, String alias) =>
      _call('registerService', {'service': service, 'alias': alias});

  @override
  Future<ReloadReport> reloadSources(
    String isolateId, {
    bool? force,
    bool? pause,
    String? rootLibUri,
    String? packagesUri,
  }) =>
      _call('reloadSources', {
        'isolateId': isolateId,
        if (force != null) 'force': force,
        if (pause != null) 'pause': pause,
        if (rootLibUri != null) 'rootLibUri': rootLibUri,
        if (packagesUri != null) 'packagesUri': packagesUri,
      });

  @override
  Future<Success> removeBreakpoint(String isolateId, String breakpointId) =>
      _call('removeBreakpoint',
          {'isolateId': isolateId, 'breakpointId': breakpointId});

  @override
  Future<Success> requestHeapSnapshot(String isolateId) =>
      _call('requestHeapSnapshot', {'isolateId': isolateId});

  @override
  Future<Success> resume(String isolateId,
          {/*StepOption*/ String? step, int? frameIndex}) =>
      _call('resume', {
        'isolateId': isolateId,
        if (step != null) 'step': step,
        if (frameIndex != null) 'frameIndex': frameIndex,
      });

  @override
  Future<Breakpoint> setBreakpointState(
          String isolateId, String breakpointId, bool enable) =>
      _call('setBreakpointState', {
        'isolateId': isolateId,
        'breakpointId': breakpointId,
        'enable': enable
      });

  @Deprecated('Use setIsolatePauseMode instead')
  @override
  Future<Success> setExceptionPauseMode(
          String isolateId, /*ExceptionPauseMode*/ String mode) =>
      _call('setExceptionPauseMode', {'isolateId': isolateId, 'mode': mode});

  @override
  Future<Success> setIsolatePauseMode(String isolateId,
          {/*ExceptionPauseMode*/ String? exceptionPauseMode,
          bool? shouldPauseOnExit}) =>
      _call('setIsolatePauseMode', {
        'isolateId': isolateId,
        if (exceptionPauseMode != null)
          'exceptionPauseMode': exceptionPauseMode,
        if (shouldPauseOnExit != null) 'shouldPauseOnExit': shouldPauseOnExit,
      });

  @override
  Future<Response> setFlag(String name, String value) =>
      _call('setFlag', {'name': name, 'value': value});

  @override
  Future<Success> setLibraryDebuggable(
          String isolateId, String libraryId, bool isDebuggable) =>
      _call('setLibraryDebuggable', {
        'isolateId': isolateId,
        'libraryId': libraryId,
        'isDebuggable': isDebuggable
      });

  @override
  Future<Success> setName(String isolateId, String name) =>
      _call('setName', {'isolateId': isolateId, 'name': name});

  @override
  Future<Success> setTraceClassAllocation(
          String isolateId, String classId, bool enable) =>
      _call('setTraceClassAllocation',
          {'isolateId': isolateId, 'classId': classId, 'enable': enable});

  @override
  Future<Success> setVMName(String name) => _call('setVMName', {'name': name});

  @override
  Future<Success> setVMTimelineFlags(List<String> recordedStreams) =>
      _call('setVMTimelineFlags', {'recordedStreams': recordedStreams});

  @override
  Future<Success> streamCancel(String streamId) =>
      _call('streamCancel', {'streamId': streamId});

  @override
  Future<Success> streamCpuSamplesWithUserTag(List<String> userTags) =>
      _call('streamCpuSamplesWithUserTag', {'userTags': userTags});

  @override
  Future<Success> streamListen(String streamId) =>
      _call('streamListen', {'streamId': streamId});

  /// Call an arbitrary service protocol method. This allows clients to call
  /// methods not explicitly exposed by this library.
  Future<Response> callMethod(String method,
      {String? isolateId, Map<String, dynamic>? args}) {
    return callServiceExtension(method, isolateId: isolateId, args: args);
  }

  /// Invoke a specific service protocol extension method.
  ///
  /// See https://api.dart.dev/stable/dart-developer/dart-developer-library.html.
  @override
  Future<Response> callServiceExtension(String method,
      {String? isolateId, Map<String, dynamic>? args}) {
    if (args == null && isolateId == null) {
      return _call(method);
    } else if (args == null) {
      return _call(method, {'isolateId': isolateId!});
    } else {
      args = Map.from(args);
      if (isolateId != null) {
        args['isolateId'] = isolateId;
      }
      return _call(method, args);
    }
  }

  Stream<String> get onSend => _onSend.stream;

  Stream<String> get onReceive => _onReceive.stream;

  Future<void> dispose() async {
    await _streamSub.cancel();
    _outstandingRequests.forEach((id, request) {
      request._completer.completeError(RPCError(
        request.method,
        RPCError.kServerError,
        'Service connection disposed',
      ));
    });
    _outstandingRequests.clear();
    if (_disposeHandler != null) {
      await _disposeHandler!();
    }
    if (!_onDoneCompleter.isCompleted) {
      _onDoneCompleter.complete();
    }
  }

  Future get onDone => _onDoneCompleter.future;

  Future<T> _call<T>(String method, [Map args = const {}]) async {
    final request = _OutstandingRequest(method);
    _outstandingRequests[request.id] = request;
    Map m = {
      'jsonrpc': '2.0',
      'id': request.id,
      'method': method,
      'params': args,
    };
    String message = jsonEncode(m);
    _onSend.add(message);
    _writeMessage(message);
    return await request.future as T;
  }

  /// Register a service for invocation.
  void registerServiceCallback(String service, ServiceCallback cb) {
    if (_services.containsKey(service)) {
      throw Exception('Service \'${service}\' already registered');
    }
    _services[service] = cb;
  }

  void _processMessage(dynamic message) {
    // Expect a String, an int[], or a ByteData.

    if (message is String) {
      _processMessageStr(message);
    } else if (message is List<int>) {
      Uint8List list = Uint8List.fromList(message);
      _processMessageByteData(ByteData.view(list.buffer));
    } else if (message is ByteData) {
      _processMessageByteData(message);
    } else {
      _log.warning('unknown message type: ${message.runtimeType}');
    }
  }

  void _processMessageByteData(ByteData bytes) {
    final int metaOffset = 4;
    final int dataOffset = bytes.getUint32(0, Endian.little);
    final metaLength = dataOffset - metaOffset;
    final dataLength = bytes.lengthInBytes - dataOffset;
    final meta = utf8.decode(Uint8List.view(
        bytes.buffer, bytes.offsetInBytes + metaOffset, metaLength));
    final data = ByteData.view(
        bytes.buffer, bytes.offsetInBytes + dataOffset, dataLength);
    dynamic map = jsonDecode(meta)!;
    if (map['method'] == 'streamNotify') {
      String streamId = map['params']['streamId'];
      Map event = map['params']['event'];
      event['data'] = data;
      _getEventController(streamId)
          .add(createServiceObject(event, const ['Event'])! as Event);
    }
  }

  void _processMessageStr(String message) {
    late Map<String, dynamic> json;
    try {
      _onReceive.add(message);
      json = jsonDecode(message)!;
    } catch (e, s) {
      _log.severe('unable to decode message: ${message}, ${e}\n${s}');
      return;
    }

    if (json.containsKey('method')) {
      if (json.containsKey('id')) {
        _processRequest(json);
      } else {
        _processNotification(json);
      }
    } else if (json.containsKey('id') &&
        (json.containsKey('result') || json.containsKey('error'))) {
      _processResponse(json);
    } else {
      _log.severe('unknown message type: ${message}');
    }
  }

  void _processResponse(Map<String, dynamic> json) {
    final request = _outstandingRequests.remove(json['id']);
    if (request == null) {
      _log.severe('unmatched request response: ${jsonEncode(json)}');
    } else if (json['error'] != null) {
      request.completeError(RPCError.parse(request.method, json['error']));
    } else {
      Map<String, dynamic> result = json['result'] as Map<String, dynamic>;
      String? type = result['type'];
      if (type == 'Sentinel') {
        request.completeError(SentinelException.parse(request.method, result));
      } else if (_typeFactories[type] == null) {
        request.complete(Response.parse(result));
      } else {
        List<String> returnTypes = _methodReturnTypes[request.method] ?? [];
        request.complete(createServiceObject(result, returnTypes));
      }
    }
  }

  Future _processRequest(Map<String, dynamic> json) async {
    final Map m = await _routeRequest(
        json['method'], json['params'] ?? <String, dynamic>{});
    m['id'] = json['id'];
    m['jsonrpc'] = '2.0';
    String message = jsonEncode(m);
    _onSend.add(message);
    _writeMessage(message);
  }

  Future _processNotification(Map<String, dynamic> json) async {
    final String method = json['method'];
    final Map<String, dynamic> params = json['params'] ?? <String, dynamic>{};
    if (method == 'streamNotify') {
      String streamId = params['streamId'];
      _getEventController(streamId)
          .add(createServiceObject(params['event'], const ['Event'])! as Event);
    } else {
      await _routeRequest(method, params);
    }
  }

  Future<Map> _routeRequest(String method, Map<String, dynamic> params) async {
    final service = _services[method];
    if (service == null) {
      RPCError error = RPCError(
          method, RPCError.kMethodNotFound, 'method not found \'$method\'');
      return {'error': error.toMap()};
    }

    try {
      return await service(params);
    } catch (e, st) {
      RPCError error = RPCError.withDetails(
        method,
        RPCError.kServerError,
        '$e',
        details: '$st',
      );
      return {'error': error.toMap()};
    }
  }
}

typedef DisposeHandler = Future Function();

class RPCError implements Exception {
  /// Application specific error codes.
  static const int kServerError = -32000;

  /// The JSON sent is not a valid Request object.
  static const int kInvalidRequest = -32600;

  /// The method does not exist or is not available.
  static const int kMethodNotFound = -32601;

  /// Invalid method parameter(s), such as a mismatched type.
  static const int kInvalidParams = -32602;

  /// Internal JSON-RPC error.
  static const int kInternalError = -32603;

  static RPCError parse(String callingMethod, dynamic json) {
    return RPCError(callingMethod, json['code'], json['message'], json['data']);
  }

  final String? callingMethod;
  final int code;
  final String message;
  final Map? data;

  RPCError(this.callingMethod, this.code, this.message, [this.data]);

  RPCError.withDetails(this.callingMethod, this.code, this.message,
      {Object? details})
      : data = details == null ? null : <String, dynamic>{} {
    if (details != null) {
      data!['details'] = details;
    }
  }

  String? get details => data == null ? null : data!['details'];

  /// Return a map representation of this error suitable for converstion to
  /// json.
  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {
      'code': code,
      'message': message,
    };
    if (data != null) {
      map['data'] = data;
    }
    return map;
  }

  String toString() {
    if (details == null) {
      return '$callingMethod: ($code) $message';
    } else {
      return '$callingMethod: ($code) $message\n$details';
    }
  }
}

/// Thrown when an RPC response is a [Sentinel].
class SentinelException implements Exception {
  final String callingMethod;
  final Sentinel sentinel;

  SentinelException.parse(this.callingMethod, Map<String, dynamic> data)
      : sentinel = Sentinel.parse(data)!;

  String toString() => '$sentinel from ${callingMethod}()';
}

/// An `ExtensionData` is an arbitrary map that can have any contents.
class ExtensionData {
  static ExtensionData? parse(Map<String, dynamic>? json) =>
      json == null ? null : ExtensionData._fromJson(json);

  final Map<String, dynamic> data;

  ExtensionData() : data = {};

  ExtensionData._fromJson(this.data);

  String toString() => '[ExtensionData ${data}]';
}

/// A logging handler you can pass to a [VmService] instance in order to get
/// notifications of non-fatal service protocol warnings and errors.
abstract class Log {
  /// Log a warning level message.
  void warning(String message);

  /// Log an error level message.
  void severe(String message);
}

class _NullLog implements Log {
  void warning(String message) {}
  void severe(String message) {}
}
// enums

class CodeKind {
  CodeKind._();

  static const String kDart = 'Dart';
  static const String kNative = 'Native';
  static const String kStub = 'Stub';
  static const String kTag = 'Tag';
  static const String kCollected = 'Collected';
}

class ErrorKind {
  ErrorKind._();

  /// The isolate has encountered an unhandled Dart exception.
  static const String kUnhandledException = 'UnhandledException';

  /// The isolate has encountered a Dart language error in the program.
  static const String kLanguageError = 'LanguageError';

  /// The isolate has encountered an internal error. These errors should be
  /// reported as bugs.
  static const String kInternalError = 'InternalError';

  /// The isolate has been terminated by an external source.
  static const String kTerminationError = 'TerminationError';
}

/// An enum of available event streams.
class EventStreams {
  EventStreams._();

  static const String kVM = 'VM';
  static const String kIsolate = 'Isolate';
  static const String kDebug = 'Debug';
  static const String kProfiler = 'Profiler';
  static const String kGC = 'GC';
  static const String kExtension = 'Extension';
  static const String kTimeline = 'Timeline';
  static const String kLogging = 'Logging';
  static const String kService = 'Service';
  static const String kHeapSnapshot = 'HeapSnapshot';
  static const String kStdout = 'Stdout';
  static const String kStderr = 'Stderr';
}

/// Adding new values to `EventKind` is considered a backwards compatible
/// change. Clients should ignore unrecognized events.
class EventKind {
  EventKind._();

  /// Notification that VM identifying information has changed. Currently used
  /// to notify of changes to the VM debugging name via setVMName.
  static const String kVMUpdate = 'VMUpdate';

  /// Notification that a VM flag has been changed via the service protocol.
  static const String kVMFlagUpdate = 'VMFlagUpdate';

  /// Notification that a new isolate has started.
  static const String kIsolateStart = 'IsolateStart';

  /// Notification that an isolate is ready to run.
  static const String kIsolateRunnable = 'IsolateRunnable';

  /// Notification that an isolate has exited.
  static const String kIsolateExit = 'IsolateExit';

  /// Notification that isolate identifying information has changed. Currently
  /// used to notify of changes to the isolate debugging name via setName.
  static const String kIsolateUpdate = 'IsolateUpdate';

  /// Notification that an isolate has been reloaded.
  static const String kIsolateReload = 'IsolateReload';

  /// Notification that an extension RPC was registered on an isolate.
  static const String kServiceExtensionAdded = 'ServiceExtensionAdded';

  /// An isolate has paused at start, before executing code.
  static const String kPauseStart = 'PauseStart';

  /// An isolate has paused at exit, before terminating.
  static const String kPauseExit = 'PauseExit';

  /// An isolate has paused at a breakpoint or due to stepping.
  static const String kPauseBreakpoint = 'PauseBreakpoint';

  /// An isolate has paused due to interruption via pause.
  static const String kPauseInterrupted = 'PauseInterrupted';

  /// An isolate has paused due to an exception.
  static const String kPauseException = 'PauseException';

  /// An isolate has paused after a service request.
  static const String kPausePostRequest = 'PausePostRequest';

  /// An isolate has started or resumed execution.
  static const String kResume = 'Resume';

  /// Indicates an isolate is not yet runnable. Only appears in an Isolate's
  /// pauseEvent. Never sent over a stream.
  static const String kNone = 'None';

  /// A breakpoint has been added for an isolate.
  static const String kBreakpointAdded = 'BreakpointAdded';

  /// An unresolved breakpoint has been resolved for an isolate.
  static const String kBreakpointResolved = 'BreakpointResolved';

  /// A breakpoint has been removed.
  static const String kBreakpointRemoved = 'BreakpointRemoved';

  /// A breakpoint has been updated.
  static const String kBreakpointUpdated = 'BreakpointUpdated';

  /// A garbage collection event.
  static const String kGC = 'GC';

  /// Notification of bytes written, for example, to stdout/stderr.
  static const String kWriteEvent = 'WriteEvent';

  /// Notification from dart:developer.inspect.
  static const String kInspect = 'Inspect';

  /// Event from dart:developer.postEvent.
  static const String kExtension = 'Extension';

  /// Event from dart:developer.log.
  static const String kLogging = 'Logging';

  /// A block of timeline events has been completed.
  ///
  /// This service event is not sent for individual timeline events. It is
  /// subject to buffering, so the most recent timeline events may never be
  /// included in any TimelineEvents event if no timeline events occur later to
  /// complete the block.
  static const String kTimelineEvents = 'TimelineEvents';

  /// The set of active timeline streams was changed via `setVMTimelineFlags`.
  static const String kTimelineStreamSubscriptionsUpdate =
      'TimelineStreamSubscriptionsUpdate';

  /// Notification that a Service has been registered into the Service Protocol
  /// from another client.
  static const String kServiceRegistered = 'ServiceRegistered';

  /// Notification that a Service has been removed from the Service Protocol
  /// from another client.
  static const String kServiceUnregistered = 'ServiceUnregistered';

  /// Notification that the UserTag for an isolate has been changed.
  static const String kUserTagChanged = 'UserTagChanged';

  /// A block of recently collected CPU samples.
  static const String kCpuSamples = 'CpuSamples';
}

/// Adding new values to `InstanceKind` is considered a backwards compatible
/// change. Clients should treat unrecognized instance kinds as `PlainInstance`.
class InstanceKind {
  InstanceKind._();

  /// A general instance of the Dart class Object.
  static const String kPlainInstance = 'PlainInstance';

  /// null instance.
  static const String kNull = 'Null';

  /// true or false.
  static const String kBool = 'Bool';

  /// An instance of the Dart class double.
  static const String kDouble = 'Double';

  /// An instance of the Dart class int.
  static const String kInt = 'Int';

  /// An instance of the Dart class String.
  static const String kString = 'String';

  /// An instance of the built-in VM List implementation. User-defined Lists
  /// will be PlainInstance.
  static const String kList = 'List';

  /// An instance of the built-in VM Map implementation. User-defined Maps will
  /// be PlainInstance.
  static const String kMap = 'Map';

  /// Vector instance kinds.
  static const String kFloat32x4 = 'Float32x4';
  static const String kFloat64x2 = 'Float64x2';
  static const String kInt32x4 = 'Int32x4';

  /// An instance of the built-in VM TypedData implementations. User-defined
  /// TypedDatas will be PlainInstance.
  static const String kUint8ClampedList = 'Uint8ClampedList';
  static const String kUint8List = 'Uint8List';
  static const String kUint16List = 'Uint16List';
  static const String kUint32List = 'Uint32List';
  static const String kUint64List = 'Uint64List';
  static const String kInt8List = 'Int8List';
  static const String kInt16List = 'Int16List';
  static const String kInt32List = 'Int32List';
  static const String kInt64List = 'Int64List';
  static const String kFloat32List = 'Float32List';
  static const String kFloat64List = 'Float64List';
  static const String kInt32x4List = 'Int32x4List';
  static const String kFloat32x4List = 'Float32x4List';
  static const String kFloat64x2List = 'Float64x2List';

  /// An instance of the Dart class StackTrace.
  static const String kStackTrace = 'StackTrace';

  /// An instance of the built-in VM Closure implementation. User-defined
  /// Closures will be PlainInstance.
  static const String kClosure = 'Closure';

  /// An instance of the Dart class MirrorReference.
  static const String kMirrorReference = 'MirrorReference';

  /// An instance of the Dart class RegExp.
  static const String kRegExp = 'RegExp';

  /// An instance of the Dart class WeakProperty.
  static const String kWeakProperty = 'WeakProperty';

  /// An instance of the Dart class Type.
  static const String kType = 'Type';

  /// An instance of the Dart class TypeParameter.
  static const String kTypeParameter = 'TypeParameter';

  /// An instance of the Dart class TypeRef.
  static const String kTypeRef = 'TypeRef';

  /// An instance of the Dart class FunctionType.
  static const String kFunctionType = 'FunctionType';

  /// An instance of the Dart class BoundedType.
  static const String kBoundedType = 'BoundedType';

  /// An instance of the Dart class ReceivePort.
  static const String kReceivePort = 'ReceivePort';
}

/// A `SentinelKind` is used to distinguish different kinds of `Sentinel`
/// objects.
///
/// Adding new values to `SentinelKind` is considered a backwards compatible
/// change. Clients must handle this gracefully.
class SentinelKind {
  SentinelKind._();

  /// Indicates that the object referred to has been collected by the GC.
  static const String kCollected = 'Collected';

  /// Indicates that an object id has expired.
  static const String kExpired = 'Expired';

  /// Indicates that a variable or field has not been initialized.
  static const String kNotInitialized = 'NotInitialized';

  /// Indicates that a variable or field is in the process of being initialized.
  static const String kBeingInitialized = 'BeingInitialized';

  /// Indicates that a variable has been eliminated by the optimizing compiler.
  static const String kOptimizedOut = 'OptimizedOut';

  /// Reserved for future use.
  static const String kFree = 'Free';
}

/// A `FrameKind` is used to distinguish different kinds of `Frame` objects.
class FrameKind {
  FrameKind._();

  static const String kRegular = 'Regular';
  static const String kAsyncCausal = 'AsyncCausal';
  static const String kAsyncSuspensionMarker = 'AsyncSuspensionMarker';
  static const String kAsyncActivation = 'AsyncActivation';
}

class SourceReportKind {
  SourceReportKind._();

  /// Used to request a code coverage information.
  static const String kCoverage = 'Coverage';

  /// Used to request a list of token positions of possible breakpoints.
  static const String kPossibleBreakpoints = 'PossibleBreakpoints';

  /// Used to request branch coverage information.
  static const String kBranchCoverage = 'BranchCoverage';
}

/// An `ExceptionPauseMode` indicates how the isolate pauses when an exception
/// is thrown.
class ExceptionPauseMode {
  ExceptionPauseMode._();

  static const String kNone = 'None';
  static const String kUnhandled = 'Unhandled';
  static const String kAll = 'All';
}

/// A `StepOption` indicates which form of stepping is requested in a [resume]
/// RPC.
class StepOption {
  StepOption._();

  static const String kInto = 'Into';
  static const String kOver = 'Over';
  static const String kOverAsyncSuspension = 'OverAsyncSuspension';
  static const String kOut = 'Out';
  static const String kRewind = 'Rewind';
}

// types

class AllocationProfile extends Response {
  static AllocationProfile? parse(Map<String, dynamic>? json) =>
      json == null ? null : AllocationProfile._fromJson(json);

  /// Allocation information for all class types.
  List<ClassHeapStats>? members;

  /// Information about memory usage for the isolate.
  MemoryUsage? memoryUsage;

  /// The timestamp of the last accumulator reset.
  ///
  /// If the accumulators have not been reset, this field is not present.
  @optional
  int? dateLastAccumulatorReset;

  /// The timestamp of the last manually triggered GC.
  ///
  /// If a GC has not been triggered manually, this field is not present.
  @optional
  int? dateLastServiceGC;

  AllocationProfile({
    required this.members,
    required this.memoryUsage,
    this.dateLastAccumulatorReset,
    this.dateLastServiceGC,
  });

  AllocationProfile._fromJson(Map<String, dynamic> json)
      : super._fromJson(json) {
    members = List<ClassHeapStats>.from(
        createServiceObject(json['members'], const ['ClassHeapStats'])
                as List? ??
            []);
    memoryUsage =
        createServiceObject(json['memoryUsage'], const ['MemoryUsage'])
            as MemoryUsage?;
    dateLastAccumulatorReset = json['dateLastAccumulatorReset'] is String
        ? int.parse(json['dateLastAccumulatorReset'])
        : json['dateLastAccumulatorReset'];
    dateLastServiceGC = json['dateLastServiceGC'] is String
        ? int.parse(json['dateLastServiceGC'])
        : json['dateLastServiceGC'];
  }

  @override
  String get type => 'AllocationProfile';

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json['type'] = type;
    json.addAll({
      'members': members?.map((f) => f.toJson()).toList(),
      'memoryUsage': memoryUsage?.toJson(),
    });
    _setIfNotNull(json, 'dateLastAccumulatorReset', dateLastAccumulatorReset);
    _setIfNotNull(json, 'dateLastServiceGC', dateLastServiceGC);
    return json;
  }

  String toString() =>
      '[AllocationProfile members: ${members}, memoryUsage: ${memoryUsage}]';
}

/// A `BoundField` represents a field bound to a particular value in an
/// `Instance`.
///
/// If the field is uninitialized, the `value` will be the `NotInitialized`
/// [Sentinel].
///
/// If the field is being initialized, the `value` will be the
/// `BeingInitialized` [Sentinel].
class BoundField {
  static BoundField? parse(Map<String, dynamic>? json) =>
      json == null ? null : BoundField._fromJson(json);

  FieldRef? decl;

  /// [value] can be one of [InstanceRef] or [Sentinel].
  dynamic value;

  BoundField({
    required this.decl,
    required this.value,
  });

  BoundField._fromJson(Map<String, dynamic> json) {
    decl = createServiceObject(json['decl'], const ['FieldRef']) as FieldRef?;
    value =
        createServiceObject(json['value'], const ['InstanceRef', 'Sentinel'])
            as dynamic;
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json.addAll({
      'decl': decl?.toJson(),
      'value': value?.toJson(),
    });
    return json;
  }

  String toString() => '[BoundField decl: ${decl}, value: ${value}]';
}

/// A `BoundVariable` represents a local variable bound to a particular value in
/// a `Frame`.
///
/// If the variable is uninitialized, the `value` will be the `NotInitialized`
/// [Sentinel].
///
/// If the variable is being initialized, the `value` will be the
/// `BeingInitialized` [Sentinel].
///
/// If the variable has been optimized out by the compiler, the `value` will be
/// the `OptimizedOut` [Sentinel].
class BoundVariable extends Response {
  static BoundVariable? parse(Map<String, dynamic>? json) =>
      json == null ? null : BoundVariable._fromJson(json);

  String? name;

  /// [value] can be one of [InstanceRef], [TypeArgumentsRef] or [Sentinel].
  dynamic value;

  /// The token position where this variable was declared.
  int? declarationTokenPos;

  /// The first token position where this variable is visible to the scope.
  int? scopeStartTokenPos;

  /// The last token position where this variable is visible to the scope.
  int? scopeEndTokenPos;

  BoundVariable({
    required this.name,
    required this.value,
    required this.declarationTokenPos,
    required this.scopeStartTokenPos,
    required this.scopeEndTokenPos,
  });

  BoundVariable._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    name = json['name'] ?? '';
    value = createServiceObject(json['value'],
        const ['InstanceRef', 'TypeArgumentsRef', 'Sentinel']) as dynamic;
    declarationTokenPos = json['declarationTokenPos'] ?? -1;
    scopeStartTokenPos = json['scopeStartTokenPos'] ?? -1;
    scopeEndTokenPos = json['scopeEndTokenPos'] ?? -1;
  }

  @override
  String get type => 'BoundVariable';

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json['type'] = type;
    json.addAll({
      'name': name,
      'value': value?.toJson(),
      'declarationTokenPos': declarationTokenPos,
      'scopeStartTokenPos': scopeStartTokenPos,
      'scopeEndTokenPos': scopeEndTokenPos,
    });
    return json;
  }

  String toString() => '[BoundVariable ' //
      'name: ${name}, value: ${value}, declarationTokenPos: ${declarationTokenPos}, ' //
      'scopeStartTokenPos: ${scopeStartTokenPos}, scopeEndTokenPos: ${scopeEndTokenPos}]';
}

/// A `Breakpoint` describes a debugger breakpoint.
///
/// A breakpoint is `resolved` when it has been assigned to a specific program
/// location. A breakpoint my remain unresolved when it is in code which has not
/// yet been compiled or in a library which has not been loaded (i.e. a deferred
/// library).
class Breakpoint extends Obj {
  static Breakpoint? parse(Map<String, dynamic>? json) =>
      json == null ? null : Breakpoint._fromJson(json);

  /// A number identifying this breakpoint to the user.
  int? breakpointNumber;

  /// Is this breakpoint enabled?
  bool? enabled;

  /// Has this breakpoint been assigned to a specific program location?
  bool? resolved;

  /// Is this a breakpoint that was added synthetically as part of a step
  /// OverAsyncSuspension resume command?
  @optional
  bool? isSyntheticAsyncContinuation;

  /// SourceLocation when breakpoint is resolved, UnresolvedSourceLocation when
  /// a breakpoint is not resolved.
  ///
  /// [location] can be one of [SourceLocation] or [UnresolvedSourceLocation].
  dynamic location;

  Breakpoint({
    required this.breakpointNumber,
    required this.enabled,
    required this.resolved,
    required this.location,
    required String id,
    this.isSyntheticAsyncContinuation,
  }) : super(
          id: id,
        );

  Breakpoint._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    breakpointNumber = json['breakpointNumber'] ?? -1;
    enabled = json['enabled'] ?? false;
    resolved = json['resolved'] ?? false;
    isSyntheticAsyncContinuation = json['isSyntheticAsyncContinuation'];
    location = createServiceObject(json['location'],
        const ['SourceLocation', 'UnresolvedSourceLocation']) as dynamic;
  }

  @override
  String get type => 'Breakpoint';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['type'] = type;
    json.addAll({
      'breakpointNumber': breakpointNumber,
      'enabled': enabled,
      'resolved': resolved,
      'location': location?.toJson(),
    });
    _setIfNotNull(
        json, 'isSyntheticAsyncContinuation', isSyntheticAsyncContinuation);
    return json;
  }

  int get hashCode => id.hashCode;

  bool operator ==(Object other) => other is Breakpoint && id == other.id;

  String toString() => '[Breakpoint ' //
      'id: ${id}, breakpointNumber: ${breakpointNumber}, enabled: ${enabled}, ' //
      'resolved: ${resolved}, location: ${location}]';
}

/// `ClassRef` is a reference to a `Class`.
class ClassRef extends ObjRef {
  static ClassRef? parse(Map<String, dynamic>? json) =>
      json == null ? null : ClassRef._fromJson(json);

  /// The name of this class.
  String? name;

  /// The location of this class in the source code.
  @optional
  SourceLocation? location;

  /// The library which contains this class.
  LibraryRef? library;

  /// The type parameters for the class.
  ///
  /// Provided if the class is generic.
  @optional
  List<InstanceRef>? typeParameters;

  ClassRef({
    required this.name,
    required this.library,
    required String id,
    this.location,
    this.typeParameters,
  }) : super(
          id: id,
        );

  ClassRef._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    name = json['name'] ?? '';
    location = createServiceObject(json['location'], const ['SourceLocation'])
        as SourceLocation?;
    library = createServiceObject(json['library'], const ['LibraryRef'])
        as LibraryRef?;
    typeParameters = json['typeParameters'] == null
        ? null
        : List<InstanceRef>.from(
            createServiceObject(json['typeParameters'], const ['InstanceRef'])!
                as List);
  }

  @override
  String get type => '@Class';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['type'] = type;
    json.addAll({
      'name': name,
      'library': library?.toJson(),
    });
    _setIfNotNull(json, 'location', location?.toJson());
    _setIfNotNull(json, 'typeParameters',
        typeParameters?.map((f) => f.toJson()).toList());
    return json;
  }

  int get hashCode => id.hashCode;

  bool operator ==(Object other) => other is ClassRef && id == other.id;

  String toString() =>
      '[ClassRef id: ${id}, name: ${name}, library: ${library}]';
}

/// A `Class` provides information about a Dart language class.
class Class extends Obj implements ClassRef {
  static Class? parse(Map<String, dynamic>? json) =>
      json == null ? null : Class._fromJson(json);

  /// The name of this class.
  String? name;

  /// The location of this class in the source code.
  @optional
  SourceLocation? location;

  /// The library which contains this class.
  LibraryRef? library;

  /// The type parameters for the class.
  ///
  /// Provided if the class is generic.
  @optional
  List<InstanceRef>? typeParameters;

  /// The error which occurred during class finalization, if it exists.
  @optional
  ErrorRef? error;

  /// Is this an abstract class?
  bool? isAbstract;

  /// Is this a const class?
  bool? isConst;

  /// Are allocations of this class being traced?
  bool? traceAllocations;

  /// The superclass of this class, if any.
  @optional
  ClassRef? superClass;

  /// The supertype for this class, if any.
  ///
  /// The value will be of the kind: Type.
  @optional
  InstanceRef? superType;

  /// A list of interface types for this class.
  ///
  /// The values will be of the kind: Type.
  List<InstanceRef>? interfaces;

  /// The mixin type for this class, if any.
  ///
  /// The value will be of the kind: Type.
  @optional
  InstanceRef? mixin;

  /// A list of fields in this class. Does not include fields from superclasses.
  List<FieldRef>? fields;

  /// A list of functions in this class. Does not include functions from
  /// superclasses.
  List<FuncRef>? functions;

  /// A list of subclasses of this class.
  List<ClassRef>? subclasses;

  Class({
    required this.name,
    required this.library,
    required this.isAbstract,
    required this.isConst,
    required this.traceAllocations,
    required this.interfaces,
    required this.fields,
    required this.functions,
    required this.subclasses,
    required String id,
    this.location,
    this.typeParameters,
    this.error,
    this.superClass,
    this.superType,
    this.mixin,
  }) : super(
          id: id,
        );

  Class._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    name = json['name'] ?? '';
    location = createServiceObject(json['location'], const ['SourceLocation'])
        as SourceLocation?;
    library = createServiceObject(json['library'], const ['LibraryRef'])
        as LibraryRef?;
    typeParameters = json['typeParameters'] == null
        ? null
        : List<InstanceRef>.from(
            createServiceObject(json['typeParameters'], const ['InstanceRef'])!
                as List);
    error = createServiceObject(json['error'], const ['ErrorRef']) as ErrorRef?;
    isAbstract = json['abstract'] ?? false;
    isConst = json['const'] ?? false;
    traceAllocations = json['traceAllocations'] ?? false;
    superClass =
        createServiceObject(json['super'], const ['ClassRef']) as ClassRef?;
    superType = createServiceObject(json['superType'], const ['InstanceRef'])
        as InstanceRef?;
    interfaces = List<InstanceRef>.from(
        createServiceObject(json['interfaces'], const ['InstanceRef'])
                as List? ??
            []);
    mixin = createServiceObject(json['mixin'], const ['InstanceRef'])
        as InstanceRef?;
    fields = List<FieldRef>.from(
        createServiceObject(json['fields'], const ['FieldRef']) as List? ?? []);
    functions = List<FuncRef>.from(
        createServiceObject(json['functions'], const ['FuncRef']) as List? ??
            []);
    subclasses = List<ClassRef>.from(
        createServiceObject(json['subclasses'], const ['ClassRef']) as List? ??
            []);
  }

  @override
  String get type => 'Class';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['type'] = type;
    json.addAll({
      'name': name,
      'library': library?.toJson(),
      'abstract': isAbstract,
      'const': isConst,
      'traceAllocations': traceAllocations,
      'interfaces': interfaces?.map((f) => f.toJson()).toList(),
      'fields': fields?.map((f) => f.toJson()).toList(),
      'functions': functions?.map((f) => f.toJson()).toList(),
      'subclasses': subclasses?.map((f) => f.toJson()).toList(),
    });
    _setIfNotNull(json, 'location', location?.toJson());
    _setIfNotNull(json, 'typeParameters',
        typeParameters?.map((f) => f.toJson()).toList());
    _setIfNotNull(json, 'error', error?.toJson());
    _setIfNotNull(json, 'super', superClass?.toJson());
    _setIfNotNull(json, 'superType', superType?.toJson());
    _setIfNotNull(json, 'mixin', mixin?.toJson());
    return json;
  }

  int get hashCode => id.hashCode;

  bool operator ==(Object other) => other is Class && id == other.id;

  String toString() => '[Class]';
}

class ClassHeapStats extends Response {
  static ClassHeapStats? parse(Map<String, dynamic>? json) =>
      json == null ? null : ClassHeapStats._fromJson(json);

  /// The class for which this memory information is associated.
  ClassRef? classRef;

  /// The number of bytes allocated for instances of class since the accumulator
  /// was last reset.
  int? accumulatedSize;

  /// The number of bytes currently allocated for instances of class.
  int? bytesCurrent;

  /// The number of instances of class which have been allocated since the
  /// accumulator was last reset.
  int? instancesAccumulated;

  /// The number of instances of class which are currently alive.
  int? instancesCurrent;

  ClassHeapStats({
    required this.classRef,
    required this.accumulatedSize,
    required this.bytesCurrent,
    required this.instancesAccumulated,
    required this.instancesCurrent,
  });

  ClassHeapStats._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    classRef =
        createServiceObject(json['class'], const ['ClassRef']) as ClassRef?;
    accumulatedSize = json['accumulatedSize'] ?? -1;
    bytesCurrent = json['bytesCurrent'] ?? -1;
    instancesAccumulated = json['instancesAccumulated'] ?? -1;
    instancesCurrent = json['instancesCurrent'] ?? -1;
  }

  @override
  String get type => 'ClassHeapStats';

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json['type'] = type;
    json.addAll({
      'class': classRef?.toJson(),
      'accumulatedSize': accumulatedSize,
      'bytesCurrent': bytesCurrent,
      'instancesAccumulated': instancesAccumulated,
      'instancesCurrent': instancesCurrent,
    });
    return json;
  }

  String toString() => '[ClassHeapStats ' //
      'classRef: ${classRef}, accumulatedSize: ${accumulatedSize}, ' //
      'bytesCurrent: ${bytesCurrent}, instancesAccumulated: ${instancesAccumulated}, instancesCurrent: ${instancesCurrent}]';
}

class ClassList extends Response {
  static ClassList? parse(Map<String, dynamic>? json) =>
      json == null ? null : ClassList._fromJson(json);

  List<ClassRef>? classes;

  ClassList({
    required this.classes,
  });

  ClassList._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    classes = List<ClassRef>.from(
        createServiceObject(json['classes'], const ['ClassRef']) as List? ??
            []);
  }

  @override
  String get type => 'ClassList';

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json['type'] = type;
    json.addAll({
      'classes': classes?.map((f) => f.toJson()).toList(),
    });
    return json;
  }

  String toString() => '[ClassList classes: ${classes}]';
}

/// `CodeRef` is a reference to a `Code` object.
class CodeRef extends ObjRef {
  static CodeRef? parse(Map<String, dynamic>? json) =>
      json == null ? null : CodeRef._fromJson(json);

  /// A name for this code object.
  String? name;

  /// What kind of code object is this?
  /*CodeKind*/ String? kind;

  CodeRef({
    required this.name,
    required this.kind,
    required String id,
  }) : super(
          id: id,
        );

  CodeRef._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    name = json['name'] ?? '';
    kind = json['kind'] ?? '';
  }

  @override
  String get type => '@Code';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['type'] = type;
    json.addAll({
      'name': name,
      'kind': kind,
    });
    return json;
  }

  int get hashCode => id.hashCode;

  bool operator ==(Object other) => other is CodeRef && id == other.id;

  String toString() => '[CodeRef id: ${id}, name: ${name}, kind: ${kind}]';
}

/// A `Code` object represents compiled code in the Dart VM.
class Code extends Obj implements CodeRef {
  static Code? parse(Map<String, dynamic>? json) =>
      json == null ? null : Code._fromJson(json);

  /// A name for this code object.
  String? name;

  /// What kind of code object is this?
  /*CodeKind*/ String? kind;

  Code({
    required this.name,
    required this.kind,
    required String id,
  }) : super(
          id: id,
        );

  Code._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    name = json['name'] ?? '';
    kind = json['kind'] ?? '';
  }

  @override
  String get type => 'Code';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['type'] = type;
    json.addAll({
      'name': name,
      'kind': kind,
    });
    return json;
  }

  int get hashCode => id.hashCode;

  bool operator ==(Object other) => other is Code && id == other.id;

  String toString() => '[Code id: ${id}, name: ${name}, kind: ${kind}]';
}

class ContextRef extends ObjRef {
  static ContextRef? parse(Map<String, dynamic>? json) =>
      json == null ? null : ContextRef._fromJson(json);

  /// The number of variables in this context.
  int? length;

  ContextRef({
    required this.length,
    required String id,
  }) : super(
          id: id,
        );

  ContextRef._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    length = json['length'] ?? -1;
  }

  @override
  String get type => '@Context';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['type'] = type;
    json.addAll({
      'length': length,
    });
    return json;
  }

  int get hashCode => id.hashCode;

  bool operator ==(Object other) => other is ContextRef && id == other.id;

  String toString() => '[ContextRef id: ${id}, length: ${length}]';
}

/// A `Context` is a data structure which holds the captured variables for some
/// closure.
class Context extends Obj implements ContextRef {
  static Context? parse(Map<String, dynamic>? json) =>
      json == null ? null : Context._fromJson(json);

  /// The number of variables in this context.
  int? length;

  /// The enclosing context for this context.
  @optional
  ContextRef? parent;

  /// The variables in this context object.
  List<ContextElement>? variables;

  Context({
    required this.length,
    required this.variables,
    required String id,
    this.parent,
  }) : super(
          id: id,
        );

  Context._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    length = json['length'] ?? -1;
    parent = createServiceObject(json['parent'], const ['ContextRef'])
        as ContextRef?;
    variables = List<ContextElement>.from(
        createServiceObject(json['variables'], const ['ContextElement'])
                as List? ??
            []);
  }

  @override
  String get type => 'Context';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['type'] = type;
    json.addAll({
      'length': length,
      'variables': variables?.map((f) => f.toJson()).toList(),
    });
    _setIfNotNull(json, 'parent', parent?.toJson());
    return json;
  }

  int get hashCode => id.hashCode;

  bool operator ==(Object other) => other is Context && id == other.id;

  String toString() =>
      '[Context id: ${id}, length: ${length}, variables: ${variables}]';
}

class ContextElement {
  static ContextElement? parse(Map<String, dynamic>? json) =>
      json == null ? null : ContextElement._fromJson(json);

  /// [value] can be one of [InstanceRef] or [Sentinel].
  dynamic value;

  ContextElement({
    required this.value,
  });

  ContextElement._fromJson(Map<String, dynamic> json) {
    value =
        createServiceObject(json['value'], const ['InstanceRef', 'Sentinel'])
            as dynamic;
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json.addAll({
      'value': value?.toJson(),
    });
    return json;
  }

  String toString() => '[ContextElement value: ${value}]';
}

/// See [getCpuSamples] and [CpuSample].
class CpuSamples extends Response {
  static CpuSamples? parse(Map<String, dynamic>? json) =>
      json == null ? null : CpuSamples._fromJson(json);

  /// The sampling rate for the profiler in microseconds.
  int? samplePeriod;

  /// The maximum possible stack depth for samples.
  int? maxStackDepth;

  /// The number of samples returned.
  int? sampleCount;

  /// The timespan the set of returned samples covers, in microseconds
  /// (deprecated).
  ///
  /// Note: this property is deprecated and will always return -1. Use
  /// `timeExtentMicros` instead.
  int? timeSpan;

  /// The start of the period of time in which the returned samples were
  /// collected.
  int? timeOriginMicros;

  /// The duration of time covered by the returned samples.
  int? timeExtentMicros;

  /// The process ID for the VM.
  int? pid;

  /// A list of functions seen in the relevant samples. These references can be
  /// looked up using the indicies provided in a `CpuSample` `stack` to
  /// determine which function was on the stack.
  List<ProfileFunction>? functions;

  /// A list of samples collected in the range `[timeOriginMicros,
  /// timeOriginMicros + timeExtentMicros]`
  List<CpuSample>? samples;

  CpuSamples({
    required this.samplePeriod,
    required this.maxStackDepth,
    required this.sampleCount,
    required this.timeSpan,
    required this.timeOriginMicros,
    required this.timeExtentMicros,
    required this.pid,
    required this.functions,
    required this.samples,
  });

  CpuSamples._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    samplePeriod = json['samplePeriod'] ?? -1;
    maxStackDepth = json['maxStackDepth'] ?? -1;
    sampleCount = json['sampleCount'] ?? -1;
    timeSpan = json['timeSpan'] ?? -1;
    timeOriginMicros = json['timeOriginMicros'] ?? -1;
    timeExtentMicros = json['timeExtentMicros'] ?? -1;
    pid = json['pid'] ?? -1;
    functions = List<ProfileFunction>.from(
        createServiceObject(json['functions'], const ['ProfileFunction'])
                as List? ??
            []);
    samples = List<CpuSample>.from(
        createServiceObject(json['samples'], const ['CpuSample']) as List? ??
            []);
  }

  @override
  String get type => 'CpuSamples';

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json['type'] = type;
    json.addAll({
      'samplePeriod': samplePeriod,
      'maxStackDepth': maxStackDepth,
      'sampleCount': sampleCount,
      'timeSpan': timeSpan,
      'timeOriginMicros': timeOriginMicros,
      'timeExtentMicros': timeExtentMicros,
      'pid': pid,
      'functions': functions?.map((f) => f.toJson()).toList(),
      'samples': samples?.map((f) => f.toJson()).toList(),
    });
    return json;
  }

  String toString() => '[CpuSamples]';
}

class CpuSamplesEvent {
  static CpuSamplesEvent? parse(Map<String, dynamic>? json) =>
      json == null ? null : CpuSamplesEvent._fromJson(json);

  /// The sampling rate for the profiler in microseconds.
  int? samplePeriod;

  /// The maximum possible stack depth for samples.
  int? maxStackDepth;

  /// The number of samples returned.
  int? sampleCount;

  /// The timespan the set of returned samples covers, in microseconds
  /// (deprecated).
  ///
  /// Note: this property is deprecated and will always return -1. Use
  /// `timeExtentMicros` instead.
  int? timeSpan;

  /// The start of the period of time in which the returned samples were
  /// collected.
  int? timeOriginMicros;

  /// The duration of time covered by the returned samples.
  int? timeExtentMicros;

  /// The process ID for the VM.
  int? pid;

  /// A list of references to functions seen in the relevant samples. These
  /// references can be looked up using the indicies provided in a `CpuSample`
  /// `stack` to determine which function was on the stack.
  List<dynamic>? functions;

  /// A list of samples collected in the range `[timeOriginMicros,
  /// timeOriginMicros + timeExtentMicros]`
  List<CpuSample>? samples;

  CpuSamplesEvent({
    required this.samplePeriod,
    required this.maxStackDepth,
    required this.sampleCount,
    required this.timeSpan,
    required this.timeOriginMicros,
    required this.timeExtentMicros,
    required this.pid,
    required this.functions,
    required this.samples,
  });

  CpuSamplesEvent._fromJson(Map<String, dynamic> json) {
    samplePeriod = json['samplePeriod'] ?? -1;
    maxStackDepth = json['maxStackDepth'] ?? -1;
    sampleCount = json['sampleCount'] ?? -1;
    timeSpan = json['timeSpan'] ?? -1;
    timeOriginMicros = json['timeOriginMicros'] ?? -1;
    timeExtentMicros = json['timeExtentMicros'] ?? -1;
    pid = json['pid'] ?? -1;
    functions = List<dynamic>.from(
        createServiceObject(json['functions'], const ['dynamic']) as List? ??
            []);
    samples = List<CpuSample>.from(
        createServiceObject(json['samples'], const ['CpuSample']) as List? ??
            []);
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json.addAll({
      'samplePeriod': samplePeriod,
      'maxStackDepth': maxStackDepth,
      'sampleCount': sampleCount,
      'timeSpan': timeSpan,
      'timeOriginMicros': timeOriginMicros,
      'timeExtentMicros': timeExtentMicros,
      'pid': pid,
      'functions': functions?.map((f) => f.toJson()).toList(),
      'samples': samples?.map((f) => f.toJson()).toList(),
    });
    return json;
  }

  String toString() => '[CpuSamplesEvent]';
}

/// See [getCpuSamples] and [CpuSamples].
class CpuSample {
  static CpuSample? parse(Map<String, dynamic>? json) =>
      json == null ? null : CpuSample._fromJson(json);

  /// The thread ID representing the thread on which this sample was collected.
  int? tid;

  /// The time this sample was collected in microseconds.
  int? timestamp;

  /// The name of VM tag set when this sample was collected. Omitted if the VM
  /// tag for the sample is not considered valid.
  @optional
  String? vmTag;

  /// The name of the User tag set when this sample was collected. Omitted if no
  /// User tag was set when this sample was collected.
  @optional
  String? userTag;

  /// Provided and set to true if the sample's stack was truncated. This can
  /// happen if the stack is deeper than the `stackDepth` in the `CpuSamples`
  /// response.
  @optional
  bool? truncated;

  /// The call stack at the time this sample was collected. The stack is to be
  /// interpreted as top to bottom. Each element in this array is a key into the
  /// `functions` array in `CpuSamples`.
  ///
  /// Example:
  ///
  /// `functions[stack[0]] = @Function(bar())` `functions[stack[1]] =
  /// @Function(foo())` `functions[stack[2]] = @Function(main())`
  List<int>? stack;

  /// The identityHashCode assigned to the allocated object. This hash code is
  /// the same as the hash code provided in HeapSnapshot. Provided for CpuSample
  /// instances returned from a getAllocationTraces().
  @optional
  int? identityHashCode;

  /// Matches the index of a class in HeapSnapshot.classes. Provided for
  /// CpuSample instances returned from a getAllocationTraces().
  @optional
  int? classId;

  CpuSample({
    required this.tid,
    required this.timestamp,
    required this.stack,
    this.vmTag,
    this.userTag,
    this.truncated,
    this.identityHashCode,
    this.classId,
  });

  CpuSample._fromJson(Map<String, dynamic> json) {
    tid = json['tid'] ?? -1;
    timestamp = json['timestamp'] ?? -1;
    vmTag = json['vmTag'];
    userTag = json['userTag'];
    truncated = json['truncated'];
    stack = List<int>.from(json['stack']);
    identityHashCode = json['identityHashCode'];
    classId = json['classId'];
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json.addAll({
      'tid': tid,
      'timestamp': timestamp,
      'stack': stack?.map((f) => f).toList(),
    });
    _setIfNotNull(json, 'vmTag', vmTag);
    _setIfNotNull(json, 'userTag', userTag);
    _setIfNotNull(json, 'truncated', truncated);
    _setIfNotNull(json, 'identityHashCode', identityHashCode);
    _setIfNotNull(json, 'classId', classId);
    return json;
  }

  String toString() =>
      '[CpuSample tid: ${tid}, timestamp: ${timestamp}, stack: ${stack}]';
}

/// `ErrorRef` is a reference to an `Error`.
class ErrorRef extends ObjRef {
  static ErrorRef? parse(Map<String, dynamic>? json) =>
      json == null ? null : ErrorRef._fromJson(json);

  /// What kind of error is this?
  /*ErrorKind*/ String? kind;

  /// A description of the error.
  String? message;

  ErrorRef({
    required this.kind,
    required this.message,
    required String id,
  }) : super(
          id: id,
        );

  ErrorRef._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    kind = json['kind'] ?? '';
    message = json['message'] ?? '';
  }

  @override
  String get type => '@Error';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['type'] = type;
    json.addAll({
      'kind': kind,
      'message': message,
    });
    return json;
  }

  int get hashCode => id.hashCode;

  bool operator ==(Object other) => other is ErrorRef && id == other.id;

  String toString() =>
      '[ErrorRef id: ${id}, kind: ${kind}, message: ${message}]';
}

/// An `Error` represents a Dart language level error. This is distinct from an
/// [RPC error].
class Error extends Obj implements ErrorRef {
  static Error? parse(Map<String, dynamic>? json) =>
      json == null ? null : Error._fromJson(json);

  /// What kind of error is this?
  /*ErrorKind*/ String? kind;

  /// A description of the error.
  String? message;

  /// If this error is due to an unhandled exception, this is the exception
  /// thrown.
  @optional
  InstanceRef? exception;

  /// If this error is due to an unhandled exception, this is the stacktrace
  /// object.
  @optional
  InstanceRef? stacktrace;

  Error({
    required this.kind,
    required this.message,
    required String id,
    this.exception,
    this.stacktrace,
  }) : super(
          id: id,
        );

  Error._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    kind = json['kind'] ?? '';
    message = json['message'] ?? '';
    exception = createServiceObject(json['exception'], const ['InstanceRef'])
        as InstanceRef?;
    stacktrace = createServiceObject(json['stacktrace'], const ['InstanceRef'])
        as InstanceRef?;
  }

  @override
  String get type => 'Error';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['type'] = type;
    json.addAll({
      'kind': kind,
      'message': message,
    });
    _setIfNotNull(json, 'exception', exception?.toJson());
    _setIfNotNull(json, 'stacktrace', stacktrace?.toJson());
    return json;
  }

  int get hashCode => id.hashCode;

  bool operator ==(Object other) => other is Error && id == other.id;

  String toString() => '[Error id: ${id}, kind: ${kind}, message: ${message}]';
}

/// An `Event` is an asynchronous notification from the VM. It is delivered only
/// when the client has subscribed to an event stream using the [streamListen]
/// RPC.
///
/// For more information, see [events].
class Event extends Response {
  static Event? parse(Map<String, dynamic>? json) =>
      json == null ? null : Event._fromJson(json);

  /// What kind of event is this?
  /*EventKind*/ String? kind;

  /// The isolate with which this event is associated.
  ///
  /// This is provided for all event kinds except for:
  ///  - VMUpdate, VMFlagUpdate
  @optional
  IsolateRef? isolate;

  /// The vm with which this event is associated.
  ///
  /// This is provided for the event kind:
  ///  - VMUpdate, VMFlagUpdate
  @optional
  VMRef? vm;

  /// The timestamp (in milliseconds since the epoch) associated with this
  /// event. For some isolate pause events, the timestamp is from when the
  /// isolate was paused. For other events, the timestamp is from when the event
  /// was created.
  int? timestamp;

  /// The breakpoint which was added, removed, or resolved.
  ///
  /// This is provided for the event kinds:
  ///  - PauseBreakpoint
  ///  - BreakpointAdded
  ///  - BreakpointRemoved
  ///  - BreakpointResolved
  ///  - BreakpointUpdated
  @optional
  Breakpoint? breakpoint;

  /// The list of breakpoints at which we are currently paused for a
  /// PauseBreakpoint event.
  ///
  /// This list may be empty. For example, while single-stepping, the VM sends a
  /// PauseBreakpoint event with no breakpoints.
  ///
  /// If there is more than one breakpoint set at the program position, then all
  /// of them will be provided.
  ///
  /// This is provided for the event kinds:
  ///  - PauseBreakpoint
  @optional
  List<Breakpoint>? pauseBreakpoints;

  /// The top stack frame associated with this event, if applicable.
  ///
  /// This is provided for the event kinds:
  ///  - PauseBreakpoint
  ///  - PauseInterrupted
  ///  - PauseException
  ///
  /// For PauseInterrupted events, there will be no top frame if the isolate is
  /// idle (waiting in the message loop).
  ///
  /// For the Resume event, the top frame is provided at all times except for
  /// the initial resume event that is delivered when an isolate begins
  /// execution.
  @optional
  Frame? topFrame;

  /// The exception associated with this event, if this is a PauseException
  /// event.
  @optional
  InstanceRef? exception;

  /// An array of bytes, encoded as a base64 string.
  ///
  /// This is provided for the WriteEvent event.
  @optional
  String? bytes;

  /// The argument passed to dart:developer.inspect.
  ///
  /// This is provided for the Inspect event.
  @optional
  InstanceRef? inspectee;

  /// The RPC name of the extension that was added.
  ///
  /// This is provided for the ServiceExtensionAdded event.
  @optional
  String? extensionRPC;

  /// The extension event kind.
  ///
  /// This is provided for the Extension event.
  @optional
  String? extensionKind;

  /// The extension event data.
  ///
  /// This is provided for the Extension event.
  @optional
  ExtensionData? extensionData;

  /// An array of TimelineEvents
  ///
  /// This is provided for the TimelineEvents event.
  @optional
  List<TimelineEvent>? timelineEvents;

  /// The new set of recorded timeline streams.
  ///
  /// This is provided for the TimelineStreamSubscriptionsUpdate event.
  @optional
  List<String>? updatedStreams;

  /// Is the isolate paused at an await, yield, or yield* statement?
  ///
  /// This is provided for the event kinds:
  ///  - PauseBreakpoint
  ///  - PauseInterrupted
  @optional
  bool? atAsyncSuspension;

  /// The status (success or failure) related to the event. This is provided for
  /// the event kinds:
  ///  - IsolateReloaded
  @optional
  String? status;

  /// LogRecord data.
  ///
  /// This is provided for the Logging event.
  @optional
  LogRecord? logRecord;

  /// The service identifier.
  ///
  /// This is provided for the event kinds:
  ///  - ServiceRegistered
  ///  - ServiceUnregistered
  @optional
  String? service;

  /// The RPC method that should be used to invoke the service.
  ///
  /// This is provided for the event kinds:
  ///  - ServiceRegistered
  ///  - ServiceUnregistered
  @optional
  String? method;

  /// The alias of the registered service.
  ///
  /// This is provided for the event kinds:
  ///  - ServiceRegistered
  @optional
  String? alias;

  /// The name of the changed flag.
  ///
  /// This is provided for the event kinds:
  ///  - VMFlagUpdate
  @optional
  String? flag;

  /// The new value of the changed flag.
  ///
  /// This is provided for the event kinds:
  ///  - VMFlagUpdate
  @optional
  String? newValue;

  /// Specifies whether this event is the last of a group of events.
  ///
  /// This is provided for the event kinds:
  ///  - HeapSnapshot
  @optional
  bool? last;

  /// The current UserTag label.
  @optional
  String? updatedTag;

  /// The previous UserTag label.
  @optional
  String? previousTag;

  /// A CPU profile containing recent samples.
  @optional
  CpuSamplesEvent? cpuSamples;

  /// Binary data associated with the event.
  ///
  /// This is provided for the event kinds:
  ///   - HeapSnapshot
  @optional
  ByteData? data;

  Event({
    required this.kind,
    required this.timestamp,
    this.isolate,
    this.vm,
    this.breakpoint,
    this.pauseBreakpoints,
    this.topFrame,
    this.exception,
    this.bytes,
    this.inspectee,
    this.extensionRPC,
    this.extensionKind,
    this.extensionData,
    this.timelineEvents,
    this.updatedStreams,
    this.atAsyncSuspension,
    this.status,
    this.logRecord,
    this.service,
    this.method,
    this.alias,
    this.flag,
    this.newValue,
    this.last,
    this.updatedTag,
    this.previousTag,
    this.cpuSamples,
    this.data,
  });

  Event._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    kind = json['kind'] ?? '';
    isolate = createServiceObject(json['isolate'], const ['IsolateRef'])
        as IsolateRef?;
    vm = createServiceObject(json['vm'], const ['VMRef']) as VMRef?;
    timestamp = json['timestamp'] ?? -1;
    breakpoint = createServiceObject(json['breakpoint'], const ['Breakpoint'])
        as Breakpoint?;
    pauseBreakpoints = json['pauseBreakpoints'] == null
        ? null
        : List<Breakpoint>.from(
            createServiceObject(json['pauseBreakpoints'], const ['Breakpoint'])!
                as List);
    topFrame = createServiceObject(json['topFrame'], const ['Frame']) as Frame?;
    exception = createServiceObject(json['exception'], const ['InstanceRef'])
        as InstanceRef?;
    bytes = json['bytes'];
    inspectee = createServiceObject(json['inspectee'], const ['InstanceRef'])
        as InstanceRef?;
    extensionRPC = json['extensionRPC'];
    extensionKind = json['extensionKind'];
    extensionData = ExtensionData.parse(json['extensionData']);
    timelineEvents = json['timelineEvents'] == null
        ? null
        : List<TimelineEvent>.from(createServiceObject(
            json['timelineEvents'], const ['TimelineEvent'])! as List);
    updatedStreams = json['updatedStreams'] == null
        ? null
        : List<String>.from(json['updatedStreams']);
    atAsyncSuspension = json['atAsyncSuspension'];
    status = json['status'];
    logRecord = createServiceObject(json['logRecord'], const ['LogRecord'])
        as LogRecord?;
    service = json['service'];
    method = json['method'];
    alias = json['alias'];
    flag = json['flag'];
    newValue = json['newValue'];
    last = json['last'];
    updatedTag = json['updatedTag'];
    previousTag = json['previousTag'];
    cpuSamples =
        createServiceObject(json['cpuSamples'], const ['CpuSamplesEvent'])
            as CpuSamplesEvent?;
    data = json['data'];
  }

  @override
  String get type => 'Event';

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json['type'] = type;
    json.addAll({
      'kind': kind,
      'timestamp': timestamp,
    });
    _setIfNotNull(json, 'isolate', isolate?.toJson());
    _setIfNotNull(json, 'vm', vm?.toJson());
    _setIfNotNull(json, 'breakpoint', breakpoint?.toJson());
    _setIfNotNull(json, 'pauseBreakpoints',
        pauseBreakpoints?.map((f) => f.toJson()).toList());
    _setIfNotNull(json, 'topFrame', topFrame?.toJson());
    _setIfNotNull(json, 'exception', exception?.toJson());
    _setIfNotNull(json, 'bytes', bytes);
    _setIfNotNull(json, 'inspectee', inspectee?.toJson());
    _setIfNotNull(json, 'extensionRPC', extensionRPC);
    _setIfNotNull(json, 'extensionKind', extensionKind);
    _setIfNotNull(json, 'extensionData', extensionData?.data);
    _setIfNotNull(json, 'timelineEvents',
        timelineEvents?.map((f) => f.toJson()).toList());
    _setIfNotNull(
        json, 'updatedStreams', updatedStreams?.map((f) => f).toList());
    _setIfNotNull(json, 'atAsyncSuspension', atAsyncSuspension);
    _setIfNotNull(json, 'status', status);
    _setIfNotNull(json, 'logRecord', logRecord?.toJson());
    _setIfNotNull(json, 'service', service);
    _setIfNotNull(json, 'method', method);
    _setIfNotNull(json, 'alias', alias);
    _setIfNotNull(json, 'flag', flag);
    _setIfNotNull(json, 'newValue', newValue);
    _setIfNotNull(json, 'last', last);
    _setIfNotNull(json, 'updatedTag', updatedTag);
    _setIfNotNull(json, 'previousTag', previousTag);
    _setIfNotNull(json, 'cpuSamples', cpuSamples?.toJson());
    _setIfNotNull(json, 'data', data);
    return json;
  }

  String toString() => '[Event kind: ${kind}, timestamp: ${timestamp}]';
}

/// An `FieldRef` is a reference to a `Field`.
class FieldRef extends ObjRef {
  static FieldRef? parse(Map<String, dynamic>? json) =>
      json == null ? null : FieldRef._fromJson(json);

  /// The name of this field.
  String? name;

  /// The owner of this field, which can be either a Library or a Class.
  ///
  /// Note: the location of `owner` may not agree with `location` if this is a
  /// field from a mixin application, patched class, etc.
  ObjRef? owner;

  /// The declared type of this field.
  ///
  /// The value will always be of one of the kinds: Type, TypeRef,
  /// TypeParameter, BoundedType.
  InstanceRef? declaredType;

  /// Is this field const?
  bool? isConst;

  /// Is this field final?
  bool? isFinal;

  /// Is this field static?
  bool? isStatic;

  /// The location of this field in the source code.
  ///
  /// Note: this may not agree with the location of `owner` if this is a field
  /// from a mixin application, patched class, etc.
  @optional
  SourceLocation? location;

  FieldRef({
    required this.name,
    required this.owner,
    required this.declaredType,
    required this.isConst,
    required this.isFinal,
    required this.isStatic,
    required String id,
    this.location,
  }) : super(
          id: id,
        );

  FieldRef._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    name = json['name'] ?? '';
    owner = createServiceObject(json['owner'], const ['ObjRef']) as ObjRef?;
    declaredType =
        createServiceObject(json['declaredType'], const ['InstanceRef'])
            as InstanceRef?;
    isConst = json['const'] ?? false;
    isFinal = json['final'] ?? false;
    isStatic = json['static'] ?? false;
    location = createServiceObject(json['location'], const ['SourceLocation'])
        as SourceLocation?;
  }

  @override
  String get type => '@Field';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['type'] = type;
    json.addAll({
      'name': name,
      'owner': owner?.toJson(),
      'declaredType': declaredType?.toJson(),
      'const': isConst,
      'final': isFinal,
      'static': isStatic,
    });
    _setIfNotNull(json, 'location', location?.toJson());
    return json;
  }

  int get hashCode => id.hashCode;

  bool operator ==(Object other) => other is FieldRef && id == other.id;

  String toString() => '[FieldRef ' //
      'id: ${id}, name: ${name}, owner: ${owner}, declaredType: ${declaredType}, ' //
      'isConst: ${isConst}, isFinal: ${isFinal}, isStatic: ${isStatic}]';
}

/// A `Field` provides information about a Dart language field or variable.
class Field extends Obj implements FieldRef {
  static Field? parse(Map<String, dynamic>? json) =>
      json == null ? null : Field._fromJson(json);

  /// The name of this field.
  String? name;

  /// The owner of this field, which can be either a Library or a Class.
  ///
  /// Note: the location of `owner` may not agree with `location` if this is a
  /// field from a mixin application, patched class, etc.
  ObjRef? owner;

  /// The declared type of this field.
  ///
  /// The value will always be of one of the kinds: Type, TypeRef,
  /// TypeParameter, BoundedType.
  InstanceRef? declaredType;

  /// Is this field const?
  bool? isConst;

  /// Is this field final?
  bool? isFinal;

  /// Is this field static?
  bool? isStatic;

  /// The location of this field in the source code.
  ///
  /// Note: this may not agree with the location of `owner` if this is a field
  /// from a mixin application, patched class, etc.
  @optional
  SourceLocation? location;

  /// The value of this field, if the field is static. If uninitialized, this
  /// will take the value of an uninitialized Sentinel.
  ///
  /// [staticValue] can be one of [InstanceRef] or [Sentinel].
  @optional
  dynamic staticValue;

  Field({
    required this.name,
    required this.owner,
    required this.declaredType,
    required this.isConst,
    required this.isFinal,
    required this.isStatic,
    required String id,
    this.location,
    this.staticValue,
  }) : super(
          id: id,
        );

  Field._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    name = json['name'] ?? '';
    owner = createServiceObject(json['owner'], const ['ObjRef']) as ObjRef?;
    declaredType =
        createServiceObject(json['declaredType'], const ['InstanceRef'])
            as InstanceRef?;
    isConst = json['const'] ?? false;
    isFinal = json['final'] ?? false;
    isStatic = json['static'] ?? false;
    location = createServiceObject(json['location'], const ['SourceLocation'])
        as SourceLocation?;
    staticValue = createServiceObject(
        json['staticValue'], const ['InstanceRef', 'Sentinel']) as dynamic;
  }

  @override
  String get type => 'Field';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['type'] = type;
    json.addAll({
      'name': name,
      'owner': owner?.toJson(),
      'declaredType': declaredType?.toJson(),
      'const': isConst,
      'final': isFinal,
      'static': isStatic,
    });
    _setIfNotNull(json, 'location', location?.toJson());
    _setIfNotNull(json, 'staticValue', staticValue?.toJson());
    return json;
  }

  int get hashCode => id.hashCode;

  bool operator ==(Object other) => other is Field && id == other.id;

  String toString() => '[Field ' //
      'id: ${id}, name: ${name}, owner: ${owner}, declaredType: ${declaredType}, ' //
      'isConst: ${isConst}, isFinal: ${isFinal}, isStatic: ${isStatic}]';
}

/// A `Flag` represents a single VM command line flag.
class Flag {
  static Flag? parse(Map<String, dynamic>? json) =>
      json == null ? null : Flag._fromJson(json);

  /// The name of the flag.
  String? name;

  /// A description of the flag.
  String? comment;

  /// Has this flag been modified from its default setting?
  bool? modified;

  /// The value of this flag as a string.
  ///
  /// If this property is absent, then the value of the flag was NULL.
  @optional
  String? valueAsString;

  Flag({
    required this.name,
    required this.comment,
    required this.modified,
    this.valueAsString,
  });

  Flag._fromJson(Map<String, dynamic> json) {
    name = json['name'] ?? '';
    comment = json['comment'] ?? '';
    modified = json['modified'] ?? false;
    valueAsString = json['valueAsString'];
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json.addAll({
      'name': name,
      'comment': comment,
      'modified': modified,
    });
    _setIfNotNull(json, 'valueAsString', valueAsString);
    return json;
  }

  String toString() =>
      '[Flag name: ${name}, comment: ${comment}, modified: ${modified}]';
}

/// A `FlagList` represents the complete set of VM command line flags.
class FlagList extends Response {
  static FlagList? parse(Map<String, dynamic>? json) =>
      json == null ? null : FlagList._fromJson(json);

  /// A list of all flags in the VM.
  List<Flag>? flags;

  FlagList({
    required this.flags,
  });

  FlagList._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    flags = List<Flag>.from(
        createServiceObject(json['flags'], const ['Flag']) as List? ?? []);
  }

  @override
  String get type => 'FlagList';

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json['type'] = type;
    json.addAll({
      'flags': flags?.map((f) => f.toJson()).toList(),
    });
    return json;
  }

  String toString() => '[FlagList flags: ${flags}]';
}

class Frame extends Response {
  static Frame? parse(Map<String, dynamic>? json) =>
      json == null ? null : Frame._fromJson(json);

  int? index;

  @optional
  FuncRef? function;

  @optional
  CodeRef? code;

  @optional
  SourceLocation? location;

  @optional
  List<BoundVariable>? vars;

  @optional
  /*FrameKind*/ String? kind;

  Frame({
    required this.index,
    this.function,
    this.code,
    this.location,
    this.vars,
    this.kind,
  });

  Frame._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    index = json['index'] ?? -1;
    function =
        createServiceObject(json['function'], const ['FuncRef']) as FuncRef?;
    code = createServiceObject(json['code'], const ['CodeRef']) as CodeRef?;
    location = createServiceObject(json['location'], const ['SourceLocation'])
        as SourceLocation?;
    vars = json['vars'] == null
        ? null
        : List<BoundVariable>.from(
            createServiceObject(json['vars'], const ['BoundVariable'])!
                as List);
    kind = json['kind'];
  }

  @override
  String get type => 'Frame';

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json['type'] = type;
    json.addAll({
      'index': index,
    });
    _setIfNotNull(json, 'function', function?.toJson());
    _setIfNotNull(json, 'code', code?.toJson());
    _setIfNotNull(json, 'location', location?.toJson());
    _setIfNotNull(json, 'vars', vars?.map((f) => f.toJson()).toList());
    _setIfNotNull(json, 'kind', kind);
    return json;
  }

  String toString() => '[Frame index: ${index}]';
}

/// An `FuncRef` is a reference to a `Func`.
class FuncRef extends ObjRef {
  static FuncRef? parse(Map<String, dynamic>? json) =>
      json == null ? null : FuncRef._fromJson(json);

  /// The name of this function.
  String? name;

  /// The owner of this function, which can be a Library, Class, or a Function.
  ///
  /// Note: the location of `owner` may not agree with `location` if this is a
  /// function from a mixin application, expression evaluation, patched class,
  /// etc.
  ///
  /// [owner] can be one of [LibraryRef], [ClassRef] or [FuncRef].
  dynamic owner;

  /// Is this function static?
  bool? isStatic;

  /// Is this function const?
  bool? isConst;

  /// Is this function implicitly defined (e.g., implicit getter/setter)?
  bool? implicit;

  /// The location of this function in the source code.
  ///
  /// Note: this may not agree with the location of `owner` if this is a
  /// function from a mixin application, expression evaluation, patched class,
  /// etc.
  @optional
  SourceLocation? location;

  FuncRef({
    required this.name,
    required this.owner,
    required this.isStatic,
    required this.isConst,
    required this.implicit,
    required String id,
    this.location,
  }) : super(
          id: id,
        );

  FuncRef._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    name = json['name'] ?? '';
    owner = createServiceObject(
        json['owner'], const ['LibraryRef', 'ClassRef', 'FuncRef']) as dynamic;
    isStatic = json['static'] ?? false;
    isConst = json['const'] ?? false;
    implicit = json['implicit'] ?? false;
    location = createServiceObject(json['location'], const ['SourceLocation'])
        as SourceLocation?;
  }

  @override
  String get type => '@Function';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['type'] = type;
    json.addAll({
      'name': name,
      'owner': owner?.toJson(),
      'static': isStatic,
      'const': isConst,
      'implicit': implicit,
    });
    _setIfNotNull(json, 'location', location?.toJson());
    return json;
  }

  int get hashCode => id.hashCode;

  bool operator ==(Object other) => other is FuncRef && id == other.id;

  String toString() => '[FuncRef ' //
      'id: ${id}, name: ${name}, owner: ${owner}, isStatic: ${isStatic}, ' //
      'isConst: ${isConst}, implicit: ${implicit}]';
}

/// A `Func` represents a Dart language function.
class Func extends Obj implements FuncRef {
  static Func? parse(Map<String, dynamic>? json) =>
      json == null ? null : Func._fromJson(json);

  /// The name of this function.
  String? name;

  /// The owner of this function, which can be a Library, Class, or a Function.
  ///
  /// Note: the location of `owner` may not agree with `location` if this is a
  /// function from a mixin application, expression evaluation, patched class,
  /// etc.
  ///
  /// [owner] can be one of [LibraryRef], [ClassRef] or [FuncRef].
  dynamic owner;

  /// Is this function static?
  bool? isStatic;

  /// Is this function const?
  bool? isConst;

  /// Is this function implicitly defined (e.g., implicit getter/setter)?
  bool? implicit;

  /// The location of this function in the source code.
  ///
  /// Note: this may not agree with the location of `owner` if this is a
  /// function from a mixin application, expression evaluation, patched class,
  /// etc.
  @optional
  SourceLocation? location;

  /// The signature of the function.
  InstanceRef? signature;

  /// The compiled code associated with this function.
  @optional
  CodeRef? code;

  Func({
    required this.name,
    required this.owner,
    required this.isStatic,
    required this.isConst,
    required this.implicit,
    required this.signature,
    required String id,
    this.location,
    this.code,
  }) : super(
          id: id,
        );

  Func._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    name = json['name'] ?? '';
    owner = createServiceObject(
        json['owner'], const ['LibraryRef', 'ClassRef', 'FuncRef']) as dynamic;
    isStatic = json['static'] ?? false;
    isConst = json['const'] ?? false;
    implicit = json['implicit'] ?? false;
    location = createServiceObject(json['location'], const ['SourceLocation'])
        as SourceLocation?;
    signature = createServiceObject(json['signature'], const ['InstanceRef'])
        as InstanceRef?;
    code = createServiceObject(json['code'], const ['CodeRef']) as CodeRef?;
  }

  @override
  String get type => 'Function';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['type'] = type;
    json.addAll({
      'name': name,
      'owner': owner?.toJson(),
      'static': isStatic,
      'const': isConst,
      'implicit': implicit,
      'signature': signature?.toJson(),
    });
    _setIfNotNull(json, 'location', location?.toJson());
    _setIfNotNull(json, 'code', code?.toJson());
    return json;
  }

  int get hashCode => id.hashCode;

  bool operator ==(Object other) => other is Func && id == other.id;

  String toString() => '[Func ' //
      'id: ${id}, name: ${name}, owner: ${owner}, isStatic: ${isStatic}, ' //
      'isConst: ${isConst}, implicit: ${implicit}, signature: ${signature}]';
}

/// `InstanceRef` is a reference to an `Instance`.
class InstanceRef extends ObjRef {
  static InstanceRef? parse(Map<String, dynamic>? json) =>
      json == null ? null : InstanceRef._fromJson(json);

  /// What kind of instance is this?
  /*InstanceKind*/ String? kind;

  /// The identityHashCode assigned to the allocated object. This hash code is
  /// the same as the hash code provided in HeapSnapshot and CpuSample's
  /// returned by getAllocationTraces().
  int? identityHashCode;

  /// Instance references always include their class.
  ClassRef? classRef;

  /// The value of this instance as a string.
  ///
  /// Provided for the instance kinds:
  ///  - Null (null)
  ///  - Bool (true or false)
  ///  - Double (suitable for passing to Double.parse())
  ///  - Int (suitable for passing to int.parse())
  ///  - String (value may be truncated)
  ///  - Float32x4
  ///  - Float64x2
  ///  - Int32x4
  ///  - StackTrace
  @optional
  String? valueAsString;

  /// The valueAsString for String references may be truncated. If so, this
  /// property is added with the value 'true'.
  ///
  /// New code should use 'length' and 'count' instead.
  @optional
  bool? valueAsStringIsTruncated;

  /// The length of a List or the number of associations in a Map or the number
  /// of codeunits in a String.
  ///
  /// Provided for instance kinds:
  ///  - String
  ///  - List
  ///  - Map
  ///  - Uint8ClampedList
  ///  - Uint8List
  ///  - Uint16List
  ///  - Uint32List
  ///  - Uint64List
  ///  - Int8List
  ///  - Int16List
  ///  - Int32List
  ///  - Int64List
  ///  - Float32List
  ///  - Float64List
  ///  - Int32x4List
  ///  - Float32x4List
  ///  - Float64x2List
  @optional
  int? length;

  /// The name of a Type instance.
  ///
  /// Provided for instance kinds:
  ///  - Type
  @optional
  String? name;

  /// The corresponding Class if this Type has a resolved typeClass.
  ///
  /// Provided for instance kinds:
  ///  - Type
  @optional
  ClassRef? typeClass;

  /// The parameterized class of a type parameter.
  ///
  /// Provided for instance kinds:
  ///  - TypeParameter
  @optional
  ClassRef? parameterizedClass;

  /// The return type of a function.
  ///
  /// Provided for instance kinds:
  ///  - FunctionType
  @optional
  InstanceRef? returnType;

  /// The list of parameter types for a function.
  ///
  /// Provided for instance kinds:
  ///  - FunctionType
  @optional
  List<Parameter>? parameters;

  /// The type parameters for a function.
  ///
  /// Provided for instance kinds:
  ///  - FunctionType
  @optional
  List<InstanceRef>? typeParameters;

  /// The pattern of a RegExp instance.
  ///
  /// The pattern is always an instance of kind String.
  ///
  /// Provided for instance kinds:
  ///  - RegExp
  @optional
  InstanceRef? pattern;

  /// The function associated with a Closure instance.
  ///
  /// Provided for instance kinds:
  ///  - Closure
  @optional
  FuncRef? closureFunction;

  /// The context associated with a Closure instance.
  ///
  /// Provided for instance kinds:
  ///  - Closure
  @optional
  ContextRef? closureContext;

  /// The port ID for a ReceivePort.
  ///
  /// Provided for instance kinds:
  ///  - ReceivePort
  @optional
  int? portId;

  /// The stack trace associated with the allocation of a ReceivePort.
  ///
  /// Provided for instance kinds:
  ///  - ReceivePort
  @optional
  InstanceRef? allocationLocation;

  /// A name associated with a ReceivePort used for debugging purposes.
  ///
  /// Provided for instance kinds:
  ///  - ReceivePort
  @optional
  String? debugName;

  InstanceRef({
    required this.kind,
    required this.identityHashCode,
    required this.classRef,
    required String id,
    this.valueAsString,
    this.valueAsStringIsTruncated,
    this.length,
    this.name,
    this.typeClass,
    this.parameterizedClass,
    this.returnType,
    this.parameters,
    this.typeParameters,
    this.pattern,
    this.closureFunction,
    this.closureContext,
    this.portId,
    this.allocationLocation,
    this.debugName,
  }) : super(
          id: id,
        );

  InstanceRef._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    kind = json['kind'] ?? '';
    identityHashCode = json['identityHashCode'] ?? -1;
    classRef =
        createServiceObject(json['class'], const ['ClassRef']) as ClassRef?;
    valueAsString = json['valueAsString'];
    valueAsStringIsTruncated = json['valueAsStringIsTruncated'];
    length = json['length'];
    name = json['name'];
    typeClass =
        createServiceObject(json['typeClass'], const ['ClassRef']) as ClassRef?;
    parameterizedClass =
        createServiceObject(json['parameterizedClass'], const ['ClassRef'])
            as ClassRef?;
    returnType = createServiceObject(json['returnType'], const ['InstanceRef'])
        as InstanceRef?;
    parameters = json['parameters'] == null
        ? null
        : List<Parameter>.from(
            createServiceObject(json['parameters'], const ['Parameter'])!
                as List);
    typeParameters = json['typeParameters'] == null
        ? null
        : List<InstanceRef>.from(
            createServiceObject(json['typeParameters'], const ['InstanceRef'])!
                as List);
    pattern = createServiceObject(json['pattern'], const ['InstanceRef'])
        as InstanceRef?;
    closureFunction =
        createServiceObject(json['closureFunction'], const ['FuncRef'])
            as FuncRef?;
    closureContext =
        createServiceObject(json['closureContext'], const ['ContextRef'])
            as ContextRef?;
    portId = json['portId'];
    allocationLocation =
        createServiceObject(json['allocationLocation'], const ['InstanceRef'])
            as InstanceRef?;
    debugName = json['debugName'];
  }

  @override
  String get type => '@Instance';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['type'] = type;
    json.addAll({
      'kind': kind,
      'identityHashCode': identityHashCode,
      'class': classRef?.toJson(),
    });
    _setIfNotNull(json, 'valueAsString', valueAsString);
    _setIfNotNull(json, 'valueAsStringIsTruncated', valueAsStringIsTruncated);
    _setIfNotNull(json, 'length', length);
    _setIfNotNull(json, 'name', name);
    _setIfNotNull(json, 'typeClass', typeClass?.toJson());
    _setIfNotNull(json, 'parameterizedClass', parameterizedClass?.toJson());
    _setIfNotNull(json, 'returnType', returnType?.toJson());
    _setIfNotNull(
        json, 'parameters', parameters?.map((f) => f.toJson()).toList());
    _setIfNotNull(json, 'typeParameters',
        typeParameters?.map((f) => f.toJson()).toList());
    _setIfNotNull(json, 'pattern', pattern?.toJson());
    _setIfNotNull(json, 'closureFunction', closureFunction?.toJson());
    _setIfNotNull(json, 'closureContext', closureContext?.toJson());
    _setIfNotNull(json, 'portId', portId);
    _setIfNotNull(json, 'allocationLocation', allocationLocation?.toJson());
    _setIfNotNull(json, 'debugName', debugName);
    return json;
  }

  int get hashCode => id.hashCode;

  bool operator ==(Object other) => other is InstanceRef && id == other.id;

  String toString() => '[InstanceRef ' //
      'id: ${id}, kind: ${kind}, identityHashCode: ${identityHashCode}, ' //
      'classRef: ${classRef}]';
}

/// An `Instance` represents an instance of the Dart language class `Obj`.
class Instance extends Obj implements InstanceRef {
  static Instance? parse(Map<String, dynamic>? json) =>
      json == null ? null : Instance._fromJson(json);

  /// What kind of instance is this?
  /*InstanceKind*/ String? kind;

  /// The identityHashCode assigned to the allocated object. This hash code is
  /// the same as the hash code provided in HeapSnapshot and CpuSample's
  /// returned by getAllocationTraces().
  int? identityHashCode;

  /// Instance references always include their class.
  @override
  ClassRef? classRef;

  /// The value of this instance as a string.
  ///
  /// Provided for the instance kinds:
  ///  - Bool (true or false)
  ///  - Double (suitable for passing to Double.parse())
  ///  - Int (suitable for passing to int.parse())
  ///  - String (value may be truncated)
  ///  - StackTrace
  @optional
  String? valueAsString;

  /// The valueAsString for String references may be truncated. If so, this
  /// property is added with the value 'true'.
  ///
  /// New code should use 'length' and 'count' instead.
  @optional
  bool? valueAsStringIsTruncated;

  /// The length of a List or the number of associations in a Map or the number
  /// of codeunits in a String.
  ///
  /// Provided for instance kinds:
  ///  - String
  ///  - List
  ///  - Map
  ///  - Uint8ClampedList
  ///  - Uint8List
  ///  - Uint16List
  ///  - Uint32List
  ///  - Uint64List
  ///  - Int8List
  ///  - Int16List
  ///  - Int32List
  ///  - Int64List
  ///  - Float32List
  ///  - Float64List
  ///  - Int32x4List
  ///  - Float32x4List
  ///  - Float64x2List
  @optional
  int? length;

  /// The index of the first element or association or codeunit returned. This
  /// is only provided when it is non-zero.
  ///
  /// Provided for instance kinds:
  ///  - String
  ///  - List
  ///  - Map
  ///  - Uint8ClampedList
  ///  - Uint8List
  ///  - Uint16List
  ///  - Uint32List
  ///  - Uint64List
  ///  - Int8List
  ///  - Int16List
  ///  - Int32List
  ///  - Int64List
  ///  - Float32List
  ///  - Float64List
  ///  - Int32x4List
  ///  - Float32x4List
  ///  - Float64x2List
  @optional
  int? offset;

  /// The number of elements or associations or codeunits returned. This is only
  /// provided when it is less than length.
  ///
  /// Provided for instance kinds:
  ///  - String
  ///  - List
  ///  - Map
  ///  - Uint8ClampedList
  ///  - Uint8List
  ///  - Uint16List
  ///  - Uint32List
  ///  - Uint64List
  ///  - Int8List
  ///  - Int16List
  ///  - Int32List
  ///  - Int64List
  ///  - Float32List
  ///  - Float64List
  ///  - Int32x4List
  ///  - Float32x4List
  ///  - Float64x2List
  @optional
  int? count;

  /// The name of a Type instance.
  ///
  /// Provided for instance kinds:
  ///  - Type
  @optional
  String? name;

  /// The corresponding Class if this Type is canonical.
  ///
  /// Provided for instance kinds:
  ///  - Type
  @optional
  ClassRef? typeClass;

  /// The parameterized class of a type parameter:
  ///
  /// Provided for instance kinds:
  ///  - TypeParameter
  @optional
  ClassRef? parameterizedClass;

  /// The return type of a function.
  ///
  /// Provided for instance kinds:
  ///  - FunctionType
  @optional
  InstanceRef? returnType;

  /// The list of parameter types for a function.
  ///
  /// Provided for instance kinds:
  ///  - FunctionType
  @optional
  List<Parameter>? parameters;

  /// The type parameters for a function.
  ///
  /// Provided for instance kinds:
  ///  - FunctionType
  @optional
  List<InstanceRef>? typeParameters;

  /// The fields of this Instance.
  @optional
  List<BoundField>? fields;

  /// The elements of a List instance.
  ///
  /// Provided for instance kinds:
  ///  - List
  @optional
  List<dynamic>? elements;

  /// The elements of a Map instance.
  ///
  /// Provided for instance kinds:
  ///  - Map
  @optional
  List<MapAssociation>? associations;

  /// The bytes of a TypedData instance.
  ///
  /// The data is provided as a Base64 encoded string.
  ///
  /// Provided for instance kinds:
  ///  - Uint8ClampedList
  ///  - Uint8List
  ///  - Uint16List
  ///  - Uint32List
  ///  - Uint64List
  ///  - Int8List
  ///  - Int16List
  ///  - Int32List
  ///  - Int64List
  ///  - Float32List
  ///  - Float64List
  ///  - Int32x4List
  ///  - Float32x4List
  ///  - Float64x2List
  @optional
  String? bytes;

  /// The referent of a MirrorReference instance.
  ///
  /// Provided for instance kinds:
  ///  - MirrorReference
  @optional
  InstanceRef? mirrorReferent;

  /// The pattern of a RegExp instance.
  ///
  /// Provided for instance kinds:
  ///  - RegExp
  @optional
  InstanceRef? pattern;

  /// The function associated with a Closure instance.
  ///
  /// Provided for instance kinds:
  ///  - Closure
  @optional
  FuncRef? closureFunction;

  /// The context associated with a Closure instance.
  ///
  /// Provided for instance kinds:
  ///  - Closure
  @optional
  ContextRef? closureContext;

  /// Whether this regular expression is case sensitive.
  ///
  /// Provided for instance kinds:
  ///  - RegExp
  @optional
  bool? isCaseSensitive;

  /// Whether this regular expression matches multiple lines.
  ///
  /// Provided for instance kinds:
  ///  - RegExp
  @optional
  bool? isMultiLine;

  /// The key for a WeakProperty instance.
  ///
  /// Provided for instance kinds:
  ///  - WeakProperty
  @optional
  InstanceRef? propertyKey;

  /// The key for a WeakProperty instance.
  ///
  /// Provided for instance kinds:
  ///  - WeakProperty
  @optional
  InstanceRef? propertyValue;

  /// The type arguments for this type.
  ///
  /// Provided for instance kinds:
  ///  - Type
  @optional
  TypeArgumentsRef? typeArguments;

  /// The index of a TypeParameter instance.
  ///
  /// Provided for instance kinds:
  ///  - TypeParameter
  @optional
  int? parameterIndex;

  /// The type bounded by a BoundedType instance - or - the referent of a
  /// TypeRef instance.
  ///
  /// The value will always be of one of the kinds: Type, TypeRef,
  /// TypeParameter, BoundedType.
  ///
  /// Provided for instance kinds:
  ///  - BoundedType
  ///  - TypeRef
  @optional
  InstanceRef? targetType;

  /// The bound of a TypeParameter or BoundedType.
  ///
  /// The value will always be of one of the kinds: Type, TypeRef,
  /// TypeParameter, BoundedType.
  ///
  /// Provided for instance kinds:
  ///  - BoundedType
  ///  - TypeParameter
  @optional
  InstanceRef? bound;

  /// The port ID for a ReceivePort.
  ///
  /// Provided for instance kinds:
  ///  - ReceivePort
  @optional
  int? portId;

  /// The stack trace associated with the allocation of a ReceivePort.
  ///
  /// Provided for instance kinds:
  ///  - ReceivePort
  @optional
  InstanceRef? allocationLocation;

  /// A name associated with a ReceivePort used for debugging purposes.
  ///
  /// Provided for instance kinds:
  ///  - ReceivePort
  @optional
  String? debugName;

  Instance({
    required this.kind,
    required this.identityHashCode,
    required this.classRef,
    required String id,
    this.valueAsString,
    this.valueAsStringIsTruncated,
    this.length,
    this.offset,
    this.count,
    this.name,
    this.typeClass,
    this.parameterizedClass,
    this.returnType,
    this.parameters,
    this.typeParameters,
    this.fields,
    this.elements,
    this.associations,
    this.bytes,
    this.mirrorReferent,
    this.pattern,
    this.closureFunction,
    this.closureContext,
    this.isCaseSensitive,
    this.isMultiLine,
    this.propertyKey,
    this.propertyValue,
    this.typeArguments,
    this.parameterIndex,
    this.targetType,
    this.bound,
    this.portId,
    this.allocationLocation,
    this.debugName,
  }) : super(
          id: id,
          classRef: classRef,
        );

  Instance._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    kind = json['kind'] ?? '';
    identityHashCode = json['identityHashCode'] ?? -1;
    classRef =
        createServiceObject(json['class'], const ['ClassRef']) as ClassRef?;
    valueAsString = json['valueAsString'];
    valueAsStringIsTruncated = json['valueAsStringIsTruncated'];
    length = json['length'];
    offset = json['offset'];
    count = json['count'];
    name = json['name'];
    typeClass =
        createServiceObject(json['typeClass'], const ['ClassRef']) as ClassRef?;
    parameterizedClass =
        createServiceObject(json['parameterizedClass'], const ['ClassRef'])
            as ClassRef?;
    returnType = createServiceObject(json['returnType'], const ['InstanceRef'])
        as InstanceRef?;
    parameters = json['parameters'] == null
        ? null
        : List<Parameter>.from(
            createServiceObject(json['parameters'], const ['Parameter'])!
                as List);
    typeParameters = json['typeParameters'] == null
        ? null
        : List<InstanceRef>.from(
            createServiceObject(json['typeParameters'], const ['InstanceRef'])!
                as List);
    fields = json['fields'] == null
        ? null
        : List<BoundField>.from(
            createServiceObject(json['fields'], const ['BoundField'])! as List);
    elements = json['elements'] == null
        ? null
        : List<dynamic>.from(
            createServiceObject(json['elements'], const ['dynamic'])! as List);
    associations = json['associations'] == null
        ? null
        : List<MapAssociation>.from(
            _createSpecificObject(json['associations'], MapAssociation.parse));
    bytes = json['bytes'];
    mirrorReferent =
        createServiceObject(json['mirrorReferent'], const ['InstanceRef'])
            as InstanceRef?;
    pattern = createServiceObject(json['pattern'], const ['InstanceRef'])
        as InstanceRef?;
    closureFunction =
        createServiceObject(json['closureFunction'], const ['FuncRef'])
            as FuncRef?;
    closureContext =
        createServiceObject(json['closureContext'], const ['ContextRef'])
            as ContextRef?;
    isCaseSensitive = json['isCaseSensitive'];
    isMultiLine = json['isMultiLine'];
    propertyKey =
        createServiceObject(json['propertyKey'], const ['InstanceRef'])
            as InstanceRef?;
    propertyValue =
        createServiceObject(json['propertyValue'], const ['InstanceRef'])
            as InstanceRef?;
    typeArguments =
        createServiceObject(json['typeArguments'], const ['TypeArgumentsRef'])
            as TypeArgumentsRef?;
    parameterIndex = json['parameterIndex'];
    targetType = createServiceObject(json['targetType'], const ['InstanceRef'])
        as InstanceRef?;
    bound = createServiceObject(json['bound'], const ['InstanceRef'])
        as InstanceRef?;
    portId = json['portId'];
    allocationLocation =
        createServiceObject(json['allocationLocation'], const ['InstanceRef'])
            as InstanceRef?;
    debugName = json['debugName'];
  }

  @override
  String get type => 'Instance';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['type'] = type;
    json.addAll({
      'kind': kind,
      'identityHashCode': identityHashCode,
      'class': classRef?.toJson(),
    });
    _setIfNotNull(json, 'valueAsString', valueAsString);
    _setIfNotNull(json, 'valueAsStringIsTruncated', valueAsStringIsTruncated);
    _setIfNotNull(json, 'length', length);
    _setIfNotNull(json, 'offset', offset);
    _setIfNotNull(json, 'count', count);
    _setIfNotNull(json, 'name', name);
    _setIfNotNull(json, 'typeClass', typeClass?.toJson());
    _setIfNotNull(json, 'parameterizedClass', parameterizedClass?.toJson());
    _setIfNotNull(json, 'returnType', returnType?.toJson());
    _setIfNotNull(
        json, 'parameters', parameters?.map((f) => f.toJson()).toList());
    _setIfNotNull(json, 'typeParameters',
        typeParameters?.map((f) => f.toJson()).toList());
    _setIfNotNull(json, 'fields', fields?.map((f) => f.toJson()).toList());
    _setIfNotNull(json, 'elements', elements?.map((f) => f.toJson()).toList());
    _setIfNotNull(
        json, 'associations', associations?.map((f) => f.toJson()).toList());
    _setIfNotNull(json, 'bytes', bytes);
    _setIfNotNull(json, 'mirrorReferent', mirrorReferent?.toJson());
    _setIfNotNull(json, 'pattern', pattern?.toJson());
    _setIfNotNull(json, 'closureFunction', closureFunction?.toJson());
    _setIfNotNull(json, 'closureContext', closureContext?.toJson());
    _setIfNotNull(json, 'isCaseSensitive', isCaseSensitive);
    _setIfNotNull(json, 'isMultiLine', isMultiLine);
    _setIfNotNull(json, 'propertyKey', propertyKey?.toJson());
    _setIfNotNull(json, 'propertyValue', propertyValue?.toJson());
    _setIfNotNull(json, 'typeArguments', typeArguments?.toJson());
    _setIfNotNull(json, 'parameterIndex', parameterIndex);
    _setIfNotNull(json, 'targetType', targetType?.toJson());
    _setIfNotNull(json, 'bound', bound?.toJson());
    _setIfNotNull(json, 'portId', portId);
    _setIfNotNull(json, 'allocationLocation', allocationLocation?.toJson());
    _setIfNotNull(json, 'debugName', debugName);
    return json;
  }

  int get hashCode => id.hashCode;

  bool operator ==(Object other) => other is Instance && id == other.id;

  String toString() => '[Instance ' //
      'id: ${id}, kind: ${kind}, identityHashCode: ${identityHashCode}, ' //
      'classRef: ${classRef}]';
}

/// `IsolateRef` is a reference to an `Isolate` object.
class IsolateRef extends Response {
  static IsolateRef? parse(Map<String, dynamic>? json) =>
      json == null ? null : IsolateRef._fromJson(json);

  /// The id which is passed to the getIsolate RPC to load this isolate.
  String? id;

  /// A numeric id for this isolate, represented as a string. Unique.
  String? number;

  /// A name identifying this isolate. Not guaranteed to be unique.
  String? name;

  /// Specifies whether the isolate was spawned by the VM or embedder for
  /// internal use. If `false`, this isolate is likely running user code.
  bool? isSystemIsolate;

  IsolateRef({
    required this.id,
    required this.number,
    required this.name,
    required this.isSystemIsolate,
  });

  IsolateRef._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    id = json['id'] ?? '';
    number = json['number'] ?? '';
    name = json['name'] ?? '';
    isSystemIsolate = json['isSystemIsolate'] ?? false;
  }

  @override
  String get type => '@Isolate';

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json['type'] = type;
    json.addAll({
      'id': id,
      'number': number,
      'name': name,
      'isSystemIsolate': isSystemIsolate,
    });
    return json;
  }

  int get hashCode => id.hashCode;

  bool operator ==(Object other) => other is IsolateRef && id == other.id;

  String toString() => '[IsolateRef ' //
      'id: ${id}, number: ${number}, name: ${name}, isSystemIsolate: ${isSystemIsolate}]';
}

/// An `Isolate` object provides information about one isolate in the VM.
class Isolate extends Response implements IsolateRef {
  static Isolate? parse(Map<String, dynamic>? json) =>
      json == null ? null : Isolate._fromJson(json);

  /// The id which is passed to the getIsolate RPC to reload this isolate.
  String? id;

  /// A numeric id for this isolate, represented as a string. Unique.
  String? number;

  /// A name identifying this isolate. Not guaranteed to be unique.
  String? name;

  /// Specifies whether the isolate was spawned by the VM or embedder for
  /// internal use. If `false`, this isolate is likely running user code.
  bool? isSystemIsolate;

  /// The list of isolate flags provided to this isolate. See Dart_IsolateFlags
  /// in dart_api.h for the list of accepted isolate flags.
  List<IsolateFlag>? isolateFlags;

  /// The time that the VM started in milliseconds since the epoch.
  ///
  /// Suitable to pass to DateTime.fromMillisecondsSinceEpoch.
  int? startTime;

  /// Is the isolate in a runnable state?
  bool? runnable;

  /// The number of live ports for this isolate.
  int? livePorts;

  /// Will this isolate pause when exiting?
  bool? pauseOnExit;

  /// The last pause event delivered to the isolate. If the isolate is running,
  /// this will be a resume event.
  Event? pauseEvent;

  /// The root library for this isolate.
  ///
  /// Guaranteed to be initialized when the IsolateRunnable event fires.
  @optional
  LibraryRef? rootLib;

  /// A list of all libraries for this isolate.
  ///
  /// Guaranteed to be initialized when the IsolateRunnable event fires.
  List<LibraryRef>? libraries;

  /// A list of all breakpoints for this isolate.
  List<Breakpoint>? breakpoints;

  /// The error that is causing this isolate to exit, if applicable.
  @optional
  Error? error;

  /// The current pause on exception mode for this isolate.
  /*ExceptionPauseMode*/ String? exceptionPauseMode;

  /// The list of service extension RPCs that are registered for this isolate,
  /// if any.
  @optional
  List<String>? extensionRPCs;

  Isolate({
    required this.id,
    required this.number,
    required this.name,
    required this.isSystemIsolate,
    required this.isolateFlags,
    required this.startTime,
    required this.runnable,
    required this.livePorts,
    required this.pauseOnExit,
    required this.pauseEvent,
    required this.libraries,
    required this.breakpoints,
    required this.exceptionPauseMode,
    this.rootLib,
    this.error,
    this.extensionRPCs,
  });

  Isolate._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    id = json['id'] ?? '';
    number = json['number'] ?? '';
    name = json['name'] ?? '';
    isSystemIsolate = json['isSystemIsolate'] ?? false;
    isolateFlags = List<IsolateFlag>.from(
        createServiceObject(json['isolateFlags'], const ['IsolateFlag'])
                as List? ??
            []);
    startTime = json['startTime'] ?? -1;
    runnable = json['runnable'] ?? false;
    livePorts = json['livePorts'] ?? -1;
    pauseOnExit = json['pauseOnExit'] ?? false;
    pauseEvent =
        createServiceObject(json['pauseEvent'], const ['Event']) as Event?;
    rootLib = createServiceObject(json['rootLib'], const ['LibraryRef'])
        as LibraryRef?;
    libraries = List<LibraryRef>.from(
        createServiceObject(json['libraries'], const ['LibraryRef']) as List? ??
            []);
    breakpoints = List<Breakpoint>.from(
        createServiceObject(json['breakpoints'], const ['Breakpoint'])
                as List? ??
            []);
    error = createServiceObject(json['error'], const ['Error']) as Error?;
    exceptionPauseMode = json['exceptionPauseMode'] ?? '';
    extensionRPCs = json['extensionRPCs'] == null
        ? null
        : List<String>.from(json['extensionRPCs']);
  }

  @override
  String get type => 'Isolate';

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json['type'] = type;
    json.addAll({
      'id': id,
      'number': number,
      'name': name,
      'isSystemIsolate': isSystemIsolate,
      'isolateFlags': isolateFlags?.map((f) => f.toJson()).toList(),
      'startTime': startTime,
      'runnable': runnable,
      'livePorts': livePorts,
      'pauseOnExit': pauseOnExit,
      'pauseEvent': pauseEvent?.toJson(),
      'libraries': libraries?.map((f) => f.toJson()).toList(),
      'breakpoints': breakpoints?.map((f) => f.toJson()).toList(),
      'exceptionPauseMode': exceptionPauseMode,
    });
    _setIfNotNull(json, 'rootLib', rootLib?.toJson());
    _setIfNotNull(json, 'error', error?.toJson());
    _setIfNotNull(json, 'extensionRPCs', extensionRPCs?.map((f) => f).toList());
    return json;
  }

  int get hashCode => id.hashCode;

  bool operator ==(Object other) => other is Isolate && id == other.id;

  String toString() => '[Isolate]';
}

/// Represents the value of a single isolate flag. See [Isolate].
class IsolateFlag {
  static IsolateFlag? parse(Map<String, dynamic>? json) =>
      json == null ? null : IsolateFlag._fromJson(json);

  /// The name of the flag.
  String? name;

  /// The value of this flag as a string.
  String? valueAsString;

  IsolateFlag({
    required this.name,
    required this.valueAsString,
  });

  IsolateFlag._fromJson(Map<String, dynamic> json) {
    name = json['name'] ?? '';
    valueAsString = json['valueAsString'] ?? '';
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json.addAll({
      'name': name,
      'valueAsString': valueAsString,
    });
    return json;
  }

  String toString() =>
      '[IsolateFlag name: ${name}, valueAsString: ${valueAsString}]';
}

/// `IsolateGroupRef` is a reference to an `IsolateGroup` object.
class IsolateGroupRef extends Response {
  static IsolateGroupRef? parse(Map<String, dynamic>? json) =>
      json == null ? null : IsolateGroupRef._fromJson(json);

  /// The id which is passed to the getIsolateGroup RPC to load this isolate
  /// group.
  String? id;

  /// A numeric id for this isolate group, represented as a string. Unique.
  String? number;

  /// A name identifying this isolate group. Not guaranteed to be unique.
  String? name;

  /// Specifies whether the isolate group was spawned by the VM or embedder for
  /// internal use. If `false`, this isolate group is likely running user code.
  bool? isSystemIsolateGroup;

  IsolateGroupRef({
    required this.id,
    required this.number,
    required this.name,
    required this.isSystemIsolateGroup,
  });

  IsolateGroupRef._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    id = json['id'] ?? '';
    number = json['number'] ?? '';
    name = json['name'] ?? '';
    isSystemIsolateGroup = json['isSystemIsolateGroup'] ?? false;
  }

  @override
  String get type => '@IsolateGroup';

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json['type'] = type;
    json.addAll({
      'id': id,
      'number': number,
      'name': name,
      'isSystemIsolateGroup': isSystemIsolateGroup,
    });
    return json;
  }

  int get hashCode => id.hashCode;

  bool operator ==(Object other) => other is IsolateGroupRef && id == other.id;

  String toString() => '[IsolateGroupRef ' //
      'id: ${id}, number: ${number}, name: ${name}, isSystemIsolateGroup: ${isSystemIsolateGroup}]';
}

/// An `IsolateGroup` object provides information about an isolate group in the
/// VM.
class IsolateGroup extends Response implements IsolateGroupRef {
  static IsolateGroup? parse(Map<String, dynamic>? json) =>
      json == null ? null : IsolateGroup._fromJson(json);

  /// The id which is passed to the getIsolateGroup RPC to reload this isolate.
  String? id;

  /// A numeric id for this isolate, represented as a string. Unique.
  String? number;

  /// A name identifying this isolate group. Not guaranteed to be unique.
  String? name;

  /// Specifies whether the isolate group was spawned by the VM or embedder for
  /// internal use. If `false`, this isolate group is likely running user code.
  bool? isSystemIsolateGroup;

  /// A list of all isolates in this isolate group.
  List<IsolateRef>? isolates;

  IsolateGroup({
    required this.id,
    required this.number,
    required this.name,
    required this.isSystemIsolateGroup,
    required this.isolates,
  });

  IsolateGroup._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    id = json['id'] ?? '';
    number = json['number'] ?? '';
    name = json['name'] ?? '';
    isSystemIsolateGroup = json['isSystemIsolateGroup'] ?? false;
    isolates = List<IsolateRef>.from(
        createServiceObject(json['isolates'], const ['IsolateRef']) as List? ??
            []);
  }

  @override
  String get type => 'IsolateGroup';

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json['type'] = type;
    json.addAll({
      'id': id,
      'number': number,
      'name': name,
      'isSystemIsolateGroup': isSystemIsolateGroup,
      'isolates': isolates?.map((f) => f.toJson()).toList(),
    });
    return json;
  }

  int get hashCode => id.hashCode;

  bool operator ==(Object other) => other is IsolateGroup && id == other.id;

  String toString() => '[IsolateGroup ' //
      'id: ${id}, number: ${number}, name: ${name}, isSystemIsolateGroup: ${isSystemIsolateGroup}, ' //
      'isolates: ${isolates}]';
}

/// See [getInboundReferences].
class InboundReferences extends Response {
  static InboundReferences? parse(Map<String, dynamic>? json) =>
      json == null ? null : InboundReferences._fromJson(json);

  /// An array of inbound references to an object.
  List<InboundReference>? references;

  InboundReferences({
    required this.references,
  });

  InboundReferences._fromJson(Map<String, dynamic> json)
      : super._fromJson(json) {
    references = List<InboundReference>.from(
        createServiceObject(json['references'], const ['InboundReference'])
                as List? ??
            []);
  }

  @override
  String get type => 'InboundReferences';

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json['type'] = type;
    json.addAll({
      'references': references?.map((f) => f.toJson()).toList(),
    });
    return json;
  }

  String toString() => '[InboundReferences references: ${references}]';
}

/// See [getInboundReferences].
class InboundReference {
  static InboundReference? parse(Map<String, dynamic>? json) =>
      json == null ? null : InboundReference._fromJson(json);

  /// The object holding the inbound reference.
  ObjRef? source;

  /// If source is a List, parentListIndex is the index of the inbound
  /// reference.
  @optional
  int? parentListIndex;

  /// If source is a field of an object, parentField is the field containing the
  /// inbound reference.
  @optional
  FieldRef? parentField;

  InboundReference({
    required this.source,
    this.parentListIndex,
    this.parentField,
  });

  InboundReference._fromJson(Map<String, dynamic> json) {
    source = createServiceObject(json['source'], const ['ObjRef']) as ObjRef?;
    parentListIndex = json['parentListIndex'];
    parentField = createServiceObject(json['parentField'], const ['FieldRef'])
        as FieldRef?;
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json.addAll({
      'source': source?.toJson(),
    });
    _setIfNotNull(json, 'parentListIndex', parentListIndex);
    _setIfNotNull(json, 'parentField', parentField?.toJson());
    return json;
  }

  String toString() => '[InboundReference source: ${source}]';
}

/// See [getInstances].
class InstanceSet extends Response {
  static InstanceSet? parse(Map<String, dynamic>? json) =>
      json == null ? null : InstanceSet._fromJson(json);

  /// The number of instances of the requested type currently allocated.
  int? totalCount;

  /// An array of instances of the requested type.
  List<ObjRef>? instances;

  InstanceSet({
    required this.totalCount,
    required this.instances,
  });

  InstanceSet._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    totalCount = json['totalCount'] ?? -1;
    instances = List<ObjRef>.from(createServiceObject(
            (json['instances'] ?? json['samples']!) as List, const ['ObjRef'])!
        as List);
  }

  @override
  String get type => 'InstanceSet';

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json['type'] = type;
    json.addAll({
      'totalCount': totalCount,
      'instances': instances?.map((f) => f.toJson()).toList(),
    });
    return json;
  }

  String toString() =>
      '[InstanceSet totalCount: ${totalCount}, instances: ${instances}]';
}

/// `LibraryRef` is a reference to a `Library`.
class LibraryRef extends ObjRef {
  static LibraryRef? parse(Map<String, dynamic>? json) =>
      json == null ? null : LibraryRef._fromJson(json);

  /// The name of this library.
  String? name;

  /// The uri of this library.
  String? uri;

  LibraryRef({
    required this.name,
    required this.uri,
    required String id,
  }) : super(
          id: id,
        );

  LibraryRef._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    name = json['name'] ?? '';
    uri = json['uri'] ?? '';
  }

  @override
  String get type => '@Library';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['type'] = type;
    json.addAll({
      'name': name,
      'uri': uri,
    });
    return json;
  }

  int get hashCode => id.hashCode;

  bool operator ==(Object other) => other is LibraryRef && id == other.id;

  String toString() => '[LibraryRef id: ${id}, name: ${name}, uri: ${uri}]';
}

/// A `Library` provides information about a Dart language library.
///
/// See [setLibraryDebuggable].
class Library extends Obj implements LibraryRef {
  static Library? parse(Map<String, dynamic>? json) =>
      json == null ? null : Library._fromJson(json);

  /// The name of this library.
  String? name;

  /// The uri of this library.
  String? uri;

  /// Is this library debuggable? Default true.
  bool? debuggable;

  /// A list of the imports for this library.
  List<LibraryDependency>? dependencies;

  /// A list of the scripts which constitute this library.
  List<ScriptRef>? scripts;

  /// A list of the top-level variables in this library.
  List<FieldRef>? variables;

  /// A list of the top-level functions in this library.
  List<FuncRef>? functions;

  /// A list of all classes in this library.
  List<ClassRef>? classes;

  Library({
    required this.name,
    required this.uri,
    required this.debuggable,
    required this.dependencies,
    required this.scripts,
    required this.variables,
    required this.functions,
    required this.classes,
    required String id,
  }) : super(
          id: id,
        );

  Library._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    name = json['name'] ?? '';
    uri = json['uri'] ?? '';
    debuggable = json['debuggable'] ?? false;
    dependencies = List<LibraryDependency>.from(
        _createSpecificObject(json['dependencies']!, LibraryDependency.parse));
    scripts = List<ScriptRef>.from(
        createServiceObject(json['scripts'], const ['ScriptRef']) as List? ??
            []);
    variables = List<FieldRef>.from(
        createServiceObject(json['variables'], const ['FieldRef']) as List? ??
            []);
    functions = List<FuncRef>.from(
        createServiceObject(json['functions'], const ['FuncRef']) as List? ??
            []);
    classes = List<ClassRef>.from(
        createServiceObject(json['classes'], const ['ClassRef']) as List? ??
            []);
  }

  @override
  String get type => 'Library';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['type'] = type;
    json.addAll({
      'name': name,
      'uri': uri,
      'debuggable': debuggable,
      'dependencies': dependencies?.map((f) => f.toJson()).toList(),
      'scripts': scripts?.map((f) => f.toJson()).toList(),
      'variables': variables?.map((f) => f.toJson()).toList(),
      'functions': functions?.map((f) => f.toJson()).toList(),
      'classes': classes?.map((f) => f.toJson()).toList(),
    });
    return json;
  }

  int get hashCode => id.hashCode;

  bool operator ==(Object other) => other is Library && id == other.id;

  String toString() => '[Library]';
}

/// A `LibraryDependency` provides information about an import or export.
class LibraryDependency {
  static LibraryDependency? parse(Map<String, dynamic>? json) =>
      json == null ? null : LibraryDependency._fromJson(json);

  /// Is this dependency an import (rather than an export)?
  bool? isImport;

  /// Is this dependency deferred?
  bool? isDeferred;

  /// The prefix of an 'as' import, or null.
  String? prefix;

  /// The library being imported or exported.
  LibraryRef? target;

  /// The list of symbols made visible from this dependency.
  @optional
  List<String>? shows;

  /// The list of symbols hidden from this dependency.
  @optional
  List<String>? hides;

  LibraryDependency({
    required this.isImport,
    required this.isDeferred,
    required this.prefix,
    required this.target,
    this.shows,
    this.hides,
  });

  LibraryDependency._fromJson(Map<String, dynamic> json) {
    isImport = json['isImport'] ?? false;
    isDeferred = json['isDeferred'] ?? false;
    prefix = json['prefix'] ?? '';
    target = createServiceObject(json['target'], const ['LibraryRef'])
        as LibraryRef?;
    shows = json['shows'] == null ? null : List<String>.from(json['shows']);
    hides = json['hides'] == null ? null : List<String>.from(json['hides']);
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json.addAll({
      'isImport': isImport,
      'isDeferred': isDeferred,
      'prefix': prefix,
      'target': target?.toJson(),
    });
    _setIfNotNull(json, 'shows', shows?.map((f) => f).toList());
    _setIfNotNull(json, 'hides', hides?.map((f) => f).toList());
    return json;
  }

  String toString() => '[LibraryDependency ' //
      'isImport: ${isImport}, isDeferred: ${isDeferred}, prefix: ${prefix}, ' //
      'target: ${target}]';
}

class LogRecord extends Response {
  static LogRecord? parse(Map<String, dynamic>? json) =>
      json == null ? null : LogRecord._fromJson(json);

  /// The log message.
  InstanceRef? message;

  /// The timestamp.
  int? time;

  /// The severity level (a value between 0 and 2000).
  ///
  /// See the package:logging `Level` class for an overview of the possible
  /// values.
  int? level;

  /// A monotonically increasing sequence number.
  int? sequenceNumber;

  /// The name of the source of the log message.
  InstanceRef? loggerName;

  /// The zone where the log was emitted.
  InstanceRef? zone;

  /// An error object associated with this log event.
  InstanceRef? error;

  /// A stack trace associated with this log event.
  InstanceRef? stackTrace;

  LogRecord({
    required this.message,
    required this.time,
    required this.level,
    required this.sequenceNumber,
    required this.loggerName,
    required this.zone,
    required this.error,
    required this.stackTrace,
  });

  LogRecord._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    message = createServiceObject(json['message'], const ['InstanceRef'])
        as InstanceRef?;
    time = json['time'] ?? -1;
    level = json['level'] ?? -1;
    sequenceNumber = json['sequenceNumber'] ?? -1;
    loggerName = createServiceObject(json['loggerName'], const ['InstanceRef'])
        as InstanceRef?;
    zone = createServiceObject(json['zone'], const ['InstanceRef'])
        as InstanceRef?;
    error = createServiceObject(json['error'], const ['InstanceRef'])
        as InstanceRef?;
    stackTrace = createServiceObject(json['stackTrace'], const ['InstanceRef'])
        as InstanceRef?;
  }

  @override
  String get type => 'LogRecord';

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json['type'] = type;
    json.addAll({
      'message': message?.toJson(),
      'time': time,
      'level': level,
      'sequenceNumber': sequenceNumber,
      'loggerName': loggerName?.toJson(),
      'zone': zone?.toJson(),
      'error': error?.toJson(),
      'stackTrace': stackTrace?.toJson(),
    });
    return json;
  }

  String toString() => '[LogRecord]';
}

class MapAssociation {
  static MapAssociation? parse(Map<String, dynamic>? json) =>
      json == null ? null : MapAssociation._fromJson(json);

  /// [key] can be one of [InstanceRef] or [Sentinel].
  dynamic key;

  /// [value] can be one of [InstanceRef] or [Sentinel].
  dynamic value;

  MapAssociation({
    required this.key,
    required this.value,
  });

  MapAssociation._fromJson(Map<String, dynamic> json) {
    key = createServiceObject(json['key'], const ['InstanceRef', 'Sentinel'])
        as dynamic;
    value =
        createServiceObject(json['value'], const ['InstanceRef', 'Sentinel'])
            as dynamic;
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json.addAll({
      'key': key?.toJson(),
      'value': value?.toJson(),
    });
    return json;
  }

  String toString() => '[MapAssociation key: ${key}, value: ${value}]';
}

/// A `MemoryUsage` object provides heap usage information for a specific
/// isolate at a given point in time.
class MemoryUsage extends Response {
  static MemoryUsage? parse(Map<String, dynamic>? json) =>
      json == null ? null : MemoryUsage._fromJson(json);

  /// The amount of non-Dart memory that is retained by Dart objects. For
  /// example, memory associated with Dart objects through APIs such as
  /// Dart_NewFinalizableHandle, Dart_NewWeakPersistentHandle and
  /// Dart_NewExternalTypedData.  This usage is only as accurate as the values
  /// supplied to these APIs from the VM embedder. This external memory applies
  /// GC pressure, but is separate from heapUsage and heapCapacity.
  int? externalUsage;

  /// The total capacity of the heap in bytes. This is the amount of memory used
  /// by the Dart heap from the perspective of the operating system.
  int? heapCapacity;

  /// The current heap memory usage in bytes. Heap usage is always less than or
  /// equal to the heap capacity.
  int? heapUsage;

  MemoryUsage({
    required this.externalUsage,
    required this.heapCapacity,
    required this.heapUsage,
  });

  MemoryUsage._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    externalUsage = json['externalUsage'] ?? -1;
    heapCapacity = json['heapCapacity'] ?? -1;
    heapUsage = json['heapUsage'] ?? -1;
  }

  @override
  String get type => 'MemoryUsage';

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json['type'] = type;
    json.addAll({
      'externalUsage': externalUsage,
      'heapCapacity': heapCapacity,
      'heapUsage': heapUsage,
    });
    return json;
  }

  String toString() => '[MemoryUsage ' //
      'externalUsage: ${externalUsage}, heapCapacity: ${heapCapacity}, ' //
      'heapUsage: ${heapUsage}]';
}

/// A `Message` provides information about a pending isolate message and the
/// function that will be invoked to handle it.
class Message extends Response {
  static Message? parse(Map<String, dynamic>? json) =>
      json == null ? null : Message._fromJson(json);

  /// The index in the isolate's message queue. The 0th message being the next
  /// message to be processed.
  int? index;

  /// An advisory name describing this message.
  String? name;

  /// An instance id for the decoded message. This id can be passed to other
  /// RPCs, for example, getObject or evaluate.
  String? messageObjectId;

  /// The size (bytes) of the encoded message.
  int? size;

  /// A reference to the function that will be invoked to handle this message.
  @optional
  FuncRef? handler;

  /// The source location of handler.
  @optional
  SourceLocation? location;

  Message({
    required this.index,
    required this.name,
    required this.messageObjectId,
    required this.size,
    this.handler,
    this.location,
  });

  Message._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    index = json['index'] ?? -1;
    name = json['name'] ?? '';
    messageObjectId = json['messageObjectId'] ?? '';
    size = json['size'] ?? -1;
    handler =
        createServiceObject(json['handler'], const ['FuncRef']) as FuncRef?;
    location = createServiceObject(json['location'], const ['SourceLocation'])
        as SourceLocation?;
  }

  @override
  String get type => 'Message';

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json['type'] = type;
    json.addAll({
      'index': index,
      'name': name,
      'messageObjectId': messageObjectId,
      'size': size,
    });
    _setIfNotNull(json, 'handler', handler?.toJson());
    _setIfNotNull(json, 'location', location?.toJson());
    return json;
  }

  String toString() => '[Message ' //
      'index: ${index}, name: ${name}, messageObjectId: ${messageObjectId}, ' //
      'size: ${size}]';
}

/// A `NativeFunction` object is used to represent native functions in profiler
/// samples. See [CpuSamples];
class NativeFunction {
  static NativeFunction? parse(Map<String, dynamic>? json) =>
      json == null ? null : NativeFunction._fromJson(json);

  /// The name of the native function this object represents.
  String? name;

  NativeFunction({
    required this.name,
  });

  NativeFunction._fromJson(Map<String, dynamic> json) {
    name = json['name'] ?? '';
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json.addAll({
      'name': name,
    });
    return json;
  }

  String toString() => '[NativeFunction name: ${name}]';
}

/// `NullValRef` is a reference to an a `NullVal`.
class NullValRef extends InstanceRef {
  static NullValRef? parse(Map<String, dynamic>? json) =>
      json == null ? null : NullValRef._fromJson(json);

  /// Always 'null'.
  @override
  String? valueAsString;

  NullValRef({
    required this.valueAsString,
  }) : super(
          id: 'instance/null',
          identityHashCode: 0,
          kind: InstanceKind.kNull,
          classRef: ClassRef(
            id: 'class/null',
            library: LibraryRef(
              id: '',
              name: 'dart:core',
              uri: 'dart:core',
            ),
            name: 'Null',
          ),
        );

  NullValRef._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    valueAsString = json['valueAsString'] ?? '';
  }

  @override
  String get type => '@Null';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['type'] = type;
    json.addAll({
      'valueAsString': valueAsString,
    });
    return json;
  }

  int get hashCode => id.hashCode;

  bool operator ==(Object other) => other is NullValRef && id == other.id;

  String toString() => '[NullValRef ' //
      'id: ${id}, kind: ${kind}, identityHashCode: ${identityHashCode}, ' //
      'classRef: ${classRef}, valueAsString: ${valueAsString}]';
}

/// A `NullVal` object represents the Dart language value null.
class NullVal extends Instance implements NullValRef {
  static NullVal? parse(Map<String, dynamic>? json) =>
      json == null ? null : NullVal._fromJson(json);

  /// Always 'null'.
  @override
  String? valueAsString;

  NullVal({
    required this.valueAsString,
  }) : super(
          id: 'instance/null',
          identityHashCode: 0,
          kind: InstanceKind.kNull,
          classRef: ClassRef(
            id: 'class/null',
            library: LibraryRef(
              id: '',
              name: 'dart:core',
              uri: 'dart:core',
            ),
            name: 'Null',
          ),
        );

  NullVal._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    valueAsString = json['valueAsString'] ?? '';
  }

  @override
  String get type => 'Null';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['type'] = type;
    json.addAll({
      'valueAsString': valueAsString,
    });
    return json;
  }

  int get hashCode => id.hashCode;

  bool operator ==(Object other) => other is NullVal && id == other.id;

  String toString() => '[NullVal ' //
      'id: ${id}, kind: ${kind}, identityHashCode: ${identityHashCode}, ' //
      'classRef: ${classRef}, valueAsString: ${valueAsString}]';
}

/// `ObjRef` is a reference to a `Obj`.
class ObjRef extends Response {
  static ObjRef? parse(Map<String, dynamic>? json) =>
      json == null ? null : ObjRef._fromJson(json);

  /// A unique identifier for an Object. Passed to the getObject RPC to load
  /// this Object.
  String? id;

  /// Provided and set to true if the id of an Object is fixed. If true, the id
  /// of an Object is guaranteed not to change or expire. The object may,
  /// however, still be _Collected_.
  @optional
  bool? fixedId;

  ObjRef({
    required this.id,
    this.fixedId,
  });

  ObjRef._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    id = json['id'] ?? '';
    fixedId = json['fixedId'];
  }

  @override
  String get type => '@Object';

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json['type'] = type;
    json.addAll({
      'id': id,
    });
    _setIfNotNull(json, 'fixedId', fixedId);
    return json;
  }

  int get hashCode => id.hashCode;

  bool operator ==(Object other) => other is ObjRef && id == other.id;

  String toString() => '[ObjRef id: ${id}]';
}

/// An `Obj` is a persistent object that is owned by some isolate.
class Obj extends Response implements ObjRef {
  static Obj? parse(Map<String, dynamic>? json) =>
      json == null ? null : Obj._fromJson(json);

  /// A unique identifier for an Object. Passed to the getObject RPC to reload
  /// this Object.
  ///
  /// Some objects may get a new id when they are reloaded.
  String? id;

  /// Provided and set to true if the id of an Object is fixed. If true, the id
  /// of an Object is guaranteed not to change or expire. The object may,
  /// however, still be _Collected_.
  @optional
  bool? fixedId;

  /// If an object is allocated in the Dart heap, it will have a corresponding
  /// class object.
  ///
  /// The class of a non-instance is not a Dart class, but is instead an
  /// internal vm object.
  ///
  /// Moving an Object into or out of the heap is considered a backwards
  /// compatible change for types other than Instance.
  @optional
  ClassRef? classRef;

  /// The size of this object in the heap.
  ///
  /// If an object is not heap-allocated, then this field is omitted.
  ///
  /// Note that the size can be zero for some objects. In the current VM
  /// implementation, this occurs for small integers, which are stored entirely
  /// within their object pointers.
  @optional
  int? size;

  Obj({
    required this.id,
    this.fixedId,
    this.classRef,
    this.size,
  });

  Obj._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    id = json['id'] ?? '';
    fixedId = json['fixedId'];
    classRef =
        createServiceObject(json['class'], const ['ClassRef']) as ClassRef?;
    size = json['size'];
  }

  @override
  String get type => 'Object';

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json['type'] = type;
    json.addAll({
      'id': id,
    });
    _setIfNotNull(json, 'fixedId', fixedId);
    _setIfNotNull(json, 'class', classRef?.toJson());
    _setIfNotNull(json, 'size', size);
    return json;
  }

  int get hashCode => id.hashCode;

  bool operator ==(Object other) => other is Obj && id == other.id;

  String toString() => '[Obj id: ${id}]';
}

/// A `Parameter` is a representation of a function parameter.
///
/// See [Instance].
class Parameter {
  static Parameter? parse(Map<String, dynamic>? json) =>
      json == null ? null : Parameter._fromJson(json);

  /// The type of the parameter.
  InstanceRef? parameterType;

  /// Represents whether or not this parameter is fixed or optional.
  bool? fixed;

  /// The name of a named optional parameter.
  @optional
  String? name;

  /// Whether or not this named optional parameter is marked as required.
  @optional
  bool? required;

  Parameter({
    required this.parameterType,
    required this.fixed,
    this.name,
    this.required,
  });

  Parameter._fromJson(Map<String, dynamic> json) {
    parameterType =
        createServiceObject(json['parameterType'], const ['InstanceRef'])
            as InstanceRef?;
    fixed = json['fixed'] ?? false;
    name = json['name'];
    required = json['required'];
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json.addAll({
      'parameterType': parameterType?.toJson(),
      'fixed': fixed,
    });
    _setIfNotNull(json, 'name', name);
    _setIfNotNull(json, 'required', required);
    return json;
  }

  String toString() =>
      '[Parameter parameterType: ${parameterType}, fixed: ${fixed}]';
}

/// A `PortList` contains a list of ports associated with some isolate.
///
/// See [getPort].
class PortList extends Response {
  static PortList? parse(Map<String, dynamic>? json) =>
      json == null ? null : PortList._fromJson(json);

  List<InstanceRef>? ports;

  PortList({
    required this.ports,
  });

  PortList._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    ports = List<InstanceRef>.from(
        createServiceObject(json['ports'], const ['InstanceRef']) as List? ??
            []);
  }

  @override
  String get type => 'PortList';

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json['type'] = type;
    json.addAll({
      'ports': ports?.map((f) => f.toJson()).toList(),
    });
    return json;
  }

  String toString() => '[PortList ports: ${ports}]';
}

/// A `ProfileFunction` contains profiling information about a Dart or native
/// function.
///
/// See [CpuSamples].
class ProfileFunction {
  static ProfileFunction? parse(Map<String, dynamic>? json) =>
      json == null ? null : ProfileFunction._fromJson(json);

  /// The kind of function this object represents.
  String? kind;

  /// The number of times function appeared on the stack during sampling events.
  int? inclusiveTicks;

  /// The number of times function appeared on the top of the stack during
  /// sampling events.
  int? exclusiveTicks;

  /// The resolved URL for the script containing function.
  String? resolvedUrl;

  /// The function captured during profiling.
  dynamic function;

  ProfileFunction({
    required this.kind,
    required this.inclusiveTicks,
    required this.exclusiveTicks,
    required this.resolvedUrl,
    required this.function,
  });

  ProfileFunction._fromJson(Map<String, dynamic> json) {
    kind = json['kind'] ?? '';
    inclusiveTicks = json['inclusiveTicks'] ?? -1;
    exclusiveTicks = json['exclusiveTicks'] ?? -1;
    resolvedUrl = json['resolvedUrl'] ?? '';
    function =
        createServiceObject(json['function'], const ['dynamic']) as dynamic;
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json.addAll({
      'kind': kind,
      'inclusiveTicks': inclusiveTicks,
      'exclusiveTicks': exclusiveTicks,
      'resolvedUrl': resolvedUrl,
      'function': function?.toJson(),
    });
    return json;
  }

  String toString() => '[ProfileFunction ' //
      'kind: ${kind}, inclusiveTicks: ${inclusiveTicks}, exclusiveTicks: ${exclusiveTicks}, ' //
      'resolvedUrl: ${resolvedUrl}, function: ${function}]';
}

/// A `ProtocolList` contains a list of all protocols supported by the service
/// instance.
///
/// See [Protocol] and [getSupportedProtocols].
class ProtocolList extends Response {
  static ProtocolList? parse(Map<String, dynamic>? json) =>
      json == null ? null : ProtocolList._fromJson(json);

  /// A list of supported protocols provided by this service.
  List<Protocol>? protocols;

  ProtocolList({
    required this.protocols,
  });

  ProtocolList._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    protocols = List<Protocol>.from(
        createServiceObject(json['protocols'], const ['Protocol']) as List? ??
            []);
  }

  @override
  String get type => 'ProtocolList';

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json['type'] = type;
    json.addAll({
      'protocols': protocols?.map((f) => f.toJson()).toList(),
    });
    return json;
  }

  String toString() => '[ProtocolList protocols: ${protocols}]';
}

/// See [getSupportedProtocols].
class Protocol {
  static Protocol? parse(Map<String, dynamic>? json) =>
      json == null ? null : Protocol._fromJson(json);

  /// The name of the supported protocol.
  String? protocolName;

  /// The major revision of the protocol.
  int? major;

  /// The minor revision of the protocol.
  int? minor;

  Protocol({
    required this.protocolName,
    required this.major,
    required this.minor,
  });

  Protocol._fromJson(Map<String, dynamic> json) {
    protocolName = json['protocolName'] ?? '';
    major = json['major'] ?? -1;
    minor = json['minor'] ?? -1;
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json.addAll({
      'protocolName': protocolName,
      'major': major,
      'minor': minor,
    });
    return json;
  }

  String toString() => '[Protocol ' //
      'protocolName: ${protocolName}, major: ${major}, minor: ${minor}]';
}

/// Set [getProcessMemoryUsage].
class ProcessMemoryUsage extends Response {
  static ProcessMemoryUsage? parse(Map<String, dynamic>? json) =>
      json == null ? null : ProcessMemoryUsage._fromJson(json);

  ProcessMemoryItem? root;

  ProcessMemoryUsage({
    required this.root,
  });

  ProcessMemoryUsage._fromJson(Map<String, dynamic> json)
      : super._fromJson(json) {
    root = createServiceObject(json['root'], const ['ProcessMemoryItem'])
        as ProcessMemoryItem?;
  }

  @override
  String get type => 'ProcessMemoryUsage';

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json['type'] = type;
    json.addAll({
      'root': root?.toJson(),
    });
    return json;
  }

  String toString() => '[ProcessMemoryUsage root: ${root}]';
}

class ProcessMemoryItem {
  static ProcessMemoryItem? parse(Map<String, dynamic>? json) =>
      json == null ? null : ProcessMemoryItem._fromJson(json);

  /// A short name for this bucket of memory.
  String? name;

  /// A longer description for this item.
  String? description;

  /// The amount of memory in bytes. This is a retained size, not a shallow
  /// size. That is, it includes the size of children.
  int? size;

  /// Subdivisons of this bucket of memory.
  List<ProcessMemoryItem>? children;

  ProcessMemoryItem({
    required this.name,
    required this.description,
    required this.size,
    required this.children,
  });

  ProcessMemoryItem._fromJson(Map<String, dynamic> json) {
    name = json['name'] ?? '';
    description = json['description'] ?? '';
    size = json['size'] ?? -1;
    children = List<ProcessMemoryItem>.from(
        createServiceObject(json['children'], const ['ProcessMemoryItem'])
                as List? ??
            []);
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json.addAll({
      'name': name,
      'description': description,
      'size': size,
      'children': children?.map((f) => f.toJson()).toList(),
    });
    return json;
  }

  String toString() => '[ProcessMemoryItem ' //
      'name: ${name}, description: ${description}, size: ${size}, ' //
      'children: ${children}]';
}

class ReloadReport extends Response {
  static ReloadReport? parse(Map<String, dynamic>? json) =>
      json == null ? null : ReloadReport._fromJson(json);

  /// Did the reload succeed or fail?
  bool? success;

  ReloadReport({
    required this.success,
  });

  ReloadReport._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    success = json['success'] ?? false;
  }

  @override
  String get type => 'ReloadReport';

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json['type'] = type;
    json.addAll({
      'success': success,
    });
    return json;
  }

  String toString() => '[ReloadReport success: ${success}]';
}

/// See [RetainingPath].
class RetainingObject {
  static RetainingObject? parse(Map<String, dynamic>? json) =>
      json == null ? null : RetainingObject._fromJson(json);

  /// An object that is part of a retaining path.
  ObjRef? value;

  /// The offset of the retaining object in a containing list.
  @optional
  int? parentListIndex;

  /// The key mapping to the retaining object in a containing map.
  @optional
  ObjRef? parentMapKey;

  /// The name of the field containing the retaining object within an object.
  @optional
  String? parentField;

  RetainingObject({
    required this.value,
    this.parentListIndex,
    this.parentMapKey,
    this.parentField,
  });

  RetainingObject._fromJson(Map<String, dynamic> json) {
    value = createServiceObject(json['value'], const ['ObjRef']) as ObjRef?;
    parentListIndex = json['parentListIndex'];
    parentMapKey =
        createServiceObject(json['parentMapKey'], const ['ObjRef']) as ObjRef?;
    parentField = json['parentField'];
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json.addAll({
      'value': value?.toJson(),
    });
    _setIfNotNull(json, 'parentListIndex', parentListIndex);
    _setIfNotNull(json, 'parentMapKey', parentMapKey?.toJson());
    _setIfNotNull(json, 'parentField', parentField);
    return json;
  }

  String toString() => '[RetainingObject value: ${value}]';
}

/// See [getRetainingPath].
class RetainingPath extends Response {
  static RetainingPath? parse(Map<String, dynamic>? json) =>
      json == null ? null : RetainingPath._fromJson(json);

  /// The length of the retaining path.
  int? length;

  /// The type of GC root which is holding a reference to the specified object.
  /// Possible values include:  * class table  * local handle  * persistent
  /// handle  * stack  * user global  * weak persistent handle  * unknown
  String? gcRootType;

  /// The chain of objects which make up the retaining path.
  List<RetainingObject>? elements;

  RetainingPath({
    required this.length,
    required this.gcRootType,
    required this.elements,
  });

  RetainingPath._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    length = json['length'] ?? -1;
    gcRootType = json['gcRootType'] ?? '';
    elements = List<RetainingObject>.from(
        createServiceObject(json['elements'], const ['RetainingObject'])
                as List? ??
            []);
  }

  @override
  String get type => 'RetainingPath';

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json['type'] = type;
    json.addAll({
      'length': length,
      'gcRootType': gcRootType,
      'elements': elements?.map((f) => f.toJson()).toList(),
    });
    return json;
  }

  String toString() => '[RetainingPath ' //
      'length: ${length}, gcRootType: ${gcRootType}, elements: ${elements}]';
}

/// Every non-error response returned by the Service Protocol extends
/// `Response`. By using the `type` property, the client can determine which
/// [type] of response has been provided.
class Response {
  static Response? parse(Map<String, dynamic>? json) =>
      json == null ? null : Response._fromJson(json);

  Map<String, dynamic>? json;

  Response();

  Response._fromJson(this.json);

  String get type => 'Response';

  Map<String, dynamic> toJson() {
    final localJson = json;
    final result = localJson == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.of(localJson);
    result['type'] = type;
    return result;
  }

  String toString() => '[Response]';
}

/// A `Sentinel` is used to indicate that the normal response is not available.
///
/// We use a `Sentinel` instead of an [error] for these cases because they do
/// not represent a problematic condition. They are normal.
class Sentinel extends Response {
  static Sentinel? parse(Map<String, dynamic>? json) =>
      json == null ? null : Sentinel._fromJson(json);

  /// What kind of sentinel is this?
  /*SentinelKind*/ String? kind;

  /// A reasonable string representation of this sentinel.
  String? valueAsString;

  Sentinel({
    required this.kind,
    required this.valueAsString,
  });

  Sentinel._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    kind = json['kind'] ?? '';
    valueAsString = json['valueAsString'] ?? '';
  }

  @override
  String get type => 'Sentinel';

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json['type'] = type;
    json.addAll({
      'kind': kind,
      'valueAsString': valueAsString,
    });
    return json;
  }

  String toString() =>
      '[Sentinel kind: ${kind}, valueAsString: ${valueAsString}]';
}

/// `ScriptRef` is a reference to a `Script`.
class ScriptRef extends ObjRef {
  static ScriptRef? parse(Map<String, dynamic>? json) =>
      json == null ? null : ScriptRef._fromJson(json);

  /// The uri from which this script was loaded.
  String? uri;

  ScriptRef({
    required this.uri,
    required String id,
  }) : super(
          id: id,
        );

  ScriptRef._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    uri = json['uri'] ?? '';
  }

  @override
  String get type => '@Script';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['type'] = type;
    json.addAll({
      'uri': uri,
    });
    return json;
  }

  int get hashCode => id.hashCode;

  bool operator ==(Object other) => other is ScriptRef && id == other.id;

  String toString() => '[ScriptRef id: ${id}, uri: ${uri}]';
}

/// A `Script` provides information about a Dart language script.
///
/// The `tokenPosTable` is an array of int arrays. Each subarray consists of a
/// line number followed by `(tokenPos, columnNumber)` pairs:
///
/// ```
/// [lineNumber, (tokenPos, columnNumber)*]
/// ```
///
/// The `tokenPos` is an arbitrary integer value that is used to represent a
/// location in the source code. A `tokenPos` value is not meaningful in itself
/// and code should not rely on the exact values returned.
///
/// For example, a `tokenPosTable` with the value...
///
/// ```
/// [[1, 100, 5, 101, 8],[2, 102, 7]]
/// ```
///
/// ...encodes the mapping:
///
/// tokenPos | line | column
/// -------- | ---- | ------
/// 100 | 1 | 5
/// 101 | 1 | 8
/// 102 | 2 | 7
class Script extends Obj implements ScriptRef {
  static Script? parse(Map<String, dynamic>? json) =>
      json == null ? null : Script._fromJson(json);

  final _tokenToLine = <int, int>{};
  final _tokenToColumn = <int, int>{};

  /// The uri from which this script was loaded.
  String? uri;

  /// The library which owns this script.
  LibraryRef? library;

  @optional
  int? lineOffset;

  @optional
  int? columnOffset;

  /// The source code for this script. This can be null for certain built-in
  /// scripts.
  @optional
  String? source;

  /// A table encoding a mapping from token position to line and column. This
  /// field is null if sources aren't available.
  @optional
  List<List<int>>? tokenPosTable;

  Script({
    required this.uri,
    required this.library,
    required String id,
    this.lineOffset,
    this.columnOffset,
    this.source,
    this.tokenPosTable,
  }) : super(
          id: id,
        );

  Script._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    uri = json['uri'] ?? '';
    library = createServiceObject(json['library'], const ['LibraryRef'])
        as LibraryRef?;
    lineOffset = json['lineOffset'];
    columnOffset = json['columnOffset'];
    source = json['source'];
    tokenPosTable = json['tokenPosTable'] == null
        ? null
        : List<List<int>>.from(
            json['tokenPosTable']!.map((dynamic list) => List<int>.from(list)));
    _parseTokenPosTable();
  }

  /// This function maps a token position to a line number.
  /// The VM considers the first line to be line 1.
  int? getLineNumberFromTokenPos(int tokenPos) => _tokenToLine[tokenPos];

  /// This function maps a token position to a column number.
  /// The VM considers the first column to be column 1.
  int? getColumnNumberFromTokenPos(int tokenPos) => _tokenToColumn[tokenPos];

  void _parseTokenPosTable() {
    final tokenPositionTable = tokenPosTable;
    if (tokenPositionTable == null) {
      return;
    }
    final lineSet = <int>{};
    for (List line in tokenPositionTable) {
      // Each entry begins with a line number...
      int lineNumber = line[0];
      lineSet.add(lineNumber);
      for (var pos = 1; pos < line.length; pos += 2) {
        // ...and is followed by (token offset, col number) pairs.
        final int tokenOffset = line[pos];
        final int colNumber = line[pos + 1];
        _tokenToLine[tokenOffset] = lineNumber;
        _tokenToColumn[tokenOffset] = colNumber;
      }
    }
  }

  @override
  String get type => 'Script';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['type'] = type;
    json.addAll({
      'uri': uri,
      'library': library?.toJson(),
    });
    _setIfNotNull(json, 'lineOffset', lineOffset);
    _setIfNotNull(json, 'columnOffset', columnOffset);
    _setIfNotNull(json, 'source', source);
    _setIfNotNull(
        json, 'tokenPosTable', tokenPosTable?.map((f) => f.toList()).toList());
    return json;
  }

  int get hashCode => id.hashCode;

  bool operator ==(Object other) => other is Script && id == other.id;

  String toString() => '[Script id: ${id}, uri: ${uri}, library: ${library}]';
}

class ScriptList extends Response {
  static ScriptList? parse(Map<String, dynamic>? json) =>
      json == null ? null : ScriptList._fromJson(json);

  List<ScriptRef>? scripts;

  ScriptList({
    required this.scripts,
  });

  ScriptList._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    scripts = List<ScriptRef>.from(
        createServiceObject(json['scripts'], const ['ScriptRef']) as List? ??
            []);
  }

  @override
  String get type => 'ScriptList';

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json['type'] = type;
    json.addAll({
      'scripts': scripts?.map((f) => f.toJson()).toList(),
    });
    return json;
  }

  String toString() => '[ScriptList scripts: ${scripts}]';
}

/// The `SourceLocation` class is used to designate a position or range in some
/// script.
class SourceLocation extends Response {
  static SourceLocation? parse(Map<String, dynamic>? json) =>
      json == null ? null : SourceLocation._fromJson(json);

  /// The script containing the source location.
  ScriptRef? script;

  /// The first token of the location.
  int? tokenPos;

  /// The last token of the location if this is a range.
  @optional
  int? endTokenPos;

  /// The line associated with this location. Only provided for non-synthetic
  /// token positions.
  @optional
  int? line;

  /// The column associated with this location. Only provided for non-synthetic
  /// token positions.
  @optional
  int? column;

  SourceLocation({
    required this.script,
    required this.tokenPos,
    this.endTokenPos,
    this.line,
    this.column,
  });

  SourceLocation._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    script =
        createServiceObject(json['script'], const ['ScriptRef']) as ScriptRef?;
    tokenPos = json['tokenPos'] ?? -1;
    endTokenPos = json['endTokenPos'];
    line = json['line'];
    column = json['column'];
  }

  @override
  String get type => 'SourceLocation';

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json['type'] = type;
    json.addAll({
      'script': script?.toJson(),
      'tokenPos': tokenPos,
    });
    _setIfNotNull(json, 'endTokenPos', endTokenPos);
    _setIfNotNull(json, 'line', line);
    _setIfNotNull(json, 'column', column);
    return json;
  }

  String toString() =>
      '[SourceLocation script: ${script}, tokenPos: ${tokenPos}]';
}

/// The `SourceReport` class represents a set of reports tied to source
/// locations in an isolate.
class SourceReport extends Response {
  static SourceReport? parse(Map<String, dynamic>? json) =>
      json == null ? null : SourceReport._fromJson(json);

  /// A list of ranges in the program source.  These ranges correspond to ranges
  /// of executable code in the user's program (functions, methods,
  /// constructors, etc.)
  ///
  /// Note that ranges may nest in other ranges, in the case of nested
  /// functions.
  ///
  /// Note that ranges may be duplicated, in the case of mixins.
  List<SourceReportRange>? ranges;

  /// A list of scripts, referenced by index in the report's ranges.
  List<ScriptRef>? scripts;

  SourceReport({
    required this.ranges,
    required this.scripts,
  });

  SourceReport._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    ranges = List<SourceReportRange>.from(
        _createSpecificObject(json['ranges']!, SourceReportRange.parse));
    scripts = List<ScriptRef>.from(
        createServiceObject(json['scripts'], const ['ScriptRef']) as List? ??
            []);
  }

  @override
  String get type => 'SourceReport';

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json['type'] = type;
    json.addAll({
      'ranges': ranges?.map((f) => f.toJson()).toList(),
      'scripts': scripts?.map((f) => f.toJson()).toList(),
    });
    return json;
  }

  String toString() => '[SourceReport ranges: ${ranges}, scripts: ${scripts}]';
}

/// The `SourceReportCoverage` class represents coverage information for one
/// [SourceReportRange].
///
/// Note that `SourceReportCoverage` does not extend [Response] and therefore
/// will not contain a `type` property.
class SourceReportCoverage {
  static SourceReportCoverage? parse(Map<String, dynamic>? json) =>
      json == null ? null : SourceReportCoverage._fromJson(json);

  /// A list of token positions (or line numbers if reportLines was enabled) in
  /// a SourceReportRange which have been executed.  The list is sorted.
  List<int>? hits;

  /// A list of token positions (or line numbers if reportLines was enabled) in
  /// a SourceReportRange which have not been executed.  The list is sorted.
  List<int>? misses;

  SourceReportCoverage({
    required this.hits,
    required this.misses,
  });

  SourceReportCoverage._fromJson(Map<String, dynamic> json) {
    hits = List<int>.from(json['hits']);
    misses = List<int>.from(json['misses']);
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json.addAll({
      'hits': hits?.map((f) => f).toList(),
      'misses': misses?.map((f) => f).toList(),
    });
    return json;
  }

  String toString() =>
      '[SourceReportCoverage hits: ${hits}, misses: ${misses}]';
}

/// The `SourceReportRange` class represents a range of executable code
/// (function, method, constructor, etc) in the running program. It is part of a
/// [SourceReport].
///
/// Note that `SourceReportRange` does not extend [Response] and therefore will
/// not contain a `type` property.
class SourceReportRange {
  static SourceReportRange? parse(Map<String, dynamic>? json) =>
      json == null ? null : SourceReportRange._fromJson(json);

  /// An index into the script table of the SourceReport, indicating which
  /// script contains this range of code.
  int? scriptIndex;

  /// The token position at which this range begins.
  int? startPos;

  /// The token position at which this range ends.  Inclusive.
  int? endPos;

  /// Has this range been compiled by the Dart VM?
  bool? compiled;

  /// The error while attempting to compile this range, if this report was
  /// generated with forceCompile=true.
  @optional
  ErrorRef? error;

  /// Code coverage information for this range.  Provided only when the Coverage
  /// report has been requested and the range has been compiled.
  @optional
  SourceReportCoverage? coverage;

  /// Possible breakpoint information for this range, represented as a sorted
  /// list of token positions (or line numbers if reportLines was enabled).
  /// Provided only when the when the PossibleBreakpoint report has been
  /// requested and the range has been compiled.
  @optional
  List<int>? possibleBreakpoints;

  /// Branch coverage information for this range.  Provided only when the
  /// BranchCoverage report has been requested and the range has been compiled.
  @optional
  SourceReportCoverage? branchCoverage;

  SourceReportRange({
    required this.scriptIndex,
    required this.startPos,
    required this.endPos,
    required this.compiled,
    this.error,
    this.coverage,
    this.possibleBreakpoints,
    this.branchCoverage,
  });

  SourceReportRange._fromJson(Map<String, dynamic> json) {
    scriptIndex = json['scriptIndex'] ?? -1;
    startPos = json['startPos'] ?? -1;
    endPos = json['endPos'] ?? -1;
    compiled = json['compiled'] ?? false;
    error = createServiceObject(json['error'], const ['ErrorRef']) as ErrorRef?;
    coverage =
        _createSpecificObject(json['coverage'], SourceReportCoverage.parse);
    possibleBreakpoints = json['possibleBreakpoints'] == null
        ? null
        : List<int>.from(json['possibleBreakpoints']);
    branchCoverage = createServiceObject(
            json['branchCoverage'], const ['SourceReportCoverage'])
        as SourceReportCoverage?;
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json.addAll({
      'scriptIndex': scriptIndex,
      'startPos': startPos,
      'endPos': endPos,
      'compiled': compiled,
    });
    _setIfNotNull(json, 'error', error?.toJson());
    _setIfNotNull(json, 'coverage', coverage?.toJson());
    _setIfNotNull(json, 'possibleBreakpoints',
        possibleBreakpoints?.map((f) => f).toList());
    _setIfNotNull(json, 'branchCoverage', branchCoverage?.toJson());
    return json;
  }

  String toString() => '[SourceReportRange ' //
      'scriptIndex: ${scriptIndex}, startPos: ${startPos}, endPos: ${endPos}, ' //
      'compiled: ${compiled}]';
}

/// The `Stack` class represents the various components of a Dart stack trace
/// for a given isolate.
///
/// See [getStack].
class Stack extends Response {
  static Stack? parse(Map<String, dynamic>? json) =>
      json == null ? null : Stack._fromJson(json);

  /// A list of frames that make up the synchronous stack, rooted at the message
  /// loop (i.e., the frames since the last asynchronous gap or the isolate's
  /// entrypoint).
  List<Frame>? frames;

  /// A list of frames representing the asynchronous path. Comparable to
  /// `awaiterFrames`, if provided, although some frames may be different.
  @optional
  List<Frame>? asyncCausalFrames;

  /// A list of frames representing the asynchronous path. Comparable to
  /// `asyncCausalFrames`, if provided, although some frames may be different.
  @optional
  List<Frame>? awaiterFrames;

  /// A list of messages in the isolate's message queue.
  List<Message>? messages;

  /// Specifies whether or not this stack is complete or has been artificially
  /// truncated.
  bool? truncated;

  Stack({
    required this.frames,
    required this.messages,
    required this.truncated,
    this.asyncCausalFrames,
    this.awaiterFrames,
  });

  Stack._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    frames = List<Frame>.from(
        createServiceObject(json['frames'], const ['Frame']) as List? ?? []);
    asyncCausalFrames = json['asyncCausalFrames'] == null
        ? null
        : List<Frame>.from(
            createServiceObject(json['asyncCausalFrames'], const ['Frame'])!
                as List);
    awaiterFrames = json['awaiterFrames'] == null
        ? null
        : List<Frame>.from(
            createServiceObject(json['awaiterFrames'], const ['Frame'])!
                as List);
    messages = List<Message>.from(
        createServiceObject(json['messages'], const ['Message']) as List? ??
            []);
    truncated = json['truncated'] ?? false;
  }

  @override
  String get type => 'Stack';

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json['type'] = type;
    json.addAll({
      'frames': frames?.map((f) => f.toJson()).toList(),
      'messages': messages?.map((f) => f.toJson()).toList(),
      'truncated': truncated,
    });
    _setIfNotNull(json, 'asyncCausalFrames',
        asyncCausalFrames?.map((f) => f.toJson()).toList());
    _setIfNotNull(
        json, 'awaiterFrames', awaiterFrames?.map((f) => f.toJson()).toList());
    return json;
  }

  String toString() => '[Stack ' //
      'frames: ${frames}, messages: ${messages}, truncated: ${truncated}]';
}

/// The `Success` type is used to indicate that an operation completed
/// successfully.
class Success extends Response {
  static Success? parse(Map<String, dynamic>? json) =>
      json == null ? null : Success._fromJson(json);

  Success();

  Success._fromJson(Map<String, dynamic> json) : super._fromJson(json);

  @override
  String get type => 'Success';

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json['type'] = type;
    return json;
  }

  String toString() => '[Success]';
}

class Timeline extends Response {
  static Timeline? parse(Map<String, dynamic>? json) =>
      json == null ? null : Timeline._fromJson(json);

  /// A list of timeline events. No order is guaranteed for these events; in
  /// particular, these events may be unordered with respect to their
  /// timestamps.
  List<TimelineEvent>? traceEvents;

  /// The start of the period of time in which traceEvents were collected.
  int? timeOriginMicros;

  /// The duration of time covered by the timeline.
  int? timeExtentMicros;

  Timeline({
    required this.traceEvents,
    required this.timeOriginMicros,
    required this.timeExtentMicros,
  });

  Timeline._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    traceEvents = List<TimelineEvent>.from(
        createServiceObject(json['traceEvents'], const ['TimelineEvent'])
                as List? ??
            []);
    timeOriginMicros = json['timeOriginMicros'] ?? -1;
    timeExtentMicros = json['timeExtentMicros'] ?? -1;
  }

  @override
  String get type => 'Timeline';

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json['type'] = type;
    json.addAll({
      'traceEvents': traceEvents?.map((f) => f.toJson()).toList(),
      'timeOriginMicros': timeOriginMicros,
      'timeExtentMicros': timeExtentMicros,
    });
    return json;
  }

  String toString() => '[Timeline ' //
      'traceEvents: ${traceEvents}, timeOriginMicros: ${timeOriginMicros}, ' //
      'timeExtentMicros: ${timeExtentMicros}]';
}

/// An `TimelineEvent` is an arbitrary map that contains a [Trace Event Format]
/// event.
class TimelineEvent {
  static TimelineEvent? parse(Map<String, dynamic>? json) =>
      json == null ? null : TimelineEvent._fromJson(json);

  Map<String, dynamic>? json;

  TimelineEvent();

  TimelineEvent._fromJson(this.json);

  Map<String, dynamic> toJson() {
    final localJson = json;
    final result = localJson == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.of(localJson);
    result['type'] = 'TimelineEvent';
    return result;
  }

  String toString() => '[TimelineEvent]';
}

class TimelineFlags extends Response {
  static TimelineFlags? parse(Map<String, dynamic>? json) =>
      json == null ? null : TimelineFlags._fromJson(json);

  /// The name of the recorder currently in use. Recorder types include, but are
  /// not limited to: Callback, Endless, Fuchsia, Macos, Ring, Startup, and
  /// Systrace. Set to "null" if no recorder is currently set.
  String? recorderName;

  /// The list of all available timeline streams.
  List<String>? availableStreams;

  /// The list of timeline streams that are currently enabled.
  List<String>? recordedStreams;

  TimelineFlags({
    required this.recorderName,
    required this.availableStreams,
    required this.recordedStreams,
  });

  TimelineFlags._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    recorderName = json['recorderName'] ?? '';
    availableStreams = List<String>.from(json['availableStreams']);
    recordedStreams = List<String>.from(json['recordedStreams']);
  }

  @override
  String get type => 'TimelineFlags';

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json['type'] = type;
    json.addAll({
      'recorderName': recorderName,
      'availableStreams': availableStreams?.map((f) => f).toList(),
      'recordedStreams': recordedStreams?.map((f) => f).toList(),
    });
    return json;
  }

  String toString() => '[TimelineFlags ' //
      'recorderName: ${recorderName}, availableStreams: ${availableStreams}, ' //
      'recordedStreams: ${recordedStreams}]';
}

class Timestamp extends Response {
  static Timestamp? parse(Map<String, dynamic>? json) =>
      json == null ? null : Timestamp._fromJson(json);

  /// A timestamp in microseconds since epoch.
  int? timestamp;

  Timestamp({
    required this.timestamp,
  });

  Timestamp._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    timestamp = json['timestamp'] ?? -1;
  }

  @override
  String get type => 'Timestamp';

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json['type'] = type;
    json.addAll({
      'timestamp': timestamp,
    });
    return json;
  }

  String toString() => '[Timestamp timestamp: ${timestamp}]';
}

/// `TypeArgumentsRef` is a reference to a `TypeArguments` object.
class TypeArgumentsRef extends ObjRef {
  static TypeArgumentsRef? parse(Map<String, dynamic>? json) =>
      json == null ? null : TypeArgumentsRef._fromJson(json);

  /// A name for this type argument list.
  String? name;

  TypeArgumentsRef({
    required this.name,
    required String id,
  }) : super(
          id: id,
        );

  TypeArgumentsRef._fromJson(Map<String, dynamic> json)
      : super._fromJson(json) {
    name = json['name'] ?? '';
  }

  @override
  String get type => '@TypeArguments';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['type'] = type;
    json.addAll({
      'name': name,
    });
    return json;
  }

  int get hashCode => id.hashCode;

  bool operator ==(Object other) => other is TypeArgumentsRef && id == other.id;

  String toString() => '[TypeArgumentsRef id: ${id}, name: ${name}]';
}

/// A `TypeArguments` object represents the type argument vector for some
/// instantiated generic type.
class TypeArguments extends Obj implements TypeArgumentsRef {
  static TypeArguments? parse(Map<String, dynamic>? json) =>
      json == null ? null : TypeArguments._fromJson(json);

  /// A name for this type argument list.
  String? name;

  /// A list of types.
  ///
  /// The value will always be one of the kinds: Type, TypeRef, TypeParameter,
  /// BoundedType.
  List<InstanceRef>? types;

  TypeArguments({
    required this.name,
    required this.types,
    required String id,
  }) : super(
          id: id,
        );

  TypeArguments._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    name = json['name'] ?? '';
    types = List<InstanceRef>.from(
        createServiceObject(json['types'], const ['InstanceRef']) as List? ??
            []);
  }

  @override
  String get type => 'TypeArguments';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['type'] = type;
    json.addAll({
      'name': name,
      'types': types?.map((f) => f.toJson()).toList(),
    });
    return json;
  }

  int get hashCode => id.hashCode;

  bool operator ==(Object other) => other is TypeArguments && id == other.id;

  String toString() =>
      '[TypeArguments id: ${id}, name: ${name}, types: ${types}]';
}

/// A `TypeParameters` object represents the type argument vector for some
/// uninstantiated generic type.
class TypeParameters {
  static TypeParameters? parse(Map<String, dynamic>? json) =>
      json == null ? null : TypeParameters._fromJson(json);

  /// The names of the type parameters.
  List<String>? names;

  /// The bounds set on each type parameter.
  TypeArgumentsRef? bounds;

  /// The default types for each type parameter.
  TypeArgumentsRef? defaults;

  TypeParameters({
    required this.names,
    required this.bounds,
    required this.defaults,
  });

  TypeParameters._fromJson(Map<String, dynamic> json) {
    names = List<String>.from(json['names']);
    bounds = createServiceObject(json['bounds'], const ['TypeArgumentsRef'])
        as TypeArgumentsRef?;
    defaults = createServiceObject(json['defaults'], const ['TypeArgumentsRef'])
        as TypeArgumentsRef?;
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json.addAll({
      'names': names?.map((f) => f).toList(),
      'bounds': bounds?.toJson(),
      'defaults': defaults?.toJson(),
    });
    return json;
  }

  String toString() =>
      '[TypeParameters names: ${names}, bounds: ${bounds}, defaults: ${defaults}]';
}

/// The `UnresolvedSourceLocation` class is used to refer to an unresolved
/// breakpoint location. As such, it is meant to approximate the final location
/// of the breakpoint but it is not exact.
///
/// Either the `script` or the `scriptUri` field will be present.
///
/// Either the `tokenPos` or the `line` field will be present.
///
/// The `column` field will only be present when the breakpoint was specified
/// with a specific column number.
class UnresolvedSourceLocation extends Response {
  static UnresolvedSourceLocation? parse(Map<String, dynamic>? json) =>
      json == null ? null : UnresolvedSourceLocation._fromJson(json);

  /// The script containing the source location if the script has been loaded.
  @optional
  ScriptRef? script;

  /// The uri of the script containing the source location if the script has yet
  /// to be loaded.
  @optional
  String? scriptUri;

  /// An approximate token position for the source location. This may change
  /// when the location is resolved.
  @optional
  int? tokenPos;

  /// An approximate line number for the source location. This may change when
  /// the location is resolved.
  @optional
  int? line;

  /// An approximate column number for the source location. This may change when
  /// the location is resolved.
  @optional
  int? column;

  UnresolvedSourceLocation({
    this.script,
    this.scriptUri,
    this.tokenPos,
    this.line,
    this.column,
  });

  UnresolvedSourceLocation._fromJson(Map<String, dynamic> json)
      : super._fromJson(json) {
    script =
        createServiceObject(json['script'], const ['ScriptRef']) as ScriptRef?;
    scriptUri = json['scriptUri'];
    tokenPos = json['tokenPos'];
    line = json['line'];
    column = json['column'];
  }

  @override
  String get type => 'UnresolvedSourceLocation';

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json['type'] = type;
    _setIfNotNull(json, 'script', script?.toJson());
    _setIfNotNull(json, 'scriptUri', scriptUri);
    _setIfNotNull(json, 'tokenPos', tokenPos);
    _setIfNotNull(json, 'line', line);
    _setIfNotNull(json, 'column', column);
    return json;
  }

  String toString() => '[UnresolvedSourceLocation]';
}

class UriList extends Response {
  static UriList? parse(Map<String, dynamic>? json) =>
      json == null ? null : UriList._fromJson(json);

  /// A list of URIs.
  List<String?>? uris;

  UriList({
    required this.uris,
  });

  UriList._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    uris = List<String?>.from(json['uris']);
  }

  @override
  String get type => 'UriList';

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json['type'] = type;
    json.addAll({
      'uris': uris?.map((f) => f).toList(),
    });
    return json;
  }

  String toString() => '[UriList uris: ${uris}]';
}

/// See [Versioning].
class Version extends Response {
  static Version? parse(Map<String, dynamic>? json) =>
      json == null ? null : Version._fromJson(json);

  /// The major version number is incremented when the protocol is changed in a
  /// potentially incompatible way.
  int? major;

  /// The minor version number is incremented when the protocol is changed in a
  /// backwards compatible way.
  int? minor;

  Version({
    required this.major,
    required this.minor,
  });

  Version._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    major = json['major'] ?? -1;
    minor = json['minor'] ?? -1;
  }

  @override
  String get type => 'Version';

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json['type'] = type;
    json.addAll({
      'major': major,
      'minor': minor,
    });
    return json;
  }

  String toString() => '[Version major: ${major}, minor: ${minor}]';
}

/// `VMRef` is a reference to a `VM` object.
class VMRef extends Response {
  static VMRef? parse(Map<String, dynamic>? json) =>
      json == null ? null : VMRef._fromJson(json);

  /// A name identifying this vm. Not guaranteed to be unique.
  String? name;

  VMRef({
    required this.name,
  });

  VMRef._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    name = json['name'] ?? '';
  }

  @override
  String get type => '@VM';

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json['type'] = type;
    json.addAll({
      'name': name,
    });
    return json;
  }

  String toString() => '[VMRef name: ${name}]';
}

class VM extends Response implements VMRef {
  static VM? parse(Map<String, dynamic>? json) =>
      json == null ? null : VM._fromJson(json);

  /// A name identifying this vm. Not guaranteed to be unique.
  String? name;

  /// Word length on target architecture (e.g. 32, 64).
  int? architectureBits;

  /// The CPU we are actually running on.
  String? hostCPU;

  /// The operating system we are running on.
  String? operatingSystem;

  /// The CPU we are generating code for.
  String? targetCPU;

  /// The Dart VM version string.
  String? version;

  /// The process id for the VM.
  int? pid;

  /// The time that the VM started in milliseconds since the epoch.
  ///
  /// Suitable to pass to DateTime.fromMillisecondsSinceEpoch.
  int? startTime;

  /// A list of isolates running in the VM.
  List<IsolateRef>? isolates;

  /// A list of isolate groups running in the VM.
  List<IsolateGroupRef>? isolateGroups;

  /// A list of system isolates running in the VM.
  List<IsolateRef>? systemIsolates;

  /// A list of isolate groups which contain system isolates running in the VM.
  List<IsolateGroupRef>? systemIsolateGroups;

  VM({
    required this.name,
    required this.architectureBits,
    required this.hostCPU,
    required this.operatingSystem,
    required this.targetCPU,
    required this.version,
    required this.pid,
    required this.startTime,
    required this.isolates,
    required this.isolateGroups,
    required this.systemIsolates,
    required this.systemIsolateGroups,
  });

  VM._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    name = json['name'] ?? '';
    architectureBits = json['architectureBits'] ?? -1;
    hostCPU = json['hostCPU'] ?? '';
    operatingSystem = json['operatingSystem'] ?? '';
    targetCPU = json['targetCPU'] ?? '';
    version = json['version'] ?? '';
    pid = json['pid'] ?? -1;
    startTime = json['startTime'] ?? -1;
    isolates = List<IsolateRef>.from(
        createServiceObject(json['isolates'], const ['IsolateRef']) as List? ??
            []);
    isolateGroups = List<IsolateGroupRef>.from(
        createServiceObject(json['isolateGroups'], const ['IsolateGroupRef'])
                as List? ??
            []);
    systemIsolates = List<IsolateRef>.from(
        createServiceObject(json['systemIsolates'], const ['IsolateRef'])
                as List? ??
            []);
    systemIsolateGroups = List<IsolateGroupRef>.from(createServiceObject(
            json['systemIsolateGroups'], const ['IsolateGroupRef']) as List? ??
        []);
  }

  @override
  String get type => 'VM';

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json['type'] = type;
    json.addAll({
      'name': name,
      'architectureBits': architectureBits,
      'hostCPU': hostCPU,
      'operatingSystem': operatingSystem,
      'targetCPU': targetCPU,
      'version': version,
      'pid': pid,
      'startTime': startTime,
      'isolates': isolates?.map((f) => f.toJson()).toList(),
      'isolateGroups': isolateGroups?.map((f) => f.toJson()).toList(),
      'systemIsolates': systemIsolates?.map((f) => f.toJson()).toList(),
      'systemIsolateGroups':
          systemIsolateGroups?.map((f) => f.toJson()).toList(),
    });
    return json;
  }

  String toString() => '[VM]';
}
