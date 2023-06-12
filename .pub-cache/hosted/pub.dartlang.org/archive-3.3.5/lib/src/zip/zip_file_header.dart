import '../util/input_stream.dart';
import 'zip_file.dart';

class ZipFileHeader {
  static const int SIGNATURE = 0x02014b50;
  int versionMadeBy = 0; // 2 bytes
  int versionNeededToExtract = 0; // 2 bytes
  int generalPurposeBitFlag = 0; // 2 bytes
  int compressionMethod = 0; // 2 bytes
  int lastModifiedFileTime = 0; // 2 bytes
  int lastModifiedFileDate = 0; // 2 bytes
  int? crc32; // 4 bytes
  int? compressedSize; // 4 bytes
  int? uncompressedSize; // 4 bytes
  int? diskNumberStart; // 2 bytes
  int? internalFileAttributes; // 2 bytes
  int? externalFileAttributes; // 4 bytes
  int? localHeaderOffset; // 4 bytes
  String filename = '';
  List<int> extraField = [];
  String fileComment = '';
  ZipFile? file;

  ZipFileHeader([InputStreamBase? input, InputStreamBase? bytes,
                 String? password]) {
    if (input != null) {
      versionMadeBy = input.readUint16();
      versionNeededToExtract = input.readUint16();
      generalPurposeBitFlag = input.readUint16();
      compressionMethod = input.readUint16();
      lastModifiedFileTime = input.readUint16();
      lastModifiedFileDate = input.readUint16();
      crc32 = input.readUint32();
      compressedSize = input.readUint32();
      uncompressedSize = input.readUint32();
      final fnameLen = input.readUint16();
      final extraLen = input.readUint16();
      final commentLen = input.readUint16();
      diskNumberStart = input.readUint16();
      internalFileAttributes = input.readUint16();
      externalFileAttributes = input.readUint32();
      localHeaderOffset = input.readUint32();

      if (fnameLen > 0) {
        filename = input.readString(size: fnameLen);
      }

      if (extraLen > 0) {
        final extra = input.readBytes(extraLen);
        extraField = extra.toUint8List();
        // Rewind to start of the extra fields to read field by field.
        extra.rewind(extraLen);

        final id = extra.readUint16();
        var size = extra.readUint16();
        if (id == 1) {
          // Zip64 extended information
          // The following is the layout of the zip64 extended
          // information "extra" block. If one of the size or
          // offset fields in the Local or Central directory
          // record is too small to hold the required data,
          // a Zip64 extended information record is created.
          // The order of the fields in the zip64 extended
          // information record is fixed, but the fields MUST
          // only appear if the corresponding Local or Central
          // directory record field is set to 0xFFFF or 0xFFFFFFFF.
          // Original
          // Size       8 bytes    Original uncompressed file size
          // Compressed
          // Size       8 bytes    Size of compressed data
          // Relative Header
          // Offset     8 bytes    Offset of local header record
          // Disk Start
          // Number     4 bytes    Number of the disk on which
          // this file starts
          if (size >= 8 && uncompressedSize == 0xFFFFFFFF) {
            uncompressedSize = extra.readUint64();
            size -= 8;
          }
          if (size >= 8 && compressedSize == 0xFFFFFFFF) {
            compressedSize = extra.readUint64();
            size -= 8;
          }
          if (size >= 8 && localHeaderOffset == 0xFFFFFFFF) {
            localHeaderOffset = extra.readUint64();
            size -= 8;
          }
          if (size >= 4 && diskNumberStart == 0xFFFF) {
            diskNumberStart = extra.readUint32();
            size -= 4;
          }
        }
      }

      if (commentLen > 0) {
        fileComment = input.readString(size: commentLen);
      }

      if (bytes != null) {
        bytes.position = localHeaderOffset!;
        file = ZipFile(bytes, this, password);
      }
    }
  }

  @override
  String toString() => filename;
}
