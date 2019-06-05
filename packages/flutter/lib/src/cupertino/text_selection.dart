// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';

import 'button.dart';
import 'colors.dart';
import 'localizations.dart';


const Color _kHandlesColor = Color(0xFF136FE0);
const double _kSelectionHandleOverlap = 1.5;
// Read off from the output on iOS 12. This color does not vary with the
// application's theme color.
const double _kSelectionHandleRadius = 5.5;

// Minimal padding from all edges of the selection toolbar to all edges of the
// viewport.
const double _kToolbarScreenPadding = 8.0;

// Vertical distance between the tip of the arrow and the line the arrow is pointing
// to. The value used here is eyeballed.
const double _kToolbarContentDistance = 8.0;
// Values derived from https://developer.apple.com/design/resources/.
// 92% Opacity ~= 0xEB

// The height of the toolbar, including the arrow.
const double _kToolbarHeight = 43.0;
const Color _kToolbarBackgroundColor = Color(0xEB202020);
const Color _kToolbarDividerColor = Color(0xFF808080);
const Size _kToolbarArrowSize = Size(14.0, 7.0);
const EdgeInsets _kToolbarButtonPadding = EdgeInsets.symmetric(vertical: 10.0, horizontal: 18.0);
const Radius _kToolbarBorderRadius = Radius.circular(8);

const TextStyle _kToolbarButtonFontStyle = TextStyle(
  inherit: false,
  fontSize: 14.0,
  letterSpacing: -0.15,
  fontWeight: FontWeight.w400,
  color: CupertinoColors.white,
);

class _ToolbarClipper extends CustomClipper<Path> {
  const _ToolbarClipper({
    this.isArrowPointingDown,
    this.arrowXOffset,
  });

  final bool isArrowPointingDown;
  final double arrowXOffset;

  @override
  Path getClip(Size size) {
    final Path rrect = Path()
    ..addRRect(
      RRect.fromRectAndRadius(
        Offset(
          0,
          isArrowPointingDown ? 0 : _kToolbarArrowSize.height,
        )
        & Size(size.width, size.height - _kToolbarArrowSize.height),
        _kToolbarBorderRadius
      )
    );

    final double arrowBottomY = isArrowPointingDown
      ? size.height - _kToolbarArrowSize.height
      : _kToolbarArrowSize.height;

      final double arrowPointY = isArrowPointingDown
      ? _kToolbarArrowSize.height
      : 0;

    final Path arrow = Path()
      ..moveTo(arrowXOffset, arrowPointY)
      ..lineTo(arrowXOffset - _kToolbarArrowSize.width / 2, arrowBottomY)
      ..lineTo(arrowXOffset + _kToolbarArrowSize.width / 2, arrowBottomY)
      ..close();

    return Path.combine(PathOperation.union, rrect, arrow);
  }

  @override
  bool shouldReclip(_ToolbarClipper oldClipper) => false;
}

/// Manages a copy/paste text selection toolbar.
class _TextSelectionToolbar extends StatelessWidget {
  const _TextSelectionToolbar({
    Key key,
    this.handleCut,
    this.handleCopy,
    this.handlePaste,
    this.handleSelectAll,
    this.isArrowPointingDown,
  }) : super(key: key);

  final VoidCallback handleCut;
  final VoidCallback handleCopy;
  final VoidCallback handlePaste;
  final VoidCallback handleSelectAll;
  final bool isArrowPointingDown;

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

    return Row(mainAxisSize: MainAxisSize.min, children: items);
    /*
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
        child:
      ),
    );*/
  }

  /// Builds a themed [CupertinoButton] for the toolbar.
  CupertinoButton _buildToolbarButton(String text, VoidCallback onPressed) {
    final EdgeInsets arrowPadding = isArrowPointingDown
      ? EdgeInsets.only(bottom: _kToolbarArrowSize.height)
      : EdgeInsets.only(top: _kToolbarArrowSize.height);

    return CupertinoButton(
      child: Text(text, style: _kToolbarButtonFontStyle),
      color: _kToolbarBackgroundColor,
      minSize: _kToolbarHeight + _kToolbarArrowSize.height,
      padding: _kToolbarButtonPadding.add(arrowPadding),
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

    final double x = globalPosition.dx - childSize.width / 2.0;
    final double y = globalPosition.dy - childSize.height;

    return Offset(
      x.clamp(_kToolbarScreenPadding, screenSize.width - childSize.width - _kToolbarScreenPadding),
      y.clamp(_kToolbarScreenPadding, screenSize.height - childSize.height - _kToolbarScreenPadding),
    );
  }

  @override
  bool shouldRelayout(_TextSelectionToolbarLayout oldDelegate) {
    return screenSize != oldDelegate.screenSize
        || globalEditableRegion != oldDelegate.globalEditableRegion
        || position != oldDelegate.position;
  }
}

