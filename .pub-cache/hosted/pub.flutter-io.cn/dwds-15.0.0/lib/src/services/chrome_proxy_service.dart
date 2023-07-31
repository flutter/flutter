// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart' hide LogRecord;
import 'package:pub_semver/pub_semver.dart' as semver;
import 'package:vm_service/vm_service.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

import '../../data/debug_event.dart';
import '../../data/register_event.dart';
import '../connections/app_connection.dart';
import '../debugging/debugger.dart';
import '../debugging/execution_context.dart';
import '../debugging/inspector.dart';
import '../debugging/instance.dart';
import '../debugging/location.dart';
import '../debugging/modules.dart';
import '../debugging/remote_debugger.dart';
import '../debugging/skip_list.dart';
import '../events.dart';
import '../loaders/strategy.dart';
import '../readers/asset_reader.dart';
import '../services/chrome_debug_exception.dart';
import '../services/expression_compiler.dart';
import '../utilities/dart_uri.dart';
import '../utilities/sdk_configuration.dart';
import '../utilities/shared.dart';
import 'expression_evaluator.dart';

/// Adds [event] to the stream with [streamId] if there is anybody listening
/// on that stream.
typedef StreamNotify = void Function(String streamId, Event event);

/// Returns the [AppInspector] for the current tab.
///
/// This may be null during a hot restart or page refresh.
typedef AppInspectorProvider = AppInspector Function();

/// A proxy from the chrome debug protocol to the dart vm service protocol.
class ChromeProxyService implements VmServiceInterface {
  /// Cache of all existing StreamControllers.
  ///
  /// These are all created through [onEvent].
  final _streamControllers = <String, StreamController<Event>>{};

  /// The root `VM` instance. There can only be one of these, but its isolates
  /// are dynamic and roughly map to chrome tabs.
  final VM _vm;

  /// Signals when isolate is intialized.
  Completer<void> _initializedCompleter = Completer<void>();
  Future<void> get isInitialized => _initializedCompleter.future;

  /// Signals when expression compiler is ready to evaluate.
  Completer<void> _compilerCompleter = Completer<void>();
  Future<void> get isCompilerInitialized => _compilerCompleter.future;

  /// The root at which we're serving.
  final String root;

  final RemoteDebugger remoteDebugger;
  final ExecutionContext executionContext;

  /// Provides debugger-related functionality.
  Future<Debugger> get _debugger => _debuggerCompleter.future;

  final AssetReader _assetReader;

  final Locations _locations;

  final SkipLists _skipLists;

  final Modules _modules;

  final _debuggerCompleter = Completer<Debugger>();

  AppInspector _inspector;

  /// Public only for testing.
  ///
  /// Returns the [AppInspector] this service uses.
  AppInspector appInspectorProvider() => _inspector;

  StreamSubscription<ConsoleAPIEvent> _consoleSubscription;

  final _disabledBreakpoints = <Breakpoint>{};
  final _previousBreakpoints = <Breakpoint>{};

  final _logger = Logger('ChromeProxyService');

  final ExpressionCompiler _compiler;
  ExpressionEvaluator _expressionEvaluator;

  final SdkConfigurationProvider _sdkConfigurationProvider;

  bool terminatingIsolates = false;

  ChromeProxyService._(
    this._vm,
    this.root,
    this._assetReader,
    this.remoteDebugger,
    this._modules,
    this._locations,
    this._skipLists,
    this.executionContext,
    this._compiler,
    this._sdkConfigurationProvider,
  ) {
    final debugger = Debugger.create(
      remoteDebugger,
      _streamNotify,
      appInspectorProvider,
      _locations,
      _skipLists,
      root,
    );
    _debuggerCompleter.complete(debugger);
  }

  static Future<ChromeProxyService> create(
    RemoteDebugger remoteDebugger,
    String root,
    AssetReader assetReader,
    LoadStrategy loadStrategy,
    AppConnection appConnection,
    ExecutionContext executionContext,
    ExpressionCompiler expressionCompiler,
    SdkConfigurationProvider sdkConfigurationProvider,
  ) async {
    final vm = VM(
      name: 'ChromeDebugProxy',
      operatingSystem: Platform.operatingSystem,
      startTime: DateTime.now().millisecondsSinceEpoch,
      version: Platform.version,
      isolates: [],
      isolateGroups: [],
      systemIsolates: [],
      systemIsolateGroups: [],
      targetCPU: 'Web',
      hostCPU: 'DWDS',
      architectureBits: -1,
      pid: -1,
    );

    final modules = Modules(root);
    final locations = Locations(assetReader, modules, root);
    final skipLists = SkipLists();
    final service = ChromeProxyService._(
      vm,
      root,
      assetReader,
      remoteDebugger,
      modules,
      locations,
      skipLists,
      executionContext,
      expressionCompiler,
      sdkConfigurationProvider,
    );
    unawaited(service.createIsolate(appConnection));
    return service;
  }

