import 'package:flutter/widgets.dart';

void main() {
  // Change made in https://github.com/flutter/flutter/pull/177895
  SizeTransition();
  SizeTransition(axisAlignment: 1.0);
  SizeTransition(axis: Axis.vertical, axisAlignment: 1.0);
  SizeTransition(
    axis: Axis.vertical,
    axisAlignment: position.dx < 0 ? 1.0 : -1.0,
  );
  SizeTransition(axis: Axis.horizontal, axisAlignment: 1.0);
}
