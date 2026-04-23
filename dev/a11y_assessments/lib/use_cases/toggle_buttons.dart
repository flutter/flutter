// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import '../utils.dart';
import 'use_cases.dart';

class ToggleButtonsUseCase extends UseCase {
  ToggleButtonsUseCase();

  @override
  String get name => 'ToggleButtons';

  @override
  String get route => '/toggle-buttons';

  @override
  List<Tag> get tags => <Tag>[Tag.batch2, Tag.core];

  @override
  Widget build(BuildContext context) => const MainWidget();
}

class MainWidget extends StatefulWidget {
  const MainWidget({super.key});

  @override
  State<MainWidget> createState() => MainWidgetState();
}

class MainWidgetState extends State<MainWidget> {
  String pageTitle = getUseCaseName(ToggleButtonsUseCase());
  final List<bool> _selected = <bool>[true, false, false];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Semantics(headingLevel: 1, child: Text('$pageTitle Demo')),
      ),
      body: Center(
        child: ToggleButtons(
          isSelected: _selected,
          onPressed: (int index) {
            setState(() {
              _selected[index] = !_selected[index];
            });
          },
          children: <Widget>[
            Semantics(label: 'Bold', child: const Icon(Icons.format_bold)),
            Semantics(label: 'Italic', child: const Icon(Icons.format_italic)),
            Semantics(label: 'Underline', child: const Icon(Icons.format_underlined)),
          ],
        ),
      ),
    );
  }
}
