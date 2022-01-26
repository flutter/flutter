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

/// A DAP Debug Adapter for running and debugging Flutter tests.
class FlutterTestDebugAdapter extends DartDebugAdapter<FlutterLaunchRequestArguments, FlutterAttachRequestArguments>
    with PidTracker, PackageConfigUtils, TestAdapter {
  FlutterTestDebugAdapter(
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

  /// Whether the VM Service closing should be used as a signal to terminate the debug session.
  ///
  /// Since we do not support attaching for tests, this is always false.
  @override
  bool get terminateOnVmServiceClose => false;

  /// Called by [attachRequest] to request that we actually connect to the app to be debugged.
  @override
  Future<void> attachImpl() async {
    sendOutput('console', '\nAttach is not currently supported');
    handleSessionTerminate();
  }

  @override
  Future<void> debuggerConnected(vm.VM vmInfo) async {
    // Capture the PID from the VM Service so that we can terminate it when
    // cleaning up. Terminating the process might not be enough as it could be
    // just a shell script (e.g. pub on Windows) and may not pass the
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

  /// Called by [launchRequest] to request that we actually start the tests to be run/debugged.
  ///
  /// For debugging, this should start paused, connect to the VM Service, set
  /// breakpoints, and resume.
  @override
  Future<void> launchImpl() async {
    final FlutterLaunchRequestArguments args = this.args as FlutterLaunchRequestArguments;

    final bool debug = !(args.noDebug ?? false);
    final String? program = args.program;

    final List<String> toolArgs = <String>[
      'test',
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
      if (program != null) program,
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

    // Delay responding until the debugger is connected.
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

  /// Called by [terminateRequest] to request that we gracefully shut down the app being run (or in the case of an attach, disconnect).
  @override
  Future<void> terminateImpl() async {
    terminatePids(ProcessSignal.sigterm);
    await _process?.exitCode;
  }

  /// Handles the Flutter process exiting, terminating the debug session if it has not already begun terminating.
  void _handleExitCode(int code) {
    final String codeSuffix = code == 0 ? '' : ' ($code)';
    logger?.call('Process exited ($code)');
    handleSessionTerminate(codeSuffix);
  }

  /// Handles incoming JSON events from `flutter test --machine`.
  bool _handleJsonEvent(String event, Map<String, Object?>? params) {
    params ??= <String, Object?>{};
    switch (event) {
      case 'test.startedProcess':
        _handleTestStartedProcess(params);
        return true;
    }

    return false;
  }

  void _handleStderr(List<int> data) {
    logger?.call('stderr: $data');
    sendOutput('stderr', utf8.decode(data));
  }

  /// Handles stdout from the `flutter test --machine` process, decoding the JSON and calling the appropriate handlers.
  void _handleStdout(String data) {
    // Output to stdout from `flutter test --machine` is either:
    //   1. JSON output from flutter_tools (eg. "test.startedProcess") which is
    //      wrapped in [] brackets and has an event/params.
    //   2. JSON output from package:test (not wrapped in brackets).
    //   3. Non-JSON output (user messages, or flutter_tools printing things like
    //      call stacks/error information).
    logger?.call('stdout: $data');

    Object? jsonData;
    try {
      jsonData = jsonDecode(data);
    } on FormatException {
      // If the output wasn't valid JSON, it was standard stdout that should
      // be passed through to the user.
      sendOutput('stdout', data);
      return;
    }

    // Check for valid flutter_tools JSON output (1) first.
    final Map<String, Object?>? flutterPayload = jsonData is List &&
            jsonData.length == 1 &&
            jsonData.first is Map<String, Object?>
        ? jsonData.first as Map<String, Object?>
        : null;
    final Object? event = flutterPayload?['event'];
    final Object? params = flutterPayload?['params'];

    if (event is String && params is Map<String, Object?>?) {
      _handleJsonEvent(event, params);
    } else if (jsonData != null) {
      // Handle package:test output (2).
      sendTestEvents(jsonData);
    } else {
      // Other output should just be passed straight through.
      sendOutput('stdout', data);
    }
  }

  /// Handles the test.processStarted event from Flutter that provides the VM Service URL.
  void _handleTestStartedProcess(Map<String, Object?> params) {
    final String? vmServiceUriString = params['observatoryUri'] as String?;
    // For no-debug mode, this event is still sent, but has a null URI.
    if (vmServiceUriString == null) {
      return;
    }
    final Uri vmServiceUri = Uri.parse(vmServiceUriString);
    connectDebugger(vmServiceUri, resumeIfStarting: true);
  }
}
