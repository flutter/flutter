import 'dart:convert';

import 'util/crc32.dart';
import 'util/input_stream.dart';
import 'util/output_stream.dart';
import 'zip/zip_directory.dart';
import 'zip/zip_file.dart';
import 'zip/zip_file_header.dart';
import 'zlib/deflate.dart';
import 'archive.dart';
import 'archive_file.dart';

class _ZipFileData {
  late String name;
  int time = 0;
  int date = 0;
  int crc32 = 0;
  int compressedSize = 0;
  int uncompressedSize = 0;
  InputStreamBase? compressedData;
  bool compress = true;
  String? comment = '';
  int position = 0;
  int mode = 0;
  bool isFile = true;
}

int? _getTime(DateTime? dateTime) {
  if (dateTime == null) {
    return null;
  }
  final t1 = ((dateTime.minute & 0x7) << 5) | (dateTime.second ~/ 2);
  final t2 = (dateTime.hour << 3) | (dateTime.minute >> 3);
  return ((t2 & 0xff) << 8) | (t1 & 0xff);
}

int? _getDate(DateTime? dateTime) {
  if (dateTime == null) {
    return null;
  }
  final d1 = ((dateTime.month & 0x7) << 5) | dateTime.day;
  final d2 = (((dateTime.year - 1980) & 0x7f) << 1) | (dateTime.month >> 3);
  return ((d2 & 0xff) << 8) | (d1 & 0xff);
}

class _ZipEncoderData {
  int? level;
  late final int? time;
  late final int? date;
  int localFileSize = 0;
  int centralDirectorySize = 0;
  int endOfCentralDirectorySize = 0;
  List<_ZipFileData> files = [];

  _ZipEncoderData(this.level, [DateTime? dateTime]) {
    time = _getTime(dateTime);
    date = _getDate(dateTime);
  }
}

/// Encode an [Archive] object into a Zip formatted buffer.
class ZipEncoder {
  late _ZipEncoderData _data;
  OutputStreamBase? _output;
  final Encoding filenameEncoding;

  ZipEncoder({this.filenameEncoding = const Utf8Codec()});

  /// Bit 11 of the general purpose flag, Language encoding flag
  final int languageEncodingBitUtf8 = 2048;

  List<int>? encode(Archive archive,
      {int level = Deflate.BEST_SPEED,
      OutputStreamBase? output,
      DateTime? modified}) {
    output ??= OutputStream();

    startEncode(output, level: level, modified: modified);
    for (final file in archive.files) {
      addFile(file);
    }
    endEncode(comment: archive.comment);

    if (output is OutputStream) {
      return output.getBytes();
    }

    return null;
  }

  void startEncode(OutputStreamBase? output,
      {int? level = Deflate.BEST_SPEED, DateTime? modified}) {
    _data = _ZipEncoderData(level, modified);
    _output = output;
  }

  int getFileCrc32(ArchiveFile file) {
    if (file.content == null) {
      return 0;
    }
    if (file.content is InputStreamBase) {
      var s = file.content as InputStreamBase;
      s.reset();
      var bytes = s.toUint8List();
      final crc32 = getCrc32(bytes);
      file.content.reset();
      return crc32;
    }
    return getCrc32(file.content as List<int>);
  }

  void addFile(ArchiveFile file) {
    final fileData = _ZipFileData();
    _data.files.add(fileData);

    final lastModMS = file.lastModTime * 1000;
    final lastModTime = DateTime.fromMillisecondsSinceEpoch(lastModMS);

    fileData.name = file.name;
    // If the archive modification time was overwritten, use that, otherwise
    // use the lastModTime from the file.
    fileData.time = _data.time ?? _getTime(lastModTime)!;
    fileData.date = _data.date ?? _getDate(lastModTime)!;
    fileData.mode = file.mode;
    fileData.isFile = file.isFile;

    InputStreamBase? compressedData;
    int crc32 = 0;

    // If the user want's to store the file without compressing it,
    // make sure it's decompressed.
    if (!file.compress) {
      if (file.isCompressed) {
        file.decompress();
      }

      compressedData = (file.content is InputStreamBase)
          ? file.content as InputStreamBase
          : InputStream(file.content);

      if (file.crc32 != null) {
        crc32 = file.crc32!;
      } else {
        crc32 = getFileCrc32(file);
      }
    } else if (file.isCompressed &&
        file.compressionType == ArchiveFile.DEFLATE) {
      // If the file is already compressed, no sense in uncompressing it and
      // compressing it again, just pass along the already compressed data.
      compressedData = file.rawContent;

      if (file.crc32 != null) {
        crc32 = file.crc32!;
      } else {
        crc32 = getFileCrc32(file);
      }
    } else if (file.isFile) {
      // Otherwise we need to compress it now.
      crc32 = getFileCrc32(file);

      dynamic bytes = file.content;
      if (bytes is InputStreamBase) {
        bytes = bytes.toUint8List();
      }
      bytes = Deflate(bytes as List<int>, level: _data.level).getBytes();
      compressedData = InputStream(bytes);
    }

    var encodedFilename = filenameEncoding.encode(file.name);
    var comment =
        file.comment != null ? filenameEncoding.encode(file.comment!) : null;

    var dataLen = compressedData?.length ?? 0;
    _data.localFileSize += 30 + encodedFilename.length + dataLen;

    _data.centralDirectorySize +=
        46 + encodedFilename.length + (comment != null ? comment.length : 0);

    fileData.crc32 = crc32;
    fileData.compressedSize = dataLen;
    fileData.compressedData = compressedData;
    fileData.uncompressedSize = file.size;
    fileData.compress = file.compress;
    fileData.comment = file.comment;
    fileData.position = _output!.length;

    _writeFile(fileData, _output!);

    fileData.compressedData = null;
  }

