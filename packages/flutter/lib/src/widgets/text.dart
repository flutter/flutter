// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'basic.dart';
import 'framework.dart';
import 'media_query.dart';

/// The text style to apply to descendant [Text] widgets without explicit style.
class DefaultTextStyle extends InheritedWidget {
  /// Creates a default text style for the given subtree.
  ///
  /// Consider using [DefaultTextStyle.merge] to inherit styling information
  /// from the current default text style for a given [BuildContext].
  const DefaultTextStyle({
    Key key,
    @required this.style,
    this.textAlign,
    this.softWrap: true,
    this.overflow: TextOverflow.clip,
    this.maxLines,
    @required Widget child,
  }) : assert(style != null),
       assert(softWrap != null),
       assert(overflow != null),
       assert(child != null),
       super(key: key, child: child);

  /// A const-constructible default text style that provides fallback values.
  ///
  /// Returned from [of] when the given [BuildContext] doesn't have an enclosing default text style.
  ///
  /// This constructor creates a [DefaultTextStyle] that lacks a [child], which
  /// means the constructed value cannot be incorporated into the tree.
  const DefaultTextStyle.fallback()
    : style = const TextStyle(),
      textAlign = null,
      softWrap = true,
      maxLines = null,
      overflow = TextOverflow.clip;

  /// Creates a default text style that overrides the text styles in scope at
  /// this point in the widget tree.
  ///
  /// The given [style] is merged with the [style] from the default text style
  /// for the [BuildContext] where the widget is inserted, and any of the other
  /// arguments that are not null replace the corresponding properties on that
  /// same default text style.
  static Widget merge({
    Key key,
    TextStyle style,
    TextAlign textAlign,
    bool softWrap,
    TextOverflow overflow,
    int maxLines,
    @required Widget child,
  }) {
    assert(child != null);
    return new Builder(
      builder: (BuildContext context) {
        final DefaultTextStyle parent = DefaultTextStyle.of(context);
        return new DefaultTextStyle(
          key: key,
          style: parent.style.merge(style),
          textAlign: textAlign ?? parent.textAlign,
          softWrap: softWrap ?? parent.softWrap,
          overflow: overflow ?? parent.overflow,
          maxLines: maxLines ?? parent.maxLines,
          child: child,
        );
      },
    );
  }

  /// The text style to apply.
  final TextStyle style;

  /// How the text should be aligned horizontally.
  final TextAlign textAlign;

  /// Whether the text should break at soft line breaks.
  ///
  /// If false, the glyphs in the text will be positioned as if there was unlimited horizontal space.
  final bool softWrap;

  /// How visual overflow should be handled.
  final TextOverflow overflow;

  /// An optional maximum number of lines for the text to span, wrapping if necessary.
  /// If the text exceeds the given number of lines, it will be truncated according
  /// to [overflow].
  final int maxLines;

  /// The closest instance of this class that encloses the given context.
  ///
  /// If no such instance exists, returns an instance created by
  /// [DefaultTextStyle.fallback], which contains fallback values.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// DefaultTextStyle style = DefaultTextStyle.of(context);
  /// ```
  static DefaultTextStyle of(BuildContext context) {
    return context.inheritFromWidgetOfExactType(DefaultTextStyle) ?? const DefaultTextStyle.fallback();
  }

  @override
  bool updateShouldNotify(DefaultTextStyle old) {
    return style != old.style ||
        textAlign != old.textAlign ||
        softWrap != old.softWrap ||
        overflow != old.overflow ||
        maxLines != old.maxLines;
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    '$style'.split('\n').forEach(description.add);
  }
}

/// A run of text with a single style.
///
/// The [Text] widget displays a string of text with single style. The string
/// might break across multiple lines or might all be displayed on the same line
/// depending on the layout constraints.
///
/// The [style] argument is optional. When omitted, the text will use the style
/// from the closest enclosing [DefaultTextStyle]. If the given style's
/// [TextStyle.inherit] property is true, the given style will be merged with
/// the closest enclosing [DefaultTextStyle]. This merging behavior is useful,
/// for example, to make the text bold while using the default font family and
/// size.
///
/// To display text that uses multiple styles (e.g., a paragraph with some bold
/// words), use [RichText].
///
/// See also:
///
///  * [RichText]
///  * [DefaultTextStyle]
class Text extends StatelessWidget {
  /// Creates a text widget.
  ///
  /// If the [style] argument is null, the text will use the style from the
  /// closest enclosing [DefaultTextStyle].
  const Text(this.data, {
    Key key,
    this.style,
    this.textAlign,
    this.softWrap,
    this.overflow,
    this.textScaleFactor,
    this.maxLines,
  }) : assert(data != null),
       super(key: key);

  /// The text to display.
  final String data;

  /// If non-null, the style to use for this text.
  ///
  /// If the style's "inherit" property is true, the style will be merged with
  /// the closest enclosing [DefaultTextStyle]. Otherwise, the style will
  /// replace the closest enclosing [DefaultTextStyle].
  final TextStyle style;

  /// How the text should be aligned horizontally.
  final TextAlign textAlign;

  /// Whether the text should break at soft line breaks.
  ///
  /// If false, the glyphs in the text will be positioned as if there was unlimited horizontal space.
  final bool softWrap;

  /// How visual overflow should be handled.
  final TextOverflow overflow;

  /// The number of font pixels for each logical pixel.
  ///
  /// For example, if the text scale factor is 1.5, text will be 50% larger than
  /// the specified font size.
  ///
  /// Defaults to the [MediaQueryData.textScaleFactor] obtained from the ambient
  /// [MediaQuery], or 1.0 if there is no [MediaQuery] in scope.
  final double textScaleFactor;

  /// An optional maximum number of lines the text is allowed to take up.
  /// If the text exceeds the given number of lines, it will be truncated according
  /// to [overflow].
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final DefaultTextStyle defaultTextStyle = DefaultTextStyle.of(context);
    TextStyle effectiveTextStyle = style;
    if (style == null || style.inherit)
      effectiveTextStyle = defaultTextStyle.style.merge(style);
    return new RichText(
      textAlign: textAlign ?? defaultTextStyle.textAlign,
      softWrap: softWrap ?? defaultTextStyle.softWrap,
      overflow: overflow ?? defaultTextStyle.overflow,
      textScaleFactor: textScaleFactor ?? MediaQuery.of(context, nullOk: true)?.textScaleFactor ?? 1.0,
      maxLines: maxLines ?? defaultTextStyle.maxLines,
      text: new TextSpan(
        style: effectiveTextStyle,
        text: data
      )
    );
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('"$data"');
    if (style != null)
      '$style'.split('\n').forEach(description.add);
  }
}
