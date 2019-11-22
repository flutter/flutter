// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';

import 'button_bar_theme.dart';
import 'button_theme.dart';
import 'dialog.dart';
import 'flat_button.dart';
import 'raised_button.dart';

/// An end-aligned row of buttons, laying out into a column if there is not
/// enough horizontal space.
///
/// Places the buttons horizontally according to the [buttonPadding]. The
/// children are laid out in a [Row] with [MainAxisAlignment.end]. When the
/// [Directionality] is [TextDirection.ltr], the button bar's children are
/// right justified and the last child becomes the rightmost child. When the
/// [Directionality] [TextDirection.rtl] the children are left justified and
/// the last child becomes the leftmost child.
///
/// If the button bar's width exceeds the maximum width constraint on the
/// widget, it aligns its buttons in a column. The key difference here
/// is that the [MainAxisAlignment] will then be treated as a
/// cross-axis/horizontal alignment. For example, if the buttons overflow and
/// [ButtonBar.alignment] was set to [MainAxisAligment.start], the buttons would
/// align to the horizontal start of the button bar.
///
/// The [ButtonBar] can be configured with a [ButtonBarTheme]. For any null
/// property on the ButtonBar, the surrounding ButtonBarTheme's property
/// will be used instead. If the ButtonBarTheme's property is null
/// as well, the property will default to a value described in the field
/// documentation below.
///
/// The [children] are wrapped in a [ButtonTheme] that is a copy of the
/// surrounding ButtonTheme with the button properties overridden by the
/// properties of the ButtonBar as described above. These properties include
/// [buttonTextTheme], [buttonMinWidth], [buttonHeight], [buttonPadding],
/// and [buttonAlignedDropdown].
///
/// Used by [Dialog] to arrange the actions at the bottom of the dialog.
///
/// See also:
///
///  * [RaisedButton], a kind of button.
///  * [FlatButton], another kind of button.
///  * [Card], at the bottom of which it is common to place a [ButtonBar].
///  * [Dialog], which uses a [ButtonBar] for its actions.
///  * [ButtonBarTheme], which configures the [ButtonBar].
class ButtonBar extends StatelessWidget {
  /// Creates a button bar.
  ///
  /// Both [buttonMinWidth] and [buttonHeight] must be non-negative if they
  /// are not null.
  const ButtonBar({
    Key key,
    this.alignment,
    this.mainAxisSize,
    this.buttonTextTheme,
    this.buttonMinWidth,
    this.buttonHeight,
    this.buttonPadding,
    this.buttonAlignedDropdown,
    this.layoutBehavior,
    this.children = const <Widget>[],
  }) : assert(buttonMinWidth == null || buttonMinWidth >= 0.0),
       assert(buttonHeight == null || buttonHeight >= 0.0),
       super(key: key);

  /// How the children should be placed along the horizontal axis.
  ///
  /// If null then it will use [ButtonBarTheme.alignment]. If that is null,
  /// it will default to [MainAxisAlignment.end].
  final MainAxisAlignment alignment;

  /// How much horizontal space is available. See [Row.mainAxisSize].
  ///
  /// If null then it will use the surrounding [ButtonBarTheme.mainAxisSize].
  /// If that is null, it will default to [MainAxisSize.max].
  final MainAxisSize mainAxisSize;

  /// Overrides the surrounding [ButtonTheme.textTheme] to define a button's
  /// base colors, size, internal padding and shape.
  ///
  /// If null then it will use the surrounding [ButtonBarTheme.buttonTextTheme].
  /// If that is null, it will default to [ButtonTextTheme.primary].
  final ButtonTextTheme buttonTextTheme;

  /// Overrides the surrounding [ButtonThemeData.minWidth] to define a button's
  /// minimum width.
  ///
  /// If null then it will use the surrounding [ButtonBarTheme.buttonMinWidth].
  /// If that is null, it will default to 64.0 logical pixels.
  final double buttonMinWidth;

  /// Overrides the surrounding [ButtonThemeData.height] to define a button's
  /// minimum height.
  ///
  /// If null then it will use the surrounding [ButtonBarTheme.buttonHeight].
  /// If that is null, it will default to 36.0 logical pixels.
  final double buttonHeight;

  /// Overrides the surrounding [ButtonThemeData.padding] to define the padding
  /// for a button's child (typically the button's label).
  ///
  /// If null then it will use the surrounding [ButtonBarTheme.buttonPadding].
  /// If that is null, it will default to 8.0 logical pixels on the left
  /// and right.
  final EdgeInsetsGeometry buttonPadding;

