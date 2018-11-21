import 'package:flutter/material.dart';
import 'package:flutter_gallery/welcome/step.dart';

class FlutterWelcomeStep extends WelcomeStep {
  @override
  String title() => 'Welcome to Flutter!';
  @override
  String subtitle() => 'Flutter is a mobile app SDK for building high-performance, high-fidelity, apps for iOS and Android.';

  @override
  List<String> imageUris() => <String>[
        'assets/images/welcome_phones.png',
      ];

  @override
  Widget imageWidget() {
    // TODO: implement imageWidget
    return null;
  }
}


class PlaygroundWelcomeStep extends WelcomeStep {
  @override
  String title() => 'Interactive widget playground';
  @override
  String subtitle() => 'Explore the rich native UI widgets';

  @override
  List<String> imageUris() => <String>[
        'assets/images/welcome_phones.png',
      ];

  @override
  Widget imageWidget() {
    // TODO: implement imageWidget
    return null;
  }
}

class DocumentationWelcomeStep extends WelcomeStep {
  @override
  String title() => 'Complete, flexible APIs';
  @override
  String subtitle() => 'View full API documentation';

  @override
  List<String> imageUris() => <String>[
        'assets/images/welcome_phones.png',
      ];

  @override
  Widget imageWidget() {
    // TODO: implement imageWidget
    return null;
  }
}

class WidgetWelcomeStep extends WelcomeStep {
  @override
  String title() => 'Everything\'s a Widget';
  @override
  String subtitle() => 'Widgets are the basic building blocks of every Flutter app.';

  @override
  List<String> imageUris() => <String>[
                'assets/images/welcome_pie.png',
        'assets/images/welcome_widget_1.png',
        'assets/images/welcome_widget_2.png',
        'assets/images/welcome_widget_3.png',
        'assets/images/welcome_widget_4.png',
      ];

  @override
  Widget imageWidget() {
    // TODO: implement imageWidget
    return null;
  }
}
