// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import '../utils.dart';
import 'use_cases.dart';

class SwitchUseCase extends UseCase {
  SwitchUseCase();

  @override
  String get name => 'Switch';

  @override
  String get route => '/switch';

  @override
  List<Tag> get tags => <Tag>[Tag.batch3, Tag.core];

  @override
  Widget build(BuildContext context) => _MainWidget();
}

class _MainWidget extends StatefulWidget {
  @override
  State<_MainWidget> createState() => _MainWidgetState();
}

class _MainWidgetState extends State<_MainWidget> {
  bool _value = false;

  String pageTitle = getUseCaseName(SwitchUseCase());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Semantics(headingLevel: 1, child: Text('$pageTitle Demo'))),
      body: ListView(
        children: <Widget>[
          Semantics(
            label: 'Enabled switch',
            child: Switch(
              value: _value,
              onChanged: (bool value) {
                setState(() {
                  _value = value;
                });
              },
            ),
          ),
          Semantics(label: 'Disabled switch', child: const Switch(value: false, onChanged: null)),
        ],
      ),
    );
  }
}
