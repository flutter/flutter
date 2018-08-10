// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';


import 'text_selection.dart';

export 'package:flutter/services.dart' show TextInputType, TextInputAction;

class CupertinoTextField extends StatefulWidget {
  const CupertinoTextField({
    Key key,
    this.controller,
    this.focusNode,
    TextInputType keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.done,
    this.style,
    this.textAlign = TextAlign.start,
    this.autofocus = false,
    this.obscureText = false,
    this.autocorrect = true,
    this.maxLines = 1,
    this.maxLength,
    this.maxLengthEnforced = true,
    this.onChanged,
    this.onSubmitted,
    this.inputFormatters,
    this.enabled,
    this.cursorWidth = 2.0,
    this.cursorRadius,
    this.cursorColor,
    this.keyboardAppearance,
  }) : assert(keyboardType != null),
        assert(textInputAction != null),
        assert(textAlign != null),
        assert(autofocus != null),
        assert(obscureText != null),
        assert(autocorrect != null),
        assert(maxLengthEnforced != null),
        assert(maxLines == null || maxLines > 0),
        assert(maxLength == null || maxLength > 0),
        keyboardType = maxLines == 1 ? keyboardType : TextInputType.multiline,
        super(key: key);

  /// Controls the text being edited.
  ///
  /// If null, this widget will create its own [TextEditingController].
  final TextEditingController controller;

  /// Controls whether this widget has keyboard focus.
  ///
  /// If null, this widget will create its own [FocusNode].
  final FocusNode focusNode;

  /// The type of keyboard to use for editing the text.
  ///
  /// Defaults to [TextInputType.text]. Must not be null. If
  /// [maxLines] is not one, then [keyboardType] is ignored, and the
  /// [TextInputType.multiline] keyboard type is used.
  final TextInputType keyboardType;

  /// The type of action button to use for the keyboard.
  ///
  /// Defaults to [TextInputAction.done]. Must not be null.
  final TextInputAction textInputAction;

  /// The style to use for the text being edited.
  ///
  /// This text style is also used as the base style for the [decoration].
  ///
  /// If null, defaults to the `subhead` text style from the current [Theme].
  final TextStyle style;

  /// How the text being edited should be aligned horizontally.
  ///
  /// Defaults to [TextAlign.start].
  final TextAlign textAlign;

  /// Whether this text field should focus itself if nothing else is already
  /// focused.
  ///
  /// If true, the keyboard will open as soon as this text field obtains focus.
  /// Otherwise, the keyboard is only shown after the user taps the text field.
  ///
  /// Defaults to false. Cannot be null.
  // See https://github.com/flutter/flutter/issues/7035 for the rationale for this
  // keyboard behavior.
  final bool autofocus;

  /// Whether to hide the text being edited (e.g., for passwords).
  ///
  /// When this is set to true, all the characters in the text field are
  /// replaced by U+2022 BULLET characters (•).
  ///
  /// Defaults to false. Cannot be null.
  final bool obscureText;

  /// Whether to enable autocorrection.
  ///
  /// Defaults to true. Cannot be null.
  final bool autocorrect;

  /// The maximum number of lines for the text to span, wrapping if necessary.
  ///
  /// If this is 1 (the default), the text will not wrap, but will scroll
  /// horizontally instead.
  ///
  /// If this is null, there is no limit to the number of lines. If it is not
  /// null, the value must be greater than zero.
  final int maxLines;

