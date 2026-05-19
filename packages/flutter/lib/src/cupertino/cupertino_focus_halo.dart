// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'constants.dart';

/// Applies an iOS-style focus border around its child when any of child focus nodes gain focus.
///
/// The shape of the focus halo does not automatically adapt to the child widget
/// it encloses. You are responsible for specifying a shape that correctly
/// matches the child's geometry by using the appropriate constructor, such as
/// [CupertinoFocusHalo.withRect] or [CupertinoFocusHalo.withRRect].
///
/// See also:
///
/// * <https://developer.apple.com/design/human-interface-guidelines/focus-and-selection/>
class CupertinoFocusHalo extends StatefulWidget {
  /// Creates a rectangular [CupertinoFocusHalo] around the child.
  ///
  /// For example, to highlight a rectangular section of the widget tree when any button inside that
  /// section has focus, one could write:
  ///
  /// ```dart
  /// CupertinoFocusHalo.withRect(
  ///   child: Column(
  ///     children: <Widget>[
  ///       CupertinoButton(child: const Text('Child 1'), onPressed: () {}),
  ///       CupertinoButton(child: const Text('Child 2'), onPressed: () {}),
  ///     ],
  ///   ),
  /// )
  /// ```
  const CupertinoFocusHalo.withRect({required this.child, super.key})
    : _borderRadius = BorderRadius.zero;

  /// Creates a rounded rectangular [CupertinoFocusHalo] around the child
  ///
  /// For example, to highlight a rounded rectangular section of the widget tree when any button inside that
  /// section has focus, one could write:
  ///
  /// ```dart
  /// CupertinoFocusHalo.withRRect(
  ///   borderRadius: BorderRadius.circular(10.0),
  ///   child: Column(
  ///     children: <Widget>[
  ///       CupertinoButton(child: const Text('Child 1'), onPressed: () {}),
  ///       CupertinoButton(child: const Text('Child 2'), onPressed: () {}),
  ///     ],
  ///   ),
  /// )
  /// ```
  const CupertinoFocusHalo.withRRect({
    required this.child,
    required BorderRadiusGeometry borderRadius,
    super.key,
  }) : _borderRadius = borderRadius;

  final BorderRadiusGeometry _borderRadius;

  /// The child to draw the focused border around.
  ///
  /// Since [CupertinoFocusHalo] can't request focus to itself, this [child] should
  /// contain widget(s) that can request focus.
  ///
  /// The child widget is responsible for its own visual shape, for example by
  /// using an appropriate clipping.
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
          border: _childHasFocus
              ? Border.fromBorderSide(BorderSide(color: _effectiveFocusOutlineColor, width: 3.5))
              : null,
        ),
        child: widget.child,
      ),
    );
  }
}
