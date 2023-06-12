import 'dart:typed_data';
import '../util/archive_exception.dart';
import '../util/input_stream.dart';
import '../util/output_stream.dart';

/*  File Header (512 bytes)
 *  Offset Size Field
 *      Pre-POSIX Header
 *  0     100  File name
 *  100   8    File mode
 *  108   8    Owner's numeric user ID
 *  116   8    Group's numeric user ID
 *  124   12   File size in bytes (octal basis)
 *  136   12   Last modification time in numeric Unix time format (octal)
 *  148   8    Checksum for header record
 *  156   1    Type flag
 *  157   100  Name of linked file
 *      UStar Format
 *  257   6    UStar indicator "ustar"
 *  263   2    UStar version "00"
 *  265   32   Owner user name
 *  297   32   Owner group name
 *  329   8    Device major number
 *  337   8    Device minor number
 *  345   155  Filename prefix
 */

class TarFile {
  static const String TYPE_NORMAL_FILE = '0';
  static const String TYPE_HARD_LINK = '1';
  static const String TYPE_SYMBOLIC_LINK = '2';
  static const String TYPE_CHAR_SPEC = '3';
  static const String TYPE_BLOCK_SPEC = '4';
  static const String TYPE_DIRECTORY = '5';
  static const String TYPE_FIFO = '6';
  static const String TYPE_CONT_FILE = '7';
  // global extended header with meta data (POSIX.1-2001)
  static const String TYPE_G_EX_HEADER = 'g';
  static const String TYPE_G_EX_HEADER2 = 'G';
  // extended header with meta data for the next file in the archive
  // (POSIX.1-2001)
  static const String TYPE_EX_HEADER = 'x';
  static const String TYPE_EX_HEADER2 = 'X';

  // Pre-POSIX Format
  late String filename; // 100 bytes
  int mode = 644; // 8 bytes
  int ownerId = 0; // 8 bytes
  int groupId = 0; // 8 bytes
  int fileSize = 0; // 12 bytes
  int lastModTime = 0; // 12 bytes
  int checksum = 0; // 8 bytes
  String typeFlag = '0'; // 1 byte
  late String nameOfLinkedFile; // 100 bytes
  // UStar Format
  String ustarIndicator = ''; // 6 bytes (ustar)
  String ustarVersion = ''; // 2 bytes (00)
  String ownerUserName = ''; // 32 bytes
  String ownerGroupName = ''; // 32 bytes
  int deviceMajorNumber = 0; // 8 bytes
  int deviceMinorNumber = 0; // 8 bytes
  String filenamePrefix = ''; // 155 bytes
  InputStreamBase? _rawContent;
  dynamic _content;

  TarFile();

  TarFile.read(InputStreamBase input, {bool storeData = true}) {
    final header = input.readBytes(512);

    // The name, linkname, magic, uname, and gname are null-terminated
    // character strings. All other fields are zero-filled octal numbers in
    // ASCII. Each numeric field of width w contains w minus 1 digits, and a
    // null.
    filename = _parseString(header, 100);
    mode = _parseInt(header, 8);
    ownerId = _parseInt(header, 8);
    groupId = _parseInt(header, 8);
    fileSize = _parseInt(header, 12);
    lastModTime = _parseInt(header, 12);
    checksum = _parseInt(header, 8);
    typeFlag = _parseString(header, 1);
    nameOfLinkedFile = _parseString(header, 100);

    ustarIndicator = _parseString(header, 6);
    if (ustarIndicator == 'ustar') {
      ustarVersion = _parseString(header, 2);
      ownerUserName = _parseString(header, 32);
      ownerGroupName = _parseString(header, 32);
      deviceMajorNumber = _parseInt(header, 8);
      deviceMinorNumber = _parseInt(header, 8);
    }

    if (storeData || filename == '././@LongLink') {
      _rawContent = input.readBytes(fileSize);
    } else {
      input.skip(fileSize);
    }

    if (isFile && fileSize > 0) {
      final remainder = fileSize % 512;
      var skiplen = 0;
      if (remainder != 0) {
        skiplen = 512 - remainder;
        input.skip(skiplen);
      }
    }
  }

