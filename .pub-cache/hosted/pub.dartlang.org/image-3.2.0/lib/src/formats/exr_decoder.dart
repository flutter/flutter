import '../animation.dart';
import '../hdr/hdr_image.dart';
import '../hdr/hdr_to_image.dart';
import '../image.dart';
import 'decode_info.dart';
import 'decoder.dart';
import 'exr/exr_image.dart';

/// Decode an OpenEXR formatted image.
///
/// OpenEXR is a format developed by Industrial Light & Magic, with collaboration
/// from other companies such as Weta and Pixar, for storing high dynamic
/// range (HDR) images for use in digital visual effects production. It supports
/// a wide range of features, including 16-bit or 32-bit floating-point channels;
/// lossless and lossy data compression; arbitrary image channels for storing
/// any combination of data, such as red, green, blue, alpha, luminance and
/// chroma channels, depth, surface normal, motion vectors, etc. It can also
/// store images in scanline or tiled format; multiple views for stereo images;
/// multiple parts; etc.
///
/// Because OpenEXR is a high-dynamic-range (HDR) format, it must be converted
/// to a low-dynamic-range (LDR) image for display, or for use as an OpenGL
/// texture (for example). This process is called tone-mapping. Currently only
/// a simple tone-mapping function is provided with a single [exposure]
/// parameter. More tone-mapping functionality will be added.
class ExrDecoder extends Decoder {
  ExrImage? exrImage;

  /// Exposure for tone-mapping the hdr image to an [Image], applied during
  /// [decodeFrame].
  double exposure;
  double? gamma;
  bool? reinhard;
  double? bloomAmount;
  double? bloomRadius;

  ExrDecoder({this.exposure = 1.0});

  @override
  bool isValidFile(List<int> bytes) => ExrImage.isValidFile(bytes);

  @override
  DecodeInfo? startDecode(List<int> bytes) {
    exrImage = ExrImage(bytes);
    return exrImage;
  }

  @override
  int numFrames() => exrImage != null ? exrImage!.parts.length : 0;

  @override
  Image? decodeFrame(int frame) {
    if (exrImage == null) {
      return null;
    }

    return hdrToImage(exrImage!.getPart(frame).framebuffer, exposure: exposure);
  }

  @override
  HdrImage? decodeHdrFrame(int frame) {
    if (exrImage == null) {
      return null;
    }
    if (frame >= exrImage!.parts.length) {
      return null;
    }
    return exrImage!.parts[frame].framebuffer;
  }

  @override
  Image? decodeImage(List<int> bytes, {int frame = 0}) {
    if (startDecode(bytes) == null) {
      return null;
    }

    return decodeFrame(frame);
  }

  @override
  HdrImage? decodeHdrImage(List<int> bytes, {int frame = 0}) {
    if (startDecode(bytes) == null) {
      return null;
    }
    return decodeHdrFrame(frame);
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