  /// Initializes metdata in [Locations], [Modules], and [ExpressionCompiler].
  Future<void> _initializeEntrypoint(String entrypoint) async {
    _locations.initialize(entrypoint);
    _modules.initialize(entrypoint);
    _skipLists.initialize();
    // We do not need to wait for compiler dependencies to be udpated as the
    // [ExpressionEvaluator] is robust to evaluation requests during updates.
    unawaited(_updateCompilerDependencies(entrypoint));
  }

  Future<void> _updateCompilerDependencies(String entrypoint) async {
    final metadataProvider = globalLoadStrategy.metadataProviderFor(entrypoint);
    final moduleFormat = globalLoadStrategy.moduleFormat;
    final soundNullSafety = await metadataProvider.soundNullSafety;

    _logger.info('Initializing expression compiler for $entrypoint '
        'with sound null safety: $soundNullSafety');

    if (_compiler != null) {
      await _compiler?.initialize(
          moduleFormat: moduleFormat, soundNullSafety: soundNullSafety);
      final dependencies =
          await globalLoadStrategy.moduleInfoForEntrypoint(entrypoint);
      await captureElapsedTime(() async {
        final result = await _compiler.updateDependencies(dependencies);
        // Expression evaluation is ready after dependencies are updated.
        if (!_compilerCompleter.isCompleted) _compilerCompleter.complete();
        return result;
      }, (result) => DwdsEvent.compilerUpdateDependencies(entrypoint));
    }
  }

  /// Creates a new isolate.
  ///
  /// Only one isolate at a time is supported, but they should be cleaned up
  /// with [destroyIsolate] and recreated with this method there is a hot
  /// restart or full page refresh.
  Future<void> createIsolate(AppConnection appConnection) async {
    if (_inspector?.isolate != null) {
      throw UnsupportedError(
          'Cannot create multiple isolates for the same app');
    }
    // Waiting for the debugger to be ready before initializing the entrypoint.
    //
    // Note: moving `await _debugger` after the `_initalizeEntryPoint` call
    // causes `getcwd` system calls to fail. Since that system call is used
    // in first `Uri.base` call in the expression compiler service isolate,
    // the expression compiler service will fail to start.
    // Issue: https://github.com/dart-lang/webdev/issues/1282
    final debugger = await _debugger;
    final entrypoint = appConnection.request.entrypointPath;
    await _initializeEntrypoint(entrypoint);
    final sdkConfiguration = await _sdkConfigurationProvider.configuration;

    debugger.notifyPausedAtStart();
    _inspector = await AppInspector.initialize(
      appConnection,
      remoteDebugger,
      _assetReader,
      _locations,
      root,
      debugger,
      executionContext,
      sdkConfiguration,
    );

    _expressionEvaluator = _compiler == null
        ? null
        : ExpressionEvaluator(
            entrypoint,
            _inspector,
            _locations,
            _modules,
            _compiler,
          );

    await debugger.reestablishBreakpoints(
        _previousBreakpoints, _disabledBreakpoints);
    _disabledBreakpoints.clear();

    unawaited(appConnection.onStart.then((_) async {
      await debugger.resumeFromStart();
    }));

    final isolateRef = _inspector.isolateRef;
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // Listen for `registerExtension` and `postEvent` calls.
    _setUpChromeConsoleListeners(isolateRef);

    _vm.isolates.add(isolateRef);

    _streamNotify(
        'Isolate',
        Event(
            kind: EventKind.kIsolateStart,
            timestamp: timestamp,
            isolate: isolateRef));
    _streamNotify(
        'Isolate',
        Event(
            kind: EventKind.kIsolateRunnable,
            timestamp: timestamp,
            isolate: isolateRef));

    // TODO: We shouldn't need to fire these events since they exist on the
    // isolate, but devtools doesn't recognize extensions after a page refresh
    // otherwise.
    for (var extensionRpc in _inspector.isolate.extensionRPCs) {
      _streamNotify(
          'Isolate',
          Event(
              kind: EventKind.kServiceExtensionAdded,
              timestamp: timestamp,
              isolate: isolateRef)
            ..extensionRPC = extensionRpc);
    }

    // The service is considered initialized when the first isolate is created.
    if (!_initializedCompleter.isCompleted) _initializedCompleter.complete();
  }

