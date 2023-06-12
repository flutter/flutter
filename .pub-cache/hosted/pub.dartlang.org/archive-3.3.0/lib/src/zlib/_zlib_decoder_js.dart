import '../util/adler32.dart';
import '../util/archive_exception.dart';
import '../util/byte_order.dart';
import '../util/input_stream.dart';
import 'inflate.dart';
import 'zlib_decoder_base.dart';

const platformZLibDecoder = _ZLibDecoder();

/// Decompress data with the zlib format decoder.
class _ZLibDecoder extends ZLibDecoderBase {
  static const int DEFLATE = 8;

  const _ZLibDecoder();

  @override
  List<int> decodeBytes(List<int> data, {bool verify = false}) {
    return decodeBuffer(InputStream(data, byteOrder: BIG_ENDIAN),
        verify: verify);
  }

  @override
  List<int> decodeBuffer(InputStream input, {bool verify = false}) {
    /*
     * The zlib format has the following structure:
     * CMF  1 byte
     * FLG 1 byte
     * [DICT_ID 4 bytes]? (if FLAG has FDICT (bit 5) set)
     * <compressed data>
     * ADLER32 4 bytes
     * ----
     * CMF:
     *    bits [0, 3] Compression Method, DEFLATE = 8
     *    bits [4, 7] Compression Info, base-2 logarithm of the LZ77 window
     *                size, minus eight (CINFO=7 indicates a 32K window size).
     * FLG:
     *    bits [0, 4] FCHECK (check bits for CMF and FLG)
     *    bits [5]    FDICT (preset dictionary)
     *    bits [6, 7] FLEVEL (compression level)
     */
    final cmf = input.readByte();
    final flg = input.readByte();

    final method = cmf & 8;
    final cinfo = (cmf >> 3) & 8; // ignore: unused_local_variable

    if (method != DEFLATE) {
      throw ArchiveException('Only DEFLATE compression supported: $method');
    }

    final fcheck = flg & 16; // ignore: unused_local_variable
    final fdict = (flg & 32) >> 5;
    final flevel = (flg & 64) >> 6; // ignore: unused_local_variable

    // FCHECK is set such that (cmf * 256 + flag) must be a multiple of 31.
    if (((cmf << 8) + flg) % 31 != 0) {
      throw ArchiveException('Invalid FCHECK');
    }

    if (fdict != 0) {
      /*dictid =*/ input.readUint32();
      throw ArchiveException('FDICT Encoding not currently supported');
    }

    // Inflate
    final buffer = Inflate.buffer(input).getBytes();

    // verify adler-32
    final adler32 = input.readUint32();
    if (verify) {
      final a = getAdler32(buffer);
      if (adler32 != a) {
        throw ArchiveException('Invalid adler-32 checksum');
      }
    }

    return buffer;
  }
}
