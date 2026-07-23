// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import '../utils.dart';
import 'use_cases.dart';

class CheckBoxUseCase extends UseCase {
  CheckBoxUseCase();

  @override
  String get name => 'CheckBox';

  @override
  String get route => '/check-box';

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
  bool _checked = false;

  String pageTitle = getUseCaseName(CheckBoxUseCase());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Semantics(headingLevel: 1, child: Text('$pageTitle Demo'))),
      body: ListView(
        children: <Widget>[
          Checkbox(
            value: _checked,
            semanticLabel: 'Enabled checkbox',
            onChanged: (bool? value) {
              setState(() {
                _checked = value!;
              });
            },
          ),
          const Checkbox(value: false, semanticLabel: 'Disabled checkbox', onChanged: null),
        ],
      ),
    );
  }
}
