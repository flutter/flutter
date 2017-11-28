// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'debug.dart';
import 'theme.dart';

const Duration _kTransitionDuration = const Duration(milliseconds: 200);
const Curve _kTransitionCurve = Curves.fastOutSlowIn;

// See the InputDecorator.build method, where this is used.
class _InputDecoratorChildGlobalKey extends GlobalObjectKey {
  const _InputDecoratorChildGlobalKey(BuildContext value) : super(value);
}

/// Text and styles used to label an input field.
///
/// The [TextField] and [InputDecorator] classes use [InputDecoration] objects
/// to describe their decoration. (In fact, this class is merely the
/// configuration of an [InputDecorator], which does all the heavy lifting.)
///
/// See also:
///
///  * [TextField], which is a text input widget that uses an
///    [InputDecoration].
///  * [InputDecorator], which is a widget that draws an [InputDecoration]
///    around an arbitrary child widget.
///  * [Decoration] and [DecoratedBox], for drawing arbitrary decorations
///    around other widgets.
@immutable
class InputDecoration {
  /// Creates a bundle of text and styles used to label an input field.
  ///
  /// Sets the [isCollapsed] property to false. To create a decoration that does
  /// not reserve space for [labelText] or [errorText], use
  /// [InputDecoration.collapsed].
  const InputDecoration({
    this.icon,
    this.labelText,
    this.labelStyle,
    this.helperText,
    this.helperStyle,
    this.hintText,
    this.hintStyle,
    this.errorText,
    this.errorStyle,
    this.isDense: false,
    this.hideDivider: false,
    this.prefixText,
    this.prefixStyle,
    this.suffixText,
    this.suffixStyle,
    this.counterText,
    this.counterStyle,
  }) : isCollapsed = false;

  /// Creates a decoration that is the same size as the input field.
  ///
  /// This type of input decoration does not include a divider or an icon and
  /// does not reserve space for [labelText] or [errorText].
  ///
  /// Sets the [isCollapsed] property to true.
  const InputDecoration.collapsed({
    @required this.hintText,
    this.hintStyle,
  }) : icon = null,
       labelText = null,
       labelStyle = null,
       helperText = null,
       helperStyle = null,
       errorText = null,
       errorStyle = null,
       isDense = false,
       isCollapsed = true,
       hideDivider = true,
       prefixText = null,
       prefixStyle = null,
       suffixText = null,
       suffixStyle = null,
       counterText = null,
       counterStyle = null;

  /// An icon to show before the input field.
  ///
  /// The size and color of the icon is configured automatically using an
  /// [IconTheme] and therefore does not need to be explicitly given in the
  /// icon widget.
  ///
  /// See [Icon], [ImageIcon].
  final Widget icon;

  /// Text that describes the input field.
  ///
  /// When the input field is empty and unfocused, the label is displayed on
  /// top of the input field (i.e., at the same location on the screen where
  /// text my be entered in the input field). When the input field receives
  /// focus (or if the field is non-empty), the label moves above (i.e.,
  /// vertically adjacent to) the input field.
  final String labelText;

  /// The style to use for the [labelText] when the label is above (i.e.,
  /// vertically adjacent to) the input field.
  ///
  /// When the [labelText] is on top of the input field, the text uses the
  /// [hintStyle] instead.
  ///
  /// If null, defaults of a value derived from the base [TextStyle] for the
  /// input field and the current [Theme].
  final TextStyle labelStyle;

  /// Text that provides context about the field’s value, such as how the value
  /// will be used.
  ///
  /// If non-null, the text is displayed below the input field, in the same
  /// location as [errorText]. If a non-null [errorText] value is specified then
  /// the helper text is not shown.
  final String helperText;

  /// The style to use for the [helperText].
  final TextStyle helperStyle;

  /// Text that suggests what sort of input the field accepts.
  ///
  /// Displayed on top of the input field (i.e., at the same location on the
  /// screen where text my be entered in the input field) when the input field
  /// is empty and either (a) [labelText] is null or (b) the input field has
  /// focus.
  final String hintText;

  /// The style to use for the [hintText].
  ///
  /// Also used for the [labelText] when the [labelText] is displayed on
  /// top of the input field (i.e., at the same location on the screen where
  /// text my be entered in the input field).
  ///
  /// If null, defaults of a value derived from the base [TextStyle] for the
  /// input field and the current [Theme].
  final TextStyle hintStyle;

  /// Text that appears below the input field.
  ///
  /// If non-null, the divider that appears below the input field is red.
  final String errorText;

