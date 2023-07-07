import 'dart:typed_data';

import '../exif/exif_data.dart';
import '../filter/dither_image.dart';
import '../image/image.dart';
import '../util/file_access.dart';
import 'bmp_decoder.dart';
import 'bmp_encoder.dart';
import 'cur_encoder.dart';
import 'decoder.dart';
import 'encoder.dart';
import 'exr_decoder.dart';
import 'gif_decoder.dart';
import 'gif_encoder.dart';
import 'ico_decoder.dart';
import 'ico_encoder.dart';
import 'jpeg/jpeg_util.dart';
import 'jpeg_decoder.dart';
import 'jpeg_encoder.dart';
import 'png_decoder.dart';
import 'png_encoder.dart';
import 'psd_decoder.dart';
import 'pvr_decoder.dart';
import 'pvr_encoder.dart';
import 'tga_decoder.dart';
import 'tga_encoder.dart';
import 'tiff_decoder.dart';
import 'tiff_encoder.dart';
import 'webp_decoder.dart';

/// Return the [Decoder] that can decode image with the given [name],
/// by looking at the file extension.
Decoder? findDecoderForNamedImage(String name) {
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
  if (n.endsWith('.pvr')) {
    return PvrDecoder();
  }
  return null;
}

/// Return the [Encoder] that can decode image with the given [name],
/// by looking at the file extension.
Encoder? findEncoderForNamedImage(String name) {
  final n = name.toLowerCase();
  if (n.endsWith('.jpg') || n.endsWith('.jpeg')) {
    return JpegEncoder();
  }
  if (n.endsWith('.png')) {
    return PngEncoder();
  }
  if (n.endsWith('.tga')) {
    return TgaEncoder();
  }
  if (n.endsWith('.gif')) {
    return GifEncoder();
  }
  if (n.endsWith('.tif') || n.endsWith('.tiff')) {
    return TiffEncoder();
  }
  if (n.endsWith('.bmp')) {
    return BmpEncoder();
  }
  if (n.endsWith('.ico')) {
    return IcoEncoder();
  }
  if (n.endsWith('.cur')) {
    return IcoEncoder();
  }
  if (n.endsWith('.pvr')) {
    return PvrEncoder();
  }
  return null;
}

/// Find a [Decoder] that is able to decode the given image [data].
/// Use this is you don't know the type of image it is.
/// **WARNING** Since this will check the image data against all known decoders,
/// it is much slower than using an explicit decoder.
Decoder? findDecoderForData(List<int> data) {
  // The various decoders will be creating a Uint8List for their InputStream
  // if the data isn't already that type, so do it once here to avoid having
  // to do it multiple times.
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

  final pvr = PvrDecoder();
  if (pvr.isValidFile(bytes)) {
    return pvr;
  }

  return null;
}

/// Decode the given image file bytes by first identifying the format of the
/// file and using that decoder to decode the file into a single frame [Image].
/// **WARNING** Since this will check the image data against all known decoders,
/// it is much slower than using an explicit decoder.
Image? decodeImage(Uint8List data, {int? frame}) {
  final decoder = findDecoderForData(data);
  return decoder?.decode(data, frame: frame);
}

/// Decodes the given image file bytes, using the filename extension to
/// determine the decoder.
Image? decodeNamedImage(String path, Uint8List data, {int? frame}) {
  final decoder = findDecoderForNamedImage(path);
  if (decoder != null) {
    return decoder.decode(data, frame: frame);
  }
  return decodeImage(data, frame: frame);
}

/// Decode an image from a file path. For platforms that do not support dart:io,
/// such as the web, this will return null.
/// **WARNING** Since this will check the image data against all known decoders,
/// it is much slower than using an explicit decoder.
Future<Image?> decodeImageFile(String path, {int? frame}) async {
  final bytes = await readFile(path);
  if (bytes == null) {
    return null;
  }

  final decoder = findDecoderForNamedImage(path);
  if (decoder != null) {
    return decoder.decode(bytes, frame: frame);
  }

  return decodeImage(bytes, frame: frame);
}

