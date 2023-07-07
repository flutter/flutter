import 'dart:math';
import 'dart:typed_data';
import '../image.dart';
import 'neural_quantizer.dart';

// From http://jsbin.com/iXofIji/2/edit by PAEz
enum DitherKernel {
  None,
  FalseFloydSteinberg,
  FloydSteinberg,
  Stucki,
  Atkinson
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

Uint8List ditherPixels(Image image, NeuralQuantizer quantizer,
    DitherKernel kernel, bool serpentine) {
  if (kernel == DitherKernel.None) {
    return quantizer.getIndexMap(image);
  }

  final ds = _ditherKernels[kernel.index];
  final height = image.height;
  final width = image.width;
  final data = Uint8List.fromList(image.getBytes());

  var direction = serpentine ? -1 : 1;

  final indexedPixels = Uint8List(width * height);
  final colorMap = quantizer.colorMap;

  var index = 0;
  for (var y = 0; y < height; y++) {
    if (serpentine) direction = direction * -1;

    final x0 = direction == 1 ? 0 : width - 1;
    final x1 = direction == 1 ? width : 0;
    for (var x = x0; x != x1; x += direction, ++index) {
      // Get original color
      var idx = index * 4;
      final r1 = data[idx];
      final g1 = data[idx + 1];
      final b1 = data[idx + 2];

      // Get converted color
      idx = quantizer.lookupRGB(r1, g1, b1);

      indexedPixels[index] = idx;
      idx *= 3;
      final r2 = colorMap[idx];
      final g2 = colorMap[idx + 1];
      final b2 = colorMap[idx + 2];

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
          var d = ds[i][0];
          idx = index + x1 + (y1 * width);
          idx *= 4;

          data[idx] = max(0, min(255, (data[idx] + er * d).toInt()));
          data[idx + 1] = max(0, min(255, (data[idx + 1] + eg * d).toInt()));
          data[idx + 2] = max(0, min(255, (data[idx + 2] + eb * d).toInt()));
        }
      }
    }
  }

  return indexedPixels;
}
