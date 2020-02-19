// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import '../cache.dart';
import '../globals.dart' as globals;

import '../runner/flutter_command.dart';

class GenerateLocalizationsCommand extends FlutterCommand {
  @override
  String get name => 'generate-localizations';

  @override
  String get description => 'Generate Dart files from ARB files to localize a Flutter application.';

  String get dartSdkPath {
    return globals.fs.path.join(Cache.flutterRoot, 'bin', 'cache', 'dart-sdk');
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    final String root = globals.fs.path.absolute(Cache.flutterRoot);

    final List<String> command = <String>[
      globals.fs.path.join(dartSdkPath, 'bin', 'dart'),
      globals.fs.path.join(root, 'dev', 'tools', 'localization', 'bin', 'gen_l10n.dart'),
    ];
    final ProcessResult result = await globals.processManager.run(command);

    print(result.stdout);
    print(result.stderr);

    return FlutterCommandResult.success();
  }
}