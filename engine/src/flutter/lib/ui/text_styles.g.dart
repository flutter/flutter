// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// GENERATED CODE - DO NOT EDIT BY HAND.
// ignore_for_file: unused_element

part of dart.ui;

final class _PackedTextStyle extends Struct {
  @Double()
  external double _decorationThickness;

  @Double()
  external double _fontSize;

  @Double()
  external double _letterSpacing;

  @Double()
  external double _wordSpacing;

  @Double()
  external double _height;

  @Uint32()
  external int _color;

  @Uint32()
  external int _decorationColor;

  @Uint32()
  external int _presentMask;

  @Uint16()
  external int _fontWeight;

  @Uint8()
  external int _decoration;

  @Uint8()
  external int _decorationStyle;

  @Uint8()
  external int _fontStyle;

  @Uint8()
  external int _textBaseline;

  @Uint8()
  external int _leadingDistribution;

  Color? get color => (_presentMask & (1 << 0)) == 0 ? null : _NativeColor.decode(_color);

  TextDecoration? get decoration =>
      (_presentMask & (1 << 1)) == 0 ? null : _NativeTextDecoration.decode(_decoration);

  Color? get decorationColor =>
      (_presentMask & (1 << 2)) == 0 ? null : _NativeColor.decode(_decorationColor);

  TextDecorationStyle? get decorationStyle =>
      (_presentMask & (1 << 3)) == 0 ? null : TextDecorationStyle.values[_decorationStyle];

  double? get decorationThickness => (_presentMask & (1 << 4)) == 0 ? null : _decorationThickness;

  FontWeight? get fontWeight =>
      (_presentMask & (1 << 5)) == 0 ? null : _NativeFontWeight.decode(_fontWeight);

  FontStyle? get fontStyle => (_presentMask & (1 << 6)) == 0 ? null : FontStyle.values[_fontStyle];

  TextBaseline? get textBaseline =>
      (_presentMask & (1 << 7)) == 0 ? null : TextBaseline.values[_textBaseline];

  double? get fontSize => (_presentMask & (1 << 8)) == 0 ? null : _fontSize;

  double? get letterSpacing => (_presentMask & (1 << 9)) == 0 ? null : _letterSpacing;

  double? get wordSpacing => (_presentMask & (1 << 10)) == 0 ? null : _wordSpacing;

  double? get height => (_presentMask & (1 << 11)) == 0 ? null : _height;

