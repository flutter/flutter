import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'sheet.dart';

// TODO: Arbitrary values, keep them or make SheetRoute abstract
const Duration _kSheetTransitionDuration = Duration(milliseconds: 400);
const Color _kBarrierColor = Color(0x59000000);


/// 
class SheetRoute<T> extends PopupRoute<T> with DefinesBottomRouteTransitionMixin<T> {
  
  SheetRoute({
    required this.builder,
    this.initialStop = 1,
    this.stops,
    this.draggable = true,
    this.expanded = true,
    this.bounceAtTop = false,
    this.animationCurve,
    this.duration,
    this.sheetLabel,
    this.barrierLabel,
    this.barrierColor = _kBarrierColor,
    this.barrierDismissible = true,
    RouteSettings? settings,
  }) : super(settings: settings);

  final WidgetBuilder builder;

  final double initialStop;

  final List<double>? stops;

  final bool expanded;

  final bool bounceAtTop;

  final bool draggable;

  final Duration? duration;

  final Curve? animationCurve;

  @override
  Duration get transitionDuration => duration ?? _kSheetTransitionDuration;

  final String? sheetLabel;

  @override
  final bool barrierDismissible;

  @override
  final Color? barrierColor;

  @override
  final String? barrierLabel;

  AnimationController? _routeAnimationController;
  AnimationController? _sheetAnimationController;

  Animation<double>? get sheetAnimation => _sheetAnimationController;

  @override
  AnimationController createAnimationController() {
    assert(_routeAnimationController == null);
    assert(navigator?.overlay != null);
    _routeAnimationController = SnapSheet.createAnimationController(
      navigator!.overlay!,
      duration: duration,
    );
    _sheetAnimationController = SnapSheet.createAnimationController(
      navigator!.overlay!,
      duration: duration,
    );
    return _routeAnimationController!;
  }

  @override
  void dispose() {
    _sheetAnimationController?.dispose();
    super.dispose();
  }

  bool get _hasScopedWillPopCallback => hasScopedWillPopCallback;

  @override
  Widget buildPage(
      BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return _DefaultSheetRouteController<T>(
      route: this,
      child: Builder(
        builder: (BuildContext context) {
          return Semantics(
            scopesRoute: true,
            namesRoute: true,
            label: sheetLabel,
            explicitChildNodes: true,
            child: SnapSheet(
              controller: DefaultSheetController.of(context)!,
              expanded: expanded,
              child: builder(context),
              draggable: draggable,
              bounceAtTop: bounceAtTop,
            ),
          );
        },
      ),
    );
  }

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) => nextRoute is SheetRoute;

  @override
  bool canTransitionFrom(TransitionRoute<dynamic> previousRoute) =>
      previousRoute is SheetRoute || previousRoute is PageRoute;

  @override
  Widget getBottomRouteTransition(
      BuildContext context, Animation<double> secondAnimation, Widget child) {
    return child;
  }
}

/// A page that creates a material style [PageRoute].
///
/// {@macro flutter.material.materialRouteTransitionMixin}
///
/// By default, when the created route is replaced by another, the previous
/// route remains in memory. To free all the resources when this is not
/// necessary, set [maintainState] to false.
///
/// The `fullscreenDialog` property specifies whether the created route is a
/// fullscreen modal dialog. On iOS, those routes animate from the bottom to the
/// top rather than horizontally.
///
/// The type `T` specifies the return type of the route which can be supplied as
/// the route is popped from the stack via [Navigator.transitionDelegate] by
/// providing the optional `result` argument to the
/// [RouteTransitionRecord.markForPop] in the [TransitionDelegate.resolve].
///
/// See also:
///
///  * [MaterialPageRoute], which is the [PageRoute] version of this class
class SheetPage<T> extends Page<T> {
  /// Creates a material page.
  const SheetPage({
    required this.child,
    this.maintainState = true,
    LocalKey? key,
    String? name,
    Object? arguments,
  })  : assert(child != null),
        assert(maintainState != null),
        super(key: key, name: name, arguments: arguments);

  /// The content to be shown in the [Route] created by this page.
  final Widget child;

  /// {@macro flutter.widgets.modalRoute.maintainState}
  final bool maintainState;

  @override
  Route<T> createRoute(BuildContext context) {
    return _PageBasedSheetRoute<T>(page: this);
  }
}

