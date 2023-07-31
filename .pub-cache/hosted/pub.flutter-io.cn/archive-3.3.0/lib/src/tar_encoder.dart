import 'dart:typed_data';
import 'tar/tar_file.dart';
import 'util/output_stream.dart';
import 'archive.dart';
import 'archive_file.dart';

/// Encode an [Archive] object into a tar formatted buffer.
class TarEncoder {
  List<int> encode(Archive archive, {OutputStreamBase? output}) {
    final outputStream = output ?? OutputStream();
    start(outputStream);

    for (final file in archive.files) {
      add(file);
    }

    finish();

    if (outputStream is OutputStream) {
      return outputStream.getBytes();
    }
    return [];
  }

  void start([dynamic outputStream]) {
    _outputStream = outputStream ?? OutputStream();
  }

  void add(ArchiveFile file) {
    if (_outputStream == null) {
      return;
    }

    // GNU tar files store extra long file names in a separate file
    if (file.name.length > 100) {
      final ts = TarFile();
      ts.filename = '././@LongLink';
      ts.fileSize = file.name.length;
      ts.mode = 0;
      ts.ownerId = 0;
      ts.groupId = 0;
      ts.lastModTime = 0;
      ts.content = file.name.codeUnits;
      ts.write(_outputStream);
    }

    final ts = TarFile();
    ts.filename = file.name;
    ts.fileSize = file.size;
    ts.mode = file.mode;
    ts.ownerId = file.ownerId;
    ts.groupId = file.groupId;
    ts.lastModTime = file.lastModTime;
    ts.content = file.content;
    ts.write(_outputStream);
  }

  void finish() {
    if (_outputStream == null) {
      return;
    }
    // At the end of the archive file there are two 512-byte blocks filled
    // with binary zeros as an end-of-file marker.
    final eof = Uint8List(1024);
    _outputStream.writeBytes(eof);
    _outputStream.flush();
    _outputStream = null;
  }

  dynamic _outputStream;
}
