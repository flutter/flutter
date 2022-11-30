// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Flutter code sample for [DropdownMenu]s. The first dropdown menu has an outlined border
/// which is the default configuration, and the second one has a filled input decoration.

import 'package:flutter/material.dart';

void main() => runApp(const DropdownMenuExample());

class DropdownMenuExample extends StatefulWidget {
  const DropdownMenuExample({super.key});

  @override
  State<DropdownMenuExample> createState() => _DropdownMenuExampleState();
}

class _DropdownMenuExampleState extends State<DropdownMenuExample> {
  final TextEditingController colorController = TextEditingController();
  final TextEditingController iconController = TextEditingController();
  bool hasColor = false;
  bool hasIcon = false;

  Map<String, Color> colors = <String, Color>{
    'Blue': Colors.blue,
    'Pink': Colors.pink,
    'Green': Colors.green,
    'Yellow': Colors.yellow,
    'Grey': Colors.grey,
  };
  Map<String, IconData> icons = <String, IconData>{
    'Smile': Icons.sentiment_satisfied_outlined,
    'Cloud': Icons.cloud_outlined,
    'Brush': Icons.brush_outlined,
    'Heart': Icons.favorite,
  };

  List<DropdownMenuEntry> getEntry(List<String> labels, {String? disabledLabel}) {
    final List<DropdownMenuEntry> entries = <DropdownMenuEntry>[];
    for (final String label in labels) {
      entries.add(DropdownMenuEntry(label: label, enabled: label != disabledLabel));
    }
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final List<DropdownMenuEntry> colorEntries = getEntry(colors.keys.toList(), disabledLabel: 'Grey');
    final List<DropdownMenuEntry> iconEntries = getEntry(icons.keys.toList());

    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green
      ),
      home: Scaffold(
        body: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    DropdownMenu(
                      controller: colorController,
                      label: const Text('Color'),
                      dropdownMenuEntries: colorEntries,
                      onChanged: (String text) {
                        setState(() {
                          hasColor = colors.containsKey(text);
                        });
                      },
                    ),
                    const SizedBox(width: 20),
                    DropdownMenu(
                      controller: iconController,
                      enableFilter: true,
                      leadingIcon: const Icon(Icons.search),
                      label: const Text('Icon'),
                      dropdownMenuEntries: iconEntries,
                      inputDecorationTheme: const InputDecorationTheme(filled: true),
                      onChanged: (String text) {
                        setState(() {
                          hasIcon = icons.containsKey(text);
                        });
                      },
                    )
                  ],
                ),
              ),
              if (hasColor && hasIcon)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text('You selected a ${colorController.text} ${iconController.text}'),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Icon(icons[iconController.text], color: colors[colorController.text],))
                  ],
                )
              else const Text('Please select a color and an icon.')
            ],
          )
        ),
      ),
    );
  }
}
