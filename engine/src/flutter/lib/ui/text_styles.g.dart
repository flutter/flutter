// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// GENERATED CODE - DO NOT EDIT BY HAND.
// ignore_for_file: unused_element

part of dart.ui;

final class _PackedTextStyle extends Struct {
  @Double()
  external double decorationThickness;

  @Double()
  external double fontSize;

  @Double()
  external double letterSpacing;

  @Double()
  external double wordSpacing;

  @Double()
  external double height;

  @Uint32()
  external int color;

  @Int32()
  external int decoration;

  @Uint32()
  external int decorationColor;

  @Int32()
  external int fontWeight;

  @Uint32()
  external int presentMask;

  @Uint8()
  external int decorationStyle;

  @Uint8()
  external int fontStyle;

  @Uint8()
  external int textBaseline;

  @Uint8()
  external int leadingDistribution;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is _PackedTextStyle &&
        decorationThickness == other.decorationThickness &&
        fontSize == other.fontSize &&
        letterSpacing == other.letterSpacing &&
        wordSpacing == other.wordSpacing &&
        height == other.height &&
        color == other.color &&
        decoration == other.decoration &&
        decorationColor == other.decorationColor &&
        fontWeight == other.fontWeight &&
        presentMask == other.presentMask &&
        decorationStyle == other.decorationStyle &&
        fontStyle == other.fontStyle &&
        textBaseline == other.textBaseline &&
        leadingDistribution == other.leadingDistribution;
  }

  @override
  int get hashCode => Object.hash(
    decorationThickness,
    fontSize,
    letterSpacing,
    wordSpacing,
    height,
    color,
    decoration,
    decorationColor,
    fontWeight,
    presentMask,
    decorationStyle,
    fontStyle,
    textBaseline,
    leadingDistribution,
  );
}

extension type const _EncodedTextStyle(List<Object?> _data) implements Object {
  _PackedTextStyle get packed => _data[0]! as _PackedTextStyle;
}

