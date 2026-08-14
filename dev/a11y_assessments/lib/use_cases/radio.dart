// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import '../utils.dart';
import 'use_cases.dart';

class RadioUseCase extends UseCase {
  RadioUseCase();

  @override
  String get name => 'Radio';

  @override
  String get route => '/radio';

  @override
  List<Tag> get tags => <Tag>[Tag.batch3, Tag.core];

  @override
  Widget build(BuildContext context) => _MainWidget();
}

enum Option { option1, option2, option3 }

class _MainWidget extends StatefulWidget {
  @override
  State<_MainWidget> createState() => _MainWidgetState();
}

class _MainWidgetState extends State<_MainWidget> {
  Option? _value = Option.option1;

  String pageTitle = getUseCaseName(RadioUseCase());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Semantics(headingLevel: 1, child: Text('$pageTitle Demo'))),
      body: Center(
        child: RadioGroup<Option>(
          groupValue: _value,
          onChanged: (Option? value) {
            setState(() {
              _value = value;
            });
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Semantics(
                    label: 'Option 1',
                    child: const Radio<Option>(value: Option.option1),
                  ),
                  const Text('Option 1'),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Semantics(
                    label: 'Option 2',
                    child: const Radio<Option>(value: Option.option2),
                  ),
                  const Text('Option 2'),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Semantics(
                    label: 'Disabled Option',
                    child: const Radio<Option>(value: Option.option3, enabled: false),
                  ),
                  const Text('Disabled Option'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
