import 'package:flutter/animation.dart';

void main() {
  final animationController = AnimationController();
  // This should become:
  // `final animation = animationController.drive(CurveTween(curve: Curves.easeIn));`
  // or
  // `final animation = CurveTween(curve: Curves.easeIn).animate(animationController);`
  // but the data-driven fix isn't implemented yet.
  final animation = CurvedAnimation(
    parent: animationController,
    curve: Curves.easeIn,
    reverseCurve: Curves.easeIn,
  );
}