  /// Should be called when there is a hot restart or full page refresh.
  ///
  /// Clears out the [_inspector] and all related cached information.
  void destroyIsolate() {
    final isolate = _inspector?.isolate;
    if (isolate == null) return;
    _initializedCompleter = Completer<void>();
    _compilerCompleter = Completer<void>();
    _streamNotify(
        'Isolate',
        Event(
            kind: EventKind.kIsolateExit,
            timestamp: DateTime.now().millisecondsSinceEpoch,
            isolate: _inspector.isolateRef));
    _vm.isolates.removeWhere((ref) => ref.id == isolate.id);
    _inspector = null;
    _previousBreakpoints.clear();
    _previousBreakpoints.addAll(isolate.breakpoints);
    _consoleSubscription?.cancel();
    _consoleSubscription = null;
  }

  Future<void> disableBreakpoints() async {
    _disabledBreakpoints.clear();
    final isolate = _inspector?.isolate;
    if (isolate == null) return;
    _disabledBreakpoints.addAll(isolate.breakpoints);
    for (var breakpoint in isolate.breakpoints.toList()) {
      await (await _debugger).removeBreakpoint(isolate.id, breakpoint.id);
    }
  }

  @override
  Future<Breakpoint> addBreakpoint(String isolateId, String scriptId, int line,
      {int column}) async {
    await isInitialized;
    return (await _debugger)
        .addBreakpoint(isolateId, scriptId, line, column: column);
  }

  @override
  Future<Breakpoint> addBreakpointAtEntry(String isolateId, String functionId) {
    return _rpcNotSupportedFuture('addBreakpointAtEntry');
  }

  @override
  Future<Breakpoint> addBreakpointWithScriptUri(
      String isolateId, String scriptUri, int line,
      {int column}) async {
    await isInitialized;
    if (Uri.parse(scriptUri).scheme == 'dart') {
      _logger.finest('Cannot set breakpoint at $scriptUri:$line:$column: '
          'breakpoints in dart SDK locations are not supported yet.');
      // TODO(annagrin): Support setting breakpoints in dart SDK locations.
      // Issue: https://github.com/dart-lang/webdev/issues/1584
      throw RPCError(
          'addBreakpoint',
          102,
          'The VM is unable to add a breakpoint '
              'at the specified line or function');
    }
    final dartUri = DartUri(scriptUri, root);
    final ref = await _inspector.scriptRefFor(dartUri.serverPath);
    return (await _debugger)
        .addBreakpoint(isolateId, ref.id, line, column: column);
  }

  @override
  Future<Response> callServiceExtension(String method,
      {String isolateId, Map args}) async {
    await isInitialized;
    // Validate the isolate id is correct, _getIsolate throws if not.
    if (isolateId != null) _getIsolate(isolateId);
    args ??= <String, String>{};
    final stringArgs = args.map((k, v) => MapEntry(
        k is String ? k : jsonEncode(k), v is String ? v : jsonEncode(v)));
    final expression = '''
${globalLoadStrategy.loadModuleSnippet}("dart_sdk").developer.invokeExtension(
    "$method", JSON.stringify(${jsonEncode(stringArgs)}));
''';
    final response =
        await remoteDebugger.sendCommand('Runtime.evaluate', params: {
      'expression': expression,
      'awaitPromise': true,
      'contextId': await executionContext.id,
    });
    handleErrorIfPresent(response, evalContents: expression);
    final decodedResponse =
        jsonDecode(response.result['result']['value'] as String)
            as Map<String, dynamic>;
    if (decodedResponse.containsKey('code') &&
        decodedResponse.containsKey('message') &&
        decodedResponse.containsKey('data')) {
      // ignore: only_throw_errors
      throw RPCError(method, decodedResponse['code'] as int,
          decodedResponse['message'] as String, decodedResponse['data'] as Map);
    } else {
      return Response()..json = decodedResponse;
    }
  }

  @override
  Future<Success> clearVMTimeline() {
    return _rpcNotSupportedFuture('clearVMTimeline');
  }

  void _validateIsolateId(String isolateId) {
    final isolate = _inspector?.isolate;
    if (isolate?.id != isolateId) {
      throw RPCError('evaluateInFrame', RPCError.kInvalidParams,
          'Unrecognized isolate id: $isolateId. Supported isolate: ${isolate?.id}');
    }
  }

