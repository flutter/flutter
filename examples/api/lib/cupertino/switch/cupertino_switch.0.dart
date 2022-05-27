// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter code sample for CupertinoSwitch

import 'package:flutter/cupertino.dart';

void main() => runApp(const CupertinoSwitchApp());

class CupertinoSwitchApp extends StatelessWidget {
  const CupertinoSwitchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      theme: CupertinoThemeData(brightness: Brightness.light),
      home: CupertinoSwitchExample(),
    );
  }
}

class CupertinoSwitchExample extends StatefulWidget {
  const CupertinoSwitchExample({super.key});

  @override
  State<CupertinoSwitchExample> createState() => _CupertinoSwitchExampleState();
}

class _CupertinoSwitchExampleState extends State<CupertinoSwitchExample> {
  bool wifi = true;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('CupertinoSwitch Sample'),
      ),
      child: Center(
        // CupertinoFormRow's main axis is set to max by default.
        // Set the intrinsic height widget to center the CupertinoFormRow.
        child: IntrinsicHeight(
          child: Container(
            color: CupertinoTheme.of(context).barBackgroundColor,
            child: CupertinoFormRow(
              prefix: Row(
                children: <Widget>[
                  Icon(
                    // Wifi icon is updated based on switch value.
                    wifi ? CupertinoIcons.wifi : CupertinoIcons.wifi_slash,
                    color: wifi ? CupertinoColors.systemBlue : CupertinoColors.systemRed,
                  ),
                  const SizedBox(width: 10),
                  const Text('Wi-Fi')
                ],
              ),
              child: CupertinoSwitch(
                // This bool value toggles the switch.
                value: wifi,
                thumbColor: CupertinoColors.systemBlue,
                trackColor: CupertinoColors.systemRed.withOpacity(0.14),
                activeColor: CupertinoColors.systemRed.withOpacity(0.64),
                onChanged: (bool? value) {
                  // This is called when the user toggles the switch.
                  setState(() {
                    wifi = value!;
                  });
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
