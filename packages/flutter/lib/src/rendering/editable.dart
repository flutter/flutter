// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui' as ui show TextBox, BoxHeightStyle, BoxWidthStyle;

import 'package:characters/characters.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import 'box.dart';
import 'custom_paint.dart';
import 'layer.dart';
import 'object.dart';
import 'viewport_offset.dart';

const double _kCaretGap = 1.0; // pixels
const double _kCaretHeightOffset = 2.0; // pixels

// The additional size on the x and y axis with which to expand the prototype
// cursor to render the floating cursor in pixels.
const EdgeInsets _kFloatingCaretSizeIncrease = EdgeInsets.symmetric(horizontal: 0.5, vertical: 1.0);

// The corner radius of the floating cursor in pixels.
const Radius _kFloatingCaretRadius = Radius.circular(1.0);

/// Signature for the callback that reports when the user changes the selection
/// (including the cursor location).
///
/// Used by [RenderEditable.onSelectionChanged].
@Deprecated(
  'Signature of a deprecated class method, '
  'textSelectionDelegate.userUpdateTextEditingValue. '
  'This feature was deprecated after v1.26.0-17.2.pre.',
)
typedef SelectionChangedHandler = void Function(TextSelection selection, RenderEditable renderObject, SelectionChangedCause cause);

/// Signature for the callback that reports when the caret location changes.
///
/// Used by [RenderEditable.onCaretChanged].
typedef CaretChangedHandler = void Function(Rect caretRect);

/// Represents the coordinates of the point in a selection, and the text
/// direction at that point, relative to top left of the [RenderEditable] that
/// holds the selection.
@immutable
class TextSelectionPoint {
  /// Creates a description of a point in a text selection.
  ///
  /// The [point] argument must not be null.
  const TextSelectionPoint(this.point, this.direction)
    : assert(point != null);

  /// Coordinates of the lower left or lower right corner of the selection,
  /// relative to the top left of the [RenderEditable] object.
  final Offset point;

  /// Direction of the text at this edge of the selection.
  final TextDirection? direction;

  @override
  String toString() {
    switch (direction) {
      case TextDirection.ltr:
        return '$point-ltr';
      case TextDirection.rtl:
        return '$point-rtl';
      case null:
        return '$point';
    }
  }
}

// Check if the given code unit is a white space or separator
// character.
//
// Includes newline characters from ASCII and separators from the
// [unicode separator category](https://www.compart.com/en/unicode/category/Zs)
// TODO(gspencergoog): replace when we expose this ICU information.
bool _isWhitespace(int codeUnit) {
  switch (codeUnit) {
    case 0x9: // horizontal tab
    case 0xA: // line feed
    case 0xB: // vertical tab
    case 0xC: // form feed
    case 0xD: // carriage return
    case 0x1C: // file separator
    case 0x1D: // group separator
    case 0x1E: // record separator
    case 0x1F: // unit separator
    case 0x20: // space
    case 0xA0: // no-break space
    case 0x1680: // ogham space mark
    case 0x2000: // en quad
    case 0x2001: // em quad
    case 0x2002: // en space
    case 0x2003: // em space
    case 0x2004: // three-per-em space
    case 0x2005: // four-er-em space
    case 0x2006: // six-per-em space
    case 0x2007: // figure space
    case 0x2008: // punctuation space
    case 0x2009: // thin space
    case 0x200A: // hair space
    case 0x202F: // narrow no-break space
    case 0x205F: // medium mathematical space
    case 0x3000: // ideographic space
      break;
    default:
      return false;
  }
  return true;
}

/// Displays some text in a scrollable container with a potentially blinking
/// cursor and with gesture recognizers.
///
/// This is the renderer for an editable text field. It does not directly
/// provide affordances for editing the text, but it does handle text selection
/// and manipulation of the text cursor.
///
/// The [text] is displayed, scrolled by the given [offset], aligned according
/// to [textAlign]. The [maxLines] property controls whether the text displays
/// on one line or many. The [selection], if it is not collapsed, is painted in
/// the [selectionColor]. If it _is_ collapsed, then it represents the cursor
/// position. The cursor is shown while [showCursor] is true. It is painted in
/// the [cursorColor].
///
/// If, when the render object paints, the caret is found to have changed
/// location, [onCaretChanged] is called.
///
/// Keyboard handling, IME handling, scrolling, toggling the [showCursor] value
/// to actually blink the cursor, and other features not mentioned above are the
/// responsibility of higher layers and not handled by this object.
class RenderEditable extends RenderBox with RelayoutWhenSystemFontsChangeMixin {
  /// Creates a render object that implements the visual aspects of a text field.
  ///
  /// The [textAlign] argument must not be null. It defaults to [TextAlign.start].
  ///
  /// The [textDirection] argument must not be null.
  ///
  /// If [showCursor] is not specified, then it defaults to hiding the cursor.
  ///
  /// The [maxLines] property can be set to null to remove the restriction on
  /// the number of lines. By default, it is 1, meaning this is a single-line
  /// text field. If it is not null, it must be greater than zero.
  ///
  /// The [offset] is required and must not be null. You can use [new
  /// ViewportOffset.zero] if you have no need for scrolling.
  RenderEditable({
    TextSpan? text,
    required TextDirection textDirection,
    TextAlign textAlign = TextAlign.start,
    Color? cursorColor,
    Color? backgroundCursorColor,
    ValueNotifier<bool>? showCursor,
    bool? hasFocus,
    required LayerLink startHandleLayerLink,
    required LayerLink endHandleLayerLink,
    int? maxLines = 1,
    int? minLines,
    bool expands = false,
    StrutStyle? strutStyle,
    Color? selectionColor,
    double textScaleFactor = 1.0,
    TextSelection? selection,
    required ViewportOffset offset,
    @Deprecated(
      'Uses the textSelectionDelegate.userUpdateTextEditingValue instead. '
      'This feature was deprecated after v1.26.0-17.2.pre.',
    )
    this.onSelectionChanged,
    this.onCaretChanged,
    this.ignorePointer = false,
    bool readOnly = false,
    bool forceLine = true,
    TextHeightBehavior? textHeightBehavior,
    TextWidthBasis textWidthBasis = TextWidthBasis.parent,
    String obscuringCharacter = '•',
    bool obscureText = false,
    Locale? locale,
    double cursorWidth = 1.0,
    double? cursorHeight,
    Radius? cursorRadius,
    bool paintCursorAboveText = false,
    Offset cursorOffset = Offset.zero,
    double devicePixelRatio = 1.0,
    ui.BoxHeightStyle selectionHeightStyle = ui.BoxHeightStyle.tight,
    ui.BoxWidthStyle selectionWidthStyle = ui.BoxWidthStyle.tight,
    bool? enableInteractiveSelection,
    this.floatingCursorAddedMargin = const EdgeInsets.fromLTRB(4, 4, 4, 5),
    TextRange? promptRectRange,
    Color? promptRectColor,
    Clip clipBehavior = Clip.hardEdge,
    required this.textSelectionDelegate,
    RenderEditablePainter? painter,
    RenderEditablePainter? foregroundPainter,
  }) : assert(textAlign != null),
       assert(textDirection != null, 'RenderEditable created without a textDirection.'),
       assert(maxLines == null || maxLines > 0),
       assert(minLines == null || minLines > 0),
       assert(startHandleLayerLink != null),
       assert(endHandleLayerLink != null),
       assert(
         (maxLines == null) || (minLines == null) || (maxLines >= minLines),
         "minLines can't be greater than maxLines",
       ),
       assert(expands != null),
       assert(
         !expands || (maxLines == null && minLines == null),
         'minLines and maxLines must be null when expands is true.',
       ),
       assert(textScaleFactor != null),
       assert(offset != null),
       assert(ignorePointer != null),
       assert(textWidthBasis != null),
       assert(paintCursorAboveText != null),
       assert(obscuringCharacter != null && obscuringCharacter.characters.length == 1),
       assert(obscureText != null),
       assert(textSelectionDelegate != null),
       assert(cursorWidth != null && cursorWidth >= 0.0),
       assert(cursorHeight == null || cursorHeight >= 0.0),
       assert(readOnly != null),
       assert(forceLine != null),
       assert(devicePixelRatio != null),
       assert(selectionHeightStyle != null),
       assert(selectionWidthStyle != null),
       assert(clipBehavior != null),
       _textPainter = TextPainter(
         text: text,
         textAlign: textAlign,
         textDirection: textDirection,
         textScaleFactor: textScaleFactor,
         locale: locale,
         strutStyle: strutStyle,
         textHeightBehavior: textHeightBehavior,
         textWidthBasis: textWidthBasis,
       ),
       _showCursor = showCursor ?? ValueNotifier<bool>(false),
       _maxLines = maxLines,
       _minLines = minLines,
       _expands = expands,
       _selection = selection,
       _offset = offset,
       _cursorWidth = cursorWidth,
       _cursorHeight = cursorHeight,
       _paintCursorOnTop = paintCursorAboveText,
       _enableInteractiveSelection = enableInteractiveSelection,
       _devicePixelRatio = devicePixelRatio,
       _startHandleLayerLink = startHandleLayerLink,
       _endHandleLayerLink = endHandleLayerLink,
       _obscuringCharacter = obscuringCharacter,
       _obscureText = obscureText,
       _readOnly = readOnly,
       _forceLine = forceLine,
       _clipBehavior = clipBehavior,
       _hasFocus = hasFocus ?? false {
    assert(_showCursor != null);
    assert(!_showCursor.value || cursorColor != null);

    _selectionPainter.highlightColor = selectionColor;
    _selectionPainter.highlightedRange = selection;
    _selectionPainter.selectionHeightStyle = selectionHeightStyle;
    _selectionPainter.selectionWidthStyle = selectionWidthStyle;

    _autocorrectHighlightPainter.highlightColor = promptRectColor;
    _autocorrectHighlightPainter.highlightedRange = promptRectRange;

    _caretPainter.caretColor = cursorColor;
    _caretPainter.cursorRadius = cursorRadius;
    _caretPainter.cursorOffset = cursorOffset;
    _caretPainter.backgroundCursorColor = backgroundCursorColor;

    _updateForegroundPainter(foregroundPainter);
    _updatePainter(painter);
  }

  /// Child render objects
  _RenderEditableCustomPaint? _foregroundRenderObject;
  _RenderEditableCustomPaint? _backgroundRenderObject;

  void _updateForegroundPainter(RenderEditablePainter? newPainter) {
    final _CompositeRenderEditablePainter effectivePainter = newPainter == null
      ? _builtInForegroundPainters
      : _CompositeRenderEditablePainter(painters: <RenderEditablePainter>[
         _builtInForegroundPainters,
         newPainter,
      ]);

    if (_foregroundRenderObject == null) {
      final _RenderEditableCustomPaint foregroundRenderObject = _RenderEditableCustomPaint(painter: effectivePainter);
      adoptChild(foregroundRenderObject);
      _foregroundRenderObject = foregroundRenderObject;
    } else {
      _foregroundRenderObject?.painter = effectivePainter;
    }
    _foregroundPainter = newPainter;
  }

  /// The [RenderEditablePainter] to use for painting above this
  /// [RenderEditable]'s text content.
  ///
  /// The new [RenderEditablePainter] will replace the previously specified
  /// foreground painter, and schedule a repaint if the new painter's
  /// `shouldRepaint` method returns true.
  RenderEditablePainter? get foregroundPainter => _foregroundPainter;
  RenderEditablePainter? _foregroundPainter;
  set foregroundPainter(RenderEditablePainter? newPainter) {
    if (newPainter == _foregroundPainter)
      return;
    _updateForegroundPainter(newPainter);
  }

  void _updatePainter(RenderEditablePainter? newPainter) {
    final _CompositeRenderEditablePainter effectivePainter = newPainter == null
      ? _builtInPainters
      : _CompositeRenderEditablePainter(painters: <RenderEditablePainter>[_builtInPainters, newPainter]);

    if (_backgroundRenderObject == null) {
      final _RenderEditableCustomPaint backgroundRenderObject = _RenderEditableCustomPaint(painter: effectivePainter);
      adoptChild(backgroundRenderObject);
      _backgroundRenderObject = backgroundRenderObject;
    } else {
      _backgroundRenderObject?.painter = effectivePainter;
    }
    _painter = newPainter;
  }

  /// Sets the [RenderEditablePainter] to use for painting beneath this
  /// [RenderEditable]'s text content.
  ///
  /// The new [RenderEditablePainter] will replace the previously specified
  /// painter, and schedule a repaint if the new painter's `shouldRepaint`
  /// method returns true.
  RenderEditablePainter? get painter => _painter;
  RenderEditablePainter? _painter;
  set painter(RenderEditablePainter? newPainter) {
    if (newPainter == _painter)
      return;
    _updatePainter(newPainter);
  }

  // Caret Painters:
  // The floating painter. This painter paints the regular caret as well.
  late final _FloatingCursorPainter _caretPainter = _FloatingCursorPainter(_onCaretChanged);

  // Text Highlight painters:
  final _TextHighlightPainter _selectionPainter = _TextHighlightPainter();
  final _TextHighlightPainter _autocorrectHighlightPainter = _TextHighlightPainter();

  _CompositeRenderEditablePainter get _builtInForegroundPainters => _cachedBuiltInForegroundPainters ??= _createBuiltInForegroundPainters();
  _CompositeRenderEditablePainter? _cachedBuiltInForegroundPainters;
  _CompositeRenderEditablePainter _createBuiltInForegroundPainters() {
    return _CompositeRenderEditablePainter(
      painters: <RenderEditablePainter>[
        if (paintCursorAboveText) _caretPainter,
      ],
    );
  }

  _CompositeRenderEditablePainter get _builtInPainters => _cachedBuiltInPainters ??= _createBuiltInPainters();
  _CompositeRenderEditablePainter? _cachedBuiltInPainters;
  _CompositeRenderEditablePainter _createBuiltInPainters() {
    return _CompositeRenderEditablePainter(
      painters: <RenderEditablePainter>[
        _autocorrectHighlightPainter,
        _selectionPainter,
        if (!paintCursorAboveText) _caretPainter,
      ],
    );
  }
  /// Called when the selection changes.
  ///
  /// If this is null, then selection changes will be ignored.
  @Deprecated(
    'Uses the textSelectionDelegate.userUpdateTextEditingValue instead. '
    'This feature was deprecated after v1.26.0-17.2.pre.',
  )
  SelectionChangedHandler? onSelectionChanged;

  double? _textLayoutLastMaxWidth;
  double? _textLayoutLastMinWidth;

  Rect? _lastCaretRect;
  // TODO(LongCatIsLooong): currently EditableText uses this callback to keep
  // the text field visible. But we don't always paint the caret, for example
  // when the selection is not collapsed.
  /// Called during the paint phase when the caret location changes.
  CaretChangedHandler? onCaretChanged;
  void _onCaretChanged(Rect caretRect) {
    if (_lastCaretRect != caretRect)
      onCaretChanged?.call(caretRect);
    _lastCaretRect = onCaretChanged == null ? null : caretRect;
  }

  /// Whether the [handleEvent] will propagate pointer events to selection
  /// handlers.
  ///
  /// If this property is true, the [handleEvent] assumes that this renderer
  /// will be notified of input gestures via [handleTapDown], [handleTap],
  /// [handleDoubleTap], and [handleLongPress].
  ///
  /// If there are any gesture recognizers in the text span, the [handleEvent]
  /// will still propagate pointer events to those recognizers.
  ///
  /// The default value of this property is false.
  bool ignorePointer;

  /// {@macro flutter.dart:ui.textHeightBehavior}
  TextHeightBehavior? get textHeightBehavior => _textPainter.textHeightBehavior;
  set textHeightBehavior(TextHeightBehavior? value) {
    if (_textPainter.textHeightBehavior == value)
      return;
    _textPainter.textHeightBehavior = value;
    markNeedsTextLayout();
  }

  /// {@macro flutter.painting.textPainter.textWidthBasis}
  TextWidthBasis get textWidthBasis => _textPainter.textWidthBasis;
  set textWidthBasis(TextWidthBasis value) {
    assert(value != null);
    if (_textPainter.textWidthBasis == value)
      return;
    _textPainter.textWidthBasis = value;
    markNeedsTextLayout();
  }

  /// The pixel ratio of the current device.
  ///
  /// Should be obtained by querying MediaQuery for the devicePixelRatio.
  double get devicePixelRatio => _devicePixelRatio;
  double _devicePixelRatio;
  set devicePixelRatio(double value) {
    if (devicePixelRatio == value)
      return;
    _devicePixelRatio = value;
    markNeedsTextLayout();
  }

