// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppBar centers title on iOS', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        theme: new ThemeData(platform: TargetPlatform.android),
        home: new Scaffold(
          appBar: new AppBar(
            title: new Text('X')
          )
        )
      )
    );

    Finder title = find.text('X');
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
            title: new Text('X')
          )
        )
      )
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
            title: new Text('X')
          )
        )
      )
    );


    Finder title = find.text('X');
    Point center = tester.getCenter(title);
    Size size = tester.getSize(title);
    expect(center.x, greaterThan(400 - size.width / 2.0));
    expect(center.x, lessThan(400 + size.width / 2.0));
  });

  testWidgets('AppBar centerTitle:false title left edge is 72.0 ', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        home: new Scaffold(
          appBar: new AppBar(
            centerTitle: false,
            title: new Text('X')
          )
        )
      )
    );

    expect(tester.getTopLeft(find.text('X')).x, 72.0);
  });

  testWidgets('AppBar centerTitle:false title overflow OK ', (WidgetTester tester) async {
    // The app bar's title should be constrained to fit within the available space
    // between the leading and actions widgets.

    Key titleKey = new UniqueKey();
    Widget leading;
    List<Widget> actions;

    Widget buildApp() {
      return new MaterialApp(
        home: new Scaffold(
          appBar: new AppBar(
            leading: leading,
            centerTitle: false,
            title: new Container(
              key: titleKey,
              constraints: new BoxConstraints.loose(const Size(1000.0, 1000.0))
            ),
            actions: actions
          )
        )
      );
    }

    await tester.pumpWidget(buildApp());

    Finder title = find.byKey(titleKey);
    expect(tester.getTopLeft(title).x, 72.0);
    // The toolbar's contents are padded on the right by 8.0
    expect(tester.getSize(title).width, equals(800.0 - 72.0 - 8.0));

    actions = <Widget>[
      const SizedBox(width: 100.0),
      const SizedBox(width: 100.0)
    ];
    await tester.pumpWidget(buildApp());

    expect(tester.getTopLeft(title).x, 72.0);
    // The title shrinks by 200.0 to allow for the actions widgets.
    expect(tester.getSize(title).width, equals(800.0 - 72.0 - 8.0 - 200.0));

    leading = new Container(); // AppBar will constrain the width to 24.0
    await tester.pumpWidget(buildApp());
    expect(tester.getTopLeft(title).x, 72.0);
    // Adding a leading widget shouldn't effect the title's size
    expect(tester.getSize(title).width, equals(800.0 - 72.0 - 8.0 - 200.0));
  });

  testWidgets('AppBar centerTitle:true title overflow OK ', (WidgetTester tester) async {
    // The app bar's title should be constrained to fit within the available space
    // between the leading and actions widgets. When it's also centered it may
    // also be left or right justified if it doesn't fit in the overall center.

    Key titleKey = new UniqueKey();
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
              constraints: new BoxConstraints.loose(new Size(titleWidth, 1000.0))
            ),
            actions: actions
          )
        )
      );
    }

    // Centering a title with width 700 within the 800 pixel wide test widget
    // would mean that its left edge would have to be 50. The material spec says
    // that the left edge of the title must be atleast 72.
    await tester.pumpWidget(buildApp());

    Finder title = find.byKey(titleKey);
    expect(tester.getTopLeft(title).x, 72.0);
    expect(tester.getSize(title).width, equals(700.0));

    // Centering a title with width 620 within the 800 pixel wide test widget
    // would mean that its left edge would have to be 90. We reserve 72
    // on the left and the padded actions occupy 90 + 8 on the right. That
    // leaves 630, so the title is right justified but its width isn't changed.

    await tester.pumpWidget(buildApp());
    leading = null;
    titleWidth = 620.0;
    actions = <Widget>[
      const SizedBox(width: 45.0),
      const SizedBox(width: 45.0)
    ];
    await tester.pumpWidget(buildApp());
    expect(tester.getTopLeft(title).x, 800 - 620 - 45 - 45 - 8);
    expect(tester.getSize(title).width, equals(620.0));
  });

  testWidgets('AppBar render at zero size', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Center(
        child: new Container(
          height: 0.0,
          width: 0.0,
          child: new Scaffold(
            appBar: new AppBar(
              title: new Text('X')
            )
          )
        )
      )
    );

    Finder title = find.text('X');
    expect(tester.getSize(title).isEmpty, isTrue);
  });

  testWidgets('AppBar actions are vertically centered', (WidgetTester tester) async {
    UniqueKey appBarKey = new UniqueKey();
    UniqueKey leadingKey = new UniqueKey();
    UniqueKey titleKey = new UniqueKey();
    UniqueKey action0Key = new UniqueKey();
    UniqueKey action1Key = new UniqueKey();

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
      )
    );

    // The vertical center of the widget with key, in global coordinates.
    double yCenter(Key key) {
      RenderBox box = tester.renderObject(find.byKey(appBarKey));
      return box.localToGlobal(new Point(0.0, box.size.height / 2.0)).y;
    }

    expect(yCenter(appBarKey), equals(yCenter(leadingKey)));
    expect(yCenter(appBarKey), equals(yCenter(titleKey)));
    expect(yCenter(appBarKey), equals(yCenter(action0Key)));
    expect(yCenter(appBarKey), equals(yCenter(action1Key)));
  });

}