/// Encode the [image] to the format determined by the file extension of [path].
/// If a format wasn't able to be identified, null will be returned.
/// Otherwise the encoded format bytes of the image will be returned.
Uint8List? encodeNamedImage(String path, Image image) {
  final encoder = findEncoderForNamedImage(path);
  if (encoder == null) {
    return null;
  }
  return encoder.encode(image);
}

/// Encode the [image] to a file at the given [path]. The format of the image
/// file is determined from the extension of the file. If the image was
/// successfully written to the file, true will be returned, otherwise false.
/// For platforms that do not support dart:io, false will be returned.
Future<bool> encodeImageFile(String path, Image image) async {
  if (!supportsFileAccess()) {
    return false;
  }
  final encoder = findEncoderForNamedImage(path);
  if (encoder == null) {
    return false;
  }
  final bytes = encoder.encode(image);
  return writeFile(path, bytes);
}

/// Decode a JPG formatted image.
Image? decodeJpg(Uint8List bytes) => JpegDecoder().decode(bytes);

/// Decode a JPG formatted image from a file. If the platform does not support
/// dart:io, null will be returned.
Future<Image?> decodeJpgFile(String path) async {
  final bytes = await readFile(path);
  if (bytes == null) {
    return null;
  }
  return JpegDecoder().decode(bytes);
}

/// Encode an [image] to the JPEG format.
Uint8List encodeJpg(Image image, {int quality = 100}) =>
    JpegEncoder(quality: quality).encode(image);

/// Encode an [image] to a JPG file at the given [path].
Future<bool> encodeJpgFile(String path, Image image,
    {int quality = 100}) async {
  if (!supportsFileAccess()) {
    return false;
  }
  final bytes = JpegEncoder(quality: quality).encode(image);
  return writeFile(path, bytes);
}

/// Decode only the [ExifData] from a JPEG file, returning null if it was
/// unable to.
ExifData? decodeJpgExif(Uint8List jpeg) => JpegUtil().decodeExif(jpeg);

/// Inject [ExifData] into a JPEG file, replacing any existing EXIF data.
/// The new JPEG file bytes will be returned, otherwise null if there was an
/// issue.
Uint8List? injectJpgExif(Uint8List jpeg, ExifData exif) =>
    JpegUtil().injectExif(exif, jpeg);

/// Decode a PNG formatted [Image].
Image? decodePng(Uint8List bytes, {int? frame}) =>
    PngDecoder().decode(bytes, frame: frame);

/// Decode a PNG formatted image from a file. If the platform does not support
/// dart:io, null will be returned.
Future<Image?> decodePngFile(String path) async {
  final bytes = await readFile(path);
  if (bytes == null) {
    return null;
  }
  return PngDecoder().decode(bytes);
}

/// Encode an image to the PNG format.
Uint8List encodePng(Image image,
        {bool singleFrame = false,
        int level = 6,
        PngFilter filter = PngFilter.paeth}) =>
    PngEncoder(filter: filter, level: level)
        .encode(image, singleFrame: singleFrame);

/// Encode an [image] to a PNG file at the given [path].
Future<bool> encodePngFile(String path, Image image,
    {bool singleFrame = false,
    int level = 6,
    PngFilter filter = PngFilter.paeth}) async {
  if (!supportsFileAccess()) {
    return false;
  }
  final bytes = PngEncoder(level: level, filter: filter)
      .encode(image, singleFrame: singleFrame);
  return writeFile(path, bytes);
}

/// Decode a TGA formatted image.
Image? decodeTga(Uint8List bytes, {int? frame}) =>
    TgaDecoder().decode(bytes, frame: frame);

/// Decode a TGA formatted image from a file. If the platform does not support
/// dart:io, null will be returned.
Future<Image?> decodeTgaFile(String path) async {
  final bytes = await readFile(path);
  if (bytes == null) {
    return null;
  }
  return TgaDecoder().decode(bytes);
}

