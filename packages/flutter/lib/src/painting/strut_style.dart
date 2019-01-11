// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'basic_types.dart';

/// [StrutStyle] defines the properties of the strut to use on the entire paragraph.
///
/// To define a strut, a non-negative value must be defined for [fontSize] and at
/// least one of [lineHeight] and [leading]. Failure to define the minimum properties
/// will result in a zero strut and it will have no effect on the layout. Negative and
/// null values are treated the same. Most use cases will prefer [fontSize] and
/// [lineHeight] to be defined.
///
/// Strut is a feature that allows minimum line heights to be set. The effect is as
/// if a zero width space is laid out at the beginning of each line in the
/// paragraph. This imaginary space has the dimensions if it were laid out according
/// to the properties defined in this class.
///
/// No lines will be shorter than the strut. The ascent and descent strut
/// metrics are calculated, and any font that has a shorter ascent or descent will
/// take the ascent and descent of the strut. Larger ascent or decents will lay out
/// as normal.
///
/// The vertical components of strut are as follows:
/// 
///  * `leading * fontSize / 2` or half the font leading if `leading` is undefined (half leading)
///  * `ascent * lineHeight`
///  * `descent * lineHeight`
///  * `leading * fontSize / 2` or half the font leading if `leading` is undefined (half leading)
/// 
/// The values for `ascent` and `descent` are provided by the [fontFamily]. If no
/// [fontFamily] is provided, then the platform's default family will be used.
///
/// Each line's spacing above the baseline will be at least as tall as the half
/// leading plus ascent. Each line's spacing below the baseline will be at least as
/// tall as the half leading plus descent.
/// 
/// ### Fields
/// 
/// If any properties (except [forceStrutHeight]) are omitted or null, it will inherit the
/// values of the default text style.
///
///  * [fontFamily] the name of the font to use when calcualting the strut (e.g., Roboto).
///    No glyphs from the font will be drawn and the font will be used purely for metrics.
/// 
///  * [fontSize] the size of the ascent plus descent in logical pixels. This is also
///    used as the basis of the custom leading caluclation. This value cannot
///    be negative.
///
///  * [lineHeight] the height of the line as a ratio of [fontSize]. This property does
///    not affect the leading height, which is controlled separately through [leading].
///    This value cannot be negative.
/// 
///  * [leading] the custom leading to apply to the strut as a ratio of [fontSize].
///    Leading is additional spacing between lines. Half of the leading is added
///    to the top and the other half to the bottom of the line height. This value cannot
///    be negative.
///
///  * [fontWeight] the typeface thickness to use when calculating the strut (e.g., bold).
///
///  * [fontStyle] the typeface variant to use when calculating the strut (e.g., italic).
/// 
///  * [forceStrutHeight] when true, all lines will be laid out with the height of the
///    strut. All line and run-specific metrics will be ignored/overrided and only strut
///    metrics will be used instead. This property guarantees uniform line spacing, however
///    text overlap will become possible. This property should be enabled with caution as
///    it bypasses a large portion of the vertical layout system. The default value is false.
/// 
/// ### Examples
/// 
/// {@tool sample}
/// In this simple case, the text will be rendered at font size 10, however, the vertical
/// line height will be the strut height (Roboto in font size 30 * 1.5) as the text
/// itself is smaller than the strut.
/// 
/// ```dart
/// Text(
///   "Hello, world!\nSecond line!",
///   strutStyle: StrutStyle(
///     fontFamily: "Roboto",
///     fontSize: 30,
///     lineHeight: 1.5,
///   ),
///   style: TextStyle(
///     fontSize: 10,
///     fontFamily: "Raleway"
///   ),
/// ),
/// ```
/// {@end-tool}
/// 
/// {@tool sample}
/// Here, strut is used to absorb the additional line height in the second line.
/// The strut [lineHeight] was defined as 1.5, which caused all lines to be laid out
/// taller than without strut. This extra space was able to accomodate the larger
/// font size `Second line!` without causing the line height to change for the second
/// line only.
/// 
/// ```dart
/// Text.rich(
///   TextSpan(
///     text: "First line!\n",
///     style: TextStyle(
///       fontSize: 14,
///       fontFamily: "Roboto"
///     ),
///     children: <TextSpan>[
///       TextSpan(
///         text: "Second line!\n",
///         style: TextStyle(
///           fontSize: 16,
///           fontFamily: "Roboto"
///         ),
///       ),
///       TextSpan(
///         text: "Third line!\n",
///         style: TextStyle(
///           fontSize: 14,
///           fontFamily: "Roboto"
///         ),
///       ),
///     ],
///   ),
///   strutStyle: StrutStyle(
///     fontFamily: "Roboto",
///     fontSize: 14,
///     lineHeight: 1.5,
///   ),
/// ),
/// ```
/// {@end-tool}
/// 
/// {@tool sample}
/// Here, strut is used to enable strange and overlapping text to achieve unique
/// effects. The `M`s in lines 2 and 3 are able to extend above their lines and
/// fill empty space in lines above. The [forceStrutHeight] is enabled and functions
/// as a 'grid' for the glyphs to draw on.
/// 
/// ![The result of the example below.](https://flutter.github.io/assets-for-api-docs/assets/painting/strut_force_example.png)
/// 
/// ```dart
/// Text.rich(
///   TextSpan(
///     text: "---------         ---------\n",
///     style: TextStyle(
///       fontSize: 14,
///       fontFamily: "Roboto"
///     ),
///     children: <TextSpan>[
///       TextSpan(
///         text: "^^^M^^^\n",
///         style: TextStyle(
///           fontSize: 30,
///           fontFamily: "Roboto"
///         ),
///       ),
///       TextSpan(
///         text: "M------M\n",
///         style: TextStyle(
///           fontSize: 30,
///           fontFamily: "Roboto"
///         ),
///       ),
///     ],
///   ),
///   strutStyle: StrutStyle(
///     fontFamily: "Roboto",
///     fontSize: 14,
///     lineHeight: 1,
///     forceStrutHeight: true,
///   ),
/// ),
/// ```
/// {@end-tool}
/// 
@immutable
class StrutStyle {
  /// Creates a strut style.
  ///
  /// The `package` argument must be non-null if the font family is defined in a
  /// package. It is combined with the `fontFamily` argument to set the
  /// [fontFamily] property.
  const StrutStyle({
    String fontFamily,
    this.fontSize,
    this.lineHeight,
    this.leading,
    this.fontWeight,
    this.fontStyle,
    this.forceStrutHeight,
    String package,
  }) : fontFamily = package == null ? fontFamily : 'packages/$package/$fontFamily',
       assert(lineHeight == null || lineHeight > 0),
       assert(leading == null || leading > 0),
       assert(fontSize == null || fontSize > 0);

