import 'util/adler32.dart';
import 'util/byte_order.dart';
import 'util/input_stream.dart';
import 'util/output_stream.dart';
import 'zlib/deflate.dart';

class ZLibEncoder {
  static const int DEFLATE = 8;

  const ZLibEncoder();

  List<int> encode(List<int> data, {int? level, OutputStreamBase? output}) {
    output = output ?? OutputStream(byteOrder: BIG_ENDIAN);

    // Compression Method and Flags
    final cm = DEFLATE;
    final cinfo = 7; //2^(7+8) = 32768 window size

    final cmf = (cinfo << 4) | cm;
    output.writeByte(cmf);

    // 0x01, (00 0 00001) (FLG)
    // bits 0 to 4  FCHECK  (check bits for CMF and FLG)
    // bit  5       FDICT   (preset dictionary)
    // bits 6 to 7  FLEVEL  (compression level)
    // FCHECK is set such that (cmf * 256 + flag) must be a multiple of 31.
    final fdict = 0;
    final flevel = 0;
    var flag = ((flevel & 0x3) << 7) | ((fdict & 0x1) << 5);
    var fcheck = 0;
    final cmf256 = cmf * 256;
    while ((cmf256 + (flag | fcheck)) % 31 != 0) {
      fcheck++;
    }
    flag |= fcheck;
    output.writeByte(flag);

    final adler32 = getAdler32(data);

    final input = InputStream(data, byteOrder: BIG_ENDIAN);

    final compressed = Deflate.buffer(input, level: level).getBytes();
    output.writeBytes(compressed);

    output.writeUint32(adler32);

    output.flush();

    if (output is OutputStream) {
      return output.getBytes();
    }
    return [];
  }
}
