// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@Tags(<String>['reduced-test-set'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestPage extends StatelessWidget {
  const _TestPage({this.useMaterial3});

  final bool? useMaterial3;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: useMaterial3, primarySwatch: Colors.blue),
      home: const _HomePage(),
    );
  }
}

class _HomePage extends StatefulWidget {
  const _HomePage();

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  void _presentModalPage() {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        barrierColor: Colors.black54,
        opaque: false,
        pageBuilder: (BuildContext context, _, _) {
          return const _ModalPage();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(child: Text('Test Home')),
      floatingActionButton: FloatingActionButton(
        onPressed: _presentModalPage,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ModalPage extends StatelessWidget {
  const _ModalPage();

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
              child: Container(height: 150, color: Colors.teal),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  testWidgets('Material2 - Barriers show when using PageRouteBuilder', (WidgetTester tester) async {
    await tester.pumpWidget(const _TestPage(useMaterial3: false));
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(_TestPage),
      matchesGoldenFile('m2_page_route_builder.barrier.png'),
    );
  });

  testWidgets('Material3 - Barriers show when using PageRouteBuilder', (WidgetTester tester) async {
    await tester.pumpWidget(const _TestPage());
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(_TestPage),
      matchesGoldenFile('m3_page_route_builder.barrier.png'),
    );
  });
}
