// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

Widget buildSliverAppBarApp({ bool floating, bool pinned, double expandedHeight }) {
  return new Scaffold(
    body: new DefaultTabController(
      length: 3,
      child: new CustomScrollView(
        primary: true,
        slivers: <Widget>[
          new SliverAppBar(
            title: new Text('AppBar Title'),
            floating: floating,
            pinned: pinned,
            expandedHeight: expandedHeight,
            bottom: new TabBar(
              tabs: <String>['A','B','C'].map((String t) => new Tab(text: 'TAB $t')).toList(),
            ),
          ),
          new SliverToBoxAdapter(
            child: new Container(
              height: 1200.0,
              color: Colors.orange[400],
            ),
          ),
        ],
      ),
    ),
  );
}

ScrollController primaryScrollController(WidgetTester tester) {
  return PrimaryScrollController.of(tester.element(find.byType(CustomScrollView)));
}

bool appBarIsVisible(WidgetTester tester) {
  final RenderSliver sliver = tester.element(find.byType(SliverAppBar)).findRenderObject();
  return sliver.geometry.visible;
}

double appBarHeight(WidgetTester tester) {
  final Element element = tester.element(find.byType(AppBar));
  final RenderBox box = element.findRenderObject();
  return box.size.height;
}

double tabBarHeight(WidgetTester tester) {
  final Element element = tester.element(find.byType(TabBar));
  final RenderBox box = element.findRenderObject();
  return box.size.height;
}

