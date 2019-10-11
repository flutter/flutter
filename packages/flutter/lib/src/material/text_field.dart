// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

import 'debug.dart';
import 'feedback.dart';
import 'input_decorator.dart';
import 'material.dart';
import 'material_localizations.dart';
import 'selectable_text.dart' show iOSHorizontalOffset;
import 'text_selection.dart';
import 'theme.dart';

export 'package:flutter/services.dart' show TextInputType, TextInputAction, TextCapitalization;

/// Signature for the [TextField.buildCounter] callback.
typedef InputCounterWidgetBuilder = Widget Function(
  /// The build context for the TextField
  BuildContext context, {
  /// The length of the string currently in the input.
  @required int currentLength,
  /// The maximum string length that can be entered into the TextField.
  @required int maxLength,
  /// Whether or not the TextField is currently focused.  Mainly provided for
  /// the [liveRegion] parameter in the [Semantics] widget for accessibility.
  @required bool isFocused,
});

class _TextFieldSelectionGestureDetectorBuilder extends TextSelectionGestureDetectorBuilder {
  _TextFieldSelectionGestureDetectorBuilder({
    @required _TextFieldState state,
  }) : _state = state,
       super(delegate: state);

  final _TextFieldState _state;

  @override
  void onForcePressStart(ForcePressDetails details) {
    super.onForcePressStart(details);
    if (delegate.selectionEnabled && shouldShowSelectionToolbar) {
      editableText.showToolbar();
    }
  }

  @override
  void onForcePressEnd(ForcePressDetails details) {
    // Not required.
  }

  @override
  void onSingleLongTapMoveUpdate(LongPressMoveUpdateDetails details) {
    if (delegate.selectionEnabled) {
      switch (Theme.of(_state.context).platform) {
        case TargetPlatform.iOS:
          renderEditable.selectPositionAt(
            from: details.globalPosition,
            cause: SelectionChangedCause.longPress,
          );
          break;
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
          renderEditable.selectWordsInRange(
            from: details.globalPosition - details.offsetFromOrigin,
            to: details.globalPosition,
            cause: SelectionChangedCause.longPress,
          );
          break;
      }
    }
  }

  @override
  void onSingleTapUp(TapUpDetails details) {
    editableText.hideToolbar();
    if (delegate.selectionEnabled) {
      switch (Theme.of(_state.context).platform) {
        case TargetPlatform.iOS:
          renderEditable.selectWordEdge(cause: SelectionChangedCause.tap);
          break;
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
          renderEditable.selectPosition(cause: SelectionChangedCause.tap);
          break;
      }
    }
    _state._requestKeyboard();
    if (_state.widget.onTap != null)
      _state.widget.onTap();
  }

