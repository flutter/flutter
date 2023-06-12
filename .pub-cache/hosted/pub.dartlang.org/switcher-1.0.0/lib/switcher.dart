import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:switcher/core/switcher_body.dart';

import 'core/switcher_size.dart';

class Switcher extends StatefulWidget {
  @required
  final bool value;
  @required
  final SwitcherSize size;
  @required
  final Function(bool) onChanged;
  final Color colorOn;
  final Color colorOff;
  final Color switcherButtonColor;
  final double switcherRadius;
  final double switcherButtonRadius;
  final double switcherButtonAngleTransform;
  final bool enabledSwitcherButtonRotate;
  final BoxShape switcherButtonBoxShape;
  final Duration animationDuration;
  final IconData iconOn;
  final IconData iconOff;
  final Curve curveType;
  final Function? onTap;
  final Function? onDoubleTap;
  final Function? onSwipe;

  final double _width;
  final double _height;
  final Offset _switcherButtonOffset;
  final double _switcherButtonSize;
  final double _switcherButtonIconSize;
  final double _switcherButtonPadding;

  Switcher(
      {this.value = false,
      this.size = SwitcherSize.small,
      this.switcherButtonColor = Colors.white,
      this.switcherRadius = 50,
      this.switcherButtonRadius = 50,
      this.switcherButtonAngleTransform = 0,
      this.enabledSwitcherButtonRotate = true,
      this.switcherButtonBoxShape = BoxShape.circle,
      this.colorOn = Colors.blue,
      this.colorOff = Colors.black,
      this.iconOff = Icons.circle,
      this.iconOn = Icons.check,
      this.animationDuration = const Duration(milliseconds: 500),
      this.curveType = Curves.easeInOut,
      this.onTap,
      this.onDoubleTap,
      this.onSwipe,
      required this.onChanged})
      : _width = size == SwitcherSize.small
            ? 55
            : size == SwitcherSize.medium
                ? 80
                : 105,
        _height = size == SwitcherSize.small
            ? 20
            : size == SwitcherSize.medium
                ? 30
                : 40,
        _switcherButtonOffset = size == SwitcherSize.small
            ? switcherButtonBoxShape == BoxShape.rectangle
                ? Offset(36, 0.5)
                : switcherButtonRadius < 4
                    ? Offset(35, 0.3)
                    : Offset(34, 0.2)
            : size == SwitcherSize.medium
                ? switcherButtonBoxShape == BoxShape.rectangle
                    ? Offset(51, 0)
                    : switcherButtonRadius < 4
                        ? Offset(51, 0.5)
                        : Offset(50, 0.3)
                : switcherButtonBoxShape == BoxShape.rectangle
                    ? Offset(67, 1)
                    : switcherButtonRadius < 4
                        ? Offset(67, 0.5)
                        : Offset(65, 0.5),
        _switcherButtonSize = size == SwitcherSize.small
            ? switcherButtonBoxShape == BoxShape.rectangle
                ? 12
                : switcherButtonRadius < 4
                    ? 10
                    : 15
            : size == SwitcherSize.medium
                ? switcherButtonBoxShape == BoxShape.rectangle
                    ? 22
                    : switcherButtonRadius < 4
                        ? 17
                        : 25
                : size == SwitcherSize.large
                    ? switcherButtonBoxShape == BoxShape.rectangle
                        ? 28
                        : switcherButtonRadius < 4
                            ? 22
                            : 33
                    : 33,
        _switcherButtonIconSize = size == SwitcherSize.small
            ? switcherButtonBoxShape == BoxShape.rectangle
                ? 11
                : switcherButtonRadius < 4
                    ? 10
                    : 15
            : size == SwitcherSize.medium
                ? switcherButtonBoxShape == BoxShape.rectangle
                    ? 18
                    : switcherButtonRadius < 4
                        ? 15
                        : 21
                : size == SwitcherSize.large
                    ? switcherButtonBoxShape == BoxShape.rectangle
                        ? 24
                        : switcherButtonRadius < 4
                            ? 21
                            : 27
                    : 27,
        _switcherButtonPadding = size == SwitcherSize.small
            ? switcherButtonBoxShape == BoxShape.rectangle
                ? 4
                : switcherButtonRadius < 4
                    ? 5
                    : 2.5
            : size == SwitcherSize.medium
                ? switcherButtonBoxShape == BoxShape.rectangle
                    ? 4
                    : switcherButtonRadius < 4
                        ? 7
                        : 3
                : switcherButtonBoxShape == BoxShape.rectangle
                    ? 5
                    : switcherButtonRadius < 4
                        ? 9
                        : 4;

