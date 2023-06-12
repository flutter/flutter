import 'dart:typed_data';
import '../../color.dart';
import '../../exif/exif_data.dart';
import '../../image.dart';
import '../../image_exception.dart';
import '../../internal/bit_operators.dart';
import '_component_data.dart';
import 'jpeg_data.dart';

Uint8List? _dctClip;
int _clamp8(int i) => i < 0
    ? 0
    : i > 255
        ? 255
        : i;

// These functions contain bit-shift operations that fail with HTML builds.
// A conditional import is used to use a modified version for HTML builds
// to work around this javascript bug, while keeping the native version fast.

// Quantize the coefficients and apply IDCT.
//
// A port of poppler's IDCT method which in turn is taken from:
// Christoph Loeffler, Adriaan Ligtenberg, George S. Moschytz,
// "Practical Fast 1-D DCT Algorithms with 11 Multiplications",
// IEEE Intl. Conf. on Acoustics, Speech & Signal Processing, 1989, 988-991.
void quantizeAndInverse(Int16List quantizationTable, Int32List coefBlock,
    Uint8List dataOut, Int32List dataIn) {
  final p = dataIn;

  const dctClipOffset = 256;
  const dctClipLength = 768;
  if (_dctClip == null) {
    _dctClip = Uint8List(dctClipLength);
    int i;
    for (i = -256; i < 0; ++i) {
      _dctClip![dctClipOffset + i] = 0;
    }
    for (i = 0; i < 256; ++i) {
      _dctClip![dctClipOffset + i] = i;
    }
    for (i = 256; i < 512; ++i) {
      _dctClip![dctClipOffset + i] = 255;
    }
  }

  // IDCT constants (20.12 fixed point format)
  const COS_1 = 4017; // cos(pi/16)*4096
  const SIN_1 = 799; // sin(pi/16)*4096
  const COS_3 = 3406; // cos(3*pi/16)*4096
  const SIN_3 = 2276; // sin(3*pi/16)*4096
  const COS_6 = 1567; // cos(6*pi/16)*4096
  const SIN_6 = 3784; // sin(6*pi/16)*4096
  const SQRT_2 = 5793; // sqrt(2)*4096
  const SQRT_1D2 = 2896; // sqrt(2) / 2

  // de-quantize
  for (var i = 0; i < 64; i++) {
    p[i] = (coefBlock[i] * quantizationTable[i]);
  }

  // inverse DCT on rows
  var row = 0;
  for (var i = 0; i < 8; ++i, row += 8) {
    // check for all-zero AC coefficients
    if (p[1 + row] == 0 &&
        p[2 + row] == 0 &&
        p[3 + row] == 0 &&
        p[4 + row] == 0 &&
        p[5 + row] == 0 &&
        p[6 + row] == 0 &&
        p[7 + row] == 0) {
      final t = shiftR((SQRT_2 * p[0 + row] + 512), 10);
      p[row + 0] = t;
      p[row + 1] = t;
      p[row + 2] = t;
      p[row + 3] = t;
      p[row + 4] = t;
      p[row + 5] = t;
      p[row + 6] = t;
      p[row + 7] = t;
      continue;
    }

    // stage 4
    var v0 = shiftR((SQRT_2 * p[0 + row] + 128), 8);
    var v1 = shiftR((SQRT_2 * p[4 + row] + 128), 8);
    var v2 = p[2 + row];
    var v3 = p[6 + row];
    var v4 = shiftR((SQRT_1D2 * (p[1 + row] - p[7 + row]) + 128), 8);
    var v7 = shiftR((SQRT_1D2 * (p[1 + row] + p[7 + row]) + 128), 8);
    var v5 = shiftL(p[3 + row], 4);
    var v6 = shiftL(p[5 + row], 4);

    // stage 3
    var t = shiftR((v0 - v1 + 1), 1);
    v0 = shiftR((v0 + v1 + 1), 1);
    v1 = t;
    t = shiftR((v2 * SIN_6 + v3 * COS_6 + 128), 8);
    v2 = shiftR((v2 * COS_6 - v3 * SIN_6 + 128), 8);
    v3 = t;
    t = shiftR((v4 - v6 + 1), 1);
    v4 = shiftR((v4 + v6 + 1), 1);
    v6 = t;
    t = shiftR((v7 + v5 + 1), 1);
    v5 = shiftR((v7 - v5 + 1), 1);
    v7 = t;

    // stage 2
    t = shiftR((v0 - v3 + 1), 1);
    v0 = shiftR((v0 + v3 + 1), 1);
    v3 = t;
    t = shiftR((v1 - v2 + 1), 1);
    v1 = shiftR((v1 + v2 + 1), 1);
    v2 = t;
    t = shiftR((v4 * SIN_3 + v7 * COS_3 + 2048), 12);
    v4 = shiftR((v4 * COS_3 - v7 * SIN_3 + 2048), 12);
    v7 = t;
    t = shiftR((v5 * SIN_1 + v6 * COS_1 + 2048), 12);
    v5 = shiftR((v5 * COS_1 - v6 * SIN_1 + 2048), 12);
    v6 = t;

    // stage 1
    p[0 + row] = (v0 + v7);
    p[7 + row] = (v0 - v7);
    p[1 + row] = (v1 + v6);
    p[6 + row] = (v1 - v6);
    p[2 + row] = (v2 + v5);
    p[5 + row] = (v2 - v5);
    p[3 + row] = (v3 + v4);
    p[4 + row] = (v3 - v4);
  }

  // inverse DCT on columns
  for (var i = 0; i < 8; ++i) {
    final col = i;

    // check for all-zero AC coefficients
    if (p[1 * 8 + col] == 0 &&
        p[2 * 8 + col] == 0 &&
        p[3 * 8 + col] == 0 &&
        p[4 * 8 + col] == 0 &&
        p[5 * 8 + col] == 0 &&
        p[6 * 8 + col] == 0 &&
        p[7 * 8 + col] == 0) {
      final t = shiftR((SQRT_2 * dataIn[i] + 8192), 14);
      p[0 * 8 + col] = t;
      p[1 * 8 + col] = t;
      p[2 * 8 + col] = t;
      p[3 * 8 + col] = t;
      p[4 * 8 + col] = t;
      p[5 * 8 + col] = t;
      p[6 * 8 + col] = t;
      p[7 * 8 + col] = t;
      continue;
    }

    // stage 4
    var v0 = shiftR((SQRT_2 * p[0 * 8 + col] + 2048), 12);
    var v1 = shiftR((SQRT_2 * p[4 * 8 + col] + 2048), 12);
    var v2 = p[2 * 8 + col];
    var v3 = p[6 * 8 + col];
    var v4 = shiftR((SQRT_1D2 * (p[1 * 8 + col] - p[7 * 8 + col]) + 2048), 12);
    var v7 = shiftR((SQRT_1D2 * (p[1 * 8 + col] + p[7 * 8 + col]) + 2048), 12);
    var v5 = p[3 * 8 + col];
    var v6 = p[5 * 8 + col];

    // stage 3
    var t = shiftR((v0 - v1 + 1), 1);
    v0 = shiftR((v0 + v1 + 1), 1);
    v1 = t;
    t = shiftR((v2 * SIN_6 + v3 * COS_6 + 2048), 12);
    v2 = shiftR((v2 * COS_6 - v3 * SIN_6 + 2048), 12);
    v3 = t;
    t = shiftR((v4 - v6 + 1), 1);
    v4 = shiftR((v4 + v6 + 1), 1);
    v6 = t;
    t = shiftR((v7 + v5 + 1), 1);
    v5 = shiftR((v7 - v5 + 1), 1);
    v7 = t;

    // stage 2
    t = shiftR((v0 - v3 + 1), 1);
    v0 = shiftR((v0 + v3 + 1), 1);
    v3 = t;
    t = shiftR((v1 - v2 + 1), 1);
    v1 = shiftR((v1 + v2 + 1), 1);
    v2 = t;
    t = shiftR((v4 * SIN_3 + v7 * COS_3 + 2048), 12);
    v4 = shiftR((v4 * COS_3 - v7 * SIN_3 + 2048), 12);
    v7 = t;
    t = shiftR((v5 * SIN_1 + v6 * COS_1 + 2048), 12);
    v5 = shiftR((v5 * COS_1 - v6 * SIN_1 + 2048), 12);
    v6 = t;

    // stage 1
    p[0 * 8 + col] = (v0 + v7);
    p[7 * 8 + col] = (v0 - v7);
    p[1 * 8 + col] = (v1 + v6);
    p[6 * 8 + col] = (v1 - v6);
    p[2 * 8 + col] = (v2 + v5);
    p[5 * 8 + col] = (v2 - v5);
    p[3 * 8 + col] = (v3 + v4);
    p[4 * 8 + col] = (v3 - v4);
  }

  // convert to 8-bit integers
  for (var i = 0; i < 64; ++i) {
    dataOut[i] = _dctClip![(dctClipOffset + 128 + shiftR((p[i] + 8), 4))];
  }
}

