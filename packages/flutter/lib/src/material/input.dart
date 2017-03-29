// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'debug.dart';
import 'icon.dart';
import 'icon_theme.dart';
import 'icon_theme_data.dart';
import 'text_selection.dart';
import 'theme.dart';

export 'package:flutter/services.dart' show TextInputType;

const Duration _kTransitionDuration = const Duration(milliseconds: 200);
const Curve _kTransitionCurve = Curves.fastOutSlowIn;

/// A simple undecorated text input field.
///
/// If you want decorations as specified in the Material spec (most likely),
/// use [Input] instead.
///
/// This widget is comparable to [Text] in that it does not include a margin
/// or any decoration outside the text itself. It is useful for applications,
/// like a search box, that don't need any additional decoration. It should
/// also be useful in custom widgets that support text input.
///
/// The [value] field must be updated each time the [onChanged] callback is
/// invoked. Be sure to include the full [value] provided by the [onChanged]
/// callback, or information like the current selection will be lost.
///
/// Requires one of its ancestors to be a [Material] widget.
///
/// See also:
///
/// * [Input], which adds a label, a divider below the text field, and support for
///   an error message.
/// * [EditableText], a text field that does not require [Material] design.
class InputField extends StatefulWidget {
  InputField({
    Key key,
    this.focusKey,
    this.value,
    this.keyboardType: TextInputType.text,
    this.hintText,
    this.style,
    this.hintStyle,
    this.obscureText: false,
    this.maxLines: 1,
    this.autofocus: false,
    this.onChanged,
    this.onSubmitted,
  }) : super(key: key);

  final GlobalKey focusKey;

  /// The current state of text of the input field. This includes the selected
  /// text, if any, among other things.
  final InputValue value;

  /// The type of keyboard to use for editing the text.
  final TextInputType keyboardType;

  /// Text to show inline in the input field when it would otherwise be empty.
  final String hintText;

  /// The style to use for the text being edited.
  final TextStyle style;

  /// The style to use for the hint text.
  ///
  /// Defaults to the specified TextStyle in style with the hintColor from
  /// the ThemeData
  final TextStyle hintStyle;

  /// Whether to hide the text being edited (e.g., for passwords).
  ///
  /// When this is set to true, all the characters in the input are replaced by
  /// U+2022 BULLET characters (•).
  ///
  /// Defaults to false.
  final bool obscureText;

  /// The maximum number of lines for the text to span, wrapping if necessary.
  /// If this is 1 (the default), the text will not wrap, but will scroll
  /// horizontally instead.
  final int maxLines;

  /// Whether this input field should focus itself if nothing else is already focused.
  ///
  /// Defaults to false.
  final bool autofocus;

  /// Called when the text being edited changes.
  ///
  /// The [value] must be updated each time [onChanged] is invoked.
  final ValueChanged<InputValue> onChanged;

  /// Called when the user indicates that they are done editing the text in the field.
  final ValueChanged<InputValue> onSubmitted;

  @override
  _InputFieldState createState() => new _InputFieldState();
}

class _InputFieldState extends State<InputField> {
  final GlobalKey<EditableTextState> _editableTextKey = new GlobalKey<EditableTextState>();
  final GlobalKey<EditableTextState> _focusKey = new GlobalKey(debugLabel: "_InputFieldState _focusKey");

  GlobalKey get focusKey => config.focusKey ?? (config.key is GlobalKey ? config.key : _focusKey);

  void requestKeyboard() {
    _editableTextKey.currentState?.requestKeyboard();
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    final InputValue value = config.value ?? InputValue.empty;
    final ThemeData themeData = Theme.of(context);
    final TextStyle textStyle = config.style ?? themeData.textTheme.subhead;

    final List<Widget> stackChildren = <Widget>[
      new GestureDetector(
        key: focusKey == _focusKey ? _focusKey : null,
        behavior: HitTestBehavior.opaque,
        onTap: requestKeyboard,
        // Since the focusKey may have been created here, defer building the
        // EditableText until the focusKey's context has been set. This is
        // necessary because the EditableText will check the focus, like
        // Focus.at(focusContext), when it builds.
        child: new Builder(
          builder: (BuildContext context) {
            return new EditableText(
              key: _editableTextKey,
              value: value,
              focusKey: focusKey,
              style: textStyle,
              obscureText: config.obscureText,
              maxLines: config.maxLines,
              autofocus: config.autofocus,
              cursorColor: themeData.textSelectionColor,
              selectionColor: themeData.textSelectionColor,
              selectionControls: materialTextSelectionControls,
              keyboardType: config.keyboardType,
              onChanged: config.onChanged,
              onSubmitted: config.onSubmitted,
            );
          }
        ),
      ),
    ];

    if (config.hintText != null && value.text.isEmpty) {
      final TextStyle hintStyle = config.hintStyle ??
        textStyle.copyWith(color: themeData.hintColor);
      stackChildren.add(
        new Positioned(
          left: 0.0,
          top: textStyle.fontSize - hintStyle.fontSize,
          child: new IgnorePointer(
            child: new Text(config.hintText, style: hintStyle),
          ),
        ),
      );
    }

    return new RepaintBoundary(child: new Stack(children: stackChildren));
  }
}