/// Encode an image to the TGA format.
Uint8List encodeTga(Image image) => TgaEncoder().encode(image);

/// Encode an [image] to a TGA file at the given [path].
Future<bool> encodeTgaFile(String path, Image image) async {
  if (!supportsFileAccess()) {
    return false;
  }
  final bytes = TgaEncoder().encode(image);
  return writeFile(path, bytes);
}

/// Decode a WebP formatted image
Image? decodeWebP(Uint8List bytes, {int? frame}) =>
    WebPDecoder().decode(bytes, frame: frame);

/// Decode a WebP formatted image from a file. If the platform does not support
/// dart:io, null will be returned.
Future<Image?> decodeWebPFile(String path, {int? frame}) async {
  final bytes = await readFile(path);
  if (bytes == null) {
    return null;
  }
  return WebPDecoder().decode(bytes, frame: frame);
}

/// Decode a GIF formatted image.
Image? decodeGif(Uint8List bytes, {int? frame}) =>
    GifDecoder().decode(bytes, frame: frame);

/// Decode a GIF formatted image from a file. If the platform does not support
/// dart:io, null will be returned.
Future<Image?> decodeGifFile(String path, {int? frame}) async {
  final bytes = await readFile(path);
  if (bytes == null) {
    return null;
  }
  return GifDecoder().decode(bytes, frame: frame);
}

/// Encode an image to the GIF format.
///
/// The [samplingFactor] specifies the sampling factor for
/// NeuQuant image quantization. It is responsible for reducing
/// the amount of unique colors in your images to 256.
/// A sampling factor of 10 gives you a reasonable trade-off between
/// image quality and quantization speed.
/// If you know that you have less than 256 colors in your frames
/// anyway, you should supply a very large [samplingFactor] for maximum
/// performance.
Uint8List encodeGif(Image image,
        {bool singleFrame = false,
        int repeat = 0,
        int samplingFactor = 10,
        DitherKernel dither = DitherKernel.floydSteinberg,
        bool ditherSerpentine = false}) =>
    GifEncoder(
            samplingFactor: samplingFactor,
            dither: dither,
            ditherSerpentine: ditherSerpentine)
        .encode(image, singleFrame: singleFrame);

/// Encode an [image] to a GIF file at the given [path].
Future<bool> encodeGifFile(String path, Image image,
    {bool singleFrame = false,
    int repeat = 0,
    int samplingFactor = 10,
    DitherKernel dither = DitherKernel.floydSteinberg,
    bool ditherSerpentine = false}) async {
  if (!supportsFileAccess()) {
    return false;
  }
  final bytes = GifEncoder(
          samplingFactor: samplingFactor,
          dither: dither,
          ditherSerpentine: ditherSerpentine)
      .encode(image, singleFrame: singleFrame);
  return writeFile(path, bytes);
}

/// Decode a TIFF formatted image.
Image? decodeTiff(Uint8List bytes, {int? frame}) =>
    TiffDecoder().decode(bytes, frame: frame);

/// Decode a TIFF formatted image from a file. If the platform does not support
/// dart:io, null will be returned.
Future<Image?> decodeTiffFile(String path, {int? frame}) async {
  final bytes = await readFile(path);
  if (bytes == null) {
    return null;
  }
  return TiffDecoder().decode(bytes, frame: frame);
}

Uint8List encodeTiff(Image image, {bool singleFrame = false}) =>
    TiffEncoder().encode(image, singleFrame: singleFrame);

/// Encode an [image] to a TIFF file at the given [path].
Future<bool> encodeTiffFile(String path, Image image,
    {bool singleFrame = false}) async {
  if (!supportsFileAccess()) {
    return false;
  }
  final bytes = TiffEncoder().encode(image, singleFrame: singleFrame);
  return writeFile(path, bytes);
}

/// Decode a Photoshop PSD formatted image.
Image? decodePsd(Uint8List bytes) => PsdDecoder().decode(bytes);

