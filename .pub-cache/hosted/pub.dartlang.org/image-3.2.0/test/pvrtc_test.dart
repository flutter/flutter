import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import 'paths.dart';

void main() {
  group('PVRTC', () {
    test('encode_rgb_4bpp', () {
      final bytes = File('test/res/tga/globe.tga').readAsBytesSync();
      final image = TgaDecoder().decodeImage(bytes)!;

      File('$tmpPath/out/pvrtc/globe_before.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(image));

      // Encode the image to PVRTC
      final pvrtc = PvrtcEncoder().encodeRgb4Bpp(image);

      final decoded =
          PvrtcDecoder().decodeRgb4bpp(image.width, image.height, pvrtc);
      File('$tmpPath/out/pvrtc/globe_after.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(decoded));

      final pvr = PvrtcEncoder().encodePvr(image);
      File('$tmpPath/out/pvrtc/globe.pvr')
        ..createSync(recursive: true)
        ..writeAsBytesSync(pvr);
    });

    test('encode_rgba_4bpp', () {
      final bytes = File('test/res/png/alpha_edge.png').readAsBytesSync();
      final image = PngDecoder().decodeImage(bytes)!;

      File('$tmpPath/out/pvrtc/alpha_before.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(image));

      // Encode the image to PVRTC
      final pvrtc = PvrtcEncoder().encodeRgba4Bpp(image);

      final decoded =
          PvrtcDecoder().decodeRgba4bpp(image.width, image.height, pvrtc);
      File('$tmpPath/out/pvrtc/alpha_after.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(decoded));

      final pvr = PvrtcEncoder().encodePvr(image);
      File('$tmpPath/out/pvrtc/alpha.pvr')
        ..createSync(recursive: true)
        ..writeAsBytesSync(pvr);
    });
  });

  group('PVR Decode', () {
    final dir = Directory('test/res/pvr');
    final files = dir.listSync();
    for (var f in files.whereType<File>()) {
      if (!f.path.endsWith('.pvr')) {
        continue;
      }
      final name = f.path.split(RegExp(r'(/|\\)')).last;
      test(name, () {
        final List<int> bytes = f.readAsBytesSync();
        final img = PvrtcDecoder().decodePvr(bytes)!;
        File('$tmpPath/out/pvrtc/pvr_$name.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(encodePng(img));
      });
    }
  });
}
