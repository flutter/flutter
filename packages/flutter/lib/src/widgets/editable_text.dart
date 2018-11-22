// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'automatic_keep_alive.dart';
import 'basic.dart';
import 'binding.dart';
import 'focus_manager.dart';
import 'focus_scope.dart';
import 'framework.dart';
import 'localizations.dart';
import 'media_query.dart';
import 'scroll_controller.dart';
import 'scroll_physics.dart';
import 'scrollable.dart';
import 'text_selection.dart';

export 'package:flutter/services.dart' show TextEditingValue, TextSelection, TextInputType;
export 'package:flutter/rendering.dart' show SelectionChangedCause;

/// Signature for the callback that reports when the user changes the selection
/// (including the cursor location).
typedef SelectionChangedCallback = void Function(TextSelection selection, SelectionChangedCause cause);

const Duration _kCursorBlinkHalfPeriod = Duration(milliseconds: 500);

// Number of cursor ticks during which the most recently entered character
// is shown in an obscured text field.
const int _kObscureShowLatestCharCursorTicks = 3;

/// A controller for an editable text field.
///
/// Whenever the user modifies a text field with an associated
/// [TextEditingController], the text field updates [value] and the controller
/// notifies its listeners. Listeners can then read the [text] and [selection]
/// properties to learn what the user has typed or how the selection has been
/// updated.
///
/// Similarly, if you modify the [text] or [selection] properties, the text
/// field will be notified and will update itself appropriately.
///
/// A [TextEditingController] can also be used to provide an initial value for a
/// text field. If you build a text field with a controller that already has
/// [text], the text field will use that text as its initial value.
///
/// See also:
///
///  * [TextField], which is a Material Design text field that can be controlled
///    with a [TextEditingController].
///  * [EditableText], which is a raw region of editable text that can be
///    controlled with a [TextEditingController].
class TextEditingController extends ValueNotifier<TextEditingValue> {
  /// Creates a controller for an editable text field.
  ///
  /// This constructor treats a null [text] argument as if it were the empty
  /// string.
  TextEditingController({ String text })
    : super(text == null ? TextEditingValue.empty : TextEditingValue(text: text));

  /// Creates a controller for an editable text field from an initial [TextEditingValue].
  ///
  /// This constructor treats a null [value] argument as if it were
  /// [TextEditingValue.empty].
  TextEditingController.fromValue(TextEditingValue value)
    : super(value ?? TextEditingValue.empty);

  /// The current string the user is editing.
  String get text => value.text;
  /// Setting this will notify all the listeners of this [TextEditingController]
  /// that they need to update (it calls [notifyListeners]). For this reason,
  /// this value should only be set between frames, e.g. in response to user
  /// actions, not during the build, layout, or paint phases.
  set text(String newText) {
    value = value.copyWith(text: newText,
                           selection: const TextSelection.collapsed(offset: -1),
                           composing: TextRange.empty);
  }

  /// The currently selected [text].
  ///
  /// If the selection is collapsed, then this property gives the offset of the
  /// cursor within the text.
  TextSelection get selection => value.selection;
  /// Setting this will notify all the listeners of this [TextEditingController]
  /// that they need to update (it calls [notifyListeners]). For this reason,
  /// this value should only be set between frames, e.g. in response to user
  /// actions, not during the build, layout, or paint phases.
  set selection(TextSelection newSelection) {
    if (newSelection.start > text.length || newSelection.end > text.length)
      throw FlutterError('invalid text selection: $newSelection');
    value = value.copyWith(selection: newSelection, composing: TextRange.empty);
  }

  /// Set the [value] to empty.
  ///
  /// After calling this function, [text] will be the empty string and the
  /// selection will be invalid.
  ///
  /// Calling this will notify all the listeners of this [TextEditingController]
  /// that they need to update (it calls [notifyListeners]). For this reason,
  /// this method should only be called between frames, e.g. in response to user
  /// actions, not during the build, layout, or paint phases.
  void clear() {
    value = TextEditingValue.empty;
  }

  /// Set the composing region to an empty range.
  ///
  /// The composing region is the range of text that is still being composed.
  /// Calling this function indicates that the user is done composing that
  /// region.
  ///
  /// Calling this will notify all the listeners of this [TextEditingController]
  /// that they need to update (it calls [notifyListeners]). For this reason,
  /// this method should only be called between frames, e.g. in response to user
  /// actions, not during the build, layout, or paint phases.
  void clearComposing() {
    value = value.copyWith(composing: TextRange.empty);
  }
}