  bool get isFile => typeFlag != TYPE_DIRECTORY;

  bool get isSymLink => typeFlag == TYPE_SYMBOLIC_LINK;

  InputStreamBase? get rawContent => _rawContent;

  dynamic get content {
    _content ??= _rawContent!.toUint8List();
    return _content;
  }

  List<int> get contentBytes => content as List<int>;

  set content(dynamic data) => _content = data;

  int get size => _content != null
      ? _content.length as int
      : _rawContent != null
          ? _rawContent!.length
          : 0;

  @override
  String toString() => '[$filename, $mode, $fileSize]';

  void write(dynamic output) {
    fileSize = size;

    // The name, linkname, magic, uname, and gname are null-terminated
    // character strings. All other fields are zero-filled octal numbers in
    // ASCII. Each numeric field of width w contains w minus 1 digits, and a null.
    final header = OutputStream();
    _writeString(header, filename, 100);
    _writeInt(header, mode, 8);
    _writeInt(header, ownerId, 8);
    _writeInt(header, groupId, 8);
    _writeInt(header, fileSize, 12);
    _writeInt(header, lastModTime, 12);
    _writeString(header, '        ', 8); // checksum placeholder
    _writeString(header, typeFlag, 1);

    final remainder = 512 - header.length;
    var nulls = Uint8List(remainder); // typed arrays default to 0.
    header.writeBytes(nulls);

    final headerBytes = header.getBytes();

    // The checksum is calculated by taking the sum of the unsigned byte values
    // of the header record with the eight checksum bytes taken to be ascii
    // spaces (decimal value 32). It is stored as a six digit octal number
    // with leading zeroes followed by a NUL and then a space.
    var sum = 0;
    for (var b in headerBytes) {
      sum += b;
    }

    var sumStr = sum.toRadixString(8); // octal basis
    while (sumStr.length < 6) {
      sumStr = '0' + sumStr;
    }

    var checksumIndex = 148; // checksum is at 148th byte
    for (var i = 0; i < 6; ++i) {
      headerBytes[checksumIndex++] = sumStr.codeUnits[i];
    }
    headerBytes[154] = 0;
    headerBytes[155] = 32;

    output.writeBytes(header.getBytes());

    if (_content is List<int>) {
      output.writeBytes(_content);
    } else if (_content is InputStreamBase) {
      output.writeInputStream(_content);
    } else if (_rawContent != null) {
      output.writeInputStream(_rawContent);
    }

    if (isFile && fileSize > 0) {
      // Pad to 512-byte boundary
      final remainder = fileSize % 512;
      if (remainder != 0) {
        final skiplen = 512 - remainder;
        nulls = Uint8List(skiplen); // typed arrays default to 0.
        output.writeBytes(nulls);
      }
    }
  }

  int _parseInt(InputStreamBase input, int numBytes) {
    var s = _parseString(input, numBytes);
    if (s.isEmpty) {
      return 0;
    }
    var x = 0;
    try {
      x = int.parse(s, radix: 8);
    } catch (e) {
      // Catch to fix a crash with bad group_id and owner_id values.
      // This occurs for POSIX archives, where some attributes like uid and
      // gid are stored in a separate PaxHeader file.
    }
    return x;
  }

  String _parseString(InputStreamBase input, int numBytes) {
    try {
      final codes = input.readBytes(numBytes).toUint8List();
      final r = codes.indexOf(0);
      final s = codes.sublist(0, r < 0 ? null : r);
      final str = String.fromCharCodes(s).trim();
      return str;
    } catch (e) {
      throw ArchiveException('Invalid Archive');
    }
  }

  void _writeString(OutputStream output, String value, int numBytes) {
    final codes = List<int>.filled(numBytes, 0);
    final end = numBytes < value.length ? numBytes : value.length;
    codes.setRange(0, end, value.codeUnits);
    output.writeBytes(codes);
  }

  void _writeInt(OutputStream output, int value, int numBytes) {
    var s = value.toRadixString(8);
    while (s.length < numBytes - 1) {
      s = '0' + s;
    }
    _writeString(output, s, numBytes);
  }
}