_EncodedTextStyle _encodeTextStyleFfi({
  required _NativeColor? color,
  required _NativeTextDecoration? decoration,
  required _NativeColor? decorationColor,
  required _NativeEnum<TextDecorationStyle>? decorationStyle,
  required _NativeDouble? decorationThickness,
  required _NativeFontWeight? fontWeight,
  required _NativeEnum<FontStyle>? fontStyle,
  required _NativeEnum<TextBaseline>? textBaseline,
  required _NativeDouble? fontSize,
  required _NativeDouble? letterSpacing,
  required _NativeDouble? wordSpacing,
  required _NativeDouble? height,
  required _NativeEnum<TextLeadingDistribution>? leadingDistribution,
  required _NativeHandle<String>? fontFamily,
  required _NativeHandle<List<String>>? fontFamilyFallback,
  required _NativeLocale? locale,
  required _NativePaint? background,
  required _NativePaint? foreground,
  required _NativeShadows? shadows,
  required _NativeFontFeatures? fontFeatures,
  required _NativeFontVariations? fontVariations,
}) {
  final bytes = Uint8List(sizeOf<_PackedTextStyle>());
  final _PackedTextStyle packed = Struct.create<_PackedTextStyle>(bytes);
  var mask = 0;
  if (color != null) {
    mask |= 1 << 0;
  } else {
    color = const .new(Color(0xFFFFFFFF));
  }
  packed.color = color.encode();
  if (decoration != null) {
    mask |= 1 << 1;
  } else {
    decoration = const .new(.none);
  }
  packed.decoration = decoration.encode();
  if (decorationColor != null) {
    mask |= 1 << 2;
  } else {
    decorationColor = const .new(Color(0x00000000));
  }
  packed.decorationColor = decorationColor.encode();
  if (decorationStyle != null) {
    mask |= 1 << 3;
  } else {
    decorationStyle = const .new(.solid);
  }
  packed.decorationStyle = decorationStyle.value.index;
  if (decorationThickness != null) {
    mask |= 1 << 4;
  } else {
    decorationThickness = const .new(1.0);
  }
  packed.decorationThickness = decorationThickness.value;
  if (fontWeight != null) {
    mask |= 1 << 5;
  } else {
    fontWeight = const .new(.normal);
  }
  packed.fontWeight = fontWeight.encode();
  if (fontStyle != null) {
    mask |= 1 << 6;
  } else {
    fontStyle = const .new(.normal);
  }
  packed.fontStyle = fontStyle.value.index;
  if (textBaseline != null) {
    mask |= 1 << 7;
  } else {
    textBaseline = const .new(.alphabetic);
  }
  packed.textBaseline = textBaseline.value.index;
  if (fontSize != null) {
    mask |= 1 << 8;
  } else {
    fontSize = const .new(14.0);
  }
  packed.fontSize = fontSize.value;
  if (letterSpacing != null) {
    mask |= 1 << 9;
  } else {
    letterSpacing = const .new(0.0);
  }
  packed.letterSpacing = letterSpacing.value;
  if (wordSpacing != null) {
    mask |= 1 << 10;
  } else {
    wordSpacing = const .new(0.0);
  }
  packed.wordSpacing = wordSpacing.value;
  if (height != null) {
    mask |= 1 << 11;
  } else {
    height = const .new(kTextHeightNone);
  }
  packed.height = height.value;
  if (leadingDistribution != null) {
    mask |= 1 << 12;
  } else {
    leadingDistribution = const .new(.proportional);
  }
  packed.leadingDistribution = leadingDistribution.value.index;
  if (fontFamily != null) {
    mask |= 1 << 13;
  }
  if (fontFamilyFallback != null) {
    mask |= 1 << 14;
  }
  if (locale != null) {
    mask |= 1 << 15;
  }
  if (background != null) {
    mask |= 1 << 16;
  }
  if (foreground != null) {
    mask |= 1 << 17;
  }
  if (shadows != null) {
    mask |= 1 << 18;
  }
  if (fontFeatures != null) {
    mask |= 1 << 19;
  }
  if (fontVariations != null) {
    mask |= 1 << 20;
  }
  packed.presentMask = mask;
  return _EncodedTextStyle(<Object?>[
    packed,
    bytes,
    fontFamily,
    fontFamilyFallback,
    locale?.encode(),
    background?.encode(),
    foreground?.encode(),
    shadows?.encode(),
    fontFeatures?.encode(),
    fontVariations?.encode(),
  ]);
}

@pragma('vm:prefer-inline')
String _textStyleToString(TextStyle s) {
  final _PackedTextStyle packed = s._encoded.packed;
  final int mask = packed.presentMask;
  return 'TextStyle('
      'color: ${(mask & (1 << 0)) != 0 ? _NativeColor.decode(packed.color) : "unspecified"}, '
      'decoration: ${(mask & (1 << 1)) != 0 ? _NativeTextDecoration.decode(packed.decoration) : "unspecified"}, '
      'decorationColor: ${(mask & (1 << 2)) != 0 ? _NativeColor.decode(packed.decorationColor) : "unspecified"}, '
      'decorationStyle: ${(mask & (1 << 3)) != 0 ? TextDecorationStyle.values[packed.decorationStyle] : "unspecified"}, '
      'decorationThickness: ${(mask & (1 << 4)) != 0 ? packed.decorationThickness : "unspecified"}, '
      'fontWeight: ${(mask & (1 << 5)) != 0 ? _NativeFontWeight.decode(packed.fontWeight) : "unspecified"}, '
      'fontStyle: ${(mask & (1 << 6)) != 0 ? FontStyle.values[packed.fontStyle] : "unspecified"}, '
      'textBaseline: ${(mask & (1 << 7)) != 0 ? TextBaseline.values[packed.textBaseline] : "unspecified"}, '
      'fontSize: ${(mask & (1 << 8)) != 0 ? packed.fontSize : "unspecified"}, '
      'letterSpacing: ${(mask & (1 << 9)) != 0 ? packed.letterSpacing : "unspecified"}, '
      'wordSpacing: ${(mask & (1 << 10)) != 0 ? packed.wordSpacing : "unspecified"}, '
      'height: ${(mask & (1 << 11)) != 0 ? packed.height : "unspecified"}, '
      'leadingDistribution: ${(mask & (1 << 12)) != 0 ? TextLeadingDistribution.values[packed.leadingDistribution] : "unspecified"}, '
      'fontFamily: ${(mask & (1 << 13)) != 0 ? s._fontFamily : "unspecified"}, '
      'fontFamilyFallback: ${(mask & (1 << 14)) != 0 ? s._fontFamilyFallback : "unspecified"}, '
      'locale: ${(mask & (1 << 15)) != 0 ? s._locale : "unspecified"}, '
      'background: ${(mask & (1 << 16)) != 0 ? s._background : "unspecified"}, '
      'foreground: ${(mask & (1 << 17)) != 0 ? s._foreground : "unspecified"}, '
      'shadows: ${(mask & (1 << 18)) != 0 ? s._shadows : "unspecified"}, '
      'fontFeatures: ${(mask & (1 << 19)) != 0 ? s._fontFeatures : "unspecified"}, '
      'fontVariations: ${(mask & (1 << 20)) != 0 ? s._fontVariations : "unspecified"}'
      ')';
}

