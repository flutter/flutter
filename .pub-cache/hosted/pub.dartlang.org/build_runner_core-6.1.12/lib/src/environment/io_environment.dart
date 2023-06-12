// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:build/build.dart';
import 'package:logging/logging.dart';

import '../asset/file_based.dart';
import '../asset/reader.dart';
import '../asset/writer.dart';
import '../generate/build_directory.dart';
import '../generate/build_result.dart';
import '../generate/finalized_assets_view.dart';
import '../package_graph/package_graph.dart';
import 'build_environment.dart';
import 'create_merged_dir.dart';

final _logger = Logger('IOEnvironment');

/// A [BuildEnvironment] writing to disk and stdout.
class IOEnvironment implements BuildEnvironment {
  @override
  final RunnerAssetReader reader;

  @override
  final RunnerAssetWriter writer;

  final bool _isInteractive;

  final bool _outputSymlinksOnly;

  final PackageGraph _packageGraph;

  IOEnvironment(this._packageGraph, {bool assumeTty, bool outputSymlinksOnly})
      : _isInteractive = assumeTty == true || _canPrompt(),
        _outputSymlinksOnly = outputSymlinksOnly ?? false,
        reader = FileBasedAssetReader(_packageGraph),
        writer = FileBasedAssetWriter(_packageGraph) {
    if (_outputSymlinksOnly && Platform.isWindows) {
      _logger.warning('Symlinks to files are not yet working on Windows, you '
          'may experience issues using this mode. Follow '
          'https://github.com/dart-lang/sdk/issues/33966 for updates.');
    }
  }

  @override
  void onLog(LogRecord record) {
    if (record.level >= Level.SEVERE) {
      stderr.writeln(record);
    } else {
      stdout.writeln(record);
    }
  }

  @override
  Future<int> prompt(String message, List<String> choices) async {
    if (!_isInteractive) throw NonInteractiveBuildException();
    while (true) {
      stdout.writeln('\n$message');
      for (var i = 0, l = choices.length; i < l; i++) {
        stdout.writeln('${i + 1} - ${choices[i]}');
      }
      final input = stdin.readLineSync();
      final choice = int.tryParse(input) ?? -1;
      if (choice > 0 && choice <= choices.length) return choice - 1;
      stdout.writeln('Unrecognized option $input, '
          'a number between 1 and ${choices.length} expected');
    }
  }

  @override
  Future<BuildResult> finalizeBuild(
      BuildResult buildResult,
      FinalizedAssetsView finalizedAssetsView,
      AssetReader reader,
      Set<BuildDirectory> buildDirs) async {
    if (buildDirs.any(
            (target) => target.outputLocation?.path?.isNotEmpty ?? false) &&
        buildResult.status == BuildStatus.success) {
      if (!await createMergedOutputDirectories(buildDirs, _packageGraph, this,
          reader, finalizedAssetsView, _outputSymlinksOnly)) {
        return _convertToFailure(buildResult,
            failureType: FailureType.cantCreate);
      }
    }
    return buildResult;
  }
}

bool _canPrompt() =>
    stdioType(stdin) == StdioType.terminal &&
    // Assume running inside a test if the code is running as a `data:` URI
    Platform.script.scheme != 'data';

BuildResult _convertToFailure(BuildResult previous,
        {FailureType failureType}) =>
    BuildResult(
      BuildStatus.failure,
      previous.outputs,
      performance: previous.performance,
      failureType: failureType,
    );
