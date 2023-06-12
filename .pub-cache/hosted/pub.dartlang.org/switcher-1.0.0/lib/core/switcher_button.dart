import 'package:flutter/material.dart';

class SwitcherButton extends StatelessWidget {
  const SwitcherButton({
    Key? key,
    required this.value,
    required this.isSwitcherOn,
    required this.transitionColor,
    required this.iconOff,
    required this.iconOn,
    required this.switcherButtonIconSize,
  }) : super(key: key);

  final double value;
  final bool isSwitcherOn;
  final Color transitionColor;
  final IconData iconOn;
  final IconData iconOff;
  final double switcherButtonIconSize;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Opacity(
        opacity:
            isSwitcherOn ? value.clamp(0.0, 1.0) : (1 - value).clamp(0.0, 1.0),
        child: Icon(
          isSwitcherOn ? iconOn : iconOff,
          size: switcherButtonIconSize,
          color: transitionColor,
        ),
      ),
    );
  }
}
