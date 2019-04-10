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

/// An immutable span of content. [LayoutSpan]s do not contain content directly and
/// should be instances of [TextSpan] or [WidgetSpan] to properly represent content.
///
/// Widgets may be embedded inline. Specify a widget within the [TextSpan.children]
/// tree by wrapping the widget with a [WidgetSpan]. The widget will be laid
/// out inline within the paragraph.
///
/// See also:
///
///  * [TextSpan], a [LayoutSpan] node that represents text in a [LayoutSpan] tree. Only [TextSpan]
///    may have children nodes.
///  * [WidgetSpan], a leaf [LayoutSpan] node that represents an embedded inline widget
///    in a [LayoutSpan] tree.
///  * [Text], a widget for showing uniformly-styled text.
///  * [RichText], a widget for finer control of text rendering.
///  * [TextPainter], a class for painting [LayoutSpan] objects on a [Canvas].
@immutable
abstract class LayoutSpan extends DiagnosticableTree {
  /// Creates a [LayoutSpan] with the given values.
  const LayoutSpan({
    this.style,
    this.recognizer,
  });

  /// Provided for API compatibility, LayoutSpan does not represent text.
  /// [TextSpan] should be used instead.
  String get text => null;

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
  /// [TextPainter] class to paint [TextSpan] objects onto [Canvas]
  /// objects.
  void build(ui.ParagraphBuilder builder, { double textScaleFactor = 1.0, List<PlaceholderDimensions> dimensions });

  /// Walks this text span and any descendants in pre-order and calls [visitor]
  /// for each span that has content.
  bool visitLayoutSpan(bool visitor(LayoutSpan span));

  /// Returns the text span that contains the given position in the text.
  LayoutSpan getSpanForPosition(TextPosition position);

  /// Flattens the [LayoutSpan] tree into a single string.
  ///
  /// Styles are not honored in this process.
  String toPlainText();

  /// Returns the UTF-16 code unit at the given index in the flattened string.
  ///
  /// Returns null if the index is out of bounds.
  int codeUnitAt(int index);

  /// In checked mode, throws an exception if the object is not in a
  /// valid configuration. Otherwise, returns true.
  ///
  /// This is intended to be used as follows:
  ///
  /// ```dart
  /// assert(myLayoutSpan.debugAssertIsValid());
  /// ```
  bool debugAssertIsValid();

  /// Describe the difference between this span and another, in terms of
  /// how much damage it will make to the rendering. The comparison is deep.
  ///
  /// Comparing a [TextSpan] with a [WidgetSpan] will result in [RenderComparison.layout].
  ///
  /// See also:
  ///
  ///  * [TextStyle.compareTo], which does the same thing for [TextStyle]s.
  RenderComparison compareTo(LayoutSpan other);

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other.runtimeType != runtimeType)
      return false;
    final LayoutSpan typedOther = other;
    return typedOther.style == style
        && typedOther.recognizer == recognizer;
  }

  @override
  int get hashCode => hashValues(style, recognizer);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.defaultDiagnosticsTreeStyle = DiagnosticsTreeStyle.whitespace;
    // Properties on style are added as if they were properties directly on
    // this LayoutSpan.
    if (style != null)
      style.debugFillProperties(properties);

    properties.add(DiagnosticsProperty<GestureRecognizer>(
      'recognizer', recognizer,
      description: recognizer?.runtimeType?.toString(),
      defaultValue: null,
    ));
  }
}
