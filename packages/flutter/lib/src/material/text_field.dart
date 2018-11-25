// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'debug.dart';
import 'feedback.dart';
import 'ink_well.dart' show InteractiveInkFeature;
import 'input_decorator.dart';
import 'material.dart';
import 'material_localizations.dart';
import 'text_selection.dart';
import 'theme.dart';

export 'package:flutter/services.dart' show TextInputType, TextInputAction, TextCapitalization;

/// A material design text field.
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
/// one of its ancestors to be a [Material] widget. When the [TextField] is
/// tapped an ink splash that paints on the material is triggered, see
/// [ThemeData.splashFactory].
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
  ///
  /// The [maxLines] property can be set to null to remove the restriction on
  /// the number of lines. By default, it is one, meaning this is a single-line
  /// text field. [maxLines] must not be zero.
  ///
  /// The [maxLength] property is set to null by default, which means the
  /// number of characters allowed in the text field is not restricted. If
  /// [maxLength] is set, a character counter will be displayed below the
  /// field, showing how many characters have been entered and how many are
  /// allowed unless the value is set to [noMaxLength] in which case only the
  /// current length is displayed.
  ///
  /// After [maxLength] characters have been input, additional input
  /// is ignored, unless [maxLengthEnforced] is set to false. The TextField
  /// enforces the length with a [LengthLimitingTextInputFormatter], which is
  /// evaluated after the supplied [inputFormatters], if any. The [maxLength]
  /// value must be either null or greater than zero.
  ///
  /// If [maxLengthEnforced] is set to false, then more than [maxLength]
  /// characters may be entered, and the error counter and divider will
  /// switch to the [decoration.errorStyle] when the limit is exceeded.
  ///
  /// The [textAlign], [autofocus], [obscureText], [autocorrect],
  /// [maxLengthEnforced], [scrollPadding], [maxLines], [maxLength],
  /// and [enableInteractiveSelection] arguments must not be null.
  ///
  /// See also:
  ///
  ///  * [maxLength], which discusses the precise meaning of "number of
  ///    characters" and how it may differ from the intuitive meaning.
  const TextField({
    Key key,
    this.controller,
    this.focusNode,
    this.decoration = const InputDecoration(),
    TextInputType keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.style,
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.autofocus = false,
    this.obscureText = false,
    this.autocorrect = true,
    this.maxLines = 1,
    this.maxLength,
    this.maxLengthEnforced = true,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.inputFormatters,
    this.enabled,
    this.cursorWidth = 2.0,
    this.cursorRadius,
    this.cursorColor,
    this.keyboardAppearance,
    this.scrollPadding = const EdgeInsets.all(20.0),
    this.enableInteractiveSelection = true,
    this.onTap,
  }) : assert(textAlign != null),
       assert(autofocus != null),
       assert(obscureText != null),
       assert(autocorrect != null),
       assert(maxLengthEnforced != null),
       assert(scrollPadding != null),
       assert(maxLines == null || maxLines > 0),
       assert(maxLength == null || maxLength > 0),
       keyboardType = keyboardType ?? (maxLines == 1 ? TextInputType.text : TextInputType.multiline),
       assert(enableInteractiveSelection != null),
       super(key: key);

  /// Controls the text being edited.
  ///
  /// If null, this widget will create its own [TextEditingController].
  final TextEditingController controller;

  /// Defines the keyboard focus for this widget.
  ///
  /// The [focusNode] is a long-lived object that's typically managed by a
  /// [StatefulWidget] parent. See [FocusNode] for more information.
  ///
  /// To give the keyboard focus to this widget, provide a [focusNode] and then
  /// use the current [FocusScope] to request the focus:
  ///
  /// ```dart
  /// FocusScope.of(context).requestFocus(myFocusNode);
  /// ```
  ///
  /// This happens automatically when the widget is tapped.
  ///
  /// To be notified when the widget gains or loses the focus, add a listener
  /// to the [focusNode]:
  ///
  /// ```dart
  /// focusNode.addListener(() { print(myFocusNode.hasFocus); });
  /// ```
  ///
  /// If null, this widget will create its own [FocusNode].
  ///
  /// ## Keyboard
  ///
  /// Requesting the focus will typically cause the the keyboard to be shown
  /// if it's not showing already.
  ///
  /// On Android, the user can hide the keyboard - withouth changing the focus -
  /// with the system back button. They can restore the keyboard's visibility
  /// by tapping on a text field.  The user might hide the keyboard and
  /// switch to a physical keyboard, or they might just need to get it
  /// out of the way for a moment, to expose something it's
  /// obscuring. In this case requesting the focus again will not
  /// cause the focus to change, and will not make the keyboard visible.
  ///
  /// This widget builds an [EditableText] and will ensure that the keyboard is
  /// showing when it is tapped by calling [EditableTextState.requestKeyboard()].
  final FocusNode focusNode;

  /// The decoration to show around the text field.
  ///
  /// By default, draws a horizontal line under the text field but can be
  /// configured to show an icon, label, hint text, and error text.
  ///
  /// Specify null to remove the decoration entirely (including the
  /// extra padding introduced by the decoration to save space for the labels).
  final InputDecoration decoration;

  /// {@macro flutter.widgets.editableText.keyboardType}
  final TextInputType keyboardType;

  /// The type of action button to use for the keyboard.
  ///
  /// Defaults to [TextInputAction.newline] if [keyboardType] is
  /// [TextInputType.multiline] and [TextInputAction.done] otherwise.
  final TextInputAction textInputAction;

  /// {@macro flutter.widgets.editableText.textCapitalization}
  final TextCapitalization textCapitalization;

  /// The style to use for the text being edited.
  ///
  /// This text style is also used as the base style for the [decoration].
  ///
  /// If null, defaults to the `subhead` text style from the current [Theme].
  final TextStyle style;

  /// {@macro flutter.widgets.editableText.textAlign}
  final TextAlign textAlign;

  /// {@macro flutter.widgets.editableText.textDirection}
  final TextDirection textDirection;

  /// {@macro flutter.widgets.editableText.autofocus}
  final bool autofocus;

  /// {@macro flutter.widgets.editableText.obscureText}
  final bool obscureText;

  /// {@macro flutter.widgets.editableText.autocorrect}
  final bool autocorrect;

  /// {@macro flutter.widgets.editableText.maxLines}
  final int maxLines;

  /// If [maxLength] is set to this value, only the "current input length"
  /// part of the character counter is shown.
  static const int noMaxLength = 9007199254740992; // math.pow(2, 53);

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

  /// {@macro flutter.widgets.editableText.onChanged}
  final ValueChanged<String> onChanged;

  /// {@macro flutter.widgets.editableText.onEditingComplete}
  final VoidCallback onEditingComplete;

  /// {@macro flutter.widgets.editableText.onSubmitted}
  final ValueChanged<String> onSubmitted;

  /// {@macro flutter.widgets.editableText.inputFormatters}
  final List<TextInputFormatter> inputFormatters;

  /// If false the textfield is "disabled": it ignores taps and its
  /// [decoration] is rendered in grey.
  ///
  /// If non-null this property overrides the [decoration]'s
  /// [Decoration.enabled] property.
  final bool enabled;

  /// {@macro flutter.widgets.editableText.cursorWidth}
  final double cursorWidth;

  /// {@macro flutter.widgets.editableText.cursorRadius}
  final Radius cursorRadius;

  /// The color to use when painting the cursor.
  ///
  /// Defaults to the theme's `cursorColor` when null.
  final Color cursorColor;

  /// The appearance of the keyboard.
  ///
  /// This setting is only honored on iOS devices.
  ///
  /// If unset, defaults to the brightness of [ThemeData.primaryColorBrightness].
  final Brightness keyboardAppearance;

  /// {@macro flutter.widgets.editableText.scrollPadding}
  final EdgeInsets scrollPadding;

  /// {@macro flutter.widgets.editableText.enableInteractiveSelection}
  final bool enableInteractiveSelection;

  /// Called when the user taps on this textfield.
  ///
  /// The textfield builds a [GestureDetector] to handle input events like tap,
  /// to trigger focus requests, to move the caret, adjust the selection, etc.
  /// Handling some of those events by wrapping the textfield with a competing
  /// GestureDetector is problematic.
  ///
  /// To unconditionally handle taps, without interfering with the textfield's
  /// internal gesture detector, provide this callback.
  ///
  /// If the textfield is created with [enabled] false, taps will not be
  /// recognized.
  ///
  /// To be notified when the textfield gains or loses the focus, provide a
  /// [focusNode] and add a listener to that.
  ///
  /// To listen to arbitrary pointer events without competing with the
  /// textfield's internal gesture detector, use a [Listener].
  final GestureTapCallback onTap;

  @override
  _TextFieldState createState() => _TextFieldState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<TextEditingController>('controller', controller, defaultValue: null));
    properties.add(DiagnosticsProperty<FocusNode>('focusNode', focusNode, defaultValue: null));
    properties.add(DiagnosticsProperty<bool>('enabled', enabled, defaultValue: null));
    properties.add(DiagnosticsProperty<InputDecoration>('decoration', decoration));
    properties.add(DiagnosticsProperty<TextInputType>('keyboardType', keyboardType, defaultValue: TextInputType.text));
    properties.add(DiagnosticsProperty<TextStyle>('style', style, defaultValue: null));
    properties.add(DiagnosticsProperty<bool>('autofocus', autofocus, defaultValue: false));
    properties.add(DiagnosticsProperty<bool>('obscureText', obscureText, defaultValue: false));
    properties.add(DiagnosticsProperty<bool>('autocorrect', autocorrect, defaultValue: false));
    properties.add(IntProperty('maxLines', maxLines, defaultValue: 1));
    properties.add(IntProperty('maxLength', maxLength, defaultValue: null));
    properties.add(FlagProperty('maxLengthEnforced', value: maxLengthEnforced, ifTrue: 'max length enforced'));
    properties.add(DiagnosticsProperty<GestureTapCallback>('onTap', onTap, defaultValue: false));
  }
}

