// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';

import 'button.dart';
import 'colors.dart';
import 'localizations.dart';

// Padding around the line at the edge of the text selection that has 0 width and
// the height of the text font.
const double _kHandlesPadding = 18.0;
// Minimal padding from all edges of the selection toolbar to all edges of the
// viewport.
const double _kToolbarScreenPadding = 8.0;
const double _kToolbarHeight = 36.0;

const Color _kToolbarBackgroundColor = Color(0xFF2E2E2E);
const Color _kToolbarDividerColor = Color(0xFFB9B9B9);
// Read off from the output on iOS 12. This color does not vary with the
// application's theme color.
const Color _kHandlesColor = Color(0xFF136FE0);

// This offset is used to determine the center of the selection during a drag.
// It's slightly below the center of the text so the finger isn't entirely
// covering the text being selected.
const Size _kSelectionOffset = Size(20.0, 30.0);
const Size _kToolbarTriangleSize = Size(18.0, 9.0);
const EdgeInsets _kToolbarButtonPadding = EdgeInsets.symmetric(vertical: 10.0, horizontal: 18.0);
const BorderRadius _kToolbarBorderRadius = BorderRadius.all(Radius.circular(7.5));

const TextStyle _kToolbarButtonFontStyle = TextStyle(
  inherit: false,
  fontSize: 14.0,
  letterSpacing: -0.11,
  fontWeight: FontWeight.w300,
  color: CupertinoColors.white,
);

/// The direction of the triangle attached to the toolbar.
///
/// Defaults to showing the triangle downwards if sufficient space is available
/// to show the toolbar above the text field. Otherwise, the toolbar will
/// appear below the text field and the triangle's direction will be [up].
enum _ArrowDirection { up, down }

/// Paints a triangle below the toolbar.
class _TextSelectionToolbarNotchPainter extends CustomPainter {
  const _TextSelectionToolbarNotchPainter(
    this.arrowDirection
  ) : assert (arrowDirection != null);

