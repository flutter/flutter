import 'dart:io';

import 'package:image/image.dart';
import 'package:test/test.dart';

import 'paths.dart';

void main() {
  final dir = Directory('test/res/psd');
  final files = dir.listSync();

  group('PSD', () {
    for (var f in files.whereType<File>()) {
      if (!f.path.endsWith('.psd')) {
        continue;
      }

      final name = f.path.split(RegExp(r'(/|\\)')).last;
      test(name, () {
        print('Decoding $name');

        final psd = PsdDecoder().decodeImage(f.readAsBytesSync());

        if (psd != null) {
          final outPng = PngEncoder().encodeImage(psd);
          File('$tmpPath/out/psd/$name.png')
            ..createSync(recursive: true)
            ..writeAsBytesSync(outPng);
        } else {
          throw StateError('Unable to decode $name');
        }
      });
    }
  });
}
