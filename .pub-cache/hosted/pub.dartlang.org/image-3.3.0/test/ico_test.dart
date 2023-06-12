import 'dart:io';

import 'package:image/image.dart';
import 'package:image/src/formats/ico_encoder.dart';
import 'package:test/test.dart';

import 'paths.dart';

void main() {
  group('ICO', () {
    test('encode', () {
      final image = Image(64, 64);
      image.fill(getColor(100, 200, 255));

      // Encode the image to ICO
      final png = IcoEncoder().encodeImage(image);
      File('$tmpPath/out/ico/encode.ico')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png);

      final image2 = Image(64, 64);
      image2.fill(getColor(100, 255, 200));

      final png2 = IcoEncoder().encodeImages([image, image2]);
      File('$tmpPath/out/ico/encode2.ico')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png2);

      final image3 = Image(32, 64);
      image3.fill(getColor(255, 100, 200));

      final png3 = IcoEncoder().encodeImages([image, image2, image3]);
      File('$tmpPath/out/ico/encode3.ico')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png3);
    });

    final dir = Directory('test/res/ico');
    if (!dir.existsSync()) {
      return;
    }

    for (final file in dir.listSync().whereType<File>()) {
      if (!file.path.endsWith('.ico')) {
        continue;
      }

      final name = file.path.split(RegExp(r'(/|\\)')).last;
      test('decode $name', () {
        final bytes = file.readAsBytesSync();
        final image = IcoDecoder().decodeImageLargest(bytes)!;
        File('$tmpPath/out/ico/$name.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(PngEncoder().encodeImage(image));
      });
    }
  });
}
