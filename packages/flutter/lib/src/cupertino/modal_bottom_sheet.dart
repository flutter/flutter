import 'package:flutter/cupertino.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Value extracted from the official sketch iOS UI kit
/// It is the top offset that will be displayed from previous route 
const double _kPreviousRouteVisibeOffset = 10.0;

/// Value extracted from the official sketch iOS UI kit
const Radius kCupertinoModalSheetTopRadius = Radius.circular(10.0);

/// Estimated Round corners for iPhone X, XR, 11, 11 Pro
/// https://kylebashour.com/posts/finding-the-real-iphone-x-corner-radius
const double _kDeviceFrameCorners = 38.5;

const Color _kModalBarrierColor = Color.fromRGBO(0, 0, 0, 0.12);

/// Wraps the child into a cupertino modal sheet appareance. This is used to
/// create a [ModalBottomSheetRoute].
///
/// Clip the child widget to rectangle with top rounded corners and adds
/// top padding and top safe area.
class _CupertinoSheetDecorationBuilder extends StatelessWidget {
  const _CupertinoSheetDecorationBuilder({
    Key? key,
    required this.child,
    required this.topRadius,
    this.backgroundColor,
  }) : super(key: key);

  /// The child contained by the modal sheet
  final Widget child;

  /// The color to paint behind the child
  final Color? backgroundColor;

  /// The top corners of this modal sheet are rounded by this Radius
  final Radius topRadius;

  @override
  Widget build(BuildContext context) {
    // This should be changed before merging the PR
    final BoxShadow shadow = BoxShadow(
        blurRadius: 10,
        color: CupertinoColors.black.withOpacity(0.12),
        spreadRadius: 5);
    final Color backgroundColor = this.backgroundColor ??
        CupertinoTheme.of(context).scaffoldBackgroundColor;
    return SafeArea(
      bottom: false,
      right: false,
      left: false,
      child: Padding(
        padding: const EdgeInsets.only(top: _kPreviousRouteVisibeOffset),
        child: Container(
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: backgroundColor,
            boxShadow: <BoxShadow>[shadow],
            borderRadius: BorderRadius.vertical(top: topRadius),
          ),
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: child,
          ),
        ),
      ),
    );
  }
}

Future<T> showCupertinoModalBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool useRootNavigator = false,
  Color? backgroundColor,
  bool expand = false,
  bool bounce = true,
  bool draggable = true,
  Radius topRadius = kCupertinoModalSheetTopRadius,
  double? closeProgressThreshold,
  Color? barrierColor,
  String? barrierLabel,
  bool? barrierDismissible,
  Color? transitionBackgroundColor,
  Curve? animationCurve,
  Curve? previousRouteAnimationCurve,
  Duration? duration,
  RouteSettings? settings,
}) async {
  assert(context != null);
  assert(builder != null);
  assert(expand != null);
  assert(useRootNavigator != null);
  assert(draggable != null);
  assert(debugCheckHasMediaQuery(context));

  return await Navigator.of(context, rootNavigator: useRootNavigator)!.push(
    _CupertinoModalBottomSheetRoute<T>(
      builder: builder,
      sheetBuilder:
          (BuildContext context, Animation<double> animation, Widget child) {
        return _CupertinoSheetDecorationBuilder(
          child: child,
          backgroundColor: backgroundColor,
          topRadius: topRadius,
        );
      },
      expanded: expand,
      bounce: bounce,
      enableDrag: draggable,
      closeProgressThreshold: closeProgressThreshold,
      barrierLabel: barrierLabel,
      modalBarrierColor: barrierColor,
      isDismissible: barrierDismissible ?? !expand,
      topRadius: topRadius,
      animationCurve: animationCurve,
      previousRouteAnimationCurve: previousRouteAnimationCurve,
      duration: duration,
      settings: settings,
      transitionBackgroundColor: transitionBackgroundColor,
    ),
  );
}

