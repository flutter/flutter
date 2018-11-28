import 'package:flutter/material.dart';
import '../constants.dart';

typedef StepImageBuilder = Widget Function();

class StepContainer extends StatelessWidget {

  const StepContainer({ @required this.title, @required this.subtitle, @required this.imageContentBuilder });

  final String title;
  final String subtitle;
  final StepImageBuilder imageContentBuilder;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kWelcomeBlue,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              height: 240.0,
              child: imageContentBuilder(),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 50.0),
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'GoogleSans',
                  fontSize: 24.0,
                  color: Colors.white,
                  height: 0.8,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 16.0,
                  color: Colors.white70,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