  /// The maximum number of characters (Unicode scalar values) to allow in the
  /// text field.
  ///
  /// If set, a character counter will be displayed below the
  /// field, showing how many characters have been entered and how many are
  /// allowed. After [maxLength] characters have been input, additional input
  /// is ignored, unless [maxLengthEnforced] is set to false. The TextField
  /// enforces the length with a [LengthLimitingTextInputFormatter], which is
  /// evaluated after the supplied [inputFormatters], if any.
  ///
  /// This value must be either null or greater than zero. If set to null
  /// (the default), there is no limit to the number of characters allowed.
  ///
  /// Whitespace characters (e.g. newline, space, tab) are included in the
  /// character count.
  ///
  /// If [maxLengthEnforced] is set to false, then more than [maxLength]
  /// characters may be entered, but the error counter and divider will
  /// switch to the [decoration.errorStyle] when the limit is exceeded.
  ///
  /// ## Limitations
  ///
  /// The TextField does not currently count Unicode grapheme clusters (i.e.
  /// characters visible to the user), it counts Unicode scalar values, which
  /// leaves out a number of useful possible characters (like many emoji and
  /// composed characters), so this will be inaccurate in the presence of those
  /// characters. If you expect to encounter these kinds of characters, be
  /// generous in the maxLength used.
  ///
  /// For instance, the character "ö" can be represented as '\u{006F}\u{0308}',
  /// which is the letter "o" followed by a composed diaeresis "¨", or it can
  /// be represented as '\u{00F6}', which is the Unicode scalar value "LATIN
  /// SMALL LETTER O WITH DIAERESIS". In the first case, the text field will
  /// count two characters, and the second case will be counted as one
  /// character, even though the user can see no difference in the input.
  ///
  /// Similarly, some emoji are represented by multiple scalar values. The
  /// Unicode "THUMBS UP SIGN + MEDIUM SKIN TONE MODIFIER", "👍🏽", should be
  /// counted as a single character, but because it is a combination of two
  /// Unicode scalar values, '\u{1F44D}\u{1F3FD}', it is counted as two
  /// characters.
  ///
  /// See also:
  ///
  ///  * [LengthLimitingTextInputFormatter] for more information on how it
  ///    counts characters, and how it may differ from the intuitive meaning.
  final int maxLength;

  /// If true, prevents the field from allowing more than [maxLength]
  /// characters.
  ///
  /// If [maxLength] is set, [maxLengthEnforced] indicates whether or not to
  /// enforce the limit, or merely provide a character counter and warning when
  /// [maxLength] is exceeded.
  final bool maxLengthEnforced;

  /// Called when the text being edited changes.
  final ValueChanged<String> onChanged;

  /// Called when the user indicates that they are done editing the text in the
  /// field.
  final ValueChanged<String> onSubmitted;

  /// Optional input validation and formatting overrides.
  ///
  /// Formatters are run in the provided order when the text input changes.
  final List<TextInputFormatter> inputFormatters;

  /// If false the textfield is "disabled": it ignores taps and its
  /// [decoration] is rendered in grey.
  ///
  /// If non-null this property overrides the [decoration]'s
  /// [Decoration.enabled] property.
  final bool enabled;

  /// How thick the cursor will be.
  ///
  /// Defaults to 2.0.
  final double cursorWidth;

  /// How rounded the corners of the cursor should be.
  /// By default, the cursor has a null Radius
  final Radius cursorRadius;

  /// The color to use when painting the cursor.
  final Color cursorColor;

  /// The appearance of the keyboard.
  ///
  /// This setting is only honored on iOS devices.
  ///
  /// If unset, defaults to the brightness of [ThemeData.primaryColorBrightness].
  final Brightness keyboardAppearance;

  @override
  _CupertinoTextFieldState createState() => new _CupertinoTextFieldState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(new DiagnosticsProperty<TextEditingController>('controller', controller, defaultValue: null));
    properties.add(new DiagnosticsProperty<FocusNode>('focusNode', focusNode, defaultValue: null));
    properties.add(new DiagnosticsProperty<TextInputType>('keyboardType', keyboardType, defaultValue: TextInputType.text));
    properties.add(new DiagnosticsProperty<TextStyle>('style', style, defaultValue: null));
    properties.add(new DiagnosticsProperty<bool>('autofocus', autofocus, defaultValue: false));
    properties.add(new DiagnosticsProperty<bool>('obscureText', obscureText, defaultValue: false));
    properties.add(new DiagnosticsProperty<bool>('autocorrect', autocorrect, defaultValue: false));
    properties.add(new IntProperty('maxLines', maxLines, defaultValue: 1));
    properties.add(new IntProperty('maxLength', maxLength, defaultValue: null));
    properties.add(new FlagProperty('maxLengthEnforced', value: maxLengthEnforced, ifTrue: 'max length enforced'));
  }
}

class _CupertinoTextFieldState extends State<CupertinoTextField> {
  final GlobalKey<EditableTextState> _editableTextKey = new GlobalKey<EditableTextState>();

