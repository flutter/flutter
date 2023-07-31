import 'dart:io';

import 'package:path/path.dart';
import 'package:recase/recase.dart';

import '../../core/structure.dart';

String findBindingFromName(String path, String name) {
  path = Structure.replaceAsExpected(path: path);
  var splitPath = Structure.safeSplitPath(path);
  splitPath
    ..remove('.')
    ..removeLast();

  var bindingPath = '';
  while (splitPath.isNotEmpty && bindingPath == '') {
    Directory(splitPath.join(separator))
        .listSync(recursive: true, followLinks: false)
        .forEach((element) {
      if (element is File) {
        var fileName = basename(element.path);
        if (fileName == '${name.snakeCase}_binding.dart' ||
            fileName == '${name.snakeCase}.controller.binding.dart') {
          bindingPath = element.path;
        }
      }
    });
    splitPath.removeLast();
  }
  return bindingPath;
}
