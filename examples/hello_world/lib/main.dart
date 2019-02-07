// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter/cupertino.dart';
//void main() => runApp(const Center(child: Text('Hello, world!', textDirection: TextDirection.ltr)));

void main() {
  DateTime date;
  runApp(CupertinoApp(
    home: SizedBox(
      height: 400.0,
      width: 400.0,
      child: CupertinoDatePicker(
        mode: CupertinoDatePickerMode.date,
        onDateTimeChanged: (DateTime newDate) {
          date = newDate;
          print(date);
        },
        initialDateTime: DateTime(2018, 3, 30),
      ),
    ),
  ));
}