/// Displays the visual elements of a material design text field around an
/// arbitrary child widget.
///
/// Use InputContainer to create widgets that look and behave like the [Input]
/// widget.
///
/// Requires one of its ancestors to be a [Material] widget.
///
/// See also:
///
/// * [Input], which combines an [InputContainer] with an [InputField].
class InputContainer extends StatefulWidget {
  InputContainer({
    Key key,
    this.focused: false,
    this.isEmpty: false,
    this.icon,
    this.labelText,
    this.hintText,
    this.errorText,
    this.style,
    this.isDense: false,
    this.showDivider: true,
    this.child,
  }) : super(key: key);

  /// An icon to show adjacent to the input field.
  ///
  /// The size and color of the icon is configured automatically using an
  /// [IconTheme] and therefore does not need to be explicitly given in the
  /// icon widget.
  ///
  /// See [Icon], [ImageIcon].
  final Widget icon;

  /// Text that appears above the child or over it, if isEmpty is true.
  final String labelText;

  /// Text that appears over the child if isEmpty is true and labelText is null.
  final String hintText;

  /// Text that appears below the child. If errorText is non-null the divider
  /// that appears below the child is red.
  final String errorText;

  /// The style to use for the hint. It's also used for the label when the label
  /// appears over the child.
  final TextStyle style;

  /// Whether the input container is part of a dense form (i.e., uses less vertical space).
  ///
  /// Defaults to false.
  final bool isDense;

  /// True if the hint and label should be displayed as if the child had the focus.
  ///
  /// Defaults to false.
  final bool focused;

  /// Should the hint and label be displayed as if no value had been input
  /// to the child.
  ///
  /// Defaults to false.
  final bool isEmpty;

  /// Whether to show a divider below the child and above the error text.
  ///
  /// Defaults to true.
  final bool showDivider;

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  _InputContainerState createState() => new _InputContainerState();
}

class _InputContainerState extends State<InputContainer> {
  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    final ThemeData themeData = Theme.of(context);
    final String errorText = config.errorText;

    final TextStyle textStyle = config.style ?? themeData.textTheme.subhead;
    Color activeColor = themeData.hintColor;
    if (config.focused) {
      switch (themeData.brightness) {
        case Brightness.dark:
          activeColor = themeData.accentColor;
          break;
        case Brightness.light:
          activeColor = themeData.primaryColor;
          break;
      }
    }
    double topPadding = config.isDense ? 12.0 : 16.0;

    final List<Widget> stackChildren = <Widget>[];

    // If we're not focused, there's not value, and labelText was provided,
    // then the label appears where the hint would. And we will not show
    // the hintText.
    final bool hasInlineLabel = !config.focused && config.labelText != null && config.isEmpty;

    if (config.labelText != null) {
      final TextStyle labelStyle = hasInlineLabel ?
        textStyle.copyWith(color: themeData.hintColor) :
        themeData.textTheme.caption.copyWith(color: activeColor);

      final double topPaddingIncrement = themeData.textTheme.caption.fontSize + (config.isDense ? 4.0 : 8.0);
      double top = topPadding;
      if (hasInlineLabel)
        top += topPaddingIncrement + textStyle.fontSize - labelStyle.fontSize;

      stackChildren.add(
        new AnimatedPositioned(
          left: 0.0,
          top: top,
          duration: _kTransitionDuration,
          curve: _kTransitionCurve,
          child: new _AnimatedLabel(
            text: config.labelText,
            style: labelStyle,
            duration: _kTransitionDuration,
            curve: _kTransitionCurve,
          )
        ),
      );

      topPadding += topPaddingIncrement;
    }

