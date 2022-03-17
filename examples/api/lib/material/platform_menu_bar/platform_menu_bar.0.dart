// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter code sample for PlatformMenuBar
import 'package:flutter/material.dart';

void main() => runApp(const SampleApp());

enum MenuSelection {
  about,
  showMessage,
}

class SampleApp extends StatelessWidget {
  const SampleApp({Key? key}) : super(key: key);

  static const String _title = 'MenuBar Sample';

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: _title,
      home: Scaffold(body: MyMenuBarApp()),
    );
  }
}

class MyMenuBarApp extends StatefulWidget {
  const MyMenuBarApp({Key? key}) : super(key: key);

  @override
  State<MyMenuBarApp> createState() => _MyMenuBarAppState();
}

class _MyMenuBarAppState extends State<MyMenuBarApp> {
  bool get showMessage => _showMessage;
  bool _showMessage = false;
  String _message = 'Hello';
  set showMessage(bool value) {
    if (_showMessage != value) {
      setState(() {
        _showMessage = value;
      });
    }
  }

  void _handleMenuSelection(MenuSelection value) {
    switch (value) {
      case MenuSelection.about:
        showAboutDialog(
          context: context,
          applicationName: 'MenuBar Test',
          applicationVersion: '1.0.0',
        );
        break;
      case MenuSelection.showMessage:
        showMessage = !showMessage;
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PlatformMenuBar(
      children: <MenuItem>[
        PlatformSubMenu(
          label: 'Test App',
          children: <MenuItem>[
            PlatformMenuItemGroup(
              members: <MenuItem>[
                PlatformMenuBarItem(
                  label: 'About',
                  onSelected: () => _handleMenuSelection(MenuSelection.about),
                )
              ],
            ),
            PlatformMenuItemGroup(
              members: <MenuItem>[
                PlatformMenuBarItem(
                  onSelected: () => _handleMenuSelection(MenuSelection.showMessage),
                  label: showMessage ? 'Hide Message' : 'Show Message',
                ),
                PlatformSubMenu(
                  label: 'Messages',
                  children: <MenuItem>[
                    PlatformMenuBarItem(
                      label: 'I am not throwing away my shot.',
                      onSelected: () {
                        setState(() {
                          _message = 'I am not throwing away my shot.';
                        });
                      },
                    ),
                    PlatformMenuBarItem(
                      label: "There's a million things I haven't done, but just you wait.",
                      onSelected: () {
                        setState(() {
                          _message = "There's a million things I haven't done, but just you wait.";
                        });
                      },
                    ),
                  ],
                )
              ],
            ),
            const PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.quit),
          ],
        ),
      ],
      body: Center(
        child: Text(_showMessage ? _message : 'Application Body'),
      ),
    );
  }
}
