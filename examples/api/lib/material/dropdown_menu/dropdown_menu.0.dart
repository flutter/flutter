// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Flutter code sample for [DropdownMenu]s. The first dropdown menu has an outlined border
/// which is the default configuration, and the second one has a filled input decoration.

import 'package:flutter/material.dart';

void main() => runApp(const DropdownMenuExample());

class DropdownMenuExample extends StatelessWidget {
  const DropdownMenuExample({super.key});

  List<DropdownMenuEntry> getEntryList() {
    final List<DropdownMenuEntry> entries = <DropdownMenuEntry>[];

    for (int index = 0; index < EntryLabel.values.length; index++) {
      // Disabled item 1, 2 and 6.
      final bool enabled = index != 1 && index != 2 && index != 6;
      entries.add(DropdownMenuEntry(label: EntryLabel.values[index].label, enabled: enabled));
    }
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final List<DropdownMenuEntry> dropdownMenuEntries = getEntryList();

    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green
      ),
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                DropdownMenu(
                  label: const Text('Label'),
                  dropdownMenuEntries: dropdownMenuEntries,
                ),
                const SizedBox(width: 20),
                DropdownMenu(
                  enableFilter: true,
                  leadingIcon: const Icon(Icons.search),
                  label: const Text('Label'),
                  dropdownMenuEntries: dropdownMenuEntries,
                  inputDecorationTheme: const InputDecorationTheme(filled: true),
                )
              ],
            ),
          )
        ),
      ),
    );
  }
}

enum EntryLabel {
  item0('Item 0'),
  item1('Item 1'),
  item2('Item 2'),
  item3('Item 3'),
  item4('Item 4'),
  item5('Item 5'),
  item6('Item 6');

  const EntryLabel(this.label);
  final String label;
}
