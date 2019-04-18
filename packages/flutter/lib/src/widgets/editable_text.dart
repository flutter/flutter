// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart' show DragStartBehavior;

import 'automatic_keep_alive.dart';
import 'basic.dart';
import 'binding.dart';
import 'debug.dart';
import 'focus_manager.dart';
import 'focus_scope.dart';
import 'framework.dart';
import 'localizations.dart';
import 'media_query.dart';
import 'scroll_controller.dart';
import 'scroll_physics.dart';
import 'scrollable.dart';
import 'text_selection.dart';
import 'ticker_provider.dart';

export 'package:flutter/services.dart' show TextEditingValue, TextSelection, TextInputType;
export 'package:flutter/rendering.dart' show SelectionChangedCause;

/// Signature for the callback that reports when the user changes the selection
/// (including the cursor location).
typedef SelectionChangedCallback = void Function(TextSelection selection, SelectionChangedCause cause);

// The time it takes for the cursor to fade from fully opaque to fully
// transparent and vice versa. A full cursor blink, from transparent to opaque
// to transparent, is twice this duration.
const Duration _kCursorBlinkHalfPeriod = Duration(milliseconds: 500);

// The time the cursor is static in opacity before animating to become
// transparent.
const Duration _kCursorBlinkWaitForStart = Duration(milliseconds: 150);

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
/// The [text] or [selection] properties can be set from within a listener
/// added to this controller. If both properties need to be changed then the
/// controller's [value] should be set instead.
///
/// {@tool snippet --template=stateful_widget_material}
/// This example creates a [TextField] with a [TextEditingController] whose
/// change listener forces the entered text to be lower case and keeps the
/// cursor at the end of the input.
///
/// ```dart
/// final _controller = TextEditingController();
///
/// void initState() {
///   _controller.addListener(() {
///     final text = _controller.text.toLowerCase();
///     _controller.value = _controller.value.copyWith(
///       text: text,
///       selection: TextSelection(baseOffset: text.length, extentOffset: text.length),
///       composing: TextRange.empty,
///     );
///   });
///   super.initState();
/// }
///
/// void dispose() {
///   _controller.dispose();
///   super.dispose();
/// }
///
/// Widget build(BuildContext context) {
///   return Scaffold(
///     body: Container(
///      alignment: Alignment.center,
///       padding: const EdgeInsets.all(6),
///       child: TextFormField(
///         controller: _controller,
///        decoration: InputDecoration(border: OutlineInputBorder()),
///       ),
///     ),
///   );
/// }
/// ```
/// {@end-tool}
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
  ///
  /// This property can be set from a listener added to this
  /// [TextEditingController]; however, one should not also set [selection]
  /// in a separate statement. To change both the [text] and the [selection]
  /// change the controller's [value].
  set text(String newText) {
    value = value.copyWith(
      text: newText,
      selection: const TextSelection.collapsed(offset: -1),
      composing: TextRange.empty,
    );
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
  ///
  /// This property can be set from a listener added to this
  /// [TextEditingController]; however, one should not also set [text]
  /// in a separate statement. To change both the [text] and the [selection]
  /// change the controller's [value].
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
/// ## Gesture Events Handling
///
/// This widget provides rudimentary, platform-agnostic gesture handling for
/// user actions such as tapping, long-pressing and scrolling when
/// [rendererIgnoresPointer] is false (false by default). To tightly conform
/// to the platform behavior with respect to input gestures in text fields, use
/// [TextField] or [CupertinoTextField]. For custom selection behavior, call
/// methods such as [RenderEditable.selectPosition],
/// [RenderEditable.selectWord], etc. programmatically.
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
  /// The [controller], [focusNode], [style], [cursorColor], [backgroundCursorColor],
  /// [textAlign], [dragStartBehavior] and [rendererIgnoresPointer] arguments
  /// must not be null.
  EditableText({
    Key key,
    @required this.controller,
    @required this.focusNode,
    this.obscureText = false,
    this.autocorrect = true,
    @required this.style,
    StrutStyle strutStyle,
    @required this.cursorColor,
    @required this.backgroundCursorColor,
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.locale,
    this.textScaleFactor,
    this.maxLines = 1,
    this.minLines,
    this.expands = false,
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
    this.cursorOpacityAnimates = false,
    this.cursorOffset,
    this.paintCursorAboveText = false,
    this.scrollPadding = const EdgeInsets.all(20.0),
    this.keyboardAppearance = Brightness.light,
    this.dragStartBehavior = DragStartBehavior.start,
    this.enableInteractiveSelection,
  }) : assert(controller != null),
       assert(focusNode != null),
       assert(obscureText != null),
       assert(autocorrect != null),
       assert(style != null),
       assert(cursorColor != null),
       assert(cursorOpacityAnimates != null),
       assert(paintCursorAboveText != null),
       assert(backgroundCursorColor != null),
       assert(textAlign != null),
       assert(maxLines == null || maxLines > 0),
       assert(minLines == null || minLines > 0),
       assert(
         (maxLines == null) || (minLines == null) || (maxLines >= minLines),
         'minLines can\'t be greater than maxLines',
       ),
       assert(expands != null),
       assert(
         !expands || (maxLines == null && minLines == null),
         'minLines and maxLines must be null when expands is true.',
       ),
       assert(autofocus != null),
       assert(rendererIgnoresPointer != null),
       assert(scrollPadding != null),
       assert(dragStartBehavior != null),
       _strutStyle = strutStyle,
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

  /// {@template flutter.widgets.editableText.strutStyle}
  /// The strut style used for the vertical layout.
  ///
  /// [StrutStyle] is used to establish a predictable vertical layout.
  /// Since fonts may vary depending on user input and due to font
  /// fallback, [StrutStyle.forceStrutHeight] is enabled by default
  /// to lock all lines to the height of the base [TextStyle], provided by
  /// [style]. This ensures the typed text fits within the allotted space.
  ///
  /// If null, the strut used will is inherit values from the [style] and will
  /// have [StrutStyle.forceStrutHeight] set to true. When no [style] is
  /// passed, the theme's [TextStyle] will be used to generate [strutStyle]
  /// instead.
  ///
  /// To disable strut-based vertical alignment and allow dynamic vertical
  /// layout based on the glyphs typed, use [StrutStyle.disabled].
  ///
  /// Flutter's strut is based on [typesetting strut](https://en.wikipedia.org/wiki/Strut_(typesetting))
  /// and CSS's [line-height](https://www.w3.org/TR/CSS2/visudet.html#line-height).
  /// {@endtemplate}
  ///
  /// Within editable text and textfields, [StrutStyle] will not use its standalone
  /// default values, and will instead inherit omitted/null properties from the
  /// [TextStyle] instead. See [StrutStyle.inheritFromTextStyle].
  StrutStyle get strutStyle {
    if (_strutStyle == null) {
      return style != null ? StrutStyle.fromTextStyle(style, forceStrutHeight: true) : StrutStyle.disabled;
    }
    return _strutStyle.inheritFromTextStyle(style);
  }
  final StrutStyle _strutStyle;

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
  ///
  /// See also:
  ///
  ///   * {@macro flutter.gestures.monodrag.dragStartExample}
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
  ///  * [TextCapitalization], for a description of each capitalization behavior.
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

  /// The color to use when painting the background cursor aligned with the text
  /// while rendering the floating cursor.
  ///
  /// Cannot be null. By default it is the disabled grey color from
  /// CupertinoColors.
  final Color backgroundCursorColor;

  /// {@template flutter.widgets.editableText.maxLines}
  /// The maximum number of lines for the text to span, wrapping if necessary.
  ///
  /// If this is 1 (the default), the text will not wrap, but will scroll
  /// horizontally instead.
  ///
  /// If this is null, there is no limit to the number of lines, and the text
  /// container will start with enough vertical space for one line and
  /// automatically grow to accommodate additional lines as they are entered.
  ///
  /// If this is not null, the value must be greater than zero, and it will lock
  /// the input to the given number of lines and take up enough horizontal space
  /// to accommodate that number of lines. Setting [minLines] as well allows the
  /// input to grow between the indicated range.
  ///
  /// The full set of behaviors possible with [minLines] and [maxLines] are as
  /// follows. These examples apply equally to `TextField`, `TextFormField`, and
  /// `EditableText`.
  ///
  /// Input that occupies a single line and scrolls horizontally as needed.
  /// ```dart
  /// TextField()
  /// ```
  ///
  /// Input whose height grows from one line up to as many lines as needed for
  /// the text that was entered. If a height limit is imposed by its parent, it
  /// will scroll vertically when its height reaches that limit.
  /// ```dart
  /// TextField(maxLines: null)
  /// ```
  ///
  /// The input's height is large enough for the given number of lines. If
  /// additional lines are entered the input scrolls vertically.
  /// ```dart
  /// TextField(maxLines: 2)
  /// ```
  ///
  /// Input whose height grows with content between a min and max. An infinite
  /// max is possible with `maxLines: null`.
  /// ```dart
  /// TextField(minLines: 2, maxLines: 4)
  /// ```
  /// {@endtemplate}
  final int maxLines;

  /// {@template flutter.widgets.editableText.minLines}
  /// The minimum number of lines to occupy when the content spans fewer lines.

  /// When [maxLines] is set as well, the height will grow between the indicated
  /// range of lines. When [maxLines] is null, it will grow as high as needed,
  /// starting from [minLines].
  ///
  /// See the examples in [maxLines] for the complete picture of how [maxLines]
  /// and [minLines] interact to produce various behaviors.
  ///
  /// Defaults to null.
  /// {@endtemplate}
  final int minLines;

  /// {@template flutter.widgets.editableText.expands}
  /// Whether this widget's height will be sized to fill its parent.
  ///
  /// If set to true and wrapped in a parent widget like [Expanded] or
  /// [SizedBox], the input will expand to fill the parent.
  ///
  /// [maxLines] and [minLines] must both be null when this is set to true,
  /// otherwise an error is thrown.
  ///
  /// Defaults to false.
  ///
  /// See the examples in [maxLines] for the complete picture of how [maxLines],
  /// [minLines], and [expands] interact to produce various behaviors.
  ///
  /// Input that matches the height of its parent
  /// ```dart
  /// Expanded(
  ///   child: TextField(maxLines: null, expands: true),
  /// )
  /// ```
  /// {@endtemplate}
  final bool expands;

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
  ///
  /// The [EditableText] widget used on its own will not trigger the display
  /// of the selection toolbar by itself. The toolbar is shown by calling
  /// [EditableTextState.showToolbar] in response to an appropriate user event.
  ///
  /// See also:
  ///
  ///  * [CupertinoTextField], which wraps an [EditableText] and which shows the
  ///    selection toolbar upon user events that are appropriate on the iOS
  ///    platform.
  ///  * [TextField], a Material Design themed wrapper of [EditableText], which
  ///    shows the selection toolbar upon appropriate user events based on the
  ///    user's platform set in [ThemeData.platform].
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
  /// Called when the user initiates a change to the TextField's
  /// value: when they have inserted or deleted text.
  ///
  /// This callback doesn't run when the TextField's text is changed
  /// programmatically, via the TextField's [controller]. Typically it
  /// isn't necessary to be notified of such changes, since they're
  /// initiated by the app itself.
  ///
  /// To be notified of all changes to the TextField's text, cursor,
  /// and selection, one can add a listener to its [controller] with
  /// [TextEditingController.addListener].
  /// {@endtemplate}
  ///
  /// See also:
  ///
  ///  * [inputFormatters], which are called before [onChanged]
  ///    runs and can validate and change ("format") the input value.
  ///  * [onEditingComplete], [onSubmitted], [onSelectionChanged]:
  ///    which are more specialized input change notifications.
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

  /// Whether the cursor will animate from fully transparent to fully opaque
  /// during each cursor blink.
  ///
  /// By default, the cursor opacity will animate on iOS platforms and will not
  /// animate on Android platforms.
  final bool cursorOpacityAnimates;

  ///{@macro flutter.rendering.editable.cursorOffset}
  final Offset cursorOffset;

  ///{@macro flutter.rendering.editable.paintCursorOnTop}
  final bool paintCursorAboveText;

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

  /// Setting this property to true makes the cursor stop blinking or fading
  /// on and off once the cursor appears on focus. This property is useful for
  /// testing purposes.
  ///
  /// It does not affect the necessity to focus the EditableText for the cursor
  /// to appear in the first place.
  ///
  /// Defaults to false, resulting in a typical blinking cursor.
  static bool debugDeterministicCursor = false;

  /// {@macro flutter.widgets.scrollable.dragStartBehavior}
  final DragStartBehavior dragStartBehavior;

  /// {@macro flutter.rendering.editable.selectionEnabled}
  bool get selectionEnabled {
    return enableInteractiveSelection ?? !obscureText;
  }

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
    properties.add(IntProperty('minLines', minLines, defaultValue: null));
    properties.add(DiagnosticsProperty<bool>('expands', expands, defaultValue: false));
    properties.add(DiagnosticsProperty<bool>('autofocus', autofocus, defaultValue: false));
    properties.add(DiagnosticsProperty<TextInputType>('keyboardType', keyboardType, defaultValue: null));
  }
}

