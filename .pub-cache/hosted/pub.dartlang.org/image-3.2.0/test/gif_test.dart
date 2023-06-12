import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import 'paths.dart';

void main() {
  final dir = Directory('test/res/gif');
  final files = dir.listSync();

  group('GIF', () {
    print(tmpPath);
    for (var f in files.whereType<File>()) {
      if (!f.path.endsWith('.gif')) {
        continue;
      }

      final name = f.path.split(RegExp(r'(/|\\)')).last;
      test('getInfo $name', () {
        final bytes = f.readAsBytesSync();

        final data = GifDecoder().startDecode(bytes);
        if (data == null) {
          throw ImageException('Unable to parse Gif info: $name.');
        }
      });
    }

    for (var f in files) {
      if (f is! File || !f.path.endsWith('.gif')) {
        continue;
      }

      final name = f.path.split(RegExp(r'(/|\\)')).last;
      test('decodeImage $name', () {
        final bytes = f.readAsBytesSync();
        final image = GifDecoder().decodeImage(bytes)!;
        File('$tmpPath/out/gif/$name.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(encodePng(image));
      });
    }

    for (var f in files) {
      if (f is! File || !f.path.endsWith('cars.gif')) {
        continue;
      }

      Animation? anim;
      final name = f.path.split(RegExp(r'(/|\\)')).last;
      test('decodeCars $name', () {
        final bytes = f.readAsBytesSync();
        anim = GifDecoder().decodeAnimation(bytes);
        expect(anim!.length, equals(30));
        expect(anim!.loopCount, equals(0));
      });

      test('encodeCars', () {
        final gif = encodeGifAnimation(anim!)!;
        File('$tmpPath/out/gif/cars.gif')
          ..createSync(recursive: true)
          ..writeAsBytesSync(gif);
      });
    }

    test('encodeAnimation', () {
      final anim = Animation();
      anim.loopCount = 10;
      for (var i = 0; i < 10; i++) {
        final image = Image(480, 120);
        drawString(image, arial_48, 100, 60, i.toString());
        anim.addFrame(image);
      }

      final gif = encodeGifAnimation(anim)!;
      File('$tmpPath/out/gif/encodeAnimation.gif')
        ..createSync(recursive: true)
        ..writeAsBytesSync(gif);

      final anim2 = GifDecoder().decodeAnimation(gif)!;
      expect(anim2.length, equals(10));
      expect(anim2.loopCount, equals(10));
    });

    test('encodeAnimation with variable FPS', () {
      final anim = Animation();
      for (var i = 1; i <= 3; i++) {
        final image = Image(480, 120);
        image.duration = i * 1000;
        drawString(image, arial_24, 50, 50, 'This frame is $i second(s) long');
        anim.addFrame(image);
      }

      final gif = encodeGifAnimation(anim)!;
      File('$tmpPath/out/gif/encodeAnimation_variable_fps.gif')
        ..createSync(recursive: true)
        ..writeAsBytesSync(gif);

      final anim2 = GifDecoder().decodeAnimation(gif)!;
      expect(anim2.length, equals(3));
      expect(anim2.loopCount, equals(0));
      expect(anim2[0].duration, equals(1000));
      expect(anim2[1].duration, equals(2000));
      expect(anim2[2].duration, equals(3000));
    });

    test('encodeImage', () {
      final bytes = File('test/res/jpg/jpeg444.jpg').readAsBytesSync();
      final image = JpegDecoder().decodeImage(bytes)!;

      final gif = GifEncoder().encodeImage(image);
      File('$tmpPath/out/gif/jpeg444.gif')
        ..createSync(recursive: true)
        ..writeAsBytesSync(gif);
    });

    test('encode_small_gif', () {
      final image =
          decodeJpg(File('test/res/jpg/big_buck_bunny.jpg').readAsBytesSync())!;
      final resized = copyResize(image, width: 16, height: 16);
      final gif = encodeGif(resized);
      File('$tmpPath/out/gif/encode_small_gif.gif')
        ..createSync(recursive: true)
        ..writeAsBytesSync(gif);
    });
  });
}
