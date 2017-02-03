// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:path/path.dart' as path;

import '../base/common.dart';
import '../base/os.dart';
import '../base/process.dart';
import '../cache.dart';
import '../runner/flutter_command.dart';

class FormatCommand extends FlutterCommand {
  @override
  final String name = 'format';

  @override
  List<String> get aliases => const <String>['dartfmt'];

  @override
  final String description = 'Format one or more dart files.';

  @override
  String get invocation => "${runner.executableName} $name <one or more paths>";

  @override
  Future<Null> runCommand() async {
    if (argResults.rest.isEmpty) {
      throwToolExit(
        'No files specified to be formatted.\n'
        '\n'
        'To format all files in the current directory tree:\n'
        '${runner.executableName} $name .\n'
        '\n'
        '$usage'
      );
    }

    String executable = os.getExecutableName('dartfmt', winExtension: 'bat');
    String dartfmt = path.join(Cache.flutterRoot, 'bin', 'cache', 'dart-sdk', 'bin', executable);
    List<String> cmd = <String>[dartfmt, '-w']..addAll(argResults.rest);
    int result = await runCommandAndStreamOutput(cmd);
    if (result != 0)
      throwToolExit('Formatting failed: $result', exitCode: result);
  }
}
