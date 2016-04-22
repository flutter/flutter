// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui show Paragraph, ParagraphBuilder, ParagraphStyle, TextBox;

import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';

import 'basic_types.dart';
import 'text_editing.dart';
import 'text_style.dart';

// TODO(abarth): Should this be somewhere more general?
bool _deepEquals(List<Object> a, List<Object> b) {
  if (a == null)
    return b == null;
  if (b == null || a.length != b.length)
    return false;
  for (int i = 0; i < a.length; ++i) {
    if (a[i] != b[i])
      return false;
  }
  return true;
}

/// An immutable span of text.
///
/// A [TextSpan] object can be styled using its [style] property.
/// The style will be applied to the [text] and the [children].
///
/// A [TextSpan] object can just have plain text, or it can have
/// children [TextSpan] objects with their own styles that (possibly
/// only partially) override the [style] of this object. If a
/// [TextSpan] has both [text] and [children], then the [text] is
/// treated as if it was an unstyled [TextSpan] at the start of the
/// [children] list.
///
/// To paint a [TextSpan] on a [Canvas], use a [TextPainter]. To display a text
/// span in a widget, use a [RichText]. For text with a single style, consider
/// using the [Text] widget.
///
/// See also:
///
///  * [Text]
///  * [RichText]
///  * [TextPainter]
class TextSpan {
  /// Creates a [TextSpan] with the given values.
  ///
  /// For the object to be useful, at least one of [text] or
  /// [children] should be set.
  const TextSpan({
    this.style,
    this.text,
    this.children,
    this.recognizer
  });

  /// The style to apply to the [text] and the [children].
  final TextStyle style;

  /// The text contained in the span.
  ///
  /// If both [text] and [children] are non-null, the text will preceed the
  /// children.
  final String text;

  /// Additional spans to include as children.
  ///
  /// If both [text] and [children] are non-null, the text will preceed the
  /// children.
  ///
  /// Modifying the list after the [TextSpan] has been created is not
  /// supported and may have unexpected results.
  ///
  /// The list must not contain any nulls.
  final List<TextSpan> children;

  /// A gesture recognizer that will receive events that hit this text span.
  ///
  /// [TextSpan] itself does not implement hit testing or event
  /// dispatch. The owner of the [TextSpan] tree to which the object
  /// belongs is responsible for dispatching events.
  ///
  /// For an example, see [RenderParagraph] in the Flutter rendering library.
  final GestureRecognizer recognizer;

  /// Apply the [style], [text], and [children] of this object to the
  /// given [ParagraphBuilder], from which a [Paragraph] can be obtained.
  /// [Paragraph] objects can be drawn on [Canvas] objects.
  ///
  /// Rather than using this directly, it's simpler to use the
  /// [TextPainter] class to paint [TextSpan] objects onto [Canvas]
  /// objects.
  void build(ui.ParagraphBuilder builder) {
    assert(debugAssertValid());
    final bool hasStyle = style != null;
    if (hasStyle)
      builder.pushStyle(style.textStyle);
    if (text != null)
      builder.addText(text);
    if (children != null) {
      for (TextSpan child in children) {
        assert(child != null);
        child.build(builder);
      }
    }
    if (hasStyle)
      builder.pop();
  }

  /// Walks this text span and its decendants in pre-order and calls [visitor] for each span that has text.
  bool visitTextSpan(bool visitor(TextSpan span)) {
    if (text != null) {
      if (!visitor(this))
        return false;
    }
    if (children != null) {
      for (TextSpan child in children) {
        if (!child.visitTextSpan(visitor))
          return false;
      }
    }
    return true;
  }

