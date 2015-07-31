// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/widgets/basic.dart';

import '../resources/display_list.dart';

main() async {
  WidgetTester tester = new WidgetTester();

  await tester.test(() {
    return new Center(
      child: new Container(
        width: 100.0,
        height: 100.0,
        decoration: new BoxDecoration(
          backgroundColor: new Color(0xFF0000FF),
          borderRadius: 20.0,
          border: new Border.all(
            color: const Color(0x7FFF0000),
            width: 10.0
          )
        )
      )
    );
  });

  tester.endTest();
}
