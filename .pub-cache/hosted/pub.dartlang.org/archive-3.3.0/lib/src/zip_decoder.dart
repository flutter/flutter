import 'util/archive_exception.dart';
import 'util/crc32.dart';
import 'util/input_stream.dart';
import 'zip/zip_directory.dart';
import 'zip/zip_file.dart';
import 'archive.dart';
import 'archive_file.dart';

/// Decode a zip formatted buffer into an [Archive] object.
class ZipDecoder {
  late ZipDirectory directory;

  Archive decodeBytes(List<int> data, {bool verify = false, String? password}) {
    return decodeBuffer(InputStream(data), verify: verify, password: password);
  }

  Archive decodeBuffer(InputStreamBase input,
      {bool verify = false, String? password}) {
    directory = ZipDirectory.read(input, password: password);
    final archive = Archive();

    for (final zfh in directory.fileHeaders) {
      final zf = zfh.file!;

      // The attributes are stored in base 8
      final mode = zfh.externalFileAttributes!;
      final compress = zf.compressionMethod != ZipFile.STORE;

      if (verify) {
        final computedCrc = getCrc32(zf.content);
        if (computedCrc != zf.crc32) {
          throw ArchiveException('Invalid CRC for file in archive.');
        }
      }

      dynamic content = zf.rawContent;
      var file = ArchiveFile(
          zf.filename, zf.uncompressedSize!, content, zf.compressionMethod);

      file.mode = mode >> 16;

      // see https://github.com/brendan-duncan/archive/issues/21
      // UNIX systems has a creator version of 3 decimal at 1 byte offset
      if (zfh.versionMadeBy >> 8 == 3) {
        //final bool isDirectory = file.mode & 0x7000 == 0x4000;
        final isFile = file.mode & 0x3F000 == 0x8000;
        file.isFile = isFile;
      } else {
        file.isFile = !file.name.endsWith('/');
      }

      file.crc32 = zf.crc32;
      file.compress = compress;
      file.lastModTime = zf.lastModFileDate << 16 | zf.lastModFileTime;

      archive.addFile(file);
    }

    return archive;
  }
}
