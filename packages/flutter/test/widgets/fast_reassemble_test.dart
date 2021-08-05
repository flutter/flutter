// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('reassemble with a className only marks subtrees from the first matching element as dirty', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Foo(Bar(Fizz(SizedBox())))
    );

    expect(Foo.count, 0);
    expect(Bar.count, 0);
    expect(Fizz.count, 0);

    DebugReassembleConfig config = DebugReassembleConfig(widgetName: 'Bar');
    WidgetsBinding.instance!.buildOwner!.reassemble(WidgetsBinding.instance!.renderViewElement!, config);

    expect(Foo.count, 0);
    expect(Bar.count, 1);
    expect(Fizz.count, 1);

    config = DebugReassembleConfig(widgetName: 'Fizz');
    WidgetsBinding.instance!.buildOwner!.reassemble(WidgetsBinding.instance!.renderViewElement!, config);

    expect(Foo.count, 0);
    expect(Bar.count, 1);
    expect(Fizz.count, 2);

    config = DebugReassembleConfig(widgetName: 'NoMatch');
    WidgetsBinding.instance!.buildOwner!.reassemble(WidgetsBinding.instance!.renderViewElement!, config);

    expect(Foo.count, 0);
    expect(Bar.count, 1);
    expect(Fizz.count, 2);

    config = DebugReassembleConfig();
    WidgetsBinding.instance!.buildOwner!.reassemble(WidgetsBinding.instance!.renderViewElement!, config);

    expect(Foo.count, 1);
    expect(Bar.count, 2);
    expect(Fizz.count, 3);

    WidgetsBinding.instance!.buildOwner!.reassemble(WidgetsBinding.instance!.renderViewElement!, null);

    expect(Foo.count, 2);
    expect(Bar.count, 3);
    expect(Fizz.count, 4);
  });
}

class Foo extends StatefulWidget {
  const Foo(this.child, {Key? key}) : super(key: key);

  final Widget child;
  static int count = 0;

  @override
  State<Foo> createState() => _FooState();
}

class _FooState extends State<Foo> {
  @override
  void reassemble() {
    Foo.count += 1;
    super.reassemble();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}


class Bar extends StatefulWidget {
  const Bar(this.child, {Key? key}) : super(key: key);

  final Widget child;
  static int count = 0;

  @override
  State<Bar> createState() => _BarState();
}

class _BarState extends State<Bar> {
  @override
  void reassemble() {
    Bar.count += 1;
    super.reassemble();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class Fizz extends StatefulWidget {
  const Fizz(this.child, {Key? key}) : super(key: key);

  final Widget child;
  static int count = 0;

  @override
  State<Fizz> createState() => _FizzState();
}

class _FizzState extends State<Fizz> {
  @override
  void reassemble() {
    Fizz.count += 1;
    super.reassemble();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
