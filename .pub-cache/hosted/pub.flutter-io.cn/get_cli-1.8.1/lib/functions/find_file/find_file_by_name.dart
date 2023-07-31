import 'dart:io';

import 'package:path/path.dart';

/// find a file from the name in the lib folder
File findFileByName(String name) {
  var current = Directory('lib');
  final list = current.listSync(recursive: true, followLinks: false);
  var contains = list.firstWhere((element) {
    if (element is File) {
      return basename(element.path) == name;
    }
    return false;
  }, orElse: () {
    return File('');
  });
  return contains as File;
}
