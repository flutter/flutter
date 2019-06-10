// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/src/material/debug.dart';
import 'package:flutter/src/material/theme_data.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'button.dart';
import 'theme.dart';

/// An individual toggle button, otherwise known as a segmented button.
///
/// This button is used by [ToggleButtons] to implement a set of segmented controls.
class _ToggleButton extends StatelessWidget {
  // TODO(WIP): Figure out which properties should be required and if
  // additional properties are required.

  /// Creates a toggle button based on [RawMaterialButton].
  ///
  /// This class adds some logic to determine between enabled, active, and
  /// disabled states to determine the appropriate colors to use.
  ///
  /// It takes in a [shape] property to modify the borders of the button,
  /// which is used by [ToggleButtons] to customize borders based on the
  /// order in which this button appears in the list.
  ///
  const _ToggleButton({
    Key key,
    this.selected = false,
    this.color,
    this.activeColor,
    this.disabledColor,
    this.fillColor,
    this.focusColor,
    this.highlightColor,
    this.hoverColor,
    this.splashColor,
    this.onPressed,
    this.shape,
    this.leadingBorderSide,
    this.horizontalBorderSide,
    this.trailingBorderSide,
    this.borderRadius = const BorderRadius.all(Radius.circular(0.0)),
    this.isFirstButton,
    this.child,
  }) : super(key: key);

  /// Determines if the button is displayed as active/selected or enabled.
  final bool selected;

  /// The color for [Text] and [Icon] widgets.
  ///
  /// If [selected] is set to false and [onPressed] is not null, this color will be used.
  final Color color;

  /// The color for [Text] and [Icon] widgets.
  ///
  /// If [selected] is set to true and [onPressed] is not null, this color will be used.
  final Color activeColor;

  /// The color for [Text] and [Icon] widgets if the button is disabled.
  ///
  /// If [onPressed] is null, this color will be used.
  final Color disabledColor;

  /// The color of the button's [Material].
  final Color fillColor;

  /// The color for the button's [Material] when it has the input focus.
  final Color focusColor;

  /// The color for the button's [Material] when a pointer is hovering over it.
  final Color hoverColor;

  /// The highlight color for the button's [InkWell].
  final Color highlightColor;

  /// The splash color for the button's [InkWell].
  final Color splashColor;

  /// Called when the button is tapped or otherwise activated.
  ///
  /// If this is set to null, the button will be disabled, see [enabled].
  final VoidCallback onPressed;

  /// The shape of the button's [Material].
  ///
  /// The button's highlight and splash are clipped to this shape. If the
  /// button has an elevation, then its drop shadow is defined by this shape.
  final ShapeBorder shape;

  final BorderSide leadingBorderSide;

  final BorderSide horizontalBorderSide;

  final BorderSide trailingBorderSide;

  final BorderRadius borderRadius;

  final bool isFirstButton;

  /// The button's label, which is usually an [Icon] or a [Text] widget.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    Color currentColor;
    final ThemeData themeData = Theme.of(context);

    if (onPressed != null && selected) {
      final Color primary = themeData.colorScheme.primary;
      currentColor = activeColor ?? primary;
    } else if (onPressed != null && !selected) {
      currentColor = color ?? themeData.colorScheme.onSurface;
    } else {
      currentColor = disabledColor ?? themeData.disabledColor;
    }

    final Widget result = IconTheme.merge(
      data: IconThemeData(
        color: currentColor,
      ),
      child: RawMaterialButton(
        textStyle: TextStyle(
          color: currentColor,
        ),
        elevation: 0.0,
        highlightElevation: 0.0,
        fillColor: selected ? fillColor : null,
        focusColor: selected ? focusColor : null,
        highlightColor: highlightColor,
        hoverColor: hoverColor,
        splashColor: splashColor,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        onPressed: onPressed,
        child: child,
      ),
    );

    return _SelectToggleButton(
      key: key,
      leadingBorderSide: leadingBorderSide,
      horizontalBorderSide: horizontalBorderSide,
      trailingBorderSide: trailingBorderSide,
      borderRadius: borderRadius,
      isFirstButton: isFirstButton,
      child: result,
    );
  }

  // TODO(WIP): include debugFillProperties method
}

class _SelectToggleButton extends SingleChildRenderObjectWidget {
  const _SelectToggleButton({
    Key key,
    Widget child,
    this.color,
    this.leadingBorderSide,
    this.horizontalBorderSide,
    this.trailingBorderSide,
    this.borderRadius,
    this.isFirstButton,
  }) : super(
    key: key,
    child: child,
  );