// A page-based version of SheetRoute.
//
// This route uses the builder from the page to build its content. This ensures
// the content is up to date after page updates.
class _PageBasedSheetRoute<T> extends SheetRoute<T> {
  _PageBasedSheetRoute({
    required SheetPage<T> page,
    Color? barrierColor,
    bool bounceAtTop = false,
    bool expanded = false,
    Curve? animationCurve,
    bool barrierDismissible = true,
    bool enableDrag = true,
    Duration? duration,
    List<double>? stops,
    double initialStop = 1,
  })  : assert(page != null),
        super(
          settings: page,
          builder: (BuildContext context) => page.child,
          bounceAtTop: bounceAtTop,
          expanded: expanded,
          stops: stops,
          initialStop: initialStop,
          barrierDismissible: barrierDismissible,
          barrierColor: barrierColor,
          draggable: enableDrag,
          animationCurve: animationCurve,
          duration: duration,
        );

  SheetPage<T> get _page => settings as SheetPage<T>;

  @override
  bool get maintainState => _page.maintainState;

  @override
  String get debugLabel => '${super.debugLabel}(${_page.name})';
}


/// Creates a DefaultSheetController syncronized with the AnimationController from
/// SheetRoute
class _DefaultSheetRouteController<T> extends StatefulWidget {
  const _DefaultSheetRouteController({
    Key? key,
    required this.route,
    required this.child,
  }) : super(key: key);

  final SheetRoute<T> route;

  final Widget child;

  @override
  _DefaultSheetRouteControllerState<T> createState() => _DefaultSheetRouteControllerState<T>();
}

class _DefaultSheetRouteControllerState<T> extends State<_DefaultSheetRouteController<T>>
    with SingleTickerProviderStateMixin {
  late SheetController _controller;

  @override
  void initState() {
    _controller = WillPopSheetController(
      controller: widget.route._sheetAnimationController!,
      animationCurve: widget.route.animationCurve,
      stops: widget.route.stops ?? <double>[0, 1],
      hasScopedWillPopCallback: () => widget.route._hasScopedWillPopCallback,
      willPop: () async {
        final RoutePopDisposition willPop = await widget.route.willPop();
        return willPop != RoutePopDisposition.doNotPop;
      },
      onPop: () {
        if (widget.route.isCurrent) {
          Navigator.of(context)?.pop();
        }
      },
    );
    widget.route._routeAnimationController?.addListener(onRouteAnimationUpdate);
    widget.route._sheetAnimationController?.addListener(onSheetAnimationUpdate);
    super.initState();
  }

  @override
  void dispose() {
    widget.route._routeAnimationController?.removeListener(onRouteAnimationUpdate);
    widget.route._sheetAnimationController?.removeListener(onSheetAnimationUpdate);
    _controller.dispose();
    super.dispose();
  }

  AnimationController get routeAnimationController => widget.route._routeAnimationController!;
  AnimationController get sheetAnimationController => widget.route._sheetAnimationController!;

  bool get dismissUnderway => routeAnimationController.status == AnimationStatus.reverse;
  double? lastPositionBeforeDismiss;

  void onRouteAnimationUpdate() {
    double newValue;
    // If dismiss is underway we animate the sheet from the last known position
    // Otherwise we will animate to the initialStop
    if (dismissUnderway) {
      lastPositionBeforeDismiss ??= sheetAnimationController.value;
      newValue =
          _mapDoubleInRange(routeAnimationController.value, 0, 1, 0, lastPositionBeforeDismiss!);
    } else {
      newValue =
          _mapDoubleInRange(routeAnimationController.value, 0, 1, 0, widget.route.initialStop);
    }
    if (sheetAnimationController.value != newValue) {
      sheetAnimationController.value = newValue;
    }
  }

  void onSheetAnimationUpdate() {
    if (dismissUnderway) {
      return;
    }
    final double clampedValue = sheetAnimationController.value.clamp(0, widget.route.initialStop);
    final double newValue = _mapDoubleInRange(clampedValue, 0, widget.route.initialStop, 0, 1);
    if (routeAnimationController.value != newValue) {
      routeAnimationController.value = newValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    return DefaultSheetController(
      controller: _controller,
      child: widget.child,
    );
  }
}

/// Re-maps a number from one range to another.
///
/// A value of fromLow would get mapped to toLow, a value of
/// fromHigh to toHigh, values in-between to values in-between, etc
double _mapDoubleInRange(
    double value, double fromLow, double fromHigh, double toLow, double toHigh) {
  final double offset = toLow;
  final double ratio = (toHigh - toLow) / (fromHigh - fromLow);
  return ratio * (value - fromLow) + offset;
}