final class _PackedParagraphStyle extends Struct {
  @Double()
  external double fontSize;

  @Double()
  external double height;

  @Int32()
  external int maxLines;

  @Int32()
  external int textHeightBehavior;

  @Int32()
  external int fontWeight;

  @Uint16()
  external int presentMask;

  @Uint8()
  external int textAlign;

  @Uint8()
  external int textDirection;

  @Uint8()
  external int fontStyle;

  @Uint8()
  external int hyphens;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is _PackedParagraphStyle &&
        fontSize == other.fontSize &&
        height == other.height &&
        maxLines == other.maxLines &&
        textHeightBehavior == other.textHeightBehavior &&
        fontWeight == other.fontWeight &&
        presentMask == other.presentMask &&
        textAlign == other.textAlign &&
        textDirection == other.textDirection &&
        fontStyle == other.fontStyle &&
        hyphens == other.hyphens;
  }

  @override
  int get hashCode => Object.hash(
    fontSize,
    height,
    maxLines,
    textHeightBehavior,
    fontWeight,
    presentMask,
    textAlign,
    textDirection,
    fontStyle,
    hyphens,
  );
}

extension type const _EncodedParagraphStyle(List<Object?> _data) implements Object {
  _PackedParagraphStyle get packed => _data[0]! as _PackedParagraphStyle;
}

_EncodedParagraphStyle _encodeParagraphStyleFfi({
  required _NativeEnum<TextAlign>? textAlign,
  required _NativeEnum<TextDirection>? textDirection,
  required _NativeInt32? maxLines,
  required _NativeDouble? fontSize,
  required _NativeDouble? height,
  required _NativeTextHeightBehavior? textHeightBehavior,
  required _NativeFontWeight? fontWeight,
  required _NativeEnum<FontStyle>? fontStyle,
  required _NativeEnum<Hyphens>? hyphens,
  required _NativeHandle<String>? fontFamily,
  required _NativeStrutStyle? strutStyle,
  required _NativeHandle<String>? ellipsis,
  required _NativeLocale? locale,
}) {
  final bytes = Uint8List(sizeOf<_PackedParagraphStyle>());
  final _PackedParagraphStyle packed = Struct.create<_PackedParagraphStyle>(bytes);
  var mask = 0;
  if (textAlign != null) {
    mask |= 1 << 0;
  } else {
    textAlign = const .new(.start);
  }
  packed.textAlign = textAlign.value.index;
  if (textDirection != null) {
    mask |= 1 << 1;
  } else {
    textDirection = const .new(.ltr);
  }
  packed.textDirection = textDirection.value.index;
  if (maxLines != null) {
    mask |= 1 << 2;
  } else {
    maxLines = const .new(0);
  }
  packed.maxLines = maxLines.value;
  if (fontSize != null) {
    mask |= 1 << 3;
  } else {
    fontSize = const .new(14.0);
  }
  packed.fontSize = fontSize.value;
  if (height != null) {
    mask |= 1 << 4;
  } else {
    height = const .new(kTextHeightNone);
  }
  packed.height = height.value;
  if (textHeightBehavior != null) {
    mask |= 1 << 5;
  } else {
    textHeightBehavior = const .new(.new());
  }
  packed.textHeightBehavior = textHeightBehavior.encode();
  if (fontWeight != null) {
    mask |= 1 << 6;
  } else {
    fontWeight = const .new(.normal);
  }
  packed.fontWeight = fontWeight.encode();
  if (fontStyle != null) {
    mask |= 1 << 7;
  } else {
    fontStyle = const .new(.normal);
  }
  packed.fontStyle = fontStyle.value.index;
  if (hyphens != null) {
    mask |= 1 << 8;
  } else {
    hyphens = const .new(.manual);
  }
  packed.hyphens = hyphens.value.index;
  if (fontFamily != null) {
    mask |= 1 << 9;
  }
  if (strutStyle != null) {
    mask |= 1 << 10;
  }
  if (ellipsis != null) {
    mask |= 1 << 11;
  }
  if (locale != null) {
    mask |= 1 << 12;
  }
  packed.presentMask = mask;
  return _EncodedParagraphStyle(<Object?>[
    packed,
    bytes,
    fontFamily,
    strutStyle?.encode(),
    ellipsis,
    locale?.encode(),
  ]);
}

