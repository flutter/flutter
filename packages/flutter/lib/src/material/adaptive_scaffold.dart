import 'adaptive_layout.dart';
import 'slot_layout.dart';
import 'slot_layout_config.dart';
import 'navigation_bar.dart';
import 'package:flutter/widgets.dart';

class AdaptiveScaffold extends StatefulWidget {
  const AdaptiveScaffold({
    this.destinations,
    this.selectedIndex,
    this.body,
    this.secondaryBody,
    this.bodyRatio,
    this.breakpoints = const [0, 480, 1024],
    this.displayAnimations = true,
    super.key,
  });

  final List<NavigationDestination>? destinations;
  final int? selectedIndex;
  final List<Widget?>? body;
  final List<Widget?>? secondaryBody;
  final double? bodyRatio;
  final List<int> breakpoints;
  final bool displayAnimations;

  @override
  State<AdaptiveScaffold> createState() => _AdaptiveScaffoldState();
}

AnimatedWidget bottomToTop(child, animation) {
  return SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(animation),
    child: child,
  );
}

AnimatedWidget topToBottom(child, animation) {
  return SlideTransition(
    position: Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, 1),
    ).animate(animation),
    child: child,
  );
}

AnimatedWidget leftOutIn(child, animation) {
  return SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(-1, 0),
      end: Offset.zero,
    ).animate(animation),
    child: child,
  );
}

AnimatedWidget leftInOut(child, animation) {
  return SlideTransition(
    position: Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-1, 0),
    ).animate(animation),
    child: child,
  );
}

AnimatedWidget rightOutIn(Widget child, animation) {
  return SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(animation),
    child: child,
  );
}

FadeTransition fadeIn(Widget child, animation) {
  return FadeTransition(
    opacity: CurvedAnimation(parent: animation, curve: Curves.easeInCubic),
    child: child,
  );
}

class _AdaptiveScaffoldState extends State<AdaptiveScaffold> {
  @override
  Widget build(BuildContext context) {
    Widget Function(Widget, AnimationController?)? inAnimation0 = (widget.secondaryBody == null || widget.secondaryBody![0] == null && widget.displayAnimations) ? fadeIn : null;
    Widget Function(Widget, AnimationController?)? inAnimation1 = (widget.secondaryBody == null || widget.secondaryBody![1] == null && widget.displayAnimations) ? fadeIn : null;
    Widget Function(Widget, AnimationController?)? inAnimation2 = (widget.secondaryBody == null || widget.secondaryBody![2] == null && widget.displayAnimations) ? fadeIn : null;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: AdaptiveLayout(
        bodyRatio: widget.bodyRatio,
        bodyAnimated: widget.displayAnimations,
        primaryNavigation: widget.destinations != null && widget.selectedIndex != null
            ? SlotLayout(
                config: {
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
                config: {
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
        body: widget.body != null
            ? SlotLayout(
                config: {
                  if (widget.body![0] != null) widget.breakpoints[0]: SlotLayoutConfig(inAnimation: inAnimation0, key: const Key('body0'), child: widget.body![0]!),
                  if (widget.body![1] != null) widget.breakpoints[1]: SlotLayoutConfig(inAnimation: inAnimation1, key: const Key('body1'), child: widget.body![1]!),
                  if (widget.body![2] != null) widget.breakpoints[2]: SlotLayoutConfig(inAnimation: inAnimation2, key: const Key('body2'), child: widget.body![2]!),
                },
              )
            : null,
        secondaryBody: widget.secondaryBody != null
            ? SlotLayout(
                config: {
                  if (widget.secondaryBody![0] != null) widget.breakpoints[0]: SlotLayoutConfig(key: const Key('sbody0'), child: widget.secondaryBody![0]!),
                  if (widget.secondaryBody![1] != null) widget.breakpoints[1]: SlotLayoutConfig(key: const Key('sbody1'), child: widget.secondaryBody![1]!),
                  if (widget.secondaryBody![2] != null) widget.breakpoints[2]: SlotLayoutConfig(key: const Key('sbody2'), child: widget.secondaryBody![2]!),
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
