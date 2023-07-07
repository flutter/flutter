import 'dart:typed_data';

import '../color/format.dart';
import '../exif/exif_data.dart';
import '../exif/ifd_value.dart';
import '../image/image.dart';
import '../util/output_buffer.dart';
import 'encoder.dart';
import 'tiff/tiff_image.dart';

/// Encode am [Image] to the TIFF format.
class TiffEncoder extends Encoder {
  @override
  Uint8List encode(Image image, {bool singleFrame = false}) {
    final out = OutputBuffer();

    // TIFF is really just an EXIF structure (or, really, EXIF is just a TIFF
    // structure).

    final exif = ExifData();
    if (image.hasExif) {
      exif.imageIfd.copy(image.exif.imageIfd);
    }

    // TODO: support encoding HDR images to TIFF.
    if (image.isHdrFormat) {
      image = image.convert(format: Format.uint8);
    }

    final type = image.numChannels == 1
        ? TiffPhotometricType.blackIsZero.index
        : image.hasPalette
            ? TiffPhotometricType.palette.index
            : TiffPhotometricType.rgb.index;

    final nc = image.numChannels;

    final ifd0 = exif.imageIfd;
    ifd0['ImageWidth'] = image.width;
    ifd0['ImageHeight'] = image.height;
    ifd0['BitsPerSample'] = image.bitsPerChannel;
    ifd0['SampleFormat'] = _getSampleFormat(image).index;
    ifd0['SamplesPerPixel'] = image.hasPalette ? 1 : nc;
    ifd0['Compression'] = TiffCompression.none;
    ifd0['PhotometricInterpretation'] = type;
    ifd0['RowsPerStrip'] = image.height;
    ifd0['PlanarConfiguration'] = 1;
    ifd0['TileWidth'] = image.width;
    ifd0['TileLength'] = image.height;
    ifd0['StripByteCounts'] = image.lengthInBytes;
    ifd0['StripOffsets'] = IfdValueUndefined.list(image.toUint8List());

    if (image.hasPalette) {
      final p = image.palette!;
      // Only support RGB palettes
      const numCh = 3;
      final numC = p.numColors;
      final colorMap = Uint16List(numC * numCh);
      for (var c = 0, ci = 0; c < numCh; ++c) {
        for (var i = 0; i < numC; ++i) {
          colorMap[ci++] = p.get(i, c).toInt() << 8;
        }
      }
      ifd0['ColorMap'] = colorMap;
    }

    exif.write(out);

    return out.getBytes();
  }

  TiffFormat _getSampleFormat(Image image) {
    switch (image.formatType) {
      case FormatType.uint:
        return TiffFormat.uint;
      case FormatType.int:
        return TiffFormat.int;
      case FormatType.float:
        return TiffFormat.float;
    }
  }
}
