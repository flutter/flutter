// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';
import 'dart:ui'
    show
        DisplayFeature,
        DisplayFeatureState,
        DisplayFeatureType,
        PointerDeviceKind,
        SemanticsFlag;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../widgets/semantics_tester.dart';


Future<void> openNestedMenu(WidgetTester tester, List<Key> keys) async {
  for (final Key key in keys) {
    await tester.tap(find.byKey(key));
    await tester.pumpAndSettle();
  }
}

void main() {
  CupertinoApp buildSample<T>(
    WidgetTester tester, {
    Key? key,
    RelativeRect Function(BuildContext)? getPosition,
    required List<CupertinoMenuEntry<T>> Function(BuildContext) itemBuilder,
    bool enabled = true,
    void Function()? onCancel,
    void Function()? onOpen,
    void Function()? onClose,
    void Function(T)? onSelect,
    BoxConstraints? constraints,
    Offset? offset,
    Widget? child,
    bool enableFeedback = true,
    ScrollPhysics? physics,
    CupertinoMenuController? controller,
    bool useRootNavigator = false,
    double? minSize,
    EdgeInsetsGeometry? buttonPadding,
    Clip clip = Clip.antiAlias,
  }) {
    return CupertinoApp(
      home: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Builder(
            builder: (BuildContext context) {
              return Positioned.fromRelativeRect(
                rect: getPosition?.call(context) ?? RelativeRect.fill,
                child: CupertinoMenuButton<T>(
                  key: key,
                  itemBuilder: itemBuilder,
                  enabled: enabled,
                  onOpen: onOpen,
                  onClose: onClose,
                  onSelect: onSelect,
                  onCancel: onCancel,
                  constraints: constraints,
                  offset: offset,
                  enableFeedback: enableFeedback,
                  physics: physics,
                  controller: controller,
                  useRootNavigator: useRootNavigator,
                  minSize: minSize,
                  buttonPadding: buttonPadding,
                  clip: clip,
                  child: child,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Migrated
  testWidgets(
      'Navigator.push is successfully called within a CupertinoMenuButton',
      (WidgetTester tester) async {
    final Key targetKey = UniqueKey();
    final Key nestedKey = UniqueKey();
    BuildContext? popupContext;
    await tester.pumpWidget(
      CupertinoApp(
        routes: <String, WidgetBuilder>{
          '/next': (BuildContext context) {
            return const Text('Next');
          },
        },
        home: Center(
          child: Builder(
            key: targetKey,
            builder: (BuildContext context) {
              return CupertinoMenuButton<int>(
                onSelect: (int? value) {
                  Navigator.pushNamed(context, '/next');
                },
                itemBuilder: (BuildContext context) {
                  popupContext = context;
                  return <CupertinoMenuEntry<int>>[
                    const CupertinoMenuItem<int>(
                      value: 1,
                      child: Text('One'),
                    ),
                    CupertinoNestedMenu<int>(
                      key: nestedKey,
                      itemBuilder: (BuildContext context) {
                        return <CupertinoMenuEntry<int>>[
                          const CupertinoMenuItem<int>(
                            value: 2,
                            child: Text('Two'),
                          ),
                        ];
                      },
                      title: const TextSpan(
                        text: 'Nested Child',
                      ),
                    ),
                  ];
                },
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(targetKey));
    await tester.pumpAndSettle(); // finish the menu animation

    expect(find.text('One'), findsOneWidget);
    expect(find.text('Next'), findsNothing);

    await tester.tap(find.text('One'));
    await tester.pumpAndSettle(); // Wait for navigation to finish

    expect(find.text('One'), findsNothing);
    expect(find.text('Next'), findsOneWidget);

    Navigator.of(popupContext!).pop();
    await tester.pumpAndSettle(); // Return to previous screen
    await tester.tap(find.byKey(targetKey));
    await tester.pumpAndSettle(); // finish the root menu animation
    await tester.tap(find.byKey(nestedKey));
    await tester.pumpAndSettle(); // finish the nested menu animation

    expect(find.text('Two'), findsOneWidget);
    expect(find.text('Next'), findsNothing);

    await tester.tap(find.text('Two'));
    await tester.pumpAndSettle(); // Wait for navigation to finish

    expect(find.text('Two'), findsNothing);
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets(
      'CupertinoMenuButton calls onOpened callback when the menu is opened',
      (WidgetTester tester) async {
    int opens = 0;
    late BuildContext popupContext;
    final Key noItemsKey = UniqueKey();
    final Key noNestedItemsRootKey = UniqueKey();
    final Key noNestedItemsNestedKey = UniqueKey();

    final Key noCallbackRootKey = UniqueKey();
    final Key noCallbackNestedKey = UniqueKey();

    final Key withCallbackRootKey = UniqueKey();
    final Key withCallbackNestedKey = UniqueKey();

    await tester.pumpWidget(
      CupertinoApp(
        home: Column(
          children: <Widget>[
            CupertinoMenuButton<int>(
              key: noItemsKey,
              onOpen: () => opens++,
              itemBuilder: (BuildContext context) {
                return <CupertinoMenuEntry<int>>[];
              },
            ),
            CupertinoMenuButton<int>(
              key: noNestedItemsRootKey,
              onOpen: () => opens++,
              itemBuilder: (BuildContext context) {
                popupContext = context;
                return <CupertinoMenuEntry<int>>[
                  CupertinoNestedMenu<int>(
                    key: noNestedItemsNestedKey,
                    itemBuilder: (BuildContext context) {
                      return <CupertinoMenuEntry<int>>[];
                    },
                    title: const TextSpan(text: 'child'),
                  ),
                ];
              },
            ),
            CupertinoMenuButton<int>(
              key: noCallbackRootKey,
              itemBuilder: (BuildContext context) {
                return <CupertinoMenuEntry<int>>[
                  CupertinoNestedMenu<int>(
                    key: noCallbackNestedKey,
                    itemBuilder: (BuildContext context) {
                      popupContext = context;
                      return <CupertinoMenuEntry<int>>[
                        const CupertinoMenuItem<int>(
                          value: 1,
                          child: Text('Tap me please!'),
                        ),
                      ];
                    },
                    title: const TextSpan(text: 'child'),
                  ),
                ];
              },
            ),
            CupertinoMenuButton<int>(
              key: withCallbackRootKey,
              itemBuilder: (BuildContext context) {
                return <CupertinoMenuEntry<int>>[
                  CupertinoNestedMenu<int>(
                    key: withCallbackNestedKey,
                    itemBuilder: (BuildContext context) {
                      popupContext = context;
                      return <CupertinoMenuEntry<int>>[
                        const CupertinoMenuItem<int>(
                          value: 1,
                          child: Text('Tap me please!'),
                        ),
                      ];
                    },
                    title: const TextSpan(text: 'child'),
                    onOpen: () => opens++,
                  ),
                ];
              },
              onOpen: () => opens++,
            ),
          ],
        ),
      ),
    );

    // Make sure callback is not called when the menu has no items
    await tester.tap(find.byKey(noItemsKey));
    await tester.pump();
    expect(opens, equals(0));

    // Make sure callback is not called when a nested menu has no items
    await openNestedMenu(
      tester,
      <Key>[noNestedItemsRootKey, noNestedItemsNestedKey],
    );
    expect(opens, equals(1));
    opens = 0;

    // Close the opened menu
    Navigator.of(popupContext).pop();
    await tester.pumpAndSettle();

    // Make sure everything works if no callback is provided
    await openNestedMenu(tester, <Key>[noCallbackRootKey, noCallbackNestedKey]);
    expect(opens, equals(0));

    Navigator.of(popupContext).pop();
    await tester.pumpAndSettle();

    // Make sure callback is called when the button is tapped
    await openNestedMenu(
      tester,
      <Key>[withCallbackRootKey, withCallbackNestedKey],
    );
    expect(opens, equals(3));

    Navigator.of(popupContext).pop();
    await tester.pumpAndSettle();
  });

  testWidgets(
      'CupertinoMenuButton calls onCanceled callback when an item is not selected',
      (WidgetTester tester) async {
    int cancels = 0;
    late BuildContext popupContext;
    final Key noCallbackKey = UniqueKey();
    final Key withCallbackKey = UniqueKey();

    await tester.pumpWidget(
      CupertinoApp(
        home: Column(
          children: <Widget>[
            CupertinoMenuButton<int>(
              key: noCallbackKey,
              itemBuilder: (BuildContext context) {
                return <CupertinoInteractiveMenuItem<int>>[
                  const CupertinoMenuItem<int>(
                    value: 1,
                    child: Text('Tap me please!'),
                  ),
                ];
              },
            ),
            CupertinoMenuButton<int>(
              key: withCallbackKey,
              onCancel: () => cancels++,
              itemBuilder: (BuildContext context) {
                popupContext = context;
                return <CupertinoInteractiveMenuItem<int>>[
                  const CupertinoMenuItem<int>(
                    value: 1,
                    child: Text('Tap me, too!'),
                  ),
                ];
              },
            ),
          ],
        ),
      ),
    );

    // Make sure everything works if no callback is provided
    await tester.tap(find.byKey(noCallbackKey));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tapAt(Offset.zero);
    await tester.pump();
    expect(cancels, equals(0));

    // Make sure callback is called when a non-selection tap occurs
    await tester.tap(find.byKey(withCallbackKey));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tapAt(Offset.zero);
    await tester.pump();
    expect(cancels, equals(1));

    // Make sure callback is called when back navigation occurs
    await tester.tap(find.byKey(withCallbackKey));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    Navigator.of(popupContext).pop();
    await tester.pump();
    expect(cancels, equals(2));
  });

  testWidgets(
      'disabled CupertinoMenuButton will not call itemBuilder, onOpened, onSelected or onCanceled',
      (WidgetTester tester) async {
    final GlobalKey popupButtonKey = GlobalKey();
    bool itemBuilderCalled = false;
    bool onOpenedCalled = false;
    bool onSelectedCalled = false;
    bool onCanceledCalled = false;

    Widget buildApp({bool directional = false}) {
      return CupertinoApp(
        home: Builder(
          builder: (BuildContext context) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                navigationMode: NavigationMode.directional,
              ),
              child: Column(
                children: <Widget>[
                  CupertinoMenuButton<int>(
                    key: popupButtonKey,
                    enabled: false,
                    child: const Text('Tap Me'),
                    itemBuilder: (BuildContext context) {
                      itemBuilderCalled = true;
                      return <CupertinoMenuEntry<int>>[
                        const CupertinoMenuItem<int>(
                          value: 1,
                          child: Text('Tap me please!'),
                        ),
                      ];
                    },
                    onOpen: () => onOpenedCalled = true,
                    onSelect: (int selected) => onSelectedCalled = true,
                    onCancel: () => onCanceledCalled = true,
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    await tester.pumpWidget(buildApp());

    // Try to bring up the popup menu and select the first item from it
    await tester.tap(find.byKey(popupButtonKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(popupButtonKey));
    await tester.pumpAndSettle();
    expect(itemBuilderCalled, isFalse);
    expect(onOpenedCalled, isFalse);
    expect(onSelectedCalled, isFalse);

    // Try to bring up the popup menu and tap outside it to cancel the menu
    await tester.tap(find.byKey(popupButtonKey));
    await tester.pumpAndSettle();
    await tester.tapAt(Offset.zero);
    await tester.pumpAndSettle();
    expect(itemBuilderCalled, isFalse);
    expect(onOpenedCalled, isFalse);
    expect(onCanceledCalled, isFalse);

    // Test again, with directional navigation mode and after focusing the button.
    await tester.pumpWidget(buildApp(directional: true));

    // Try to bring up the popup menu and select the first item from it
    // Focus.of(popupButtonKey.currentContext!).requestFocus();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(popupButtonKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(popupButtonKey));
    await tester.pumpAndSettle();
    expect(itemBuilderCalled, isFalse);
    expect(onOpenedCalled, isFalse);
    expect(onSelectedCalled, isFalse);

    // Try to bring up the popup menu and tap outside it to cancel the menu
    await tester.tap(find.byKey(popupButtonKey));
    await tester.pumpAndSettle();
    await tester.tapAt(Offset.zero);
    await tester.pumpAndSettle();
    expect(itemBuilderCalled, isFalse);
    expect(onOpenedCalled, isFalse);
    expect(onCanceledCalled, isFalse);
  });

  testWidgets('disabled CupertinoMenuButton is not focusable',
      (WidgetTester tester) async {
    final Key popupButtonKey = UniqueKey();
    final GlobalKey childKey = GlobalKey();
    bool itemBuilderCalled = false;
    bool onOpenedCalled = false;
    bool onSelectedCalled = false;

    await tester.pumpWidget(
      CupertinoApp(
        home: Column(
          children: <Widget>[
            CupertinoMenuButton<int>(
              key: popupButtonKey,
              enabled: false,
              child: Container(key: childKey),
              itemBuilder: (BuildContext context) {
                itemBuilderCalled = true;
                return <CupertinoMenuEntry<int>>[
                  const CupertinoMenuItem<int>(
                    value: 1,
                    child: Text('Tap me please!'),
                  ),
                ];
              },
              onOpen: () => onOpenedCalled = true,
              onSelect: (int selected) => onSelectedCalled = true,
            ),
          ],
        ),
      ),
    );
    Focus.of(childKey.currentContext!).requestFocus();
    await tester.pump();

    expect(Focus.of(childKey.currentContext!).hasPrimaryFocus, isFalse);
    expect(itemBuilderCalled, isFalse);
    expect(onOpenedCalled, isFalse);
    expect(onSelectedCalled, isFalse);
  });

  testWidgets(
      'disabled CupertinoMenuButton is focusable with directional navigation',
      (WidgetTester tester) async {
    final Key popupButtonKey = UniqueKey();
    final GlobalKey childKey = GlobalKey();

    await tester.pumpWidget(
      CupertinoApp(
        home: Builder(
          builder: (BuildContext context) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                navigationMode: NavigationMode.directional,
              ),
              child: Column(
                children: <Widget>[
                  CupertinoMenuButton<int>(
                    key: popupButtonKey,
                    enabled: false,
                    child: Container(key: childKey),
                    itemBuilder: (BuildContext context) {
                      return <CupertinoMenuEntry<int>>[
                        const CupertinoMenuItem<int>(
                          value: 1,
                          child: Text('Tap me please!'),
                        ),
                      ];
                    },
                    onSelect: (int selected) {},
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
    Focus.of(childKey.currentContext!).requestFocus();
    await tester.pump();

    expect(Focus.of(childKey.currentContext!).hasPrimaryFocus, isTrue);
  });

  testWidgets('CupertinoMenuButton onTap callback is called when defined',
      (WidgetTester tester) async {
    final List<int> menuItemTapCounters = <int>[0, 0];

    await tester.pumpWidget(
      TestApp(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(
          child: CupertinoMenuButton<void>(
            child: const Text('Actions'),
            itemBuilder: (BuildContext context) => <CupertinoMenuItem<void>>[
              CupertinoMenuItem<void>(
                child: const Text('First option'),
                onTap: () {
                  menuItemTapCounters[0] += 1;
                },
              ),
              CupertinoMenuItem<void>(
                child: const Text('Second option'),
                onTap: () {
                  menuItemTapCounters[1] += 1;
                },
              ),
              const CupertinoMenuItem<void>(
                child: Text('Option without onTap'),
              ),
            ],
          ),
        ),
      ),
    );

    // Tap the first time
    await tester.tap(find.text('Actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('First option'));
    await tester.pumpAndSettle();
    expect(menuItemTapCounters, <int>[1, 0]);

    // Tap the item again
    await tester.tap(find.text('Actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('First option'));
    await tester.pumpAndSettle();
    expect(menuItemTapCounters, <int>[2, 0]);

    // Tap a different item
    await tester.tap(find.text('Actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Second option'));
    await tester.pumpAndSettle();
    expect(menuItemTapCounters, <int>[2, 1]);

    // Tap an item without onTap
    await tester.tap(find.text('Actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Option without onTap'));
    await tester.pumpAndSettle();
    expect(menuItemTapCounters, <int>[2, 1]);
  });

  testWidgets('CupertinoMenuButton can have both onTap and value',
      (WidgetTester tester) async {
    final List<int> menuItemTapCounters = <int>[0, 0];
    String? selected;

    await tester.pumpWidget(
      TestApp(
        textDirection: TextDirection.ltr,
        child: Material(
          child: RepaintBoundary(
            child: CupertinoMenuButton<String>(
              child: const Text('Actions'),
              onSelect: (String value) {
                selected = value;
              },
              itemBuilder: (BuildContext context) =>
                  <CupertinoMenuItem<String>>[
                CupertinoMenuItem<String>(
                  value: 'first',
                  child: const Text('First option'),
                  onTap: () {
                    menuItemTapCounters[0] += 1;
                  },
                ),
                CupertinoMenuItem<String>(
                  value: 'second',
                  child: const Text('Second option'),
                  onTap: () {
                    menuItemTapCounters[1] += 1;
                  },
                ),
                const CupertinoMenuItem<String>(
                  value: 'third',
                  child: Text('Option without onTap'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Tap the first item
    await tester.tap(find.text('Actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('First option'));
    await tester.pumpAndSettle();
    expect(menuItemTapCounters, <int>[1, 0]);
    expect(selected, 'first');

    // Tap the item again
    await tester.tap(find.text('Actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('First option'));
    await tester.pumpAndSettle();
    expect(menuItemTapCounters, <int>[2, 0]);
    expect(selected, 'first');

    // Tap a different item
    await tester.tap(find.text('Actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Second option'));
    await tester.pumpAndSettle();
    expect(menuItemTapCounters, <int>[2, 1]);
    expect(selected, 'second');

    // Tap an item without onTap
    await tester.tap(find.text('Actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Option without onTap'));
    await tester.pumpAndSettle();
    expect(menuItemTapCounters, <int>[2, 1]);
    expect(selected, 'third');
  });

// I had to add a Focus() widget to the _MenuBody widget to make this test pass.
  testWidgets('CupertinoMenuItem is only focusable when enabled',
      (WidgetTester tester) async {
    final Key popupButtonKey = UniqueKey();
    final GlobalKey childKey = GlobalKey();
    bool itemBuilderCalled = false;

    await tester.pumpWidget(
      CupertinoApp(
        home: Column(
          children: <Widget>[
            CupertinoMenuButton<int>(
              key: popupButtonKey,
              itemBuilder: (BuildContext context) {
                itemBuilderCalled = true;
                return <CupertinoMenuEntry<int>>[
                  CupertinoMenuItem<int>(
                    value: 1,
                    child: Text('Tap me please!', key: childKey),
                  ),
                ];
              },
            ),
          ],
        ),
      ),
    );

    // Open the popup to build and show the menu contents.
    await tester.tap(find.byKey(popupButtonKey));
    await tester.pumpAndSettle();
    final FocusNode childNode = Focus.of(childKey.currentContext!);
    // Now that the contents are shown, request focus on the child text.
    childNode.requestFocus();
    await tester.pumpAndSettle();
    expect(itemBuilderCalled, isTrue);

    // Make sure that the focus went where we expected it to.
    expect(childNode.hasPrimaryFocus, isTrue);
    itemBuilderCalled = false;

    // Close the popup.
    await tester.tap(find.byKey(popupButtonKey), warnIfMissed: false);
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      CupertinoApp(
        home: Material(
          child: Column(
            children: <Widget>[
              CupertinoMenuButton<int>(
                key: popupButtonKey,
                itemBuilder: (BuildContext context) {
                  itemBuilderCalled = true;
                  return <CupertinoMenuEntry<int>>[
                    CupertinoMenuItem<int>(
                      enabled: false,
                      value: 1,
                      child: Text('Tap me please!', key: childKey),
                    ),
                  ];
                },
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Open the popup again to rebuild the contents with enabled == false.
    await tester.tap(find.byKey(popupButtonKey));
    await tester.pumpAndSettle();

    expect(itemBuilderCalled, isTrue);
    expect(Focus.of(childKey.currentContext!).hasPrimaryFocus, isFalse);
  });

/* Excluded
  testWidgets('PopupMenuButton is horizontal on iOS',
      (WidgetTester tester) async {
    Widget build(TargetPlatform platform) {
      debugDefaultTargetPlatformOverride = platform;
      return MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            actions: <Widget>[
              PopupMenuButton<int>(
                itemBuilder: (BuildContext context) {
                  return <PopupMenuItem<int>>[
                    const PopupMenuItem<int>(
                      value: 1,
                      child: Text('One'),
                    ),
                  ];
                },
              ),
            ],
          ),
        ),
      );
    }

    await tester.pumpWidget(build(TargetPlatform.android));

    expect(find.byIcon(Icons.more_vert), findsOneWidget);
    expect(find.byIcon(Icons.more_horiz), findsNothing);

    await tester.pumpWidget(build(TargetPlatform.iOS));
    await tester.pumpAndSettle(); // Run theme change animation.

    expect(find.byIcon(Icons.more_vert), findsNothing);
    expect(find.byIcon(Icons.more_horiz), findsOneWidget);

    await tester.pumpWidget(build(TargetPlatform.macOS));
    await tester.pumpAndSettle(); // Run theme change animation.

    expect(find.byIcon(Icons.more_vert), findsNothing);
    expect(find.byIcon(Icons.more_horiz), findsOneWidget);

    debugDefaultTargetPlatformOverride = null;
  });
*/

/* Excluded
   I'm not sure whether this design decision should be used with the Cupertino menu.
   I will defer to the Flutter team on this one.
  group('CupertinoMenuButton with Icon', () {
    // Helper function to create simple and valid popup menus.
    List<PopupMenuItem<int>> simplePopupMenuItemBuilder(BuildContext context) {
      return <PopupMenuItem<int>>[
        const PopupMenuItem<int>(
          value: 1,
          child: Text('1'),
        ),
      ];
    }


    testWidgets('PopupMenuButton fails when given both child and icon',
        (WidgetTester tester) async {
      expect(
        () {
          PopupMenuButton<int>(
            icon: const Icon(Icons.view_carousel),
            itemBuilder: simplePopupMenuItemBuilder,67
            child: const Text('heyo'),
          );
        },
        throwsAssertionError,
      );
    });
    testWidgets('PopupMenuButton creates IconButton when given an icon',
        (WidgetTester tester) async {
      final PopupMenuButton<int> button = PopupMenuButton<int>(
        icon: const Icon(Icons.view_carousel),
        itemBuilder: simplePopupMenuItemBuilder,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              actions: <Widget>[button],
            ),
          ),
        ),
      );

      expect(find.byType(IconButton), findsOneWidget);
      expect(find.byIcon(Icons.view_carousel), findsOneWidget);
    });
  });
*/

  testWidgets('PopupMenu positioning', (WidgetTester tester) async {
    final Widget testButton = CupertinoMenuButton<int>(
      itemBuilder: (BuildContext context) {
        return <CupertinoMenuEntry<int>>[
          const CupertinoMenuItem<int>(value: 1, child: Text('AAA')),
          const CupertinoMenuItem<int>(value: 2, child: Text('BBB')),
          const CupertinoMenuItem<int>(value: 3, child: Text('CCC')),
        ];
      },
      child: const SizedBox(
        height: 100.0,
        width: 100.0,
        child: Text('XXX'),
      ),
    );
    bool popupMenu(Widget widget) {
      final String widgetType = widget.runtimeType.toString();
      // TODO(mraleph): Remove the old case below.
      return widgetType == '_PopupMenu<int?>' // normal case
          ||
          widgetType ==
              '_PopupMenu'; // for old versions of Dart that don't reify method type arguments
    }

    Future<void> openMenu(
      TextDirection textDirection,
      Alignment alignment,
    ) async {
      return TestAsyncUtils.guard<void>(() async {
        await tester
            .pumpWidget(Container()); // reset in case we had a menu up already
        await tester.pumpWidget(
          TestApp(
            textDirection: textDirection,
            child: Align(
              alignment: alignment,
              child: testButton,
            ),
          ),
        );
        await tester.tap(find.text('XXX'));
        await tester.pump();
      });
    }

    Future<void> testPositioningDown(
      WidgetTester tester,
      TextDirection textDirection,
      Alignment alignment,
      TextDirection growthDirection,
      Rect startRect,
    ) {
      return TestAsyncUtils.guard<void>(() async {
        await openMenu(textDirection, alignment);
        Rect rect = tester.getRect(find.byWidgetPredicate(popupMenu));
        expect(rect, startRect);
        bool doneVertically = false;
        bool doneHorizontally = false;
        do {
          await tester.pump(const Duration(milliseconds: 20));
          final Rect newRect =
              tester.getRect(find.byWidgetPredicate(popupMenu));
          expect(newRect.top, rect.top);
          if (doneVertically) {
            expect(newRect.bottom, rect.bottom);
          } else {
            if (newRect.bottom == rect.bottom) {
              doneVertically = true;
            } else {
              expect(newRect.bottom, greaterThan(rect.bottom));
            }
          }
          switch (growthDirection) {
            case TextDirection.rtl:
              expect(newRect.right, rect.right);
              if (doneHorizontally) {
                expect(newRect.left, rect.left);
              } else {
                if (newRect.left == rect.left) {
                  doneHorizontally = true;
                } else {
                  expect(newRect.left, lessThan(rect.left));
                }
              }
            case TextDirection.ltr:
              expect(newRect.left, rect.left);
              if (doneHorizontally) {
                expect(newRect.right, rect.right);
              } else {
                if (newRect.right == rect.right) {
                  doneHorizontally = true;
                } else {
                  expect(newRect.right, greaterThan(rect.right));
                }
              }
          }
          rect = newRect;
        } while (tester.binding.hasScheduledFrame);
      });
    }

    Future<void> testPositioningDownThenUp(
      WidgetTester tester,
      TextDirection textDirection,
      Alignment alignment,
      TextDirection growthDirection,
      Rect startRect,
    ) {
      return TestAsyncUtils.guard<void>(() async {
        await openMenu(textDirection, alignment);
        Rect rect = tester.getRect(find.byWidgetPredicate(popupMenu));
        expect(rect, startRect);
        int verticalStage = 0; // 0=down, 1=up, 2=done
        bool doneHorizontally = false;
        do {
          await tester.pump(const Duration(milliseconds: 20));
          final Rect newRect =
              tester.getRect(find.byWidgetPredicate(popupMenu));
          switch (verticalStage) {
            case 0:
              if (newRect.top < rect.top) {
                verticalStage = 1;
                expect(newRect.bottom, greaterThanOrEqualTo(rect.bottom));
                break;
              }
              expect(newRect.top, rect.top);
              expect(newRect.bottom, greaterThan(rect.bottom));
            case 1:
              if (newRect.top == rect.top) {
                verticalStage = 2;
                expect(newRect.bottom, rect.bottom);
                break;
              }
              expect(newRect.top, lessThan(rect.top));
              expect(newRect.bottom, rect.bottom);
            case 2:
              expect(newRect.bottom, rect.bottom);
              expect(newRect.top, rect.top);
            default:
              assert(false);
          }
          switch (growthDirection) {
            case TextDirection.rtl:
              expect(newRect.right, rect.right);
              if (doneHorizontally) {
                expect(newRect.left, rect.left);
              } else {
                if (newRect.left == rect.left) {
                  doneHorizontally = true;
                } else {
                  expect(newRect.left, lessThan(rect.left));
                }
              }
            case TextDirection.ltr:
              expect(newRect.left, rect.left);
              if (doneHorizontally) {
                expect(newRect.right, rect.right);
              } else {
                if (newRect.right == rect.right) {
                  doneHorizontally = true;
                } else {
                  expect(newRect.right, greaterThan(rect.right));
                }
              }
          }
          rect = newRect;
        } while (tester.binding.hasScheduledFrame);
      });
    }

    await testPositioningDown(
      tester,
      TextDirection.ltr,
      Alignment.topRight,
      TextDirection.rtl,
      const Rect.fromLTWH(792.0, 8.0, 0.0, 0.0),
    );
    await testPositioningDown(
      tester,
      TextDirection.rtl,
      Alignment.topRight,
      TextDirection.rtl,
      const Rect.fromLTWH(792.0, 8.0, 0.0, 0.0),
    );
    await testPositioningDown(
      tester,
      TextDirection.ltr,
      Alignment.topLeft,
      TextDirection.ltr,
      const Rect.fromLTWH(8.0, 8.0, 0.0, 0.0),
    );
    await testPositioningDown(
      tester,
      TextDirection.rtl,
      Alignment.topLeft,
      TextDirection.ltr,
      const Rect.fromLTWH(8.0, 8.0, 0.0, 0.0),
    );
    await testPositioningDown(
      tester,
      TextDirection.ltr,
      Alignment.topCenter,
      TextDirection.ltr,
      const Rect.fromLTWH(350.0, 8.0, 0.0, 0.0),
    );
    await testPositioningDown(
      tester,
      TextDirection.rtl,
      Alignment.topCenter,
      TextDirection.rtl,
      const Rect.fromLTWH(450.0, 8.0, 0.0, 0.0),
    );
    await testPositioningDown(
      tester,
      TextDirection.ltr,
      Alignment.centerRight,
      TextDirection.rtl,
      const Rect.fromLTWH(792.0, 250.0, 0.0, 0.0),
    );
    await testPositioningDown(
      tester,
      TextDirection.rtl,
      Alignment.centerRight,
      TextDirection.rtl,
      const Rect.fromLTWH(792.0, 250.0, 0.0, 0.0),
    );
    await testPositioningDown(
      tester,
      TextDirection.ltr,
      Alignment.centerLeft,
      TextDirection.ltr,
      const Rect.fromLTWH(8.0, 250.0, 0.0, 0.0),
    );
    await testPositioningDown(
      tester,
      TextDirection.rtl,
      Alignment.centerLeft,
      TextDirection.ltr,
      const Rect.fromLTWH(8.0, 250.0, 0.0, 0.0),
    );
    await testPositioningDown(
      tester,
      TextDirection.ltr,
      Alignment.center,
      TextDirection.ltr,
      const Rect.fromLTWH(350.0, 250.0, 0.0, 0.0),
    );
    await testPositioningDown(
      tester,
      TextDirection.rtl,
      Alignment.center,
      TextDirection.rtl,
      const Rect.fromLTWH(450.0, 250.0, 0.0, 0.0),
    );
    await testPositioningDownThenUp(
      tester,
      TextDirection.ltr,
      Alignment.bottomRight,
      TextDirection.rtl,
      const Rect.fromLTWH(792.0, 500.0, 0.0, 0.0),
    );
    await testPositioningDownThenUp(
      tester,
      TextDirection.rtl,
      Alignment.bottomRight,
      TextDirection.rtl,
      const Rect.fromLTWH(792.0, 500.0, 0.0, 0.0),
    );
    await testPositioningDownThenUp(
      tester,
      TextDirection.ltr,
      Alignment.bottomLeft,
      TextDirection.ltr,
      const Rect.fromLTWH(8.0, 500.0, 0.0, 0.0),
    );
    await testPositioningDownThenUp(
      tester,
      TextDirection.rtl,
      Alignment.bottomLeft,
      TextDirection.ltr,
      const Rect.fromLTWH(8.0, 500.0, 0.0, 0.0),
    );
    await testPositioningDownThenUp(
      tester,
      TextDirection.ltr,
      Alignment.bottomCenter,
      TextDirection.ltr,
      const Rect.fromLTWH(350.0, 500.0, 0.0, 0.0),
    );
    await testPositioningDownThenUp(
      tester,
      TextDirection.rtl,
      Alignment.bottomCenter,
      TextDirection.rtl,
      const Rect.fromLTWH(450.0, 500.0, 0.0, 0.0),
    );
  });

  testWidgets('PopupMenu positioning inside nested Overlay',
      (WidgetTester tester) async {
    final Key buttonKey = UniqueKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('Example')),
          body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Overlay(
              initialEntries: <OverlayEntry>[
                OverlayEntry(
                  builder: (_) => Center(
                    child: PopupMenuButton<int>(
                      key: buttonKey,
                      itemBuilder: (_) => <PopupMenuItem<int>>[
                        const PopupMenuItem<int>(
                          value: 1,
                          child: Text('Item 1'),
                        ),
                        const PopupMenuItem<int>(
                          value: 2,
                          child: Text('Item 2'),
                        ),
                      ],
                      child: const Text('Show Menu'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final Finder buttonFinder = find.byKey(buttonKey);
    final Finder popupFinder = find.bySemanticsLabel('Popup menu');
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();

    final Offset buttonTopLeft = tester.getTopLeft(buttonFinder);
    expect(tester.getTopLeft(popupFinder), buttonTopLeft);
  });

  testWidgets('PopupMenu positioning inside nested Navigator',
      (WidgetTester tester) async {
    final Key buttonKey = UniqueKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('Example')),
          body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Navigator(
              onGenerateRoute: (RouteSettings settings) {
                return MaterialPageRoute<dynamic>(
                  builder: (BuildContext context) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(
                        child: PopupMenuButton<int>(
                          key: buttonKey,
                          itemBuilder: (_) => <PopupMenuItem<int>>[
                            const PopupMenuItem<int>(
                              value: 1,
                              child: Text('Item 1'),
                            ),
                            const PopupMenuItem<int>(
                              value: 2,
                              child: Text('Item 2'),
                            ),
                          ],
                          child: const Text('Show Menu'),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );

    final Finder buttonFinder = find.byKey(buttonKey);
    final Finder popupFinder = find.bySemanticsLabel('Popup menu');
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();

    final Offset buttonTopLeft = tester.getTopLeft(buttonFinder);
    expect(tester.getTopLeft(popupFinder), buttonTopLeft);
  });

  testWidgets('PopupMenu positioning around display features',
      (WidgetTester tester) async {
    final Key buttonKey = UniqueKey();

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(800, 600),
            displayFeatures: <DisplayFeature>[
              // A 20-pixel wide vertical display feature, similar to a foldable
              // with a visible hinge. Splits the display into two "virtual screens"
              // and the popup menu should never overlap the display feature.
              DisplayFeature(
                bounds: Rect.fromLTRB(390, 0, 410, 600),
                type: DisplayFeatureType.cutout,
                state: DisplayFeatureState.unknown,
              ),
            ],
          ),
          child: Scaffold(
            body: Navigator(
              onGenerateRoute: (RouteSettings settings) {
                return MaterialPageRoute<dynamic>(
                  builder: (BuildContext context) {
                    return Padding(
                      // Position the button in the top-right of the first "virtual screen"
                      padding: const EdgeInsets.only(right: 390.0),
                      child: Align(
                        alignment: Alignment.topRight,
                        child: PopupMenuButton<int>(
                          key: buttonKey,
                          itemBuilder: (_) => <PopupMenuItem<int>>[
                            const PopupMenuItem<int>(
                              value: 1,
                              child: Text('Item 1'),
                            ),
                            const PopupMenuItem<int>(
                              value: 2,
                              child: Text('Item 2'),
                            ),
                          ],
                          child: const Text('Show Menu'),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );

    final Finder buttonFinder = find.byKey(buttonKey);
    final Finder popupFinder = find.bySemanticsLabel('Popup menu');
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();

    // Since the display feature splits the display into 2 sub-screens, popup
    // menu should be positioned to fit in the first virtual screen, where the
    // originating button is.
    // The 8 pixels is [_kMenuScreenPadding].
    expect(tester.getTopRight(popupFinder), const Offset(390 - 8, 8));
  });

  testWidgets('CupertinoMenu removes MediaQuery padding',
      (WidgetTester tester) async {
    late BuildContext popupContext;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            padding: EdgeInsets.all(50.0),
          ),
          child: CupertinoMenuButton<int>(
            itemBuilder: (BuildContext context) {
              popupContext = context;
              return <CupertinoMenuEntry<int>>[
                CupertinoMenuItem<int>(
                  value: 1,
                  child: Builder(
                    builder: (BuildContext context) {
                      popupContext = context;
                      return const Text('AAA');
                    },
                  ),
                ),
              ];
            },
            child: const SizedBox(
              height: 100.0,
              width: 100.0,
              child: Text('XXX'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('XXX'));

    await tester.pump();

    expect(MediaQuery.of(popupContext).padding, EdgeInsets.zero);
  });

  testWidgets('CupertinoMenu Offset Test', (WidgetTester tester) async {
    CupertinoMenuButton<int> buildMenuButton({Offset offset = Offset.zero}) {
      return CupertinoMenuButton<int>(
        offset: offset,
        itemBuilder: (BuildContext context) {
          return <CupertinoMenuItem<int>>[
            CupertinoMenuItem<int>(
              value: 1,
              child: Builder(
                builder: (BuildContext context) {
                  return const Text('AAA');
                },
              ),
            ),
          ];
        },
      );
    }

    // Popup a menu without any offset.
    await tester.pumpWidget(
      CupertinoApp(
        home: Scaffold(
          body: buildMenuButton(),
        ),
      ),
    );

    // Popup the menu.
    await tester.tap(find.byType(CupertinoButton));
    await tester.pumpAndSettle();

    double buttonHeight = tester.getSize(find.byType(CupertinoButton)).height;
    // Initial state: a menu opened from the top right of the screen will start at
    // Offset(8.0, buttonHeight). This prevents the button from being overlapped
    expect(
      tester.getTopLeft(
        find.byWidgetPredicate((Widget w) {
          return '${w.runtimeType}' == 'CupertinoMenu';
        }),
      ),
      Offset(8.0, max(buttonHeight, 8.0)),
    );

    // Collapse the menu.
    await tester.tap(find.byType(CupertinoButton), warnIfMissed: false);
    await tester.pumpAndSettle();

    // Popup a new menu with Offset(50.0, 50.0).
    await tester.pumpWidget(
      CupertinoApp(
        home: Scaffold(
          body: buildMenuButton(
            offset: const Offset(50.0, 50.0),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(CupertinoButton));
    await tester.pumpAndSettle();

    buttonHeight = tester.getSize(find.byType(CupertinoButton)).height;
    // This time the menu should start at Offset(50.0, 50.0), the padding only added when offset.dx < 8.0.
    expect(
      tester.getTopLeft(
        find.byWidgetPredicate(
          (Widget w) => '${w.runtimeType}' == 'CupertinoMenu',
        ),
      ),
      Offset(50.0, buttonHeight + 50),
    );
  });

  testWidgets('open CupertinoMenu has correct semantics',
      (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    final List<CupertinoMenuEntry<int>> menuItems = <CupertinoMenuEntry<int>>[
      CupertinoStickyMenuHeader(
        subtitle: const Text('Subtitle'),
        leading: const FlutterLogo(size: 24),
        trailing: const Icon(CupertinoIcons.add),
        child: const Text('Title'),
      ),
      const CupertinoMenuItem<int>(
        value: 1,
        child: Text('CupertinoMenuItem'),
      ),
      const CupertinoMenuItem<int>(
        value: 1,
        enabled: false,
        child: Text('CupertinoMenuItem+Disabled'),
      ),
      const CupertinoMenuItem<int>(
        value: 1,
        isDestructiveAction: true,
        child: Text('CupertinoMenuItem+Destructive'),
      ),
      const CupertinoCheckedMenuItem<int>(
        value: 2,
        checked: false,
        child: Text('CupertinoCheckedMenuItem+Unchecked'),
      ),
      const CupertinoCheckedMenuItem<int>(
        value: 3,
        child: Text('CupertinoCheckedMenuItem+Checked'),
      ),
      const CupertinoMenuTitle(
        child: Text('CupertinoMenuTitle'),
      ),
      const CupertinoMenuLargeDivider(),
      const CupertinoMenuActionItem<int>(
        icon: Icon(CupertinoIcons.hexagon),
        value: 4,
        child: Text('ActionItem 4'),
      ),
      const CupertinoMenuActionItem<int>(
        icon: Icon(CupertinoIcons.triangle),
        value: 5,
        child: Text('ActionItem 5'),
      ),
      const CupertinoMenuActionItem<int>(
        icon: Icon(CupertinoIcons.square),
        value: 6,
        child: Text('ActionItem 6'),
      ),
    ];
    await tester.pumpWidget(
      TestApp(
        textDirection: TextDirection.ltr,
        child: CupertinoMenuButton<int>(
          itemBuilder: (BuildContext context) {
            return <CupertinoMenuEntry<int>>[
              ...menuItems,
              CupertinoNestedMenu<int>(
                itemBuilder: (BuildContext context) {
                  return menuItems;
                },
                subtitle: const Text('Subtitle'),
                title: const TextSpan(text: 'Nested Menu'),
              ),
            ];
          },
          child: const SizedBox(
            height: 100.0,
            width: 100.0,
            child: Text('XXX'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('XXX'));
    await tester.pumpAndSettle();
    expect(
      semantics,
      hasSemantics(
        TestSemantics.root(
          children: <TestSemantics>[
            TestSemantics(
              id: 1,
              actions: <SemanticsAction>[
                SemanticsAction.tap,
                SemanticsAction.dismiss,
              ],
              label: 'Dismiss',
              textDirection: TextDirection.ltr,
              children: <TestSemantics>[
                TestSemantics(
                  id: 4,
                  flags: <SemanticsFlag>[
                    SemanticsFlag.scopesRoute,
                    SemanticsFlag.namesRoute,
                  ],
                  actions: <SemanticsAction>[SemanticsAction.tap],
                  label: 'Popup menu',
                  textDirection: TextDirection.ltr,
                  children: <TestSemantics>[
                    TestSemantics(
                      id: 5,
                      children: <TestSemantics>[
                        TestSemantics(
                          id: 17,
                          tags: <SemanticsTag>[
                            const SemanticsTag(
                                'RenderViewport.excludeFromScrolling',),
                            const SemanticsTag('RenderViewport.twoPane'),
                          ],
                          label: 'Title',
                          textDirection: TextDirection.ltr,
                        ),
                        TestSemantics(
                          id: 18,
                          tags: <SemanticsTag>[
                            const SemanticsTag(
                                'RenderViewport.excludeFromScrolling',),
                            const SemanticsTag('RenderViewport.twoPane'),
                          ],
                          label: 'Subtitle',
                          textDirection: TextDirection.ltr,
                        ),
                        TestSemantics(
                          id: 19,
                          children: <TestSemantics>[
                            TestSemantics(
                              id: 6,
                              tags: <SemanticsTag>[
                                const SemanticsTag('RenderViewport.twoPane'),
                              ],
                              flags: <SemanticsFlag>[
                                SemanticsFlag.isButton,
                                SemanticsFlag.hasEnabledState,
                                SemanticsFlag.isEnabled,
                                SemanticsFlag.isFocusable,
                              ],
                              actions: <SemanticsAction>[SemanticsAction.tap],
                              label: 'CupertinoMenuItem',
                              textDirection: TextDirection.ltr,
                            ),
                            TestSemantics(
                              id: 7,
                              tags: <SemanticsTag>[
                                const SemanticsTag('RenderViewport.twoPane'),
                              ],
                              flags: <SemanticsFlag>[
                                SemanticsFlag.isButton,
                                SemanticsFlag.hasEnabledState,
                              ],
                              actions: <SemanticsAction>[SemanticsAction.tap],
                              label: 'CupertinoMenuItem+Disabled',
                              textDirection: TextDirection.ltr,
                            ),
                            TestSemantics(
                              id: 8,
                              tags: <SemanticsTag>[
                                const SemanticsTag('RenderViewport.twoPane'),
                              ],
                              flags: <SemanticsFlag>[
                                SemanticsFlag.isButton,
                                SemanticsFlag.hasEnabledState,
                                SemanticsFlag.isEnabled,
                                SemanticsFlag.isFocusable,
                              ],
                              actions: <SemanticsAction>[SemanticsAction.tap],
                              label: 'CupertinoMenuItem+Destructive',
                              textDirection: TextDirection.ltr,
                            ),
                            TestSemantics(
                              id: 9,
                              tags: <SemanticsTag>[
                                const SemanticsTag('RenderViewport.twoPane'),
                              ],
                              flags: <SemanticsFlag>[
                                SemanticsFlag.hasCheckedState,
                                SemanticsFlag.isButton,
                                SemanticsFlag.hasEnabledState,
                                SemanticsFlag.isEnabled,
                                SemanticsFlag.isFocusable,
                              ],
                              actions: <SemanticsAction>[SemanticsAction.tap],
                              label: 'CupertinoCheckedMenuItem+Unchecked',
                              textDirection: TextDirection.ltr,
                            ),
                            TestSemantics(
                              id: 10,
                              tags: <SemanticsTag>[
                                const SemanticsTag('RenderViewport.twoPane'),
                              ],
                              flags: <SemanticsFlag>[
                                SemanticsFlag.hasCheckedState,
                                SemanticsFlag.isChecked,
                                SemanticsFlag.isButton,
                                SemanticsFlag.hasEnabledState,
                                SemanticsFlag.isEnabled,
                                SemanticsFlag.isFocusable,
                              ],
                              actions: <SemanticsAction>[SemanticsAction.tap],
                              label: 'CupertinoCheckedMenuItem+Checked',
                              textDirection: TextDirection.ltr,
                            ),
                            TestSemantics(
                              id: 11,
                              tags: <SemanticsTag>[
                                const SemanticsTag('RenderViewport.twoPane'),
                              ],
                              flags: <SemanticsFlag>[SemanticsFlag.isHeader],
                              label: 'CupertinoMenuTitle',
                              textDirection: TextDirection.ltr,
                            ),
                            TestSemantics(
                              id: 12,
                              tags: <SemanticsTag>[
                                const SemanticsTag('RenderViewport.twoPane'),
                              ],
                              flags: <SemanticsFlag>[
                                SemanticsFlag.isButton,
                                SemanticsFlag.hasEnabledState,
                                SemanticsFlag.isEnabled,
                                SemanticsFlag.isFocusable,
                              ],
                              actions: <SemanticsAction>[SemanticsAction.tap],
                              label: 'ActionItem 4',
                              textDirection: TextDirection.ltr,
                            ),
                            TestSemantics(
                              id: 13,
                              tags: <SemanticsTag>[
                                const SemanticsTag('RenderViewport.twoPane'),
                              ],
                              flags: <SemanticsFlag>[
                                SemanticsFlag.isButton,
                                SemanticsFlag.hasEnabledState,
                                SemanticsFlag.isEnabled,
                                SemanticsFlag.isFocusable,
                              ],
                              actions: <SemanticsAction>[SemanticsAction.tap],
                              label: 'ActionItem 5',
                              textDirection: TextDirection.ltr,
                            ),
                            TestSemantics(
                              id: 14,
                              tags: <SemanticsTag>[
                                const SemanticsTag('RenderViewport.twoPane'),
                              ],
                              flags: <SemanticsFlag>[
                                SemanticsFlag.isButton,
                                SemanticsFlag.hasEnabledState,
                                SemanticsFlag.isEnabled,
                                SemanticsFlag.isFocusable,
                              ],
                              actions: <SemanticsAction>[SemanticsAction.tap],
                              label: 'ActionItem 6',
                              textDirection: TextDirection.ltr,
                            ),
                            TestSemantics(
                              id: 15,
                              tags: <SemanticsTag>[
                                const SemanticsTag('RenderViewport.twoPane'),
                              ],
                              hint: 'Tap to expand',
                              textDirection: TextDirection.ltr,
                              children: <TestSemantics>[
                                TestSemantics(
                                  id: 16,
                                  flags: <SemanticsFlag>[
                                    SemanticsFlag.isButton,
                                    SemanticsFlag.hasEnabledState,
                                    SemanticsFlag.isEnabled,
                                    SemanticsFlag.isFocusable,
                                  ],
                                  actions: <SemanticsAction>[
                                    SemanticsAction.tap,
                                  ],
                                  label: 'Nested Menu\nSubtitle',
                                  textDirection: TextDirection.ltr,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        ignoreId: true,
        ignoreTransform: true,
        ignoreRect: true,
      ),
    );

    semantics.dispose();
  });

  testWidgets('PopupMenuItem merges the semantics of its descendants',
      (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: PopupMenuButton<int>(
            itemBuilder: (BuildContext context) {
              return <PopupMenuItem<int>>[
                PopupMenuItem<int>(
                  value: 1,
                  child: Row(
                    children: <Widget>[
                      Semantics(
                        child: const Text('test1'),
                      ),
                      Semantics(
                        child: const Text('test2'),
                      ),
                    ],
                  ),
                ),
              ];
            },
            child: const SizedBox(
              height: 100.0,
              width: 100.0,
              child: Text('XXX'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('XXX'));
    await tester.pumpAndSettle();

    expect(
      semantics,
      hasSemantics(
        TestSemantics.root(
          children: <TestSemantics>[
            TestSemantics(
              textDirection: TextDirection.ltr,
              children: <TestSemantics>[
                TestSemantics(
                  children: <TestSemantics>[
                    TestSemantics(
                      flags: <SemanticsFlag>[
                        SemanticsFlag.scopesRoute,
                        SemanticsFlag.namesRoute,
                      ],
                      label: 'Popup menu',
                      textDirection: TextDirection.ltr,
                      children: <TestSemantics>[
                        TestSemantics(
                          flags: <SemanticsFlag>[
                            SemanticsFlag.hasImplicitScrolling,
                          ],
                          children: <TestSemantics>[
                            TestSemantics(
                              flags: <SemanticsFlag>[
                                SemanticsFlag.isButton,
                                SemanticsFlag.hasEnabledState,
                                SemanticsFlag.isEnabled,
                                SemanticsFlag.isFocusable,
                              ],
                              actions: <SemanticsAction>[SemanticsAction.tap],
                              label: 'test1\ntest2',
                              textDirection: TextDirection.ltr,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                TestSemantics(
                  actions: <SemanticsAction>[
                    SemanticsAction.tap,
                    SemanticsAction.dismiss,
                  ],
                  label: 'Dismiss',
                  textDirection: TextDirection.ltr,
                ),
              ],
            ),
          ],
        ),
        ignoreId: true,
        ignoreTransform: true,
        ignoreRect: true,
      ),
    );

    semantics.dispose();
  });

  testWidgets('disabled PopupMenuItem has correct semantics',
      (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/45044.
    final SemanticsTester semantics = SemanticsTester(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: PopupMenuButton<int>(
            itemBuilder: (BuildContext context) {
              return <PopupMenuItem<int>>[
                const PopupMenuItem<int>(value: 1, child: Text('1')),
                const PopupMenuItem<int>(
                  value: 2,
                  enabled: false,
                  child: Text('2'),
                ),
                const PopupMenuItem<int>(value: 3, child: Text('3')),
                const PopupMenuItem<int>(value: 4, child: Text('4')),
                const PopupMenuItem<int>(value: 5, child: Text('5')),
              ];
            },
            child: const SizedBox(
              height: 100.0,
              width: 100.0,
              child: Text('XXX'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('XXX'));
    await tester.pumpAndSettle();

    expect(
      semantics,
      hasSemantics(
        TestSemantics.root(
          children: <TestSemantics>[
            TestSemantics(
              textDirection: TextDirection.ltr,
              children: <TestSemantics>[
                TestSemantics(
                  children: <TestSemantics>[
                    TestSemantics(
                      flags: <SemanticsFlag>[
                        SemanticsFlag.scopesRoute,
                        SemanticsFlag.namesRoute,
                      ],
                      label: 'Popup menu',
                      textDirection: TextDirection.ltr,
                      children: <TestSemantics>[
                        TestSemantics(
                          flags: <SemanticsFlag>[
                            SemanticsFlag.hasImplicitScrolling,
                          ],
                          children: <TestSemantics>[
                            TestSemantics(
                              flags: <SemanticsFlag>[
                                SemanticsFlag.isButton,
                                SemanticsFlag.hasEnabledState,
                                SemanticsFlag.isEnabled,
                                SemanticsFlag.isFocusable,
                              ],
                              actions: <SemanticsAction>[SemanticsAction.tap],
                              label: '1',
                              textDirection: TextDirection.ltr,
                            ),
                            TestSemantics(
                              flags: <SemanticsFlag>[
                                SemanticsFlag.isButton,
                                SemanticsFlag.hasEnabledState,
                              ],
                              actions: <SemanticsAction>[],
                              label: '2',
                              textDirection: TextDirection.ltr,
                            ),
                            TestSemantics(
                              flags: <SemanticsFlag>[
                                SemanticsFlag.isButton,
                                SemanticsFlag.hasEnabledState,
                                SemanticsFlag.isEnabled,
                                SemanticsFlag.isFocusable,
                              ],
                              actions: <SemanticsAction>[SemanticsAction.tap],
                              label: '3',
                              textDirection: TextDirection.ltr,
                            ),
                            TestSemantics(
                              flags: <SemanticsFlag>[
                                SemanticsFlag.isButton,
                                SemanticsFlag.hasEnabledState,
                                SemanticsFlag.isEnabled,
                                SemanticsFlag.isFocusable,
                              ],
                              actions: <SemanticsAction>[SemanticsAction.tap],
                              label: '4',
                              textDirection: TextDirection.ltr,
                            ),
                            TestSemantics(
                              flags: <SemanticsFlag>[
                                SemanticsFlag.isButton,
                                SemanticsFlag.hasEnabledState,
                                SemanticsFlag.isEnabled,
                                SemanticsFlag.isFocusable,
                              ],
                              actions: <SemanticsAction>[SemanticsAction.tap],
                              label: '5',
                              textDirection: TextDirection.ltr,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                TestSemantics(
                  actions: <SemanticsAction>[
                    SemanticsAction.tap,
                    SemanticsAction.dismiss,
                  ],
                  label: 'Dismiss',
                  textDirection: TextDirection.ltr,
                ),
              ],
            ),
          ],
        ),
        ignoreId: true,
        ignoreTransform: true,
        ignoreRect: true,
      ),
    );

    semantics.dispose();
  });

  testWidgets('CupertinoMenuButton CupertinoMenuDivider',
      (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/27072

    late String selectedValue;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: CupertinoMenuButton<String>(
              onSelect: (String result) {
                selectedValue = result;
              },
              child: const Text('Menu Button'),
              itemBuilder: (BuildContext context) =>
                  <CupertinoMenuEntry<String>>[
                const CupertinoMenuItem<String>(
                  value: '1',
                  child: Text('1'),
                ),
                const CupertinoMenuLargeDivider(),
                const CupertinoMenuItem<String>(
                  value: '2',
                  child: Text('2'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Menu Button'));
    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget);
    expect(find.byType(CupertinoMenuLargeDivider), findsOneWidget);
    expect(find.text('2'), findsOneWidget);

    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();
    expect(selectedValue, '1');

    await tester.tap(find.text('Menu Button'));
    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget);
    expect(find.byType(CupertinoMenuLargeDivider), findsOneWidget);
    expect(find.text('2'), findsOneWidget);

    await tester.tap(find.text('2'));
    await tester.pumpAndSettle();
    expect(selectedValue, '2');
  });

/*
  testWidgets(
      'PopupMenuItem child height is a minimum, child is vertically centered',
      (WidgetTester tester) async {
    final Key popupMenuButtonKey = UniqueKey();
    final Type menuItemType =
        const PopupMenuItem<String>(child: Text('item')).runtimeType;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: PopupMenuButton<String>(
              key: popupMenuButtonKey,
              child: const Text('button'),
              onSelected: (String result) {},
              itemBuilder: (BuildContext context) {
                return <PopupMenuEntry<String>>[
                  // This menu item's height will be 48 because the default minimum height
                  // is 48 and the height of the text is less than 48.
                  const PopupMenuItem<String>(
                    value: '0',
                    child: Text('Item 0'),
                  ),
                  // This menu item's height parameter specifies its minimum height. The
                  // overall height of the menu item will be 50 because the child's
                  // height 40, is less than 50.
                  const PopupMenuItem<String>(
                    height: 50,
                    value: '1',
                    child: SizedBox(
                      height: 40,
                      child: Text('Item 1'),
                    ),
                  ),
                  // This menu item's height parameter specifies its minimum height, so the
                  // overall height of the menu item will be 75.
                  const PopupMenuItem<String>(
                    height: 75,
                    value: '2',
                    child: SizedBox(
                      child: Text('Item 2'),
                    ),
                  ),
                  // This menu item's height will be 100.
                  const PopupMenuItem<String>(
                    value: '3',
                    child: SizedBox(
                      height: 100,
                      child: Text('Item 3'),
                    ),
                  ),
                ];
              },
            ),
          ),
        ),
      ),
    );

    // Show the menu
    await tester.tap(find.byKey(popupMenuButtonKey));
    await tester.pumpAndSettle();

    // The menu items and their InkWells should have the expected vertical size
    expect(
      tester.getSize(find.widgetWithText(menuItemType, 'Item 0')).height,
      48,
    );
    expect(
      tester.getSize(find.widgetWithText(menuItemType, 'Item 1')).height,
      50,
    );
    expect(
      tester.getSize(find.widgetWithText(menuItemType, 'Item 2')).height,
      75,
    );
    expect(
      tester.getSize(find.widgetWithText(menuItemType, 'Item 3')).height,
      100,
    );
    expect(tester.getSize(find.widgetWithText(InkWell, 'Item 0')).height, 48);
    expect(tester.getSize(find.widgetWithText(InkWell, 'Item 1')).height, 50);
    expect(tester.getSize(find.widgetWithText(InkWell, 'Item 2')).height, 75);
    expect(tester.getSize(find.widgetWithText(InkWell, 'Item 3')).height, 100);

    // Menu item children which whose height is less than the PopupMenuItem
    // are vertically centered.
    expect(
      tester.getRect(find.widgetWithText(menuItemType, 'Item 0')).center.dy,
      tester.getRect(find.text('Item 0')).center.dy,
    );
    expect(
      tester.getRect(find.widgetWithText(menuItemType, 'Item 2')).center.dy,
      tester.getRect(find.text('Item 2')).center.dy,
    );
  });
*/
  testWidgets('CupertinoMenuItem custom padding', (WidgetTester tester) async {
    final Key popupMenuButtonKey = UniqueKey();
    final Type menuItemType =
        const CupertinoMenuItem<String>(child: Text('item')).runtimeType;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: CupertinoMenuButton<String>(
              key: popupMenuButtonKey,
              child: const Text('button'),
              onSelect: (String? result) {},
              itemBuilder: (BuildContext context) {
                return <CupertinoMenuEntry<String>>[
                  const CupertinoMenuItem<String>(
                    padding: EdgeInsetsDirectional.zero,
                    value: '0',
                    child: Text('Item 0'),
                  ),
                  const CupertinoMenuItem<String>(
                    padding: EdgeInsetsDirectional.zero,
                    height: 0,
                    value: '0',
                    child: Text('Item 1'),
                  ),
                  const CupertinoMenuItem<String>(
                    padding: EdgeInsetsDirectional.all(20),
                    value: '0',
                    child: Text('Item 2'),
                  ),
                  const CupertinoMenuItem<String>(
                    padding: EdgeInsetsDirectional.all(20),
                    height: 100,
                    value: '0',
                    child: Text('Item 3'),
                  ),
                ];
              },
            ),
          ),
        ),
      ),
    );

    // Show the menu
    await tester.tap(find.byKey(popupMenuButtonKey));
    await tester.pumpAndSettle();

    // The menu items and their InkWells should have the expected vertical size
    // given the interactions between heights and padding.
    expect(
      tester.getSize(find.widgetWithText(menuItemType, 'Item 0')).height,
      44,
    ); // Minimum interactive height (44)
    expect(
      tester.getSize(find.widgetWithText(menuItemType, 'Item 1')).height,
      17,
    ); // Height of text (17)
    expect(
      tester.getSize(find.widgetWithText(menuItemType, 'Item 2')).height,
      57,
    ); // Padding (20.0 + 20.0) + Height of text (17) = 57
    expect(
      tester.getSize(find.widgetWithText(menuItemType, 'Item 3')).height,
      100,
    ); // Height value of 100, since child (16) + padding (40) < 100

    expect(
      tester
          .widget<CupertinoMenuItem<String>>(
            find.widgetWithText(CupertinoMenuItem<String>, 'Item 0'),
          )
          .padding,
      EdgeInsets.zero,
    );
    expect(
      tester
          .widget<CupertinoMenuItem<String>>(
            find.widgetWithText(CupertinoMenuItem<String>, 'Item 1'),
          )
          .padding,
      EdgeInsets.zero,
    );
    expect(
      tester
          .widget<CupertinoMenuItem<String>>(
            find.widgetWithText(CupertinoMenuItem<String>, 'Item 2'),
          )
          .padding,
      const EdgeInsetsDirectional.all(20),
    );
    expect(
      tester
          .widget<CupertinoMenuItem<String>>(
            find.widgetWithText(CupertinoMenuItem<String>, 'Item 3'),
          )
          .padding,
      const EdgeInsetsDirectional.all(20),
    );
  });

  testWidgets(
      'CupertinoCheckedMenuItem child height is a minimum, child is vertically centered',
      (WidgetTester tester) async {
    final Key popupMenuButtonKey = UniqueKey();
    final Type menuItemType =
        const CupertinoCheckedMenuItem<String>(child: Text('item')).runtimeType;

    const String longText =
        'Item 0 is a very long menu item that should wrap and ellipsis';
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: Center(
            child: CupertinoMenuButton<String>(
              key: popupMenuButtonKey,
              child: const Text('button'),
              onSelect: (String result) {},
              itemBuilder: (BuildContext context) {
                return <CupertinoMenuEntry<String>>[
                  // This menu item's height will be 44.0
                  const CupertinoCheckedMenuItem<String>(
                    value: '0',
                    child: Text('Item 0'),
                  ),

                  // This menu item's height will be 50.0
                  const CupertinoCheckedMenuItem<String>(
                    value: '0',
                    child: Text(longText),
                  ),
                  // This menu item's height parameter specifies its minimum height. The
                  // overall height of the menu item will be 60 because the child's
                  // height 56, is less than 60.
                  const CupertinoCheckedMenuItem<String>(
                    height: 60,
                    value: '1',
                    child: SizedBox(
                      height: 30,
                      child: Text('Item 1'),
                    ),
                  ),
                  // This menu item's height parameter specifies its minimum height, so the
                  // overall height of the menu item will be 75.
                  const CupertinoCheckedMenuItem<String>(
                    height: 75,
                    value: '2',
                    child: SizedBox(
                      child: Text('Item 2'),
                    ),
                  ),
                  // This menu item's height will be 100.
                  const CupertinoCheckedMenuItem<String>(
                    height: 100,
                    value: '3',
                    child: SizedBox(
                      child: Text('Item 3'),
                    ),
                  ),
                ];
              },
            ),
          ),
        ),
      ),
    );

    // Show the menu
    await tester.tap(find.byKey(popupMenuButtonKey));
    await tester.pumpAndSettle();

    // The menu items should have the expected vertical size
    expect(
      tester.getSize(find.widgetWithText(menuItemType, longText)).height,
      58,
    );
    expect(
      tester.getSize(find.widgetWithText(menuItemType, 'Item 1')).height,
      60,
    );
    expect(
      tester.getSize(find.widgetWithText(menuItemType, 'Item 2')).height,
      75,
    );
    expect(
      tester.getSize(find.widgetWithText(menuItemType, 'Item 3')).height,
      100,
    );
    // We evaluate the InkWell at the first index because that is the ListTile's
    // InkWell, which wins in the gesture arena over the child's InkWell and
    // is the one of interest.
    expect(
      tester
          .getSize(
            find
                .widgetWithText(
                  GestureDetector,
                  'Item 0 is a very long menu item that should wrap and ellipsis',
                )
                .at(0),
          )
          .height,
      58,
    );
    expect(
      tester
          .getSize(find.widgetWithText(GestureDetector, 'Item 1').at(0))
          .height,
      60,
    );
    expect(
      tester
          .getSize(find.widgetWithText(GestureDetector, 'Item 2').at(0))
          .height,
      75,
    );
    expect(
      tester
          .getSize(find.widgetWithText(GestureDetector, 'Item 3').at(0))
          .height,
      100,
    );

    // Menu item children which whose height is less than the CupertinoMenuItem
    // are vertically centered.
    expect(
      tester.getRect(find.widgetWithText(menuItemType, 'Item 1')).center.dy,
      tester.getRect(find.text('Item 1')).center.dy,
    );
    expect(
      tester.getRect(find.widgetWithText(menuItemType, 'Item 2')).center.dy,
      tester.getRect(find.text('Item 2')).center.dy,
    );
  });

  testWidgets('CupertinoCheckedMenuItem custom padding',
      (WidgetTester tester) async {
    final Key popupMenuButtonKey = UniqueKey();
    final Type menuItemType =
        const CupertinoCheckedMenuItem<String>(child: Text('item')).runtimeType;
    Text buildText(String text) => Text(
          text,
          style: const TextStyle(
            fontSize: 20,
            fontFamily: 'Roboto',
          ),
        );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: CupertinoMenuButton<String>(
              key: popupMenuButtonKey,
              child: const Text('button'),
              onSelect: (String result) {},
              itemBuilder: (BuildContext context) {
                return <CupertinoMenuEntry<String>>[
                  CupertinoCheckedMenuItem<String>(
                    padding: EdgeInsetsDirectional.zero,
                    value: '0',
                    child: buildText('Item 0'),
                  ),
                  CupertinoCheckedMenuItem<String>(
                    padding: EdgeInsetsDirectional.zero,
                    height: 0,
                    value: '0',
                    child: buildText('Item 1'),
                  ),
                  CupertinoCheckedMenuItem<String>(
                    padding: const EdgeInsetsDirectional.all(20),
                    value: '0',
                    child: buildText('Item 2'),
                  ),
                  CupertinoCheckedMenuItem<String>(
                    padding: const EdgeInsetsDirectional.all(20),
                    height: 100,
                    value: '0',
                    child: buildText('Item 3'),
                  ),
                ];
              },
            ),
          ),
        ),
      ),
    );

    // Show the menu
    await tester.tap(find.byKey(popupMenuButtonKey));
    await tester.pumpAndSettle();

    // The menu items and their InkWells should have the expected vertical size
    // given the interactions between heights and padding.
    expect(
      tester.getSize(find.widgetWithText(menuItemType, 'Item 0')).height,
      44,
    ); // Minimum height (44)
    expect(
      tester.getSize(find.widgetWithText(menuItemType, 'Item 1')).height,
      44,
    ); // Minimum height (44)
    expect(
      tester.getSize(find.widgetWithText(menuItemType, 'Item 2')).height,
      60,
    ); // Padding (20.0 + 20.0) + Height of content (20) = 60
    expect(
      tester.getSize(find.widgetWithText(menuItemType, 'Item 3')).height,
      100,
    ); // Height value of 100, since child (20) + padding (40) < 100

    expect(
      tester.widget<Padding>(find.widgetWithText(Padding, 'Item 0')).padding,
      EdgeInsetsDirectional.zero,
    );
    expect(
      tester.widget<Padding>(find.widgetWithText(Padding, 'Item 1')).padding,
      EdgeInsetsDirectional.zero,
    );
    expect(
      tester.widget<Padding>(find.widgetWithText(Padding, 'Item 2')).padding,
      const EdgeInsetsDirectional.all(20),
    );
    expect(
      tester.widget<Padding>(find.widgetWithText(Padding, 'Item 3')).padding,
      const EdgeInsetsDirectional.all(20),
    );
  });

  testWidgets('Update CupertinoMenuItem layout while the menu is visible',
      (WidgetTester tester) async {
    final Key popupMenuButtonKey = UniqueKey();
    final Type menuItemType =
        const CupertinoMenuItem<String>(child: Text('item')).runtimeType;
    final double defaultHeight =
        CupertinoInteractiveMenuItem.defaultTextStyle.fontSize!;
    Widget buildFrame({
      TextDirection textDirection = TextDirection.ltr,
      double textScale = 1,
    }) {
      return CupertinoApp(
        builder: (BuildContext context, Widget? child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
            ),
            child: Directionality(
              textDirection: textDirection,
              child: child!,
            ),
          );
        },
        home: Scaffold(
          body: CupertinoMenuButton<String>(
            key: popupMenuButtonKey,
            child: const Text('button'),
            onSelect: (String? result) {
              /* Nothing to do here */
            },
            itemBuilder: (BuildContext context) {
              return <CupertinoMenuEntry<String>>[
                const CupertinoMenuItem<String>(
                  value: '0',
                  child: Text('Item 0'),
                ),
                const CupertinoMenuItem<String>(
                  value: '1',
                  child: Text('Item 1'),
                ),
              ];
            },
          ),
        ),
      );
    }

    // Show the menu
    await tester.pumpWidget(buildFrame());
    await tester.tap(find.byKey(popupMenuButtonKey));
    await tester.pumpAndSettle();

    // The menu items should have their default heights and horizontal alignment.
    expect(
      tester.getSize(find.widgetWithText(menuItemType, 'Item 0')).height,
      44,
    );
    expect(
      tester.getSize(find.widgetWithText(menuItemType, 'Item 1')).height,
      44,
    );
    expect(tester.getTopLeft(find.text('Item 0')).dx, 24);
    expect(tester.getTopLeft(find.text('Item 1')).dx, 24);

    // While the menu is up, change its font size to 64 (default is 16).
    await tester.pumpWidget(buildFrame(textScale: 2));
    await tester.pumpAndSettle(); // Size is animated.
    expect(
      tester.getSize(find.widgetWithText(menuItemType, 'Item 0')).height,
      88,
    );
    expect(
      tester.getSize(find.widgetWithText(menuItemType, 'Item 1')).height,
      88,
    );
    expect(tester.getSize(find.text('Item 0')).height, defaultHeight * 2);
    expect(tester.getSize(find.text('Item 1')).height, defaultHeight * 2);
    expect(tester.getTopLeft(find.text('Item 0')).dx, 24);
    expect(tester.getTopLeft(find.text('Item 1')).dx, 24);

    // While the menu is up, change the textDirection to rtl. Now menu items
    // will be aligned right.
    await tester.pumpWidget(buildFrame(textDirection: TextDirection.rtl));
    await tester.pumpAndSettle(); // Size is animated.
    expect(
      tester.getSize(find.widgetWithText(menuItemType, 'Item 0')).height,
      44,
    );
    expect(
      tester.getSize(find.widgetWithText(menuItemType, 'Item 1')).height,
      44,
    );
    expect(tester.getTopLeft(find.text('Item 0')).dx, 28);
    expect(tester.getTopLeft(find.text('Item 1')).dx, 28);
  });

  testWidgets('showCupertinoMenu uses nested navigator by default',
      (WidgetTester tester) async {
    const String name = 'CupertinoMenu';
    final MenuObserver rootObserver = MenuObserver(observedRoute: name);
    final MenuObserver nestedObserver = MenuObserver(observedRoute: name);

    await tester.pumpWidget(
      CupertinoApp(
        navigatorObservers: <NavigatorObserver>[rootObserver],
        home: Navigator(
          observers: <NavigatorObserver>[nestedObserver],
          onGenerateRoute: (RouteSettings settings) {
            return CupertinoPageRoute<dynamic>(
              builder: (BuildContext context) {
                return CupertinoButton(
                  onPressed: () {
                    showCupertinoMenu<int>(
                      settings: const RouteSettings(name: name),
                      context: context,
                      anchorPosition: RelativeRect.fill,
                      itemBuilder: (BuildContext context) =>
                          <CupertinoMenuEntry<int>>[
                        const CupertinoMenuItem<int>(
                          value: 1,
                          child: Text('1'),
                        ),
                      ],
                    );
                  },
                  child: const Text('Show Menu'),
                );
              },
            );
          },
        ),
      ),
    );

    // Open the dialog.
    await tester.tap(find.byType(CupertinoButton));

    expect(rootObserver.menuCount, 0);
    expect(nestedObserver.menuCount, 1);
  });

  testWidgets('showMenu uses root navigator if useRootNavigator is true',
      (WidgetTester tester) async {
    const String name = 'CupertinoMenu';
    final MenuObserver rootObserver = MenuObserver(observedRoute: name);
    final MenuObserver nestedObserver = MenuObserver(observedRoute: name);

    await tester.pumpWidget(
      CupertinoApp(
        navigatorObservers: <NavigatorObserver>[rootObserver],
        home: Navigator(
          observers: <NavigatorObserver>[nestedObserver],
          onGenerateRoute: (RouteSettings settings) {
            return CupertinoPageRoute<dynamic>(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () {
                    showCupertinoMenu<int>(
                      context: context,
                      settings: const RouteSettings(name: name),
                      itemBuilder: (BuildContext context) =>
                          <CupertinoMenuEntry<int>>[
                        const CupertinoMenuItem<int>(
                          value: 1,
                          child: Text('1'),
                        ),
                      ],
                      useRootNavigator: true,
                      anchorPosition: RelativeRect.fill,
                    );
                  },
                  child: const Text('Show Menu'),
                );
              },
            );
          },
        ),
      ),
    );

    // Open the dialog.
    await tester.tap(find.byType(ElevatedButton));

    await tester.pumpAndSettle();

    expect(rootObserver.menuCount, 1);
    expect(nestedObserver.menuCount, 0);

    // Close the dialog.
  });

  testWidgets('Can use GlobalKey to call CupertinoMenuButton.showMenu manually',
      (WidgetTester tester) async {
    final GlobalKey<CupertinoMenuButtonState<int>> globalKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Column(
            children: <Widget>[
              CupertinoMenuButton<int>(
                key: globalKey,
                itemBuilder: (BuildContext context) {
                  return <CupertinoMenuEntry<int>>[
                    const CupertinoMenuItem<int>(
                      value: 1,
                      child: Text('Tap me please!'),
                    ),
                  ];
                },
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Tap me please!'), findsNothing);

    globalKey.currentState!.showMenu();
    // The PopupMenuItem will appear after an animation, hence,
    // we have to first wait for the tester to settle.
    await tester.pumpAndSettle();

    expect(find.text('Tap me please!'), findsOneWidget);
  });

  testWidgets('CupertinoMenuItem changes mouse cursor when hovered',
      (WidgetTester tester) async {
    const Key key = ValueKey<int>(1);
    // Test PopupMenuItem() constructor
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: Material(
              child: MouseRegion(
                cursor: SystemMouseCursors.forbidden,
                child: CupertinoMenuItem<int>(
                  key: key,
                  mouseCursor: SystemMouseCursors.text,
                  value: 1,
                  child: Container(),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final TestGesture gesture =
        await tester.createGesture(kind: PointerDeviceKind.mouse, pointer: 1);
    await gesture.addPointer(location: tester.getCenter(find.byKey(key)));

    await tester.pump();

    expect(
      RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
      SystemMouseCursors.text,
    );

    // Test default cursor
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: Material(
              child: MouseRegion(
                cursor: SystemMouseCursors.forbidden,
                child: CupertinoMenuItem<int>(
                  key: key,
                  value: 1,
                  child: Container(),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
      SystemMouseCursors.click,
    );

    // Test default cursor when disabled. The cursor should defer to it's child.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: Material(
              child: MouseRegion(
                cursor: SystemMouseCursors.forbidden,
                child: CupertinoMenuItem<int>(
                  key: key,
                  value: 1,
                  enabled: false,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.basic,
                    child: Container(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
      SystemMouseCursors.basic,
    );
  });

  testWidgets('CupertinoCheckedMenuItem changes mouse cursor when hovered',
      (WidgetTester tester) async {
    const Key key = ValueKey<int>(1);
    // Test CheckedPopupMenuItem() constructor
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: Material(
              child: MouseRegion(
                cursor: SystemMouseCursors.forbidden,
                child: CupertinoCheckedMenuItem<int>(
                  key: key,
                  mouseCursor: SystemMouseCursors.text,
                  value: 1,
                  child: Container(),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final TestGesture gesture =
        await tester.createGesture(kind: PointerDeviceKind.mouse, pointer: 1);
    await gesture.addPointer(location: tester.getCenter(find.byKey(key)));
    addTearDown(gesture.removePointer);

    await tester.pump();

    expect(
      RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
      SystemMouseCursors.text,
    );

    // Test default cursor
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: Material(
              child: MouseRegion(
                cursor: SystemMouseCursors.forbidden,
                child: CupertinoCheckedMenuItem<int>(
                  key: key,
                  value: 1,
                  child: Container(),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
      SystemMouseCursors.click,
    );

    // Test default cursor when disabled
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: Material(
              child: MouseRegion(
                cursor: SystemMouseCursors.forbidden,
                child: CupertinoCheckedMenuItem<int>(
                  key: key,
                  value: 1,
                  enabled: false,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.basic,
                    child: Container(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    // The cursor should defer to it's child.
    expect(
      RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
      SystemMouseCursors.basic,
    );
  });

  testWidgets('PopupMenu in AppBar does not overlap with the status bar',
      (WidgetTester tester) async {
    const List<PopupMenuItem<int>> choices = <PopupMenuItem<int>>[
      PopupMenuItem<int>(value: 1, child: Text('Item 1')),
      PopupMenuItem<int>(value: 2, child: Text('Item 2')),
      PopupMenuItem<int>(value: 3, child: Text('Item 3')),
    ];

    const double statusBarHeight = 24.0;
    final PopupMenuItem<int> firstItem = choices[0];
    int selectedValue = choices[0].value!;

    await tester.pumpWidget(
      MaterialApp(
        builder: (BuildContext context, Widget? child) {
          return MediaQuery(
            data: const MediaQueryData(
              padding: EdgeInsets.only(top: statusBarHeight),
            ), // status bar
            child: child!,
          );
        },
        home: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('PopupMenu Test'),
                actions: <Widget>[
                  PopupMenuButton<int>(
                    onSelected: (int result) {
                      setState(() {
                        selectedValue = result;
                      });
                    },
                    initialValue: selectedValue,
                    itemBuilder: (BuildContext context) {
                      return choices;
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    // Tap third item.
    await tester.tap(find.text('Item 3'));
    await tester.pumpAndSettle();

    // Open popupMenu again.
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    // Check whether the first item is not overlapping with status bar.
    expect(
      tester.getTopLeft(find.byWidget(firstItem)).dy,
      greaterThan(statusBarHeight),
    );
  });

  testWidgets(
      'Vertically long PopupMenu does not overlap with the status bar and bottom notch',
      (WidgetTester tester) async {
    const double windowPaddingTop = 44;
    const double windowPaddingBottom = 34;

    await tester.pumpWidget(
      MaterialApp(
        builder: (BuildContext context, Widget? child) {
          return MediaQuery(
            data: const MediaQueryData(
              padding: EdgeInsets.only(
                top: windowPaddingTop,
                bottom: windowPaddingBottom,
              ),
            ),
            child: child!,
          );
        },
        home: Scaffold(
          appBar: AppBar(
            title: const Text('PopupMenu Test'),
          ),
          body: PopupMenuButton<int>(
            child: const Text('Show Menu'),
            itemBuilder: (BuildContext context) =>
                Iterable<PopupMenuItem<int>>.generate(
              20,
              (int i) => PopupMenuItem<int>(
                value: i,
                child: Text('Item $i'),
              ),
            ).toList(),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show Menu'));
    await tester.pumpAndSettle();

    final Offset topRightOfMenu =
        tester.getTopRight(find.byType(SingleChildScrollView));
    final Offset bottomRightOfMenu =
        tester.getBottomRight(find.byType(SingleChildScrollView));

    expect(topRightOfMenu.dy, windowPaddingTop + 8.0);
    expect(
      bottomRightOfMenu.dy,
      600.0 - windowPaddingBottom - 8.0,
    ); // Screen height is 600.
  });


  testWidgets("CupertinoMenuButton icon inherits IconTheme's size",
      (WidgetTester tester) async {
    Widget buildPopupMenu({double? themeIconSize, double? iconSize}) {
      return CupertinoApp(
        home: Scaffold(
          body: Center(
            child: IconTheme(
              data: IconThemeData(
                size: themeIconSize,
              ),
              child: CupertinoMenuButton<String>(
                child: Icon(
                  CupertinoIcons.square,
                  size: iconSize,
                ),
                itemBuilder: (_) => <CupertinoMenuEntry<String>>[
                  const CupertinoMenuItem<String>(
                    value: 'value',
                    child: Text('Item 0'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Popup menu with default icon size.
    await tester.pumpWidget(buildPopupMenu());
    // Default PopupMenuButton icon size is 24.0.
    expect(
      tester.getSize(find.byIcon(CupertinoIcons.square)),
      const Size(24.0, 24.0),
    );

    // Popup menu with custom theme icon size.
    await tester.pumpWidget(buildPopupMenu(themeIconSize: 30.0));
    await tester.pumpAndSettle();
    // PopupMenuButton icon inherits IconTheme's size.
    expect(
      tester.getSize(find.byIcon(CupertinoIcons.square)),
      const Size(30.0, 30.0),
    );

    // Popup menu with custom icon size.
    await tester
        .pumpWidget(buildPopupMenu(themeIconSize: 30.0, iconSize: 50.0));
    await tester.pumpAndSettle();
    // PopupMenuButton icon size overrides IconTheme's size.
    expect(
      tester.getSize(find.byIcon(CupertinoIcons.square)),
      const Size(50.0, 50.0),
    );
  });

  testWidgets('CupertinoMenuButton uses closed loop focus traversal',
      (WidgetTester tester) async {
    FocusNode nodeA() => Focus.of(find.text('A').evaluate().single);
    FocusNode nodeB() => Focus.of(find.text('B').evaluate().single);

    final GlobalKey popupButtonKey = GlobalKey();
    await tester.pumpWidget(
      CupertinoApp(
        home: Scaffold(
          body: Center(
            child: CupertinoMenuButton<String>(
              key: popupButtonKey,
              itemBuilder: (_) => const <CupertinoMenuEntry<String>>[
                CupertinoMenuItem<String>(
                  value: 'a',
                  child: Text('A'),
                ),
                CupertinoMenuItem<String>(
                  value: 'b',
                  child: Text('B'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Open the popup to build and show the menu contents.
    await tester.tap(find.byKey(popupButtonKey));
    await tester.pumpAndSettle();

    Future<bool> nextFocus() async {
      final bool result = Actions.invoke(
        primaryFocus!.context!,
        const NextFocusIntent(),
      )! as bool;
      await tester.pump();
      return result;
    }

    Future<bool> previousFocus() async {
      final bool result = Actions.invoke(
        primaryFocus!.context!,
        const PreviousFocusIntent(),
      )! as bool;
      await tester.pump();
      return result;
    }

    // Start at A
    nodeA().requestFocus();
    await tester.pump();
    expect(nodeA().hasFocus, true);
    expect(nodeB().hasFocus, false);

    // A -> B
    expect(await nextFocus(), true);
    expect(nodeA().hasFocus, false);
    expect(nodeB().hasFocus, true);

    // B -> A (wrap around)
    expect(await nextFocus(), true);
    expect(nodeA().hasFocus, true);
    expect(nodeB().hasFocus, false);

    // B <- A
    expect(await previousFocus(), true);
    expect(nodeA().hasFocus, false);
    expect(nodeB().hasFocus, true);

    // A <- B (wrap around)
    expect(await previousFocus(), true);
    expect(nodeA().hasFocus, true);
    expect(nodeB().hasFocus, false);
  });

  testWidgets('CupertinoNestedMenu uses closed loop focus traversal',
      (WidgetTester tester) async {
    final GlobalKey layerOneKey = GlobalKey();
    final GlobalKey layerTwoKey = GlobalKey();
    final GlobalKey layerThreeKey = GlobalKey();
    final Key nestedAnchorKey = UniqueKey();
    FocusNode nodeA() => Focus.of(
          find
              .descendant(
                of: find.byKey(nestedAnchorKey),
                matching: find.text('A2', findRichText: true),
              )
              .evaluate()
              .first,
        );

    FocusNode nodeB() => Focus.of(find.text('B3').evaluate().first);

    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: CupertinoMenuButton<String>(
            key: layerOneKey,
            itemBuilder: (_) => <CupertinoMenuEntry<String>>[
              CupertinoNestedMenu<String>(
                key: layerTwoKey,
                title: const TextSpan(text: 'a1'),
                itemBuilder: (_) => <CupertinoMenuEntry<String>>[
                  CupertinoNestedMenu<String>(
                    key: layerThreeKey,
                    expandedMenuAnchorKey: nestedAnchorKey,
                    title: const TextSpan(text: 'A2'),
                    itemBuilder: (_) => <CupertinoMenuEntry<String>>[
                      const CupertinoMenuItem<String>(
                        value: 'b3',
                        child: Text('B3'),
                      ),
                    ],
                  ),
                  const CupertinoMenuItem<String>(
                    value: 'b2',
                    child: Text('B2'),
                  ),
                  const CupertinoMenuItem<String>(
                    value: 'c2',
                    child: Text('C2'),
                  ),
                ],
              ),
              const CupertinoMenuItem<String>(
                value: 'b1',
                child: Text('B1'),
              ),
              const CupertinoMenuItem<String>(
                value: 'c1',
                child: Text('c1'),
              ),
            ],
          ),
        ),
      ),
    );

    // Open the popup to build and show the menu contents.
    await tester.tap(find.byKey(layerOneKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(layerTwoKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(layerThreeKey));
    await tester.pumpAndSettle();

    Future<bool> nextFocus() async {
      final bool result = Actions.invoke(
        primaryFocus!.context!,
        const NextFocusIntent(),
      )! as bool;
      await tester.pump();
      return result;
    }

    Future<bool> previousFocus() async {
      final bool result = Actions.invoke(
        primaryFocus!.context!,
        const PreviousFocusIntent(),
      )! as bool;
      await tester.pump();
      return result;
    }

    // Start at A
    nodeA().requestFocus();
    await tester.pump();
    expect(nodeA().hasFocus, true);
    expect(nodeB().hasFocus, false);

    // A -> B
    expect(await nextFocus(), true);
    expect(nodeA().hasFocus, false);
    expect(nodeB().hasFocus, true);

    // B -> A (wrap around)
    expect(await nextFocus(), true);
    expect(nodeA().hasFocus, true);
    expect(nodeB().hasFocus, false);

    // B <- A
    expect(await previousFocus(), true);
    expect(nodeA().hasFocus, false);
    expect(nodeB().hasFocus, true);

    // A <- B (wrap around)
    expect(await previousFocus(), true);
    expect(nodeA().hasFocus, true);
    expect(nodeB().hasFocus, false);
  });

  testWidgets('showCupertinoMenu with RouteSettings',
      (WidgetTester tester) async {
    late RouteSettings currentRouteSetting;

    await tester.pumpWidget(
      CupertinoApp(
        navigatorObservers: <NavigatorObserver>[
          _ClosureNavigatorObserver(
            onDidChange: (Route<dynamic> newRoute) {
              currentRouteSetting = newRoute.settings;
            },
          ),
        ],
        home: const Center(
          child: CupertinoButton(
            onPressed: null,
            child: Text('Go'),
          ),
        ),
      ),
    );

    final BuildContext context = tester.element(find.text('Go'));
    const RouteSettings exampleSetting = RouteSettings(name: 'simple');

    showCupertinoMenu<void>(
      itemBuilder: (_) => const <CupertinoMenuEntry<void>>[
        CupertinoMenuItem<void>(child: Text('foo')),
      ],
      settings: exampleSetting,
      context: context,
      anchorPosition: RelativeRect.fill,
    );

    await tester.pumpAndSettle();
    expect(find.text('foo'), findsOneWidget);
    expect(currentRouteSetting, exampleSetting);

    await tester.tap(find.text('foo'));
    await tester.pumpAndSettle();
    expect(currentRouteSetting.name, '/');
  });
}

class TestApp extends StatelessWidget {
  const TestApp({
    super.key,
    required this.textDirection,
    this.child,
  });

  final TextDirection textDirection;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Localizations(
      locale: const Locale('en', 'US'),
      delegates: const <LocalizationsDelegate<dynamic>>[
        DefaultWidgetsLocalizations.delegate,
        DefaultMaterialLocalizations.delegate,
      ],
      child: MediaQuery(
        data: MediaQueryData.fromView(View.of(context)),
        child: Directionality(
          textDirection: textDirection,
          child: Navigator(
            onGenerateRoute: (RouteSettings settings) {
              assert(settings.name == '/');
              return CupertinoPageRoute<void>(
                settings: settings,
                builder: (BuildContext context) => child!,
              );
            },
          ),
        ),
      ),
    );
  }
}

class MenuObserver extends NavigatorObserver {
  MenuObserver({required this.observedRoute});
  final String observedRoute;
  int menuCount = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route.settings.name?.contains(observedRoute) ?? false) {
      menuCount++;
    }
    super.didPush(route, previousRoute);
  }
}

class _ClosureNavigatorObserver extends NavigatorObserver {
  _ClosureNavigatorObserver({required this.onDidChange});

  final void Function(Route<dynamic> newRoute) onDidChange;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      onDidChange(route);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      onDidChange(previousRoute!);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      onDidChange(previousRoute!);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      onDidChange(newRoute!);
}
