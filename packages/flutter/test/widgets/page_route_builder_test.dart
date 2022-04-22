// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is run as part of a reduced test set in CI on Mac and Windows
// machines.
@Tags(<String>['reduced-test-set'])

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class TestPage extends StatelessWidget {
  const TestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  void _presentModalPage() {
    Navigator.of(context).push(PageRouteBuilder<void>(
      barrierColor: Colors.black54,
      opaque: false,
      pageBuilder: (BuildContext context, _, __) {
        return const ModalPage();
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(
        child: Text('Test Home'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _presentModalPage,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class ModalPage extends StatelessWidget {
  const ModalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Stack(
          children: <Widget>[
            InkWell(
              highlightColor: Colors.transparent,
              splashColor: Colors.transparent,
              onTap: () {
                Navigator.of(context).pop();
              },
              child: const SizedBox.expand(),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 150,
                color: Colors.teal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  testWidgets('Barriers show when using PageRouteBuilder', (WidgetTester tester) async {
    await tester.pumpWidget(const TestPage());
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(TestPage),
      matchesGoldenFile('page_route_builder.barrier.png'),
    );
  });
}
