import 'dart:typed_data';

import '../animation.dart';
import '../image.dart';
import 'bmp_decoder.dart';
import 'bmp_encoder.dart';
import 'cur_encoder.dart';
import 'decoder.dart';
import 'exr_decoder.dart';
import 'gif_decoder.dart';
import 'gif_encoder.dart';
import 'ico_decoder.dart';
import 'ico_encoder.dart';
import 'jpeg_decoder.dart';
import 'jpeg_encoder.dart';
import 'png_decoder.dart';
import 'png_encoder.dart';
import 'psd_decoder.dart';
import 'tga_decoder.dart';
import 'tga_encoder.dart';
import 'tiff_decoder.dart';
import 'webp_decoder.dart';

/// Find a [Decoder] that is able to decode the given image [data].
/// Use this is you don't know the type of image it is. Since this will
/// validate the image against all known decoders, it is potentially very slow.
Decoder? findDecoderForData(List<int> data) {
  // The various decoders will be creating a Uint8List for their InputStream
  // if the data isn't already that type, so do it once here to avoid having to
  // do it multiple times.
  final bytes = data is Uint8List ? data : Uint8List.fromList(data);

  final jpg = JpegDecoder();
  if (jpg.isValidFile(bytes)) {
    return jpg;
  }

  final png = PngDecoder();
  if (png.isValidFile(bytes)) {
    return png;
  }

  final gif = GifDecoder();
  if (gif.isValidFile(bytes)) {
    return gif;
  }

  final webp = WebPDecoder();
  if (webp.isValidFile(bytes)) {
    return webp;
  }

  final tiff = TiffDecoder();
  if (tiff.isValidFile(bytes)) {
    return tiff;
  }

  final psd = PsdDecoder();
  if (psd.isValidFile(bytes)) {
    return psd;
  }

  final exr = ExrDecoder();
  if (exr.isValidFile(bytes)) {
    return exr;
  }

  final bmp = BmpDecoder();
  if (bmp.isValidFile(bytes)) {
    return bmp;
  }

  final tga = TgaDecoder();
  if (tga.isValidFile(bytes)) {
    return tga;
  }

  final ico = IcoDecoder();
  if (ico.isValidFile(bytes)) {
    return ico;
  }

  return null;
}

/// Decode the given image file bytes by first identifying the format of the
/// file and using that decoder to decode the file into a single frame [Image].
Image? decodeImage(List<int> data) {
  final decoder = findDecoderForData(data);
  if (decoder == null) {
    return null;
  }
  return decoder.decodeImage(data);
}

/// Decode the given image file bytes by first identifying the format of the
/// file and using that decoder to decode the file into an [Animation]
/// containing one or more [Image] frames.
Animation? decodeAnimation(List<int> data) {
  final decoder = findDecoderForData(data);
  if (decoder == null) {
    return null;
  }
  return decoder.decodeAnimation(data);
}

/// Return the [Decoder] that can decode image with the given [name],
/// by looking at the file extension. See also [findDecoderForData] to
/// determine the decoder to use given the bytes of the file.
Decoder? getDecoderForNamedImage(String name) {
  final n = name.toLowerCase();
  if (n.endsWith('.jpg') || n.endsWith('.jpeg')) {
    return JpegDecoder();
  }
  if (n.endsWith('.png')) {
    return PngDecoder();
  }
  if (n.endsWith('.tga')) {
    return TgaDecoder();
  }
  if (n.endsWith('.webp')) {
    return WebPDecoder();
  }
  if (n.endsWith('.gif')) {
    return GifDecoder();
  }
  if (n.endsWith('.tif') || n.endsWith('.tiff')) {
    return TiffDecoder();
  }
  if (n.endsWith('.psd')) {
    return PsdDecoder();
  }
  if (n.endsWith('.exr')) {
    return ExrDecoder();
  }
  if (n.endsWith('.bmp')) {
    return BmpDecoder();
  }
  if (n.endsWith('.ico')) {
    return IcoDecoder();
  }
  return null;
}

/// Identify the format of the image using the file extension of the given
/// [name], and decode the given file [bytes] to an [Animation] with one or more
/// [Image] frames. See also [decodeAnimation].
Animation? decodeNamedAnimation(List<int> bytes, String name) {
  final decoder = getDecoderForNamedImage(name);
  if (decoder == null) {
    return null;
  }
  return decoder.decodeAnimation(bytes);
}

/// Identify the format of the image using the file extension of the given
/// [name], and decode the given file [bytes] to a single frame [Image]. See
/// also [decodeImage].
Image? decodeNamedImage(List<int> bytes, String name) {
  final decoder = getDecoderForNamedImage(name);
  if (decoder == null) {
    return null;
  }
  return decoder.decodeImage(bytes);
}

/// Identify the format of the image and encode it with the appropriate
/// [Encoder].
List<int>? encodeNamedImage(Image image, String name) {
  final n = name.toLowerCase();
  if (n.endsWith('.jpg') || n.endsWith('.jpeg')) {
    return encodeJpg(image);
  }
  if (n.endsWith('.png')) {
    return encodePng(image);
  }
  if (n.endsWith('.tga')) {
    return encodeTga(image);
  }
  if (n.endsWith('.gif')) {
    return encodeGif(image);
  }
  if (n.endsWith('.cur')) {
    return encodeCur(image);
  }
  if (n.endsWith('.ico')) {
    return encodeIco(image);
  }
  if (n.endsWith('.bmp')) {
    return encodeBmp(image);
  }
  return null;
}

/// Decode a JPG formatted image.
Image? decodeJpg(List<int> bytes) => JpegDecoder().decodeImage(bytes);

/// Renamed to [decodeJpg], left for backward compatibility.
Image? readJpg(List<int> bytes) => decodeJpg(bytes);

