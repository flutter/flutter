import 'package:flutter/material.dart';
import 'package:nested/nested.dart';

void main() {
  runApp(
    Nested(
      children: [
        const SingleChildContainer(color: Colors.red),
        SingleChildBuilder(
          builder: (context, child) => Center(child: child),
        ),
      ],
      child: const Text('Hello world', textDirection: TextDirection.ltr),
    ),
  );
}

class SingleChildContainer extends SingleChildStatelessWidget {
  const SingleChildContainer({Key? key, required this.color, Widget? child})
      : super(key: key, child: child);

  final Color color;

  @override
  Widget buildWithChild(BuildContext context, Widget? child) {
    return Container(
      color: color,
      child: child,
    );
  }
}