class _CupertinoModalBottomSheetRoute<T> extends ModalBottomSheetRoute<T> {
  _CupertinoModalBottomSheetRoute({
    required WidgetBuilder builder,
    required WidgetWithChildBuilder sheetBuilder,
    double? closeProgressThreshold,
    String? barrierLabel,
    AnimationController? secondAnimationController,
    Curve? animationCurve,
    Color? modalBarrierColor,
    bool bounce = true,
    bool isDismissible = true,
    bool enableDrag = true,
    required bool expanded,
    Duration? duration,
    RouteSettings? settings,
    ScrollController? scrollController,
    this.transitionBackgroundColor,
    this.topRadius = kCupertinoModalSheetTopRadius,
    this.previousRouteAnimationCurve,
  })  : assert(expanded != null),
        assert(isDismissible != null),
        assert(enableDrag != null),
        super(
          closeProgressThreshold: closeProgressThreshold,
          scrollController: scrollController,
          sheetBuilder: sheetBuilder,
          builder: builder,
          bounce: bounce,
          barrierLabel: barrierLabel,
          secondAnimationController: secondAnimationController,
          modalBarrierColor: modalBarrierColor ?? _kModalBarrierColor,
          isDismissible: isDismissible,
          enableDrag: enableDrag,
          expanded: expanded,
          settings: settings,
          animationCurve: animationCurve,
          duration: duration,
        );

  /// The top corners of this modal sheet are rounded by this Radius
  final Radius topRadius;

  /// Background color behind all routes. Black by default
  final Color? transitionBackgroundColor;

  /// Curve for second animation of previous route transition
  final Curve? previousRouteAnimationCurve;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final double paddingTop = MediaQuery.of(context)?.padding.top ?? 0;
    return AnimatedBuilder(
      animation: secondaryAnimation,
      child: child,
      builder: (BuildContext context, Widget? child) {
        final double progress = secondaryAnimation.value;
        final double scale = 1 - progress / 10;
        final double distanceWithScale = (paddingTop + _kPreviousRouteVisibeOffset) * 0.9;
        final Offset offset = Offset(0, progress * (paddingTop - distanceWithScale));
        return Transform.translate(
          offset: offset,
          child: Transform.scale(
            scale: scale,
            child: child,
            alignment: Alignment.topCenter,
          ),
        );
      },
    );
  }

  @override
  Widget getPreviousRouteTransition(BuildContext context,
      Animation<double> secondaryAnimation, Widget child) {
    return _CupertinoModalTransition(
       body: child,
      secondaryAnimation: secondaryAnimation,
      animationCurve: previousRouteAnimationCurve,
      topRadius: topRadius,
      backgroundColor: transitionBackgroundColor,
    );
  }
}

class _CupertinoModalTransition extends StatelessWidget {
  const _CupertinoModalTransition({
    Key? key,
    required this.secondaryAnimation,
    required this.body,
    required this.topRadius,
    this.backgroundColor,
    this.animationCurve,
  }) : super(key: key);

  final Widget body;

  final Animation<double> secondaryAnimation;
  final Radius topRadius;
  final Curve? animationCurve;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final double paddingTop = MediaQuery.of(context)?.padding.top ?? 0;

    final bool phoneWithRoundedCorners =
        defaultTargetPlatform == TargetPlatform.iOS && paddingTop > 20;
    final double startRoundCorner =
        phoneWithRoundedCorners ? _kDeviceFrameCorners : 0;

    final CurvedAnimation curvedAnimation = CurvedAnimation(
      parent: secondaryAnimation,
      curve: animationCurve ?? Curves.easeOut,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: AnimatedBuilder(
        animation: curvedAnimation,
        child: body,
        builder: (BuildContext context, Widget? child) {
          final double progress = curvedAnimation.value;
          final double yOffset = progress * paddingTop;
          final double scale = 1 - progress / 10;
          final double radius = progress == 0
              ? 0.0
              : (1 - progress) * startRoundCorner + progress * topRadius.x;
          return Stack(
            children: <Widget>[
              Container(color: backgroundColor ?? CupertinoColors.black),
              Transform.translate(
                offset: Offset(0, yOffset),
                child: Transform.scale(
                  scale: scale,
                  alignment: Alignment.topCenter,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(radius),
                    child: child,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
