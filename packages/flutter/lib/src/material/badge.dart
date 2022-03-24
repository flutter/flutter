// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'badge_theme.dart';
import 'color_scheme.dart';
import 'theme.dart';
import 'theme_data.dart';

const ShapeBorder _kDefaultBadgeShape = CircleBorder();
const ShapeBorder _kDefaultBadgeCountShape = StadiumBorder();

/// Material Badge component.
///
/// Used to display a badge on one of the edge of [NavigationDestination].
///
/// If [NavigationDestination.showBadge] is true, a small badge will be visible.
/// If [BadgeController] with a number is also provided then a [Badge] with a
/// will be shown.
class Badge extends StatefulWidget {
  ///
  const Badge({
    Key? key,
    this.backgroundColor,
  }) : shape = _kDefaultBadgeShape,
       countColor = null,
       count = null,
       textStyle = null,
       super(key: key);

  ///
  const Badge.count({
    Key? key,
    this.backgroundColor,
    this.countColor,
    this.shape,
    this.textStyle,
    required this.count,
  }) : super(key: key);

  /// The background color of the Badge.
  ///
  /// If null, defaults to [Theme.of(context).colorScheme.error].
  final Color? backgroundColor;


  /// The color of the Badge number, if provided.
  ///
  /// If null, defaults to [Theme.of(context).colorScheme.onError].
  final Color? countColor;

  ///
  final ShapeBorder? shape;

  /// The style of the Badge count, if provided.
  ///
  /// If null, defaults to [ThemeData.textTheme.labelSmall].
  final TextStyle? textStyle;

  ///
  final int? count;

  @override
  State<Badge> createState() => _BadgeState();
}

class _BadgeState extends State<Badge> {


  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final BadgeThemeData badgeTheme = BadgeTheme.of(context);

    final String countText = widget.count.toString().length < 4
      ? widget.count.toString()
      : '${widget.count.toString().substring(0, 3)}+';

    if (widget.count != null) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 1.0, horizontal: 3),
        decoration: ShapeDecoration(
          color: widget.backgroundColor ?? badgeTheme.backgroundColor ?? colorScheme.error,
          shape: _kDefaultBadgeCountShape,
        ),
        child: DefaultTextStyle(
          style: theme.textTheme.labelSmall!.copyWith(
            color: widget.countColor ?? badgeTheme.countColor ?? colorScheme.onError,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
          child: Text(countText, style: widget.textStyle ?? badgeTheme.textStyle),
        ),
      );
    }

    return SizedBox(
      width: 18.0,
      height: 11.0,
      child: Center(
        child: Container(
          height: 6.5,
          width: 6.5,
          decoration: ShapeDecoration(
            color: widget.backgroundColor ?? badgeTheme.backgroundColor ?? colorScheme.error,
            shape: _kDefaultBadgeShape,
          ),
        ),
      ),
    );
  }
}
