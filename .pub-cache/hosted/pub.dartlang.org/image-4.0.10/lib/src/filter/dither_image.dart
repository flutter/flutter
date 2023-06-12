import 'dart:math';

import '../image/image.dart';
import '../util/neural_quantizer.dart';
import '../util/quantizer.dart';

/// The pattern to use for dithering
enum DitherKernel {
  none,
  falseFloydSteinberg,
  floydSteinberg,
  stucki,
  atkinson
}

const _ditherKernels = [
  [
    [0, 0, 0],
    [0, 0, 0],
    [0, 0, 0]
  ],
  // FalseFloydSteinberg
  [
    [3 / 8, 1, 0],
    [3 / 8, 0, 1],
    [2 / 8, 1, 1]
  ],
  // FloydSteinberg
  [
    [7 / 16, 1, 0],
    [3 / 16, -1, 1],
    [5 / 16, 0, 1],
    [1 / 16, 1, 1]
  ],
  // Stucki
  [
    [8 / 42, 1, 0],
    [4 / 42, 2, 0],
    [2 / 42, -2, 1],
    [4 / 42, -1, 1],
    [8 / 42, 0, 1],
    [4 / 42, 1, 1],
    [2 / 42, 2, 1],
    [1 / 42, -2, 2],
    [2 / 42, -1, 2],
    [4 / 42, 0, 2],
    [2 / 42, 1, 2],
    [1 / 42, 2, 2]
  ],
  //Atkinson:
  [
    [1 / 8, 1, 0],
    [1 / 8, 2, 0],
    [1 / 8, -1, 1],
    [1 / 8, 0, 1],
    [1 / 8, 1, 1],
    [1 / 8, 0, 2]
  ]
];

/// Dither an image to reduce banding patterns when reducing the number of
/// colors.
Image ditherImage(Image image,
    {Quantizer? quantizer,
    DitherKernel kernel = DitherKernel.floydSteinberg,
    bool serpentine = false}) {
  quantizer ??= NeuralQuantizer(image);

  if (kernel == DitherKernel.none) {
    return quantizer.getIndexImage(image);
  }

  final ds = _ditherKernels[kernel.index];
  final height = image.height;
  final width = image.width;

  var direction = serpentine ? -1 : 1;

  final palette = quantizer.palette;
  final indexedImage =
      Image(width: width, height: height, numChannels: 1, palette: palette);

  final pIter = image.iterator..moveNext();

  var index = 0;
  for (var y = 0; y < height; y++) {
    if (serpentine) direction = direction * -1;

    final x0 = direction == 1 ? 0 : width - 1;
    final x1 = direction == 1 ? width : 0;
    for (var x = x0; x != x1; x += direction, ++index, pIter.moveNext()) {
      // Get original color
      final pc = pIter.current;
      final r1 = pc[0].toInt();
      final g1 = pc[1].toInt();
      final b1 = pc[2].toInt();

      // Get converted color
      var idx = quantizer.getColorIndexRgb(r1, g1, b1);
      indexedImage.setPixelRgb(x, y, idx, 0, 0);

      final r2 = palette.get(idx, 0);
      final g2 = palette.get(idx, 1);
      final b2 = palette.get(idx, 2);

      final er = r1 - r2;
      final eg = g1 - g2;
      final eb = b1 - b2;

      if (er == 0 && eg == 0 && eb == 0) {
        continue;
      }

      final i0 = direction == 1 ? 0 : ds.length - 1;
      final i1 = direction == 1 ? ds.length : 0;
      for (var i = i0; i != i1; i += direction) {
        final x1 = ds[i][1].toInt();
        final y1 = ds[i][2].toInt();
        if (x1 + x >= 0 && x1 + x < width && y1 + y >= 0 && y1 + y < height) {
          final d = ds[i][0];
          idx = index + x1 + (y1 * width);
          idx *= 4;
          final p2 = image.getPixel(x1, y1);
          p2
            ..r = max(0, min(255, (p2.r + er * d).toInt()))
            ..g = max(0, min(255, (p2.g + er * d).toInt()))
            ..b = max(0, min(255, (p2.b + er * d).toInt()));
        }
      }
    }
  }

  return indexedImage;
}