  @override
  void onSingleLongTapStart(LongPressStartDetails details) {
    if (delegate.selectionEnabled) {
      switch (Theme.of(_state.context).platform) {
        case TargetPlatform.iOS:
          renderEditable.selectPositionAt(
            from: details.globalPosition,
            cause: SelectionChangedCause.longPress,
          );
          break;
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
          renderEditable.selectWord(cause: SelectionChangedCause.longPress);
          Feedback.forLongPress(_state.context);
          break;
      }
    }
  }
}

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
/// one of its ancestors to be a [Material] widget.
///
/// To integrate the [TextField] into a [Form] with other [FormField] widgets,
/// consider using [TextFormField].
///
/// Remember to [dispose] of the [TextEditingController] when it is no longer needed.
/// This will ensure we discard any resources used by the object.
///
/// {@tool sample}
/// This example shows how to create a [TextField] that will obscure input. The
/// [InputDecoration] surrounds the field in a border using [OutlineInputBorder]
/// and adds a label.
///
/// ![](https://flutter.github.io/assets-for-api-docs/assets/material/text_field.png)
///
/// ```dart
/// TextField(
///   obscureText: true,
///   decoration: InputDecoration(
///     border: OutlineInputBorder(),
///     labelText: 'Password',
///   ),
/// )
/// ```
/// {@end-tool}
///
/// ## Reading values
///
/// A common way to read a value from a TextField is to use the [onSubmitted]
/// callback. This callback is applied to the text field's current value when
/// the user finishes editing.
///
/// {@tool dartpad --template=stateful_widget_material}
///
/// This sample shows how to get a value from a TextField via the [onSubmitted]
/// callback.
///
/// ```dart
/// TextEditingController _controller;
///
/// void initState() {
///   super.initState();
///   _controller = TextEditingController();
/// }
///
/// void dispose() {
///   _controller.dispose();
///   super.dispose();
/// }
///
/// Widget build(BuildContext context) {
///   return Scaffold(
///     body: Center(
///       child: TextField(
///         controller: _controller,
///         onSubmitted: (String value) async {
///           await showDialog<void>(
///             context: context,
///             builder: (BuildContext context) {
///               return AlertDialog(
///                 title: const Text('Thanks!'),
///                 content: Text ('You typed "$value".'),
///                 actions: <Widget>[
///                   FlatButton(
///                     onPressed: () { Navigator.pop(context); },
///                     child: const Text('OK'),
///                   ),
///                 ],
///               );
///             },
///           );
///         },
///       ),
///     ),
///   );
/// }
/// ```
/// {@end-tool}
///
/// For most applications the [onSubmitted] callback will be sufficient for
/// reacting to user input.
///
/// The [onEditingComplete] callback also runs when the user finishes editing.
/// It's different from [onSubmitted] because it has a default value which
/// updates the text controller and yields the keyboard focus. Applications that
/// require different behavior can override the default [onEditingComplete]
/// callback.
///
/// Keep in mind you can also always read the current string from a TextField's
/// [TextEditingController] using [TextEditingController.text].
///
/// See also:
///
///  * <https://material.io/design/components/text-fields.html>
///  * [TextFormField], which integrates with the [Form] widget.
///  * [InputDecorator], which shows the labels and other visual elements that
///    surround the actual text editing widget.
///  * [EditableText], which is the raw text editing control at the heart of a
///    [TextField]. The [EditableText] widget is rarely used directly unless
///    you are implementing an entirely different design language, such as
///    Cupertino.
///  * Learn how to use a [TextEditingController] in one of our
///    [cookbook recipe](https://flutter.dev/docs/cookbook/forms/text-field-changes#2-use-a-texteditingcontroller)s.
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
  /// [maxLength] is set a character counter will be displayed below the
  /// field showing how many characters have been entered. If the value is
  /// set to a positive integer it will also display the maximum allowed
  /// number of characters to be entered.  If the value is set to
  /// [TextField.noMaxLength] then only the current length is displayed.
  ///
  /// After [maxLength] characters have been input, additional input
  /// is ignored, unless [maxLengthEnforced] is set to false. The text field
  /// enforces the length with a [LengthLimitingTextInputFormatter], which is
  /// evaluated after the supplied [inputFormatters], if any. The [maxLength]
  /// value must be either null or greater than zero.
  ///
  /// If [maxLengthEnforced] is set to false, then more than [maxLength]
  /// characters may be entered, and the error counter and divider will
  /// switch to the [decoration.errorStyle] when the limit is exceeded.
  ///
  /// The text cursor is not shown if [showCursor] is false or if [showCursor]
  /// is null (the default) and [readOnly] is true.
  ///
  /// The [textAlign], [autofocus], [obscureText], [readOnly], [autocorrect],
  /// [maxLengthEnforced], [scrollPadding], [maxLines], and [maxLength]
  /// arguments must not be null.
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
    this.strutStyle,
    this.textAlign = TextAlign.start,
    this.textAlignVertical,
    this.textDirection,
    this.readOnly = false,
    ToolbarOptions toolbarOptions,
    this.showCursor,
    this.autofocus = false,
    this.obscureText = false,
    this.autocorrect = true,
    this.maxLines = 1,
    this.minLines,
    this.expands = false,
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
    this.dragStartBehavior = DragStartBehavior.start,
    this.enableInteractiveSelection = true,
    this.onTap,
    this.buildCounter,
    this.scrollController,
    this.scrollPhysics,
  }) : assert(textAlign != null),
       assert(readOnly != null),
       assert(autofocus != null),
       assert(obscureText != null),
       assert(autocorrect != null),
       assert(enableInteractiveSelection != null),
       assert(maxLengthEnforced != null),
       assert(scrollPadding != null),
       assert(dragStartBehavior != null),
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
       assert(maxLength == null || maxLength == TextField.noMaxLength || maxLength > 0),
       keyboardType = keyboardType ?? (maxLines == 1 ? TextInputType.text : TextInputType.multiline),
       toolbarOptions = toolbarOptions ?? (obscureText ?
         const ToolbarOptions(
           selectAll: true,
           paste: true,
         ) :
         const ToolbarOptions(
           copy: true,
           cut: true,
           selectAll: true,
           paste: true,
         )),
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
  /// Requesting the focus will typically cause the keyboard to be shown
  /// if it's not showing already.
  ///
  /// On Android, the user can hide the keyboard - without changing the focus -
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

  /// {@macro flutter.widgets.editableText.strutStyle}
  final StrutStyle strutStyle;

  /// {@macro flutter.widgets.editableText.textAlign}
  final TextAlign textAlign;

  /// {@macro flutter.material.inputDecorator.textAlignVertical}
  final TextAlignVertical textAlignVertical;

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

  /// {@macro flutter.widgets.editableText.minLines}
  final int minLines;

  /// {@macro flutter.widgets.editableText.expands}
  final bool expands;

  /// {@macro flutter.widgets.editableText.readOnly}
  final bool readOnly;

  /// Configuration of toolbar options.
  ///
  /// If not set, select all and paste will default to be enabled. Copy and cut
  /// will be disabled if [obscureText] is true. If [readOnly] is true,
  /// paste and cut will be disabled regardless.
  final ToolbarOptions toolbarOptions;

  /// {@macro flutter.widgets.editableText.showCursor}
  final bool showCursor;

  /// If [maxLength] is set to this value, only the "current input length"
  /// part of the character counter is shown.
  static const int noMaxLength = -1;

  /// The maximum number of characters (Unicode scalar values) to allow in the
  /// text field.
  ///
  /// If set, a character counter will be displayed below the
  /// field showing how many characters have been entered. If set to a number
  /// greater than 0, it will also display the maximum number allowed. If set
  /// to [TextField.noMaxLength] then only the current character count is displayed.
  ///
  /// After [maxLength] characters have been input, additional input
  /// is ignored, unless [maxLengthEnforced] is set to false. The text field
  /// enforces the length with a [LengthLimitingTextInputFormatter], which is
  /// evaluated after the supplied [inputFormatters], if any.
  ///
  /// This value must be either null, [TextField.noMaxLength], or greater than 0.
  /// If null (the default) then there is no limit to the number of characters
  /// that can be entered. If set to [TextField.noMaxLength], then no limit will
  /// be enforced, but the number of characters entered will still be displayed.
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
  /// The text field does not currently count Unicode grapheme clusters (i.e.
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
  ///
  /// See also:
  ///
  ///  * [inputFormatters], which are called before [onChanged]
  ///    runs and can validate and change ("format") the input value.
  ///  * [onEditingComplete], [onSubmitted], [onSelectionChanged]:
  ///    which are more specialized input change notifications.
  final ValueChanged<String> onChanged;

  /// {@macro flutter.widgets.editableText.onEditingComplete}
  final VoidCallback onEditingComplete;

  /// {@macro flutter.widgets.editableText.onSubmitted}
  ///
  /// See also:
  ///
  ///  * [EditableText.onSubmitted] for an example of how to handle moving to
  ///    the next/previous field when using [TextInputAction.next] and
  ///    [TextInputAction.previous] for [textInputAction].
  final ValueChanged<String> onSubmitted;

  /// {@macro flutter.widgets.editableText.inputFormatters}
  final List<TextInputFormatter> inputFormatters;

  /// If false the text field is "disabled": it ignores taps and its
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
  /// Defaults to [ThemeData.cursorColor] or [CupertinoTheme.primaryColor]
  /// depending on [ThemeData.platform].
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

  /// {@macro flutter.widgets.scrollable.dragStartBehavior}
  final DragStartBehavior dragStartBehavior;

  /// {@macro flutter.rendering.editable.selectionEnabled}
  bool get selectionEnabled => enableInteractiveSelection;

  /// {@template flutter.material.textfield.onTap}
  /// Called for each distinct tap except for every second tap of a double tap.
  ///
  /// The text field builds a [GestureDetector] to handle input events like tap,
  /// to trigger focus requests, to move the caret, adjust the selection, etc.
  /// Handling some of those events by wrapping the text field with a competing
  /// GestureDetector is problematic.
  ///
  /// To unconditionally handle taps, without interfering with the text field's
  /// internal gesture detector, provide this callback.
  ///
  /// If the text field is created with [enabled] false, taps will not be
  /// recognized.
  ///
  /// To be notified when the text field gains or loses the focus, provide a
  /// [focusNode] and add a listener to that.
  ///
  /// To listen to arbitrary pointer events without competing with the
  /// text field's internal gesture detector, use a [Listener].
  /// {@endtemplate}
  final GestureTapCallback onTap;

  /// Callback that generates a custom [InputDecorator.counter] widget.
  ///
  /// See [InputCounterWidgetBuilder] for an explanation of the passed in
  /// arguments.  The returned widget will be placed below the line in place of
  /// the default widget built when [counterText] is specified.
  ///
  /// The returned widget will be wrapped in a [Semantics] widget for
  /// accessibility, but it also needs to be accessible itself.  For example,
  /// if returning a Text widget, set the [semanticsLabel] property.
  ///
  /// {@tool sample}
  /// ```dart
  /// Widget counter(
  ///   BuildContext context,
  ///   {
  ///     int currentLength,
  ///     int maxLength,
  ///     bool isFocused,
  ///   }
  /// ) {
  ///   return Text(
  ///     '$currentLength of $maxLength characters',
  ///     semanticsLabel: 'character count',
  ///   );
  /// }
  /// ```
  /// {@end-tool}
  final InputCounterWidgetBuilder buildCounter;

  /// {@macro flutter.widgets.edtiableText.scrollPhysics}
  final ScrollPhysics scrollPhysics;

  /// {@macro flutter.widgets.editableText.scrollController}
  final ScrollController scrollController;

  @override
  _TextFieldState createState() => _TextFieldState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<TextEditingController>('controller', controller, defaultValue: null));
    properties.add(DiagnosticsProperty<FocusNode>('focusNode', focusNode, defaultValue: null));
    properties.add(DiagnosticsProperty<bool>('enabled', enabled, defaultValue: null));
    properties.add(DiagnosticsProperty<InputDecoration>('decoration', decoration, defaultValue: const InputDecoration()));
    properties.add(DiagnosticsProperty<TextInputType>('keyboardType', keyboardType, defaultValue: TextInputType.text));
    properties.add(DiagnosticsProperty<TextStyle>('style', style, defaultValue: null));
    properties.add(DiagnosticsProperty<bool>('autofocus', autofocus, defaultValue: false));
    properties.add(DiagnosticsProperty<bool>('obscureText', obscureText, defaultValue: false));
    properties.add(DiagnosticsProperty<bool>('autocorrect', autocorrect, defaultValue: true));
    properties.add(IntProperty('maxLines', maxLines, defaultValue: 1));
    properties.add(IntProperty('minLines', minLines, defaultValue: null));
    properties.add(DiagnosticsProperty<bool>('expands', expands, defaultValue: false));
    properties.add(IntProperty('maxLength', maxLength, defaultValue: null));
    properties.add(FlagProperty('maxLengthEnforced', value: maxLengthEnforced, defaultValue: true, ifFalse: 'maxLength not enforced'));
    properties.add(EnumProperty<TextInputAction>('textInputAction', textInputAction, defaultValue: null));
    properties.add(EnumProperty<TextCapitalization>('textCapitalization', textCapitalization, defaultValue: TextCapitalization.none));
    properties.add(EnumProperty<TextAlign>('textAlign', textAlign, defaultValue: TextAlign.start));
    properties.add(DiagnosticsProperty<TextAlignVertical>('textAlignVertical', textAlignVertical, defaultValue: null));
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection, defaultValue: null));
    properties.add(DoubleProperty('cursorWidth', cursorWidth, defaultValue: 2.0));
    properties.add(DiagnosticsProperty<Radius>('cursorRadius', cursorRadius, defaultValue: null));
    properties.add(ColorProperty('cursorColor', cursorColor, defaultValue: null));
    properties.add(DiagnosticsProperty<Brightness>('keyboardAppearance', keyboardAppearance, defaultValue: null));
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('scrollPadding', scrollPadding, defaultValue: const EdgeInsets.all(20.0)));
    properties.add(FlagProperty('selectionEnabled', value: selectionEnabled, defaultValue: true, ifFalse: 'selection disabled'));
    properties.add(DiagnosticsProperty<ScrollController>('scrollController', scrollController, defaultValue: null));
    properties.add(DiagnosticsProperty<ScrollPhysics>('scrollPhysics', scrollPhysics, defaultValue: null));
  }
}

