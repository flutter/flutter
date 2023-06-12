import 'dart:io';
import 'package:path/path.dart' as path;
import '../archive.dart';
import '../archive_file.dart';
import 'input_file_stream.dart';

Archive createArchiveFromDirectory(Directory dir,
    {bool includeDirName = true}) {
  final archive = Archive();

  final dirName = path.basename(dir.path);
  final files = dir.listSync(recursive: true);
  for (var file in files) {
    // If it's a Directory, only add empty directories
    if (file is Directory) {
      var filename = path.relative(file.path, from: dir.path);
      filename = includeDirName ? (dirName + '/' + filename) : filename;
      final af = ArchiveFile(filename + '/', 0, null);
      af.mode = file.statSync().mode;
      af.isFile = false;
      archive.addFile(af);
    } else if (file is File) {
      // It's a File
      var filename = path.relative(file.path, from: dir.path);
      filename = includeDirName ? (dirName + '/' + filename) : filename;

      final fileStream = InputFileStream(file.path);
      final af = ArchiveFile.stream(filename, file.lengthSync(), fileStream);
      af.lastModTime = file
          .lastModifiedSync()
          .millisecondsSinceEpoch ~/ 1000;
      af.mode = file.statSync().mode;

      archive.addFile(af);
    }
  }

  return archive;
}
