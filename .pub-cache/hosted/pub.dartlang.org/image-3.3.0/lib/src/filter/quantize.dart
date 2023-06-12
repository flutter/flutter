import '../image.dart';
import '../util/neural_quantizer.dart';
import '../util/octree_quantizer.dart';

enum QuantizeMethod { neuralNet, octree }

/// Quantize the number of colors in image to 256.
Image quantize(Image src,
    {int numberOfColors = 256,
    QuantizeMethod method = QuantizeMethod.neuralNet}) {
  if (method == QuantizeMethod.octree || numberOfColors < 4) {
    final oct = OctreeQuantizer(src, numberOfColors: numberOfColors);
    for (var i = 0, len = src.length; i < len; ++i) {
      src[i] = oct.getQuantizedColor(src[i]);
    }
    return src;
  }

  final quant = NeuralQuantizer(src, numberOfColors: numberOfColors);
  for (var i = 0, len = src.length; i < len; ++i) {
    src[i] = quant.getQuantizedColor(src[i]);
  }
  return src;
}
