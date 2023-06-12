import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';

class CustomPlugin extends StatelessWidget {
  const CustomPlugin({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ToolPanelSection(
      title: 'Custom',
      children: [
        ListTile(
          title: const Text('Print in console'),
          onTap: () {
            // ignore: avoid_print
            print('Hey, this is a custom plugin!');
          },
        )
      ],
    );
  }
}
