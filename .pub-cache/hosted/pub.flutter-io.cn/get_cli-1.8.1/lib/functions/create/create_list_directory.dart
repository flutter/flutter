import 'dart:io';

/// Create a directory from a list
void createListDirectory(List<Directory> dirs) {
  for (final element in dirs) {
    element.createSync(recursive: true);
  }
}