void main() {
  testWidgets('AppBar centers title on iOS', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        theme: new ThemeData(platform: TargetPlatform.android),
        home: new Scaffold(
          appBar: new AppBar(
            title: new Text('X'),
          ),
        ),
      ),
    );

    final Finder title = find.text('X');
    Point center = tester.getCenter(title);
    Size size = tester.getSize(title);
    expect(center.x, lessThan(400 - size.width / 2.0));

    // Clear the widget tree to avoid animating between Android and iOS.
    await tester.pumpWidget(new Container(key: new UniqueKey()));

    await tester.pumpWidget(
      new MaterialApp(
        theme: new ThemeData(platform: TargetPlatform.iOS),
        home: new Scaffold(
          appBar: new AppBar(
            title: new Text('X'),
          ),
        ),
      ),
    );

    center = tester.getCenter(title);
    size = tester.getSize(title);
    expect(center.x, greaterThan(400 - size.width / 2.0));
    expect(center.x, lessThan(400 + size.width / 2.0));
  });

  testWidgets('AppBar centerTitle:true centers on Android', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        theme: new ThemeData(platform: TargetPlatform.android),
        home: new Scaffold(
          appBar: new AppBar(
            centerTitle: true,
            title: new Text('X'),
          )
        )
      )
    );


    final Finder title = find.text('X');
    final Point center = tester.getCenter(title);
    final Size size = tester.getSize(title);
    expect(center.x, greaterThan(400 - size.width / 2.0));
    expect(center.x, lessThan(400 + size.width / 2.0));
  });

  testWidgets('AppBar centerTitle:false title left edge is 16.0 ', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        home: new Scaffold(
          appBar: new AppBar(
            centerTitle: false,
            title: new Text('X'),
          ),
        ),
      ),
    );

    expect(tester.getTopLeft(find.text('X')).x, 16.0);
  });

  testWidgets(
    'AppBar centerTitle:false leading button title left edge is 72.0 ',
    (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        home: new Scaffold(
          appBar: new AppBar(
            centerTitle: false,
            title: new Text('X'),
          ),
          // A drawer causes a leading hamburger.
          drawer: new Drawer(),
        ),
      ),
    );

    expect(tester.getTopLeft(find.text('X')).x, 72.0);
  });

  testWidgets('AppBar centerTitle:false title overflow OK ', (WidgetTester tester) async {
    // The app bar's title should be constrained to fit within the available space
    // between the leading and actions widgets.

    final Key titleKey = new UniqueKey();
    Widget leading = new Container();
    List<Widget> actions;

    Widget buildApp() {
      return new MaterialApp(
        home: new Scaffold(
          appBar: new AppBar(
            leading: leading,
            centerTitle: false,
            title: new Container(
              key: titleKey,
              constraints: new BoxConstraints.loose(const Size(1000.0, 1000.0)),
            ),
            actions: actions,
          ),
        ),
      );
    }

    await tester.pumpWidget(buildApp());

    final Finder title = find.byKey(titleKey);
    expect(tester.getTopLeft(title).x, 72.0);
    // The toolbar's contents are padded on the right by 4.0
    expect(tester.getSize(title).width, equals(800.0 - 72.0 - 4.0));

    actions = <Widget>[
      const SizedBox(width: 100.0),
      const SizedBox(width: 100.0)
    ];
    await tester.pumpWidget(buildApp());

    expect(tester.getTopLeft(title).x, 72.0);
    // The title shrinks by 200.0 to allow for the actions widgets.
    expect(tester.getSize(title).width, equals(800.0 - 72.0 - 4.0 - 200.0));

    leading = new Container(); // AppBar will constrain the width to 24.0
    await tester.pumpWidget(buildApp());
    expect(tester.getTopLeft(title).x, 72.0);
    // Adding a leading widget shouldn't effect the title's size
    expect(tester.getSize(title).width, equals(800.0 - 72.0 - 4.0 - 200.0));
  });

  testWidgets('AppBar centerTitle:true title overflow OK ', (WidgetTester tester) async {
    // The app bar's title should be constrained to fit within the available space
    // between the leading and actions widgets. When it's also centered it may
    // also be left or right justified if it doesn't fit in the overall center.

    final Key titleKey = new UniqueKey();
    double titleWidth = 700.0;
    Widget leading = new Container();
    List<Widget> actions;

    Widget buildApp() {
      return new MaterialApp(
        home: new Scaffold(
          appBar: new AppBar(
            leading: leading,
            centerTitle: true,
            title: new Container(
              key: titleKey,
              constraints: new BoxConstraints.loose(new Size(titleWidth, 1000.0)),
            ),
            actions: actions,
          ),
        ),
      );
    }

    // Centering a title with width 700 within the 800 pixel wide test widget
    // would mean that its left edge would have to be 50. The material spec says
    // that the left edge of the title must be atleast 72.
    await tester.pumpWidget(buildApp());

    final Finder title = find.byKey(titleKey);
    expect(tester.getTopLeft(title).x, 72.0);
    expect(tester.getSize(title).width, equals(700.0));

    // Centering a title with width 620 within the 800 pixel wide test widget
    // would mean that its left edge would have to be 90. We reserve 72
    // on the left and the padded actions occupy 96 + 4 on the right. That
    // leaves 628, so the title is right justified but its width isn't changed.

    await tester.pumpWidget(buildApp());
    leading = null;
    titleWidth = 620.0;
    actions = <Widget>[
      const SizedBox(width: 48.0),
      const SizedBox(width: 48.0)
    ];
    await tester.pumpWidget(buildApp());
    expect(tester.getTopLeft(title).x, 800 - 620 - 48 - 48 - 4);
    expect(tester.getSize(title).width, equals(620.0));
  });

  testWidgets('AppBar with no Scaffold', (WidgetTester tester) async {
    await tester.pumpWidget(
      new SizedBox(
        height: kToolbarHeight,
        child: new AppBar(
          leading: new Text('L'),
          title: new Text('No Scaffold'),
          actions: <Widget>[new Text('A1'), new Text('A2')],
        ),
      ),
    );

    expect(find.text('L'), findsOneWidget);
    expect(find.text('No Scaffold'), findsOneWidget);
    expect(find.text('A1'), findsOneWidget);
    expect(find.text('A2'), findsOneWidget);
  });


  testWidgets('AppBar render at zero size', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Center(
        child: new Container(
          height: 0.0,
          width: 0.0,
          child: new Scaffold(
            appBar: new AppBar(
              title: new Text('X'),
            ),
          ),
        ),
      ),
    );

    final Finder title = find.text('X');
    expect(tester.getSize(title).isEmpty, isTrue);
  });

  testWidgets('AppBar actions are vertically centered', (WidgetTester tester) async {
    final UniqueKey appBarKey = new UniqueKey();
    final UniqueKey leadingKey = new UniqueKey();
    final UniqueKey titleKey = new UniqueKey();
    final UniqueKey action0Key = new UniqueKey();
    final UniqueKey action1Key = new UniqueKey();

    await tester.pumpWidget(
      new MaterialApp(
        home: new Scaffold(
          appBar: new AppBar(
            key: appBarKey,
            leading: new SizedBox(key: leadingKey, height: 50.0),
            title: new SizedBox(key: titleKey, height: 40.0),
            actions: <Widget>[
              new SizedBox(key: action0Key, height: 20.0),
              new SizedBox(key: action1Key, height: 30.0),
            ],
          ),
        ),
      ),
    );

    // The vertical center of the widget with key, in global coordinates.
    double yCenter(Key key) => tester.getCenter(find.byKey(key)).y;

    expect(yCenter(appBarKey), equals(yCenter(leadingKey)));
    expect(yCenter(appBarKey), equals(yCenter(titleKey)));
    expect(yCenter(appBarKey), equals(yCenter(action0Key)));
    expect(yCenter(appBarKey), equals(yCenter(action1Key)));
  });

  testWidgets('leading button extends to edge and is square', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        theme: new ThemeData(platform: TargetPlatform.android),
        home: new Scaffold(
          appBar: new AppBar(
            title: new Text('X'),
          ),
          drawer: new Column(), // Doesn't really matter. Triggers a hamburger regardless.
        ),
      ),
    );

    final Finder hamburger = find.byTooltip('Open navigation menu');
    expect(tester.getTopLeft(hamburger), const Point(0.0, 0.0));
    expect(tester.getSize(hamburger), const Size(56.0, 56.0));
  });

  testWidgets('test action is 4dp from edge and 48dp min', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        theme: new ThemeData(platform: TargetPlatform.android),
        home: new Scaffold(
          appBar: new AppBar(
            title: new Text('X'),
            actions: <Widget> [
              new IconButton(
                icon: new Icon(Icons.share),
                onPressed: null,
                tooltip: 'Share',
                iconSize: 20.0,
              ),
              new IconButton(
                icon: new Icon(Icons.add),
                onPressed: null,
                tooltip: 'Add',
                iconSize: 60.0,
              ),
            ],
          ),
        ),
      ),
    );

    final Finder addButton = find.byTooltip('Add');
    // Right padding is 4dp.
    expect(tester.getTopRight(addButton), const Point(800.0 - 4.0, 0.0));
    // It's still the size it was plus the 2 * 8dp padding from IconButton.
    expect(tester.getSize(addButton), const Size(60.0 + 2 * 8.0, 56.0));

    final Finder shareButton = find.byTooltip('Share');
    // The 20dp icon is expanded to fill the IconButton's touch target to 48dp.
    expect(tester.getSize(shareButton), const Size(48.0, 56.0));
  });

  testWidgets('SliverAppBar default configuration', (WidgetTester tester) async {
    await tester.pumpWidget(buildSliverAppBarApp(
      floating: false,
      pinned: false,
      expandedHeight: null,
    ));

    final ScrollController controller = primaryScrollController(tester);
    expect(controller.offset, 0.0);
    expect(appBarIsVisible(tester), true);

    final double initialAppBarHeight = appBarHeight(tester);
    final double initialTabBarHeight = tabBarHeight(tester);

    // Scroll the not-pinned appbar partially out of view
    controller.jumpTo(50.0);
    await tester.pump();
    expect(appBarIsVisible(tester), true);
    expect(appBarHeight(tester), initialAppBarHeight);
    expect(tabBarHeight(tester), initialTabBarHeight);

    // Scroll the not-pinned appbar out of view
    controller.jumpTo(600.0);
    await tester.pump();
    expect(appBarIsVisible(tester), false);
    expect(appBarHeight(tester), initialAppBarHeight);
    expect(tabBarHeight(tester), initialTabBarHeight);

    // Scroll the not-pinned appbar back into view
    controller.jumpTo(0.0);
    await tester.pump();
    expect(appBarIsVisible(tester), true);
    expect(appBarHeight(tester), initialAppBarHeight);
    expect(tabBarHeight(tester), initialTabBarHeight);
  });

  testWidgets('SliverAppBar expandedHeight, pinned', (WidgetTester tester) async {

    await tester.pumpWidget(buildSliverAppBarApp(
      floating: false,
      pinned: true,
      expandedHeight: 128.0,
    ));

    final ScrollController controller = primaryScrollController(tester);
    expect(controller.offset, 0.0);
    expect(appBarIsVisible(tester), true);
    expect(appBarHeight(tester), 128.0);

    final double initialAppBarHeight = 128.0;
    final double initialTabBarHeight = tabBarHeight(tester);

    // Scroll the not-pinned appbar, collapsing the expanded height. At this
    // point both the toolbar and the tabbar are visible.
    controller.jumpTo(600.0);
    await tester.pump();
    expect(appBarIsVisible(tester), true);
    expect(tabBarHeight(tester), initialTabBarHeight);
    expect(appBarHeight(tester), lessThan(initialAppBarHeight));
    expect(appBarHeight(tester), greaterThan(initialTabBarHeight));

    // Scroll the not-pinned appbar back into view
    controller.jumpTo(0.0);
    await tester.pump();
    expect(appBarIsVisible(tester), true);
    expect(appBarHeight(tester), initialAppBarHeight);
    expect(tabBarHeight(tester), initialTabBarHeight);
  });

  testWidgets('SliverAppBar expandedHeight, pinned and floating', (WidgetTester tester) async {

    await tester.pumpWidget(buildSliverAppBarApp(
      floating: true,
      pinned: true,
      expandedHeight: 128.0,
    ));

    final ScrollController controller = primaryScrollController(tester);
    expect(controller.offset, 0.0);
    expect(appBarIsVisible(tester), true);
    expect(appBarHeight(tester), 128.0);

    final double initialAppBarHeight = 128.0;
    final double initialTabBarHeight = tabBarHeight(tester);

    // Scroll the not-pinned appbar, collapsing the expanded height. At this
    // point only the tabBar is visible.
    controller.jumpTo(600.0);
    await tester.pump();
    expect(appBarIsVisible(tester), true);
    expect(tabBarHeight(tester), initialTabBarHeight);
    expect(appBarHeight(tester), lessThan(initialAppBarHeight));
    expect(appBarHeight(tester), initialTabBarHeight);

    // Scroll the not-pinned appbar back into view
    controller.jumpTo(0.0);
    await tester.pump();
    expect(appBarIsVisible(tester), true);
    expect(appBarHeight(tester), initialAppBarHeight);
    expect(tabBarHeight(tester), initialTabBarHeight);
  });
}