class _TextFieldState extends State<TextField> implements TextSelectionGestureDetectorBuilderDelegate {
  TextEditingController _controller;
  TextEditingController get _effectiveController => widget.controller ?? _controller;

  FocusNode _focusNode;
  FocusNode get _effectiveFocusNode => widget.focusNode ?? (_focusNode ??= FocusNode());

  bool _isHovering = false;

  // Disables all directional focus actions inside of a text field, since up and
  // down shouldn't go to another field, even in a single line text field. We
  // remap the keys rather than the actions, since someone might want to invoke
  // a directional navigation action from another key binding.
  final Map<LogicalKeySet, Intent> _disabledNavigationKeys = <LogicalKeySet, Intent>{
    LogicalKeySet(LogicalKeyboardKey.arrowUp): const Intent(DoNothingAction.key),
    LogicalKeySet(LogicalKeyboardKey.arrowDown): const Intent(DoNothingAction.key),
    LogicalKeySet(LogicalKeyboardKey.arrowLeft): const Intent(DoNothingAction.key),
    LogicalKeySet(LogicalKeyboardKey.arrowRight): const Intent(DoNothingAction.key),
  };

  bool get needsCounter => widget.maxLength != null
    && widget.decoration != null
    && widget.decoration.counterText == null;

  bool _showSelectionHandles = false;

