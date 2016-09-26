// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/process.dart';
import '../cache.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';

class ChannelCommand extends FlutterCommand {
  @override
  final String name = 'channel';

  @override
  final String description = 'List or switch flutter channels.';

  @override
  String get invocation => '${runner.executableName} $name [<channel-name>]';

  @override
  Future<int> runCommand() async {
    switch (argResults.rest.length) {
      case 0:
        return await _listChannels();
      case 1:
        return await _switchChannel(argResults.rest[0]);
      default:
        printStatus('Too many arguments.');
        printStatus(usage);
        return 2;
    }
  }

  Future<int> _listChannels() async {
    String currentBranch = runSync(
        <String>['git', 'rev-parse', '--abbrev-ref', 'HEAD'],
        workingDirectory: Cache.flutterRoot);

    printStatus('Flutter channels:');
    return runCommandAndStreamOutput(
      <String>['git', 'branch', '-r'],
      workingDirectory: Cache.flutterRoot,
      mapFunction: (String line) {
        List<String> split = line.split('/');
        if (split.length < 2) return null;
        String branchName = split[1];
        if (branchName.startsWith('HEAD')) return null;
        if (branchName == currentBranch) return '* $branchName';
        return '  $branchName';
      },
    );
  }

  Future<int> _switchChannel(String branchName) {
    printStatus('Switching to flutter channel named $branchName');
    return runCommandAndStreamOutput(
      <String>['git', 'checkout', branchName],
      workingDirectory: Cache.flutterRoot,
    );
  }
}
