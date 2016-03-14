// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import '../base/process.dart';
import '../globals.dart';
import 'run.dart';

class ListenCommand extends RunCommandBase {
  @override
  final String name = 'listen';

  @override
  final String description =
    'Listen for changes to files and reload the running app (Android only).';

  @override
  final String usageFooter =
    'By default, only listens to "./" and "./lib/". To listen to additional directories, list them on\n'
    'the command line.';

  /// Only run once.  Used for testing.
  final bool singleRun;

  ListenCommand({ this.singleRun: false });

  @override
  bool get androidOnly => true;

  @override
  bool get requiresDevice => true;

  @override
  Future<int> runInProject() async {
    await downloadApplicationPackages();
    await downloadToolchain();

    List<String> watchCommand = _constructWatchCommand(() sync* {
      yield* argResults.rest;
      yield '.';
      yield 'lib';
    }());

    int result = 0;
    bool firstTime = true;
    do {
      printStatus('Updating running Flutter apps...');
      result = await startApp(
        deviceForCommand,
        applicationPackages,
        toolchain,
        buildConfigurations,
        target: target,
        install: firstTime,
        stop: true,
        checked: checked,
        traceStartup: traceStartup,
        route: route
      );
      firstTime = false;
    } while (!singleRun && result == 0 && _watchDirectory(watchCommand));
    return 0;
  }

  List<String> _constructWatchCommand(Iterable<String> directories) {
    if (Platform.isMacOS) {
      try {
        runCheckedSync(<String>['which', 'fswatch']);
      } catch (e) {
        printError('"listen" command is only useful if you have installed '
            'fswatch on Mac.  Run "brew install fswatch" to install it with '
            'homebrew.');
        return null;
      }
      return <String>['fswatch', '-r', '-v', '-1']..addAll(directories);
    } else if (Platform.isLinux) {
      try {
        runCheckedSync(<String>['which', 'inotifywait']);
      } catch (e) {
        printError('"listen" command is only useful if you have installed '
            'inotifywait on Linux.  Run "apt-get install inotify-tools" or '
            'equivalent to install it.');
        return null;
      }
      return <String>[
        'inotifywait',
        '-r',
        '-e',
        // Only listen for events that matter, to avoid triggering constantly
        // from the editor watching files.
        'modify,close_write,move,create,delete',
      ]..addAll(directories);
    } else {
      printError('"listen" command is only available on Mac and Linux.');
    }
    return null;
  }

  bool _watchDirectory(List<String> watchCommand) {
    printStatus('Attempting to listen to these directories: ${watchCommand.join(", ")}');
    assert(watchCommand != null);
    try {
      runCheckedSync(watchCommand);
    } catch (e) {
      printError('Watching directories failed.', e);
      return false;
    }
    return true;
  }
}
