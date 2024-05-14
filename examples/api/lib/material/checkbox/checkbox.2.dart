
// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [Checkbox.adaptive].

void main() => runApp(const CheckboxExampleApp());

class CheckboxExampleApp extends StatefulWidget {
  const CheckboxExampleApp({super.key});

  @override
  State<CheckboxExampleApp> createState() => _CheckboxExampleAppState();
}

class _CheckboxExampleAppState extends State<CheckboxExampleApp> {
  bool? isChecked = true;
  bool isMaterial = true;
  bool isCustomized = false;

  final ButtonStyle style = OutlinedButton.styleFrom(
    fixedSize: const Size(220, 40),
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        platform: isMaterial ? TargetPlatform.android : TargetPlatform.iOS,
        adaptations: <Adaptation<Object>>[
          if (isCustomized) const _CheckboxThemeAdaptation()
        ],
      ),
      title: 'Adaptive Checkbox Sample',
      home: Scaffold(
        appBar: AppBar(title: const Text('Adaptive Checkbox Sample')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              OutlinedButton(
                style: style,
                onPressed: () {
                  setState(() {
                    isMaterial = !isMaterial;
                  });
                },
                child: isMaterial
                    ? const Text('Show cupertino style')
                    : const Text('Show material style'),
              ),
              OutlinedButton(
                style: style,
                onPressed: () {
                  setState(() {
                    isCustomized = !isCustomized;
                  });
                },
                child: isCustomized
                    ? const Text('Remove customization')
                    : const Text('Add customization'),
              ),
              const SizedBox(height: 20),
              Checkbox.adaptive(
                tristate: true,
                value: isChecked,
                onChanged: (bool? value) {
                  setState(() {
                    isChecked = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckboxThemeAdaptation extends Adaptation<CheckboxThemeData> {
  const _CheckboxThemeAdaptation();

  Color getFillColor(Set<WidgetState> states) {
    const Set<WidgetState> interactiveStates = <WidgetState>{
      WidgetState.pressed,
      WidgetState.hovered,
      WidgetState.focused,
    };
    if (states.any(interactiveStates.contains)) {
      return Colors.blue;
    }
    return Colors.red;
  }

  @override
  CheckboxThemeData adapt(ThemeData theme, CheckboxThemeData defaultValue) {
    switch (theme.platform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return defaultValue;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith(getFillColor),
        );
    }
  }
}
