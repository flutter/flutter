import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:win32/win32.dart';

class WindowRoundingSelector extends StatefulWidget {
  const WindowRoundingSelector({Key? key}) : super(key: key);

  @override
  WindowRoundingSelectorState createState() => WindowRoundingSelectorState();
}

class WindowRoundingSelectorState extends State<WindowRoundingSelector> {
  bool _isWindowRounded = true;

  void setWindowRoundingEffect(bool isRounded) {
    final pref = calloc<DWORD>();
    try {
      final hwnd = GetForegroundWindow();
      final attr = DWMWINDOWATTRIBUTE.DWMWA_WINDOW_CORNER_PREFERENCE;
      pref.value = isRounded
          ? DWM_WINDOW_CORNER_PREFERENCE.DWMWCP_ROUND
          : DWM_WINDOW_CORNER_PREFERENCE.DWMWCP_DONOTROUND;

      DwmSetWindowAttribute(hwnd, attr, pref, sizeOf<DWORD>());

      setState(() {
        _isWindowRounded = isRounded;
      });
    } finally {
      free(pref);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 20),
      child: SwitchListTile(
        title: const Text('Round window corners (Windows 11 style)'),
        secondary: const FaIcon(FontAwesomeIcons.windowMaximize),
        value: _isWindowRounded,
        onChanged: setWindowRoundingEffect,
      ),
    );
  }
}
