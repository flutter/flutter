import '../animation.dart';
import '../color.dart';
import '../image.dart';
import '../util/input_buffer.dart';
import 'decode_info.dart';
import 'decoder.dart';
import 'tga/tga_info.dart';

/// Decode a TGA image. This only supports the 24-bit uncompressed format.
class TgaDecoder extends Decoder {
  TgaInfo? info;
  late InputBuffer input;

  /// Is the given file a valid TGA image?
  @override
  bool isValidFile(List<int> data) {
    final input = InputBuffer(data, bigEndian: true);

    final header = input.readBytes(18);
    if (header[2] != 2) {
      return false;
    }
    if (header[16] != 24 && header[16] != 32) {
      return false;
    }

    return true;
  }

  @override
  DecodeInfo? startDecode(List<int> bytes) {
    info = TgaInfo();
    input = InputBuffer(bytes, bigEndian: true);

    final header = input.readBytes(18);
    if (header[2] != 2) {
      return null;
    }
    if (header[16] != 24 && header[16] != 32) {
      return null;
    }

    info!.width = (header[12] & 0xff) | ((header[13] & 0xff) << 8);
    info!.height = (header[14] & 0xff) | ((header[15] & 0xff) << 8);
    info!.imageOffset = input.offset;
    info!.bpp = header[16];

    return info;
  }

  @override
  int numFrames() => info != null ? 1 : 0;

  @override
  Image? decodeFrame(int frame) {
    if (info == null) {
      return null;
    }

    input.offset = info!.imageOffset!;
    final image = Image(info!.width, info!.height, channels: Channels.rgb);
    for (var y = image.height - 1; y >= 0; --y) {
      for (var x = 0; x < image.width; ++x) {
        final b = input.readByte();
        final g = input.readByte();
        final r = input.readByte();
        final a = info!.bpp == 32 ? input.readByte() : 255;
        image.setPixel(x, y, getColor(r, g, b, a));
      }
    }

    return image;
  }

  @override
  Image? decodeImage(List<int> bytes, {int frame = 0}) {
    if (startDecode(bytes) == null) {
      return null;
    }

    return decodeFrame(frame);
  }

  @override
  Animation? decodeAnimation(List<int> bytes) {
    final image = decodeImage(bytes);
    if (image == null) {
      return null;
    }

    final anim = Animation();
    anim.width = image.width;
    anim.height = image.height;
    anim.addFrame(image);

    return anim;
  }
}
