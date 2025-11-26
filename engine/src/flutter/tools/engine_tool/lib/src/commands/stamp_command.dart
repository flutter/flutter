// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:engine_repo_tools/engine_repo_tools.dart';
import 'package:path/path.dart' as p;
import 'package:process_runner/process_runner.dart';

import 'command.dart';
import 'flags.dart';

/// The `stamp` command for recording engine build info.
final class StampCommand extends CommandBase {
  /// Constructs the `stamp` command.
  StampCommand({required super.environment, super.help = false, super.usageLineLength}) {
    argParser.addFlag(
      dryRunFlag,
      abbr: 'd',
      help: 'Write changes to stdout without modifying the file system.',
      negatable: false,
    );
  }

  @override
  String get name => 'stamp';

  @override
  String get description => 'Records build information for later consumption.';

  @override
  Future<int> run() async {
    final bool dryRun = argResults!.flag('dry-run');
    final Engine engine = environment.engine;

    final String revision = await _getGitRevision();
    final String revisionDate = await _getGitRevisionDate(revision);
    final DateTime now = environment.now();

    final stamp = <String, Object?>{
      'build_date': now.toIso8601String(),
      'build_time_ms': now.millisecondsSinceEpoch,
      'git_revision': revision,
      'git_revision_date': revisionDate,
      'content_hash': await _getContentHash(),
    };

    final String stampPath = p.join(engine.outDir.path, 'engine_stamp.json');
    if (dryRun) {
      environment.logger.status('The following would have been written to $stampPath:');
      environment.logger.status(json.encode(stamp));
      return 0;
    }
    final stampFile = File(stampPath);
    stampFile.createSync(recursive: true);
    stampFile.writeAsStringSync(json.encode(stamp));
    return 0;
  }

  Future<String> _getGitRevision() async {
    final ProcessRunnerResult result = await environment.processRunner.runProcess(
      'git rev-parse HEAD'.split(' '),
      workingDirectory: environment.engine.srcDir,
    );
    if (result.exitCode != 0) {
      environment.logger.error(
        'git rev-parse HEAD failed with exit code ${result.exitCode}'
        '\n\n'
        'STDOUT:\n${result.stdout}\n'
        'STDERR:\n${result.stderr}\n',
      );
    }
    return result.stdout.trim();
  }

  Future<String> _getGitRevisionDate(String revision) async {
    final ProcessRunnerResult result = await environment.processRunner.runProcess(
      'git show -s --pretty=format:%ad --date=iso-strict'.split(' '),
      workingDirectory: environment.engine.srcDir,
    );
    if (result.exitCode != 0) {
      environment.logger.error(
        'git show failed with exit code ${result.exitCode}'
        '\n\n'
        'STDOUT:\n${result.stdout}\n'
        'STDERR:\n${result.stderr}\n',
      );
    }
    return result.stdout.trim();
  }

  Future<String> _getContentHash() async {
    final ProcessRunnerResult result = await environment.processRunner.runProcess([
      '${environment.flutterBinInternal}/content_aware_hash.sh',
    ], workingDirectory: environment.engine.srcDir);
    if (result.exitCode != 0) {
      environment.logger.error(
        'content_aware_hash.sh failed with exit code ${result.exitCode}'
        '\n\n'
        'STDOUT:\n${result.stdout}\n'
        'STDERR:\n${result.stderr}\n',
      );
    }
    return result.stdout.trim();
  }
}
