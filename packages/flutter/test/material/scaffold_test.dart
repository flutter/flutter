// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../widgets/semantics_tester.dart';

void main() {
  testWidgets('Scaffold control test', (WidgetTester tester) async {
    final Key bodyKey = UniqueKey();
    Widget boilerplate(Widget child) {
      return Localizations(
        locale: const Locale('en', 'us'),
        delegates: const <LocalizationsDelegate<dynamic>>[
          DefaultWidgetsLocalizations.delegate,
          DefaultMaterialLocalizations.delegate,
        ],
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: child,
        ),
      );
    }
    await tester.pumpWidget(boilerplate(Scaffold(
        appBar: AppBar(title: const Text('Title')),
        body: Container(key: bodyKey),
      ),
    ));
    expect(tester.takeException(), isFlutterError);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Title')),
        body: Container(key: bodyKey),
      ),
    ));
    RenderBox bodyBox = tester.renderObject(find.byKey(bodyKey));
    expect(bodyBox.size, equals(const Size(800.0, 544.0)));

    await tester.pumpWidget(boilerplate(MediaQuery(
        data: const MediaQueryData(viewInsets: EdgeInsets.only(bottom: 100.0)),
        child: Scaffold(
          appBar: AppBar(title: const Text('Title')),
          body: Container(key: bodyKey),
        ),
      ),
    ));

    bodyBox = tester.renderObject(find.byKey(bodyKey));
    expect(bodyBox.size, equals(const Size(800.0, 444.0)));

    await tester.pumpWidget(boilerplate(MediaQuery(
      data: const MediaQueryData(viewInsets: EdgeInsets.only(bottom: 100.0)),
      child: Scaffold(
        appBar: AppBar(title: const Text('Title')),
        body: Container(key: bodyKey),
        resizeToAvoidBottomPadding: false,
      ),
    )));

    bodyBox = tester.renderObject(find.byKey(bodyKey));
    expect(bodyBox.size, equals(const Size(800.0, 544.0)));
  });

  testWidgets('Scaffold large bottom padding test', (WidgetTester tester) async {
    final Key bodyKey = UniqueKey();

    Widget boilerplate(Widget child) {
      return Localizations(
        locale: const Locale('en', 'us'),
        delegates: const <LocalizationsDelegate<dynamic>>[
          DefaultWidgetsLocalizations.delegate,
          DefaultMaterialLocalizations.delegate,
        ],
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: child,
        ),
      );
    }

    await tester.pumpWidget(boilerplate(MediaQuery(
      data: const MediaQueryData(
        viewInsets: EdgeInsets.only(bottom: 700.0),
      ),
      child: Scaffold(
        body: Container(key: bodyKey),
      ))
    ));

    final RenderBox bodyBox = tester.renderObject(find.byKey(bodyKey));
    expect(bodyBox.size, equals(const Size(800.0, 0.0)));

    await tester.pumpWidget(boilerplate(MediaQuery(
        data: const MediaQueryData(
          viewInsets: EdgeInsets.only(bottom: 500.0),
        ),
        child: Scaffold(
          body: Container(key: bodyKey),
        ),
      ),
    ));

    expect(bodyBox.size, equals(const Size(800.0, 100.0)));

    await tester.pumpWidget(boilerplate(MediaQuery(
        data: const MediaQueryData(
          viewInsets: EdgeInsets.only(bottom: 580.0),
        ),
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Title'),
          ),
          body: Container(key: bodyKey),
        ),
      ),
    ));

    expect(bodyBox.size, equals(const Size(800.0, 0.0)));
  });

  testWidgets('Floating action entrance/exit animation', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      floatingActionButton: FloatingActionButton(
        key: Key('one'),
        onPressed: null,
        child: Text('1'),
      ),
    )));

    expect(tester.binding.transientCallbackCount, 0);

    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      floatingActionButton: FloatingActionButton(
        key: Key('two'),
        onPressed: null,
        child: Text('2'),
      ),
    )));

    expect(tester.binding.transientCallbackCount, greaterThan(0));
    await tester.pumpWidget(Container());
    expect(tester.binding.transientCallbackCount, 0);

    await tester.pumpWidget(const MaterialApp(home: Scaffold()));

    expect(tester.binding.transientCallbackCount, 0);

    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      floatingActionButton: FloatingActionButton(
        key: Key('one'),
        onPressed: null,
        child: Text('1'),
      ),
    )));

    expect(tester.binding.transientCallbackCount, greaterThan(0));
  });

  testWidgets('Floating action button directionality', (WidgetTester tester) async {
    Widget build(TextDirection textDirection) {
      return Directionality(
        textDirection: textDirection,
        child: const MediaQuery(
          data: MediaQueryData(
            viewInsets: EdgeInsets.only(bottom: 200.0),
          ),
          child: Scaffold(
            floatingActionButton: FloatingActionButton(
              onPressed: null,
              child: Text('1'),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(build(TextDirection.ltr));

    expect(tester.getCenter(find.byType(FloatingActionButton)), const Offset(756.0, 356.0));

    await tester.pumpWidget(build(TextDirection.rtl));
    expect(tester.binding.transientCallbackCount, 0);

    expect(tester.getCenter(find.byType(FloatingActionButton)), const Offset(44.0, 356.0));
  });

  testWidgets('Drawer scrolling', (WidgetTester tester) async {
    final Key drawerKey = UniqueKey();
    const double appBarHeight = 256.0;

    final ScrollController scrollOffset = ScrollController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          drawer: Drawer(
            key: drawerKey,
            child: ListView(
              controller: scrollOffset,
              children: List<Widget>.generate(10,
                (int index) => SizedBox(height: 100.0, child: Text('D$index'))
              )
            )
          ),
          body: CustomScrollView(
            slivers: <Widget>[
              const SliverAppBar(
                pinned: true,
                expandedHeight: appBarHeight,
                title: Text('Title'),
                flexibleSpace: FlexibleSpaceBar(title: Text('Title')),
              ),
              SliverPadding(
                padding: const EdgeInsets.only(top: appBarHeight),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(List<Widget>.generate(
                    10, (int index) => SizedBox(height: 100.0, child: Text('B$index')),
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
    return MaterialApp(
      theme: ThemeData(platform: platform),
      home: MediaQuery(
        data: const MediaQueryData(padding: EdgeInsets.only(top: 25.0)), // status bar
        child: Scaffold(
          body: CustomScrollView(
            primary: true,
            slivers: <Widget>[
              const SliverAppBar(
                title: Text('Title')
              ),
              SliverList(
                delegate: SliverChildListDelegate(List<Widget>.generate(
                  20, (int index) => SizedBox(height: 100.0, child: Text('$index')),
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
    final Key sheetKey = UniqueKey();

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Title'),
          ),
          body: Builder(
            builder: (BuildContext context) {
              return GestureDetector(
                onTap: () {
                  Scaffold.of(context).showBottomSheet<void>((BuildContext context) {
                    return Container(
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
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Container(
              color: Colors.amber[500],
              height: 5000.0,
              child: const Text('body'),
            ),
          ),
          persistentFooterButtons: <Widget>[
            FlatButton(
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

  testWidgets('Persistent bottom buttons apply media padding', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(
            padding: EdgeInsets.fromLTRB(10.0, 20.0, 30.0, 40.0),
          ),
          child: Scaffold(
            body: SingleChildScrollView(
              child: Container(
                color: Colors.amber[500],
                height: 5000.0,
                child: const Text('body'),
              ),
            ),
            persistentFooterButtons: const <Widget>[Placeholder()],
          ),
        ),
      ),
    );
    expect(tester.getBottomLeft(find.byType(ButtonBar)), const Offset(10.0, 560.0));
    expect(tester.getBottomRight(find.byType(ButtonBar)), const Offset(770.0, 560.0));
  });

  group('back arrow', () {
    Future<void> expectBackIcon(WidgetTester tester, TargetPlatform platform, IconData expectedIcon) async {
      final GlobalKey rootKey = GlobalKey();
      final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
        '/': (_) => Container(key: rootKey, child: const Text('Home')),
        '/scaffold': (_) => Scaffold(
            appBar: AppBar(),
            body: const Text('Scaffold'),
        )
      };
      await tester.pumpWidget(
        MaterialApp(theme: ThemeData(platform: platform), routes: routes)
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
    Future<void> expectCloseIcon(WidgetTester tester, TargetPlatform platform, IconData expectedIcon, PageRoute<void> routeBuilder()) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: platform),
          home: Scaffold(appBar: AppBar(), body: const Text('Page 1')),
        )
      );

      tester.state<NavigatorState>(find.byType(Navigator)).push(routeBuilder());

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final Icon icon = tester.widget(find.byType(Icon));
      expect(icon.icon, expectedIcon);
      expect(find.byType(CloseButton), findsOneWidget);
    }

    PageRoute<void> materialRouteBuilder() {
      return MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return Scaffold(appBar: AppBar(), body: const Text('Page 2'));
        },
        fullscreenDialog: true,
      );
    }

    PageRoute<void> customPageRouteBuilder() {
      return _CustomPageRoute<void>(
        builder: (BuildContext context) {
          return Scaffold(appBar: AppBar(), body: const Text('Page 2'));
        },
        fullscreenDialog: true,
      );
    }

    testWidgets('Close button shows correctly on Android', (WidgetTester tester) async {
      await expectCloseIcon(tester, TargetPlatform.android, Icons.close, materialRouteBuilder);
    });

    testWidgets('Close button shows correctly on Fuchsia', (WidgetTester tester) async {
      await expectCloseIcon(tester, TargetPlatform.fuchsia, Icons.close, materialRouteBuilder);
    });

    testWidgets('Close button shows correctly on iOS', (WidgetTester tester) async {
      await expectCloseIcon(tester, TargetPlatform.iOS, Icons.close, materialRouteBuilder);
    });

    testWidgets('Close button shows correctly with custom page route on Android', (WidgetTester tester) async {
      await expectCloseIcon(tester, TargetPlatform.android, Icons.close, customPageRouteBuilder);
    });

    testWidgets('Close button shows correctly with custom page route on Fuchsia', (WidgetTester tester) async {
      await expectCloseIcon(tester, TargetPlatform.fuchsia, Icons.close, customPageRouteBuilder);
    });

    testWidgets('Close button shows correctly with custom page route on iOS', (WidgetTester tester) async {
      await expectCloseIcon(tester, TargetPlatform.iOS, Icons.close, customPageRouteBuilder);
    });
  });

  group('body size', () {
    testWidgets('body size with container', (WidgetTester tester) async {
      final Key testKey = UniqueKey();
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: Scaffold(
            body: Container(
              key: testKey,
            ),
          ),
        ),
      ));
      expect(tester.element(find.byKey(testKey)).size, const Size(800.0, 600.0));
      expect(tester.renderObject<RenderBox>(find.byKey(testKey)).localToGlobal(Offset.zero), const Offset(0.0, 0.0));
    });

    testWidgets('body size with sized container', (WidgetTester tester) async {
      final Key testKey = UniqueKey();
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: Scaffold(
            body: Container(
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
      final Key testKey = UniqueKey();
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: Scaffold(
            body: Center(
              child: Container(
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
      final Key testKey = UniqueKey();
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: Scaffold(
            body: FlatButton(
              key: testKey,
              onPressed: () { },
              child: const Text(''),
            ),
          ),
        ),
      ));
      expect(tester.element(find.byKey(testKey)).size, const Size(88.0, 48.0));
      expect(tester.renderObject<RenderBox>(find.byKey(testKey)).localToGlobal(Offset.zero), const Offset(0.0, 0.0));
    });
  });

  testWidgets('Open drawer hides underlying semantics tree', (WidgetTester tester) async {
    const String bodyLabel = 'I am the body';
    const String persistentFooterButtonLabel = 'a button on the bottom';
    const String bottomNavigationBarLabel = 'a bar in an app';
    const String floatingActionButtonLabel = 'I float in space';
    const String drawerLabel = 'I am the reason for this test';

    final SemanticsTester semantics = SemanticsTester(tester);
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      body: Text(bodyLabel),
      persistentFooterButtons: <Widget>[Text(persistentFooterButtonLabel)],
      bottomNavigationBar: Text(bottomNavigationBarLabel),
      floatingActionButton: Text(floatingActionButtonLabel),
      drawer: Drawer(child: Text(drawerLabel)),
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
    final Key appBar = UniqueKey();
    final Key body = UniqueKey();
    final Key floatingActionButton = UniqueKey();
    final Key persistentFooterButton = UniqueKey();
    final Key drawer = UniqueKey();
    final Key bottomNavigationBar = UniqueKey();
    final Key insideAppBar = UniqueKey();
    final Key insideBody = UniqueKey();
    final Key insideFloatingActionButton = UniqueKey();
    final Key insidePersistentFooterButton = UniqueKey();
    final Key insideDrawer = UniqueKey();
    final Key insideBottomNavigationBar = UniqueKey();
    await tester.pumpWidget(
      Localizations(
        locale: const Locale('en', 'us'),
        delegates: const <LocalizationsDelegate<dynamic>>[
          DefaultWidgetsLocalizations.delegate,
          DefaultMaterialLocalizations.delegate,
        ],
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: MediaQuery(
            data: const MediaQueryData(
              padding: EdgeInsets.only(
                left: 20.0,
                top: 30.0,
                right: 50.0,
                bottom: 60.0,
              ),
              viewInsets: EdgeInsets.only(bottom: 200.0),
            ),
            child: Scaffold(
              appBar: PreferredSize(
                preferredSize: const Size(11.0, 13.0),
                child: Container(
                  key: appBar,
                  child: SafeArea(
                    child: Placeholder(key: insideAppBar),
                  ),
                ),
              ),
              body: Container(
                key: body,
                child: SafeArea(
                  child: Placeholder(key: insideBody),
                ),
              ),
              floatingActionButton: SizedBox(
                key: floatingActionButton,
                width: 77.0,
                height: 77.0,
                child: SafeArea(
                  child: Placeholder(key: insideFloatingActionButton),
                ),
              ),
              persistentFooterButtons: <Widget>[
                SizedBox(
                  key: persistentFooterButton,
                  width: 100.0,
                  height: 90.0,
                  child: SafeArea(
                    child: Placeholder(key: insidePersistentFooterButton),
                  ),
                ),
              ],
              drawer: Container(
                key: drawer,
                width: 204.0,
                child: SafeArea(
                  child: Placeholder(key: insideDrawer),
                ),
              ),
              bottomNavigationBar: SizedBox(
                key: bottomNavigationBar,
                height: 85.0,
                child: SafeArea(
                  child: Placeholder(key: insideBottomNavigationBar),
                ),
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

    expect(tester.getRect(find.byKey(appBar)), Rect.fromLTRB(0.0, 0.0, 800.0, 43.0));
    expect(tester.getRect(find.byKey(body)), Rect.fromLTRB(0.0, 43.0, 800.0, 348.0));
    expect(tester.getRect(find.byKey(floatingActionButton)), Rect.fromLTRB(36.0, 255.0, 113.0, 332.0));
    expect(tester.getRect(find.byKey(persistentFooterButton)), Rect.fromLTRB(28.0, 357.0, 128.0, 447.0)); // Note: has 8px each top/bottom padding.
    expect(tester.getRect(find.byKey(drawer)), Rect.fromLTRB(596.0, 0.0, 800.0, 600.0));
    expect(tester.getRect(find.byKey(bottomNavigationBar)), Rect.fromLTRB(0.0, 515.0, 800.0, 600.0));
    expect(tester.getRect(find.byKey(insideAppBar)), Rect.fromLTRB(20.0, 30.0, 750.0, 43.0));
    expect(tester.getRect(find.byKey(insideBody)), Rect.fromLTRB(20.0, 43.0, 750.0, 348.0));
    expect(tester.getRect(find.byKey(insideFloatingActionButton)), Rect.fromLTRB(36.0, 255.0, 113.0, 332.0));
    expect(tester.getRect(find.byKey(insidePersistentFooterButton)), Rect.fromLTRB(28.0, 357.0, 128.0, 447.0));
    expect(tester.getRect(find.byKey(insideDrawer)), Rect.fromLTRB(596.0, 30.0, 750.0, 540.0));
    expect(tester.getRect(find.byKey(insideBottomNavigationBar)), Rect.fromLTRB(20.0, 515.0, 750.0, 540.0));
  });

  testWidgets('Scaffold and extreme window padding - persistent footer buttons only', (WidgetTester tester) async {
    final Key appBar = UniqueKey();
    final Key body = UniqueKey();
    final Key floatingActionButton = UniqueKey();
    final Key persistentFooterButton = UniqueKey();
    final Key drawer = UniqueKey();
    final Key insideAppBar = UniqueKey();
    final Key insideBody = UniqueKey();
    final Key insideFloatingActionButton = UniqueKey();
    final Key insidePersistentFooterButton = UniqueKey();
    final Key insideDrawer = UniqueKey();
    await tester.pumpWidget(
      Localizations(
        locale: const Locale('en', 'us'),
        delegates: const <LocalizationsDelegate<dynamic>>[
          DefaultWidgetsLocalizations.delegate,
          DefaultMaterialLocalizations.delegate,
        ],
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: MediaQuery(
            data: const MediaQueryData(
              padding: EdgeInsets.only(
                left: 20.0,
                top: 30.0,
                right: 50.0,
                bottom: 60.0,
              ),
              viewInsets: EdgeInsets.only(bottom: 200.0),
            ),
            child: Scaffold(
              appBar: PreferredSize(
                preferredSize: const Size(11.0, 13.0),
                child: Container(
                  key: appBar,
                  child: SafeArea(
                    child: Placeholder(key: insideAppBar),
                  ),
                ),
              ),
              body: Container(
                key: body,
                child: SafeArea(
                  child: Placeholder(key: insideBody),
                ),
              ),
              floatingActionButton: SizedBox(
                key: floatingActionButton,
                width: 77.0,
                height: 77.0,
                child: SafeArea(
                  child: Placeholder(key: insideFloatingActionButton),
                ),
              ),
              persistentFooterButtons: <Widget>[
                SizedBox(
                  key: persistentFooterButton,
                  width: 100.0,
                  height: 90.0,
                  child: SafeArea(
                    child: Placeholder(key: insidePersistentFooterButton),
                  ),
                ),
              ],
              drawer: Container(
                key: drawer,
                width: 204.0,
                child: SafeArea(
                  child: Placeholder(key: insideDrawer),
                ),
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

    expect(tester.getRect(find.byKey(appBar)), Rect.fromLTRB(0.0, 0.0, 800.0, 43.0));
    expect(tester.getRect(find.byKey(body)), Rect.fromLTRB(0.0, 43.0, 800.0, 400.0));
    expect(tester.getRect(find.byKey(floatingActionButton)), Rect.fromLTRB(36.0, 307.0, 113.0, 384.0));
    expect(tester.getRect(find.byKey(persistentFooterButton)), Rect.fromLTRB(28.0, 442.0, 128.0, 532.0)); // Note: has 8px each top/bottom padding.
    expect(tester.getRect(find.byKey(drawer)), Rect.fromLTRB(596.0, 0.0, 800.0, 600.0));
    expect(tester.getRect(find.byKey(insideAppBar)), Rect.fromLTRB(20.0, 30.0, 750.0, 43.0));
    expect(tester.getRect(find.byKey(insideBody)), Rect.fromLTRB(20.0, 43.0, 750.0, 400.0));
    expect(tester.getRect(find.byKey(insideFloatingActionButton)), Rect.fromLTRB(36.0, 307.0, 113.0, 384.0));
    expect(tester.getRect(find.byKey(insidePersistentFooterButton)), Rect.fromLTRB(28.0, 442.0, 128.0, 532.0));
    expect(tester.getRect(find.byKey(insideDrawer)), Rect.fromLTRB(596.0, 30.0, 750.0, 540.0));
  });


  group('ScaffoldGeometry', () {
    testWidgets('bottomNavigationBar', (WidgetTester tester) async {
      final GlobalKey key = GlobalKey();
      await tester.pumpWidget(MaterialApp(home: Scaffold(
            body: Container(),
            bottomNavigationBar: ConstrainedBox(
              key: key,
              constraints: const BoxConstraints.expand(height: 80.0),
              child: _GeometryListener(),
            ),
      )));

      final RenderBox navigationBox = tester.renderObject(find.byKey(key));
      final RenderBox appBox = tester.renderObject(find.byType(MaterialApp));
      final _GeometryListenerState listenerState = tester.state(find.byType(_GeometryListener));
      final ScaffoldGeometry geometry = listenerState.cache.value;

      expect(
        geometry.bottomNavigationBarTop,
        appBox.size.height - navigationBox.size.height
      );
    });

    testWidgets('no bottomNavigationBar', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(
            body: ConstrainedBox(
              constraints: const BoxConstraints.expand(height: 80.0),
              child: _GeometryListener(),
            ),
      )));

      final _GeometryListenerState listenerState = tester.state(find.byType(_GeometryListener));
      final ScaffoldGeometry geometry = listenerState.cache.value;

      expect(
        geometry.bottomNavigationBarTop,
        null
      );
    });

    testWidgets('floatingActionButton', (WidgetTester tester) async {
      final GlobalKey key = GlobalKey();
      await tester.pumpWidget(MaterialApp(home: Scaffold(
            body: Container(),
            floatingActionButton: FloatingActionButton(
              key: key,
              child: _GeometryListener(),
              onPressed: () {},
            ),
      )));

      final RenderBox floatingActionButtonBox = tester.renderObject(find.byKey(key));
      final _GeometryListenerState listenerState = tester.state(find.byType(_GeometryListener));
      final ScaffoldGeometry geometry = listenerState.cache.value;

      final Rect fabRect = floatingActionButtonBox.localToGlobal(Offset.zero) & floatingActionButtonBox.size;

      expect(
        geometry.floatingActionButtonArea,
        fabRect
      );
    });

    testWidgets('no floatingActionButton', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(
            body: ConstrainedBox(
              constraints: const BoxConstraints.expand(height: 80.0),
              child: _GeometryListener(),
            ),
      )));

      final _GeometryListenerState listenerState = tester.state(find.byType(_GeometryListener));
      final ScaffoldGeometry geometry = listenerState.cache.value;

      expect(
          geometry.floatingActionButtonArea,
          null
      );
    });

    testWidgets('floatingActionButton entrance/exit animation', (WidgetTester tester) async {
      final GlobalKey key = GlobalKey();
      await tester.pumpWidget(MaterialApp(home: Scaffold(
            body: ConstrainedBox(
              constraints: const BoxConstraints.expand(height: 80.0),
              child: _GeometryListener(),
            ),
      )));

      await tester.pumpWidget(MaterialApp(home: Scaffold(
            body: Container(),
            floatingActionButton: FloatingActionButton(
              key: key,
              child: _GeometryListener(),
              onPressed: () {},
            ),
      )));

      final _GeometryListenerState listenerState = tester.state(find.byType(_GeometryListener));
      await tester.pump(const Duration(milliseconds: 50));

      ScaffoldGeometry geometry = listenerState.cache.value;

      final Rect transitioningFabRect = geometry.floatingActionButtonArea;

      await tester.pump(const Duration(seconds: 3));
      geometry = listenerState.cache.value;
      final RenderBox floatingActionButtonBox = tester.renderObject(find.byKey(key));
      final Rect fabRect = floatingActionButtonBox.localToGlobal(Offset.zero) & floatingActionButtonBox.size;

      expect(
        geometry.floatingActionButtonArea,
        fabRect
      );

      expect(
        geometry.floatingActionButtonArea.center,
        transitioningFabRect.center
      );

      expect(
        geometry.floatingActionButtonArea.width,
        greaterThan(transitioningFabRect.width)
      );

      expect(
        geometry.floatingActionButtonArea.height,
        greaterThan(transitioningFabRect.height)
      );
    });

    testWidgets('change notifications', (WidgetTester tester) async {
      final GlobalKey key = GlobalKey();
      int numNotificationsAtLastFrame = 0;
      await tester.pumpWidget(MaterialApp(home: Scaffold(
            body: ConstrainedBox(
              constraints: const BoxConstraints.expand(height: 80.0),
              child: _GeometryListener(),
            ),
      )));

      final _GeometryListenerState listenerState = tester.state(find.byType(_GeometryListener));

      expect(listenerState.numNotifications, greaterThan(numNotificationsAtLastFrame));
      numNotificationsAtLastFrame = listenerState.numNotifications;

      await tester.pumpWidget(MaterialApp(home: Scaffold(
            body: Container(),
            floatingActionButton: FloatingActionButton(
              key: key,
              child: _GeometryListener(),
              onPressed: () {},
            ),
      )));

      expect(listenerState.numNotifications, greaterThan(numNotificationsAtLastFrame));
      numNotificationsAtLastFrame = listenerState.numNotifications;

      await tester.pump(const Duration(milliseconds: 50));

      expect(listenerState.numNotifications, greaterThan(numNotificationsAtLastFrame));
      numNotificationsAtLastFrame = listenerState.numNotifications;

      await tester.pump(const Duration(seconds: 3));

      expect(listenerState.numNotifications, greaterThan(numNotificationsAtLastFrame));
      numNotificationsAtLastFrame = listenerState.numNotifications;
    });

    testWidgets('Simultaneous drawers on either side', (WidgetTester tester) async {
      const String bodyLabel = 'I am the body';
      const String drawerLabel = 'I am the label on start side';
      const String endDrawerLabel = 'I am the label on end side';

      final SemanticsTester semantics = SemanticsTester(tester);
      await tester.pumpWidget(const MaterialApp(home: Scaffold(
        body: Text(bodyLabel),
        drawer: Drawer(child: Text(drawerLabel)),
        endDrawer: Drawer(child: Text(endDrawerLabel)),
      )));

      expect(semantics, includesNodeWith(label: bodyLabel));
      expect(semantics, isNot(includesNodeWith(label: drawerLabel)));
      expect(semantics, isNot(includesNodeWith(label: endDrawerLabel)));

      final ScaffoldState state = tester.firstState(find.byType(Scaffold));
      state.openDrawer();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(semantics, isNot(includesNodeWith(label: bodyLabel)));
      expect(semantics, includesNodeWith(label: drawerLabel));

      state.openEndDrawer();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(semantics, isNot(includesNodeWith(label: bodyLabel)));
      expect(semantics, includesNodeWith(label: endDrawerLabel));

      semantics.dispose();
    });

    testWidgets('Drawer state query correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SafeArea(
            left: false,
            top: true,
            right: false,
            bottom: false,
            child: Scaffold(
              endDrawer: const Drawer(
                child: Text('endDrawer'),
              ),
              drawer: const Drawer(
                child: Text('drawer'),
              ),
              body: const Text('scaffold body'),
              appBar: AppBar(
                centerTitle: true,
                title: const Text('Title')
              ),
            ),
          ),
        ),
      );

      final ScaffoldState scaffoldState = tester.state(find.byType(Scaffold));

      final Finder drawerOpenButton = find.byType(IconButton).first;
      final Finder endDrawerOpenButton = find.byType(IconButton).last;

      await tester.tap(drawerOpenButton);
      await tester.pumpAndSettle();
      expect(true, scaffoldState.isDrawerOpen);
      await tester.tap(endDrawerOpenButton);
      await tester.pumpAndSettle();
      expect(false, scaffoldState.isDrawerOpen);

      await tester.tap(endDrawerOpenButton);
      await tester.pumpAndSettle();
      expect(true, scaffoldState.isEndDrawerOpen);
      await tester.tap(drawerOpenButton);
      await tester.pumpAndSettle();
      expect(false, scaffoldState.isEndDrawerOpen);

      scaffoldState.openDrawer();
      expect(true, scaffoldState.isDrawerOpen);
      await tester.tap(drawerOpenButton);
      await tester.pumpAndSettle();

      scaffoldState.openEndDrawer();
      expect(true, scaffoldState.isEndDrawerOpen);
    });

    testWidgets('Dual Drawer Opening', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SafeArea(
            left: false,
            top: true,
            right: false,
            bottom: false,
            child: Scaffold(
              endDrawer: const Drawer(
                child: Text('endDrawer'),
              ),
              drawer: const Drawer(
                child: Text('drawer'),
              ),
              body: const Text('scaffold body'),
              appBar: AppBar(
                centerTitle: true,
                title: const Text('Title')
              )
            ),
          ),
        ),
      );

      // Open Drawer, tap on end drawer, which closes the drawer, but does
      // not open the drawer.
      await tester.tap(find.byType(IconButton).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(IconButton).last);
      await tester.pumpAndSettle();

      expect(find.text('endDrawer'), findsNothing);
      expect(find.text('drawer'), findsNothing);

      // Tapping the first opens the first drawer
      await tester.tap(find.byType(IconButton).first);
      await tester.pumpAndSettle();

      expect(find.text('endDrawer'), findsNothing);
      expect(find.text('drawer'), findsOneWidget);

      // Tapping on the end drawer and then on the drawer should close the
      // drawer and then reopen it.
      await tester.tap(find.byType(IconButton).last);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(IconButton).first);
      await tester.pumpAndSettle();

      expect(find.text('endDrawer'), findsNothing);
      expect(find.text('drawer'), findsOneWidget);
    });

    testWidgets('Drawer opens correctly with padding from MediaQuery', (WidgetTester tester) async {
      // The padding described by MediaQuery is larger than the default
      // drawer drag zone width which is 20.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            drawer: const Drawer(
              child: Text('drawer'),
            ),
            body: const Text('scaffold body'),
            appBar: AppBar(
              centerTitle: true,
              title: const Text('Title')
            ),
          ),
        ),
      );

      ScaffoldState scaffoldState = tester.state(find.byType(Scaffold));

      expect(scaffoldState.isDrawerOpen, false);

      await tester.dragFrom(const Offset(35, 100), const Offset(300, 0));
      await tester.pumpAndSettle();

      expect(scaffoldState.isDrawerOpen, false);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              padding: EdgeInsets.fromLTRB(40, 0, 0, 0)
            ),
            child: Scaffold(
              drawer: const Drawer(
                child: Text('drawer'),
              ),
              body: const Text('scaffold body'),
              appBar: AppBar(
                centerTitle: true,
                title: const Text('Title')
              ),
            ),
          ),
        ),
      );

      scaffoldState = tester.state(find.byType(Scaffold));

      expect(scaffoldState.isDrawerOpen, false);

      await tester.dragFrom(const Offset(35, 100), const Offset(300, 0));
      await tester.pumpAndSettle();

      expect(scaffoldState.isDrawerOpen, true);
    });

    testWidgets('Drawer opens correctly with padding from MediaQuer (RTL)', (WidgetTester tester) async {
      // The padding described by MediaQuery is larger than the default
      // drawer drag zone width which is 20.
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              padding: EdgeInsets.fromLTRB(0, 0, 40, 0)
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                drawer: const Drawer(
                  child: Text('drawer'),
                ),
                body: const Text('scaffold body'),
                appBar: AppBar(
                  centerTitle: true,
                  title: const Text('Title')
                ),
              ),
            ),
          ),
        ),
      );

      final ScaffoldState scaffoldState = tester.state(find.byType(Scaffold));

      expect(scaffoldState.isDrawerOpen, false);

      await tester.dragFrom(const Offset(765, 100), const Offset(-300, 0));
      await tester.pumpAndSettle();

      expect(scaffoldState.isDrawerOpen, true);
    });
  });
}

