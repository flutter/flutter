import 'package:flutter/material.dart';

class WindowSettings {
  WindowSettings(
      {this.regularSize = const Size(400, 300),
      this.floatingRegularSize = const Size(300, 300),
      this.dialogSize = const Size(300, 250),
      this.satelliteSize = const Size(150, 300),
      this.popupSize = const Size(200, 200),
      this.tipSize = const Size(140, 140),
      this.anchorToWindow = false,
      this.anchorRect = const Rect.fromLTWH(0, 0, 1000, 1000)});
  final Size regularSize;
  final Size floatingRegularSize;
  final Size dialogSize;
  final Size satelliteSize;
  final Size popupSize;
  final Size tipSize;
  final Rect anchorRect;
  final bool anchorToWindow;
}
