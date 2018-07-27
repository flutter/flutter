// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';

import 'button.dart';

// Padding around the line at the edge of the text selection that has 0 width and
// the height of the text font.
const double _kHandlesPadding = 18.0;
// Minimal padding from all edges of the selection toolbar to all edges of the
// viewport.
const double _kToolbarScreenPadding = 8.0;
const double _kToolbarHeight = 36.0;

const Color _kToolbarBackgroundColor = const Color(0xFF2E2E2E);
const Color _kToolbarDividerColor = const Color(0xFFB9B9B9);
const Color _kHandlesColor = const Color(0xFF146DDE);

// This offset is used to determine the center of the selection during a drag.
// It's slightly below the center of the text so the finger isn't entirely
// covering the text being selected.
const Size _kSelectionOffset = const Size(20.0, 30.0);
const Size _kToolbarTriangleSize = const Size(18.0, 9.0);
const EdgeInsets _kToolbarButtonPadding = const EdgeInsets.symmetric(vertical: 10.0, horizontal: 21.0);
const BorderRadius _kToolbarBorderRadius = const BorderRadius.all(const Radius.circular(7.5));

const TextStyle _kToolbarButtonFontStyle = const TextStyle(
  fontSize: 14.0,
  letterSpacing: -0.11,
  fontWeight: FontWeight.w300,
);

/// Paints a triangle below the toolbar.
class _TextSelectionToolbarNotchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = new Paint()
        ..color = _kToolbarBackgroundColor
        ..style = PaintingStyle.fill;
    final Path triangle = new Path()
        ..lineTo(_kToolbarTriangleSize.width / 2, 0.0)
        ..lineTo(0.0, _kToolbarTriangleSize.height)
        ..lineTo(-(_kToolbarTriangleSize.width / 2), 0.0)
        ..close();
    canvas.drawPath(triangle, paint);
  }

  @override
  bool shouldRepaint(_TextSelectionToolbarNotchPainter oldPainter) => false;
}

/// Manages a copy/paste text selection toolbar.
class _TextSelectionToolbar extends StatelessWidget {
  const _TextSelectionToolbar({
    Key key,
    this.handleCut,
    this.handleCopy,
    this.handlePaste,
    this.handleSelectAll,
  }) : super(key: key);

  final VoidCallback handleCut;
  final VoidCallback handleCopy;
  final VoidCallback handlePaste;
  final VoidCallback handleSelectAll;

  @override
  Widget build(BuildContext context) {
    final List<Widget> items = <Widget>[];
    final Widget onePhysicalPixelVerticalDivider =
        new SizedBox(width: 1.0 / MediaQuery.of(context).devicePixelRatio);

    if (handleCut != null)
      items.add(_buildToolbarButton('Cut', handleCut));

    if (handleCopy != null) {
      if (items.isNotEmpty)
        items.add(onePhysicalPixelVerticalDivider);
      items.add(_buildToolbarButton('Copy', handleCopy));
    }

    if (handlePaste != null) {
      if (items.isNotEmpty)
        items.add(onePhysicalPixelVerticalDivider);
      items.add(_buildToolbarButton('Paste', handlePaste));
    }

    if (handleSelectAll != null) {
      if (items.isNotEmpty)
        items.add(onePhysicalPixelVerticalDivider);
      items.add(_buildToolbarButton('Select All', handleSelectAll));
    }

    final Widget triangle = new SizedBox.fromSize(
      size: _kToolbarTriangleSize,
      child: new CustomPaint(
        painter: new _TextSelectionToolbarNotchPainter(),
      )
    );

    return new Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        new ClipRRect(
          borderRadius: _kToolbarBorderRadius,
          child: new DecoratedBox(
            decoration: const BoxDecoration(
              color: _kToolbarDividerColor,
            ),
            child: new Row(mainAxisSize: MainAxisSize.min, children: items),
          ),
        ),
        // TODO(https://github.com/flutter/flutter/issues/11274):
        // Position the triangle based on the layout delegate.
        // And avoid letting the triangle line up with any dividers.
        triangle,
      ],
    );
  }

  /// Builds a themed [CupertinoButton] for the toolbar.
  CupertinoButton _buildToolbarButton(String text, VoidCallback onPressed) {
    return new CupertinoButton(
      child: new Text(text, style: _kToolbarButtonFontStyle),
      color: _kToolbarBackgroundColor,
      minSize: _kToolbarHeight,
      padding: _kToolbarButtonPadding,
      borderRadius: null,
      pressedOpacity: 0.7,
      onPressed: onPressed,
    );
  }
}

/// Centers the toolbar around the given position, ensuring that it remains on
/// screen.
class _TextSelectionToolbarLayout extends SingleChildLayoutDelegate {
  _TextSelectionToolbarLayout(this.screenSize, this.globalEditableRegion, this.position);

  /// The size of the screen at the time that the toolbar was last laid out.
  final Size screenSize;

  /// Size and position of the editing region at the time the toolbar was last
  /// laid out, in global coordinates.
  final Rect globalEditableRegion;