/// Draws a single text selection handle with a bar and a ball.
class _TextSelectionHandlePainter extends CustomPainter {
  const _TextSelectionHandlePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
        ..color = _kHandlesColor
        ..strokeWidth = 2.0;
    canvas.drawCircle(
      const Offset(_kSelectionHandleRadius, _kSelectionHandleRadius),
      _kSelectionHandleRadius,
      paint,
    );
    // Draw line so it slightly overlaps the circle.
    canvas.drawLine(
      const Offset(
        _kSelectionHandleRadius,
        2 * _kSelectionHandleRadius - _kSelectionHandleOverlap,
      ),
      Offset(
        _kSelectionHandleRadius,
        size.height,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_TextSelectionHandlePainter oldPainter) => false;
}

class _CupertinoTextSelectionControls extends TextSelectionControls {
  /// Returns the size of the Cupertino handle.
  @override
  Size getHandleSize(double textLineHeight) {
    return Size(
      _kSelectionHandleRadius * 2,
      textLineHeight + _kSelectionHandleRadius * 2 - _kSelectionHandleOverlap,
    );
  }

  /// Builder for iOS-style copy/paste text selection toolbar.
  @override
  Widget buildToolbar(
    BuildContext context,
    Rect globalEditableRegion,
    double textLineHeight,
    Offset position,
    List<TextSelectionPoint> endpoints,
    TextSelectionDelegate delegate,
  ) {
    assert(debugCheckHasMediaQuery(context));

    // The toolbar should appear below the TextField
    // when there is not enough space above the TextField to show it.
    final bool isArrowPointingDown =
      MediaQuery.of(context).padding.top
      + _kToolbarScreenPadding
      + _kToolbarHeight
      + _kToolbarContentDistance <= globalEditableRegion.top;

    // We cannot trust postion.dy.
    final double midX = position.dx;

    final double midY = isArrowPointingDown
      ? endpoints.first.point.dy - textLineHeight
      : endpoints.last.point.dy;

    final Offset preciseMidpoint = Offset(midX, midY);

    return ConstrainedBox(
      constraints: BoxConstraints.tight(globalEditableRegion.size),
      child: CustomSingleChildLayout(
        delegate: _TextSelectionToolbarLayout(
          MediaQuery.of(context).size,
          globalEditableRegion,
          Offset(position.dx, position.dy + MediaQuery.of(context).padding.top),
        ),
        child: _TextSelectionToolbar(
          handleCut: canCut(delegate) ? () => handleCut(delegate) : null,
          handleCopy: canCopy(delegate) ? () => handleCopy(delegate) : null,
          handlePaste: canPaste(delegate) ? () => handlePaste(delegate) : null,
          handleSelectAll: canSelectAll(delegate) ? () => handleSelectAll(delegate) : null,
          isArrowPointingDown: isArrowPointingDown,
        ),
      ),
    );
  }

  /// Builder for iOS text selection edges.
  @override
  Widget buildHandle(BuildContext context, TextSelectionHandleType type, double textLineHeight) {
    // We want a size that's a vertical line the height of the text plus a 18.0
    // padding in every direction that will constitute the selection drag area.
    final Size desiredSize = getHandleSize(textLineHeight);

    final Widget handle = SizedBox.fromSize(
      size: desiredSize,
      child: const CustomPaint(
        painter: _TextSelectionHandlePainter(),
      ),
    );

    // [buildHandle]'s widget is positioned at the selection cursor's bottom
    // baseline. We transform the handle such that the SizedBox is superimposed
    // on top of the text selection endpoints.
    switch (type) {
      case TextSelectionHandleType.left:
        return handle;
      case TextSelectionHandleType.right:
        // Right handle is a vertical mirror of the left.
        return Transform(
          transform: Matrix4.identity()
            ..translate(desiredSize.width / 2, desiredSize.height / 2)
            ..rotateZ(math.pi)
            ..translate(-desiredSize.width / 2, -desiredSize.height / 2),
          child: handle,
        );
      // iOS doesn't draw anything for collapsed selections.
      case TextSelectionHandleType.collapsed:
        return Container();
    }
    assert(type != null);
    return null;
  }

  /// Gets anchor for cupertino-style text selection handles.
  ///
  /// See [TextSelectionControls.getHandleAnchor].
  @override
  Offset getHandleAnchor(TextSelectionHandleType type, double textLineHeight) {
    final Size handleSize = getHandleSize(textLineHeight);
    switch (type) {
      // The circle is at the top for the left handle, and the anchor point is
      // all the way at the bottom of the line.
      case TextSelectionHandleType.left:
        return Offset(
          handleSize.width / 2,
          handleSize.height,
        );
      // The right handle is vertically flipped, and the anchor point is near
      // the top of the circle to give slight overlap.
      case TextSelectionHandleType.right:
        return Offset(
          handleSize.width / 2,
          handleSize.height - 2 * _kSelectionHandleRadius + _kSelectionHandleOverlap,
        );
      // A collapsed handle anchors itself so that it's centered.
      default:
        return Offset(
          handleSize.width / 2,
          textLineHeight + (handleSize.height - textLineHeight) / 2,
        );
    }
  }
}

/// Text selection controls that follows iOS design conventions.
final TextSelectionControls cupertinoTextSelectionControls = _CupertinoTextSelectionControls();