  /// Character used for obscuring text if [obscureText] is true.
  ///
  /// Cannot be null, and must have a length of exactly one.
  String get obscuringCharacter => _obscuringCharacter;
  String _obscuringCharacter;
  set obscuringCharacter(String value) {
    if (_obscuringCharacter == value) {
      return;
    }
    assert(value != null && value.characters.length == 1);
    _obscuringCharacter = value;
    markNeedsLayout();
  }

  /// Whether to hide the text being edited (e.g., for passwords).
  bool get obscureText => _obscureText;
  bool _obscureText;
  set obscureText(bool value) {
    if (_obscureText == value)
      return;
    _obscureText = value;
    markNeedsSemanticsUpdate();
  }

  /// Controls how tall the selection highlight boxes are computed to be.
  ///
  /// See [ui.BoxHeightStyle] for details on available styles.
  ui.BoxHeightStyle get selectionHeightStyle => _selectionPainter.selectionHeightStyle;
  set selectionHeightStyle(ui.BoxHeightStyle value) {
    _selectionPainter.selectionHeightStyle = value;
  }

  /// Controls how wide the selection highlight boxes are computed to be.
  ///
  /// See [ui.BoxWidthStyle] for details on available styles.
  ui.BoxWidthStyle get selectionWidthStyle => _selectionPainter.selectionWidthStyle;
  set selectionWidthStyle(ui.BoxWidthStyle value) {
    _selectionPainter.selectionWidthStyle = value;
  }


  /// The object that controls the text selection, used by this render object
  /// for implementing cut, copy, and paste keyboard shortcuts.
  ///
  /// It must not be null. It will make cut, copy and paste functionality work
  /// with the most recently set [TextSelectionDelegate].
  TextSelectionDelegate textSelectionDelegate;

  /// Track whether position of the start of the selected text is within the viewport.
  ///
  /// For example, if the text contains "Hello World", and the user selects
  /// "Hello", then scrolls so only "World" is visible, this will become false.
  /// If the user scrolls back so that the "H" is visible again, this will
  /// become true.
  ///
  /// This bool indicates whether the text is scrolled so that the handle is
  /// inside the text field viewport, as opposed to whether it is actually
  /// visible on the screen.
  ValueListenable<bool> get selectionStartInViewport => _selectionStartInViewport;
  final ValueNotifier<bool> _selectionStartInViewport = ValueNotifier<bool>(true);

  /// Track whether position of the end of the selected text is within the viewport.
  ///
  /// For example, if the text contains "Hello World", and the user selects
  /// "World", then scrolls so only "Hello" is visible, this will become
  /// 'false'. If the user scrolls back so that the "d" is visible again, this
  /// will become 'true'.
  ///
  /// This bool indicates whether the text is scrolled so that the handle is
  /// inside the text field viewport, as opposed to whether it is actually
  /// visible on the screen.
  ValueListenable<bool> get selectionEndInViewport => _selectionEndInViewport;
  final ValueNotifier<bool> _selectionEndInViewport = ValueNotifier<bool>(true);

  void _updateSelectionExtentsVisibility(Offset effectiveOffset) {
    assert(selection != null);
    final Rect visibleRegion = Offset.zero & size;

    final Offset startOffset = _textPainter.getOffsetForCaret(
      TextPosition(offset: selection!.start, affinity: selection!.affinity),
      _caretPrototype,
    );
    // TODO(justinmc): https://github.com/flutter/flutter/issues/31495
    // Check if the selection is visible with an approximation because a
    // difference between rounded and unrounded values causes the caret to be
    // reported as having a slightly (< 0.5) negative y offset. This rounding
    // happens in paragraph.cc's layout and TextPainer's
    // _applyFloatingPointHack. Ideally, the rounding mismatch will be fixed and
    // this can be changed to be a strict check instead of an approximation.
    const double visibleRegionSlop = 0.5;
    _selectionStartInViewport.value = visibleRegion
      .inflate(visibleRegionSlop)
      .contains(startOffset + effectiveOffset);

    final Offset endOffset =  _textPainter.getOffsetForCaret(
      TextPosition(offset: selection!.end, affinity: selection!.affinity),
      _caretPrototype,
    );
    _selectionEndInViewport.value = visibleRegion
      .inflate(visibleRegionSlop)
      .contains(endOffset + effectiveOffset);
  }

  // Holds the last cursor location the user selected in the case the user tries
  // to select vertically past the end or beginning of the field. If they do,
  // then we need to keep the old cursor location so that we can go back to it
  // if they change their minds. Only used for moving selection up and down in a
  // multiline text field when selecting using the keyboard.
  int _cursorResetLocation = -1;

  // Whether we should reset the location of the cursor in the case the user
  // tries to select vertically past the end or beginning of the field. If they
  // do, then we need to keep the old cursor location so that we can go back to
  // it if they change their minds. Only used for resetting selection up and
  // down in a multiline text field when selecting using the keyboard.
  bool _wasSelectingVerticallyWithKeyboard = false;

  void _setTextEditingValue(TextEditingValue newValue, SelectionChangedCause cause) {
    textSelectionDelegate.textEditingValue = newValue;
    textSelectionDelegate.userUpdateTextEditingValue(newValue, cause);
  }

  void _setSelection(TextSelection nextSelection, SelectionChangedCause cause) {
    if (nextSelection.isValid) {
      // The nextSelection is calculated based on _plainText, which can be out
      // of sync with the textSelectionDelegate.textEditingValue by one frame.
      // This is due to the render editable and editable text handle pointer
      // event separately. If the editable text changes the text during the
      // event handler, the render editable will use the outdated text stored in
      // the _plainText when handling the pointer event.
      //
      // If this happens, we need to make sure the new selection is still valid.
      final int textLength = textSelectionDelegate.textEditingValue.text.length;
      nextSelection = nextSelection.copyWith(
        baseOffset: math.min(nextSelection.baseOffset, textLength),
        extentOffset: math.min(nextSelection.extentOffset, textLength),
      );
    }
    _handleSelectionChange(nextSelection, cause);
    _setTextEditingValue(
      textSelectionDelegate.textEditingValue.copyWith(selection: nextSelection),
      cause,
    );
  }

  void _handleSelectionChange(
    TextSelection nextSelection,
    SelectionChangedCause cause,
  ) {
    // Changes made by the keyboard can sometimes be "out of band" for listening
    // components, so always send those events, even if we didn't think it
    // changed. Also, focusing an empty field is sent as a selection change even
    // if the selection offset didn't change.
    final bool focusingEmpty = nextSelection.baseOffset == 0 && nextSelection.extentOffset == 0 && !hasFocus;
    if (nextSelection == selection && cause != SelectionChangedCause.keyboard && !focusingEmpty) {
      return;
    }
    onSelectionChanged?.call(nextSelection, this, cause);
  }

  static final Set<LogicalKeyboardKey> _movementKeys = <LogicalKeyboardKey>{
    LogicalKeyboardKey.arrowRight,
    LogicalKeyboardKey.arrowLeft,
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.arrowDown,
  };

  static final Set<LogicalKeyboardKey> _shortcutKeys = <LogicalKeyboardKey>{
    LogicalKeyboardKey.keyA,
    LogicalKeyboardKey.keyC,
    LogicalKeyboardKey.keyV,
    LogicalKeyboardKey.keyX,
    LogicalKeyboardKey.delete,
    LogicalKeyboardKey.backspace,
  };

  static final Set<LogicalKeyboardKey> _nonModifierKeys = <LogicalKeyboardKey>{
    ..._shortcutKeys,
    ..._movementKeys,
  };

  static final Set<LogicalKeyboardKey> _modifierKeys = <LogicalKeyboardKey>{
    LogicalKeyboardKey.shift,
    LogicalKeyboardKey.control,
    LogicalKeyboardKey.alt,
  };

  static final Set<LogicalKeyboardKey> _macOsModifierKeys = <LogicalKeyboardKey>{
    LogicalKeyboardKey.shift,
    LogicalKeyboardKey.meta,
    LogicalKeyboardKey.alt,
  };

  static final Set<LogicalKeyboardKey> _interestingKeys = <LogicalKeyboardKey>{
    ..._modifierKeys,
    ..._macOsModifierKeys,
    ..._nonModifierKeys,
  };

  void _handleKeyEvent(RawKeyEvent keyEvent) {
    if (kIsWeb) {
      // On web platform, we should ignore the key because it's processed already.
      return;
    }

    if (keyEvent is! RawKeyDownEvent)
      return;
    final Set<LogicalKeyboardKey> keysPressed = LogicalKeyboardKey.collapseSynonyms(RawKeyboard.instance.keysPressed);
    final LogicalKeyboardKey key = keyEvent.logicalKey;

    final bool isMacOS = keyEvent.data is RawKeyEventDataMacOs;
    if (!_nonModifierKeys.contains(key) ||
        keysPressed.difference(isMacOS ? _macOsModifierKeys : _modifierKeys).length > 1 ||
        keysPressed.difference(_interestingKeys).isNotEmpty) {
      // If the most recently pressed key isn't a non-modifier key, or more than
      // one non-modifier key is down, or keys other than the ones we're interested in
      // are pressed, just ignore the keypress.
      return;
    }

    // TODO(ianh): It seems to be entirely possible for the selection to be null here, but
    // all the keyboard handling functions assume it is not.
    assert(selection != null);

    final bool isShortcutModifierPressed = isMacOS ? keyEvent.isMetaPressed : keyEvent.isControlPressed;
    if (isShortcutModifierPressed && _shortcutKeys.contains(key)) {
      // _handleShortcuts depends on being started in the same stack invocation
      // as the _handleKeyEvent method
      _handleShortcuts(key);
    } else if (key == LogicalKeyboardKey.delete) {
      _handleDelete(forward: true);
    } else if (key == LogicalKeyboardKey.backspace) {
      _handleDelete(forward: false);
    }
  }

  /// Returns the index into the string of the next character boundary after the
  /// given index.
  ///
  /// The character boundary is determined by the characters package, so
  /// surrogate pairs and extended grapheme clusters are considered.
  ///
  /// The index must be between 0 and string.length, inclusive. If given
  /// string.length, string.length is returned.
  ///
  /// Setting includeWhitespace to false will only return the index of non-space
  /// characters.
  @visibleForTesting
  static int nextCharacter(int index, String string, [bool includeWhitespace = true]) {
    assert(index >= 0 && index <= string.length);
    if (index == string.length) {
      return string.length;
    }

    int count = 0;
    final Characters remaining = string.characters.skipWhile((String currentString) {
      if (count <= index) {
        count += currentString.length;
        return true;
      }
      if (includeWhitespace) {
        return false;
      }
      return _isWhitespace(currentString.codeUnitAt(0));
    });
    return string.length - remaining.toString().length;
  }

  /// Returns the index into the string of the previous character boundary
  /// before the given index.
  ///
  /// The character boundary is determined by the characters package, so
  /// surrogate pairs and extended grapheme clusters are considered.
  ///
  /// The index must be between 0 and string.length, inclusive. If index is 0,
  /// 0 will be returned.
  ///
  /// Setting includeWhitespace to false will only return the index of non-space
  /// characters.
  @visibleForTesting
  static int previousCharacter(int index, String string, [bool includeWhitespace = true]) {
    assert(index >= 0 && index <= string.length);
    if (index == 0) {
      return 0;
    }

    int count = 0;
    int? lastNonWhitespace;
    for (final String currentString in string.characters) {
      if (!includeWhitespace &&
          !_isWhitespace(currentString.characters.first.toString().codeUnitAt(0))) {
        lastNonWhitespace = count;
      }
      if (count + currentString.length >= index) {
        return includeWhitespace ? count : lastNonWhitespace ?? 0;
      }
      count += currentString.length;
    }
    return 0;
  }

  // Return a new selection that has been moved left once.
  //
  // If it can't be moved left, the original TextSelection is returned.
  static TextSelection _moveGivenSelectionLeft(TextSelection selection, String text) {
    // If the selection is already all the way left, there is nothing to do.
    if (selection.isCollapsed && selection.extentOffset <= 0) {
      return selection;
    }

    int previousExtent;
    if (selection.start != selection.end) {
      previousExtent = selection.start;
    } else {
      previousExtent = previousCharacter(selection.extentOffset, text);
    }
    final TextSelection newSelection = selection.copyWith(
      extentOffset: previousExtent,
    );

    final int newOffset = newSelection.extentOffset;
    return TextSelection.fromPosition(TextPosition(offset: newOffset));
  }

  // Return a new selection that has been moved right once.
  //
  // If it can't be moved right, the original TextSelection is returned.
  static TextSelection _moveGivenSelectionRight(TextSelection selection, String text) {
    // If the selection is already all the way right, there is nothing to do.
    if (selection.isCollapsed && selection.extentOffset >= text.length) {
      return selection;
    }

    int nextExtent;
    if (selection.start != selection.end) {
      nextExtent = selection.end;
    } else {
      nextExtent = nextCharacter(selection.extentOffset, text);
    }
    final TextSelection nextSelection = selection.copyWith(extentOffset: nextExtent);

    int newOffset = nextSelection.extentOffset;
    newOffset = nextSelection.baseOffset > nextSelection.extentOffset
        ? nextSelection.baseOffset : nextSelection.extentOffset;
    return TextSelection.fromPosition(TextPosition(offset: newOffset));
  }

  // Return the offset at the start of the nearest word to the left of the given
  // offset.
  static int _getLeftByWord(TextPainter textPainter, int offset, [bool includeWhitespace = true]) {
    // If the offset is already all the way left, there is nothing to do.
    if (offset <= 0) {
      return offset;
    }

    // If we can just return the start of the text without checking for a word.
    if (offset == 1) {
      return 0;
    }

    final String text = textPainter.text!.toPlainText();
    final int startPoint = previousCharacter(offset, text, includeWhitespace);
    final TextRange word = textPainter.getWordBoundary(TextPosition(offset: startPoint));
    return word.start;
  }

  // Return the offset at the end of the nearest word to the right of the given
  // offset.
  static int _getRightByWord(TextPainter textPainter, int offset, [bool includeWhitespace = true]) {
    // If the selection is already all the way right, there is nothing to do.
    final String text = textPainter.text!.toPlainText();
    if (offset == text.length) {
      return offset;
    }

    // If we can just return the end of the text without checking for a word.
    if (offset == text.length - 1 || offset == text.length) {
      return text.length;
    }

    final int startPoint = includeWhitespace || !_isWhitespace(text.codeUnitAt(offset))
        ? offset
        : nextCharacter(offset, text, includeWhitespace);
    final TextRange nextWord = textPainter.getWordBoundary(TextPosition(offset: startPoint));
    return nextWord.end;
  }

  // Return the given TextSelection extended left to the beginning of the
  // nearest word.
  //
  // See extendSelectionLeftByWord for a detailed explanation of the two
  // optional parameters.
  static TextSelection _extendGivenSelectionLeftByWord(TextPainter textPainter, TextSelection selection, [bool includeWhitespace = true, bool stopAtReversal = false]) {
    // If the selection is already all the way left, there is nothing to do.
    if (selection.isCollapsed && selection.extentOffset <= 0) {
      return selection;
    }

    final int leftOffset = _getLeftByWord(textPainter, selection.extentOffset, includeWhitespace);

    if (stopAtReversal && selection.extentOffset > selection.baseOffset
        && leftOffset < selection.baseOffset) {
      return selection.copyWith(
        extentOffset: selection.baseOffset,
      );
    }

    return selection.copyWith(
      extentOffset: leftOffset,
    );
  }

  // Return the given TextSelection extended right to the end of the nearest
  // word.
  //
  // See extendSelectionRightByWord for a detailed explanation of the two
  // optional parameters.
  static TextSelection _extendGivenSelectionRightByWord(TextPainter textPainter, TextSelection selection, [bool includeWhitespace = true, bool stopAtReversal = false]) {
    // If the selection is already all the way right, there is nothing to do.
    final String text = textPainter.text!.toPlainText();
    if (selection.isCollapsed && selection.extentOffset == text.length) {
      return selection;
    }

    final int rightOffset = _getRightByWord(textPainter, selection.extentOffset, includeWhitespace);

    if (stopAtReversal && selection.baseOffset > selection.extentOffset
        && rightOffset > selection.baseOffset) {
      return selection.copyWith(
        extentOffset: selection.baseOffset,
      );
    }

    return selection.copyWith(
      extentOffset: rightOffset,
    );
  }

  // Return the given TextSelection moved left to the end of the nearest word.
  //
  // A TextSelection that isn't collapsed will be collapsed and moved from the
  // extentOffset.
  static TextSelection _moveGivenSelectionLeftByWord(TextPainter textPainter, TextSelection selection, [bool includeWhitespace = true]) {
    // If the selection is already all the way left, there is nothing to do.
    if (selection.isCollapsed && selection.extentOffset <= 0) {
      return selection;
    }

    final int leftOffset = _getLeftByWord(textPainter, selection.extentOffset, includeWhitespace);
    return selection.copyWith(
      baseOffset: leftOffset,
      extentOffset: leftOffset,
    );
  }