  Future<Response> _getEvaluationResult(
      Future<RemoteObject> Function() evaluation, String expression) async {
    try {
      final result = await evaluation();
      // Handle compilation errors, internal errors,
      // and reference errors from JavaScript evaluation in chrome.
      if (result.type.contains('Error')) {
        if (!result.type.startsWith('CompilationError')) {
          _logger.warning('Failed to evaluate expression \'$expression\': '
              '${result.type}: ${result.value}.');

          _logger.info('Please follow instructions at '
              'https://github.com/dart-lang/webdev/issues/956 '
              'to file a bug.');
        }
        return ErrorRef(
          kind: 'error',
          message: '${result.type}: ${result.value}',
          id: createId(),
        );
      }
      return _inspector?.instanceHelper?.instanceRefFor(result);
    } on RPCError catch (_) {
      rethrow;
    } catch (e, s) {
      // Handle errors that throw exceptions, such as invalid JavaScript
      // generated by the expression evaluator.
      _logger.warning('Failed to evaluate expression \'$expression\'. ');
      _logger.info('Please follow instructions at '
          'https://github.com/dart-lang/webdev/issues/956 '
          'to file a bug.');
      _logger.info('$e:$s');
      return ErrorRef(kind: 'error', message: '<unknown>', id: createId());
    }
  }

  @override
  Future<Response> evaluate(
    String isolateId,
    String targetId,
    String expression, {
    Map<String, String> scope,
    bool disableBreakpoints,
  }) async {
    // TODO(798) - respect disableBreakpoints.
    return captureElapsedTime(() async {
      await isInitialized;
      if (_expressionEvaluator != null) {
        await isCompilerInitialized;
        _validateIsolateId(isolateId);

        final library = await _inspector?.getLibrary(isolateId, targetId);
        return await _getEvaluationResult(
            () => _expressionEvaluator.evaluateExpression(
                isolateId, library.uri, expression, scope),
            expression);
      }
      // fall back to javascript evaluation
      final remote = await _inspector?.evaluate(isolateId, targetId, expression,
          scope: scope);
      return await _inspector?.instanceHelper?.instanceRefFor(remote);
    }, (result) => DwdsEvent.evaluate(expression, result));
  }

  @override
  Future<Response> evaluateInFrame(
      String isolateId, int frameIndex, String expression,
      {Map<String, String> scope, bool disableBreakpoints}) async {
    // TODO(798) - respect disableBreakpoints.

    return captureElapsedTime(() async {
      await isInitialized;
      if (_expressionEvaluator != null) {
        await isCompilerInitialized;
        _validateIsolateId(isolateId);

        if (scope != null) {
          // TODO(annagrin): Implement scope support.
          // Issue: https://github.com/dart-lang/webdev/issues/1344
          throw RPCError(
              'evaluateInFrame',
              RPCError.kInvalidRequest,
              'Expression evaluation with scope is not supported '
                  'for this configuration.');
        }

        return await _getEvaluationResult(
            () => _expressionEvaluator.evaluateExpressionInFrame(
                isolateId, frameIndex, expression, scope),
            expression);
      }
      throw RPCError('evaluateInFrame', RPCError.kInvalidRequest,
          'Expression evaluation is not supported for this configuration.');
    }, (result) => DwdsEvent.evaluateInFrame(expression, result));
  }

  @override
  Future<AllocationProfile> getAllocationProfile(String isolateId,
      {bool gc, bool reset}) {
    return _rpcNotSupportedFuture('getAllocationProfile');
  }

  @override
  Future<ClassList> getClassList(String isolateId) {
    // See dart-lang/webdev/issues/971.
    return _rpcNotSupportedFuture('getClassList');
  }

  @override
  Future<FlagList> getFlagList() async {
    // VM flags do not apply to web apps.
    return FlagList(flags: []);
  }

  @override
  Future<InstanceSet> getInstances(
      String isolateId, String classId, int limit) {
    return _rpcNotSupportedFuture('getInstances');
  }

  /// Sync version of [getIsolate] for internal use, also has stronger typing
  /// than the public one which has to be dynamic.
  Isolate _getIsolate(String isolateId) {
    final isolate = _inspector?.isolate;
    if (isolate?.id == isolateId) return isolate;
    // TODO: Throw an RPC error here.
    throw ArgumentError.value(isolateId, 'isolateId',
        'Unrecognized isolate id. (Supported isolate: ${isolate?.id})');
  }

