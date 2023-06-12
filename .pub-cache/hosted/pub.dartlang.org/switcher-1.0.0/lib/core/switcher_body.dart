import 'package:flutter/material.dart';

import 'switcher_button_transform.dart';

class SwitcherBody extends StatelessWidget {
  const SwitcherBody({
    Key? key,
    required this.value,
    required this.width,
    required this.height,
    required this.iconOn,
    required this.iconOff,
    required this.switcherRadius,
    required this.transitionColor,
    required this.switcherButtonSize,
    required this.switcherButtonColor,
    required this.switcherButtonRadius,
    required this.switcherButtonOffset,
    required this.switcherButtonPadding,
    required this.switcherButtonIconSize,
    required this.switcherButtonAngleTransform,
  }) : super(key: key);

  final double value;
  final double width;
  final double height;
  final IconData iconOn;
  final IconData iconOff;
  final double switcherRadius;
  final Color transitionColor;
  final double switcherButtonSize;
  final Color switcherButtonColor;
  final double switcherButtonRadius;
  final Offset switcherButtonOffset;
  final double switcherButtonPadding;
  final double switcherButtonIconSize;
  final double switcherButtonAngleTransform;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(switcherButtonPadding),
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: transitionColor,
        borderRadius: BorderRadius.circular(switcherRadius),
      ),
      child: Stack(
        children: <Widget>[
          SwitcherButtonTransform(
            value: value,
            iconOn: iconOn,
            transitionColor: transitionColor,
            switcherButtonSize: switcherButtonSize,
            switcherButtonRadius: switcherButtonRadius,
            switcherButtonOffset: switcherButtonOffset,
            switcherButtonIconSize: switcherButtonIconSize,
            switcherButtonAngleTransform: switcherButtonAngleTransform,
            iconOff: iconOff,
            switcherButtonColor: switcherButtonColor,
          )
        ],
      ),
    );
  }
}
