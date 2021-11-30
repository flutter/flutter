// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html' as html;

import 'package:ui/ui.dart' as ui;

import '../browser_detection.dart';
import '../embedder.dart';
import '../util.dart';
import 'measurement.dart';
import 'paragraph.dart';

String buildCssFontString({
  required ui.FontStyle? fontStyle,
  required ui.FontWeight? fontWeight,
  required double? fontSize,
  required String fontFamily,
}) {
  final StringBuffer result = StringBuffer();

  // Font style
  if (fontStyle != null) {
    result.write(fontStyle == ui.FontStyle.normal ? 'normal' : 'italic');
  } else {
    result.write(FlutterViewEmbedder.defaultFontStyle);
  }
  result.write(' ');

  // Font weight.
  if (fontWeight != null) {
    result.write(fontWeightToCss(fontWeight));
  } else {
    result.write(FlutterViewEmbedder.defaultFontWeight);
  }
  result.write(' ');

  if (fontSize != null) {
    result.write(fontSize.floor());
  } else {
    result.write(FlutterViewEmbedder.defaultFontSize);
  }
  result.write('px ');
  result.write(canonicalizeFontFamily(fontFamily));

  return result.toString();
}

/// Contains the subset of [ui.ParagraphStyle] properties that affect layout.
class ParagraphGeometricStyle {
  ParagraphGeometricStyle({
    required this.textDirection,
    required this.textAlign,
    this.fontWeight,
    this.fontStyle,
    this.fontFamily,
    this.fontSize,
    this.lineHeight,
    this.maxLines,
    this.letterSpacing,
    this.wordSpacing,
    this.decoration,
    this.ellipsis,
    this.shadows,
  });

  final ui.TextDirection textDirection;
  final ui.TextAlign textAlign;
  final ui.FontWeight? fontWeight;
  final ui.FontStyle? fontStyle;
  final String? fontFamily;
  final double? fontSize;
  final double? lineHeight;
  final int? maxLines;
  final double? letterSpacing;
  final double? wordSpacing;
  final String? decoration;
  final String? ellipsis;
  final List<ui.Shadow>? shadows;

  // Since all fields above are primitives, cache hashcode since ruler lookups
  // use this style as key.
  int? _cachedHashCode;

  /// Returns the font-family that should be used to style the paragraph. It may
  /// or may not be different from [fontFamily]:
  ///
  /// - Always returns "Ahem" in tests.
  /// - Provides correct defaults when [fontFamily] doesn't have a value.
  String get effectiveFontFamily {
    if (assertionsEnabled) {
      // In widget tests we use a predictable-size font "Ahem". This makes
      // widget tests predictable and less flaky.
      if (ui.debugEmulateFlutterTesterEnvironment) {
        return 'Ahem';
      }
    }
    final String? localFontFamily = fontFamily;
    if (localFontFamily == null || localFontFamily.isEmpty) {
      return FlutterViewEmbedder.defaultFontFamily;
    }
    return localFontFamily;
  }

  String? _cssFontString;

  /// Cached font string that can be used in CSS.
  ///
  /// See <https://developer.mozilla.org/en-US/docs/Web/CSS/font>.
  String get cssFontString {
    return _cssFontString ??= buildCssFontString(
      fontStyle: fontStyle,
      fontWeight: fontWeight,
      fontSize: fontSize,
      fontFamily: effectiveFontFamily,
    );
  }

  TextHeightStyle? _cachedHeightStyle;

  TextHeightStyle get textHeightStyle {
    TextHeightStyle? style = _cachedHeightStyle;
    if (style == null) {
      style = TextHeightStyle(
        fontFamily: effectiveFontFamily,
        fontSize: fontSize ?? FlutterViewEmbedder.defaultFontSize,
        height: lineHeight,
        // TODO(mdebbar): Pass the actual value when font features become supported
        //                https://github.com/flutter/flutter/issues/64595
        fontFeatures: null,
      );
      _cachedHeightStyle = style;
    }
    return style;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is ParagraphGeometricStyle
        && other.textDirection == textDirection
        && other.textAlign == textAlign
        && other.fontWeight == fontWeight
        && other.fontStyle == fontStyle
        && other.fontFamily == fontFamily
        && other.fontSize == fontSize
        && other.lineHeight == lineHeight
        && other.maxLines == maxLines
        && other.letterSpacing == letterSpacing
        && other.wordSpacing == wordSpacing
        && other.decoration == decoration
        && other.ellipsis == ellipsis;
  }

  @override
  int get hashCode => _cachedHashCode ??= ui.hashValues(
        textDirection,
        textAlign,
        fontWeight,
        fontStyle,
        fontFamily,
        fontSize,
        lineHeight,
        maxLines,
        letterSpacing,
        wordSpacing,
        decoration,
        ellipsis,
      );

  @override
  String toString() {
    if (assertionsEnabled) {
      return '$runtimeType(textDirection: $textDirection, textAlign: $textAlign,'
          ' fontWeight: $fontWeight,'
          ' fontStyle: $fontStyle,'
          ' fontFamily: $fontFamily, fontSize: $fontSize,'
          ' lineHeight: $lineHeight,'
          ' maxLines: $maxLines,'
          ' letterSpacing: $letterSpacing,'
          ' wordSpacing: $wordSpacing,'
          ' decoration: $decoration,'
          ' ellipsis: $ellipsis,'
          ')';
    } else {
      return super.toString();
    }
  }
}