  /// The name of the font to use when calcualting the strut (e.g., Roboto). If the
  /// font is defined in a package, this will be prefixed with
  /// 'packages/package_name/' (e.g. 'packages/cool_fonts/Roboto'). The
  /// prefixing is done by the constructor when the `package` argument is
  /// provided.
  ///
  /// When no fontFamily is provided, then the default platform font will
  /// be used.
  final String fontFamily;

  /// The minimum size of glyphs (in logical pixels) to use when painting the text.
  ///
  /// During painting, the [fontSize] is multiplied by the current
  /// `textScaleFactor` to let users make it easier to read text by increasing
  /// its size.
  ///
  /// [getParagraphStyle] will default to 0 logical pixels if the font size
  /// isn't specified here.
  final double fontSize;

  // The default font size if none is specified.
  static const double _defaultFontSize = 0.0;

  /// The height of the line as a ratio of fontSize. This property does
  /// not affect the leading height, which is controlled separately through
  /// [leading].
  final double lineHeight;

  /// The typeface thickness to use when calculating the strut (e.g., bold).
  final FontWeight fontWeight;

  /// The typeface variant to use when calculating the strut (e.g., italics).
  final FontStyle fontStyle;

  /// The custom strut leading as a ratio of [fontSize].
  ///
  /// If this is null or negative, the font's leading will be used.
  final double leading;

  /// Whether the strut height should be forced.
  ///
  /// When true, all lines will be laid out with the height of the
  /// strut. All line and run-specific metrics will be ignored/overrided and only strut
  /// metrics will be used instead. This property guarantees uniform line spacing, however
  /// text overlap will become possible. This property should be enabled with caution as
  /// it bypasses a large portion of the vertical layout system.
  final bool forceStrutHeight;

  /// Describe the difference between this style and another, in terms of how
  /// much damage it will make to the rendering.
  ///
  /// See also:
  ///
  ///  * [TextSpan.compareTo], which does the same thing for entire [TextSpan]s.
  RenderComparison compareTo(StrutStyle other) {
    if (identical(this, other))
      return RenderComparison.identical;
    if (fontFamily != other.fontFamily ||
        fontSize != other.fontSize ||
        fontWeight != other.fontWeight ||
        fontStyle != other.fontStyle ||
        lineHeight != other.lineHeight ||
        leading != other.leading ||
        forceStrutHeight != other.forceStrutHeight)
      return RenderComparison.layout;
    return RenderComparison.identical;
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other.runtimeType != runtimeType)
      return false;
    final StrutStyle typedOther = other;
    return fontFamily == typedOther.fontFamily &&
           fontSize == typedOther.fontSize &&
           fontWeight == typedOther.fontWeight &&
           fontStyle == typedOther.fontStyle &&
           lineHeight == typedOther.lineHeight &&
           leading == typedOther.leading &&
           forceStrutHeight == typedOther.forceStrutHeight;
  }

  @override
  int get hashCode {
    return hashValues(
      fontFamily,
      fontSize,
      fontWeight,
      fontStyle,
      lineHeight,
      leading,
      forceStrutHeight,
    );
  }
}
