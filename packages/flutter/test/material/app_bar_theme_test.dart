// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
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
    final ThemeData theme = ThemeData();
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          appBar: AppBar(
            actions: <Widget>[
              IconButton(icon: const Icon(Icons.share), onPressed: () { }),
            ],
          ),
        ),
      ),
    );

    final Material widget = _getAppBarMaterial(tester);
    final IconTheme iconTheme = _getAppBarIconTheme(tester);
    final IconTheme actionsIconTheme = _getAppBarActionsIconTheme(tester);
    final RichText actionIconText = _getAppBarIconRichText(tester);
    final DefaultTextStyle text = _getAppBarText(tester);

    if (theme.useMaterial3) {
      expect(SystemChrome.latestStyle!.statusBarBrightness, Brightness.light);
      expect(widget.color, theme.colorScheme.surface);
      expect(widget.elevation, 0);
      expect(widget.shadowColor, null);
      expect(widget.surfaceTintColor, theme.colorScheme.surfaceTint);
      expect(widget.shape, null);
      expect(iconTheme.data, IconThemeData(color: theme.colorScheme.onSurface, size: 24));
      expect(actionsIconTheme.data, IconThemeData(color: theme.colorScheme.onSurfaceVariant, size: 24));
      expect(actionIconText.text.style!.color, Colors.black);
      expect(text.style, Typography.material2021().englishLike.bodyText2!.merge(Typography.material2021().black.bodyText2).copyWith(color: theme.colorScheme.onSurface));
      expect(tester.getSize(find.byType(AppBar)).height, kToolbarHeight);
      expect(tester.getSize(find.byType(AppBar)).width, 800);
    } else {
      expect(SystemChrome.latestStyle!.statusBarBrightness, SystemUiOverlayStyle.light.statusBarBrightness);
      expect(widget.color, Colors.blue);
      expect(widget.elevation, 4.0);
      expect(widget.shadowColor, Colors.black);
      expect(widget.surfaceTintColor, null);
      expect(widget.shape, null);
      expect(iconTheme.data, const IconThemeData(color: Colors.white));
      expect(actionsIconTheme.data, const IconThemeData(color: Colors.white));
      expect(actionIconText.text.style!.color, Colors.white);
      expect(text.style, Typography.material2014().englishLike.bodyText2!.merge(Typography.material2014().white.bodyText2));
      expect(tester.getSize(find.byType(AppBar)).height, kToolbarHeight);
      expect(tester.getSize(find.byType(AppBar)).width, 800);
    }
  });

  testWidgets('AppBar uses values from AppBarTheme', (WidgetTester tester) async {
    final AppBarTheme appBarTheme = _appBarTheme();

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(appBarTheme: appBarTheme),
        home: Scaffold(
          appBar: AppBar(
            title: const Text('App Bar Title'),
            actions: <Widget>[
              IconButton(icon: const Icon(Icons.share), onPressed: () { }),
            ],
          ),
        ),
      ),
    );

    final Material widget = _getAppBarMaterial(tester);
    final IconTheme iconTheme = _getAppBarIconTheme(tester);
    final IconTheme actionsIconTheme = _getAppBarActionsIconTheme(tester);
    final RichText actionIconText = _getAppBarIconRichText(tester);
    final DefaultTextStyle text = _getAppBarText(tester);

    expect(SystemChrome.latestStyle!.statusBarBrightness, appBarTheme.brightness);
    expect(widget.color, appBarTheme.backgroundColor);
    expect(widget.elevation, appBarTheme.elevation);
    expect(widget.shadowColor, appBarTheme.shadowColor);
    expect(widget.surfaceTintColor, appBarTheme.surfaceTintColor);
    expect(widget.shape, const StadiumBorder());
    expect(iconTheme.data, appBarTheme.iconTheme);
    expect(actionsIconTheme.data, appBarTheme.actionsIconTheme);
    expect(actionIconText.text.style!.color, appBarTheme.actionsIconTheme!.color);
    expect(text.style, appBarTheme.toolbarTextStyle);
    expect(tester.getSize(find.byType(AppBar)).height, appBarTheme.toolbarHeight);
    expect(tester.getSize(find.byType(AppBar)).width, 800);
  });

  testWidgets('SliverAppBar allows AppBar to determine backwardsCompatibility', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/77016
    const AppBarTheme appBarTheme = AppBarTheme(
      backwardsCompatibility: false,
      backgroundColor: Colors.lightBlue,
      foregroundColor: Colors.black,
    );

    Widget _buildWithBackwardsCompatibility([bool? enabled]) => MaterialApp(
      theme: ThemeData(appBarTheme: appBarTheme),
      home: Scaffold(body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            title: const Text('App Bar Title'),
            backwardsCompatibility: enabled,
            actions: <Widget>[
              IconButton(icon: const Icon(Icons.share), onPressed: () { }),
            ],
          ),
        ],
      )),
    );

    // Backwards compatibility enabled, AppBar should be built with true.
    await tester.pumpWidget(_buildWithBackwardsCompatibility(true));
    AppBar appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.backwardsCompatibility, true);

    // Backwards compatibility disabled, AppBar should be built with false.
    await tester.pumpWidget(_buildWithBackwardsCompatibility(false));
    appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.backwardsCompatibility, false);

    // Backwards compatibility unspecified, AppBar should be built with null.
    await tester.pumpWidget(_buildWithBackwardsCompatibility());
    appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.backwardsCompatibility, null);

    // AppBar should use the backwardsCompatibility of AppBarTheme.
    // Since backwardsCompatibility is false, the text color should match the
    // foreground color of the AppBarTheme.
    final DefaultTextStyle text = _getAppBarText(tester);
    expect(text.style.color, appBarTheme.foregroundColor);
  });

  testWidgets('AppBar widget properties take priority over theme', (WidgetTester tester) async {
    const Brightness brightness = Brightness.dark;
    const SystemUiOverlayStyle systemOverlayStyle = SystemUiOverlayStyle.light;
    const Color color = Colors.orange;
    const double elevation = 3.0;
    const Color shadowColor = Colors.purple;
    const Color surfaceTintColor = Colors.brown;
    const ShapeBorder shape = RoundedRectangleBorder();
    const IconThemeData iconThemeData = IconThemeData(color: Colors.green);
    const IconThemeData actionsIconThemeData = IconThemeData(color: Colors.lightBlue);
    const TextStyle toolbarTextStyle = TextStyle(color: Colors.pink);
    const TextStyle titleTextStyle = TextStyle(color: Colors.orange);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.from(colorScheme: const ColorScheme.light()).copyWith(
          appBarTheme: _appBarTheme(),
        ),
        home: Scaffold(
          appBar: AppBar(
            backgroundColor: color,
            brightness: brightness,
            systemOverlayStyle: systemOverlayStyle,
            elevation: elevation,
            shadowColor: shadowColor,
            surfaceTintColor: surfaceTintColor,
            shape: shape,
            iconTheme: iconThemeData,
            actionsIconTheme: actionsIconThemeData,
            toolbarTextStyle: toolbarTextStyle,
            titleTextStyle: titleTextStyle,
            actions: <Widget>[
              IconButton(icon: const Icon(Icons.share), onPressed: () { }),
            ],
          ),
        ),
      ),
    );

    final Material widget = _getAppBarMaterial(tester);
    final IconTheme iconTheme = _getAppBarIconTheme(tester);
    final IconTheme actionsIconTheme = _getAppBarActionsIconTheme(tester);
    final RichText actionIconText = _getAppBarIconRichText(tester);
    final DefaultTextStyle text = _getAppBarText(tester);

    expect(SystemChrome.latestStyle!.statusBarBrightness, brightness);
    expect(widget.color, color);
    expect(widget.elevation, elevation);
    expect(widget.shadowColor, shadowColor);
    expect(widget.surfaceTintColor, surfaceTintColor);
    expect(widget.shape, shape);
    expect(iconTheme.data, iconThemeData);
    expect(actionsIconTheme.data, actionsIconThemeData);
    expect(actionIconText.text.style!.color, actionsIconThemeData.color);
    expect(text.style, toolbarTextStyle);
  });

  testWidgets('AppBar icon color takes priority over everything', (WidgetTester tester) async {
    const Color color = Colors.lime;
    const IconThemeData iconThemeData = IconThemeData(color: Colors.green);
    const IconThemeData actionsIconThemeData = IconThemeData(color: Colors.lightBlue);

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData.from(colorScheme: const ColorScheme.light()),
      home: Scaffold(appBar: AppBar(
        iconTheme: iconThemeData,
        actionsIconTheme: actionsIconThemeData,
        actions: <Widget>[
          IconButton(icon: const Icon(Icons.share), color: color, onPressed: () { }),
        ],
      )),
    ));

    final RichText actionIconText = _getAppBarIconRichText(tester);
    expect(actionIconText.text.style!.color, color);
  });

  testWidgets('AppBarTheme properties take priority over ThemeData properties', (WidgetTester tester) async {
    final AppBarTheme appBarTheme = _appBarTheme();

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.from(colorScheme: const ColorScheme.light())
          .copyWith(appBarTheme: _appBarTheme()),
        home: Scaffold(
          appBar: AppBar(
            actions: <Widget>[
              IconButton(icon: const Icon(Icons.share), onPressed: () { }),
            ],
          ),
        ),
      ),
    );

    final Material widget = _getAppBarMaterial(tester);
    final IconTheme iconTheme = _getAppBarIconTheme(tester);
    final IconTheme actionsIconTheme = _getAppBarActionsIconTheme(tester);
    final RichText actionIconText = _getAppBarIconRichText(tester);
    final DefaultTextStyle text = _getAppBarText(tester);

    expect(SystemChrome.latestStyle!.statusBarBrightness, appBarTheme.brightness);
    expect(widget.color, appBarTheme.backgroundColor);
    expect(widget.elevation, appBarTheme.elevation);
    expect(widget.shadowColor, appBarTheme.shadowColor);
    expect(widget.surfaceTintColor, appBarTheme.surfaceTintColor);
    expect(iconTheme.data, appBarTheme.iconTheme);
    expect(actionsIconTheme.data, appBarTheme.actionsIconTheme);
    expect(actionIconText.text.style!.color, appBarTheme.actionsIconTheme!.color);
    expect(text.style, appBarTheme.toolbarTextStyle);
  });

  testWidgets('ThemeData colorScheme is used when no AppBarTheme is set', (WidgetTester tester) async {
    final ThemeData lightTheme = ThemeData.from(colorScheme: const ColorScheme.light());
    final ThemeData darkTheme = ThemeData.from(colorScheme: const ColorScheme.dark());
    Widget buildFrame(ThemeData appTheme) {
      return MaterialApp(
        theme: appTheme,
        home: Builder(
          builder: (BuildContext context) {
            return Scaffold(
              appBar: AppBar(
                actions: <Widget>[
                  IconButton(icon: const Icon(Icons.share), onPressed: () { }),
                ],
              ),
            );
          },
        ),
      );
    }

    if (lightTheme.useMaterial3) {
      // M3 AppBar defaults for light themes:
      // - elevation: 0
      // - shadow color: null
      // - surface tint color: ColorScheme.surfaceTint
      // - background color: ColorScheme.surface
      // - foreground color: ColorScheme.onSurface
      // - actions text: style bodyText2, foreground color
      // - status bar brightness: light (based on color scheme brightness)
      {
        await tester.pumpWidget(buildFrame(lightTheme));

        final Material widget = _getAppBarMaterial(tester);
        final IconTheme iconTheme = _getAppBarIconTheme(tester);
        final IconTheme actionsIconTheme = _getAppBarActionsIconTheme(tester);
        final RichText actionIconText = _getAppBarIconRichText(tester);
        final DefaultTextStyle text = _getAppBarText(tester);

        expect(SystemChrome.latestStyle!.statusBarBrightness, Brightness.light);
        expect(widget.color, lightTheme.colorScheme.surface);
        expect(widget.elevation, 0);
        expect(widget.shadowColor, null);
        expect(widget.surfaceTintColor, lightTheme.colorScheme.surfaceTint);
        expect(iconTheme.data.color, lightTheme.colorScheme.onSurface);
        expect(actionsIconTheme.data.color, lightTheme.colorScheme.onSurface);
        expect(actionIconText.text.style!.color, lightTheme.colorScheme.onSurface);
        expect(text.style, Typography.material2021().englishLike.bodyText2!.merge(Typography.material2021().black.bodyText2).copyWith(color: lightTheme.colorScheme.onSurface));
      }

      // M3 AppBar defaults for dark themes:
      // - elevation: 0
      // - shadow color: null
      // - surface tint color: ColorScheme.surfaceTint
      // - background color: ColorScheme.surface
      // - foreground color: ColorScheme.onSurface
      // - actions text: style bodyText2, foreground color
      // - status bar brightness: dark (based on background color)
      {
        await tester.pumpWidget(buildFrame(ThemeData.from(colorScheme: const ColorScheme.dark())));
        await tester.pumpAndSettle(); // Theme change animation

        final Material widget = _getAppBarMaterial(tester);
        final IconTheme iconTheme = _getAppBarIconTheme(tester);
        final IconTheme actionsIconTheme = _getAppBarActionsIconTheme(tester);
        final RichText actionIconText = _getAppBarIconRichText(tester);
        final DefaultTextStyle text = _getAppBarText(tester);

        expect(SystemChrome.latestStyle!.statusBarBrightness, Brightness.dark);
        expect(widget.color, darkTheme.colorScheme.surface);
        expect(widget.elevation, 0);
        expect(widget.shadowColor, null);
        expect(widget.surfaceTintColor, darkTheme.colorScheme.surfaceTint);
        expect(iconTheme.data.color, darkTheme.colorScheme.onSurface);
        expect(actionsIconTheme.data.color, darkTheme.colorScheme.onSurface);
        expect(actionIconText.text.style!.color, darkTheme.colorScheme.onSurface);
        expect(text.style, Typography.material2021().englishLike.bodyText2!.merge(Typography.material2021().black.bodyText2).copyWith(color: darkTheme.colorScheme.onSurface));
      }
    } else {
      // AppBar defaults for light themes:
      // - elevation: 4
      // - shadow color: black
      // - surface tint color: null
      // - background color: ColorScheme.primary
      // - foreground color: ColorScheme.onPrimary
      // - actions text: style bodyText2, foreground color
      // - status bar brightness: light (based on color scheme brightness)
      {
        await tester.pumpWidget(buildFrame(lightTheme));

        final Material widget = _getAppBarMaterial(tester);
        final IconTheme iconTheme = _getAppBarIconTheme(tester);
        final IconTheme actionsIconTheme = _getAppBarActionsIconTheme(tester);
        final RichText actionIconText = _getAppBarIconRichText(tester);
        final DefaultTextStyle text = _getAppBarText(tester);

        expect(SystemChrome.latestStyle!.statusBarBrightness, SystemUiOverlayStyle.light.statusBarBrightness);
        expect(widget.color, lightTheme.colorScheme.primary);
        expect(widget.elevation, 4.0);
        expect(widget.shadowColor, Colors.black);
        expect(widget.surfaceTintColor, null);
        expect(iconTheme.data.color, lightTheme.colorScheme.onPrimary);
        expect(actionsIconTheme.data.color, lightTheme.colorScheme.onPrimary);
        expect(actionIconText.text.style!.color, lightTheme.colorScheme.onPrimary);
        expect(text.style, Typography.material2014().englishLike.bodyText2!.merge(Typography.material2014().black.bodyText2).copyWith(color: lightTheme.colorScheme.onPrimary));
      }

      // AppBar defaults for dark themes:
      // - elevation: 4
      // - shadow color: black
      // - surface tint color: null
      // - background color: ColorScheme.surface
      // - foreground color: ColorScheme.onSurface
      // - actions text: style bodyText2, foreground color
      // - status bar brightness: dark (based on background color)
      {
        await tester.pumpWidget(buildFrame(darkTheme));
        await tester.pumpAndSettle(); // Theme change animation

        final Material widget = _getAppBarMaterial(tester);
        final IconTheme iconTheme = _getAppBarIconTheme(tester);
        final IconTheme actionsIconTheme = _getAppBarActionsIconTheme(tester);
        final RichText actionIconText = _getAppBarIconRichText(tester);
        final DefaultTextStyle text = _getAppBarText(tester);

        expect(SystemChrome.latestStyle!.statusBarBrightness, SystemUiOverlayStyle.light.statusBarBrightness);
        expect(widget.color, darkTheme.colorScheme.surface);
        expect(widget.elevation, 4.0);
        expect(widget.shadowColor, Colors.black);
        expect(widget.surfaceTintColor, null);
        expect(iconTheme.data.color, darkTheme.colorScheme.onSurface);
        expect(actionsIconTheme.data.color, darkTheme.colorScheme.onSurface);
        expect(actionIconText.text.style!.color, darkTheme.colorScheme.onSurface);
        expect(text.style, Typography.material2014().englishLike.bodyText2!.merge(Typography.material2014().black.bodyText2).copyWith(color: darkTheme.colorScheme.onSurface));
      }
    }
  });

  testWidgets('AppBar iconTheme with color=null defers to outer IconTheme', (WidgetTester tester) async {
    // Verify claim made in https://github.com/flutter/flutter/pull/71184#issuecomment-737419215

    Widget buildFrame({ Color? appIconColor, Color? appBarIconColor }) {
      return MaterialApp(
        theme: ThemeData.from(useMaterial3: false, colorScheme: const ColorScheme.light()),
        home: IconTheme(
          data: IconThemeData(color: appIconColor),
          child: Builder(
            builder: (BuildContext context) {
              return Scaffold(
                appBar: AppBar(
                  iconTheme: IconThemeData(color: appBarIconColor),
                  actions: <Widget>[
                    IconButton(icon: const Icon(Icons.share), onPressed: () { }),
                  ],
                ),
              );
            },
          ),
        ),
      );
    }

    RichText getIconText() {
      return tester.widget<RichText>(
        find.descendant(
          of: find.byType(Icon),
          matching: find.byType(RichText),
        ),
      );
    }

    await tester.pumpWidget(buildFrame(appIconColor: Colors.lime));
    expect(getIconText().text.style!.color, Colors.lime);

    await tester.pumpWidget(buildFrame(appIconColor: Colors.lime, appBarIconColor: Colors.purple));
    expect(getIconText().text.style!.color, Colors.purple);
  });

  testWidgets('AppBar uses AppBarTheme.centerTitle when centerTitle is null', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(appBarTheme: const AppBarTheme(centerTitle: true)),
      home: Scaffold(appBar: AppBar(
        title: const Text('Title'),
      )),
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
      home: Scaffold(appBar: AppBar(
        title: const Text('Title'),
      )),
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

  testWidgets('AppBar.surfaceTintColor takes priority over AppBarTheme.surfaceTintColor', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(appBarTheme: const AppBarTheme(surfaceTintColor: Colors.red)),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Title'),
          surfaceTintColor: Colors.yellow,
        ),
      ),
    ));

    final AppBar appBar = tester.widget(find.byType(AppBar));
    // The AppBar.surfaceTintColor should be used instead of AppBarTheme.surfaceTintColor.
    expect(appBar.surfaceTintColor, Colors.yellow);
  });

  testWidgets('AppBar uses AppBarTheme.titleSpacing', (WidgetTester tester) async {
    const double kTitleSpacing = 10;
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(appBarTheme: const AppBarTheme(titleSpacing: kTitleSpacing)),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Title'),
        ),
      ),
    ));

    final NavigationToolbar navToolBar = tester.widget(find.byType(NavigationToolbar));
    expect(navToolBar.middleSpacing, kTitleSpacing);
  });

  testWidgets('AppBar.titleSpacing takes priority over AppBarTheme.titleSpacing', (WidgetTester tester) async {
    const double kTitleSpacing = 10;
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(appBarTheme: const AppBarTheme(titleSpacing: kTitleSpacing)),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Title'),
          titleSpacing: 40,
        ),
      ),
    ));

    final NavigationToolbar navToolBar = tester.widget(find.byType(NavigationToolbar));
    expect(navToolBar.middleSpacing, 40);
  });

  testWidgets('SliverAppBar uses AppBarTheme.titleSpacing', (WidgetTester tester) async {
    const double kTitleSpacing = 10;
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(appBarTheme: const AppBarTheme(titleSpacing: kTitleSpacing)),
      home: const CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            title: Text('Title'),
          ),
        ],
      ),
    ));

    final NavigationToolbar navToolBar = tester.widget(find.byType(NavigationToolbar));
    expect(navToolBar.middleSpacing, kTitleSpacing);
  });

  testWidgets('SliverAppBar.titleSpacing takes priority over AppBarTheme.titleSpacing ', (WidgetTester tester) async {
    const double kTitleSpacing = 10;
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(appBarTheme: const AppBarTheme(titleSpacing: kTitleSpacing)),
      home: const CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            title: Text('Title'),
            titleSpacing: 40,
          ),
        ],
      ),
    ));

    final NavigationToolbar navToolbar = tester.widget(find.byType(NavigationToolbar));
    expect(navToolbar.middleSpacing, 40);
  });

  testWidgets('Default AppBarTheme debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const AppBarTheme().debugFillProperties(builder);

    final List<String> description = builder.properties
      .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
      .map((DiagnosticsNode node) => node.toString())
      .toList();

    expect(description, <String>[]);
  });

  testWidgets('AppBarTheme implements debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const AppBarTheme(
      brightness: Brightness.dark,
      backgroundColor: Color(0xff000001),
      elevation: 8.0,
      shadowColor: Color(0xff000002),
      surfaceTintColor: Color(0xff000003),
      centerTitle: true,
      titleSpacing: 40.0,
    ).debugFillProperties(builder);

    final List<String> description = builder.properties
      .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
      .map((DiagnosticsNode node) => node.toString())
      .toList();

    expect(description, <String>[
      'brightness: Brightness.dark',
      'backgroundColor: Color(0xff000001)',
      'elevation: 8.0',
      'shadowColor: Color(0xff000002)',
      'surfaceTintColor: Color(0xff000003)',
      'centerTitle: true',
      'titleSpacing: 40.0',
    ]);

    // On the web, Dart doubles and ints are backed by the same kind of object because
    // JavaScript does not support integers. So, the Dart double "4.0" is identical
    // to "4", which results in the web evaluating to the value "4" regardless of which
    // one is used. This results in a difference for doubles in debugFillProperties between
    // the web and the rest of Flutter's target platforms.
  }, skip: kIsWeb); // https://github.com/flutter/flutter/issues/87364
}

AppBarTheme _appBarTheme() {
  const Brightness brightness = Brightness.light;
  const Color backgroundColor = Colors.lightBlue;
  const double elevation = 6.0;
  const Color shadowColor = Colors.red;
  const Color surfaceTintColor = Colors.green;
  const IconThemeData iconThemeData = IconThemeData(color: Colors.black);
  const IconThemeData actionsIconThemeData = IconThemeData(color: Colors.pink);
  return const AppBarTheme(
    actionsIconTheme: actionsIconThemeData,
    brightness: brightness,
    backgroundColor: backgroundColor,
    elevation: elevation,
    shadowColor: shadowColor,
    surfaceTintColor: surfaceTintColor,
    shape: StadiumBorder(),
    iconTheme: iconThemeData,
    toolbarHeight: 96,
    toolbarTextStyle: TextStyle(color: Colors.yellow),
    titleTextStyle: TextStyle(color: Colors.pink),
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