  TextLeadingDistribution? get leadingDistribution =>
      (_presentMask & (1 << 12)) == 0 ? null : TextLeadingDistribution.values[_leadingDistribution];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is _PackedTextStyle &&
        _presentMask == other._presentMask &&
        _decorationThickness == other._decorationThickness &&
        _fontSize == other._fontSize &&
        _letterSpacing == other._letterSpacing &&
        _wordSpacing == other._wordSpacing &&
        _height == other._height &&
        _color == other._color &&
        _decorationColor == other._decorationColor &&
        _fontWeight == other._fontWeight &&
        _decoration == other._decoration &&
        _decorationStyle == other._decorationStyle &&
        _fontStyle == other._fontStyle &&
        _textBaseline == other._textBaseline &&
        _leadingDistribution == other._leadingDistribution;
  }

  @override
  int get hashCode => Object.hash(
    _presentMask,
    _decorationThickness,
    _fontSize,
    _letterSpacing,
    _wordSpacing,
    _height,
    _color,
    _decorationColor,
    _fontWeight,
    _decoration,
    _decorationStyle,
    _fontStyle,
    _textBaseline,
    _leadingDistribution,
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
  packed._color = color.encode();
  if (decoration != null) {
    mask |= 1 << 1;
  } else {
    decoration = const .new(.none);
  }
  packed._decoration = decoration.encode();
  if (decorationColor != null) {
    mask |= 1 << 2;
  } else {
    decorationColor = const .new(Color(0x00000000));
  }
  packed._decorationColor = decorationColor.encode();
  if (decorationStyle != null) {
    mask |= 1 << 3;
  } else {
    decorationStyle = const .new(.solid);
  }
  packed._decorationStyle = decorationStyle.value.index;
  if (decorationThickness != null) {
    mask |= 1 << 4;
  } else {
    decorationThickness = const .new(1.0);
  }
  packed._decorationThickness = decorationThickness.value;
  if (fontWeight != null) {
    mask |= 1 << 5;
  } else {
    fontWeight = const .new(.normal);
  }
  packed._fontWeight = fontWeight.encode();
  if (fontStyle != null) {
    mask |= 1 << 6;
  } else {
    fontStyle = const .new(.normal);
  }
  packed._fontStyle = fontStyle.value.index;
  if (textBaseline != null) {
    mask |= 1 << 7;
  } else {
    textBaseline = const .new(.alphabetic);
  }
  packed._textBaseline = textBaseline.value.index;
  if (fontSize != null) {
    mask |= 1 << 8;
  } else {
    fontSize = const .new(14.0);
  }
  packed._fontSize = fontSize.value;
  if (letterSpacing != null) {
    mask |= 1 << 9;
  } else {
    letterSpacing = const .new(0.0);
  }
  packed._letterSpacing = letterSpacing.value;
  if (wordSpacing != null) {
    mask |= 1 << 10;
  } else {
    wordSpacing = const .new(0.0);
  }
  packed._wordSpacing = wordSpacing.value;
  if (height != null) {
    mask |= 1 << 11;
  } else {
    height = const .new(kTextHeightNone);
  }
  packed._height = height.value;
  if (leadingDistribution != null) {
    mask |= 1 << 12;
  } else {
    leadingDistribution = const .new(.proportional);
  }
  packed._leadingDistribution = leadingDistribution.value.index;
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
  packed._presentMask = mask;
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

final class _PackedParagraphStyle extends Struct {
  @Double()
  external double _fontSize;

  @Double()
  external double _height;

  @Int32()
  external int _maxLines;

  @Uint16()
  external int _fontWeight;

  @Uint16()
  external int _presentMask;

  @Uint8()
  external int _textAlign;

  @Uint8()
  external int _textDirection;

  @Uint8()
  external int _textHeightBehavior;

  @Uint8()
  external int _fontStyle;

  @Uint8()
  external int _hyphens;

  TextAlign? get textAlign => (_presentMask & (1 << 0)) == 0 ? null : TextAlign.values[_textAlign];

  TextDirection? get textDirection =>
      (_presentMask & (1 << 1)) == 0 ? null : TextDirection.values[_textDirection];

  int? get maxLines => (_presentMask & (1 << 2)) == 0 ? null : _maxLines;

  double? get fontSize => (_presentMask & (1 << 3)) == 0 ? null : _fontSize;

  double? get height => (_presentMask & (1 << 4)) == 0 ? null : _height;

  TextHeightBehavior? get textHeightBehavior =>
      (_presentMask & (1 << 5)) == 0 ? null : _NativeTextHeightBehavior.decode(_textHeightBehavior);

  FontWeight? get fontWeight =>
      (_presentMask & (1 << 6)) == 0 ? null : _NativeFontWeight.decode(_fontWeight);

  FontStyle? get fontStyle => (_presentMask & (1 << 7)) == 0 ? null : FontStyle.values[_fontStyle];

  Hyphens? get hyphens => (_presentMask & (1 << 8)) == 0 ? null : Hyphens.values[_hyphens];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is _PackedParagraphStyle &&
        _presentMask == other._presentMask &&
        _fontSize == other._fontSize &&
        _height == other._height &&
        _maxLines == other._maxLines &&
        _fontWeight == other._fontWeight &&
        _textAlign == other._textAlign &&
        _textDirection == other._textDirection &&
        _textHeightBehavior == other._textHeightBehavior &&
        _fontStyle == other._fontStyle &&
        _hyphens == other._hyphens;
  }

  @override
  int get hashCode => Object.hash(
    _presentMask,
    _fontSize,
    _height,
    _maxLines,
    _fontWeight,
    _textAlign,
    _textDirection,
    _textHeightBehavior,
    _fontStyle,
    _hyphens,
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
  packed._textAlign = textAlign.value.index;
  if (textDirection != null) {
    mask |= 1 << 1;
  } else {
    textDirection = const .new(.ltr);
  }
  packed._textDirection = textDirection.value.index;
  if (maxLines != null) {
    mask |= 1 << 2;
  } else {
    maxLines = const .new(0);
  }
  packed._maxLines = maxLines.value;
  if (fontSize != null) {
    mask |= 1 << 3;
  } else {
    fontSize = const .new(14.0);
  }
  packed._fontSize = fontSize.value;
  if (height != null) {
    mask |= 1 << 4;
  } else {
    height = const .new(kTextHeightNone);
  }
  packed._height = height.value;
  if (textHeightBehavior != null) {
    mask |= 1 << 5;
  } else {
    textHeightBehavior = const .new(.new());
  }
  packed._textHeightBehavior = textHeightBehavior.encode();
  if (fontWeight != null) {
    mask |= 1 << 6;
  } else {
    fontWeight = const .new(.normal);
  }
  packed._fontWeight = fontWeight.encode();
  if (fontStyle != null) {
    mask |= 1 << 7;
  } else {
    fontStyle = const .new(.normal);
  }
  packed._fontStyle = fontStyle.value.index;
  if (hyphens != null) {
    mask |= 1 << 8;
  } else {
    hyphens = const .new(.manual);
  }
  packed._hyphens = hyphens.value.index;
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
  packed._presentMask = mask;
  return _EncodedParagraphStyle(<Object?>[
    packed,
    bytes,
    fontFamily,
    strutStyle?.encode(),
    ellipsis,
    locale?.encode(),
  ]);
}

final class _PackedStrutStyle extends Struct {
  @Double()
  external double _fontSize;

  @Double()
  external double _height;

  @Double()
  external double _leading;

  @Uint16()
  external int _fontWeight;

  @Uint16()
  external int _presentMask;

  @Uint8()
  external int _leadingDistribution;

  @Uint8()
  external int _fontStyle;

  @Bool()
  external bool _forceStrutHeight;

  double? get fontSize => (_presentMask & (1 << 2)) == 0 ? null : _fontSize;

  double? get height => (_presentMask & (1 << 3)) == 0 ? null : _height;

  TextLeadingDistribution? get leadingDistribution =>
      (_presentMask & (1 << 4)) == 0 ? null : TextLeadingDistribution.values[_leadingDistribution];

  double? get leading => (_presentMask & (1 << 5)) == 0 ? null : _leading;

  FontWeight? get fontWeight =>
      (_presentMask & (1 << 6)) == 0 ? null : _NativeFontWeight.decode(_fontWeight);

  FontStyle? get fontStyle => (_presentMask & (1 << 7)) == 0 ? null : FontStyle.values[_fontStyle];

  bool? get forceStrutHeight => (_presentMask & (1 << 8)) == 0 ? null : _forceStrutHeight;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is _PackedStrutStyle &&
        _presentMask == other._presentMask &&
        _fontSize == other._fontSize &&
        _height == other._height &&
        _leading == other._leading &&
        _fontWeight == other._fontWeight &&
        _leadingDistribution == other._leadingDistribution &&
        _fontStyle == other._fontStyle &&
        _forceStrutHeight == other._forceStrutHeight;
  }

  @override
  int get hashCode => Object.hash(
    _presentMask,
    _fontSize,
    _height,
    _leading,
    _fontWeight,
    _leadingDistribution,
    _fontStyle,
    _forceStrutHeight,
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
  packed._fontSize = fontSize.value;
  if (height != null) {
    mask |= 1 << 3;
  } else {
    height = const .new(kTextHeightNone);
  }
  packed._height = height.value;
  if (leadingDistribution != null) {
    mask |= 1 << 4;
  } else {
    leadingDistribution = const .new(.proportional);
  }
  packed._leadingDistribution = leadingDistribution.value.index;
  if (leading != null) {
    mask |= 1 << 5;
  } else {
    leading = const .new(-1.0);
  }
  packed._leading = leading.value;
  if (fontWeight != null) {
    mask |= 1 << 6;
  } else {
    fontWeight = const .new(.normal);
  }
  packed._fontWeight = fontWeight.encode();
  if (fontStyle != null) {
    mask |= 1 << 7;
  } else {
    fontStyle = const .new(.normal);
  }
  packed._fontStyle = fontStyle.value.index;
  if (forceStrutHeight != null) {
    mask |= 1 << 8;
  } else {
    forceStrutHeight = const .new(false);
  }
  packed._forceStrutHeight = forceStrutHeight.value;
  packed._presentMask = mask;
  return _EncodedStrutStyle(<Object?>[packed, bytes, fontFamily, fontFamilyFallback]);
}