  void endEncode({String? comment = ''}) {
    // Write Central Directory and End Of Central Directory
    _writeCentralDirectory(_data.files, comment, _output!);
    if (_output is OutputStreamBase) {
      _output!.flush();
    }
  }

  void _writeFile(_ZipFileData fileData, OutputStreamBase output) {
    var filename = fileData.name;

    output.writeUint32(ZipFile.SIGNATURE);

    final version = VERSION;
    final flags =
        filenameEncoding.name == "utf-8" ? languageEncodingBitUtf8 : 0;
    final compressionMethod =
        fileData.compress ? ZipFile.DEFLATE : ZipFile.STORE;
    final lastModFileTime = fileData.time;
    final lastModFileDate = fileData.date;
    final crc32 = fileData.crc32;
    final compressedSize = fileData.compressedSize;
    final uncompressedSize = fileData.uncompressedSize;
    final extra = <int>[];

    final compressedData = fileData.compressedData;

    var encodedFilename = filenameEncoding.encode(filename);

    output.writeUint16(version);
    output.writeUint16(flags);
    output.writeUint16(compressionMethod);
    output.writeUint16(lastModFileTime);
    output.writeUint16(lastModFileDate);
    output.writeUint32(crc32);
    output.writeUint32(compressedSize);
    output.writeUint32(uncompressedSize);
    output.writeUint16(encodedFilename.length);
    output.writeUint16(extra.length);
    output.writeBytes(encodedFilename);
    output.writeBytes(extra);

    if (compressedData != null) {
      output.writeInputStream(compressedData);
    }
  }

  void _writeCentralDirectory(
      List<_ZipFileData> files, String? comment, OutputStreamBase output) {
    comment ??= '';
    var encodedComment = filenameEncoding.encode(comment);

    final centralDirPosition = output.length;
    final version = VERSION;
    final os = OS_MSDOS;

    for (var fileData in files) {
      final versionMadeBy = (os << 8) | version;
      final versionNeededToExtract = version;
      final generalPurposeBitFlag = languageEncodingBitUtf8;
      final compressionMethod =
          fileData.compress ? ZipFile.DEFLATE : ZipFile.STORE;
      final lastModifiedFileTime = fileData.time;
      final lastModifiedFileDate = fileData.date;
      final crc32 = fileData.crc32;
      final compressedSize = fileData.compressedSize;
      final uncompressedSize = fileData.uncompressedSize;
      final diskNumberStart = 0;
      final internalFileAttributes = 0;
      final externalFileAttributes = fileData.mode << 16;
      /*if (!fileData.isFile) {
        externalFileAttributes |= 0x4000; // ?
      }*/
      final localHeaderOffset = fileData.position;
      final extraField = <int>[];
      final fileComment = fileData.comment ?? '';

      final encodedFilename = filenameEncoding.encode(fileData.name);
      final encodedFileComment = filenameEncoding.encode(fileComment);

      output.writeUint32(ZipFileHeader.SIGNATURE);
      output.writeUint16(versionMadeBy);
      output.writeUint16(versionNeededToExtract);
      output.writeUint16(generalPurposeBitFlag);
      output.writeUint16(compressionMethod);
      output.writeUint16(lastModifiedFileTime);
      output.writeUint16(lastModifiedFileDate);
      output.writeUint32(crc32);
      output.writeUint32(compressedSize);
      output.writeUint32(uncompressedSize);
      output.writeUint16(encodedFilename.length);
      output.writeUint16(extraField.length);
      output.writeUint16(encodedFileComment.length);
      output.writeUint16(diskNumberStart);
      output.writeUint16(internalFileAttributes);
      output.writeUint32(externalFileAttributes);
      output.writeUint32(localHeaderOffset);
      output.writeBytes(encodedFilename);
      output.writeBytes(extraField);
      output.writeBytes(encodedFileComment);
    }

    final numberOfThisDisk = 0;
    final diskWithTheStartOfTheCentralDirectory = 0;
    final totalCentralDirectoryEntriesOnThisDisk = files.length;
    final totalCentralDirectoryEntries = files.length;
    final centralDirectorySize = output.length - centralDirPosition;
    final centralDirectoryOffset = centralDirPosition;

    output.writeUint32(ZipDirectory.signature);
    output.writeUint16(numberOfThisDisk);
    output.writeUint16(diskWithTheStartOfTheCentralDirectory);
    output.writeUint16(totalCentralDirectoryEntriesOnThisDisk);
    output.writeUint16(totalCentralDirectoryEntries);
    output.writeUint32(centralDirectorySize);
    output.writeUint32(centralDirectoryOffset);
    output.writeUint16(encodedComment.length);
    output.writeBytes(encodedComment);
  }

  static const int VERSION = 20;

  // enum OS
  static const int OS_MSDOS = 0;
  static const int OS_UNIX = 3;
  static const int OS_MACINTOSH = 7;
}