  /// Overrides the surrounding [ButtonThemeData.alignedDropdown] to define whether
  /// a [DropdownButton] menu's width will match the button's width.
  ///
  /// If null then it will use the surrounding [ButtonBarTheme.buttonAlignedDropdown].
  /// If that is null, it will default to false.
  final bool buttonAlignedDropdown;

  /// Defines whether a [ButtonBar] should size itself with a minimum size
  /// constraint or with padding.
  ///
  /// Overrides the surrounding [ButtonThemeData.layoutBehavior].
  ///
  /// If null then it will use the surrounding [ButtonBarTheme.layoutBehavior].
  /// If that is null, it will default [ButtonBarLayoutBehavior.padded].
  final ButtonBarLayoutBehavior layoutBehavior;

  /// The buttons to arrange horizontally.
  ///
  /// Typically [RaisedButton] or [FlatButton] widgets.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ButtonThemeData parentButtonTheme = ButtonTheme.of(context);
    final ButtonBarThemeData barTheme = ButtonBarTheme.of(context);

    final ButtonThemeData buttonTheme = parentButtonTheme.copyWith(
      textTheme: buttonTextTheme ?? barTheme.buttonTextTheme ?? ButtonTextTheme.primary,
      minWidth: buttonMinWidth ?? barTheme.buttonMinWidth ?? 64.0,
      height: buttonHeight ?? barTheme.buttonHeight ?? 36.0,
      padding: buttonPadding ?? barTheme.buttonPadding ?? const EdgeInsets.symmetric(horizontal: 8.0),
      alignedDropdown: buttonAlignedDropdown ?? barTheme.buttonAlignedDropdown ?? false,
      layoutBehavior: layoutBehavior ?? barTheme.layoutBehavior ?? ButtonBarLayoutBehavior.padded,
    );

    // We divide by 4.0 because we want half of the average of the left and right padding.
    final double paddingUnit = buttonTheme.padding.horizontal / 4.0;
    final Widget child = ButtonTheme.fromButtonThemeData(
      data: buttonTheme,
      child: _ButtonBarRow(
        mainAxisAlignment: alignment ?? barTheme.alignment ?? MainAxisAlignment.end,
        mainAxisSize: mainAxisSize ?? barTheme.mainAxisSize ?? MainAxisSize.max,
        children: children.map<Widget>((Widget child) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: paddingUnit),
            child: child,
          );
        }).toList(),
      ),
    );
    switch (buttonTheme.layoutBehavior) {
      case ButtonBarLayoutBehavior.padded:
        return Padding(
          padding: EdgeInsets.symmetric(
            vertical: 2.0 * paddingUnit,
            horizontal: paddingUnit,
          ),
          child: child,
        );
      case ButtonBarLayoutBehavior.constrained:
        return Container(
          padding: EdgeInsets.symmetric(horizontal: paddingUnit),
          constraints: const BoxConstraints(minHeight: 52.0),
          alignment: Alignment.center,
          child: child,
        );
    }
    assert(false);
    return null;
  }
}

/// Attempts to display buttons in a row, but displays them in a column if
/// there is not enough horizontal space.
///
/// It first attempts to lay out its buttons as though there were no
/// maximum width constraints on the widget. If the button bar's width is
/// less than the maximum width constraints of the widget, it then lays
/// out the widget as though it were placed in a [Row].
///
/// However, if the button bar's width exceeds the maximum width constraint on
/// the widget, it then aligns its buttons in a column. The key difference here
/// is that the [MainAxisAlignment] will then be treated as a
/// cross-axis/horizontal alignment. For example, if the buttons overflow and
/// [ButtonBar.alignment] was set to [MainAxisAligment.start], the column of
/// buttons would align to the horizontal start of the button bar.
class _ButtonBarRow extends Flex {
  /// Creates a button bar that attempts to display in a row, but displays in
  /// a column if there is insufficient horizontal space.
  _ButtonBarRow({
    List<Widget> children,
    Axis direction = Axis.horizontal,
    MainAxisSize mainAxisSize = MainAxisSize.max,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    TextDirection textDirection,
    VerticalDirection verticalDirection = VerticalDirection.down,
    TextBaseline textBaseline,
  }) : super(
    children: children,
    direction: direction,
    mainAxisSize: mainAxisSize,
    mainAxisAlignment: mainAxisAlignment,
    crossAxisAlignment: crossAxisAlignment,
    textDirection: textDirection,
    verticalDirection: verticalDirection,
    textBaseline: textBaseline,
  );

  @override
  _RenderButtonBarRow createRenderObject(BuildContext context) {
    return _RenderButtonBarRow(
      direction: direction,
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      crossAxisAlignment: crossAxisAlignment,
      textDirection: getEffectiveTextDirection(context),
      verticalDirection: verticalDirection,
      textBaseline: textBaseline,
    );
  }

