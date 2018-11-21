import 'package:flutter/material.dart';
import 'package:flutter_gallery/welcome/step.dart';

class FlutterWelcomeStep extends WelcomeStep {
  FlutterWelcomeStep({TickerProvider tickerProvider})
      : super(tickerProvider: tickerProvider);

  @override
  String title() => 'Welcome to Flutter!';
  @override
  String subtitle() =>
      'Flutter is a mobile app SDK for building high-performance, high-fidelity, apps for iOS and Android.';

  @override
  Widget imageWidget() {
    return Image.asset(
      'assets/images/welcome/welcome_flutter_logo.png',
    );
  }

  @override
  void animate({bool restart}) {}
}
