import 'models.dart';

class WelcomeManager {
  WelcomeManager() {
    _steps = _stepsList;
  }

  static List<WelcomeStep> _steps;

  List<WelcomeStep> steps() {
    return _steps;
  }

  final List<WelcomeStep> _stepsList = [
    WelcomeStep(
      title: 'Welcome to Flutter',
      subtitle:
          'Flutter is a mobile app SDK for building high-performance, high-fidelity, apps for iOS and Android.',
      imageUris: [
        'assets/images/welcome_phones.png',
      ],
    ),
    WelcomeStep(
      title: 'Why use Flutter?',
      subtitle: 'Be highly productive by doing more with less code.',
      imageUris: [
        'assets/images/welcome_recipe.png',
      ],
    ),
    WelcomeStep(
      title: 'Everything\'s a Widget',
      subtitle: 'Widgets are the basic building blocks of every Flutter app.',
      imageUris: [
        'assets/images/welcome_pie.png',
        'assets/images/welcome_widget_1.png',
        'assets/images/welcome_widget_2.png',
        'assets/images/welcome_widget_3.png',
        'assets/images/welcome_widget_4.png',
      ],
    ),
    WelcomeStep(
      title: 'Explore Flutter!',
      subtitle:
          'Now that you’re familiar with the basic structure and principles of the Flutter framework, explore what it can do.',
      imageUris: [
        'assets/images/welcome_flutter_logo.png',
        'assets/images/welcome_widget_1.png',
        'assets/images/welcome_widget_2.png',
        'assets/images/welcome_widget_3.png',
        'assets/images/welcome_widget_4.png',
        'assets/images/welcome_widget_5.png',
      ],
    ),
  ];
}
