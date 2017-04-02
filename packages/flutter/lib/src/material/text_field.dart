// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'input_decorator.dart';
import 'text_selection.dart';
import 'theme.dart';

export 'package:flutter/services.dart' show TextInputType;

const Duration _kTransitionDuration = const Duration(milliseconds: 200);
const Curve _kTransitionCurve = Curves.fastOutSlowIn;

/// A Material Design text field.
///
/// A text field lets the user enter text, either with hardware keyboard or with
/// an onscreen keyboard.
///
/// The text field calls the [onChanged] callback whenever the user changes the
/// text in the field. If the user indicates that they are done typing in the
/// field (e.g., by pressing a button on the soft keyboard), the text field
/// calls the [onSubmitted] callback.
///
/// To control the text that is displayed in the text field, use the
/// [controller]. For example, to set the initial value of the text field, use
/// a [controller] that already contains some text. The [controller] can also
/// control the selection and composing region (and to observe changes to the
/// text, selection, and composing region).
///
/// By default, a text field has a [decoration] that draws a divider below the
/// text field. You can use the [decoration] property to control the decoration,
/// for example by adding a label or an icon. If you set the [decoration]
/// property to null, the decoration will be removed entirely, including the
/// extra padding introduced by the decoration to save space for the labels.
///
/// If [decoration] is non-null (which is the default), the text field requires
/// one of its ancestors to be a [Material] widget.
///
/// To integrate the [TextField] into a [Form] with other [FormField] widgets,
/// consider using [TextFormField].
///
/// See also:
///
///  * <https://material.google.com/components/text-fields.html>
///  * [TextFormField], which integrates with the [Form] widget.
///  * [InputDecorator], which shows the labels and other visual elements that
///    surround the actual text editing widget.
///  * [EditableText], which is the raw text editing control at the heart of a
///    [TextField]. (The [EditableText] widget is rarely used directly unless
///    you are implementing an entirely different design language, such as
///    Cupertino.)
class TextField extends StatefulWidget {
  /// Creates a Material Design text field.
  ///
  /// If [decoration] is non-null (which is the default), the text field requires
  /// one of its ancestors to be a [Material] widget.
  ///
  /// To remove the decoration entirely (including the extra padding introduced
  /// by the decoration to save space for the labels), set the [decoration] to
  /// null.
  TextField({
    Key key,
    this.controller,
    this.focusNode,
    this.decoration: const InputDecoration(),
    this.keyboardType: TextInputType.text,
    this.style,
    this.textAlign,
    this.autofocus: false,
    this.obscureText: false,
    this.maxLines: 1,
    this.onChanged,
    this.onSubmitted,
  }) : super(key: key);

  /// Controls the text being edited.
  ///
  /// If null, this widget will creates its own [TextEditingController].
  final TextEditingController controller;

  /// Controls whether this widget has keyboard focus.
  ///
  /// If null, this widget will create its own [FocusNode].
  final FocusNode focusNode;

  /// The decoration to show around the text field.
  ///
  /// By default, draws a horizontal line under the text field but can be
  /// configured to show an icon, label, hint text, and error text.
  ///
  /// Set this field to null to remove the decoration entirely (including the
  /// extra padding introduced by the decoration to save space for the labels).
  final InputDecoration decoration;

  /// The type of keyboard to use for editing the text.
  final TextInputType keyboardType;

  /// The style to use for the text being edited.
  ///
  /// This text style is also used as the base style for the [decoration].
  ///
  /// If null, defaults to a text style from the current [Theme].
  final TextStyle style;

  /// How the text being edited should be aligned horizontally.
  final TextAlign textAlign;

  /// Whether this text field should focus itself if nothing else is already
  /// focused.
  ///
  /// If true, the keyboard will open as soon as this text field obtains focus.
  /// Otherwise, the keyboard is only shown after the user taps the text field.
  ///
  /// Defaults to false.
  // See https://github.com/flutter/flutter/issues/7035 for the rationale for this
  // keyboard behavior.
  final bool autofocus;

  /// Whether to hide the text being edited (e.g., for passwords).
  ///
  /// When this is set to true, all the characters in the text field are
  /// replaced by U+2022 BULLET characters (•).
  ///
  /// Defaults to false.
  final bool obscureText;

  /// The maximum number of lines for the text to span, wrapping if necessary.
  ///
  /// If this is 1 (the default), the text will not wrap, but will scroll
  /// horizontally instead.
  final int maxLines;

  /// Called when the text being edited changes.
  final ValueChanged<String> onChanged;

  /// Called when the user indicates that they are done editing the text in the
  /// field.
  final ValueChanged<String> onSubmitted;

  @override
  _TextFieldState createState() => new _TextFieldState();

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    if (controller != null)
      description.add('controller: $controller');
    if (focusNode != null)
      description.add('focusNode: $focusNode');
    description.add('decoration: $decoration');
    if (keyboardType != TextInputType.text)
      description.add('keyboardType: $keyboardType');
    if (style != null)
      description.add('style: $style');
    if (autofocus)
      description.add('autofocus: $autofocus');
    if (obscureText)
      description.add('obscureText: $obscureText');
    if (maxLines != 1)
      description.add('maxLines: $maxLines');
  }
}

class _TextFieldState extends State<TextField> {
  final GlobalKey<EditableTextState> _editableTextKey = new GlobalKey<EditableTextState>();

  TextEditingController _controller;
  TextEditingController get _effectiveController => config.controller ?? _controller;

  FocusNode _focusNode;
  FocusNode get _effectiveFocusNode => config.focusNode ?? (_focusNode ??= new FocusNode());

  @override
  void initState() {
    super.initState();
    if (config.controller == null)
      _controller = new TextEditingController();
  }

  @override
  void didUpdateConfig(TextField oldConfig) {
    if (config.controller == null && oldConfig.controller != null)
      _controller == new TextEditingController.fromValue(oldConfig.controller.value);
    else if (config.controller != null && oldConfig.controller == null)
      _controller = null;
  }

  @override
  void dispose() {
    _focusNode?.dispose();
    super.dispose();
  }

  void _requestKeyboard() {
    _editableTextKey.currentState?.requestKeyboard();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    final TextStyle style = config.style ?? themeData.textTheme.subhead;
    final TextEditingController controller = _effectiveController;
    final FocusNode focusNode = _effectiveFocusNode;

    Widget child = new RepaintBoundary(
      child: new EditableText(
        key: _editableTextKey,
        controller: controller,
        focusNode: focusNode,
        keyboardType: config.keyboardType,
        style: style,
        textAlign: config.textAlign,
        autofocus: config.autofocus,
        obscureText: config.obscureText,
        maxLines: config.maxLines,
        cursorColor: themeData.textSelectionColor,
        selectionColor: themeData.textSelectionColor,
        selectionControls: materialTextSelectionControls,
        onChanged: config.onChanged,
        onSubmitted: config.onSubmitted,
      ),
    );

    if (config.decoration != null) {
      child = new AnimatedBuilder(
        animation: new Listenable.merge(<Listenable>[ focusNode, controller ]),
        builder: (BuildContext context, Widget child) {
          return new InputDecorator(
            decoration: config.decoration,
            baseStyle: config.style,
            textAlign: config.textAlign,
            isFocused: focusNode.hasFocus,
            isEmpty: controller.value.text.isEmpty,
            child: child,
          );
        },
        child: child,
      );
    }

    return new GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _requestKeyboard,
      child: child,
    );
  }
}