/// A basic text input field.
///
/// This widget interacts with the [TextInput] service to let the user edit the
/// text it contains. It also provides scrolling, selection, and cursor
/// movement. This widget does not provide any focus management (e.g.,
/// tap-to-focus).
///
/// ## Input Actions
///
/// A [TextInputAction] can be provided to customize the appearance of the
/// action button on the soft keyboard for Android and iOS. The default action
/// is [TextInputAction.done].
///
/// Many [TextInputAction]s are common between Android and iOS. However, if an
/// [inputAction] is provided that is not supported by the current
/// platform in debug mode, an error will be thrown when the corresponding
/// EditableText receives focus. For example, providing iOS's "emergencyCall"
/// action when running on an Android device will result in an error when in
/// debug mode. In release mode, incompatible [TextInputAction]s are replaced
/// either with "unspecified" on Android, or "default" on iOS. Appropriate
/// [inputAction]s can be chosen by checking the current platform and then
/// selecting the appropriate action.
///
/// ## Lifecycle
///
/// Upon completion of editing, like pressing the "done" button on the keyboard,
/// two actions take place:
///
///   1st: Editing is finalized. The default behavior of this step includes
///   an invocation of [onChanged]. That default behavior can be overridden.
///   See [onEditingComplete] for details.
///
///   2nd: [onSubmitted] is invoked with the user's input value.
///
/// [onSubmitted] can be used to manually move focus to another input widget
/// when a user finishes with the currently focused input widget.
///
/// Rather than using this widget directly, consider using [TextField], which
/// is a full-featured, material-design text input field with placeholder text,
/// labels, and [Form] integration.
///
/// See also:
///
///  * [TextField], which is a full-featured, material-design text input field
///    with placeholder text, labels, and [Form] integration.
class EditableText extends StatefulWidget {
  /// Creates a basic text input control.
  ///
  /// The [maxLines] property can be set to null to remove the restriction on
  /// the number of lines. By default, it is one, meaning this is a single-line
  /// text field. [maxLines] must be null or greater than zero.
  ///
  /// If [keyboardType] is not set or is null, it will default to
  /// [TextInputType.text] unless [maxLines] is greater than one, when it will
  /// default to [TextInputType.multiline].
  ///
  /// The [controller], [focusNode], [style], [cursorColor], [textAlign],
  /// [rendererIgnoresPointer], and [enableInteractiveSelection] arguments must
  /// not be null.
  EditableText({
    Key key,
    @required this.controller,
    @required this.focusNode,
    this.obscureText = false,
    this.autocorrect = true,
    @required this.style,
    @required this.cursorColor,
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.locale,
    this.textScaleFactor,
    this.maxLines = 1,
    this.autofocus = false,
    this.selectionColor,
    this.selectionControls,
    TextInputType keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.onSelectionChanged,
    List<TextInputFormatter> inputFormatters,
    this.rendererIgnoresPointer = false,
    this.cursorWidth = 2.0,
    this.cursorRadius,
    this.scrollPadding = const EdgeInsets.all(20.0),
    this.keyboardAppearance = Brightness.light,
    this.enableInteractiveSelection = true,
  }) : assert(controller != null),
       assert(focusNode != null),
       assert(obscureText != null),
       assert(autocorrect != null),
       assert(style != null),
       assert(cursorColor != null),
       assert(textAlign != null),
       assert(maxLines == null || maxLines > 0),
       assert(autofocus != null),
       assert(rendererIgnoresPointer != null),
       assert(scrollPadding != null),
       assert(enableInteractiveSelection != null),
       keyboardType = keyboardType ?? (maxLines == 1 ? TextInputType.text : TextInputType.multiline),
       inputFormatters = maxLines == 1
           ? (
               <TextInputFormatter>[BlacklistingTextInputFormatter.singleLineFormatter]
                 ..addAll(inputFormatters ?? const Iterable<TextInputFormatter>.empty())
             )
           : inputFormatters,
       super(key: key);

  /// Controls the text being edited.
  final TextEditingController controller;

  /// Controls whether this widget has keyboard focus.
  final FocusNode focusNode;

  /// {@template flutter.widgets.editableText.obscureText}
  /// Whether to hide the text being edited (e.g., for passwords).
  ///
  /// When this is set to true, all the characters in the text field are
  /// replaced by U+2022 BULLET characters (•).
  ///
  /// Defaults to false. Cannot be null.
  /// {@endtemplate}
  final bool obscureText;

  /// {@template flutter.widgets.editableText.autocorrect}
  /// Whether to enable autocorrection.
  ///
  /// Defaults to true. Cannot be null.
  /// {@endtemplate}
  final bool autocorrect;

  /// The text style to use for the editable text.
  final TextStyle style;

  /// {@template flutter.widgets.editableText.textAlign}
  /// How the text should be aligned horizontally.
  ///
  /// Defaults to [TextAlign.start] and cannot be null.
  /// {@endtemplate}
  final TextAlign textAlign;

  /// {@template flutter.widgets.editableText.textDirection}
  /// The directionality of the text.
  ///
  /// This decides how [textAlign] values like [TextAlign.start] and
  /// [TextAlign.end] are interpreted.
  ///
  /// This is also used to disambiguate how to render bidirectional text. For
  /// example, if the text is an English phrase followed by a Hebrew phrase,
  /// in a [TextDirection.ltr] context the English phrase will be on the left
  /// and the Hebrew phrase to its right, while in a [TextDirection.rtl]
  /// context, the English phrase will be on the right and the Hebrew phrase on
  /// its left.
  ///
  /// Defaults to the ambient [Directionality], if any.
  /// {@endtemplate}
  final TextDirection textDirection;