    if (config.hintText != null) {
      final TextStyle hintStyle = textStyle.copyWith(color: themeData.hintColor);
      stackChildren.add(
        new Positioned(
          left: 0.0,
          top: topPadding + textStyle.fontSize - hintStyle.fontSize,
          child: new AnimatedOpacity(
            opacity: (config.isEmpty && !hasInlineLabel) ? 1.0 : 0.0,
            duration: _kTransitionDuration,
            curve: _kTransitionCurve,
            child: new IgnorePointer(
              child: new Text(config.hintText, style: hintStyle),
            ),
          ),
        ),
      );
    }

    final Color borderColor = errorText == null ? activeColor : themeData.errorColor;
    final double bottomPadding = config.isDense ? 8.0 : 1.0;
    final double bottomBorder = 2.0;
    final double bottomHeight = config.isDense ? 14.0 : 18.0;

    final EdgeInsets padding = new EdgeInsets.only(top: topPadding, bottom: bottomPadding);
    final Border border = new Border(
      bottom: new BorderSide(
        color: borderColor,
        width: bottomBorder,
      )
    );
    final EdgeInsets margin = new EdgeInsets.only(bottom: bottomHeight - (bottomPadding + bottomBorder));

    Widget divider;
    if (!config.showDivider) {
      divider = new Container(
        margin: margin + new EdgeInsets.only(bottom: bottomBorder),
        padding: padding,
        child: config.child,
      );
    } else {
      divider = new AnimatedContainer(
        margin: margin,
        padding: padding,
        duration: _kTransitionDuration,
        curve: _kTransitionCurve,
        decoration: new BoxDecoration(
          border: border,
        ),
        child: config.child,
      );
    }
    stackChildren.add(divider);

    if (!config.isDense) {
      final TextStyle errorStyle = themeData.textTheme.caption.copyWith(color: themeData.errorColor);
      stackChildren.add(new Positioned(
        left: 0.0,
        bottom: 0.0,
        child: new Text(errorText ?? '', style: errorStyle)
      ));
    }

    Widget textField = new Stack(children: stackChildren);

    if (config.icon != null) {
      final double iconSize = config.isDense ? 18.0 : 24.0;
      final double iconTop = topPadding + (textStyle.fontSize - iconSize) / 2.0;
      textField = new Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          new Container(
            margin: new EdgeInsets.only(top: iconTop),
            width: config.isDense ? 40.0 : 48.0,
            child: new IconTheme.merge(
              context: context,
              data: new IconThemeData(
                color: config.focused ? activeColor : Colors.black45,
                size: config.isDense ? 18.0 : 24.0
              ),
              child: config.icon
            )
          ),
          new Expanded(child: textField)
        ]
      );
    }

    return textField;
  }
}

/// A material design text input field.
///
/// The [value] field must be updated each time the [onChanged] callback is
/// invoked. Be sure to include the full [value] provided by the [onChanged]
/// callback, or information like the current selection will be lost.
///
/// Requires one of its ancestors to be a [Material] widget.
///
/// When using inside a [Form], consider using [TextField] instead.
///
/// Assuming that the input is already focused, the basic data flow for
/// retrieving user input is:
/// 1. User taps a character on the keyboard.
/// 2. The [onChanged] callback is called with the current [InputValue].
/// 3. Perform any necessary logic/validation on the current input value.
/// 4. Update the state of the [Input] widget accordingly through [State.setState].
///
/// For most cases, we recommend that you use the [Input] class within a
/// [StatefulWidget] so you can save and operate on the current value of the
/// input.
///
/// See also:
///
///  * <https://material.google.com/components/text-fields.html>
///  * [TextField], which simplifies steps 2-4 above.
class Input extends StatefulWidget {
  /// Creates a text input field.
  ///
  /// By default, the input uses a keyboard appropriate for text entry.
  //
  // If you change this constructor signature, please also update
  // InputContainer, TextField, InputField.
  Input({
    Key key,
    this.value,
    this.keyboardType: TextInputType.text,
    this.icon,
    this.labelText,
    this.hintText,
    this.errorText,
    this.style,
    this.obscureText: false,
    this.showDivider: true,
    this.isDense: false,
    this.autofocus: false,
    this.maxLines: 1,
    this.onChanged,
    this.onSubmitted,
  }) : super(key: key);

