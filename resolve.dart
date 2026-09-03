import 'dart:io';

void main() {
  var result = Process.runSync('git', ['diff', '--name-only', '--diff-filter=U']);
  var files = result.stdout.toString().split('\n').where((l) => l.isNotEmpty).toList();
  for (var file in files) {
    print('Checking $file');
    var lines = File(file).readAsLinesSync();
    int i = 0;
    while(i < lines.length) {
      if (lines[i].startsWith('<<<<<<< HEAD')) {
        int start = i;
        while(i < lines.length && !lines[i].startsWith('=======')) i++;
        int mid = i;
        while(i < lines.length && !lines[i].startsWith('>>>>>>>')) i++;
        int end = i;
        print('Conflict in $file : $start to $end');
      }
      i++;
    }
  }
}
