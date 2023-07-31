import 'dart:io';

import '../../core/structure.dart';

void addExport(String path, String line) {
  var newFile = File(Structure.replaceAsExpected(path: path));
  if (!newFile.existsSync()) {
    newFile.createSync(recursive: true);
    newFile.writeAsStringSync(line);
    return;
  }
  var lines = newFile.readAsLinesSync();

  if (lines.length > 1) {
    if (lines.contains(line)) {
      return;
    }
    while (lines.last.isEmpty) {
      /* remover as linhas em branco no final do arquivo 
    gerada pelo o visual studio e outras ide
    */
      lines.removeLast();
    }
  }

  lines.add(line);

  lines.sort();

  newFile.writeAsStringSync(lines.join('\n'));
}
