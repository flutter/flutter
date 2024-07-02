// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

@immutable
class _Home extends StatelessWidget {
  const _Home({
    required this.buttonKey,
    required this.onButtonPressed,
  });

  final Key buttonKey;
  final VoidCallback onButtonPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(),
      child: Center(
        child: CupertinoButton.filled(
          key: buttonKey,
          padding: const EdgeInsets.symmetric(horizontal: 200),
          onPressed: onButtonPressed,
          child: const Text('Button'),
        ),
      ),
    );
  }
}

@immutable
class _Next extends StatelessWidget {
  const _Next();

  @override
  Widget build(BuildContext context) {
    return const CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(),
      child: SizedBox.shrink(),
    );
  }
}

void main() {
  testWidgets(
      'Can tap widget on underlying page during back animation by back button',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 600));
    final GlobalKey buttonKey = GlobalKey();
    int pressCount = 0;

    final Widget app = CupertinoApp(
      home: _Home(
        buttonKey: buttonKey,
        onButtonPressed: () => pressCount += 1,
      ),
    );
    await tester.pumpWidget(app);

    await tester.tap(find.byKey(buttonKey));
    await tester.pump();
    expect(pressCount, 1);

    final NavigatorState navigator = tester.state(find.byType(Navigator));
    navigator.push(
      CupertinoPageRoute<void>(
        builder: (BuildContext context) => const _Next(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(CupertinoNavigationBarBackButton));
    await tester.pumpFrames(app, const Duration(milliseconds: 100));
    await tester.tap(find.byKey(buttonKey));
    await tester.pumpAndSettle();
    expect(pressCount, 2);
  });

  testWidgets(
      'Can tap widget on underlying page during back animation by fling',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 600));

    final GlobalKey buttonKey = GlobalKey();
    int pressCount = 0;

    final Widget app = CupertinoApp(
      home: _Home(
        buttonKey: buttonKey,
        onButtonPressed: () => pressCount += 1,
      ),
    );
    await tester.pumpWidget(app);

    await tester.tap(find.byKey(buttonKey));
    await tester.pump();
    expect(pressCount, 1);

    final NavigatorState navigator = tester.state(find.byType(Navigator));
    navigator.push(
      CupertinoPageRoute<void>(
        builder: (BuildContext context) => const _Next(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.flingFrom(
      const Offset(0, 300),
      const Offset(100, 0),
      10000,
    );
    await tester.pumpFrames(app, const Duration(milliseconds: 100));
    await tester.tap(find.byKey(buttonKey));
    await tester.pumpAndSettle();
    expect(pressCount, 2);
  });
}