/// Encode an image to the JPEG format.
List<int> encodeJpg(Image image, {int quality = 100}) =>
    JpegEncoder(quality: quality).encodeImage(image);

/// Renamed to [encodeJpg], left for backward compatibility.
List<int> writeJpg(Image image, {int quality = 100}) =>
    encodeJpg(image, quality: quality);

/// Decode a PNG formatted image.
Image? decodePng(List<int> bytes) => PngDecoder().decodeImage(bytes);

/// Decode a PNG formatted animation.
Animation? decodePngAnimation(List<int> bytes) =>
    PngDecoder().decodeAnimation(bytes);

/// Renamed to [decodePng], left for backward compatibility.
Image? readPng(List<int> bytes) => decodePng(bytes);

/// Encode an image to the PNG format.
List<int> encodePng(Image image, {int level = 6}) =>
    PngEncoder(level: level).encodeImage(image);

/// Encode an animation to the PNG format.
List<int>? encodePngAnimation(Animation anim, {int level = 6}) =>
    PngEncoder(level: level).encodeAnimation(anim);

/// Renamed to [encodePng], left for backward compatibility.
List<int> writePng(Image image, {int level = 6}) =>
    encodePng(image, level: level);

/// Decode a Targa formatted image.
Image? decodeTga(List<int> bytes) => TgaDecoder().decodeImage(bytes);

/// Renamed to [decodeTga], left for backward compatibility.
Image? readTga(List<int> bytes) => decodeTga(bytes);

/// Encode an image to the Targa format.
List<int> encodeTga(Image image) => TgaEncoder().encodeImage(image);

/// Renamed to [encodeTga], left for backward compatibility.
List<int> writeTga(Image image) => encodeTga(image);

/// Decode a WebP formatted image (first frame for animations).
Image? decodeWebP(List<int> bytes) => WebPDecoder().decodeImage(bytes);

/// Decode an animated WebP file. If the webp isn't animated, the animation
/// will contain a single frame with the webp's image.
Animation? decodeWebPAnimation(List<int> bytes) =>
    WebPDecoder().decodeAnimation(bytes);

/// Decode a GIF formatted image (first frame for animations).
Image? decodeGif(List<int> bytes) => GifDecoder().decodeImage(bytes);

/// Decode an animated GIF file. If the GIF isn't animated, the animation
/// will contain a single frame with the GIF's image.
Animation? decodeGifAnimation(List<int> bytes) =>
    GifDecoder().decodeAnimation(bytes);

/// Encode an image to the GIF format.
///
/// The [samplingFactor] specifies the sampling factor for
/// NeuQuant image quantization. It is responsible for reducing
/// the amount of unique colors in your images to 256.
/// According to https://scientificgems.wordpress.com/stuff/neuquant-fast-high-quality-image-quantization/,
/// a sampling factor of 10 gives you a reasonable trade-off between
/// image quality and quantization speed.
/// If you know that you have less than 256 colors in your frames
/// anyway, you should supply a very large [samplingFactor] for maximum performance.
List<int> encodeGif(Image image, {int samplingFactor = 10}) =>
    GifEncoder(samplingFactor: samplingFactor).encodeImage(image);

/// Encode an animation to the GIF format.
///
/// The [samplingFactor] specifies the sampling factor for
/// NeuQuant image quantization. It is responsible for reducing
/// the amount of unique colors in your images to 256.
/// According to https://scientificgems.wordpress.com/stuff/neuquant-fast-high-quality-image-quantization/,
/// a sampling factor of 10 gives you a reasonable trade-off between
/// image quality and quantization speed.
/// If you know that you have less than 256 colors in your frames
/// anyway, you should supply a very large [samplingFactor] for maximum performance.
///
/// Here, `30` is used a default value for the [samplingFactor] as
/// encoding animations is usually a process that takes longer than
/// encoding a single image (see [encodeGif]).
List<int>? encodeGifAnimation(Animation anim, {int samplingFactor = 30}) =>
    GifEncoder(samplingFactor: samplingFactor).encodeAnimation(anim);

/// Decode a TIFF formatted image.
Image? decodeTiff(List<int> bytes) => TiffDecoder().decodeImage(bytes);

/// Decode an multi-image (animated) TIFF file. If the tiff doesn't have
/// multiple images, the animation will contain a single frame with the tiff's
/// image.
Animation? decodeTiffAnimation(List<int> bytes) =>
    TiffDecoder().decodeAnimation(bytes);

/// Decode a Photoshop PSD formatted image.
Image? decodePsd(List<int> bytes) => PsdDecoder().decodeImage(bytes);

/// Decode an OpenEXR formatted image, tone-mapped using the
/// given [exposure] to a low-dynamic-range [Image].
Image? decodeExr(List<int> bytes, {double exposure = 1.0}) =>
    ExrDecoder(exposure: exposure).decodeImage(bytes);

/// Decode a BMP formatted image.
Image? decodeBmp(List<int> bytes) => BmpDecoder().decodeImage(bytes);

// Encode an image to the BMP format.
List<int> encodeBmp(Image image) => BmpEncoder().encodeImage(image);

/// Encode an image to the CUR format.
List<int> encodeCur(Image image) => CurEncoder().encodeImage(image);

/// Encode a list of images to the CUR format.
List<int> encodeCurImages(List<Image> images) =>
    CurEncoder().encodeImages(images);

/// Encode an image to the ICO format.
List<int> encodeIco(Image image) => IcoEncoder().encodeImage(image);

/// Encode a list of images to the ICO format.
List<int> encodeIcoImages(List<Image> images) =>
    IcoEncoder().encodeImages(images);

/// Decode an ICO image.
Image? decodeIco(List<int> bytes) => IcoDecoder().decodeImage(bytes);
