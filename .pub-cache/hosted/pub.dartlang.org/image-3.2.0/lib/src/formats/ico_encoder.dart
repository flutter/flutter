import '../image.dart';
import '../util/output_buffer.dart';
import 'encoder.dart';
import 'png_encoder.dart';

abstract class WinEncoder extends Encoder {
  int get type;

  int colorPlanesOrXHotSpot(int index);

  int bitsPerPixelOrYHotSpot(int index);

  @override
  List<int> encodeImage(Image image) => encodeImages([image]);

  List<int> encodeImages(List<Image> images) {
    final count = images.length;

    final out = OutputBuffer();

    // header
    out.writeUint16(0); // reserved
    out.writeUint16(type); // type: ICO => 1; CUR => 2
    out.writeUint16(count);

    var offset = 6 + count * 16; // file header with image directory byte size

    final imageDatas = [<int>[]];

    var i = 0;
    for (var img in images) {
      if (img.width > 256 || img.height > 256) {
        throw Exception('ICO and CUR support only sizes until 256');
      }

      out.writeByte(img.width); // image width in pixels
      out.writeByte(img.height); // image height in pixels
      // Color count, should be 0 if more than 256 colors
      out.writeByte(0);
      out.writeByte(0); // Reserved
      out.writeUint16(colorPlanesOrXHotSpot(i));
      out.writeUint16(bitsPerPixelOrYHotSpot(i));

      // Use png instead of bmp encoded data, it's supported since Windows Vista
      final data = PngEncoder().encodeImage(img);

      out.writeUint32(data.length); // size of the image's data in bytes
      out.writeUint32(offset); // offset of data from the beginning of the file

      // add the size of bytes to get the new begin of the next image
      offset += data.length;
      i++;
      imageDatas.add(data);
    }

    for (var imageData in imageDatas) {
      out.writeBytes(imageData);
    }

    return out.getBytes();
  }
}

class IcoEncoder extends WinEncoder {
  @override
  int colorPlanesOrXHotSpot(int index) => 0;

  @override
  int bitsPerPixelOrYHotSpot(int index) => 32;

  @override
  int get type => 1;
}
