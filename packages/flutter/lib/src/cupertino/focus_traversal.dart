// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'button.dart';
import 'colors.dart';
import 'constants.dart';

/// {@template flutter.cupertino.CupertinoFocusTraversalGroup}
/// A wrapper around [FocusTraversalGroup] to apply a Cupertino-style focus border
/// around its child when any of child focus nodes gain focus.
///
/// The focus border is drawn using a border color specified by [focusColor] and
/// is rounded by a border radius specified by [borderRadius].
///
/// See also:
///
/// * <https://developer.apple.com/design/human-interface-guidelines/focus-and-selection/>
/// {@endtemplate}
class CupertinoFocusTraversalGroup extends StatefulWidget {
  /// {@macro flutter.cupertino.CupertinoFocusTraversalGroup}
  const CupertinoFocusTraversalGroup({
    this.borderRadius,
    this.focusColor,
    required this.child,
    super.key,
  });

  /// The radius of the border that highlights active focus.
  ///
  /// When [borderRadius] is null, it defaults to [CupertinoFocusTraversalGroup.defaultBorderRadius]
  final BorderRadiusGeometry? borderRadius;

  /// {@template flutter.cupertino.CupertinoFocusTraversalGroup.focusColor}
  /// The color of the traversal group border that highlights active focus.
  ///
  /// A opacity of [kCupertinoFocusColorOpacity], brightness of [kCupertinoFocusColorBrightness]
  /// and saturation of [kCupertinoFocusColorSaturation] is automatically applied to this color.
  ///
  /// When [focusColor] is null, the widget defaults to [CupertinoColors.activeBlue]
  /// {@endtemplate}
  final Color? focusColor;

  /// The child to draw the focused border around.
  ///
  /// Since [CupertinoFocusTraversalGroup] can't request focus to itself, this [child] should
  /// contain widget(s) that can request focus.
  final Widget child;

  /// The default radius of the border that highlights active focus.
  static BorderRadius get defaultBorderRadius =>
      kCupertinoButtonSizeBorderRadius[CupertinoButtonSize.large]!;

  @override
  State<CupertinoFocusTraversalGroup> createState() => CupertinoFocusTraversalGroupState();
}

/// {@macro flutter.cupertino.CupertinoFocusTraversalGroup}
class CupertinoFocusTraversalGroupState extends State<CupertinoFocusTraversalGroup> {
  bool _childHasFocus = false;

  Color get _effectiveFocusOutlineColor =>
      HSLColor.fromColor(
            (widget.focusColor ?? CupertinoColors.activeBlue).withOpacity(
              kCupertinoFocusColorOpacity,
            ),
          )
          .withLightness(kCupertinoFocusColorBrightness)
          .withSaturation(kCupertinoFocusColorSaturation)
          .toColor();

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      onFocusChange: (bool hasFocus) {
        setState(() {
          _childHasFocus = hasFocus;
        });
      },
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius ?? CupertinoFocusTraversalGroup.defaultBorderRadius,
          border:
              _childHasFocus
                  ? Border.fromBorderSide(
                    BorderSide(color: _effectiveFocusOutlineColor, width: 3.5),
                  )
                  : null,
        ),
        child: widget.child,
      ),
    );
  }
}
