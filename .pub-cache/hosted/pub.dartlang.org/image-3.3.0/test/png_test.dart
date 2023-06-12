import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import 'paths.dart';

void main() {
  group('PNG', () {
    test('encode', () {
      final image = Image(64, 64);
      image.fill(getColor(100, 200, 255));

      // Encode the image to PNG
      final png = PngEncoder().encodeImage(image);
      File('$tmpPath/out/png/encode.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png);
    });

    test('decodeAnimation', () {
      var files = [
        ['test/res/png/apng/test_apng.png', 2, 'test_apng'],
        ['test/res/png/apng/test_apng2.png', 60, 'test_apng2'],
        ['test/res/png/apng/test_apng3.png', 19, 'test_apng3'],];

      for (var f in files)
      {
        final bytes = File(f[0] as String).readAsBytesSync();
        final anim = PngDecoder().decodeAnimation(bytes)!;
        expect(anim.length, equals(f[1]));

        /*for (var i = 0; i < anim.length; ++i) {
          final png = PngEncoder().encodeImage(anim[i]);
          File('$tmpPath/out/png/${f[2] as String}-$i.png')
            ..createSync(recursive: true)
            ..writeAsBytesSync(png);
        }*/
      }
    });

    test('encodeAnimation', () {
      final anim = Animation();
      anim.loopCount = 10;
      for (var i = 0; i < 10; i++) {
        final image = Image(480, 120);
        drawString(image, arial_48, 100, 60, i.toString());
        anim.addFrame(image);
      }

      final png = encodePngAnimation(anim)!;
      File('$tmpPath/out/png/encodeAnimation.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png);
    });

    test('textData', () {
      final img = Image(16, 16, textData: {"foo":"bar"});
      final png = PngEncoder().encodeImage(img);
      final img2 = PngDecoder().decodeImage(png);
      expect(img2?.width, equals(img.width));
      expect(img2?.textData?["foo"], equals("bar"));
    });

    test('decode', () {
      final List<int> bytes =
          File('$tmpPath/out/png/encode.png').readAsBytesSync();
      final image = PngDecoder().decodeImage(bytes)!;

      expect(image.width, equals(64));
      expect(image.height, equals(64));
      final c = getColor(100, 200, 255);
      for (var i = 0, len = image.length; i < len; ++i) {
        expect(image[i], equals(c));
      }

      final png = PngEncoder().encodeImage(image);
      File('$tmpPath/out/png/decode.png').writeAsBytesSync(png);
    });

    test('iCCP', () {
      final bytes = File('test/res/png/iCCP.png').readAsBytesSync();
      final image = PngDecoder().decodeImage(bytes)!;
      expect(image.iccProfile, isNotNull);
      expect(image.iccProfile!.data, isNotNull);

      final png = PngEncoder().encodeImage(image);

      final image2 = PngDecoder().decodeImage(png)!;
      expect(image2.iccProfile, isNotNull);
      expect(image2.iccProfile!.data, isNotNull);
      expect(image2.iccProfile!.data.length,
          equals(image.iccProfile!.data.length));
    });

    final dir = Directory('test/res/png');
    final files = dir.listSync();

    for (var f in files) {
      if (f is! File || !f.path.endsWith('.png')) {
        continue;
      }

      // PngSuite File naming convention:
      // filename:                                g04i2c08.png
      //                                          || ||||
      //  test feature (in this case gamma) ------+| ||||
      //  parameter of test (here gamma-value) ----+ ||||
      //  interlaced or non-interlaced --------------+|||
      //  color-type (numerical) ---------------------+||
      //  color-type (descriptive) --------------------+|
      //  bit-depth ------------------------------------+
      //
      //  color-type:
      //
      //    0g - grayscale
      //    2c - rgb color
      //    3p - paletted
      //    4a - grayscale + alpha channel
      //    6a - rgb color + alpha channel
      //    bit-depth:
      //      01 - with color-type 0, 3
      //      02 - with color-type 0, 3
      //      04 - with color-type 0, 3
      //      08 - with color-type 0, 2, 3, 4, 6
      //      16 - with color-type 0, 2, 4, 6
      //      interlacing:
      //        n - non-interlaced
      //        i - interlaced
      final name = f.path.split(RegExp(r'(/|\\)')).last;

      test('PNG $name', () {
        final file = f;

        // x* png's are corrupted and are supposed to crash.
        if (name.startsWith('x')) {
          try {
            final image = PngDecoder().decodeImage(file.readAsBytesSync());
            expect(image, isNull);
          } catch (e) {
            // noop
          }
        } else {
          final anim = decodeAnimation(file.readAsBytesSync());
          expect(anim, isNotNull);
          if (anim != null) {
            if (anim.length == 1) {
              final png = PngEncoder().encodeImage(anim[0]);
              File('$tmpPath/out/png/$name')
                ..createSync(recursive: true)
                ..writeAsBytesSync(png);
            } else {
              for (var i = 0; i < anim.length; ++i) {
                final png = PngEncoder().encodeImage(anim[i]);
                File('$tmpPath/out/png/$name-$i.png')
                  ..createSync(recursive: true)
                  ..writeAsBytesSync(png);
              }
            }
          }
        }
      });
    }
  });
}