class _GeometryListener extends StatefulWidget {
  @override
  _GeometryListenerState createState() => _GeometryListenerState();
}

class _GeometryListenerState extends State<_GeometryListener> {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: cache
    );
  }

  int numNotifications = 0;
  ValueListenable<ScaffoldGeometry> geometryListenable;
  _GeometryCachePainter cache;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ValueListenable<ScaffoldGeometry> newListenable = Scaffold.geometryOf(context);
    if (geometryListenable == newListenable)
      return;

    if (geometryListenable != null)
      geometryListenable.removeListener(onGeometryChanged);

    geometryListenable = newListenable;
    geometryListenable.addListener(onGeometryChanged);
    cache = _GeometryCachePainter(geometryListenable);
  }

  void onGeometryChanged() {
    numNotifications += 1;
  }
}

// The Scaffold.geometryOf() value is only available at paint time.
// To fetch it for the tests we implement this CustomPainter that just
// caches the ScaffoldGeometry value in its paint method.
class _GeometryCachePainter extends CustomPainter {
  _GeometryCachePainter(this.geometryListenable) : super(repaint: geometryListenable);

  final ValueListenable<ScaffoldGeometry> geometryListenable;

  ScaffoldGeometry value;
  @override
  void paint(Canvas canvas, Size size) {
    value = geometryListenable.value;
  }

  @override
  bool shouldRepaint(_GeometryCachePainter oldDelegate) {
    return true;
  }
}

class _CustomPageRoute<T> extends PageRoute<T> {
  _CustomPageRoute({
    @required this.builder,
    RouteSettings settings = const RouteSettings(),
    this.maintainState = true,
    bool fullscreenDialog = false,
  }) : assert(builder != null),
       super(settings: settings, fullscreenDialog: fullscreenDialog);

  final WidgetBuilder builder;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  Color get barrierColor => null;

  @override
  String get barrierLabel => null;

  @override
  final bool maintainState;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return builder(context);
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return child;
  }
}
