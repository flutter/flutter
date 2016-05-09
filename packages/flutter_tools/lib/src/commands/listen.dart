// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import '../base/os.dart';
import '../base/process.dart';
import '../device.dart';
import '../build_configuration.dart';
import '../globals.dart';
import 'run.dart';

class ListenCommand extends RunCommandBase {
  ListenCommand({ this.singleRun: false });

  @override
  final String name = 'listen';

  @override
  final String description = 'Listen for changes to files and reload the running app.';

  @override
  final String usageFooter =
    'By default, only listens to "./" and "./lib/". To listen to additional directories, list them on\n'
    'the command line.';

  /// Only run once. Used for testing.
  final bool singleRun;

  @override
  bool get requiresDevice => true;

  @override
  Future<int> runInProject() async {
    Iterable<String> directories = () sync* {
      yield* argResults.rest;
      yield '.';
      yield 'lib';
    }();

    List<String> watchCommand = _constructWatchCommand(directories);

    if (watchCommand == null)
      return 1;

    printStatus('Listening for changes in '
      '${directories.map((String name) => "'$name${Platform.pathSeparator}'").join(', ')}'
      '.');

    int result = 0;
    bool firstTime = true;
    do {
      printStatus('');

      // TODO(devoncarew): We could print out here what changes we detected that caused a re-run.
      if (!firstTime)
        printStatus('Re-running app...');

      result = await startApp(
        deviceForCommand,
        toolchain,
        target: target,
        install: firstTime,
        stop: true,
        debuggingOptions: new DebuggingOptions.enabled(checked: getBuildMode() == BuildMode.debug),
        traceStartup: traceStartup,
        route: route
      );
      firstTime = false;
    } while (!singleRun && result == 0 && _watchDirectory(watchCommand));

    return 0;
  }

  List<String> _constructWatchCommand(Iterable<String> directories) {
    if (Platform.isMacOS) {
      if (os.which('fswatch') == null) {
        printError('"listen" command is only useful if you have installed '
          'fswatch on Mac. Run "brew install fswatch" to install it with homebrew.');
        return null;
      } else {
        return <String>['fswatch', '-r', '-v', '-1']..addAll(directories);
      }
    } else if (Platform.isLinux) {
      if (os.which('inotifywait') == null) {
        printError('"listen" command is only useful if you have installed '
          'inotifywait on Linux. Run "apt-get install inotify-tools" or '
          'equivalent to install it.');
        return null;
      } else {
        return <String>[
          'inotifywait',
          '-r',
          '-e',
          // Only listen for events that matter, to avoid triggering constantly
          // from the editor watching files.
          'modify,close_write,move,create,delete',
        ]..addAll(directories);
      }
    } else {
      printError('"listen" command is only available on Mac and Linux.');
    }

    return null;
  }

  bool _watchDirectory(List<String> watchCommand) {
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
