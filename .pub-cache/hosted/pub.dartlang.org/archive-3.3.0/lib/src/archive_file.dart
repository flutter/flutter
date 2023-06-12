import 'dart:typed_data';

import 'util/input_stream.dart';
import 'util/output_stream.dart';
import 'zlib/inflate.dart';
import 'zlib/inflate_buffer.dart';

/// A file contained in an Archive.
class ArchiveFile {
  static const int STORE = 0;
  static const int DEFLATE = 8;

  String name;

  /// The uncompressed size of the file
  int size = 0;
  int mode = 420; // octal 644 (-rw-r--r--)
  int ownerId = 0;
  int groupId = 0;
  /// Seconds since epoch
  int lastModTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  /// If false, this is a directory.
  bool isFile = true;
  /// If true, this is a symbolic link to the file specified in nameOfLinkedFile
  bool isSymbolicLink = false;
  /// If this is a symbolic link, this is the path to the file its linked to.
  String nameOfLinkedFile = '';

  /// The crc32 checksum of the uncompressed content.
  int? crc32;
  String? comment;

  /// If false, this file will not be compressed when encoded to an archive
  /// format such as zip.
  bool compress = true;

  int get unixPermissions => mode & 0x1FF;

  ArchiveFile(this.name, this.size, dynamic content,
      [this._compressionType = STORE]) {
    name = name.replaceAll('\\', '/');
    if (content is Uint8List) {
      _content = content;
      _rawContent = InputStream(_content);
      if (size <= 0) {
        size = content.length;
      }
    } else if (content is InputStream) {
      _rawContent = InputStream.from(content);
      if (size <= 0) {
        size = content.length;
      }
    } else if (content is InputStreamBase) {
      _rawContent = content;
      if (size <= 0) {
        size = content.length;
      }
    } else if (content is TypedData) {
      _content = Uint8List.view(content.buffer);
      _rawContent = InputStream(_content);
      if (size <= 0) {
        size = (_content as Uint8List).length;
      }
    } else if (content is String) {
      _content = content.codeUnits;
      _rawContent = InputStream(_content);
      if (size <= 0) {
        size = content.codeUnits.length + 1;
      }
    } else if (content is List<int>) { // Legacy
      // This expects the list to be a list of bytes, with values [0, 255].
      _content = content;
      _rawContent = InputStream(_content);
      if (size <= 0) {
        size = content.length;
      }
    }
  }

  ArchiveFile.string(this.name, String content,
      [this._compressionType = STORE]) {
    size = content.length;
    _content = Uint8List.fromList(content.codeUnits);
    _rawContent = InputStream(_content);
  }

  ArchiveFile.noCompress(this.name, this.size, dynamic content) {
    name = name.replaceAll('\\', '/');
    compress = false;
    if (content is Uint8List) {
      _content = content;
      _rawContent = InputStream(_content);
    } else if (content is InputStream) {
      _rawContent = InputStream.from(content);
    }
  }

  ArchiveFile.stream(this.name, this.size, InputStreamBase contentStream) {
    // Paths can only have / path separators
    name = name.replaceAll('\\', '/');
    compress = true;
    _content = contentStream;
    //_rawContent = content_stream;
    _compressionType = STORE;
  }

  void writeContent(OutputStreamBase output, {bool freeMemory = true}) {
    if (_content is List<int>) {
      output.writeBytes(_content as List<int>);
    } else if (_content is InputStreamBase) {
      output.writeInputStream(_content as InputStreamBase);
    } else if (_rawContent != null) {
      decompress();
      output.writeBytes(_content as List<int>);
      // Release memory
      if (freeMemory) {
        _content = null;
      }
    }
  }

  /// Get the content of the file, decompressing on demand as necessary.
  dynamic get content {
    if (_content == null) {
      decompress();
    }
    return _content;
  }

  void clear() {
    _content = null;
  }

  Future<void> close() async {
    var futures = <Future<void>>[];
    if (_content is InputStreamBase) {
      futures.add((_content as InputStreamBase).close());
    }
    if (_rawContent is InputStreamBase) {
      futures.add((_rawContent as InputStreamBase).close());
    }
    _content = null;
    _rawContent = null;
    await Future.wait(futures);
  }

  /// If the file data is compressed, decompress it.
  void decompress([OutputStreamBase? output]) {
    if (_content == null && _rawContent != null) {
      if (_compressionType == DEFLATE) {
        if (output != null) {
          Inflate.stream(_rawContent!, output);
        } else {
          _content = inflateBuffer(_rawContent!.toUint8List());
        }
      } else {
        if (output != null) {
          output.writeInputStream(_rawContent!);
        } else {
          _content = _rawContent!.toUint8List();
        }
      }
      _compressionType = STORE;
    }
  }

  /// Is the data stored by this file currently compressed?
  bool get isCompressed => _compressionType != STORE;

  /// What type of compression is the raw data stored in
  int? get compressionType => _compressionType;

  /// Get the content without decompressing it first.
  InputStreamBase? get rawContent => _rawContent;

  @override
  String toString() => name;

  int? _compressionType;
  InputStreamBase? _rawContent;
  dynamic _content;
}
