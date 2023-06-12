import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import 'paths.dart';

void main() {
  final dir = Directory('test/res/tiff');
  if (!dir.existsSync()) {
    return;
  }
  final files = dir.listSync();

  group('TIFF/getInfo', () {
    for (var f in files.whereType<File>()) {
      if (!f.path.endsWith('.tif') && !f.path.endsWith('.tiff')) {
        continue;
      }

      final name = f.path.split(RegExp(r'(/|\\)')).last;
      test(name, () {
        final bytes = f.readAsBytesSync();

        final info = TiffDecoder().startDecode(bytes);
        if (info == null) {
          throw ImageException('Unable to parse Tiff info: $name.');
        }

        print(name);
        print('  width: ${info.width}');
        print('  height: ${info.height}');
        print('  bigEndian: ${info.bigEndian}');
        print('  images: ${info.images.length}');
        for (var i = 0; i < info.images.length; ++i) {
          print('  image[$i]');
          print('    width: ${info.images[i].width}');
          print('    height: ${info.images[i].height}');
          print('    photometricType: ${info.images[i].photometricType}');
          print('    compression: ${info.images[i].compression}');
          print('    bitsPerSample: ${info.images[i].bitsPerSample}');
          print('    samplesPerPixel: ${info.images[i].samplesPerPixel}');
          print('    imageType: ${info.images[i].imageType}');
          print('    tiled: ${info.images[i].tiled}');
          print('    tileWidth: ${info.images[i].tileWidth}');
          print('    tileHeight: ${info.images[i].tileHeight}');
          print('    predictor: ${info.images[i].predictor}');
          if (info.images[i].colorMap != null) {
            print(
                '    colorMap.numColors: ${info.images[i].colorMap!.length ~/ 3}');
            print('    colorMap: ${info.images[i].colorMap}');
          }
        }
      });
    }
  });

  group('TIFF/decodeImage', () {
    for (var f in files) {
      if (f is! File ||
          (!f.path.endsWith('.tif') && !f.path.endsWith('.tiff'))) {
        continue;
      }

      final name = f.path.split(RegExp(r'(/|\\)')).last;
      test(name, () {
        final List<int> bytes = f.readAsBytesSync();
        final image = TiffDecoder().decodeImage(bytes);
        if (image == null) {
          throw ImageException('Unable to decode TIFF Image: $name.');
        }

        final png = PngEncoder().encodeImage(image);
        File('$tmpPath/out/tif/$name.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(png);

        final tif = TiffEncoder().encodeImage(image);
        File('$tmpPath/out/tif/$name.tif')
          ..createSync(recursive: true)
          ..writeAsBytesSync(tif);

        final img2 = TiffDecoder().decodeImage(tif)!;
        expect(img2.width, equals(image.width));
        expect(img2.height, equals(image.height));

        final png2 = PngEncoder().encodeImage(image);
        File('$tmpPath/out/tif/$name-2.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(png2);
      });
    }
  });

  group('TIFF/dtm_test', () {
    test('dtm_test.tif', () {
      final bytes = File('test/res/tiff/dtm_test.tif').readAsBytesSync();
      final image = TiffDecoder().decodeHdrImage(bytes)!;
      expect(image.numberOfChannels, equals(1));
      expect(image.red!.data[11], equals(-9999.0));
      final img = hdrToImage(image);
      File('$tmpPath/out/tif/dtm_test.hdr.png')
          .writeAsBytesSync(encodePng(img));
    });
  });

  group('TIFF/tca32int', () {
    test('tca32int.tif', () {
      final bytes = File('test/res/tiff/tca32int.tif').readAsBytesSync();
      final decoder = TiffDecoder();
      final image = decoder.decodeHdrImage(bytes)!;
      expect(image.numberOfChannels, equals(1));
      final tags = decoder.info!.images[0].tags;
      for (var tag in tags.keys) {
        final entry = tags[tag]!;
        if (entry.type == TiffEntry.TYPE_ASCII) {
          print('tca32int TAG $tag: ${entry.readString()}');
        } else {
          print('tca32int TAG $tag: ${entry.read()}');
        }
      }

      //File('$tmpPath/out/tif/tca32int.tif')
      //.writeAsBytes(TiffEncoder().encodeHdrImage(image));

      final img = hdrToImage(image);
      File('$tmpPath/out/tif/tca32int.hdr.png')
          .writeAsBytesSync(encodePng(img));
    });
  });

  group('TIFF/dtm64float', () {
    test('dtm64float.tif', () {
      final bytes = File('test/res/tiff/dtm64float.tif').readAsBytesSync();
      final decoder = TiffDecoder();
      final image = decoder.decodeHdrImage(bytes)!;
      expect(image.numberOfChannels, equals(1));
      final tags = decoder.info!.images[0].tags;
      for (var tag in tags.keys) {
        final entry = tags[tag]!;
        if (entry.type == TiffEntry.TYPE_ASCII) {
          print('dtm64float TAG $tag: ${entry.readString()}');
        } else {
          print('dtm64float TAG $tag: ${entry.read()}');
        }
      }

      //File('$tmpPath/out/tif/dtm64float.tif')
      //.writeAsBytes(TiffEncoder().encodeHdrImage(image));

      final img = hdrToImage(image);
      File('$tmpPath/out/tif/dtm64float.hdr.png')
          .writeAsBytesSync(encodePng(img));
    });
  });

  group('TIFF/startDecode', () {
    test('dtm64float.tif', () {
      final bytes = File('test/res/tiff/dtm64float.tif').readAsBytesSync();
      final decoder = TiffDecoder();
      final info = decoder.startDecode(bytes)!;
      final tags = info.images[0].tags;
      for (var tag in tags.keys) {
        final entry = tags[tag]!;
        if (entry.type == TiffEntry.TYPE_ASCII) {
          print('dtm64float TAG $tag: ${entry.readString()}');
        } else {
          print('dtm64float TAG $tag: ${entry.read()}');
        }
      }
    });
  });

  group('TIFF/float1x32', () {
    test('float1x32.tif', () {
      final bytes = File('test/res/tiff/float1x32.tif').readAsBytesSync();
      final decoder = TiffDecoder();
      final image = decoder.decodeHdrImage(bytes)!;
      expect(image.numberOfChannels, equals(1));

      File('$tmpPath/out/tif/float1x32.tif')
          .writeAsBytes(TiffEncoder().encodeHdrImage(image));

      final img = hdrToImage(image);
      File('$tmpPath/out/tif/float1x32.hdr.png')
          .writeAsBytesSync(encodePng(img));
    });
  });

  group('TIFF/float32', () {
    test('float32.tif', () {
      final bytes = File('test/res/tiff/float32.tif').readAsBytesSync();
      final decoder = TiffDecoder();
      final image = decoder.decodeHdrImage(bytes)!;
      expect(image.numberOfChannels, equals(3));

      File('$tmpPath/out/tif/float32.tif')
          .writeAsBytes(TiffEncoder().encodeHdrImage(image));

      final img = hdrToImage(image);
      File('$tmpPath/out/tif/float32.hdr.png').writeAsBytesSync(encodePng(img));
    });
  });
}