  @override
  void updateRenderObject(BuildContext context, covariant _RenderButtonBarRow renderObject) {
    renderObject
      ..direction = direction
      ..mainAxisAlignment = mainAxisAlignment
      ..mainAxisSize = mainAxisSize
      ..crossAxisAlignment = crossAxisAlignment
      ..textDirection = getEffectiveTextDirection(context)
      ..verticalDirection = verticalDirection
      ..textBaseline = textBaseline;
  }
}

/// Attempts to display buttons in a row, but displays them in a column if
/// there is not enough horizontal space.
///
/// It first attempts to lay out its buttons as though there were no
/// maximum width constraints on the widget. If the button bar's width is
/// less than the maximum width constraints of the widget, it then lays
/// out the widget as though it were placed in a [Row].
///
/// However, if the button bar's width exceeds the maximum width constraint on
/// the widget, it then aligns its buttons in a column. The key difference here
/// is that the [MainAxisAlignment] will then be treated as a
/// cross-axis/horizontal alignment. For example, if the buttons overflow and
/// [ButtonBar.alignment] was set to [MainAxisAligment.start], the buttons would
/// align to the horizontal start of the button bar.
class _RenderButtonBarRow extends RenderFlex {
  /// Creates a button bar that attempts to display in a row, but displays in
  /// a column if there is insufficient horizontal space.
  _RenderButtonBarRow({
    List<RenderBox> children,
    Axis direction = Axis.horizontal,
    MainAxisSize mainAxisSize = MainAxisSize.max,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    @required TextDirection textDirection,
    VerticalDirection verticalDirection = VerticalDirection.down,
    TextBaseline textBaseline,
  }) : assert(textDirection != null),
       super(
         children: children,
         direction: direction,
         mainAxisSize: mainAxisSize,
         mainAxisAlignment: mainAxisAlignment,
         crossAxisAlignment: crossAxisAlignment,
         textDirection: textDirection,
         verticalDirection: verticalDirection,
         textBaseline: textBaseline,
       );

  bool _hasCheckedLayoutWidth = false;

  @override
  BoxConstraints get constraints {
    if (_hasCheckedLayoutWidth)
      return super.constraints;
    return super.constraints.copyWith(maxWidth: double.infinity);
  }

  @override
  void performLayout() {
    // Set check layout width to false in reload or update cases.
    _hasCheckedLayoutWidth = false;

    // Perform layout to ensure that button bar knows how wide it would
    // ideally want to be.
    super.performLayout();
    _hasCheckedLayoutWidth = true;

    // If the button bar is constrained by width and it overflows, set the
    // buttons to align vertically. Otherwise, lay out the button bar
    // horizontally.
    if (size.width <= constraints.maxWidth) {
      // A second performLayout is required to ensure that the original maximum
      // width constraints are used. The original perform layout call assumes
      // a maximum width constraint of infinity.
      super.performLayout();
    } else {
      final BoxConstraints childConstraints = constraints.copyWith(minWidth: 0.0);
      RenderBox child = firstChild;
      double currentHeight = 0.0;

      while (child != null) {
        final FlexParentData childParentData = child.parentData;

        // Lay out the child with the button bar's original constraints, but
        // with minimum width set to zero.
        child.layout(childConstraints, parentUsesSize: true);

        // Set the cross axis alignment for the column to match the main axis
        // alignment for a row. For [MainAxisAligment.spaceAround],
        // [MainAxisAligment.spaceBetween] and [MainAxisAlignment.spaceEvenly]
        // cases, use [MainAxisAligmnent.start].
        switch (textDirection) {
          case TextDirection.ltr:
            switch (mainAxisAlignment) {
              case MainAxisAlignment.center:
                final double midpoint = (constraints.maxWidth - child.size.width) / 2.0;
                childParentData.offset = Offset(midpoint, currentHeight);
                break;
              case MainAxisAlignment.end:
                childParentData.offset = Offset(constraints.maxWidth - child.size.width, currentHeight);
                break;
              default:
                childParentData.offset = Offset(0, currentHeight);
                break;
            }
            break;
          case TextDirection.rtl:
            switch (mainAxisAlignment) {
              case MainAxisAlignment.center:
                final double midpoint = constraints.maxWidth / 2.0 - child.size.width / 2.0;
                childParentData.offset = Offset(midpoint, currentHeight);
                break;
              case MainAxisAlignment.end:
                childParentData.offset = Offset(0, currentHeight);
                break;
              default:
                childParentData.offset = Offset(constraints.maxWidth - child.size.width, currentHeight);
                break;
            }
            break;
        }
        currentHeight += child.size.height;
        child = childParentData.nextSibling;
      }
      size = constraints.constrain(Size(constraints.maxWidth, currentHeight));
    }
  }
}