  /// Returns the text span that contains the given position in the text.
  TextSpan getSpanForPosition(TextPosition position) {
    assert(debugAssertValid());
    TextAffinity affinity = position.affinity;
    int targetOffset = position.offset;
    int offset = 0;
    TextSpan result;
    visitTextSpan((TextSpan span) {
      assert(result == null);
      int endOffset = offset + span.text.length;
      if (targetOffset == offset && affinity == TextAffinity.downstream ||
          targetOffset > offset && targetOffset < endOffset ||
          targetOffset == endOffset && affinity == TextAffinity.upstream) {
        result = span;
        return false;
      }
      offset = endOffset;
      return true;
    });
    return result;
  }

  /// Flattens the [TextSpan] tree into a single string.
  ///
  /// Styles are not honored in this process.
  String toPlainText() {
    assert(debugAssertValid());
    StringBuffer buffer = new StringBuffer();
    visitTextSpan((TextSpan span) {
      buffer.write(span.text);
      return true;
    });
    return buffer.toString();
  }

  @override
  String toString([String prefix = '']) {
    StringBuffer buffer = new StringBuffer();
    buffer.writeln('$prefix$runtimeType:');
    String indent = '$prefix  ';
    if (style != null)
      buffer.writeln(style.toString(indent));
    if (text != null)
      buffer.writeln('$indent"$text"');
    if (children != null) {
      for (TextSpan child in children) {
        if (child != null) {
          buffer.write(child.toString(indent));
        } else {
          buffer.writeln('$indent<null>');
        }
      }
    }
    if (style == null && text == null && children == null)
      buffer.writeln('$indent(empty)');
    return buffer.toString();
  }

  /// In checked mode, throws an exception if the object is not in a
  /// valid configuration. Otherwise, returns true.
  ///
  /// This is intended to be used as follows:
  /// ```dart
  ///   assert(myTextSpan.debugAssertValid());
  /// ```
  bool debugAssertValid() {
    assert(() {
      if (!visitTextSpan((TextSpan span) {
        if (span.children != null) {
          for (TextSpan child in span.children) {
            if (child == null)
              return false;
          }
        }
        return true;
      })) {
        throw new FlutterError(
          'TextSpan contains a null child.\n'
          'A TextSpan object with a non-null child list should not have any nulls in its child list.\n'
          'The full text in question was:\n'
          '${toString("  ")}'
        );
      }
      return true;
    });
    return true;
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other is! TextSpan)
      return false;
    final TextSpan typedOther = other;
    return typedOther.text == text
        && typedOther.style == style
        && typedOther.recognizer == recognizer
        && _deepEquals(typedOther.children, children);
  }

  @override
  int get hashCode => hashValues(style, text, recognizer, hashList(children));
}

/// An object that paints a [TextSpan] tree into a [Canvas].
///
/// To use a [TextPainter], follow these steps:
///
/// 1. Create a [TextSpan] tree and pass it to the [TextPainter]
///    constructor.
///
/// 2. Set the [maxWidth] property of the [TextPainter] to the width
///    of the area into which the text should be painted.
///
/// 3. Call [layout] to prepare the paragraph.
///
/// 4. Call [paint] as often as desired to paint the paragraph.
///
/// If the width of the area into which the text is being painted
/// changes, return to step 2. If the text to be painted changes,
/// return to step 1.
class TextPainter {
  /// Creates a text painter that paints the given text.
  ///
  /// The text argument is optional but [text] must be non-null before calling
  /// [layout] or [layoutToMaxIntrinsicWidth].
  TextPainter([ TextSpan text ]) {
    this.text = text;
  }

  ui.Paragraph _paragraph;
  bool _needsLayout = false;

  /// The (potentially styled) text to paint.
  TextSpan get text => _text;
  TextSpan _text;
  void set text(TextSpan value) {
    assert(value == null || value.debugAssertValid());
    if (_text == value)
      return;
    _text = value;
    if (_text != null) {
      ui.ParagraphBuilder builder = new ui.ParagraphBuilder();
      _text.build(builder);
      _paragraph = builder.build(_text.style?.paragraphStyle ?? new ui.ParagraphStyle());
      _needsLayout = true;
    } else {
      _paragraph = null;
      _needsLayout = false;
    }
  }

