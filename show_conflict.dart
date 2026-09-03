import 'dart:io';

void main(List<String> args) {
  var file = args.first;
  var lines = File(file).readAsLinesSync();
  int i = 0;
  bool inConflict = false;
  int conflictId = 0;
  while(i < lines.length) {
    if (lines[i].startsWith('<<<<<<< HEAD')) {
      conflictId++;
      print('--- Conflict $conflictId in $file ---');
      inConflict = true;
      print(lines[i]);
    } else if (inConflict) {
      print(lines[i]);
      if (lines[i].startsWith('>>>>>>>')) {
        inConflict = false;
      }
    }
    i++;
  }
}
