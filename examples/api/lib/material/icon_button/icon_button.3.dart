// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter code sample for IconButton with toggle feature

import 'package:flutter/material.dart';

void main() {
  runApp(const IconButtonToggleApp());
}

class IconButtonToggleApp extends StatelessWidget {
  const IconButtonToggleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorSchemeSeed: const Color(0xff6750a4),
        useMaterial3: true,
      ),
      title: 'Icon Button Types',
      home: const Scaffold(
        body: DemoIconToggleButtons(),
      ),
    );
  }
}

class DemoIconToggleButtons extends StatefulWidget {
  const DemoIconToggleButtons({super.key});

  @override
  State<DemoIconToggleButtons> createState() => _DemoIconToggleButtonsState();
}

class _DemoIconToggleButtonsState extends State<DemoIconToggleButtons> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            // Standard IconButton
            children: const <Widget>[
              DemoIconToggleButton(isEnabled: true),
              SizedBox(width: 10),
              DemoIconToggleButton(isEnabled: false),
            ]
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const <Widget>[
              // Filled IconButton
              DemoIconToggleButton(isEnabled: true, getDefaultStyle: enabledFilledButtonStyle,),
              SizedBox(width: 10),
              DemoIconToggleButton(isEnabled: false, getDefaultStyle: disabledFilledButtonStyle,)
            ]
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const <Widget>[
              // Filled Tonal IconButton
              DemoIconToggleButton(isEnabled: true, getDefaultStyle: enabledFilledTonalButtonStyle,),
              SizedBox(width: 10),
              DemoIconToggleButton(isEnabled: false, getDefaultStyle: disabledFilledTonalButtonStyle,),
            ]
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const <Widget>[
              // Outlined IconButton
              DemoIconToggleButton(isEnabled: true, getDefaultStyle: enabledOutlinedButtonStyle,),
              SizedBox(width: 10),
              DemoIconToggleButton(isEnabled: false, getDefaultStyle: disabledOutlinedButtonStyle,),
            ]
          ),
        ]
      ),
    );
  }
}

class DemoIconToggleButton extends StatefulWidget {
  const DemoIconToggleButton({required this.isEnabled, this.getDefaultStyle, super.key});

  final bool isEnabled;
  final ButtonStyle? Function(bool, ColorScheme)? getDefaultStyle;

  @override
  State<DemoIconToggleButton> createState() => _DemoIconToggleButtonState();
}

class _DemoIconToggleButtonState extends State<DemoIconToggleButton> {
  bool selected = false;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final VoidCallback? onPressed = widget.isEnabled
      ? () {
        setState(() {
          selected = !selected;
        });
      }
      : null;
    ButtonStyle? style;
    if (widget.getDefaultStyle != null) {
      style = widget.getDefaultStyle!(selected, colors);
    }

    return IconButton(
      isSelected: selected,
      icon: const Icon(Icons.settings_outlined),
      selectedIcon: const Icon(Icons.settings),
      onPressed: onPressed,
      style: style,
    );
  }
}

ButtonStyle enabledFilledButtonStyle(bool selected, ColorScheme colors) {
  return IconButton.styleFrom(
    foregroundColor: selected ? colors.onPrimary : colors.primary,
    backgroundColor: selected ? colors.primary : colors.surfaceVariant,
    disabledForegroundColor: colors.onSurface.withOpacity(0.38),
    disabledBackgroundColor: colors.onSurface.withOpacity(0.12),
    hoverColor: selected ? colors.onPrimary.withOpacity(0.08) : colors.primary.withOpacity(0.08),
    focusColor: selected ? colors.onPrimary.withOpacity(0.12) : colors.primary.withOpacity(0.12),
    highlightColor: selected ? colors.onPrimary.withOpacity(0.12) : colors.primary.withOpacity(0.12),
  );
}

ButtonStyle disabledFilledButtonStyle(bool selected, ColorScheme colors) {
  return IconButton.styleFrom(
    disabledForegroundColor: colors.onSurface.withOpacity(0.38),
    disabledBackgroundColor: colors.onSurface.withOpacity(0.12),
  );
}

ButtonStyle enabledFilledTonalButtonStyle(bool selected, ColorScheme colors) {
  return IconButton.styleFrom(
    foregroundColor: selected ? colors.onSecondaryContainer : colors.onSurfaceVariant,
    backgroundColor: selected ?  colors.secondaryContainer : colors.surfaceVariant,
    hoverColor: selected ? colors.onSecondaryContainer.withOpacity(0.08) : colors.onSurfaceVariant.withOpacity(0.08),
    focusColor: selected ? colors.onSecondaryContainer.withOpacity(0.12) : colors.onSurfaceVariant.withOpacity(0.12),
    highlightColor: selected ? colors.onSecondaryContainer.withOpacity(0.12) : colors.onSurfaceVariant.withOpacity(0.12),
  );
}

ButtonStyle disabledFilledTonalButtonStyle(bool selected, ColorScheme colors) {
  return IconButton.styleFrom(
    disabledForegroundColor: colors.onSurface.withOpacity(0.38),
    disabledBackgroundColor: colors.onSurface.withOpacity(0.12),
  );
}

ButtonStyle enabledOutlinedButtonStyle(bool selected, ColorScheme colors) {
  return IconButton.styleFrom(
    backgroundColor: selected ? colors.inverseSurface : null,
    hoverColor: selected ? colors.onInverseSurface.withOpacity(0.08) : colors.onSurfaceVariant.withOpacity(0.08),
    focusColor: selected ? colors.onInverseSurface.withOpacity(0.12) : colors.onSurfaceVariant.withOpacity(0.12),
    highlightColor: selected ? colors.onInverseSurface.withOpacity(0.12) : colors.onSurface.withOpacity(0.12),
    side: BorderSide(color: colors.outline),
  ).copyWith(
    foregroundColor: MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.selected)) {
        return colors.onInverseSurface;
      }
      if (states.contains(MaterialState.pressed)) {
        return colors.onSurface;
      }
      return null;
    }),
  );
}

ButtonStyle disabledOutlinedButtonStyle(bool selected, ColorScheme colors) {
  return IconButton.styleFrom(
    disabledForegroundColor: colors.onSurface.withOpacity(0.38),
    disabledBackgroundColor: selected ? colors.onSurface.withOpacity(0.12) : null,
    side: selected ? null : BorderSide(color: colors.outline.withOpacity(0.12)),
  );
}
