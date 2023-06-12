import '../color.dart';
import '../image.dart';
import '../util/output_buffer.dart';
import 'encoder.dart';

/// Encode a TGA image. This only supports the 24-bit uncompressed format.
class TgaEncoder extends Encoder {
  @override
  List<int> encodeImage(Image image) {
    final out = OutputBuffer(bigEndian: true);

    final header = List<int>.filled(18, 0);
    header[2] = 2;
    header[12] = image.width & 0xff;
    header[13] = (image.width >> 8) & 0xff;
    header[14] = image.height & 0xff;
    header[15] = (image.height >> 8) & 0xff;
    header[16] = image.channels == Channels.rgb ? 24 : 32;

    out.writeBytes(header);

    for (var y = image.height - 1; y >= 0; --y) {
      for (var x = 0; x < image.width; ++x) {
        final c = image.getPixel(x, y);
        out.writeByte(getBlue(c));
        out.writeByte(getGreen(c));
        out.writeByte(getRed(c));
        if (image.channels == Channels.rgba) {
          out.writeByte(getAlpha(c));
        }
      }
    }

    return out.getBytes();
  }
}