class _TextFieldState extends State<TextField> with AutomaticKeepAliveClientMixin {
  final GlobalKey<EditableTextState> _editableTextKey = GlobalKey<EditableTextState>();

  Set<InteractiveInkFeature> _splashes;
  InteractiveInkFeature _currentSplash;

  TextEditingController _controller;
  TextEditingController get _effectiveController => widget.controller ?? _controller;

  FocusNode _focusNode;
  FocusNode get _effectiveFocusNode => widget.focusNode ?? (_focusNode ??= FocusNode());

  bool get needsCounter => widget.maxLength != null
    && widget.decoration != null
    && widget.decoration.counterText == null;

  InputDecoration _getEffectiveDecoration() {
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);
    final InputDecoration effectiveDecoration = (widget.decoration ?? const InputDecoration())
      .applyDefaults(Theme.of(context).inputDecorationTheme)
      .copyWith(
        enabled: widget.enabled,
      );

    if (!needsCounter)
      return effectiveDecoration;

    final int currentLength = _effectiveController.value.text.runes.length;
    String counterText = '$currentLength';
    String semanticCounterText = '';

    if (widget.maxLength != TextField.noMaxLength) {
      counterText += '/${widget.maxLength}';
      final int remaining = (widget.maxLength - currentLength).clamp(0, widget.maxLength);
      semanticCounterText = localizations.remainingTextFieldCharacterCount(remaining);
    }