  /// The style to use for the [errorText].
  ///
  /// If null, defaults of a value derived from the base [TextStyle] for the
  /// input field and the current [Theme].
  final TextStyle errorStyle;

  /// Whether the input field is part of a dense form (i.e., uses less vertical
  /// space).
  ///
  /// Defaults to false.
  final bool isDense;

  /// Whether the decoration is the same size as the input field.
  ///
  /// A collapsed decoration cannot have [labelText], [errorText], an [icon], or
  /// a divider because those elements require extra space.
  ///
  /// To create a collapsed input decoration, use [InputDecoration..collapsed].
  final bool isCollapsed;

  /// Whether to hide the divider below the input field and above the error text.
  ///
  /// Defaults to false.
  final bool hideDivider;

  /// Optional text prefix to place on the line before the input.
  ///
  /// Uses the [prefixStyle]. Uses [hintStyle] if [prefixStyle] isn't
  /// specified. Prefix is not returned as part of the input.
  final String prefixText;

  /// The style to use for the [prefixText].
  ///
  /// If null, defaults to the [hintStyle].
  final TextStyle prefixStyle;

  /// Optional text suffix to place on the line after the input.
  ///
  /// Uses the [suffixStyle]. Uses [hintStyle] if [suffixStyle] isn't
  /// specified. Suffix is not returned as part of the input.
  final String suffixText;

  /// The style to use for the [suffixText].
  ///
  /// If null, defaults to the [hintStyle].
  final TextStyle suffixStyle;

  /// Optional text to place below the line as a character count.
  ///
  /// Rendered using [counterStyle]. Uses [helperStyle] if [counterStyle] is
  /// null.
  final String counterText;

  /// The style to use for the [counterText].
  ///
  /// If null, defaults to the [helperStyle].
  final TextStyle counterStyle;

  /// Creates a copy of this input decoration but with the given fields replaced
  /// with the new values.
  ///
  /// Always sets [isCollapsed] to false.
  InputDecoration copyWith({
    Widget icon,
    String labelText,
    TextStyle labelStyle,
    String helperText,
    TextStyle helperStyle,
    String hintText,
    TextStyle hintStyle,
    String errorText,
    TextStyle errorStyle,
    bool isDense,
    bool hideDivider,
    String prefixText,
    TextStyle prefixStyle,
    String suffixText,
    TextStyle suffixStyle,
    String counterText,
    TextStyle counterStyle,
  }) {
    return new InputDecoration(
      icon: icon ?? this.icon,
      labelText: labelText ?? this.labelText,
      labelStyle: labelStyle ?? this.labelStyle,
      helperText: helperText ?? this.helperText,
      helperStyle: helperStyle ?? this.helperStyle,
      hintText: hintText ?? this.hintText,
      hintStyle: hintStyle ?? this.hintStyle,
      errorText: errorText ?? this.errorText,
      errorStyle: errorStyle ?? this.errorStyle,
      isDense: isDense ?? this.isDense,
      hideDivider: hideDivider ?? this.hideDivider,
      prefixText: prefixText ?? this.prefixText,
      prefixStyle: prefixStyle ?? this.prefixStyle,
      suffixText: suffixText ?? this.suffixText,
      suffixStyle: suffixStyle ?? this.suffixStyle,
      counterText: counterText ?? this.counterText,
      counterStyle: counterStyle ?? this.counterStyle,
    );
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other.runtimeType != runtimeType)
      return false;
    final InputDecoration typedOther = other;
    return typedOther.icon == icon
        && typedOther.labelText == labelText
        && typedOther.labelStyle == labelStyle
        && typedOther.helperText == helperText
        && typedOther.helperStyle == helperStyle
        && typedOther.hintText == hintText
        && typedOther.hintStyle == hintStyle
        && typedOther.errorText == errorText
        && typedOther.errorStyle == errorStyle
        && typedOther.isDense == isDense
        && typedOther.isCollapsed == isCollapsed
        && typedOther.hideDivider == hideDivider
        && typedOther.prefixText == prefixText
        && typedOther.prefixStyle == prefixStyle
        && typedOther.suffixText == suffixText
        && typedOther.suffixStyle == suffixStyle
        && typedOther.counterText == counterText
        && typedOther.counterStyle == counterStyle;
  }

  @override
  int get hashCode {
    return hashValues(
      icon,
      labelText,
      labelStyle,
      helperText,
      helperStyle,
      hintText,
      hintStyle,
      errorText,
      errorStyle,
      isDense,
      isCollapsed,
      hideDivider,
      prefixText,
      prefixStyle,
      suffixText,
      suffixStyle,
      counterText,
      counterStyle,
    );
  }

  @override
  String toString() {
    final List<String> description = <String>[];
    if (icon != null)
      description.add('icon: $icon');
    if (labelText != null)
      description.add('labelText: "$labelText"');
    if (helperText != null)
      description.add('helperText: "$helperText"');
    if (hintText != null)
      description.add('hintText: "$hintText"');
    if (errorText != null)
      description.add('errorText: "$errorText"');
    if (isDense)
      description.add('isDense: $isDense');
    if (isCollapsed)
      description.add('isCollapsed: $isCollapsed');
    if (hideDivider)
      description.add('hideDivider: $hideDivider');
    if (prefixText != null)
      description.add('prefixText: $prefixText');
    if (prefixStyle != null)
      description.add('prefixStyle: $prefixStyle');
    if (suffixText != null)
      description.add('suffixText: $suffixText');
    if (suffixStyle != null)
      description.add('suffixStyle: $suffixStyle');
    if (counterText != null)
      description.add('counterText: $counterText');
    if (counterStyle != null)
      description.add('counterStyle: $counterStyle');
    return 'InputDecoration(${description.join(', ')})';
  }
}