  @override
  _SwitcherState createState() => _SwitcherState();
}

class _SwitcherState extends State<Switcher>
    with SingleTickerProviderStateMixin {
  late AnimationController animationController;
  late Animation<double> animation;
  late bool turnState;
  double value = 0.0;
  late Color transitionColor;
  late double switcherRadius;
  late double switcherButtonAngleTransform;

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      vsync: this,
      lowerBound: 0.0,
      upperBound: 1.0,
      duration: widget.animationDuration,
    );
    animation =
        CurvedAnimation(parent: animationController, curve: widget.curveType);
    animationController.addListener(() {
      setState(() {
        value = animation.value;
      });
    });
    turnState = widget.value;
    _determine();
  }

  _action() {
    _determine(changeState: true);
  }

  _determine({bool changeState = false}) {
    setState(() {
      if (changeState) turnState = !turnState;
      (turnState)
          ? animationController.forward()
          : animationController.reverse();

      widget.onChanged(turnState);
    });
  }

  @override
  Widget build(BuildContext context) {
    transitionColor = getTransitionColor();
    switcherRadius = getSwitcherRadius();

    switcherButtonAngleTransform = getSwitcherButtonAngleTransform();

    return GestureDetector(
      onDoubleTap: () {
        _action();
        if (widget.onDoubleTap != null) {
          widget.onDoubleTap!();
        }
      },
      onTap: () {
        _action();
        if (widget.onTap != null) {
          widget.onTap!();
        }
      },
      onPanEnd: (details) {
        _action();
        if (widget.onSwipe != null) {
          widget.onSwipe!();
        }
      },
      child: SwitcherBody(
        value: value,
        width: widget._width,
        height: widget._height,
        iconOn: widget.iconOn,
        iconOff: widget.iconOff,
        switcherRadius: switcherRadius,
        transitionColor: transitionColor,
        switcherButtonSize: widget._switcherButtonSize,
        switcherButtonColor: widget.switcherButtonColor,
        switcherButtonRadius: widget.switcherButtonRadius,
        switcherButtonOffset: widget._switcherButtonOffset,
        switcherButtonPadding: widget._switcherButtonPadding,
        switcherButtonIconSize: widget._switcherButtonIconSize,
        switcherButtonAngleTransform: switcherButtonAngleTransform,
      ),
    );
  }

  Color getTransitionColor() {
    Color transitionColor = Color.lerp(widget.colorOff, widget.colorOn, value)!;
    return transitionColor;
  }

  double getSwitcherRadius() {
    double switcherRadius = widget.switcherButtonBoxShape == BoxShape.rectangle
        ? widget.switcherRadius > 5
            ? 5
            : widget.switcherRadius
        : widget.switcherRadius;
    return switcherRadius;
  }

  double getSwitcherButtonAngleTransform() {
    double switcherButtonAngleTransform = !widget.enabledSwitcherButtonRotate
        ? 6.28
        : widget.switcherButtonAngleTransform > 15
            ? 15
            : widget.switcherButtonAngleTransform < 0
                ? 0
                : widget.switcherButtonAngleTransform;
    return switcherButtonAngleTransform;
  }
}
