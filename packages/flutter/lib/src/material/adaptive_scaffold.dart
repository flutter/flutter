// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'adaptive_layout.dart';
import 'bottom_navigation_bar.dart';
import 'colors.dart';
import 'navigation_bar.dart';
import 'navigation_rail.dart';
import 'slot_layout.dart';
import 'slot_layout_config.dart';

/// [AdaptiveScaffold] is an abstraction that passes properties to
/// [AdaptiveLayout] and reduces repetition and a burden on the developer.
class AdaptiveScaffold extends StatefulWidget {
  /// Returns an [AdaptiveScaffold] by passing information down to an
  /// [AdaptiveLayout].
  const AdaptiveScaffold({
    this.destinations,
    this.selectedIndex,
    this.bodyList,
    this.secondaryBodyList,
    this.bodyRatio,
    this.breakpoints = const <int>[0, 480, 1024],
    this.displayAnimations = true,
    this.bodyAnimated = true,
    super.key,
  });

  /// The destinations to be used in navigation items. These are converted to
  /// [NavigationRailDestination]s and [BottomNavigationBarItem]s and inserted
  /// into the appropriate places. If passing destinations, you must also pass a
  /// selected index to be used by the [NavigationRail].
  final List<NavigationDestination>? destinations;

  /// The index to be used by the [NavigationRail] if applicable.
  final int? selectedIndex;

  /// By default the indexing of this list goes in order of what to display in
  /// the body slot under the same indexing of the [breakpoints] list.
  final List<Widget?>? bodyList;

  /// By default the indexing of this list goes in order of what to display in
  /// the secondaryBody slot under the same indexing of the [breakpoints] list.
  final List<Widget?>? secondaryBodyList;

  /// Defines the fractional ratio of body to the secondaryBody.
  ///
  /// For example 1 / 3 would mean body takes up 1/3 of the available space and
  /// secondaryBody takes up the rest.
  ///
  /// If this value is null, the ratio is defined so that the split axis is in
  /// the center of the screen.
  final double? bodyRatio;

  /// The list defining breakpoints for the [AdaptiveLayout] the breakpoint is
  /// active from the value at the index up until the value at the next index.
  ///
  /// Defaults to [0, 480, 1024].
  final List<int> breakpoints;

  /// Whether or not the developer wants display animations.
  ///
  /// Defaults to true.
  final bool displayAnimations;

  /// Whether or not the developer wants the smooth entering slide transition on
  /// secondaryBody.
  ///
  /// Defaults to true.
  final bool bodyAnimated;

  @override
  State<AdaptiveScaffold> createState() => _AdaptiveScaffoldState();
}


