// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// TODO(gspencergoog): Remove this tag once this test's state leaks/test
// dependencies have been fixed.
// https://github.com/flutter/flutter/issues/85160
// Fails with "flutter test --test-randomize-ordering-seed=123"
@Tags(<String>['no-shuffle'])

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';

class StateMarker extends StatefulWidget {
  const StateMarker({ super.key, this.child });

  final Widget? child;

  @override
  StateMarkerState createState() => StateMarkerState();
}

class StateMarkerState extends State<StateMarker> {
  late String marker;

  @override
  Widget build(BuildContext context) {
    if (widget.child != null) {
      return widget.child!;
    }
    return Container();
  }
}

void main() {
  testWidgets('Can nest apps', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MaterialApp(
          home: Text('Home sweet home'),
        ),
      ),
    );

    expect(find.text('Home sweet home'), findsOneWidget);
  });

  testWidgets('Focus handling', (WidgetTester tester) async {
    final FocusNode focusNode = FocusNode();
    await tester.pumpWidget(MaterialApp(
      home: Material(
        child: Center(
          child: TextField(focusNode: focusNode, autofocus: true),
        ),
      ),
    ));

    expect(focusNode.hasFocus, isTrue);
  });

  testWidgets('Can place app inside FocusScope', (WidgetTester tester) async {
    final FocusScopeNode focusScopeNode = FocusScopeNode();

    await tester.pumpWidget(FocusScope(
      autofocus: true,
      node: focusScopeNode,
      child: const MaterialApp(
        home: Text('Home'),
      ),
    ));

    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('Can show grid without losing sync', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: StateMarker(),
      ),
    );

    final StateMarkerState state1 = tester.state(find.byType(StateMarker));
    state1.marker = 'original';

    await tester.pumpWidget(
      const MaterialApp(
        debugShowMaterialGrid: true,
        home: StateMarker(),
      ),
    );

    final StateMarkerState state2 = tester.state(find.byType(StateMarker));
    expect(state1, equals(state2));
    expect(state2.marker, equals('original'));
  });

  testWidgets('Do not rebuild page during a route transition', (WidgetTester tester) async {
    int buildCounter = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            return Material(
              child: ElevatedButton(
                child: const Text('X'),
                onPressed: () { Navigator.of(context).pushNamed('/next'); },
              ),
            );
          },
        ),
        routes: <String, WidgetBuilder>{
          '/next': (BuildContext context) {
            return Builder(
              builder: (BuildContext context) {
                ++buildCounter;
                return const Text('Y');
              },
            );
          },
        },
      ),
    );

    expect(buildCounter, 0);
    await tester.tap(find.text('X'));
    expect(buildCounter, 0);
    await tester.pump();
    expect(buildCounter, 1);
    await tester.pump(const Duration(milliseconds: 10));
    expect(buildCounter, 1);
    await tester.pump(const Duration(milliseconds: 10));
    expect(buildCounter, 1);
    await tester.pump(const Duration(milliseconds: 10));
    expect(buildCounter, 1);
    await tester.pump(const Duration(milliseconds: 10));
    expect(buildCounter, 1);
    await tester.pump(const Duration(seconds: 1));
    expect(buildCounter, 1);
    expect(find.text('Y'), findsOneWidget);
  });

  testWidgets('Do rebuild the home page if it changes', (WidgetTester tester) async {
    int buildCounter = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            ++buildCounter;
            return const Text('A');
          },
        ),
      ),
    );
    expect(buildCounter, 1);
    expect(find.text('A'), findsOneWidget);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            ++buildCounter;
            return const Text('B');
          },
        ),
      ),
    );
    expect(buildCounter, 2);
    expect(find.text('B'), findsOneWidget);
  });

  testWidgets('Do not rebuild the home page if it does not actually change', (WidgetTester tester) async {
    int buildCounter = 0;
    final Widget home = Builder(
      builder: (BuildContext context) {
        ++buildCounter;
        return const Placeholder();
      },
    );
    await tester.pumpWidget(
      MaterialApp(
        home: home,
      ),
    );
    expect(buildCounter, 1);
    await tester.pumpWidget(
      MaterialApp(
        home: home,
      ),
    );
    expect(buildCounter, 1);
  });

  testWidgets('Do rebuild pages that come from the routes table if the MaterialApp changes', (WidgetTester tester) async {
    int buildCounter = 0;
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/': (BuildContext context) {
        ++buildCounter;
        return const Placeholder();
      },
    };
    await tester.pumpWidget(
      MaterialApp(
        routes: routes,
      ),
    );
    expect(buildCounter, 1);
    await tester.pumpWidget(
      MaterialApp(
        routes: routes,
      ),
    );
    expect(buildCounter, 2);
  });

  testWidgets('Cannot pop the initial route', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: Text('Home')));

    expect(find.text('Home'), findsOneWidget);

    final NavigatorState navigator = tester.state(find.byType(Navigator));
    final bool result = await navigator.maybePop();

    expect(result, isFalse);

    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('Default initialRoute', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(routes: <String, WidgetBuilder>{
      '/': (BuildContext context) => const Text('route "/"'),
    }));

    expect(find.text('route "/"'), findsOneWidget);
  });

  testWidgets('One-step initial route', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: '/a',
        routes: <String, WidgetBuilder>{
          '/': (BuildContext context) => const Text('route "/"'),
          '/a': (BuildContext context) => const Text('route "/a"'),
          '/a/b': (BuildContext context) => const Text('route "/a/b"'),
          '/b': (BuildContext context) => const Text('route "/b"'),
        },
      ),
    );

    expect(find.text('route "/"', skipOffstage: false), findsOneWidget);
    expect(find.text('route "/a"'), findsOneWidget);
    expect(find.text('route "/a/b"', skipOffstage: false), findsNothing);
    expect(find.text('route "/b"', skipOffstage: false), findsNothing);
  });

  testWidgets('Return value from pop is correct', (WidgetTester tester) async {
    late Future<Object?> result;
    await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              return Material(
                child: ElevatedButton(
                    child: const Text('X'),
                    onPressed: () async {
                      result = Navigator.of(context).pushNamed<Object?>('/a');
                    },
                ),
              );
            },
          ),
          routes: <String, WidgetBuilder>{
            '/a': (BuildContext context) {
              return Material(
                child: ElevatedButton(
                  child: const Text('Y'),
                  onPressed: () {
                    Navigator.of(context).pop('all done');
                  },
                ),
              );
            },
          },
        ),
    );
    await tester.tap(find.text('X'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Y'), findsOneWidget);
    await tester.tap(find.text('Y'));
    await tester.pump();

    expect(await result, equals('all done'));
  });

  testWidgets('Two-step initial route', (WidgetTester tester) async {
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/': (BuildContext context) => const Text('route "/"'),
      '/a': (BuildContext context) => const Text('route "/a"'),
      '/a/b': (BuildContext context) => const Text('route "/a/b"'),
      '/b': (BuildContext context) => const Text('route "/b"'),
    };

    await tester.pumpWidget(
      MaterialApp(
        initialRoute: '/a/b',
        routes: routes,
      ),
    );
    expect(find.text('route "/"', skipOffstage: false), findsOneWidget);
    expect(find.text('route "/a"', skipOffstage: false), findsOneWidget);
    expect(find.text('route "/a/b"'), findsOneWidget);
    expect(find.text('route "/b"', skipOffstage: false), findsNothing);
  });

  testWidgets('Initial route with missing step', (WidgetTester tester) async {
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/': (BuildContext context) => const Text('route "/"'),
      '/a': (BuildContext context) => const Text('route "/a"'),
      '/a/b': (BuildContext context) => const Text('route "/a/b"'),
      '/b': (BuildContext context) => const Text('route "/b"'),
    };

    await tester.pumpWidget(
      MaterialApp(
        initialRoute: '/a/b/c',
        routes: routes,
      ),
    );
    final dynamic exception = tester.takeException();
    expect(exception, isA<String>());
    if (exception is String) {
      expect(exception.startsWith('Could not navigate to initial route.'), isTrue);
      expect(find.text('route "/"'), findsOneWidget);
      expect(find.text('route "/a"'), findsNothing);
      expect(find.text('route "/a/b"'), findsNothing);
      expect(find.text('route "/b"'), findsNothing);
    }
  });

  testWidgets('Make sure initialRoute is only used the first time', (WidgetTester tester) async {
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/': (BuildContext context) => const Text('route "/"'),
      '/a': (BuildContext context) => const Text('route "/a"'),
      '/b': (BuildContext context) => const Text('route "/b"'),
    };

    await tester.pumpWidget(
      MaterialApp(
        initialRoute: '/a',
        routes: routes,
      ),
    );
    expect(find.text('route "/"', skipOffstage: false), findsOneWidget);
    expect(find.text('route "/a"'), findsOneWidget);
    expect(find.text('route "/b"', skipOffstage: false), findsNothing);

    // changing initialRoute has no effect
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: '/b',
        routes: routes,
      ),
    );
    expect(find.text('route "/"', skipOffstage: false), findsOneWidget);
    expect(find.text('route "/a"'), findsOneWidget);
    expect(find.text('route "/b"', skipOffstage: false), findsNothing);

    // removing it has no effect
    await tester.pumpWidget(MaterialApp(routes: routes));
    expect(find.text('route "/"', skipOffstage: false), findsOneWidget);
    expect(find.text('route "/a"'), findsOneWidget);
    expect(find.text('route "/b"', skipOffstage: false), findsNothing);
  });

  testWidgets('onGenerateRoute / onUnknownRoute', (WidgetTester tester) async {
    final List<String> log = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (RouteSettings settings) {
          log.add('onGenerateRoute ${settings.name}');
          return null;
        },
        onUnknownRoute: (RouteSettings settings) {
          log.add('onUnknownRoute ${settings.name}');
          return null;
        },
      ),
    );
    expect(tester.takeException(), isFlutterError);
    expect(log, <String>['onGenerateRoute /', 'onUnknownRoute /']);

    // Work-around for https://github.com/flutter/flutter/issues/65655.
    await tester.pumpWidget(Container());
    expect(tester.takeException(), isAssertionError);
  });

  testWidgets('MaterialApp with builder and no route information works.', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/18904
    await tester.pumpWidget(
      MaterialApp(
        builder: (BuildContext context, Widget? child) {
          return const SizedBox();
        },
      ),
    );
  });

  testWidgets("WidgetsApp don't rebuild routes when MediaQuery updates", (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/37878
    int routeBuildCount = 0;
    int dependentBuildCount = 0;

    await tester.pumpWidget(WidgetsApp(
      color: const Color.fromARGB(255, 255, 255, 255),
      onGenerateRoute: (_) {
        return PageRouteBuilder<void>(pageBuilder: (_, __, ___) {
          routeBuildCount++;
          return Builder(
            builder: (BuildContext context) {
              dependentBuildCount++;
              MediaQuery.of(context);
              return Container();
            },
          );
        });
      },
    ));

    expect(routeBuildCount, equals(1));
    expect(dependentBuildCount, equals(1));

    // didChangeMetrics
    tester.binding.window.physicalSizeTestValue = const Size(42, 42);
    addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

    await tester.pump();

    expect(routeBuildCount, equals(1));
    expect(dependentBuildCount, equals(2));

    // didChangeTextScaleFactor
    tester.binding.platformDispatcher.textScaleFactorTestValue = 42;
    addTearDown(tester.binding.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pump();

    expect(routeBuildCount, equals(1));
    expect(dependentBuildCount, equals(3));

    // didChangePlatformBrightness
    tester.binding.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.binding.platformDispatcher.clearPlatformBrightnessTestValue);

    await tester.pump();

    expect(routeBuildCount, equals(1));
    expect(dependentBuildCount, equals(4));

    // didChangeAccessibilityFeatures
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures.allOn;
    addTearDown(tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await tester.pump();

    expect(routeBuildCount, equals(1));
    expect(dependentBuildCount, equals(5));
  });

  testWidgets('Can get text scale from media query', (WidgetTester tester) async {
    double? textScaleFactor;
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder:(BuildContext context) {
        textScaleFactor = MediaQuery.of(context).textScaleFactor;
        return Container();
      }),
    ));
    expect(textScaleFactor, isNotNull);
    expect(textScaleFactor, equals(1.0));
  });

  testWidgets('MaterialApp.navigatorKey', (WidgetTester tester) async {
    final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
      navigatorKey: key,
      color: const Color(0xFF112233),
      home: const Placeholder(),
    ));
    expect(key.currentState, isA<NavigatorState>());
    await tester.pumpWidget(const MaterialApp(
      color: Color(0xFF112233),
      home: Placeholder(),
    ));
    expect(key.currentState, isNull);
    await tester.pumpWidget(MaterialApp(
      navigatorKey: key,
      color: const Color(0xFF112233),
      home: const Placeholder(),
    ));
    expect(key.currentState, isA<NavigatorState>());
  });

  testWidgets('Has default material and cupertino localizations', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            return Column(
              children: <Widget>[
                Text(MaterialLocalizations.of(context).selectAllButtonLabel),
                Text(CupertinoLocalizations.of(context).selectAllButtonLabel),
              ],
            );
          },
        ),
      ),
    );

    // Default US "select all" text.
    expect(find.text('Select all'), findsOneWidget);
    // Default Cupertino US "select all" text.
    expect(find.text('Select All'), findsOneWidget);
  });

  testWidgets('MaterialApp uses regular theme when themeMode is light', (WidgetTester tester) async {
    // Mock the Window to explicitly report a light platformBrightness.
    tester.binding.platformDispatcher.platformBrightnessTestValue = Brightness.light;

    late ThemeData appliedTheme;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          brightness: Brightness.light,
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
        ),
        themeMode: ThemeMode.light,
        home: Builder(
          builder: (BuildContext context) {
            appliedTheme = Theme.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(appliedTheme.brightness, Brightness.light);

    // Mock the Window to explicitly report a dark platformBrightness.
    tester.binding.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          brightness: Brightness.light,
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
        ),
        themeMode: ThemeMode.light,
        home: Builder(
          builder: (BuildContext context) {
            appliedTheme = Theme.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(appliedTheme.brightness, Brightness.light);
  });

  testWidgets('MaterialApp uses darkTheme when themeMode is dark', (WidgetTester tester) async {
    // Mock the Window to explicitly report a light platformBrightness.
    tester.binding.platformDispatcher.platformBrightnessTestValue = Brightness.light;

    late ThemeData appliedTheme;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          brightness: Brightness.light,
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
        ),
        themeMode: ThemeMode.dark,
        home: Builder(
          builder: (BuildContext context) {
            appliedTheme = Theme.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(appliedTheme.brightness, Brightness.dark);

    // Mock the Window to explicitly report a dark platformBrightness.
    tester.binding.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          brightness: Brightness.light,
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
        ),
        themeMode: ThemeMode.dark,
        home: Builder(
          builder: (BuildContext context) {
            appliedTheme = Theme.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(appliedTheme.brightness, Brightness.dark);
  });

  testWidgets('MaterialApp uses regular theme when themeMode is system and platformBrightness is light', (WidgetTester tester) async {
    // Mock the Window to explicitly report a light platformBrightness.
    final TestWidgetsFlutterBinding binding = tester.binding;
    binding.platformDispatcher.platformBrightnessTestValue = Brightness.light;

    late ThemeData appliedTheme;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          brightness: Brightness.light,
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
        ),
        home: Builder(
          builder: (BuildContext context) {
            appliedTheme = Theme.of(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(appliedTheme.brightness, Brightness.light);
  });

  testWidgets('MaterialApp uses darkTheme when themeMode is system and platformBrightness is dark', (WidgetTester tester) async {
    // Mock the Window to explicitly report a dark platformBrightness.
    tester.binding.platformDispatcher.platformBrightnessTestValue = Brightness.dark;

    late ThemeData appliedTheme;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          brightness: Brightness.light,
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
        ),
        home: Builder(
          builder: (BuildContext context) {
            appliedTheme = Theme.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(appliedTheme.brightness, Brightness.dark);
  });

  testWidgets('MaterialApp uses light theme when platformBrightness is dark but no dark theme is provided', (WidgetTester tester) async {
    // Mock the Window to explicitly report a dark platformBrightness.
    final TestWidgetsFlutterBinding binding = tester.binding;
    binding.platformDispatcher.platformBrightnessTestValue = Brightness.dark;

    late ThemeData appliedTheme;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          brightness: Brightness.light,
        ),
        home: Builder(
          builder: (BuildContext context) {
            appliedTheme = Theme.of(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(appliedTheme.brightness, Brightness.light);
  });

  testWidgets('MaterialApp uses fallback light theme when platformBrightness is dark but no theme is provided at all', (WidgetTester tester) async {
    // Mock the Window to explicitly report a dark platformBrightness.
    final TestWidgetsFlutterBinding binding = tester.binding;
    binding.platformDispatcher.platformBrightnessTestValue = Brightness.dark;

    late ThemeData appliedTheme;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            appliedTheme = Theme.of(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(appliedTheme.brightness, Brightness.light);
  });

  testWidgets('MaterialApp uses fallback light theme when platformBrightness is light and a dark theme is provided', (WidgetTester tester) async {
    // Mock the Window to explicitly report a dark platformBrightness.
    final TestWidgetsFlutterBinding binding = tester.binding;
    binding.platformDispatcher.platformBrightnessTestValue = Brightness.light;

    late ThemeData appliedTheme;

    await tester.pumpWidget(
      MaterialApp(
        darkTheme: ThemeData(
          brightness: Brightness.dark,
        ),
        home: Builder(
          builder: (BuildContext context) {
            appliedTheme = Theme.of(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(appliedTheme.brightness, Brightness.light);
  });

  testWidgets('MaterialApp uses dark theme when platformBrightness is dark', (WidgetTester tester) async {
    // Mock the Window to explicitly report a dark platformBrightness.
    final TestWidgetsFlutterBinding binding = tester.binding;
    binding.platformDispatcher.platformBrightnessTestValue = Brightness.dark;

    late ThemeData appliedTheme;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          brightness: Brightness.light,
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
        ),
        home: Builder(
          builder: (BuildContext context) {
            appliedTheme = Theme.of(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(appliedTheme.brightness, Brightness.dark);
  });

  testWidgets('MaterialApp uses high contrast theme when appropriate', (WidgetTester tester) async {
    tester.binding.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures.allOn;

    late ThemeData appliedTheme;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          primaryColor: Colors.lightBlue,
        ),
        highContrastTheme: ThemeData(
          primaryColor: Colors.blue,
        ),
        home: Builder(
          builder: (BuildContext context) {
            appliedTheme = Theme.of(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(appliedTheme.primaryColor, Colors.blue);
    tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue();
  });

  testWidgets('MaterialApp uses high contrast dark theme when appropriate', (WidgetTester tester) async {
    tester.binding.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures.allOn;

    late ThemeData appliedTheme;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          primaryColor: Colors.lightBlue,
        ),
        darkTheme: ThemeData(
          primaryColor: Colors.lightGreen,
        ),
        highContrastTheme: ThemeData(
          primaryColor: Colors.blue,
        ),
        highContrastDarkTheme: ThemeData(
          primaryColor: Colors.green,
        ),
        home: Builder(
          builder: (BuildContext context) {
            appliedTheme = Theme.of(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(appliedTheme.primaryColor, Colors.green);
    tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue();
  });

  testWidgets('MaterialApp uses dark theme when no high contrast dark theme is provided', (WidgetTester tester) async {
    tester.binding.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures.allOn;

    late ThemeData appliedTheme;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          primaryColor: Colors.lightBlue,
        ),
        darkTheme: ThemeData(
          primaryColor: Colors.lightGreen,
        ),
        home: Builder(
          builder: (BuildContext context) {
            appliedTheme = Theme.of(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(appliedTheme.primaryColor, Colors.lightGreen);
    tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue();
    tester.binding.platformDispatcher.clearPlatformBrightnessTestValue();
  });

  testWidgets('MaterialApp animates theme changes', (WidgetTester tester) async {
    final ThemeData lightTheme = ThemeData.light();
    final ThemeData darkTheme = ThemeData.dark();
    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: ThemeMode.light,
        home: Builder(
          builder: (BuildContext context) {
            return const Scaffold();
          },
        ),
      ),
    );
    expect(tester.widget<Material>(find.byType(Material)).color, lightTheme.scaffoldBackgroundColor);

    // Change to dark theme
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: ThemeMode.dark,
        home: Builder(
          builder: (BuildContext context) {
            return const Scaffold();
          },
        ),
      ),
    );

    // Wait half kThemeAnimationDuration = 200ms.
    await tester.pump(const Duration(milliseconds: 100));

    // Default curve is linear so background should be half way between
    // the two colors.
    final Color halfBGColor = Color.lerp(lightTheme.scaffoldBackgroundColor, darkTheme.scaffoldBackgroundColor, 0.5)!;
    expect(tester.widget<Material>(find.byType(Material)).color, halfBGColor);
  });

  testWidgets('MaterialApp theme animation can be turned off', (WidgetTester tester) async {
    final ThemeData lightTheme = ThemeData.light();
    final ThemeData darkTheme = ThemeData.dark();
    int scaffoldRebuilds = 0;

    final Widget scaffold = Builder(
      builder: (BuildContext context) {
        scaffoldRebuilds++;
        // Use Theme.of() to ensure we are building when the theme changes.
        return Scaffold(backgroundColor: Theme.of(context).scaffoldBackgroundColor);
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: ThemeMode.light,
        themeAnimationDuration: Duration.zero,
        home: scaffold,
      ),
    );
    expect(tester.widget<Material>(find.byType(Material)).color, lightTheme.scaffoldBackgroundColor);
    expect(scaffoldRebuilds, 1);

    // Change to dark theme
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: ThemeMode.dark,
        themeAnimationDuration: Duration.zero,
        home: scaffold,
      ),
    );

    // Wait for any animation to finish.
    await tester.pumpAndSettle();
    expect(tester.widget<Material>(find.byType(Material)).color, darkTheme.scaffoldBackgroundColor);
    expect(scaffoldRebuilds, 2);
  });

  testWidgets('MaterialApp switches themes when the Window platformBrightness changes.', (WidgetTester tester) async {
    // Mock the Window to explicitly report a light platformBrightness.
    final TestWidgetsFlutterBinding binding = tester.binding;
    binding.platformDispatcher.platformBrightnessTestValue = Brightness.light;

    ThemeData? themeBeforeBrightnessChange;
    ThemeData? themeAfterBrightnessChange;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          brightness: Brightness.light,
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
        ),
        home: Builder(
          builder: (BuildContext context) {
            if (themeBeforeBrightnessChange == null) {
              themeBeforeBrightnessChange = Theme.of(context);
            } else {
              themeAfterBrightnessChange = Theme.of(context);
            }
            return const SizedBox();
          },
        ),
      ),
    );

    // Switch the platformBrightness from light to dark and pump the widget tree
    // to process changes.
    binding.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pumpAndSettle();

    expect(themeBeforeBrightnessChange!.brightness, Brightness.light);
    expect(themeAfterBrightnessChange!.brightness, Brightness.dark);
  });

  testWidgets('MaterialApp provides default overscroll color', (WidgetTester tester) async {
    Future<void> slowDrag(WidgetTester tester, Offset start, Offset offset) async {
      final TestGesture gesture = await tester.startGesture(start);
      for (int index = 0; index < 10; index += 1) {
        await gesture.moveBy(offset);
        await tester.pump(const Duration(milliseconds: 20));
      }
      await gesture.up();
    }

    // The overscroll color should be a transparent version of the colorScheme's
    // secondary color.
    const Color secondaryColor = Color(0xff008800);
    final Color glowSecondaryColor = secondaryColor.withOpacity(0.05);
    final ThemeData theme = ThemeData.from(
      colorScheme: const ColorScheme.light().copyWith(secondary: secondaryColor),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const SingleChildScrollView(
          child: SizedBox(height: 2000.0),
        ),
      ),
    );

    final RenderObject painter = tester.renderObject(find.byType(CustomPaint).first);
    await slowDrag(tester, const Offset(200.0, 200.0), const Offset(0.0, 5.0));
    expect(painter, paints..circle(color: glowSecondaryColor));
  });

  testWidgets('MaterialApp can customize initial routes', (WidgetTester tester) async {
    final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        onGenerateInitialRoutes: (String initialRoute) {
          expect(initialRoute, '/abc');
          return <Route<void>>[
            PageRouteBuilder<void>(
              pageBuilder: (
                BuildContext context,
                Animation<double> animation,
                Animation<double> secondaryAnimation,
              ) {
                return const Text('non-regular page one');
              },
            ),
            PageRouteBuilder<void>(
              pageBuilder: (
                BuildContext context,
                Animation<double> animation,
                Animation<double> secondaryAnimation,
              ) {
                return const Text('non-regular page two');
              },
            ),
          ];
        },
        initialRoute: '/abc',
        routes: <String, WidgetBuilder>{
          '/': (BuildContext context) => const Text('regular page one'),
          '/abc': (BuildContext context) => const Text('regular page two'),
        },
      ),
    );
    expect(find.text('non-regular page two'), findsOneWidget);
    expect(find.text('non-regular page one'), findsNothing);
    expect(find.text('regular page one'), findsNothing);
    expect(find.text('regular page two'), findsNothing);
    navigatorKey.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.text('non-regular page two'), findsNothing);
    expect(find.text('non-regular page one'), findsOneWidget);
    expect(find.text('regular page one'), findsNothing);
    expect(find.text('regular page two'), findsNothing);
  });

  testWidgets('MaterialApp does create HeroController with the MaterialRectArcTween', (WidgetTester tester) async {
    final HeroController controller = MaterialApp.createMaterialHeroController();
    final Tween<Rect?> tween = controller.createRectTween!(
      const Rect.fromLTRB(0.0, 0.0, 10.0, 10.0),
      const Rect.fromLTRB(0.0, 0.0, 20.0, 20.0),
    );
    expect(tween, isA<MaterialRectArcTween>());
  });

  testWidgets('MaterialApp.navigatorKey can be updated', (WidgetTester tester) async {
    final GlobalKey<NavigatorState> key1 = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
      navigatorKey: key1,
      home: const Placeholder(),
    ));
    expect(key1.currentState, isA<NavigatorState>());
    final GlobalKey<NavigatorState> key2 = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
      navigatorKey: key2,
      home: const Placeholder(),
    ));
    expect(key2.currentState, isA<NavigatorState>());
    expect(key1.currentState, isNull);
  });

  testWidgets('MaterialApp.router works', (WidgetTester tester) async {
    final PlatformRouteInformationProvider provider = PlatformRouteInformationProvider(
      initialRouteInformation: const RouteInformation(
        location: 'initial',
      ),
    );
    final SimpleNavigatorRouterDelegate delegate = SimpleNavigatorRouterDelegate(
      builder: (BuildContext context, RouteInformation information) {
        return Text(information.location!);
      },
      onPopPage: (Route<void> route, void result, SimpleNavigatorRouterDelegate delegate) {
        delegate.routeInformation = const RouteInformation(
          location: 'popped',
        );
        return route.didPop(result);
      },
    );
    await tester.pumpWidget(MaterialApp.router(
      routeInformationProvider: provider,
      routeInformationParser: SimpleRouteInformationParser(),
      routerDelegate: delegate,
    ));
    expect(find.text('initial'), findsOneWidget);

    // Simulate android back button intent.
    final ByteData message = const JSONMethodCodec().encodeMethodCall(const MethodCall('popRoute'));
    await ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage('flutter/navigation', message, (_) { });
    await tester.pumpAndSettle();
    expect(find.text('popped'), findsOneWidget);
  });

  testWidgets('MaterialApp.router route information parser is optional', (WidgetTester tester) async {
    final SimpleNavigatorRouterDelegate delegate = SimpleNavigatorRouterDelegate(
      builder: (BuildContext context, RouteInformation information) {
        return Text(information.location!);
      },
      onPopPage: (Route<void> route, void result, SimpleNavigatorRouterDelegate delegate) {
        delegate.routeInformation = const RouteInformation(
          location: 'popped',
        );
        return route.didPop(result);
      },
    );
    delegate.routeInformation = const RouteInformation(location: 'initial');
    await tester.pumpWidget(MaterialApp.router(
      routerDelegate: delegate,
    ));
    expect(find.text('initial'), findsOneWidget);

    // Simulate android back button intent.
    final ByteData message = const JSONMethodCodec().encodeMethodCall(const MethodCall('popRoute'));
    await ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage('flutter/navigation', message, (_) { });
    await tester.pumpAndSettle();
    expect(find.text('popped'), findsOneWidget);
  });

  testWidgets('MaterialApp.router throw if route information provider is provided but no route information parser', (WidgetTester tester) async {
    final SimpleNavigatorRouterDelegate delegate = SimpleNavigatorRouterDelegate(
      builder: (BuildContext context, RouteInformation information) {
        return Text(information.location!);
      },
      onPopPage: (Route<void> route, void result, SimpleNavigatorRouterDelegate delegate) {
        delegate.routeInformation = const RouteInformation(
          location: 'popped',
        );
        return route.didPop(result);
      },
    );
    delegate.routeInformation = const RouteInformation(location: 'initial');
    final PlatformRouteInformationProvider provider = PlatformRouteInformationProvider(
      initialRouteInformation: const RouteInformation(
        location: 'initial',
      ),
    );
    await tester.pumpWidget(MaterialApp.router(
      routeInformationProvider: provider,
      routerDelegate: delegate,
    ));
    expect(tester.takeException(), isAssertionError);
  });

  testWidgets('MaterialApp.router throw if route configuration is provided along with other delegate', (WidgetTester tester) async {
    final SimpleNavigatorRouterDelegate delegate = SimpleNavigatorRouterDelegate(
      builder: (BuildContext context, RouteInformation information) {
        return Text(information.location!);
      },
      onPopPage: (Route<void> route, void result, SimpleNavigatorRouterDelegate delegate) {
        delegate.routeInformation = const RouteInformation(
          location: 'popped',
        );
        return route.didPop(result);
      },
    );
    delegate.routeInformation = const RouteInformation(location: 'initial');
    final RouterConfig<RouteInformation> routerConfig = RouterConfig<RouteInformation>(routerDelegate: delegate);
    await tester.pumpWidget(MaterialApp.router(
      routerDelegate: delegate,
      routerConfig: routerConfig,
    ));
    expect(tester.takeException(), isAssertionError);
  });

  testWidgets('MaterialApp.router router config works', (WidgetTester tester) async {
    final RouterConfig<RouteInformation> routerConfig = RouterConfig<RouteInformation>(
        routeInformationProvider: PlatformRouteInformationProvider(
          initialRouteInformation: const RouteInformation(
            location: 'initial',
          ),
        ),
        routeInformationParser: SimpleRouteInformationParser(),
        routerDelegate: SimpleNavigatorRouterDelegate(
          builder: (BuildContext context, RouteInformation information) {
            return Text(information.location!);
          },
          onPopPage: (Route<void> route, void result, SimpleNavigatorRouterDelegate delegate) {
            delegate.routeInformation = const RouteInformation(
              location: 'popped',
            );
            return route.didPop(result);
          },
        ),
        backButtonDispatcher: RootBackButtonDispatcher()
    );
    await tester.pumpWidget(MaterialApp.router(
      routerConfig: routerConfig,
    ));
    expect(find.text('initial'), findsOneWidget);

    // Simulate android back button intent.
    final ByteData message = const JSONMethodCodec().encodeMethodCall(const MethodCall('popRoute'));
    await ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage('flutter/navigation', message, (_) { });
    await tester.pumpAndSettle();
    expect(find.text('popped'), findsOneWidget);
  });

  testWidgets('MaterialApp.builder can build app without a Navigator', (WidgetTester tester) async {
    Widget? builderChild;
    await tester.pumpWidget(MaterialApp(
      builder: (BuildContext context, Widget? child) {
        builderChild = child;
        return Container();
      },
    ));
    expect(builderChild, isNull);
  });

  testWidgets('MaterialApp has correct default ScrollBehavior', (WidgetTester tester) async {
    late BuildContext capturedContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            capturedContext = context;
            return const Placeholder();
          },
        ),
      ),
    );
    expect(ScrollConfiguration.of(capturedContext).runtimeType, MaterialScrollBehavior);
  });

  testWidgets('A ScrollBehavior can be set for MaterialApp', (WidgetTester tester) async {
    late BuildContext capturedContext;
    await tester.pumpWidget(
      MaterialApp(
        scrollBehavior: const MockScrollBehavior(),
        home: Builder(
          builder: (BuildContext context) {
            capturedContext = context;
            return const Placeholder();
          },
        ),
      ),
    );
    final ScrollBehavior scrollBehavior = ScrollConfiguration.of(capturedContext);
    expect(scrollBehavior.runtimeType, MockScrollBehavior);
    expect(scrollBehavior.getScrollPhysics(capturedContext).runtimeType, NeverScrollableScrollPhysics);
  });

  testWidgets('ScrollBehavior default android overscroll indicator', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      scrollBehavior: const MaterialScrollBehavior(),
      home: ListView(
        children: const <Widget>[
          SizedBox(
            height: 1000.0,
            width: 1000.0,
            child: Text('Test'),
          ),
        ],
      ),
    ));

    expect(find.byType(StretchingOverscrollIndicator), findsNothing);
    expect(find.byType(GlowingOverscrollIndicator), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('ScrollBehavior stretch android overscroll indicator', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      scrollBehavior: const MaterialScrollBehavior(androidOverscrollIndicator: AndroidOverscrollIndicator.stretch),
      home: ListView(
        children: const <Widget>[
          SizedBox(
            height: 1000.0,
            width: 1000.0,
            child: Text('Test'),
          ),
        ],
      ),
    ));

    expect(find.byType(StretchingOverscrollIndicator), findsOneWidget);
    expect(find.byType(GlowingOverscrollIndicator), findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('ScrollBehavior stretch android overscroll indicator via useMaterial3 flag', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: ListView(
        children: const <Widget>[
          SizedBox(
            height: 1000.0,
            width: 1000.0,
            child: Text('Test'),
          ),
        ],
      ),
    ));

    expect(find.byType(StretchingOverscrollIndicator), findsOneWidget);
    expect(find.byType(GlowingOverscrollIndicator), findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('Overscroll indicator can be set by theme', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      // The current default is glowing, setting via the theme should override.
      theme: ThemeData().copyWith(androidOverscrollIndicator: AndroidOverscrollIndicator.stretch),
      home: ListView(
        children: const <Widget>[
          SizedBox(
            height: 1000.0,
            width: 1000.0,
            child: Text('Test'),
          ),
        ],
      ),
    ));

    expect(find.byType(StretchingOverscrollIndicator), findsOneWidget);
    expect(find.byType(GlowingOverscrollIndicator), findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('Overscroll indicator in MaterialScrollBehavior takes precedence over theme', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      // MaterialScrollBehavior.androidOverscrollIndicator takes precedence over theme.
      scrollBehavior: const MaterialScrollBehavior(androidOverscrollIndicator: AndroidOverscrollIndicator.stretch),
      theme: ThemeData().copyWith(androidOverscrollIndicator: AndroidOverscrollIndicator.glow),
      home: ListView(
        children: const <Widget>[
          SizedBox(
            height: 1000.0,
            width: 1000.0,
            child: Text('Test'),
          ),
        ],
      ),
    ));

    expect(find.byType(StretchingOverscrollIndicator), findsOneWidget);
    expect(find.byType(GlowingOverscrollIndicator), findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets(
    'ListView clip behavior updates overscroll indicator clip behavior', (WidgetTester tester) async {
      Widget buildFrame(Clip clipBehavior) {
        return MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Column(
            children: <Widget>[
              SizedBox(
                height: 300,
                child: ListView.builder(
                  itemCount: 20,
                  clipBehavior: clipBehavior,
                  itemBuilder: (BuildContext context, int index){
                    return Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Text('Index $index'),
                    );
                  },
                ),
              ),
              Opacity(
                opacity: 0.5,
                child: Container(
                  color: const Color(0xD0FF0000),
                  height: 100,
                ),
              ),
            ],
          ),
        );
      }

      // Test default clip behavior.
      await tester.pumpWidget(buildFrame(Clip.hardEdge));

      expect(find.byType(StretchingOverscrollIndicator), findsOneWidget);
      expect(find.byType(GlowingOverscrollIndicator), findsNothing);
      expect(find.text('Index 1'), findsOneWidget);

      RenderClipRect renderClip = tester.allRenderObjects.whereType<RenderClipRect>().first;
      // Currently not clipping
      expect(renderClip.clipBehavior, equals(Clip.none));

      TestGesture gesture = await tester.startGesture(tester.getCenter(find.text('Index 1')));
      // Overscroll the start.
      await gesture.moveBy(const Offset(0.0, 200.0));
      await tester.pumpAndSettle();
      expect(find.text('Index 1'), findsOneWidget);
      expect(tester.getCenter(find.text('Index 1')).dy, greaterThan(0));
      renderClip = tester.allRenderObjects.whereType<RenderClipRect>().first;
      // Now clipping
      expect(renderClip.clipBehavior, equals(Clip.hardEdge));

      await gesture.up();
      await tester.pumpAndSettle();

      // Test custom clip behavior.
      await tester.pumpWidget(buildFrame(Clip.none));

      renderClip = tester.allRenderObjects.whereType<RenderClipRect>().first;
      // Currently not clipping
      expect(renderClip.clipBehavior, equals(Clip.none));

      gesture = await tester.startGesture(tester.getCenter(find.text('Index 1')));
      // Overscroll the start.
      await gesture.moveBy(const Offset(0.0, 200.0));
      await tester.pumpAndSettle();
      expect(find.text('Index 1'), findsOneWidget);
      expect(tester.getCenter(find.text('Index 1')).dy, greaterThan(0));
      renderClip = tester.allRenderObjects.whereType<RenderClipRect>().first;
      // Now clipping
      expect(renderClip.clipBehavior, equals(Clip.none));

      await gesture.up();
      await tester.pumpAndSettle();
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('When `useInheritedMediaQuery` is true an existing MediaQuery is used if one is available', (WidgetTester tester) async {
    late BuildContext capturedContext;
    final UniqueKey uniqueKey = UniqueKey();
    await tester.pumpWidget(
      MediaQuery(
        key: uniqueKey,
        data: const MediaQueryData(),
        child: MaterialApp(
          useInheritedMediaQuery: true,
          builder: (BuildContext context, Widget? child) {
            capturedContext = context;
            return const Placeholder();
          },
          color: const Color(0xFF123456),
        ),
      ),
    );
    expect(capturedContext.dependOnInheritedWidgetOfExactType<MediaQuery>()?.key, uniqueKey);
  });
}

class MockScrollBehavior extends ScrollBehavior {
  const MockScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) => const NeverScrollableScrollPhysics();
}