@pragma('vm:prefer-inline')
String _paragraphStyleToString(ParagraphStyle s) {
  final _PackedParagraphStyle packed = s._encoded.packed;
  final int mask = packed.presentMask;
  return 'ParagraphStyle('
      'textAlign: ${(mask & (1 << 0)) != 0 ? TextAlign.values[packed.textAlign] : "unspecified"}, '
      'textDirection: ${(mask & (1 << 1)) != 0 ? TextDirection.values[packed.textDirection] : "unspecified"}, '
      'maxLines: ${(mask & (1 << 2)) != 0 ? packed.maxLines : "unspecified"}, '
      'fontSize: ${(mask & (1 << 3)) != 0 ? packed.fontSize : "unspecified"}, '
      'height: ${(mask & (1 << 4)) != 0 ? packed.height : "unspecified"}, '
      'textHeightBehavior: ${(mask & (1 << 5)) != 0 ? _NativeTextHeightBehavior.decode(packed.textHeightBehavior) : "unspecified"}, '
      'fontWeight: ${(mask & (1 << 6)) != 0 ? _NativeFontWeight.decode(packed.fontWeight) : "unspecified"}, '
      'fontStyle: ${(mask & (1 << 7)) != 0 ? FontStyle.values[packed.fontStyle] : "unspecified"}, '
      'hyphens: ${(mask & (1 << 8)) != 0 ? Hyphens.values[packed.hyphens] : "unspecified"}, '
      'fontFamily: ${(mask & (1 << 9)) != 0 ? s._fontFamily : "unspecified"}, '
      'strutStyle: ${(mask & (1 << 10)) != 0 ? s._strutStyle : "unspecified"}, '
      'ellipsis: ${(mask & (1 << 11)) != 0 ? s._ellipsis : "unspecified"}, '
      'locale: ${(mask & (1 << 12)) != 0 ? s._locale : "unspecified"}'
      ')';
}

final class _PackedStrutStyle extends Struct {
  @Double()
  external double fontSize;

  @Double()
  external double height;

  @Double()
  external double leading;

  @Int32()
  external int fontWeight;

  @Uint16()
  external int presentMask;

  @Uint8()
  external int leadingDistribution;

  @Uint8()
  external int fontStyle;

  @Bool()
  external bool forceStrutHeight;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is _PackedStrutStyle &&
        fontSize == other.fontSize &&
        height == other.height &&
        leading == other.leading &&
        fontWeight == other.fontWeight &&
        presentMask == other.presentMask &&
        leadingDistribution == other.leadingDistribution &&
        fontStyle == other.fontStyle &&
        forceStrutHeight == other.forceStrutHeight;
  }

  @override
  int get hashCode => Object.hash(
    fontSize,
    height,
    leading,
    fontWeight,
    presentMask,
    leadingDistribution,
    fontStyle,
    forceStrutHeight,
  );
}

