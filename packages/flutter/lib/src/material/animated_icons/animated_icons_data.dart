// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file serves as the interface between the public and private APIs for
// animated icons.
// The AnimatedIcons class is public and is used to specify available icons,
// while the _AnimatedIconData interface which used to deliver the icon data is
// kept private.

part of material_animated_icons;

/// Identifier for the supported Material Design animated icons.
///
/// Use with [AnimatedIcon] class to show specific animated icons.
abstract class AnimatedIcons {

  /// The Material Design add to event icon animation.
  static const AnimatedIconData add_event = _$add_event;

  /// The Material Design arrow to menu icon animation.
  static const AnimatedIconData arrow_menu = _$arrow_menu;

  /// The Material Design close to menu icon animation.
  static const AnimatedIconData close_menu = _$close_menu;

  /// The Material Design ellipsis to search icon animation.
  static const AnimatedIconData ellipsis_search = _$ellipsis_search;

  /// The Material Design event to add icon animation.
  static const AnimatedIconData event_add = _$event_add;

  /// The Material Design home to menu icon animation.
  static const AnimatedIconData home_menu = _$home_menu;

  /// The Material Design list to view icon animation.
  static const AnimatedIconData list_view = _$list_view;

  /// The Material Design menu to arrow icon animation.
  static const AnimatedIconData menu_arrow = _$menu_arrow;

  /// The Material Design menu to close icon animation.
  static const AnimatedIconData menu_close = _$menu_close;

  /// The Material Design menu to home icon animation.
  static const AnimatedIconData menu_home = _$menu_home;

  /// The Material Design pause to play icon animation.
  static const AnimatedIconData pause_play = _$pause_play;

  /// The Material Design play to pause icon animation.
  static const AnimatedIconData play_pause = _$play_pause;

  /// The Material Design search to ellipsis icon animation.
  static const AnimatedIconData search_ellipsis = _$search_ellipsis;

  /// The Material Design view to list icon animation.
  static const AnimatedIconData view_list = _$view_list;
}

/// Vector graphics data for icons used by [AnimatedIcon].
///
/// Instances of this class are currently opaque because we have not committed to a specific
/// animated vector graphics format.
///
/// See also:
///
///  * [AnimatedIcons], a class that contains constants that implement this interface.
abstract class AnimatedIconData {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const AnimatedIconData();

  /// Whether this icon should be mirrored horizontally when text direction is
  /// right-to-left.
  ///
  /// See also:
  ///
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
