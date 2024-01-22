// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui show TextHeightBehavior;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/rendering.dart';

import 'basic.dart';
import 'default_selection_style.dart';
import 'framework.dart';
import 'inherited_theme.dart';
import 'media_query.dart';
import 'selection_container.dart';
import 'selectable_region.dart';

// Examples can assume:
// late String _name;
// late BuildContext context;

/// The text style to apply to descendant [Text] widgets which don't have an
/// explicit style.
///
/// {@tool dartpad}
/// This example shows how to use [DefaultTextStyle.merge] to create a default
/// text style that inherits styling information from the current default text
/// style and overrides some properties.
///
/// ** See code in examples/api/lib/widgets/text/text.0.dart **
/// {@end-tool}
///
/// See also:
///
///  * [AnimatedDefaultTextStyle], which animates changes in the text style
///    smoothly over a given duration.
///  * [DefaultTextStyleTransition], which takes a provided [Animation] to
///    animate changes in text style smoothly over time.
class DefaultTextStyle extends InheritedTheme {
  /// Creates a default text style for the given subtree.
  ///
  /// Consider using [DefaultTextStyle.merge] to inherit styling information
  /// from the current default text style for a given [BuildContext].
  ///
  /// The [maxLines] property may be null (and indeed defaults to null), but if
  /// it is not null, it must be greater than zero.
  const DefaultTextStyle({
    super.key,
    required this.style,
    this.textAlign,
    this.softWrap = true,
    this.overflow = TextOverflow.clip,
    this.maxLines,
    this.textWidthBasis = TextWidthBasis.parent,
    this.textHeightBehavior,
    required super.child,
  }) : assert(maxLines == null || maxLines > 0);

  /// A const-constructable default text style that provides fallback values.
  ///
  /// Returned from [of] when the given [BuildContext] doesn't have an enclosing default text style.
  ///
  /// This constructor creates a [DefaultTextStyle] with an invalid [child], which
  /// means the constructed value cannot be incorporated into the tree.
  const DefaultTextStyle.fallback({ super.key })
    : style = const TextStyle(),
      textAlign = null,
      softWrap = true,
      maxLines = null,
      overflow = TextOverflow.clip,
      textWidthBasis = TextWidthBasis.parent,
      textHeightBehavior = null,
      super(child: const _NullWidget());

  /// Creates a default text style that overrides the text styles in scope at
  /// this point in the widget tree.
  ///
  /// The given [style] is merged with the [style] from the default text style
  /// for the [BuildContext] where the widget is inserted, and any of the other
  /// arguments that are not null replace the corresponding properties on that
  /// same default text style.
  ///
  /// This constructor cannot be used to override the [maxLines] property of the
  /// ancestor with the value null, since null here is used to mean "defer to
  /// ancestor". To replace a non-null [maxLines] from an ancestor with the null
  /// value (to remove the restriction on number of lines), manually obtain the
  /// ambient [DefaultTextStyle] using [DefaultTextStyle.of], then create a new
  /// [DefaultTextStyle] using the [DefaultTextStyle.new] constructor directly.
  /// See the source below for an example of how to do this (since that's
  /// essentially what this constructor does).
  static Widget merge({
    Key? key,
    TextStyle? style,
    TextAlign? textAlign,
    bool? softWrap,
    TextOverflow? overflow,
    int? maxLines,
    TextWidthBasis? textWidthBasis,
    required Widget child,
  }) {
    return Builder(
      builder: (BuildContext context) {
        final DefaultTextStyle parent = DefaultTextStyle.of(context);
        return DefaultTextStyle(
          key: key,
          style: parent.style.merge(style),
          textAlign: textAlign ?? parent.textAlign,
          softWrap: softWrap ?? parent.softWrap,
          overflow: overflow ?? parent.overflow,
          maxLines: maxLines ?? parent.maxLines,
          textWidthBasis: textWidthBasis ?? parent.textWidthBasis,
          child: child,
        );
      },
    );
  }

  /// The text style to apply.
  final TextStyle style;

  /// How each line of text in the Text widget should be aligned horizontally.
  final TextAlign? textAlign;

  /// Whether the text should break at soft line breaks.
  ///
  /// If false, the glyphs in the text will be positioned as if there was unlimited horizontal space.
  ///
  /// This also decides the [overflow] property's behavior. If this is true or null,
  /// the glyph causing overflow, and those that follow, will not be rendered.
  final bool softWrap;

  /// How visual overflow should be handled.
  ///
  /// If [softWrap] is true or null, the glyph causing overflow, and those that follow,
  /// will not be rendered. Otherwise, it will be shown with the given overflow option.
  final TextOverflow overflow;

  /// An optional maximum number of lines for the text to span, wrapping if necessary.
  /// If the text exceeds the given number of lines, it will be truncated according
  /// to [overflow].
  ///
  /// If this is 1, text will not wrap. Otherwise, text will be wrapped at the
  /// edge of the box.
  ///
  /// If this is non-null, it will override even explicit null values of
  /// [Text.maxLines].
  final int? maxLines;

  /// The strategy to use when calculating the width of the Text.
  ///
  /// See [TextWidthBasis] for possible values and their implications.
  final TextWidthBasis textWidthBasis;

  /// {@macro dart.ui.textHeightBehavior}
  final ui.TextHeightBehavior? textHeightBehavior;

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
    return context.dependOnInheritedWidgetOfExactType<DefaultTextStyle>() ?? const DefaultTextStyle.fallback();
  }

  @override
  bool updateShouldNotify(DefaultTextStyle oldWidget) {
    return style != oldWidget.style ||
        textAlign != oldWidget.textAlign ||
        softWrap != oldWidget.softWrap ||
        overflow != oldWidget.overflow ||
        maxLines != oldWidget.maxLines ||
        textWidthBasis != oldWidget.textWidthBasis ||
        textHeightBehavior != oldWidget.textHeightBehavior;
  }

  @override
  Widget wrap(BuildContext context, Widget child) {
    return DefaultTextStyle(
      style: style,
      textAlign: textAlign,
      softWrap: softWrap,
      overflow: overflow,
      maxLines: maxLines,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      child: child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    style.debugFillProperties(properties);
    properties.add(EnumProperty<TextAlign>('textAlign', textAlign, defaultValue: null));
    properties.add(FlagProperty('softWrap', value: softWrap, ifTrue: 'wrapping at box width', ifFalse: 'no wrapping except at line break characters', showName: true));
    properties.add(EnumProperty<TextOverflow>('overflow', overflow, defaultValue: null));
    properties.add(IntProperty('maxLines', maxLines, defaultValue: null));
    properties.add(EnumProperty<TextWidthBasis>('textWidthBasis', textWidthBasis, defaultValue: TextWidthBasis.parent));
    properties.add(DiagnosticsProperty<ui.TextHeightBehavior>('textHeightBehavior', textHeightBehavior, defaultValue: null));
  }
}

class _NullWidget extends StatelessWidget {
  const _NullWidget();

  @override
  Widget build(BuildContext context) {
    throw FlutterError(
      'A DefaultTextStyle constructed with DefaultTextStyle.fallback cannot be incorporated into the widget tree, '
      'it is meant only to provide a fallback value returned by DefaultTextStyle.of() '
      'when no enclosing default text style is present in a BuildContext.',
    );
  }
}

/// The [TextHeightBehavior] that will apply to descendant [Text] and [EditableText]
/// widgets which have not explicitly set [Text.textHeightBehavior].
///
/// If there is a [DefaultTextStyle] with a non-null [DefaultTextStyle.textHeightBehavior]
/// below this widget, the [DefaultTextStyle.textHeightBehavior] will be used
/// over this widget's [TextHeightBehavior].
///
/// See also:
///
///  * [DefaultTextStyle], which defines a [TextStyle] to apply to descendant
///    [Text] widgets.
class DefaultTextHeightBehavior extends InheritedTheme {
  /// Creates a default text height behavior for the given subtree.
  const DefaultTextHeightBehavior({
    super.key,
    required this.textHeightBehavior,
    required super.child,
  });

  /// {@macro dart.ui.textHeightBehavior}
  final TextHeightBehavior textHeightBehavior;

