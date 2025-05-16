// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

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
  const CupertinoFocusTraversalGroup.onRect({
    required this.child,
    super.key,
  })  : borderRadius = BorderRadius.zero;

  /// {@macro flutter.cupertino.CupertinoFocusTraversalGroup}
  const CupertinoFocusTraversalGroup.onRRect({
    required this.child,
    required this.borderRadius,
    super.key,
  });

  /// The radius of the border that highlights active focus.
  ///
  /// When [borderRadius] is null, it defaults to [CupertinoFocusTraversalGroup.defaultBorderRadius].
  final BorderRadiusGeometry borderRadius;

  /// The child to draw the focused border around.
  ///
  /// Since [CupertinoFocusTraversalGroup] can't request focus to itself, this [child] should
  /// contain widget(s) that can request focus.
  final Widget child;

  @override
  State<CupertinoFocusTraversalGroup> createState() => _CupertinoFocusTraversalGroupState();
}

class _CupertinoFocusTraversalGroupState extends State<CupertinoFocusTraversalGroup> {
  bool _childHasFocus = false;

  Color get _effectiveFocusOutlineColor =>
      HSLColor.fromColor(
            CupertinoColors.activeBlue.withOpacity(
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
          borderRadius: widget.borderRadius,
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
