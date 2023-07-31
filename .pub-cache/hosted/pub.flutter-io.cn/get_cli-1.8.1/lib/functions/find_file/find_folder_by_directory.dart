import 'dart:io';

/// find a folder from the name in the lib folder
Directory? findFolderByName(String name) {
  var current = Directory('lib');
  final List<FileSystemEntity?> list =
      current.listSync(recursive: true, followLinks: false);
  var contains = list.firstWhere((element) {
    //Fix erro ao encontrar arquivo com nome
    if (element is Directory) {
      return element.path.contains(name);
    }
    return false;
  }, orElse: () {
    return null;
  });
  return contains as Directory?;
}