  /// The closest instance of [DefaultTextHeightBehavior] that encloses the
  /// given context, or null if none is found.
  ///
  /// If no such instance exists, this method will return `null`.
  ///
  /// Calling this method will create a dependency on the closest
  /// [DefaultTextHeightBehavior] in the [context], if there is one.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// TextHeightBehavior? defaultTextHeightBehavior = DefaultTextHeightBehavior.of(context);
  /// ```
  ///
  /// See also:
  ///
  /// * [DefaultTextHeightBehavior.maybeOf], which is similar to this method,
  ///   but asserts if no [DefaultTextHeightBehavior] ancestor is found.
  static TextHeightBehavior? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<DefaultTextHeightBehavior>()?.textHeightBehavior;
  }

  /// The closest instance of [DefaultTextHeightBehavior] that encloses the
  /// given context.
  ///
  /// If no such instance exists, this method will assert in debug mode, and
  /// throw an exception in release mode.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// TextHeightBehavior defaultTextHeightBehavior = DefaultTextHeightBehavior.of(context);
  /// ```
  ///
  /// Calling this method will create a dependency on the closest
  /// [DefaultTextHeightBehavior] in the [context].
  ///
  /// See also:
  ///
  /// * [DefaultTextHeightBehavior.maybeOf], which is similar to this method,
  ///   but returns null if no [DefaultTextHeightBehavior] ancestor is found.
  static TextHeightBehavior of(BuildContext context) {
    final TextHeightBehavior? behavior = maybeOf(context);
    assert(() {
      if (behavior == null) {
        throw FlutterError(
          'DefaultTextHeightBehavior.of() was called with a context that does not contain a '
          'DefaultTextHeightBehavior widget.\n'
          'No DefaultTextHeightBehavior widget ancestor could be found starting from the '
          'context that was passed to DefaultTextHeightBehavior.of(). This can happen '
          'because you are using a widget that looks for a DefaultTextHeightBehavior '
          'ancestor, but no such ancestor exists.\n'
          'The context used was:\n'
          '  $context',
        );
      }
      return true;
    }());
    return behavior!;
  }

  @override
  bool updateShouldNotify(DefaultTextHeightBehavior oldWidget) {
    return textHeightBehavior != oldWidget.textHeightBehavior;
  }

  @override
  Widget wrap(BuildContext context, Widget child) {
    return DefaultTextHeightBehavior(
      textHeightBehavior: textHeightBehavior,
      child: child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ui.TextHeightBehavior>('textHeightBehavior', textHeightBehavior, defaultValue: null));
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
/// [TextStyle.inherit] property is true (the default), the given style will
/// be merged with the closest enclosing [DefaultTextStyle]. This merging
/// behavior is useful, for example, to make the text bold while using the
/// default font family and size.
///
/// {@tool snippet}
///
/// This example shows how to display text using the [Text] widget with the
/// [overflow] set to [TextOverflow.ellipsis].
///
/// ![If the text overflows, the Text widget displays an ellipsis to trim the overflowing text](https://flutter.github.io/assets-for-api-docs/assets/widgets/text_ellipsis.png)
///
/// ```dart
/// Container(
///   width: 100,
///   decoration: BoxDecoration(border: Border.all()),
///   child: Text(overflow: TextOverflow.ellipsis, 'Hello $_name, how are you?'))
/// ```
/// {@end-tool}
///
/// {@tool snippet}
///
/// Setting [maxLines] to `1` is not equivalent to disabling soft wrapping with
/// [softWrap]. This is apparent when using [TextOverflow.fade] as the following
/// examples show.
///
/// ![If a second line overflows the Text widget displays a horizontal fade](https://flutter.github.io/assets-for-api-docs/assets/widgets/text_fade_max_lines.png)
///
/// ```dart
/// Text(
///   overflow: TextOverflow.fade,
///   maxLines: 1,
///   'Hello $_name, how are you?')
/// ```
///
/// Here soft wrapping is enabled and the [Text] widget tries to wrap the words
/// "how are you?" to a second line. This is prevented by the [maxLines] value
/// of `1`. The result is that a second line overflows and the fade appears in a
/// horizontal direction at the bottom.
///
/// ![If a single line overflows the Text widget displays a horizontal fade](https://flutter.github.io/assets-for-api-docs/assets/widgets/text_fade_soft_wrap.png)
///
/// ```dart
/// Text(
///   overflow: TextOverflow.fade,
///   softWrap: false,
///   'Hello $_name, how are you?')
/// ```
///
/// Here soft wrapping is disabled with `softWrap: false` and the [Text] widget
/// attempts to display its text in a single unbroken line. The result is that
/// the single line overflows and the fade appears in a vertical direction at
/// the right.
///
/// {@end-tool}
///
/// Using the [Text.rich] constructor, the [Text] widget can
/// display a paragraph with differently styled [TextSpan]s. The sample
/// that follows displays "Hello beautiful world" with different styles
/// for each word.
///
/// {@tool snippet}
///
/// ![The word "Hello" is shown with the default text styles. The word "beautiful" is italicized. The word "world" is bold.](https://flutter.github.io/assets-for-api-docs/assets/widgets/text_rich.png)
///
/// ```dart
/// const Text.rich(
///   TextSpan(
///     text: 'Hello', // default text style
///     children: <TextSpan>[
///       TextSpan(text: ' beautiful ', style: TextStyle(fontStyle: FontStyle.italic)),
///       TextSpan(text: 'world', style: TextStyle(fontWeight: FontWeight.bold)),
///     ],
///   ),
/// )
/// ```
/// {@end-tool}
///
/// ## Interactivity
///
/// To make [Text] react to touch events, wrap it in a [GestureDetector] widget
/// with a [GestureDetector.onTap] handler.
///
/// In a Material Design application, consider using a [TextButton] instead, or
/// if that isn't appropriate, at least using an [InkWell] instead of
/// [GestureDetector].
///
/// To make sections of the text interactive, use [RichText] and specify a
/// [TapGestureRecognizer] as the [TextSpan.recognizer] of the relevant part of
/// the text.
///
/// ## Selection
///
/// [Text] is not selectable by default. To make a [Text] selectable, one can
/// wrap a subtree with a [SelectionArea] widget. To exclude a part of a subtree
/// under [SelectionArea] from selection, once can also wrap that part of the
/// subtree with [SelectionContainer.disabled].
///
/// {@tool dartpad}
/// This sample demonstrates how to disable selection for a Text under a
/// SelectionArea.
///
/// ** See code in examples/api/lib/material/selection_container/selection_container_disabled.0.dart **
/// {@end-tool}
///
/// See also:
///
///  * [RichText], which gives you more control over the text styles.
///  * [DefaultTextStyle], which sets default styles for [Text] widgets.
///  * [SelectableRegion], which provides an overview of the selection system.
class Text extends StatelessWidget {
  /// Creates a text widget.
  ///
  /// If the [style] argument is null, the text will use the style from the
  /// closest enclosing [DefaultTextStyle].
  ///
  /// The [overflow] property's behavior is affected by the [softWrap] argument.
  /// If the [softWrap] is true or null, the glyph causing overflow, and those
  /// that follow, will not be rendered. Otherwise, it will be shown with the
  /// given overflow option.
  const Text(
    String this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    @Deprecated(
      'Use textScaler instead. '
      'Use of textScaleFactor was deprecated in preparation for the upcoming nonlinear text scaling support. '
      'This feature was deprecated after v3.12.0-2.0.pre.',
    )
    this.textScaleFactor,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
  }) : textSpan = null,
       assert(
         textScaler == null || textScaleFactor == null,
         'textScaleFactor is deprecated and cannot be specified when textScaler is specified.',
       );

  /// Creates a text widget with a [InlineSpan].
  ///
  /// The following subclasses of [InlineSpan] may be used to build rich text:
  ///
  /// * [TextSpan]s define text and children [InlineSpan]s.
  /// * [WidgetSpan]s define embedded inline widgets.
  ///
  /// See [RichText] which provides a lower-level way to draw text.
  const Text.rich(
    InlineSpan this.textSpan, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    @Deprecated(
      'Use textScaler instead. '
      'Use of textScaleFactor was deprecated in preparation for the upcoming nonlinear text scaling support. '
      'This feature was deprecated after v3.12.0-2.0.pre.',
    )
    this.textScaleFactor,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
  }) : data = null,
       assert(
         textScaler == null || textScaleFactor == null,
         'textScaleFactor is deprecated and cannot be specified when textScaler is specified.',
       );

  /// The text to display.
  ///
  /// This will be null if a [textSpan] is provided instead.
  final String? data;

  /// The text to display as a [InlineSpan].
  ///
  /// This will be null if [data] is provided instead.
  final InlineSpan? textSpan;

  /// If non-null, the style to use for this text.
  ///
  /// If the style's "inherit" property is true, the style will be merged with
  /// the closest enclosing [DefaultTextStyle]. Otherwise, the style will
  /// replace the closest enclosing [DefaultTextStyle].
  final TextStyle? style;

  /// {@macro flutter.painting.textPainter.strutStyle}
  final StrutStyle? strutStyle;

  /// How the text should be aligned horizontally.
  final TextAlign? textAlign;

  /// The directionality of the text.
  ///
  /// This decides how [textAlign] values like [TextAlign.start] and
  /// [TextAlign.end] are interpreted.
  ///
  /// This is also used to disambiguate how to render bidirectional text. For
  /// example, if the [data] is an English phrase followed by a Hebrew phrase,
  /// in a [TextDirection.ltr] context the English phrase will be on the left
  /// and the Hebrew phrase to its right, while in a [TextDirection.rtl]
  /// context, the English phrase will be on the right and the Hebrew phrase on
  /// its left.
  ///
  /// Defaults to the ambient [Directionality], if any.
  final TextDirection? textDirection;

  /// Used to select a font when the same Unicode character can
  /// be rendered differently, depending on the locale.
  ///
  /// It's rarely necessary to set this property. By default its value
  /// is inherited from the enclosing app with `Localizations.localeOf(context)`.
  ///
  /// See [RenderParagraph.locale] for more information.
  final Locale? locale;

  /// Whether the text should break at soft line breaks.
  ///
  /// If false, the glyphs in the text will be positioned as if there was unlimited horizontal space.
  final bool? softWrap;

  /// How visual overflow should be handled.
  ///
  /// If this is null [TextStyle.overflow] will be used, otherwise the value
  /// from the nearest [DefaultTextStyle] ancestor will be used.
  final TextOverflow? overflow;

  /// Deprecated. Will be removed in a future version of Flutter. Use
  /// [textScaler] instead.
  ///
  /// The number of font pixels for each logical pixel.
  ///
  /// For example, if the text scale factor is 1.5, text will be 50% larger than
  /// the specified font size.
  ///
  /// The value given to the constructor as textScaleFactor. If null, will
  /// use the [MediaQueryData.textScaleFactor] obtained from the ambient
  /// [MediaQuery], or 1.0 if there is no [MediaQuery] in scope.
  @Deprecated(
    'Use textScaler instead. '
    'Use of textScaleFactor was deprecated in preparation for the upcoming nonlinear text scaling support. '
    'This feature was deprecated after v3.12.0-2.0.pre.',
  )
  final double? textScaleFactor;

  /// {@macro flutter.painting.textPainter.textScaler}
  final TextScaler? textScaler;

  /// An optional maximum number of lines for the text to span, wrapping if necessary.
  /// If the text exceeds the given number of lines, it will be truncated according
  /// to [overflow].
  ///
  /// If this is 1, text will not wrap. Otherwise, text will be wrapped at the
  /// edge of the box.
  ///
  /// If this is null, but there is an ambient [DefaultTextStyle] that specifies
  /// an explicit number for its [DefaultTextStyle.maxLines], then the
  /// [DefaultTextStyle] value will take precedence. You can use a [RichText]
  /// widget directly to entirely override the [DefaultTextStyle].
  final int? maxLines;

  /// {@template flutter.widgets.Text.semanticsLabel}
  /// An alternative semantics label for this text.
  ///
  /// If present, the semantics of this widget will contain this value instead
  /// of the actual text. This will overwrite any of the semantics labels applied
  /// directly to the [TextSpan]s.
  ///
  /// This is useful for replacing abbreviations or shorthands with the full
  /// text value:
  ///
  /// ```dart
  /// const Text(r'$$', semanticsLabel: 'Double dollars')
  /// ```
  /// {@endtemplate}
  final String? semanticsLabel;

  /// {@macro flutter.painting.textPainter.textWidthBasis}
  final TextWidthBasis? textWidthBasis;

  /// {@macro dart.ui.textHeightBehavior}
  final ui.TextHeightBehavior? textHeightBehavior;

  /// The color to use when painting the selection.
  ///
  /// This is ignored if [SelectionContainer.maybeOf] returns null
  /// in the [BuildContext] of the [Text] widget.
  ///
  /// If null, the ambient [DefaultSelectionStyle] is used (if any); failing
  /// that, the selection color defaults to [DefaultSelectionStyle.defaultColor]
  /// (semi-transparent grey).
  final Color? selectionColor;

  @override
  Widget build(BuildContext context) {
    final DefaultTextStyle defaultTextStyle = DefaultTextStyle.of(context);
    TextStyle? effectiveTextStyle = style;
    if (style == null || style!.inherit) {
      effectiveTextStyle = defaultTextStyle.style.merge(style);
    }
    if (MediaQuery.boldTextOf(context)) {
      effectiveTextStyle = effectiveTextStyle!.merge(const TextStyle(fontWeight: FontWeight.bold));
    }
    final SelectionRegistrar? registrar = SelectionContainer.maybeOf(context);
    final TextScaler textScaler = switch ((this.textScaler, textScaleFactor)) {
      (final TextScaler textScaler, _)     => textScaler,
      // For unmigrated apps, fall back to textScaleFactor.
      (null, final double textScaleFactor) => TextScaler.linear(textScaleFactor),
      (null, null)                         => MediaQuery.textScalerOf(context),
    };
    final GlobalKey _textKey = GlobalKey();
    final _SelectableTextContainerDelegate _selectionDelegate = _SelectableTextContainerDelegate(_textKey, TextSpan(
        style: effectiveTextStyle,
        text: data,
        children: textSpan != null ? <InlineSpan>[textSpan!] : null,
      ));
    Widget result = RichText(
      key: _textKey,
      textAlign: textAlign ?? defaultTextStyle.textAlign ?? TextAlign.start,
      textDirection: textDirection, // RichText uses Directionality.of to obtain a default if this is null.
      locale: locale, // RichText uses Localizations.localeOf to obtain a default if this is null
      softWrap: softWrap ?? defaultTextStyle.softWrap,
      overflow: overflow ?? effectiveTextStyle?.overflow ?? defaultTextStyle.overflow,
      textScaler: textScaler,
      maxLines: maxLines ?? defaultTextStyle.maxLines,
      strutStyle: strutStyle,
      textWidthBasis: textWidthBasis ?? defaultTextStyle.textWidthBasis,
      textHeightBehavior: textHeightBehavior ?? defaultTextStyle.textHeightBehavior ?? DefaultTextHeightBehavior.maybeOf(context),
      selectionRegistrar: _selectionDelegate,
      selectionColor: selectionColor ?? DefaultSelectionStyle.of(context).selectionColor ?? DefaultSelectionStyle.defaultColor,
      text: TextSpan(
        style: effectiveTextStyle,
        text: data,
        children: textSpan != null ? <InlineSpan>[textSpan!] : null,
      ),
    );
    if (registrar != null) {
      result = SelectionContainer(delegate: _selectionDelegate, child: result);
      result = MouseRegion(
        cursor: DefaultSelectionStyle.of(context).mouseCursor ?? SystemMouseCursors.text,
        child: result,
      );
    }
    if (semanticsLabel != null) {
      result = Semantics(
        textDirection: textDirection,
        label: semanticsLabel,
        child: ExcludeSemantics(
          child: result,
        ),
      );
    }
    return result;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('data', data, showName: false));
    if (textSpan != null) {
      properties.add(textSpan!.toDiagnosticsNode(name: 'textSpan', style: DiagnosticsTreeStyle.transition));
    }
    style?.debugFillProperties(properties);
    properties.add(EnumProperty<TextAlign>('textAlign', textAlign, defaultValue: null));
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection, defaultValue: null));
    properties.add(DiagnosticsProperty<Locale>('locale', locale, defaultValue: null));
    properties.add(FlagProperty('softWrap', value: softWrap, ifTrue: 'wrapping at box width', ifFalse: 'no wrapping except at line break characters', showName: true));
    properties.add(EnumProperty<TextOverflow>('overflow', overflow, defaultValue: null));
    properties.add(DoubleProperty('textScaleFactor', textScaleFactor, defaultValue: null));
    properties.add(IntProperty('maxLines', maxLines, defaultValue: null));
    properties.add(EnumProperty<TextWidthBasis>('textWidthBasis', textWidthBasis, defaultValue: null));
    properties.add(DiagnosticsProperty<ui.TextHeightBehavior>('textHeightBehavior', textHeightBehavior, defaultValue: null));
    if (semanticsLabel != null) {
      properties.add(StringProperty('semanticsLabel', semanticsLabel));
    }
  }
}

