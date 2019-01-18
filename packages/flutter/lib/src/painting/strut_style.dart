// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'basic_types.dart';

/// [StrutStyle] defines the strut, which defines the minimum height a line can be
/// relative to the baseline. Strut applies to all lines in the pararaph.
///
/// Strut is a feature that allows minimum line heights to be set. The effect is as
/// if a zero width space is laid out at the beginning of each line in the
/// paragraph. This imaginary space is "shaped" according the properties defined
/// in this class.
///
/// No lines may be shorter than the strut. The ascent and descent of the strut
/// are calculated, and any laid out text that has a shorter ascent or descent than
/// the strut's ascent or descent will take the ascent and descent of the strut.
/// Text with ascents or descents larger than the strut's ascent or descent will lay
/// out as normal and extend past the strut.
///
/// Strut is defined independently from any text content or [TextStyle]s.
///
/// The vertical components of strut are as follows:
/// 
///  * `leading * fontSize / 2` or half the font leading if `leading` is undefined (half leading)
///  * `ascent * lineHeight`
///  * `descent * lineHeight`
///  * `leading * fontSize / 2` or half the font leading if `leading` is undefined (half leading)
/// 
/// The `ascent + descent` is equivalent to the [fontSize].
/// The values for `ascent` and `descent` are provided by the font named by
/// [fontFamily]. If no [fontFamily] or [fontFamilyFallback] is provided, then the
/// platform's default family will be used.
///
/// Each line's spacing above the baseline will be at least as tall as the half
/// leading plus ascent. Each line's spacing below the baseline will be at least as
/// tall as the half leading plus descent.
/// 
/// ### Fields and their default values.

// ///////////////////////////////////////////////////////////////////////////
// The defaults are noted here for convenience. The actual place where they //
// are defined is in the engine paragraph_style.h of LibTxt. The values here//
// should be updated should it change in the engine. The engine specifies   //
// the defaults in order to reduce the amount of data we pass to native as  //
// strut will usually be unspecified.                                       //
// ///////////////////////////////////////////////////////////////////////////

///
/// Omitted or null properties will take the default values specified below:
///
///  * [fontFamily] the name of the font to use when calcualting the strut (e.g., Roboto).
///    No glyphs from the font will be drawn and the font will be used purely for metrics.
///
///  * [fontFamilyFallback] an ordered list of font family names that will be searched for when
///    the font in [fontFamily] cannot be found. When all specified font families have been
///    exhausted an no match was found, the default platform font will be used.
///
///  * [fontSize] the size of the ascent plus descent in logical pixels. This is also
///    used as the basis of the custom leading caluclation. This value cannot
///    be negative.
///    Default is `14` logical pixels.
///
///  * [lineHeight] the multiple of [fontSize] to multiply the ascent and descent by.
///    The [lineHeight] will impact the spacing above and below the baseline differently
///    depending on the ratios between the font's ascent and descent. This property is
///    separate from the leading multiplier, which is controlled through [leading].
///    Default is `1.0`.
///
///  * [leading] the custom leading to apply to the strut as a multiple of [fontSize].
///    Leading is additional spacing between lines. Half of the leading is added
///    to the top and the other half to the bottom of the line height. This differs
///    from [lineHeight] since the spacing is equally distributed above and below the
///    baseline.
///    Default is `null`, which will use the font-specified leading.
///
///  * [fontWeight] the typeface thickness to use when calculating the strut (e.g., bold).
///    Default is `w400`.
///
///  * [fontStyle] the typeface variant to use when calculating the strut (e.g., italic).
///    Default is `normal`.
///
///  * [forceStrutHeight] when true, all lines will be laid out with the height of the
///    strut. All line and run-specific metrics will be ignored/overrided and only strut
///    metrics will be used instead. This property guarantees uniform line spacing, however
///    text in adjacent lines may overlap. This property should be enabled with caution as
///    it bypasses a large portion of the vertical layout system.
///    The default value is false.
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
///   'Hello, world!\nSecond line!',
///   style: TextStyle(
///     fontSize: 10,
///     fontFamily: 'Raleway',
///   ),
///   strutStyle: StrutStyle(
///     fontFamily: 'Roboto',
///     fontSize: 30,
///     lineHeight: 1.5,
///   ),
/// ),
/// ```
/// {@end-tool}
///
/// {@tool sample}
/// Here, strut is used to absorb the additional line height in the second line.
/// The strut [lineHeight] was defined as 1.5 (the default font size is 14), which
/// caused all lines to be laid out taller than without strut. This extra space was
/// able to accomodate the larger font size of `Second line!` without causing the line
/// height to change for the second line only. All lines in this example are thus the
/// same height.
///
/// ```dart
/// Text.rich(
///   TextSpan(
///     text: 'First line!\n',
///     style: TextStyle(
///       fontSize: 14,
///       fontFamily: 'Roboto'
///     ),
///     children: <TextSpan>[
///       TextSpan(
///         text: 'Second line!\n',
///         style: TextStyle(
///           fontSize: 16,
///           fontFamily: 'Roboto',
///         ),
///       ),
///       TextSpan(
///         text: 'Third line!\n',
///         style: TextStyle(
///           fontSize: 14,
///           fontFamily: 'Roboto',
///         ),
///       ),
///     ],
///   ),
///   strutStyle: StrutStyle(
///     fontFamily: 'Roboto',
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
///     text: '---------         ---------\n',
///     style: TextStyle(
///       fontSize: 14,
///       fontFamily: 'Roboto',
///     ),
///     children: <TextSpan>[
///       TextSpan(
///         text: '^^^M^^^\n',
///         style: TextStyle(
///           fontSize: 30,
///           fontFamily: 'Roboto',
///         ),
///       ),
///       TextSpan(
///         text: 'M------M\n',
///         style: TextStyle(
///           fontSize: 30,
///           fontFamily: 'Roboto',
///         ),
///       ),
///     ],
///   ),
///   strutStyle: StrutStyle(
///     fontFamily: 'Roboto',
///     fontSize: 14,
///     lineHeight: 1,
///     forceStrutHeight: true,
///   ),
/// ),
/// ```
/// {@end-tool}
///
@immutable
class StrutStyle extends Diagnosticable {
  /// Creates a strut style.
  ///
  /// The `package` argument must be non-null if the font family is defined in a
  /// package. It is combined with the `fontFamily` argument to set the
  /// [fontFamily] property.
  const StrutStyle({
    String fontFamily,
    List<String> fontFamilyFallback,
    this.fontSize,
    this.lineHeight,
    this.leading,
    this.fontWeight,
    this.fontStyle,
    this.forceStrutHeight,
    this.debugLabel,
    String package,
  }) : fontFamily = package == null ? fontFamily : 'packages/$package/$fontFamily',
       _fontFamilyFallback = fontFamilyFallback,
       _package = package,
       assert(fontSize == null || fontSize > 0)
       assert(leading == null || leading >= 0);

