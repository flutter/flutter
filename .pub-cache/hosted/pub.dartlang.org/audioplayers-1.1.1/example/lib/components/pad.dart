import 'package:flutter/material.dart';

class Pad extends StatelessWidget {
  final double width, height;

  const Pad({Key? key, this.width = 0, this.height = 0}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
    );
  }
}
