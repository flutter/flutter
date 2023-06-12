import 'dart:math';

import '../color/channel.dart';
import '../image/image.dart';
import '../util/math_util.dart';

/// Apply gamma scaling
Image gamma(Image src,
    {required num gamma,
    Image? mask,
    Channel maskChannel = Channel.luminance}) {
  for (final frame in src.frames) {
    for (final p in frame) {
      final msk = mask?.getPixel(p.x, p.y).getChannelNormalized(maskChannel);
      if (msk == null) {
        p
          ..rNormalized = pow(p.rNormalized, gamma)
          ..gNormalized = pow(p.gNormalized, gamma)
          ..bNormalized = pow(p.bNormalized, gamma);
      } else {
        p
          ..rNormalized = mix(p.rNormalized, pow(p.rNormalized, gamma), msk)
          ..gNormalized = mix(p.gNormalized, pow(p.gNormalized, gamma), msk)
          ..bNormalized = mix(p.bNormalized, pow(p.bNormalized, gamma), msk);
      }
    }
  }
  return src;
}
