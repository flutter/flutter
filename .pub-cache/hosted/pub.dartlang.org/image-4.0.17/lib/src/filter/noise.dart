import 'dart:math';

import '../color/channel.dart';
import '../image/image.dart';
import '../util/math_util.dart';
import '../util/min_max.dart';
import '../util/random.dart';

enum NoiseType { gaussian, uniform, saltAndPepper, poisson, rice }

/// Add random noise to pixel values. [sigma] determines how strong the effect
/// should be. [type] should be one of the following: [NoiseType.gaussian],
/// [NoiseType.uniform], [NoiseType.saltAndPepper], [NoiseType.poisson],
/// or [NoiseType.rice].
Image noise(Image image, num sigma,
    {NoiseType type = NoiseType.gaussian,
    Random? random,
    Image? mask,
    Channel maskChannel = Channel.luminance}) {
  random ??= Random();

  var nSigma = sigma;
  num m = 0;
  num M = 0;

  if (nSigma == 0.0 && type != NoiseType.poisson) {
    return image;
  }

  if (nSigma < 0.0 || type == NoiseType.saltAndPepper) {
    final mM = minMax(image);
    m = mM[0];
    M = mM[1];
  }

  if (nSigma < 0.0) {
    nSigma = -nSigma * (M - m) / 100.0;
  }

  for (final frame in image.frames) {
    switch (type) {
      case NoiseType.gaussian:
        for (final p in frame) {
          final r = p.r + nSigma * grand(random);
          final g = p.g + nSigma * grand(random);
          final b = p.b + nSigma * grand(random);
          final a = p.a;
          final msk =
              mask?.getPixel(p.x, p.y).getChannelNormalized(maskChannel);
          if (msk == null) {
            p.setRgba(r, g, b, a);
          } else {
            p
              ..r = mix(p.r, r, msk)
              ..g = mix(p.g, g, msk)
              ..b = mix(p.b, b, msk)
              ..a = mix(p.a, a, msk);
          }
        }
        break;
      case NoiseType.uniform:
        for (final p in frame) {
          final r = p.r + nSigma * crand(random);
          final g = p.g + nSigma * crand(random);
          final b = p.b + nSigma * crand(random);
          final a = p.a;
          final msk =
              mask?.getPixel(p.x, p.y).getChannelNormalized(maskChannel);
          if (msk == null) {
            p.setRgba(r, g, b, a);
          } else {
            p
              ..r = mix(p.r, r, msk)
              ..g = mix(p.g, g, msk)
              ..b = mix(p.b, b, msk)
              ..a = mix(p.a, a, msk);
          }
        }
        break;
      case NoiseType.saltAndPepper:
        if (nSigma < 0) {
          nSigma = -nSigma;
        }
        if (M == m) {
          m = 0;
          M = 255;
        }
        for (final p in frame) {
          if (random.nextDouble() * 100.0 < nSigma) {
            final r = random.nextDouble() < 0.5 ? M : m;
            final g = random.nextDouble() < 0.5 ? M : m;
            final b = random.nextDouble() < 0.5 ? M : m;
            final a = p.a;
            final msk =
                mask?.getPixel(p.x, p.y).getChannelNormalized(maskChannel);
            if (msk == null) {
              p.setRgba(r, g, b, a);
            } else {
              p
                ..r = mix(p.r, r, msk)
                ..g = mix(p.g, g, msk)
                ..b = mix(p.b, b, msk)
                ..a = mix(p.a, a, msk);
            }
          }
        }
        break;
      case NoiseType.poisson:
        for (final p in frame) {
          final r = prand(random, p.r.toDouble());
          final g = prand(random, p.g.toDouble());
          final b = prand(random, p.b.toDouble());
          final a = p.a;
          final msk =
              mask?.getPixel(p.x, p.y).getChannelNormalized(maskChannel);
          if (msk == null) {
            p.setRgba(r, g, b, a);
          } else {
            p
              ..r = mix(p.r, r, msk)
              ..g = mix(p.g, g, msk)
              ..b = mix(p.b, b, msk)
              ..a = mix(p.a, a, msk);
          }
        }
        break;
      case NoiseType.rice:
        final num sqrt2 = sqrt(2.0);
        for (final p in frame) {
          var val0 = p.r / sqrt2;
          var re = val0 + nSigma * grand(random);
          var im = val0 + nSigma * grand(random);
          var val = sqrt(re * re + im * im);
          final r = val.toInt();

          val0 = p.g / sqrt2;
          re = val0 + nSigma * grand(random);
          im = val0 + nSigma * grand(random);
          val = sqrt(re * re + im * im);
          final g = val.toInt();

          val0 = p.b / sqrt2;
          re = val0 + nSigma * grand(random);
          im = val0 + nSigma * grand(random);
          val = sqrt(re * re + im * im);
          final b = val.toInt();

          final a = p.a;

          final msk =
              mask?.getPixel(p.x, p.y).getChannelNormalized(maskChannel);
          if (msk == null) {
            p.setRgba(r, g, b, a);
          } else {
            p
              ..r = mix(p.r, r, msk)
              ..g = mix(p.g, g, msk)
              ..b = mix(p.b, b, msk)
              ..a = mix(p.a, a, msk);
          }
        }
        break;
    }
  }

  return image;
}
