import 'dart:io';

void main() {
  final allowed = {
    'packages/flutter_tools/bin/fuchsia_tester.dart',
    'packages/flutter_tools/lib/executable.dart',
    'packages/flutter_tools/lib/src/commands/test.dart',
    'packages/flutter_tools/lib/src/test/coverage_collector.dart',
    'packages/flutter_tools/lib/src/test/flutter_platform.dart',
    'packages/flutter_tools/lib/src/test/flutter_web_platform.dart',
    'packages/flutter_tools/lib/src/test/runner.dart',
    'packages/flutter_tools/lib/src/test/test_compiler.dart',
    'packages/flutter_tools/test/commands.shard/hermetic/test_test.dart',
    'packages/flutter_tools/test/general.shard/coverage_collector_test.dart',
    'packages/flutter_tools/test/general.shard/flutter_platform_test.dart',
    'packages/flutter_tools/test/general.shard/test/test_compiler_test.dart',
    'packages/flutter_tools/test/general.shard/test_golden_comparator_test.dart',
  };
  
  // Find everything this branch changed compared to upstream/master merge base
  final status = Process.runSync('git', ['diff', '--name-only', 'upstream/master...HEAD']);
  final diffOutput = (status.stdout as String).trim();
  final toRevert = <String>{};
  
  if (diffOutput.isNotEmpty) {
    for (var file in diffOutput.split('\n').map((e) => e.trim())) {
      if (file.isNotEmpty && !allowed.contains(file)) {
        toRevert.add(file);
      }
    }
  }
      
  print('Found ${toRevert.length} files to revert to upstream/master.');
  for (var file in toRevert) {
    // If it's reverting from branch changes we are already post merge, 
    // HEAD has them, but upstream/master has the old version.
    final res = Process.runSync('git', ['checkout', 'upstream/master', '--', file]);
    if (res.exitCode != 0) {
      // Meaning it was an added file in the branch. Remove it.
      Process.runSync('rm', ['-f', file]);
      Process.runSync('git', ['rm', '--cached', '--force', '--ignore-unmatch', file]);
    } else {
      Process.runSync('git', ['add', file]);
    }
  }
  print('Done.');
}
