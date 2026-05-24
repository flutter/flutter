// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final TestWidgetsFlutterBinding binding = TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Default PageTransitionsTheme platform', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: Text('home')));
    final PageTransitionsTheme theme = Theme.of(
      tester.element(find.text('home')),
    ).pageTransitionsTheme;
    expect(theme.builders, isNotNull);
    for (final TargetPlatform platform in TargetPlatform.values) {
      switch (platform) {
        case TargetPlatform.android:
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          expect(
            theme.builders[platform],
            isNotNull,
            reason: 'theme builder for $platform is null',
          );
        case TargetPlatform.fuchsia:
          expect(
            theme.builders[platform],
            isNull,
            reason: 'theme builder for $platform is not null',
          );
      }
    }
  });

  testWidgets(
    'Default PageTransitionsTheme builds a CupertinoPageTransition',
    (WidgetTester tester) async {
      final routes = <String, WidgetBuilder>{
        '/': (BuildContext context) => Material(
          child: TextButton(
            child: const Text('push'),
            onPressed: () {
              Navigator.of(context).pushNamed('/b');
            },
          ),
        ),
        '/b': (BuildContext context) => const Text('page b'),
      };

      await tester.pumpWidget(MaterialApp(routes: routes));

      expect(
        Theme.of(tester.element(find.text('push'))).platform,
        debugDefaultTargetPlatformOverride,
      );
      expect(find.byType(CupertinoPageTransition), findsOneWidget);

      await tester.tap(find.text('push'));
      await tester.pumpAndSettle();
      expect(find.text('page b'), findsOneWidget);
      expect(find.byType(CupertinoPageTransition), findsOneWidget);
    },
    variant: const TargetPlatformVariant(<TargetPlatform>{
      TargetPlatform.iOS,
      TargetPlatform.macOS,
    }),
  );

  testWidgets(
    'Default PageTransitionsTheme builds a _FadeForwardsPageTransition for android',
    (WidgetTester tester) async {
      final routes = <String, WidgetBuilder>{
        '/': (BuildContext context) => Material(
          child: TextButton(
            child: const Text('push'),
            onPressed: () {
              Navigator.of(context).pushNamed('/b');
            },
          ),
        ),
        '/b': (BuildContext context) => const Text('page b'),
      };

      await tester.pumpWidget(MaterialApp(routes: routes));

      Finder findFadeForwardsPageTransition() {
        return find.descendant(
          of: find.byType(MaterialApp),
          matching: find.byWidgetPredicate(
            (Widget w) => '${w.runtimeType}' == '_FadeForwardsPageTransition',
          ),
        );
      }

      expect(
        Theme.of(tester.element(find.text('push'))).platform,
        debugDefaultTargetPlatformOverride,
      );
      expect(findFadeForwardsPageTransition(), findsOneWidget);

      await tester.tap(find.text('push'));
      await tester.pumpAndSettle();
      expect(find.text('page b'), findsOneWidget);
      expect(findFadeForwardsPageTransition(), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'Default background color when FadeForwardsPageTransitionBuilder is used',
    (WidgetTester tester) async {
      final routes = <String, WidgetBuilder>{
        '/': (BuildContext context) => Material(
          child: TextButton(
            child: const Text('push'),
            onPressed: () {
              Navigator.of(context).pushNamed('/b');
            },
          ),
        ),
        '/b': (BuildContext context) => const Text('page b'),
      };

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: <TargetPlatform, PageTransitionsBuilder>{
                TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
              },
            ),
            colorScheme: ThemeData().colorScheme.copyWith(surface: Colors.pink),
          ),
          routes: routes,
        ),
      );

      Finder findFadeForwardsPageTransition() {
        return find.descendant(
          of: find.byType(MaterialApp),
          matching: find.byWidgetPredicate(
            (Widget w) => '${w.runtimeType}' == '_FadeForwardsPageTransition',
          ),
        );
      }

      expect(findFadeForwardsPageTransition(), findsOneWidget);

      await tester.tap(find.text('push'));
      await tester.pump(const Duration(milliseconds: 400));

      final Finder coloredBoxFinder = find.byType(ColoredBox).last;
      expect(coloredBoxFinder, findsOneWidget);
      final ColoredBox coloredBox = tester.widget<ColoredBox>(coloredBoxFinder);
      expect(coloredBox.color, Colors.pink);

      await tester.pumpAndSettle();
      expect(find.text('page b'), findsOneWidget);
      expect(findFadeForwardsPageTransition(), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'Override background color in FadeForwardsPageTransitionBuilder',
    (WidgetTester tester) async {
      final routes = <String, WidgetBuilder>{
        '/': (BuildContext context) => Material(
          child: TextButton(
            child: const Text('push'),
            onPressed: () {
              Navigator.of(context).pushNamed('/b');
            },
          ),
        ),
        '/b': (BuildContext context) => const Text('page b'),
      };

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: <TargetPlatform, PageTransitionsBuilder>{
                TargetPlatform.android: FadeForwardsPageTransitionsBuilder(
                  backgroundColor: Colors.lightGreen,
                ),
              },
            ),
            colorScheme: ThemeData().colorScheme.copyWith(surface: Colors.pink),
          ),
          routes: routes,
        ),
      );

      Finder findFadeForwardsPageTransition() {
        return find.descendant(
          of: find.byType(MaterialApp),
          matching: find.byWidgetPredicate(
            (Widget w) => '${w.runtimeType}' == '_FadeForwardsPageTransition',
          ),
        );
      }

      expect(findFadeForwardsPageTransition(), findsOneWidget);

      await tester.tap(find.text('push'));
      await tester.pump(const Duration(milliseconds: 400));

      final Finder coloredBoxFinder = find.byType(ColoredBox).last;
      expect(coloredBoxFinder, findsOneWidget);
      final ColoredBox coloredBox = tester.widget<ColoredBox>(coloredBoxFinder);
      expect(coloredBox.color, Colors.lightGreen);

      await tester.pumpAndSettle();
      expect(find.text('page b'), findsOneWidget);
      expect(findFadeForwardsPageTransition(), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  group('FadeForwardsPageTransitionsBuilder transitions', () {
    testWidgets(
      'opacity fades out during forward secondary animation',
      (WidgetTester tester) async {
        final controller = AnimationController(
          duration: const Duration(milliseconds: 100),
          vsync: const TestVSync(),
        );
        addTearDown(controller.dispose);
        final Animation<double> animation = Tween<double>(begin: 1, end: 0).animate(controller);
        final Animation<double> secondaryAnimation = Tween<double>(
          begin: 0,
          end: 1,
        ).animate(controller);

        await tester.pumpWidget(
          Builder(
            builder: (BuildContext context) {
              return const FadeForwardsPageTransitionsBuilder().delegatedTransition!(
                context,
                animation,
                secondaryAnimation,
                false,
                const SizedBox(),
              )!;
            },
          ),
        );

        final RenderAnimatedOpacity? renderOpacity = tester
            .element(find.byType(SizedBox))
            .findAncestorRenderObjectOfType<RenderAnimatedOpacity>();

        // Since secondary animation is forward, transition will be reverse between duration 0 to 0.25.
        controller.value = 0.0;
        await tester.pump();
        expect(renderOpacity?.opacity.value, 1.0);

        controller.value = 0.25;
        await tester.pump();
        expect(renderOpacity?.opacity.value, 0.0);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.android),
    );

    testWidgets(
      'opacity fades in during reverse secondary animaation',
      (WidgetTester tester) async {
        final controller = AnimationController(
          duration: const Duration(milliseconds: 100),
          vsync: const TestVSync(),
        );
        addTearDown(controller.dispose);
        final Animation<double> animation = Tween<double>(begin: 0, end: 1).animate(controller);
        final Animation<double> secondaryAnimation = Tween<double>(
          begin: 1,
          end: 0,
        ).animate(controller);

        await tester.pumpWidget(
          Builder(
            builder: (BuildContext context) {
              return const FadeForwardsPageTransitionsBuilder().delegatedTransition!(
                context,
                animation,
                secondaryAnimation,
                false,
                const SizedBox(),
              )!;
            },
          ),
        );

        final RenderAnimatedOpacity? renderOpacity = tester
            .element(find.byType(SizedBox))
            .findAncestorRenderObjectOfType<RenderAnimatedOpacity>();

        // Since secondary animation is reverse, transition will be forward between duration 0.75 to 1.0.
        controller.value = 0.75;
        await tester.pump();
        expect(renderOpacity?.opacity.value, 0.0);

        controller.value = 1.0;
        await tester.pump();
        expect(renderOpacity?.opacity.value, 1.0);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.android),
    );

    testWidgets(
      'FadeForwardsPageTransitionBuilder does not use ColoredBox for non-opaque routes',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              pageTransitionsTheme: const PageTransitionsTheme(
                builders: <TargetPlatform, PageTransitionsBuilder>{
                  TargetPlatform.android: FadeForwardsPageTransitionsBuilder(
                    backgroundColor: Colors.lightGreen,
                  ),
                },
              ),
            ),
            home: Builder(
              builder: (BuildContext context) {
                return Material(
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder<void>(
                          opaque: false,
                          pageBuilder: (_, _, _) {
                            return Material(
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(builder: (_) => const Text('page b')),
                                  );
                                },
                                child: const Text('push b'),
                              ),
                            );
                          },
                        ),
                      );
                    },
                    child: const Text('push a'),
                  ),
                );
              },
            ),
          ),
        );

        await tester.tap(find.text('push a'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('push b'));
        await tester.pump(const Duration(milliseconds: 400));

        void findColoredBox() {
          expect(
            find.byWidgetPredicate((Widget w) => w is ColoredBox && w.color == Colors.lightGreen),
            findsNothing,
          );
        }

        // Check that ColoredBox is not used for non-opaque route.
        findColoredBox();

        await tester.pumpAndSettle();

        Navigator.pop(tester.element(find.text('page b')));

        await tester.pumpAndSettle(const Duration(milliseconds: 400));

        // Check that ColoredBox is not used for non-opaque route
        findColoredBox();
      },
      variant: TargetPlatformVariant.only(TargetPlatform.android),
    );
  });

  testWidgets(
    'FadeForwardsPageTransitionBuilder default duration is 800ms',
    (WidgetTester tester) async {
      final routes = <String, WidgetBuilder>{
        '/': (BuildContext context) => Material(
          child: TextButton(
            child: const Text('push'),
            onPressed: () {
              Navigator.of(context).pushNamed('/b');
            },
          ),
        ),
        '/b': (BuildContext context) => const Text('page b'),
      };

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: <TargetPlatform, PageTransitionsBuilder>{
                TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
              },
            ),
          ),
          routes: routes,
        ),
      );

      Finder findFadeForwardsPageTransition() {
        return find.descendant(
          of: find.byType(MaterialApp),
          matching: find.byWidgetPredicate(
            (Widget w) => '${w.runtimeType}' == '_FadeForwardsPageTransition',
          ),
        );
      }

      expect(findFadeForwardsPageTransition(), findsOneWidget);

      await tester.tap(find.text('push'));
      await tester.pump(const Duration(milliseconds: 799));
      expect(find.text('page b'), findsNothing);
      ColoredBox coloredBox = tester.widget(find.byType(ColoredBox).last);
      expect(
        coloredBox.color,
        isNot(Colors.transparent),
      ); // Color is not transparent during animation.

      await tester.pump(const Duration(milliseconds: 801));
      expect(find.text('page b'), findsOneWidget);
      coloredBox = tester.widget(find.byType(ColoredBox).last);
      expect(coloredBox.color, Colors.transparent); // Color is transparent during animation.
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'CupertinoPageTransitionsBuilder default duration is 500ms',
    (WidgetTester tester) async {
      final routes = <String, WidgetBuilder>{
        '/': (BuildContext context) => Material(
          child: TextButton(
            child: const Text('push'),
            onPressed: () {
              Navigator.of(context).pushNamed('/b');
            },
          ),
        ),
        '/b': (BuildContext context) => const Text('page b'),
      };

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: <TargetPlatform, PageTransitionsBuilder>{
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              },
            ),
          ),
          routes: routes,
        ),
      );

      expect(find.byType(CupertinoPageTransition), findsOneWidget);

      await tester.tap(find.text('push'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 499));
      expect(tester.hasRunningAnimations, isTrue);

      await tester.pump(const Duration(milliseconds: 10));
      expect(tester.hasRunningAnimations, isFalse);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'Animation duration changes accordingly when page transition builder changes',
    (WidgetTester tester) async {
      Widget buildApp(PageTransitionsBuilder pageTransitionBuilder) {
        return MaterialApp(
          theme: ThemeData(
            pageTransitionsTheme: PageTransitionsTheme(
              builders: <TargetPlatform, PageTransitionsBuilder>{
                TargetPlatform.android: pageTransitionBuilder,
              },
            ),
          ),
          routes: <String, WidgetBuilder>{
            '/': (BuildContext context) => Material(
              child: TextButton(
                child: const Text('push'),
                onPressed: () {
                  Navigator.of(context).pushNamed('/b');
                },
              ),
            ),
            '/b': (BuildContext context) => Material(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  TextButton(
                    child: const Text('pop'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  const Text('page b'),
                ],
              ),
            ),
          },
        );
      }

      await tester.pumpWidget(buildApp(const FadeForwardsPageTransitionsBuilder()));

      Finder findFadeForwardsPageTransition() {
        return find.descendant(
          of: find.byType(MaterialApp),
          matching: find.byWidgetPredicate(
            (Widget w) => '${w.runtimeType}' == '_FadeForwardsPageTransition',
          ),
        );
      }

      expect(findFadeForwardsPageTransition(), findsOneWidget);

      await tester.tap(find.text('push'));
      await tester.pump(const Duration(milliseconds: 799));
      expect(find.text('page b'), findsNothing);
      ColoredBox coloredBox = tester.widget(find.byType(ColoredBox).last);
      expect(
        coloredBox.color,
        isNot(Colors.transparent),
      ); // The color is not transparent during animation.

      await tester.pump(const Duration(milliseconds: 801));
      expect(find.text('page b'), findsOneWidget);
      coloredBox = tester.widget(find.byType(ColoredBox).last);
      expect(coloredBox.color, Colors.transparent); // The color is transparent during animation.

      await tester.pumpWidget(buildApp(const FadeUpwardsPageTransitionsBuilder()));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(MaterialApp),
          matching: find.byWidgetPredicate(
            (Widget w) => '${w.runtimeType}' == '_FadeUpwardsPageTransition',
          ),
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('pop'));
      await tester.pump(const Duration(milliseconds: 299));
      expect(find.text('page b'), findsOneWidget);
      expect(
        find.byType(ColoredBox),
        findsNothing,
      ); // ColoredBox doesn't exist in FadeUpwardsPageTransition.

      await tester.pump(const Duration(milliseconds: 301));
      expect(find.text('page b'), findsNothing);
      expect(find.text('push'), findsOneWidget); // The first page
      expect(find.byType(ColoredBox), findsNothing);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'PageTransitionsTheme override builds a CupertinoPageTransition on android',
    (WidgetTester tester) async {
      final routes = <String, WidgetBuilder>{
        '/': (BuildContext context) => Material(
          child: TextButton(
            child: const Text('push'),
            onPressed: () {
              Navigator.of(context).pushNamed('/b');
            },
          ),
        ),
        '/b': (BuildContext context) => const Text('page b'),
      };

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: <TargetPlatform, PageTransitionsBuilder>{
                TargetPlatform.android: CupertinoPageTransitionsBuilder(),
              },
            ),
          ),
          routes: routes,
        ),
      );

      expect(
        Theme.of(tester.element(find.text('push'))).platform,
        debugDefaultTargetPlatformOverride,
      );
      expect(find.byType(CupertinoPageTransition), findsOneWidget);

      await tester.tap(find.text('push'));
      await tester.pumpAndSettle();
      expect(find.text('page b'), findsOneWidget);
      expect(find.byType(CupertinoPageTransition), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'CupertinoPageTransition on android does not block gestures on backswipe',
    (WidgetTester tester) async {
      final routes = <String, WidgetBuilder>{
        '/': (BuildContext context) => Material(
          child: TextButton(
            child: const Text('push'),
            onPressed: () {
              Navigator.of(context).pushNamed('/b');
            },
          ),
        ),
        '/b': (BuildContext context) => const Text('page b'),
      };

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: <TargetPlatform, PageTransitionsBuilder>{
                TargetPlatform.android: CupertinoPageTransitionsBuilder(),
              },
            ),
          ),
          routes: routes,
        ),
      );

      expect(
        Theme.of(tester.element(find.text('push'))).platform,
        debugDefaultTargetPlatformOverride,
      );
      expect(find.byType(CupertinoPageTransition), findsOneWidget);

      await tester.tap(find.text('push'));
      await tester.pumpAndSettle();
      expect(find.text('page b'), findsOneWidget);
      expect(find.byType(CupertinoPageTransition), findsOneWidget);

      await tester.pumpAndSettle(const Duration(minutes: 1));

      final TestGesture gesture = await tester.startGesture(const Offset(5.0, 100.0));
      await gesture.moveBy(const Offset(400.0, 0.0));
      await gesture.up();
      await tester.pump();

      await tester.pumpAndSettle(const Duration(minutes: 1));

      expect(find.text('push'), findsOneWidget);
      await tester.tap(find.text('push'));
      await tester.pumpAndSettle();
      expect(find.text('page b'), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'PageTransitionsTheme override builds a _FadeUpwardsTransition',
    (WidgetTester tester) async {
      final routes = <String, WidgetBuilder>{
        '/': (BuildContext context) => Material(
          child: TextButton(
            child: const Text('push'),
            onPressed: () {
              Navigator.of(context).pushNamed('/b');
            },
          ),
        ),
        '/b': (BuildContext context) => const Text('page b'),
      };

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: <TargetPlatform, PageTransitionsBuilder>{
                TargetPlatform.android:
                    FadeUpwardsPageTransitionsBuilder(), // creates a _FadeUpwardsTransition
              },
            ),
          ),
          routes: routes,
        ),
      );

      Finder findFadeUpwardsPageTransition() {
        return find.descendant(
          of: find.byType(MaterialApp),
          matching: find.byWidgetPredicate(
            (Widget w) => '${w.runtimeType}' == '_FadeUpwardsPageTransition',
          ),
        );
      }

      expect(
        Theme.of(tester.element(find.text('push'))).platform,
        debugDefaultTargetPlatformOverride,
      );
      expect(findFadeUpwardsPageTransition(), findsOneWidget);

      await tester.tap(find.text('push'));
      await tester.pumpAndSettle();
      expect(find.text('page b'), findsOneWidget);
      expect(findFadeUpwardsPageTransition(), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  Widget boilerplate({
    required bool themeAllowSnapshotting,
    bool secondRouteAllowSnapshotting = true,
  }) {
    return MaterialApp(
      theme: ThemeData(
        pageTransitionsTheme: PageTransitionsTheme(
          builders: <TargetPlatform, PageTransitionsBuilder>{
            TargetPlatform.android: ZoomPageTransitionsBuilder(
              allowSnapshotting: themeAllowSnapshotting,
            ),
          },
        ),
      ),
      onGenerateRoute: (RouteSettings settings) {
        if (settings.name == '/') {
          return MaterialPageRoute<Widget>(builder: (_) => const Material(child: Text('Page 1')));
        }
        return MaterialPageRoute<Widget>(
          builder: (_) => const Material(child: Text('Page 2')),
          allowSnapshotting: secondRouteAllowSnapshotting,
        );
      },
    );
  }

  bool isTransitioningWithSnapshotting(WidgetTester tester, Finder of) {
    final Iterable<Layer> layers = tester.layerListOf(
      find.ancestor(of: of, matching: find.byType(SnapshotWidget)).first,
    );
    final hasOneOpacityLayer = layers.whereType<OpacityLayer>().length == 1;
    final hasOneTransformLayer = layers.whereType<TransformLayer>().length == 1;
    // When snapshotting is on, the OpacityLayer and TransformLayer will not be
    // applied directly.
    return !(hasOneOpacityLayer && hasOneTransformLayer);
  }

  testWidgets(
    'ZoomPageTransitionsBuilder default route snapshotting behavior',
    (WidgetTester tester) async {
      await tester.pumpWidget(boilerplate(themeAllowSnapshotting: true));

      final Finder page1 = find.text('Page 1');
      final Finder page2 = find.text('Page 2');

      // Transitioning from page 1 to page 2.
      tester.state<NavigatorState>(find.byType(Navigator)).pushNamed('/2');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Exiting route should be snapshotted.
      expect(isTransitioningWithSnapshotting(tester, page1), isTrue);

      // Entering route should be snapshotted.
      expect(isTransitioningWithSnapshotting(tester, page2), isTrue);

      await tester.pumpAndSettle();

      // Transitioning back from page 2 to page 1.
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Exiting route should be snapshotted.
      expect(isTransitioningWithSnapshotting(tester, page2), isTrue);

      // Entering route should be snapshotted.
      expect(isTransitioningWithSnapshotting(tester, page1), isTrue);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
    skip: kIsWeb, // [intended] rasterization is not used on the web.
  );

  testWidgets(
    'ZoomPageTransitionsBuilder.allowSnapshotting can disable route snapshotting',
    (WidgetTester tester) async {
      await tester.pumpWidget(boilerplate(themeAllowSnapshotting: false));

      final Finder page1 = find.text('Page 1');
      final Finder page2 = find.text('Page 2');

      // Transitioning from page 1 to page 2.
      tester.state<NavigatorState>(find.byType(Navigator)).pushNamed('/2');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Exiting route should not be snapshotted.
      expect(isTransitioningWithSnapshotting(tester, page1), isFalse);

      // Entering route should not be snapshotted.
      expect(isTransitioningWithSnapshotting(tester, page2), isFalse);

      await tester.pumpAndSettle();

      // Transitioning back from page 2 to page 1.
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Exiting route should not be snapshotted.
      expect(isTransitioningWithSnapshotting(tester, page2), isFalse);

      // Entering route should not be snapshotted.
      expect(isTransitioningWithSnapshotting(tester, page1), isFalse);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
    skip: kIsWeb, // [intended] rasterization is not used on the web.
  );

  testWidgets(
    'Setting PageRoute.allowSnapshotting to false overrides ZoomPageTransitionsBuilder.allowSnapshotting = true',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        boilerplate(themeAllowSnapshotting: true, secondRouteAllowSnapshotting: false),
      );

      final Finder page1 = find.text('Page 1');
      final Finder page2 = find.text('Page 2');

      // Transitioning from page 1 to page 2.
      tester.state<NavigatorState>(find.byType(Navigator)).pushNamed('/2');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // First route should be snapshotted.
      expect(isTransitioningWithSnapshotting(tester, page1), isTrue);

      // Second route should not be snapshotted.
      expect(isTransitioningWithSnapshotting(tester, page2), isFalse);

      await tester.pumpAndSettle();
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
    skip: kIsWeb, // [intended] rasterization is not used on the web.
  );

  testWidgets(
    '_ZoomPageTransition only causes child widget built once',
    (WidgetTester tester) async {
      // Regression test for https://github.com/flutter/flutter/issues/58345

      var builtCount = 0;

      final routes = <String, WidgetBuilder>{
        '/': (BuildContext context) => Material(
          child: TextButton(
            child: const Text('push'),
            onPressed: () {
              Navigator.of(context).pushNamed('/b');
            },
          ),
        ),
        '/b': (BuildContext context) => StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            builtCount++; // Increase [builtCount] each time the widget build
            return TextButton(
              child: const Text('pop'),
              onPressed: () {
                Navigator.pop(context);
              },
            );
          },
        ),
      };

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: <TargetPlatform, PageTransitionsBuilder>{
                TargetPlatform.android:
                    ZoomPageTransitionsBuilder(), // creates a _ZoomPageTransition
              },
            ),
          ),
          routes: routes,
        ),
      );

      // No matter push or pop was called, the child widget should built only once.
      await tester.tap(find.text('push'));
      await tester.pumpAndSettle();
      expect(builtCount, 1);

      await tester.tap(find.text('pop'));
      await tester.pumpAndSettle();
      expect(builtCount, 1);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'predictive back gestures pop the route on all platforms regardless of whether their transition handles predictive back',
    (WidgetTester tester) async {
      final routes = <String, WidgetBuilder>{
        '/': (BuildContext context) => Material(
          child: TextButton(
            child: const Text('push'),
            onPressed: () {
              Navigator.of(context).pushNamed('/b');
            },
          ),
        ),
        '/b': (BuildContext context) => const Text('page b'),
      };

      await tester.pumpWidget(MaterialApp(routes: routes));

      expect(find.text('push'), findsOneWidget);
      expect(find.text('page b'), findsNothing);

      await tester.tap(find.text('push'));
      await tester.pumpAndSettle();

      expect(find.text('push'), findsNothing);
      expect(find.text('page b'), findsOneWidget);

      // Start a system pop gesture.
      final ByteData startMessage = const StandardMethodCodec().encodeMethodCall(
        const MethodCall('startBackGesture', <String, dynamic>{
          'touchOffset': <double>[5.0, 300.0],
          'progress': 0.0,
          'swipeEdge': 0, // left
        }),
      );
      await binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/backgesture',
        startMessage,
        (ByteData? _) {},
      );
      await tester.pump();

      expect(find.text('push'), findsNothing);
      expect(find.text('page b'), findsOneWidget);

      // Drag the system back gesture far enough to commit.
      final ByteData updateMessage = const StandardMethodCodec().encodeMethodCall(
        const MethodCall('updateBackGestureProgress', <String, dynamic>{
          'x': 100.0,
          'y': 300.0,
          'progress': 0.35,
          'swipeEdge': 0, // left
        }),
      );
      await binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/backgesture',
        updateMessage,
        (ByteData? _) {},
      );
      await tester.pumpAndSettle();

      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          // Shows both pages while doing the "peek" predicitve back transition.
          expect(find.text('push'), findsOneWidget);
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
        case TargetPlatform.linux:
        case TargetPlatform.fuchsia:
        case TargetPlatform.windows:
          // Does no transition yet; still shows page b only.
          expect(find.text('push'), findsNothing);
      }
      expect(find.text('page b'), findsOneWidget);

      // Commit the system back gesture.
      final ByteData commitMessage = const StandardMethodCodec().encodeMethodCall(
        const MethodCall('commitBackGesture'),
      );
      await binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/backgesture',
        commitMessage,
        (ByteData? _) {},
      );
      await tester.pumpAndSettle();
      expect(find.text('push'), findsOneWidget);
      expect(find.text('page b'), findsNothing);
    },
    variant: TargetPlatformVariant.all(),
  );

  testWidgets('predictive back is the default on Android', (WidgetTester tester) async {
    final routes = <String, WidgetBuilder>{
      '/': (BuildContext context) => Material(
        child: TextButton(
          child: const Text('push'),
          onPressed: () {
            Navigator.of(context).pushNamed('/b');
          },
        ),
      ),
    };
    await tester.pumpWidget(MaterialApp(routes: routes));

    final ThemeData themeData = Theme.of(tester.element(find.text('push')));
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        expect(
          themeData.pageTransitionsTheme.builders[defaultTargetPlatform],
          isA<PredictiveBackPageTransitionsBuilder>(),
        );
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
      case TargetPlatform.windows:
        expect(
          themeData.pageTransitionsTheme.builders[defaultTargetPlatform],
          isNot(isA<PredictiveBackPageTransitionsBuilder>()),
        );
    }
  }, variant: TargetPlatformVariant.all());

  testWidgets('predictive back falls back to FadeForwardsPageTransition', (
    WidgetTester tester,
  ) async {
    Finder findPredictiveBackPageTransition() {
      return find.descendant(
        of: find.byType(PrimaryScrollController),
        matching: find.byWidgetPredicate(
          (Widget w) => '${w.runtimeType}' == '_PredictiveBackSharedElementPageTransition',
        ),
      );
    }

    Finder findFallbackPageTransition() {
      return find.descendant(
        of: find.byType(PrimaryScrollController),
        matching: find.byWidgetPredicate(
          (Widget w) => '${w.runtimeType}' == '_FadeForwardsPageTransition',
        ),
      );
    }

    final routes = <String, WidgetBuilder>{
      '/': (BuildContext context) => Material(
        child: TextButton(
          child: const Text('push'),
          onPressed: () {
            Navigator.of(context).pushNamed('/b');
          },
        ),
      ),
      '/b': (BuildContext context) => const Text('page b'),
    };

    await tester.pumpWidget(
      MaterialApp(
        routes: routes,
        theme: ThemeData(
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: <TargetPlatform, PageTransitionsBuilder>{
              TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
              TargetPlatform.iOS: PredictiveBackPageTransitionsBuilder(),
              TargetPlatform.macOS: PredictiveBackPageTransitionsBuilder(),
              TargetPlatform.windows: PredictiveBackPageTransitionsBuilder(),
              TargetPlatform.linux: PredictiveBackPageTransitionsBuilder(),
              TargetPlatform.fuchsia: PredictiveBackPageTransitionsBuilder(),
            },
          ),
        ),
      ),
    );

    final ThemeData themeData = Theme.of(tester.element(find.text('push')));
    expect(
      themeData.pageTransitionsTheme.builders[defaultTargetPlatform],
      isA<PredictiveBackPageTransitionsBuilder>(),
    );

    expect(find.text('push'), findsOneWidget);
    expect(find.text('page b'), findsNothing);

    await tester.tap(find.text('push'));
    await tester.pumpAndSettle();

    expect(find.text('push'), findsNothing);
    expect(find.text('page b'), findsOneWidget);

    // Only Android sends system back gestures.
    if (defaultTargetPlatform == TargetPlatform.android) {
      final ByteData startMessage = const StandardMethodCodec().encodeMethodCall(
        const MethodCall('startBackGesture', <String, dynamic>{
          'touchOffset': <double>[5.0, 300.0],
          'progress': 0.0,
          'swipeEdge': 0, // left
        }),
      );
      await binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/backgesture',
        startMessage,
        (ByteData? _) {},
      );
      await tester.pump();
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        expect(findPredictiveBackPageTransition(), findsOneWidget);
        expect(findFallbackPageTransition(), findsNothing);
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
      case TargetPlatform.windows:
        expect(findPredictiveBackPageTransition(), findsNothing);
        expect(findFallbackPageTransition(), findsOneWidget);
    }

    expect(find.text('push'), findsNothing);
    expect(find.text('page b'), findsOneWidget);

    // Drag the system back gesture far enough to commit.
    if (defaultTargetPlatform == TargetPlatform.android) {
      final ByteData updateMessage = const StandardMethodCodec().encodeMethodCall(
        const MethodCall('updateBackGestureProgress', <String, dynamic>{
          'x': 100.0,
          'y': 300.0,
          'progress': 0.35,
          'swipeEdge': 0, // left
        }),
      );
      await binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/backgesture',
        updateMessage,
        (ByteData? _) {},
      );
      await tester.pumpAndSettle();
      expect(find.text('push'), findsOneWidget);
    } else {
      expect(find.text('push'), findsNothing);
    }

    expect(find.text('page b'), findsOneWidget);

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        expect(findPredictiveBackPageTransition(), findsNWidgets(2));
        expect(findFallbackPageTransition(), findsNothing);
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
      case TargetPlatform.windows:
        expect(findPredictiveBackPageTransition(), findsNothing);
        expect(findFallbackPageTransition(), findsOneWidget);
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      // Commit the system back gesture on Android.
      final ByteData commitMessage = const StandardMethodCodec().encodeMethodCall(
        const MethodCall('commitBackGesture'),
      );
      await binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/backgesture',
        commitMessage,
        (ByteData? _) {},
      );
    } else {
      // On other platforms, send a one-off system pop.
      final ByteData popMessage = const JSONMethodCodec().encodeMethodCall(
        const MethodCall('popRoute'),
      );
      await binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/navigation',
        popMessage,
        (ByteData? _) {},
      );
    }
    await tester.pump();

    expect(find.text('push'), findsOneWidget);
    expect(find.text('page b'), findsOneWidget);

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        expect(findPredictiveBackPageTransition(), findsNWidgets(2));
        expect(findFallbackPageTransition(), findsNothing);
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
      case TargetPlatform.windows:
        expect(findPredictiveBackPageTransition(), findsNothing);
        expect(findFallbackPageTransition(), findsNWidgets(2));
    }

    await tester.pumpAndSettle();

    expect(find.text('push'), findsOneWidget);
    expect(find.text('page b'), findsNothing);

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        expect(findPredictiveBackPageTransition(), findsNothing);
        expect(findFallbackPageTransition(), findsOneWidget);
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
      case TargetPlatform.windows:
        expect(findPredictiveBackPageTransition(), findsNothing);
        expect(findFallbackPageTransition(), findsOneWidget);
    }
  }, variant: TargetPlatformVariant.all());

  testWidgets(
    'ZoomPageTransitionsBuilder uses theme color during transition effects',
    (WidgetTester tester) async {
      // Color that is being tested for presence.
      const themeTestSurfaceColor = Color.fromARGB(255, 195, 255, 0);

      final routes = <String, WidgetBuilder>{
        '/': (BuildContext context) => Material(
          child: Scaffold(
            appBar: AppBar(title: const Text('Home Page')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/scaffolded');
                    },
                    child: const Text('Route with scaffold!'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/not-scaffolded');
                    },
                    child: const Text('Route with NO scaffold!'),
                  ),
                ],
              ),
            ),
          ),
        ),
        '/scaffolded': (BuildContext context) => Material(
          child: Scaffold(
            appBar: AppBar(title: const Text('Scaffolded Page')),
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Back to home route...'),
              ),
            ),
          ),
        ),
        '/not-scaffolded': (BuildContext context) => Material(
          child: Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Back to home route...'),
            ),
          ),
        ),
      };

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              surface: themeTestSurfaceColor,
            ),
            pageTransitionsTheme: PageTransitionsTheme(
              builders: <TargetPlatform, PageTransitionsBuilder>{
                // Force all platforms to use ZoomPageTransitionsBuilder to test each one.
                for (final TargetPlatform platform in TargetPlatform.values)
                  platform: const ZoomPageTransitionsBuilder(),
              },
            ),
          ),
          routes: routes,
        ),
      );

      // Go to scaffolded page.
      await tester.tap(find.text('Route with scaffold!'));

      // Pump till animation is half-way through.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 75));

      // Verify that the render box is painting the right color for scaffolded pages.
      final RenderBox scaffoldedRenderBox = tester.firstRenderObject<RenderBox>(
        find.byType(MaterialApp),
      );
      // Expect the color to be at exactly 12.2% opacity at this time.
      expect(scaffoldedRenderBox, paints..rect(color: themeTestSurfaceColor.withOpacity(0.122)));

      await tester.pumpAndSettle();

      // Go back home and then go to non-scaffolded page.
      await tester.tap(find.text('Back to home route...'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Route with NO scaffold!'));

      // Pump till animation is half-way through.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 125));

      // Verify that the render box is painting the right color for non-scaffolded pages.
      final RenderBox nonScaffoldedRenderBox = tester.firstRenderObject<RenderBox>(
        find.byType(MaterialApp),
      );
      // Expect the color to be at exactly 59.6% opacity at this time.
      expect(nonScaffoldedRenderBox, paints..rect(color: themeTestSurfaceColor.withOpacity(0.596)));

      await tester.pumpAndSettle();

      // Verify that the transition successfully completed.
      expect(find.text('Back to home route...'), findsOneWidget);
    },
    variant: TargetPlatformVariant.all(),
  );

  testWidgets(
    'ZoomPageTransitionsBuilder uses developer-provided color during transition effects if provided',
    (WidgetTester tester) async {
      // Color that is being tested for presence.
      const Color testSurfaceColor = Colors.red;

      final routes = <String, WidgetBuilder>{
        '/': (BuildContext context) => Material(
          child: Scaffold(
            appBar: AppBar(title: const Text('Home Page')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/scaffolded');
                    },
                    child: const Text('Route with scaffold!'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/not-scaffolded');
                    },
                    child: const Text('Route with NO scaffold!'),
                  ),
                ],
              ),
            ),
          ),
        ),
        '/scaffolded': (BuildContext context) => Material(
          child: Scaffold(
            appBar: AppBar(title: const Text('Scaffolded Page')),
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Back to home route...'),
              ),
            ),
          ),
        ),
        '/not-scaffolded': (BuildContext context) => Material(
          child: Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Back to home route...'),
            ),
          ),
        ),
      };

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, surface: Colors.blue),
            pageTransitionsTheme: PageTransitionsTheme(
              builders: <TargetPlatform, PageTransitionsBuilder>{
                // Force all platforms to use ZoomPageTransitionsBuilder to test each one.
                for (final TargetPlatform platform in TargetPlatform.values)
                  platform: const ZoomPageTransitionsBuilder(backgroundColor: testSurfaceColor),
              },
            ),
          ),
          routes: routes,
        ),
      );

      // Go to scaffolded page.
      await tester.tap(find.text('Route with scaffold!'));

      // Pump till animation is half-way through.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 75));

      // Verify that the render box is painting the right color for scaffolded pages.
      final RenderBox scaffoldedRenderBox = tester.firstRenderObject<RenderBox>(
        find.byType(MaterialApp),
      );
      // Expect the color to be at exactly 12.2% opacity at this time.
      expect(scaffoldedRenderBox, paints..rect(color: testSurfaceColor.withOpacity(0.122)));

      await tester.pumpAndSettle();

      // Go back home and then go to non-scaffolded page.
      await tester.tap(find.text('Back to home route...'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Route with NO scaffold!'));

      // Pump till animation is half-way through.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 125));

      // Verify that the render box is painting the right color for non-scaffolded pages.
      final RenderBox nonScaffoldedRenderBox = tester.firstRenderObject<RenderBox>(
        find.byType(MaterialApp),
      );
      // Expect the color to be at exactly 59.6% opacity at this time.
      expect(nonScaffoldedRenderBox, paints..rect(color: testSurfaceColor.withOpacity(0.596)));

      await tester.pumpAndSettle();

      // Verify that the transition successfully completed.
      expect(find.text('Back to home route...'), findsOneWidget);
    },
    variant: TargetPlatformVariant.all(),
  );

  testWidgets(
    'Can interact with incoming route during FadeForwards back navigation',
    (WidgetTester tester) async {
      final routes = <String, WidgetBuilder>{
        '/': (BuildContext context) => Material(
          child: TextButton(
            child: const Text('push'),
            onPressed: () {
              Navigator.of(context).pushNamed('/b');
            },
          ),
        ),
        '/b': (BuildContext context) => Material(
          child: TextButton(
            child: const Text('go back'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
      };

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: <TargetPlatform, PageTransitionsBuilder>{
                TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
              },
            ),
            colorScheme: ThemeData().colorScheme.copyWith(surface: Colors.pink),
          ),
          routes: routes,
        ),
      );

      expect(find.text('push'), findsOneWidget);
      expect(find.text('go back'), findsNothing);

      // Go to the second route. The duration of the FadeForwardsPageTransition
      // is 800ms.
      await tester.tap(find.text('push'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 801));

      expect(find.text('push'), findsNothing);
      expect(find.text('go back'), findsOneWidget);

      // Tap to go back to the first route.
      await tester.tap(find.text('go back'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('push'), findsOneWidget);
      expect(find.text('go back'), findsOneWidget);

      // In the middle of the transition, tap to go back to the second route.
      await tester.tap(find.text('push'));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 401));

      expect(find.text('push'), findsOneWidget);
      expect(find.text('go back'), findsOneWidget);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('push'), findsNothing);
      expect(find.text('go back'), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets('Check onstage/offstage handling around transitions', (WidgetTester tester) async {
    final GlobalKey containerKey1 = GlobalKey();
    final GlobalKey containerKey2 = GlobalKey();
    final routes = <String, WidgetBuilder>{
      '/': (_) => Container(key: containerKey1, child: const Text('Home')),
      '/settings': (_) => Container(key: containerKey2, child: const Text('Settings')),
    };

    await tester.pumpWidget(MaterialApp(routes: routes));

    expect(find.text('Home'), isOnstage);
    expect(find.text('Settings'), findsNothing);
    expect(find.text('Overlay'), findsNothing);

    expect(Navigator.canPop(containerKey1.currentContext!), isFalse);
    Navigator.pushNamed(containerKey1.currentContext!, '/settings');
    expect(Navigator.canPop(containerKey1.currentContext!), isTrue);

    await tester.pump();

    expect(find.text('Home'), isOnstage);
    expect(find.text('Settings', skipOffstage: false), isOffstage);
    expect(find.text('Overlay'), findsNothing);

    await tester.pump(const Duration(milliseconds: 16));

    expect(find.text('Home'), isOnstage);
    expect(find.text('Settings'), isOnstage);
    expect(find.text('Overlay'), findsNothing);

    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Home'), findsNothing);
    expect(find.text('Settings'), isOnstage);
    expect(find.text('Overlay'), findsNothing);

    Navigator.push(containerKey2.currentContext!, TestOverlayRoute());

    await tester.pump();

    expect(find.text('Home'), findsNothing);
    expect(find.text('Settings'), isOnstage);
    expect(find.text('Overlay'), isOnstage);

    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Home'), findsNothing);
    expect(find.text('Settings'), isOnstage);
    expect(find.text('Overlay'), isOnstage);

    expect(Navigator.canPop(containerKey2.currentContext!), isTrue);
    Navigator.pop(containerKey2.currentContext!);
    await tester.pump();

    expect(find.text('Home'), findsNothing);
    expect(find.text('Settings'), isOnstage);
    expect(find.text('Overlay'), findsNothing);

    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Home'), findsNothing);
    expect(find.text('Settings'), isOnstage);
    expect(find.text('Overlay'), findsNothing);

    expect(Navigator.canPop(containerKey2.currentContext!), isTrue);
    Navigator.pop(containerKey2.currentContext!);
    await tester.pump();
    await tester.pump();

    expect(find.text('Home'), isOnstage);
    expect(find.text('Settings'), isOnstage);
    expect(find.text('Overlay'), findsNothing);

    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Home'), isOnstage);
    expect(find.text('Settings'), findsNothing);
    expect(find.text('Overlay'), findsNothing);

    expect(Navigator.canPop(containerKey1.currentContext!), isFalse);
  });

  testWidgets(
    'Check back gesture disables Heroes',
    (WidgetTester tester) async {
      final GlobalKey containerKey1 = GlobalKey();
      final GlobalKey containerKey2 = GlobalKey();
      const kHeroTag = 'hero';
      final routes = <String, WidgetBuilder>{
        '/': (_) => SizedBox(
          key: containerKey1,
          child: const ColoredBox(
            color: Color(0xff00ffff),
            child: Hero(tag: kHeroTag, child: Text('Home')),
          ),
        ),
        '/settings': (_) => SizedBox(
          key: containerKey2,
          child: Container(
            padding: const EdgeInsets.all(100.0),
            color: const Color(0xffff00ff),
            child: const Hero(tag: kHeroTag, child: Text('Settings')),
          ),
        ),
      };

      await tester.pumpWidget(MaterialApp(routes: routes));

      Navigator.pushNamed(containerKey1.currentContext!, '/settings');

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.text('Settings'), isOnstage);

      // Settings text is heroing to its new location
      Offset settingsOffset = tester.getTopLeft(find.text('Settings'));
      expect(settingsOffset.dx, greaterThan(0.0));
      expect(settingsOffset.dx, lessThan(100.0));
      expect(settingsOffset.dy, greaterThan(0.0));
      expect(settingsOffset.dy, lessThan(100.0));

      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Home'), findsNothing);
      expect(find.text('Settings'), isOnstage);

      // Drag from left edge to invoke the gesture.
      final TestGesture gesture = await tester.startGesture(const Offset(5.0, 100.0));
      await gesture.moveBy(const Offset(50.0, 0.0));
      await tester.pump();

      // Home is now visible.
      expect(find.text('Home'), isOnstage);
      expect(find.text('Settings'), isOnstage);

      // Home page is sliding in from the left, no heroes.
      final Offset homeOffset = tester.getTopLeft(find.text('Home'));
      expect(homeOffset.dx, lessThan(0.0));
      expect(homeOffset.dy, 0.0);

      // Settings page is sliding off to the right, no heroes.
      settingsOffset = tester.getTopLeft(find.text('Settings'));
      expect(settingsOffset.dx, greaterThan(100.0));
      expect(settingsOffset.dy, 100.0);
    },
    variant: const TargetPlatformVariant(<TargetPlatform>{
      TargetPlatform.iOS,
      TargetPlatform.macOS,
    }),
  );

  testWidgets(
    "Check back gesture doesn't start during transitions",
    (WidgetTester tester) async {
      final GlobalKey containerKey1 = GlobalKey();
      final GlobalKey containerKey2 = GlobalKey();
      final routes = <String, WidgetBuilder>{
        '/': (_) => SizedBox(key: containerKey1, child: const Text('Home')),
        '/settings': (_) => SizedBox(key: containerKey2, child: const Text('Settings')),
      };

      await tester.pumpWidget(MaterialApp(routes: routes));

      Navigator.pushNamed(containerKey1.currentContext!, '/settings');

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // We are mid-transition, both pages are on stage.
      expect(find.text('Home'), isOnstage);
      expect(find.text('Settings'), isOnstage);

      // Drag from left edge to invoke the gesture. (near bottom so we grab
      // the Settings page as it comes up).
      TestGesture gesture = await tester.startGesture(const Offset(5.0, 550.0));
      await gesture.moveBy(const Offset(500.0, 0.0));
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));

      // The original forward navigation should have completed, instead of the
      // back gesture, since we were mid transition.
      expect(find.text('Home'), findsNothing);
      expect(find.text('Settings'), isOnstage);

      // Try again now that we're settled.
      gesture = await tester.startGesture(const Offset(5.0, 550.0));
      await gesture.moveBy(const Offset(500.0, 0.0));
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));

      expect(find.text('Home'), isOnstage);
      expect(find.text('Settings'), findsNothing);
    },
    variant: const TargetPlatformVariant(<TargetPlatform>{
      TargetPlatform.iOS,
      TargetPlatform.macOS,
    }),
  );

  testWidgets('Test completed future', (WidgetTester tester) async {
    final routes = <String, WidgetBuilder>{
      '/': (_) => const Center(child: Text('home')),
      '/next': (_) => const Center(child: Text('next')),
    };

    await tester.pumpWidget(MaterialApp(routes: routes));

    final PageRoute<void> route = PageRouteBuilder<void>(
      settings: const RouteSettings(name: '/page'),
      pageBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) => const Center(child: Text('page')),
    );

    var popCount = 0;
    route.popped.whenComplete(() {
      popCount += 1;
    });

    var completeCount = 0;
    route.completed.whenComplete(() {
      completeCount += 1;
    });

    expect(popCount, 0);
    expect(completeCount, 0);

    Navigator.push(tester.element(find.text('home')), route);

    expect(popCount, 0);
    expect(completeCount, 0);

    await tester.pump();

    expect(popCount, 0);
    expect(completeCount, 0);

    await tester.pump(const Duration(milliseconds: 100));

    expect(popCount, 0);
    expect(completeCount, 0);

    await tester.pump(const Duration(milliseconds: 100));

    expect(popCount, 0);
    expect(completeCount, 0);

    await tester.pump(const Duration(seconds: 1));

    expect(popCount, 0);
    expect(completeCount, 0);

    Navigator.pop(tester.element(find.text('page')));

    expect(popCount, 0);
    expect(completeCount, 0);

    await tester.pump();

    expect(popCount, 1);
    expect(completeCount, 0);

    await tester.pump(const Duration(milliseconds: 100));

    expect(popCount, 1);
    expect(completeCount, 0);

    await tester.pump(const Duration(milliseconds: 100));

    expect(popCount, 1);
    expect(completeCount, 0);

    await tester.pump(const Duration(seconds: 1));

    expect(popCount, 1);
    expect(completeCount, 1);
  });

  testWidgets('navigating with transitions of different lengths', (WidgetTester tester) async {
    final observer = TransitionDurationObserver();

    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: <NavigatorObserver>[observer],
        onGenerateRoute: (RouteSettings settings) {
          return switch (settings.name) {
            // A route that uses the default page transition.
            '/' => MaterialPageRoute<void>(
              builder: (BuildContext context) {
                return Scaffold(
                  body: Center(
                    child: Column(
                      children: <Widget>[
                        const Text('Page 1'),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/2');
                          },
                          child: const Text('Next'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            // A route that uses ZoomPageTransitionsBuilder.
            '/2' => _TestTransitionRoute<void>(
              transitionDurationOverride: const Duration(milliseconds: 456),
              reverseTransitionDurationOverride: const Duration(milliseconds: 567),
              pageTransitionsBuilder: const ZoomPageTransitionsBuilder(),
              builder: (BuildContext context) {
                return Scaffold(
                  body: Center(
                    child: Column(
                      children: <Widget>[
                        const Text('Page 2'),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/3');
                          },
                          child: const Text('Next'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('Back'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            // A route that uses FadeForwardsPageTransitionsBuilder.
            '/3' => _TestTransitionRoute<void>(
              pageTransitionsBuilder: const FadeForwardsPageTransitionsBuilder(),
              builder: (BuildContext context) {
                return Scaffold(
                  body: Center(
                    child: Column(
                      children: <Widget>[
                        const Text('Page 3'),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('Back'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            _ => throw Exception('Invalid route.'),
          };
        },
      ),
    );

    expect(find.text('Page 1'), findsOneWidget);
    expect(find.text('Page 2'), findsNothing);
    expect(find.text('Page 3'), findsNothing);

    await tester.tap(find.text('Next'));

    await observer.pumpPastTransition(tester);

    expect(find.text('Page 1'), findsNothing);
    expect(find.text('Page 2'), findsOneWidget);
    expect(find.text('Page 3'), findsNothing);

    await tester.tap(find.text('Next'));

    await observer.pumpPastTransition(tester);

    expect(find.text('Page 1'), findsNothing);
    expect(find.text('Page 2'), findsNothing);
    expect(find.text('Page 3'), findsOneWidget);

    await tester.tap(find.text('Back'));

    await observer.pumpPastTransition(tester);

    expect(find.text('Page 1'), findsNothing);
    expect(find.text('Page 2'), findsOneWidget);
    expect(find.text('Page 3'), findsNothing);

    await tester.tap(find.text('Back'));

    await observer.pumpPastTransition(tester);

    expect(find.text('Page 1'), findsOneWidget);
    expect(find.text('Page 2'), findsNothing);
    expect(find.text('Page 3'), findsNothing);
  });

  testWidgets('PageTransitionsBuilder buildTransitions method is called correctly', (
    WidgetTester tester,
  ) async {
    var buildTransitionsCalled = false;
    PageRoute<dynamic>? capturedRoute;
    BuildContext? capturedContext;
    Animation<double>? capturedAnimation;
    Animation<double>? capturedSecondaryAnimation;
    Widget? capturedChild;

    final builderWithCapture = _TestPageTransitionsBuilder(
      onBuildTransitions:
          <T>(
            PageRoute<T> route,
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            buildTransitionsCalled = true;
            capturedRoute = route;
            capturedContext = context;
            capturedAnimation = animation;
            capturedSecondaryAnimation = secondaryAnimation;
            capturedChild = child;

            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
    );

    final routes = <String, WidgetBuilder>{
      '/': (BuildContext context) => Material(
        child: TextButton(
          child: const Text('push'),
          onPressed: () {
            Navigator.of(context).pushNamed('/test');
          },
        ),
      ),
      '/test': (BuildContext context) => const Material(child: Text('test page')),
    };

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          pageTransitionsTheme: PageTransitionsTheme(
            builders: <TargetPlatform, PageTransitionsBuilder>{
              TargetPlatform.android: builderWithCapture,
            },
          ),
        ),
        routes: routes,
      ),
    );

    // Trigger navigation
    await tester.tap(find.text('push'));
    await tester.pump();

    // Verify buildTransitions was called with correct parameters
    expect(buildTransitionsCalled, isTrue);
    expect(capturedRoute, isNotNull);
    expect(capturedContext, isNotNull);
    expect(capturedAnimation, isNotNull);
    expect(capturedSecondaryAnimation, isNotNull);
    expect(capturedChild, isNotNull);
    expect(capturedRoute!.settings.name, '/');
  });

  testWidgets('PageTransitionsBuilder works with custom Navigator and PageRoute', (
    WidgetTester tester,
  ) async {
    final customTransitionsBuilder = _TestPageTransitionsBuilder(
      onBuildTransitions:
          <T>(
            PageRoute<T> route,
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: animation.drive(
                  Tween<double>(begin: 0.5, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)),
                ),
                child: child,
              ),
            );
          },
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Navigator(
          onGenerateRoute: (RouteSettings settings) {
            return _CustomPageRoute<void>(
              settings: settings,
              transitionsBuilder: customTransitionsBuilder,
              builder: (BuildContext context) {
                if (settings.name == '/') {
                  return Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushNamed('/second');
                      },
                      child: Container(
                        width: 200,
                        height: 50,
                        color: const Color(0xFF2196F3),
                        child: const Center(
                          child: Text('Navigate', style: TextStyle(color: Color(0xFFFFFFFF))),
                        ),
                      ),
                    ),
                  );
                }
                return const ColoredBox(
                  color: Color(0xFF4CAF50),
                  child: Center(
                    child: Text(
                      'Second Page',
                      style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 24),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );

    expect(find.text('Navigate'), findsOneWidget);
    expect(find.text('Second Page'), findsNothing);

    await tester.tap(find.text('Navigate'));
    await tester.pump();

    expect(find.text('Navigate'), findsOneWidget);
    expect(find.text('Second Page'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 50));

    final FadeTransition fadeTransition = tester.widget<FadeTransition>(
      find.byType(FadeTransition).first,
    );
    expect(fadeTransition.opacity.value, greaterThan(0.0));
    expect(fadeTransition.opacity.value, lessThanOrEqualTo(1.0));

    final ScaleTransition scaleTransition = tester.widget<ScaleTransition>(
      find.byType(ScaleTransition).first,
    );
    expect(scaleTransition.scale.value, greaterThanOrEqualTo(0.5));
    expect(scaleTransition.scale.value, lessThanOrEqualTo(1.0));

    await tester.pumpAndSettle();

    expect(find.text('Navigate'), findsNothing);
    expect(find.text('Second Page'), findsOneWidget);
  });

  testWidgets('FadeUpwardsPageTransitionsBuilder test', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Navigator(
          onGenerateRoute: (RouteSettings settings) {
            return _CustomPageRoute<void>(
              settings: settings,
              transitionsBuilder: const FadeUpwardsPageTransitionsBuilder(),
              builder: (BuildContext context) {
                if (settings.name == '/') {
                  return ColoredBox(
                    color: const Color(0xFF2196F3),
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushNamed('/second');
                        },
                        child: const Text(
                          'Page 1',
                          style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 24),
                        ),
                      ),
                    ),
                  );
                }
                return const ColoredBox(
                  color: Color(0xFF4CAF50),
                  child: Center(
                    child: Text('Page 2', style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 24)),
                  ),
                );
              },
            );
          },
        ),
      ),
    );

    final Offset widget1TopLeft = tester.getTopLeft(find.text('Page 1'));

    await tester.tap(find.text('Page 1'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));

    FadeTransition widget2Opacity = tester
        .element(find.text('Page 2'))
        .findAncestorWidgetOfExactType<FadeTransition>()!;
    Offset widget2TopLeft = tester.getTopLeft(find.text('Page 2'));

    expect(widget1TopLeft.dx == widget2TopLeft.dx, true);
    expect(widget1TopLeft.dy < widget2TopLeft.dy, true);
    expect(widget2Opacity.opacity.value < 0.01, true);

    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Page 1'), findsNothing);
    expect(find.text('Page 2'), isOnstage);

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));

    widget2Opacity = tester
        .element(find.text('Page 2'))
        .findAncestorWidgetOfExactType<FadeTransition>()!;
    widget2TopLeft = tester.getTopLeft(find.text('Page 2'));

    expect(widget1TopLeft.dy < widget2TopLeft.dy, true);
    expect(widget2Opacity.opacity.value < 1.0, true);

    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Page 1'), isOnstage);
    expect(find.text('Page 2'), findsNothing);
  });

  testWidgets(
    'FadeUpwardsPageTransitionsBuilder test with Material PageTransitionTheme',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const Material(child: Text('Page 1')),
          theme: ThemeData(
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: <TargetPlatform, PageTransitionsBuilder>{
                TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
              },
            ),
          ),
          routes: <String, WidgetBuilder>{
            '/next': (BuildContext context) {
              return const Material(child: Text('Page 2'));
            },
          },
        ),
      );

      final Offset widget1TopLeft = tester.getTopLeft(find.text('Page 1'));

      tester.state<NavigatorState>(find.byType(Navigator)).pushNamed('/next');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));

      FadeTransition widget2Opacity = tester
          .element(find.text('Page 2'))
          .findAncestorWidgetOfExactType<FadeTransition>()!;
      Offset widget2TopLeft = tester.getTopLeft(find.text('Page 2'));
      final Size widget2Size = tester.getSize(find.text('Page 2'));

      // Android transition is vertical only.
      expect(widget1TopLeft.dx == widget2TopLeft.dx, true);
      // Page 1 is above page 2 mid-transition.
      expect(widget1TopLeft.dy < widget2TopLeft.dy, true);
      // Animation begins 3/4 of the way up the page.
      expect(widget2TopLeft.dy < widget2Size.height / 4.0, true);
      // Animation starts with page 2 being near transparent.
      expect(widget2Opacity.opacity.value < 0.01, true);

      await tester.pump(const Duration(milliseconds: 300));

      // Page 2 covers page 1.
      expect(find.text('Page 1'), findsNothing);
      expect(find.text('Page 2'), isOnstage);

      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));

      widget2Opacity = tester
          .element(find.text('Page 2'))
          .findAncestorWidgetOfExactType<FadeTransition>()!;
      widget2TopLeft = tester.getTopLeft(find.text('Page 2'));

      // Page 2 starts to move down.
      expect(widget1TopLeft.dy < widget2TopLeft.dy, true);
      // Page 2 starts to lose opacity.
      expect(widget2Opacity.opacity.value < 1.0, true);

      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Page 1'), isOnstage);
      expect(find.text('Page 2'), findsNothing);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'PageTransitionsTheme override builds a _OpenUpwardsPageTransition',
    (WidgetTester tester) async {
      final routes = <String, WidgetBuilder>{
        '/': (BuildContext context) => Material(
          child: TextButton(
            child: const Text('push'),
            onPressed: () {
              Navigator.of(context).pushNamed('/b');
            },
          ),
        ),
        '/b': (BuildContext context) => const Text('page b'),
      };

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: <TargetPlatform, PageTransitionsBuilder>{
                TargetPlatform.android:
                    OpenUpwardsPageTransitionsBuilder(), // creates a _OpenUpwardsPageTransition
              },
            ),
          ),
          routes: routes,
        ),
      );

      Finder findOpenUpwardsPageTransition() {
        return find.descendant(
          of: find.byType(MaterialApp),
          matching: find.byWidgetPredicate(
            (Widget w) => '${w.runtimeType}' == '_OpenUpwardsPageTransition',
          ),
        );
      }

      expect(
        Theme.of(tester.element(find.text('push'))).platform,
        debugDefaultTargetPlatformOverride,
      );
      expect(findOpenUpwardsPageTransition(), findsOneWidget);

      await tester.tap(find.text('push'));
      await tester.pumpAndSettle();
      expect(find.text('page b'), findsOneWidget);
      expect(findOpenUpwardsPageTransition(), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets('OpenUpwardsPageTransitionsBuilder test', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Navigator(
          onGenerateRoute: (RouteSettings settings) {
            return _CustomPageRoute<void>(
              settings: settings,
              transitionsBuilder: const OpenUpwardsPageTransitionsBuilder(),
              builder: (BuildContext context) {
                if (settings.name == '/') {
                  return ColoredBox(
                    color: const Color(0xFF2196F3),
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushNamed('/second');
                        },
                        child: const Text(
                          'Page 1',
                          style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 24),
                        ),
                      ),
                    ),
                  );
                }
                return const ColoredBox(
                  color: Color(0xFF4CAF50),
                  child: Center(
                    child: Text('Page 2', style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 24)),
                  ),
                );
              },
            );
          },
        ),
      ),
    );

    final Offset widget1TopLeft = tester.getTopLeft(find.text('Page 1'));

    await tester.tap(find.text('Page 1'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));

    expect(find.text('Page 1'), findsOneWidget);
    expect(find.text('Page 2'), findsOneWidget);

    final Offset widget2TopLeft = tester.getTopLeft(find.text('Page 2'));

    expect(widget1TopLeft.dx, widget2TopLeft.dx);
    expect(widget1TopLeft.dy <= widget2TopLeft.dy, true);

    await tester.pump(const Duration(milliseconds: 300));

    // After animation, only Page 2 should be visible.
    expect(find.text('Page 1'), findsNothing);
    expect(find.text('Page 2'), isOnstage);

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));

    expect(find.text('Page 1'), findsOneWidget);
    expect(find.text('Page 2'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 300));

    // After reverse animation, only Page 1 should be visible.
    expect(find.text('Page 1'), isOnstage);
    expect(find.text('Page 2'), findsNothing);
  });

  testWidgets(
    'OpenUpwardsPageTransitionsBuilder test with Material PageTransitionTheme',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const Material(child: Text('Page 1')),
          theme: ThemeData(
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: <TargetPlatform, PageTransitionsBuilder>{
                TargetPlatform.android: OpenUpwardsPageTransitionsBuilder(),
              },
            ),
          ),
          routes: <String, WidgetBuilder>{
            '/next': (BuildContext context) {
              return const Material(child: Text('Page 2'));
            },
          },
        ),
      );

      final Offset widget1TopLeft = tester.getTopLeft(find.text('Page 1'));

      tester.state<NavigatorState>(find.byType(Navigator)).pushNamed('/next');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));

      expect(find.text('Page 1'), findsOneWidget);
      expect(find.text('Page 2'), findsOneWidget);

      final Offset widget2TopLeft = tester.getTopLeft(find.text('Page 2'));

      expect(widget1TopLeft.dx, widget2TopLeft.dx);
      expect(widget1TopLeft.dy < widget2TopLeft.dy, true);

      await tester.pump(const Duration(milliseconds: 300));

      // Page 2 covers page 1.
      expect(find.text('Page 1'), findsNothing);
      expect(find.text('Page 2'), isOnstage);

      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));

      expect(find.text('Page 1'), findsOneWidget);
      expect(find.text('Page 2'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 300));

      // Back to page 1.
      expect(find.text('Page 1'), isOnstage);
      expect(find.text('Page 2'), findsNothing);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );
}