  _TextFieldSelectionGestureDetectorBuilder _selectionGestureDetectorBuilder;

  // API for TextSelectionGestureDetectorBuilderDelegate.
  @override
  bool forcePressEnabled;

  @override
  final GlobalKey<EditableTextState> editableTextKey = GlobalKey<EditableTextState>();

  @override
  bool get selectionEnabled => widget.selectionEnabled;
  // End of API for TextSelectionGestureDetectorBuilderDelegate.

  bool get _isEnabled =>  widget.enabled ?? widget.decoration?.enabled ?? true;

  int get _currentLength => _effectiveController.value.text.runes.length;

  InputDecoration _getEffectiveDecoration() {
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);
    final ThemeData themeData = Theme.of(context);
    final InputDecoration effectiveDecoration = (widget.decoration ?? const InputDecoration())
      .applyDefaults(themeData.inputDecorationTheme)
      .copyWith(
        enabled: widget.enabled,
        hintMaxLines: widget.decoration?.hintMaxLines ?? widget.maxLines,
      );

    // No need to build anything if counter or counterText were given directly.
    if (effectiveDecoration.counter != null || effectiveDecoration.counterText != null)
      return effectiveDecoration;

    // If buildCounter was provided, use it to generate a counter widget.
    Widget counter;
    final int currentLength = _currentLength;
    if (effectiveDecoration.counter == null
        && effectiveDecoration.counterText == null
        && widget.buildCounter != null) {
      final bool isFocused = _effectiveFocusNode.hasFocus;
      counter = Semantics(
        container: true,
        liveRegion: isFocused,
        child: widget.buildCounter(
          context,
          currentLength: currentLength,
          maxLength: widget.maxLength,
          isFocused: isFocused,
        ),
      );
      return effectiveDecoration.copyWith(counter: counter);
    }

