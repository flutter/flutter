// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show DragStartBehavior;
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
        resizeToAvoidBottomInset: false,
      ),
    )));

    bodyBox = tester.renderObject(find.byKey(bodyKey));
    expect(bodyBox.size, equals(const Size(800.0, 544.0)));

    // Backwards compatibility: deprecated resizeToAvoidBottomPadding flag
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
      ),
    )));

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

  testWidgets('Floating Action Button bottom padding not consumed by viewInsets', (WidgetTester tester) async {
    final Widget child = Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Container(),
        floatingActionButton: const Placeholder(),
      ),
    );

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          padding: EdgeInsets.only(bottom: 20.0),
        ),
        child: child,
      ),
    );
    final Offset initialPoint = tester.getCenter(find.byType(Placeholder));
    // Consume bottom padding - as if by the keyboard opening
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          padding: EdgeInsets.zero,
          viewPadding: EdgeInsets.only(bottom: 20),
          viewInsets: EdgeInsets.only(bottom: 300),
        ),
        child: child,
      ),
    );
    final Offset finalPoint = tester.getCenter(find.byType(Placeholder));
    expect(initialPoint, finalPoint);
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
              dragStartBehavior: DragStartBehavior.down,
              controller: scrollOffset,
              children: List<Widget>.generate(10,
                (int index) => SizedBox(height: 100.0, child: Text('D$index')),
              ),
            ),
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
        ),
      ),
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
                title: Text('Title'),
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

  testWidgets('Tapping the status bar scrolls to top', (WidgetTester tester) async {
    await tester.pumpWidget(_buildStatusBarTestApp(debugDefaultTargetPlatformOverride));
    final ScrollableState scrollable = tester.state(find.byType(Scrollable));
    scrollable.position.jumpTo(500.0);
    expect(scrollable.position.pixels, equals(500.0));
    await tester.tapAt(const Offset(100.0, 10.0));
    await tester.pumpAndSettle();
    expect(scrollable.position.pixels, equals(0.0));
  }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS,  TargetPlatform.macOS }));

  testWidgets('Tapping the status bar does not scroll to top', (WidgetTester tester) async {
    await tester.pumpWidget(_buildStatusBarTestApp(TargetPlatform.android));
    final ScrollableState scrollable = tester.state(find.byType(Scrollable));
    scrollable.position.jumpTo(500.0);
    expect(scrollable.position.pixels, equals(500.0));
    await tester.tapAt(const Offset(100.0, 10.0));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(scrollable.position.pixels, equals(500.0));
  }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.android }));

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

  testWidgets('BottomSheet bottom padding is not consumed by viewInsets', (WidgetTester tester) async {
    final Widget child = Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Container(),
        bottomSheet: const Placeholder(),
      ),
    );

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          padding: EdgeInsets.only(bottom: 20.0),
        ),
        child: child,
      ),
    );
    final Offset initialPoint = tester.getCenter(find.byType(Placeholder));
    // Consume bottom padding - as if by the keyboard opening
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          padding: EdgeInsets.zero,
          viewPadding: EdgeInsets.only(bottom: 20),
          viewInsets: EdgeInsets.only(bottom: 300),
        ),
        child: child,
      ),
    );
    final Offset finalPoint = tester.getCenter(find.byType(Placeholder));
    expect(initialPoint, finalPoint);
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
            TextButton(
              onPressed: () {
                didPressButton = true;
              },
              child: const Text('X'),
            ),
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

  testWidgets('Persistent bottom buttons bottom padding is not consumed by viewInsets', (WidgetTester tester) async {
    final Widget child = Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Container(),
        persistentFooterButtons: const <Widget>[Placeholder()],
      ),
    );

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          padding: EdgeInsets.only(bottom: 20.0),
        ),
        child: child,
      ),
    );
    final Offset initialPoint = tester.getCenter(find.byType(Placeholder));
    // Consume bottom padding - as if by the keyboard opening
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          padding: EdgeInsets.zero,
          viewPadding: EdgeInsets.only(bottom: 20),
          viewInsets: EdgeInsets.only(bottom: 300),
        ),
        child: child,
      ),
    );
    final Offset finalPoint = tester.getCenter(find.byType(Placeholder));
    expect(initialPoint, finalPoint);
  });

  group('back arrow', () {
    Future<void> expectBackIcon(WidgetTester tester, IconData expectedIcon) async {
      final GlobalKey rootKey = GlobalKey();
      final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
        '/': (_) => Container(key: rootKey, child: const Text('Home')),
        '/scaffold': (_) => Scaffold(
            appBar: AppBar(),
            body: const Text('Scaffold'),
        ),
      };
      await tester.pumpWidget(MaterialApp(routes: routes));

      Navigator.pushNamed(rootKey.currentContext, '/scaffold');
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final Icon icon = tester.widget(find.byType(Icon));
      expect(icon.icon, expectedIcon);
    }

    testWidgets('Back arrow uses correct default', (WidgetTester tester) async {
      await expectBackIcon(tester, Icons.arrow_back);
    }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.android, TargetPlatform.fuchsia }));

    testWidgets('Back arrow uses correct default', (WidgetTester tester) async {
      await expectBackIcon(tester, Icons.arrow_back_ios);
    }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS,  TargetPlatform.macOS }));
  });

  group('close button', () {
    Future<void> expectCloseIcon(WidgetTester tester, PageRoute<void> routeBuilder(), String type) async {
      const IconData expectedIcon = Icons.close;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(appBar: AppBar(), body: const Text('Page 1')),
        ),
      );

      tester.state<NavigatorState>(find.byType(Navigator)).push(routeBuilder());

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final Icon icon = tester.widget(find.byType(Icon));
      expect(icon.icon, expectedIcon, reason: "didn't find close icon for $type");
      expect(find.byType(CloseButton), findsOneWidget, reason: "didn't find close button for $type");
    }

    PageRoute<void> materialRouteBuilder() {
      return MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return Scaffold(appBar: AppBar(), body: const Text('Page 2'));
        },
        fullscreenDialog: true,
      );
    }

    PageRoute<void> pageRouteBuilder() {
      return PageRouteBuilder<void>(
        pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
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

    testWidgets('Close button shows correctly', (WidgetTester tester) async {
      await expectCloseIcon(tester, materialRouteBuilder, 'materialRouteBuilder');
    }, variant: TargetPlatformVariant.all());

    testWidgets('Close button shows correctly with PageRouteBuilder', (WidgetTester tester) async {
      await expectCloseIcon(tester, pageRouteBuilder, 'pageRouteBuilder');
    }, variant: TargetPlatformVariant.all());

    testWidgets('Close button shows correctly with custom page route', (WidgetTester tester) async {
      await expectCloseIcon(tester, customPageRouteBuilder, 'customPageRouteBuilder');
    }, variant: TargetPlatformVariant.all());
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
            body: TextButton(
              key: testKey,
              onPressed: () { },
              child: const Text(''),
            ),
          ),
        ),
      ));
      expect(tester.element(find.byKey(testKey)).size, const Size(64.0, 48.0));
      expect(tester.renderObject<RenderBox>(find.byKey(testKey)).localToGlobal(Offset.zero), const Offset(0.0, 0.0));
    });

    testWidgets('body size with extendBody', (WidgetTester tester) async {
      final Key bodyKey = UniqueKey();
      double mediaQueryBottom;

      Widget buildFrame({ bool extendBody, bool resizeToAvoidBottomInset, double viewInsetBottom = 0.0 }) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: MediaQueryData(
              viewInsets: EdgeInsets.only(bottom: viewInsetBottom),
            ),
            child: Scaffold(
              resizeToAvoidBottomInset: resizeToAvoidBottomInset,
              extendBody: extendBody,
              body: Builder(
                builder: (BuildContext context) {
                  mediaQueryBottom = MediaQuery.of(context).padding.bottom;
                  return Container(key: bodyKey);
                },
              ),
              bottomNavigationBar: const BottomAppBar(
                child: SizedBox(height: 48.0,),
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(buildFrame(extendBody: true));
      expect(tester.getSize(find.byKey(bodyKey)), const Size(800.0, 600.0));
      expect(mediaQueryBottom, 48.0);

      await tester.pumpWidget(buildFrame(extendBody: false));
      expect(tester.getSize(find.byKey(bodyKey)), const Size(800.0, 552.0)); // 552 = 600 - 48 (BAB height)
      expect(mediaQueryBottom, 0.0);

      // If resizeToAvoidBottomInsets is false, same results as if it was unspecified (null).
      await tester.pumpWidget(buildFrame(extendBody: true, resizeToAvoidBottomInset: false, viewInsetBottom: 100.0));
      expect(tester.getSize(find.byKey(bodyKey)), const Size(800.0, 600.0));
      expect(mediaQueryBottom, 48.0);

      await tester.pumpWidget(buildFrame(extendBody: false, resizeToAvoidBottomInset: false, viewInsetBottom: 100.0));
      expect(tester.getSize(find.byKey(bodyKey)), const Size(800.0, 552.0));
      expect(mediaQueryBottom, 0.0);

      // If resizeToAvoidBottomInsets is true and viewInsets.bottom is > the bottom
      // navigation bar's height then the body always resizes and the MediaQuery
      // isn't adjusted. This case corresponds to the keyboard appearing.
      await tester.pumpWidget(buildFrame(extendBody: true, resizeToAvoidBottomInset: true, viewInsetBottom: 100.0));
      expect(tester.getSize(find.byKey(bodyKey)), const Size(800.0, 500.0));
      expect(mediaQueryBottom, 0.0);

      await tester.pumpWidget(buildFrame(extendBody: false, resizeToAvoidBottomInset: true, viewInsetBottom: 100.0));
      expect(tester.getSize(find.byKey(bodyKey)), const Size(800.0, 500.0));
      expect(mediaQueryBottom, 0.0);
    });

    testWidgets('body size with extendBodyBehindAppBar', (WidgetTester tester) async {
      final Key appBarKey = UniqueKey();
      final Key bodyKey = UniqueKey();

      const double appBarHeight = 100;
      const double windowPaddingTop = 24;
      bool fixedHeightAppBar;
      double mediaQueryTop;

      Widget buildFrame({ bool extendBodyBehindAppBar, bool hasAppBar }) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(
              padding: EdgeInsets.only(top: windowPaddingTop),
            ),
            child: Builder(
              builder: (BuildContext context) {
                return Scaffold(
                  extendBodyBehindAppBar: extendBodyBehindAppBar,
                  appBar: !hasAppBar ? null : PreferredSize(
                    key: appBarKey,
                    preferredSize: const Size.fromHeight(appBarHeight),
                    child: Container(
                      constraints: BoxConstraints(
                        minHeight: appBarHeight,
                        maxHeight: fixedHeightAppBar ? appBarHeight : double.infinity,
                      ),
                    ),
                  ),
                  body: Builder(
                    builder: (BuildContext context) {
                      mediaQueryTop = MediaQuery.of(context).padding.top;
                      return Container(key: bodyKey);
                    }
                  ),
                );
              },
            ),
          ),
        );
      }

      fixedHeightAppBar = false;

      // When an appbar is provided, the Scaffold's body is built within a
      // MediaQuery with padding.top = 0, and the appBar's maxHeight is
      // constrained to its preferredSize.height + the original MediaQuery
      // padding.top. When extendBodyBehindAppBar is true, an additional
      // inner MediaQuery is added around the Scaffold's body with padding.top
      // equal to the overall height of the appBar. See _BodyBuilder in
      // material/scaffold.dart.

      await tester.pumpWidget(buildFrame(extendBodyBehindAppBar: true, hasAppBar: true));
      expect(tester.getSize(find.byKey(bodyKey)), const Size(800.0, 600.0));
      expect(tester.getSize(find.byKey(appBarKey)), const Size(800.0, appBarHeight + windowPaddingTop));
      expect(mediaQueryTop, appBarHeight + windowPaddingTop);

      await tester.pumpWidget(buildFrame(extendBodyBehindAppBar: true, hasAppBar: false));
      expect(tester.getSize(find.byKey(bodyKey)), const Size(800.0, 600.0));
      expect(find.byKey(appBarKey), findsNothing);
      expect(mediaQueryTop, windowPaddingTop);

      await tester.pumpWidget(buildFrame(extendBodyBehindAppBar: false, hasAppBar: true));
      expect(tester.getSize(find.byKey(bodyKey)), const Size(800.0, 600.0 - appBarHeight - windowPaddingTop));
      expect(tester.getSize(find.byKey(appBarKey)), const Size(800.0, appBarHeight + windowPaddingTop));
      expect(mediaQueryTop, 0.0);

      await tester.pumpWidget(buildFrame(extendBodyBehindAppBar: false, hasAppBar: false));
      expect(tester.getSize(find.byKey(bodyKey)), const Size(800.0, 600.0));
      expect(find.byKey(appBarKey), findsNothing);
      expect(mediaQueryTop, windowPaddingTop);

      fixedHeightAppBar = true;

      await tester.pumpWidget(buildFrame(extendBodyBehindAppBar: true, hasAppBar: true));
      expect(tester.getSize(find.byKey(bodyKey)), const Size(800.0, 600.0));
      expect(tester.getSize(find.byKey(appBarKey)), const Size(800.0, appBarHeight));
      expect(mediaQueryTop, appBarHeight);

      await tester.pumpWidget(buildFrame(extendBodyBehindAppBar: true, hasAppBar: false));
      expect(tester.getSize(find.byKey(bodyKey)), const Size(800.0, 600.0));
      expect(find.byKey(appBarKey), findsNothing);
      expect(mediaQueryTop, windowPaddingTop);

      await tester.pumpWidget(buildFrame(extendBodyBehindAppBar: false, hasAppBar: true));
      expect(tester.getSize(find.byKey(bodyKey)), const Size(800.0, 600.0 - appBarHeight));
      expect(tester.getSize(find.byKey(appBarKey)), const Size(800.0, appBarHeight));
      expect(mediaQueryTop, 0.0);

      await tester.pumpWidget(buildFrame(extendBodyBehindAppBar: false, hasAppBar: false));
      expect(tester.getSize(find.byKey(bodyKey)), const Size(800.0, 600.0));
      expect(find.byKey(appBarKey), findsNothing);
      expect(mediaQueryTop, windowPaddingTop);
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
              drawerDragStartBehavior: DragStartBehavior.down,
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

    expect(tester.getRect(find.byKey(appBar)), const Rect.fromLTRB(0.0, 0.0, 800.0, 43.0));
    expect(tester.getRect(find.byKey(body)), const Rect.fromLTRB(0.0, 43.0, 800.0, 348.0));
    expect(tester.getRect(find.byKey(floatingActionButton)), rectMoreOrLessEquals(const Rect.fromLTRB(36.0, 255.0, 113.0, 332.0)));
    expect(tester.getRect(find.byKey(persistentFooterButton)),const  Rect.fromLTRB(28.0, 357.0, 128.0, 447.0)); // Note: has 8px each top/bottom padding.
    expect(tester.getRect(find.byKey(drawer)), const Rect.fromLTRB(596.0, 0.0, 800.0, 600.0));
    expect(tester.getRect(find.byKey(bottomNavigationBar)), const Rect.fromLTRB(0.0, 515.0, 800.0, 600.0));
    expect(tester.getRect(find.byKey(insideAppBar)), const Rect.fromLTRB(20.0, 30.0, 750.0, 43.0));
    expect(tester.getRect(find.byKey(insideBody)), const Rect.fromLTRB(20.0, 43.0, 750.0, 348.0));
    expect(tester.getRect(find.byKey(insideFloatingActionButton)), rectMoreOrLessEquals(const Rect.fromLTRB(36.0, 255.0, 113.0, 332.0)));
    expect(tester.getRect(find.byKey(insidePersistentFooterButton)), const Rect.fromLTRB(28.0, 357.0, 128.0, 447.0));
    expect(tester.getRect(find.byKey(insideDrawer)), const Rect.fromLTRB(596.0, 30.0, 750.0, 540.0));
    expect(tester.getRect(find.byKey(insideBottomNavigationBar)), const Rect.fromLTRB(20.0, 515.0, 750.0, 540.0));
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

    expect(tester.getRect(find.byKey(appBar)), const Rect.fromLTRB(0.0, 0.0, 800.0, 43.0));
    expect(tester.getRect(find.byKey(body)), const Rect.fromLTRB(0.0, 43.0, 800.0, 400.0));
    expect(tester.getRect(find.byKey(floatingActionButton)), rectMoreOrLessEquals(const Rect.fromLTRB(36.0, 307.0, 113.0, 384.0)));
    expect(tester.getRect(find.byKey(persistentFooterButton)), const Rect.fromLTRB(28.0, 442.0, 128.0, 532.0)); // Note: has 8px each top/bottom padding.
    expect(tester.getRect(find.byKey(drawer)), const Rect.fromLTRB(596.0, 0.0, 800.0, 600.0));
    expect(tester.getRect(find.byKey(insideAppBar)), const Rect.fromLTRB(20.0, 30.0, 750.0, 43.0));
    expect(tester.getRect(find.byKey(insideBody)), const Rect.fromLTRB(20.0, 43.0, 750.0, 400.0));
    expect(tester.getRect(find.byKey(insideFloatingActionButton)), rectMoreOrLessEquals(const Rect.fromLTRB(36.0, 307.0, 113.0, 384.0)));
    expect(tester.getRect(find.byKey(insidePersistentFooterButton)), const Rect.fromLTRB(28.0, 442.0, 128.0, 532.0));
    expect(tester.getRect(find.byKey(insideDrawer)), const Rect.fromLTRB(596.0, 30.0, 750.0, 540.0));
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
        appBox.size.height - navigationBox.size.height,
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
        null,
      );
    });

    testWidgets('Scaffold BottomNavigationBar bottom padding is not consumed by viewInsets.', (WidgetTester tester) async {
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

      final Widget child = boilerplate(
        Scaffold(
          resizeToAvoidBottomInset: false,
          body: const Placeholder(),
          bottomNavigationBar: Navigator(
            onGenerateRoute: (RouteSettings settings) {
              return MaterialPageRoute<void>(
                builder: (BuildContext context) {
                  return BottomNavigationBar(
                    items: const <BottomNavigationBarItem>[
                      BottomNavigationBarItem(
                        icon: Icon(Icons.add),
                        title: Text('test'),
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.add),
                        title: Text('test'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      );

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(padding: EdgeInsets.only(bottom: 20.0)),
          child: child,
        ),
      );
      final Offset initialPoint = tester.getCenter(find.byType(Placeholder));
      // Consume bottom padding - as if by the keyboard opening
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            padding: EdgeInsets.zero,
            viewPadding: EdgeInsets.only(bottom: 20),
            viewInsets: EdgeInsets.only(bottom: 300),
          ),
          child: child,
        ),
      );
      final Offset finalPoint = tester.getCenter(find.byType(Placeholder));
      expect(initialPoint, finalPoint);
    });

    testWidgets('floatingActionButton', (WidgetTester tester) async {
      final GlobalKey key = GlobalKey();
      await tester.pumpWidget(MaterialApp(home: Scaffold(
            body: Container(),
            floatingActionButton: FloatingActionButton(
              key: key,
              child: _GeometryListener(),
              onPressed: () { },
            ),
      )));

      final RenderBox floatingActionButtonBox = tester.renderObject(find.byKey(key));
      final _GeometryListenerState listenerState = tester.state(find.byType(_GeometryListener));
      final ScaffoldGeometry geometry = listenerState.cache.value;

      final Rect fabRect = floatingActionButtonBox.localToGlobal(Offset.zero) & floatingActionButtonBox.size;

      expect(
        geometry.floatingActionButtonArea,
        fabRect,
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
          null,
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
              onPressed: () { },
            ),
      )));

      final _GeometryListenerState listenerState = tester.state(find.byType(_GeometryListener));
      await tester.pump(const Duration(milliseconds: 50));

      ScaffoldGeometry geometry = listenerState.cache.value;
      final Rect transitioningFabRect = geometry.floatingActionButtonArea;

      final double transitioningRotation = tester.widget<RotationTransition>(
        find.byType(RotationTransition),
      ).turns.value;

      await tester.pump(const Duration(seconds: 3));
      geometry = listenerState.cache.value;
      final RenderBox floatingActionButtonBox = tester.renderObject(find.byKey(key));
      final Rect fabRect = floatingActionButtonBox.localToGlobal(Offset.zero) & floatingActionButtonBox.size;

      final double completedRotation = tester.widget<RotationTransition>(
        find.byType(RotationTransition),
      ).turns.value;

      expect(transitioningRotation, lessThan(1.0));

      expect(completedRotation, equals(1.0));

      expect(
        geometry.floatingActionButtonArea,
        fabRect,
      );

      expect(
        geometry.floatingActionButtonArea.center,
        transitioningFabRect.center,
      );

      expect(
        geometry.floatingActionButtonArea.width,
        greaterThan(transitioningFabRect.width),
      );

      expect(
        geometry.floatingActionButtonArea.height,
        greaterThan(transitioningFabRect.height),
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
              onPressed: () { },
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
                title: const Text('Title'),
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
                title: const Text('Title'),
              ),
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

    testWidgets('Drawer opens correctly with padding from MediaQuery (LTR)', (WidgetTester tester) async {
      const double simulatedNotchSize = 40.0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            drawer: const Drawer(
              child: Text('Drawer'),
            ),
            body: const Text('Scaffold Body'),
            appBar: AppBar(
              centerTitle: true,
              title: const Text('Title'),
            ),
          ),
        ),
      );

      ScaffoldState scaffoldState = tester.state(find.byType(Scaffold));
      expect(scaffoldState.isDrawerOpen, false);

      await tester.dragFrom(const Offset(simulatedNotchSize + 15.0, 100), const Offset(300, 0));
      await tester.pumpAndSettle();
      expect(scaffoldState.isDrawerOpen, false);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              padding: EdgeInsets.fromLTRB(simulatedNotchSize, 0, 0, 0),
            ),
            child: Scaffold(
              drawer: const Drawer(
                child: Text('Drawer'),
              ),
              body: const Text('Scaffold Body'),
              appBar: AppBar(
                centerTitle: true,
                title: const Text('Title'),
              ),
            ),
          ),
        ),
      );
      scaffoldState = tester.state(find.byType(Scaffold));
      expect(scaffoldState.isDrawerOpen, false);

      await tester.dragFrom(
        const Offset(simulatedNotchSize + 15.0, 100),
        const Offset(300, 0),
      );
      await tester.pumpAndSettle();
      expect(scaffoldState.isDrawerOpen, true);
    });

    testWidgets('Drawer opens correctly with padding from MediaQuery (RTL)', (WidgetTester tester) async {
      const double simulatedNotchSize = 40.0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            drawer: const Drawer(
              child: Text('Drawer'),
            ),
            body: const Text('Scaffold Body'),
            appBar: AppBar(
              centerTitle: true,
              title: const Text('Title'),
            ),
          ),
        ),
      );

      final double scaffoldWidth = tester.renderObject<RenderBox>(
        find.byType(Scaffold),
      ).size.width;
      ScaffoldState scaffoldState = tester.state(find.byType(Scaffold));
      expect(scaffoldState.isDrawerOpen, false);

      await tester.dragFrom(
        Offset(scaffoldWidth - simulatedNotchSize - 15.0, 100),
        const Offset(-300, 0),
      );
      await tester.pumpAndSettle();
      expect(scaffoldState.isDrawerOpen, false);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              padding: EdgeInsets.fromLTRB(0, 0, simulatedNotchSize, 0),
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                drawer: const Drawer(
                  child: Text('Drawer'),
                ),
                body: const Text('Scaffold body'),
                appBar: AppBar(
                  centerTitle: true,
                  title: const Text('Title'),
                ),
              ),
            ),
          ),
        ),
      );
      scaffoldState = tester.state(find.byType(Scaffold));
      expect(scaffoldState.isDrawerOpen, false);

      await tester.dragFrom(
        Offset(scaffoldWidth - simulatedNotchSize - 15.0, 100),
        const Offset(-300, 0),
      );
      await tester.pumpAndSettle();
      expect(scaffoldState.isDrawerOpen, true);
    });
  });

  testWidgets('Drawer opens correctly with custom edgeDragWidth', (WidgetTester tester) async {
    // The default edge drag width is 20.0.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          drawer: const Drawer(
            child: Text('Drawer'),
          ),
          body: const Text('Scaffold body'),
          appBar: AppBar(
            centerTitle: true,
            title: const Text('Title'),
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
        home: Scaffold(
          drawer: const Drawer(
            child: Text('Drawer'),
          ),
          drawerEdgeDragWidth: 40.0,
          body: const Text('Scaffold Body'),
          appBar: AppBar(
            centerTitle: true,
            title: const Text('Title'),
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

  testWidgets('Drawer does not open with a drag gesture when it is disabled', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          drawer: const Drawer(
            child: Text('Drawer'),
          ),
          drawerEnableOpenDragGesture: true,
          body: const Text('Scaffold Body'),
          appBar: AppBar(
            centerTitle: true,
            title: const Text('Title'),
          ),
        ),
      ),
    );
    ScaffoldState scaffoldState = tester.state(find.byType(Scaffold));
    expect(scaffoldState.isDrawerOpen, false);

    // Test that we can open the drawer with a drag gesture when
    // `Scaffold.drawerEnableDragGesture` is true.
    await tester.dragFrom(const Offset(0, 100), const Offset(300, 0));
    await tester.pumpAndSettle();
    expect(scaffoldState.isDrawerOpen, true);

    await tester.dragFrom(const Offset(300, 100), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(scaffoldState.isDrawerOpen, false);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          drawer: const Drawer(
            child: Text('Drawer'),
          ),
          drawerEnableOpenDragGesture: false,
          body: const Text('Scaffold body'),
          appBar: AppBar(
            centerTitle: true,
            title: const Text('Title'),
          ),
        ),
      ),
    );
    scaffoldState = tester.state(find.byType(Scaffold));
    expect(scaffoldState.isDrawerOpen, false);

    // Test that we cannot open the drawer with a drag gesture when
    // `Scaffold.drawerEnableDragGesture` is false.
    await tester.dragFrom(const Offset(0, 100), const Offset(300, 0));
    await tester.pumpAndSettle();
    expect(scaffoldState.isDrawerOpen, false);

    // Test that we can close drawer with a drag gesture when
    // `Scaffold.drawerEnableDragGesture` is false.
    final Finder drawerOpenButton = find.byType(IconButton).first;
    await tester.tap(drawerOpenButton);
    await tester.pumpAndSettle();
    expect(scaffoldState.isDrawerOpen, true);

    await tester.dragFrom(const Offset(300, 100), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(scaffoldState.isDrawerOpen, false);
  });

  testWidgets('End drawer does not open with a drag gesture when it is disabled', (WidgetTester tester) async {
    double screenWidth;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            screenWidth = MediaQuery.of(context).size.width;
            return Scaffold(
              endDrawer: const Drawer(
                child: Text('Drawer'),
              ),
              endDrawerEnableOpenDragGesture: true,
              body: const Text('Scaffold Body'),
              appBar: AppBar(
                centerTitle: true,
                title: const Text('Title'),
              ),
            );
          }
        ),
      ),
    );
    ScaffoldState scaffoldState = tester.state(find.byType(Scaffold));
    expect(scaffoldState.isEndDrawerOpen, false);

    // Test that we can open the end drawer with a drag gesture when
    // `Scaffold.endDrawerEnableDragGesture` is true.
    await tester.dragFrom(Offset(screenWidth - 1, 100), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(scaffoldState.isEndDrawerOpen, true);

    await tester.dragFrom(Offset(screenWidth - 300, 100), const Offset(300, 0));
    await tester.pumpAndSettle();
    expect(scaffoldState.isEndDrawerOpen, false);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          endDrawer: const Drawer(
            child: Text('Drawer'),
          ),
          endDrawerEnableOpenDragGesture: false,
          body: const Text('Scaffold body'),
          appBar: AppBar(
            centerTitle: true,
            title: const Text('Title'),
          ),
        ),
      ),
    );
    scaffoldState = tester.state(find.byType(Scaffold));
    expect(scaffoldState.isEndDrawerOpen, false);

    // Test that we cannot open the end drawer with a drag gesture when
    // `Scaffold.endDrawerEnableDragGesture` is false.
    await tester.dragFrom(Offset(screenWidth - 1, 100), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(scaffoldState.isEndDrawerOpen, false);

    // Test that we can close the end drawer a with drag gesture when
    // `Scaffold.endDrawerEnableDragGesture` is false.
    final Finder endDrawerOpenButton = find.byType(IconButton).first;
    await tester.tap(endDrawerOpenButton);
    await tester.pumpAndSettle();
    expect(scaffoldState.isEndDrawerOpen, true);

    await tester.dragFrom(Offset(screenWidth - 300, 100), const Offset(300, 0));
    await tester.pumpAndSettle();
    expect(scaffoldState.isEndDrawerOpen, false);
  });

  testWidgets('Nested scaffold body insets', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/20295
    final Key bodyKey = UniqueKey();

    Widget buildFrame(bool innerResizeToAvoidBottomInset, bool outerResizeToAvoidBottomInset) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(viewInsets: EdgeInsets.only(bottom: 100.0)),
          child: Builder(
            builder: (BuildContext context) {
              return Scaffold(
                resizeToAvoidBottomInset: outerResizeToAvoidBottomInset,
                body: Builder(
                  builder: (BuildContext context) {
                    return Scaffold(
                      resizeToAvoidBottomInset: innerResizeToAvoidBottomInset,
                      body: Container(key: bodyKey),
                    );
                  },
                ),
              );
            },
          ),
        ),
      );
    }

    await tester.pumpWidget(buildFrame(true, true));
    expect(tester.getSize(find.byKey(bodyKey)), const Size(800.0, 500.0));

    await tester.pumpWidget(buildFrame(false, true));
    expect(tester.getSize(find.byKey(bodyKey)), const Size(800.0, 500.0));

    await tester.pumpWidget(buildFrame(true, false));
    expect(tester.getSize(find.byKey(bodyKey)), const Size(800.0, 500.0));

    // This is the only case where the body is not bottom inset.
    await tester.pumpWidget(buildFrame(false, false));
    expect(tester.getSize(find.byKey(bodyKey)), const Size(800.0, 600.0));

    await tester.pumpWidget(buildFrame(null, null));  // resizeToAvoidBottomInset default  is true
    expect(tester.getSize(find.byKey(bodyKey)), const Size(800.0, 500.0));

    await tester.pumpWidget(buildFrame(null, false));
    expect(tester.getSize(find.byKey(bodyKey)), const Size(800.0, 500.0));

    await tester.pumpWidget(buildFrame(false, null));
    expect(tester.getSize(find.byKey(bodyKey)), const Size(800.0, 500.0));
  });

  group('FlutterError control test', () {
    testWidgets('showBottomSheet() while Scaffold has bottom sheet',
      (WidgetTester tester) async {
        final GlobalKey<ScaffoldState> key = GlobalKey<ScaffoldState>();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              key: key,
              body: Center(
                child: Container(),
              ),
              bottomSheet: Container(
                child: const Text('Bottom sheet'),
              ),
            ),
          ),
        );
        FlutterError error;
        try {
          key.currentState.showBottomSheet<void>((BuildContext context) {
            final ThemeData themeData = Theme.of(context);
            return Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: themeData.disabledColor))
              ),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text('This is a Material persistent bottom sheet. Drag downwards to dismiss it.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: themeData.accentColor,
                    fontSize: 24.0,
                  ),
                ),
              ),
            );
          },);
        } on FlutterError catch (e) {
          error = e;
        } finally {
          expect(error, isNotNull);
          expect(error.toStringDeep(), equalsIgnoringHashCodes(
            'FlutterError\n'
            '   Scaffold.bottomSheet cannot be specified while a bottom sheet\n'
            '   displayed with showBottomSheet() is still visible.\n'
            '   Rebuild the Scaffold with a null bottomSheet before calling\n'
            '   showBottomSheet().\n',
          ));
        }
      }
    );

    testWidgets('didUpdate bottomSheet while a previous bottom sheet is still displayed',
        (WidgetTester tester) async {
        final GlobalKey<ScaffoldState> key = GlobalKey<ScaffoldState>();
        const Key buttonKey = Key('button');
        final List<FlutterErrorDetails> errors = <FlutterErrorDetails>[];
        FlutterError.onError = (FlutterErrorDetails error) => errors.add(error);
        int state = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Scaffold(
                  key: key,
                  body: Container(),
                  floatingActionButton: FloatingActionButton(
                    key: buttonKey,
                    onPressed: () {
                      state += 1;
                      setState(() {});
                    }
                  ),
                  bottomSheet: state == 0 ? null : const SizedBox(),
                );
              }
            ),
          ),
        );
        key.currentState.showBottomSheet<void>((_) => Container());
        await tester.tap(find.byKey(buttonKey));
        await tester.pump();
        expect(errors, isNotEmpty);
        expect(errors.first.exception, isFlutterError);
        final FlutterError error = errors.first.exception as FlutterError;
        expect(error.diagnostics.length, 2);
        expect(error.diagnostics.last.level, DiagnosticLevel.hint);
        expect(
          error.diagnostics.last.toStringDeep(),
          'Use the PersistentBottomSheetController returned by\n'
          'showBottomSheet() to close the old bottom sheet before creating a\n'
          'Scaffold with a (non null) bottomSheet.\n',
        );
        expect(
          error.toStringDeep(),
          'FlutterError\n'
          '   Scaffold.bottomSheet cannot be specified while a bottom sheet\n'
          '   displayed with showBottomSheet() is still visible.\n'
          '   Use the PersistentBottomSheetController returned by\n'
          '   showBottomSheet() to close the old bottom sheet before creating a\n'
          '   Scaffold with a (non null) bottomSheet.\n'
        );
    });

    testWidgets('Call to Scaffold.of() without context', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              Scaffold.of(context).showBottomSheet<void>((BuildContext context) {
                return Container();
              });
              return Container();
            },
          ),
        ),
      );
      final dynamic exception = tester.takeException();
      expect(exception, isFlutterError);
      final FlutterError error = exception as FlutterError;
      expect(error.diagnostics.length, 5);
      expect(error.diagnostics[2].level, DiagnosticLevel.hint);
      expect(
        error.diagnostics[2].toStringDeep(),
        equalsIgnoringHashCodes(
          'There are several ways to avoid this problem. The simplest is to\n'
          'use a Builder to get a context that is "under" the Scaffold. For\n'
          'an example of this, please see the documentation for\n'
          'Scaffold.of():\n'
          '  https://api.flutter.dev/flutter/material/Scaffold/of.html\n',
        ),
      );
      expect(error.diagnostics[3].level, DiagnosticLevel.hint);
      expect(
        error.diagnostics[3].toStringDeep(),
        equalsIgnoringHashCodes(
          'A more efficient solution is to split your build function into\n'
          'several widgets. This introduces a new context from which you can\n'
          'obtain the Scaffold. In this solution, you would have an outer\n'
          'widget that creates the Scaffold populated by instances of your\n'
          'new inner widgets, and then in these inner widgets you would use\n'
          'Scaffold.of().\n'
          'A less elegant but more expedient solution is assign a GlobalKey\n'
          'to the Scaffold, then use the key.currentState property to obtain\n'
          'the ScaffoldState rather than using the Scaffold.of() function.\n',
        ),
      );
      expect(error.diagnostics[4], isA<DiagnosticsProperty<Element>>());
      expect(error.toStringDeep(),
        'FlutterError\n'
        '   Scaffold.of() called with a context that does not contain a\n'
        '   Scaffold.\n'
        '   No Scaffold ancestor could be found starting from the context\n'
        '   that was passed to Scaffold.of(). This usually happens when the\n'
        '   context provided is from the same StatefulWidget as that whose\n'
        '   build function actually creates the Scaffold widget being sought.\n'
        '   There are several ways to avoid this problem. The simplest is to\n'
        '   use a Builder to get a context that is "under" the Scaffold. For\n'
        '   an example of this, please see the documentation for\n'
        '   Scaffold.of():\n'
        '     https://api.flutter.dev/flutter/material/Scaffold/of.html\n'
        '   A more efficient solution is to split your build function into\n'
        '   several widgets. This introduces a new context from which you can\n'
        '   obtain the Scaffold. In this solution, you would have an outer\n'
        '   widget that creates the Scaffold populated by instances of your\n'
        '   new inner widgets, and then in these inner widgets you would use\n'
        '   Scaffold.of().\n'
        '   A less elegant but more expedient solution is assign a GlobalKey\n'
        '   to the Scaffold, then use the key.currentState property to obtain\n'
        '   the ScaffoldState rather than using the Scaffold.of() function.\n'
        '   The context used was:\n'
        '     Builder\n'
      );
      await tester.pumpAndSettle();
    });

    testWidgets('Call to Scaffold.geometryOf() without context', (WidgetTester tester) async {
      ValueListenable<ScaffoldGeometry> geometry;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              geometry = Scaffold.geometryOf(context);
              return Container();
            },
          ),
        ),
      );
      final dynamic exception = tester.takeException();
      expect(exception, isFlutterError);
      expect(geometry, isNull);
      final FlutterError error = exception as FlutterError;
      expect(error.diagnostics.length, 5);
      expect(error.diagnostics[2].level, DiagnosticLevel.hint);
      expect(
        error.diagnostics[2].toStringDeep(),
        equalsIgnoringHashCodes(
          'There are several ways to avoid this problem. The simplest is to\n'
          'use a Builder to get a context that is "under" the Scaffold. For\n'
          'an example of this, please see the documentation for\n'
          'Scaffold.of():\n'
          '  https://api.flutter.dev/flutter/material/Scaffold/of.html\n',
        ),
      );
      expect(error.diagnostics[3].level, DiagnosticLevel.hint);
      expect(
        error.diagnostics[3].toStringDeep(),
        equalsIgnoringHashCodes(
          'A more efficient solution is to split your build function into\n'
          'several widgets. This introduces a new context from which you can\n'
          'obtain the Scaffold. In this solution, you would have an outer\n'
          'widget that creates the Scaffold populated by instances of your\n'
          'new inner widgets, and then in these inner widgets you would use\n'
          'Scaffold.geometryOf().\n',
        ),
      );
      expect(error.diagnostics[4], isA<DiagnosticsProperty<Element>>());
      expect(error.toStringDeep(),
        'FlutterError\n'
        '   Scaffold.geometryOf() called with a context that does not contain\n'
        '   a Scaffold.\n'
        '   This usually happens when the context provided is from the same\n'
        '   StatefulWidget as that whose build function actually creates the\n'
        '   Scaffold widget being sought.\n'
        '   There are several ways to avoid this problem. The simplest is to\n'
        '   use a Builder to get a context that is "under" the Scaffold. For\n'
        '   an example of this, please see the documentation for\n'
        '   Scaffold.of():\n'
        '     https://api.flutter.dev/flutter/material/Scaffold/of.html\n'
        '   A more efficient solution is to split your build function into\n'
        '   several widgets. This introduces a new context from which you can\n'
        '   obtain the Scaffold. In this solution, you would have an outer\n'
        '   widget that creates the Scaffold populated by instances of your\n'
        '   new inner widgets, and then in these inner widgets you would use\n'
        '   Scaffold.geometryOf().\n'
        '   The context used was:\n'
        '     Builder\n'
      );
      await tester.pumpAndSettle();
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
