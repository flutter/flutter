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

/// Called on each span as [InlineSpan.visitChildren] walks the InlineSpan tree.
///
/// Returns true when the walk should continue, and false to stop visiting further
/// [InlineSpan]s.
typedef InlineSpanVisitor = bool Function(InlineSpan span);

/// An immutable span of inline content which forms a paragraph.
///
/// The subclass [TextSpan] specifies text and may contain child [InlineSpan]s.
///
/// The subclass [PlaceholderSpan] represents a placeholder that may be
/// filled with non-text content. [PlaceholderSpan] itself defines a
/// [ui.PlaceholderAlignemnt] and a [TextBaseline]. To be useful,
/// [PlaceholderSpan] should be extended to define content. An instance of
/// this is the [WidgetSpan] class in the widgets library.
///
/// The subclass [WidgetSpan] specifies embedded inline widgets. Specify a
/// widget by wrapping the widget with a [WidgetSpan].
///
/// Leaving the [TextSpan.text] field null results in the [TextSpan] acting
/// as an empty node with a list of children.
///
/// {@tool sample}
///
/// This example shows a tree of [InlineSpan]s that make a query asking for a
/// name with a [TextField] embedded inline.
///
/// ```dart
/// RichText(
///   text: TextSpan(
///     text: 'My name is ',
///     style: TextStyle(color: Colors.black),
///     children: <InlineSpan>[
///       WidgetSpan(
///         alignment: InlineWidgetAlignment.baseline,
///         baseline: TextBaseline.alphabetic,
///         widget: ConstrainedBox(
///           constraints: BoxConstraints(maxWidth: 100),
///           child: TextField(),
///         )
///       ),
///       TextSpan(
///         text: '.',
///       ),
///     ],
///   ),
/// )
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [Text], a widget for showing uniformly-styled text.
///  * [RichText], a widget for finer control of text rendering.
///  * [TextPainter], a class for painting [InlineSpan] objects on a [Canvas].
@immutable
abstract class InlineSpan extends DiagnosticableTree {
  /// Creates a [InlineSpan] with the given values.
  const InlineSpan({
    this.style,
    this.children,
    this.semanticsLabel,
  });

  /// The style to apply to this span.
  ///
  /// The [style] is also applied to any child spans when this is an instance
  /// of [TextSpan].
  final TextStyle style;

  /// Additional spans to include as children.
  ///
  /// If both [text] and [children] are non-null, the text will precede the
  /// children.
  ///
  /// Modifying the list after the [TextSpan] has been created is not
  /// supported and may have unexpected results.
  ///
  /// The list must not contain any nulls.
  final List<InlineSpan> children;

  /// An alternative semantics label for this InlineSpan.
  ///
  /// If present, the semantics of this span will contain this value instead
  /// of the actual content.
  ///
  /// This is useful for replacing abbreviations or shorthands with the full
  /// text value:
  ///
  /// ```dart
  /// TextSpan(text: r'$$', semanticsLabel: 'Double dollars')
  /// ```
  final String semanticsLabel;

  /// Apply the properties of this object to the given [ParagraphBuilder], from
  /// which a [Paragraph] can be obtained. [Paragraph] objects can be drawn on
  /// [Canvas] objects.
  void build(ui.ParagraphBuilder builder, { double textScaleFactor = 1.0, List<PlaceholderDimensions> dimensions });

  /// Walks this [InlineSpan] and any descendants in pre-order and calls [visitor]
  /// for each span that has content.
  ///
  /// When [visitor] returns true, the walk will continue. When [visitor] returns
  /// false, then the walk will end.
  bool visitChildren(InlineSpanVisitor visitor);

  /// Returns the text span that contains the given position in the text. 
  InlineSpan getSpanForPosition(TextPosition position);

  /// Flattens the [InlineSpan] tree into a single string.
  ///
  /// Styles are not honored in this process. If `includeSemanticsLabels` is
  /// true, then the text returned will include the [TextStyle.semanticsLabel]s
  /// instead of the text contents for [TextSpan]s.
  String toPlainText({bool includeSemanticsLabels = true});

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
  /// assert(myInlineSpan.debugAssertIsValid());
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
  RenderComparison compareTo(InlineSpan other);

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other.runtimeType != runtimeType)
      return false;
    final InlineSpan typedOther = other;
    return typedOther.style == style
        && typedOther.semanticsLabel == semanticsLabel
        && listEquals<InlineSpan>(typedOther.children, children);
  }

  @override
  int get hashCode => hashValues(style, hashList(children));

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.defaultDiagnosticsTreeStyle = DiagnosticsTreeStyle.whitespace;
    // Properties on style are added as if they were properties directly on
    // this InlineSpan.
    if (style != null) {
      style.debugFillProperties(properties);
    }

    if (semanticsLabel != null) {
      properties.add(StringProperty('semanticsLabel', semanticsLabel));
    }
  }
}
