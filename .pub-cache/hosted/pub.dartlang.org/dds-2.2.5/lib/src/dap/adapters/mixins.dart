// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../logging.dart';
import '../protocol_common.dart';

/// A mixin providing some utility functions for locating/working with
/// package_config.json files.
mixin PackageConfigUtils {
  /// Find the `package_config.json` file for the program being launched.
  ///
  /// It is no longer necessary to call this method as the package config file
  /// is no longer used. URI lookups are done via the VM Service.
  @Deprecated('No longer necessary, URI lookups are done via VM Service')
  File? findPackageConfigFile(String possibleRoot) {
    // TODO(dantup): Remove this method after Flutter DA is updated not to use
    // it.
    return null;
  }
}

/// A mixin for tracking additional PIDs that can be shut down at the end of a
/// debug session.
mixin PidTracker {
  /// Process IDs to terminate during shutdown.
  ///
  /// This may be populated with pids from the VM Service to ensure we clean up
  /// properly where signals may not be passed through the shell to the
  /// underlying VM process.
  /// https://github.com/Dart-Code/Dart-Code/issues/907
  final pidsToTerminate = <int>{};

  /// Terminates all processes with the PIDs registered in [pidsToTerminate].
  void terminatePids(ProcessSignal signal) {
    // TODO(dantup): In Dart-Code DAP, we first try again with sigint and wait
    // for a few seconds before sending sigkill.
    pidsToTerminate.forEach(
      (pid) => Process.killPid(pid, signal),
    );
  }
}

/// A mixin providing some utility functions for adapters that run tests and
/// provides some basic test reporting since otherwise nothing is printed when
/// using the JSON test reporter.
mixin TestAdapter {
  static const _tick = "✓";
  static const _cross = "✖";

  /// Test names by testID.
  ///
  /// Stored in testStart so that they can be looked up in testDone.
  Map<int, String> _testNames = {};

  void sendEvent(EventBody body, {String? eventType});
  void sendOutput(String category, String message);

  void sendTestEvents(Object testNotification) {
    // Send the JSON package as a raw notification so the client can interpret
    // the results (for example to populate a test tree).
    sendEvent(RawEventBody(testNotification),
        eventType: 'dart.testNotification');

    // Additionally, send a textual output so that the user also has visible
    // output in the Debug Console.
    if (testNotification is Map<String, Object?>) {
      sendTestTextOutput(testNotification);
    }
  }

  /// Sends textual output for tests, including pass/fail and test output.
  ///
  /// This is sent so that clients that do not handle the package:test JSON
  /// events still get some useful textual output in their Debug Consoles.
  void sendTestTextOutput(Map<String, Object?> testNotification) {
    switch (testNotification['type']) {
      case 'testStart':
        // When a test starts, capture its name by ID so we can get it back when
        // testDone comes.
        final test = testNotification['test'] as Map<String, Object?>?;
        if (test != null) {
          final testID = test['id'] as int?;
          final testName = test['name'] as String?;
          if (testID != null && testName != null) {
            _testNames[testID] = testName;
          }
        }
        break;

      case 'testDone':
        // Print the status of completed tests with a tick/cross.
        if (testNotification['hidden'] == true) {
          break;
        }
        final testID = testNotification['testID'] as int?;
        if (testID != null) {
          final testName = _testNames[testID];
          if (testName != null) {
            final symbol =
                testNotification['result'] == "success" ? _tick : _cross;
            sendOutput('console', '$symbol $testName\n');
          }
        }
        break;

      case 'print':
        final message = testNotification['message'] as String?;
        if (message != null) {
          sendOutput('stdout', '${message.trimRight()}\n');
        }
        break;

      case 'error':
        final error = testNotification['error'] as String?;
        final stack = testNotification['stackTrace'] as String?;
        if (error != null) {
          sendOutput('stderr', '${error.trimRight()}\n');
        }
        if (stack != null) {
          sendOutput('stderr', '${stack.trimRight()}\n');
        }
        break;
    }
  }
}

/// A mixin providing some utility functions for working with vm-service-info
/// files such as ensuring a temp folder exists to create them in, and waiting
/// for the file to become valid parsable JSON.
mixin VmServiceInfoFileUtils {
  /// Creates a temp folder for the VM to write the service-info-file into and
  /// returns the [File] to use.
  File generateVmServiceInfoFile() {
    // Using tmpDir.createTempory() is flakey on Windows+Linux (at least
    // on GitHub Actions) complaining the file does not exist when creating a
    // watcher. Creating/watching a folder and writing the file into it seems
    // to be reliable.
    final serviceInfoFilePath = path.join(
      Directory.systemTemp.createTempSync('dart-vm-service').path,
      'vm.json',
    );

    return File(serviceInfoFilePath);
  }

  /// Waits for [vmServiceInfoFile] to exist and become valid before returning
  /// the VM Service URI contained within.
  Future<Uri> waitForVmServiceInfoFile(
    Logger? logger,
    File vmServiceInfoFile,
  ) async {
    final completer = Completer<Uri>();
    late final StreamSubscription<FileSystemEvent> vmServiceInfoFileWatcher;

    void tryParseServiceInfoFile(FileSystemEvent event) {
      final uri = _readVmServiceInfoFile(logger, vmServiceInfoFile);
      if (uri != null && !completer.isCompleted) {
        vmServiceInfoFileWatcher.cancel();
        completer.complete(uri);
      }
    }

    vmServiceInfoFileWatcher = vmServiceInfoFile.parent
        .watch(events: FileSystemEvent.all)
        .where((event) => event.path == vmServiceInfoFile.path)
        .listen(
          tryParseServiceInfoFile,
          onError: (e) => logger?.call('Ignoring exception from watcher: $e'),
        );

    // After setting up the watcher, also check if the file already exists to
    // ensure we don't miss it if it was created right before we set the
    // watched up.
    final uri = _readVmServiceInfoFile(logger, vmServiceInfoFile);
    if (uri != null && !completer.isCompleted) {
      unawaited(vmServiceInfoFileWatcher.cancel());
      completer.complete(uri);
    }

    return completer.future;
  }

  /// Attempts to read VM Service info from a watcher event.
  ///
  /// If successful, returns the URI. Otherwise, returns null.
  Uri? _readVmServiceInfoFile(Logger? logger, File file) {
    try {
      final content = file.readAsStringSync();
      final json = jsonDecode(content);
      return Uri.parse(json['uri']);
    } catch (e) {
      // It's possible we tried to read the file before it was completely
      // written so ignore and try again on the next event.
      logger?.call('Ignoring error parsing vm-service-info file: $e');
      return null;
    }
  }
}
