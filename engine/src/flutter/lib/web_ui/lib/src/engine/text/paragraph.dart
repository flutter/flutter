// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/ui.dart' as ui;

class EngineLineMetrics implements ui.LineMetrics {
  const EngineLineMetrics({
    required this.hardBreak,
    required this.ascent,
    required this.descent,
    required this.unscaledAscent,
    required this.height,
    required this.width,
    required this.left,
    required this.baseline,
    required this.lineNumber,
  });

  @override
  final bool hardBreak;

  @override
  final double ascent;

  @override
  final double descent;

  @override
  final double unscaledAscent;

  @override
  final double height;

  @override
  final double width;

  @override
  final double left;

  @override
  final double baseline;

  @override
  final int lineNumber;

  @override
  int get hashCode => Object.hash(
    hardBreak,
    ascent,
    descent,
    unscaledAscent,
    height,
    width,
    left,
    baseline,
    lineNumber,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is EngineLineMetrics &&
        other.hardBreak == hardBreak &&
        other.ascent == ascent &&
        other.descent == descent &&
        other.unscaledAscent == unscaledAscent &&
        other.height == height &&
        other.width == width &&
        other.left == left &&
        other.baseline == baseline &&
        other.lineNumber == lineNumber;
  }

  @override
  String toString() {
    var result = super.toString();
    assert(() {
      result =
          'LineMetrics(hardBreak: $hardBreak, '
          'ascent: $ascent, '
          'descent: $descent, '
          'unscaledAscent: $unscaledAscent, '
          'height: $height, '
          'width: $width, '
          'left: $left, '
          'baseline: $baseline, '
          'lineNumber: $lineNumber)';
      return true;
    }());
    return result;
  }
}

extension FontStyleExtension on ui.FontStyle {
  /// Converts a [ui.FontStyle] value to its CSS equivalent.
  String toCssString() {
    return this == ui.FontStyle.normal ? 'normal' : 'italic';
  }
}

extension FontWeightExtension on ui.FontWeight {
  /// Converts a [ui.FontWeight] value to its CSS equivalent.
  String toCssString() {
    return fontWeightIndexToCss(fontWeightIndex: index);
  }
}

String fontWeightIndexToCss({int fontWeightIndex = 3}) {
  switch (fontWeightIndex) {
    case 0:
      return '100';
    case 1:
      return '200';
    case 2:
      return '300';
    case 3:
      return 'normal';
    case 4:
      return '500';
    case 5:
      return '600';
    case 6:
      return 'bold';
    case 7:
      return '800';
    case 8:
      return '900';
  }

  assert(() {
    throw AssertionError('Failed to convert font weight $fontWeightIndex to CSS.');
  }());

  return '';
}

/// Converts [align] to its corresponding CSS value.
///
/// This value is used as the "text-align" CSS property, e.g.:
///
/// ```css
/// text-align: right;
/// ```
String textAlignToCssValue(ui.TextAlign? align, ui.TextDirection textDirection) {
  switch (align) {
    case ui.TextAlign.left:
      return 'left';
    case ui.TextAlign.right:
      return 'right';
    case ui.TextAlign.center:
      return 'center';
    case ui.TextAlign.justify:
      return 'justify';
    case ui.TextAlign.end:
      return switch (textDirection) {
        ui.TextDirection.ltr => 'end',
        ui.TextDirection.rtl => 'left',
      };
    case ui.TextAlign.start:
      return switch (textDirection) {
        ui.TextDirection.ltr => '', // it's the default
        ui.TextDirection.rtl => 'right',
      };
    case null:
      // If align is not specified return default.
      return '';
  }
}

String fontFeatureListToCss(List<ui.FontFeature> fontFeatures) {
  assert(fontFeatures.isNotEmpty);

  // For more details, see:
  // * https://developer.mozilla.org/en-US/docs/Web/CSS/font-feature-settings
  final sb = StringBuffer();
  final int len = fontFeatures.length;
  for (var i = 0; i < len; i++) {
    if (i != 0) {
      sb.write(',');
    }
    final ui.FontFeature fontFeature = fontFeatures[i];
    sb.write('"${fontFeature.feature}" ${fontFeature.value}');
  }
  return sb.toString();
}

String fontVariationListToCss(List<ui.FontVariation> fontVariations) {
  assert(fontVariations.isNotEmpty);

  final sb = StringBuffer();
  final int len = fontVariations.length;
  for (var i = 0; i < len; i++) {
    if (i != 0) {
      sb.write(',');
    }
    final ui.FontVariation fontVariation = fontVariations[i];
    sb.write('"${fontVariation.axis}" ${fontVariation.value}');
  }
  return sb.toString();
}