  /// The name of the font to use when calcualting the strut (e.g., Roboto). If the
  /// font is defined in a package, this will be prefixed with
  /// 'packages/package_name/' (e.g. 'packages/cool_fonts/Roboto'). The
  /// prefixing is done by the constructor when the `package` argument is
  /// provided.
  ///
  /// The value provided in [fontFamily] will act as the preferred/first font
  /// family that will be searched for, followed in order by the font families
  /// in [fontFamilyFallback]. If all font families are exhausted and no match
  /// was found, the default platform font family will be used instead. Unlike
  /// [TextStyle.fontFamilyFallback], the font does not need to contain the
  /// desired glyphs to match.
  final String fontFamily;

  /// The ordered list of font families to fall back on when a higher priority
  /// font family cannot be found.
  ///
  /// The value provided in [fontFamily] will act as the preferred/first font
  /// family that will be searched for, followed in order by the font families
  /// in [fontFamilyFallback]. If all font families are exhausted and no match
  /// was found, the default platform font family will be used instead. Unlike
  /// [TextStyle.fontFamilyFallback], the font does not need to contain the
  /// desired glyphs to match.
  ///
  /// When [fontFamily] is null or not provided, the first value in [fontFamilyFallback]
  /// acts as the preferred/first font family. When neither is provided, then
  /// the default platform font will be used. Providing and empty list or null
  /// for this property is the same as omitting it.
  ///
  /// If the font is defined in a package, each font family in the list will be
  /// prefixed with 'packages/package_name/' (e.g. 'packages/cool_fonts/Roboto').
  /// The package name should be provided by the `package` argument in the
  /// constructor.
  List<String> get fontFamilyFallback => _package != null && _fontFamilyFallback != null ? _fontFamilyFallback.map((String str) => 'packages/$_package/$str').toList() : _fontFamilyFallback;
  final List<String> _fontFamilyFallback;

  // This is stored in order to prefix the fontFamilies in _fontFamilyFallback
  // in the [fontFamilyFallback] getter.
  final String _package;

