import 'package:flutter/animation.dart';

void main() {
  final animationController = AnimationController();
  final animation = CurvedAnimation(
    parent: animationController,
    curve: Curves.easeIn,
    reverseCurve: Curves.easeOut,
  );
}
