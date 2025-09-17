// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

void main() {
  runApp(const DropdownMenuExample());
}

class DropdownMenuExample extends StatefulWidget {
  const DropdownMenuExample({super.key});

  @override
  State<DropdownMenuExample> createState() => _DropdownMenuExampleState();
}

class _DropdownMenuExampleState extends State<DropdownMenuExample> {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: DropdownMenu<String>(
            dropdownMenuEntries: <DropdownMenuEntry<String>>[
              DropdownMenuEntry<String>(value: 'Hewwo', label: 'Hewwo')
            ],
            trailingIconButtonStyle: DropDownMenuTrailingIconButtonStyle(
              iconSize: 12,
              padding: EdgeInsets.zero,
              style: ButtonStyle(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap
              )
            ),
            inputDecorationTheme: InputDecorationTheme(
              isCollapsed: true,
              suffixIconConstraints: BoxConstraints(),
            ),
          )
        ),
      )
    );
  }
}
