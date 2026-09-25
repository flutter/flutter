// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:dap_adapters/dap_adapters.dart' hide PidTracker;
import 'package:vm_service/vm_service.dart' as vm;

import '../base/file_system.dart';
import '../base/io.dart';
import '../base/platform.dart';
import '../base/utils.dart';
import '../cache.dart';
import '../convert.dart';
import 'flutter_adapter_args.dart';
import 'mixins.dart';

/// A base DAP Debug Adapter for Flutter applications and tests.
abstract class FlutterBaseDebugAdapter
    extends DartDebugAdapter<FlutterLaunchRequestArguments, FlutterAttachRequestArguments>
    with PidTracker {
  FlutterBaseDebugAdapter(
    super.channel, {
    required this.fileSystem,
    required this.platform,
    super.ipv6,
    this.enableFlutterDds = true,
    super.enableAuthCodes,
    super.logger,
    super.onError,
  }) : flutterSdkRoot = Cache.flutterRoot! {
    configureOrgDartlangSdkMappings();
  }

  FileSystem fileSystem;
  Platform platform;
  Process? process;

  final String flutterSdkRoot;

  /// Whether DDS should be enabled in the Flutter process.
  ///
  /// We never enable DDS in the DAP process for Flutter, so this value is not
  /// the same as what is passed to the base class, which is always provided 'false'.
  final bool enableFlutterDds;

  /// Whether the adapter is currently waiting for the debugger to initialize.
  bool waitingForDebugger = false;

  /// A completer that completes with an error if debugger initialization fails
  /// (for example, if the session terminates early).
  ///
  /// A dummy error handler is attached to the future to prevent unhandled
  /// asynchronous exceptions if it completes before any listeners are active.
  final Completer<void> debuggerInitializationFailedCompleter = Completer<void>()
    ..future.then<void>((_) {}, onError: (Object _) {});

  @override
  void handleSessionTerminate([String exitSuffix = '']) {
    isTerminating = true;
    if (waitingForDebugger && !debuggerInitializationFailedCompleter.isCompleted) {
      final String suffix = exitSuffix.trim();
      final message = suffix.isNotEmpty
          ? 'Session terminated before debugger initialized: $suffix'
          : 'Session terminated before debugger initialized';
      debuggerInitializationFailedCompleter.completeError(DebugAdapterException(message));
    }
    super.handleSessionTerminate(exitSuffix);
  }

  @override
  final FlutterLaunchRequestArguments Function(Map<String, Object?> obj) parseLaunchArgs =
      FlutterLaunchRequestArguments.fromJson;

  @override
  final FlutterAttachRequestArguments Function(Map<String, Object?> obj) parseAttachArgs =
      FlutterAttachRequestArguments.fromJson;

  /// Whether the VM Service closing should be used as a signal to terminate the debug session.
  ///
  /// Since we always have a process for Flutter (whether run or attach) we'll
  /// always use its termination instead, so this is always false.
  @override
  bool get terminateOnVmServiceClose => false;

  /// Whether or not the user requested debugging be enabled.
  ///
  /// For debugging to be enabled, the user must have chosen "Debug" (and not
  /// "Run") in the editor (which maps to the DAP `noDebug` field).
  bool get enableDebugger {
    final DartCommonLaunchAttachRequestArguments args = this.args;
    if (args is FlutterLaunchRequestArguments) {
      // Invert DAP's noDebug flag, treating it as false (so _do_ debug) if not
      // provided.
      return !(args.noDebug ?? false);
    }

    // Otherwise (attach), always debug.
    return true;
  }

  void configureOrgDartlangSdkMappings() {
    /// When a user navigates into 'dart:xxx' sources in their editor (via the
    /// analysis server) they will land in flutter_sdk/bin/cache/pkg/sky_engine.
    ///
    /// The running VM knows nothing about these paths and will resolve these
    /// libraries to 'org-dartlang-sdk://' URIs. We need to map between these
    /// to ensure that if a user puts a breakpoint inside sky_engine the VM can
    /// apply it to the correct place and once hit, we can navigate the user
    /// back to the correct file on their disk.
    ///
    /// The mapping is handled by the base adapter but we need to override the
    /// paths to match the layout used by Flutter.
    ///
    /// In future this might become unnecessary if
    /// https://github.com/dart-lang/sdk/issues/48435 is implemented. Until
    /// then, providing these mappings improves the debugging experience.

    // Clear original Dart SDK mappings because they're not valid here.
    orgDartlangSdkMappings.clear();

    // 'dart:ui' maps to /flutter/lib/ui
    final String flutterRoot = fileSystem.path.join(
      flutterSdkRoot,
      'bin',
      'cache',
      'pkg',
      'sky_engine',
      'lib',
      'ui',
    );
    orgDartlangSdkMappings[flutterRoot] = Uri.parse('org-dartlang-sdk:///flutter/lib/ui');

    // The rest of the Dart SDK maps to /flutter/third_party/dart/sdk
    final String dartRoot = fileSystem.path.join(
      flutterSdkRoot,
      'bin',
      'cache',
      'pkg',
      'sky_engine',
    );
    orgDartlangSdkMappings[dartRoot] = Uri.parse(
      'org-dartlang-sdk:///flutter/third_party/dart/sdk',
    );
  }

  static const _isolateReadyTimeout = Duration(seconds: 5);
  static const _isolateReadyPollInterval = Duration(milliseconds: 10);

  @override
  Future<void> debuggerConnected(vm.VM vmInfo) async {
    // Usually we'd capture the pid from the VM here and record it for
    // terminating, however for Flutter apps it may be running on a remote
    // device so it's not valid to terminate a process with that pid locally.
    // For attach, pids should never be collected as terminateRequest() should
    // not terminate the debugger.
    final vm.VmService? service = vmService;
    if (service != null && enableDebugger) {
      await _waitForIsolatesReady(service, vmInfo);
    }
  }

  /// Waits for existing isolates in [vmInfo] to become runnable and, when
  /// launching with `--start-paused` (`!isAttach`), to reach their initial
  /// pause state before `DartDebugAdapter._configureExistingIsolates` runs.
  ///
  /// On macOS, `FlutterTesterTestDevice` can emit `test.startedProcess` while
  /// the `main` isolate is still transitioning from `IsolateStart`
  /// (`runnable: false, pauseEvent: None`) through `IsolateRunnable`
  /// (`runnable: true, pauseEvent: None`) to `PauseStart`. If
  /// `_configureExistingIsolates` queries `getIsolate` during that window:
  /// 1. Seeing `runnable: false` registers the isolate with `kIsolateStart`,
  ///    leaving `IsolateManager._isolateRegistrations` uncompleted if
  ///    `IsolateRunnable` was already emitted before `streamListen('Isolate')`,
  ///    which deadlocks `handleEvent(PauseStart)`.
  /// 2. Seeing `runnable: true` with `pauseEvent: None` triggers an immediate
  ///    `readyToResumeThread` call before the isolate reaches `PauseStart`,
  ///    causing DDS to clear its resume approvals prematurely and leave the
  ///    isolate permanently paused at `PauseStart`.
  Future<void> _waitForIsolatesReady(vm.VmService service, vm.VM vmInfo) async {
    final stopwatch = Stopwatch()..start();
    try {
      final vm.VM latestVm = await service.getVM();
      vmInfo.isolates = latestVm.isolates;
    } on vm.RPCError {
      // Fall back to the initial vmInfo snapshot if refreshing fails.
    }

    final List<vm.IsolateRef>? isolateRefs = vmInfo.isolates;
    if (isolateRefs == null || isolateRefs.isEmpty) {
      return;
    }

    for (final vm.IsolateRef isolateRef in isolateRefs) {
      final String? isolateId = isolateRef.id;
      if (isolateId == null) {
        continue;
      }
      while (stopwatch.elapsed < _isolateReadyTimeout && !isTerminating) {
        try {
          final vm.Isolate isolate = await service.getIsolate(isolateId);
          final bool isRunnable = isolate.runnable ?? false;
          final String? pauseKind = isolate.pauseEvent?.kind;
          final bool isPausedOrAttach =
              isAttach || (pauseKind != null && pauseKind != vm.EventKind.kNone);
          if (isRunnable && isPausedOrAttach) {
            break;
          }
        } on vm.SentinelException {
          break;
        } on vm.RPCError {
          break;
        }
        await Future<void>.delayed(_isolateReadyPollInterval);
      }
    }
  }

  /// Ensures that any existing isolates whose startup was already handled by
  /// [isolateManager] are not left stuck at [vm.EventKind.kPauseStart].
  ///
  /// In `package:dds`, `IsolateManager.initialize()` issues an unawaited
  /// `getIsolate` request on startup that can race with `PauseStart` and
  /// overwrite the isolate's pause state in DDS, causing `readyToResume` to
  /// return `Success` without forwarding `resume` to the VM.
  Future<void> ensureIsolatesResumedFromPauseStart() async {
    final vm.VmService? service = vmService;
    if (service == null || !enableDebugger || isAttach || isTerminating) {
      return;
    }
    try {
      final vm.VM currentVm = await service.getVM();
      final List<vm.IsolateRef>? isolateRefs = currentVm.isolates;
      if (isolateRefs == null) {
        return;
      }
      for (final vm.IsolateRef isolateRef in isolateRefs) {
        final String? isolateId = isolateRef.id;
        if (isolateId == null) {
          continue;
        }
        try {
          final vm.Isolate isolate = await service.getIsolate(isolateId);
          if (isolate.pauseEvent?.kind != vm.EventKind.kPauseStart) {
            continue;
          }
          final bool? startupHandled = isolateManager.threadForIsolate(isolate)?.startupHandled;
          if (startupHandled == null) {
            continue;
          }
          if (!startupHandled) {
            await isolateManager.handleEvent(isolate.pauseEvent!);
          }
          final vm.Isolate refreshedIsolate = await service.getIsolate(isolateId);
          if (refreshedIsolate.pauseEvent?.kind == vm.EventKind.kPauseStart) {
            logger?.call(
              'Isolate $isolateId remained at PauseStart after readyToResume; '
              'sending explicit resume.',
            );
            await service.resume(isolateId);
          }
        } on vm.SentinelException {
          // Isolate exited.
        } on vm.RPCError {
          // Ignore RPC errors if the isolate was concurrently resumed.
        }
      }
    } on vm.RPCError {
      // Ignore VM Service connection errors during shutdown.
    }
  }

  /// Called by [disconnectRequest] to request that we forcefully shut down the app being run (or in the case of an attach, disconnect).
  ///
  /// Client IDEs/editors should send a terminateRequest before a
  /// disconnectRequest to allow a graceful shutdown. This method must terminate
  /// quickly and therefore may leave orphaned processes.
  @override
  Future<void> disconnectImpl() async {
    if (isAttach) {
      await handleDetach();
    }
    terminatePids(ProcessSignal.sigkill);
  }

  Future<void> launchAsProcess({
    required String executable,
    required List<String> processArgs,
    required Map<String, String>? env,
  }) async {
    final Process process =
        await (
          String executable,
          List<String> processArgs, {
          required Map<String, String>? env,
        }) async {
          logger?.call('Spawning $executable with $processArgs in ${args.cwd}');
          final Process process = await Process.start(
            executable,
            processArgs,
            workingDirectory: args.cwd,
            environment: env,
          );
          pidsToTerminate.add(process.pid);
          return process;
        }(executable, processArgs, env: env);
    this.process = process;

    process.stdout.transformWithCallSite(ByteToLineTransformer()).listen(handleStdout);
    // Use permissive decoder for debugger stderr which may contain invalid UTF-8
    process.stderr.transformWithCallSite(utf8AllowMalformed.decoder).listen(handleStderr);
    unawaited(process.exitCode.then(handleExitCode));
  }

  void handleExitCode(int code);
  void handleStderr(String data);
  void handleStdout(String data);
}
