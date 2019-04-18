// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ExpansionPanelList test', (WidgetTester tester) async {
    int index;
    bool isExpanded;

    await tester.pumpWidget(
      MaterialApp(
        home: SingleChildScrollView(
          child: ExpansionPanelList(
            expansionCallback: (int _index, bool _isExpanded) {
              index = _index;
              isExpanded = _isExpanded;
            },
            children: <ExpansionPanel>[
              ExpansionPanel(
                headerBuilder: (BuildContext context, bool isExpanded) {
                  return Text(isExpanded ? 'B' : 'A');
                },
                body: const SizedBox(height: 100.0),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsNothing);
    RenderBox box = tester.renderObject(find.byType(ExpansionPanelList));
    final double oldHeight = box.size.height;
    expect(find.byType(ExpandIcon), findsOneWidget);
    await tester.tap(find.byType(ExpandIcon));
    expect(index, 0);
    expect(isExpanded, isFalse);
    box = tester.renderObject(find.byType(ExpansionPanelList));
    expect(box.size.height, equals(oldHeight));

    // now expand the child panel
    await tester.pumpWidget(
      MaterialApp(
        home: SingleChildScrollView(
          child: ExpansionPanelList(
            expansionCallback: (int _index, bool _isExpanded) {
              index = _index;
              isExpanded = _isExpanded;
            },
            children: <ExpansionPanel>[
              ExpansionPanel(
                headerBuilder: (BuildContext context, bool isExpanded) {
                  return Text(isExpanded ? 'B' : 'A');
                },
                body: const SizedBox(height: 100.0),
                isExpanded: true, // this is the addition
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('A'), findsNothing);
    expect(find.text('B'), findsOneWidget);
    box = tester.renderObject(find.byType(ExpansionPanelList));
    expect(box.size.height - oldHeight, greaterThanOrEqualTo(100.0)); // 100 + some margin
  });

  testWidgets('Multiple Panel List test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ListView(
          children: <ExpansionPanelList>[
            ExpansionPanelList(
              children: <ExpansionPanel>[
                ExpansionPanel(
                  headerBuilder: (BuildContext context, bool isExpanded) {
                    return Text(isExpanded ? 'B' : 'A');
                  },
                  body: const SizedBox(height: 100.0),
                  isExpanded: true,
                ),
              ],
            ),
            ExpansionPanelList(
              children: <ExpansionPanel>[
                ExpansionPanel(
                  headerBuilder: (BuildContext context, bool isExpanded) {
                    return Text(isExpanded ? 'D' : 'C');
                  },
                  body: const SizedBox(height: 100.0),
                  isExpanded: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('A'), findsNothing);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('C'), findsNothing);
    expect(find.text('D'), findsOneWidget);
  });

  testWidgets('Open/close animations', (WidgetTester tester) async {
    const Duration kSizeAnimationDuration = Duration(milliseconds: 1000);
    // The MaterialGaps animate in using kThemeAnimationDuration (hardcoded),
    // which should be less than our test size animation length. So we can assume that they
    // appear immediately. Here we just verify that our assumption is true.
    expect(kThemeAnimationDuration, lessThan(kSizeAnimationDuration ~/ 2));

    Widget build(bool a, bool b, bool c) {
      return MaterialApp(
        home: Column(
          children: <Widget>[
            ExpansionPanelList(
              animationDuration: kSizeAnimationDuration,
              children: <ExpansionPanel>[
                ExpansionPanel(
                  headerBuilder: (BuildContext context, bool isExpanded) => const Placeholder(
                    fallbackHeight: 12.0,
                  ),
                  body: const SizedBox(height: 100.0, child: Placeholder(
                    fallbackHeight: 12.0,
                  )),
                  isExpanded: a,
                ),
                ExpansionPanel(
                  headerBuilder: (BuildContext context, bool isExpanded) => const Placeholder(
                    fallbackHeight: 12.0,
                  ),
                  body: const SizedBox(height: 100.0, child: Placeholder()),
                  isExpanded: b,
                ),
                ExpansionPanel(
                  headerBuilder: (BuildContext context, bool isExpanded) => const Placeholder(
                    fallbackHeight: 12.0,
                  ),
                  body: const SizedBox(height: 100.0, child: Placeholder()),
                  isExpanded: c,
                ),
              ],
            ),
          ],
        ),
      );
    }

    await tester.pumpWidget(build(false, false, false));
    expect(tester.renderObjectList(find.byType(AnimatedSize)), hasLength(3));
    expect(tester.getRect(find.byType(AnimatedSize).at(0)), Rect.fromLTWH(0.0, 56.0, 800.0, 0.0));
    expect(tester.getRect(find.byType(AnimatedSize).at(1)), Rect.fromLTWH(0.0, 113.0, 800.0, 0.0));
    expect(tester.getRect(find.byType(AnimatedSize).at(2)), Rect.fromLTWH(0.0, 170.0, 800.0, 0.0));

    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.getRect(find.byType(AnimatedSize).at(0)), Rect.fromLTWH(0.0, 56.0, 800.0, 0.0));
    expect(tester.getRect(find.byType(AnimatedSize).at(1)), Rect.fromLTWH(0.0, 113.0, 800.0, 0.0));
    expect(tester.getRect(find.byType(AnimatedSize).at(2)), Rect.fromLTWH(0.0, 170.0, 800.0, 0.0));

    await tester.pumpWidget(build(false, true, false));
    expect(tester.getRect(find.byType(AnimatedSize).at(0)), Rect.fromLTWH(0.0, 56.0, 800.0, 0.0));
    expect(tester.getRect(find.byType(AnimatedSize).at(1)), Rect.fromLTWH(0.0, 113.0, 800.0, 0.0));
    expect(tester.getRect(find.byType(AnimatedSize).at(2)), Rect.fromLTWH(0.0, 170.0, 800.0, 0.0));

    await tester.pump(kSizeAnimationDuration ~/ 2);
    expect(tester.getRect(find.byType(AnimatedSize).at(0)), Rect.fromLTWH(0.0, 56.0, 800.0, 0.0));
    final Rect rect1 = tester.getRect(find.byType(AnimatedSize).at(1));
    expect(rect1.left, 0.0);
    expect(rect1.top, inExclusiveRange(113.0, 113.0 + 16.0 + 32.0)); // 16.0 material gap, plus 16.0 top and bottom margins added to the header
    expect(rect1.width, 800.0);
    expect(rect1.height, inExclusiveRange(0.0, 100.0));
    final Rect rect2 = tester.getRect(find.byType(AnimatedSize).at(2));
    expect(rect2, Rect.fromLTWH(0.0, rect1.bottom + 16.0 + 56.0, 800.0, 0.0)); // the 16.0 comes from the MaterialGap being introduced, the 56.0 is the header height.

    await tester.pumpWidget(build(false, false, false));
    expect(tester.getRect(find.byType(AnimatedSize).at(0)), Rect.fromLTWH(0.0, 56.0, 800.0, 0.0));
    expect(tester.getRect(find.byType(AnimatedSize).at(1)), rect1);
    expect(tester.getRect(find.byType(AnimatedSize).at(2)), rect2);

    await tester.pumpWidget(build(false, false, true));
    expect(tester.getRect(find.byType(AnimatedSize).at(0)), Rect.fromLTWH(0.0, 56.0, 800.0, 0.0));
    expect(tester.getRect(find.byType(AnimatedSize).at(1)), rect1);
    expect(tester.getRect(find.byType(AnimatedSize).at(2)), rect2);

    // a few no-op pumps to make sure there's nothing fishy going on
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(tester.getRect(find.byType(AnimatedSize).at(0)), Rect.fromLTWH(0.0, 56.0, 800.0, 0.0));
    expect(tester.getRect(find.byType(AnimatedSize).at(1)), rect1);
    expect(tester.getRect(find.byType(AnimatedSize).at(2)), rect2);

    await tester.pumpAndSettle();
    expect(tester.getRect(find.byType(AnimatedSize).at(0)), Rect.fromLTWH(0.0, 56.0, 800.0, 0.0));
    expect(tester.getRect(find.byType(AnimatedSize).at(1)), Rect.fromLTWH(0.0, 56.0 + 1.0 + 56.0, 800.0, 0.0));
    expect(tester.getRect(find.byType(AnimatedSize).at(2)), Rect.fromLTWH(0.0, 56.0 + 1.0 + 56.0 + 16.0 + 16.0 + 48.0 + 16.0, 800.0, 100.0));
  });

  testWidgets('Radio mode has max of one panel open at a time',  (WidgetTester tester) async {
    final List<ExpansionPanel> _demoItemsRadio = <ExpansionPanelRadio>[
      ExpansionPanelRadio(
        headerBuilder: (BuildContext context, bool isExpanded) {
          return Text(isExpanded ? 'B' : 'A');
        },
        body: const SizedBox(height: 100.0),
        value: 0,
      ),
      ExpansionPanelRadio(
        headerBuilder: (BuildContext context, bool isExpanded) {
          return Text(isExpanded ? 'D' : 'C');
        },
        body: const SizedBox(height: 100.0),
        value: 1,
      ),
      ExpansionPanelRadio(
        headerBuilder: (BuildContext context, bool isExpanded) {
          return Text(isExpanded ? 'F' : 'E');
        },
        body: const SizedBox(height: 100.0),
        value: 2,
      ),
    ];

    final ExpansionPanelList _expansionListRadio = ExpansionPanelList.radio(
      children: _demoItemsRadio,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SingleChildScrollView(
          child: _expansionListRadio,
        ),
      ),
    );

    // Initializes with all panels closed
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsNothing);
    expect(find.text('C'), findsOneWidget);
    expect(find.text('D'), findsNothing);
    expect(find.text('E'), findsOneWidget);
    expect(find.text('F'), findsNothing);

    RenderBox box = tester.renderObject(find.byType(ExpansionPanelList));
    double oldHeight = box.size.height;

    expect(find.byType(ExpandIcon), findsNWidgets(3));

    await tester.tap(find.byType(ExpandIcon).at(0));

    box = tester.renderObject(find.byType(ExpansionPanelList));
    expect(box.size.height, equals(oldHeight));

    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    // Now the first panel is open
    expect(find.text('A'), findsNothing);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
    expect(find.text('D'), findsNothing);
    expect(find.text('E'), findsOneWidget);
    expect(find.text('F'), findsNothing);

    box = tester.renderObject(find.byType(ExpansionPanelList));
    expect(box.size.height - oldHeight, greaterThanOrEqualTo(100.0)); // 100 + some margin

    await tester.tap(find.byType(ExpandIcon).at(1));

    box = tester.renderObject(find.byType(ExpansionPanelList));
    oldHeight = box.size.height;

    await tester.pump(const Duration(milliseconds: 200));

    // Now the first panel is closed and the second should be opened
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsNothing);
    expect(find.text('C'), findsNothing);
    expect(find.text('D'), findsOneWidget);
    expect(find.text('E'), findsOneWidget);
    expect(find.text('F'), findsNothing);

    expect(box.size.height, greaterThanOrEqualTo(oldHeight));

    _demoItemsRadio.removeAt(0);

    await tester.pumpAndSettle();

    // Now the first panel should be opened
    expect(find.text('C'), findsNothing);
    expect(find.text('D'), findsOneWidget);
    expect(find.text('E'), findsOneWidget);
    expect(find.text('F'), findsNothing);


    final List<ExpansionPanel> _demoItems = <ExpansionPanel>[
      ExpansionPanel(
        headerBuilder: (BuildContext context, bool isExpanded) {
          return Text(isExpanded ? 'B' : 'A');
        },
        body: const SizedBox(height: 100.0),
        isExpanded: false,
      ),
      ExpansionPanel(
        headerBuilder: (BuildContext context, bool isExpanded) {
          return Text(isExpanded ? 'D' : 'C');
        },
        body: const SizedBox(height: 100.0),
        isExpanded: false,
      ),
      ExpansionPanel(
        headerBuilder: (BuildContext context, bool isExpanded) {
          return Text(isExpanded ? 'F' : 'E');
        },
        body: const SizedBox(height: 100.0),
        isExpanded: false,
      ),
    ];

    final ExpansionPanelList _expansionList = ExpansionPanelList(
      children: _demoItems,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SingleChildScrollView(
          child: _expansionList,
        ),
      ),
    );

    // We've reinitialized with a regular expansion panel so they should all be closed again
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsNothing);
    expect(find.text('C'), findsOneWidget);
    expect(find.text('D'), findsNothing);
    expect(find.text('E'), findsOneWidget);
    expect(find.text('F'), findsNothing);
  });

  testWidgets('Radio mode calls expansionCallback once if other panels closed', (WidgetTester tester) async {
    final List<ExpansionPanel> _demoItemsRadio = <ExpansionPanelRadio>[
      ExpansionPanelRadio(
        headerBuilder: (BuildContext context, bool isExpanded) {
          return Text(isExpanded ? 'B' : 'A');
        },
        body: const SizedBox(height: 100.0),
        value: 0,
      ),
      ExpansionPanelRadio(
        headerBuilder: (BuildContext context, bool isExpanded) {
          return Text(isExpanded ? 'D' : 'C');
        },
        body: const SizedBox(height: 100.0),
        value: 1,
      ),
      ExpansionPanelRadio(
        headerBuilder: (BuildContext context, bool isExpanded) {
          return Text(isExpanded ? 'F' : 'E');
        },
        body: const SizedBox(height: 100.0),
        value: 2,
      ),
    ];

    final List<Map<String, dynamic>> callbackHistory = <Map<String, dynamic>>[];
    Map<String, dynamic> latestCall;

    final ExpansionPanelList _expansionListRadio = ExpansionPanelList.radio(
      expansionCallback: (int _index, bool _isExpanded) {
        callbackHistory.add(<String, dynamic>{
          'index': _index,
          'isExpanded': _isExpanded,
        });
      },
      children: _demoItemsRadio,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SingleChildScrollView(
          child: _expansionListRadio,
        ),
      ),
    );

    // Initializes with all panels closed
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsNothing);
    expect(find.text('C'), findsOneWidget);
    expect(find.text('D'), findsNothing);
    expect(find.text('E'), findsOneWidget);
    expect(find.text('F'), findsNothing);

    // open one panel
    await tester.tap(find.byType(ExpandIcon).at(1));
    await tester.pumpAndSettle();

    // callback is invoked once with appropriate arguments
    expect(callbackHistory.length, equals(1));
    latestCall = callbackHistory[callbackHistory.length - 1];
    expect(latestCall['index'], equals(1));
    expect(latestCall['isExpanded'], equals(false));

    // close the same panel
    await tester.tap(find.byType(ExpandIcon).at(1));
    await tester.pumpAndSettle();

    // callback is invoked once with appropriate arguments
    expect(callbackHistory.length, equals(2));
    latestCall = callbackHistory[callbackHistory.length - 1];
    expect(latestCall['index'], equals(1));
    expect(latestCall['isExpanded'], equals(true));
  });

  testWidgets('Radio mode calls expansionCallback twice if other panel open prior', (WidgetTester tester) async {
    final List<ExpansionPanel> _demoItemsRadio = <ExpansionPanelRadio>[
      ExpansionPanelRadio(
        headerBuilder: (BuildContext context, bool isExpanded) {
          return Text(isExpanded ? 'B' : 'A');
        },
        body: const SizedBox(height: 100.0),
        value: 0,
      ),
      ExpansionPanelRadio(
        headerBuilder: (BuildContext context, bool isExpanded) {
          return Text(isExpanded ? 'D' : 'C');
        },
        body: const SizedBox(height: 100.0),
        value: 1,
      ),
      ExpansionPanelRadio(
        headerBuilder: (BuildContext context, bool isExpanded) {
          return Text(isExpanded ? 'F' : 'E');
        },
        body: const SizedBox(height: 100.0),
        value: 2,
      ),
    ];

    final List<Map<String, dynamic>> callbackHistory = <Map<String, dynamic>>[];
    Map<String, dynamic> callbackResults;

    final ExpansionPanelList _expansionListRadio = ExpansionPanelList.radio(
      expansionCallback: (int _index, bool _isExpanded) {
        callbackHistory.add(<String, dynamic>{
          'index': _index,
          'isExpanded': _isExpanded,
        });
      },
      children: _demoItemsRadio,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SingleChildScrollView(
          child: _expansionListRadio,
        ),
      ),
    );

    // Initializes with all panels closed
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsNothing);
    expect(find.text('C'), findsOneWidget);
    expect(find.text('D'), findsNothing);
    expect(find.text('E'), findsOneWidget);
    expect(find.text('F'), findsNothing);

    // open one panel
    await tester.tap(find.byType(ExpandIcon).at(1));
    await tester.pumpAndSettle();

    // callback is invoked once with appropriate arguments
    expect(callbackHistory.length, equals(1));
    callbackResults = callbackHistory[callbackHistory.length - 1];
    expect(callbackResults['index'], equals(1));
    expect(callbackResults['isExpanded'], equals(false));

    // close a different panel
    await tester.tap(find.byType(ExpandIcon).at(2));
    await tester.pumpAndSettle();

    // callback is invoked the first time with correct arguments
    expect(callbackHistory.length, equals(3));
    callbackResults = callbackHistory[callbackHistory.length - 2];
    expect(callbackResults['index'], equals(2));
    expect(callbackResults['isExpanded'], equals(false));

    // callback is invoked the second time with correct arguments
    callbackResults = callbackHistory[callbackHistory.length - 1];
    expect(callbackResults['index'], equals(1));
    expect(callbackResults['isExpanded'], equals(false));
  });

  testWidgets('No duplicate global keys at layout/build time', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/13780
  });

  testWidgets('Panel header has semantics', (WidgetTester tester) async {
    const Key expandedKey = Key('expanded');
    const Key collapsedKey = Key('collapsed');
    const DefaultMaterialLocalizations localizations = DefaultMaterialLocalizations();
    final SemanticsHandle handle = tester.ensureSemantics();
    final List<ExpansionPanel> _demoItems = <ExpansionPanel>[
      ExpansionPanel(
        headerBuilder: (BuildContext context, bool isExpanded) {
          return const Text('Expanded', key: expandedKey);
        },
        body: const SizedBox(height: 100.0),
        isExpanded: true,
      ),
      ExpansionPanel(
        headerBuilder: (BuildContext context, bool isExpanded) {
          return const Text('Collapsed', key: collapsedKey);
        },
        body: const SizedBox(height: 100.0),
        isExpanded: false,
      ),
    ];

    final ExpansionPanelList _expansionList = ExpansionPanelList(
      children: _demoItems,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SingleChildScrollView(
          child: _expansionList,
        ),
      ),
    );

    expect(tester.getSemantics(find.byKey(expandedKey)), matchesSemantics(
      label: 'Expanded',
      isButton: true,
      hasEnabledState: true,
      isEnabled: true,
      hasTapAction: true,
      onTapHint: localizations.expandedIconTapHint,
    ));

    expect(tester.getSemantics(find.byKey(collapsedKey)), matchesSemantics(
      label: 'Collapsed',
      isButton: true,
      hasEnabledState: true,
      isEnabled: true,
      hasTapAction: true,
      onTapHint: localizations.collapsedIconTapHint,
    ));

    handle.dispose();
  });
}
