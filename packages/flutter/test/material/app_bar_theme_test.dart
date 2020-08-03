// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AppBarTheme copyWith, ==, hashCode basics', () {
    expect(const AppBarTheme(), const AppBarTheme().copyWith());
    expect(const AppBarTheme().hashCode, const AppBarTheme().copyWith().hashCode);
  });

  testWidgets('Passing no AppBarTheme returns defaults', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(appBar: AppBar(
        actions: <Widget>[
          IconButton(icon: const Icon(Icons.share), onPressed: () { }),
        ],
      )),
    ));

    final Material widget = _getAppBarMaterial(tester);
    final IconTheme iconTheme = _getAppBarIconTheme(tester);
    final IconTheme actionsIconTheme = _getAppBarActionsIconTheme(tester);
    final RichText actionIconText = _getAppBarIconRichText(tester);
    final DefaultTextStyle text = _getAppBarText(tester);

    expect(SystemChrome.latestStyle.statusBarBrightness, Brightness.dark);
    expect(widget.color, Colors.blue);
    expect(widget.elevation, 4.0);
    expect(widget.shadowColor, Colors.black);
    expect(iconTheme.data, const IconThemeData(color: Colors.white));
    expect(actionsIconTheme.data, const IconThemeData(color: Colors.white));
    expect(actionIconText.text.style.color, Colors.white);
    expect(text.style, Typography.material2014().englishLike.bodyText2.merge(Typography.material2014().white.bodyText2));
  });

  testWidgets('AppBar uses values from AppBarTheme', (WidgetTester tester) async {
    final AppBarTheme appBarTheme = _appBarTheme();

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(appBarTheme: appBarTheme),
      home: Scaffold(appBar: AppBar(
        title: const Text('App Bar Title'),
        actions: <Widget>[
          IconButton(icon: const Icon(Icons.share), onPressed: () { }),
        ],
      )),
    ));

    final Material widget = _getAppBarMaterial(tester);
    final IconTheme iconTheme = _getAppBarIconTheme(tester);
    final IconTheme actionsIconTheme = _getAppBarActionsIconTheme(tester);
    final RichText actionIconText = _getAppBarIconRichText(tester);
    final DefaultTextStyle text = _getAppBarText(tester);

    expect(SystemChrome.latestStyle.statusBarBrightness, appBarTheme.brightness);
    expect(widget.color, appBarTheme.color);
    expect(widget.elevation, appBarTheme.elevation);
    expect(widget.shadowColor, appBarTheme.shadowColor);
    expect(iconTheme.data, appBarTheme.iconTheme);
    expect(actionsIconTheme.data, appBarTheme.actionsIconTheme);
    expect(actionIconText.text.style.color, appBarTheme.actionsIconTheme.color);
    expect(text.style, appBarTheme.textTheme.bodyText2);
  });

  testWidgets('AppBar widget properties take priority over theme', (WidgetTester tester) async {
    const Brightness brightness = Brightness.dark;
    const Color color = Colors.orange;
    const double elevation = 3.0;
    const Color shadowColor = Colors.red;
    const IconThemeData iconThemeData = IconThemeData(color: Colors.green);
    const IconThemeData actionsIconThemeData = IconThemeData(color: Colors.lightBlue);
    const TextTheme textTheme = TextTheme(headline6: TextStyle(color: Colors.orange), bodyText2: TextStyle(color: Colors.pink));

    final ThemeData themeData = _themeData().copyWith(appBarTheme: _appBarTheme());

    await tester.pumpWidget(MaterialApp(
      theme: themeData,
      home: Scaffold(appBar: AppBar(
        backgroundColor: color,
        brightness: brightness,
        elevation: elevation,
        shadowColor: shadowColor,
        iconTheme: iconThemeData,
        actionsIconTheme: actionsIconThemeData,
        textTheme: textTheme,
        actions: <Widget>[
          IconButton(icon: const Icon(Icons.share), onPressed: () { }),
        ],
      )),
    ));

    final Material widget = _getAppBarMaterial(tester);
    final IconTheme iconTheme = _getAppBarIconTheme(tester);
    final IconTheme actionsIconTheme = _getAppBarActionsIconTheme(tester);
    final RichText actionIconText = _getAppBarIconRichText(tester);
    final DefaultTextStyle text = _getAppBarText(tester);

    expect(SystemChrome.latestStyle.statusBarBrightness, brightness);
    expect(widget.color, color);
    expect(widget.elevation, elevation);
    expect(widget.shadowColor, shadowColor);
    expect(iconTheme.data, iconThemeData);
    expect(actionsIconTheme.data, actionsIconThemeData);
    expect(actionIconText.text.style.color, actionsIconThemeData.color);
    expect(text.style, textTheme.bodyText2);
  });

  testWidgets('AppBar icon color takes priority over everything', (WidgetTester tester) async {
    const Color color = Colors.lime;
    const IconThemeData iconThemeData = IconThemeData(color: Colors.green);
    const IconThemeData actionsIconThemeData = IconThemeData(color: Colors.lightBlue);

    final ThemeData themeData = _themeData().copyWith(appBarTheme: _appBarTheme());

    await tester.pumpWidget(MaterialApp(
      theme: themeData,
      home: Scaffold(appBar: AppBar(
        iconTheme: iconThemeData,
        actionsIconTheme: actionsIconThemeData,
        actions: <Widget>[
          IconButton(icon: const Icon(Icons.share), color: color, onPressed: () { }),
        ],
      )),
    ));

    final RichText actionIconText = _getAppBarIconRichText(tester);
    expect(actionIconText.text.style.color, color);
  });

  testWidgets('AppBarTheme properties take priority over ThemeData properties', (WidgetTester tester) async {
    final AppBarTheme appBarTheme = _appBarTheme();
    final ThemeData themeData = _themeData().copyWith(appBarTheme: _appBarTheme());

    await tester.pumpWidget(MaterialApp(
      theme: themeData,
      home: Scaffold(appBar: AppBar(
        actions: <Widget>[
          IconButton(icon: const Icon(Icons.share), onPressed: () { }),
        ],
      )),
    ));

    final Material widget = _getAppBarMaterial(tester);
    final IconTheme iconTheme = _getAppBarIconTheme(tester);
    final IconTheme actionsIconTheme = _getAppBarActionsIconTheme(tester);
    final RichText actionIconText = _getAppBarIconRichText(tester);
    final DefaultTextStyle text = _getAppBarText(tester);

    expect(SystemChrome.latestStyle.statusBarBrightness, appBarTheme.brightness);
    expect(widget.color, appBarTheme.color);
    expect(widget.elevation, appBarTheme.elevation);
    expect(widget.shadowColor, appBarTheme.shadowColor);
    expect(iconTheme.data, appBarTheme.iconTheme);
    expect(actionsIconTheme.data, appBarTheme.actionsIconTheme);
    expect(actionIconText.text.style.color, appBarTheme.actionsIconTheme.color);
    expect(text.style, appBarTheme.textTheme.bodyText2);
  });

  testWidgets('ThemeData properties are used when no AppBarTheme is set', (WidgetTester tester) async {
    final ThemeData themeData = _themeData();

    await tester.pumpWidget(MaterialApp(
      theme: themeData,
      home: Scaffold(appBar: AppBar(
        actions: <Widget>[
          IconButton(icon: const Icon(Icons.share), onPressed: () { }),
        ],
      )),
    ));

    final Material widget = _getAppBarMaterial(tester);
    final IconTheme iconTheme = _getAppBarIconTheme(tester);
    final IconTheme actionsIconTheme = _getAppBarActionsIconTheme(tester);
    final RichText actionIconText = _getAppBarIconRichText(tester);
    final DefaultTextStyle text = _getAppBarText(tester);

    expect(SystemChrome.latestStyle.statusBarBrightness, themeData.brightness);
    expect(widget.color, themeData.primaryColor);
    expect(widget.elevation, 4.0);
    expect(widget.shadowColor, Colors.black);
    expect(iconTheme.data, themeData.primaryIconTheme);
    expect(actionsIconTheme.data, themeData.primaryIconTheme);
    expect(actionIconText.text.style.color, themeData.primaryIconTheme.color);
    // Default value for ThemeData.typography is Typography.material2014()
    expect(text.style, Typography.material2014().englishLike.bodyText2.merge(Typography.material2014().white.bodyText2).merge(themeData.primaryTextTheme.bodyText2));
  });

  testWidgets('AppBar uses AppBarTheme.centerTitle when centerTitle is null', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(appBarTheme: const AppBarTheme(centerTitle: true)),
      home: Scaffold(appBar: AppBar(title: const Text('Title'))),
    ));

    final NavigationToolbar navToolBar = tester.widget(find.byType(NavigationToolbar));
    expect(navToolBar.centerMiddle, true);
  });

  testWidgets('AppBar.centerTitle takes priority over AppBarTheme.centerTitle', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(appBarTheme: const AppBarTheme(centerTitle: true)),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Title'),
          centerTitle: false,
        ),
      ),
    ));

    final NavigationToolbar navToolBar = tester.widget(find.byType(NavigationToolbar));
    // The AppBar.centerTitle should be used instead of AppBarTheme.centerTitle.
    expect(navToolBar.centerMiddle, false);
  });

  testWidgets('AppBar.centerTitle adapts to TargetPlatform when AppBarTheme.centerTitle is null', (WidgetTester tester) async{
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(platform: TargetPlatform.iOS),
      home: Scaffold(appBar: AppBar(title: const Text('Title'))),
    ));

    final NavigationToolbar navToolBar = tester.widget(find.byType(NavigationToolbar));
    // When ThemeData.platform is TargetPlatform.iOS, and AppBarTheme is null,
    // the value of NavigationToolBar.centerMiddle should be true.
    expect(navToolBar.centerMiddle, true);
  });

  testWidgets('AppBar.shadowColor takes priority over AppBarTheme.shadowColor', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(appBarTheme: const AppBarTheme(shadowColor: Colors.red)),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Title'),
          shadowColor: Colors.yellow,
        ),
      ),
    ));

    final AppBar appBar = tester.widget(find.byType(AppBar));
    // The AppBar.shadowColor should be used instead of AppBarTheme.shadowColor.
    expect(appBar.shadowColor, Colors.yellow);
  });
}

