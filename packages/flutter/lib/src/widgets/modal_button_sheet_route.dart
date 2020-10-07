import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'modal_button_sheet.dart';

// Route that defines the transition animation of the previous route when this
// one is closing
mixin RouteWithPreviousTransitionMixin<T> on Route<T> {
  Widget getPreviousRouteTransition(
    BuildContext context,
    Animation<double> secondAnimation,
    Widget child,
  );
}

// Route that allows the next route to define the animation transition of this route
// when the route appears back after the next one is popped
mixin AllowsRouteWithPreviousTransitionMixin<T> on PageRoute<T> {
  RouteWithPreviousTransitionMixin? _nextModalRoute;

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) {
    return super.canTransitionTo(nextRoute) ||
        (nextRoute is RouteWithPreviousTransitionMixin);
  }

  @override
  void didChangeNext(Route? nextRoute) {
    if (nextRoute is RouteWithPreviousTransitionMixin) {
      _nextModalRoute = nextRoute;
    }

    super.didChangeNext(nextRoute);
  }

  @override
  bool didPop(T result) {
    _nextModalRoute = null;
    return super.didPop(result);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (_nextModalRoute != null) {
      if (secondaryAnimation.isDismissed) {
        _nextModalRoute = null;
      } else {
        // Avoid default transition theme to animate when a new modal view is pushed
        final fakeSecondaryAnimation =
            Tween<double>(begin: 0, end: 0).animate(secondaryAnimation);

        final defaultTransition = super.buildTransitions(
            context, animation, fakeSecondaryAnimation, child);
        return _nextModalRoute!.getPreviousRouteTransition(
            context, secondaryAnimation, defaultTransition);
      }
    }
    return super.buildTransitions(
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}

const Duration _bottomSheetDuration = Duration(milliseconds: 400);

class _ModalBottomSheet<T> extends StatefulWidget {
  const _ModalBottomSheet({
    Key? key,
    this.closeProgressThreshold,
    required this.route,
    required this.secondAnimationController,
    this.bounce = false,
    this.expanded = false,
    this.enableDrag = true,
    required this.animationCurve,
    this.modalLabel,
  })  : assert(expanded != null),
        assert(enableDrag != null),
        super(key: key);

  final double? closeProgressThreshold;
  final ModalBottomSheetRoute<T> route;
  final bool expanded;
  final bool bounce;
  final bool enableDrag;
  final AnimationController? secondAnimationController;
  final Curve? animationCurve;
  final String? modalLabel;

  @override
  _ModalBottomSheetState<T> createState() => _ModalBottomSheetState<T>();
}

class _ModalBottomSheetState<T> extends State<_ModalBottomSheet<T>> {
  

  ScrollController? _scrollController;

  @override
  void initState() {
    widget.route.animation?.addListener(updateController);
    super.initState();
  }

  @override
  void dispose() {
    widget.route.animation?.removeListener(updateController);
    _scrollController?.dispose();
    super.dispose();
  }

  void updateController() {
    final animation = widget.route.animation;
    if (animation != null) {
      widget.secondAnimationController?.value = animation.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    final scrollController = PrimaryScrollController.of(context) ??
        (_scrollController ??= ScrollController());
    return ModalScrollController(
      controller: scrollController,
      child: Builder(
        builder: (context) => AnimatedBuilder(
          animation: widget.route._animationController!,
          child: widget.route.builder(context),
          builder: (BuildContext context, Widget? child) {
            // Disable the initial animation when accessible navigation is on so
            // that the semantics are added to the tree at the correct time.
            return Semantics(
              scopesRoute: true,
              namesRoute: true,
              label: widget.modalLabel,
              explicitChildNodes: true,
              child: ModalBottomSheet(
                expanded: widget.route.expanded,
                containerBuilder: widget.route.containerBuilder,
                animationController: widget.route._animationController!,
                shouldClose: widget.route._hasScopedWillPopCallback
                    ? () async {
                        final willPop = await widget.route.willPop();
                        return willPop != RoutePopDisposition.doNotPop;
                      }
                    : null,
                onClosing: () {
                  if (widget.route.isCurrent) {
                    Navigator.of(context)?.pop();
                  }
                },
                child: child!,
                enableDrag: widget.enableDrag,
                bounce: widget.bounce,
                scrollController: scrollController,
                animationCurve: widget.animationCurve,
              ),
            );
          },
        ),
      ),
    );
  }
}

class ModalBottomSheetRoute<T> extends PopupRoute<T>
    with RouteWithPreviousTransitionMixin<T> {
  ModalBottomSheetRoute({
    this.closeProgressThreshold,
    required this.containerBuilder,
    required this.builder,
    this.scrollController,
    this.barrierLabel,
    this.modalLabel,
    this.secondAnimationController,
    this.modalBarrierColor,
    this.isDismissible = true,
    this.enableDrag = true,
    required this.expanded,
    this.bounce = false,
    required this.animationCurve,
    this.duration,
    RouteSettings? settings,
  })  : assert(expanded != null),
        assert(isDismissible != null),
        assert(enableDrag != null),
        super(settings: settings);

  final double? closeProgressThreshold;
  final WidgetWithChildBuilder containerBuilder;
  final WidgetBuilder builder;
  final bool expanded;
  final bool bounce;
  final Color? modalBarrierColor;
  final bool isDismissible;
  final bool enableDrag;
  final ScrollController? scrollController;

  final Duration? duration;

  final AnimationController? secondAnimationController;
  final Curve? animationCurve;

  @override
  Duration get transitionDuration => duration ?? _bottomSheetDuration;

  @override
  bool get barrierDismissible => isDismissible;

  @override
  final String? barrierLabel;

  final String? modalLabel;

  @override
  Color get barrierColor => modalBarrierColor ?? const Color(0x00000000).withOpacity(0.35);
  
  AnimationController? _animationController;

  @override
  AnimationController createAnimationController() {
    assert(_animationController == null);
    assert(navigator?.overlay != null);
    _animationController = ModalBottomSheet.createAnimationController(
      navigator!.overlay!,
      duration: duration,
    );
    return _animationController!;
  }

  bool get _hasScopedWillPopCallback => hasScopedWillPopCallback;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    // By definition, the bottom sheet is aligned to the bottom of the page
    // and isn't exposed to the top padding of the MediaQuery.
    Widget bottomSheet = MediaQuery.removePadding(
      context: context,
      // removeTop: true,
      child: _ModalBottomSheet<T>(
        closeProgressThreshold: closeProgressThreshold,
        route: this,
        secondAnimationController: secondAnimationController,
        expanded: expanded,
        bounce: bounce,
        enableDrag: enableDrag,
        animationCurve: animationCurve,
      ),
    );
    return bottomSheet;
  }

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) =>
      nextRoute is ModalBottomSheetRoute;

  @override
  bool canTransitionFrom(TransitionRoute<dynamic> previousRoute) =>
      previousRoute is ModalBottomSheetRoute || previousRoute is PageRoute;

  Widget getPreviousRouteTransition(
    BuildContext context,
    Animation<double> secondAnimation,
    Widget child,
  ) {
    return child;
  }
}

/// Shows a modal material design bottom sheet.
Future<T> showCustomModalBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  required WidgetWithChildBuilder containerWidget,
  Color? barrierColor,
  bool bounce = false,
  bool expand = false,
  AnimationController? secondAnimation,
  Curve? animationCurve,
  bool useRootNavigator = false,
  bool isDismissible = true,
  bool enableDrag = true,
  Duration? duration,
  String? barrierLabel,
}) async {
  assert(context != null);
  assert(builder != null);
  assert(containerWidget != null);
  assert(expand != null);
  assert(useRootNavigator != null);
  assert(isDismissible != null);
  assert(enableDrag != null);
  assert(debugCheckHasMediaQuery(context));

  return await Navigator.of(context, rootNavigator: useRootNavigator)!
      .push(ModalBottomSheetRoute<T>(
    builder: builder,
    bounce: bounce,
    containerBuilder: containerWidget,
    secondAnimationController: secondAnimation,
    expanded: expand,
    barrierLabel: barrierLabel,
    isDismissible: isDismissible,
    modalBarrierColor: barrierColor,
    enableDrag: enableDrag,
    animationCurve: animationCurve,
    duration: duration,
  ));
}
