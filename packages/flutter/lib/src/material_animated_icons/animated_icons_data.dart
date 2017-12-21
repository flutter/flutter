// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file serves as the interface between the public and private APIs for
// animated icons.
// The AnimatedIcons class is public and is used to specify available icons,
// while the _AnimatedIconData interface which used to deliver the icon data is
// kept private.

part of material_animated_icons;

/// Identifier for the supported material design animated icons.
///
/// Use with [AnimatedIcon] class to show specific animated icons.
abstract class AnimatedIcons {
  /// The material design arrow to menu icon animation.
  static const AnimatedIconData arrow_menu = _$arrow_menu;

  /// The material design menu to arrow icon animation.
  static const AnimatedIconData menu_arrow = _$menu_arrow;
}

/// Vector graphics data for icons used by [AnimatedIcon].
///
/// Instances of this class are currently opaque because we have not committed to a specific
/// animated vector graphics format.
///
/// See also:
///  * [AnimatedIcons], a class that contains constants that implement this interface.
abstract class AnimatedIconData {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const AnimatedIconData();
  
  /// Whether this icon should be mirrored horizontally when text direction is
  /// right-to-left.
  ///
  /// See also:
  ///  * [TextDirection], which discusses concerns regarding reading direction
  ///    in Flutter.
  ///  * [Directionality], a widget which determines the ambient directionality.
  bool get matchTextDirection;
}

class _AnimatedIconData extends AnimatedIconData {
  const _AnimatedIconData(this.size, this.paths, {this.matchTextDirection = false});

  final Size size;
  final List<_PathFrames> paths;

  @override
  final bool matchTextDirection;
}
