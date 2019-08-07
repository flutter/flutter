import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';
import 'package:flutter/painting.dart' show MatrixUtils;
import 'package:vector_math/vector_math_64.dart';
import 'route.dart';

// The scale of the child at the time that the ContextMenu opens.
const double _kOpenScale = 1.2;

/// A full-screen menu that can be activated for the given child.
///
/// Long pressing or 3d touching on the child will open in up in a full-screen
/// overlay menu.
// TODO(justinmc): Set up type param here for return value.
class ContextMenu extends StatefulWidget {
  /// Create a context menu.
  const ContextMenu({
    Key key,
    this.child,
  }) : super(key: key);

  /// The widget that can be opened in a ContextMenu.
  ///
  /// This widget will be displayed at its normal position in the widget tree,
  /// but long pressing or 3d touching on it will cause the ContextMenu to open.
  final Widget child;

  @override
  _ContextMenuState createState() => _ContextMenuState();
}

class _ContextMenuState extends State<ContextMenu> with TickerProviderStateMixin {
  // TODO(justinmc): Replace with real system colors when dark mode is
  // supported for iOS.
  //static const Color _darkModeMaskColor = Color(0xAAFFFFFF);
  static const Color _lightModeMaskColor = Color(0xAAAAAAAA);

  final GlobalKey _childGlobalKey = GlobalKey();

  Animation<Matrix4> _transform;
  AnimationController _controller;
  double _scaleStart;
  // TODO(justinmc): Get mask flash working again.
  bool _isMasked = false;
  bool _isOpen = false;

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _controller.addStatusListener(_onAnimationChangeStatus);
    super.initState();
  }

  void _onAnimationChangeStatus(AnimationStatus animationStatus) {
    if (animationStatus == AnimationStatus.completed) {
      _openContextMenu();
    }
  }

  void _onTapDown(TapDownDetails details) {
    _transform = Tween<Matrix4>(
      begin: Matrix4.identity(),
      // todo(justinmc): make end centered instead of using alignment.
      end: Matrix4.identity()..scale(_kOpenScale),//..translate(-100.0),
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInBack,
      ),
    );
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _openContextMenu() async {
    setState(() {
      _isOpen = true;
    });

    // Get the current position of the child
    assert(_childGlobalKey.currentContext != null);
    final RenderBox renderBox = _childGlobalKey.currentContext.findRenderObject();
    final Container container = _childGlobalKey.currentContext.widget;
    final Offset offset = renderBox.localToGlobal(renderBox.paintBounds.topLeft);
    final Rect originalRect = offset & renderBox.paintBounds.size;
    //final Rect rect = MatrixUtils.transformRect(_transform.value, originalRect);
    Vector4 sizeVector = _transform.value.transform(Vector4(originalRect.width, originalRect.height, 0, 0));
    final Rect rect = Rect.fromLTWH(
      originalRect.left,
      originalRect.top,
      sizeVector.x,
      sizeVector.y,
    );

    await Navigator.of(context, rootNavigator: true).push(
      _ContextMenuRoute<void>(
        barrierLabel: 'Dismiss',
        filter: ui.ImageFilter.blur(
          sigmaX: 5.0,
          sigmaY: 5.0,
        ),
        rect: rect,
        builder: (BuildContext context) {
          return container.child;
        },
      ),
    );

    // TODO(justinmc): This happens when the transition starts and the child is
    // still in the scene.  Should happen when the transition ends.
    setState(() {
      _isOpen = false;
    });
  }

  @override
  void dispose() {
    _controller.stop();
    _controller.reset();
    _transform = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      child: AnimatedBuilder(
        builder: _buildAnimation,
        animation: _controller,
      ),
    );
  }

  Widget _buildAnimation(BuildContext context, Widget child) {
    final Color maskColor = _isMasked ? _lightModeMaskColor : const Color(0xFFFFFFFF);

    return Transform(
      transform: _transform?.value ?? Matrix4.identity(),
      child: ShaderMask(
        shaderCallback: (Rect bounds) {
          return LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[maskColor, maskColor],
          ).createShader(bounds);
        },
        child: Opacity(
          opacity: _isOpen ? 0.0 : 1.0,
          // TODO(justinmc): Maybe get rid of Container and put key on Opacity.
          child: Container(
            key: _childGlobalKey,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

// The open context menu.
class _ContextMenuRoute<T> extends PopupRoute<T> {
  _ContextMenuRoute({
    this.barrierLabel,
    this.builder,
    ui.ImageFilter filter,
    RouteSettings settings,
    Rect rect,
  }) : _rect = rect,
       super(
         filter: filter,
         settings: settings,
       );

  // The rect containing the widget that should show in the ContextMenu.
  final Rect _rect;

  // Barrier color for a Cupertino modal barrier.
  static const Color _kModalBarrierColor = Color(0x6604040F);
  // The duration of the transition used when a modal popup is shown.
  static const Duration _kModalPopupTransitionDuration = Duration(milliseconds: 1335);

  final WidgetBuilder builder;

  @override
  final String barrierLabel;

  @override
  Color get barrierColor => _kModalBarrierColor;

  @override
  bool get barrierDismissible => true;

  @override
  bool get semanticsDismissible => false;

  @override
  Duration get transitionDuration => _kModalPopupTransitionDuration;

  Animation<double> _animation;

  Tween<Offset> _offsetTween;
  Tween<double> _scaleTween;

  @override
  Animation<double> createAnimation() {
    assert(_animation == null);
    _animation = CurvedAnimation(
      parent: super.createAnimation(),

      // These curves were initially measured from native iOS horizontal page
      // route animations and seemed to be a good match here as well.
      curve: Curves.linearToEaseOut,
      reverseCurve: Curves.linearToEaseOut.flipped,
    );
    _offsetTween = Tween<Offset>(
      begin: _rect.topLeft,
      // TODO(justinmc): Should end such that bottom of child is at center of
      // screen vertically.
      end: _rect.topLeft + const Offset(-100.0, -100.0),
    );
    _scaleTween = Tween<double>(
      begin: _kOpenScale,
      // TODO(justinmc): Should end so that it fits inside top of screen with
      // padding. Maybe add this padding to Stack.
      end: _kOpenScale + 1.5,
    );
    return _animation;
  }

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return Stack(
      children: <Widget>[
        builder(context),
      ],
    );
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    final Offset offset = _offsetTween.evaluate(_animation);
    return Transform(
      transform: Matrix4.identity()..translate(offset.dx, offset.dy)..scale(_scaleTween.evaluate(_animation)),
      child: child,
    );
  }
}
