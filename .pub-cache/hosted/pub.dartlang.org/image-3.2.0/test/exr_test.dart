import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import 'paths.dart';

void main() {
  group('EXR', () {
    test('decoding', () {
      final bytes = File('test/res/exr/grid.exr').readAsBytesSync();

      final dec = ExrDecoder();
      dec.startDecode(bytes);
      final img = dec.decodeFrame(0)!;

      final png = PngEncoder().encodeImage(img);
      File('$tmpPath/out/exr/grid.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png);
    });

    test('hdr image', () {
      final img = decodeJpg(File('test/res/jpg/big_buck_bunny.jpg').readAsBytesSync())!;
      img.channels = Channels.rgba;
      final hdr = HdrImage.fromImage(img);
      var img2 = hdrToImage(hdr);
      File('$tmpPath/out/exr/big_buck_bunny.png').writeAsBytesSync(encodePng(img2));

      hdrGamma(hdr);
      //hdrBloom(hdr, radius: 0.2);
      img2 = hdrToImage(hdr);
      File('$tmpPath/out/exr/big_buck_bunny_gamma.png')
          .writeAsBytesSync(encodePng(img2));
    });
  });
}