  @override
  Future<Isolate> getIsolate(String isolateId) async {
    return captureElapsedTime(() async {
      await isInitialized;
      return _getIsolate(isolateId);
    }, (result) => DwdsEvent.getIsolate());
  }

  @override
  Future<MemoryUsage> getMemoryUsage(String isolateId) async {
    await isInitialized;
    return _inspector.getMemoryUsage(isolateId);
  }

  @override
  Future<Obj> getObject(String isolateId, String objectId,
      {int offset, int count}) async {
    await isInitialized;
    return _inspector?.getObject(isolateId, objectId,
        offset: offset, count: count);
  }

  @override
  Future<ScriptList> getScripts(String isolateId) async {
    return await captureElapsedTime(() async {
      await isInitialized;
      return _inspector?.getScripts(isolateId);
    }, (result) => DwdsEvent.getScripts());
  }

  @override
  Future<SourceReport> getSourceReport(
    String isolateId,
    List<String> reports, {
    String scriptId,
    int tokenPos,
    int endTokenPos,
    bool forceCompile,
    bool reportLines,
    List<String> libraryFilters,
  }) async {
    return await captureElapsedTime(() async {
      await isInitialized;
      return await _inspector?.getSourceReport(
        isolateId,
        reports,
        scriptId: scriptId,
        tokenPos: tokenPos,
        endTokenPos: endTokenPos,
        forceCompile: forceCompile,
        reportLines: reportLines,
        libraryFilters: libraryFilters,
      );
    }, (result) => DwdsEvent.getSourceReport());
  }

  /// Returns the current stack.
  ///
  /// Returns null if the corresponding isolate is not paused.
  ///
  /// The returned stack will contain up to [limit] frames if provided.
  @override
  Future<Stack> getStack(String isolateId, {int limit}) async {
    await isInitialized;
    return (await _debugger).getStack(isolateId, limit: limit);
  }

  @override
  Future<VM> getVM() async {
    return captureElapsedTime(() async {
      await isInitialized;
      return _vm;
    }, (result) => DwdsEvent.getVM());
  }

  @override
  Future<Timeline> getVMTimeline({int timeOriginMicros, int timeExtentMicros}) {
    return _rpcNotSupportedFuture('getVMTimeline');
  }

  @override
  Future<TimelineFlags> getVMTimelineFlags() {
    return _rpcNotSupportedFuture('getVMTimelineFlags');
  }

  @override
  Future<Version> getVersion() async {
    final version = semver.Version.parse(vmServiceVersion);
    return Version(major: version.major, minor: version.minor);
  }

  @override
  Future<Response> invoke(
      String isolateId, String targetId, String selector, List argumentIds,
      {bool disableBreakpoints}) async {
    await isInitialized;
    // TODO(798) - respect disableBreakpoints.
    final remote =
        await _inspector?.invoke(isolateId, targetId, selector, argumentIds);
    final result = _inspector?.instanceHelper?.instanceRefFor(remote);
    if (result == null) {
      throw ChromeDebugException(
          {'text': 'null result from invoke of $selector'});
    }
    return result;
  }

  @override
  Future<Success> kill(String isolateId) {
    return _rpcNotSupportedFuture('kill');
  }

  @override
  Stream<Event> onEvent(String streamId) {
    return _streamControllers.putIfAbsent(streamId, () {
      switch (streamId) {
        case EventStreams.kExtension:
          return StreamController<Event>.broadcast();
        case EventStreams.kIsolate:
          // TODO: right now we only support the `ServiceExtensionAdded` event
          // for the Isolate stream.
          return StreamController<Event>.broadcast();
        case EventStreams.kVM:
          return StreamController<Event>.broadcast();
        case EventStreams.kGC:
          return StreamController<Event>.broadcast();
        case EventStreams.kTimeline:
          return StreamController<Event>.broadcast();
        case EventStreams.kService:
          return StreamController<Event>.broadcast();
        case EventStreams.kDebug:
          return StreamController<Event>.broadcast();
        case EventStreams.kLogging:
          return StreamController<Event>.broadcast();
        case EventStreams.kStdout:
          return _chromeConsoleStreamController(
              (e) => _stdoutTypes.contains(e.type));
        case EventStreams.kStderr:
          return _chromeConsoleStreamController(
              (e) => _stderrTypes.contains(e.type),
              includeExceptions: true);
        default:
          throw RPCError(
            'streamListen',
            RPCError.kMethodNotFound,
            'The stream `$streamId` is not supported on web devices',
          );
      }
    }).stream;
  }

  @override
  Future<Success> pause(String isolateId) async {
    await isInitialized;
    return (await _debugger).pause();
  }

