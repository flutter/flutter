import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'sheet.dart';

/// Route that defines the transition animation of the previous route when this
/// one is closing
mixin RouteWithPreviousTransitionMixin<T> on Route<T> {
  Widget getPreviousRouteTransition(
    BuildContext context,
    Animation<double> secondAnimation,
    Widget child,
  );
}

/// Route that allows the next route to define the animation transition of this route
/// when the route appears back after the next one is popped
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
        final Animation<double> fakeSecondaryAnimation =
            Tween<double>(begin: 0, end: 0).animate(secondaryAnimation);

        final Widget defaultTransition = super.buildTransitions(
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

class _Sheet<T> extends StatefulWidget {
  const _Sheet({
    Key? key,
    required this.route,
    required this.secondAnimationController,
    this.bounce = false,
    this.expanded = false,
    this.enableDrag = true,
    required this.animationCurve,
    this.closeProgressThreshold,
    this.modalLabel,
  })  : assert(expanded != null),
        assert(enableDrag != null),
        super(key: key);

  final double? closeProgressThreshold;
  final SheetRoute<T> route;
  final bool expanded;
  final bool bounce;
  final bool enableDrag;
  final AnimationController? secondAnimationController;
  final Curve? animationCurve;
  final String? modalLabel;

  @override
  _SheetState<T> createState() => _SheetState<T>();
}

class _SheetState<T> extends State<_Sheet<T>> {
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
    final Animation<double>? animation = widget.route.animation;
    if (animation != null) {
      widget.secondAnimationController?.value = animation.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    final ScrollController scrollController =
        PrimaryScrollController.of(context) ??
            (_scrollController ??= ScrollController());
    print(widget.route._hasScopedWillPopCallback);
    return SheetController(
      scrollController: scrollController,
      shouldPreventClose: () => widget.route._hasScopedWillPopCallback,
      shouldClose: () async {
        final RoutePopDisposition willPop = await widget.route.willPop();
        return willPop != RoutePopDisposition.doNotPop;
      },
      animationController: widget.route._animationController!,
      onClose: () {
        if (widget.route.isCurrent) {
          Navigator.of(context)?.pop();
        }
      },
      child: Builder(
        builder: (BuildContext context) => Semantics(
          scopesRoute: true,
          namesRoute: true,
          label: widget.modalLabel,
          explicitChildNodes: true,
          child: Sheet(
            controller: SheetController.of(context)!,
            expanded: widget.route.expanded,

            child: widget.route.builder(context),
            enableDrag: widget.enableDrag,
            bounce: widget.bounce,
            animationCurve: widget.animationCurve,
          ),
        ),
      ),
    );
  }
}

class SheetRoute<T> extends PopupRoute<T>
    with RouteWithPreviousTransitionMixin<T> {
  SheetRoute({
    this.closeProgressThreshold,
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
    this.animationCurve,
    this.duration,
    RouteSettings? settings,
  })  : assert(expanded != null),
        assert(isDismissible != null),
        assert(enableDrag != null),
        super(settings: settings);

  final double? closeProgressThreshold;
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
  Color get barrierColor =>
      modalBarrierColor ?? const Color(0x00000000).withOpacity(0.35);

  AnimationController? _animationController;

  @override
  AnimationController createAnimationController() {
    assert(_animationController == null);
    assert(navigator?.overlay != null);
    _animationController = Sheet.createAnimationController(
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
    return MediaQuery.removePadding(
      context: context,
      // removeTop: true,
      child: _Sheet<T>(
        route: this,
        secondAnimationController: secondAnimationController,
        closeProgressThreshold: closeProgressThreshold,
        expanded: expanded,
        bounce: bounce,
        enableDrag: enableDrag,
        animationCurve: animationCurve,
      ),
    );
  }

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) =>
      nextRoute is SheetRoute;

  @override
  bool canTransitionFrom(TransitionRoute<dynamic> previousRoute) =>
      previousRoute is SheetRoute || previousRoute is PageRoute;

  @override
  Widget getPreviousRouteTransition(
      BuildContext context, Animation<double> secondAnimation, Widget child) {
    return child;
  }
}