  // Return the given TextSelection moved right to the end of the nearest word.
  //
  // A TextSelection that isn't collapsed will be collapsed and moved from the
  // extentOffset.
  static TextSelection _moveGivenSelectionRightByWord(TextPainter textPainter, TextSelection selection, [bool includeWhitespace = true]) {
    // If the selection is already all the way right, there is nothing to do.
    final String text = textPainter.text!.toPlainText();
    if (selection.isCollapsed && selection.extentOffset == text.length) {
      return selection;
    }

    final int rightOffset = _getRightByWord(textPainter, selection.extentOffset, includeWhitespace);
    return selection.copyWith(
      baseOffset: rightOffset,
      extentOffset: rightOffset,
    );
  }

  static TextSelection _extendGivenSelectionLeft(TextSelection selection, String text, [bool includeWhitespace = true]) {
    // If the selection is already all the way left, there is nothing to do.
    if (selection.extentOffset <= 0) {
      return selection;
    }
    final int previousExtent = previousCharacter(selection.extentOffset, text, includeWhitespace);
    return selection.copyWith(extentOffset: previousExtent);
  }

  static TextSelection _extendGivenSelectionRight(TextSelection selection, String text, [bool includeWhitespace = true]) {
    // If the selection is already all the way right, there is nothing to do.
    if (selection.extentOffset >= text.length) {
      return selection;
    }
    final int nextExtent = nextCharacter(selection.extentOffset, text, includeWhitespace);
    return selection.copyWith(extentOffset: nextExtent);
  }

  // Extend the current selection to the end of the field.
  //
  // If selectionEnabled is false, keeps the selection collapsed and moves it to
  // the end.
  //
  // The given [SelectionChangedCause] indicates the cause of this change and
  // will be passed to [onSelectionChanged].
  //
  // See also:
  //
  //   * _extendSelectionToStart
  void _extendSelectionToEnd(SelectionChangedCause cause) {
    if (selection!.extentOffset == _plainText.length) {
      return;
    }
    if (!selectionEnabled) {
      return moveSelectionToEnd(cause);
    }

    final TextSelection nextSelection = selection!.copyWith(
      extentOffset: _plainText.length,
    );
    _setSelection(nextSelection, cause);
  }

  // Extend the current selection to the start of the field.
  //
  // If selectionEnabled is false, keeps the selection collapsed and moves it to
  // the start.
  //
  // The given [SelectionChangedCause] indicates the cause of this change and
  // will be passed to [onSelectionChanged].
  //
  // See also:
  //
  //   * _expandSelectionToEnd
  void _extendSelectionToStart(SelectionChangedCause cause) {
    if (selection!.extentOffset == 0) {
      return;
    }
    if (!selectionEnabled) {
      return moveSelectionToStart(cause);
    }

    final TextSelection nextSelection = selection!.copyWith(
      extentOffset: 0,
    );
    _setSelection(nextSelection, cause);
  }

  // Returns the TextPosition above or below the given offset.
  TextPosition _getTextPositionVertical(int textOffset, double verticalOffset) {
    final Offset caretOffset = _textPainter.getOffsetForCaret(TextPosition(offset: textOffset), _caretPrototype);
    final Offset caretOffsetTranslated = caretOffset.translate(0.0, verticalOffset);
    return _textPainter.getPositionForOffset(caretOffsetTranslated);
  }

  // Returns the TextPosition above the given offset into _plainText.
  //
  // If the offset is already on the first line, the given offset will be
  // returned.
  TextPosition _getTextPositionAbove(int offset) {
    // The caret offset gives a location in the upper left hand corner of
    // the caret so the middle of the line above is a half line above that
    // point and the line below is 1.5 lines below that point.
    final double preferredLineHeight = _textPainter.preferredLineHeight;
    final double verticalOffset = -0.5 * preferredLineHeight;
    return _getTextPositionVertical(offset, verticalOffset);
  }

  // Returns the TextPosition below the given offset into _plainText.
  //
  // If the offset is already on the last line, the given offset will be
  // returned.
  TextPosition _getTextPositionBelow(int offset) {
    // The caret offset gives a location in the upper left hand corner of
    // the caret so the middle of the line above is a half line above that
    // point and the line below is 1.5 lines below that point.
    final double preferredLineHeight = _textPainter.preferredLineHeight;
    final double verticalOffset = 1.5 * preferredLineHeight;
    return _getTextPositionVertical(offset, verticalOffset);
  }

  /// Keeping [selection]'s [TextSelection.baseOffset] fixed, move the
  /// [TextSelection.extentOffset] down by one line.
  ///
  /// If [selectionEnabled] is false, keeps the selection collapsed and just
  /// moves it down.
  ///
  /// {@template flutter.rendering.RenderEditable.cause}
  /// The given [SelectionChangedCause] indicates the cause of this change and
  /// will be passed to [onSelectionChanged].
  /// {@endtemplate}
  ///
  /// See also:
  ///
  ///   * [extendSelectionUp], which is same but in the opposite direction.
  void extendSelectionDown(SelectionChangedCause cause) {
    assert(selection != null);

    // If the selection is collapsed at the end of the field already, then
    // nothing happens.
    if (selection!.isCollapsed && selection!.extentOffset >= _plainText.length) {
      return;
    }
    if (!selectionEnabled) {
      return moveSelectionDown(cause);
    }

    final TextPosition positionBelow = _getTextPositionBelow(selection!.extentOffset);
    late final TextSelection nextSelection;
    if (positionBelow.offset == selection!.extentOffset) {
      nextSelection = selection!.copyWith(
        extentOffset: _plainText.length,
      );
      _wasSelectingVerticallyWithKeyboard = true;
    } else if (_wasSelectingVerticallyWithKeyboard) {
      nextSelection = selection!.copyWith(
        extentOffset: _cursorResetLocation,
      );
      _wasSelectingVerticallyWithKeyboard = false;
    } else {
      nextSelection = selection!.copyWith(
        extentOffset: positionBelow.offset,
      );
      _cursorResetLocation = nextSelection.extentOffset;
    }

    _setSelection(nextSelection, cause);
  }

  /// Expand the current [selection] to the end of the field.
  ///
  /// The selection will never shrink. The [TextSelection.extentOffset] will
  // always be at the end of the field, regardless of the original order of
  /// [TextSelection.baseOffset] and [TextSelection.extentOffset].
  ///
  /// If [selectionEnabled] is false, keeps the selection collapsed and moves it
  /// to the end.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// See also:
  ///
  ///   * [expandSelectionToStart], which is same but in the opposite direction.
  void expandSelectionToEnd(SelectionChangedCause cause) {
    assert(selection != null);

    if (selection!.extentOffset == _plainText.length) {
      return;
    }
    if (!selectionEnabled) {
      return moveSelectionToEnd(cause);
    }

    final int firstOffset = math.max(0, math.min(
      selection!.baseOffset,
      selection!.extentOffset,
    ));
    final TextSelection nextSelection = TextSelection(
      baseOffset: firstOffset,
      extentOffset: _plainText.length,
    );
    _setSelection(nextSelection, cause);
  }

  /// Keeping [selection]'s [TextSelection.baseOffset] fixed, move the
  /// [TextSelection.extentOffset] left.
  ///
  /// If [selectionEnabled] is false, keeps the selection collapsed and moves it
  /// left.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// See also:
  ///
  ///   * [extendSelectionRight], which is same but in the opposite direction.
  void extendSelectionLeft(SelectionChangedCause cause) {
    assert(selection != null);

    if (!selectionEnabled) {
      return moveSelectionLeft(cause);
    }

    final TextSelection nextSelection = _extendGivenSelectionLeft(
      selection!,
      _plainText,
    );
    if (nextSelection == selection) {
      return;
    }
    final int distance = selection!.extentOffset - nextSelection.extentOffset;
    _cursorResetLocation -= distance;
    _setSelection(nextSelection, cause);
  }

  /// Extend the current [selection] to the start of
  /// [TextSelection.extentOffset]'s line.
  ///
  /// Uses [TextSelection.baseOffset] as a pivot point and doesn't change it.
  /// If [TextSelection.extentOffset] is right of [TextSelection.baseOffset],
  /// then collapses the selection.
  ///
  /// If [selectionEnabled] is false, keeps the selection collapsed and moves it
  /// left by line.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// See also:
  ///
  ///   * [extendSelectionRightByLine], which is same but in the opposite
  ///     direction.
  ///   * [expandSelectionRightByLine], which strictly grows the selection
  ///     regardless of the order.
  void extendSelectionLeftByLine(SelectionChangedCause cause) {
    assert(selection != null);

    if (!selectionEnabled) {
      return moveSelectionLeftByLine(cause);
    }

    // When going left, we want to skip over any whitespace before the line,
    // so we go back to the first non-whitespace before asking for the line
    // bounds, since _getLineAtOffset finds the line boundaries without
    // including whitespace (like the newline).
    final int startPoint = previousCharacter(selection!.extentOffset, _plainText, false);
    final TextSelection selectedLine = _getLineAtOffset(TextPosition(offset: startPoint));

    late final TextSelection nextSelection;
    if (selection!.extentOffset > selection!.baseOffset) {
      nextSelection = selection!.copyWith(
        extentOffset: selection!.baseOffset,
      );
    } else {
      nextSelection = selection!.copyWith(
        extentOffset: selectedLine.baseOffset,
      );
    }

    _setSelection(nextSelection, cause);
  }

  /// Keeping [selection]'s [TextSelection.baseOffset] fixed, move the
  /// [TextSelection.extentOffset] right.
  ///
  /// If [selectionEnabled] is false, keeps the selection collapsed and moves it
  /// right.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// See also:
  ///
  ///   * [extendSelectionLeft], which is same but in the opposite direction.
  void extendSelectionRight(SelectionChangedCause cause) {
    assert(selection != null);

    if (!selectionEnabled) {
      return moveSelectionRight(cause);
    }

    final TextSelection nextSelection = _extendGivenSelectionRight(
      selection!,
      _plainText,
    );
    if (nextSelection == selection) {
      return;
    }
    final int distance = nextSelection.extentOffset - selection!.extentOffset;
    _cursorResetLocation += distance;
    _setSelection(nextSelection, cause);
  }

  /// Extend the current [selection] to the end of [TextSelection.extentOffset]'s
  /// line.
  ///
  /// Uses [TextSelection.baseOffset] as a pivot point and doesn't change it. If
  /// [TextSelection.extentOffset] is left of [TextSelection.baseOffset], then
  /// collapses the selection.
  ///
  /// If [selectionEnabled] is false, keeps the selection collapsed and moves it
  /// right by line.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// See also:
  ///
  ///   * [extendSelectionLeftByLine], which is same but in the opposite
  ///     direction.
  ///   * [expandSelectionRightByLine], which strictly grows the selection
  ///     regardless of the order.
  void extendSelectionRightByLine(SelectionChangedCause cause) {
    assert(selection != null);

    if (!selectionEnabled) {
      return moveSelectionRightByLine(cause);
    }

    final int startPoint = nextCharacter(selection!.extentOffset, _plainText, false);
    final TextSelection selectedLine = _getLineAtOffset(TextPosition(offset: startPoint));

    late final TextSelection nextSelection;
    if (selection!.extentOffset < selection!.baseOffset) {
      nextSelection = selection!.copyWith(
        extentOffset: selection!.baseOffset,
      );
    } else {
      nextSelection = selection!.copyWith(
        extentOffset: selectedLine.extentOffset,
      );
    }

    _setSelection(nextSelection, cause);
  }

  /// Keeping [selection]'s [TextSelection.baseOffset] fixed, move the
  /// [TextSelection.extentOffset] up by one
  /// line.
  ///
  /// If [selectionEnabled] is false, keeps the selection collapsed and moves it
  /// up.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// See also:
  ///
  ///   * [extendSelectionDown], which is the same but in the opposite
  ///     direction.
  void extendSelectionUp(SelectionChangedCause cause) {
    assert(selection != null);

    // If the selection is collapsed at the beginning of the field already, then
    // nothing happens.
    if (selection!.isCollapsed && selection!.extentOffset <= 0.0) {
      return;
    }
    if (!selectionEnabled) {
      return moveSelectionUp(cause);
    }

    final TextPosition positionAbove = _getTextPositionAbove(selection!.extentOffset);
    late final TextSelection nextSelection;
    if (positionAbove.offset == selection!.extentOffset) {
      nextSelection = selection!.copyWith(
        extentOffset: 0,
      );
      _wasSelectingVerticallyWithKeyboard = true;
    } else if (_wasSelectingVerticallyWithKeyboard) {
      nextSelection = selection!.copyWith(
        baseOffset: selection!.baseOffset,
        extentOffset: _cursorResetLocation,
      );
      _wasSelectingVerticallyWithKeyboard = false;
    } else {
      nextSelection = selection!.copyWith(
        baseOffset: selection!.baseOffset,
        extentOffset: positionAbove.offset,
      );
      _cursorResetLocation = nextSelection.extentOffset;
    }

    _setSelection(nextSelection, cause);
  }

  /// Expand the current [selection] to the start of the field.
  ///
  /// The selection will never shrink. The [TextSelection.extentOffset] will
  /// always be at the start of the field, regardless of the original order of
  /// [TextSelection.baseOffset] and [TextSelection.extentOffset].
  ///
  /// If [selectionEnabled] is false, keeps the selection collapsed and moves it
  /// to the start.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// See also:
  ///
  ///   * [expandSelectionToEnd], which is the same but in the opposite
  ///     direction.
  void expandSelectionToStart(SelectionChangedCause cause) {
    assert(selection != null);

    if (selection!.extentOffset == 0) {
      return;
    }
    if (!selectionEnabled) {
      return moveSelectionToStart(cause);
    }

    final int lastOffset = math.max(0, math.max(
      selection!.baseOffset,
      selection!.extentOffset,
    ));
    final TextSelection nextSelection = TextSelection(
      baseOffset: lastOffset,
      extentOffset: 0,
    );
    _setSelection(nextSelection, cause);
  }

  /// Expand the current [selection] to the start of the line.
  ///
  /// The selection will never shrink. The upper offset will be expanded to the
  /// beginning of its line, and the original order of baseOffset and
  /// [TextSelection.extentOffset] will be preserved.
  ///
  /// If [selectionEnabled] is false, keeps the selection collapsed and moves it
  /// left by line.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// See also:
  ///
  ///   * [expandSelectionRightByLine], which is the same but in the opposite
  ///     direction.
  void expandSelectionLeftByLine(SelectionChangedCause cause) {
    assert(selection != null);

    if (!selectionEnabled) {
      return moveSelectionLeftByLine(cause);
    }

    final int firstOffset = math.min(selection!.baseOffset, selection!.extentOffset);
    final int startPoint = previousCharacter(firstOffset, _plainText, false);
    final TextSelection selectedLine = _getLineAtOffset(TextPosition(offset: startPoint));

    late final TextSelection nextSelection;
    if (selection!.extentOffset <= selection!.baseOffset) {
      nextSelection = selection!.copyWith(
        extentOffset: selectedLine.baseOffset,
      );
    } else {
      nextSelection = selection!.copyWith(
        baseOffset: selectedLine.baseOffset,
      );
    }

    _setSelection(nextSelection, cause);
  }

  /// Extend the current [selection] to the previous start of a word.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// By default, `includeWhitespace` is set to true, meaning that whitespace
  /// can be considered a word in itself.  If set to false, the selection will
  /// be extended past any whitespace and the first word following the
  /// whitespace.
  ///
  /// {@template flutter.rendering.RenderEditable.stopAtReversal}
  /// The `stopAtReversal` parameter is false by default, meaning that it's
  /// ok for the base and extent to flip their order here. If set to true, then
  /// the selection will collapse when it would otherwise reverse its order. A
  /// selection that is already collapsed is not affected by this parameter.
  /// {@endtemplate}
  ///
  /// See also:
  ///
  ///   * [extendSelectionRightByWord], which is the same but in the opposite
  ///     direction.
  void extendSelectionLeftByWord(SelectionChangedCause cause, [bool includeWhitespace = true, bool stopAtReversal = false]) {
    assert(selection != null);

    // When the text is obscured, the whole thing is treated as one big word.
    if (obscureText) {
      return _extendSelectionToStart(cause);
    }

    assert(
      _textLayoutLastMaxWidth == constraints.maxWidth &&
      _textLayoutLastMinWidth == constraints.minWidth,
      'Last width ($_textLayoutLastMinWidth, $_textLayoutLastMaxWidth) not the same as max width constraint (${constraints.minWidth}, ${constraints.maxWidth}).',
    );
    final TextSelection nextSelection = _extendGivenSelectionLeftByWord(
      _textPainter,
      selection!,
      includeWhitespace,
      stopAtReversal,
    );
    if (nextSelection == selection) {
      return;
    }
    _setSelection(nextSelection, cause);
  }