  // Note: Ignore the optional local parameter, it is there to keep the method
  // signature consistent with the VM service interface.
  @override
  Future<UriList> lookupResolvedPackageUris(String isolateId, List<String> uris,
      {bool local}) async {
    await isInitialized;
    return UriList(uris: uris.map(DartUri.toResolvedUri).toList());
  }

  @override
  Future<UriList> lookupPackageUris(String isolateId, List<String> uris) async {
    await isInitialized;
    return UriList(uris: uris.map(DartUri.toPackageUri).toList());
  }

  @override
  Future<Success> registerService(String service, String alias) async {
    return _rpcNotSupportedFuture('registerService');
  }

  @override
  Future<ReloadReport> reloadSources(String isolateId,
      {bool force, bool pause, String rootLibUri, String packagesUri}) {
    return Future.error(RPCError(
      'reloadSources',
      RPCError.kMethodNotFound,
      'Hot reload not supported on web devices',
    ));
  }

  @override
  Future<Success> removeBreakpoint(
      String isolateId, String breakpointId) async {
    await isInitialized;
    _disabledBreakpoints
        .removeWhere((breakpoint) => breakpoint.id == breakpointId);
    return (await _debugger).removeBreakpoint(isolateId, breakpointId);
  }

  @override
  Future<Success> resume(String isolateId,
      {String step, int frameIndex}) async {
    if (_inspector == null) throw StateError('No running isolate.');
    if (_inspector.appConnection.isStarted) {
      return captureElapsedTime(() async {
        await isInitialized;
        return await (await _debugger)
            .resume(isolateId, step: step, frameIndex: frameIndex);
      }, (result) => DwdsEvent.resume(step));
    } else {
      _inspector.appConnection.runMain();
      return Success();
    }
  }

  @override
  Future<Success> setIsolatePauseMode(String isolateId,
      {String exceptionPauseMode, bool shouldPauseOnExit}) async {
    // TODO(elliette): Is there a way to respect the shouldPauseOnExit parameter
    // in Chrome?
    return setExceptionPauseMode(isolateId, exceptionPauseMode);
  }

  @override
  Future<Success> setExceptionPauseMode(String isolateId, String mode) async {
    await isInitialized;
    return (await _debugger).setExceptionPauseMode(isolateId, mode);
  }

  @override
  Future<Success> setFlag(String name, String value) {
    return _rpcNotSupportedFuture('setFlag');
  }

  @override
  Future<Success> setLibraryDebuggable(
      String isolateId, String libraryId, bool isDebuggable) {
    return _rpcNotSupportedFuture('setLibraryDebuggable');
  }

  @override
  Future<Success> setName(String isolateId, String name) async {
    await isInitialized;
    final isolate = _getIsolate(isolateId);
    isolate.name = name;
    return Success();
  }

  @override
  Future<Success> setVMName(String name) async {
    _vm.name = name;
    _streamNotify(
        'VM',
        Event(
            kind: EventKind.kVMUpdate,
            timestamp: DateTime.now().millisecondsSinceEpoch,
            // We are not guaranteed to have an isolate at this point an time.
            isolate: null)
          ..vm = toVMRef(_vm));
    return Success();
  }

  @override
  Future<Success> setVMTimelineFlags(List<String> recordedStreams) {
    return _rpcNotSupportedFuture('setVMTimelineFlags');
  }

  @override
  Future<Success> streamCancel(String streamId) {
    // TODO: We should implement this (as we've already implemented
    // streamListen).
    return _rpcNotSupportedFuture('streamCancel');
  }

  @override
  Future<Success> streamListen(String streamId) async {
    // TODO: This should return an error if the stream is already being listened
    // to.
    onEvent(streamId);
    return Success();
  }

  @override
  Future<Success> clearCpuSamples(String isolateId) {
    return _rpcNotSupportedFuture('clearCpuSamples');
  }

  @override
  Future<CpuSamples> getCpuSamples(
      String isolateId, int timeOriginMicros, int timeExtentMicros) {
    return _rpcNotSupportedFuture('getCpuSamples');
  }

