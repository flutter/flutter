// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:process/process.dart';

import '../base/common.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/process.dart';
import '../convert.dart';
import 'devices.dart';

/// Wraps idevicedebug command line tool to interact with the device's debug server.
///
/// See https://github.com/libimobiledevice/libimobiledevice.
class IDeviceDebug {
  IDeviceDebug({
    @required String iDeviceDebugPath,
    @required Logger logger,
    @required ProcessManager processManager,
    @required MapEntry<String, String> dyLdLibEntry,
  }) : _dyLdLibEntry = dyLdLibEntry,
        _logger = logger,
        _processUtils = ProcessUtils(processManager: processManager, logger: logger),
        _iDeviceDebugPath = iDeviceDebugPath;

  /// Create a [IDeviceDebug] for testing.
  ///
  /// This specifies the path to idevicedebug as 'idevicedebug` and the dyLdLibEntry as
  /// 'DYLD_LIBRARY_PATH: /path/to/libs'.
  factory IDeviceDebug.test({
    @required Logger logger,
    @required ProcessManager processManager,
  }) {
    return IDeviceDebug(
      iDeviceDebugPath: 'idevicedebug',
      logger: logger,
      processManager: processManager,
      dyLdLibEntry: const MapEntry<String, String>(
        'DYLD_LIBRARY_PATH', '/path/to/libs',
      ),
    );
  }

  final String _iDeviceDebugPath;
  final ProcessUtils _processUtils;
  final Logger _logger;
  final MapEntry<String, String> _dyLdLibEntry;

  Future<IDeviceDebugRun> runApp({
    @required String deviceId,
    @required String bundleIdentifier,
    @required List<String> launchArguments,
    @required IOSDeviceInterface interfaceType,
  }) async {
    // Run in interactive mode (via script) to convince
    // idevicedebug it has a terminal attached to redirect stdout.
    final List<String> launchCommand = <String>[
      'script',
      '-t',
      '0',
      '/dev/null',
      _iDeviceDebugPath,
      '--udid',
      deviceId,
      '--debug',
      if (interfaceType == IOSDeviceInterface.network)
        '--network',
      'run',
      bundleIdentifier,
      // Arguments after "run bundle-id" are launch arguments.
      if (launchArguments.isNotEmpty)
        ...launchArguments,
    ];

    final Process iDeviceDebugProcess = await _processUtils.start(
      launchCommand,
      environment: Map<String, String>.fromEntries(
        <MapEntry<String, String>>[_dyLdLibEntry],
      ),
    );

    final Completer<int> debuggerCompleter = Completer<int>();

    final StreamSubscription<String> stdoutSubscription = iDeviceDebugProcess.stdout
        .transform<String>(utf8.decoder)
        .transform<String>(const LineSplitter())
        .listen((String line) {
      _logger.printTrace('idevicedebug: $line');
      if (line.contains('Entering run loop')) {
        // The app successfully launched.
        debuggerCompleter.complete(0);
      }
    });
    final StreamSubscription<String> stderrSubscription = iDeviceDebugProcess.stderr
        .transform<String>(utf8.decoder)
        .transform<String>(const LineSplitter())
        .listen((String line) {
      _logger.printTrace('idevicedebug error: $line');
    });
    unawaited(iDeviceDebugProcess.exitCode.then((int exitCode) {
      _logger.printTrace('idevicedebug exited with code $exitCode');
      unawaited(stdoutSubscription.cancel());
      unawaited(stderrSubscription.cancel());
    }).whenComplete(() async {
      // May have already completed on a timeout.
      if (!debuggerCompleter.isCompleted) {
        debuggerCompleter.complete(await iDeviceDebugProcess.exitCode);
      }
    }));

    return IDeviceDebugRun(
      iDeviceDebugProcess: iDeviceDebugProcess,
      status: debuggerCompleter.future.timeout(const Duration(seconds: 10), onTimeout: () {
        _logger.printTrace('idevicedebug timed out in 10 seconds, exiting.');
        iDeviceDebugProcess?.kill();
        return 15; // SIGTERM
      }));
  }
}

/// Wrapper around a idevicedebug process and the results of the run.
///
/// The idevicedebug needs to stay alive to keep the app running.
/// Check [status] to see if the app successfully launched, since the process
/// will not have exited.
class IDeviceDebugRun {
  IDeviceDebugRun({
    this.iDeviceDebugProcess,
    this.status,
  });

  Process iDeviceDebugProcess;

  /// Future completes when the app has successfully launched,
  /// or with the process exit code if the process errored or timed out.
  final Future<int> status;
}
