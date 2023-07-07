import '../color/channel.dart';
import '../image/image.dart';
import 'convolution.dart';

/// Apply an emboss convolution filter.
Image emboss(Image src,
    {num amount = 1, Image? mask, Channel maskChannel = Channel.luminance}) {
  const filter = [1.5, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, -1.5];
  return convolution(src,
      filter: filter,
      div: 1,
      offset: 127,
      amount: amount,
      mask: mask,
      maskChannel: maskChannel);
}
