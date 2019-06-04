// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/src/material/debug.dart';
import 'package:flutter/src/material/theme_data.dart';
import 'package:flutter/widgets.dart';

import 'button.dart';
import 'colors.dart';
import 'theme.dart';

// Minimum logical pixel size of the IconButton.
// See: <https://material.io/design/usability/accessibility.html#layout-typography>
const double _kMinButtonSize = 48.0;

const Border _kDefaultStandaloneBorder = Border(
  left: BorderSide(color: Colors.black12),
  top: BorderSide(color: Colors.black12),
  right: BorderSide(color: Colors.black12),
  bottom: BorderSide(color: Colors.black12),
);

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

  /// The button's label, which is usually an [Icon] or a [Text] widget.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    Color currentColor;

    if (onPressed != null && selected) {
      currentColor = activeColor ?? Theme.of(context).colorScheme.primary;
    } else if (onPressed != null && !selected) {
      currentColor = color ?? Theme.of(context).colorScheme.onSurface;
    } else {
      currentColor = disabledColor ?? Theme.of(context).disabledColor;
    }

    return IconTheme.merge(
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
  }

  // TODO(WIP): include debugFillProperties method
}

class ToggleButtonBorder extends BoxBorder {
  const ToggleButtonBorder({
    this.borderSide,
    @required this.borderRadius,
  });

  final BorderSide borderSide;

  final BorderRadius borderRadius;

  @override
  BorderSide get top {
    return borderSide;
  }

  @override
  BorderSide get bottom {
    return borderSide;
  }

  @override
  bool get isUniform {
    return false;
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection textDirection}) {
    return Path()
      ..addRRect(borderRadius.resolve(textDirection).toRRect(rect).deflate(borderSide.width));
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection textDirection}) {
    return Path()
      ..addRRect(borderRadius.resolve(textDirection).toRRect(rect));
  }

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    TextDirection textDirection,
    BoxShape shape = BoxShape.rectangle,
    BorderRadius borderRadius,
  }) {
    final Paint paint = borderSide.toPaint();
    final RRect outer = borderRadius.toRRect(rect);
    final RRect center = outer.deflate(borderSide.width / 2.0);

    canvas.drawRRect(center, paint);
  }

  @override
  ToggleButtonBorder scale(double t) {
    return ToggleButtonBorder(
      borderSide: borderSide.scale(t),
      borderRadius: borderRadius * t,
    );
  }

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;
}

class ToggleButtons extends StatelessWidget {
  const ToggleButtons({
    this.children,
    this.isSelected,
    this.onPressed,
    this.color,
    this.activeColor,
    this.disabledColor,
    this.border,
    this.borderSide = const BorderSide(),
    this.borderRadius = const BorderRadius.all(Radius.circular(0.0)),
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

  final Border border;

  final BorderSide borderSide;

  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: ToggleButtonBorder(
          borderSide: borderSide,
          borderRadius: borderRadius,
          // pass in children to figure out width
          // pass in selected to figre out color
          // figure out: custom colors?
        ),
        borderRadius: borderRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List<Widget>.generate(children.length, (int index) {
          return _ToggleButton(
            onPressed: () {
              onPressed(index);
            },
            selected: isSelected[index],
            child: children[index],
          );
        }),
      ),
    );
  }

  // TODO(WIP): include debugFillProperties method
}
