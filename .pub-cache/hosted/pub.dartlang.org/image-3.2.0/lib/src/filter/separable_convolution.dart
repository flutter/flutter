import '../image.dart';
import 'separable_kernel.dart';

/// Apply a generic separable convolution filter the [src] image, using the
/// given [kernel].
///
/// [gaussianBlur] is an example of such a filter.
Image separableConvolution(Image src, SeparableKernel kernel) {
  // Apply the filter horizontally
  final tmp = Image.from(src);
  kernel.apply(src, tmp);

  // Apply the filter vertically, applying back to the original image.
  kernel.apply(tmp, src, horizontal: false);

  return src;
}
