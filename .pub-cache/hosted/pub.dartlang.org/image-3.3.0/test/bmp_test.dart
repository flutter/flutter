import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import 'paths.dart';

void main() {
  final dir = Directory('test/res/bmp');
  if (!dir.existsSync()) {
    return;
  }
  final files = dir.listSync().whereType<File>();

  group('BMP', () {
    for (var f in files) {
      if (!f.path.endsWith('.bmp')) {
        continue;
      }

      final name = f.path.split(RegExp(r'(/|\\)')).last;
      test(name, () {
        final List<int> bytes = f.readAsBytesSync();
        final image = BmpDecoder().decodeImage(bytes);
        if (image == null) {
          throw ImageException('Unable to decode BMP Image: $name.');
        }

        final bmp = BmpEncoder().encodeImage(image);
        File('$tmpPath/out/bmp/$name.bmp')
          ..createSync(recursive: true)
          ..writeAsBytesSync(bmp);
      });
    }
  });
}