  /// The minimum width at which to layout the text.
  ///
  /// Requires [layout] to be called again before painting.
  double get minWidth => _paragraph.minWidth;
  void set minWidth(double value) {
    if (_paragraph.minWidth == value)
      return;
    _paragraph.minWidth = value;
    _needsLayout = true;
  }

  /// The maximum width at which to layout the text.
  ///
  /// Requires [layout] to be called again before painting.
  double get maxWidth => _paragraph.maxWidth;
  void set maxWidth(double value) {
    if (_paragraph.maxWidth == value)
      return;
    _paragraph.maxWidth = value;
    _needsLayout = true;
  }

  /// The minimum height at which to layout the text.
  ///
  /// Requires [layout] or [layoutToMaxIntrinsicWidth] to be called again before painting.
  double get minHeight => _paragraph.minHeight;
  void set minHeight(double value) {
    if (_paragraph.minHeight == value)
      return;
    _paragraph.minHeight = value;
    _needsLayout = true;
  }

  /// The maximum height at which to layout the text.
  ///
  /// Requires [layout] or [layoutToMaxIntrinsicWidth] to be called again before painting.
  double get maxHeight => _paragraph.maxHeight;
  void set maxHeight(double value) {
    if (_paragraph.maxHeight == value)
      return;
    _paragraph.maxHeight = value;
  }

  // Unfortunately, using full precision floating point here causes bad layouts
  // because floating point math isn't associative. If we add and subtract
  // padding, for example, we'll get different values when we estimate sizes and
  // when we actually compute layout because the operations will end up associated
  // differently. To work around this problem for now, we round fractional pixel
  // values up to the nearest whole pixel value. The right long-term fix is to do
  // layout using fixed precision arithmetic.
  double _applyFloatingPointHack(double layoutValue) {
    return layoutValue.ceilToDouble();
  }

  /// The width at which decreasing the width of the text would prevent it from painting itself completely within its bounds.
  ///
  /// Valid only after [layout] or [layoutToMaxIntrinsicWidth] has been called.
  double get minIntrinsicWidth {
    assert(!_needsLayout);
    return _applyFloatingPointHack(_paragraph.minIntrinsicWidth);
  }

  /// The width at which increasing the width of the text no longer decreases the height.
  ///
  /// Valid only after [layout] or [layoutToMaxIntrinsicWidth] has been called.
  double get maxIntrinsicWidth {
    assert(!_needsLayout);
    return _applyFloatingPointHack(_paragraph.maxIntrinsicWidth);
  }

  /// The horizontal space required to paint this text.
  ///
  /// Valid only after [layout] or [layoutToMaxIntrinsicWidth] has been called.
  double get width {
    assert(!_needsLayout);
    return _applyFloatingPointHack(_paragraph.width);
  }

  /// The vertical space required to paint this text.
  ///
  /// Valid only after [layout] or [layoutToMaxIntrinsicWidth] has been called.
  double get height {
    assert(!_needsLayout);
    return _applyFloatingPointHack(_paragraph.height);
  }

  /// The amount of space required to paint this text.
  ///
  /// Valid only after [layout] or [layoutToMaxIntrinsicWidth] has been called.
  Size get size {
    assert(!_needsLayout);
    return new Size(width, height);
  }

