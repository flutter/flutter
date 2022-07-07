// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'bottom_navigation_bar.dart';
import 'colors.dart';
import 'navigation_bar.dart';
import 'navigation_rail.dart';

/// [AdaptiveScaffold] is an abstraction that passes properties to
/// [AdaptiveLayout] and reduces repetition and a burden on the developer.
class AdaptiveScaffold extends StatefulWidget {
  /// Returns an [AdaptiveScaffold] by passing information down to an
  /// [AdaptiveLayout].
  const AdaptiveScaffold({
    this.destinations,
    this.selectedIndex = 0,
    this.smallBody = const SizedBox(key: Key('')),
    this.body,
    this.largeBody = const SizedBox(key: Key('')),
    this.smallSecondaryBody = const SizedBox(key: Key('')),
    this.secondaryBody,
    this.largeSecondaryBody = const SizedBox(key: Key('')),
    this.bodyRatio,
    this.breakpoints = const <int>[0, 480, 1024],
    this.displayAnimations = true,
    this.bodyAnimated = true,
    this.horizontalBody = true,
    super.key,
  });

  /// The destinations to be used in navigation items. These are converted to
  /// [NavigationRailDestination]s and [BottomNavigationBarItem]s and inserted
  /// into the appropriate places. If passing destinations, you must also pass a
  /// selected index to be used by the [NavigationRail].
  final List<NavigationDestination>? destinations;

  /// The index to be used by the [NavigationRail] if applicable.
  final int? selectedIndex;

  /// Widget to be displayed in the body slot at the smallest breakpoint.
  ///
  /// If nothing is entered for this property, then the default [body] is
  /// displayed in the slot. If null is entered for this slot, the slot stays
  /// empty.
  final Widget? smallBody;

  /// Widget to be displayed in the body slot at the middle breakpoint.
  ///
  /// The default displayed body.
  final Widget? body;

  /// Widget to be displayed in the body slot at the largest breakpoint.
  ///
  /// If nothing is entered for this property, then the default [body] is
  /// displayed in the slot. If null is entered for this slot, the slot stays
  /// empty.
  final Widget? largeBody;

  /// Widget to be displayed in the secondaryBody slot at the smallest
  /// breakpoint.
  ///
  /// If nothing is entered for this property, then the default [secondaryBody]
  /// is displayed in the slot. If null is entered for this slot, the slot stays
  /// empty.
  final Widget? smallSecondaryBody;

  /// Widget to be displayed in the secondaryBody slot at the middle breakpoint.
  ///
  /// The default displayed secondaryBody.
  final Widget? secondaryBody;

  /// Widget to be displayed in the seconaryBody slot at the smallest
  /// breakpoint.
  ///
  /// If nothing is entered for this property, then the default [secondaryBody]
  /// is displayed in the slot. If null is entered for this slot, the slot stays
  /// empty.
  final Widget? largeSecondaryBody;

  /// Defines the fractional ratio of body to the secondaryBody.
  ///
  /// For example 1 / 3 would mean body takes up 1/3 of the available space and
  /// secondaryBody takes up the rest.
  ///
  /// If this value is null, the ratio is defined so that the split axis is in
  /// the center of the screen.
  final double? bodyRatio;

  /// Must be of length 3. The list defining breakpoints for the
  /// [AdaptiveLayout] the breakpoint is active from the value at the index up
  /// until the value at the next index.
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

  /// Whether to orient the body and secondaryBody in horizontal order (true) or
  /// in vertical order (false).
  ///
  /// Defaults to true.
  final bool horizontalBody;

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

  Widget fadeOut(Widget child, AnimationController animation) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: ReverseAnimation(animation), curve: Curves.easeInCubic),
      child: child,
    );
  }
  @override
  Widget build(BuildContext context) {
    Widget? defaultWidget(Widget? primary, Widget? secondary) {
      return primary?.key == const Key('') ? secondary : primary;
    }

    List<Widget?>? bodyList = <Widget?>[defaultWidget(widget.smallBody, widget.body), widget.body, defaultWidget(widget.largeBody, widget.body)];
    List<Widget?>? secondaryBodyList = <Widget?>[defaultWidget(widget.smallSecondaryBody, widget.secondaryBody), widget.secondaryBody, defaultWidget(widget.largeSecondaryBody, widget.secondaryBody)];
    if(bodyList.every((Widget? e) => e==null)) {
      bodyList = null;
      }
    if(secondaryBodyList.every((Widget? e) => e==null)) {
      secondaryBodyList = null;
      }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: AdaptiveLayout(
        horizontalBody: widget.horizontalBody,
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
        body: _createSlotFromProperties(bodyList, 'body'),
        secondaryBody: _createSlotFromProperties(secondaryBodyList, 'secondaryBody'),
      ),
    );
  }

  SlotLayout? _createSlotFromProperties(List<Widget?>? list, String name) {
    return list != null
        ? SlotLayout(
            config: <int, SlotLayoutConfig?>{
              for (MapEntry<int, Widget?> entry in list.asMap().entries)
                if (entry.key == 0 || list[entry.key] != list[entry.key - 1])
                  widget.breakpoints[entry.key]: (entry.value != null)
                      ? SlotLayoutConfig(
                          key: Key('$name${entry.key}'),
                          inAnimation: fadeIn,
                          overtakeAnimation: fadeOut,
                          child: entry.value,
                        )
                      : null
            },
          )
        : null;
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
