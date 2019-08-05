import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' show Colors;
import 'colors.dart';

class ContextMenu extends StatefulWidget {
  ContextMenu({
    Key key,
    this.child,
  }) : super(key: key);

  final Widget child;

  @override
  ContextMenuState createState() => ContextMenuState();
}

class ContextMenuState extends State<ContextMenu> with TickerProviderStateMixin {
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

  @override
  void _dispose(AnimationStatus status) {
    _controller.stop();
    _controller.reset();
    _scale = null;
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
    final maskColor = _isMasked ? _lightModeMaskColor : Color(0xFFFFFFFF);

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
