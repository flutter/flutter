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

class ToggleButtons extends StatelessWidget {
  const ToggleButtons({
    @required this.children,
    @required this.isSelected,
    this.onPressed,
    this.color,
    this.activeColor,
    this.disabledColor,
    this.borderColor,
    this.activeBorderColor,
    this.disabledBorderColor,
    this.borderRadius = const BorderRadius.all(Radius.circular(0.0)),
    this.borderWidth = 1.0,
  }) :
    assert(children != null),
    assert(isSelected != null),
    assert(borderRadius != null);

  /// The corresponding widget values in the toggle buttons.
  ///
  /// The selection state corresponds to its state in the [isSelected] list.
  final List<Widget> children;

  /// The corresponding selection state of each toggle button.
  ///
  /// The boolean values in the list map directly to [children] by its index.
  final List<bool> isSelected;

  /// The callback that is called when a button is tapped.
  ///
  /// When set to null, all toggle buttons will be disabled.
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

  /// The border color to display when the toggle button is selected.
  final Color borderColor;

  /// The border color to display when the toggle button is active/selectable.
  final Color activeBorderColor;

  /// The border color to display when the toggle button is disabled.
  final Color disabledBorderColor;

  /// The width of the border surrounding teach toggle button.
  ///
  /// This applies to both the greater surrounding border, as well as the
  /// borders dividing each toggle button.
  ///
  /// To omit the border entirely, set this value to null.
  ///
  /// To render a hairline border (one physical pixel), set borderWidth to 0.0.
  /// See [BorderSide.width] for more details on hairline borders.
  final double borderWidth;

  /// The radii of the border's corners.
  ///
  /// By default, the border's corners are not rounded.
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    final TextDirection textDirection = Directionality.of(context);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: List<Widget>.generate(children.length, (int index) {
          BorderRadius edgeBorderRadius;
          BorderRadius clipBorderRadius;
          if (
            index == 0 && textDirection == TextDirection.ltr ||
            index == children.length - 1 && textDirection == TextDirection.rtl
          ) {
            edgeBorderRadius = BorderRadius.only(
              topLeft: borderRadius.topLeft,
              bottomLeft: borderRadius.bottomLeft,
            );
            clipBorderRadius = BorderRadius.only(
              topLeft: borderRadius.topLeft - Radius.circular(borderWidth ?? 0.0 / 2.0),
              bottomLeft: borderRadius.bottomLeft - Radius.circular(borderWidth ?? 0.0 / 2.0),
            );
          } else if (
            index == children.length - 1 && textDirection == TextDirection.ltr ||
            index == 0 && textDirection == TextDirection.rtl
          ) {
            edgeBorderRadius = BorderRadius.only(
              topRight: borderRadius.topRight,
              bottomRight: borderRadius.bottomRight,
            );
            clipBorderRadius = BorderRadius.only(
              topRight: borderRadius.topRight - Radius.circular(borderWidth ?? 0.0 / 2.0),
              bottomRight: borderRadius.bottomRight - Radius.circular(borderWidth ?? 0.0 / 2.0),
            );
          }

          if (borderWidth == null) {
            return _ToggleButton(
              onPressed: onPressed != null
                ? () { onPressed(index); }
                : null,
              selected: isSelected[index],
              leadingBorderSide: BorderSide.none,
              horizontalBorderSide: BorderSide.none,
              trailingBorderSide: BorderSide.none,
              borderRadius: edgeBorderRadius ?? BorderRadius.zero,
              clipRadius: clipBorderRadius ?? BorderRadius.zero,
              isFirstButton: index == 0,
              isLastButton: index == children.length - 1,
              child: children[index],
            );
          }

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

          return _ToggleButton(
            onPressed: onPressed != null
              ? () { onPressed(index); }
              : null,
            selected: isSelected[index],
            leadingBorderSide: leadingBorderSide,
            horizontalBorderSide: horizontalBorderSide,
            trailingBorderSide: trailingBorderSide,
            borderRadius: edgeBorderRadius ?? BorderRadius.zero,
            clipRadius: clipBorderRadius ?? BorderRadius.zero,
            isFirstButton: index == 0,
            isLastButton: index == children.length - 1,
            child: children[index],
          );
        }),
      ),
    );
  }

  // TODO(WIP): include debugFillProperties method
}

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
    this.borderRadius,
    this.clipRadius,
    this.isFirstButton,
    this.isLastButton,
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

  final BorderRadius clipRadius;

  final bool isFirstButton;

  final bool isLastButton;

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
      child: ClipRRect(
        borderRadius: clipRadius,
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
      ),
    );

    return _SelectToggleButton(
      key: key,
      leadingBorderSide: leadingBorderSide,
      horizontalBorderSide: horizontalBorderSide,
      trailingBorderSide: trailingBorderSide,
      borderRadius: borderRadius,
      isFirstButton: isFirstButton,
      isLastButton: isLastButton,
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
    this.isLastButton,
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

  final bool isLastButton;

  @override
  _SelectToggleButtonRenderObject createRenderObject(BuildContext context) => _SelectToggleButtonRenderObject(
    leadingBorderSide: leadingBorderSide,
    horizontalBorderSide: horizontalBorderSide,
    trailingBorderSide: trailingBorderSide,
    borderRadius: borderRadius,
    isFirstButton: isFirstButton,
    isLastButton: isLastButton,
    textDirection: Directionality.of(context),
  );

  @override
  void updateRenderObject(BuildContext context, _SelectToggleButtonRenderObject renderObject) {
    renderObject
      ..leadingBorderSide = leadingBorderSide
      ..horizontalBorderSide = horizontalBorderSide
      ..trailingBorderSide = trailingBorderSide
      ..borderRadius = borderRadius
      ..isFirstButton = isFirstButton
      ..isLastButton = isLastButton
      ..textDirection = Directionality.of(context);
  }
}

