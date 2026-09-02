import 'dart:io';

void main() {
  final status = Process.runSync('git', ['status', '--porcelain']);
  final lines = (status.stdout as String).trim().split('\n');
  final deleted = <String>[];
  
  for (final line in lines) {
    if (line.isEmpty) continue;
    final state = line.substring(0, 2);
    final file = line.substring(3).trim();
    if (state.contains('D')) {
      deleted.add(file);
    }
  }
  
  if (deleted.isEmpty) {
    print('No deleted files found.');
    return;
  }
  
  print('Restoring ${deleted.length} deleted files from upstream/master...');
  for (final file in deleted) {
    if (file == 'packages/flutter_tools/test/src/context.dart' || file.startsWith('packages/')) {
       final res = Process.runSync('git', ['checkout', 'upstream/master', '--', file]);
       if (res.exitCode == 0) {
         Process.runSync('git', ['add', file]);
       } else {
         print('Failed to restore $file: ${res.stderr}');
       }
    }
  }
  print('Done.');
}
