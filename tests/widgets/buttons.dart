// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/flat_button.dart';
import 'package:sky/widgets/floating_action_button.dart';
import 'package:sky/widgets/raised_button.dart';

import '../resources/display_list.dart';

main() async {
  WidgetTester tester = new WidgetTester();

  await tester.test(() {
    return new Center(child: new RaisedButton(child: new Text("ENGAGE")));
  });

  await tester.test(() {
    return new Center(child: new FlatButton(child: new Text("ENGAGE")));
  });

  await tester.test(() {
    return new Center(child: new FloatingActionButton(child: new Text("+")));
  });

  await tester.endTest();
}
