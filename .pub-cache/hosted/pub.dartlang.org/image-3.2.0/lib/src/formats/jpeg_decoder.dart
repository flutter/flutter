import '../animation.dart';
import '../image.dart';
import '../image_exception.dart';
import '../util/input_buffer.dart';
import 'decode_info.dart';
import 'decoder.dart';
import 'jpeg/jpeg_data.dart';
import 'jpeg/jpeg_info.dart';

/// Decode a jpeg encoded image.
class JpegDecoder extends Decoder {
  JpegInfo? info;
  InputBuffer? input;

  /// Is the given file a valid JPEG image?
  @override
  bool isValidFile(List<int> data) => JpegData().validate(data);

  @override
  DecodeInfo? startDecode(List<int> bytes) {
    input = InputBuffer(bytes, bigEndian: true);
    info = JpegData().readInfo(bytes);
    return info;
  }

  @override
  int numFrames() => info == null ? 0 : info!.numFrames;

  @override
  Image? decodeFrame(int frame) {
    if (input == null) {
      return null;
    }
    final jpeg = JpegData();
    jpeg.read(input!.buffer);
    if (jpeg.frames.length != 1) {
      throw ImageException('only single frame JPEGs supported');
    }

    return jpeg.getImage();
  }

  @override
  Image? decodeImage(List<int> bytes, {int frame = 0}) {
    final jpeg = JpegData();
    jpeg.read(bytes);

    if (jpeg.frames.length != 1) {
      throw ImageException('only single frame JPEGs supported');
    }

    return jpeg.getImage();
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