  final _ArrowDirection arrowDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
        ..color = _kToolbarBackgroundColor
        ..style = PaintingStyle.fill;
    final double triangleBottomY = (arrowDirection == _ArrowDirection.down)
        ? 0.0
        : _kToolbarTriangleSize.height;
    final Path triangle = Path()
        ..lineTo(_kToolbarTriangleSize.width / 2, triangleBottomY)
        ..lineTo(0.0, _kToolbarTriangleSize.height)
        ..lineTo(-(_kToolbarTriangleSize.width / 2), triangleBottomY)
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
    this.arrowDirection,
  }) : super(key: key);

  final VoidCallback handleCut;
  final VoidCallback handleCopy;
  final VoidCallback handlePaste;
  final VoidCallback handleSelectAll;
  final _ArrowDirection arrowDirection;

  @override
  Widget build(BuildContext context) {
    final List<Widget> items = <Widget>[];
    final Widget onePhysicalPixelVerticalDivider =
    SizedBox(width: 1.0 / MediaQuery.of(context).devicePixelRatio);
    final CupertinoLocalizations localizations = CupertinoLocalizations.of(context);

    if (handleCut != null)
      items.add(_buildToolbarButton(localizations.cutButtonLabel, handleCut));

    if (handleCopy != null) {
      if (items.isNotEmpty)
        items.add(onePhysicalPixelVerticalDivider);
      items.add(_buildToolbarButton(localizations.copyButtonLabel, handleCopy));
    }

    if (handlePaste != null) {
      if (items.isNotEmpty)
        items.add(onePhysicalPixelVerticalDivider);
      items.add(_buildToolbarButton(localizations.pasteButtonLabel, handlePaste));
    }

    if (handleSelectAll != null) {
      if (items.isNotEmpty)
        items.add(onePhysicalPixelVerticalDivider);
      items.add(_buildToolbarButton(localizations.selectAllButtonLabel, handleSelectAll));
    }

    const Widget padding = Padding(padding: EdgeInsets.only(bottom: 10.0));

    final Widget triangle = SizedBox.fromSize(
      size: _kToolbarTriangleSize,
      child: CustomPaint(
        painter: _TextSelectionToolbarNotchPainter(arrowDirection),
      ),
    );

    final Widget toolbar = ClipRRect(
      borderRadius: _kToolbarBorderRadius,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _kToolbarDividerColor,
          borderRadius: _kToolbarBorderRadius,
          // Add a hairline border with the button color to avoid
          // antialiasing artifacts.
          border: Border.all(color: _kToolbarBackgroundColor, width: 0),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: items),
      ),
    );

    final List<Widget> menus = (arrowDirection == _ArrowDirection.down)
        ? <Widget>[
            toolbar,
            // TODO(xster): Position the triangle based on the layout delegate, and
            // avoid letting the triangle line up with any dividers.
            // https://github.com/flutter/flutter/issues/11274
            triangle,
            padding,
          ]
        : <Widget>[
            padding,
            triangle,
            toolbar,
          ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: menus,
    );
  }

  /// Builds a themed [CupertinoButton] for the toolbar.
  CupertinoButton _buildToolbarButton(String text, VoidCallback onPressed) {
    return CupertinoButton(
      child: Text(text, style: _kToolbarButtonFontStyle),
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

    return Offset(x, y);
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
    final Paint paint = Paint()
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
  Widget buildToolbar(
    BuildContext context,
    Rect globalEditableRegion,
    Offset position,
    List<TextSelectionPoint> endpoints,
    TextSelectionDelegate delegate,
  ) {
    assert(debugCheckHasMediaQuery(context));

    // The toolbar should appear below the TextField
    // when there is not enough space above the TextField to show it.
    final double availableHeight
        = globalEditableRegion.top - MediaQuery.of(context).padding.top - _kToolbarScreenPadding;
    final _ArrowDirection direction = (availableHeight > _kToolbarHeight)
        ? _ArrowDirection.down
        : _ArrowDirection.up;

    final TextSelectionPoint startTextSelectionPoint = endpoints[0];
    final TextSelectionPoint endTextSelectionPoint = (endpoints.length > 1)
        ? endpoints[1]
        : null;
    final double x = (endTextSelectionPoint == null)
        ? startTextSelectionPoint.point.dx
        : (startTextSelectionPoint.point.dx + endTextSelectionPoint.point.dx) / 2.0;
    final double y = (direction == _ArrowDirection.up)
        ? startTextSelectionPoint.point.dy + globalEditableRegion.height + _kToolbarHeight
        : startTextSelectionPoint.point.dy - globalEditableRegion.height;
    final Offset preciseMidpoint = Offset(x, y);

    return ConstrainedBox(
      constraints: BoxConstraints.tight(globalEditableRegion.size),
      child: CustomSingleChildLayout(
        delegate: _TextSelectionToolbarLayout(
          MediaQuery.of(context).size,
          globalEditableRegion,
          preciseMidpoint,
        ),
        child: _TextSelectionToolbar(
          handleCut: canCut(delegate) ? () => handleCut(delegate) : null,
          handleCopy: canCopy(delegate) ? () => handleCopy(delegate) : null,
          handlePaste: canPaste(delegate) ? () => handlePaste(delegate) : null,
          handleSelectAll: canSelectAll(delegate) ? () => handleSelectAll(delegate) : null,
          arrowDirection: direction,
        ),
      ),
    );
  }

  /// Builder for iOS text selection edges.
  @override
  Widget buildHandle(BuildContext context, TextSelectionHandleType type, double textLineHeight) {
    // We want a size that's a vertical line the height of the text plus a 18.0
    // padding in every direction that will constitute the selection drag area.
    final Size desiredSize = Size(
      2.0 * _kHandlesPadding,
      textLineHeight + 2.0 * _kHandlesPadding,
    );

    final Widget handle = SizedBox.fromSize(
      size: desiredSize,
      child: CustomPaint(
        painter: _TextSelectionHandlePainter(
          // We give the painter a point of origin that's at the bottom baseline
          // of the selection cursor position.
          //
          // We give it in the form of an offset from the top left of the
          // SizedBox.
          origin: Offset(_kHandlesPadding, textLineHeight + _kHandlesPadding),
        ),
      ),
    );

    // [buildHandle]'s widget is positioned at the selection cursor's bottom
    // baseline. We transform the handle such that the SizedBox is superimposed
    // on top of the text selection endpoints.
    switch (type) {
      case TextSelectionHandleType.left: // The left handle is upside down on iOS.
        return Transform(
          transform: Matrix4.rotationZ(math.pi)
              ..translate(-_kHandlesPadding, -_kHandlesPadding),
          child: handle,
        );
      case TextSelectionHandleType.right:
        return Transform(
          transform: Matrix4.translationValues(
            -_kHandlesPadding,
            -(textLineHeight + _kHandlesPadding),
            0.0,
          ),
          child: handle,
        );
      case TextSelectionHandleType.collapsed: // iOS doesn't draw anything for collapsed selections.
        return Container();
    }
    assert(type != null);
    return null;
  }
}

/// Text selection controls that follows iOS design conventions.
final TextSelectionControls cupertinoTextSelectionControls = _CupertinoTextSelectionControls();
