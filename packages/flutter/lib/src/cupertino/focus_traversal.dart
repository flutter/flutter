// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'constants.dart';

/// {@template flutter.cupertino.CupertinoFocusHalo}
/// A wrapper around [FocusTraversalGroup] to apply a Cupertino-style focus border
/// around its child when any of child focus nodes gain focus.
///
/// The focus border is drawn using a border color specified by [focusColor] and
/// is rounded by a border radius specified by [borderRadius].
///
/// For example, to highlight a section of the widget tree when any button inside that
/// section has focus, one could write:
///
/// ```dart
/// CupertinoFocusHalo.onRect(
///   child: Column(
///     children: [
///       CupertinoButton(child: Text('Child 1'), onPressed: () {}),
///       CupertinoButton(child: Text('Child 2'), onPressed: () {}),
///     ],
///   ),
/// )
/// ```
///
/// See also:
///
/// * <https://developer.apple.com/design/human-interface-guidelines/focus-and-selection/>
/// {@endtemplate}
class CupertinoFocusHalo extends StatefulWidget {
  /// {@macro flutter.cupertino.CupertinoFocusHalo}
  const CupertinoFocusHalo.onRect({required this.child, super.key})
    : _borderRadius = BorderRadius.zero;

  /// {@macro flutter.cupertino.CupertinoFocusHalo}
  const CupertinoFocusHalo.onRRect({
    required this.child,
    required BorderRadiusGeometry borderRadius,
    super.key,
  }) : _borderRadius = borderRadius;

  final BorderRadiusGeometry _borderRadius;

  /// The child to draw the focused border around.
  ///
  /// Since [CupertinoFocusHalo] can't request focus to itself, this [child] should
  /// contain widget(s) that can request focus.
  final Widget child;

  @override
  State<CupertinoFocusHalo> createState() => _CupertinoFocusHaloState();
}

class _CupertinoFocusHaloState extends State<CupertinoFocusHalo> {
  bool _childHasFocus = false;

  Color get _effectiveFocusOutlineColor =>
      HSLColor.fromColor(CupertinoColors.activeBlue.withOpacity(kCupertinoFocusColorOpacity))
          .withLightness(kCupertinoFocusColorBrightness)
          .withSaturation(kCupertinoFocusColorSaturation)
          .toColor();

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      onFocusChange: (bool hasFocus) {
        setState(() {
          _childHasFocus = hasFocus;
        });
      },
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: widget._borderRadius,
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
