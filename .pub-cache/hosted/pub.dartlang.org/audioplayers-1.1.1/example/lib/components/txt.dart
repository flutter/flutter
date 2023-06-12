import 'package:flutter/material.dart';

class TxtBox extends StatefulWidget {
  final String value;
  final void Function(String) onChange;
  const TxtBox({
    Key? key,
    required this.value,
    required this.onChange,
  }) : super(key: key);

  @override
  State<TxtBox> createState() => _TxtBoxState();
}

class _TxtBoxState extends State<TxtBox> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.value,
    )..addListener(() => widget.onChange(_controller.text));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(controller: _controller);
  }
}
