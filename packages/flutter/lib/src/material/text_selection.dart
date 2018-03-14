// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';

import 'flat_button.dart';
import 'material.dart';
import 'material_localizations.dart';
import 'theme.dart';

const double _kHandleSize = 22.0;
// Minimal padding from all edges of the selection toolbar to all edges of the
// viewport.
const double _kToolbarScreenPadding = 8.0;

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
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);

    if (handleCut != null)
      items.add(new FlatButton(child: new Text(localizations.cutButtonLabel), onPressed: handleCut));
    if (handleCopy != null)
      items.add(new FlatButton(child: new Text(localizations.copyButtonLabel), onPressed: handleCopy));
    if (handlePaste != null)
      items.add(new FlatButton(child: new Text(localizations.pasteButtonLabel), onPressed: handlePaste,));
    if (handleSelectAll != null)
      items.add(new FlatButton(child: new Text(localizations.selectAllButtonLabel), onPressed: handleSelectAll));

    return new Material(
      elevation: 1.0,
      child: new Container(
        height: 44.0,
        child: new Row(mainAxisSize: MainAxisSize.min, children: items)
      )
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
    return position != oldDelegate.position;
  }
}

/// Draws a single text selection handle. The [type] determines where the handle
/// points (e.g. the [left] handle points up and to the right).
class _TextSelectionHandlePainter extends CustomPainter {
  _TextSelectionHandlePainter({ this.color });

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = new Paint()..color = color;
    final double radius = size.width/2.0;
    canvas.drawCircle(new Offset(radius, radius), radius, paint);
    canvas.drawRect(new Rect.fromLTWH(0.0, 0.0, radius, radius), paint);
  }

  @override
  bool shouldRepaint(_TextSelectionHandlePainter oldPainter) {
    return color != oldPainter.color;
  }
}

class _MaterialTextSelectionControls extends TextSelectionControls {
  @override
  Size handleSize = const Size(_kHandleSize, _kHandleSize);

  /// Builder for material-style copy/paste text selection toolbar.
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

  /// Builder for material-style text selection handles.
  @override
  Widget buildHandle(BuildContext context, TextSelectionHandleType type, double textHeight) {
    final Widget handle = new SizedBox(
      width: _kHandleSize,
      height: _kHandleSize,
      child: new CustomPaint(
        painter: new _TextSelectionHandlePainter(
          color: Theme.of(context).textSelectionHandleColor
        )
      )
    );

    // [handle] is a circle, with a rectangle in the top left quadrant of that
    // circle (an onion pointing to 10:30). We rotate [handle] to point
    // straight up or up-right depending on the handle type.
    switch (type) {
      case TextSelectionHandleType.left: // points up-right
        return new Transform(
          transform: new Matrix4.rotationZ(math.pi / 2.0),
          child: handle
        );
      case TextSelectionHandleType.right: // points up-left
        return handle;
      case TextSelectionHandleType.collapsed: // points up
        return new Transform(
          transform: new Matrix4.rotationZ(math.pi / 4.0),
          child: handle
        );
    }
    assert(type != null);
    return null;
  }
}

/// Text selection controls that follow the Material Design specification.
final TextSelectionControls materialTextSelectionControls = new _MaterialTextSelectionControls();
