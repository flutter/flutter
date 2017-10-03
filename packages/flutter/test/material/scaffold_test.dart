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
    await tester.pumpWidget(new Directionality(
      textDirection: TextDirection.ltr,
      child: new Scaffold(
        appBar: new AppBar(title: const Text('Title')),
        body: new Container(key: bodyKey),
      ),
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

    await tester.pumpWidget(new Directionality(
      textDirection: TextDirection.ltr,
      child: new MediaQuery(
        data: const MediaQueryData(padding: const EdgeInsets.only(bottom: 100.0)),
        child: new Scaffold(
          appBar: new AppBar(title: const Text('Title')),
          body: new Container(key: bodyKey),
        ),
      ),
    ));

    bodyBox = tester.renderObject(find.byKey(bodyKey));
    expect(bodyBox.size, equals(const Size(800.0, 444.0)));

    await tester.pumpWidget(new Directionality(
      textDirection: TextDirection.ltr,
      child: new MediaQuery(
        data: const MediaQueryData(padding: const EdgeInsets.only(bottom: 100.0)),
        child: new Scaffold(
          appBar: new AppBar(title: const Text('Title')),
          body: new Container(key: bodyKey),
          resizeToAvoidBottomPadding: false,
        ),
      ),
    ));

    bodyBox = tester.renderObject(find.byKey(bodyKey));
    expect(bodyBox.size, equals(const Size(800.0, 544.0)));
  });

  testWidgets('Scaffold large bottom padding test', (WidgetTester tester) async {
    final Key bodyKey = new UniqueKey();
    await tester.pumpWidget(new Directionality(
      textDirection: TextDirection.ltr,
      child: new MediaQuery(
        data: const MediaQueryData(
          padding: const EdgeInsets.only(bottom: 700.0),
        ),
        child: new Scaffold(
          body: new Container(key: bodyKey),
        ),
      ),
    ));

    final RenderBox bodyBox = tester.renderObject(find.byKey(bodyKey));
    expect(bodyBox.size, equals(const Size(800.0, 0.0)));

    await tester.pumpWidget(new Directionality(
      textDirection: TextDirection.ltr,
      child: new MediaQuery(
        data: const MediaQueryData(
          padding: const EdgeInsets.only(bottom: 500.0),
        ),
        child: new Scaffold(
          body: new Container(key: bodyKey),
        ),
      ),
    ));

    expect(bodyBox.size, equals(const Size(800.0, 100.0)));

    await tester.pumpWidget(new Directionality(
      textDirection: TextDirection.ltr,
      child: new MediaQuery(
        data: const MediaQueryData(
          padding: const EdgeInsets.only(bottom: 580.0),
        ),
        child: new Scaffold(
          appBar: new AppBar(
            title: const Text('Title'),
          ),
          body: new Container(key: bodyKey),
        ),
      ),
    ));

    expect(bodyBox.size, equals(const Size(800.0, 0.0)));
  });

  testWidgets('Floating action animation', (WidgetTester tester) async {
    await tester.pumpWidget(new MaterialApp(home: const Scaffold(
      floatingActionButton: const FloatingActionButton(
        key: const Key('one'),
        onPressed: null,
        child: const Text('1'),
      ),
    )));

    expect(tester.binding.transientCallbackCount, 0);

    await tester.pumpWidget(new MaterialApp(home: const Scaffold(
      floatingActionButton: const FloatingActionButton(
        key: const Key('two'),
        onPressed: null,
        child: const Text('2'),
      ),
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
        child: const Text('1'),
      ),
    )));

    expect(tester.binding.transientCallbackCount, greaterThan(0));
  });

  testWidgets('Floating action button position', (WidgetTester tester) async {
    Widget build(TextDirection textDirection) {
      return new Directionality(
        textDirection: textDirection,
        child: const MediaQuery(
          data: const MediaQueryData(
            padding: const EdgeInsets.only(bottom: 200.0),
          ),
          child: const Scaffold(
            floatingActionButton: const FloatingActionButton(
              onPressed: null,
              child: const Text('1'),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(build(TextDirection.ltr));

    expect(tester.getCenter(find.byType(FloatingActionButton)), const Offset(756.0, 356.0));

    await tester.pumpWidget(build(TextDirection.rtl));

    expect(tester.getCenter(find.byType(FloatingActionButton)), const Offset(44.0, 356.0));
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
      await tester.pumpWidget(new Directionality(
        textDirection: TextDirection.ltr,
        child: new MediaQuery(
          data: const MediaQueryData(),
          child: new Scaffold(
            body: new Container(
              key: testKey,
            ),
          ),
        ),
      ));
      expect(tester.element(find.byKey(testKey)).size, const Size(800.0, 600.0));
      expect(tester.renderObject<RenderBox>(find.byKey(testKey)).localToGlobal(Offset.zero), const Offset(0.0, 0.0));
    });

    testWidgets('body size with sized container', (WidgetTester tester) async {
      final Key testKey = new UniqueKey();
      await tester.pumpWidget(new Directionality(
        textDirection: TextDirection.ltr,
        child: new MediaQuery(
          data: const MediaQueryData(),
          child: new Scaffold(
            body: new Container(
              key: testKey,
              height: 100.0,
            ),
          ),
        ),
      ));
      expect(tester.element(find.byKey(testKey)).size, const Size(800.0, 100.0));
      expect(tester.renderObject<RenderBox>(find.byKey(testKey)).localToGlobal(Offset.zero), const Offset(0.0, 0.0));
    });

    testWidgets('body size with centered container', (WidgetTester tester) async {
      final Key testKey = new UniqueKey();
      await tester.pumpWidget(new Directionality(
        textDirection: TextDirection.ltr,
        child: new MediaQuery(
          data: const MediaQueryData(),
          child: new Scaffold(
            body: new Center(
              child: new Container(
                key: testKey,
              ),
            ),
          ),
        ),
      ));
      expect(tester.element(find.byKey(testKey)).size, const Size(800.0, 600.0));
      expect(tester.renderObject<RenderBox>(find.byKey(testKey)).localToGlobal(Offset.zero), const Offset(0.0, 0.0));
    });

    testWidgets('body size with button', (WidgetTester tester) async {
      final Key testKey = new UniqueKey();
      await tester.pumpWidget(new Directionality(
        textDirection: TextDirection.ltr,
        child: new MediaQuery(
          data: const MediaQueryData(),
          child: new Scaffold(
            body: new FlatButton(
              key: testKey,
              onPressed: () { },
              child: const Text(''),
            ),
          ),
        ),
      ));
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
      body: const Text(bodyLabel),
      persistentFooterButtons: <Widget>[const Text(persistentFooterButtonLabel)],
      bottomNavigationBar: const Text(bottomNavigationBarLabel),
      floatingActionButton: const Text(floatingActionButtonLabel),
      drawer: const Drawer(child:const Text(drawerLabel)),
    )));

    expect(semantics, includesNodeWith(label: bodyLabel));
    expect(semantics, includesNodeWith(label: persistentFooterButtonLabel));
    expect(semantics, includesNodeWith(label: bottomNavigationBarLabel));
    expect(semantics, includesNodeWith(label: floatingActionButtonLabel));
    expect(semantics, isNot(includesNodeWith(label: drawerLabel)));

    final ScaffoldState state = tester.firstState(find.byType(Scaffold));
    state.openDrawer();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(semantics, isNot(includesNodeWith(label: bodyLabel)));
    expect(semantics, isNot(includesNodeWith(label: persistentFooterButtonLabel)));
    expect(semantics, isNot(includesNodeWith(label: bottomNavigationBarLabel)));
    expect(semantics, isNot(includesNodeWith(label: floatingActionButtonLabel)));
    expect(semantics, includesNodeWith(label: drawerLabel));

    semantics.dispose();
  });

  testWidgets('Scaffold and extreme window padding', (WidgetTester tester) async {
    final Key appBar = new UniqueKey();
    final Key body = new UniqueKey();
    final Key floatingActionButton = new UniqueKey();
    final Key persistentFooterButton = new UniqueKey();
    final Key drawer = new UniqueKey();
    final Key bottomNavigationBar = new UniqueKey();
    final Key insideAppBar = new UniqueKey();
    final Key insideBody = new UniqueKey();
    final Key insideFloatingActionButton = new UniqueKey();
    final Key insidePersistentFooterButton = new UniqueKey();
    final Key insideDrawer = new UniqueKey();
    final Key insideBottomNavigationBar = new UniqueKey();
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.rtl,
        child: new MediaQuery(
          data: const MediaQueryData(
            padding: const EdgeInsets.only(
              left: 20.0,
              top: 30.0,
              right: 50.0,
              bottom: 70.0,
            ),
          ),
          child: new Scaffold(
            appBar: new PreferredSize(
              preferredSize: const Size(11.0, 13.0),
              child: new Container(
                key: appBar,
                child: new SafeArea(
                  child: new Placeholder(key: insideAppBar),
                ),
              ),
            ),
            body: new Container(
              key: body,
              child: new SafeArea(
                child: new Placeholder(key: insideBody),
              ),
            ),
            floatingActionButton: new SizedBox(
              key: floatingActionButton,
              width: 77.0,
              height: 77.0,
              child: new SafeArea(
                child: new Placeholder(key: insideFloatingActionButton),
              ),
            ),
            persistentFooterButtons: <Widget>[
              new SizedBox(
                key: persistentFooterButton,
                width: 100.0,
                height: 90.0,
                child: new SafeArea(
                  child: new Placeholder(key: insidePersistentFooterButton),
                ),
              ),
            ],
            drawer: new Container(
              key: drawer,
              width: 204.0,
              child: new SafeArea(
                child: new Placeholder(key: insideDrawer),
              ),
            ),
            bottomNavigationBar: new SizedBox(
              key: bottomNavigationBar,
              height: 55.0,
              child: new SafeArea(
                child: new Placeholder(key: insideBottomNavigationBar),
              ),
            ),
          ),
        ),
      ),
    );
    // open drawer
    await tester.flingFrom(const Offset(795.0, 5.0), const Offset(-200.0, 0.0), 10.0);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(tester.getRect(find.byKey(appBar)), new Rect.fromLTRB(0.0, 0.0, 800.0, 43.0));
    expect(tester.getRect(find.byKey(body)), new Rect.fromLTRB(0.0, 43.0, 800.0, 368.0));
    expect(tester.getRect(find.byKey(floatingActionButton)), new Rect.fromLTRB(36.0, 275.0, 113.0, 352.0));
    expect(tester.getRect(find.byKey(persistentFooterButton)), new Rect.fromLTRB(28.0, 377.0, 128.0, 467.0));
    expect(tester.getRect(find.byKey(drawer)), new Rect.fromLTRB(596.0, 0.0, 800.0, 600.0));
    expect(tester.getRect(find.byKey(bottomNavigationBar)), new Rect.fromLTRB(0.0, 475.0, 800.0, 530.0));
    expect(tester.getRect(find.byKey(insideAppBar)), new Rect.fromLTRB(20.0, 30.0, 750.0, 43.0));
    expect(tester.getRect(find.byKey(insideBody)), new Rect.fromLTRB(20.0, 43.0, 750.0, 368.0));
    expect(tester.getRect(find.byKey(insideFloatingActionButton)), new Rect.fromLTRB(36.0, 275.0, 113.0, 352.0));
    expect(tester.getRect(find.byKey(insidePersistentFooterButton)), new Rect.fromLTRB(28.0, 377.0, 128.0, 467.0));
    expect(tester.getRect(find.byKey(insideDrawer)), new Rect.fromLTRB(596.0, 30.0, 750.0, 530.0));
    expect(tester.getRect(find.byKey(insideBottomNavigationBar)), new Rect.fromLTRB(20.0, 475.0, 750.0, 530.0));
  });
}