/// Decode a PSD formatted image from a file. If the platform does not support
/// dart:io, null will be returned.
Future<Image?> decodePsdFile(String path) async {
  final bytes = await readFile(path);
  if (bytes == null) {
    return null;
  }
  return PsdDecoder().decode(bytes);
}

/// Decode an OpenEXR formatted image. EXR is a high dynamic range format.
Image? decodeExr(Uint8List bytes) => ExrDecoder().decode(bytes);

/// Decode a EXR formatted image from a file. If the platform does not support
/// dart:io, null will be returned.
Future<Image?> decodeExrFile(String path) async {
  final bytes = await readFile(path);
  if (bytes == null) {
    return null;
  }
  return ExrDecoder().decode(bytes);
}

/// Decode a BMP formatted image.
Image? decodeBmp(Uint8List bytes) => BmpDecoder().decode(bytes);

/// Decode a BMP formatted image from a file. If the platform does not support
/// dart:io, null will be returned.
Future<Image?> decodeBmpFile(String path) async {
  final bytes = await readFile(path);
  if (bytes == null) {
    return null;
  }
  return BmpDecoder().decode(bytes);
}

/// Encode an [Image] to the BMP format.
Uint8List encodeBmp(Image image) => BmpEncoder().encode(image);

/// Encode an [image] to a TIFF file at the given [path].
Future<bool> encodeBmpFile(String path, Image image) async {
  if (!supportsFileAccess()) {
    return false;
  }
  final bytes = BmpEncoder().encode(image);
  return writeFile(path, bytes);
}

/// Encode an [Image] to the CUR format.
Uint8List encodeCur(Image image, {bool singleFrame = false}) =>
    CurEncoder().encode(image, singleFrame: singleFrame);

/// Encode an [image] to a CUR file at the given [path].
Future<bool> encodeCurFile(String path, Image image,
    {bool singleFrame = false}) async {
  if (!supportsFileAccess()) {
    return false;
  }
  final bytes = CurEncoder().encode(image, singleFrame: singleFrame);
  return writeFile(path, bytes);
}

/// Decode an ICO image.
Image? decodeIco(Uint8List bytes, {int? frame}) =>
    IcoDecoder().decode(bytes, frame: frame);

/// Decode a ICO formatted image from a file. If the platform does not support
/// dart:io, null will be returned.
Future<Image?> decodeIcoFile(String path, {int? frame}) async {
  final bytes = await readFile(path);
  if (bytes == null) {
    return null;
  }
  return IcoDecoder().decode(bytes, frame: frame);
}

/// Encode an image to the ICO format.
Uint8List encodeIco(Image image, {bool singleFrame = false}) =>
    IcoEncoder().encode(image, singleFrame: singleFrame);

/// Encode an [image] to a ICO file at the given [path].
Future<bool> encodeIcoFile(String path, Image image,
    {bool singleFrame = false}) async {
  if (!supportsFileAccess()) {
    return false;
  }
  final bytes = IcoEncoder().encode(image, singleFrame: singleFrame);
  return writeFile(path, bytes);
}

/// Decode an PVR image.
Image? decodePvr(Uint8List bytes, {int? frame}) =>
    PvrDecoder().decode(bytes, frame: frame);

/// Decode a PVR formatted image from a file. If the platform does not support
/// dart:io, null will be returned.
Future<Image?> decodePvrFile(String path, {int? frame}) async {
  final bytes = await readFile(path);
  if (bytes == null) {
    return null;
  }
  return PvrDecoder().decode(bytes, frame: frame);
}

/// Encode an image to the PVR format.
Uint8List encodePvr(Image image, {bool singleFrame = false}) =>
    PvrEncoder().encode(image, singleFrame: singleFrame);

/// Encode an [image] to a PVR file at the given [path].
Future<bool> encodePvrFile(String path, Image image,
    {bool singleFrame = false}) async {
  if (!supportsFileAccess()) {
    return false;
  }
  final bytes = PvrEncoder().encode(image, singleFrame: singleFrame);
  return writeFile(path, bytes);
}
