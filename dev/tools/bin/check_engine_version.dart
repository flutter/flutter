// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:args/args.dart';
import 'package:dev_tools/check_engine_version.dart';
import 'package:path/path.dart' as p;

final String _scriptSuffix = io.Platform.isWindows ? '.bat' : '.sh';
final ArgParser _argParser = ArgParser()
  ..addOption(
    'version',
    abbr: 'v',
    help: 'Path to the engine.version file',
    defaultsTo: p.join('bin', 'internal', 'engine.version'),
  )
  ..addOption(
    'script',
    abbr: 'l',
    help: 'Path to the last_engine_commit$_scriptSuffix script',
    defaultsTo: p.join('bin', 'internal', 'last_engine_commit$_scriptSuffix'),
  )
  ..addFlag(
    'skip-if-version-file-not-changed-from-head',
    help: 'Skips the check, if the file was not changed compared to HEAD',
    defaultsTo: true,
  );

/// Checks if `bin/internal/engine.version` was updated to the current SHA.
void main(List<String> args) async {
  final ArgResults argResults = _argParser.parse(args);

  final String versionPath = argResults.option('version')!;
  final String scriptPath = argResults.option('script')!;
  final bool skipIfNotChanged = argResults.flag('skip-if-version-file-not-changed-from-head');

  final bool result = await checkEngineVersion(
    versionPath: versionPath,
    scriptPath: scriptPath,
    onlyIfVersionChanged: skipIfNotChanged,
  );
  if (!result) {
    io.exitCode = 1;
  }
}