  /// {@template flutter.widgets.editableText.textCapitalization}
  /// Configures how the platform keyboard will select an uppercase or
  /// lowercase keyboard.
  ///
  /// Only supports text keyboards, other keyboard types will ignore this
  /// configuration. Capitalization is locale-aware.
  ///
  /// Defaults to [TextCapitalization.none]. Must not be null.
  ///
  /// See also:
  ///
  ///   * [TextCapitalization], for a description of each capitalization behavior.
  /// {@endtemplate}
  final TextCapitalization textCapitalization;

  /// Used to select a font when the same Unicode character can
  /// be rendered differently, depending on the locale.
  ///
  /// It's rarely necessary to set this property. By default its value
  /// is inherited from the enclosing app with `Localizations.localeOf(context)`.
  ///
  /// See [RenderEditable.locale] for more information.
  final Locale locale;

  /// The number of font pixels for each logical pixel.
  ///
  /// For example, if the text scale factor is 1.5, text will be 50% larger than
  /// the specified font size.
  ///
  /// Defaults to the [MediaQueryData.textScaleFactor] obtained from the ambient
  /// [MediaQuery], or 1.0 if there is no [MediaQuery] in scope.
  final double textScaleFactor;

  /// The color to use when painting the cursor.
  ///
  /// Cannot be null.
  final Color cursorColor;

  /// {@template flutter.widgets.editableText.maxLines}
  /// The maximum number of lines for the text to span, wrapping if necessary.
  ///
  /// If this is 1 (the default), the text will not wrap, but will scroll
  /// horizontally instead.
  ///
  /// If this is null, there is no limit to the number of lines. If it is not
  /// null, the value must be greater than zero.
  /// {@endtemplate}
  final int maxLines;

  /// {@template flutter.widgets.editableText.autofocus}
  /// Whether this text field should focus itself if nothing else is already
  /// focused.
  ///
  /// If true, the keyboard will open as soon as this text field obtains focus.
  /// Otherwise, the keyboard is only shown after the user taps the text field.
  ///
  /// Defaults to false. Cannot be null.
  /// {@endtemplate}
  // See https://github.com/flutter/flutter/issues/7035 for the rationale for this
  // keyboard behavior.
  final bool autofocus;

  /// The color to use when painting the selection.
  final Color selectionColor;

  /// Optional delegate for building the text selection handles and toolbar.
  final TextSelectionControls selectionControls;

  /// {@template flutter.widgets.editableText.keyboardType}
  /// The type of keyboard to use for editing the text.
  ///
  /// Defaults to [TextInputType.text] if [maxLines] is one and
  /// [TextInputType.multiline] otherwise.
  /// {@endtemplate}
  final TextInputType keyboardType;

  /// The type of action button to use with the soft keyboard.
  final TextInputAction textInputAction;

  /// {@template flutter.widgets.editableText.onChanged}
  /// Called when the text being edited changes.
  /// {@endtemplate}
  final ValueChanged<String> onChanged;

  /// {@template flutter.widgets.editableText.onEditingComplete}
  /// Called when the user submits editable content (e.g., user presses the "done"
  /// button on the keyboard).
  ///
  /// The default implementation of [onEditingComplete] executes 2 different
  /// behaviors based on the situation:
  ///
  ///  - When a completion action is pressed, such as "done", "go", "send", or
  ///    "search", the user's content is submitted to the [controller] and then
  ///    focus is given up.
  ///
  ///  - When a non-completion action is pressed, such as "next" or "previous",
  ///    the user's content is submitted to the [controller], but focus is not
  ///    given up because developers may want to immediately move focus to
  ///    another input widget within [onSubmitted].
  ///
  /// Providing [onEditingComplete] prevents the aforementioned default behavior.
  /// {@endtemplate}
  final VoidCallback onEditingComplete;

  /// {@template flutter.widgets.editableText.onSubmitted}
  /// Called when the user indicates that they are done editing the text in the
  /// field.
  /// {@endtemplate}
  final ValueChanged<String> onSubmitted;

  /// Called when the user changes the selection of text (including the cursor
  /// location).
  final SelectionChangedCallback onSelectionChanged;

  /// {@template flutter.widgets.editableText.inputFormatters}
  /// Optional input validation and formatting overrides.
  ///
  /// Formatters are run in the provided order when the text input changes.
  /// {@endtemplate}
  final List<TextInputFormatter> inputFormatters;

  /// If true, the [RenderEditable] created by this widget will not handle
  /// pointer events, see [renderEditable] and [RenderEditable.ignorePointer].
  ///
  /// This property is false by default.
  final bool rendererIgnoresPointer;

  /// {@template flutter.widgets.editableText.cursorWidth}
  /// How thick the cursor will be.
  ///
  /// Defaults to 2.0
  ///
  /// The cursor will draw under the text. The cursor width will extend
  /// to the right of the boundary between characters for left-to-right text
  /// and to the left for right-to-left text. This corresponds to extending
  /// downstream relative to the selected position. Negative values may be used
  /// to reverse this behavior.
  /// {@endtemplate}
  final double cursorWidth;