class _SelectableTextContainerDelegate extends SelectionContainerDelegate with ChangeNotifier {
  _SelectableTextContainerDelegate(
    GlobalKey textKey,
    InlineSpan text,
  ) : _textKey = textKey {
    if (kFlutterMemoryAllocationsEnabled) {
      ChangeNotifier.maybeDispatchObjectCreation(this);
    }
    _slots = _getSlots(text);
  }

  final GlobalKey _textKey;
  RenderParagraph get paragraph => _textKey.currentContext!.findRenderObject()! as RenderParagraph;
  late List<_SelectableSlot> _slots;

  bool _isSlotsFilled() {
    if (_slots.isEmpty) {
      return false;
    }
    for (final _SelectableSlot slot in _slots) {
      if (slot.selectable == null) {
        return false;
      }
    }
    return true;
  }

  List<_SelectableSlot> _getSlots(InlineSpan text) {
    final String _placeholderCharacter = String.fromCharCode(PlaceholderSpan.placeholderCodeUnit);
    final String plainText = text.toPlainText(includeSemanticsLabels: false);
    final List<_SelectableSlot> result = <_SelectableSlot>[];
    int start = 0;
    while (start < plainText.length) {
      int end = plainText.indexOf(_placeholderCharacter, start);
      int prevEnd = end;
      if (start != end) {
        if (end == -1) {
          end = plainText.length;
          result.add(
            _SelectableSlot(type: _SlotType.text),
          );
        } else {
          result.add(
            _SelectableSlot(type: _SlotType.text),
          );
          result.add(
            _SelectableSlot(type: _SlotType.placeholder),
          );
        }
        start = end;
      } else {
        result.add(
          _SelectableSlot(type: _SlotType.placeholder),
        );
      }
      start += 1;
    }
    return result;
  }

