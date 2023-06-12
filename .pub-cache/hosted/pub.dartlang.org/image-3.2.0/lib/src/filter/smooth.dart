import '../image.dart';
import 'convolution.dart';

/// Apply a smoothing convolution filter to the [src] image.
///
/// [w] is the weight of the current pixel being filtered. If it's greater than
/// 1.0, it will make the image sharper.
Image smooth(Image src, num w) {
  final filter = [1.0, 1.0, 1.0, 1.0, w.toDouble(), 1.0, 1.0, 1.0, 1.0];
  return convolution(src, filter, div: w + 8, offset: 0);
}