  /// {@template flutter.widgets.editableText.cursorRadius}
  /// How rounded the corners of the cursor should be.
  ///
  /// By default, the cursor has no radius.
  /// {@endtemplate}
  final Radius cursorRadius;

  /// The appearance of the keyboard.
  ///
  /// This setting is only honored on iOS devices.
  ///
  /// Defaults to [Brightness.light].
  final Brightness keyboardAppearance;

  /// {@template flutter.widgets.editableText.scrollPadding}
  /// Configures padding to edges surrounding a [Scrollable] when the Textfield scrolls into view.
  ///
  /// When this widget receives focus and is not completely visible (for example scrolled partially
  /// off the screen or overlapped by the keyboard)
  /// then it will attempt to make itself visible by scrolling a surrounding [Scrollable], if one is present.
  /// This value controls how far from the edges of a [Scrollable] the TextField will be positioned after the scroll.
  ///
  /// Defaults to EdgeInserts.all(20.0).
  /// {@endtemplate}
  final EdgeInsets scrollPadding;

  /// {@template flutter.widgets.editableText.enableInteractiveSelection}
  /// If true, then long-pressing this TextField will select text and show the
  /// cut/copy/paste menu, and tapping will move the text caret.
  ///
  /// True by default.
  ///
  /// If false, most of the accessibility support for selecting text, copy
  /// and paste, and moving the caret will be disabled.
  /// {@endtemplate}
  final bool enableInteractiveSelection;

  /// Setting this property to true makes the cursor stop blinking and stay visible on the screen continually.
  /// This property is most useful for testing purposes.
  ///
  /// Defaults to false, resulting in a typical blinking cursor.
  static bool debugDeterministicCursor = false;

  @override
  EditableTextState createState() => EditableTextState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<TextEditingController>('controller', controller));
    properties.add(DiagnosticsProperty<FocusNode>('focusNode', focusNode));
    properties.add(DiagnosticsProperty<bool>('obscureText', obscureText, defaultValue: false));
    properties.add(DiagnosticsProperty<bool>('autocorrect', autocorrect, defaultValue: true));
    style?.debugFillProperties(properties);
    properties.add(EnumProperty<TextAlign>('textAlign', textAlign, defaultValue: null));
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection, defaultValue: null));
    properties.add(DiagnosticsProperty<Locale>('locale', locale, defaultValue: null));
    properties.add(DoubleProperty('textScaleFactor', textScaleFactor, defaultValue: null));
    properties.add(IntProperty('maxLines', maxLines, defaultValue: 1));
    properties.add(DiagnosticsProperty<bool>('autofocus', autofocus, defaultValue: false));
    properties.add(DiagnosticsProperty<TextInputType>('keyboardType', keyboardType, defaultValue: null));
  }
}

/// State for a [EditableText].
class EditableTextState extends State<EditableText> with AutomaticKeepAliveClientMixin<EditableText>, WidgetsBindingObserver implements TextInputClient, TextSelectionDelegate {
  Timer _cursorTimer;
  final ValueNotifier<bool> _showCursor = ValueNotifier<bool>(false);
  final GlobalKey _editableKey = GlobalKey();

  TextInputConnection _textInputConnection;
  TextSelectionOverlay _selectionOverlay;

  final ScrollController _scrollController = ScrollController();
  final LayerLink _layerLink = LayerLink();
  bool _didAutoFocus = false;

  @override
  bool get wantKeepAlive => widget.focusNode.hasFocus;