  /// The current state of text of the input field. This includes the selected
  /// text, if any, among other things.
  final InputValue value;

  /// The type of keyboard to use for editing the text.
  final TextInputType keyboardType;

  /// An icon to show adjacent to the input field.
  ///
  /// The size and color of the icon is configured automatically using an
  /// [IconTheme] and therefore does not need to be explicitly given in the
  /// icon widget.
  ///
  /// See [Icon], [ImageIcon].
  final Widget icon;

  /// Text to show above the input field.
  final String labelText;

  /// Text to show inline in the input field when it would otherwise be empty.
  final String hintText;

  /// Text to show when the input text is invalid.
  final String errorText;

  /// The style to use for the text being edited.
  final TextStyle style;

  /// Whether to hide the text being edited (e.g., for passwords).
  ///
  /// When this is set to true, all the characters in the input are replaced by
  /// U+2022 BULLET characters (•).
  ///
  /// Defaults to false.
  final bool obscureText;

  /// Whether to show a divider below the child and above the error text.
  ///
  /// Defaults to true.
  final bool showDivider;

  /// Whether the input field is part of a dense form (i.e., uses less vertical space).
  /// If true, [errorText] is not shown.
  ///
  /// Defaults to false.
  final bool isDense;

  /// Whether this input field should focus itself if nothing else is already focused.
  /// If true, the keyboard will open as soon as this input obtains focus. Otherwise,
  /// the keyboard is only shown after the user taps the text field.
  ///
  /// Defaults to false.
  // See https://github.com/flutter/flutter/issues/7035 for the rationale for this
  // keyboard behavior.
  final bool autofocus;

  /// The maximum number of lines for the text to span, wrapping if necessary.
  /// If this is 1 (the default), the text will not wrap, but will scroll
  /// horizontally instead.
  final int maxLines;

  /// Called when the text being edited changes.
  ///
  /// The [value] must be updated each time [onChanged] is invoked.
  final ValueChanged<InputValue> onChanged;

  /// Called when the user indicates that they are done editing the text in the field.
  final ValueChanged<InputValue> onSubmitted;

  @override
  _InputState createState() => new _InputState();
}

class _InputState extends State<Input> {
  final GlobalKey<_InputFieldState> _inputFieldKey = new GlobalKey<_InputFieldState>();
  final GlobalKey _focusKey = new GlobalKey();

  GlobalKey get focusKey => config.key is GlobalKey ? config.key : _focusKey;

  @override
  Widget build(BuildContext context) {
    return new GestureDetector(
      key: focusKey == _focusKey ? _focusKey : null,
      onTap: () {
        _inputFieldKey.currentState?.requestKeyboard();
      },
      // Since the focusKey may have been created here, defer building the
      // InputContainer until the focusKey's context has been set. This is
      // necessary because we're passing the value of Focus.at() along.
      child: new Builder(
        builder: (BuildContext context) {
          final bool focused = Focus.at(focusKey.currentContext, autofocus: config.autofocus);
          final bool isEmpty = (config.value ?? InputValue.empty).text.isEmpty;
          return new InputContainer(
            focused: focused,
            isEmpty: isEmpty,
            icon: config.icon,
            labelText: config.labelText,
            hintText: config.hintText,
            errorText: config.errorText,
            style: config.style,
            isDense: config.isDense,
            showDivider: config.showDivider,
            child: new InputField(
              key: _inputFieldKey,
              focusKey: focusKey,
              value: config.value,
              style: config.style,
              obscureText: config.obscureText,
              maxLines: config.maxLines,
              autofocus: config.autofocus,
              keyboardType: config.keyboardType,
              onChanged: config.onChanged,
              onSubmitted: config.onSubmitted,
            ),
          );
        },
      ),
    );
  }
}