  /// Anchor position of the toolbar, relative to the top left of the
  /// [globalEditableRegion].
  final Offset position;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return constraints.loosen();
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final Offset globalPosition = globalEditableRegion.topLeft + position;

    double x = globalPosition.dx - childSize.width / 2.0;
    double y = globalPosition.dy - childSize.height;

    if (x < _kToolbarScreenPadding)
      x = _kToolbarScreenPadding;
    else if (x + childSize.width > screenSize.width - _kToolbarScreenPadding)
      x = screenSize.width - childSize.width - _kToolbarScreenPadding;

    if (y < _kToolbarScreenPadding)
      y = _kToolbarScreenPadding;
    else if (y + childSize.height > screenSize.height - _kToolbarScreenPadding)
      y = screenSize.height - childSize.height - _kToolbarScreenPadding;

    return new Offset(x, y);
  }

  @override
  bool shouldRelayout(_TextSelectionToolbarLayout oldDelegate) {
    return screenSize != oldDelegate.screenSize
        || globalEditableRegion != oldDelegate.globalEditableRegion
        || position != oldDelegate.position;
  }
}

/// Draws a single text selection handle with a bar and a ball.
///
/// Draws from a point of origin somewhere inside the size of the painter
/// such that the ball is below the point of origin and the bar is above the
/// point of origin.
class _TextSelectionHandlePainter extends CustomPainter {
  _TextSelectionHandlePainter({this.origin});

  final Offset origin;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = new Paint()
        ..color = _kHandlesColor
        ..strokeWidth = 2.0;
    // Draw circle below the origin that slightly overlaps the bar.
    canvas.drawCircle(origin.translate(0.0, 4.0), 5.5, paint);
    // Draw up from origin leaving 10 pixels of margin on top.
    canvas.drawLine(
      origin,
      origin.translate(
        0.0,
        -(size.height - 2.0 * _kHandlesPadding),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_TextSelectionHandlePainter oldPainter) => origin != oldPainter.origin;
}

class _CupertinoTextSelectionControls extends TextSelectionControls {
  @override
  Size handleSize = _kSelectionOffset; // Used for drag selection offset.

  /// Builder for iOS-style copy/paste text selection toolbar.
  @override
  Widget buildToolbar(BuildContext context, Rect globalEditableRegion, Offset position, TextSelectionDelegate delegate) {
    assert(debugCheckHasMediaQuery(context));
    return new ConstrainedBox(
      constraints: new BoxConstraints.tight(globalEditableRegion.size),
      child: new CustomSingleChildLayout(
        delegate: new _TextSelectionToolbarLayout(
          MediaQuery.of(context).size,
          globalEditableRegion,
          position,
        ),
        child: new _TextSelectionToolbar(
          handleCut: canCut(delegate) ? () => handleCut(delegate) : null,
          handleCopy: canCopy(delegate) ? () => handleCopy(delegate) : null,
          handlePaste: canPaste(delegate) ? () => handlePaste(delegate) : null,
          handleSelectAll: canSelectAll(delegate) ? () => handleSelectAll(delegate) : null,
        ),
      )
    );
  }

  /// Builder for iOS text selection edges.
  @override
  Widget buildHandle(BuildContext context, TextSelectionHandleType type, double textLineHeight) {
    // We want a size that's a vertical line the height of the text plus a 18.0
    // padding in every direction that will constitute the selection drag area.
    final Size desiredSize = new Size(
      2.0 * _kHandlesPadding,
      textLineHeight + 2.0 * _kHandlesPadding
    );

    final Widget handle = new SizedBox.fromSize(
      size: desiredSize,
      child: new CustomPaint(
        painter: new _TextSelectionHandlePainter(
          // We give the painter a point of origin that's at the bottom baseline
          // of the selection cursor position.
          //
          // We give it in the form of an offset from the top left of the
          // SizedBox.
          origin: new Offset(_kHandlesPadding, textLineHeight + _kHandlesPadding),
        ),
      ),
    );

    // [buildHandle]'s widget is positioned at the selection cursor's bottom
    // baseline. We transform the handle such that the SizedBox is superimposed
    // on top of the text selection endpoints.
    switch (type) {
      case TextSelectionHandleType.left: // The left handle is upside down on iOS.
        return new Transform(
          transform: new Matrix4.rotationZ(math.pi)
              ..translate(-_kHandlesPadding, -_kHandlesPadding),
          child: handle
        );
      case TextSelectionHandleType.right:
        return new Transform(
          transform: new Matrix4.translationValues(
            -_kHandlesPadding,
            -(textLineHeight + _kHandlesPadding),
            0.0
          ),
          child: handle
        );
      case TextSelectionHandleType.collapsed: // iOS doesn't draw anything for collapsed selections.
        return new Container();
    }
    assert(type != null);
    return null;
  }
}

/// Text selection controls that follows iOS design conventions.
final TextSelectionControls cupertinoTextSelectionControls = new _CupertinoTextSelectionControls();