/// Contains all styles that have an effect on the height of text.
///
/// This is useful as a cache key for [TextHeightRuler]. It's more efficient
/// than using the entire [ParagraphGeometricStyle] as a cache key.
class TextHeightStyle {
  TextHeightStyle({
    required this.fontFamily,
    required this.fontSize,
    required this.height,
    required this.fontFeatures,
  });

  final String fontFamily;
  final double fontSize;
  final double? height;
  final List<ui.FontFeature>? fontFeatures;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is TextHeightStyle && other.hashCode == hashCode;
  }

  @override
  late final int hashCode = ui.hashValues(
    fontFamily,
    fontSize,
    height,
    ui.hashList(fontFeatures),
  );
}

/// Provides text dimensions found on [_element]. The idea behind this class is
/// to allow the [ParagraphRuler] to mutate multiple dom elements and allow
/// consumers to lazily read the measurements.
///
/// The [ParagraphRuler] would have multiple instances of [TextDimensions] with
/// different backing elements for different types of measurements. When a
/// measurement is needed, the [ParagraphRuler] would mutate all the backing
/// elements at once. The consumer of the ruler can later read those
/// measurements.
///
/// The rationale behind this is to minimize browser reflows by batching dom
/// writes first, then performing all the reads.
class TextDimensions {
  TextDimensions(this._element);

  final html.HtmlElement _element;
  html.Rectangle<num>? _cachedBoundingClientRect;

  void _invalidateBoundsCache() {
    _cachedBoundingClientRect = null;
  }

  /// Sets text of contents to a single space character to measure empty text.
  void updateTextToSpace() {
    _invalidateBoundsCache();
    _element.text = ' ';
  }

  void applyHeightStyle(TextHeightStyle textHeightStyle) {
    final String fontFamily = textHeightStyle.fontFamily;
    final double fontSize = textHeightStyle.fontSize;
    final html.CssStyleDeclaration style = _element.style;
    style
      ..fontSize = '${fontSize.floor()}px'
      ..fontFamily = canonicalizeFontFamily(fontFamily);

    final double? height = textHeightStyle.height;
    if (height != null) {
      style.lineHeight = height.toString();
    }
    _invalidateBoundsCache();
  }

  /// Appends element and probe to hostElement that is set up for a specific
  /// TextStyle.
  void appendToHost(html.HtmlElement hostElement) {
    hostElement.append(_element);
    _invalidateBoundsCache();
  }

  html.Rectangle<num> _readAndCacheMetrics() =>
      _cachedBoundingClientRect ??= _element.getBoundingClientRect();

  /// The height of the paragraph being measured.
  double get height {
    double cachedHeight = _readAndCacheMetrics().height as double;
    if (browserEngine == BrowserEngine.firefox &&
      // In the flutter tester environment, we use a predictable-size for font
      // measurement tests.
      !ui.debugEmulateFlutterTesterEnvironment) {
      // See subpixel rounding bug :
      // https://bugzilla.mozilla.org/show_bug.cgi?id=442139
      // This causes bottom of letters such as 'y' to be cutoff and
      // incorrect rendering of double underlines.
      cachedHeight += 1.0;
    }
    return cachedHeight;
  }
}

/// Performs height measurement for the given [textHeightStyle].
///
/// The two results of this ruler's measurement are:
///
/// 1. [alphabeticBaseline].
/// 2. [height].
class TextHeightRuler {
  TextHeightRuler(this.textHeightStyle, this.rulerHost);

  final TextHeightStyle textHeightStyle;
  final RulerHost rulerHost;

  // Elements used to measure the line-height metric.
  late final html.HtmlElement _probe = _createProbe();
  late final html.HtmlElement _host = _createHost();
  final TextDimensions _dimensions = TextDimensions(html.ParagraphElement());

  /// The alphabetic baseline for this ruler's [textHeightStyle].
  late final double alphabeticBaseline = _probe.getBoundingClientRect().bottom.toDouble();

  /// The height for this ruler's [textHeightStyle].
  late final double height = _dimensions.height;

  /// Disposes of this ruler and detaches it from the DOM tree.
  void dispose() {
    _host.remove();
  }

  html.HtmlElement _createHost() {
    final html.DivElement host = html.DivElement();
    host.style
      ..visibility = 'hidden'
      ..position = 'absolute'
      ..top = '0'
      ..left = '0'
      ..display = 'flex'
      ..flexDirection = 'row'
      ..alignItems = 'baseline'
      ..margin = '0'
      ..border = '0'
      ..padding = '0';

    if (assertionsEnabled) {
      host.setAttribute('data-ruler', 'line-height');
    }

    _dimensions.applyHeightStyle(textHeightStyle);

    // Force single-line (even if wider than screen) and preserve whitespaces.
    _dimensions._element.style.whiteSpace = 'pre';

    // To measure line-height, all we need is a whitespace.
    _dimensions.updateTextToSpace();

    _dimensions.appendToHost(host);
    rulerHost.addElement(host);
    return host;
  }

  html.HtmlElement _createProbe() {
    final html.HtmlElement probe = html.DivElement();
    _host.append(probe);
    return probe;
  }
}
