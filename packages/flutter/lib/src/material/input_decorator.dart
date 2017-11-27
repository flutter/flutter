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
    this.filled: false,
    this.fillColor,
    this.enabled: true,
  }) : assert(isDense != null),
       assert(hideDivider != null),
       assert(filled != null),
       assert(enabled != null),
       isCollapsed = false;

  /// Creates a decoration that is the same size as the input field.
  ///
  /// This type of input decoration does not include a divider or an icon and
  /// does not reserve space for [labelText] or [errorText].
  ///
  /// Sets the [isCollapsed] property to true.
  const InputDecoration.collapsed({
    @required this.hintText,
    this.hintStyle,
    this.filled: false,
    this.fillColor,
    this.enabled: true,
  }) : assert(filled != null),
       assert(enabled != null),
       icon = null,
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

  final bool filled;

  final Color fillColor;

  final bool enabled;

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
    bool filled,
    Color fillColor,
    bool enabled,
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
      filled: filled ?? this.filled,
      fillColor: fillColor ?? this.fillColor,
      enabled: enabled ?? this.enabled,
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
        && typedOther.counterStyle == counterStyle
        && typedOther.filled == filled
        && typedOther.fillColor == fillColor
        && typedOther.enabled == enabled;
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
      filled,
      fillColor,
      //enabled, hashValues supports 20 parameters
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
    if (filled)
      description.add('filled: true');
    if (fillColor != null)
      description.add('fillColor: $fillColor');
    if (!enabled)
      description.add('enabled: false');
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
  ///
  /// Typically an [EditableText], [DropdownButton], or [InkWell].
  final Widget child;

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

  Color _getFillColor(ThemeData themeData) {
    if (!decoration.filled)
      return null;
    if (decoration.fillColor != null)
      return decoration.fillColor;

    // dark theme: 10% white (enabled), 5% white (disabled)
    // light theme: 4% black (enabled), 2% black (disabled)
    const Color darkEnabled = const Color(0x1AFFFFFF);
    const Color darkDisabled = const Color(0x0DFFFFFF);
    const Color lightEnabled = const Color(0x0A000000);
    const Color lightDisabled = const Color(0x05000000);

    switch (themeData.brightness) {
      case Brightness.dark:
        return decoration.enabled ? darkEnabled : darkDisabled;
      case Brightness.light:
        return decoration.enabled ? lightEnabled : lightDisabled;
    }
    return lightEnabled;
  }

  // The style for the inline label or hint when they're displayed "inline", i.e.
  // when they appear in place of the empty text field.
  TextStyle _getInlineLabelStyle(ThemeData themeData) {
    return themeData.textTheme.subhead.merge(baseStyle)
      .copyWith(color: themeData.hintColor)
      .merge(decoration.hintStyle);
  }

  // The style for the label when it's displayed above the text is the
  // same as the inline label style except that the font's size is
  // 75% of the inline size and its color depends on the value of errorText.
  TextStyle _getFloatingLabelStyle(ThemeData themeData) {
    final Color color = decoration.errorText != null
      ? decoration.errorStyle?.color ?? themeData.errorColor
      : _getActiveColor(themeData);
    final TextStyle style = themeData.textTheme.subhead.merge(baseStyle);
    return style
      .copyWith(color: color, fontSize: style.fontSize * 0.75)
      .merge(decoration.labelStyle);
  }

  TextStyle _getHelperTextStyle(ThemeData themeData) {
    return themeData.textTheme.caption.copyWith(color: themeData.hintColor).merge(decoration.helperStyle);
  }

  TextStyle _getSubtextStyle(ThemeData themeData) {
    final TextStyle helperStyle = _getHelperTextStyle(themeData);
    return decoration.errorText != null
      ? themeData.textTheme.caption.copyWith(color: themeData.errorColor).merge(decoration.errorStyle)
      : helperStyle;
  }

  double get _dividerWeight {
    if (decoration.hideDivider || !decoration.enabled)
      return 0.0;
    return isFocused ? 2.0 : 1.0;
  }

  // True if the label will be shown and the hint will not.
  // If we're not focused, there's no value, and labelText was provided,
  // then the label appears where the hint would.
  bool get _hasInlineLabel => !isFocused && isEmpty && decoration.labelText != null;

  bool get _hasSubtext {
    return !decoration.isCollapsed &&
      (decoration.errorText != null || decoration.helperText != null || decoration.counterText != null);
  }


  // Build a baseline-aligned row, [prefix input/hint suffix], within a container
  // with the specified topPadding, decoration.fillColor in the background,
  // and the divider at the bottom.
  Widget _buildInput(BuildContext context, double topPadding, Widget inputChild) {
    final ThemeData themeData = Theme.of(context);
    final TextStyle hintStyle = _getInlineLabelStyle(themeData);
    final double dividerWeight = _dividerWeight;
    final Color dividerColor = decoration.errorText == null
      ? _getActiveColor(themeData)
      : themeData.errorColor;

    Widget content = inputChild;

    // The hint is stacked on top of the inputChild (which may be "empty")
    // because they both occupy the same location.
    if (decoration.hintText != null) {
      content = new Stack(
        children: <Widget>[
          inputChild,
          new PositionedDirectional(
            start: 0.0,
            bottom: 0.0,
            child: new AnimatedOpacity(
              opacity: (isEmpty && !_hasInlineLabel) ? 1.0 : 0.0,
              duration: _kTransitionDuration,
              curve: _kTransitionCurve,
              child: new Text(
                decoration.hintText,
                style: hintStyle,
                overflow: TextOverflow.ellipsis,
                textAlign: textAlign,
              ),
            ),
          ),
        ],
      );
    }

    // Add the prefix and suffix widgets
    if (!_hasInlineLabel && (!isEmpty || decoration.hintText == null)) {
      final Widget prefix = decoration.prefixText == null ? null :
        new Text(
          decoration.prefixText,
          style: decoration.prefixStyle ?? hintStyle
        );
      final Widget suffix = decoration.suffixText == null ? null :
        new Text(
          decoration.suffixText,
          style: decoration.suffixStyle ?? hintStyle
        );
      if ((prefix ?? suffix) != null) {
        final List<Widget> rowChildren = <Widget>[];
        if (prefix != null)
          rowChildren.add(prefix);
        rowChildren.add(new Expanded(child: content));
        if (suffix != null)
          rowChildren.add(suffix);
        content = new Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: rowChildren
        );
      }
    }

    // Wrap the content in an optionally filled container with the bottom
    // border serving as the divider.
    content = new AnimatedContainer(
      padding: decoration.isCollapsed ? EdgeInsets.zero : new EdgeInsetsDirectional.only(
        start: 12.0,
        end: 12.0,
        top: topPadding,
        bottom: (decoration.isDense ? 8.0 : 12.0) - dividerWeight,
      ),
      duration: _kTransitionDuration,
      curve: _kTransitionCurve,
      decoration: new BoxDecoration(
        color: _getFillColor(themeData),
        border: new Border(
          bottom: new BorderSide(
            color: dividerColor,
            width: dividerWeight,
          ),
        ),
      ),
      child: content,
    );

    return content;
  }

  List<Widget> _buildLabel(BuildContext context) {
    if (decoration.labelText == null)
      return const <Widget>[];

    final ThemeData themeData = Theme.of(context);
    final bool isFloating = !isEmpty || isFocused;

    EdgeInsets padding;
    if (isFloating) {
      padding = decoration.isDense
        ? const EdgeInsets.only(top: 8.0)
        : const EdgeInsets.only(top: 12.0);
    } else {
      padding = _hasSubtext
        ? new EdgeInsets.only(bottom: 8.0 + _getSubtextStyle(themeData).fontSize)
        : EdgeInsets.zero;
    }

    final Widget label = new PositionedDirectional(
      start: 12.0,
      end: 0.0,
      top: 0.0,
      bottom: 0.0,
      child: new AnimatedContainer(
        duration: _kTransitionDuration,
        curve: _kTransitionCurve,
        alignment: isFloating
          ? AlignmentDirectional.topStart
          : AlignmentDirectional.centerStart,
        padding: padding,
        child: new _AnimatedLabel(
          duration: _kTransitionDuration,
          curve: _kTransitionCurve,
          text: decoration.labelText,
          textAlign: textAlign,
          style: isFloating
            ? _getFloatingLabelStyle(themeData)
            : _getInlineLabelStyle(themeData),
        ),
      ),
    );

    return <Widget>[label];
  }

  // Return widgets that display the error or helper text and the counterText.
  // The tops of the returned widgets will be aligned with the bottom of
  // the inputChild (typically a text field) which is also the top of the
  // divider, if a divider is included.
  List<Widget> _buildSubtextAndCounter(BuildContext context) {
    final String helperText = decoration.helperText;
    final String counterText = decoration.counterText;
    final String errorText = decoration.errorText;
    if (errorText == null && helperText == null && counterText == null)
      return const <Widget>[];

    assert(!decoration.isCollapsed, "Collapsed fields can't have errorText, helperText, or counterText set.");

    final ThemeData themeData = Theme.of(context);

    final Widget errorOrHelp = (errorText ?? helperText) == null ? null :
      new AnimatedContainer(
        padding: const EdgeInsetsDirectional.only(start: 12.0, top: 8.0),
        duration: _kTransitionDuration,
        curve: _kTransitionCurve,
        child: new Text(
          errorText ?? helperText,
          style: _getSubtextStyle(themeData),
          textAlign: textAlign,
          overflow: TextOverflow.ellipsis,
        ),
      );

    final Widget counter = counterText == null ? null :
      new AnimatedContainer(
        padding: const EdgeInsetsDirectional.only(end: 0.0, top: 8.0),
        duration: _kTransitionDuration,
        curve: _kTransitionCurve,
        child: new Text(
          counterText,
          style: _getHelperTextStyle(themeData).merge(decoration.counterStyle),
          textAlign: textAlign == TextAlign.end ? TextAlign.start : TextAlign.end,
          overflow: TextOverflow.ellipsis,
        ),
      );

    if (counter == null)
      return <Widget>[errorOrHelp];
    else if (errorOrHelp == null)
      return <Widget>[counter];
    return <Widget>[
      new Row(
        children: <Widget>[
          new Expanded(child: errorOrHelp),
          counter,
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    final ThemeData themeData = Theme.of(context);
    final double textScaleFactor = MediaQuery.of(context, nullOk: true)?.textScaleFactor ?? 1.0;

    final bool isDense = decoration.isDense;
    final bool isCollapsed = decoration.isCollapsed;
    assert(!isDense || !isCollapsed);

    final Color activeColor = _getActiveColor(themeData);
    final TextStyle baseStyle = themeData.textTheme.subhead.merge(this.baseStyle);

    double topPadding = isCollapsed ? 0.0 : (isDense ? 8.0 : 12.0);
    if (decoration.labelText != null) {
      final double floatingLabelHeight = _getFloatingLabelStyle(themeData).fontSize * textScaleFactor;
      topPadding += floatingLabelHeight + 4.0; // 4.0 gap between label and text
    }

    final Widget inputChild = new KeyedSubtree(
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

    final Widget stack = new Stack(
      fit: StackFit.passthrough,
      children: <Widget>[]
        ..add(
          // The inputChild and the helper/error text need to be in a column
          // so that if the inputChild is a multiline input or a non-text widget,
          // it lays out with the helper/error text below the inputChild.
          new Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[]
              ..add(_buildInput(context, topPadding, inputChild))
              ..addAll(_buildSubtextAndCounter(context))
          )
        )
        ..addAll(_buildLabel(context))
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