/// Displays the visual elements of a Material Design text field around an
/// arbitrary widget.
///
/// Use [InputDecorator] to create widgets that look and behave like a
/// [TextField] but can be used to input information other than text.
///
/// The configuration of this widget is primarily provided in the form of an
/// [InputDecoration] object.
///
/// Requires one of its ancestors to be a [Material] widget.
///
/// See also:
///
///  * [TextField], which uses an [InputDecorator] to draw labels and other
///    visual elements around a text entry widget.
///  * [Decoration] and [DecoratedBox], for drawing arbitrary decorations
///    around other widgets.
class InputDecorator extends StatelessWidget {
  /// Creates a widget that displays labels and other visual elements similar
  /// to a [TextField].
  ///
  /// The [isFocused] and [isEmpty] arguments must not be null.
  const InputDecorator({
    Key key,
    @required this.decoration,
    this.baseStyle,
    this.textAlign,
    this.isFocused: false,
    this.isEmpty: false,
    this.child,
  }) : assert(isFocused != null),
       assert(isEmpty != null),
       super(key: key);

  /// The text and styles to use when decorating the child.
  final InputDecoration decoration;

  /// The style on which to base the label, hint, and error styles if the
  /// [decoration] does not provide explicit styles.
  ///
  /// If null, defaults to a text style from the current [Theme].
  final TextStyle baseStyle;

  /// How the text in the decoration should be aligned horizontally.
  final TextAlign textAlign;

  /// Whether the input field has focus.
  ///
  /// Determines the position of the label text and the color of the divider.
  ///
  /// Defaults to false.
  final bool isFocused;

  /// Whether the input field is empty.
  ///
  /// Determines the position of the label text and whether to display the hint
  /// text.
  ///
  /// Defaults to false.
  final bool isEmpty;

  /// The widget below this widget in the tree.
  final Widget child;