  final Color color;

  final BorderSide leadingBorderSide;

  final BorderSide horizontalBorderSide;

  final BorderSide trailingBorderSide;

  final BorderRadius borderRadius;

  final bool isFirstButton;

  @override
  _SelectToggleButtonRenderObject createRenderObject(BuildContext context) => _SelectToggleButtonRenderObject(
      leadingBorderSide: leadingBorderSide,
      horizontalBorderSide: horizontalBorderSide,
      trailingBorderSide: trailingBorderSide,
      borderRadius: borderRadius,
      isFirstButton: isFirstButton,
  );

  @override
  void updateRenderObject(BuildContext context, _SelectToggleButtonRenderObject renderObject) {
    renderObject
      ..leadingBorderSide = leadingBorderSide
      ..horizontalBorderSide = horizontalBorderSide
      ..trailingBorderSide = trailingBorderSide
      ..borderRadius = borderRadius
      ..isFirstButton = isFirstButton;
  }
}

class _SelectToggleButtonRenderObject extends RenderProxyBox {
  _SelectToggleButtonRenderObject({
    this.leadingBorderSide,
    this.horizontalBorderSide,
    this.trailingBorderSide,
    this.borderRadius,
    this.isFirstButton,
  });

  BorderSide leadingBorderSide;

  BorderSide horizontalBorderSide;

  BorderSide trailingBorderSide;

  BorderRadius borderRadius;

  bool isFirstButton;

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);
    final Offset bottomRight = size.bottomRight(offset);
    final Rect inner = Rect.fromLTRB(offset.dx, offset.dy, bottomRight.dx, bottomRight.dy);
    final Rect center = inner.inflate(horizontalBorderSide.width / 2.0);

    final double bottom = center.bottom;
    final double left = center.left;
    final double top = center.top;
    final double right = center.right;

    final Radius tlRadius = borderRadius.topLeft;
    final Radius trRadius = borderRadius.topRight;
    final Radius blRadius = borderRadius.bottomLeft;
    final Radius brRadius = borderRadius.bottomRight;

    final double sweepAngle = math.pi / 2.0;

    final Paint leadingPaint = leadingBorderSide.toPaint();
    final Rect tlCorner = Rect.fromLTWH(
      left,
      top,
      tlRadius.x * 2,
      tlRadius.y * 2,
    );
    final Rect blCorner = Rect.fromLTWH(
      left,
      bottom - (blRadius.y * 2),
      blRadius.x * 2,
      blRadius.y * 2,
    );

    if (isFirstButton) {
      final Path leftPath = Path()
        ..addArc(blCorner, math.pi / 2.0, sweepAngle)
        ..moveTo(left, bottom - blRadius.y)
        ..lineTo(left, top + tlRadius.y)
        ..addArc(tlCorner, math.pi, sweepAngle);
      context.canvas.drawPath(leftPath, leadingPaint);

      final Paint horizontalPaint = horizontalBorderSide.toPaint();
      final Path horizontalPaths = Path()
        ..moveTo(left + tlRadius.x, top)
        ..lineTo(right, top)
        ..moveTo(left + blRadius.x, bottom)
        ..lineTo(right, bottom);
      context.canvas.drawPath(horizontalPaths, horizontalPaint);
    } else {
      final Path leftPath = Path()
        ..moveTo(left, bottom + leadingBorderSide.width / 2)
        ..lineTo(left, top - leadingBorderSide.width / 2);
      context.canvas.drawPath(leftPath, leadingPaint);

      final Paint horizontalPaint = horizontalBorderSide.toPaint();
      final Path horizontalPaths = Path()
        ..moveTo(left + horizontalBorderSide.width / 2.0, top)
        ..lineTo(right - trRadius.x, top)
        ..moveTo(left + horizontalBorderSide.width / 2.0 + tlRadius.x, bottom)
        ..lineTo(right - trRadius.x, bottom);
      context.canvas.drawPath(horizontalPaths, horizontalPaint);
    }

    // only the last toggle button requires a paint on the trailing side
    if (trailingBorderSide != null) {
      final Paint trailingPaint = trailingBorderSide.toPaint();
      final Rect trCorner = Rect.fromLTWH(
        right - (trRadius.x * 2),
        top,
        trRadius.x * 2,
        trRadius.y * 2,
      );
      final Rect brCorner = Rect.fromLTWH(
        right - (trRadius.x * 2),
        bottom - (brRadius.y * 2),
        brRadius.x * 2,
        brRadius.y * 2,
      );

      final Path rightPath = Path()
        ..addArc(trCorner, math.pi * 3.0 / 2.0, sweepAngle)
        ..moveTo(right, top + trRadius.y)
        ..lineTo(right, bottom - brRadius.y)
        ..addArc(brCorner, 0, sweepAngle);
      context.canvas.drawPath(rightPath, trailingPaint);
    }
  }
}

