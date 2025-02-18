import 'package:flutter/material.dart';

class Centered extends StatefulWidget {
  Centered(this.text, {super.key});
  String text;

  @override
  State<Centered> createState() => _CenteredState();
}

class _CenteredState extends State<Centered> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        widget.text,
        style: const TextStyle(
          color: Colors.white, 
          fontSize: 34,
          ),
      ),
    );
  }
}
