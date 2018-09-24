// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

class ScrollPositionListener extends StatefulWidget {
  const ScrollPositionListener({ Key key, this.child, this.log}) : super(key: key);

  final Widget child;
  final ValueChanged<String> log;

  @override
  _ScrollPositionListenerState createState() => _ScrollPositionListenerState();
}

class _ScrollPositionListenerState extends State<ScrollPositionListener> {
  ScrollPosition _position;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _position?.removeListener(listener);
    _position = Scrollable.of(context)?.position;
    _position?.addListener(listener);
    widget.log('didChangeDependencies ${_position?.pixels}');
  }

  @override
  void dispose() {
    _position?.removeListener(listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;

  void listener() {
    widget.log('listener ${_position?.pixels}');
  }

}

void main() {
  testWidgets('Scrollable.of() dependent rebuilds when Scrollable position changes', (WidgetTester tester) async {
    String logValue;
    final ScrollController controller = ScrollController();

    // Changing the SingleChildScrollView's physics causes the
    // ScrollController's ScrollPosition to be rebuilt.

    Widget buildFrame(ScrollPhysics physics) {
      return SingleChildScrollView(
        controller: controller,
        physics: physics,
        child: ScrollPositionListener(
          log: (String s) { logValue = s; },
          child: const SizedBox(height: 400.0),
        ),
      );
    }

    await tester.pumpWidget(buildFrame(null));
    expect(logValue, 'didChangeDependencies 0.0');

    controller.jumpTo(100.0);
    expect(logValue, 'listener 100.0');

    await tester.pumpWidget(buildFrame(const ClampingScrollPhysics()));
    expect(logValue, 'didChangeDependencies 100.0');

    controller.jumpTo(200.0);
    expect(logValue, 'listener 200.0');

    controller.jumpTo(300.0);
    expect(logValue, 'listener 300.0');

    await tester.pumpWidget(buildFrame(const BouncingScrollPhysics()));
    expect(logValue, 'didChangeDependencies 300.0');

    controller.jumpTo(400.0);
    expect(logValue, 'listener 400.0');
  });
}
