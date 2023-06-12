import 'dart:typed_data';

import '../image/image.dart';
import 'decode_info.dart';
import 'decoder.dart';
import 'psd/psd_image.dart';

/// Decode a Photoshop PSD image.
class PsdDecoder extends Decoder {
  PsdImage? info;

  /// A light-weight function to test if the given file is able to be decoded
  /// by this Decoder.
  @override
  bool isValidFile(Uint8List bytes) => PsdImage(bytes).isValid;

  /// Decode a raw PSD image without rendering it to a flat image.
  PsdImage? decodePsd(Uint8List bytes) {
    final psd = PsdImage(bytes);
    return psd.decode() ? psd : null;
  }

  /// Decode the file and extract a single image from it. If the file is
  /// animated, the specified [frame] will be decoded. If there was a problem
  /// decoding the file, null is returned.
  @override
  Image? decode(Uint8List bytes, {int? frame}) {
    if (startDecode(bytes) == null) {
      return null;
    }

    final len = numFrames();
    if (len == 1 || frame != null) {
      return decodeFrame(frame ?? 0);
    }

    Image? firstImage;
    for (var i = 0; i < len; ++i) {
      final frame = decodeFrame(i);
      if (frame == null) {
        continue;
      }
      if (firstImage == null) {
        firstImage = frame;
        frame.frameType = FrameType.page;
      } else {
        firstImage.addFrame(frame);
      }
    }

    return firstImage;
  }

  /// Start decoding the data as an animation sequence, but don't actually
  /// process the frames until they are requested with decodeFrame.
  @override
  DecodeInfo? startDecode(Uint8List bytes) => info = PsdImage(bytes);

  /// How many frames are available to be decoded. [startDecode] should have
  /// been called first. Non animated image files will have a single frame.
  @override
  int numFrames() => info?.numFrames ?? 0;

  /// Decode a single frame from the data stat was set with [startDecode].
  /// If [frame] is out of the range of available frames, null is returned.
  /// Non animated image files will only have [frame] 0.
  @override
  Image? decodeFrame(int frame) => info?.decodeImage();
}
