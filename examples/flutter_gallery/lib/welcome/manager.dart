import 'package:flutter_gallery/welcome/steps/playground_step.dart';

import 'step.dart';

class WelcomeManager {
  WelcomeManager() {
    _steps = _stepsList;
  }

  static List<WelcomeStep> _steps;

  List<WelcomeStep> steps() {
    return _steps;
  }

  final List<WelcomeStep> _stepsList = <WelcomeStep>[
    FlutterWelcomeStep(),
    PlaygroundWelcomeStep(),
    DocumentationWelcomeStep(),
    WidgetWelcomeStep(),
  ];
}