  // State lifecycle:

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_didChangeTextEditingValue);
    widget.focusNode.addListener(_handleFocusChanged);
    _scrollController.addListener(() { _selectionOverlay?.updateForScroll(); });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didAutoFocus && widget.autofocus) {
      FocusScope.of(context).autofocus(widget.focusNode);
      _didAutoFocus = true;
    }
  }

  @override
  void didUpdateWidget(EditableText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_didChangeTextEditingValue);
      widget.controller.addListener(_didChangeTextEditingValue);
      _updateRemoteEditingValueIfNeeded();
    }
    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode.removeListener(_handleFocusChanged);
      widget.focusNode.addListener(_handleFocusChanged);
      updateKeepAlive();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_didChangeTextEditingValue);
    _closeInputConnectionIfNeeded();
    assert(!_hasInputConnection);
    _stopCursorTimer();
    assert(_cursorTimer == null);
    _selectionOverlay?.dispose();
    _selectionOverlay = null;
    widget.focusNode.removeListener(_handleFocusChanged);
    super.dispose();
  }

  // TextInputClient implementation:

  TextEditingValue _lastKnownRemoteTextEditingValue;

  @override
  void updateEditingValue(TextEditingValue value) {
    if (value.text != _value.text) {
      _hideSelectionOverlayIfNeeded();
      _showCaretOnScreen();
      if (widget.obscureText && value.text.length == _value.text.length + 1) {
        _obscureShowCharTicksPending = _kObscureShowLatestCharCursorTicks;
        _obscureLatestCharIndex = _value.selection.baseOffset;
      }
    }
    _lastKnownRemoteTextEditingValue = value;
    _formatAndSetValue(value);
  }

  @override
  void performAction(TextInputAction action) {
    switch (action) {
      case TextInputAction.newline:
        // If this is a multiline EditableText, do nothing for a "newline"
        // action; The newline is already inserted. Otherwise, finalize
        // editing.
        if (widget.maxLines == 1)
          _finalizeEditing(true);
        break;
      case TextInputAction.done:
      case TextInputAction.go:
      case TextInputAction.send:
      case TextInputAction.search:
        _finalizeEditing(true);
        break;
      default:
        // Finalize editing, but don't give up focus because this keyboard
        //  action does not imply the user is done inputting information.
        _finalizeEditing(false);
        break;
    }
  }

  void _finalizeEditing(bool shouldUnfocus) {
    // Take any actions necessary now that the user has completed editing.
    if (widget.onEditingComplete != null) {
      widget.onEditingComplete();
    } else {
      // Default behavior if the developer did not provide an
      // onEditingComplete callback: Finalize editing and remove focus.
      widget.controller.clearComposing();
      if (shouldUnfocus)
        widget.focusNode.unfocus();
    }

    // Invoke optional callback with the user's submitted content.
    if (widget.onSubmitted != null)
      widget.onSubmitted(_value.text);
  }

  void _updateRemoteEditingValueIfNeeded() {
    if (!_hasInputConnection)
      return;
    final TextEditingValue localValue = _value;
    if (localValue == _lastKnownRemoteTextEditingValue)
      return;
    _lastKnownRemoteTextEditingValue = localValue;
    _textInputConnection.setEditingState(localValue);
  }

  TextEditingValue get _value => widget.controller.value;
  set _value(TextEditingValue value) {
    widget.controller.value = value;
  }

  bool get _hasFocus => widget.focusNode.hasFocus;
  bool get _isMultiline => widget.maxLines != 1;

  // Calculate the new scroll offset so the cursor remains visible.
  double _getScrollOffsetForCaret(Rect caretRect) {
    final double caretStart = _isMultiline ? caretRect.top : caretRect.left;
    final double caretEnd = _isMultiline ? caretRect.bottom : caretRect.right;
    double scrollOffset = _scrollController.offset;
    final double viewportExtent = _scrollController.position.viewportDimension;
    if (caretStart < 0.0) // cursor before start of bounds
      scrollOffset += caretStart;
    else if (caretEnd >= viewportExtent) // cursor after end of bounds
      scrollOffset += caretEnd - viewportExtent;
    return scrollOffset;
  }

  // Calculates where the `caretRect` would be if `_scrollController.offset` is set to `scrollOffset`.
  Rect _getCaretRectAtScrollOffset(Rect caretRect, double scrollOffset) {
    final double offsetDiff = _scrollController.offset - scrollOffset;
    return _isMultiline ? caretRect.translate(0.0, offsetDiff) : caretRect.translate(offsetDiff, 0.0);
  }

  bool get _hasInputConnection => _textInputConnection != null && _textInputConnection.attached;

  void _openInputConnection() {
    if (!_hasInputConnection) {
      final TextEditingValue localValue = _value;
      _lastKnownRemoteTextEditingValue = localValue;
      _textInputConnection = TextInput.attach(this,
          TextInputConfiguration(
              inputType: widget.keyboardType,
              obscureText: widget.obscureText,
              autocorrect: widget.autocorrect,
              inputAction: widget.textInputAction ?? (widget.keyboardType == TextInputType.multiline
                  ? TextInputAction.newline
                  : TextInputAction.done
              ),
              textCapitalization: widget.textCapitalization,
          )
      )..setEditingState(localValue);
    }
    _textInputConnection.show();
  }

  void _closeInputConnectionIfNeeded() {
    if (_hasInputConnection) {
      _textInputConnection.close();
      _textInputConnection = null;
      _lastKnownRemoteTextEditingValue = null;
    }
  }

  void _openOrCloseInputConnectionIfNeeded() {
    if (_hasFocus && widget.focusNode.consumeKeyboardToken()) {
      _openInputConnection();
    } else if (!_hasFocus) {
      _closeInputConnectionIfNeeded();
      widget.controller.clearComposing();
    }
  }

  /// Express interest in interacting with the keyboard.
  ///
  /// If this control is already attached to the keyboard, this function will
  /// request that the keyboard become visible. Otherwise, this function will
  /// ask the focus system that it become focused. If successful in acquiring
  /// focus, the control will then attach to the keyboard and request that the
  /// keyboard become visible.
  void requestKeyboard() {
    if (_hasFocus)
      _openInputConnection();
    else
      FocusScope.of(context).requestFocus(widget.focusNode);
  }

  void _hideSelectionOverlayIfNeeded() {
    _selectionOverlay?.hide();
    _selectionOverlay = null;
  }

  void _updateOrDisposeSelectionOverlayIfNeeded() {
    if (_selectionOverlay != null) {
      if (_hasFocus) {
        _selectionOverlay.update(_value);
      } else {
        _selectionOverlay.dispose();
        _selectionOverlay = null;
      }
    }
  }

  void _handleSelectionChanged(TextSelection selection, RenderEditable renderObject, SelectionChangedCause cause) {
    widget.controller.selection = selection;

    // This will show the keyboard for all selection changes on the
    // EditableWidget, not just changes triggered by user gestures.
    requestKeyboard();

    _hideSelectionOverlayIfNeeded();

    if (widget.selectionControls != null) {
      _selectionOverlay = TextSelectionOverlay(
        context: context,
        value: _value,
        debugRequiredFor: widget,
        layerLink: _layerLink,
        renderObject: renderObject,
        selectionControls: widget.selectionControls,
        selectionDelegate: this,
      );
      final bool longPress = cause == SelectionChangedCause.longPress;
      if (cause != SelectionChangedCause.keyboard && (_value.text.isNotEmpty || longPress))
        _selectionOverlay.showHandles();
      if (longPress || cause == SelectionChangedCause.doubleTap)
        _selectionOverlay.showToolbar();
      if (widget.onSelectionChanged != null)
        widget.onSelectionChanged(selection, cause);
    }
  }

  bool _textChangedSinceLastCaretUpdate = false;
  Rect _currentCaretRect;

  void _handleCaretChanged(Rect caretRect) {
    _currentCaretRect = caretRect;
    // If the caret location has changed due to an update to the text or
    // selection, then scroll the caret into view.
    if (_textChangedSinceLastCaretUpdate) {
      _textChangedSinceLastCaretUpdate = false;
      _showCaretOnScreen();
    }
  }

  // Animation configuration for scrolling the caret back on screen.
  static const Duration _caretAnimationDuration = Duration(milliseconds: 100);
  static const Curve _caretAnimationCurve = Curves.fastOutSlowIn;

  bool _showCaretOnScreenScheduled = false;

  void _showCaretOnScreen() {
    if (_showCaretOnScreenScheduled) {
      return;
    }
    _showCaretOnScreenScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((Duration _) {
      _showCaretOnScreenScheduled = false;
      if (_currentCaretRect == null || !_scrollController.hasClients){
        return;
      }
      final double scrollOffsetForCaret =  _getScrollOffsetForCaret(_currentCaretRect);
      _scrollController.animateTo(
        scrollOffsetForCaret,
        duration: _caretAnimationDuration,
        curve: _caretAnimationCurve,
      );
      final Rect newCaretRect = _getCaretRectAtScrollOffset(_currentCaretRect, scrollOffsetForCaret);
      // Enlarge newCaretRect by scrollPadding to ensure that caret is not positioned directly at the edge after scrolling.
      final Rect inflatedRect = Rect.fromLTRB(
          newCaretRect.left - widget.scrollPadding.left,
          newCaretRect.top - widget.scrollPadding.top,
          newCaretRect.right + widget.scrollPadding.right,
          newCaretRect.bottom + widget.scrollPadding.bottom
      );
      _editableKey.currentContext.findRenderObject().showOnScreen(
        rect: inflatedRect,
        duration: _caretAnimationDuration,
        curve: _caretAnimationCurve,
      );
    });
  }

  double _lastBottomViewInset;

  @override
  void didChangeMetrics() {
    if (_lastBottomViewInset < ui.window.viewInsets.bottom) {
      _showCaretOnScreen();
    }
    _lastBottomViewInset = ui.window.viewInsets.bottom;
  }

  void _formatAndSetValue(TextEditingValue value) {
    final bool textChanged = _value?.text != value?.text;
    if (widget.inputFormatters != null && widget.inputFormatters.isNotEmpty) {
      for (TextInputFormatter formatter in widget.inputFormatters)
        value = formatter.formatEditUpdate(_value, value);
      _value = value;
      _updateRemoteEditingValueIfNeeded();
    } else {
      _value = value;
    }
    if (textChanged && widget.onChanged != null)
      widget.onChanged(value.text);
  }

  /// Whether the blinking cursor is actually visible at this precise moment
  /// (it's hidden half the time, since it blinks).
  @visibleForTesting
  bool get cursorCurrentlyVisible => _showCursor.value;

  /// The cursor blink interval (the amount of time the cursor is in the "on"
  /// state or the "off" state). A complete cursor blink period is twice this
  /// value (half on, half off).
  @visibleForTesting
  Duration get cursorBlinkInterval => _kCursorBlinkHalfPeriod;

  /// The current status of the text selection handles.
  @visibleForTesting
  TextSelectionOverlay get selectionOverlay => _selectionOverlay;

  int _obscureShowCharTicksPending = 0;
  int _obscureLatestCharIndex;

  void _cursorTick(Timer timer) {
    _showCursor.value = !_showCursor.value;
    if (_obscureShowCharTicksPending > 0) {
      setState(() { _obscureShowCharTicksPending--; });
    }
  }

  void _startCursorTimer() {
    _showCursor.value = true;
    _cursorTimer = Timer.periodic(_kCursorBlinkHalfPeriod, _cursorTick);
  }

  void _stopCursorTimer() {
    _cursorTimer?.cancel();
    _cursorTimer = null;
    _showCursor.value = false;
    _obscureShowCharTicksPending = 0;
  }

  void _startOrStopCursorTimerIfNeeded() {
    if (_cursorTimer == null && _hasFocus && _value.selection.isCollapsed)
      _startCursorTimer();
    else if (_cursorTimer != null && (!_hasFocus || !_value.selection.isCollapsed))
      _stopCursorTimer();
  }

  void _didChangeTextEditingValue() {
    _updateRemoteEditingValueIfNeeded();
    _startOrStopCursorTimerIfNeeded();
    _updateOrDisposeSelectionOverlayIfNeeded();
    _textChangedSinceLastCaretUpdate = true;
    // TODO(abarth): Teach RenderEditable about ValueNotifier<TextEditingValue>
    // to avoid this setState().
    setState(() { /* We use widget.controller.value in build(). */ });
  }

  void _handleFocusChanged() {
    _openOrCloseInputConnectionIfNeeded();
    _startOrStopCursorTimerIfNeeded();
    _updateOrDisposeSelectionOverlayIfNeeded();
    if (_hasFocus) {
      // Listen for changing viewInsets, which indicates keyboard showing up.
      WidgetsBinding.instance.addObserver(this);
      _lastBottomViewInset = ui.window.viewInsets.bottom;
      _showCaretOnScreen();
      if (!_value.selection.isValid) {
        // Place cursor at the end if the selection is invalid when we receive focus.
        widget.controller.selection = TextSelection.collapsed(offset: _value.text.length);
      }
    } else {
      WidgetsBinding.instance.removeObserver(this);
      // Clear the selection and composition state if this widget lost focus.
      _value = TextEditingValue(text: _value.text);
    }
    updateKeepAlive();
  }

  TextDirection get _textDirection {
    final TextDirection result = widget.textDirection ?? Directionality.of(context);
    assert(result != null, '$runtimeType created without a textDirection and with no ambient Directionality.');
    return result;
  }

  /// The renderer for this widget's [Editable] descendant.
  ///
  /// This property is typically used to notify the renderer of input gestures
  /// when [ignorePointer] is true. See [RenderEditable.ignorePointer].
  RenderEditable get renderEditable => _editableKey.currentContext.findRenderObject();

  @override
  TextEditingValue get textEditingValue => _value;

  @override
  set textEditingValue(TextEditingValue value) {
    _selectionOverlay?.update(value);
    _formatAndSetValue(value);
  }

  @override
  void bringIntoView(TextPosition position) {
    _scrollController.jumpTo(_getScrollOffsetForCaret(renderEditable.getLocalRectForCaret(position)));
  }

  @override
  void hideToolbar() {
    _selectionOverlay?.hide();
  }

  VoidCallback _semanticsOnCopy(TextSelectionControls controls) {
    return widget.enableInteractiveSelection && _hasFocus && controls?.canCopy(this) == true
      ? () => controls.handleCopy(this)
      : null;
  }

  VoidCallback _semanticsOnCut(TextSelectionControls controls) {
    return widget.enableInteractiveSelection && _hasFocus && controls?.canCut(this) == true
      ? () => controls.handleCut(this)
      : null;
  }

  VoidCallback _semanticsOnPaste(TextSelectionControls controls) {
    return widget.enableInteractiveSelection &&_hasFocus && controls?.canPaste(this) == true
      ? () => controls.handlePaste(this)
      : null;
  }

  @override
  Widget build(BuildContext context) {
    FocusScope.of(context).reparentIfNeeded(widget.focusNode);
    super.build(context); // See AutomaticKeepAliveClientMixin.

    final TextSelectionControls controls = widget.selectionControls;
    return Scrollable(
      excludeFromSemantics: true,
      axisDirection: _isMultiline ? AxisDirection.down : AxisDirection.right,
      controller: _scrollController,
      physics: const ClampingScrollPhysics(),
      viewportBuilder: (BuildContext context, ViewportOffset offset) {
        return CompositedTransformTarget(
          link: _layerLink,
          child: Semantics(
            onCopy: _semanticsOnCopy(controls),
            onCut: _semanticsOnCut(controls),
            onPaste: _semanticsOnPaste(controls),
            child: _Editable(
              key: _editableKey,
              textSpan: buildTextSpan(),
              value: _value,
              cursorColor: widget.cursorColor,
              showCursor: EditableText.debugDeterministicCursor ? ValueNotifier<bool>(true) : _showCursor,
              hasFocus: _hasFocus,
              maxLines: widget.maxLines,
              selectionColor: widget.selectionColor,
              textScaleFactor: widget.textScaleFactor ?? MediaQuery.textScaleFactorOf(context),
              textAlign: widget.textAlign,
              textDirection: _textDirection,
              locale: widget.locale,
              obscureText: widget.obscureText,
              autocorrect: widget.autocorrect,
              offset: offset,
              onSelectionChanged: _handleSelectionChanged,
              onCaretChanged: _handleCaretChanged,
              rendererIgnoresPointer: widget.rendererIgnoresPointer,
              cursorWidth: widget.cursorWidth,
              cursorRadius: widget.cursorRadius,
              enableInteractiveSelection: widget.enableInteractiveSelection,
              textSelectionDelegate: this,
            ),
          ),
        );
      },
    );
  }

  /// Builds [TextSpan] from current editing value.
  ///
  /// By default makes text in composing range appear as underlined.
  /// Descendants can override this method to customize appearance of text.
  TextSpan buildTextSpan() {
    if (!widget.obscureText && _value.composing.isValid) {
      final TextStyle composingStyle = widget.style.merge(
        const TextStyle(decoration: TextDecoration.underline),
      );

      return TextSpan(
        style: widget.style,
        children: <TextSpan>[
          TextSpan(text: _value.composing.textBefore(_value.text)),
          TextSpan(
            style: composingStyle,
            text: _value.composing.textInside(_value.text),
          ),
          TextSpan(text: _value.composing.textAfter(_value.text)),
      ]);
    }

    String text = _value.text;
    if (widget.obscureText) {
      text = RenderEditable.obscuringCharacter * text.length;
      final int o =
        _obscureShowCharTicksPending > 0 ? _obscureLatestCharIndex : null;
      if (o != null && o >= 0 && o < text.length)
        text = text.replaceRange(o, o + 1, _value.text.substring(o, o + 1));
    }
    return TextSpan(style: widget.style, text: text);
  }
}

