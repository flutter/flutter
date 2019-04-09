// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui show ParagraphBuilder;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

import 'basic_types.dart';
import 'text_style.dart';
import 'text_painter.dart';

/// An immutable span of text.
///
/// A [LayoutSpan] object can be styled using its [style] property.
/// The style will be applied to the [text] and the [children].
///
/// A [LayoutSpan] object can just have plain text, or it can have
/// children [LayoutSpan] objects with their own styles that (possibly
/// only partially) override the [style] of this object. If a
/// [LayoutSpan] has both [text] and [children], then the [text] is
/// treated as if it was an unstyled [LayoutSpan] at the start of the
/// [children] list.
///
/// To paint a [LayoutSpan] on a [Canvas], use a [TextPainter]. To display a text
/// span in a widget, use a [RichText]. For text with a single style, consider
/// using the [Text] widget.
///
/// {@tool sample}
///
/// The text "Hello world!", in black:
///
/// ```dart
/// LayoutSpan(
///   text: 'Hello world!',
///   style: TextStyle(color: Colors.black),
/// )
/// ```
/// {@end-tool}
///
/// _There is some more detailed sample code in the documentation for the
/// [recognizer] property._
///
/// Widgets may be embedded inline. Specify a widget within the [children]
/// tree by wrapping the widget with a [WidgetSpan]. The widget will be laid
/// out inline within the paragraph.
///
/// See also:
///
///  * [WidgetSpan], a leaf node that represents an embedded inline widget
///    in a [LayoutSpan] tree.
///  * [Text], a widget for showing uniformly-styled text.
///  * [RichText], a widget for finer control of text rendering.
///  * [TextPainter], a class for painting [LayoutSpan] objects on a [Canvas].
@immutable
abstract class LayoutSpan extends DiagnosticableTree {
  /// Creates a [LayoutSpan] with the given values.
  ///
  /// For the object to be useful, at least one of [text] or
  /// [children] should be set.
  const LayoutSpan({
    this.text,
    this.style,
    this.recognizer,
  });

  final String text;

  /// The style to apply to the [text] and the [children].
  final TextStyle style;

