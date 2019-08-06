import 'package:flutter/material.dart';

class CullOpacityPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _CullOpacityPageState();
}

class _CullOpacityPageState extends State<CullOpacityPage> with SingleTickerProviderStateMixin {
  Animation<double> _offsetY;
  AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _offsetY = Tween<double>(begin: 0, end: -1000.0).animate(_controller)..addListener((){
      setState(() {});
    });
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: List<Widget>.generate(50, (int i) => Positioned(
      left: 0,
      top: (200 * i).toDouble() + _offsetY.value,
      child: Opacity(
        opacity: 0.5,
        child: RepaintBoundary(
          child: Container(
            // Slightly change width to invalidate raster cache.
            width: 1000 - (_offsetY.value / 100),
            height: 100, color: Colors.red,
          ),
        ),
      ),
    )));
  }
}