/// State for a [EditableText].
class EditableTextState extends State<EditableText> with AutomaticKeepAliveClientMixin<EditableText>, WidgetsBindingObserver, TickerProviderStateMixin<EditableText> implements TextInputClient, TextSelectionDelegate {
  Timer _cursorTimer;
  bool _targetCursorVisibility = false;
  final ValueNotifier<bool> _cursorVisibilityNotifier = ValueNotifier<bool>(true);
  final GlobalKey _editableKey = GlobalKey();

  TextInputConnection _textInputConnection;
  TextSelectionOverlay _selectionOverlay;

  final ScrollController _scrollController = ScrollController();
  AnimationController _cursorBlinkOpacityController;

  final LayerLink _layerLink = LayerLink();
  bool _didAutoFocus = false;

  // This value is an eyeball estimation of the time it takes for the iOS cursor
  // to ease in and out.
  static const Duration _fadeDuration = Duration(milliseconds: 250);

  // The time it takes for the floating cursor to snap to the text aligned
  // cursor position after the user has finished placing it.
  static const Duration _floatingCursorResetTime = Duration(milliseconds: 125);

  AnimationController _floatingCursorResetController;

  @override
  bool get wantKeepAlive => widget.focusNode.hasFocus;

  Color get _cursorColor => widget.cursorColor.withOpacity(_cursorBlinkOpacityController.value);

