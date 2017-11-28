// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

ChangerState changer;

class Changer extends StatefulWidget {
  const Changer(this.child);

  final Widget child;

  @override
  ChangerState createState() => new ChangerState();
}

class ChangerState extends State<Changer> {
  bool _state = false;

  @override
  void initState() {
    super.initState();
    changer = this;
  }

  void test() { setState(() { _state = true; }); }

  @override
  Widget build(BuildContext context) => _state ? new Wrapper(widget.child) : widget.child;
}

class Wrapper extends StatelessWidget {
  const Wrapper(this.child);

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

class Leaf extends StatefulWidget {
  @override
  LeafState createState() => new LeafState();
}

class LeafState extends State<Leaf> {
  @override
  Widget build(BuildContext context) => const Text('leaf', textDirection: TextDirection.ltr);
}

void main() {
  testWidgets('three-way setState() smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(new Changer(new Wrapper(new Leaf())));
    await tester.pumpWidget(new Changer(new Wrapper(new Leaf())));
    changer.test();
    await tester.pump();
  });
}
