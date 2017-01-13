// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

bool willPopValue = false;

class SamplePage extends StatefulWidget {
  @override
  SamplePageState createState() => new SamplePageState();
}

class SamplePageState extends State<SamplePage> {
  @override
  void dependenciesChanged() {
    super.dependenciesChanged();
    final ModalRoute<Null> route = ModalRoute.of(context);
    if (route.isCurrent) {
      route.scopedWillPopCallback = () {
        return new Future<bool>.value(willPopValue);
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(title: new Text('Sample Page')),
    );
  }
}

class SampleForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(title: new Text('Sample Form')),
      body: new SizedBox.expand(
        child: new Form(
          onWillPop: () {
            return new Future<bool>.value(willPopValue);
          },
          child: new InputFormField(),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('ModalRoute.scopedWillPopupCallback can inhibit back button', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        home: new Scaffold(
          appBar: new AppBar(title: new Text('Home')),
          body: new Builder(
            builder: (BuildContext context) {
              return new Center(
                child: new FlatButton(
                  child: new Text('X'),
                  onPressed: () {
                    showDialog(
                      context: context,
                      child: new SamplePage(),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('X'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Sample Page'), findsOneWidget);

    willPopValue = false;
    await tester.tap(find.byTooltip('Back'));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Sample Page'), findsOneWidget);

    willPopValue = true;
    await tester.tap(find.byTooltip('Back'));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Sample Page'), findsNothing);
  });

  testWidgets('Form.willPop can inhibit back button', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        home: new Scaffold(
          appBar: new AppBar(title: new Text('Home')),
          body: new Builder(
            builder: (BuildContext context) {
              return new Center(
                child: new FlatButton(
                  child: new Text('X'),
                  onPressed: () {
                    Navigator.of(context).push(new MaterialPageRoute<Null>(
                      builder: (BuildContext context) => new SampleForm(),
                    ));
                  },
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('X'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Sample Form'), findsOneWidget);

    willPopValue = false;
    await tester.tap(find.byTooltip('Back'));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Sample Form'), findsOneWidget);

    willPopValue = true;
    await tester.tap(find.byTooltip('Back'));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Sample Form'), findsNothing);
  });
}
