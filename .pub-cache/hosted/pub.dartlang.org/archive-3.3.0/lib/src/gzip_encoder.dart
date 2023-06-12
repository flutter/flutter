import 'util/output_stream.dart';
import 'zlib/deflate.dart';
import 'util/input_stream.dart';

class GZipEncoder {
  static const int SIGNATURE = 0x8b1f;
  static const int DEFLATE = 8;
  static const int FLAG_TEXT = 0x01;
  static const int FLAG_HCRC = 0x02;
  static const int FLAG_EXTRA = 0x04;
  static const int FLAG_NAME = 0x08;
  static const int FLAG_COMMENT = 0x10;

  // enum OperatingSystem
  static const int OS_FAT = 0;
  static const int OS_AMIGA = 1;
  static const int OS_VMS = 2;
  static const int OS_UNIX = 3;
  static const int OS_VM_CMS = 4;
  static const int OS_ATARI_TOS = 5;
  static const int OS_HPFS = 6;
  static const int OS_MACINTOSH = 7;
  static const int OS_Z_SYSTEM = 8;
  static const int OS_CP_M = 9;
  static const int OS_TOPS_20 = 10;
  static const int OS_NTFS = 11;
  static const int OS_QDOS = 12;
  static const int OS_ACORN_RISCOS = 13;
  static const int OS_UNKNOWN = 255;

  List<int>? encode(dynamic data, {int? level, dynamic output}) {
    dynamic outputStream = output ?? OutputStream();

    // The GZip format has the following structure:
    // Offset   Length   Contents
    // 0      2 bytes  magic header  0x1f, 0x8b (\037 \213)
    // 2      1 byte   compression method
    //                  0: store (copied)
    //                  1: compress
    //                  2: pack
    //                  3: lzh
    //                  4..7: reserved
    //                  8: deflate
    // 3      1 byte   flags
    //                  bit 0 set: file probably ascii text
    //                  bit 1 set: continuation of multi-part gzip file, part number present
    //                  bit 2 set: extra field present
    //                  bit 3 set: original file name present
    //                  bit 4 set: file comment present
    //                  bit 5 set: file is encrypted, encryption header present
    //                  bit 6,7:   reserved
    // 4      4 bytes  file modification time in Unix format
    // 8      1 byte   extra flags (depend on compression method)
    // 9      1 byte   OS type
    // [
    //        2 bytes  optional part number (second part=1)
    // ]?
    // [
    //        2 bytes  optional extra field length (e)
    //       (e)bytes  optional extra field
    // ]?
    // [
    //          bytes  optional original file name, zero terminated
    // ]?
    // [
    //          bytes  optional file comment, zero terminated
    // ]?
    // [
    //       12 bytes  optional encryption header
    // ]?
    //          bytes  compressed data
    //        4 bytes  crc32
    //        4 bytes  uncompressed input size modulo 2^32

    outputStream.writeUint16(SIGNATURE);
    outputStream.writeByte(DEFLATE);

    var flags = 0;
    var fileModTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    var extraFlags = 0;
    var osType = OS_UNKNOWN;

    outputStream.writeByte(flags);
    outputStream.writeUint32(fileModTime);
    outputStream.writeByte(extraFlags);
    outputStream.writeByte(osType);

    Deflate deflate;
    if (data is List<int>) {
      deflate = Deflate(data, level: level, output: outputStream);
    } else {
      deflate = Deflate.buffer(data as InputStreamBase,
          level: level, output: outputStream);
    }

    if (outputStream is! OutputStream) {
      deflate.finish();
    }

    outputStream.writeUint32(deflate.crc32);

    outputStream.writeUint32(data.length);

    if (outputStream is OutputStreamBase) {
      outputStream.flush();
    }

    if (outputStream is OutputStream) {
      return outputStream.getBytes();
    }
    return null;
  }
}