    if (widget.maxLength == null)
      return effectiveDecoration; // No counter widget

    String counterText = '$currentLength';
    String semanticCounterText = '';

    // Handle a real maxLength (positive number)
    if (widget.maxLength > 0) {
      // Show the maxLength in the counter
      counterText += '/${widget.maxLength}';
      final int remaining = (widget.maxLength - currentLength).clamp(0, widget.maxLength);
      semanticCounterText = localizations.remainingTextFieldCharacterCount(remaining);

      // Handle length exceeds maxLength
      if (_effectiveController.value.text.runes.length > widget.maxLength) {
        return effectiveDecoration.copyWith(
          errorText: effectiveDecoration.errorText ?? '',
          counterStyle: effectiveDecoration.errorStyle
            ?? themeData.textTheme.caption.copyWith(color: themeData.errorColor),
          counterText: counterText,
          semanticCounterText: semanticCounterText,
        );
      }
    }

    return effectiveDecoration.copyWith(
      counterText: counterText,
      semanticCounterText: semanticCounterText,
    );
  }

  @override
  void initState() {
    super.initState();
    _selectionGestureDetectorBuilder = _TextFieldSelectionGestureDetectorBuilder(state: this);
    if (widget.controller == null) {
      _controller = TextEditingController();
    }
    _effectiveFocusNode.canRequestFocus = _isEnabled;
  }

  @override
  void didUpdateWidget(TextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller == null && oldWidget.controller != null)
      _controller = TextEditingController.fromValue(oldWidget.controller.value);
    else if (widget.controller != null && oldWidget.controller == null)
      _controller = null;
    _effectiveFocusNode.canRequestFocus = _isEnabled;
    if (_effectiveFocusNode.hasFocus && widget.readOnly != oldWidget.readOnly) {
      if(_effectiveController.selection.isCollapsed) {
        _showSelectionHandles = !widget.readOnly;
      }
    }
  }

  @override
  void dispose() {
    _focusNode?.dispose();
    super.dispose();
  }

  EditableTextState get _editableText => editableTextKey.currentState;

  void _requestKeyboard() {
    _editableText?.requestKeyboard();
  }

  bool _shouldShowSelectionHandles(SelectionChangedCause cause) {
    // When the text field is activated by something that doesn't trigger the
    // selection overlay, we shouldn't show the handles either.
    if (!_selectionGestureDetectorBuilder.shouldShowSelectionToolbar)
      return false;

    if (cause == SelectionChangedCause.keyboard)
      return false;

    if (widget.readOnly && _effectiveController.selection.isCollapsed)
      return false;

    if (cause == SelectionChangedCause.longPress)
      return true;

    if (_effectiveController.text.isNotEmpty)
      return true;

    return false;
  }

  void _handleSelectionChanged(TextSelection selection, SelectionChangedCause cause) {
    final bool willShowSelectionHandles = _shouldShowSelectionHandles(cause);
    if (willShowSelectionHandles != _showSelectionHandles) {
      setState(() {
        _showSelectionHandles = willShowSelectionHandles;
      });
    }

    switch (Theme.of(context).platform) {
      case TargetPlatform.iOS:
        if (cause == SelectionChangedCause.longPress) {
          _editableText?.bringIntoView(selection.base);
        }
        return;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        // Do nothing.
    }
  }

  /// Toggle the toolbar when a selection handle is tapped.
  void _handleSelectionHandleTapped() {
    if (_effectiveController.selection.isCollapsed) {
      _editableText.toggleToolbar();
    }
  }

  void _handleHover(bool hovering) {
    if (hovering != _isHovering) {
      setState(() {
        return _isHovering = hovering;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    // TODO(jonahwilliams): uncomment out this check once we have migrated tests.
    // assert(debugCheckHasMaterialLocalizations(context));
    assert(debugCheckHasDirectionality(context));
    assert(
      !(widget.style != null && widget.style.inherit == false &&
        (widget.style.fontSize == null || widget.style.textBaseline == null)),
      'inherit false style must supply fontSize and textBaseline',
    );

    final ThemeData themeData = Theme.of(context);
    final TextStyle style = themeData.textTheme.subhead.merge(widget.style);
    final Brightness keyboardAppearance = widget.keyboardAppearance ?? themeData.primaryColorBrightness;
    final TextEditingController controller = _effectiveController;
    final FocusNode focusNode = _effectiveFocusNode;
    final List<TextInputFormatter> formatters = widget.inputFormatters ?? <TextInputFormatter>[];
    if (widget.maxLength != null && widget.maxLengthEnforced)
      formatters.add(LengthLimitingTextInputFormatter(widget.maxLength));

    TextSelectionControls textSelectionControls;
    bool paintCursorAboveText;
    bool cursorOpacityAnimates;
    Offset cursorOffset;
    Color cursorColor = widget.cursorColor;
    Radius cursorRadius = widget.cursorRadius;

    switch (themeData.platform) {
      case TargetPlatform.iOS:
        forcePressEnabled = true;
        textSelectionControls = cupertinoTextSelectionControls;
        paintCursorAboveText = true;
        cursorOpacityAnimates = true;
        cursorColor ??= CupertinoTheme.of(context).primaryColor;
        cursorRadius ??= const Radius.circular(2.0);
        cursorOffset = Offset(iOSHorizontalOffset / MediaQuery.of(context).devicePixelRatio, 0);
        break;

      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        forcePressEnabled = false;
        textSelectionControls = materialTextSelectionControls;
        paintCursorAboveText = false;
        cursorOpacityAnimates = false;
        cursorColor ??= themeData.cursorColor;
        break;
    }

    Widget child = RepaintBoundary(
      child: Shortcuts(
        shortcuts: _disabledNavigationKeys,
        child: EditableText(
          key: editableTextKey,
          readOnly: widget.readOnly,
          toolbarOptions: widget.toolbarOptions,
          showCursor: widget.showCursor,
          showSelectionHandles: _showSelectionHandles,
          controller: controller,
          focusNode: focusNode,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          textCapitalization: widget.textCapitalization,
          style: style,
          strutStyle: widget.strutStyle,
          textAlign: widget.textAlign,
          textDirection: widget.textDirection,
          autofocus: widget.autofocus,
          obscureText: widget.obscureText,
          autocorrect: widget.autocorrect,
          maxLines: widget.maxLines,
          minLines: widget.minLines,
          expands: widget.expands,
          selectionColor: themeData.textSelectionColor,
          selectionControls: widget.selectionEnabled ? textSelectionControls : null,
          onChanged: widget.onChanged,
          onSelectionChanged: _handleSelectionChanged,
          onEditingComplete: widget.onEditingComplete,
          onSubmitted: widget.onSubmitted,
          onSelectionHandleTapped: _handleSelectionHandleTapped,
          inputFormatters: formatters,
          rendererIgnoresPointer: true,
          cursorWidth: widget.cursorWidth,
          cursorRadius: cursorRadius,
          cursorColor: cursorColor,
          cursorOpacityAnimates: cursorOpacityAnimates,
          cursorOffset: cursorOffset,
          paintCursorAboveText: paintCursorAboveText,
          backgroundCursorColor: CupertinoColors.inactiveGray,
          scrollPadding: widget.scrollPadding,
          keyboardAppearance: keyboardAppearance,
          enableInteractiveSelection: widget.enableInteractiveSelection,
          dragStartBehavior: widget.dragStartBehavior,
          scrollController: widget.scrollController,
          scrollPhysics: widget.scrollPhysics,
        ),
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
            textAlignVertical: widget.textAlignVertical,
            isHovering: _isHovering,
            isFocused: focusNode.hasFocus,
            isEmpty: controller.value.text.isEmpty,
            expands: widget.expands,
            child: child,
          );
        },
        child: child,
      );
    }
    return IgnorePointer(
      ignoring: !_isEnabled,
      child: MouseRegion(
        onEnter: (PointerEnterEvent event) => _handleHover(true),
        onExit: (PointerExitEvent event) => _handleHover(false),
        child: AnimatedBuilder(
          animation: controller, // changes the _currentLength
          builder: (BuildContext context, Widget child) {
            return Semantics(
              maxValueLength: widget.maxLengthEnforced && widget.maxLength != null && widget.maxLength > 0
                  ? widget.maxLength
                  : null,
              currentValueLength: _currentLength,
              onTap: () {
                if (!_effectiveController.selection.isValid)
                  _effectiveController.selection = TextSelection.collapsed(offset: _effectiveController.text.length);
                _requestKeyboard();
              },
              child: child,
            );
          },
          child: _selectionGestureDetectorBuilder.buildGestureDetector(
            behavior: HitTestBehavior.translucent,
            child: child,
          ),
        ),
      ),
    );
  }
}