class _SelectToggleButtonRenderObject extends RenderShiftedBox {
  _SelectToggleButtonRenderObject({
    this.leadingBorderSide,
    this.horizontalBorderSide,
    this.trailingBorderSide,
    this.borderRadius,
    this.isFirstButton,
    this.isLastButton,
    this.textDirection,
    RenderBox child,
  }) : super(child);

  BorderSide leadingBorderSide;

  BorderSide horizontalBorderSide;

  BorderSide trailingBorderSide;

  BorderRadius borderRadius;

  bool isFirstButton;

  bool isLastButton;

  TextDirection textDirection;

  @override
  void performLayout() {
    if (child == null) {
      size = constraints.constrain(Size(
        leadingBorderSide.width + trailingBorderSide.width,
        horizontalBorderSide.width * 2.0,
      ));
      return;
    }

    final double trailingBorderOffset = isLastButton ? trailingBorderSide.width : 0.0;
    double leftConstraint;
    double rightConstraint;

    switch (textDirection) {
      case TextDirection.ltr:
        rightConstraint = trailingBorderOffset;
        leftConstraint = leadingBorderSide.width;

        final BoxConstraints innerConstraints = constraints.deflate(
          EdgeInsets.only(
            left: leftConstraint,
            top: horizontalBorderSide.width,
            right: rightConstraint,
            bottom: horizontalBorderSide.width,
          ),
        );

        child.layout(innerConstraints, parentUsesSize: true);
        final BoxParentData childParentData = child.parentData;
        childParentData.offset = Offset(leadingBorderSide.width, leadingBorderSide.width);

        size = constraints.constrain(Size(
          leftConstraint + child.size.width + rightConstraint,
          horizontalBorderSide.width * 2.0 + child.size.height,
        ));
        break;
      case TextDirection.rtl:
        rightConstraint = leadingBorderSide.width;
        leftConstraint = trailingBorderOffset;

        final BoxConstraints innerConstraints = constraints.deflate(
          EdgeInsets.only(
            left: leftConstraint,
            top: horizontalBorderSide.width,
            right: rightConstraint,
            bottom: horizontalBorderSide.width,
          ),
        );

        child.layout(innerConstraints, parentUsesSize: true);
        final BoxParentData childParentData = child.parentData;

        if (isLastButton) {
          childParentData.offset = Offset(trailingBorderOffset, trailingBorderOffset);
        } else {
          childParentData.offset = Offset(0, horizontalBorderSide.width);
        }

        size = constraints.constrain(Size(
          leftConstraint + child.size.width + rightConstraint,
          horizontalBorderSide.width * 2.0 + child.size.height,
        ));
        break;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);
    final Offset bottomRight = size.bottomRight(offset);
    final Rect outer = Rect.fromLTRB(offset.dx, offset.dy, bottomRight.dx, bottomRight.dy);
    final Rect center = outer.deflate(horizontalBorderSide.width / 2.0);
    final double sweepAngle = math.pi / 2.0;

    final RRect rrect = RRect.fromRectAndCorners(
      center,
      topLeft: borderRadius.topLeft,
      topRight: borderRadius.topRight,
      bottomLeft: borderRadius.bottomLeft,
      bottomRight: borderRadius.bottomRight,
    ).scaleRadii();

    final Rect tlCorner = Rect.fromLTWH(
      rrect.left,
      rrect.top,
      rrect.tlRadiusX * 2.0,
      rrect.tlRadiusY * 2.0,
    );
    final Rect blCorner = Rect.fromLTWH(
      rrect.left,
      rrect.bottom - (rrect.blRadiusY * 2.0),
      rrect.blRadiusX * 2.0,
      rrect.blRadiusY * 2.0,
    );
    final Rect trCorner = Rect.fromLTWH(
      rrect.right - (rrect.trRadiusX * 2),
      rrect.top,
      rrect.trRadiusX * 2,
      rrect.trRadiusY * 2,
    );
    final Rect brCorner = Rect.fromLTWH(
      rrect.right - (rrect.brRadiusX * 2),
      rrect.bottom - (rrect.brRadiusY * 2),
      rrect.brRadiusX * 2,
      rrect.brRadiusY * 2,
    );

    final Paint leadingPaint = leadingBorderSide.toPaint();
    switch (textDirection) {
      case TextDirection.ltr:
        if (isFirstButton) {
          final Path leadingPath = Path()
            ..moveTo(outer.right, rrect.bottom)
            ..lineTo(rrect.left + rrect.blRadiusX, rrect.bottom)
            ..addArc(blCorner, math.pi / 2.0, sweepAngle)
            ..lineTo(rrect.left, rrect.top + rrect.tlRadiusY)
            ..addArc(tlCorner, math.pi, sweepAngle)
            ..lineTo(outer.right, rrect.top);
          context.canvas.drawPath(leadingPath, leadingPaint);
        } else if (isLastButton) {
          final Path leftPath = Path()
            ..moveTo(rrect.left, rrect.bottom + leadingBorderSide.width / 2)
            ..lineTo(rrect.left, rrect.top - leadingBorderSide.width / 2);
          context.canvas.drawPath(leftPath, leadingPaint);

          final Paint endingPaint = trailingBorderSide.toPaint();
          final Path endingPath = Path()
            ..moveTo(rrect.left + horizontalBorderSide.width / 2.0, rrect.top)
            ..lineTo(rrect.right - rrect.trRadiusX, rrect.top)
            ..addArc(trCorner, math.pi * 3.0 / 2.0, sweepAngle)
            ..lineTo(rrect.right, rrect.bottom - rrect.brRadiusY)
            ..addArc(brCorner, 0, sweepAngle)
            ..lineTo(rrect.left + horizontalBorderSide.width / 2.0, rrect.bottom);
          context.canvas.drawPath(endingPath, endingPaint);
        } else {
          final Path leadingPath = Path()
            ..moveTo(rrect.left, rrect.bottom + leadingBorderSide.width / 2)
            ..lineTo(rrect.left, rrect.top - leadingBorderSide.width / 2);
          context.canvas.drawPath(leadingPath, leadingPaint);

          final Paint horizontalPaint = horizontalBorderSide.toPaint();
          final Path horizontalPaths = Path()
            ..moveTo(rrect.left + horizontalBorderSide.width / 2.0, rrect.top)
            ..lineTo(outer.right - rrect.trRadiusX, rrect.top)
            ..moveTo(rrect.left + horizontalBorderSide.width / 2.0 + rrect.tlRadiusX, rrect.bottom)
            ..lineTo(outer.right - rrect.trRadiusX, rrect.bottom);
          context.canvas.drawPath(horizontalPaths, horizontalPaint);
        }
        break;
      case TextDirection.rtl:
        if (isFirstButton) {
          final Path leadingPath = Path()
            ..moveTo(outer.left, rrect.bottom)
            ..lineTo(rrect.right - rrect.brRadiusX, rrect.bottom)
            ..addArc(brCorner, math.pi / 2.0, -sweepAngle)
            ..lineTo(rrect.right, rrect.top + rrect.trRadiusY)
            ..addArc(trCorner, 0, -sweepAngle)
            ..lineTo(outer.left, rrect.top);
          context.canvas.drawPath(leadingPath, leadingPaint);
        } else if (isLastButton) {
          final Path leadingPath = Path()
            ..moveTo(rrect.right, rrect.bottom + leadingBorderSide.width / 2)
            ..lineTo(rrect.right, rrect.top - leadingBorderSide.width / 2);
          context.canvas.drawPath(leadingPath, leadingPaint);

          final Paint endingPaint = trailingBorderSide.toPaint();
          final Path endingPath = Path()
            ..moveTo(rrect.right - horizontalBorderSide.width / 2.0, rrect.top)
            ..lineTo(rrect.left + rrect.tlRadiusX, rrect.top)
            ..addArc(tlCorner, math.pi * 3.0 / 2.0, -sweepAngle)
            ..lineTo(rrect.left, rrect.bottom - rrect.blRadiusY)
            ..addArc(blCorner, math.pi, -sweepAngle)
            ..lineTo(rrect.right - horizontalBorderSide.width / 2.0, rrect.bottom);
          context.canvas.drawPath(endingPath, endingPaint);
        } else {
          final Path leadingPath = Path()
            ..moveTo(rrect.right, rrect.bottom + leadingBorderSide.width / 2)
            ..lineTo(rrect.right, rrect.top - leadingBorderSide.width / 2);
          context.canvas.drawPath(leadingPath, leadingPaint);

          final Paint horizontalPaint = horizontalBorderSide.toPaint();
          final Path horizontalPaths = Path()
            ..moveTo(rrect.right - horizontalBorderSide.width / 2.0, rrect.top)
            ..lineTo(outer.left - rrect.tlRadiusX, rrect.top)
            ..moveTo(rrect.right - horizontalBorderSide.width / 2.0 + rrect.trRadiusX, rrect.bottom)
            ..lineTo(outer.left - rrect.tlRadiusX, rrect.bottom);
          context.canvas.drawPath(horizontalPaths, horizontalPaint);
        }
        break;
    }
  }
}
