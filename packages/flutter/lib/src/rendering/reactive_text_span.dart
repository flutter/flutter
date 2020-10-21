// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/painting.dart';

import 'mouse_cursor.dart';
import 'mouse_tracking.dart';

/// An immutable span of text that can react to gestures and mouse movements.
///
/// Aside from what [TextSpan] provides, [ReactiveTextSpan] also accepts a
/// [recognizer] that recognizes gestures starting on this text span, as well as
/// allowing customizing the [mouseCursor] when a mouse hovers over it.
class ReactiveTextSpan extends TextSpan implements MouseTrackerAnnotation {
  /// Creates a [ReactiveTextSpan] with the given values.
  ///
  /// For the object to be useful, at least one of [text] or
  /// [children] should be set.
  const ReactiveTextSpan({
    String? text,
    List<InlineSpan>? children,
    TextStyle? style,
    GestureRecognizer? recognizer,
    MouseCursor? mouseCursor,
    this.onEnter,
    this.onExit,
    String? semanticsLabel,
  }) : mouseCursor = mouseCursor ??
           (recognizer == null ? MouseCursor.defer : SystemMouseCursors.click),
       super(
         text: text,
         children: children,
         recognizer: recognizer,
         style: style,
         semanticsLabel: semanticsLabel,
       );

  /// A gesture recognizer that will receive events that hit this span.
  ///
  /// [ReactiveTextSpan] itself does not implement hit testing or event dispatch.
  /// The object that manages the [ReactiveTextSpan] painting is also responsible
  /// for dispatching events. In the rendering library, that is the
  /// [RenderParagraph] object, which corresponds to the [RichText] widget in the
  /// widgets layer; these objects do not bubble events in [InlineSpan]s, so a
  /// [recognizer] is only effective for events that directly hit the [text] of
  /// that [ReactiveTextSpan], not any of its [children].
  ///
  /// [ReactiveTextSpan] also does not manage the lifetime of the gesture
  /// recognizer. The code that owns the [GestureRecognizer] object must call
  /// [GestureRecognizer.dispose] when the [ReactiveTextSpan] object is no longer
  /// used.
  ///
  /// {@tool snippet}
  ///
  /// This example shows how to manage the lifetime of a gesture recognizer
  /// provided to an [ReactiveTextSpan] object. It defines a `BuzzingText` widget
  /// which uses the [HapticFeedback] class to vibrate the device when the user
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
  ///     return Text.rich(
  ///       TextSpan(
  ///         text: 'Can you ',
  ///         style: TextStyle(color: Colors.black),
  ///         children: <InlineSpan>[
  ///           ReactiveTextSpan(
  ///             text: 'find the',
  ///             style: TextStyle(
  ///               color: Colors.green,
  ///               decoration: TextDecoration.underline,
  ///               decorationStyle: TextDecorationStyle.wavy,
  ///             ),
  ///             recognizer: _longPressRecognizer,
  ///           ),
  ///           TextSpan(
  ///             text: ' secret?',
  ///           ),
  ///         ],
  ///       ),
  ///     );
  ///   }
  /// }
  /// ```
  /// {@end-tool}
  @override
  // This field is overridden only to override the documentation.
  GestureRecognizer? get recognizer => super.recognizer;

  /// Mouse cursor when the mouse hovers over this span.
  ///
  /// The default value is [SystemMouseCursors.click] if [recognizer] is not
  /// null, or [MouseCursor.defer] otherwise.
  ///
  /// [ReactiveTextSpan] itself does not implement hit testing or cursor changing.
  /// The object that manages the [ReactiveTextSpan] painting is responsible
  /// to return the [ReactiveTextSpan] in its hit test, as well as providing the
  /// correct mouse cursor when the [ReactiveTextSpan]'s mouse cursor is
  /// [MouseCursor.defer].
  final MouseCursor mouseCursor;

  @override
  final PointerEnterEventListener? onEnter;

  @override
  final PointerExitEventListener? onExit;

  /// Returns the value of [mouseCursor].
  ///
  /// This field, required by [MouseTrackerAnnotation], is hidden publicly to
  /// avoid the confusion as a text cursor.
  @protected
  @override
  MouseCursor get cursor => mouseCursor;
}