  TextEditingController _controller;
  TextEditingController get _effectiveController => widget.controller ?? _controller;

  FocusNode _focusNode;
  FocusNode get _effectiveFocusNode => widget.focusNode ?? (_focusNode ??= new FocusNode());

  bool get needsCounter => widget.maxLength != null;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null)
      _controller = new TextEditingController();
  }

  /*@override
  void didUpdateWidget(CupertinoTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller == null && oldWidget.controller != null)
      _controller = new TextEditingController.fromValue(oldWidget.controller.value);
    else if (widget.controller != null && oldWidget.controller == null)
      _controller = null;
    final bool isEnabled = widget.enabled ?? widget.decoration?.enabled ?? true;
    final bool wasEnabled = oldWidget.enabled ?? oldWidget.decoration?.enabled ?? true;
    if (wasEnabled && !isEnabled) {
      _effectiveFocusNode.unfocus();
    }
  }*/

  @override
  void dispose() {
    _focusNode?.dispose();
    super.dispose();
  }

  void _requestKeyboard() {
    _editableTextKey.currentState?.requestKeyboard();
  }

  void _handleSelectionChanged(TextSelection selection, SelectionChangedCause cause) {
    // if (cause == SelectionChangedCause.longPress)
    //   Feedback.forLongPress(context);
  }

  RenderEditable get _renderEditable => _editableTextKey.currentState.renderEditable;

  void _handleTapDown(TapDownDetails details) {
    _renderEditable.handleTapDown(details);
    _startSplash(details);
  }

  void _handleTap() {
    _renderEditable.handleTap();
    _requestKeyboard();
  }

  void _handleTapCancel() {
  }

  void _handleLongPress() {
    _renderEditable.handleLongPress();
  }

  void _startSplash(TapDownDetails details) {
    if (_effectiveFocusNode.hasFocus)
      return;
    //updateKeepAlive();
  }


  @override
  void deactivate() {
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    // super.build(context); // See AutomaticKeepAliveClientMixin.
    final TextStyle style = widget.style; //?? themeData.textTheme.subhead;
    // final Brightness keyboardAppearance = widget.keyboardAppearance ?? themeData.primaryColorBrightness;
    final TextEditingController controller = _effectiveController;
    final FocusNode focusNode = _effectiveFocusNode;
    final List<TextInputFormatter> formatters = widget.inputFormatters ?? <TextInputFormatter>[];
    if (widget.maxLength != null && widget.maxLengthEnforced)
      formatters.add(new LengthLimitingTextInputFormatter(widget.maxLength));

    Widget child = new RepaintBoundary(
      child: new EditableText(
        key: _editableTextKey,
        controller: controller,
        focusNode: focusNode,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        style: new TextStyle(),
        textAlign: widget.textAlign,
        autofocus: widget.autofocus,
        obscureText: widget.obscureText,
        autocorrect: widget.autocorrect,
        maxLines: widget.maxLines,
        selectionColor: CupertinoColors.activeBlue, // themeData.textSelectionColor,
        selectionControls: cupertinoTextSelectionControls,
        //selectionControls: themeData.platform == TargetPlatform.iOS
          //  ? cupertinoTextSelectionControls
            //: materialTextSelectionControls,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        onSelectionChanged: _handleSelectionChanged,
        inputFormatters: formatters,
        rendererIgnoresPointer: true,
        cursorWidth: widget.cursorWidth,
        cursorRadius: widget.cursorRadius,
        cursorColor: CupertinoColors.activeBlue, // ?? Theme.of(context).cursorColor,
        keyboardAppearance: Brightness.dark,// keyboardAppearance,
      ),
    );

    return new Semantics(
      onTap: () {
        if (!_effectiveController.selection.isValid)
          _effectiveController.selection = new TextSelection.collapsed(offset: _effectiveController.text.length);
        _requestKeyboard();
      },
      child: new IgnorePointer(
        // ignoring: !(widget.enabled ?? widget.decoration?.enabled ?? true),
        child: new GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapDown: _handleTapDown,
          onTap: _handleTap,
          onTapCancel: _handleTapCancel,
          onLongPress: _handleLongPress,
          excludeFromSemantics: true,
          child: child,
        ),
      ),
    );
  }
}