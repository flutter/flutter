import 'package:flutter/cupertino.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

const double _behind_widget_visible_height = 10;

const Radius _default_top_radius = Radius.circular(12);

const double _deviceFrameCorners =
    38.5; //https://kylebashour.com/posts/finding-the-real-iphone-x-corner-radius

/// Cupertino Bottom Sheet Container
///
/// Clip the child widget to rectangle with top rounded corners and adds
/// top padding(+safe area padding). This padding [_behind_widget_visible_height]
/// is the height that will be displayed from previous route.
class _CupertinoBottomSheetContainer extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final Radius topRadius;

  const _CupertinoBottomSheetContainer(
      {Key? key,
      required this.child,
      this.backgroundColor,
      required this.topRadius})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final topSafeAreaPadding = MediaQuery.of(context)?.padding.top ?? 0;
    final topPadding = _behind_widget_visible_height + topSafeAreaPadding;

    final shadow = BoxShadow(
        blurRadius: 10,
        color: CupertinoColors.black.withOpacity(0.12),
        spreadRadius: 5);
    final _backgroundColor =
        backgroundColor ?? CupertinoTheme.of(context).scaffoldBackgroundColor;
    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: topRadius),
        child: Container(
          decoration:
              BoxDecoration(color: _backgroundColor, boxShadow: [shadow]),
          width: double.infinity,
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true, //Remove top Safe Area
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
  Color? backgroundColor,
  double? elevation,
  double? closeProgressThreshold,
  ShapeBorder? shape,
  Clip? clipBehavior,
  Color? barrierColor,
  bool expand = false,
  AnimationController? secondAnimation,
  Curve? animationCurve,
  Curve? previousRouteAnimationCurve,
  bool useRootNavigator = false,
  bool bounce = true,
  bool? isDismissible,
  bool enableDrag = true,
  Radius topRadius = _default_top_radius,
  Duration? duration,
  RouteSettings? settings,
  Color? transitionBackgroundColor,
  String? barrierLabel,
}) async {
  assert(context != null);
  assert(builder != null);
  assert(expand != null);
  assert(useRootNavigator != null);
  assert(enableDrag != null);
  assert(debugCheckHasMediaQuery(context));

  return await Navigator.of(context, rootNavigator: useRootNavigator)!.push(
    CupertinoModalBottomSheetRoute<T>(
        builder: builder,
        containerBuilder: (context, _, child) => _CupertinoBottomSheetContainer(
              child: child,
              backgroundColor: backgroundColor,
              topRadius: topRadius,
            ),
        secondAnimationController: secondAnimation,
        expanded: expand,
        closeProgressThreshold: closeProgressThreshold,
        barrierLabel: barrierLabel,
        bounce: bounce,
        isDismissible: isDismissible ?? !expand,
        modalBarrierColor:
            barrierColor ?? CupertinoColors.black.withOpacity(0.12),
        enableDrag: enableDrag,
        topRadius: topRadius,
        animationCurve: animationCurve,
        previousRouteAnimationCurve: previousRouteAnimationCurve,
        duration: duration,
        settings: settings,
        transitionBackgroundColor:
            transitionBackgroundColor ?? CupertinoColors.black),
  );
}

class CupertinoModalBottomSheetRoute<T> extends ModalBottomSheetRoute<T> {
  final Radius topRadius;
  final Curve? previousRouteAnimationCurve;

  // Background color behind all routes
  // Black by default
  final Color? transitionBackgroundColor;

  CupertinoModalBottomSheetRoute({
    required WidgetBuilder builder,
    required WidgetWithChildBuilder containerBuilder,
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
    this.topRadius = _default_top_radius,
    this.previousRouteAnimationCurve,
  })  : assert(expanded != null),
        assert(isDismissible != null),
        assert(enableDrag != null),
        super(
          closeProgressThreshold: closeProgressThreshold,
          scrollController: scrollController,
          containerBuilder: containerBuilder,
          builder: builder,
          bounce: bounce,
          barrierLabel: barrierLabel,
          secondAnimationController: secondAnimationController,
          modalBarrierColor: modalBarrierColor,
          isDismissible: isDismissible,
          enableDrag: enableDrag,
          expanded: expanded,
          settings: settings,
          animationCurve: animationCurve,
          duration: duration,
        );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final paddingTop = MediaQuery.of(context)?.padding.top ?? 0;
    final distanceWithScale =
        (paddingTop + _behind_widget_visible_height) * 0.9;
    final offsetY = secondaryAnimation.value * (paddingTop - distanceWithScale);
    final scale = 1 - secondaryAnimation.value / 10;
    return AnimatedBuilder(
      builder: (context, child) => Transform.translate(
        offset: Offset(0, offsetY),
        child: Transform.scale(
          scale: scale,
          child: child,
          alignment: Alignment.topCenter,
        ),
      ),
      child: child,
      animation: secondaryAnimation,
    );
  }

  @override
  Widget getPreviousRouteTransition(BuildContext context,
      Animation<double> secondaryAnimation, Widget child) {
    return _CupertinoModalTransition(
      secondaryAnimation: secondaryAnimation,
      body: child,
      animationCurve: previousRouteAnimationCurve,
      topRadius: topRadius,
      backgroundColor: transitionBackgroundColor ?? CupertinoColors.black,
    );
  }
}

