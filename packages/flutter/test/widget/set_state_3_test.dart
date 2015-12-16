// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

ChangerState changer;

class Changer extends StatefulComponent {
  Changer(this.child);

  final Widget child;

  ChangerState createState() => new ChangerState();
}

class ChangerState extends State<Changer> {
  bool _state = false;

  void initState() {
    super.initState();
    changer = this;
  }

  void test() { setState(() { _state = true; }); }

  Widget build(BuildContext context) => _state ? new Wrapper(config.child) : config.child;
}

class Wrapper extends StatelessComponent {
  Wrapper(this.child);

  final Widget child;

  Widget build(BuildContext context) => child;
}

class Leaf extends StatefulComponent {
  LeafState createState() => new LeafState();
}

class LeafState extends State<Leaf> {
  Widget build(BuildContext context) => new Text("leaf");
}

void main() {
  test('three-way setState() smoke test', () {
    testWidgets((WidgetTester tester) {
      tester.pumpWidget(new Changer(new Wrapper(new Leaf())));
      tester.pumpWidget(new Changer(new Wrapper(new Leaf())));
      changer.test();
      tester.pump();
    });
  });
}
