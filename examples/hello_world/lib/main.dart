// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
//
//void main() => runApp(const Center(child: Text('Hello, world!', textDirection: TextDirection.ltr)));

void main() {
  int value = 0;
  final List<DropdownMenuItem<int>> items = <DropdownMenuItem<int>>[];
  for (int i = 0; i < 222; ++i)
    items.add(DropdownMenuItem<int>(value: i, child: Text('$i')));

  void handleChanged(int newValue) {
    value = newValue;
  }

  final DropdownButton<int> button = DropdownButton<int>(
    value: value,
    onChanged: handleChanged,
    items: items,
  );

 runApp(
   MaterialApp(
      home: Material(
        child: Align(
          alignment: Alignment.center,
          child: button,
        ),
      ),
    ),
  );
}