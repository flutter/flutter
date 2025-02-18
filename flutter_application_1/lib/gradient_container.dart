import 'package:flutter_application_1/centered.dart';
import 'package:flutter/material.dart';

class GradientContainer extends StatelessWidget {
GradientContainer(this.startAlignment, this.endAlignment, {super.key});
  Alignment startAlignment;
  Alignment endAlignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: startAlignment,
          end: endAlignment,
          colors: <Color>[
            Color.fromARGB(255, 26, 2, 80),
            Color.fromARGB(55, 9, 1, 24),
          ],
        ),
      ),
      child: Centered("Welcome ITEC 315"),
    );
  }
}