class TestOverlayRoute extends OverlayRoute<void> {
  TestOverlayRoute({super.settings});
  @override
  Iterable<OverlayEntry> createOverlayEntries() => [OverlayEntry(builder: _build)];

  Widget _build(BuildContext context) => const Text('Overlay');
}

class _TestTransitionRoute<T> extends MaterialPageRoute<T> {
  _TestTransitionRoute({
    required super.builder,
    required this.pageTransitionsBuilder,
    this.transitionDurationOverride,
    this.reverseTransitionDurationOverride,
  });

  final PageTransitionsBuilder pageTransitionsBuilder;
  final Duration? transitionDurationOverride;
  final Duration? reverseTransitionDurationOverride;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return pageTransitionsBuilder.buildTransitions(
      this,
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }

  @override
  Duration get transitionDuration =>
      transitionDurationOverride ?? pageTransitionsBuilder.transitionDuration;
  @override
  Duration get reverseTransitionDuration =>
      reverseTransitionDurationOverride ?? pageTransitionsBuilder.reverseTransitionDuration;
}

class _CustomPageRoute<T> extends PageRoute<T> {
  _CustomPageRoute({required this.builder, required this.transitionsBuilder, super.settings});

  final WidgetBuilder builder;
  final PageTransitionsBuilder transitionsBuilder;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  bool get maintainState => true;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return transitionsBuilder.buildTransitions<T>(
      this,
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}

class _TestPageTransitionsBuilder extends PageTransitionsBuilder {
  const _TestPageTransitionsBuilder({required this.onBuildTransitions});

  final Widget Function<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  )
  onBuildTransitions;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return onBuildTransitions(route, context, animation, secondaryAnimation, child);
  }
}