/// A [FormField] that contains an [Input].
///
/// This is a convenience widget that simply wraps an [Input] widget in a
/// [FormField]. The [FormField] maintains the current value of the [Input] so
/// that you don't need to manage it yourself.
///
/// A [Form] ancestor is not required. The [Form] simply makes it easier to
/// save, reset, or validate multiple fields at once. To use without a [Form],
/// pass a [GlobalKey] to the constructor and use [GlobalKey.currentState] to
/// save or reset the form field.
///
/// To see the use of [TextField], compare these two ways of a implementing
/// a simple two text field form.
///
/// Using [TextField]:
///
/// ```dart
/// String _firstName, _lastName;
/// GlobalKey<FormState> _formKey = new GlobalKey<FormState>();
/// ...
/// new Form(
///   key: _formKey,
///   child: new Row(
///     children: <Widget>[
///       new TextField(
///         labelText: 'First Name',
///         onSaved: (InputValue value) { _firstName = value.text; }
///       ),
///       new TextField(
///         labelText: 'Last Name',
///         onSaved: (InputValue value) { _lastName = value.text; }
///       ),
///       new RaisedButton(
///         child: new Text('SUBMIT'),
///         // Instead of _formKey.currentState, you could wrap the
///         // RaisedButton in a Builder widget to get access to a BuildContext,
///         // and use Form.of(context).
///         onPressed: () { _formKey.currentState.save(); },
///       ),
///    )
///  )
/// ```
///
/// Using [Input] directly:
///
/// ```dart
/// String _firstName, _lastName;
/// InputValue _firstNameValue = const InputValue();
/// InputValue _lastNameValue = const InputValue();
/// ...
/// new Row(
///   children: <Widget>[
///     new Input(
///       value: _firstNameValue,
///       labelText: 'First Name',
///       onChanged: (InputValue value) { setState( () { _firstNameValue = value; } ); }
///     ),
///     new Input(
///       value: _lastNameValue,
///       labelText: 'Last Name',
///       onChanged: (InputValue value) { setState( () { _lastNameValue = value; } ); }
///     ),
///     new RaisedButton(
///       child: new Text('SUBMIT'),
///       onPressed: () {
///         _firstName = _firstNameValue.text;
///         _lastName = _lastNameValue.text;
///       },
///     ),
///  )
/// ```
class TextField extends FormField<InputValue> {
  TextField({
    Key key,
    GlobalKey focusKey,
    TextInputType keyboardType: TextInputType.text,
    Icon icon,
    String labelText,
    String hintText,
    TextStyle style,
    bool obscureText: false,
    bool isDense: false,
    bool autofocus: false,
    int maxLines: 1,
    InputValue initialValue: InputValue.empty,
    FormFieldSetter<InputValue> onSaved,
    FormFieldValidator<InputValue> validator,
    ValueChanged<InputValue> onChanged,
  }) : super(
    key: key,
    initialValue: initialValue,
    onSaved: onSaved,
    validator: validator,
    builder: (FormFieldState<InputValue> field) {
      return new Input(
        key: focusKey,
        keyboardType: keyboardType,
        icon: icon,
        labelText: labelText,
        hintText: hintText,
        style: style,
        obscureText: obscureText,
        isDense: isDense,
        autofocus: autofocus,
        maxLines: maxLines,
        value: field.value,
        onChanged: (InputValue value) {
          field.onChanged(value);
          if (onChanged != null)
            onChanged(value);
        },
        errorText: field.errorText,
      );
    },
  );
}

// Helper widget to smoothly animate the labelText of an Input, as it
// transitions between inline and caption.
class _AnimatedLabel extends ImplicitlyAnimatedWidget {
  _AnimatedLabel({
    Key key,
    this.text,
    this.style,
    Curve curve: Curves.linear,
    Duration duration,
  }) : super(key: key, curve: curve, duration: duration) {
    assert(style != null);
  }

  final String text;
  final TextStyle style;

  @override
  _AnimatedLabelState createState() => new _AnimatedLabelState();

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    '$style'.split('\n').forEach(description.add);
  }
}

class _AnimatedLabelState extends AnimatedWidgetBaseState<_AnimatedLabel> {
  TextStyleTween _style;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _style = visitor(_style, config.style, (dynamic value) => new TextStyleTween(begin: value));
  }

  @override
  Widget build(BuildContext context) {
    TextStyle style = _style.evaluate(animation);
    double scale = 1.0;
    if (style.fontSize != config.style.fontSize) {
      // While the fontSize is transitioning, use a scaled Transform as a
      // fraction of the original fontSize. That way we get a smooth scaling
      // effect with no snapping between discrete font sizes.
      scale = style.fontSize / config.style.fontSize;
      style = style.copyWith(fontSize: config.style.fontSize);
    }

    return new Transform(
      transform: new Matrix4.identity()..scale(scale),
      child: new Text(
        config.text,
        style: style,
      )
    );
  }
}
