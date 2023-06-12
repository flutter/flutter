import '../color/channel.dart';
import '../image/image.dart';
import 'convolution.dart';

/// Apply a smoothing convolution filter to the [src] image.
///
/// [weight] is the weight of the current pixel being filtered. If it's greater
/// than 1.0, it will make the image sharper.
Image smooth(Image src,
    {required num weight,
    Image? mask,
    Channel maskChannel = Channel.luminance}) {
  final filter = [1.0, 1.0, 1.0, 1.0, weight.toDouble(), 1.0, 1.0, 1.0, 1.0];
  return convolution(src,
      filter: filter,
      div: weight + 8,
      offset: 0,
      mask: mask,
      maskChannel: maskChannel);
}