    // Handle length exceeds maxLength
    if (_effectiveController.value.text.runes.length > widget.maxLength) {
      final ThemeData themeData = Theme.of(context);
      return effectiveDecoration.copyWith(
        errorText: effectiveDecoration.errorText ?? '',
        counterStyle: effectiveDecoration.errorStyle
          ?? themeData.textTheme.caption.copyWith(color: themeData.errorColor),
        counterText: counterText,
        semanticCounterText: semanticCounterText,
      );
    }
    return effectiveDecoration.copyWith(
      counterText: counterText,
      semanticCounterText: semanticCounterText,
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.controller == null)
      _controller = TextEditingController();
  }

  @override
  void didUpdateWidget(TextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller == null && oldWidget.controller != null)
      _controller = TextEditingController.fromValue(oldWidget.controller.value);
    else if (widget.controller != null && oldWidget.controller == null)
      _controller = null;
    final bool isEnabled = widget.enabled ?? widget.decoration?.enabled ?? true;
    final bool wasEnabled = oldWidget.enabled ?? oldWidget.decoration?.enabled ?? true;
    if (wasEnabled && !isEnabled) {
      _effectiveFocusNode.unfocus();
    }
  }

  @override
  void dispose() {
    _focusNode?.dispose();
    super.dispose();
  }

  void _requestKeyboard() {
    _editableTextKey.currentState?.requestKeyboard();
  }

  void _handleSelectionChanged(TextSelection selection, SelectionChangedCause cause) {
    if (cause == SelectionChangedCause.longPress)
      Feedback.forLongPress(context);
  }

  InteractiveInkFeature _createInkFeature(TapDownDetails details) {
    final MaterialInkController inkController = Material.of(context);
    final BuildContext editableContext = _editableTextKey.currentContext;
    final RenderBox referenceBox = InputDecorator.containerOf(editableContext) ?? editableContext.findRenderObject();
    final Offset position = referenceBox.globalToLocal(details.globalPosition);
    final Color color = Theme.of(context).splashColor;

    InteractiveInkFeature splash;
    void handleRemoved() {
      if (_splashes != null) {
        assert(_splashes.contains(splash));
        _splashes.remove(splash);
        if (_currentSplash == splash)
          _currentSplash = null;
        updateKeepAlive();
      } // else we're probably in deactivate()
    }

    splash = Theme.of(context).splashFactory.create(
      controller: inkController,
      referenceBox: referenceBox,
      position: position,
      color: color,
      containedInkWell: true,
      // TODO(hansmuller): splash clip borderRadius should match the input decorator's border.
      borderRadius: BorderRadius.zero,
      onRemoved: handleRemoved,
      textDirection: Directionality.of(context),
    );

    return splash;
  }

  RenderEditable get _renderEditable => _editableTextKey.currentState.renderEditable;

  void _handleTapDown(TapDownDetails details) {
    _renderEditable.handleTapDown(details);
    _startSplash(details);
  }

  void _handleTap() {
    if (widget.enableInteractiveSelection)
      _renderEditable.handleTap();
    _requestKeyboard();
    _confirmCurrentSplash();
    if (widget.onTap != null)
      widget.onTap();
  }

  void _handleTapCancel() {
    _cancelCurrentSplash();
  }

  void _handleLongPress() {
    if (widget.enableInteractiveSelection)
      _renderEditable.handleLongPress();
    _confirmCurrentSplash();
  }

  void _startSplash(TapDownDetails details) {
    if (_effectiveFocusNode.hasFocus)
      return;
    final InteractiveInkFeature splash = _createInkFeature(details);
    _splashes ??= HashSet<InteractiveInkFeature>();
    _splashes.add(splash);
    _currentSplash = splash;
    updateKeepAlive();
  }

  void _confirmCurrentSplash() {
    _currentSplash?.confirm();
    _currentSplash = null;
  }

  void _cancelCurrentSplash() {
    _currentSplash?.cancel();
  }

  @override
  bool get wantKeepAlive => _splashes != null && _splashes.isNotEmpty;

  @override
  void deactivate() {
    if (_splashes != null) {
      final Set<InteractiveInkFeature> splashes = _splashes;
      _splashes = null;
      for (InteractiveInkFeature splash in splashes)
        splash.dispose();
      _currentSplash = null;
    }
    assert(_currentSplash == null);
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // See AutomaticKeepAliveClientMixin.
    assert(debugCheckHasMaterial(context));
    // TODO(jonahwilliams): uncomment out this check once we have migrated tests.
    // assert(debugCheckHasMaterialLocalizations(context));
    assert(debugCheckHasDirectionality(context));
    final ThemeData themeData = Theme.of(context);
    final TextStyle style = widget.style ?? themeData.textTheme.subhead;
    final Brightness keyboardAppearance = widget.keyboardAppearance ?? themeData.primaryColorBrightness;
    final TextEditingController controller = _effectiveController;
    final FocusNode focusNode = _effectiveFocusNode;
    final List<TextInputFormatter> formatters = widget.inputFormatters ?? <TextInputFormatter>[];
    if (widget.maxLength != null && widget.maxLengthEnforced)
      formatters.add(LengthLimitingTextInputFormatter(widget.maxLength));

    Widget child = RepaintBoundary(
      child: EditableText(
        key: _editableTextKey,
        controller: controller,
        focusNode: focusNode,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        textCapitalization: widget.textCapitalization,
        style: style,
        textAlign: widget.textAlign,
        textDirection: widget.textDirection,
        autofocus: widget.autofocus,
        obscureText: widget.obscureText,
        autocorrect: widget.autocorrect,
        maxLines: widget.maxLines,
        selectionColor: themeData.textSelectionColor,
        selectionControls: widget.enableInteractiveSelection
          ? (themeData.platform == TargetPlatform.iOS
             ? cupertinoTextSelectionControls
             : materialTextSelectionControls)
          : null,
        onChanged: widget.onChanged,
        onEditingComplete: widget.onEditingComplete,
        onSubmitted: widget.onSubmitted,
        onSelectionChanged: _handleSelectionChanged,
        inputFormatters: formatters,
        rendererIgnoresPointer: true,
        cursorWidth: widget.cursorWidth,
        cursorRadius: widget.cursorRadius,
        cursorColor: widget.cursorColor ?? Theme.of(context).cursorColor,
        scrollPadding: widget.scrollPadding,
        keyboardAppearance: keyboardAppearance,
        enableInteractiveSelection: widget.enableInteractiveSelection,
      ),
    );

    if (widget.decoration != null) {
      child = AnimatedBuilder(
        animation: Listenable.merge(<Listenable>[ focusNode, controller ]),
        builder: (BuildContext context, Widget child) {
          return InputDecorator(
            decoration: _getEffectiveDecoration(),
            baseStyle: widget.style,
            textAlign: widget.textAlign,
            isFocused: focusNode.hasFocus,
            isEmpty: controller.value.text.isEmpty,
            child: child,
          );
        },
        child: child,
      );
    }

    return Semantics(
      onTap: () {
        if (!_effectiveController.selection.isValid)
          _effectiveController.selection = TextSelection.collapsed(offset: _effectiveController.text.length);
        _requestKeyboard();
      },
      child: IgnorePointer(
        ignoring: !(widget.enabled ?? widget.decoration?.enabled ?? true),
        child: GestureDetector(
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