  void _fillNextSlot(Selectable selectable) {
    // Iterate through slots.
    for (int index = 0; index < _slots.length; index += 1) {
      // Find an empty slot.
      if (_slots[index].selectable == null) {
        final bool isRootSelectable = paragraph.selectables?.contains(selectable) ?? false;
        if (_slots[index].type == _SlotType.placeholder) {
          if (isRootSelectable) {
            continue;
          }
          _slots[index] = _SelectableSlot(type: _SlotType.placeholder, selectable: selectable);
          break;
        }
        if (_slots[index].type == _SlotType.text) {
          if (isRootSelectable) {
            _slots[index] = _SelectableSlot(type: _SlotType.text, selectable: selectable);
            break;
          }
        }
      }
    }
  }

  final Set<Selectable> _hasReceivedStartEvent = <Selectable>{};
  final Set<Selectable> _hasReceivedEndEvent = <Selectable>{};

  Offset? _lastStartEdgeUpdateGlobalPosition;
  Offset? _lastEndEdgeUpdateGlobalPosition;

  /// Gets the list of selectables this delegate is managing.
  List<Selectable> selectables = <Selectable>[];

  /// The number of additional pixels added to the selection handle drawable
  /// area.
  ///
  /// Selection handles that are outside of the drawable area will be hidden.
  /// That logic prevents handles that get scrolled off the viewport from being
  /// drawn on the screen.
  ///
  /// The drawable area = current rectangle of [SelectionContainer] +
  /// _kSelectionHandleDrawableAreaPadding on each side.
  ///
  /// This was an eyeballed value to create smooth user experiences.
  static const double _kSelectionHandleDrawableAreaPadding = 5.0;

  /// The current selectable that contains the selection end edge.
  @protected
  int currentSelectionEndIndex = -1;

  /// The current selectable that contains the selection start edge.
  @protected
  int currentSelectionStartIndex = -1;

  LayerLink? _startHandleLayer;
  Selectable? _startHandleLayerOwner;
  LayerLink? _endHandleLayer;
  Selectable? _endHandleLayerOwner;

  bool _isHandlingSelectionEvent = false;
  bool _scheduledSelectableUpdate = false;
  List<Selectable> _additions = <Selectable>[];

  bool _extendSelectionInProgress = false;

  @override
  void add(Selectable selectable) {
    assert(!_isSlotsFilled());
    assert(!selectables.contains(selectable));
    _additions.add(selectable);
    _scheduleSelectableUpdate();
  }

  @override
  void remove(Selectable selectable) {
    _hasReceivedStartEvent.remove(selectable);
    _hasReceivedEndEvent.remove(selectable);
    if (_additions.remove(selectable)) {
      // The same selectable was added in the same frame and is not yet
      // incorporated into the selectables.
      //
      // Removing such selectable doesn't require selection geometry update.
      return;
    }
    _removeSelectable(selectable);
    _scheduleSelectableUpdate();
  }

  void _updateLastEdgeEventsFromGeometries() {
    if (currentSelectionStartIndex != -1 && selectables[currentSelectionStartIndex].value.hasSelection) {
      final Selectable start = selectables[currentSelectionStartIndex];
      final Offset localStartEdge = start.value.startSelectionPoint!.localPosition +
          Offset(0, - start.value.startSelectionPoint!.lineHeight / 2);
      _lastStartEdgeUpdateGlobalPosition = MatrixUtils.transformPoint(start.getTransformTo(null), localStartEdge);
    }
    if (currentSelectionEndIndex != -1 && selectables[currentSelectionEndIndex].value.hasSelection) {
      final Selectable end = selectables[currentSelectionEndIndex];
      final Offset localEndEdge = end.value.endSelectionPoint!.localPosition +
          Offset(0, -end.value.endSelectionPoint!.lineHeight / 2);
      _lastEndEdgeUpdateGlobalPosition = MatrixUtils.transformPoint(end.getTransformTo(null), localEndEdge);
    }
  }

  /// Notifies this delegate that layout of the container has changed.
  void layoutDidChange() {
    _updateSelectionGeometry();
  }