class ToggleButtons extends StatelessWidget {
  const ToggleButtons({
    this.children,
    this.isSelected,
    this.onPressed,
    this.color,
    this.activeColor,
    this.disabledColor,
    this.borderColor,
    this.activeBorderColor,
    this.disabledBorderColor,
    this.borderRadius = const BorderRadius.all(Radius.circular(0.0)),
    this.borderWidth = 1.0,
  }); // borderRadius cannot be null

  final List<Widget> children;

  final List<bool> isSelected;

  final Function onPressed;

  /// The color for [Text] and [Icon] widgets.
  ///
  /// If [selected] is set to false and [onPressed] is not null, this color will be used.
  final Color color;

  /// The color for [Text] and [Icon] widgets.
  ///
  /// If [selected] is set to true and [onPressed] is not null, this color will be used.
  final Color activeColor;

  /// The color for [Text] and [Icon] widgets if the button is disabled.
  ///
  /// If [onPressed] is null, this color will be used.
  final Color disabledColor;

  final Color borderColor;

  final Color activeBorderColor;

  final Color disabledBorderColor;

  final double borderWidth;

  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(children.length, (int index) {
        BorderSide horizontalBorderSide;
        BorderSide leadingBorderSide;
        BorderSide trailingBorderSide;

        if (onPressed != null && isSelected[index]) {
          horizontalBorderSide = BorderSide(
            color: borderColor ?? themeData.colorScheme.primary,
            width: borderWidth,
          );
        } else if (onPressed != null && !isSelected[index]) {
          horizontalBorderSide = BorderSide(
            color: activeBorderColor ?? themeData.colorScheme.onSurface,
            width: borderWidth,
          );
        } else {
          horizontalBorderSide = BorderSide(
            color: disabledBorderColor ?? themeData.disabledColor,
            width: borderWidth,
          );
        }

        if (onPressed != null && (isSelected[index] || (index != 0 && isSelected[index - 1]))) {
          leadingBorderSide = BorderSide(
            color: borderColor ?? themeData.colorScheme.primary,
            width: borderWidth,
          );
        } else if (onPressed != null && !isSelected[index]) {
          leadingBorderSide = BorderSide(
            color: activeBorderColor ?? themeData.colorScheme.onSurface,
            width: borderWidth,
          );
        } else {
          leadingBorderSide = BorderSide(
            color: disabledBorderColor ?? themeData.disabledColor,
            width: borderWidth,
          );
        }

        if (index != children.length - 1) {
          trailingBorderSide = null;
        } else {
          if (onPressed != null && (isSelected[index])) {
            trailingBorderSide = BorderSide(
            color: borderColor ?? themeData.colorScheme.primary,
            width: borderWidth,
          );
          } else if (onPressed != null && !isSelected[index]) {
            trailingBorderSide = BorderSide(
            color: activeBorderColor ?? themeData.colorScheme.onSurface,
            width: borderWidth,
          );
          } else {
            trailingBorderSide = BorderSide(
              color: disabledBorderColor ?? themeData.disabledColor,
              width: borderWidth,
            );
          }
        }

        // consider rtl languages
        BorderRadius edgeBorderRadius;
        if (index == 0) {
          edgeBorderRadius = BorderRadius.only(
            topLeft: borderRadius.topLeft,
            bottomLeft: borderRadius.bottomLeft,
          );
        } else if (index == children.length - 1) {
          edgeBorderRadius = BorderRadius.only(
            topRight: borderRadius.topRight,
            bottomRight: borderRadius.bottomRight,
          );
        }

        return _ToggleButton(
          onPressed: onPressed != null
            ? () { onPressed(index); }
            : null,
          selected: isSelected[index],
          leadingBorderSide: leadingBorderSide,
          horizontalBorderSide: horizontalBorderSide,
          trailingBorderSide: trailingBorderSide,
          borderRadius: edgeBorderRadius ?? BorderRadius.zero,
          isFirstButton: index == 0,
          child: children[index],
        );
      }),
    );
  }

  // TODO(WIP): include debugFillProperties method
}