AppBarTheme _appBarTheme() {
  const Brightness brightness = Brightness.light;
  const Color color = Colors.lightBlue;
  const double elevation = 6.0;
  const Color shadowColor = Colors.red;
  const IconThemeData iconThemeData = IconThemeData(color: Colors.black);
  const IconThemeData actionsIconThemeData = IconThemeData(color: Colors.pink);
  const TextTheme textTheme = TextTheme(bodyText2: TextStyle(color: Colors.yellow));
  return const AppBarTheme(
    actionsIconTheme: actionsIconThemeData,
    brightness: brightness,
    color: color,
    elevation: elevation,
    shadowColor: shadowColor,
    iconTheme: iconThemeData,
    textTheme: textTheme,
  );
}

ThemeData _themeData() {
  return ThemeData(
    primaryColor: Colors.purple,
    brightness: Brightness.dark,
    primaryIconTheme: const IconThemeData(color: Colors.green),
    primaryTextTheme: const TextTheme(headline6: TextStyle(color: Colors.orange), bodyText2: TextStyle(color: Colors.pink)),
  );
}

Material _getAppBarMaterial(WidgetTester tester) {
  return tester.widget<Material>(
    find.descendant(
      of: find.byType(AppBar),
      matching: find.byType(Material),
    ),
  );
}

IconTheme _getAppBarIconTheme(WidgetTester tester) {
  return tester.widget<IconTheme>(
    find.descendant(
      of: find.byType(AppBar),
      matching: find.byType(IconTheme),
    ).first,
  );
}

IconTheme _getAppBarActionsIconTheme(WidgetTester tester) {
  return tester.widget<IconTheme>(
    find.descendant(
      of: find.byType(NavigationToolbar),
      matching: find.byType(IconTheme),
    ).first,
  );
}

RichText _getAppBarIconRichText(WidgetTester tester) {
  return tester.widget<RichText>(
    find.descendant(
      of: find.byType(Icon),
      matching: find.byType(RichText),
    ).first,
  );
}

DefaultTextStyle _getAppBarText(WidgetTester tester) {
  return tester.widget<DefaultTextStyle>(
    find.descendant(
      of: find.byType(CustomSingleChildLayout),
      matching: find.byType(DefaultTextStyle),
    ).first,
  );
}