  // State lifecycle:

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_didChangeTextEditingValue);
    widget.focusNode.addListener(_handleFocusChanged);
    _scrollController.addListener(() { _selectionOverlay?.updateForScroll(); });
    _cursorBlinkOpacityController = AnimationController(vsync: this, duration: _fadeDuration);
    _cursorBlinkOpacityController.addListener(_onCursorColorTick);
    _floatingCursorResetController = AnimationController(vsync: this);
    _floatingCursorResetController.addListener(_onFloatingCursorResetTick);
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
    _cursorBlinkOpacityController.removeListener(_onCursorColorTick);
    _floatingCursorResetController.removeListener(_onFloatingCursorResetTick);
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

    // To keep the cursor from blinking while typing, we want to restart the
    // cursor timer every time a new character is typed.
    _stopCursorTimer(resetCharTicks: false);
    _startCursorTimer();
  }

  @override
  void performAction(TextInputAction action) {
    switch (action) {
      case TextInputAction.newline:
        // If this is a multiline EditableText, do nothing for a "newline"
        // action; The newline is already inserted. Otherwise, finalize
        // editing.
        if (!_isMultiline)
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

  // The original position of the caret on FloatingCursorDragState.start.
  Rect _startCaretRect;

  // The most recent text position as determined by the location of the floating
  // cursor.
  TextPosition _lastTextPosition;

  // The offset of the floating cursor as determined from the first update call.
  Offset _pointOffsetOrigin;

  // The most recent position of the floating cursor.
  Offset _lastBoundedOffset;

  // Because the center of the cursor is preferredLineHeight / 2 below the touch
  // origin, but the touch origin is used to determine which line the cursor is
  // on, we need this offset to correctly render and move the cursor.
  Offset get _floatingCursorOffset => Offset(0, renderEditable.preferredLineHeight / 2);

  @override
  void updateFloatingCursor(RawFloatingCursorPoint point) {
    switch(point.state){
      case FloatingCursorDragState.Start:
        if (_floatingCursorResetController.isAnimating) {
          _floatingCursorResetController.stop();
          _onFloatingCursorResetTick();
        }
        final TextPosition currentTextPosition = TextPosition(offset: renderEditable.selection.baseOffset);
        _startCaretRect = renderEditable.getLocalRectForCaret(currentTextPosition);
        renderEditable.setFloatingCursor(point.state, _startCaretRect.center - _floatingCursorOffset, currentTextPosition);
        break;
      case FloatingCursorDragState.Update:
        // We want to send in points that are centered around a (0,0) origin, so we cache the
        // position on the first update call.
        if (_pointOffsetOrigin != null) {
          final Offset centeredPoint = point.offset - _pointOffsetOrigin;
          final Offset rawCursorOffset = _startCaretRect.center + centeredPoint - _floatingCursorOffset;
          _lastBoundedOffset = renderEditable.calculateBoundedFloatingCursorOffset(rawCursorOffset);
          _lastTextPosition = renderEditable.getPositionForPoint(renderEditable.localToGlobal(_lastBoundedOffset + _floatingCursorOffset));
          renderEditable.setFloatingCursor(point.state, _lastBoundedOffset, _lastTextPosition);
        } else {
          _pointOffsetOrigin = point.offset;
        }
        break;
      case FloatingCursorDragState.End:
        _floatingCursorResetController.value = 0.0;
        _floatingCursorResetController.animateTo(1.0, duration: _floatingCursorResetTime, curve: Curves.decelerate);
      break;
    }
  }

  void _onFloatingCursorResetTick() {
    final Offset finalPosition = renderEditable.getLocalRectForCaret(_lastTextPosition).centerLeft - _floatingCursorOffset;
    if (_floatingCursorResetController.isCompleted) {
      renderEditable.setFloatingCursor(FloatingCursorDragState.End, finalPosition, _lastTextPosition);
      if (_lastTextPosition.offset != renderEditable.selection.baseOffset)
        // The cause is technically the force cursor, but the cause is listed as tap as the desired functionality is the same.
        _handleSelectionChanged(TextSelection.collapsed(offset: _lastTextPosition.offset), renderEditable, SelectionChangedCause.forcePress);
      _startCaretRect = null;
      _lastTextPosition = null;
      _pointOffsetOrigin = null;
      _lastBoundedOffset = null;
    } else {
      final double lerpValue = _floatingCursorResetController.value;
      final double lerpX = ui.lerpDouble(_lastBoundedOffset.dx, finalPosition.dx, lerpValue);
      final double lerpY = ui.lerpDouble(_lastBoundedOffset.dy, finalPosition.dy, lerpValue);

      renderEditable.setFloatingCursor(FloatingCursorDragState.Update, Offset(lerpX, lerpY), _lastTextPosition, resetLerpValue: lerpValue);
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
    double caretStart;
    double caretEnd;
    if (_isMultiline) {
      // The caret is vertically centered within the line. Expand the caret's
      // height so that it spans the line because we're going to ensure that the entire
      // expanded caret is scrolled into view.
      final double lineHeight = renderEditable.preferredLineHeight;
      final double caretOffset = (lineHeight - caretRect.height) / 2;
      caretStart = caretRect.top - caretOffset;
      caretEnd = caretRect.bottom + caretOffset;
    } else {
      caretStart = caretRect.left;
      caretEnd = caretRect.right;
    }

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
              keyboardAppearance: widget.keyboardAppearance,
          ),
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
    if (_hasFocus) {
      _openInputConnection();
    } else {
      final List<FocusScopeNode> ancestorScopes = FocusScope.ancestorsOf(context);
      for (int i = ancestorScopes.length - 1; i >= 1; i -= 1)
        ancestorScopes[i].setFirstFocus(ancestorScopes[i - 1]);
      FocusScope.of(context).requestFocus(widget.focusNode);
    }
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
        dragStartBehavior: widget.dragStartBehavior,
      );
      final bool longPress = cause == SelectionChangedCause.longPress;
      if (cause != SelectionChangedCause.keyboard && (_value.text.isNotEmpty || longPress))
        _selectionOverlay.showHandles();
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
      if (_currentCaretRect == null || !_scrollController.hasClients) {
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
          newCaretRect.bottom + widget.scrollPadding.bottom,
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
    if (_lastBottomViewInset < WidgetsBinding.instance.window.viewInsets.bottom) {
      _showCaretOnScreen();
    }
    _lastBottomViewInset = WidgetsBinding.instance.window.viewInsets.bottom;
  }

  void _formatAndSetValue(TextEditingValue value) {
    final bool textChanged = _value?.text != value?.text;
    if (textChanged && widget.inputFormatters != null && widget.inputFormatters.isNotEmpty) {
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

  void _onCursorColorTick() {
    renderEditable.cursorColor = widget.cursorColor.withOpacity(_cursorBlinkOpacityController.value);
    _cursorVisibilityNotifier.value = _cursorBlinkOpacityController.value > 0;
  }

  /// Whether the blinking cursor is actually visible at this precise moment
  /// (it's hidden half the time, since it blinks).
  @visibleForTesting
  bool get cursorCurrentlyVisible => _cursorBlinkOpacityController.value > 0;

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
    _targetCursorVisibility = !_targetCursorVisibility;
    final double targetOpacity = _targetCursorVisibility ? 1.0 : 0.0;
    if (widget.cursorOpacityAnimates) {
      // If we want to show the cursor, we will animate the opacity to the value
      // of 1.0, and likewise if we want to make it disappear, to 0.0. An easing
      // curve is used for the animation to mimic the aesthetics of the native
      // iOS cursor.
      //
      // These values and curves have been obtained through eyeballing, so are
      // likely not exactly the same as the values for native iOS.
      _cursorBlinkOpacityController.animateTo(targetOpacity, curve: Curves.easeOut);
    } else {
      _cursorBlinkOpacityController.value = targetOpacity;
    }

    if (_obscureShowCharTicksPending > 0) {
      setState(() {
        _obscureShowCharTicksPending--;
      });
    }
  }

  void _cursorWaitForStart(Timer timer) {
    assert(_kCursorBlinkHalfPeriod > _fadeDuration);
    _cursorTimer?.cancel();
    _cursorTimer = Timer.periodic(_kCursorBlinkHalfPeriod, _cursorTick);
  }

  void _startCursorTimer() {
    _targetCursorVisibility = true;
    _cursorBlinkOpacityController.value = 1.0;
    if (EditableText.debugDeterministicCursor)
      return;
    if (widget.cursorOpacityAnimates) {
      _cursorTimer = Timer.periodic(_kCursorBlinkWaitForStart, _cursorWaitForStart);
    } else {
      _cursorTimer = Timer.periodic(_kCursorBlinkHalfPeriod, _cursorTick);
    }
  }

  void _stopCursorTimer({ bool resetCharTicks = true }) {
    _cursorTimer?.cancel();
    _cursorTimer = null;
    _targetCursorVisibility = false;
    _cursorBlinkOpacityController.value = 0.0;
    if (EditableText.debugDeterministicCursor)
      return;
    if (resetCharTicks)
      _obscureShowCharTicksPending = 0;
    if (widget.cursorOpacityAnimates) {
      _cursorBlinkOpacityController.stop();
      _cursorBlinkOpacityController.value = 0.0;
    }
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
      _lastBottomViewInset = WidgetsBinding.instance.window.viewInsets.bottom;
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

  double get _devicePixelRatio => MediaQuery.of(context).devicePixelRatio ?? 1.0;

  @override
  set textEditingValue(TextEditingValue value) {
    _selectionOverlay?.update(value);
    _formatAndSetValue(value);
  }

  @override
  void bringIntoView(TextPosition position) {
    _scrollController.jumpTo(_getScrollOffsetForCaret(renderEditable.getLocalRectForCaret(position)));
  }

  /// Shows the selection toolbar at the location of the current cursor.
  ///
  /// Returns `false` if a toolbar couldn't be shown such as when no text
  /// selection currently exists.
  bool showToolbar() {
    if (_selectionOverlay == null)
      return false;

    _selectionOverlay.showToolbar();
    return true;
  }

  @override
  void hideToolbar() {
    _selectionOverlay?.hide();
  }

  VoidCallback _semanticsOnCopy(TextSelectionControls controls) {
    return widget.selectionEnabled && _hasFocus && controls?.canCopy(this) == true
      ? () => controls.handleCopy(this)
      : null;
  }

  VoidCallback _semanticsOnCut(TextSelectionControls controls) {
    return widget.selectionEnabled && _hasFocus && controls?.canCut(this) == true
      ? () => controls.handleCut(this)
      : null;
  }

  VoidCallback _semanticsOnPaste(TextSelectionControls controls) {
    return widget.selectionEnabled &&_hasFocus && controls?.canPaste(this) == true
      ? () => controls.handlePaste(this)
      : null;
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    FocusScope.of(context).reparentIfNeeded(widget.focusNode);
    super.build(context); // See AutomaticKeepAliveClientMixin.

    final TextSelectionControls controls = widget.selectionControls;
    return Scrollable(
      excludeFromSemantics: true,
      axisDirection: _isMultiline ? AxisDirection.down : AxisDirection.right,
      controller: _scrollController,
      physics: const ClampingScrollPhysics(),
      dragStartBehavior: widget.dragStartBehavior,
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
              cursorColor: _cursorColor,
              backgroundCursorColor: widget.backgroundCursorColor,
              showCursor: EditableText.debugDeterministicCursor
                  ? ValueNotifier<bool>(true)
                  : _cursorVisibilityNotifier,
              hasFocus: _hasFocus,
              maxLines: widget.maxLines,
              minLines: widget.minLines,
              expands: widget.expands,
              strutStyle: widget.strutStyle,
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
              cursorOffset: widget.cursorOffset,
              paintCursorAboveText: widget.paintCursorAboveText,
              enableInteractiveSelection: widget.enableInteractiveSelection,
              textSelectionDelegate: this,
              devicePixelRatio: _devicePixelRatio,
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
    this.backgroundCursorColor,
    this.showCursor,
    this.hasFocus,
    this.maxLines,
    this.minLines,
    this.expands,
    this.strutStyle,
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
    this.cursorOffset,
    this.enableInteractiveSelection = true,
    this.textSelectionDelegate,
    this.paintCursorAboveText,
    this.devicePixelRatio,
  }) : assert(textDirection != null),
       assert(rendererIgnoresPointer != null),
       super(key: key);

  final TextSpan textSpan;
  final TextEditingValue value;
  final Color cursorColor;
  final Color backgroundCursorColor;
  final ValueNotifier<bool> showCursor;
  final bool hasFocus;
  final int maxLines;
  final int minLines;
  final bool expands;
  final StrutStyle strutStyle;
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
  final Offset cursorOffset;
  final bool enableInteractiveSelection;
  final TextSelectionDelegate textSelectionDelegate;
  final double devicePixelRatio;
  final bool paintCursorAboveText;

  @override
  RenderEditable createRenderObject(BuildContext context) {
    return RenderEditable(
      text: textSpan,
      cursorColor: cursorColor,
      backgroundCursorColor: backgroundCursorColor,
      showCursor: showCursor,
      hasFocus: hasFocus,
      maxLines: maxLines,
      minLines: minLines,
      expands: expands,
      strutStyle: strutStyle,
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
      cursorOffset: cursorOffset,
      paintCursorAboveText: paintCursorAboveText,
      enableInteractiveSelection: enableInteractiveSelection,
      textSelectionDelegate: textSelectionDelegate,
      devicePixelRatio: devicePixelRatio,
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
      ..minLines = minLines
      ..expands = expands
      ..strutStyle = strutStyle
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
      ..cursorOffset = cursorOffset
      ..textSelectionDelegate = textSelectionDelegate
      ..devicePixelRatio = devicePixelRatio
      ..paintCursorAboveText = paintCursorAboveText;
  }
}
