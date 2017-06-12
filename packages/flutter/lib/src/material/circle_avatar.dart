// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'constants.dart';
import 'theme.dart';
import 'typography.dart';

// Examples can assume:
// String userAvatarUrl;

/// A circle that represents a user.
///
/// Typically used with a user's profile image, or, in the absence of
/// such an image, the user's initials. A given user's initials should
/// always be paired with the same background color, for consistency.
///
/// ## Sample code
///
/// If the avatar is to have an image, the image should be specified in the
/// [backgroundImage] property:
///
/// ```dart
/// new CircleAvatar(
///   backgroundImage: new NetworkImage(userAvatarUrl),
/// )
/// ```
///
/// The image will be cropped to have a circle shape.
///
/// If the avatar is to just have the user's initials, they are typically
/// provided using a [Text] widget as the [child] and a [backgroundColor]:
///
/// ```dart
/// new CircleAvatar(
///   backgroundColor: Colors.brown.shade800,
///   child: new Text('AH'),
/// )
/// ```
///
/// See also:
///
///  * [Chip], for representing users or concepts in long form.
///  * [ListTile], which can combine an icon (such as a [CircleAvatar]) with some
///    text for a fixed height list entry.
///  * <https://material.google.com/components/chips.html#chips-contact-chips>
class CircleAvatar extends StatelessWidget {
  /// Creates a circle that represents a user.
  const CircleAvatar({
    Key key,
    this.child,
    this.backgroundColor,
    this.backgroundImage,
    this.foregroundColor,
    this.radius: 20.0,
  }) : super(key: key);

  /// The widget below this widget in the tree.
  ///
  /// Typically a [Text] widget. If the [CircleAvatar] is to have an image, use
  /// [backgroundImage] instead.
  final Widget child;

  /// The color with which to fill the circle. Changing the background
  /// color will cause the avatar to animate to the new color.
  ///
  /// If a background color is not specified, the theme's primary color is used.
  final Color backgroundColor;

  /// The default text color for text in the circle.
  ///
  /// Falls back to white if a background color is specified, or the primary
  /// text theme color otherwise.
  final Color foregroundColor;

  /// The background image of the circle. Changing the background
  /// image will cause the avatar to animate to the new image.
  ///
  /// If the [CircleAvatar] is to have the user's initials, use [child] instead.
  final ImageProvider backgroundImage;

  /// The size of the avatar. Changing the radius will cause the
  /// avatar to animate to the new size.
  ///
  /// Defaults to 20 logical pixels.
  final double radius;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle textStyle = backgroundColor != null ?
        new Typography(platform: theme.platform).white.title :
        theme.primaryTextTheme.title;
    return new AnimatedContainer(
      width: radius * 2.0,
      height: radius * 2.0,
      duration: kThemeChangeDuration,
      decoration: new BoxDecoration(
        color: backgroundColor ?? theme.primaryColor,
        image: backgroundImage != null ? new DecorationImage(
          image: backgroundImage
        ) : null,
        shape: BoxShape.circle,
      ),
      child: child != null ? new Center(
        child: new DefaultTextStyle(
          style: textStyle.copyWith(color: foregroundColor),
          child: child,
        )
      ) : null,
    );
  }
}
