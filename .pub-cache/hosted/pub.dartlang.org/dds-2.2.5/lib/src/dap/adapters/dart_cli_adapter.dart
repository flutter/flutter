// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:path/path.dart' as path;
import 'package:vm_service/vm_service.dart' as vm;

import '../logging.dart';
import '../protocol_generated.dart';
import '../protocol_stream.dart';
import 'dart.dart';
import 'mixins.dart';

/// A DAP Debug Adapter for running and debugging Dart CLI scripts.
class DartCliDebugAdapter extends DartDebugAdapter<DartLaunchRequestArguments,
        DartAttachRequestArguments>
    with PidTracker, VmServiceInfoFileUtils, PackageConfigUtils {
  Process? _process;

  @override
  final parseLaunchArgs = DartLaunchRequestArguments.fromJson;

  @override
  final parseAttachArgs = DartAttachRequestArguments.fromJson;

  DartCliDebugAdapter(
    ByteStreamServerChannel channel, {
    bool ipv6 = false,
    bool enableDds = true,
    bool enableAuthCodes = true,
    Logger? logger,
    Function? onError,
  }) : super(
          channel,
          ipv6: ipv6,
          enableDds: enableDds,
          enableAuthCodes: enableAuthCodes,
          logger: logger,
          onError: onError,
        );

  /// Whether the VM Service closing should be used as a signal to terminate the
  /// debug session.
  ///
  /// If we have a process, we will instead use its termination as a signal to
  /// terminate the debug session. Otherwise, we will use the VM Service close.
  bool get terminateOnVmServiceClose => _process == null;

  Future<void> debuggerConnected(vm.VM vmInfo) async {
    if (!isAttach) {
      // Capture the PID from the VM Service so that we can terminate it when
      // cleaning up. Terminating the process might not be enough as it could be
      // just a shell script (e.g. pub on Windows) and may not pass the
      // signal on correctly.
      // See: https://github.com/Dart-Code/Dart-Code/issues/907
      final pid = vmInfo.pid;
      if (pid != null) {
        pidsToTerminate.add(pid);
      }
    }
  }

  /// Called by [disconnectRequest] to request that we forcefully shut down the
  /// app being run (or in the case of an attach, disconnect).
  Future<void> disconnectImpl() async {
    if (isAttach) {
      await preventBreakingAndResume();
    }
    terminatePids(ProcessSignal.sigkill);
  }

  /// Checks whether [flag] is in [args], allowing for both underscore and
  /// dash format.
  bool _containsVmFlag(List<String> args, String flag) {
    final flagUnderscores = flag.replaceAll('-', '_');
    final flagDashes = flag.replaceAll('_', '-');
    return args.contains(flagUnderscores) || args.contains(flagDashes);
  }

  /// Called by [launchRequest] to request that we actually start the app to be
  /// run/debugged.
  ///
  /// For debugging, this should start paused, connect to the VM Service, set
  /// breakpoints, and resume.
  Future<void> launchImpl() async {
    final args = this.args as DartLaunchRequestArguments;
    File? vmServiceInfoFile;

    final debug = !(args.noDebug ?? false);
    if (debug) {
      vmServiceInfoFile = generateVmServiceInfoFile();
      unawaited(waitForVmServiceInfoFile(logger, vmServiceInfoFile)
          .then((uri) => connectDebugger(uri)));
    }

    final vmArgs = <String>[
      ...?args.vmAdditionalArgs,
      if (debug) ...[
        '--enable-vm-service=${args.vmServicePort ?? 0}${ipv6 ? '/::1' : ''}',
        '--pause_isolates_on_start',
        if (!enableAuthCodes) '--disable-service-auth-codes'
      ],
      '--disable-dart-dev',
      if (debug && vmServiceInfoFile != null) ...[
        '-DSILENT_OBSERVATORY=true',
        '--write-service-info=${Uri.file(vmServiceInfoFile.path)}'
      ],
    ];

    final toolArgs = args.toolArgs ?? [];
    if (debug) {
      // If the user has explicitly set pause-isolates-on-exit we need to
      // not add it ourselves, and disable auto-resuming.
      if (_containsVmFlag(toolArgs, '--pause_isolates_on_exit')) {
        resumeIsolatesAfterPauseExit = false;
      } else {
        vmArgs.add('--pause_isolates_on_exit');
      }
    }

    // Handle customTool and deletion of any arguments for it.
    final executable = args.customTool ?? Platform.resolvedExecutable;
    final removeArgs = args.customToolReplacesArgs;
    if (args.customTool != null && removeArgs != null) {
      vmArgs.removeRange(0, math.min(removeArgs, vmArgs.length));
    }

    final processArgs = [
      ...vmArgs,
      ...toolArgs,
      args.program,
      ...?args.args,
    ];

    // If the client supports runInTerminal and args.console is set to either
    // 'terminal' or 'runInTerminal' we won't run the process ourselves, but
    // instead call the client to run it for us (this allows it to run in a
    // terminal where the user can interact with `stdin`).
    final canRunInTerminal =
        initializeArgs?.supportsRunInTerminalRequest ?? false;

    // The terminal kinds used by DAP are 'integrated' and 'external'.
    final terminalKind = canRunInTerminal
        ? args.console == 'terminal'
            ? 'integrated'
            : args.console == 'externalTerminal'
                ? 'external'
                : null
        : null;

    if (terminalKind != null) {
      await launchInEditorTerminal(
        debug,
        terminalKind,
        executable,
        processArgs,
        workingDirectory: args.cwd,
        env: args.env,
      );
    } else {
      await launchAsProcess(
        executable,
        processArgs,
        workingDirectory: args.cwd,
        env: args.env,
      );
    }
  }

  /// Called by [attachRequest] to request that we actually connect to the app
  /// to be debugged.
  Future<void> attachImpl() async {
    final args = this.args as DartAttachRequestArguments;
    final vmServiceUri = args.vmServiceUri;
    final vmServiceInfoFile = args.vmServiceInfoFile;

    if ((vmServiceUri == null) == (vmServiceInfoFile == null)) {
      sendOutput(
        'console',
        '\nTo attach, provide exactly one of vmServiceUri/vmServiceInfoFile',
      );
      handleSessionTerminate();
      return;
    }

    final uri = vmServiceUri != null
        ? Uri.parse(vmServiceUri)
        : await waitForVmServiceInfoFile(logger, File(vmServiceInfoFile!));

    unawaited(connectDebugger(uri));
  }

  /// Calls the client (via a `runInTerminal` request) to spawn the process so
  /// that it can run in a local terminal that the user can interact with.
  Future<void> launchInEditorTerminal(
    bool debug,
    String terminalKind,
    String executable,
    List<String> processArgs, {
    required String? workingDirectory,
    required Map<String, String>? env,
  }) async {
    final args = this.args as DartLaunchRequestArguments;
    logger?.call('Spawning $executable with $processArgs in $workingDirectory'
        ' via client ${terminalKind} terminal');

    // runInTerminal is a DAP request that goes from server-to-client that
    // allows the DA to ask the client editor to run the debugee for us. In this
    // case we will have no access to the process (although we get the PID) so
    // for debugging will rely on the process writing the service-info file that
    // we can detect with the normal watching code.
    final requestArgs = RunInTerminalRequestArguments(
      args: [executable, ...processArgs],
      cwd: workingDirectory ?? path.dirname(args.program),
      env: env,
      kind: terminalKind,
      title: args.name ?? 'Dart',
    );
    try {
      final response = await sendRequest(requestArgs);
      final body =
          RunInTerminalResponseBody.fromJson(response as Map<String, Object?>);
      logger?.call(
        'Client spawned process'
        ' (proc: ${body.processId}, shell: ${body.shellProcessId})',
      );
    } catch (e) {
      logger?.call('Client failed to spawn process $e');
      sendOutput('console', '\nFailed to spawn process: $e');
      handleSessionTerminate();
    }

    // When using `runInTerminal` and `noDebug`, we will not connect to the VM
    // Service so we will have no way of knowing when the process completes, so
    // we just send the termination event right away.
    if (!debug) {
      handleSessionTerminate();
    }
  }

  /// Launches the program as a process controlled by the debug adapter.
  ///
  /// Output to `stdout`/`stderr` will be sent to the editor using
  /// [OutputEvent]s.
  Future<void> launchAsProcess(
    String executable,
    List<String> processArgs, {
    required String? workingDirectory,
    required Map<String, String>? env,
  }) async {
    logger?.call('Spawning $executable with $processArgs in $workingDirectory');
    final process = await Process.start(
      executable,
      processArgs,
      workingDirectory: workingDirectory,
      environment: env,
    );
    _process = process;
    pidsToTerminate.add(process.pid);

    process.stdout.listen(_handleStdout);
    process.stderr.listen(_handleStderr);
    unawaited(process.exitCode.then(_handleExitCode));
  }

  /// Called by [terminateRequest] to request that we gracefully shut down the
  /// app being run (or in the case of an attach, disconnect).
  Future<void> terminateImpl() async {
    if (isAttach) {
      await preventBreakingAndResume();
    }
    terminatePids(ProcessSignal.sigterm);
    await _process?.exitCode;
  }

  void _handleExitCode(int code) {
    final codeSuffix = code == 0 ? '' : ' ($code)';
    logger?.call('Process exited ($code)');
    handleSessionTerminate(codeSuffix);
  }

  void _handleStderr(List<int> data) {
    sendOutput('stderr', utf8.decode(data));
  }

  void _handleStdout(List<int> data) {
    sendOutput('stdout', utf8.decode(data));
  }
}
