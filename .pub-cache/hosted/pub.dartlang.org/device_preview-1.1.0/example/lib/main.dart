import 'package:device_preview/device_preview.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'basic.dart';
import 'custom_plugin.dart';

void main() {
  runApp(
    DevicePreview(
      enabled: true,
      tools: [
        ...DevicePreview.defaultTools,
        const CustomPlugin(),
      ],
      builder: (context) => const BasicApp(),
    ),
  );
}
