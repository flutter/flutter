import 'package:flutter/widgets.dart';
import 'package:sample_plugin/sample_plugin.dart';

class DoubleBox extends StatelessWidget {
  const DoubleBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        SizedBox(
          width: 50,
          height: 50,
          child: RedBox(),
        ),
        SizedBox(width: 10),
        SizedBox(
          width: 50,
          height: 50,
          child: RedBox(),
        ),
      ],
    );
  }
}