extension type const _EncodedStrutStyle(List<Object?> _data) implements Object {
  _PackedStrutStyle get packed => _data[0]! as _PackedStrutStyle;
}

_EncodedStrutStyle _encodeStrutStyleFfi({
  required _NativeHandle<String>? fontFamily,
  required _NativeHandle<List<String>>? fontFamilyFallback,
  required _NativeDouble? fontSize,
  required _NativeDouble? height,
  required _NativeEnum<TextLeadingDistribution>? leadingDistribution,
  required _NativeDouble? leading,
  required _NativeFontWeight? fontWeight,
  required _NativeEnum<FontStyle>? fontStyle,
  required _NativeBool? forceStrutHeight,
}) {
  final bytes = Uint8List(sizeOf<_PackedStrutStyle>());
  final _PackedStrutStyle packed = Struct.create<_PackedStrutStyle>(bytes);
  var mask = 0;
  if (fontFamily != null) {
    mask |= 1 << 0;
  }
  if (fontFamilyFallback != null) {
    mask |= 1 << 1;
  }
  if (fontSize != null) {
    mask |= 1 << 2;
  } else {
    fontSize = const .new(14.0);
  }
  packed.fontSize = fontSize.value;
  if (height != null) {
    mask |= 1 << 3;
  } else {
    height = const .new(kTextHeightNone);
  }
  packed.height = height.value;
  if (leadingDistribution != null) {
    mask |= 1 << 4;
  } else {
    leadingDistribution = const .new(.proportional);
  }
  packed.leadingDistribution = leadingDistribution.value.index;
  if (leading != null) {
    mask |= 1 << 5;
  } else {
    leading = const .new(-1.0);
  }
  packed.leading = leading.value;
  if (fontWeight != null) {
    mask |= 1 << 6;
  } else {
    fontWeight = const .new(.normal);
  }
  packed.fontWeight = fontWeight.encode();
  if (fontStyle != null) {
    mask |= 1 << 7;
  } else {
    fontStyle = const .new(.normal);
  }
  packed.fontStyle = fontStyle.value.index;
  if (forceStrutHeight != null) {
    mask |= 1 << 8;
  } else {
    forceStrutHeight = const .new(false);
  }
  packed.forceStrutHeight = forceStrutHeight.value;
  packed.presentMask = mask;
  return _EncodedStrutStyle(<Object?>[packed, bytes, fontFamily, fontFamilyFallback]);
}

@pragma('vm:prefer-inline')
String _strutStyleToString(StrutStyle s) {
  final _PackedStrutStyle packed = s._encoded.packed;
  final int mask = packed.presentMask;
  return 'StrutStyle('
      'fontFamily: ${(mask & (1 << 0)) != 0 ? s._fontFamily : "unspecified"}, '
      'fontFamilyFallback: ${(mask & (1 << 1)) != 0 ? s._fontFamilyFallback : "unspecified"}, '
      'fontSize: ${(mask & (1 << 2)) != 0 ? packed.fontSize : "unspecified"}, '
      'height: ${(mask & (1 << 3)) != 0 ? packed.height : "unspecified"}, '
      'leadingDistribution: ${(mask & (1 << 4)) != 0 ? TextLeadingDistribution.values[packed.leadingDistribution] : "unspecified"}, '
      'leading: ${(mask & (1 << 5)) != 0 ? packed.leading : "unspecified"}, '
      'fontWeight: ${(mask & (1 << 6)) != 0 ? _NativeFontWeight.decode(packed.fontWeight) : "unspecified"}, '
      'fontStyle: ${(mask & (1 << 7)) != 0 ? FontStyle.values[packed.fontStyle] : "unspecified"}, '
      'forceStrutHeight: ${(mask & (1 << 8)) != 0 ? packed.forceStrutHeight : "unspecified"}'
      ')';
}
