import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import 'paths.dart';

void main() {
  final dir = Directory('test/res/webp');
  final files = dir.listSync();

  group('WebP/Lossless', () {
    test('test.webp', () {
      final webp = WebPDecoder().decodeImage(File('test/res/webp/test.webp').readAsBytesSync())!;
      final png = PngDecoder().decodeImage(File('test/res/webp/test.png').readAsBytesSync())!;
      expect(webp.width, equals(png.width));
      expect(webp.height, equals(png.height));
      var match = true;
      for (var i = 0, len = webp.length; i < len; ++i) {
        if (webp[i] != png[i]) {
          match = false;
          break;
        }
      }
      expect(match, equals(true), reason: 'test.webp does not match test.png');
      File('$tmpPath/test/res/test_webp.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(PngEncoder().encodeImage(webp));
    });
  });

  group('WebP/getInfo', () {
    for (var f in files.whereType<File>()) {
      if (!f.path.endsWith('.webp')) {
        continue;
      }

      final name = f.path.split(RegExp(r'(/|\\)')).last;
      test(name, () {
        final List<int> bytes = f.readAsBytesSync();

        final webp = WebPDecoder(bytes);
        final data = webp.info;
        if (data == null) {
          throw ImageException('Unable to parse WebP info: $name.');
        }

        if (_webp_tests.containsKey(name)) {
          expect(data.format, equals(_webp_tests[name]!['format']));
          expect(data.width, equals(_webp_tests[name]!['width']));
          expect(data.height, equals(_webp_tests[name]!['height']));
          expect(data.hasAlpha, equals(_webp_tests[name]!['hasAlpha']));
          expect(data.hasAnimation, equals(_webp_tests[name]!['hasAnimation']));

          if (data.hasAnimation) {
            expect(webp.numFrames(), equals(_webp_tests[name]!['numFrames']));
          }
        }
      });
    }
  });

  group('WebP/decodeImage', () {
    test('validate', () {
      var file = File('test/res/webp/2b.webp');
      var bytes = file.readAsBytesSync();
      final image = WebPDecoder().decodeImage(bytes)!;
      final png = PngEncoder().encodeImage(image);
      File('$tmpPath/out/webp/decode.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png);

      // Validate decoding.
      file = File('test/res/webp/2b.png');
      bytes = file.readAsBytesSync();
      final debugImage = PngDecoder().decodeImage(bytes)!;
      const found = false;
      for (var y = 0; y < debugImage.height && !found; ++y) {
        for (var x = 0; x < debugImage.width; ++x) {
          final dc = debugImage.getPixel(x, y);
          final c = image.getPixel(x, y);
          expect(c, equals(dc));
        }
      }
    });

    for (var f in files) {
      if (f is! File || !f.path.endsWith('.webp')) {
        continue;
      }

      final name = f.path.split(RegExp(r'(/|\\)')).last;
      test(name, () {
        final List<int> bytes = f.readAsBytesSync();
        final image = WebPDecoder().decodeImage(bytes);
        if (image == null) {
          throw ImageException('Unable to decode WebP Image: $name.');
        }

        final png = PngEncoder().encodeImage(image);
        File('$tmpPath/out/webp/$name.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(png);
      });
    }
  });

  group('WebP/decodeAnimation', () {
    test('Transparent Animation', () {
      const path = 'test/res/webp/animated_transparency.webp';
      final anim = WebPDecoder().decodeAnimation(File(path).readAsBytesSync())!;

      expect(anim.numFrames, equals(20));
      expect(anim.frames[2].getPixel(0, 0), equals(0));
      for (var i = 0; i < anim.numFrames; ++i) {
        final image = anim.frames[i];
        File('$tmpPath/out/webp/animated_transparency_$i.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(PngEncoder().encodeImage(image));
      }
    });
  });
}

const _webp_tests = {
  '1.webp': {
    'format': 1,
    'width': 550,
    'height': 368,
    'hasAlpha': false,
    'hasAnimation': false
  },
  '1_webp_a.webp': {
    'format': 1,
    'width': 400,
    'height': 301,
    'hasAlpha': true,
    'hasAnimation': false
  },
  '1_webp_ll.webp': {
    'format': 2,
    'width': 400,
    'height': 301,
    'hasAlpha': true,
    'hasAnimation': false
  },
  '2.webp': {
    'format': 1,
    'width': 550,
    'height': 404,
    'hasAlpha': false,
    'hasAnimation': false
  },
  '2b.webp': {
    'format': 1,
    'width': 75,
    'height': 55,
    'hasAlpha': false,
    'hasAnimation': false
  },
  '2_webp_a.webp': {
    'format': 1,
    'width': 386,
    'height': 395,
    'hasAlpha': true,
    'hasAnimation': false
  },
  '2_webp_ll.webp': {
    'format': 2,
    'width': 386,
    'height': 395,
    'hasAlpha': true,
    'hasAnimation': false
  },
  '3.webp': {
    'format': 1,
    'width': 1280,
    'height': 720,
    'hasAlpha': false,
    'hasAnimation': false
  },
  '3_webp_a.webp': {
    'format': 1,
    'width': 800,
    'height': 600,
    'hasAlpha': true,
    'hasAnimation': false
  },
  '3_webp_ll.webp': {
    'format': 2,
    'width': 800,
    'height': 600,
    'hasAlpha': true,
    'hasAnimation': false
  },
  '4.webp': {
    'format': 1,
    'width': 1024,
    'height': 772,
    'hasAlpha': false,
    'hasAnimation': false
  },
  '4_webp_a.webp': {
    'format': 1,
    'width': 421,
    'height': 163,
    'hasAlpha': true,
    'hasAnimation': false
  },
  '4_webp_ll.webp': {
    'format': 2,
    'width': 421,
    'height': 163,
    'hasAlpha': true,
    'hasAnimation': false
  },
  '5.webp': {
    'format': 1,
    'width': 1024,
    'height': 752,
    'hasAlpha': false,
    'hasAnimation': false
  },
  '5_webp_a.webp': {
    'format': 1,
    'width': 300,
    'height': 300,
    'hasAlpha': true,
    'hasAnimation': false
  },
  '5_webp_ll.webp': {
    'format': 2,
    'width': 300,
    'height': 300,
    'hasAlpha': true,
    'hasAnimation': false
  },
  'BladeRunner.webp': {
    'format': 3,
    'width': 500,
    'height': 224,
    'hasAlpha': true,
    'hasAnimation': true,
    'numFrames': 75
  },
  'BladeRunner_lossy.webp': {
    'format': 3,
    'width': 500,
    'height': 224,
    'hasAlpha': true,
    'hasAnimation': true,
    'numFrames': 75
  },
  'red.webp': {
    'format': 1,
    'width': 32,
    'height': 32,
    'hasAlpha': false,
    'hasAnimation': false
  },
  'SteamEngine.webp': {
    'format': 3,
    'width': 320,
    'height': 240,
    'hasAlpha': true,
    'hasAnimation': true,
    'numFrames': 31
  },
  'SteamEngine_lossy.webp': {
    'format': 3,
    'width': 320,
    'height': 240,
    'hasAlpha': true,
    'hasAnimation': true,
    'numFrames': 31
  }
};
