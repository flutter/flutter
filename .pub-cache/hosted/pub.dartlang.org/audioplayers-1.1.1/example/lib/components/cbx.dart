import 'package:flutter/material.dart';

class Cbx extends StatelessWidget {
  final String label;
  final bool value;
  final void Function(bool) update;

  const Cbx(
    this.label,
    this.value,
    this.update, {
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label),
        Checkbox(value: value, onChanged: (v) => update(v!)),
      ],
    );
  }
}