class _Editable extends LeafRenderObjectWidget {
  const _Editable({
    Key key,
    this.textSpan,
    this.value,
    this.cursorColor,
    this.showCursor,
    this.hasFocus,
    this.maxLines,
    this.selectionColor,
    this.textScaleFactor,
    this.textAlign,
    @required this.textDirection,
    this.locale,
    this.obscureText,
    this.autocorrect,
    this.offset,
    this.onSelectionChanged,
    this.onCaretChanged,
    this.rendererIgnoresPointer = false,
    this.cursorWidth,
    this.cursorRadius,
    this.enableInteractiveSelection = true,
    this.textSelectionDelegate,
  }) : assert(textDirection != null),
       assert(rendererIgnoresPointer != null),
       assert(enableInteractiveSelection != null),
       super(key: key);

  final TextSpan textSpan;
  final TextEditingValue value;
  final Color cursorColor;
  final ValueNotifier<bool> showCursor;
  final bool hasFocus;
  final int maxLines;
  final Color selectionColor;
  final double textScaleFactor;
  final TextAlign textAlign;
  final TextDirection textDirection;
  final Locale locale;
  final bool obscureText;
  final bool autocorrect;
  final ViewportOffset offset;
  final SelectionChangedHandler onSelectionChanged;
  final CaretChangedHandler onCaretChanged;
  final bool rendererIgnoresPointer;
  final double cursorWidth;
  final Radius cursorRadius;
  final bool enableInteractiveSelection;
  final TextSelectionDelegate textSelectionDelegate;

