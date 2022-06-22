// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter code sample for IconButton with toggle feature

import 'package:flutter/material.dart';

void main() {
  runApp(const IconButtonsApp());
}

class IconButtonsApp extends StatelessWidget {
  const IconButtonsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorSchemeSeed: const Color(0xff6750a4),
        useMaterial3: true,
        // Desktop and web platforms have a compact visual density by default.
        // To see buttons with circular background on desktop/web, the "visualDensity"
        // needs to be set to "VisualDensity.standard".
        visualDensity: VisualDensity.standard,
      ),
      title: 'Icon Button Types',
      home: Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: const <Widget>[
            StandardIconButtons(),
            FilledIconButtons(),
            FilledTonalIconButtons(),
            OutlinedIconButtons(),
          ]
        ),
      ),
    );
  }
}

class StandardIconButtons extends StatefulWidget {
  const StandardIconButtons({super.key});

  @override
  State<StandardIconButtons> createState() => _StandardIconButtonsState();
}

class _StandardIconButtonsState extends State<StandardIconButtons> {
  bool selected = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          IconButton(
            isSelected: selected,
            onPressed: () {
              setState(() {
                selected = !selected;
              });
            },
            selectedIcon: const Icon(Icons.settings),
            icon: const Icon(Icons.settings_outlined),
          ),
          const SizedBox(width: 10),
          IconButton(
            isSelected: selected,
            onPressed: null,
            selectedIcon: const Icon(Icons.settings),
            icon: const Icon(Icons.settings_outlined),
          ),
        ]
      ),
    );
  }
}

// Use a standard IconButton with specific style to implement the
// 'Filled' toggle button.
class FilledIconButtons extends StatefulWidget {
  const FilledIconButtons({super.key});

  @override
  State<FilledIconButtons> createState() => _FilledIconButtonsState();
}

class _FilledIconButtonsState extends State<FilledIconButtons> {
  bool selected = false;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          IconButton(
            isSelected: selected,
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            onPressed: () {
              setState(() {
                selected = !selected;
              });
            },
            style: IconButton.styleFrom(
              foregroundColor: selected ? colors.onPrimary : colors.primary,
              backgroundColor: selected ? colors.primary : colors.surfaceVariant,
              hoverColor: selected ? colors.onPrimary.withOpacity(0.08) : colors.primary.withOpacity(0.08),
              focusColor: selected ? colors.onPrimary.withOpacity(0.12) : colors.primary.withOpacity(0.12),
              highlightColor: selected ? colors.onPrimary.withOpacity(0.12) : colors.primary.withOpacity(0.12),
            )
          ),
          const SizedBox(width: 10),
          IconButton(
              isSelected: selected,
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings),
              onPressed: null,
              style: IconButton.styleFrom(
                disabledForegroundColor: colors.onSurface.withOpacity(0.38),
                disabledBackgroundColor: colors.onSurface.withOpacity(0.12),
              )
          ),
        ]
      ),
    );
  }
}

// Use a standard IconButton with specific style to implement the
// 'Filled Tonal' toggle button.
class FilledTonalIconButtons extends StatefulWidget {
  const FilledTonalIconButtons({super.key});

  @override
  State<FilledTonalIconButtons> createState() => _FilledTonalIconButtonsState();
}

class _FilledTonalIconButtonsState extends State<FilledTonalIconButtons> {
  bool selected = false;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            IconButton(
              isSelected: selected,
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings),
              onPressed: () {
                setState(() {
                  selected = !selected;
                });
              },
              style: IconButton.styleFrom(
                foregroundColor: selected ? colors.onSecondaryContainer : colors.onSurfaceVariant,
                backgroundColor: selected ?  colors.secondaryContainer : colors.surfaceVariant,
                hoverColor: selected ? colors.onSecondaryContainer.withOpacity(0.08) : colors.onSurfaceVariant.withOpacity(0.08),
                focusColor: selected ? colors.onSecondaryContainer.withOpacity(0.12) : colors.onSurfaceVariant.withOpacity(0.12),
                highlightColor: selected ? colors.onSecondaryContainer.withOpacity(0.12) : colors.onSurfaceVariant.withOpacity(0.12),
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              isSelected: selected,
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings),
              onPressed: null,
              style: IconButton.styleFrom(
                disabledForegroundColor: colors.onSurface.withOpacity(0.38),
                disabledBackgroundColor: colors.onSurface.withOpacity(0.12),
              ),
            ),
          ]
      ),
    );
  }
}

class OutlinedIconButtons extends StatefulWidget {
  const OutlinedIconButtons({super.key});

  @override
  State<OutlinedIconButtons> createState() => _OutlinedIconButtonsState();
}

// Use a standard IconButton with specific style to implement the
// 'Outlined' toggle button.
class _OutlinedIconButtonsState extends State<OutlinedIconButtons> {
  bool selected = false;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          IconButton(
            isSelected: selected,
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            onPressed: () {
              setState(() {
                selected = !selected;
              });
            },
            style: IconButton.styleFrom(
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
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            isSelected: selected,
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            onPressed: null,
            style: IconButton.styleFrom(
              disabledForegroundColor: colors.onSurface.withOpacity(0.38),
              disabledBackgroundColor: selected ? colors.onSurface.withOpacity(0.12) : null,
              side: selected ? null : BorderSide(color: colors.outline.withOpacity(0.12)),
            ),
          ),
        ],
      ),
    );
  }
}


