// Copyright 2020 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

/// Represents a Google Fonts API variant in Flutter-specific types.
class GoogleFontsVariant {
  const GoogleFontsVariant({
    required this.fontWeight,
    required this.fontStyle,
  });

  /// Creates a [GoogleFontsVariant] from a Google Fonts API specific
  /// filename part.
  ///
  /// A filename part is the part of the filename that does not include the
  /// font family. For example, for the filename "Lato-Regular.ttf", the
  /// filename part is "Regular".
  ///
  /// The following table shows how these filename parts convert:
  /// 'Regular' -> weight: 400, style: normal
  /// 'Italic' -> weight: 400, style: italic
  /// 'Bold' -> weight: 700, style: normal
  /// 'BoldItalic' -> weight: 700, style: italic
  ///
  /// See [GoogleFontsVariant.toApiFilenamePart] for the inverse function.
  GoogleFontsVariant.fromApiFilenamePart(String filenamePart)
      : fontWeight = _extractFontWeightFromApiFilenamePart(filenamePart),
        fontStyle = _extractFontStyleFromApiFilenamePart(filenamePart);

  /// Creates a [GoogleFontsVariant] from a Google Fonts API specific
  /// variant name.
  ///
  /// The following table shows how these variant strings convert:
  /// 'regular' -> weight: 400, style: normal
  /// 'italic' -> weight: 400, style: italic
  /// '700' -> weight: 700, style: normal
  /// '700italic' -> weight: 700, style: italic
  ///
  /// See [GoogleFontsVariant.toString] for the inverse function.
  GoogleFontsVariant.fromString(String variantString)
      : fontWeight = FontWeight.values[variantString == _regular ||
                variantString == _italic
            ? 3
            : (int.parse(variantString.replaceAll(_italic, '')) ~/ 100) - 1],
        fontStyle = variantString.contains(_italic)
            ? FontStyle.italic
            : FontStyle.normal;

  final FontWeight fontWeight;
  final FontStyle fontStyle;

  static FontWeight _extractFontWeightFromApiFilenamePart(String filenamePart) {
    if (filenamePart.contains('Thin')) return FontWeight.w100;

    // ExtraLight must be checked before Light because of the substring match.
    if (filenamePart.contains('ExtraLight')) return FontWeight.w200;
    if (filenamePart.contains('Light')) return FontWeight.w300;

    if (filenamePart.contains('Medium')) return FontWeight.w500;

    // SemiBold and ExtraBold must be checked before Bold because of the
    // substring match.
    if (filenamePart.contains('SemiBold')) return FontWeight.w600;
    if (filenamePart.contains('ExtraBold')) return FontWeight.w800;
    if (filenamePart.contains('Bold')) return FontWeight.w700;

    if (filenamePart.contains('Black')) return FontWeight.w900;
    return FontWeight.w400;
  }

  static FontStyle _extractFontStyleFromApiFilenamePart(String filenamePart) {
    if (filenamePart.contains('Italic')) return FontStyle.italic;
    return FontStyle.normal;
  }

  /// Converts this [GoogleFontsVariant] to a Google Fonts API specific filename
  /// part.
  ///
  /// A Filename part is the part of the filename that does not include the
  /// font family. For example: for the filename "Lato-Regular.ttf", the
  /// filename part is "Regular".
  ///
  /// The following table shows how these [GoogleFontsVariant]s convert:
  /// weight: 400, style: normal -> 'Regular'
  /// weight: 400, style: italic -> 'Italic'
  /// weight: 700, style: normal -> 'Bold'
  /// weight: 700, style: italic -> 'BoldItalic'
  ///
  /// See [GoogleFontsVariant.fromApiFilenamePart] for the inverse function.
  String toApiFilenamePart() {
    final weightPrefix = _fontWeightToFilenameWeightParts[fontWeight] ??
        _fontWeightToFilenameWeightParts[FontWeight.w400]!;
    final italicSuffix = fontStyle == FontStyle.italic ? 'Italic' : '';
    if (weightPrefix == 'Regular') {
      return italicSuffix == '' ? weightPrefix : italicSuffix;
    }
    return '$weightPrefix$italicSuffix';
  }

  /// Converts this [GoogleFontsVariant] to a Google Fonts API specific variant
  /// name string.
  ///
  /// The following table shows how these variant strings convert:
  /// weight: 400, style: normal -> 'regular'
  /// weight: 400, style: italic -> 'italic'
  /// weight: 700, style: normal -> '700'
  /// weight: 700, style: italic -> '700italic'
  ///
  /// See [GoogleFontsVariant.toString] for the inverse function.
  @override
  String toString() {
    final fontWeightString =
        fontWeight.index == 3 ? '' : (fontWeight.index + 1) * 100;
    final fontStyleString = fontStyle
        .toString()
        .replaceAll('FontStyle.', '')
        .replaceFirst(_normal, fontWeight.index == 3 ? _regular : '');
    return '$fontWeightString$fontStyleString';
  }

  @override
  int get hashCode => hashValues(fontWeight, fontStyle);

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other.fontWeight == fontWeight && other.fontStyle == fontStyle;
  }
}

/// What the Flutter API calls a font style of normal/regular.
const _normal = 'normal';

/// What the Google Fonts API calls a font style of normal/regular.
const _regular = 'regular';

/// Both the Flutter API and the Google API have the same name for a font style
/// of italic.
const _italic = 'italic';

/// Mapping from font weight types to the 'weight' part of the Google Fonts API
/// specific filename.
const _fontWeightToFilenameWeightParts = {
  FontWeight.w100: 'Thin',
  FontWeight.w200: 'ExtraLight',
  FontWeight.w300: 'Light',
  FontWeight.w400: 'Regular',
  FontWeight.w500: 'Medium',
  FontWeight.w600: 'SemiBold',
  FontWeight.w700: 'Bold',
  FontWeight.w800: 'ExtraBold',
  FontWeight.w900: 'Black',
};