  /// Returns a streamController that listens for console logs from chrome and
  /// adds all events passing [filter] to the stream.
  StreamController<Event> _chromeConsoleStreamController(
      bool Function(ConsoleAPIEvent) filter,
      {bool includeExceptions = false}) {
    StreamController<Event> controller;
    StreamSubscription chromeConsoleSubscription;
    StreamSubscription exceptionsSubscription;

    // This is an edge case for this lint apparently
    //
    // ignore: join_return_with_assignment
    controller = StreamController<Event>.broadcast(onCancel: () {
      chromeConsoleSubscription?.cancel();
      exceptionsSubscription?.cancel();
    }, onListen: () {
      chromeConsoleSubscription = remoteDebugger.onConsoleAPICalled.listen((e) {
        final isolate = _inspector?.isolate;
        if (isolate == null) return;
        if (!filter(e)) return;
        final args = e.params['args'] as List;
        final item = args[0] as Map;
        final value = '${item["value"]}\n';
        controller.add(Event(
            kind: EventKind.kWriteEvent,
            timestamp: DateTime.now().millisecondsSinceEpoch,
            isolate: _inspector.isolateRef)
          ..bytes = base64.encode(utf8.encode(value))
          ..timestamp = e.timestamp.toInt());
      });
      if (includeExceptions) {
        exceptionsSubscription =
            remoteDebugger.onExceptionThrown.listen((e) async {
          final isolate = _inspector?.isolate;
          if (isolate == null) return;
          var description = e.exceptionDetails.exception.description;
          if (description != null) {
            description = await _inspector.mapExceptionStackTrace(description);
          }
          controller.add(Event(
              kind: EventKind.kWriteEvent,
              timestamp: DateTime.now().millisecondsSinceEpoch,
              isolate: _inspector.isolateRef)
            ..bytes = base64.encode(utf8.encode(description ?? '')));
        });
      }
    });
    return controller;
  }

  /// Parses the [BatchedDebugEvents] and emits corresponding Dart VM Service
  /// protocol [Event]s.
  Future<void> parseBatchedDebugEvents(BatchedDebugEvents debugEvents) async {
    for (var debugEvent in debugEvents.events) {
      await parseDebugEvent(debugEvent);
    }
  }

  /// Parses the [DebugEvent] and emits a corresponding Dart VM Service
  /// protocol [Event].
  Future<void> parseDebugEvent(DebugEvent debugEvent) async {
    if (terminatingIsolates) return;

    final isolateRef = _inspector?.isolateRef;
    if (isolateRef == null) return;

    _streamNotify(
        EventStreams.kExtension,
        Event(
            kind: EventKind.kExtension,
            timestamp: DateTime.now().millisecondsSinceEpoch,
            isolate: isolateRef)
          ..extensionKind = debugEvent.kind
          ..extensionData = ExtensionData.parse(
              jsonDecode(debugEvent.eventData) as Map<String, dynamic>));
  }

  /// Parses the [RegisterEvent] and emits a corresponding Dart VM Service
  /// protocol [Event].
  Future<void> parseRegisterEvent(RegisterEvent registerEvent) async {
    if (terminatingIsolates) return;

    final isolate = _inspector?.isolate;
    if (isolate == null) return;
    final service = registerEvent.eventData;
    isolate.extensionRPCs.add(service);

    final isolateRef = _inspector?.isolateRef;
    if (isolateRef == null) return;
    _streamNotify(
        EventStreams.kIsolate,
        Event(
            kind: EventKind.kServiceExtensionAdded,
            timestamp: DateTime.now().millisecondsSinceEpoch,
            isolate: isolateRef)
          ..extensionRPC = service);
  }

  /// Listens for chrome console events and handles the ones we care about.
  void _setUpChromeConsoleListeners(IsolateRef isolateRef) {
    _consoleSubscription =
        remoteDebugger.onConsoleAPICalled.listen((event) async {
      if (terminatingIsolates) return;
      if (event.type != 'debug') return;

      final isolate = _inspector?.isolate;
      if (isolate == null) return;
      if (isolateRef.id != isolate.id) return;

      final firstArgValue = event.args[0].value as String;
      // TODO(nshahan) - Migrate 'inspect' and 'log' events to the injected
      // client communication approach as well?
      switch (firstArgValue) {
        case 'dart.developer.inspect':
          // All inspected objects should be real objects.
          if (event.args[1].type != 'object') break;

          final inspectee =
              await _inspector.instanceHelper.instanceRefFor(event.args[1]);
          _streamNotify(
              EventStreams.kDebug,
              Event(
                  kind: EventKind.kInspect,
                  timestamp: DateTime.now().millisecondsSinceEpoch,
                  isolate: isolateRef)
                ..inspectee = inspectee
                ..timestamp = event.timestamp.toInt());
          break;
        case 'dart.developer.log':
          _handleDeveloperLog(isolateRef, event);
          break;
        default:
          break;
      }
    });
  }