  /// The minimum size of glyphs (in logical pixels) to use when painting the text.
  ///
  /// During painting, the [fontSize] is multiplied by the current
  /// `textScaleFactor` to let users make it easier to read text by increasing
  /// its size. [fontSize] must be a positive value.
  ///
  /// The default fontSize is `14` logical pixels.
  final double fontSize;

  /// The height of the ascent plus descent as a multiple of fontSize. This property does
  /// not affect the leading height (additional spacing added to the line), which is
  /// controlled separately through [leading].
  ///
  /// The default lineHeight is `1.0`.
  final double lineHeight;

  /// The typeface thickness to use when calculating the strut (e.g., bold).
  ///
  /// The default fontWeight is `w400`.
  final FontWeight fontWeight;

  /// The typeface variant to use when calculating the strut (e.g., italics).
  ///
  /// The default fontStyle is `normal`.
  final FontStyle fontStyle;

  /// The custom strut leading as a multiple of [fontSize]. Leading is additional
  /// vertical spacing in addition to the ascent and descent.
  ///
  /// This must be positive, zero, or null. If this is null or omitted, the font's
  /// leading will be used. Positive values and zero specifies a custom leading,
  /// half of which will be applied to the top of the line box and the other half
  /// to the bottom of the text.
  ///
  /// The default leading is `null`, which will use the font-specified leading.
  final double leading;

  /// Whether the strut height should be forced.
  ///
  /// When true, all lines will be laid out with the height of the
  /// strut. All line and run-specific metrics will be ignored/overrided and only strut
  /// metrics will be used instead. This will guarantee uniform line spacing, however
  /// text overlap will become possible.
  ///
  /// This property should be enabled with caution as
  /// it bypasses a large portion of the vertical layout system.
  ///
  /// The default is `false`.
  final bool forceStrutHeight;

  /// A human-readable description of this strut style.
  ///
  /// This property is maintained only in debug builds.
  ///
  /// This property is not considered when comparing strut styles using `==` or
  /// [compareTo], and it does not affect [hashCode].
  final String debugLabel;

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
        forceStrutHeight != other.forceStrutHeight ||
        !listEquals(fontFamilyFallback, other.fontFamilyFallback))
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

  /// Adds all properties prefixing property names with the optional `prefix`.
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties, { String prefix = '' }) {
    super.debugFillProperties(properties);
    if (debugLabel != null)
      properties.add(MessageProperty('${prefix}debugLabel', debugLabel));
    final List<DiagnosticsNode> styles = <DiagnosticsNode>[];
    styles.add(StringProperty('${prefix}family', fontFamily, defaultValue: null, quoted: false));
    styles.add(IterableProperty<String>('${prefix}familyFallback', fontFamilyFallback, defaultValue: null));
    styles.add(DoubleProperty('${prefix}size', fontSize, defaultValue: null));
    String weightDescription;
    if (fontWeight != null) {
      switch (fontWeight) {
        case FontWeight.w100:
          weightDescription = '100';
          break;
        case FontWeight.w200:
          weightDescription = '200';
          break;
        case FontWeight.w300:
          weightDescription = '300';
          break;
        case FontWeight.w400:
          weightDescription = '400';
          break;
        case FontWeight.w500:
          weightDescription = '500';
          break;
        case FontWeight.w600:
          weightDescription = '600';
          break;
        case FontWeight.w700:
          weightDescription = '700';
          break;
        case FontWeight.w800:
          weightDescription = '800';
          break;
        case FontWeight.w900:
          weightDescription = '900';
          break;
      }
    }
    // TODO(jacobr): switch this to use enumProperty which will either cause the
    // weight description to change to w600 from 600 or require existing
    // enumProperty to handle this special case.
    styles.add(DiagnosticsProperty<FontWeight>(
      '${prefix}weight',
      fontWeight,
      description: weightDescription,
      defaultValue: null,
    ));
    styles.add(EnumProperty<FontStyle>('${prefix}style', fontStyle, defaultValue: null));
    styles.add(DoubleProperty('${prefix}height', lineHeight, unit: 'x', defaultValue: null));
    styles.add(FlagProperty('${prefix}forceStrutHeight', value: forceStrutHeight, defaultValue: null));

    final bool styleSpecified = styles.any((DiagnosticsNode n) => !n.isFiltered(DiagnosticLevel.info));
    styles.forEach(properties.add);

    if (!styleSpecified)
      properties.add(FlagProperty('forceStrutHeight', value: forceStrutHeight, ifTrue: '$prefix<strut height forced>', ifFalse: '$prefix<strut height normal>'));
  }
}
