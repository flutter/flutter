import 'dart:typed_data';

import '../image/image.dart';
import '../util/output_buffer.dart';
import 'encoder.dart';

/// Encode a TGA image. This only supports the 24-bit uncompressed format.
class TgaEncoder extends Encoder {
  @override
  Uint8List encode(Image image, {bool singleFrame = false}) {
    final out = OutputBuffer(bigEndian: true);

    final header = List<int>.filled(18, 0);
    header[2] = 2;
    header[12] = image.width & 0xff;
    header[13] = (image.width >> 8) & 0xff;
    header[14] = image.height & 0xff;
    header[15] = (image.height >> 8) & 0xff;
    final nc = image.palette?.numChannels ?? image.numChannels;
    header[16] = nc == 3 ? 24 : 32;

    out.writeBytes(header);

    if (nc == 4) {
      for (var y = image.height - 1; y >= 0; --y) {
        for (var x = 0; x < image.width; ++x) {
          final c = image.getPixel(x, y);
          out
            ..writeByte(c.b as int)
            ..writeByte(c.g as int)
            ..writeByte(c.r as int)
            ..writeByte(c.a as int);
        }
      }
    } else {
      for (var y = image.height - 1; y >= 0; --y) {
        for (var x = 0; x < image.width; ++x) {
          final c = image.getPixel(x, y);
          out
            ..writeByte(c.b as int)
            ..writeByte(c.g as int)
            ..writeByte(c.r as int);
        }
      }
    }

    return out.getBytes();
  }
}
