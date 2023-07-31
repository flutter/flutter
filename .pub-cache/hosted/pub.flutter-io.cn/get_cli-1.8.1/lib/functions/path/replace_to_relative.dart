import 'package:path/path.dart';

import '../../core/structure.dart';

/// Replace the import with a relative path import.
String replaceToRelativeImport(String import, String otherFile) {
  var startImport = import.indexOf('/');
  var endImport = import.lastIndexOf("'");
  var pathImport = import.substring(startImport + 1, endImport);
  var pathSafe = Structure.safeSplitPath(otherFile);
  pathSafe.removeWhere((element) => element == 'lib');
  pathSafe.removeLast();
  otherFile = pathSafe.join('/');

  var newImport = relative(pathImport, from: otherFile);
  newImport = Structure.safeSplitPath(newImport).join('/');
  return "import '$newImport${import.substring(endImport)}";
}