  static const double _kBottomBorderHeight = 1.0;
  static const double _kDensePadding = 4.0;
  static const double _kNormalPadding = 8.0;
  static const double _kDenseTopPadding = 8.0;
  static const double _kNormalTopPadding = 16.0;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(new DiagnosticsProperty<InputDecoration>('decoration', decoration));
    description.add(new DiagnosticsProperty<TextStyle>('baseStyle', baseStyle, defaultValue: null));
    description.add(new DiagnosticsProperty<bool>('isFocused', isFocused));
    description.add(new DiagnosticsProperty<bool>('isEmpty', isEmpty));
  }

  Color _getActiveColor(ThemeData themeData) {
    if (isFocused) {
      switch (themeData.brightness) {
        case Brightness.dark:
          return themeData.accentColor;
        case Brightness.light:
          return themeData.primaryColor;
      }
    }
    return themeData.hintColor;
  }

  Widget _buildContent(Color borderColor, double topPadding, bool isDense, Widget inputChild) {
    if (decoration.hideDivider) {
      return new Container(
        padding: new EdgeInsets.only(top: topPadding, bottom: _kNormalPadding),
        child: inputChild,
      );
    }

    return new AnimatedContainer(
      padding: new EdgeInsets.only(top: topPadding, bottom: _kNormalPadding - _kBottomBorderHeight),
      duration: _kTransitionDuration,
      curve: _kTransitionCurve,
      decoration: new BoxDecoration(
        border: new Border(
          bottom: new BorderSide(
            color: borderColor,
            width: _kBottomBorderHeight,
          ),
        ),
      ),
      child: inputChild,
    );
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    final ThemeData themeData = Theme.of(context);
    final double textScaleFactor = MediaQuery.of(context, nullOk: true)?.textScaleFactor ?? 1.0;

    final bool isDense = decoration.isDense;
    final bool isCollapsed = decoration.isCollapsed;
    assert(!isDense || !isCollapsed);

    final String labelText = decoration.labelText;
    final String helperText = decoration.helperText;
    final String counterText = decoration.counterText;
    final String hintText = decoration.hintText;
    final String errorText = decoration.errorText;

    // If we're not focused, there's no value, and labelText was provided,
    // then the label appears where the hint would. And we will not show
    // the hintText.
    final bool hasInlineLabel = !isFocused && labelText != null && isEmpty;

    final Color activeColor = _getActiveColor(themeData);

    final TextStyle baseStyle = themeData.textTheme.subhead.merge(this.baseStyle);
    final TextStyle hintStyle = baseStyle.copyWith(color: themeData.hintColor).merge(decoration.hintStyle);
    final TextStyle helperStyle = themeData.textTheme.caption.copyWith(color: themeData.hintColor).merge(decoration.helperStyle);
    final TextStyle counterStyle = helperStyle.merge(decoration.counterStyle);
    final TextStyle subtextStyle = errorText != null
      ? themeData.textTheme.caption.copyWith(color: themeData.errorColor).merge(decoration.errorStyle)
      : helperStyle;

    double topPadding = isCollapsed ? 0.0 : (isDense ?  _kDenseTopPadding : _kNormalTopPadding);

    final List<Widget> stackChildren = <Widget>[];

    if (labelText != null) {
      assert(!isCollapsed);
      final TextStyle floatingLabelStyle = themeData.textTheme.caption.copyWith(color: activeColor).merge(decoration.labelStyle);
      final TextStyle labelStyle = hasInlineLabel ? hintStyle : floatingLabelStyle;
      final double labelTextHeight = floatingLabelStyle.fontSize * textScaleFactor;

      final double topPaddingIncrement = labelTextHeight + (isDense ? _kDensePadding : _kNormalPadding);
      stackChildren.add(
        new AnimatedPositionedDirectional(
          start: 0.0,
          top: topPadding + (hasInlineLabel ? topPaddingIncrement : 0.0),
          duration: _kTransitionDuration,
          curve: _kTransitionCurve,
          child: new _AnimatedLabel(
            text: labelText,
            style: labelStyle,
            duration: _kTransitionDuration,
            curve: _kTransitionCurve,
          ),
        ),
      );

      topPadding += topPaddingIncrement;
    }

    if (hintText != null) {
      stackChildren.add(
        new AnimatedPositionedDirectional(
          start: 0.0,
          end: 0.0,
          top: topPadding,
          duration: _kTransitionDuration,
          curve: _kTransitionCurve,
          child: new AnimatedOpacity(
            opacity: (isEmpty && !hasInlineLabel) ? 1.0 : 0.0,
            duration: _kTransitionDuration,
            curve: _kTransitionCurve,
            child: new Text(
              hintText,
              style: hintStyle,
              overflow: TextOverflow.ellipsis,
              textAlign: textAlign,
            ),
          ),
        ),
      );
    }

    Widget inputChild = new KeyedSubtree(
      // It's important that we maintain the state of our child subtree, as it
      // may be stateful (e.g. containing text selections). Since our build
      // function risks changing the depth of the tree, we preserve the subtree
      // using global keys.
      // GlobalObjectKey(context) will always be the same whenever we are built.
      // Additionally, we use a subclass of GlobalObjectKey to avoid clashes
      // with anyone else using our BuildContext as their global object key
      // value.
      key: new _InputDecoratorChildGlobalKey(context),
      child: child,
    );

    if (!hasInlineLabel && (!isEmpty || hintText == null) &&
        (decoration?.prefixText != null || decoration?.suffixText != null)) {
      final List<Widget> rowContents = <Widget>[];
      if (decoration.prefixText != null) {
        rowContents.add(
            new Text(decoration.prefixText,
            style: decoration.prefixStyle ?? hintStyle)
        );
      }
      rowContents.add(new Expanded(child: inputChild));
      if (decoration.suffixText != null) {
        rowContents.add(
            new Text(decoration.suffixText,
            style: decoration.suffixStyle ?? hintStyle)
        );
      }
      inputChild = new Row(children: rowContents);
    }

    // The inputChild and the helper/error text need to be in a column so that if the inputChild is
    // a multiline input or a non-text widget, it lays out with the helper/error text below the
    // inputChild.
    final List<Widget> columnChildren = <Widget>[];
    if (isCollapsed) {
      columnChildren.add(inputChild);
    } else {
      final Color borderColor = errorText == null ? activeColor : themeData.errorColor;
      columnChildren.add(_buildContent(borderColor, topPadding, isDense, inputChild));
    }

    if (errorText != null || helperText != null || counterText != null) {
      assert(!isCollapsed, "Collapsed fields can't have errorText, helperText, or counterText set.");
      final EdgeInsets topPadding = new EdgeInsets.only(
        top: _kBottomBorderHeight + (isDense ? _kDensePadding : _kNormalPadding)
      );

      Widget buildSubText() {
        return new AnimatedContainer(
          padding: topPadding,
          duration: _kTransitionDuration,
          curve: _kTransitionCurve,
          child: new Text(
            errorText ?? helperText,
            style: subtextStyle,
            textAlign: textAlign,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }

      Widget buildCounter() {
        return new AnimatedContainer(
          padding: topPadding,
          duration: _kTransitionDuration,
          curve: _kTransitionCurve,
          child: new Text(
            counterText,
            style: counterStyle,
            textAlign: textAlign == TextAlign.end ? TextAlign.start : TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }

      final bool needSubTextField = errorText != null || helperText != null;
      final bool needCounterField = counterText != null;
      if (needCounterField && needSubTextField) {
        columnChildren.add(
          new Row(
            children: <Widget>[
              new Expanded(child: buildSubText()),
              buildCounter(),
            ],
          ),
        );
      } else if (needSubTextField) {
        columnChildren.add(buildSubText());
      } else if (needCounterField) {
        columnChildren.add(buildCounter());
      }
    }

    stackChildren.add(
      new Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: columnChildren,
      ),
    );

    final Widget stack = new Stack(
      fit: StackFit.passthrough,
      children: stackChildren
    );

    if (decoration.icon != null) {
      assert(!isCollapsed);
      final double iconSize = isDense ? 18.0 : 24.0;
      final double entryTextHeight = baseStyle.fontSize * textScaleFactor;
      final double iconTop = topPadding + (entryTextHeight - iconSize) / 2.0;
      return new Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          new AnimatedContainer(
            margin: new EdgeInsets.only(top: iconTop),
            duration: _kTransitionDuration,
            curve: _kTransitionCurve,
            width: isDense ? 40.0 : 48.0,
            child: IconTheme.merge(
              data: new IconThemeData(
                color: isFocused ? activeColor : Colors.black45,
                size: iconSize,
              ),
              child: decoration.icon,
            ),
          ),
          new Expanded(child: stack),
        ],
      );
    } else {
      return new ConstrainedBox(
        constraints: const BoxConstraints(minWidth: double.INFINITY),
        child: stack,
      );
    }
  }
}

