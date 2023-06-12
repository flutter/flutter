import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import 'paths.dart';

void main() {
  final image =
      readJpg(File('test/res/jpg/big_buck_bunny.jpg').readAsBytesSync())!;

  group('bitmapFont', () {
    test('zip/xml', () {
      final fontZip = File('test/res/font/test.zip').readAsBytesSync();
      final font = readFontZip(fontZip);

      final img = copyResize(image, width: 400);
      drawString(img, font, 10, 50, 'Testing Font 1: Hello World');

      File('$tmpPath/out/font/font_zip_xml.jpg')
        ..createSync(recursive: true)
        ..writeAsBytesSync(writeJpg(img));
    });

    test('zip/text', () {
      final fontZip = File('test/res/font/test_text.zip').readAsBytesSync();
      final font = readFontZip(fontZip);

      final img = copyResize(image, width: 400);
      drawString(img, font, 10, 50, 'Testing Font 2: Hello World',
          color: getColor(255, 0, 0, 128));

      File('$tmpPath/out/font/font_zip_text.jpg')
        ..createSync(recursive: true)
        ..writeAsBytesSync(writeJpg(img));
    });

    test('arial_14', () {
      final img = copyResize(image, width: 400);
      drawString(img, arial_14, 10, 50, 'Testing Arial 14: Hello World',
          color: getColor(255, 0, 0, 128));

      File('$tmpPath/out/font/font_arial_14.jpg')
        ..createSync(recursive: true)
        ..writeAsBytesSync(writeJpg(img));
    });

    test('arial_24', () {
      final img = copyResize(image, width: 400);
      drawString(img, arial_24, 10, 50, 'Testing Arial 24: Hello World',
          color: getColor(255, 0, 0, 128));

      File('$tmpPath/out/font/font_arial_24.jpg')
        ..createSync(recursive: true)
        ..writeAsBytesSync(writeJpg(img));
    });

    test('arial_48', () {
      final img = copyResize(image, width: 400);
      drawString(img, arial_48, 10, 50, 'Testing Arial 48: Hello World',
          color: getColor(255, 0, 0, 128));

      File('$tmpPath/out/font/font_arial_48.jpg')
        ..createSync(recursive: true)
        ..writeAsBytesSync(writeJpg(img));
    });

    test('drawStringCenteredY', () {
      final img = copyResize(image, width: 400);
      drawStringCentered(img, arial_24, 'Testing Arial 24: Hello World',
          y: 50, color: getColor(255, 0, 0, 128));

      File('$tmpPath/out/font/y_centered.jpg')
        ..createSync(recursive: true)
        ..writeAsBytesSync(writeJpg(img));
    });

    test('drawStringCenteredY', () {
      final img = copyResize(image, width: 400);
      drawStringCentered(img, arial_24, 'Testing Arial 24: Hello World',
          x: 10, color: getColor(255, 0, 0, 128));

      File('$tmpPath/out/font/x_centered.jpg')
        ..createSync(recursive: true)
        ..writeAsBytesSync(writeJpg(img));
    });

    test('drawStringCenteredXY', () {
      final img = copyResize(image, width: 400);
      drawStringCentered(img, arial_24, 'Testing Arial 24: Hello World',
          color: getColor(255, 0, 0, 128));

      File('$tmpPath/out/font/xy_centered.jpg')
        ..createSync(recursive: true)
        ..writeAsBytesSync(writeJpg(img));
    });
  });
}
