// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

import 'package:build_runner/src/build_script_generate/build_script_generate.dart';
import 'package:build_runner/src/entrypoint/base_command.dart' show lineLength;

class GenerateBuildScript extends Command<int> {
  @override
  final argParser = ArgParser(usageLineLength: lineLength);

  @override
  String get description =>
      'Generate a script to run builds and print the file path '
      'with no other logging. Useful for wrapping builds with other tools.';

  @override
  String get name => 'generate-build-script';

  @override
  bool get hidden => true;

  @override
  Future<int> run() async {
    Logger.root.clearListeners();
    var buildScript = await generateBuildScript();
    File(scriptLocation)
      ..createSync(recursive: true)
      ..writeAsStringSync(buildScript);
    print(p.absolute(scriptLocation));
    return 0;
  }
}