// Smoothly animate the label of an InputDecorator as the label
// transitions between inline and caption.
class _AnimatedLabel extends ImplicitlyAnimatedWidget {
  const _AnimatedLabel({
    Key key,
    this.text,
    @required this.style,
    Curve curve: Curves.linear,
    @required Duration duration,
    this.textAlign,
    this.overflow,
  }) : assert(style != null),
       super(key: key, curve: curve, duration: duration);

  final String text;
  final TextStyle style;
  final TextAlign textAlign;
  final TextOverflow overflow;

  @override
  _AnimatedLabelState createState() => new _AnimatedLabelState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    style?.debugFillProperties(description);
  }
}

class _AnimatedLabelState extends AnimatedWidgetBaseState<_AnimatedLabel> {
  TextStyleTween _style;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _style = visitor(_style, widget.style, (dynamic value) => new TextStyleTween(begin: value));
  }

  @override
  Widget build(BuildContext context) {
    TextStyle style = _style.evaluate(animation);
    double scale = 1.0;
    if (style.fontSize != widget.style.fontSize) {
      // While the fontSize is transitioning, use a scaled Transform as a
      // fraction of the original fontSize. That way we get a smooth scaling
      // effect with no snapping between discrete font sizes.
      scale = style.fontSize / widget.style.fontSize;
      style = style.copyWith(fontSize: widget.style.fontSize);
    }

    return new Transform(
      transform: new Matrix4.identity()..scale(scale),
      child: new Text(
        widget.text,
        style: style,
        textAlign: widget.textAlign,
        overflow: widget.overflow,
      ),
    );
  }
}
