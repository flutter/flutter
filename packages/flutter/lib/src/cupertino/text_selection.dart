// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'button.dart';

const double _kHandleSize = 22.0; // pixels
const double _kToolbarScreenPadding = 8.0; // pixels
const double _kToolbarHeight = 36.0;

const Color _selectionToolbarBackgroundBlack = const Color(0xFF2E2E2E);
const Color _selectionToolbarDividerGray = const Color(0xFFB9B9B9);
const Color _selectionHandlesBlue = const Color(0xFF146DDE);

const EdgeInsets _kToolbarButtonPadding = const EdgeInsets.symmetric(vertical: 10.0, horizontal: 21.0);

const TextStyle _kToolbarButtonFontStyle = const TextStyle(
  fontSize: 14.0,
  letterSpacing: -0.11,
  fontWeight: FontWeight.w300,
);

/// Paints a triangle below the toolbar.
class _TextSelectionToolbarNotchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = new Paint()..color = _selectionToolbarBackgroundBlack;
    final Path triangle = new Path();
    triangle.lineTo(9.0, 0.0);
    triangle.lineTo(0.0, 9.0);
    triangle.lineTo(-9.0, 0.0);
    triangle.close();
    paint.style = PaintingStyle.fill;
    canvas.drawPath(triangle, paint);
  }

  @override
  bool shouldRepaint(_TextSelectionToolbarNotchPainter oldPainter) {
    return false;
  }
}

/// Manages a copy/paste text selection toolbar.
class _TextSelectionToolbar extends StatelessWidget {
    const _TextSelectionToolbar(
    this.delegate,
    this._handleCut,
    this._handleCopy,
    this._handlePaste,
    this._handleSelectAll,
    {Key key}) : super(key: key);

  final TextSelectionDelegate delegate;
  TextEditingValue get value => delegate.textEditingValue;

  final VoidCallback _handleCut;
  final VoidCallback _handleCopy;
  final VoidCallback _handlePaste;
  final VoidCallback _handleSelectAll;

  @override
  Widget build(BuildContext context) {
    final List<Widget> items = <Widget>[];

    if (!value.selection.isCollapsed) {
      _addButton(items, 'Cut', _handleCut);
      _addButton(items, 'Copy', _handleCopy);
    }

    // TODO(xster): This should probably be grayed-out if there is nothing to paste.
    _addButton(items, 'Paste', _handlePaste);

    if (value.text.isNotEmpty)
      if (value.selection.isCollapsed)
        _addButton(items, 'Select All', _handleSelectAll);

    // Remove the last divider.
    if (items.last.runtimeType == SizedBox)
      items.removeLast();

    final Widget triangle = new SizedBox(
      width: 18.0,
      height: 9.0,
      child: new CustomPaint(
        painter: new _TextSelectionToolbarNotchPainter(),
      )
    );

    return new Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        new ClipRRect(
          borderRadius: new BorderRadius.circular(7.5),
          child: new Row(mainAxisSize: MainAxisSize.min, children: items),
        ),
        // TODO(xster): position the triangle based on the layout delegate.
        // And avoid letting the triangle line up with any dividers.
        triangle,
      ],
    );
  }

  /// Adds a themed button and a divider to the list.
  void _addButton(List<Widget> list, String text, VoidCallback onPressed) {
    list.add(new CupertinoButton(
      child: new Text(text, style: _kToolbarButtonFontStyle),
      color: _selectionToolbarBackgroundBlack,
      minSize: _kToolbarHeight,
      padding: _kToolbarButtonPadding,
      borderRadius: null,
      onPressed: onPressed,
    ));
    // Insert a 1 pixel divider.
    list.add(const DecoratedBox(
      decoration: const BoxDecoration(
        color: _selectionToolbarDividerGray,
      ),
      child: const SizedBox(
        width: 0.5,
      ),
    ));
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
    return position != oldDelegate.position;
  }
}

/// Draws a single text selection handle. The [type] determines where the handle
/// points (e.g. the [left] handle points up and to the right).
class _TextSelectionHandlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = new Paint()..color = _selectionHandlesBlue;
    final double radius = size.width/2.0;
    canvas.drawCircle(new Offset(radius, radius), radius, paint);
    canvas.drawRect(new Rect.fromLTWH(0.0, 0.0, radius, radius), paint);
  }

  @override
  bool shouldRepaint(_TextSelectionHandlePainter oldPainter) {
    return false;
  }
}

class _CupertinoTextSelectionControls extends TextSelectionControls {
  @override
  Size handleSize = const Size(_kHandleSize, _kHandleSize);

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
          delegate,
          () => handleCut(delegate),
          () => handleCopy(delegate),
          () => handlePaste(delegate),
          () => handleSelectAll(delegate),
        ),
      )
    );
  }

  /// Builder for material-style text selection handles.
  @override
  Widget buildHandle(BuildContext context, TextSelectionHandleType type) {
    final Widget handle = new SizedBox(
      width: _kHandleSize,
      height: _kHandleSize,
      child: new CustomPaint(
        painter: new _TextSelectionHandlePainter(),
      )
    );

    // [handle] is a circle, with a rectangle in the top left quadrant of that
    // circle (an onion pointing to 10:30). We rotate [handle] to point
    // straight up or up-right depending on the handle type.
    switch (type) {
      case TextSelectionHandleType.left:  // points up-right
        return new Transform(
          transform: new Matrix4.rotationZ(math.PI / 2.0),
          child: handle
        );
      case TextSelectionHandleType.right:  // points up-left
        return handle;
      case TextSelectionHandleType.collapsed:  // points up
        return new Transform(
          transform: new Matrix4.rotationZ(math.PI / 4.0),
          child: handle
        );
    }
    assert(type != null);
    return null;
  }
}

/// Text selection controls that follow the Material Design specification.
final TextSelectionControls cupertinoTextSelectionControls = new _CupertinoTextSelectionControls();