class _AdaptiveScaffoldState extends State<AdaptiveScaffold> {
  AnimatedWidget bottomToTop(Widget child, AnimationController animation) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(animation),
      child: child,
    );
  }

  AnimatedWidget topToBottom(Widget child, AnimationController animation) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(0, 1),
      ).animate(animation),
      child: child,
    );
  }

  AnimatedWidget leftOutIn(Widget child, AnimationController animation) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(-1, 0),
        end: Offset.zero,
      ).animate(animation),
      child: child,
    );
  }

  AnimatedWidget leftInOut(Widget child, AnimationController animation) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(-1, 0),
      ).animate(animation),
      child: child,
    );
  }

  AnimatedWidget rightOutIn(Widget child, AnimationController animation) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(animation),
      child: child,
    );
  }

  Widget fadeIn(Widget child, AnimationController animation) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeInCubic),
      child: child,
    );
  }
  @override
  Widget build(BuildContext context) {
    final Widget Function(Widget, AnimationController)? inAnimation0 = (widget.secondaryBodyList == null || widget.secondaryBodyList![0] == null && widget.displayAnimations) ? fadeIn : null;
    final Widget Function(Widget, AnimationController)? inAnimation1 = (widget.secondaryBodyList == null || widget.secondaryBodyList![1] == null && widget.displayAnimations) ? fadeIn : null;
    final Widget Function(Widget, AnimationController)? inAnimation2 = (widget.secondaryBodyList == null || widget.secondaryBodyList![2] == null && widget.displayAnimations) ? fadeIn : null;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: AdaptiveLayout(
        bodyRatio: widget.bodyRatio,
        bodyAnimated: widget.bodyAnimated && widget.displayAnimations,
        primaryNavigation: widget.destinations != null && widget.selectedIndex != null
            ? SlotLayout(
                config: <int, SlotLayoutConfig>{
                  widget.breakpoints[0]: SlotLayoutConfig(
                    overtakeAnimation: widget.displayAnimations ? leftInOut : null,
                    key: const Key('primaryNavigation0'),
                    child: const SizedBox(
                      width: 0,
                      height: 0,
                    ),
                  ),
                  widget.breakpoints[1]: SlotLayoutConfig(
                    inAnimation: widget.displayAnimations ? leftOutIn : null,
                    key: const Key('primaryNavigation1'),
                    child: SizedBox(
                      width: 75,
                      height: MediaQuery.of(context).size.height,
                      child: NavigationRail(
                        selectedIndex: widget.selectedIndex,
                        destinations: widget.destinations!.map(_toRailDestination).toList(),
                      ),
                    ),
                  ),
                  widget.breakpoints[2]: SlotLayoutConfig(
                    inAnimation: widget.displayAnimations ? leftOutIn : null,
                    key: const Key('primaryNavigation2'),
                    child: SizedBox(
                      width: 150,
                      height: MediaQuery.of(context).size.height,
                      child: NavigationRail(
                        extended: true,
                        selectedIndex: widget.selectedIndex,
                        destinations: widget.destinations!.map(_toRailDestination).toList(),
                      ),
                    ),
                  ),
                },
              )
            : null,
        bottomNavigation: widget.destinations != null && widget.selectedIndex != null
            ? SlotLayout(
                config: <int, SlotLayoutConfig>{
                  widget.breakpoints[0]: SlotLayoutConfig(
                    inAnimation: widget.displayAnimations ? bottomToTop : null,
                    key: const Key('botnav1'),
                    child: BottomNavigationBar(
                      unselectedItemColor: Colors.grey,
                      selectedItemColor: Colors.black,
                      items: widget.destinations!.map(_toBottomNavItem).toList(),
                    ),
                  ),
                  widget.breakpoints[1]: SlotLayoutConfig(
                    overtakeAnimation: widget.displayAnimations ? topToBottom : null,
                    key: const Key('botnavnone'),
                    child: const SizedBox(width: 0, height: 0),
                  ),
                },
              )
            : null,
        body: widget.bodyList != null
            ? SlotLayout(
                config: <int, SlotLayoutConfig>{
                  if (widget.bodyList![0] != null) widget.breakpoints[0]: SlotLayoutConfig(inAnimation: inAnimation0, key: const Key('body0'), child: widget.bodyList![0]!),
                  if (widget.bodyList![1] != null) widget.breakpoints[1]: SlotLayoutConfig(inAnimation: inAnimation1, key: const Key('body1'), child: widget.bodyList![1]!),
                  if (widget.bodyList![2] != null) widget.breakpoints[2]: SlotLayoutConfig(inAnimation: inAnimation2, key: const Key('body2'), child: widget.bodyList![2]!),
                },
              )
            : null,
        secondaryBody: widget.secondaryBodyList != null
            ? SlotLayout(
                config: <int, SlotLayoutConfig>{
                  if (widget.secondaryBodyList![0] != null) widget.breakpoints[0]: SlotLayoutConfig(key: const Key('sbody0'), child: widget.secondaryBodyList![0]!),
                  if (widget.secondaryBodyList![1] != null) widget.breakpoints[1]: SlotLayoutConfig(key: const Key('sbody1'), child: widget.secondaryBodyList![1]!),
                  if (widget.secondaryBodyList![2] != null) widget.breakpoints[2]: SlotLayoutConfig(key: const Key('sbody2'), child: widget.secondaryBodyList![2]!),
                },
              )
            : null,
      ),
    );
  }
}

NavigationRailDestination _toRailDestination(NavigationDestination destination) {
  return NavigationRailDestination(
    label: Text(destination.label),
    icon: destination.icon,
  );
}

BottomNavigationBarItem _toBottomNavItem(NavigationDestination destination) {
  return BottomNavigationBarItem(
    label: destination.label,
    icon: destination.icon,
  );
}