  /// Extend the current [selection] to the next end of a word.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// By default, `includeWhitespace` is set to true, meaning that whitespace
  /// can be considered a word in itself.  If set to false, the selection will
  /// be extended past any whitespace and the first word following the
  /// whitespace.
  ///
  /// {@macro flutter.rendering.RenderEditable.stopAtReversal}
  ///
  /// See also:
  ///
  ///   * [extendSelectionLeftByWord], which is the same but in the opposite
  ///     direction.
  void extendSelectionRightByWord(SelectionChangedCause cause, [bool includeWhitespace = true, bool stopAtReversal = false]) {
    assert(selection != null);

    // When the text is obscured, the whole thing is treated as one big word.
    if (obscureText) {
      return _extendSelectionToEnd(cause);
    }

    assert(
      _textLayoutLastMaxWidth == constraints.maxWidth &&
      _textLayoutLastMinWidth == constraints.minWidth,
      'Last width ($_textLayoutLastMinWidth, $_textLayoutLastMaxWidth) not the same as max width constraint (${constraints.minWidth}, ${constraints.maxWidth}).',
    );
    final TextSelection nextSelection = _extendGivenSelectionRightByWord(
      _textPainter,
      selection!,
      includeWhitespace,
      stopAtReversal,
    );
    if (nextSelection == selection) {
      return;
    }
    _setSelection(nextSelection, cause);
  }

  /// Expand the current [selection] to the end of the line.
  ///
  /// The selection will never shrink. The lower offset will be expanded to the
  /// end of its line and the original order of [TextSelection.baseOffset] and
  /// [TextSelection.extentOffset] will be preserved.
  ///
  /// If [selectionEnabled] is false, keeps the selection collapsed and moves it
  /// right by line.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// See also:
  ///
  ///   * [expandSelectionLeftByLine], which is the same but in the opposite
  ///     direction.
  void expandSelectionRightByLine(SelectionChangedCause cause) {
    assert(selection != null);

    if (!selectionEnabled) {
      return moveSelectionRightByLine(cause);
    }

    final int lastOffset = math.max(selection!.baseOffset, selection!.extentOffset);
    final int startPoint = nextCharacter(lastOffset, _plainText, false);
    final TextSelection selectedLine = _getLineAtOffset(TextPosition(offset: startPoint));

    late final TextSelection nextSelection;
    if (selection!.extentOffset >= selection!.baseOffset) {
      nextSelection = selection!.copyWith(
        extentOffset: selectedLine.extentOffset,
      );
    } else {
      nextSelection = selection!.copyWith(
        baseOffset: selectedLine.extentOffset,
      );
    }

    _setSelection(nextSelection, cause);
  }

  /// Move the current [selection] to the next line.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// See also:
  ///
  ///   * [moveSelectionUp], which is the same but in the opposite direction.
  void moveSelectionDown(SelectionChangedCause cause) {
    assert(selection != null);

    // If the selection is collapsed at the end of the field already, then
    // nothing happens.
    if (selection!.isCollapsed && selection!.extentOffset >= _plainText.length) {
      return;
    }

    final TextPosition positionBelow = _getTextPositionBelow(selection!.extentOffset);

    late final TextSelection nextSelection;
    if (positionBelow.offset == selection!.extentOffset) {
      nextSelection = selection!.copyWith(
        baseOffset: _plainText.length,
        extentOffset: _plainText.length,
      );
      _wasSelectingVerticallyWithKeyboard = false;
    } else {
      nextSelection = TextSelection.fromPosition(positionBelow);
      _cursorResetLocation = nextSelection.extentOffset;
    }

    _setSelection(nextSelection, cause);
  }

  /// Move the current [selection] left by one character.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// See also:
  ///
  ///   * [moveSelectionRight], which is the same but in the opposite direction.
  void moveSelectionLeft(SelectionChangedCause cause) {
    assert(selection != null);

    final TextSelection nextSelection = _moveGivenSelectionLeft(
      selection!,
      _plainText,
    );
    if (nextSelection == selection) {
      return;
    }
    _cursorResetLocation -= selection!.extentOffset - nextSelection.extentOffset;
    _setSelection(nextSelection, cause);
  }

  /// Move the current [selection] to the leftmost of the current line.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// See also:
  ///
  ///   * [moveSelectionRightByLine], which is the same but in the opposite
  ///     direction.
  void moveSelectionLeftByLine(SelectionChangedCause cause) {
    assert(selection != null);

    // If the previous character is the edge of a line, don't do anything.
    final int previousPoint = previousCharacter(selection!.extentOffset, _plainText, true);
    final TextSelection line = _getLineAtOffset(TextPosition(offset: previousPoint));
    if (line.extentOffset == previousPoint) {
      return;
    }

    // When going left, we want to skip over any whitespace before the line,
    // so we go back to the first non-whitespace before asking for the line
    // bounds, since _getLineAtOffset finds the line boundaries without
    // including whitespace (like the newline).
    final int startPoint = previousCharacter(selection!.extentOffset, _plainText, false);
    final TextSelection selectedLine = _getLineAtOffset(TextPosition(offset: startPoint));
    final TextSelection nextSelection = TextSelection.collapsed(
      offset: selectedLine.baseOffset,
    );

    _setSelection(nextSelection, cause);
  }

  /// Move the current [selection] to the previous start of a word.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// By default, includeWhitespace is set to true, meaning that whitespace can
  /// be considered a word in itself.  If set to false, the selection will be
  /// moved past any whitespace and the first word following the whitespace.
  ///
  /// See also:
  ///
  ///   * [moveSelectionRightByWord], which is the same but in the opposite
  ///     direction.
  void moveSelectionLeftByWord(SelectionChangedCause cause, [bool includeWhitespace = true]) {
    assert(selection != null);

    // When the text is obscured, the whole thing is treated as one big word.
    if (obscureText) {
      return moveSelectionToStart(cause);
    }

    assert(
      _textLayoutLastMaxWidth == constraints.maxWidth &&
      _textLayoutLastMinWidth == constraints.minWidth,
      'Last width ($_textLayoutLastMinWidth, $_textLayoutLastMaxWidth) not the same as max width constraint (${constraints.minWidth}, ${constraints.maxWidth}).',
    );
    final TextSelection nextSelection = _moveGivenSelectionLeftByWord(
      _textPainter,
      selection!,
      includeWhitespace,
    );
    if (nextSelection == selection) {
      return;
    }
    _setSelection(nextSelection, cause);
  }

  /// Move the current [selection] to the right by one character.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// See also:
  ///
  ///   * [moveSelectionLeft], which is the same but in the opposite direction.
  void moveSelectionRight(SelectionChangedCause cause) {
    assert(selection != null);

    final TextSelection nextSelection = _moveGivenSelectionRight(
      selection!,
      _plainText,
    );
    if (nextSelection == selection) {
      return;
    }
    _setSelection(nextSelection, cause);
  }

  /// Move the current [selection] to the rightmost point of the current line.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// See also:
  ///
  ///   * [moveSelectionLeftByLine], which is the same but in the opposite
  ///     direction.
  void moveSelectionRightByLine(SelectionChangedCause cause) {
    assert(selection != null);

    // If already at the right edge of the line, do nothing.
    final TextSelection currentLine = _getLineAtOffset(TextPosition(
      offset: selection!.extentOffset,
    ));
    if (currentLine.extentOffset == selection!.extentOffset) {
      return;
    }

    // When going right, we want to skip over any whitespace after the line,
    // so we go forward to the first non-whitespace character before asking
    // for the line bounds, since _getLineAtOffset finds the line
    // boundaries without including whitespace (like the newline).
    final int startPoint = nextCharacter(selection!.extentOffset, _plainText, false);
    final TextSelection selectedLine = _getLineAtOffset(TextPosition(offset: startPoint));
    final TextSelection nextSelection = TextSelection.collapsed(
      offset: selectedLine.extentOffset,
    );

    _setSelection(nextSelection, cause);
  }

  /// Move the current [selection] to the next end of a word.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// By default, includeWhitespace is set to true, meaning that whitespace can
  /// be considered a word in itself.  If set to false, the selection will be
  /// moved past any whitespace and the first word following the whitespace.
  ///
  /// See also:
  ///
  ///   * [moveSelectionLeftByWord], which is the same but in the opposite
  ///     direction.
  void moveSelectionRightByWord(SelectionChangedCause cause, [bool includeWhitespace = true]) {
    assert(selection != null);

    // When the text is obscured, the whole thing is treated as one big word.
    if (obscureText) {
      return moveSelectionToEnd(cause);
    }

    assert(
      _textLayoutLastMaxWidth == constraints.maxWidth &&
      _textLayoutLastMinWidth == constraints.minWidth,
      'Last width ($_textLayoutLastMinWidth, $_textLayoutLastMaxWidth) not the same as max width constraint (${constraints.minWidth}, ${constraints.maxWidth}).',
    );
    final TextSelection nextSelection = _moveGivenSelectionRightByWord(
      _textPainter,
      selection!,
      includeWhitespace,
    );
    if (nextSelection == selection) {
      return;
    }
    _setSelection(nextSelection, cause);
  }

  /// Move the current [selection] to the end of the field.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// See also:
  ///
  ///   * [moveSelectionToStart], which is the same but in the opposite
  ///     direction.
  void moveSelectionToEnd(SelectionChangedCause cause) {
    assert(selection != null);

    if (selection!.isCollapsed && selection!.extentOffset == _plainText.length) {
      return;
    }
    final TextSelection nextSelection = TextSelection.collapsed(
      offset: _plainText.length,
    );
    _setSelection(nextSelection, cause);
  }

  /// Move the current [selection] to the start of the field.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// See also:
  ///
  ///   * [moveSelectionToEnd], which is the same but in the opposite direction.
  void moveSelectionToStart(SelectionChangedCause cause) {
    assert(selection != null);

    if (selection!.isCollapsed && selection!.extentOffset == 0) {
      return;
    }
    const TextSelection nextSelection = TextSelection.collapsed(offset: 0);
    _setSelection(nextSelection, cause);
  }

  /// Move the current [selection] up by one line.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// See also:
  ///
  ///   * [moveSelectionDown], which is the same but in the opposite direction.
  void moveSelectionUp(SelectionChangedCause cause) {
    assert(selection != null);

    // If the selection is collapsed at the beginning of the field already, then
    // nothing happens.
    if (selection!.isCollapsed && selection!.extentOffset <= 0.0) {
      return;
    }

    final TextPosition positionAbove = _getTextPositionAbove(selection!.extentOffset);
    late final TextSelection nextSelection;
    if (positionAbove.offset == selection!.extentOffset) {
      nextSelection = selection!.copyWith(baseOffset: 0, extentOffset: 0);
      _wasSelectingVerticallyWithKeyboard = false;
    } else {
      nextSelection = selection!.copyWith(
        baseOffset: positionAbove.offset,
        extentOffset: positionAbove.offset,
      );
      _cursorResetLocation = nextSelection.extentOffset;
    }

    _setSelection(nextSelection, cause);
  }