  /// Returns the distance from the top of the text to the first baseline of the given type.
  ///
  /// Valid only after [layout] or [layoutToMaxIntrinsicWidth] has been called.
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    assert(!_needsLayout);
    switch (baseline) {
      case TextBaseline.alphabetic:
        return _paragraph.alphabeticBaseline;
      case TextBaseline.ideographic:
        return _paragraph.ideographicBaseline;
    }
  }

  bool _lastLayoutWasToMaxIntrinsicWidth = false;

  /// Computes the visual position of the glyphs for painting the text.
  void layout() {
    if (!_needsLayout)
      return;
    _paragraph.layout();
    _needsLayout = false;
    _lastLayoutWasToMaxIntrinsicWidth = false;
  }

  /// Computes the visual position of the glyphs using the unconstrainted max intrinsic width.
  ///
  /// Overwrites the previously configured [minWidth] and [maxWidth] values.
  void layoutToMaxIntrinsicWidth() {
    if (!_needsLayout && _lastLayoutWasToMaxIntrinsicWidth && width == maxIntrinsicWidth)
      return;
    _needsLayout = false;
    _lastLayoutWasToMaxIntrinsicWidth = true;
    _paragraph
      ..minWidth = 0.0
      ..maxWidth = double.INFINITY
      ..layout();
    final double newMaxIntrinsicWidth = maxIntrinsicWidth;
    _paragraph
      ..minWidth = newMaxIntrinsicWidth
      ..maxWidth = newMaxIntrinsicWidth
      ..layout();
    assert(width == maxIntrinsicWidth);
  }

  /// Paints the text onto the given canvas at the given offset.
  ///
  /// Valid only after [layout] or [layoutToMaxIntrinsicWidth] has been called.
  void paint(Canvas canvas, Offset offset) {
    assert(() {
      if (_needsLayout) {
        throw new FlutterError(
          'TextPainter.paint called when text geometry was not yet calculated.\n'
          'Please call layout() before paint() to position the text before painting it.'
        );
      }
      return true;
    });
    canvas.drawParagraph(_paragraph, offset);
  }

  Offset _getOffsetFromUpstream(int offset, Rect caretPrototype) {
    List<ui.TextBox> boxes = _paragraph.getBoxesForRange(offset - 1, offset);
    if (boxes.isEmpty)
      return null;
    ui.TextBox box = boxes[0];
    double caretEnd = box.end;
    double dx = box.direction == TextDirection.rtl ? caretEnd : caretEnd - caretPrototype.width;
    return new Offset(dx, 0.0);
  }

  Offset _getOffsetFromDownstream(int offset, Rect caretPrototype) {
    List<ui.TextBox> boxes = _paragraph.getBoxesForRange(offset, offset + 1);
    if (boxes.isEmpty)
      return null;
    ui.TextBox box = boxes[0];
    double caretStart = box.start;
    double dx = box.direction == TextDirection.rtl ? caretStart - caretPrototype.width : caretStart;
    return new Offset(dx, 0.0);
  }

  /// Returns the offset at which to paint the caret.
  ///
  /// Valid only after [layout] or [layoutToMaxIntrinsicWidth] has been called.
  Offset getOffsetForCaret(TextPosition position, Rect caretPrototype) {
    assert(!_needsLayout);
    int offset = position.offset;
    // TODO(abarth): Handle the directionality of the text painter itself.
    const Offset emptyOffset = Offset.zero;
    switch (position.affinity) {
      case TextAffinity.upstream:
        return _getOffsetFromUpstream(offset, caretPrototype)
            ?? _getOffsetFromDownstream(offset, caretPrototype)
            ?? emptyOffset;
      case TextAffinity.downstream:
        return _getOffsetFromDownstream(offset, caretPrototype)
            ?? _getOffsetFromUpstream(offset, caretPrototype)
            ?? emptyOffset;
    }
  }

  /// Returns a list of rects that bound the given selection.
  ///
  /// A given selection might have more than one rect if this text painter
  /// contains bidirectional text because logically contiguous text might not be
  /// visually contiguous.
  List<ui.TextBox> getBoxesForSelection(TextSelection selection) {
    assert(!_needsLayout);
    return _paragraph.getBoxesForRange(selection.start, selection.end);
  }

  /// Returns the position within the text for the given pixel offset.
  TextPosition getPositionForOffset(Offset offset) {
    assert(!_needsLayout);
    return _paragraph.getPositionForOffset(offset);
  }

}
