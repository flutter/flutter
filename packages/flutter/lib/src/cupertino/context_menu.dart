import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';
import 'route.dart';

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

  Animation<double> _scale;
  AnimationController _controller;
  Matrix4 _transform = Matrix4.identity();
  double _scaleStart;
  bool _isMasked = false;

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
    _scale = Tween<double>(
      begin: 1.0,
      end: 1.2,
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

  void _openContextMenu() {
    showCupertinoModalPopup<void>(
      context: context,
      filter: ui.ImageFilter.blur(
        sigmaX: 5.0,
        sigmaY: 5.0,
      ),
      builder: (BuildContext context) {
        return const Text('TODO render context menu items and animate in correctly');
      },
    );
  }

  @override
  void dispose() {
    _controller.stop();
    _controller.reset();
    _scale = null;
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
      alignment: FractionalOffset.center,
      transform: Matrix4.identity()..scale(_scale?.value ?? 1.0),
      child: ShaderMask(
        shaderCallback: (Rect bounds) {
          return LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[maskColor, maskColor],
          ).createShader(bounds);
        },
        child: widget.child,
      ),
    );
  }
}