  // Handles shortcut functionality including cut, copy, paste and select all
  // using control/command + (X, C, V, A).
  Future<void> _handleShortcuts(LogicalKeyboardKey key) async {
    final TextSelection selection = textSelectionDelegate.textEditingValue.selection;
    final String text = textSelectionDelegate.textEditingValue.text;
    assert(selection != null);
    assert(_shortcutKeys.contains(key), 'shortcut key $key not recognized.');
    if (key == LogicalKeyboardKey.keyC) {
      if (!selection.isCollapsed) {
        Clipboard.setData(ClipboardData(text: selection.textInside(text)));
      }
      return;
    }
    TextEditingValue? value;
    if (key == LogicalKeyboardKey.keyX && !_readOnly) {
      if (!selection.isCollapsed) {
        Clipboard.setData(ClipboardData(text: selection.textInside(text)));
        value = TextEditingValue(
          text: selection.textBefore(text) + selection.textAfter(text),
          selection: TextSelection.collapsed(offset: math.min(selection.start, selection.end)),
        );
      }
    } else if (key == LogicalKeyboardKey.keyV && !_readOnly) {
      // Snapshot the input before using `await`.
      // See https://github.com/flutter/flutter/issues/11427
      final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data != null) {
        value = TextEditingValue(
          text: selection.textBefore(text) + data.text! + selection.textAfter(text),
          selection: TextSelection.collapsed(
            offset: math.min(selection.start, selection.end) + data.text!.length,
          ),
        );
      }
    } else if (key == LogicalKeyboardKey.keyA) {
      value = TextEditingValue(
        text: text,
        selection: selection.copyWith(
          baseOffset: 0,
          extentOffset: textSelectionDelegate.textEditingValue.text.length,
        ),
      );
    }
    if (value != null) {
      _setTextEditingValue(
        value,
        SelectionChangedCause.keyboard,
      );
    }
  }

  void _handleDelete({ required bool forward }) {
    final TextSelection selection = textSelectionDelegate.textEditingValue.selection;
    final String text = textSelectionDelegate.textEditingValue.text;
    assert(_selection != null);
    if (_readOnly || !selection.isValid) {
      return;
    }
    String textBefore = selection.textBefore(text);
    String textAfter = selection.textAfter(text);
    int cursorPosition = math.min(selection.start, selection.end);
    // If not deleting a selection, delete the next/previous character.
    if (selection.isCollapsed) {
      if (!forward && textBefore.isNotEmpty) {
        final int characterBoundary = previousCharacter(textBefore.length, textBefore);
        textBefore = textBefore.substring(0, characterBoundary);
        cursorPosition = characterBoundary;
      }
      if (forward && textAfter.isNotEmpty) {
        final int deleteCount = nextCharacter(0, textAfter);
        textAfter = textAfter.substring(deleteCount);
      }
    }
    final TextSelection newSelection = TextSelection.collapsed(offset: cursorPosition);
    _setTextEditingValue(
      TextEditingValue(
        text: textBefore + textAfter,
        selection: newSelection,
      ),
      SelectionChangedCause.keyboard,
    );
  }

  @override
  void markNeedsPaint() {
    super.markNeedsPaint();
    // Tell the painers to repaint since text layout may have changed.
    _foregroundRenderObject?.markNeedsPaint();
    _backgroundRenderObject?.markNeedsPaint();
  }

  /// Marks the render object as needing to be laid out again and have its text
  /// metrics recomputed.
  ///
  /// Implies [markNeedsLayout].
  @protected
  void markNeedsTextLayout() {
    _textLayoutLastMaxWidth = null;
    _textLayoutLastMinWidth = null;
    markNeedsLayout();
  }

  @override
  void systemFontsDidChange() {
    super.systemFontsDidChange();
    _textPainter.markNeedsLayout();
    _textLayoutLastMaxWidth = null;
    _textLayoutLastMinWidth = null;
  }

  String? _cachedPlainText;
  // Returns a plain text version of the text in the painter.
  //
  // Returns the obscured text when [obscureText] is true. See
  // [obscureText] and [obscuringCharacter].
  String get _plainText {
    _cachedPlainText ??= _textPainter.text!.toPlainText(includeSemanticsLabels: false);
    return _cachedPlainText!;
  }

  /// The text to display.
  TextSpan? get text => _textPainter.text as TextSpan?;
  final TextPainter _textPainter;
  set text(TextSpan? value) {
    if (_textPainter.text == value)
      return;
    _textPainter.text = value;
    _cachedPlainText = null;
    markNeedsTextLayout();
    markNeedsSemanticsUpdate();
  }

  /// How the text should be aligned horizontally.
  ///
  /// This must not be null.
  TextAlign get textAlign => _textPainter.textAlign;
  set textAlign(TextAlign value) {
    assert(value != null);
    if (_textPainter.textAlign == value)
      return;
    _textPainter.textAlign = value;
    markNeedsTextLayout();
  }

  /// The directionality of the text.
  ///
  /// This decides how the [TextAlign.start], [TextAlign.end], and
  /// [TextAlign.justify] values of [textAlign] are interpreted.
  ///
  /// This is also used to disambiguate how to render bidirectional text. For
  /// example, if the [text] is an English phrase followed by a Hebrew phrase,
  /// in a [TextDirection.ltr] context the English phrase will be on the left
  /// and the Hebrew phrase to its right, while in a [TextDirection.rtl]
  /// context, the English phrase will be on the right and the Hebrew phrase on
  /// its left.
  ///
  /// This must not be null.
  // TextPainter.textDirection is nullable, but it is set to a
  // non-null value in the RenderEditable constructor and we refuse to
  // set it to null here, so _textPainter.textDirection cannot be null.
  TextDirection get textDirection => _textPainter.textDirection!;
  set textDirection(TextDirection value) {
    assert(value != null);
    if (_textPainter.textDirection == value)
      return;
    _textPainter.textDirection = value;
    markNeedsTextLayout();
    markNeedsSemanticsUpdate();
  }

  /// Used by this renderer's internal [TextPainter] to select a locale-specific
  /// font.
  ///
  /// In some cases the same Unicode character may be rendered differently depending
  /// on the locale. For example the '骨' character is rendered differently in
  /// the Chinese and Japanese locales. In these cases the [locale] may be used
  /// to select a locale-specific font.
  ///
  /// If this value is null, a system-dependent algorithm is used to select
  /// the font.
  Locale? get locale => _textPainter.locale;
  set locale(Locale? value) {
    if (_textPainter.locale == value)
      return;
    _textPainter.locale = value;
    markNeedsTextLayout();
  }

  /// The [StrutStyle] used by the renderer's internal [TextPainter] to
  /// determine the strut to use.
  StrutStyle? get strutStyle => _textPainter.strutStyle;
  set strutStyle(StrutStyle? value) {
    if (_textPainter.strutStyle == value)
      return;
    _textPainter.strutStyle = value;
    markNeedsTextLayout();
  }

  /// The color to use when painting the cursor.
  Color? get cursorColor => _caretPainter.caretColor;
  set cursorColor(Color? value) {
    _caretPainter.caretColor = value;
  }

  /// The color to use when painting the cursor aligned to the text while
  /// rendering the floating cursor.
  ///
  /// The default is light grey.
  Color? get backgroundCursorColor => _caretPainter.backgroundCursorColor;
  set backgroundCursorColor(Color? value) {
    _caretPainter.backgroundCursorColor = value;
  }

  /// Whether to paint the cursor.
  ValueNotifier<bool> get showCursor => _showCursor;
  ValueNotifier<bool> _showCursor;
  set showCursor(ValueNotifier<bool> value) {
    assert(value != null);
    if (_showCursor == value)
      return;
    if (attached)
      _showCursor.removeListener(_showHideCursor);
    _showCursor = value;
    if (attached) {
      _showHideCursor();
      _showCursor.addListener(_showHideCursor);
    }
  }

  void _showHideCursor() {
    _caretPainter.shouldPaint = showCursor.value;
  }

  /// Whether the editable is currently focused.
  bool get hasFocus => _hasFocus;
  bool _hasFocus = false;
  bool _listenerAttached = false;
  set hasFocus(bool value) {
    assert(value != null);
    if (_hasFocus == value)
      return;
    _hasFocus = value;
    markNeedsSemanticsUpdate();

    if (!attached) {
      assert(!_listenerAttached);
      return;
    }

    if (_hasFocus) {
      assert(!_listenerAttached);
      // TODO(justinmc): This listener should be ported to Actions and removed.
      // https://github.com/flutter/flutter/issues/75004
      RawKeyboard.instance.addListener(_handleKeyEvent);
      _listenerAttached = true;
    } else {
      assert(_listenerAttached);
      // TODO(justinmc): This listener should be ported to Actions and removed.
      // https://github.com/flutter/flutter/issues/75004
      RawKeyboard.instance.removeListener(_handleKeyEvent);
      _listenerAttached = false;
    }
  }

  /// Whether this rendering object will take a full line regardless the text width.
  bool get forceLine => _forceLine;
  bool _forceLine = false;
  set forceLine(bool value) {
    assert(value != null);
    if (_forceLine == value)
      return;
    _forceLine = value;
    markNeedsLayout();
  }

  /// Whether this rendering object is read only.
  bool get readOnly => _readOnly;
  bool _readOnly = false;
  set readOnly(bool value) {
    assert(value != null);
    if (_readOnly == value)
      return;
    _readOnly = value;
    markNeedsSemanticsUpdate();
  }

  /// The maximum number of lines for the text to span, wrapping if necessary.
  ///
  /// If this is 1 (the default), the text will not wrap, but will extend
  /// indefinitely instead.
  ///
  /// If this is null, there is no limit to the number of lines.
  ///
  /// When this is not null, the intrinsic height of the render object is the
  /// height of one line of text multiplied by this value. In other words, this
  /// also controls the height of the actual editing widget.
  int? get maxLines => _maxLines;
  int? _maxLines;
  /// The value may be null. If it is not null, then it must be greater than zero.
  set maxLines(int? value) {
    assert(value == null || value > 0);
    if (maxLines == value)
      return;
    _maxLines = value;
    markNeedsTextLayout();
  }

  /// {@macro flutter.widgets.editableText.minLines}
  int? get minLines => _minLines;
  int? _minLines;
  /// The value may be null. If it is not null, then it must be greater than zero.
  set minLines(int? value) {
    assert(value == null || value > 0);
    if (minLines == value)
      return;
    _minLines = value;
    markNeedsTextLayout();
  }

  /// {@macro flutter.widgets.editableText.expands}
  bool get expands => _expands;
  bool _expands;
  set expands(bool value) {
    assert(value != null);
    if (expands == value)
      return;
    _expands = value;
    markNeedsTextLayout();
  }

  /// The color to use when painting the selection.
  Color? get selectionColor => _selectionPainter.highlightColor;
  set selectionColor(Color? value) {
    _selectionPainter.highlightColor = value;
  }

  /// The number of font pixels for each logical pixel.
  ///
  /// For example, if the text scale factor is 1.5, text will be 50% larger than
  /// the specified font size.
  double get textScaleFactor => _textPainter.textScaleFactor;
  set textScaleFactor(double value) {
    assert(value != null);
    if (_textPainter.textScaleFactor == value)
      return;
    _textPainter.textScaleFactor = value;
    markNeedsTextLayout();
  }

  /// The region of text that is selected, if any.
  ///
  /// The caret position is represented by a collapsed selection.
  ///
  /// If [selection] is null, there is no selection and attempts to
  /// manipulate the selection will throw.
  TextSelection? get selection => _selection;
  TextSelection? _selection;
  set selection(TextSelection? value) {
    if (_selection == value)
      return;
    _selection = value;
    _selectionPainter.highlightedRange = value;
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  /// The offset at which the text should be painted.
  ///
  /// If the text content is larger than the editable line itself, the editable
  /// line clips the text. This property controls which part of the text is
  /// visible by shifting the text by the given offset before clipping.
  ViewportOffset get offset => _offset;
  ViewportOffset _offset;
  set offset(ViewportOffset value) {
    assert(value != null);
    if (_offset == value)
      return;
    if (attached)
      _offset.removeListener(markNeedsPaint);
    _offset = value;
    if (attached)
      _offset.addListener(markNeedsPaint);
    markNeedsLayout();
  }

  /// How thick the cursor will be.
  double get cursorWidth => _cursorWidth;
  double _cursorWidth = 1.0;
  set cursorWidth(double value) {
    if (_cursorWidth == value)
      return;
    _cursorWidth = value;
    markNeedsLayout();
  }

  /// How tall the cursor will be.
  ///
  /// This can be null, in which case the getter will actually return [preferredLineHeight].
  ///
  /// Setting this to itself fixes the value to the current [preferredLineHeight]. Setting
  /// this to null returns the behavior of deferring to [preferredLineHeight].
  // TODO(ianh): This is a confusing API. We should have a separate getter for the effective cursor height.
  double get cursorHeight => _cursorHeight ?? preferredLineHeight;
  double? _cursorHeight;
  set cursorHeight(double? value) {
    if (_cursorHeight == value)
      return;
    _cursorHeight = value;
    markNeedsLayout();
  }

  /// {@template flutter.rendering.RenderEditable.paintCursorAboveText}
  /// If the cursor should be painted on top of the text or underneath it.
  ///
  /// By default, the cursor should be painted on top for iOS platforms and
  /// underneath for Android platforms.
  /// {@endtemplate}
  bool get paintCursorAboveText => _paintCursorOnTop;
  bool _paintCursorOnTop;
  set paintCursorAboveText(bool value) {
    if (_paintCursorOnTop == value)
      return;
    _paintCursorOnTop = value;
    // Clear cached built-in painters and reconfigure painters.
    _cachedBuiltInForegroundPainters = null;
    _cachedBuiltInPainters = null;
    // Call update methods to rebuild and set the effective painters.
    _updateForegroundPainter(_foregroundPainter);
    _updatePainter(_painter);
  }

  /// {@template flutter.rendering.RenderEditable.cursorOffset}
  /// The offset that is used, in pixels, when painting the cursor on screen.
  ///
  /// By default, the cursor position should be set to an offset of
  /// (-[cursorWidth] * 0.5, 0.0) on iOS platforms and (0, 0) on Android
  /// platforms. The origin from where the offset is applied to is the arbitrary
  /// location where the cursor ends up being rendered from by default.
  /// {@endtemplate}
  Offset get cursorOffset => _caretPainter.cursorOffset;
  set cursorOffset(Offset value) {
    _caretPainter.cursorOffset = value;
  }

  /// How rounded the corners of the cursor should be.
  ///
  /// A null value is the same as [Radius.zero].
  Radius? get cursorRadius => _caretPainter.cursorRadius;
  set cursorRadius(Radius? value) {
    _caretPainter.cursorRadius = value;
  }

  /// The [LayerLink] of start selection handle.
  ///
  /// [RenderEditable] is responsible for calculating the [Offset] of this
  /// [LayerLink], which will be used as [CompositedTransformTarget] of start handle.
  LayerLink get startHandleLayerLink => _startHandleLayerLink;
  LayerLink _startHandleLayerLink;
  set startHandleLayerLink(LayerLink value) {
    if (_startHandleLayerLink == value)
      return;
    _startHandleLayerLink = value;
    markNeedsPaint();
  }

  /// The [LayerLink] of end selection handle.
  ///
  /// [RenderEditable] is responsible for calculating the [Offset] of this
  /// [LayerLink], which will be used as [CompositedTransformTarget] of end handle.
  LayerLink get endHandleLayerLink => _endHandleLayerLink;
  LayerLink _endHandleLayerLink;
  set endHandleLayerLink(LayerLink value) {
    if (_endHandleLayerLink == value)
      return;
    _endHandleLayerLink = value;
    markNeedsPaint();
  }

  /// The padding applied to text field. Used to determine the bounds when
  /// moving the floating cursor.
  ///
  /// Defaults to a padding with left, top and right set to 4, bottom to 5.
  EdgeInsets floatingCursorAddedMargin;

  bool _floatingCursorOn = false;
  late TextPosition _floatingCursorTextPosition;

  /// Whether to allow the user to change the selection.
  ///
  /// Since [RenderEditable] does not handle selection manipulation
  /// itself, this actually only affects whether the accessibility
  /// hints provided to the system (via
  /// [describeSemanticsConfiguration]) will enable selection
  /// manipulation. It's the responsibility of this object's owner
  /// to provide selection manipulation affordances.
  ///
  /// This field is used by [selectionEnabled] (which then controls
  /// the accessibility hints mentioned above). When null,
  /// [obscureText] is used to determine the value of
  /// [selectionEnabled] instead.
  bool? get enableInteractiveSelection => _enableInteractiveSelection;
  bool? _enableInteractiveSelection;
  set enableInteractiveSelection(bool? value) {
    if (_enableInteractiveSelection == value)
      return;
    _enableInteractiveSelection = value;
    markNeedsTextLayout();
    markNeedsSemanticsUpdate();
  }

  /// Whether interactive selection are enabled based on the values of
  /// [enableInteractiveSelection] and [obscureText].
  ///
  /// Since [RenderEditable] does not handle selection manipulation
  /// itself, this actually only affects whether the accessibility
  /// hints provided to the system (via
  /// [describeSemanticsConfiguration]) will enable selection
  /// manipulation. It's the responsibility of this object's owner
  /// to provide selection manipulation affordances.
  ///
  /// By default, [enableInteractiveSelection] is null, [obscureText] is false,
  /// and this getter returns true.
  ///
  /// If [enableInteractiveSelection] is null and [obscureText] is true, then this
  /// getter returns false. This is the common case for password fields.
  ///
  /// If [enableInteractiveSelection] is non-null then its value is
  /// returned. An application might [enableInteractiveSelection] to
  /// true to enable interactive selection for a password field, or to
  /// false to unconditionally disable interactive selection.
  bool get selectionEnabled {
    return enableInteractiveSelection ?? !obscureText;
  }

  /// The color used to paint the prompt rectangle.
  ///
  /// The prompt rectangle will only be requested on non-web iOS applications.
  // TODO(ianh): We should change the getter to return null when _promptRectRange is null
  // (otherwise, if you set it to null and then get it, you get back non-null).
  // Alternatively, we could stop supporting setting this to null.
  Color? get promptRectColor => _autocorrectHighlightPainter.highlightColor;
  set promptRectColor(Color? newValue) {
    _autocorrectHighlightPainter.highlightColor = newValue;
  }

  /// Dismisses the currently displayed prompt rectangle and displays a new prompt rectangle
  /// over [newRange] in the given color [promptRectColor].
  ///
  /// The prompt rectangle will only be requested on non-web iOS applications.
  ///
  /// When set to null, the currently displayed prompt rectangle (if any) will be dismissed.
  void setPromptRectRange(TextRange? newRange) {
    _autocorrectHighlightPainter.highlightedRange = newRange;
  }

  /// The maximum amount the text is allowed to scroll.
  ///
  /// This value is only valid after layout and can change as additional
  /// text is entered or removed in order to accommodate expanding when
  /// [expands] is set to true.
  double get maxScrollExtent => _maxScrollExtent;
  double _maxScrollExtent = 0;

  double get _caretMargin => _kCaretGap + cursorWidth;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.hardEdge], and must not be null.
  Clip get clipBehavior => _clipBehavior;
  Clip _clipBehavior = Clip.hardEdge;
  set clipBehavior(Clip value) {
    assert(value != null);
    if (value != _clipBehavior) {
      _clipBehavior = value;
      markNeedsPaint();
      markNeedsSemanticsUpdate();
    }
  }

  /// Collected during [describeSemanticsConfiguration], used by
  /// [assembleSemanticsNode] and [_combineSemanticsInfo].
  List<InlineSpanSemanticsInformation>? _semanticsInfo;

  // Caches [SemanticsNode]s created during [assembleSemanticsNode] so they
  // can be re-used when [assembleSemanticsNode] is called again. This ensures
  // stable ids for the [SemanticsNode]s of [TextSpan]s across
  // [assembleSemanticsNode] invocations.
  Queue<SemanticsNode>? _cachedChildNodes;

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    _semanticsInfo = _textPainter.text!.getSemanticsInformation();
    // TODO(chunhtai): the macOS does not provide a public API to support text
    // selections across multiple semantics nodes. Remove this platform check
    // once we can support it.
    // https://github.com/flutter/flutter/issues/77957
    if (_semanticsInfo!.any((InlineSpanSemanticsInformation info) => info.recognizer != null) &&
        defaultTargetPlatform != TargetPlatform.macOS) {
      assert(readOnly && !obscureText);
      // For Selectable rich text with recognizer, we need to create a semantics
      // node for each text fragment.
      config
        ..isSemanticBoundary = true
        ..explicitChildNodes = true;
      return;
    }
    config
      ..value = obscureText
          ? obscuringCharacter * _plainText.length
          : _plainText
      ..isObscured = obscureText
      ..isMultiline = _isMultiline
      ..textDirection = textDirection
      ..isFocused = hasFocus
      ..isTextField = true
      ..isReadOnly = readOnly;

    if (hasFocus && selectionEnabled)
      config.onSetSelection = _handleSetSelection;

    if (hasFocus && !readOnly)
      config.onSetText = _handleSetText;

    if (selectionEnabled && selection?.isValid == true) {
      config.textSelection = selection;
      if (_textPainter.getOffsetBefore(selection!.extentOffset) != null) {
        config
          ..onMoveCursorBackwardByWord = _handleMoveCursorBackwardByWord
          ..onMoveCursorBackwardByCharacter = _handleMoveCursorBackwardByCharacter;
      }
      if (_textPainter.getOffsetAfter(selection!.extentOffset) != null) {
        config
          ..onMoveCursorForwardByWord = _handleMoveCursorForwardByWord
          ..onMoveCursorForwardByCharacter = _handleMoveCursorForwardByCharacter;
      }
    }
  }

  void _handleSetText(String text) {
    textSelectionDelegate.userUpdateTextEditingValue(
      TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      ),
      SelectionChangedCause.keyboard,
    );
  }

  @override
  void assembleSemanticsNode(SemanticsNode node, SemanticsConfiguration config, Iterable<SemanticsNode> children) {
    assert(_semanticsInfo != null && _semanticsInfo!.isNotEmpty);
    final List<SemanticsNode> newChildren = <SemanticsNode>[];
    TextDirection currentDirection = textDirection;
    Rect currentRect;
    double ordinal = 0.0;
    int start = 0;
    final Queue<SemanticsNode> newChildCache = Queue<SemanticsNode>();
    for (final InlineSpanSemanticsInformation info in combineSemanticsInfo(_semanticsInfo!)) {
      assert(!info.isPlaceholder);
      final TextSelection selection = TextSelection(
        baseOffset: start,
        extentOffset: start + info.text.length,
      );
      start += info.text.length;

      final TextDirection initialDirection = currentDirection;
      final List<ui.TextBox> rects = _textPainter.getBoxesForSelection(selection);
      if (rects.isEmpty) {
        continue;
      }
      Rect rect = rects.first.toRect();
      currentDirection = rects.first.direction;
      for (final ui.TextBox textBox in rects.skip(1)) {
        rect = rect.expandToInclude(textBox.toRect());
        currentDirection = textBox.direction;
      }
      // Any of the text boxes may have had infinite dimensions.
      // We shouldn't pass infinite dimensions up to the bridges.
      rect = Rect.fromLTWH(
        math.max(0.0, rect.left),
        math.max(0.0, rect.top),
        math.min(rect.width, constraints.maxWidth),
        math.min(rect.height, constraints.maxHeight),
      );
      // Round the current rectangle to make this API testable and add some
      // padding so that the accessibility rects do not overlap with the text.
      currentRect = Rect.fromLTRB(
        rect.left.floorToDouble() - 4.0,
        rect.top.floorToDouble() - 4.0,
        rect.right.ceilToDouble() + 4.0,
        rect.bottom.ceilToDouble() + 4.0,
      );
      final SemanticsConfiguration configuration = SemanticsConfiguration()
        ..sortKey = OrdinalSortKey(ordinal++)
        ..textDirection = initialDirection
        ..label = info.semanticsLabel ?? info.text;
      final GestureRecognizer? recognizer = info.recognizer;
      if (recognizer != null) {
        if (recognizer is TapGestureRecognizer) {
          if (recognizer.onTap != null) {
            configuration.onTap = recognizer.onTap;
            configuration.isLink = true;
          }
        } else if (recognizer is DoubleTapGestureRecognizer) {
          if (recognizer.onDoubleTap != null) {
            configuration.onTap = recognizer.onDoubleTap;
            configuration.isLink = true;
          }
        } else if (recognizer is LongPressGestureRecognizer) {
          if (recognizer.onLongPress != null) {
            configuration.onLongPress = recognizer.onLongPress;
          }
        } else {
          assert(false, '${recognizer.runtimeType} is not supported.');
        }
      }
      final SemanticsNode newChild = (_cachedChildNodes?.isNotEmpty == true)
          ? _cachedChildNodes!.removeFirst()
          : SemanticsNode();
      newChild
        ..updateWith(config: configuration)
        ..rect = currentRect;
      newChildCache.addLast(newChild);
      newChildren.add(newChild);
    }
    _cachedChildNodes = newChildCache;
    node.updateWith(config: config, childrenInInversePaintOrder: newChildren);
  }

  // TODO(ianh): in theory, [selection] could become null between when
  // we last called describeSemanticsConfiguration and when the
  // callbacks are invoked, in which case the callbacks will crash...

  void _handleSetSelection(TextSelection selection) {
    _setSelection(selection, SelectionChangedCause.keyboard);
  }

  void _handleMoveCursorForwardByCharacter(bool extentSelection) {
    assert(selection != null);
    final int? extentOffset = _textPainter.getOffsetAfter(selection!.extentOffset);
    if (extentOffset == null)
      return;
    final int baseOffset = !extentSelection ? extentOffset : selection!.baseOffset;
    _setSelection(
      TextSelection(baseOffset: baseOffset, extentOffset: extentOffset),
      SelectionChangedCause.keyboard,
    );
  }

  void _handleMoveCursorBackwardByCharacter(bool extentSelection) {
    assert(selection != null);
    final int? extentOffset = _textPainter.getOffsetBefore(selection!.extentOffset);
    if (extentOffset == null)
      return;
    final int baseOffset = !extentSelection ? extentOffset : selection!.baseOffset;
    _setSelection(
      TextSelection(baseOffset: baseOffset, extentOffset: extentOffset),
      SelectionChangedCause.keyboard,
    );
  }

  void _handleMoveCursorForwardByWord(bool extentSelection) {
    assert(selection != null);
    final TextRange currentWord = _textPainter.getWordBoundary(selection!.extent);
    final TextRange? nextWord = _getNextWord(currentWord.end);
    if (nextWord == null)
      return;
    final int baseOffset = extentSelection ? selection!.baseOffset : nextWord.start;
    _setSelection(
      TextSelection(
        baseOffset: baseOffset,
        extentOffset: nextWord.start,
      ),
      SelectionChangedCause.keyboard,
    );
  }

  void _handleMoveCursorBackwardByWord(bool extentSelection) {
    assert(selection != null);
    final TextRange currentWord = _textPainter.getWordBoundary(selection!.extent);
    final TextRange? previousWord = _getPreviousWord(currentWord.start - 1);
    if (previousWord == null)
      return;
    final int baseOffset = extentSelection ?  selection!.baseOffset : previousWord.start;
    _setSelection(
      TextSelection(
        baseOffset: baseOffset,
        extentOffset: previousWord.start,
      ),
      SelectionChangedCause.keyboard,
    );
  }

  TextRange? _getNextWord(int offset) {
    while (true) {
      final TextRange range = _textPainter.getWordBoundary(TextPosition(offset: offset));
      if (range == null || !range.isValid || range.isCollapsed)
        return null;
      if (!_onlyWhitespace(range))
        return range;
      offset = range.end;
    }
  }

  TextRange? _getPreviousWord(int offset) {
    while (offset >= 0) {
      final TextRange range = _textPainter.getWordBoundary(TextPosition(offset: offset));
      if (range == null || !range.isValid || range.isCollapsed)
        return null;
      if (!_onlyWhitespace(range))
        return range;
      offset = range.start - 1;
    }
    return null;
  }

  // Check if the given text range only contains white space or separator
  // characters.
  //
  // Includes newline characters from ASCII and separators from the
  // [unicode separator category](https://www.compart.com/en/unicode/category/Zs)
  // TODO(jonahwilliams): replace when we expose this ICU information.
  bool _onlyWhitespace(TextRange range) {
    for (int i = range.start; i < range.end; i++) {
      final int codeUnit = text!.codeUnitAt(i)!;
      if (!_isWhitespace(codeUnit)) {
        return false;
      }
    }
    return true;
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _foregroundRenderObject?.attach(owner);
    _backgroundRenderObject?.attach(owner);

    _tap = TapGestureRecognizer(debugOwner: this)
      ..onTapDown = _handleTapDown
      ..onTap = _handleTap;
    _longPress = LongPressGestureRecognizer(debugOwner: this)..onLongPress = _handleLongPress;
    _offset.addListener(markNeedsPaint);
    _showHideCursor();
    _showCursor.addListener(_showHideCursor);
    assert(!_listenerAttached);
    if (_hasFocus) {
      RawKeyboard.instance.addListener(_handleKeyEvent);
      _listenerAttached = true;
    }
  }

  @override
  void detach() {
    _tap.dispose();
    _longPress.dispose();
    _offset.removeListener(markNeedsPaint);
    _showCursor.removeListener(_showHideCursor);
    // TODO(justinmc): This listener should be ported to Actions and removed.
    // https://github.com/flutter/flutter/issues/75004
    if (_listenerAttached) {
      RawKeyboard.instance.removeListener(_handleKeyEvent);
      _listenerAttached = false;
    }
    super.detach();
    _foregroundRenderObject?.detach();
    _backgroundRenderObject?.detach();
  }

  @override
  void redepthChildren() {
    final RenderObject? foregroundChild = _foregroundRenderObject;
    final RenderObject? backgroundChild = _backgroundRenderObject;
    if (foregroundChild != null)
      redepthChild(foregroundChild);
    if (backgroundChild != null)
      redepthChild(backgroundChild);
  }

  @override
  void visitChildren(RenderObjectVisitor visitor) {
    final RenderObject? foregroundChild = _foregroundRenderObject;
    final RenderObject? backgroundChild = _backgroundRenderObject;
    if (foregroundChild != null)
      visitor(foregroundChild);
    if (backgroundChild != null)
      visitor(backgroundChild);
  }

  bool get _isMultiline => maxLines != 1;

  Axis get _viewportAxis => _isMultiline ? Axis.vertical : Axis.horizontal;

  Offset get _paintOffset {
    switch (_viewportAxis) {
      case Axis.horizontal:
        return Offset(-offset.pixels, 0.0);
      case Axis.vertical:
        return Offset(0.0, -offset.pixels);
    }
  }

  double get _viewportExtent {
    assert(hasSize);
    switch (_viewportAxis) {
      case Axis.horizontal:
        return size.width;
      case Axis.vertical:
        return size.height;
    }
  }

  double _getMaxScrollExtent(Size contentSize) {
    assert(hasSize);
    switch (_viewportAxis) {
      case Axis.horizontal:
        return math.max(0.0, contentSize.width - size.width);
      case Axis.vertical:
        return math.max(0.0, contentSize.height - size.height);
    }
  }

  // We need to check the paint offset here because during animation, the start of
  // the text may position outside the visible region even when the text fits.
  bool get _hasVisualOverflow => _maxScrollExtent > 0 || _paintOffset != Offset.zero;

  /// Returns the local coordinates of the endpoints of the given selection.
  ///
  /// If the selection is collapsed (and therefore occupies a single point), the
  /// returned list is of length one. Otherwise, the selection is not collapsed
  /// and the returned list is of length two. In this case, however, the two
  /// points might actually be co-located (e.g., because of a bidirectional
  /// selection that contains some text but whose ends meet in the middle).
  ///
  /// See also:
  ///
  ///  * [getLocalRectForCaret], which is the equivalent but for
  ///    a [TextPosition] rather than a [TextSelection].
  List<TextSelectionPoint> getEndpointsForSelection(TextSelection selection) {
    assert(constraints != null);
    _layoutText(minWidth: constraints.minWidth, maxWidth: constraints.maxWidth);

    final Offset paintOffset = _paintOffset;

    final List<ui.TextBox> boxes = selection.isCollapsed ?
        <ui.TextBox>[] : _textPainter.getBoxesForSelection(selection);
    if (boxes.isEmpty) {
      // TODO(mpcomplete): This doesn't work well at an RTL/LTR boundary.
      final Offset caretOffset = _textPainter.getOffsetForCaret(selection.extent, _caretPrototype);
      final Offset start = Offset(0.0, preferredLineHeight) + caretOffset + paintOffset;
      return <TextSelectionPoint>[TextSelectionPoint(start, null)];
    } else {
      final Offset start = Offset(boxes.first.start, boxes.first.bottom) + paintOffset;
      final Offset end = Offset(boxes.last.end, boxes.last.bottom) + paintOffset;
      return <TextSelectionPoint>[
        TextSelectionPoint(start, boxes.first.direction),
        TextSelectionPoint(end, boxes.last.direction),
      ];
    }
  }

  /// Returns the smallest [Rect], in the local coordinate system, that covers
  /// the text within the [TextRange] specified.
  ///
  /// This method is used to calculate the approximate position of the IME bar
  /// on iOS.
  ///
  /// Returns null if [TextRange.isValid] is false for the given `range`, or the
  /// given `range` is collapsed.
  Rect? getRectForComposingRange(TextRange range) {
    assert(constraints != null);
    if (!range.isValid || range.isCollapsed)
      return null;
    _layoutText(minWidth: constraints.minWidth, maxWidth: constraints.maxWidth);

    final List<ui.TextBox> boxes = _textPainter.getBoxesForSelection(
      TextSelection(baseOffset: range.start, extentOffset: range.end),
    );

    return boxes.fold(
      null,
      (Rect? accum, TextBox incoming) => accum?.expandToInclude(incoming.toRect()) ?? incoming.toRect(),
    )?.shift(_paintOffset);
  }

  /// Returns the position in the text for the given global coordinate.
  ///
  /// See also:
  ///
  ///  * [getLocalRectForCaret], which is the reverse operation, taking
  ///    a [TextPosition] and returning a [Rect].
  ///  * [TextPainter.getPositionForOffset], which is the equivalent method
  ///    for a [TextPainter] object.
  TextPosition getPositionForPoint(Offset globalPosition) {
    _layoutText(minWidth: constraints.minWidth, maxWidth: constraints.maxWidth);
    globalPosition += -_paintOffset;
    return _textPainter.getPositionForOffset(globalToLocal(globalPosition));
  }

  /// Returns the [Rect] in local coordinates for the caret at the given text
  /// position.
  ///
  /// See also:
  ///
  ///  * [getPositionForPoint], which is the reverse operation, taking
  ///    an [Offset] in global coordinates and returning a [TextPosition].
  ///  * [getEndpointsForSelection], which is the equivalent but for
  ///    a selection rather than a particular text position.
  ///  * [TextPainter.getOffsetForCaret], the equivalent method for a
  ///    [TextPainter] object.
  Rect getLocalRectForCaret(TextPosition caretPosition) {
    _layoutText(minWidth: constraints.minWidth, maxWidth: constraints.maxWidth);
    final Offset caretOffset = _textPainter.getOffsetForCaret(caretPosition, _caretPrototype);
    // This rect is the same as _caretPrototype but without the vertical padding.
    final Rect rect = Rect.fromLTWH(0.0, 0.0, cursorWidth, cursorHeight).shift(caretOffset + _paintOffset + cursorOffset);
    // Add additional cursor offset (generally only if on iOS).
    return rect.shift(_snapToPhysicalPixel(rect.topLeft));
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    _layoutText(maxWidth: double.infinity);
    return _textPainter.minIntrinsicWidth;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    _layoutText(maxWidth: double.infinity);
    return _textPainter.maxIntrinsicWidth + cursorWidth;
  }

  /// An estimate of the height of a line in the text. See [TextPainter.preferredLineHeight].
  /// This does not require the layout to be updated.
  double get preferredLineHeight => _textPainter.preferredLineHeight;

  double _preferredHeight(double width) {
    // Lock height to maxLines if needed.
    final bool lockedMax = maxLines != null && minLines == null;
    final bool lockedBoth = minLines != null && minLines == maxLines;
    final bool singleLine = maxLines == 1;
    if (singleLine || lockedMax || lockedBoth) {
      return preferredLineHeight * maxLines!;
    }

    // Clamp height to minLines or maxLines if needed.
    final bool minLimited = minLines != null && minLines! > 1;
    final bool maxLimited = maxLines != null;
    if (minLimited || maxLimited) {
      _layoutText(maxWidth: width);
      if (minLimited && _textPainter.height < preferredLineHeight * minLines!) {
        return preferredLineHeight * minLines!;
      }
      if (maxLimited && _textPainter.height > preferredLineHeight * maxLines!) {
        return preferredLineHeight * maxLines!;
      }
    }

    // Set the height based on the content.
    if (width == double.infinity) {
      final String text = _plainText;
      int lines = 1;
      for (int index = 0; index < text.length; index += 1) {
        if (text.codeUnitAt(index) == 0x0A) // count explicit line breaks
          lines += 1;
      }
      return preferredLineHeight * lines;
    }
    _layoutText(maxWidth: width);
    return math.max(preferredLineHeight, _textPainter.height);
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return _preferredHeight(width);
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return _preferredHeight(width);
  }

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    _layoutText(minWidth: constraints.minWidth, maxWidth: constraints.maxWidth);
    return _textPainter.computeDistanceToActualBaseline(baseline);
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  @protected
  bool hitTestChildren(BoxHitTestResult result, { required Offset position }) {
    final TextPosition textPosition = _textPainter.getPositionForOffset(position);
    final InlineSpan? span = _textPainter.text!.getSpanForPosition(textPosition);
    if (span != null && span is HitTestTarget) {
      result.add(HitTestEntry(span as HitTestTarget));
      return true;
    }
    return false;
  }

  late TapGestureRecognizer _tap;
  late LongPressGestureRecognizer _longPress;

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    assert(debugHandleEvent(event, entry));
    if (event is PointerDownEvent) {
      assert(!debugNeedsLayout);

      if (!ignorePointer) {
        // Propagates the pointer event to selection handlers.
        _tap.addPointer(event);
        _longPress.addPointer(event);
      }
    }
  }

  Offset? _lastTapDownPosition;
  Offset? _lastSecondaryTapDownPosition;

  /// The position of the most recent secondary tap down event on this text
  /// input.
  Offset? get lastSecondaryTapDownPosition => _lastSecondaryTapDownPosition;

  /// Tracks the position of a secondary tap event.
  ///
  /// Should be called before attempting to change the selection based on the
  /// position of a secondary tap.
  void handleSecondaryTapDown(TapDownDetails details) {
    _lastTapDownPosition = details.globalPosition;
    _lastSecondaryTapDownPosition = details.globalPosition;
  }

  /// If [ignorePointer] is false (the default) then this method is called by
  /// the internal gesture recognizer's [TapGestureRecognizer.onTapDown]
  /// callback.
  ///
  /// When [ignorePointer] is true, an ancestor widget must respond to tap
  /// down events by calling this method.
  void handleTapDown(TapDownDetails details) {
    _lastTapDownPosition = details.globalPosition;
  }
  void _handleTapDown(TapDownDetails details) {
    assert(!ignorePointer);
    handleTapDown(details);
  }

  /// If [ignorePointer] is false (the default) then this method is called by
  /// the internal gesture recognizer's [TapGestureRecognizer.onTap]
  /// callback.
  ///
  /// When [ignorePointer] is true, an ancestor widget must respond to tap
  /// events by calling this method.
  void handleTap() {
    selectPosition(cause: SelectionChangedCause.tap);
  }
  void _handleTap() {
    assert(!ignorePointer);
    handleTap();
  }

  /// If [ignorePointer] is false (the default) then this method is called by
  /// the internal gesture recognizer's [DoubleTapGestureRecognizer.onDoubleTap]
  /// callback.
  ///
  /// When [ignorePointer] is true, an ancestor widget must respond to double
  /// tap events by calling this method.
  void handleDoubleTap() {
    selectWord(cause: SelectionChangedCause.doubleTap);
  }

  /// If [ignorePointer] is false (the default) then this method is called by
  /// the internal gesture recognizer's [LongPressGestureRecognizer.onLongPress]
  /// callback.
  ///
  /// When [ignorePointer] is true, an ancestor widget must respond to long
  /// press events by calling this method.
  void handleLongPress() {
    selectWord(cause: SelectionChangedCause.longPress);
  }
  void _handleLongPress() {
    assert(!ignorePointer);
    handleLongPress();
  }

  /// Move selection to the location of the last tap down.
  ///
  /// {@template flutter.rendering.RenderEditable.selectPosition}
  /// This method is mainly used to translate user inputs in global positions
  /// into a [TextSelection]. When used in conjunction with a [EditableText],
  /// the selection change is fed back into [TextEditingController.selection].
  ///
  /// If you have a [TextEditingController], it's generally easier to
  /// programmatically manipulate its `value` or `selection` directly.
  /// {@endtemplate}
  void selectPosition({ required SelectionChangedCause cause }) {
    selectPositionAt(from: _lastTapDownPosition!, cause: cause);
  }

  /// Select text between the global positions [from] and [to].
  ///
  /// [from] corresponds to the [TextSelection.baseOffset], and [to] corresponds
  /// to the [TextSelection.extentOffset].
  void selectPositionAt({ required Offset from, Offset? to, required SelectionChangedCause cause }) {
    assert(cause != null);
    assert(from != null);
    _layoutText(minWidth: constraints.minWidth, maxWidth: constraints.maxWidth);
    final TextPosition fromPosition = _textPainter.getPositionForOffset(globalToLocal(from - _paintOffset));
    final TextPosition? toPosition = to == null
      ? null
      : _textPainter.getPositionForOffset(globalToLocal(to - _paintOffset));

    final int baseOffset = fromPosition.offset;
    final int extentOffset = toPosition?.offset ?? fromPosition.offset;

    final TextSelection newSelection = TextSelection(
      baseOffset: baseOffset,
      extentOffset: extentOffset,
      affinity: fromPosition.affinity,
    );
    _setSelection(newSelection, cause);
  }

  /// Select a word around the location of the last tap down.
  ///
  /// {@macro flutter.rendering.RenderEditable.selectPosition}
  void selectWord({ required SelectionChangedCause cause }) {
    selectWordsInRange(from: _lastTapDownPosition!, cause: cause);
  }

  /// Selects the set words of a paragraph in a given range of global positions.
  ///
  /// The first and last endpoints of the selection will always be at the
  /// beginning and end of a word respectively.
  ///
  /// {@macro flutter.rendering.RenderEditable.selectPosition}
  void selectWordsInRange({ required Offset from, Offset? to, required SelectionChangedCause cause }) {
    assert(cause != null);
    assert(from != null);
    _layoutText(minWidth: constraints.minWidth, maxWidth: constraints.maxWidth);
    final TextPosition firstPosition = _textPainter.getPositionForOffset(globalToLocal(from - _paintOffset));
    final TextSelection firstWord = _getWordAtOffset(firstPosition);
    final TextSelection lastWord = to == null ?
      firstWord : _getWordAtOffset(_textPainter.getPositionForOffset(globalToLocal(to - _paintOffset)));

    _setSelection(
      TextSelection(
        baseOffset: firstWord.base.offset,
        extentOffset: lastWord.extent.offset,
        affinity: firstWord.affinity,
      ),
      cause,
    );
  }

  /// Move the selection to the beginning or end of a word.
  ///
  /// {@macro flutter.rendering.RenderEditable.selectPosition}
  void selectWordEdge({ required SelectionChangedCause cause }) {
    assert(cause != null);
    _layoutText(minWidth: constraints.minWidth, maxWidth: constraints.maxWidth);
    assert(_lastTapDownPosition != null);
    final TextPosition position = _textPainter.getPositionForOffset(globalToLocal(_lastTapDownPosition! - _paintOffset));
    final TextRange word = _textPainter.getWordBoundary(position);
    late TextSelection newSelection;
    if (position.offset - word.start <= 1) {
      newSelection = TextSelection.collapsed(offset: word.start, affinity: TextAffinity.downstream);
    } else {
      newSelection = TextSelection.collapsed(offset: word.end, affinity: TextAffinity.upstream);
    }
    _setSelection(newSelection, cause);
  }

  TextSelection _getWordAtOffset(TextPosition position) {
    assert(
      _textLayoutLastMaxWidth == constraints.maxWidth &&
      _textLayoutLastMinWidth == constraints.minWidth,
      'Last width ($_textLayoutLastMinWidth, $_textLayoutLastMaxWidth) not the same as max width constraint (${constraints.minWidth}, ${constraints.maxWidth}).',
    );
    final TextRange word = _textPainter.getWordBoundary(position);
    // When long-pressing past the end of the text, we want a collapsed cursor.
    if (position.offset >= word.end)
      return TextSelection.fromPosition(position);
    // If text is obscured, the entire sentence should be treated as one word.
    if (obscureText) {
      return TextSelection(baseOffset: 0, extentOffset: _plainText.length);
    // On iOS, select the previous word if there is a previous word, or select
    // to the end of the next word if there is a next word. Select nothing if
    // there is neither a previous word nor a next word.
    //
    // If the platform is Android and the text is read only, try to select the
    // previous word if there is one; otherwise, select the single whitespace at
    // the position.
    } else if (_isWhitespace(_plainText.codeUnitAt(position.offset))
        && position.offset > 0) {
      assert(defaultTargetPlatform != null);
      final TextRange? previousWord = _getPreviousWord(word.start);
      switch (defaultTargetPlatform) {
        case TargetPlatform.iOS:
          if (previousWord == null) {
            final TextRange? nextWord = _getNextWord(word.start);
            if (nextWord == null) {
              return TextSelection.collapsed(offset: position.offset);
            }
            return TextSelection(
              baseOffset: position.offset,
              extentOffset: nextWord.end,
            );
          }
          return TextSelection(
            baseOffset: previousWord.start,
            extentOffset: position.offset,
          );
        case TargetPlatform.android:
          if (readOnly) {
            if (previousWord == null) {
              return TextSelection(
                baseOffset: position.offset,
                extentOffset: position.offset + 1,
              );
            }
            return TextSelection(
              baseOffset: previousWord.start,
              extentOffset: position.offset,
            );
          }
          break;
        case TargetPlatform.fuchsia:
        case TargetPlatform.macOS:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          break;
      }
    }

    return TextSelection(baseOffset: word.start, extentOffset: word.end);
  }

  TextSelection _getLineAtOffset(TextPosition position) {
    assert(
      _textLayoutLastMaxWidth == constraints.maxWidth &&
      _textLayoutLastMinWidth == constraints.minWidth,
      'Last width ($_textLayoutLastMinWidth, $_textLayoutLastMaxWidth) not the same as max width constraint (${constraints.minWidth}, ${constraints.maxWidth}).',
    );
    final TextRange line = _textPainter.getLineBoundary(position);
    if (position.offset >= line.end)
      return TextSelection.fromPosition(position);
    // If text is obscured, the entire string should be treated as one line.
    if (obscureText) {
      return TextSelection(baseOffset: 0, extentOffset: _plainText.length);
    }
    return TextSelection(baseOffset: line.start, extentOffset: line.end);
  }

  void _layoutText({ double minWidth = 0.0, double maxWidth = double.infinity }) {
    assert(maxWidth != null && minWidth != null);
    if (_textLayoutLastMaxWidth == maxWidth && _textLayoutLastMinWidth == minWidth)
      return;
    final double availableMaxWidth = math.max(0.0, maxWidth - _caretMargin);
    final double availableMinWidth = math.min(minWidth, availableMaxWidth);
    final double textMaxWidth = _isMultiline ? availableMaxWidth : double.infinity;
    final double textMinWidth = forceLine ? availableMaxWidth : availableMinWidth;
    _textPainter.layout(
        minWidth: textMinWidth,
        maxWidth: textMaxWidth,
    );
    _textLayoutLastMinWidth = minWidth;
    _textLayoutLastMaxWidth = maxWidth;
  }

  late Rect _caretPrototype;

  // TODO(garyq): This is no longer producing the highest-fidelity caret
  // heights for Android, especially when non-alphabetic languages
  // are involved. The current implementation overrides the height set
  // here with the full measured height of the text on Android which looks
  // superior (subjectively and in terms of fidelity) in _paintCaret. We
  // should rework this properly to once again match the platform. The constant
  // _kCaretHeightOffset scales poorly for small font sizes.
  //
  /// On iOS, the cursor is taller than the cursor on Android. The height
  /// of the cursor for iOS is approximate and obtained through an eyeball
  /// comparison.
  void _computeCaretPrototype() {
    assert(defaultTargetPlatform != null);
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        _caretPrototype = Rect.fromLTWH(0.0, 0.0, cursorWidth, cursorHeight + 2);
        break;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        _caretPrototype = Rect.fromLTWH(0.0, _kCaretHeightOffset, cursorWidth, cursorHeight - 2.0 * _kCaretHeightOffset);
        break;
    }
  }

  // Computes the offset to apply to the given [sourceOffset] so it perfectly
  // snaps to physical pixels.
  Offset _snapToPhysicalPixel(Offset sourceOffset) {
    final Offset globalOffset = localToGlobal(sourceOffset);
    final double pixelMultiple = 1.0 / _devicePixelRatio;
    return Offset(
      globalOffset.dx.isFinite
        ? (globalOffset.dx / pixelMultiple).round() * pixelMultiple - globalOffset.dx
        : 0,
      globalOffset.dy.isFinite
        ? (globalOffset.dy / pixelMultiple).round() * pixelMultiple - globalOffset.dy
        : 0,
      );
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    _layoutText(minWidth: constraints.minWidth, maxWidth: constraints.maxWidth);
    final double width = forceLine ? constraints.maxWidth : constraints
        .constrainWidth(_textPainter.size.width + _caretMargin);
    return Size(width, constraints.constrainHeight(_preferredHeight(constraints.maxWidth)));
  }

  @override
  void performLayout() {
    final BoxConstraints constraints = this.constraints;
    _layoutText(minWidth: constraints.minWidth, maxWidth: constraints.maxWidth);
    _computeCaretPrototype();
    // We grab _textPainter.size here because assigning to `size` on the next
    // line will trigger us to validate our intrinsic sizes, which will change
    // _textPainter's layout because the intrinsic size calculations are
    // destructive, which would mean we would get different results if we later
    // used properties on _textPainter in this method.
    // Other _textPainter state like didExceedMaxLines will also be affected,
    // though we currently don't use those here.
    // See also RenderParagraph which has a similar issue.
    final Size textPainterSize = _textPainter.size;
    final double width = forceLine ? constraints.maxWidth : constraints
        .constrainWidth(_textPainter.size.width + _caretMargin);
    size = Size(width, constraints.constrainHeight(_preferredHeight(constraints.maxWidth)));
    final Size contentSize = Size(textPainterSize.width + _caretMargin, textPainterSize.height);

    final BoxConstraints painterConstraints = BoxConstraints.tight(contentSize);

    _foregroundRenderObject?.layout(painterConstraints);
    _backgroundRenderObject?.layout(painterConstraints);

    _maxScrollExtent = _getMaxScrollExtent(contentSize);
    offset.applyViewportDimension(_viewportExtent);
    offset.applyContentDimensions(0.0, _maxScrollExtent);
  }

  // The relative origin in relation to the distance the user has theoretically
  // dragged the floating cursor offscreen. This value is used to account for the
  // difference in the rendering position and the raw offset value.
  Offset _relativeOrigin = Offset.zero;
  Offset? _previousOffset;
  bool _resetOriginOnLeft = false;
  bool _resetOriginOnRight = false;
  bool _resetOriginOnTop = false;
  bool _resetOriginOnBottom = false;
  double? _resetFloatingCursorAnimationValue;

  /// Returns the position within the text field closest to the raw cursor offset.
  Offset calculateBoundedFloatingCursorOffset(Offset rawCursorOffset) {
    Offset deltaPosition = Offset.zero;
    final double topBound = -floatingCursorAddedMargin.top;
    final double bottomBound = _textPainter.height - preferredLineHeight + floatingCursorAddedMargin.bottom;
    final double leftBound = -floatingCursorAddedMargin.left;
    final double rightBound = _textPainter.width + floatingCursorAddedMargin.right;

    if (_previousOffset != null)
      deltaPosition = rawCursorOffset - _previousOffset!;

    // If the raw cursor offset has gone off an edge, we want to reset the relative
    // origin of the dragging when the user drags back into the field.
    if (_resetOriginOnLeft && deltaPosition.dx > 0) {
      _relativeOrigin = Offset(rawCursorOffset.dx - leftBound, _relativeOrigin.dy);
      _resetOriginOnLeft = false;
    } else if (_resetOriginOnRight && deltaPosition.dx < 0) {
      _relativeOrigin = Offset(rawCursorOffset.dx - rightBound, _relativeOrigin.dy);
      _resetOriginOnRight = false;
    }
    if (_resetOriginOnTop && deltaPosition.dy > 0) {
      _relativeOrigin = Offset(_relativeOrigin.dx, rawCursorOffset.dy - topBound);
      _resetOriginOnTop = false;
    } else if (_resetOriginOnBottom && deltaPosition.dy < 0) {
      _relativeOrigin = Offset(_relativeOrigin.dx, rawCursorOffset.dy - bottomBound);
      _resetOriginOnBottom = false;
    }

    final double currentX = rawCursorOffset.dx - _relativeOrigin.dx;
    final double currentY = rawCursorOffset.dy - _relativeOrigin.dy;
    final double adjustedX = math.min(math.max(currentX, leftBound), rightBound);
    final double adjustedY = math.min(math.max(currentY, topBound), bottomBound);
    final Offset adjustedOffset = Offset(adjustedX, adjustedY);

    if (currentX < leftBound && deltaPosition.dx < 0)
      _resetOriginOnLeft = true;
    else if (currentX > rightBound && deltaPosition.dx > 0)
      _resetOriginOnRight = true;
    if (currentY < topBound && deltaPosition.dy < 0)
      _resetOriginOnTop = true;
    else if (currentY > bottomBound && deltaPosition.dy > 0)
      _resetOriginOnBottom = true;

    _previousOffset = rawCursorOffset;

    return adjustedOffset;
  }

  /// Sets the screen position of the floating cursor and the text position
  /// closest to the cursor.
  void setFloatingCursor(FloatingCursorDragState state, Offset boundedOffset, TextPosition lastTextPosition, { double? resetLerpValue }) {
    assert(state != null);
    assert(boundedOffset != null);
    assert(lastTextPosition != null);
    if (state == FloatingCursorDragState.Start) {
      _relativeOrigin = Offset.zero;
      _previousOffset = null;
      _resetOriginOnBottom = false;
      _resetOriginOnTop = false;
      _resetOriginOnRight = false;
      _resetOriginOnBottom = false;
    }
    _floatingCursorOn = state != FloatingCursorDragState.End;
    _resetFloatingCursorAnimationValue = resetLerpValue;
    if (_floatingCursorOn) {
      _floatingCursorTextPosition = lastTextPosition;
      final double? animationValue = _resetFloatingCursorAnimationValue;
      final EdgeInsets sizeAdjustment = animationValue != null
        ? EdgeInsets.lerp(_kFloatingCaretSizeIncrease, EdgeInsets.zero, animationValue)!
        : _kFloatingCaretSizeIncrease;
      _caretPainter.floatingCursorRect = sizeAdjustment.inflateRect(_caretPrototype).shift(boundedOffset);
    } else {
      _caretPainter.floatingCursorRect = null;
    }
    _caretPainter.showRegularCaret = _resetFloatingCursorAnimationValue == null;
  }

  void _paintContents(PaintingContext context, Offset offset) {
    assert(
      _textLayoutLastMaxWidth == constraints.maxWidth &&
      _textLayoutLastMinWidth == constraints.minWidth,
      'Last width ($_textLayoutLastMinWidth, $_textLayoutLastMaxWidth) not the same as max width constraint (${constraints.minWidth}, ${constraints.maxWidth}).',
    );
    final Offset effectiveOffset = offset + _paintOffset;

    if (selection != null && !_floatingCursorOn) {
      _updateSelectionExtentsVisibility(effectiveOffset);
    }

    final RenderBox? foregroundChild = _foregroundRenderObject;
    final RenderBox? backgroundChild = _backgroundRenderObject;

    // The painters paint in the viewport's coordinate space, since the
    // textPainter's coordinate space is not known to high level widgets.
    if (backgroundChild != null)
      context.paintChild(backgroundChild, offset);

    _textPainter.paint(context.canvas, effectiveOffset);

    if (foregroundChild != null)
      context.paintChild(foregroundChild, offset);
  }

  void _paintHandleLayers(PaintingContext context, List<TextSelectionPoint> endpoints) {
    Offset startPoint = endpoints[0].point;
    startPoint = Offset(
      startPoint.dx.clamp(0.0, size.width),
      startPoint.dy.clamp(0.0, size.height),
    );
    context.pushLayer(
      LeaderLayer(link: startHandleLayerLink, offset: startPoint),
      super.paint,
      Offset.zero,
    );
    if (endpoints.length == 2) {
      Offset endPoint = endpoints[1].point;
      endPoint = Offset(
        endPoint.dx.clamp(0.0, size.width),
        endPoint.dy.clamp(0.0, size.height),
      );
      context.pushLayer(
        LeaderLayer(link: endHandleLayerLink, offset: endPoint),
        super.paint,
        Offset.zero,
      );
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    _layoutText(minWidth: constraints.minWidth, maxWidth: constraints.maxWidth);
    if (_hasVisualOverflow && clipBehavior != Clip.none) {
      _clipRectLayer = context.pushClipRect(
        needsCompositing,
        offset,
        Offset.zero & size,
        _paintContents,
        clipBehavior: clipBehavior,
        oldLayer: _clipRectLayer,
      );
    } else {
      _clipRectLayer = null;
      _paintContents(context, offset);
    }
    _paintHandleLayers(context, getEndpointsForSelection(selection!));
  }

  ClipRectLayer? _clipRectLayer;

  @override
  Rect? describeApproximatePaintClip(RenderObject child) => _hasVisualOverflow ? Offset.zero & size : null;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ColorProperty('cursorColor', cursorColor));
    properties.add(DiagnosticsProperty<ValueNotifier<bool>>('showCursor', showCursor));
    properties.add(IntProperty('maxLines', maxLines));
    properties.add(IntProperty('minLines', minLines));
    properties.add(DiagnosticsProperty<bool>('expands', expands, defaultValue: false));
    properties.add(ColorProperty('selectionColor', selectionColor));
    properties.add(DoubleProperty('textScaleFactor', textScaleFactor));
    properties.add(DiagnosticsProperty<Locale>('locale', locale, defaultValue: null));
    properties.add(DiagnosticsProperty<TextSelection>('selection', selection));
    properties.add(DiagnosticsProperty<ViewportOffset>('offset', offset));
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return <DiagnosticsNode>[
      if (text != null)
        text!.toDiagnosticsNode(
          name: 'text',
          style: DiagnosticsTreeStyle.transition,
        ),
    ];
  }
}