  /// A gesture recognizer that will receive events that hit this text span.
  ///
  /// [LayoutSpan] itself does not implement hit testing or event dispatch. The
  /// object that manages the [LayoutSpan] painting is also responsible for
  /// dispatching events. In the rendering library, that is the
  /// [RenderParagraph] object, which corresponds to the [RichText] widget in
  /// the widgets layer; these objects do not bubble events in [LayoutSpan]s, so a
  /// [recognizer] is only effective for events that directly hit the [text] of
  /// that [LayoutSpan], not any of its [children].
  ///
  /// [LayoutSpan] also does not manage the lifetime of the gesture recognizer.
  /// The code that owns the [GestureRecognizer] object must call
  /// [GestureRecognizer.dispose] when the [LayoutSpan] object is no longer used.
  ///
  /// {@tool sample}
  ///
  /// This example shows how to manage the lifetime of a gesture recognizer
  /// provided to a [LayoutSpan] object. It defines a `BuzzingText` widget which
  /// uses the [HapticFeedback] class to vibrate the device when the user
  /// long-presses the "find the" span, which is underlined in wavy green. The
  /// hit-testing is handled by the [RichText] widget.
  ///
  /// ```dart
  /// class BuzzingText extends StatefulWidget {
  ///   @override
  ///   _BuzzingTextState createState() => _BuzzingTextState();
  /// }
  ///
  /// class _BuzzingTextState extends State<BuzzingText> {
  ///   LongPressGestureRecognizer _longPressRecognizer;
  ///
  ///   @override
  ///   void initState() {
  ///     super.initState();
  ///     _longPressRecognizer = LongPressGestureRecognizer()
  ///       ..onLongPress = _handlePress;
  ///   }
  ///
  ///   @override
  ///   void dispose() {
  ///     _longPressRecognizer.dispose();
  ///     super.dispose();
  ///   }
  ///
  ///   void _handlePress() {
  ///     HapticFeedback.vibrate();
  ///   }
  ///
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     return RichText(
  ///       text: LayoutSpan(
  ///         text: 'Can you ',
  ///         style: TextStyle(color: Colors.black),
  ///         children: <LayoutSpan>[
  ///           LayoutSpan(
  ///             text: 'find the',
  ///             style: TextStyle(
  ///               color: Colors.green,
  ///               decoration: TextDecoration.underline,
  ///               decorationStyle: TextDecorationStyle.wavy,
  ///             ),
  ///             recognizer: _longPressRecognizer,
  ///           ),
  ///           LayoutSpan(
  ///             text: ' secret?',
  ///           ),
  ///         ],
  ///       ),
  ///     );
  ///   }
  /// }
  /// ```
  /// {@end-tool}
  final GestureRecognizer recognizer;

  /// Apply the [style], [text], and [children] of this object to the
  /// given [ParagraphBuilder], from which a [Paragraph] can be obtained.
  /// [Paragraph] objects can be drawn on [Canvas] objects.
  ///
  /// Rather than using this directly, it's simpler to use the
  /// [TextPainter] class to paint [LayoutSpan] objects onto [Canvas]
  /// objects.
  void build(ui.ParagraphBuilder builder, { double textScaleFactor = 1.0, List<PlaceholderDimensions> dimensions });
  //   assert(debugAssertIsValid());
  //   final bool hasStyle = style != null;
  //   if (hasStyle)
  //     builder.pushStyle(style.getTextStyle(textScaleFactor: textScaleFactor));
  //   if (text != null)
  //     builder.addText(text);
  //   if (children != null) {
  //     for (LayoutSpan child in children) {
  //       assert(child != null);
  //       child.build(builder, textScaleFactor: textScaleFactor, dimensions: dimensions);
  //     }
  //   }
  //   if (hasStyle)
  //     builder.pop();
  // }

  /// Walks this text span and its descendants in pre-order and calls [visitor]
  /// for each span that has text.
  bool visitLayoutSpan(bool visitor(LayoutSpan span));
  //   if (text != null) {
  //     if (!visitor(this))
  //       return false;
  //   }
  //   if (children != null) {
  //     for (LayoutSpan child in children) {
  //       if (!child.visitLayoutSpan(visitor))
  //         return false;
  //     }
  //   }
  //   return true;
  // }

  /// Returns the text span that contains the given position in the text.
  LayoutSpan getSpanForPosition(TextPosition position);
  //   assert(debugAssertIsValid());
  //   final TextAffinity affinity = position.affinity;
  //   final int targetOffset = position.offset;
  //   int offset = 0;
  //   LayoutSpan result;
  //   visitLayoutSpan((LayoutSpan span) {
  //     assert(result == null);
  //     final int endOffset = offset + span.text.length;
  //     if (targetOffset == offset && affinity == TextAffinity.downstream ||
  //         targetOffset > offset && targetOffset < endOffset ||
  //         targetOffset == endOffset && affinity == TextAffinity.upstream) {
  //       result = span;
  //       return false;
  //     }
  //     offset = endOffset;
  //     return true;
  //   });
  //   return result;
  // }

  /// Flattens the [LayoutSpan] tree into a single string.
  ///
  /// Styles are not honored in this process.
  String toPlainText();
  //   assert(debugAssertIsValid());
  //   final StringBuffer buffer = StringBuffer();
  //   visitLayoutSpan((LayoutSpan span) {
  //     buffer.write(span.text);
  //     return true;
  //   });
  //   return buffer.toString();
  // }

  /// Returns the UTF-16 code unit at the given index in the flattened string.
  ///
  /// Returns null if the index is out of bounds.
  int codeUnitAt(int index);
  //   if (index < 0)
  //     return null;
  //   int offset = 0;
  //   int result;
  //   visitLayoutSpan((LayoutSpan span) {
  //     if (index - offset < span.text.length) {
  //       result = span.text.codeUnitAt(index - offset);
  //       return false;
  //     }
  //     offset += span.text.length;
  //     return true;
  //   });
  //   return result;
  // }

  /// In checked mode, throws an exception if the object is not in a
  /// valid configuration. Otherwise, returns true.
  ///
  /// This is intended to be used as follows:
  ///
  /// ```dart
  /// assert(myLayoutSpan.debugAssertIsValid());
  /// ```
  bool debugAssertIsValid();
  //   assert(() {
  //     if (!visitLayoutSpan((LayoutSpan span) {
  //       if (span.children != null) {
  //         for (LayoutSpan child in span.children) {
  //           if (child == null)
  //             return false;
  //         }
  //       }
  //       return true;
  //     })) {
  //       throw FlutterError(
  //         'LayoutSpan contains a null child.\n'
  //         'A LayoutSpan object with a non-null child list should not have any nulls in its child list.\n'
  //         'The full text in question was:\n'
  //         '${toStringDeep(prefixLineOne: '  ')}'
  //       );
  //     }
  //     return true;
  //   }());
  //   return true;
  // }

  /// Describe the difference between this text span and another, in terms of
  /// how much damage it will make to the rendering. The comparison is deep.
  ///
  /// Comparing a [LayoutSpan] with a [WidgetSpan] will result in [RenderComparison.layout].
  ///
  /// See also:
  ///
  ///  * [TextStyle.compareTo], which does the same thing for [TextStyle]s.
  RenderComparison compareTo(LayoutSpan other);
  //   if (identical(this, other))
  //     return RenderComparison.identical;
  //   if (other.text != text ||
  //       children?.length != other.children?.length ||
  //       (style == null) != (other.style == null))
  //     return RenderComparison.layout;
  //   RenderComparison result = recognizer == other.recognizer ? RenderComparison.identical : RenderComparison.metadata;
  //   if (style != null) {
  //     final RenderComparison candidate = style.compareTo(other.style);
  //     if (candidate.index > result.index)
  //       result = candidate;
  //     if (result == RenderComparison.layout)
  //       return result;
  //   }
  //   if (children != null) {
  //     for (int index = 0; index < children.length; index += 1) {
  //       final RenderComparison candidate = children[index].compareTo(other.children[index]);
  //       if (candidate.index > result.index)
  //         result = candidate;
  //       if (result == RenderComparison.layout)
  //         return result;
  //     }
  //   }
  //   return result;
  // }

  // @override
  // bool operator ==(dynamic other) {
  //   if (identical(this, other))
  //     return true;
  //   if (other.runtimeType != runtimeType)
  //     return false;
  //   final LayoutSpan typedOther = other;
  //   return typedOther.text == text
  //       && typedOther.style == style
  //       && typedOther.recognizer == recognizer
  //       && listEquals<LayoutSpan>(typedOther.children, children);
  // }

  // @override
  // int get hashCode => hashValues(style, text, recognizer, hashList(children));

  // @override
  // String toStringShort() => '$runtimeType';

  // @override
  // void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  //   super.debugFillProperties(properties);
  //   properties.defaultDiagnosticsTreeStyle = DiagnosticsTreeStyle.whitespace;
  //   // Properties on style are added as if they were properties directly on
  //   // this LayoutSpan.
  //   if (style != null)
  //     style.debugFillProperties(properties);

  //   properties.add(DiagnosticsProperty<GestureRecognizer>(
  //     'recognizer', recognizer,
  //     description: recognizer?.runtimeType?.toString(),
  //     defaultValue: null,
  //   ));

  //   properties.add(StringProperty('text', text, showName: false, defaultValue: null));
  //   if (style == null && text == null && children == null)
  //     properties.add(DiagnosticsNode.message('(empty)'));
  // }

  // @override
  // List<DiagnosticsNode> debugDescribeChildren() {
  //   if (children == null)
  //     return const <DiagnosticsNode>[];
  //   return children.map<DiagnosticsNode>((LayoutSpan child) {
  //     if (child != null) {
  //       return child.toDiagnosticsNode();
  //     } else {
  //       return DiagnosticsNode.message('<null child>');
  //     }
  //   }).toList();
  // }
}
