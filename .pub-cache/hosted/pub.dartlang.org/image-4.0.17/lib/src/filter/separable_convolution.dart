import '../color/channel.dart';
import '../image/image.dart';
import 'separable_kernel.dart';

/// Apply a generic separable convolution filter the [src] image, using the
/// given [kernel].
///
/// gaussianBlur is an example of such a filter.
Image separableConvolution(Image src,
    {required SeparableKernel kernel,
    Image? mask,
    Channel maskChannel = Channel.luminance}) {
  final tmp = Image.from(src);
  // Apply the filter horizontally
  kernel
    ..apply(src, tmp, mask: mask, maskChannel: maskChannel)
    // Apply the filter vertically, applying back to the original image.
    ..apply(tmp, src, horizontal: false, mask: mask, maskChannel: maskChannel);

  return src;
}