class _RenderEditableCustomPaint extends RenderBox {
  _RenderEditableCustomPaint({
    RenderEditablePainter? painter,
  }) : _painter = painter,
       super();

  @override
  RenderEditable? get parent => super.parent as RenderEditable?;

  @override
  bool get isRepaintBoundary => true;

  @override
  bool get sizedByParent => true;

  RenderEditablePainter? get painter => _painter;
  RenderEditablePainter? _painter;
  set painter(RenderEditablePainter? newValue) {
    if (newValue == painter)
      return;

    final RenderEditablePainter? oldPainter = painter;
    _painter = newValue;

    if (newValue?.shouldRepaint(oldPainter) ?? true)
      markNeedsPaint();

    if (attached) {
      oldPainter?.removeListener(markNeedsPaint);
      newValue?.addListener(markNeedsPaint);
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final RenderEditable? parent = this.parent;
    assert(parent != null);
    final RenderEditablePainter? painter = this.painter;
    if (painter != null && parent != null) {
      painter.paint(context.canvas, size, parent);
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _painter?.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _painter?.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;
}

/// An interface that paints within a [RenderEditable]'s bounds, above or
/// beneath its text content.
///
/// This painter is typically used for painting auxiliary content that depends
/// on text layout metrics (for instance, for painting carets and text highlight
/// blocks). It can paint independently from its [RenderEditable], allowing it
/// to repaint without triggering a repaint on the entire [RenderEditable] stack
/// when only auxiliary content changes (e.g. a blinking cursor) are present. It
/// will be scheduled to repaint when:
///
///  * It's assigned to a new [RenderEditable] and the [shouldRepaint] method
///    returns true.
///  * Any of the [RenderEditable]s it is attached to repaints.
///  * The [notifyListeners] method is called, which typically happens when the
///    painter's attributes change.
///
/// See also:
///
///  * [RenderEditable.foregroundPainter], which takes a [RenderEditablePainter]
///    and sets it as the foreground painter of the [RenderEditable].
///  * [RenderEditable.painter], which takes a [RenderEditablePainter]
///    and sets it as the background painter of the [RenderEditable].
///  * [CustomPainter] a similar class which paints within a [RenderCustomPaint].
abstract class RenderEditablePainter extends ChangeNotifier {

  /// Determines whether repaint is needed when a new [RenderEditablePainter]
  /// is provided to a [RenderEditable].
  ///
  /// If the new instance represents different information than the old
  /// instance, then the method should return true, otherwise it should return
  /// false. When [oldDelegate] is null, this method should always return true
  /// unless the new painter initially does not paint anything.
  ///
  /// If the method returns false, then the [paint] call might be optimized
  /// away. However, the [paint] method will get called whenever the
  /// [RenderEditable]s it attaches to repaint, even if [shouldRepaint] returns
  /// false.
  bool shouldRepaint(RenderEditablePainter? oldDelegate);

  /// Paints within the bounds of a [RenderEditable].
  ///
  /// The given [Canvas] has the same coordinate space as the [RenderEditable],
  /// which may be different from the coordinate space the [RenderEditable]'s
  /// [TextPainter] uses, when the text moves inside the [RenderEditable].
  ///
  /// Paint operations performed outside of the region defined by the [canvas]'s
  /// origin and the [size] parameter may get clipped, when [RenderEditable]'s
  /// [RenderEditable.clipBehavior] is not [Clip.none].
  void paint(Canvas canvas, Size size, RenderEditable renderEditable);
}

class _TextHighlightPainter extends RenderEditablePainter {
  _TextHighlightPainter({
      TextRange? highlightedRange,
      Color? highlightColor,
  }) : _highlightedRange = highlightedRange,
       _highlightColor = highlightColor;

  final Paint highlightPaint = Paint();

  Color? get highlightColor => _highlightColor;
  Color? _highlightColor;
  set highlightColor(Color? newValue) {
    if (newValue == _highlightColor)
      return;
    _highlightColor = newValue;
    notifyListeners();
  }

  TextRange? get highlightedRange => _highlightedRange;
  TextRange? _highlightedRange;
  set highlightedRange(TextRange? newValue) {
    if (newValue == _highlightedRange)
      return;
    _highlightedRange = newValue;
    notifyListeners();
  }

  /// Controls how tall the selection highlight boxes are computed to be.
  ///
  /// See [ui.BoxHeightStyle] for details on available styles.
  ui.BoxHeightStyle get selectionHeightStyle => _selectionHeightStyle;
  ui.BoxHeightStyle _selectionHeightStyle = ui.BoxHeightStyle.tight;
  set selectionHeightStyle(ui.BoxHeightStyle value) {
    assert(value != null);
    if (_selectionHeightStyle == value)
      return;
    _selectionHeightStyle = value;
    notifyListeners();
  }

  /// Controls how wide the selection highlight boxes are computed to be.
  ///
  /// See [ui.BoxWidthStyle] for details on available styles.
  ui.BoxWidthStyle get selectionWidthStyle => _selectionWidthStyle;
  ui.BoxWidthStyle _selectionWidthStyle = ui.BoxWidthStyle.tight;
  set selectionWidthStyle(ui.BoxWidthStyle value) {
    assert(value != null);
    if (_selectionWidthStyle == value)
      return;
    _selectionWidthStyle = value;
    notifyListeners();
  }

  @override
  void paint(Canvas canvas, Size size, RenderEditable renderEditable) {
    final TextRange? range = highlightedRange;
    final Color? color = highlightColor;
    if (range == null || color == null || range.isCollapsed) {
      return;
    }

    highlightPaint.color = color;
    final List<TextBox> boxes = renderEditable._textPainter.getBoxesForSelection(
      TextSelection(baseOffset: range.start, extentOffset: range.end),
      boxHeightStyle: selectionHeightStyle,
      boxWidthStyle: selectionWidthStyle,
    );

    for (final TextBox box in boxes)
      canvas.drawRect(box.toRect().shift(renderEditable._paintOffset), highlightPaint);
  }

  @override
  bool shouldRepaint(RenderEditablePainter? oldDelegate) {
    if (identical(oldDelegate, this))
      return false;
    if (oldDelegate == null)
      return highlightColor != null && highlightedRange != null;
    return oldDelegate is! _TextHighlightPainter
        || oldDelegate.highlightColor != highlightColor
        || oldDelegate.highlightedRange != highlightedRange
        || oldDelegate.selectionHeightStyle != selectionHeightStyle
        || oldDelegate.selectionWidthStyle != selectionWidthStyle;
  }
}

class _FloatingCursorPainter extends RenderEditablePainter {
  _FloatingCursorPainter(this.caretPaintCallback);

  bool get shouldPaint => _shouldPaint;
  bool _shouldPaint = true;
  set shouldPaint(bool value) {
    if (shouldPaint == value)
      return;
    _shouldPaint = value;
    notifyListeners();
  }

  CaretChangedHandler caretPaintCallback;

  bool showRegularCaret = false;

  final Paint caretPaint = Paint();
  late final Paint floatingCursorPaint = Paint();

  Color? get caretColor => _caretColor;
  Color? _caretColor;
  set caretColor(Color? value) {
    if (caretColor?.value == value?.value)
      return;

    _caretColor = value;
    notifyListeners();
  }

  Radius? get cursorRadius => _cursorRadius;
  Radius? _cursorRadius;
  set cursorRadius(Radius? value) {
    if (_cursorRadius == value)
      return;
    _cursorRadius = value;
    notifyListeners();
  }

  Offset get cursorOffset => _cursorOffset;
  Offset _cursorOffset = Offset.zero;
  set cursorOffset(Offset value) {
    if (_cursorOffset == value)
      return;
    _cursorOffset = value;
    notifyListeners();
  }

  Color? get backgroundCursorColor => _backgroundCursorColor;
  Color? _backgroundCursorColor;
  set backgroundCursorColor(Color? value) {
    if (backgroundCursorColor?.value == value?.value)
      return;

    _backgroundCursorColor = value;
    if (showRegularCaret)
      notifyListeners();
  }

  Rect? get floatingCursorRect => _floatingCursorRect;
  Rect? _floatingCursorRect;
  set floatingCursorRect(Rect? value) {
    if (_floatingCursorRect == value)
      return;
    _floatingCursorRect = value;
    notifyListeners();
  }

  void paintRegularCursor(Canvas canvas, RenderEditable renderEditable, Color caretColor, TextPosition textPosition) {
    final Rect caretPrototype = renderEditable._caretPrototype;
    final Offset caretOffset = renderEditable._textPainter.getOffsetForCaret(textPosition, caretPrototype);
    Rect caretRect = caretPrototype.shift(caretOffset + cursorOffset);

    final double? caretHeight = renderEditable._textPainter.getFullHeightForCaret(textPosition, caretPrototype);
    if (caretHeight != null) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          final double heightDiff = caretHeight - caretRect.height;
          // Center the caret vertically along the text.
          caretRect = Rect.fromLTWH(
            caretRect.left,
            caretRect.top + heightDiff / 2,
            caretRect.width,
            caretRect.height,
          );
          break;
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          // Override the height to take the full height of the glyph at the TextPosition
          // when not on iOS. iOS has special handling that creates a taller caret.
          // TODO(garyq): See the TODO for _computeCaretPrototype().
          caretRect = Rect.fromLTWH(
            caretRect.left,
            caretRect.top - _kCaretHeightOffset,
            caretRect.width,
            caretHeight,
          );
          break;
      }
    }

    caretRect = caretRect.shift(renderEditable._paintOffset);
    final Rect integralRect = caretRect.shift(renderEditable._snapToPhysicalPixel(caretRect.topLeft));

    if (shouldPaint) {
      final Radius? radius = cursorRadius;
      caretPaint.color = caretColor;
      if (radius == null) {
        canvas.drawRect(integralRect, caretPaint);
      } else {
        final RRect caretRRect = RRect.fromRectAndRadius(integralRect, radius);
        canvas.drawRRect(caretRRect, caretPaint);
      }
    }
    caretPaintCallback(integralRect);
  }

  @override
  void paint(Canvas canvas, Size size, RenderEditable renderEditable) {
    // Compute the caret location even when `shouldPaint` is false.

    assert(renderEditable != null);
    final TextSelection? selection = renderEditable.selection;

    // TODO(LongCatIsLooong): skip painting the caret when the selection is
    // (-1, -1).
    if (selection == null || !selection.isCollapsed)
      return;

    final Rect? floatingCursorRect = this.floatingCursorRect;

    final Color? caretColor = floatingCursorRect == null
      ? this.caretColor
      : showRegularCaret ? backgroundCursorColor : null;
    final TextPosition caretTextPosition = floatingCursorRect == null
      ? selection.extent
      : renderEditable._floatingCursorTextPosition;

    if (caretColor != null) {
      paintRegularCursor(canvas, renderEditable, caretColor, caretTextPosition);
    }

    final Color? floatingCursorColor = this.caretColor?.withOpacity(0.75);
    // Floating Cursor.
    if (floatingCursorRect == null || floatingCursorColor == null || !shouldPaint)
      return;

    canvas.drawRRect(
      RRect.fromRectAndRadius(floatingCursorRect.shift(renderEditable._paintOffset), _kFloatingCaretRadius),
      floatingCursorPaint..color = floatingCursorColor,
    );
  }

  @override
  bool shouldRepaint(RenderEditablePainter? oldDelegate) {
    if (identical(this, oldDelegate))
      return false;

    if (oldDelegate == null)
      return shouldPaint;
    return oldDelegate is! _FloatingCursorPainter
        || oldDelegate.shouldPaint != shouldPaint
        || oldDelegate.showRegularCaret != showRegularCaret
        || oldDelegate.caretColor != caretColor
        || oldDelegate.cursorRadius != cursorRadius
        || oldDelegate.cursorOffset != cursorOffset
        || oldDelegate.backgroundCursorColor != backgroundCursorColor
        || oldDelegate.floatingCursorRect != floatingCursorRect;
  }
}

class _CompositeRenderEditablePainter extends RenderEditablePainter {
  _CompositeRenderEditablePainter({ required this.painters });

  final List<RenderEditablePainter> painters;

  @override
  void addListener(VoidCallback listener) {
    for (final RenderEditablePainter painter in painters)
      painter.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    for (final RenderEditablePainter painter in painters)
      painter.removeListener(listener);
  }

  @override
  void paint(Canvas canvas, Size size, RenderEditable renderEditable) {
    for (final RenderEditablePainter painter in painters)
      painter.paint(canvas, size, renderEditable);
  }

  @override
  bool shouldRepaint(RenderEditablePainter? oldDelegate) {
    if (identical(oldDelegate, this))
      return false;
    if (oldDelegate is! _CompositeRenderEditablePainter || oldDelegate.painters.length != painters.length)
      return true;

    final Iterator<RenderEditablePainter> oldPainters = oldDelegate.painters.iterator;
    final Iterator<RenderEditablePainter> newPainters = painters.iterator;
    while (oldPainters.moveNext() && newPainters.moveNext())
      if (newPainters.current.shouldRepaint(oldPainters.current))
        return true;

    return false;
  }
}