typedef SimpleRouterDelegateBuilder = Widget Function(BuildContext, RouteInformation);
typedef SimpleNavigatorRouterDelegatePopPage<T> = bool Function(Route<T> route, T result, SimpleNavigatorRouterDelegate delegate);

class SimpleRouteInformationParser extends RouteInformationParser<RouteInformation> {
  SimpleRouteInformationParser();

  @override
  Future<RouteInformation> parseRouteInformation(RouteInformation information) {
    return SynchronousFuture<RouteInformation>(information);
  }

  @override
  RouteInformation restoreRouteInformation(RouteInformation configuration) {
    return configuration;
  }
}

class SimpleNavigatorRouterDelegate extends RouterDelegate<RouteInformation> with PopNavigatorRouterDelegateMixin<RouteInformation>, ChangeNotifier {
  SimpleNavigatorRouterDelegate({
    required this.builder,
    required this.onPopPage,
  });

  @override
  GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  RouteInformation get routeInformation => _routeInformation;
  late RouteInformation _routeInformation;
  set routeInformation(RouteInformation newValue) {
    _routeInformation = newValue;
    notifyListeners();
  }

  SimpleRouterDelegateBuilder builder;
  SimpleNavigatorRouterDelegatePopPage<void> onPopPage;

  @override
  Future<void> setNewRoutePath(RouteInformation configuration) {
    _routeInformation = configuration;
    return SynchronousFuture<void>(null);
  }

  bool _handlePopPage(Route<void> route, void data) {
    return onPopPage(route, data, this);
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onPopPage: _handlePopPage,
      pages: <Page<void>>[
        // We need at least two pages for the pop to propagate through.
        // Otherwise, the navigator will bubble the pop to the system navigator.
        const MaterialPage<void>(
          child: Text('base'),
        ),
        MaterialPage<void>(
          key: ValueKey<String>(routeInformation.location!),
          child: builder(context, routeInformation),
        ),
      ],
    );
  }
}
