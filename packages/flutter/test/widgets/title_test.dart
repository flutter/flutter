// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('toString control test', (WidgetTester tester) async {
    final Widget widget = new Title(
      color: const Color(0xFF00FF00),
      title: 'Awesome app',
      child: new Container(),
    );
    expect(widget.toString, isNot(throwsException));
  });

  testWidgets('should handle a null title correctly', (WidgetTester tester) async {
    final Title widget = new Title(
      color: const Color(0xFF00FF00),
      title: null,
      child: new Container(),
    );
    expect(widget.toString, isNot(throwsException));
    expect(widget.title, equals(''));
  });

  testWidgets('should handle having no title correctly', (WidgetTester tester) async {
    final Title widget = new Title(
      color: const Color(0xFF00FF00),
      child: new Container(),
    );
    expect(widget.toString, isNot(throwsException));
    expect(widget.title, equals(''));
  });
}
