// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../widgets/semantics_tester.dart';

void main() {
  testWidgets('Scaffold control test', (WidgetTester tester) async {
    final Key bodyKey = new UniqueKey();
    await tester.pumpWidget(new Scaffold(
      appBar: new AppBar(title: const Text('Title')),
      body: new Container(key: bodyKey),
    ));
    expect(tester.takeException(), isFlutterError);

    await tester.pumpWidget(new MaterialApp(
      home: new Scaffold(
        appBar: new AppBar(title: const Text('Title')),
        body: new Container(key: bodyKey),
      ),
    ));
    RenderBox bodyBox = tester.renderObject(find.byKey(bodyKey));
    expect(bodyBox.size, equals(const Size(800.0, 544.0)));

    await tester.pumpWidget(new MediaQuery(
      data: const MediaQueryData(padding: const EdgeInsets.only(bottom: 100.0)),
      child: new Scaffold(
        appBar: new AppBar(title: const Text('Title')),
        body: new Container(key: bodyKey)
      )
    ));

    bodyBox = tester.renderObject(find.byKey(bodyKey));
    expect(bodyBox.size, equals(const Size(800.0, 444.0)));

    await tester.pumpWidget(new MediaQuery(
      data: const MediaQueryData(padding: const EdgeInsets.only(bottom: 100.0)),
      child: new Scaffold(
        appBar: new AppBar(title: const Text('Title')),
        body: new Container(key: bodyKey),
        resizeToAvoidBottomPadding: false
      )
    ));

    bodyBox = tester.renderObject(find.byKey(bodyKey));
    expect(bodyBox.size, equals(const Size(800.0, 544.0)));
  });

  testWidgets('Scaffold large bottom padding test', (WidgetTester tester) async {
    final Key bodyKey = new UniqueKey();
    await tester.pumpWidget(new MediaQuery(
      data: const MediaQueryData(
        padding: const EdgeInsets.only(bottom: 700.0),
      ),
      child: new Scaffold(
        body: new Container(key: bodyKey),
      ),
    ));

    final RenderBox bodyBox = tester.renderObject(find.byKey(bodyKey));
    expect(bodyBox.size, equals(const Size(800.0, 0.0)));

    await tester.pumpWidget(new MediaQuery(
      data: const MediaQueryData(
        padding: const EdgeInsets.only(bottom: 500.0),
      ),
      child: new Scaffold(
        body: new Container(key: bodyKey),
      ),
    ));

    expect(bodyBox.size, equals(const Size(800.0, 100.0)));

    await tester.pumpWidget(new MediaQuery(
      data: const MediaQueryData(
        padding: const EdgeInsets.only(bottom: 580.0),
      ),
      child: new Scaffold(
        appBar: new AppBar(
          title: const Text('Title'),
        ),
        body: new Container(key: bodyKey),
      ),
    ));

    expect(bodyBox.size, equals(const Size(800.0, 0.0)));
  });

  testWidgets('Floating action animation', (WidgetTester tester) async {
    await tester.pumpWidget(new MaterialApp(home: const Scaffold(
      floatingActionButton: const FloatingActionButton(
        key: const Key('one'),
        onPressed: null,
        child: const Text("1")
      )
    )));

    expect(tester.binding.transientCallbackCount, 0);

    await tester.pumpWidget(new MaterialApp(home: const Scaffold(
      floatingActionButton: const FloatingActionButton(
        key: const Key('two'),
        onPressed: null,
        child: const Text("2")
      )
    )));

    expect(tester.binding.transientCallbackCount, greaterThan(0));
    await tester.pumpWidget(new Container());
    expect(tester.binding.transientCallbackCount, 0);
    await tester.pumpWidget(new MaterialApp(home: const Scaffold()));
    expect(tester.binding.transientCallbackCount, 0);

    await tester.pumpWidget(new MaterialApp(home: const Scaffold(
      floatingActionButton: const FloatingActionButton(
        key: const Key('one'),
        onPressed: null,
        child: const Text("1")
      )
    )));

    expect(tester.binding.transientCallbackCount, greaterThan(0));
  });

  testWidgets('Drawer scrolling', (WidgetTester tester) async {
    final Key drawerKey = new UniqueKey();
    const double appBarHeight = 256.0;

    final ScrollController scrollOffset = new ScrollController();

    await tester.pumpWidget(
      new MaterialApp(
        home: new Scaffold(
          drawer: new Drawer(
            key: drawerKey,
            child: new ListView(
              controller: scrollOffset,
              children: new List<Widget>.generate(10,
                (int index) => new SizedBox(height: 100.0, child: new Text('D$index'))
              )
            )
          ),
          body: new CustomScrollView(
            slivers: <Widget>[
              const SliverAppBar(
                pinned: true,
                expandedHeight: appBarHeight,
                title: const Text('Title'),
                flexibleSpace: const FlexibleSpaceBar(title: const Text('Title')),
              ),
              new SliverPadding(
                padding: const EdgeInsets.only(top: appBarHeight),
                sliver: new SliverList(
                  delegate: new SliverChildListDelegate(new List<Widget>.generate(
                    10, (int index) => new SizedBox(height: 100.0, child: new Text('B$index')),
                  )),
                ),
              ),
            ],
          ),
        )
      )
    );

    final ScaffoldState state = tester.firstState(find.byType(Scaffold));
    state.openDrawer();

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(scrollOffset.offset, 0.0);

    const double scrollDelta = 80.0;
    await tester.drag(find.byKey(drawerKey), const Offset(0.0, -scrollDelta));
    await tester.pump();

    expect(scrollOffset.offset, scrollDelta);

    final RenderBox renderBox = tester.renderObject(find.byType(AppBar));
    expect(renderBox.size.height, equals(appBarHeight));
  });

  Widget _buildStatusBarTestApp(TargetPlatform platform) {
    return new MaterialApp(
      theme: new ThemeData(platform: platform),
      home: new MediaQuery(
        data: const MediaQueryData(padding: const EdgeInsets.only(top: 25.0)), // status bar
        child: new Scaffold(
          body: new CustomScrollView(
            primary: true,
            slivers: <Widget>[
              const SliverAppBar(
                title: const Text('Title')
              ),
              new SliverList(
                delegate: new SliverChildListDelegate(new List<Widget>.generate(
                  20, (int index) => new SizedBox(height: 100.0, child: new Text('$index')),
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('Tapping the status bar scrolls to top on iOS', (WidgetTester tester) async {
    await tester.pumpWidget(_buildStatusBarTestApp(TargetPlatform.iOS));
    final ScrollableState scrollable = tester.state(find.byType(Scrollable));
    scrollable.position.jumpTo(500.0);
    expect(scrollable.position.pixels, equals(500.0));
    await tester.tapAt(const Offset(100.0, 10.0));
    await tester.pumpAndSettle();
    expect(scrollable.position.pixels, equals(0.0));
  });

  testWidgets('Tapping the status bar does not scroll to top on Android', (WidgetTester tester) async {
    await tester.pumpWidget(_buildStatusBarTestApp(TargetPlatform.android));
    final ScrollableState scrollable = tester.state(find.byType(Scrollable));
    scrollable.position.jumpTo(500.0);
    expect(scrollable.position.pixels, equals(500.0));
    await tester.tapAt(const Offset(100.0, 10.0));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(scrollable.position.pixels, equals(500.0));
  });

  testWidgets('Bottom sheet cannot overlap app bar', (WidgetTester tester) async {
    final Key sheetKey = new UniqueKey();

    await tester.pumpWidget(
      new MaterialApp(
        theme: new ThemeData(platform: TargetPlatform.android),
        home: new Scaffold(
          appBar: new AppBar(
            title: const Text('Title'),
          ),
          body: new Builder(
            builder: (BuildContext context) {
              return new GestureDetector(
                onTap: () {
                  Scaffold.of(context).showBottomSheet<Null>((BuildContext context) {
                    return new Container(
                      key: sheetKey,
                      color: Colors.blue[500],
                    );
                  });
                },
                child: const Text('X'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('X'));
    await tester.pump(); // start animation
    await tester.pump(const Duration(seconds: 1));

    final RenderBox appBarBox = tester.renderObject(find.byType(AppBar));
    final RenderBox sheetBox = tester.renderObject(find.byKey(sheetKey));

    final Offset appBarBottomRight = appBarBox.localToGlobal(appBarBox.size.bottomRight(Offset.zero));
    final Offset sheetTopRight = sheetBox.localToGlobal(sheetBox.size.topRight(Offset.zero));

    expect(appBarBottomRight, equals(sheetTopRight));
  });

  testWidgets('Persistent bottom buttons are persistent', (WidgetTester tester) async {
    bool didPressButton = false;
    await tester.pumpWidget(
      new MaterialApp(
        home: new Scaffold(
          body: new SingleChildScrollView(
            child: new Container(
              color: Colors.amber[500],
              height: 5000.0,
              child: const Text('body'),
            ),
          ),
          persistentFooterButtons: <Widget>[
            new FlatButton(
              onPressed: () {
                didPressButton = true;
              },
              child: const Text('X'),
            )
          ],
        ),
      ),
    );

    await tester.drag(find.text('body'), const Offset(0.0, -1000.0));
    expect(didPressButton, isFalse);
    await tester.tap(find.text('X'));
    expect(didPressButton, isTrue);
  });

  group('back arrow', () {
    Future<Null> expectBackIcon(WidgetTester tester, TargetPlatform platform, IconData expectedIcon) async {
      final GlobalKey rootKey = new GlobalKey();
      final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
        '/': (_) => new Container(key: rootKey, child: const Text('Home')),
        '/scaffold': (_) => new Scaffold(
            appBar: new AppBar(),
            body: const Text('Scaffold'),
        )
      };
      await tester.pumpWidget(
        new MaterialApp(theme: new ThemeData(platform: platform), routes: routes)
      );

      Navigator.pushNamed(rootKey.currentContext, '/scaffold');
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final Icon icon = tester.widget(find.byType(Icon));
      expect(icon.icon, expectedIcon);
    }

    testWidgets('Back arrow uses correct default on Android', (WidgetTester tester) async {
      await expectBackIcon(tester, TargetPlatform.android, Icons.arrow_back);
    });

    testWidgets('Back arrow uses correct default on Fuchsia', (WidgetTester tester) async {
      await expectBackIcon(tester, TargetPlatform.fuchsia, Icons.arrow_back);
    });

    testWidgets('Back arrow uses correct default on iOS', (WidgetTester tester) async {
      await expectBackIcon(tester, TargetPlatform.iOS, Icons.arrow_back_ios);
    });
  });

  group('close button', () {
    Future<Null> expectCloseIcon(WidgetTester tester, TargetPlatform platform, IconData expectedIcon) async {
      await tester.pumpWidget(
        new MaterialApp(
          theme: new ThemeData(platform: platform),
          home: new Scaffold(appBar: new AppBar(), body: const Text('Page 1')),
        )
      );

      tester.state<NavigatorState>(find.byType(Navigator)).push(new MaterialPageRoute<Null>(
        builder: (BuildContext context) {
          return new Scaffold(appBar: new AppBar(), body: const Text('Page 2'));
        },
        fullscreenDialog: true,
      ));

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final Icon icon = tester.widget(find.byType(Icon));
      expect(icon.icon, expectedIcon);
    }

    testWidgets('Close button shows correctly on Android', (WidgetTester tester) async {
      await expectCloseIcon(tester, TargetPlatform.android, Icons.close);
    });

    testWidgets('Close button shows correctly on Fuchsia', (WidgetTester tester) async {
      await expectCloseIcon(tester, TargetPlatform.fuchsia, Icons.close);
    });

    testWidgets('Close button shows correctly on iOS', (WidgetTester tester) async {
      await expectCloseIcon(tester, TargetPlatform.iOS, Icons.close);
    });
  });

  group('body size', () {
    testWidgets('body size with container', (WidgetTester tester) async {
      final Key testKey = new UniqueKey();
      await tester.pumpWidget(
        new MediaQuery(
          data: const MediaQueryData(),
          child: new Scaffold(
            body: new Container(
              key: testKey,
            ),
          ),
        ),
      );
      expect(tester.element(find.byKey(testKey)).size, const Size(800.0, 600.0));
      expect(tester.renderObject<RenderBox>(find.byKey(testKey)).localToGlobal(Offset.zero), const Offset(0.0, 0.0));
    });

    testWidgets('body size with sized container', (WidgetTester tester) async {
      final Key testKey = new UniqueKey();
      await tester.pumpWidget(
        new MediaQuery(
          data: const MediaQueryData(),
          child: new Scaffold(
            body: new Container(
              key: testKey,
              height: 100.0,
            ),
          ),
        ),
      );
      expect(tester.element(find.byKey(testKey)).size, const Size(800.0, 100.0));
      expect(tester.renderObject<RenderBox>(find.byKey(testKey)).localToGlobal(Offset.zero), const Offset(0.0, 0.0));
    });

    testWidgets('body size with centered container', (WidgetTester tester) async {
      final Key testKey = new UniqueKey();
      await tester.pumpWidget(
        new MediaQuery(
          data: const MediaQueryData(),
          child: new Scaffold(
            body: new Center(
              child: new Container(
                key: testKey,
              ),
            ),
          ),
        ),
      );
      expect(tester.element(find.byKey(testKey)).size, const Size(800.0, 600.0));
      expect(tester.renderObject<RenderBox>(find.byKey(testKey)).localToGlobal(Offset.zero), const Offset(0.0, 0.0));
    });

    testWidgets('body size with button', (WidgetTester tester) async {
      final Key testKey = new UniqueKey();
      await tester.pumpWidget(
        new MediaQuery(
          data: const MediaQueryData(),
          child: new Scaffold(
            body: new FlatButton(
              key: testKey,
              onPressed: () { },
              child: const Text(''),
            ),
          ),
        ),
      );
      expect(tester.element(find.byKey(testKey)).size, const Size(88.0, 36.0));
      expect(tester.renderObject<RenderBox>(find.byKey(testKey)).localToGlobal(Offset.zero), const Offset(0.0, 0.0));
    });
  });

  testWidgets('Open drawer hides underlying semantics tree', (WidgetTester tester) async {
    const String bodyLabel = 'I am the body';
    const String persistentFooterButtonLabel = 'a button on the bottom';
    const String bottomNavigationBarLabel = 'a bar in an app';
    const String floatingActionButtonLabel = 'I float in space';
    const String drawerLabel = 'I am the reason for this test';

    final SemanticsTester semantics = new SemanticsTester(tester);
    await tester.pumpWidget(new MaterialApp(home: new Scaffold(
      body: new Semantics(label: bodyLabel, child: new Container()),
      persistentFooterButtons: <Widget>[new Semantics(label: persistentFooterButtonLabel, child: new Container())],
      bottomNavigationBar: new Semantics(label: bottomNavigationBarLabel, child: new Container()),
      floatingActionButton: new Semantics(label: floatingActionButtonLabel, child: new Container()),
      drawer: new Drawer(child:new Semantics(label: drawerLabel, child: new Container())),
    )));

    expect(semantics, includesNodeWithLabel(bodyLabel));
    expect(semantics, includesNodeWithLabel(persistentFooterButtonLabel));
    expect(semantics, includesNodeWithLabel(bottomNavigationBarLabel));
    expect(semantics, includesNodeWithLabel(floatingActionButtonLabel));
    expect(semantics, isNot(includesNodeWithLabel(drawerLabel)));

    final ScaffoldState state = tester.firstState(find.byType(Scaffold));
    state.openDrawer();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(semantics, isNot(includesNodeWithLabel(bodyLabel)));
    expect(semantics, isNot(includesNodeWithLabel(persistentFooterButtonLabel)));
    expect(semantics, isNot(includesNodeWithLabel(bottomNavigationBarLabel)));
    expect(semantics, isNot(includesNodeWithLabel(floatingActionButtonLabel)));
    expect(semantics, includesNodeWithLabel(drawerLabel));

    semantics.dispose();
  });
}
