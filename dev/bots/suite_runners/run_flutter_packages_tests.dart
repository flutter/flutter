import 'dart:io' show Directory;

import 'package:path/path.dart' as path;

import '../run_command.dart';
import '../test.dart';
import '../utils.dart';


/// Executes the test suite for the flutter/packages repo.
Future<void> flutterPackagesRunner() async {
  Future<void> runAnalyze() async {
    printProgress('${green}Running analysis for flutter/packages$reset');
    final Directory checkout = Directory.systemTemp.createTempSync('flutter_packages.');
    await runCommand(
      'git',
      <String>[
        '-c',
        'core.longPaths=true',
        'clone',
        'https://github.com/flutter/packages.git',
        '.',
      ],
      workingDirectory: checkout.path,
    );
    final String packagesCommit = await getFlutterPackagesVersion();
    await runCommand(
      'git',
      <String>[
        '-c',
        'core.longPaths=true',
        'checkout',
        packagesCommit,
      ],
      workingDirectory: checkout.path,
    );
    // Prep the repository tooling.
    // This test does not use tool_runner.sh because in this context the test
    // should always run on the entire packages repo, while tool_runner.sh
    // is designed for flutter/packages CI and only analyzes changed repository
    // files when run for anything but master.
    final String toolDir = path.join(checkout.path, 'script', 'tool');
    await runCommand(
      'dart',
      <String>[
        'pub',
        'get',
      ],
      workingDirectory: toolDir,
    );
    final String toolScript = path.join(toolDir, 'bin', 'flutter_plugin_tools.dart');
    await runCommand(
      'dart',
      <String>[
        'run',
        toolScript,
        'analyze',
        // Fetch the oldest possible dependencies, rather than the newest, to
        // insulate flutter/flutter from out-of-band failures when new versions
        // of dependencies are published. This compensates for the fact that
        // flutter/packages doesn't use pinned dependencies, and for the
        // purposes of this test using old dependencies is fine. See
        // https://github.com/flutter/flutter/issues/129633
        '--downgrade',
        '--custom-analysis=script/configs/custom_analysis.yaml',
      ],
      workingDirectory: checkout.path,
    );
  }
  await selectSubshard(<String, ShardRunner>{
    'analyze': runAnalyze,
  });
}
