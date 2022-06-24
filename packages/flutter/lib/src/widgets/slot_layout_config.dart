import 'package:flutter/material.dart';

/// The [SlotLayoutConfig] Widget is just responbile for holding a Widget and its
/// associated animation and taking a controller from SlotLayout then displaying
/// the child accordingly.
// ignore: must_be_immutable
class SlotLayoutConfig extends StatefulWidget {
  SlotLayoutConfig({
    required this.child,
    this.controller,
    this.animation,
    super.key,
  });
  final Widget child;
  final Function(AnimationController?, Widget)? animation;
  AnimationController? controller;

  @override
  State<SlotLayoutConfig> createState() => _SlotLayoutConfigState();
}

class _SlotLayoutConfigState extends State<SlotLayoutConfig> {
  @override
  Widget build(BuildContext context) {
    return (widget.animation != null && widget.controller != null)
        ? widget.animation!(widget.controller, widget.child) as Widget
        : widget.child;
  }
}
