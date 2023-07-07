import 'package:image/image.dart';
import 'package:test/test.dart';

void main() {
  group('Color', () {
    test('RGBA', () {
      var rgba = Color.fromRgba(0xaa, 0xbb, 0xcc, 0xff);
      expect(rgba, equals(0xffccbbaa));

      expect(getRed(rgba), equals(0xaa));
      expect(getGreen(rgba), equals(0xbb));
      expect(getBlue(rgba), equals(0xcc));
      expect(getAlpha(rgba), equals(0xff));

      expect(getChannel(rgba, Channel.red), equals(0xaa));
      expect(getChannel(rgba, Channel.green), equals(0xbb));
      expect(getChannel(rgba, Channel.blue), equals(0xcc));
      expect(getChannel(rgba, Channel.alpha), equals(0xff));

      rgba = setChannel(rgba, Channel.red, 0x11);
      rgba = setChannel(rgba, Channel.green, 0x22);
      rgba = setChannel(rgba, Channel.blue, 0x33);
      rgba = setChannel(rgba, Channel.alpha, 0x44);
      expect(rgba, equals(0x44332211));

      rgba = setRed(rgba, 0x55);
      rgba = setGreen(rgba, 0x66);
      rgba = setBlue(rgba, 0x77);
      rgba = setAlpha(rgba, 0x88);
      expect(rgba, equals(0x88776655));
    });

    test('Grayscale', () {
      final rgba = Color.fromRgba(0x55, 0x66, 0x77, 0x88);
      var l = getLuminance(rgba);
      expect(l, equals(0x63));

      l = getLuminanceRgb(0x55, 0x66, 0x77);
      expect(l, equals(0x63));
    });

    test('HSL', () {
      final rgb = hslToRgb(180.0 / 360.0, 0.5, 0.75);
      expect(rgb[0], equals(159));
      expect(rgb[1], equals(223));
      expect(rgb[2], equals(223));

      final hsl = rgbToHsl(rgb[0], rgb[1], rgb[2]);
      expect(hsl[0], closeTo(0.5, 0.001));
      expect(hsl[1], closeTo(0.5, 0.001));
      expect(hsl[2], closeTo(0.75, 0.001));
    });

    test('CMYK', () {
      final rgb =
          cmykToRgb((0.75 * 255), (0.5 * 255), (0.5 * 255), (0.5 * 255));
      expect(rgb[0], equals(32));
      expect(rgb[1], equals(64));
      expect(rgb[2], equals(64));
    });

    test('Image', () {
      final image = Image(1, 1);
      for (var i = 0, len = image.length; i < len; ++i) {
        image[i] = Color.fromRgba(200, 128, 64, 255);
      }

      expect(getRed(image[0]), 200);
      expect(getGreen(image[0]), 128);
      expect(getBlue(image[0]), 64);
      expect(getAlpha(image[0]), 255);

      final argb = image.getBytes(format: Format.argb);
      expect(argb[0], 255);
      expect(argb[1], 200);
      expect(argb[2], 128);
      expect(argb[3], 64);

      final image_argb =
          Image.fromBytes(image.width, image.height, argb, format: Format.argb);
      expect(getRed(image_argb[0]), 200);
      expect(getGreen(image_argb[0]), 128);
      expect(getBlue(image_argb[0]), 64);
      expect(getAlpha(image_argb[0]), 255);

      final abgr = image.getBytes(format: Format.abgr);
      expect(abgr[0], 255);
      expect(abgr[1], 64);
      expect(abgr[2], 128);
      expect(abgr[3], 200);

      final image_abgr =
          Image.fromBytes(image.width, image.height, abgr, format: Format.abgr);
      expect(getRed(image_abgr[0]), 200);
      expect(getGreen(image_abgr[0]), 128);
      expect(getBlue(image_abgr[0]), 64);
      expect(getAlpha(image_abgr[0]), 255);

      final rgba = image.getBytes();
      expect(rgba[0], 200);
      expect(rgba[1], 128);
      expect(rgba[2], 64);
      expect(rgba[3], 255);

      final image_rgba = Image.fromBytes(image.width, image.height, rgba);
      expect(getRed(image_rgba[0]), 200);
      expect(getGreen(image_rgba[0]), 128);
      expect(getBlue(image_rgba[0]), 64);
      expect(getAlpha(image_rgba[0]), 255);

      final bgra = image.getBytes(format: Format.bgra);
      expect(bgra[0], 64);
      expect(bgra[1], 128);
      expect(bgra[2], 200);
      expect(bgra[3], 255);

      final image_bgra =
          Image.fromBytes(image.width, image.height, bgra, format: Format.bgra);
      expect(getRed(image_bgra[0]), 200);
      expect(getGreen(image_bgra[0]), 128);
      expect(getBlue(image_bgra[0]), 64);
      expect(getAlpha(image_bgra[0]), 255);

      final rgb = image.getBytes(format: Format.rgb);
      expect(rgb[0], 200);
      expect(rgb[1], 128);
      expect(rgb[2], 64);

      final image_rgb =
          Image.fromBytes(image.width, image.height, rgb, format: Format.rgb);
      expect(getRed(image_rgb[0]), 200);
      expect(getGreen(image_rgb[0]), 128);
      expect(getBlue(image_rgb[0]), 64);
      expect(getAlpha(image_rgb[0]), 255);

      final bgr = image.getBytes(format: Format.bgr);
      expect(bgr[0], 64);
      expect(bgr[1], 128);
      expect(bgr[2], 200);

      final image_bgr =
          Image.fromBytes(image.width, image.height, bgr, format: Format.bgr);
      expect(getRed(image_bgr[0]), 200);
      expect(getGreen(image_bgr[0]), 128);
      expect(getBlue(image_bgr[0]), 64);
      expect(getAlpha(image_bgr[0]), 255);
    });
  });
}
