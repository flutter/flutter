import 'dart:io';

import 'package:path/path.dart' as path;

import '../archive_file.dart';
import '../zip_encoder.dart';
import 'input_file_stream.dart';
import 'output_file_stream.dart';

class ZipFileEncoder {
  late String zipPath;
  late OutputFileStream _output;
  late ZipEncoder _encoder;

  static const int STORE = 0;
  static const int GZIP = 1;

  void zipDirectory(Directory dir,
      {String? filename,
      int? level,
      bool followLinks = true,
      DateTime? modified}) {
    final dirPath = dir.path;
    final zipPath = filename ?? '$dirPath.zip';
    level ??= GZIP;
    create(zipPath, level: level, modified: modified);
    addDirectory(dir,
        includeDirName: false, level: level, followLinks: followLinks);
    close();
  }

  void open(String zipPath) => create(zipPath);

  void create(String zipPath, {int? level, DateTime? modified}) {
    this.zipPath = zipPath;

    _output = OutputFileStream(zipPath);
    _encoder = ZipEncoder();
    _encoder.startEncode(_output, level: level, modified: modified);
  }

  Future<void> addDirectory(Directory dir,
      {bool includeDirName = true, int? level, bool followLinks = true}) async {

    final dirName = path.basename(dir.path);
    List files = dir.listSync(recursive: true, followLinks: followLinks);
    var futures = <Future<void>>[];
    for (var file in files) {
      if (file is Directory) {
        var filename = path.relative(file.path, from: dir.path);
        filename = includeDirName ? (dirName + '/' + filename) : filename;
        final af = ArchiveFile(filename + '/', 0, null);
        af.mode = file.statSync().mode;
        af.isFile = false;
        _encoder.addFile(af);
      } else if (file is File) {
        final dirName = path.basename(dir.path);
        final relPath = path.relative(file.path, from: dir.path);
        futures.add(addFile(
            file, includeDirName ? (dirName + '/' + relPath) : relPath, level));
      }
    }
    await Future.wait(futures);
  }

  Future<void> addFile(File file, [String? filename, int? level = GZIP]) async {
    var fileStream = InputFileStream(file.path);
    var archiveFile = ArchiveFile.stream(
        filename ?? path.basename(file.path), file.lengthSync(), fileStream);

    if (level == STORE) {
      archiveFile.compress = false;
    }

    archiveFile.lastModTime = file.lastModifiedSync()
        .millisecondsSinceEpoch ~/ 1000;
    archiveFile.mode = file.statSync().mode;

    _encoder.addFile(archiveFile);
    await fileStream.close();
  }

  void addArchiveFile(ArchiveFile file) {
    _encoder.addFile(file);
  }

  void close() {
    _encoder.endEncode();
    _output.close();
  }
}
