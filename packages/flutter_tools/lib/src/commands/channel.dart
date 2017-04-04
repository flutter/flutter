// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/common.dart';
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
  Future<Null> runCommand() {
    switch (argResults.rest.length) {
      case 0:
        return _listChannels();
      case 1:
        return _switchChannel(argResults.rest[0]);
      default:
        throw new ToolExit('Too many arguments.\n$usage');
    }
  }

  Future<Null> _listChannels() async {
    final String currentBranch = runSync(
        <String>['git', 'rev-parse', '--abbrev-ref', 'HEAD'],
        workingDirectory: Cache.flutterRoot);

    printStatus('Flutter channels:');
    final int result = await runCommandAndStreamOutput(
      <String>['git', 'branch', '-r'],
      workingDirectory: Cache.flutterRoot,
      mapFunction: (String line) {
        final List<String> split = line.split('/');
        if (split.length < 2)
          return null;
        final String branchName = split[1];
        if (branchName.startsWith('HEAD'))
          return null;
        if (branchName == currentBranch)
          return '* $branchName';
        return '  $branchName';
      },
    );
    if (result != 0)
      throwToolExit('List channels failed: $result', exitCode: result);
  }

  Future<Null> _switchChannel(String branchName) async {
    printStatus('Switching to flutter channel named $branchName');
    final int result = await runCommandAndStreamOutput(
      <String>['git', 'checkout', branchName],
      workingDirectory: Cache.flutterRoot,
    );
    if (result != 0)
      throwToolExit('Switch channel failed: $result', exitCode: result);
  }
}
