// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';

//void main() => runApp(const Center(child: Text('Hello, world!', textDirection: TextDirection.ltr)));

void main() {
  final List<DropdownMenuItem<int>> items =
      List<DropdownMenuItem<int>>.generate(100, (int i) =>
  DropdownMenuItem<int>(value: i, child: Text('$i')));

  final DropdownButton<int> button = DropdownButton<int>(
    value: 87,
    onChanged: (int newValue){},
    items: items,
  );

  runApp(
    MaterialApp(
      home: Material(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: button,
        ),
      ),
    ),
  );
}