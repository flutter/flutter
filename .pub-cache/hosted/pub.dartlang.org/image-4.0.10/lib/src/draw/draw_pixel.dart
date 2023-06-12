import 'dart:math';

import '../color/channel.dart';
import '../color/color.dart';
import '../image/image.dart';
import '../util/math_util.dart';
import 'blend_mode.dart';

/// Draw a single pixel into the image, applying alpha and opacity blending.
/// If [filter] is provided, the color c will be scaled by the [filter]
/// color. If [alpha] is provided, it will be used in place of the
/// color alpha, as a normalized color value \[0, 1\].
Image drawPixel(Image image, int x, int y, Color c,
    {Color? filter,
    num? alpha,
    BlendMode blend = BlendMode.alpha,
    bool linearBlend = false,
    Image? mask,
    Channel maskChannel = Channel.luminance}) {
  if (!image.isBoundsSafe(x, y)) {
    return image;
  }

  if (blend == BlendMode.direct || image.hasPalette) {
    if (image.isBoundsSafe(x, y)) {
      image.getPixel(x, y).set(c);
      return image;
    }
  }

  final msk = mask?.getPixel(x, y).getChannelNormalized(maskChannel) ?? 1;

  var overlayR =
      filter != null ? c.rNormalized * filter.rNormalized : c.rNormalized;
  var overlayG =
      filter != null ? c.gNormalized * filter.gNormalized : c.gNormalized;
  var overlayB =
      filter != null ? c.bNormalized * filter.bNormalized : c.bNormalized;

  final overlayA = (alpha ?? (c.length < 4 ? 1.0 : c.aNormalized)) * msk;

  if (overlayA == 0) {
    return image;
  }

  final dst = image.getPixel(x, y);

  final baseR = dst.rNormalized;
  final baseG = dst.gNormalized;
  final baseB = dst.bNormalized;
  final baseA = dst.aNormalized;

  switch (blend) {
    case BlendMode.direct:
      return image;
    case BlendMode.alpha:
      break;
    case BlendMode.lighten:
      overlayR = max(baseR, overlayR);
      overlayG = max(baseG, overlayG);
      overlayB = max(baseB, overlayB);
      break;
    case BlendMode.screen:
      overlayR = 1 - ((1 - overlayR) * (1 - baseR));
      overlayG = 1 - ((1 - overlayG) * (1 - baseG));
      overlayB = 1 - ((1 - overlayB) * (1 - baseB));
      break;
    case BlendMode.dodge:
      final baseOverlayAlphaProduct = overlayA * baseA;

      final rightHandProductR = overlayR * (1 - baseA) + baseR * (1 - overlayA);
      final rightHandProductG = overlayG * (1 - baseA) + baseG * (1 - overlayA);
      final rightHandProductB = overlayB * (1 - baseA) + baseB * (1 - overlayA);

      final firstBlendColorR = baseOverlayAlphaProduct + rightHandProductR;
      final firstBlendColorG = baseOverlayAlphaProduct + rightHandProductG;
      final firstBlendColorB = baseOverlayAlphaProduct + rightHandProductB;

      final oR = (overlayR / overlayA.clamp(0.01, 1) * step(0, overlayA))
          .clamp(0, 0.99);
      final oG = (overlayG / overlayA.clamp(0.01, 1) * step(0, overlayA))
          .clamp(0, 0.99);
      final oB = (overlayB / overlayA.clamp(0.01, 1) * step(0, overlayA))
          .clamp(0, 0.99);

      final secondBlendColorR =
          (baseR * overlayA) / (1 - oR) + rightHandProductR;
      final secondBlendColorG =
          (baseG * overlayA) / (1 - oG) + rightHandProductG;
      final secondBlendColorB =
          (baseB * overlayA) / (1 - oB) + rightHandProductB;

      final colorChoiceR =
          step(overlayR * baseA + baseR * overlayA, baseOverlayAlphaProduct);
      final colorChoiceG =
          step(overlayG * baseA + baseG * overlayA, baseOverlayAlphaProduct);
      final colorChoiceB =
          step(overlayB * baseA + baseB * overlayA, baseOverlayAlphaProduct);

      overlayR = mix(firstBlendColorR, secondBlendColorR, colorChoiceR);
      overlayG = mix(firstBlendColorG, secondBlendColorG, colorChoiceG);
      overlayB = mix(firstBlendColorB, secondBlendColorB, colorChoiceB);
      break;
    case BlendMode.addition:
      overlayR = baseR + overlayR;
      overlayG = baseG + overlayG;
      overlayB = baseB + overlayB;
      break;
    case BlendMode.darken:
      overlayR = min(baseR, overlayR);
      overlayG = min(baseG, overlayG);
      overlayB = min(baseB, overlayB);
      break;
    case BlendMode.multiply:
      overlayR = baseR * overlayR;
      overlayG = baseG * overlayG;
      overlayB = baseB * overlayB;
      break;
    case BlendMode.burn:
      overlayR = overlayR != 0 ? 1 - (1 - baseR) / overlayR : 0;
      overlayG = overlayG != 0 ? 1 - (1 - baseG) / overlayG : 0;
      overlayB = overlayB != 0 ? 1 - (1 - baseB) / overlayB : 0;
      break;
    case BlendMode.overlay:
      if (2.0 * baseR < baseA) {
        overlayR = 2.0 * overlayR * baseR +
            overlayR * (1.0 - baseA) +
            baseR * (1.0 - overlayA);
      } else {
        overlayR = overlayA * baseA -
            2.0 * (baseA - baseR) * (overlayA - overlayR) +
            overlayR * (1.0 - baseA) +
            baseR * (1.0 - overlayA);
      }

      if (2.0 * baseG < baseA) {
        overlayG = 2.0 * overlayG * baseG +
            overlayG * (1.0 - baseA) +
            baseG * (1.0 - overlayA);
      } else {
        overlayG = overlayA * baseA -
            2.0 * (baseA - baseG) * (overlayA - overlayG) +
            overlayG * (1.0 - baseA) +
            baseG * (1.0 - overlayA);
      }

      if (2.0 * baseB < baseA) {
        overlayB = 2.0 * overlayB * baseB +
            overlayB * (1.0 - baseA) +
            baseB * (1.0 - overlayA);
      } else {
        overlayB = overlayA * baseA -
            2.0 * (baseA - baseB) * (overlayA - overlayB) +
            overlayB * (1.0 - baseA) +
            baseB * (1.0 - overlayA);
      }
      break;
    case BlendMode.softLight:
      overlayR = baseA == 0
          ? 0
          : baseR *
                  (overlayA * (baseR / baseA) +
                      (2 * overlayR * (1 - (baseR / baseA)))) +
              overlayR * (1 - baseA) +
              baseR * (1 - overlayA);

      overlayG = baseA == 0
          ? 0
          : baseG *
                  (overlayA * (baseG / baseA) +
                      (2 * overlayG * (1 - (baseG / baseA)))) +
              overlayG * (1 - baseA) +
              baseG * (1 - overlayA);

      overlayB = baseA == 0
          ? 0
          : baseB *
                  (overlayA * (baseB / baseA) +
                      (2 * overlayB * (1 - (baseB / baseA)))) +
              overlayB * (1 - baseA) +
              baseB * (1 - overlayA);
      break;
    case BlendMode.hardLight:
      if (2.0 * overlayR < overlayA) {
        overlayR = 2.0 * overlayR * baseR +
            overlayR * (1.0 - baseA) +
            baseR * (1.0 - overlayA);
      } else {
        overlayR = overlayA * baseA -
            2.0 * (baseA - baseR) * (overlayA - overlayR) +
            overlayR * (1.0 - baseA) +
            baseR * (1.0 - overlayA);
      }

      if (2.0 * overlayG < overlayA) {
        overlayG = 2.0 * overlayG * baseG +
            overlayG * (1.0 - baseA) +
            baseG * (1.0 - overlayA);
      } else {
        overlayG = overlayA * baseA -
            2.0 * (baseA - baseG) * (overlayA - overlayG) +
            overlayG * (1.0 - baseA) +
            baseG * (1.0 - overlayA);
      }

      if (2.0 * overlayB < overlayA) {
        overlayB = 2.0 * overlayB * baseB +
            overlayB * (1.0 - baseA) +
            baseB * (1.0 - overlayA);
      } else {
        overlayB = overlayA * baseA -
            2.0 * (baseA - baseB) * (overlayA - overlayB) +
            overlayB * (1.0 - baseA) +
            baseB * (1.0 - overlayA);
      }
      break;
    case BlendMode.difference:
      overlayR = (overlayR - baseR).abs();
      overlayG = (overlayG - baseG).abs();
      overlayB = (overlayB - baseB).abs();
      break;
    case BlendMode.subtract:
      overlayR = baseR - overlayR;
      overlayG = baseG - overlayG;
      overlayB = baseB - overlayB;
      break;
    case BlendMode.divide:
      overlayR = overlayR != 0 ? baseR / overlayR : 0;
      overlayG = overlayG != 0 ? baseG / overlayG : 0;
      overlayB = overlayB != 0 ? baseB / overlayB : 0;
      break;
  }

  final invA = 1.0 - overlayA;

  if (linearBlend) {
    final lbr = pow(baseR, 2.2);
    final lbg = pow(baseG, 2.2);
    final lbb = pow(baseB, 2.2);
    final lor = pow(overlayR, 2.2);
    final log = pow(overlayG, 2.2);
    final lob = pow(overlayB, 2.2);
    final r = pow(lor * overlayA + lbr * baseA * invA, 1.0 / 2.2);
    final g = pow(log * overlayA + lbg * baseA * invA, 1.0 / 2.2);
    final b = pow(lob * overlayA + lbb * baseA * invA, 1.0 / 2.2);
    final a = overlayA + baseA * invA;

    dst
      ..rNormalized = r
      ..gNormalized = g
      ..bNormalized = b
      ..aNormalized = a;
  } else {
    final r = overlayR * overlayA + baseR * baseA * invA;
    final g = overlayG * overlayA + baseG * baseA * invA;
    final b = overlayB * overlayA + baseB * baseA * invA;
    final a = overlayA + baseA * invA;

    dst
      ..rNormalized = r
      ..gNormalized = g
      ..bNormalized = b
      ..aNormalized = a;
  }

  return image;
}