class _CupertinoModalTransition extends StatelessWidget {
  final Animation<double> secondaryAnimation;
  final Radius topRadius;
  final Curve? animationCurve;
  final Color backgroundColor;

  final Widget body;

  const _CupertinoModalTransition({
    Key? key,
    required this.secondaryAnimation,
    required this.body,
    required this.topRadius,
    this.backgroundColor = CupertinoColors.black,
    this.animationCurve,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final paddingTop = MediaQuery.of(context)?.padding.top ?? 0;

    final phoneWithRoundedCorners = defaultTargetPlatform == TargetPlatform.iOS && paddingTop > 20;
    final startRoundCorner = phoneWithRoundedCorners ? _deviceFrameCorners : 0;

    final curvedAnimation = CurvedAnimation(
      parent: secondaryAnimation,
      curve: animationCurve ?? Curves.easeOut,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: AnimatedBuilder(
        animation: curvedAnimation,
        child: body,
        builder: (context, child) {
          final progress = curvedAnimation.value;
          final yOffset = progress * paddingTop;
          final scale = 1 - progress / 10;
          final radius = progress == 0
              ? 0.0
              : (1 - progress) * startRoundCorner + progress * topRadius.x;
          return Stack(
            children: <Widget>[
              Container(color: backgroundColor),
              Transform.translate(
                offset: Offset(0, yOffset),
                child: Transform.scale(
                  scale: scale,
                  alignment: Alignment.topCenter,
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(radius),
                      child: child),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CupertinoScaffold extends InheritedWidget {
  final AnimationController animation;

  final Radius topRadius;

  @override
  final Widget child;

  const _CupertinoScaffold(
      {Key? key,
      required this.animation,
      required this.child,
      required this.topRadius})
      : super(key: key, child: child);

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) {
    return false;
  }
}

//  This is can be removed once MaterialPageRoute suppors animated modals
class CupertinoScaffold extends StatefulWidget {
  static _CupertinoScaffold? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_CupertinoScaffold>();

  final Widget body;
  final Radius topRadius;
  final Color transitionBackgroundColor;

  const CupertinoScaffold({
    Key? key,
    required this.body,
    this.topRadius = _default_top_radius,
    this.transitionBackgroundColor = CupertinoColors.black,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _CupertinoScaffoldState();

  static Future<T> showCupertinoModalBottomSheet<T>({
    required BuildContext context,
    double? closeProgressThreshold,
    required WidgetBuilder builder,
    Curve? animationCurve,
    Curve? previousRouteAnimationCurve,
    Color? backgroundColor,
    Color? barrierColor,
    bool expand = false,
    bool useRootNavigator = false,
    bool bounce = true,
    bool? isDismissible,
    bool enableDrag = true,
    Duration? duration,
    RouteSettings? settings,
    String? barrierLabel,
  }) async {
    assert(context != null);
    assert(builder != null);
    assert(expand != null);
    assert(useRootNavigator != null);
    assert(enableDrag != null);
    assert(debugCheckHasMediaQuery(context));
    
    final scaffold = CupertinoScaffold.of(context)!;
    final topRadius = scaffold.topRadius;
    final result = await Navigator.of(context, rootNavigator: useRootNavigator)!
        .push(CupertinoModalBottomSheetRoute<T>(
      closeProgressThreshold: closeProgressThreshold,
      builder: builder,
      secondAnimationController: scaffold.animation,
      containerBuilder: (_, __, Widget child) => _CupertinoBottomSheetContainer(
        child: child,
        backgroundColor: backgroundColor,
        topRadius: topRadius,
      ),
      expanded: expand,
      barrierLabel: barrierLabel,
      bounce: bounce,
      isDismissible: isDismissible ?? !expand,
      modalBarrierColor:
          barrierColor ?? CupertinoColors.black.withOpacity(0.12),
      enableDrag: enableDrag,
      topRadius: topRadius,
      animationCurve: animationCurve,
      previousRouteAnimationCurve: previousRouteAnimationCurve,
      duration: duration,
      settings: settings,
    ));
    return result;
  }
}

class _CupertinoScaffoldState extends State<CupertinoScaffold>
    with TickerProviderStateMixin {
  late AnimationController animationController;

  SystemUiOverlayStyle? lastStyle;

  @override
  void initState() {
    animationController = AnimationController(
        duration: const Duration(milliseconds: 350), vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _CupertinoScaffold(
      animation: animationController,
      topRadius: widget.topRadius,
      child: _CupertinoModalTransition(
        secondaryAnimation: animationController,
        body: widget.body,
        topRadius: widget.topRadius,
        backgroundColor: widget.transitionBackgroundColor,
      ),
    );
  }
}
