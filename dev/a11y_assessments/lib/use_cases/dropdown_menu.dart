// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import '../utils.dart';
import 'use_cases.dart';

class DropdownMenuUseCase extends UseCase {
  DropdownMenuUseCase();

  @override
  String get name => 'DropdownMenu';

  @override
  String get route => '/dropdown-menu';

  @override
  List<Tag> get tags => <Tag>[Tag.batch3, Tag.core];

  @override
  Widget build(BuildContext context) => const _MainWidget();
}

class _MainWidget extends StatelessWidget {
  const _MainWidget();

  static const List<String> _kOptions = <String>['apple', 'banana', 'lemon'];
  static final List<DropdownMenuEntry<String>> _kMenuEntries = _kOptions
      .map<DropdownMenuEntry<String>>(
        (String name) => DropdownMenuEntry<String>(value: name, label: name),
      )
      .toList();

  @override
  Widget build(BuildContext context) {
    final String pageTitle = getUseCaseName(DropdownMenuUseCase());
    return Scaffold(
      appBar: AppBar(title: Semantics(headingLevel: 1, child: Text('$pageTitle Demo'))),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: <Widget>[
          Semantics(
            label: 'Enabled dropdown menu',
            child: DropdownMenu<String>(
              key: const Key('enabled dropdown menu'),
              label: const Text('Fruit'),
              expandedInsets: EdgeInsets.zero,
              initialSelection: _kOptions.first,
              dropdownMenuEntries: _kMenuEntries,
            ),
          ),
          const SizedBox(height: 24.0),
          Semantics(
            label: 'Disabled dropdown menu',
            child: DropdownMenu<String>(
              key: const Key('disabled dropdown menu'),
              label: const Text('Fruit'),
              expandedInsets: EdgeInsets.zero,
              enabled: false,
              initialSelection: _kOptions.first,
              dropdownMenuEntries: _kMenuEntries,
            ),
          ),
        ],
      ),
    );
  }
}
