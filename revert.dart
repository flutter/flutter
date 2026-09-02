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
  
  final status = Process.runSync('git', ['status', '--porcelain']);
  final statusOutput = (status.stdout as String).trim();
  final toCheckout = <String>{};
  
  if (statusOutput.isNotEmpty) {
    for (var line in statusOutput.split('\n')) {
      if (line.length < 4) continue;
      final file = line.substring(3).trim();
      if (!allowed.contains(file) && file != 'revert.dart') {
        toCheckout.add(file);
      }
    }
  }
      
  print('Found ${toCheckout.length} files to reset to upstream/master and stage.');
  for (var file in toCheckout) {
    if (file == 'revert.dart') continue;
    final res = Process.runSync('git', ['checkout', 'upstream/master', '--', file]);
    if (res.exitCode != 0) {
      Process.runSync('rm', ['-f', file]);
      Process.runSync('git', ['rm', '--cached', '--force', '--ignore-unmatch', file]);
    } else {
      Process.runSync('git', ['add', file]);
    }
  }
  print('Done.');
}
