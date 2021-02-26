// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class TestPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  void _presentModalPage() {
    Navigator.of(context).push(PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 300),
      barrierColor: Colors.black54,
      opaque: false,
      pageBuilder: (BuildContext context, _, __) {
        return ModalPage();
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
    await tester.pumpWidget(TestPage());
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(TestPage),
      matchesGoldenFile('page_route_builder.barrier.png'),
    );
  });
}