  @override
  RenderEditable createRenderObject(BuildContext context) {
    return RenderEditable(
      text: textSpan,
      cursorColor: cursorColor,
      showCursor: showCursor,
      hasFocus: hasFocus,
      maxLines: maxLines,
      selectionColor: selectionColor,
      textScaleFactor: textScaleFactor,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale ?? Localizations.localeOf(context, nullOk: true),
      selection: value.selection,
      offset: offset,
      onSelectionChanged: onSelectionChanged,
      onCaretChanged: onCaretChanged,
      ignorePointer: rendererIgnoresPointer,
      obscureText: obscureText,
      cursorWidth: cursorWidth,
      cursorRadius: cursorRadius,
      enableInteractiveSelection: enableInteractiveSelection,
      textSelectionDelegate: textSelectionDelegate,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderEditable renderObject) {
    renderObject
      ..text = textSpan
      ..cursorColor = cursorColor
      ..showCursor = showCursor
      ..hasFocus = hasFocus
      ..maxLines = maxLines
      ..selectionColor = selectionColor
      ..textScaleFactor = textScaleFactor
      ..textAlign = textAlign
      ..textDirection = textDirection
      ..locale = locale ?? Localizations.localeOf(context, nullOk: true)
      ..selection = value.selection
      ..offset = offset
      ..onSelectionChanged = onSelectionChanged
      ..onCaretChanged = onCaretChanged
      ..ignorePointer = rendererIgnoresPointer
      ..obscureText = obscureText
      ..cursorWidth = cursorWidth
      ..cursorRadius = cursorRadius
      ..textSelectionDelegate = textSelectionDelegate;
  }
}
