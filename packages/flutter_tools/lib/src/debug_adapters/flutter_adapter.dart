// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:dds/dap.dart' hide PidTracker, PackageConfigUtils;
import 'package:meta/meta.dart';
import 'package:vm_service/vm_service.dart' as vm;

import '../base/file_system.dart';
import '../base/io.dart';
import '../base/platform.dart';
import '../cache.dart';
import '../convert.dart';
import 'flutter_adapter_args.dart';
import 'mixins.dart';

/// A DAP Debug Adapter for running and debugging Flutter applications.
class FlutterDebugAdapter extends DartDebugAdapter<FlutterLaunchRequestArguments, FlutterAttachRequestArguments>
    with PidTracker, PackageConfigUtils {
  FlutterDebugAdapter(
    ByteStreamServerChannel channel, {
    required this.fileSystem,
    required this.platform,
    bool ipv6 = false,
    bool enableDds = true,
    bool enableAuthCodes = true,
    Logger? logger,
  }) : super(
          channel,
          ipv6: ipv6,
          enableDds: enableDds,
          enableAuthCodes: enableAuthCodes,
          logger: logger,
        );

  @override
  FileSystem fileSystem;
  Platform platform;
  Process? _process;

  @override
  final FlutterLaunchRequestArguments Function(Map<String, Object?> obj)
      parseLaunchArgs = FlutterLaunchRequestArguments.fromJson;

  @override
  final FlutterAttachRequestArguments Function(Map<String, Object?> obj)
      parseAttachArgs = FlutterAttachRequestArguments.fromJson;

  /// A completer that completes when the app.started event has been received.
  @visibleForTesting
  final Completer<void> appStartedCompleter = Completer<void>();

  /// Whether or not the app.started event has been received.
  bool get _receivedAppStarted => appStartedCompleter.isCompleted;

  /// The VM Service URI received from the app.debugPort event.
  Uri? _vmServiceUri;

  /// The appId of the current running Flutter app.
  String? _appId;

  /// The ID to use for the next request sent to the Flutter run daemon.
  int _flutterRequestId = 1;

  /// Outstanding requests that have been sent to the Flutter run daemon and
  /// their handlers.
  final Map<int, Completer<Object?>> _flutterRequestCompleters = <int, Completer<Object?>>{};

  /// Whether or not this adapter can handle the restartRequest.
  ///
  /// For Flutter apps we can handle this with a Hot Restart rather than having
  /// the whole debug session stopped and restarted.
  @override
  bool get supportsRestartRequest => true;

  /// Whether the VM Service closing should be used as a signal to terminate the debug session.
  ///
  /// Since we always have a process for Flutter (whether run or attach) we'll
  /// always use its termination instead, so this is always false.
  @override
  bool get terminateOnVmServiceClose => false;

  /// Called by [attachRequest] to request that we actually connect to the app to be debugged.
  @override
  Future<void> attachImpl() async {
    sendOutput('console', '\nAttach is not currently supported');
    handleSessionTerminate();
  }

  /// [customRequest] handles any messages that do not match standard messages in the spec.
  ///
  /// This is used to allow a client/DA to have custom methods outside of the
  /// spec. It is up to the client/DA to negotiate which custom messages are
  /// allowed.
  ///
  /// [sendResponse] must be called when handling a message, even if it is with
  /// a null response. Otherwise the client will never be informed that the
  /// request has completed.
  ///
  /// Any requests not handled must call super which will respond with an error
  /// that the message was not supported.
  ///
  /// Unless they start with _ to indicate they are private, custom messages
  /// should not change in breaking ways if client IDEs/editors may be calling
  /// them.
  @override
  Future<void> customRequest(
    Request request,
    RawRequestArguments? args,
    void Function(Object?) sendResponse,
  ) async {
    switch (request.command) {
      case 'hotRestart':
      case 'hotReload':
        final bool isFullRestart = request.command == 'hotRestart';
        await _performRestart(isFullRestart, args?.args['reason'] as String?);
        sendResponse(null);
        break;

      default:
        await super.customRequest(request, args, sendResponse);
    }
  }

  @override
  Future<void> debuggerConnected(vm.VM vmInfo) async {
    // Capture the PID from the VM Service so that we can terminate it when
    // cleaning up. Terminating the process might not be enough as it could be
    // just a shell script (e.g. flutter.bat on Windows) and may not pass the
    // signal on correctly.
    // See: https://github.com/Dart-Code/Dart-Code/issues/907
    final int? pid = vmInfo.pid;
    if (pid != null) {
      pidsToTerminate.add(pid);
    }
  }

  /// Called by [disconnectRequest] to request that we forcefully shut down the app being run (or in the case of an attach, disconnect).
  ///
  /// Client IDEs/editors should send a terminateRequest before a
  /// disconnectRequest to allow a graceful shutdown. This method must terminate
  /// quickly and therefore may leave orphaned processes.
  @override
  Future<void> disconnectImpl() async {
    terminatePids(ProcessSignal.sigkill);
  }

  @override
  Future<void> handleExtensionEvent(vm.Event event) async {
    await super.handleExtensionEvent(event);

    switch (event.kind) {
      case vm.EventKind.kExtension:
        switch (event.extensionKind) {
          case 'Flutter.ServiceExtensionStateChanged':
            _sendServiceExtensionStateChanged(event.extensionData);
            break;
        }
        break;
    }
  }

  /// Called by [launchRequest] to request that we actually start the app to be run/debugged.
  ///
  /// For debugging, this should start paused, connect to the VM Service, set
  /// breakpoints, and resume.
  @override
  Future<void> launchImpl() async {
    final FlutterLaunchRequestArguments args = this.args as FlutterLaunchRequestArguments;

    // "debug"/"noDebug" refers to the DAP "debug" mode and not the Flutter
    // debug mode (vs Profile/Release). It is possible for the user to "Run"
    // from VS Code (eg. not want to hit breakpoints/etc.) but still be running
    // a debug build.
    final bool debug = !(args.noDebug ?? false);
    final String? program = args.program;

    final List<String> toolArgs = <String>[
      'run',
      '--machine',
      if (debug) '--start-paused',
    ];

    // Handle customTool and deletion of any arguments for it.
    final String executable = args.customTool ?? fileSystem.path.join(Cache.flutterRoot!, 'bin', platform.isWindows ? 'flutter.bat' : 'flutter');
    final int? removeArgs = args.customToolReplacesArgs;
    if (args.customTool != null && removeArgs != null) {
      toolArgs.removeRange(0, math.min(removeArgs, toolArgs.length));
    }

    final List<String> processArgs = <String>[
      ...toolArgs,
      ...?args.toolArgs,
      if (program != null) ...<String>[
        '--target',
        program,
      ],
      ...?args.args,
    ];

    // Find the package_config file for this script. This is used by the
    // debugger to map package: URIs to file paths to check whether they're in
    // the editors workspace (args.cwd/args.additionalProjectPaths) so they can
    // be correctly classes as "my code", "sdk" or "external packages".
    // TODO(dantup): Remove this once https://github.com/dart-lang/sdk/issues/45530
    // is done as it will not be necessary.
    final String? possibleRoot = program == null
        ? args.cwd
        : fileSystem.path.isAbsolute(program)
            ? fileSystem.path.dirname(program)
            : fileSystem.path.dirname(
                fileSystem.path.normalize(fileSystem.path.join(args.cwd ?? '', args.program)));
    if (possibleRoot != null) {
      final File? packageConfig = findPackageConfigFile(possibleRoot);
      if (packageConfig != null) {
        usePackageConfigFile(packageConfig);
      }
    }

    await launchAsProcess(executable, processArgs);

    // Delay responding until the app is launched and (optionally) the debugger
    // is connected.
    await appStartedCompleter.future;
    if (debug) {
      await debuggerInitialized;
    }
  }

  @visibleForOverriding
  Future<void> launchAsProcess(String executable, List<String> processArgs) async {
    logger?.call('Spawning $executable with $processArgs in ${args.cwd}');
    final Process process = await Process.start(
      executable,
      processArgs,
      workingDirectory: args.cwd,
    );
    _process = process;
    pidsToTerminate.add(process.pid);

    process.stdout.transform(ByteToLineTransformer()).listen(_handleStdout);
    process.stderr.listen(_handleStderr);
    unawaited(process.exitCode.then(_handleExitCode));
  }

  /// restart is called by the client when the user invokes a restart (for example with the button on the debug toolbar).
  ///
  /// For Flutter, we handle this ourselves be sending a Hot Restart request
  /// to the running app.
  @override
  Future<void> restartRequest(
    Request request,
    RestartArguments? args,
    void Function() sendResponse,
  ) async {
    await _performRestart(true);

    sendResponse();
  }

  /// Sends a request to the Flutter daemon that is running/attaching to the app and waits for a response.
  ///
  /// If [failSilently] is `true` (the default) and there is no process, the
  /// message will be silently ignored (this is common during the application
  /// being stopped, where async messages may be processed). Setting it to
  /// `false` will cause a [DebugAdapterException] to be thrown in that case.
  Future<Object?> sendFlutterRequest(
    String method,
    Map<String, Object?>? params, {
    bool failSilently = true,
  }) async {
    final Process? process = _process;

    if (process == null) {
      if (failSilently) {
        return null;
      } else {
        throw DebugAdapterException(
          'Unable to Restart because Flutter process is not available',
        );
      }
    }

    final Completer<Object?> completer = Completer<Object?>();
    final int id = _flutterRequestId++;
    _flutterRequestCompleters[id] = completer;

    // Flutter requests are always wrapped in brackets as an array.
    final String messageString = jsonEncode(
      <String, Object?>{'id': id, 'method': method, 'params': params},
    );
    final String payload = '[$messageString]\n';

    process.stdin.writeln(payload);

    return completer.future;
  }

  /// Called by [terminateRequest] to request that we gracefully shut down the app being run (or in the case of an attach, disconnect).
  @override
  Future<void> terminateImpl() async {
    terminatePids(ProcessSignal.sigterm);
    await _process?.exitCode;
  }

  /// Connects to the VM Service if the app.started event has fired, and a VM Service URI is available.
  void _connectDebuggerIfReady() {
    final Uri? serviceUri = _vmServiceUri;
    if (_receivedAppStarted && serviceUri != null) {
      connectDebugger(serviceUri, resumeIfStarting: true);
    }
  }

  /// Handles the app.start event from Flutter.
  void _handleAppStart(Map<String, Object?> params) {
    _appId = params['appId'] as String?;
    assert(_appId != null);
  }

  /// Handles the app.started event from Flutter.
  void _handleAppStarted() {
    appStartedCompleter.complete();
    _connectDebuggerIfReady();
  }

  /// Handles the app.debugPort event from Flutter, connecting to the VM Service if everything else is ready.
  void _handleDebugPort(Map<String, Object?> params) {
    // When running in noDebug mode, Flutter may still provide us a VM Service
    // URI, but we will not connect it because we don't want to do any debugging.
    final FlutterLaunchRequestArguments args = this.args as FlutterLaunchRequestArguments;
    final bool debug = !(args.noDebug ?? false);
    if (!debug) {
      return;
    }

    // Capture the VM Service URL which we'll connect to when we get app.started.
    final String? wsUri = params['wsUri'] as String?;
    if (wsUri != null) {
      _vmServiceUri = Uri.parse(wsUri);
    }
    _connectDebuggerIfReady();
  }

  /// Handles the Flutter process exiting, terminating the debug session if it has not already begun terminating.
  void _handleExitCode(int code) {
    final String codeSuffix = code == 0 ? '' : ' ($code)';
    logger?.call('Process exited ($code)');
    handleSessionTerminate(codeSuffix);
  }

  /// Handles incoming JSON events from `flutter run --machine`.
  void _handleJsonEvent(String event, Map<String, Object?>? params) {
    params ??= <String, Object?>{};
    switch (event) {
      case 'app.debugPort':
        _handleDebugPort(params);
        break;
      case 'app.start':
        _handleAppStart(params);
        break;
      case 'app.started':
        _handleAppStarted();
        break;
    }
  }

  /// Handles incoming JSON messages from `flutter run --machine` that are responses to requests that we sent.
  void _handleJsonResponse(int id, Map<String, Object?> response) {
    final Completer<Object?>? handler = _flutterRequestCompleters.remove(id);
    if (handler == null) {
      logger?.call(
        'Received response from Flutter run daemon with ID $id '
        'but had not matching handler',
      );
      return;
    }

    final Object? error = response['error'];
    final Object? result = response['result'];
    if (error != null) {
      handler.completeError(DebugAdapterException('$error'));
    } else {
      handler.complete(result);
    }
  }

  void _handleStderr(List<int> data) {
    logger?.call('stderr: $data');
    sendOutput('stderr', utf8.decode(data));
  }

  /// Handles stdout from the `flutter run --machine` process, decoding the JSON and calling the appropriate handlers.
  void _handleStdout(String data) {
    // Output intended for us to parse is JSON wrapped in brackets:
    // [{"event":"app.foo","params":{"bar":"baz"}}]
    // However, it's also possible a user printed things that look a little like
    // this so try to detect only things we're interested in:
    // - parses as JSON
    // - is a List of only a single item that is a Map<String, Object?>
    // - the item has an "event" field that is a String
    // - the item has a "params" field that is a Map<String, Object?>?

    logger?.call('stdout: $data');

    // Output is sent as console (eg. output from tooling) until the app has
    // started, then stdout (users output). This is so info like
    // "Launching lib/main.dart on Device foo" is formatted differently to
    // general output printed by the user.
    final String outputCategory = _receivedAppStarted ? 'stdout' : 'console';

      // Output in stdout can include both user output (eg. print) and Flutter
      // daemon output. Since it's not uncommon for users to print JSON while
      // debugging, we must try to detect which messages are likely Flutter
      // messages as reliably as possible, as trying to process users output
      // as a Flutter message may result in an unhandled error that will
      // terminate the debug adater in a way that does not provide feedback
      // because the standard crash violates the DAP protocol.
    Object? jsonData;
    try {
      jsonData = jsonDecode(data);
    } on FormatException {
      // If the output wasn't valid JSON, it was standard stdout that should
      // be passed through to the user.
      sendOutput(outputCategory, data);
      return;
    }

    final Map<String, Object?>? payload = jsonData is List &&
            jsonData.length == 1 &&
            jsonData.first is Map<String, Object?>
        ? jsonData.first as Map<String, Object?>
        : null;

    if (payload == null) {
      // JSON didn't match expected format for Flutter responses, so treat as
      // standard user output.
      sendOutput(outputCategory, data);
      return;
    }

    final Object? event = payload['event'];
    final Object? params = payload['params'];
    final Object? id = payload['id'];
    if (event is String && params is Map<String, Object?>?) {
      _handleJsonEvent(event, params);
    } else if (id is int && _flutterRequestCompleters.containsKey(id)) {
      _handleJsonResponse(id, payload);
    } else {
      // If it wasn't processed above,
      sendOutput(outputCategory, data);
    }
  }

  /// Performs a restart/reload by sending the `app.restart` message to the `flutter run --machine` process.
  Future<void> _performRestart(
    bool fullRestart, [
    String? reason,
  ]) async {
    final DartCommonLaunchAttachRequestArguments args = this.args;
    final bool debug =
        args is! FlutterLaunchRequestArguments || args.noDebug != true;
    try {
      await sendFlutterRequest('app.restart', <String, Object?>{
        'appId': _appId,
        'fullRestart': fullRestart,
        'pause': debug,
        'reason': reason,
        'debounce': true,
      });
    } on DebugAdapterException catch (error) {
      final String action = fullRestart ? 'Hot Restart' : 'Hot Reload';
      sendOutput('console', 'Failed to $action: $error');
    }
  }

  void _sendServiceExtensionStateChanged(vm.ExtensionData? extensionData) {
    final Map<String, dynamic>? data = extensionData?.data;
    if (data != null) {
      sendEvent(
        RawEventBody(data),
        eventType: 'flutter.serviceExtensionStateChanged',
      );
    }
  }
}