  void _scheduleSelectableUpdate() {
    if (!_scheduledSelectableUpdate) {
      _scheduledSelectableUpdate = true;
      void runScheduledTask([Duration? duration]) {
        if (!_scheduledSelectableUpdate) {
          return;
        }
        _scheduledSelectableUpdate = false;
        _updateSelectables();
      }

      if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.postFrameCallbacks) {
        // A new task can be scheduled as a result of running the scheduled task
        // from another MultiSelectableSelectionContainerDelegate. This can
        // happen if nesting two SelectionContainers. The selectable can be
        // safely updated in the same frame in this case.
        scheduleMicrotask(runScheduledTask);
      } else {
        SchedulerBinding.instance.addPostFrameCallback(
          runScheduledTask,
          debugLabel: 'SelectionContainer.runScheduledTask',
        );
      }
    }
  }

  void _updateSelectables() {
    // Remove offScreen selectable.
    if (_additions.isNotEmpty) {
      _flushAdditions();
    }
    didChangeSelectables();
  }

  void _flushAdditions() {
    final List<Selectable> existingSelectables = selectables;
    // Find selectables that belong to the Text widget that created this container.
    final List<Selectable> rootSelectables = <Selectable>[];
    final List<Selectable> placeholderSelectables = <Selectable>[];
    for (final Selectable selectable in _additions) {
      if (paragraph.selectables?.contains(selectable) ?? false) {
        rootSelectables.add(selectable);
      } else {
        placeholderSelectables.add(selectable);
      }
    }
    rootSelectables.sort((Selectable a, Selectable b) {
      if (paragraph.selectables == null) {
        return 0;
      }

      final int indexOfA = paragraph.selectables!.indexOf(a);
      final int indexOfB = paragraph.selectables!.indexOf(b);

      if (indexOfA < indexOfB) {
        return -1;
      }
      return 1;
    });
    for (final Selectable selectable in rootSelectables) {
      _fillNextSlot(selectable);
    }
    for (final Selectable selectable in placeholderSelectables) {
      _fillNextSlot(selectable);
    }
    selectables = <Selectable>[];
    for (int index = 0; index < _slots.length; index += 1) {
      final Selectable? selectable = _slots[index].selectable;
      if (selectable != null) {
        if (!existingSelectables.contains(selectable!)) {
          if (index < max(currentSelectionStartIndex, currentSelectionEndIndex) &&
              index > min(currentSelectionStartIndex, currentSelectionEndIndex)) {
            ensureChildUpdated(selectable!);
          }
          selectable!.addListener(_handleSelectableGeometryChange);
        }
        selectables.add(selectable!);
      }
    }
    _additions = <Selectable>[];
  }

  void _removeSelectable(Selectable selectable) {
    assert(selectables.contains(selectable), 'The selectable is not in this registrar.');
    final int index = selectables.indexOf(selectable);
    selectables.removeAt(index);
    if (index <= currentSelectionEndIndex) {
      currentSelectionEndIndex -= 1;
    }
    if (index <= currentSelectionStartIndex) {
      currentSelectionStartIndex -= 1;
    }
    selectable.removeListener(_handleSelectableGeometryChange);
  }

  /// Called when this delegate finishes updating the selectables.
  @protected
  @mustCallSuper
  void didChangeSelectables() {
    if (_lastEndEdgeUpdateGlobalPosition != null) {
      handleSelectionEdgeUpdate(
        SelectionEdgeUpdateEvent.forEnd(
          globalPosition: _lastEndEdgeUpdateGlobalPosition!,
        ),
      );
    }
    if (_lastStartEdgeUpdateGlobalPosition != null) {
      handleSelectionEdgeUpdate(
        SelectionEdgeUpdateEvent.forStart(
          globalPosition: _lastStartEdgeUpdateGlobalPosition!,
        ),
      );
    }
    final Set<Selectable> selectableSet = selectables.toSet();
    _hasReceivedEndEvent.removeWhere((Selectable selectable) => !selectableSet.contains(selectable));
    _hasReceivedStartEvent.removeWhere((Selectable selectable) => !selectableSet.contains(selectable));
    _updateSelectionGeometry();
  }

  @override
  SelectionGeometry get value => _selectionGeometry;
  SelectionGeometry _selectionGeometry = const SelectionGeometry(
    hasContent: false,
    status: SelectionStatus.none,
  );

  /// Updates the [value] in this class and notifies listeners if necessary.
  void _updateSelectionGeometry() {
    final SelectionGeometry newValue = getSelectionGeometry();
    if (_selectionGeometry != newValue) {
      _selectionGeometry = newValue;
      notifyListeners();
    }
    _updateHandleLayersAndOwners();
  }

  void _handleSelectableGeometryChange() {
    // Geometries of selectable children may change multiple times when handling
    // selection events. Ignore these updates since the selection geometry of
    // this delegate will be updated after handling the selection events.
    if (_isHandlingSelectionEvent) {
      return;
    }
    _updateSelectionGeometry();
  }

  /// Gets the combined selection geometry for child selectables.
  @protected
  SelectionGeometry getSelectionGeometry() {
    if (currentSelectionEndIndex == -1 ||
        currentSelectionStartIndex == -1 ||
        selectables.isEmpty) {
      // There is no valid selection.
      return SelectionGeometry(
        status: SelectionStatus.none,
        hasContent: selectables.isNotEmpty,
      );
    }

    if (!_extendSelectionInProgress) {
      currentSelectionStartIndex = _adjustSelectionIndexBasedOnSelectionGeometry(
        currentSelectionStartIndex,
        currentSelectionEndIndex,
      );
      currentSelectionEndIndex = _adjustSelectionIndexBasedOnSelectionGeometry(
        currentSelectionEndIndex,
        currentSelectionStartIndex,
      );
    }

    // Need to find the non-null start selection point.
    SelectionGeometry startGeometry = selectables[currentSelectionStartIndex].value;
    final bool forwardSelection = currentSelectionEndIndex >= currentSelectionStartIndex;
    int startIndexWalker = currentSelectionStartIndex;
    while (startIndexWalker != currentSelectionEndIndex && startGeometry.startSelectionPoint == null) {
      startIndexWalker += forwardSelection ? 1 : -1;
      startGeometry = selectables[startIndexWalker].value;
    }

    SelectionPoint? startPoint;
    if (startGeometry.startSelectionPoint != null) {
      final Matrix4 startTransform = getTransformFrom(selectables[startIndexWalker]);
      final Offset start = MatrixUtils.transformPoint(startTransform, startGeometry.startSelectionPoint!.localPosition);
      // It can be NaN if it is detached or off-screen.
      if (start.isFinite) {
        startPoint = SelectionPoint(
          localPosition: start,
          lineHeight: startGeometry.startSelectionPoint!.lineHeight,
          handleType: startGeometry.startSelectionPoint!.handleType,
        );
      }
    }

    // Need to find the non-null end selection point.
    SelectionGeometry endGeometry = selectables[currentSelectionEndIndex].value;
    int endIndexWalker = currentSelectionEndIndex;
    while (endIndexWalker != currentSelectionStartIndex && endGeometry.endSelectionPoint == null) {
      endIndexWalker += forwardSelection ? -1 : 1;
      endGeometry = selectables[endIndexWalker].value;
    }
    SelectionPoint? endPoint;
    if (endGeometry.endSelectionPoint != null) {
      final Matrix4 endTransform = getTransformFrom(selectables[endIndexWalker]);
      final Offset end = MatrixUtils.transformPoint(endTransform, endGeometry.endSelectionPoint!.localPosition);
      // It can be NaN if it is detached or off-screen.
      if (end.isFinite) {
        endPoint = SelectionPoint(
          localPosition: end,
          lineHeight: endGeometry.endSelectionPoint!.lineHeight,
          handleType: endGeometry.endSelectionPoint!.handleType,
        );
      }
    }

    // Need to collect selection rects from selectables ranging from the
    // currentSelectionStartIndex to the currentSelectionEndIndex.
    final List<Rect> selectionRects = <Rect>[];
    final Rect? drawableArea = hasSize ? Rect
      .fromLTWH(0, 0, containerSize.width, containerSize.height) : null;
    for (int index = currentSelectionStartIndex; index <= currentSelectionEndIndex; index++) {
      final List<Rect> currSelectableSelectionRects = selectables[index].value.selectionRects;
      final List<Rect> selectionRectsWithinDrawableArea = currSelectableSelectionRects.map((Rect selectionRect) {
        final Matrix4 transform = getTransformFrom(selectables[index]);
        final Rect localRect = MatrixUtils.transformRect(transform, selectionRect);
        if (drawableArea != null) {
          return drawableArea.intersect(localRect);
        }
        return localRect;
      }).where((Rect selectionRect) {
        return selectionRect.isFinite && !selectionRect.isEmpty;
      }).toList();
      selectionRects.addAll(selectionRectsWithinDrawableArea);
    }

    return SelectionGeometry(
      startSelectionPoint: startPoint,
      endSelectionPoint: endPoint,
      selectionRects: selectionRects,
      status: startGeometry != endGeometry
        ? SelectionStatus.uncollapsed
        : startGeometry.status,
      // Would have at least one selectable child.
      hasContent: true,
    );
  }

  // The currentSelectionStartIndex or currentSelectionEndIndex may not be
  // the current index that contains selection edges. This can happen if the
  // selection edge is in between two selectables. One of the selectable will
  // have its selection collapsed at the index 0 or contentLength depends on
  // whether the selection is reversed or not. The current selection index can
  // be point to either one.
  //
  // This method adjusts the index to point to selectable with valid selection.
  int _adjustSelectionIndexBasedOnSelectionGeometry(int currentIndex, int towardIndex) {
    final bool forward = towardIndex > currentIndex;
    while (currentIndex != towardIndex &&
           selectables[currentIndex].value.status != SelectionStatus.uncollapsed) {
      currentIndex += forward ? 1 : -1;
    }
    return currentIndex;
  }

  @override
  void pushHandleLayers(LayerLink? startHandle, LayerLink? endHandle) {
    if (_startHandleLayer == startHandle && _endHandleLayer == endHandle) {
      return;
    }
    _startHandleLayer = startHandle;
    _endHandleLayer = endHandle;
    _updateHandleLayersAndOwners();
  }

  /// Pushes both handle layers to the selectables that contain selection edges.
  ///
  /// This method needs to be called every time the selectables that contain the
  /// selection edges change, i.e. [currentSelectionStartIndex] or
  /// [currentSelectionEndIndex] changes. Otherwise, the handle may be painted
  /// in the wrong place.
  void _updateHandleLayersAndOwners() {
    LayerLink? effectiveStartHandle = _startHandleLayer;
    LayerLink? effectiveEndHandle = _endHandleLayer;
    if (effectiveStartHandle != null || effectiveEndHandle != null) {
      final Rect? drawableArea = hasSize ? Rect
        .fromLTWH(0, 0, containerSize.width, containerSize.height)
        .inflate(_kSelectionHandleDrawableAreaPadding) : null;
      final bool hideStartHandle = value.startSelectionPoint == null || drawableArea == null || !drawableArea.contains(value.startSelectionPoint!.localPosition);
      final bool hideEndHandle = value.endSelectionPoint == null || drawableArea == null|| !drawableArea.contains(value.endSelectionPoint!.localPosition);
      effectiveStartHandle = hideStartHandle ? null : _startHandleLayer;
      effectiveEndHandle = hideEndHandle ? null : _endHandleLayer;
    }
    if (currentSelectionStartIndex == -1 || currentSelectionEndIndex == -1) {
      // No valid selection.
      if (_startHandleLayerOwner != null) {
        _startHandleLayerOwner!.pushHandleLayers(null, null);
        _startHandleLayerOwner = null;
      }
      if (_endHandleLayerOwner != null) {
        _endHandleLayerOwner!.pushHandleLayers(null, null);
        _endHandleLayerOwner = null;
      }
      return;
    }

    if (selectables[currentSelectionStartIndex] != _startHandleLayerOwner) {
      _startHandleLayerOwner?.pushHandleLayers(null, null);
    }
    if (selectables[currentSelectionEndIndex] != _endHandleLayerOwner) {
      _endHandleLayerOwner?.pushHandleLayers(null, null);
    }

    _startHandleLayerOwner = selectables[currentSelectionStartIndex];

    if (currentSelectionStartIndex == currentSelectionEndIndex) {
      // Selection edges is on the same selectable.
      _endHandleLayerOwner = _startHandleLayerOwner;
      _startHandleLayerOwner!.pushHandleLayers(effectiveStartHandle, effectiveEndHandle);
      return;
    }

    _startHandleLayerOwner!.pushHandleLayers(effectiveStartHandle, null);
    _endHandleLayerOwner = selectables[currentSelectionEndIndex];
    _endHandleLayerOwner!.pushHandleLayers(null, effectiveEndHandle);
  }

  /// Copies the selected contents of all selectables.
  @override
  SelectedContent? getSelectedContent() {
    final List<SelectedContent> selections = <SelectedContent>[];
    for (final Selectable selectable in selectables) {
      final SelectedContent? data = selectable.getSelectedContent();
      if (data != null) {
        selections.add(data);
      }
    }
    if (selections.isEmpty) {
      return null;
    }
    final StringBuffer buffer = StringBuffer();
    for (final SelectedContent selection in selections) {
      buffer.write(selection.plainText);
    }
    return SelectedContent(
      plainText: buffer.toString(),
    );
  }

  // Clears the selection on all selectables not in the range of
  // currentSelectionStartIndex..currentSelectionEndIndex.
  //
  // If one of the edges does not exist, then this method will clear the selection
  // in all selectables except the existing edge.
  //
  // If neither of the edges exist this method immediately returns.
  void _flushInactiveSelections() {
    if (currentSelectionStartIndex == -1 && currentSelectionEndIndex == -1) {
      return;
    }
    if (currentSelectionStartIndex == -1 || currentSelectionEndIndex == -1) {
      final int skipIndex = currentSelectionStartIndex == -1 ? currentSelectionEndIndex : currentSelectionStartIndex;
      selectables
        .where((Selectable target) => target != selectables[skipIndex])
        .forEach((Selectable target) => dispatchSelectionEventToChild(target, const ClearSelectionEvent()));
      return;
    }
    final int skipStart = min(currentSelectionStartIndex, currentSelectionEndIndex);
    final int skipEnd = max(currentSelectionStartIndex, currentSelectionEndIndex);
    for (int index = 0; index < selectables.length; index += 1) {
      if (index >= skipStart && index <= skipEnd) {
        continue;
      }
      dispatchSelectionEventToChild(selectables[index], const ClearSelectionEvent());
    }
  }

  /// Selects all contents of all selectables.
  @protected
  SelectionResult handleSelectAll(SelectAllSelectionEvent event) {
    SelectionResult _handleSelectAll(SelectAllSelectionEvent event) {
      for (final Selectable selectable in selectables) {
        dispatchSelectionEventToChild(selectable, event);
      }
      currentSelectionStartIndex = 0;
      currentSelectionEndIndex = selectables.length - 1;
      return SelectionResult.none;
    }
    final SelectionResult result = _handleSelectAll(event);
    for (final Selectable selectable in selectables) {
      _hasReceivedStartEvent.add(selectable);
      _hasReceivedEndEvent.add(selectable);
    }
    // Synthesize last update event so the edge updates continue to work.
    _updateLastEdgeEventsFromGeometries();
    return result;
  }

  SelectionResult _handleSelectBoundary(SelectionEvent event) {
    late final Offset effectiveGlobalPosition;
    if (event.type == SelectionEventType.selectWord) {
      effectiveGlobalPosition = (event as SelectWordSelectionEvent).globalPosition;
    } else if (event.type == SelectionEventType.selectParagraph) {
      effectiveGlobalPosition = (event as SelectParagraphSelectionEvent).globalPosition;
    }
    SelectionResult? lastSelectionResult;
    for (int index = 0; index < selectables.length; index += 1) {
      bool globalRectsContainsPosition = false;
      if (selectables[index].boundingBoxes.isNotEmpty) {
        for (final Rect rect in selectables[index].boundingBoxes) {
          final Rect globalRect = MatrixUtils.transformRect(selectables[index].getTransformTo(null), rect);
          if (globalRect.contains(effectiveGlobalPosition)) {
            globalRectsContainsPosition = true;
            break;
          }
        }
      }
      if (globalRectsContainsPosition) {
        final SelectionGeometry existingGeometry = selectables[index].value;
        lastSelectionResult = dispatchSelectionEventToChild(selectables[index], event);
        if (index == selectables.length - 1 && lastSelectionResult == SelectionResult.next) {
          return SelectionResult.next;
        }
        if (lastSelectionResult == SelectionResult.next) {
          continue;
        }
        if (index == 0 && lastSelectionResult == SelectionResult.previous) {
          return SelectionResult.previous;
        }
        if (selectables[index].value != existingGeometry) {
          // Geometry has changed as a result of select word, need to clear the
          // selection of other selectables to keep selection in sync.
          selectables
            .where((Selectable target) => target != selectables[index])
            .forEach((Selectable target) => dispatchSelectionEventToChild(target, const ClearSelectionEvent()));
          currentSelectionStartIndex = currentSelectionEndIndex = index;
        }
        return SelectionResult.end;
      } else {
        if (lastSelectionResult == SelectionResult.next) {
          currentSelectionStartIndex = currentSelectionEndIndex = index - 1;
          return SelectionResult.end;
        }
      }
    }
    assert(lastSelectionResult == null);
    return SelectionResult.end;
  }

  /// Selects a word in a selectable at the location
  /// [SelectWordSelectionEvent.globalPosition].
  @protected
  SelectionResult handleSelectWord(SelectWordSelectionEvent event) {
    SelectionResult _handleSelectWord(SelectWordSelectionEvent event) {
      return _handleSelectBoundary(event);
    }
    final SelectionResult result = _handleSelectWord(event);
    if (currentSelectionStartIndex != -1) {
      _hasReceivedStartEvent.add(selectables[currentSelectionStartIndex]);
    }
    if (currentSelectionEndIndex != -1) {
      _hasReceivedEndEvent.add(selectables[currentSelectionEndIndex]);
    }
    _updateLastEdgeEventsFromGeometries();
    return result;
  }

  /// Selects a paragraph in a selectable at the location
  /// [SelectParagraphSelectionEvent.globalPosition].
  @protected
  SelectionResult handleSelectParagraph(SelectParagraphSelectionEvent event) {
    final SelectionResult result = _handleSelectParagraph(event);
    if (currentSelectionStartIndex != -1) {
      _hasReceivedStartEvent.add(selectables[currentSelectionStartIndex]);
    }
    if (currentSelectionEndIndex != -1) {
      _hasReceivedEndEvent.add(selectables[currentSelectionEndIndex]);
    }
    _updateLastEdgeEventsFromGeometries();
    return result;
  }

  SelectionResult _handleSelectParagraph(SelectParagraphSelectionEvent event) {
    // First pass, if the position is on a placeholder then dispatch the selection
    // event to the [Selectable] at the location and terminate.
    for (int index = 0; index < selectables.length; index += 1) {
      bool globalRectsContainsPosition = false;
      if (selectables[index].boundingBoxes.isNotEmpty) {
        for (final Rect rect in selectables[index].boundingBoxes) {
          final Rect globalRect = MatrixUtils.transformRect(selectables[index].getTransformTo(null), rect);
          if (globalRect.contains(event.globalPosition)) {
            globalRectsContainsPosition = true;
            break;
          }
        }
      }
      if (globalRectsContainsPosition) {
        if (paragraph.selectables != null && !paragraph.selectables!.contains(selectables[index])) {
          currentSelectionStartIndex = currentSelectionEndIndex = index;
          return dispatchSelectionEventToChild(selectables[index], event);
        }
        break;
      }
    }

    SelectionResult? lastSelectionResult;
    bool foundStart = false;
    for (int index = 0; index < selectables.length; index += 1) {
      if (paragraph.selectables != null && !paragraph.selectables!.contains(selectables[index])) {
        if (foundStart) {
          final SelectionResult result = dispatchSelectionEventToChild(selectables[index], SelectAllSelectionEvent());
          if (selectables.length - 1 == index) {
            currentSelectionEndIndex = index;
            _flushInactiveSelections();
            return result;
          }
        }
        continue;
      }
      final SelectionGeometry existingGeometry = selectables[index].value;
      lastSelectionResult = dispatchSelectionEventToChild(selectables[index], event);
      if (index == selectables.length - 1 && lastSelectionResult == SelectionResult.next) {
        return SelectionResult.next;
      }
      if (lastSelectionResult == SelectionResult.next) {
        if (selectables[index].value != existingGeometry && !foundStart) {
          currentSelectionStartIndex = index;
          foundStart = true;
        }
        continue;
      }
      if (index == 0 && lastSelectionResult == SelectionResult.previous) {
        return SelectionResult.previous;
      }
      if (selectables[index].value != existingGeometry) {
        currentSelectionEndIndex = index;
        // Geometry has changed as a result of select paragraph, need to clear the
        // selection of other selectables to keep selection in sync.
        _flushInactiveSelections();
      }
      return SelectionResult.end;
    }
    assert(lastSelectionResult == null);
    return SelectionResult.end;
  }

  /// Removes the selection of all selectables this delegate manages.
  @protected
  SelectionResult handleClearSelection(ClearSelectionEvent event) {
    SelectionResult _handleClearSelection(ClearSelectionEvent event) {
      for (final Selectable selectable in selectables) {
        dispatchSelectionEventToChild(selectable, event);
      }
      currentSelectionEndIndex = -1;
      currentSelectionStartIndex = -1;
      return SelectionResult.none;
    }
    final SelectionResult result = _handleClearSelection(event);
    _hasReceivedStartEvent.clear();
    _hasReceivedEndEvent.clear();
    _lastStartEdgeUpdateGlobalPosition = null;
    _lastEndEdgeUpdateGlobalPosition = null;
    return result;
  }

  /// Extend current selection in a certain text granularity.
  @protected
  SelectionResult handleGranularlyExtendSelection(GranularlyExtendSelectionEvent event) {
    assert((currentSelectionStartIndex == -1) == (currentSelectionEndIndex == -1));
    if (currentSelectionStartIndex == -1) {
      if (event.forward) {
        currentSelectionStartIndex = currentSelectionEndIndex = 0;
      } else {
        currentSelectionStartIndex = currentSelectionEndIndex = selectables.length;
      }
    }
    int targetIndex = event.isEnd ? currentSelectionEndIndex : currentSelectionStartIndex;
    SelectionResult result = dispatchSelectionEventToChild(selectables[targetIndex], event);
    if (event.forward) {
      assert(result != SelectionResult.previous);
      while (targetIndex < selectables.length - 1 && result == SelectionResult.next) {
        targetIndex += 1;
        result = dispatchSelectionEventToChild(selectables[targetIndex], event);
        assert(result != SelectionResult.previous);
      }
    } else {
      assert(result != SelectionResult.next);
      while (targetIndex > 0 && result == SelectionResult.previous) {
        targetIndex -= 1;
        result = dispatchSelectionEventToChild(selectables[targetIndex], event);
        assert(result != SelectionResult.next);
      }
    }
    if (event.isEnd) {
      currentSelectionEndIndex = targetIndex;
    } else {
      currentSelectionStartIndex = targetIndex;
    }
    return result;
  }

  /// Extend current selection in a certain text granularity.
  @protected
  SelectionResult handleDirectionallyExtendSelection(DirectionallyExtendSelectionEvent event) {
    assert((currentSelectionStartIndex == -1) == (currentSelectionEndIndex == -1));
    if (currentSelectionStartIndex == -1) {
      switch (event.direction) {
        case SelectionExtendDirection.previousLine:
        case SelectionExtendDirection.backward:
          currentSelectionStartIndex = currentSelectionEndIndex = selectables.length;
        case SelectionExtendDirection.nextLine:
        case SelectionExtendDirection.forward:
        currentSelectionStartIndex = currentSelectionEndIndex = 0;
      }
    }
    int targetIndex = event.isEnd ? currentSelectionEndIndex : currentSelectionStartIndex;
    SelectionResult result = dispatchSelectionEventToChild(selectables[targetIndex], event);
    switch (event.direction) {
      case SelectionExtendDirection.previousLine:
        assert(result == SelectionResult.end || result == SelectionResult.previous);
        if (result == SelectionResult.previous) {
          if (targetIndex > 0) {
            targetIndex -= 1;
            result = dispatchSelectionEventToChild(
              selectables[targetIndex],
              event.copyWith(direction: SelectionExtendDirection.backward),
            );
            assert(result == SelectionResult.end);
          }
        }
      case SelectionExtendDirection.nextLine:
        assert(result == SelectionResult.end || result == SelectionResult.next);
        if (result == SelectionResult.next) {
          if (targetIndex < selectables.length - 1) {
            targetIndex += 1;
            result = dispatchSelectionEventToChild(
              selectables[targetIndex],
              event.copyWith(direction: SelectionExtendDirection.forward),
            );
            assert(result == SelectionResult.end);
          }
        }
      case SelectionExtendDirection.forward:
      case SelectionExtendDirection.backward:
        assert(result == SelectionResult.end);
    }
    if (event.isEnd) {
      currentSelectionEndIndex = targetIndex;
    } else {
      currentSelectionStartIndex = targetIndex;
    }
    return result;
  }

  /// Updates the selection edges.
  @protected
  SelectionResult handleSelectionEdgeUpdate(SelectionEdgeUpdateEvent event) {
    if (event.type == SelectionEventType.endEdgeUpdate) {
      _lastEndEdgeUpdateGlobalPosition = event.globalPosition;
      return currentSelectionEndIndex == -1 ? _initSelection(event, isEnd: true) : _adjustSelection(event, isEnd: true);
    }
    _lastStartEdgeUpdateGlobalPosition = event.globalPosition;
    return currentSelectionStartIndex == -1 ? _initSelection(event, isEnd: false) : _adjustSelection(event, isEnd: false);
  }

  @override
  SelectionResult dispatchSelectionEvent(SelectionEvent event) {
    _isHandlingSelectionEvent = true;
    late SelectionResult result;
    switch (event.type) {
      case SelectionEventType.startEdgeUpdate:
      case SelectionEventType.endEdgeUpdate:
        _extendSelectionInProgress = false;
        result = handleSelectionEdgeUpdate(event as SelectionEdgeUpdateEvent);
      case SelectionEventType.clear:
        _extendSelectionInProgress = false;
        result = handleClearSelection(event as ClearSelectionEvent);
      case SelectionEventType.selectAll:
        _extendSelectionInProgress = false;
        result = handleSelectAll(event as SelectAllSelectionEvent);
      case SelectionEventType.selectWord:
        _extendSelectionInProgress = false;
        result = handleSelectWord(event as SelectWordSelectionEvent);
      case SelectionEventType.selectParagraph:
        _extendSelectionInProgress = false;
        result = handleSelectParagraph(event as SelectParagraphSelectionEvent);
      case SelectionEventType.granularlyExtendSelection:
        _extendSelectionInProgress = true;
        result = handleGranularlyExtendSelection(event as GranularlyExtendSelectionEvent);
      case SelectionEventType.directionallyExtendSelection:
        _extendSelectionInProgress = true;
        result = handleDirectionallyExtendSelection(event as DirectionallyExtendSelectionEvent);
    }
    _isHandlingSelectionEvent = false;
    _updateSelectionGeometry();
    return result;
  }

  @override
  void dispose() {
    _hasReceivedStartEvent.clear();
    _hasReceivedEndEvent.clear();
    for (final Selectable selectable in selectables) {
      selectable.removeListener(_handleSelectableGeometryChange);
    }
    selectables = const <Selectable>[];
    _scheduledSelectableUpdate = false;
    super.dispose();
  }

  /// Ensures the selectable child has received up to date selection event.
  ///
  /// This method is called when a new [Selectable] is added to the delegate,
  /// and its screen location falls into the previous selection.
  ///
  /// Subclasses are responsible for updating the selection of this newly added
  /// [Selectable].
  @protected
  void ensureChildUpdated(Selectable selectable) {
    if (_lastEndEdgeUpdateGlobalPosition != null && _hasReceivedEndEvent.add(selectable)) {
      final SelectionEdgeUpdateEvent synthesizedEvent = SelectionEdgeUpdateEvent.forEnd(
        globalPosition: _lastEndEdgeUpdateGlobalPosition!,
      );
      if (currentSelectionEndIndex == -1) {
        handleSelectionEdgeUpdate(synthesizedEvent);
      }
      selectable.dispatchSelectionEvent(synthesizedEvent);
    }
    if (_lastStartEdgeUpdateGlobalPosition != null && _hasReceivedStartEvent.add(selectable)) {
      final SelectionEdgeUpdateEvent synthesizedEvent = SelectionEdgeUpdateEvent.forStart(
          globalPosition: _lastStartEdgeUpdateGlobalPosition!,
      );
      if (currentSelectionStartIndex == -1) {
        handleSelectionEdgeUpdate(synthesizedEvent);
      }
      selectable.dispatchSelectionEvent(synthesizedEvent);
    }
  }

  /// Dispatches a selection event to a specific selectable.
  ///
  /// Override this method if subclasses need to generate additional events or
  /// treatments prior to sending the selection events.
  @protected
  SelectionResult dispatchSelectionEventToChild(Selectable selectable, SelectionEvent event) {
    switch (event.type) {
      case SelectionEventType.startEdgeUpdate:
        _hasReceivedStartEvent.add(selectable);
        ensureChildUpdated(selectable);
      case SelectionEventType.endEdgeUpdate:
        _hasReceivedEndEvent.add(selectable);
        ensureChildUpdated(selectable);
      case SelectionEventType.clear:
        _hasReceivedStartEvent.remove(selectable);
        _hasReceivedEndEvent.remove(selectable);
      case SelectionEventType.selectAll:
      case SelectionEventType.selectWord:
      case SelectionEventType.selectParagraph:
        break;
      case SelectionEventType.granularlyExtendSelection:
      case SelectionEventType.directionallyExtendSelection:
        _hasReceivedStartEvent.add(selectable);
        _hasReceivedEndEvent.add(selectable);
        ensureChildUpdated(selectable);
    }
    return selectable.dispatchSelectionEvent(event);
  }

  /// Initializes the selection of the selectable children.
  ///
  /// The goal is to find the selectable child that contains the selection edge.
  /// Returns [SelectionResult.end] if the selection edge ends on any of the
  /// children. Otherwise, it returns [SelectionResult.previous] if the selection
  /// does not reach any of its children. Returns [SelectionResult.next]
  /// if the selection reaches the end of its children.
  ///
  /// Ideally, this method should only be called twice at the beginning of the
  /// drag selection, once for start edge update event, once for end edge update
  /// event.
  SelectionResult _initSelection(SelectionEdgeUpdateEvent event, {required bool isEnd}) {
    assert((isEnd && currentSelectionEndIndex == -1) || (!isEnd && currentSelectionStartIndex == -1));
    int newIndex = -1;
    bool hasFoundEdgeIndex = false;
    SelectionResult? result;
    for (int index = 0; index < selectables.length && !hasFoundEdgeIndex; index += 1) {
      final Selectable child = selectables[index];
      final SelectionResult childResult = dispatchSelectionEventToChild(child, event);
      switch (childResult) {
        case SelectionResult.next:
        case SelectionResult.none:
          newIndex = index;
        case SelectionResult.end:
          newIndex = index;
          result = SelectionResult.end;
          hasFoundEdgeIndex = true;
        case SelectionResult.previous:
          hasFoundEdgeIndex = true;
          if (index == 0) {
            newIndex = 0;
            result = SelectionResult.previous;
          }
          result ??= SelectionResult.end;
        case SelectionResult.pending:
          newIndex = index;
          result = SelectionResult.pending;
          hasFoundEdgeIndex = true;
      }
    }

    if (newIndex == -1) {
      assert(selectables.isEmpty);
      return SelectionResult.none;
    }
    if (isEnd) {
      currentSelectionEndIndex = newIndex;
    } else {
      currentSelectionStartIndex = newIndex;
    }
    _flushInactiveSelections();
    // The result can only be null if the loop went through the entire list
    // without any of the selection returned end or previous. In this case, the
    // caller of this method needs to find the next selectable in their list.
    return result ?? SelectionResult.next;
  }

  /// Adjusts the selection based on the drag selection update event if there
  /// is already a selectable child that contains the selection edge.
  ///
  /// This method starts by sending the selection event to the current
  /// selectable that contains the selection edge, and finds forward or backward
  /// if that selectable no longer contains the selection edge.
  SelectionResult _adjustSelection(SelectionEdgeUpdateEvent event, {required bool isEnd}) {
    assert(() {
      if (isEnd) {
        assert(currentSelectionEndIndex < selectables.length && currentSelectionEndIndex >= 0);
        return true;
      }
      assert(currentSelectionStartIndex < selectables.length && currentSelectionStartIndex >= 0);
      return true;
    }());
    SelectionResult? finalResult;
    // Determines if the edge being adjusted is within the current viewport.
    //  - If so, we begin the search for the new selection edge position at the
    //    currentSelectionEndIndex/currentSelectionStartIndex.
    //  - If not, we attempt to locate the new selection edge starting from
    //    the opposite end.
    //  - If neither edge is in the current viewport, the search for the new
    //    selection edge position begins at 0.
    //
    // This can happen when there is a scrollable child and the edge being adjusted
    // has been scrolled out of view.
    final bool isCurrentEdgeWithinViewport = isEnd ? _selectionGeometry.endSelectionPoint != null : _selectionGeometry.startSelectionPoint != null;
    final bool isOppositeEdgeWithinViewport = isEnd ? _selectionGeometry.startSelectionPoint != null : _selectionGeometry.endSelectionPoint != null;
    int newIndex = switch ((isEnd, isCurrentEdgeWithinViewport, isOppositeEdgeWithinViewport)) {
      (true, true, true) => currentSelectionStartIndex,
      (true, true, false) => 0,
      (true, false, true) => currentSelectionStartIndex,
      (true, false, false) => 0,
      (false, true, true) => currentSelectionEndIndex,
      (false, true, false) => currentSelectionEndIndex,
      (false, false, true) => 0,
      (false, false, false) => 0,
    };
    bool? forward;
    late SelectionResult currentSelectableResult;
    bool foundStart = false;
    // This loop sends the selection event to one of the following to determine
    // the direction of the search.
    //  - currentSelectionEndIndex/currentSelectionStartIndex if the current edge
    //    is in the current viewport.
    //  - The opposite edge index if the current edge is not in the current viewport.
    //  - Index 0 if neither edge is in the current viewport.
    //
    // If the result is `SelectionResult.next`, this loop look backward.
    // Otherwise, it looks forward.
    //
    // The terminate condition are:
    // 1. the selectable returns end, pending, none.
    // 2. the selectable returns previous when looking forward.
    // 2. the selectable returns next when looking backward.
    debugPrint('start at $newIndex');
    while (newIndex < selectables.length && newIndex >= 0 && finalResult == null) {
      debugPrint('adjustSelection newIndex ${selectables[newIndex]}');
      // if (paragraph.selectables != null && !paragraph.selectables!.contains(selectables[newIndex])) {
      //   if (foundStart) {
      //     dispatchSelectionEventToChild(selectables[newIndex], SelectAllSelectionEvent());
      //   }
      //   newIndex += 1;
      //   continue;
      // }
      if (paragraph.selectables != null && !paragraph.selectables!.contains(selectables[newIndex]) && foundStart) {
        debugPrint('ummmm');
        dispatchSelectionEventToChild(selectables[newIndex], SelectAllSelectionEvent());
        newIndex += 1;
        continue;
      }
      currentSelectableResult = dispatchSelectionEventToChild(selectables[newIndex], event);
      debugPrint('results $currentSelectableResult');
      switch (currentSelectableResult) {
        case SelectionResult.end:
        case SelectionResult.pending:
        case SelectionResult.none:
          finalResult = currentSelectableResult;
        case SelectionResult.next:
          if (selectables[newIndex].boundingBoxes.isNotEmpty) {
            for (final Rect rect in selectables[newIndex].boundingBoxes) {
              final Rect globalRect = MatrixUtils.transformRect(selectables[newIndex].getTransformTo(null), rect);
              if (globalRect.contains(event.globalPosition)) {
                debugPrint('found');
                foundStart = true;
                break;
              }
            }
          }
          if (forward == false) {
            newIndex += 1;
            finalResult = SelectionResult.end;
          } else if (newIndex == selectables.length - 1) {
            finalResult = currentSelectableResult;
          } else {
            // debugPrint('$newIndex ${selectables[newIndex]}');
            forward = true;
            newIndex += 1;
          }
        case SelectionResult.previous:
          if (forward ?? false) {
            newIndex -= 1;
            finalResult = SelectionResult.end;
          } else if (newIndex == 0) {
            finalResult = currentSelectableResult;
          } else {
            forward = false;
            newIndex -= 1;
          }
      }
    }
    if (isEnd) {
      currentSelectionEndIndex = newIndex;
    } else {
      currentSelectionStartIndex = newIndex;
    }
    _flushInactiveSelections();
    return finalResult!;
  }
}

class _SelectableSlot {
  const _SelectableSlot({
    required this.type,
    this.selectable,
  });
  final _SlotType type;
  final Selectable? selectable;
}

enum _SlotType {
  text,
  placeholder,
}