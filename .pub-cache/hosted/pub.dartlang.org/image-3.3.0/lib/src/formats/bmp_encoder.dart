import '../color.dart';
import '../image.dart';
import '../util/output_buffer.dart';
import 'bmp/bmp_info.dart';
import 'encoder.dart';

/// Encode a BMP image.
class BmpEncoder extends Encoder {
  @override
  List<int> encodeImage(Image image) {
    final out = OutputBuffer();

    final bytesPerPixel = image.channels == Channels.rgb ? 3 : 4;
    final bpp = bytesPerPixel * 8;
    final rgbSize = image.width * image.height * bytesPerPixel;
    const headerSize = 54;
    const headerInfoSize = 40;
    final fileSize = rgbSize + headerSize;

    out.writeUint16(BitmapFileHeader.BMP_HEADER_FILETYPE);
    out.writeUint32(fileSize);
    out.writeUint32(0); // reserved

    out.writeUint32(headerSize);
    out.writeUint32(headerInfoSize);
    out.writeUint32(image.width);
    out.writeUint32(-image.height);
    out.writeUint16(1); // planes
    out.writeUint16(bpp);
    out.writeUint32(0); // compress
    out.writeUint32(rgbSize);
    out.writeUint32(0); // hr
    out.writeUint32(0); // vr
    out.writeUint32(0); // colors
    out.writeUint32(0); // importantColors

    for (var y = 0, pi = 0; y < image.height; ++y) {
      for (var x = 0; x < image.width; ++x, ++pi) {
        var rgba = image[pi];
        out.writeByte(getBlue(rgba));
        out.writeByte(getGreen(rgba));
        out.writeByte(getRed(rgba));
        if (bytesPerPixel == 4)
          out.writeByte(getAlpha(rgba));
      }

      // Line padding
      if (bytesPerPixel != 4) {
        var padding = 4 - ((image.width * bytesPerPixel) % 4);
        if (padding != 4) {
          out.writeBytes(List.generate(padding - 1, (index) => 0x00));

          out.writeByte(0xFF);
        }
      }
    }

    return out.getBytes();
  }
}
