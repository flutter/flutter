// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is run as part of a reduced test set in CI on Mac and Windows
// machines.
@Tags(<String>['reduced-test-set'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'button_tester.dart';
import 'widgets_app_tester.dart';

const Color _debugBlack54 = Color(0x8A000000);
const Color _debugTeal = Color(0xFF009688);

class TestPage extends StatelessWidget {
  const TestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const TestWidgetsApp(home: HomePage());
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  void _presentModalPage() {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        barrierColor: _debugBlack54,
        opaque: false,
        pageBuilder: (BuildContext context, _, _) {
          return const ModalPage();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const Expanded(child: Center(child: Text('Test Home'))),
        Align(
          alignment: Alignment.bottomRight,
          child: TestButton(onPressed: _presentModalPage, child: const Text('+')),
        ),
      ],
    );
  }
}

class ModalPage extends StatelessWidget {
  const ModalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: <Widget>[
          GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: const SizedBox.expand(),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(height: 150, color: _debugTeal),
          ),
        ],
      ),
    );
  }
}

void main() {
  testWidgets('Barriers show when using PageRouteBuilder', (WidgetTester tester) async {
    await tester.pumpWidget(const TestPage());
    await tester.tap(find.byType(TestButton));
    await tester.pumpAndSettle();
    await expectLater(find.byType(TestPage), matchesGoldenFile('page_route_builder.barrier.png'));
  });
}