  void _streamNotify(String streamId, Event event) {
    final controller = _streamControllers[streamId];
    if (controller == null) return;
    controller.add(event);
  }

  void _handleDeveloperLog(IsolateRef isolateRef, ConsoleAPIEvent event) async {
    final logObject = event.params['args'][1] as Map;
    final logParams = <String, RemoteObject>{};
    for (dynamic obj in logObject['preview']['properties']) {
      if (obj['name'] != null && obj is Map<String, dynamic>) {
        logParams[obj['name'] as String] = RemoteObject(obj);
      }
    }

    final logRecord = LogRecord(
      message: await _instanceRef(logParams['message']),
      loggerName: await _instanceRef(logParams['name']),
      level: logParams['level'] != null
          ? int.tryParse(logParams['level'].value.toString())
          : 0,
      error: await _instanceRef(logParams['error']),
      time: event.timestamp.toInt(),
      sequenceNumber: logParams['sequenceNumber'] != null
          ? int.tryParse(logParams['sequenceNumber'].value.toString())
          : 0,
      stackTrace: await _instanceRef(logParams['stackTrace']),
      zone: await _instanceRef(logParams['zone']),
    );

    _streamNotify(
      EventStreams.kLogging,
      Event(
          kind: EventKind.kLogging,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          isolate: isolateRef)
        ..logRecord = logRecord
        ..timestamp = event.timestamp.toInt(),
    );
  }

  @override
  Future<Timestamp> getVMTimelineMicros() {
    return _rpcNotSupportedFuture('getVMTimelineMicros');
  }

  @override
  Future<InboundReferences> getInboundReferences(
      String isolateId, String targetId, int limit) {
    return _rpcNotSupportedFuture('getInboundReferences');
  }

  @override
  Future<RetainingPath> getRetainingPath(
      String isolateId, String targetId, int limit) {
    return _rpcNotSupportedFuture('getRetainingPath');
  }

  @override
  Future<Success> requestHeapSnapshot(String isolateId) {
    return _rpcNotSupportedFuture('requestHeapSnapshot');
  }

  @override
  Future<IsolateGroup> getIsolateGroup(String isolateGroupId) {
    return _rpcNotSupportedFuture('getIsolateGroup');
  }

  @override
  Future<MemoryUsage> getIsolateGroupMemoryUsage(String isolateGroupId) {
    return _rpcNotSupportedFuture('getIsolateGroupMemoryUsage');
  }

  @override
  Future<ProtocolList> getSupportedProtocols() async {
    final version = semver.Version.parse(vmServiceVersion);
    return ProtocolList(protocols: [
      Protocol(
        protocolName: 'VM Service',
        major: version.major,
        minor: version.minor,
      )
    ]);
  }

  Future<InstanceRef> _instanceRef(RemoteObject obj) async {
    if (obj == null) {
      return InstanceHelper.kNullInstanceRef;
    } else {
      return _inspector.instanceHelper.instanceRefFor(obj);
    }
  }

  static RPCError _rpcNotSupported(String method) {
    return RPCError(method, RPCError.kMethodNotFound,
        '$method: Not supported on web devices');
  }

  static Future<T> _rpcNotSupportedFuture<T>(String method) {
    return Future.error(_rpcNotSupported(method));
  }

  @override
  Future<ProcessMemoryUsage> getProcessMemoryUsage() =>
      _rpcNotSupportedFuture('getProcessMemoryUsage');

  @override
  Future<PortList> getPorts(String isolateId) => throw UnimplementedError();

  @override
  Future<CpuSamples> getAllocationTraces(String isolateId,
          {int timeOriginMicros, int timeExtentMicros, String classId}) =>
      throw UnimplementedError();

  @override
  Future<Success> setTraceClassAllocation(
          String isolateId, String classId, bool enable) =>
      throw UnimplementedError();

  @override
  Future<Breakpoint> setBreakpointState(
          String isolateId, String breakpointId, bool enable) =>
      throw UnimplementedError();

  @override
  Future<Success> streamCpuSamplesWithUserTag(List<String> userTags) =>
      throw UnimplementedError();

  /// Prevent DWDS from blocking Dart SDK rolls if changes in package:vm_service
  /// are unimplemented in DWDS.
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

/// The `type`s of [ConsoleAPIEvent]s that are treated as `stderr` logs.
const _stderrTypes = ['error'];

/// The `type`s of [ConsoleAPIEvent]s that are treated as `stdout` logs.
const _stdoutTypes = ['log', 'info', 'warning'];
