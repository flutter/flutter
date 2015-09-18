// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/src/widgets/basic.dart';
import 'package:sky/src/widgets/framework.dart';
import 'package:test/test.dart';
import 'widget_tester.dart';

Changer changer;
class Changer extends StatefulComponent {
  Changer(this.child);
  Widget child;
  void syncConstructorArguments(Changer source) {
    child = source.child;
  }
  bool _state = false;
  void initState() { changer = this; }
  void test() { setState(() { _state = true; }); }
  Widget build() => _state ? new Wrapper(child) : child;
}

class Wrapper extends Component {
  Wrapper(this.child);
  final Widget child;
  Widget build() => child;
}

class Leaf extends StatefulComponent {
  void syncConstructorArguments(Leaf source) { }
  Widget build() => new Text("leaf");
}

void main() {
  test('three-way setState() smoke test', () {
    WidgetTester tester = new WidgetTester();
    tester.pumpFrame(() => new Changer(new Wrapper(new Leaf())));
    tester.pumpFrame(() => new Changer(new Wrapper(new Leaf())));
    changer.test();
    tester.pumpFrameWithoutChange();
  });
}