Image getImageFromJpeg(JpegData jpeg) {
  final orientation =
    jpeg.exif.imageIfd.hasOrientation ? jpeg.exif.imageIfd.Orientation! : 0;
  final w = jpeg.width!;
  final h = jpeg.height!;
  final flipWidthHeight = orientation >= 5 && orientation <= 8;
  final width = flipWidthHeight ? h : w;
  final height = flipWidthHeight ? w : h;

  final image = Image(width, height, channels: Channels.rgb);

  // Copy exif data, except for Orientation which we're baking.
  image.exif = ExifData.from(jpeg.exif);
  image.exif.imageIfd.Orientation = null;

  ComponentData component1;
  ComponentData component2;
  ComponentData component3;
  ComponentData component4;
  Uint8List? component1Line;
  Uint8List? component2Line;
  Uint8List? component3Line;
  Uint8List? component4Line;
  var offset = 0;
  int Y, Cb, Cr, K, C, M, Ye, R, G, B;
  var colorTransform = false;

  final h1 = h - 1;
  final w1 = w - 1;

  switch (jpeg.components.length) {
    case 1:
      component1 = jpeg.components[0];
      final lines = component1.lines;
      final hShift1 = component1.hScaleShift;
      final vShift1 = component1.vScaleShift;
      for (var y = 0; y < jpeg.height!; y++) {
        final y1 = y >> vShift1;
        component1Line = lines[y1];
        for (var x = 0; x < jpeg.width!; x++) {
          final x1 = x >> hShift1;
          Y = component1Line![x1];
          final c = getColor(Y, Y, Y);
          if (orientation == 2) {
            image.setPixel(w1 - x, y, c);
          } else if (orientation == 3) {
            image.setPixel(w1 - x, h1 - y, c);
          } else if (orientation == 4) {
            image.setPixel(x, h1 - y, c);
          } else if (orientation == 5) {
            image.setPixel(y, x, c);
          } else if (orientation == 6) {
            image.setPixel(h1 - y, x, c);
          } else if (orientation == 7) {
            image.setPixel(h1 - y, w1 - x, c);
          } else if (orientation == 8) {
            image.setPixel(y, w1 - x, c);
          } else {
            image[offset++] = c;
          }
        }
      }
      break;
    /*case 2:
        // PDF might compress two component data in custom color-space
        component1 = components[0];
        component2 = components[1];
        int hShift1 = component1.hScaleShift;
        int vShift1 = component1.vScaleShift;
        int hShift2 = component2.hScaleShift;
        int vShift2 = component2.vScaleShift;

        for (int y = 0; y < height; y++) {
          int y1 = y >> vShift1;
          int y2 = y >> vShift2;
          component1Line = component1.lines[y1];
          component2Line = component2.lines[y2];

          for (int x = 0; x < width; x++) {
            int x1 = x >> hShift1;
            int x2 = x >> hShift2;

            Y = component1Line[x1];
            //data[offset++] = Y;

            Y = component2Line[x2];
            //data[offset++] = Y;
          }
        }
        break;*/
    case 3:
      // The default transform for three components is true
      colorTransform = true;

      component1 = jpeg.components[0];
      component2 = jpeg.components[1];
      component3 = jpeg.components[2];

      final lines1 = component1.lines;
      final lines2 = component2.lines;
      final lines3 = component3.lines;

      final hShift1 = component1.hScaleShift;
      final vShift1 = component1.vScaleShift;
      final hShift2 = component2.hScaleShift;
      final vShift2 = component2.vScaleShift;
      final hShift3 = component3.hScaleShift;
      final vShift3 = component3.vScaleShift;

      for (var y = 0; y < jpeg.height!; y++) {
        final y1 = y >> vShift1;
        final y2 = y >> vShift2;
        final y3 = y >> vShift3;

        component1Line = lines1[y1];
        component2Line = lines2[y2];
        component3Line = lines3[y3];

        for (var x = 0; x < jpeg.width!; x++) {
          final x1 = x >> hShift1;
          final x2 = x >> hShift2;
          final x3 = x >> hShift3;

          Y = component1Line![x1] << 8;
          Cb = component2Line![x2] - 128;
          Cr = component3Line![x3] - 128;

          R = (Y + 359 * Cr + 128);
          G = (Y - 88 * Cb - 183 * Cr + 128);
          B = (Y + 454 * Cb + 128);

          R = _clamp8(shiftR(R, 8));
          G = _clamp8(shiftR(G, 8));
          B = _clamp8(shiftR(B, 8));
          final c = getColor(R, G, B);
          if (orientation == 2) {
            image.setPixel(w1 - x, y, c);
          } else if (orientation == 3) {
            image.setPixel(w1 - x, h1 - y, c);
          } else if (orientation == 4) {
            image.setPixel(x, h1 - y, c);
          } else if (orientation == 5) {
            image.setPixel(y, x, c);
          } else if (orientation == 6) {
            image.setPixel(h1 - y, x, c);
          } else if (orientation == 7) {
            image.setPixel(h1 - y, w1 - x, c);
          } else if (orientation == 8) {
            image.setPixel(y, w1 - x, c);
          } else {
            image[offset++] = c;
          }
        }
      }
      break;
    case 4:
      if (jpeg.adobe == null) {
        throw ImageException('Unsupported color mode (4 components)');
      }
      // The default transform for four components is false
      colorTransform = false;
      // The adobe transform marker overrides any previous setting
      if (jpeg.adobe!.transformCode != 0) {
        colorTransform = true;
      }

      component1 = jpeg.components[0];
      component2 = jpeg.components[1];
      component3 = jpeg.components[2];
      component4 = jpeg.components[3];

      final lines1 = component1.lines;
      final lines2 = component2.lines;
      final lines3 = component3.lines;
      final lines4 = component4.lines;

      final hShift1 = component1.hScaleShift;
      final vShift1 = component1.vScaleShift;
      final hShift2 = component2.hScaleShift;
      final vShift2 = component2.vScaleShift;
      final hShift3 = component3.hScaleShift;
      final vShift3 = component3.vScaleShift;
      final hShift4 = component4.hScaleShift;
      final vShift4 = component4.vScaleShift;

      for (var y = 0; y < jpeg.height!; y++) {
        final y1 = y >> vShift1;
        final y2 = y >> vShift2;
        final y3 = y >> vShift3;
        final y4 = y >> vShift4;
        component1Line = lines1[y1];
        component2Line = lines2[y2];
        component3Line = lines3[y3];
        component4Line = lines4[y4];
        for (var x = 0; x < jpeg.width!; x++) {
          final x1 = x >> hShift1;
          final x2 = x >> hShift2;
          final x3 = x >> hShift3;
          final x4 = x >> hShift4;
          if (!colorTransform) {
            C = component1Line![x1];
            M = component2Line![x2];
            Ye = component3Line![x3];
            K = component4Line![x4];
          } else {
            Y = component1Line![x1];
            Cb = component2Line![x2];
            Cr = component3Line![x3];
            K = component4Line![x4];

            C = 255 - _clamp8((Y + 1.402 * (Cr - 128)).toInt());
            M = 255 -
                _clamp8((Y - 0.3441363 * (Cb - 128) - 0.71413636 * (Cr - 128))
                    .toInt());
            Ye = 255 - _clamp8((Y + 1.772 * (Cb - 128)).toInt());
          }
          R = shiftR((C * K), 8);
          G = shiftR((M * K), 8);
          B = shiftR((Ye * K), 8);

          final c = getColor(R, G, B);
          if (orientation == 2) {
            image.setPixel(w1 - x, y, c);
          } else if (orientation == 3) {
            image.setPixel(w1 - x, h1 - y, c);
          } else if (orientation == 4) {
            image.setPixel(x, h1 - y, c);
          } else if (orientation == 5) {
            image.setPixel(y, x, c);
          } else if (orientation == 6) {
            image.setPixel(h1 - y, x, c);
          } else if (orientation == 7) {
            image.setPixel(h1 - y, w1 - x, c);
          } else if (orientation == 8) {
            image.setPixel(y, w1 - x, c);
          } else {
            image[offset++] = c;
          }
        }
      }
      break;
    default:
      throw ImageException('Unsupported color mode');
  }

  return image;
}
