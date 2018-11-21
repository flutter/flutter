import 'package:flutter/material.dart';
import 'package:flutter_gallery/welcome/step.dart';

class PlaygroundWelcomeStep extends WelcomeStep {
  PlaygroundWelcomeStep({TickerProvider tickerProvider})
      : super(tickerProvider: tickerProvider);

  @override
  String title() => 'Interactive widget playground';
  @override
  String subtitle() => 'Explore the rich native UI widgets';

  @override
  Widget imageWidget() {
    return Image.asset(
      'assets/images/welcome/welcome_playground.png',
    );
  }

  @override
  void animate({bool restart}) {}
}
