// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class SimpleExpansionPanelListTestWidget extends StatefulWidget {
  const SimpleExpansionPanelListTestWidget({
    Key? key,
    this.firstPanelKey,
    this.secondPanelKey,
    this.canTapOnHeader = false,
    this.expandedHeaderPadding,
    this.dividerColor,
    this.elevation = 2,
  }) : super(key: key);

  final Key? firstPanelKey;
  final Key? secondPanelKey;
  final bool canTapOnHeader;
  final Color? dividerColor;
  final double elevation;

  /// If null, the default [ExpansionPanelList]'s expanded header padding value is applied via [defaultExpandedHeaderPadding]
  final EdgeInsets? expandedHeaderPadding;

  /// Mirrors the default expanded header padding as its source constants are private.
  static EdgeInsets defaultExpandedHeaderPadding()
  {
    return const ExpansionPanelList().expandedHeaderPadding;
  }

  @override
  State<SimpleExpansionPanelListTestWidget> createState() => _SimpleExpansionPanelListTestWidgetState();
}

class _SimpleExpansionPanelListTestWidgetState extends State<SimpleExpansionPanelListTestWidget> {
  List<bool> extendedState = <bool>[false, false];

  @override
  Widget build(BuildContext context) {
    return ExpansionPanelList(
      expandedHeaderPadding: widget.expandedHeaderPadding ?? SimpleExpansionPanelListTestWidget.defaultExpandedHeaderPadding(),
      expansionCallback: (int _index, bool _isExpanded) {
        setState(() {
          extendedState[_index] = !extendedState[_index];
        });
      },
      dividerColor: widget.dividerColor,
      elevation: widget.elevation,
      children: <ExpansionPanel>[
        ExpansionPanel(
          headerBuilder: (BuildContext context, bool isExpanded) {
            return Text(isExpanded ? 'B' : 'A', key: widget.firstPanelKey);
          },
          body: const SizedBox(height: 100.0),
          canTapOnHeader: widget.canTapOnHeader,
          isExpanded: extendedState[0],
        ),
        ExpansionPanel(
          headerBuilder: (BuildContext context, bool isExpanded) {
            return Text(isExpanded ? 'D' : 'C', key: widget.secondPanelKey);
          },
          body: const SizedBox(height: 100.0),
          canTapOnHeader: widget.canTapOnHeader,
          isExpanded: extendedState[1],
        ),
      ],
    );
  }
}

class ExpansionPanelListSemanticsTest extends StatefulWidget {
  const ExpansionPanelListSemanticsTest({ Key? key, required this.headerKey }) : super(key: key);

  final Key headerKey;

  @override
  ExpansionPanelListSemanticsTestState createState() => ExpansionPanelListSemanticsTestState();
}

class ExpansionPanelListSemanticsTestState extends State<ExpansionPanelListSemanticsTest> {
  bool headerTapped = false;
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        ExpansionPanelList(
          children: <ExpansionPanel>[
            ExpansionPanel(
              canTapOnHeader: false,
              headerBuilder: (BuildContext context, bool isExpanded) {
                return MergeSemantics(
                  key: widget.headerKey,
                  child: GestureDetector(
                    onTap: () => headerTapped = true,
                    child: const Text.rich(
                      TextSpan(
                        text:'head1',
                      ),
                    ),
                  ),
                );
              },
              body: const Placeholder(),
            ),
          ],
        ),
      ],
    );
  }
}

void main() {
  testWidgets('ExpansionPanelList test', (WidgetTester tester) async {
    late int index;
    late bool isExpanded;

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

    // Now, expand the child panel.
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

  testWidgets('ExpansionPanelList does not merge header when canTapOnHeader is false', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    final Key headerKey = UniqueKey();
    await tester.pumpWidget(
      MaterialApp(
        home: ExpansionPanelListSemanticsTest(headerKey: headerKey),
      ),
    );

    // Make sure custom gesture detector widget is clickable.
    await tester.tap(find.text('head1'));
    await tester.pump();

    final ExpansionPanelListSemanticsTestState state =
      tester.state(find.byType(ExpansionPanelListSemanticsTest));
    expect(state.headerTapped, true);

    // Check the expansion icon semantics does not merged with header widget.
    final Finder expansionIcon = find.descendant(
      of: find.ancestor(
        of: find.byKey(headerKey),
        matching: find.byType(Row),
      ),
      matching: find.byType(ExpandIcon),
    );
    expect(tester.getSemantics(expansionIcon), matchesSemantics(
      label: 'Expand',
      isButton: true,
      hasEnabledState: true,
      isEnabled: true,
      isFocusable: true,
      hasTapAction: true,
    ));

    // Check custom header widget semantics is preserved.
    final Finder headerWidget = find.descendant(
      of: find.byKey(headerKey),
      matching: find.byType(RichText),
    );
    expect(tester.getSemantics(headerWidget), matchesSemantics(
      label: 'head1',
      hasTapAction: true,
    ));

    handle.dispose();
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
    expect(tester.getRect(find.byType(AnimatedSize).at(0)), const Rect.fromLTWH(0.0, 56.0, 800.0, 0.0));
    expect(tester.getRect(find.byType(AnimatedSize).at(1)), const Rect.fromLTWH(0.0, 113.0, 800.0, 0.0));
    expect(tester.getRect(find.byType(AnimatedSize).at(2)), const Rect.fromLTWH(0.0, 170.0, 800.0, 0.0));

    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.getRect(find.byType(AnimatedSize).at(0)), const Rect.fromLTWH(0.0, 56.0, 800.0, 0.0));
    expect(tester.getRect(find.byType(AnimatedSize).at(1)), const Rect.fromLTWH(0.0, 113.0, 800.0, 0.0));
    expect(tester.getRect(find.byType(AnimatedSize).at(2)), const Rect.fromLTWH(0.0, 170.0, 800.0, 0.0));

    await tester.pumpWidget(build(false, true, false));
    expect(tester.getRect(find.byType(AnimatedSize).at(0)), const Rect.fromLTWH(0.0, 56.0, 800.0, 0.0));
    expect(tester.getRect(find.byType(AnimatedSize).at(1)), const Rect.fromLTWH(0.0, 113.0, 800.0, 0.0));
    expect(tester.getRect(find.byType(AnimatedSize).at(2)), const Rect.fromLTWH(0.0, 170.0, 800.0, 0.0));

    await tester.pump(kSizeAnimationDuration ~/ 2);
    expect(tester.getRect(find.byType(AnimatedSize).at(0)), const Rect.fromLTWH(0.0, 56.0, 800.0, 0.0));
    final Rect rect1 = tester.getRect(find.byType(AnimatedSize).at(1));
    expect(rect1.left, 0.0);
    expect(rect1.top, inExclusiveRange(113.0, 113.0 + 16.0 + 32.0)); // 16.0 material gap, plus 16.0 top and bottom margins added to the header
    expect(rect1.width, 800.0);
    expect(rect1.height, inExclusiveRange(0.0, 100.0));
    final Rect rect2 = tester.getRect(find.byType(AnimatedSize).at(2));
    expect(rect2, Rect.fromLTWH(0.0, rect1.bottom + 16.0 + 56.0, 800.0, 0.0)); // the 16.0 comes from the MaterialGap being introduced, the 56.0 is the header height.

    await tester.pumpWidget(build(false, false, false));
    expect(tester.getRect(find.byType(AnimatedSize).at(0)), const Rect.fromLTWH(0.0, 56.0, 800.0, 0.0));
    expect(tester.getRect(find.byType(AnimatedSize).at(1)), rect1);
    expect(tester.getRect(find.byType(AnimatedSize).at(2)), rect2);

    await tester.pumpWidget(build(false, false, true));
    expect(tester.getRect(find.byType(AnimatedSize).at(0)), const Rect.fromLTWH(0.0, 56.0, 800.0, 0.0));
    expect(tester.getRect(find.byType(AnimatedSize).at(1)), rect1);
    expect(tester.getRect(find.byType(AnimatedSize).at(2)), rect2);

    // a few no-op pumps to make sure there's nothing fishy going on
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(tester.getRect(find.byType(AnimatedSize).at(0)), const Rect.fromLTWH(0.0, 56.0, 800.0, 0.0));
    expect(tester.getRect(find.byType(AnimatedSize).at(1)), rect1);
    expect(tester.getRect(find.byType(AnimatedSize).at(2)), rect2);

    await tester.pumpAndSettle();
    expect(tester.getRect(find.byType(AnimatedSize).at(0)), const Rect.fromLTWH(0.0, 56.0, 800.0, 0.0));
    expect(tester.getRect(find.byType(AnimatedSize).at(1)), const Rect.fromLTWH(0.0, 56.0 + 1.0 + 56.0, 800.0, 0.0));
    expect(tester.getRect(find.byType(AnimatedSize).at(2)), const Rect.fromLTWH(0.0, 56.0 + 1.0 + 56.0 + 16.0 + 16.0 + 48.0 + 16.0, 800.0, 100.0));
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

    // Open one panel
    await tester.tap(find.byType(ExpandIcon).at(1));
    await tester.pumpAndSettle();

    // Callback is invoked once with appropriate arguments
    expect(callbackHistory.length, equals(1));
    expect(callbackHistory.last['index'], equals(1));
    expect(callbackHistory.last['isExpanded'], equals(false));

    // Close the same panel
    await tester.tap(find.byType(ExpandIcon).at(1));
    await tester.pumpAndSettle();

    // Callback is invoked once with appropriate arguments
    expect(callbackHistory.length, equals(2));
    expect(callbackHistory.last['index'], equals(1));
    expect(callbackHistory.last['isExpanded'], equals(true));
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

    // Open one panel
    await tester.tap(find.byType(ExpandIcon).at(1));
    await tester.pumpAndSettle();

    // Callback is invoked once with appropriate arguments
    expect(callbackHistory.length, equals(1));
    callbackResults = callbackHistory[callbackHistory.length - 1];
    expect(callbackResults['index'], equals(1));
    expect(callbackResults['isExpanded'], equals(false));

    // Close a different panel
    await tester.tap(find.byType(ExpandIcon).at(2));
    await tester.pumpAndSettle();

    // Callback is invoked the first time with correct arguments
    expect(callbackHistory.length, equals(3));
    callbackResults = callbackHistory[callbackHistory.length - 2];
    expect(callbackResults['index'], equals(2));
    expect(callbackResults['isExpanded'], equals(false));

    // Callback is invoked the second time with correct arguments
    callbackResults = callbackHistory[callbackHistory.length - 1];
    expect(callbackResults['index'], equals(1));
    expect(callbackResults['isExpanded'], equals(false));
  });

  testWidgets(
    'didUpdateWidget accounts for toggling between ExpansionPanelList '
    'and ExpansionPaneList.radio',
    (WidgetTester tester) async {
      bool isRadioList = false;
      final List<bool> _panelExpansionState = <bool>[
        false,
        false,
        false,
      ];

      ExpansionPanelList buildRadioExpansionPanelList() {
        return ExpansionPanelList.radio(
          initialOpenPanelValue: 2,
          children: <ExpansionPanelRadio>[
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
          ],
        );
      }

      ExpansionPanelList buildExpansionPanelList(StateSetter setState) {
        return ExpansionPanelList(
          expansionCallback: (int index, _) => setState(() { _panelExpansionState[index] = !_panelExpansionState[index]; }),
          children: <ExpansionPanel>[
            ExpansionPanel(
              isExpanded: _panelExpansionState[0],
              headerBuilder: (BuildContext context, bool isExpanded) {
                return Text(isExpanded ? 'B' : 'A');
              },
              body: const SizedBox(height: 100.0),
            ),
            ExpansionPanel(
              isExpanded: _panelExpansionState[1],
              headerBuilder: (BuildContext context, bool isExpanded) {
                return Text(isExpanded ? 'D' : 'C');
              },
              body: const SizedBox(height: 100.0),
            ),
            ExpansionPanel(
              isExpanded: _panelExpansionState[2],
              headerBuilder: (BuildContext context, bool isExpanded) {
                return Text(isExpanded ? 'F' : 'E');
              },
              body: const SizedBox(height: 100.0),
            ),
          ],
        );
      }

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: isRadioList
                    ? buildRadioExpansionPanelList()
                    : buildExpansionPanelList(setState),
                ),
                floatingActionButton: FloatingActionButton(
                  onPressed: () => setState(() { isRadioList = !isRadioList; }),
                ),
              ),
            );
          },
        ),
      );

      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsNothing);
      expect(find.text('C'), findsOneWidget);
      expect(find.text('D'), findsNothing);
      expect(find.text('E'), findsOneWidget);
      expect(find.text('F'), findsNothing);

      await tester.tap(find.byType(ExpandIcon).at(0));
      await tester.tap(find.byType(ExpandIcon).at(1));
      await tester.pumpAndSettle();

      expect(find.text('A'), findsNothing);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('C'), findsNothing);
      expect(find.text('D'), findsOneWidget);
      expect(find.text('E'), findsOneWidget);
      expect(find.text('F'), findsNothing);

      // ExpansionPanelList --> ExpansionPanelList.radio
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsNothing);
      expect(find.text('C'), findsOneWidget);
      expect(find.text('D'), findsNothing);
      expect(find.text('E'), findsNothing);
      expect(find.text('F'), findsOneWidget);

      // ExpansionPanelList.radio --> ExpansionPanelList
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('A'), findsNothing);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('C'), findsNothing);
      expect(find.text('D'), findsOneWidget);
      expect(find.text('E'), findsOneWidget);
      expect(find.text('F'), findsNothing);
    },
  );

  testWidgets('No duplicate global keys at layout/build time', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/13780
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return MaterialApp(
            // Wrapping with LayoutBuilder or other widgets that augment
            // layout/build order should not create duplicate keys
            home: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return SingleChildScrollView(
                  child: ExpansionPanelList.radio(
                    expansionCallback: (int index, bool isExpanded) {
                      if (!isExpanded) {
                        // setState invocation required to trigger
                        // _ExpansionPanelListState.didUpdateWidget,
                        // which causes duplicate keys to be
                        // generated in the regression
                        setState(() {});
                      }
                    },
                    children: <ExpansionPanelRadio>[
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
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );

    // Initializes with all panels closed
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsNothing);
    expect(find.text('C'), findsOneWidget);
    expect(find.text('D'), findsNothing);
    expect(find.text('E'), findsOneWidget);
    expect(find.text('F'), findsNothing);

    // Open a panel
    await tester.tap(find.byType(ExpandIcon).at(1));
    await tester.pumpAndSettle();

    final List<bool> panelExpansionState = <bool>[false, false];

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return MaterialApp(
            home: Scaffold(
              // Wrapping with LayoutBuilder or other widgets that augment
              // layout/build order should not create duplicate keys
              body: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  return SingleChildScrollView(
                    child: ExpansionPanelList(
                      expansionCallback: (int index, bool isExpanded) {
                        // setState invocation required to trigger
                        // _ExpansionPanelListState.didUpdateWidget, which
                        // causes duplicate keys to be generated in the
                        // regression
                        setState(() {
                          panelExpansionState[index] = !isExpanded;
                        });
                      },
                      children: <ExpansionPanel>[
                        ExpansionPanel(
                          headerBuilder: (BuildContext context, bool isExpanded) {
                            return Text(isExpanded ? 'B' : 'A');
                          },
                          body: const SizedBox(height: 100.0),
                          isExpanded: panelExpansionState[0],
                        ),
                        ExpansionPanel(
                          headerBuilder: (BuildContext context, bool isExpanded) {
                            return Text(isExpanded ? 'D' : 'C');
                          },
                          body: const SizedBox(height: 100.0),
                          isExpanded: panelExpansionState[1],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );

    // initializes with all panels closed
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsNothing);
    expect(find.text('C'), findsOneWidget);
    expect(find.text('D'), findsNothing);

    // open a panel
    await tester.tap(find.byType(ExpandIcon).at(1));
    await tester.pumpAndSettle();
  });

  testWidgets('Panel header has semantics, canTapOnHeader = false ', (WidgetTester tester) async {
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

    // Check the semantics of [ExpandIcon] for expanded panel.
    final Finder expandedIcon = find.descendant(
      of: find.ancestor(
        of: find.byKey(expandedKey),
        matching: find.byType(Row),
      ),
      matching: find.byType(ExpandIcon),
    );
    expect(tester.getSemantics(expandedIcon), matchesSemantics(
      label: 'Collapse',
      isButton: true,
      hasEnabledState: true,
      isEnabled: true,
      isFocusable: true,
      hasTapAction: true,
      onTapHint: localizations.expandedIconTapHint,
    ));

    // Check the semantics of the header widget for expanded panel.
    final Finder expandedHeader = find.byKey(expandedKey);
    expect(tester.getSemantics(expandedHeader), matchesSemantics(
      label: 'Expanded',
    ));

    // Check the semantics of [ExpandIcon] for collapsed panel.
    final Finder collapsedIcon = find.descendant(
      of: find.ancestor(
        of: find.byKey(collapsedKey),
        matching: find.byType(Row),
      ),
      matching: find.byType(ExpandIcon),
    );
    expect(tester.getSemantics(collapsedIcon), matchesSemantics(
      label: 'Expand',
      isButton: true,
      hasEnabledState: true,
      isEnabled: true,
      isFocusable: true,
      hasTapAction: true,
      onTapHint: localizations.collapsedIconTapHint,
    ));

    // Check the semantics of the header widget for expanded panel.
    final Finder collapsedHeader = find.byKey(collapsedKey);
    expect(tester.getSemantics(collapsedHeader), matchesSemantics(
      label: 'Collapsed',
    ));

    handle.dispose();
  });

  testWidgets('Panel header has semantics, canTapOnHeader = true', (WidgetTester tester) async {
    const Key expandedKey = Key('expanded');
    const Key collapsedKey = Key('collapsed');
    final SemanticsHandle handle = tester.ensureSemantics();
    final List<ExpansionPanel> _demoItems = <ExpansionPanel>[
      ExpansionPanel(
        headerBuilder: (BuildContext context, bool isExpanded) {
          return const Text('Expanded', key: expandedKey);
        },
        canTapOnHeader: true,
        body: const SizedBox(height: 100.0),
        isExpanded: true,
      ),
      ExpansionPanel(
        headerBuilder: (BuildContext context, bool isExpanded) {
          return const Text('Collapsed', key: collapsedKey);
        },
        canTapOnHeader: true,
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
      isFocusable: true,
      hasEnabledState: true,
      hasTapAction: true,
    ));

    expect(tester.getSemantics(find.byKey(collapsedKey)), matchesSemantics(
      label: 'Collapsed',
      isButton: true,
      isFocusable: true,
      hasEnabledState: true,
      hasTapAction: true,
    ));

    handle.dispose();
  });

  testWidgets('Ensure canTapOnHeader is false by default',  (WidgetTester tester) async {
    final ExpansionPanel _expansionPanel = ExpansionPanel(
      headerBuilder: (BuildContext context, bool isExpanded) => const Text('Demo'),
      body: const SizedBox(height: 100.0),
    );

    expect(_expansionPanel.canTapOnHeader, isFalse);
  });

  testWidgets('Toggle ExpansionPanelRadio when tapping header and canTapOnHeader is true',  (WidgetTester tester) async {
    const Key firstPanelKey = Key('firstPanelKey');
    const Key secondPanelKey = Key('secondPanelKey');

    final List<ExpansionPanel> _demoItemsRadio = <ExpansionPanelRadio>[
      ExpansionPanelRadio(
        headerBuilder: (BuildContext context, bool isExpanded) {
          return Text(isExpanded ? 'B' : 'A', key: firstPanelKey);
        },
        body: const SizedBox(height: 100.0),
        value: 0,
        canTapOnHeader: true,
      ),
      ExpansionPanelRadio(
        headerBuilder: (BuildContext context, bool isExpanded) {
          return Text(isExpanded ? 'D' : 'C', key: secondPanelKey);
        },
        body: const SizedBox(height: 100.0),
        value: 1,
        canTapOnHeader: true,
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

    await tester.tap(find.byKey(firstPanelKey));
    await tester.pumpAndSettle();

    // Now the first panel is open
    expect(find.text('A'), findsNothing);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
    expect(find.text('D'), findsNothing);

    await tester.tap(find.byKey(secondPanelKey));
    await tester.pumpAndSettle();

    // Now the second panel is open
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsNothing);
    expect(find.text('C'), findsNothing);
    expect(find.text('D'), findsOneWidget);
  });

  testWidgets('Toggle ExpansionPanel when tapping header and canTapOnHeader is true',  (WidgetTester tester) async {
    const Key firstPanelKey = Key('firstPanelKey');
    const Key secondPanelKey = Key('secondPanelKey');

    await tester.pumpWidget(
      const MaterialApp(
        home: SingleChildScrollView(
          child: SimpleExpansionPanelListTestWidget(
            firstPanelKey: firstPanelKey,
            secondPanelKey: secondPanelKey,
            canTapOnHeader: true,
          ),
        ),
      ),
    );

    // Initializes with all panels closed
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsNothing);
    expect(find.text('C'), findsOneWidget);
    expect(find.text('D'), findsNothing);

    await tester.tap(find.byKey(firstPanelKey));
    await tester.pumpAndSettle();

    // The first panel is open
    expect(find.text('A'), findsNothing);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
    expect(find.text('D'), findsNothing);

    await tester.tap(find.byKey(firstPanelKey));
    await tester.pumpAndSettle();

    // The first panel is closed
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsNothing);
    expect(find.text('C'), findsOneWidget);
    expect(find.text('D'), findsNothing);

    await tester.tap(find.byKey(secondPanelKey));
    await tester.pumpAndSettle();

    // The second panel is open
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsNothing);
    expect(find.text('C'), findsNothing);
    expect(find.text('D'), findsOneWidget);

    await tester.tap(find.byKey(secondPanelKey));
    await tester.pumpAndSettle();

    // The second panel is closed
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsNothing);
    expect(find.text('C'), findsOneWidget);
    expect(find.text('D'), findsNothing);
  });

  testWidgets('Do not toggle ExpansionPanel when tapping header and canTapOnHeader is false',  (WidgetTester tester) async {
    const Key firstPanelKey = Key('firstPanelKey');
    const Key secondPanelKey = Key('secondPanelKey');

    await tester.pumpWidget(
      const MaterialApp(
        home: SingleChildScrollView(
          child: SimpleExpansionPanelListTestWidget(
            firstPanelKey: firstPanelKey,
            secondPanelKey: secondPanelKey,
          ),
        ),
      ),
    );

    // Initializes with all panels closed
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsNothing);
    expect(find.text('C'), findsOneWidget);
    expect(find.text('D'), findsNothing);

    await tester.tap(find.byKey(firstPanelKey));
    await tester.pumpAndSettle();

    // The first panel is closed
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsNothing);
    expect(find.text('C'), findsOneWidget);
    expect(find.text('D'), findsNothing);

    await tester.tap(find.byKey(secondPanelKey));
    await tester.pumpAndSettle();

    // The second panel is closed
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsNothing);
    expect(find.text('C'), findsOneWidget);
    expect(find.text('D'), findsNothing);
  });

  testWidgets('Do not toggle ExpansionPanelRadio when tapping header and canTapOnHeader is false',  (WidgetTester tester) async {
    const Key firstPanelKey = Key('firstPanelKey');
    const Key secondPanelKey = Key('secondPanelKey');

    final List<ExpansionPanel> _demoItemsRadio = <ExpansionPanelRadio>[
      ExpansionPanelRadio(
        headerBuilder: (BuildContext context, bool isExpanded) {
          return Text(isExpanded ? 'B' : 'A', key: firstPanelKey);
        },
        body: const SizedBox(height: 100.0),
        value: 0,
      ),
      ExpansionPanelRadio(
        headerBuilder: (BuildContext context, bool isExpanded) {
          return Text(isExpanded ? 'D' : 'C', key: secondPanelKey);
        },
        body: const SizedBox(height: 100.0),
        value: 1,
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

    await tester.tap(find.byKey(firstPanelKey));
    await tester.pumpAndSettle();

    // The first panel is closed
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsNothing);
    expect(find.text('C'), findsOneWidget);
    expect(find.text('D'), findsNothing);

    await tester.tap(find.byKey(secondPanelKey));
    await tester.pumpAndSettle();

    // The second panel is closed
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsNothing);
    expect(find.text('C'), findsOneWidget);
    expect(find.text('D'), findsNothing);
  });

  testWidgets('Correct default header padding', (WidgetTester tester) async {
    const Key firstPanelKey = Key('firstPanelKey');

    await tester.pumpWidget(
      const MaterialApp(
        home: SingleChildScrollView(
          child: SimpleExpansionPanelListTestWidget(
            firstPanelKey: firstPanelKey,
            canTapOnHeader: true,
          ),
        ),
      ),
    );

    // The panel is closed
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsNothing);

    // No padding applied to closed header
    RenderBox box = tester.renderObject(find.ancestor(of: find.byKey(firstPanelKey), matching: find.byType(AnimatedContainer)).first);
    expect(box.size.height, equals(48.0)); // _kPanelHeaderCollapsedHeight
    expect(box.size.width, equals(736.0));

    // Now, expand the child panel.
    await tester.tap(find.byKey(firstPanelKey));
    await tester.pumpAndSettle();

    // The panel is expanded
    expect(find.text('A'), findsNothing);
    expect(find.text('B'), findsOneWidget);

    // Padding is added to expanded header
    box = tester.renderObject(find.ancestor(of: find.byKey(firstPanelKey), matching: find.byType(AnimatedContainer)).first);
    expect(box.size.height, equals(80.0)); // _kPanelHeaderCollapsedHeight + 32.0 (double default padding)
    expect(box.size.width, equals(736.0));
  });

  testWidgets('Correct custom header padding', (WidgetTester tester) async {
    const Key firstPanelKey = Key('firstPanelKey');

    await tester.pumpWidget(
      const MaterialApp(
        home: SingleChildScrollView(
          child: SimpleExpansionPanelListTestWidget(
            firstPanelKey: firstPanelKey,
            canTapOnHeader: true,
            expandedHeaderPadding: EdgeInsets.symmetric(vertical: 40.0),
          ),
        ),
      ),
    );

    // The panel is closed
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsNothing);

    // No padding applied to closed header
    RenderBox box = tester.renderObject(find.ancestor(of: find.byKey(firstPanelKey), matching: find.byType(AnimatedContainer)).first);
    expect(box.size.height, equals(48.0)); // _kPanelHeaderCollapsedHeight
    expect(box.size.width, equals(736.0));

    // Now, expand the child panel.
    await tester.tap(find.byKey(firstPanelKey));
    await tester.pumpAndSettle();

    // The panel is expanded
    expect(find.text('A'), findsNothing);
    expect(find.text('B'), findsOneWidget);

    // Padding is added to expanded header
    box = tester.renderObject(find.ancestor(of: find.byKey(firstPanelKey), matching: find.byType(AnimatedContainer)).first);
    expect(box.size.height, equals(128.0)); // _kPanelHeaderCollapsedHeight + 80.0 (double padding)
    expect(box.size.width, equals(736.0));
  });

  testWidgets('ExpansionPanelList respects dividerColor', (WidgetTester tester) async {
    const Color dividerColor = Colors.red;
    await tester.pumpWidget(const MaterialApp(
      home: SingleChildScrollView(
        child: SimpleExpansionPanelListTestWidget(
          dividerColor: dividerColor,
        ),
      ),
    ));

    final DecoratedBox decoratedBox = tester.widget(find.byType(DecoratedBox).last);
    final BoxDecoration decoration = decoratedBox.decoration as BoxDecoration;

    // For the last DecoratedBox, we will have a Border.top with the provided dividerColor.
    expect(decoration.border!.top.color, dividerColor);
  });

  testWidgets('ExpansionPanelList.radio respects DividerColor', (WidgetTester tester) async {
    const Color dividerColor = Colors.red;
    await tester.pumpWidget(MaterialApp(
      home: SingleChildScrollView(
        child: ExpansionPanelList.radio(
          dividerColor: dividerColor,
          children: <ExpansionPanelRadio>[
            ExpansionPanelRadio(
              headerBuilder: (BuildContext context, bool isExpanded) {
                return Text(isExpanded ? 'B' : 'A', key: const Key('firstKey'));
              },
              body: const SizedBox(height: 100.0),
              value: 0,
            ),
            ExpansionPanelRadio(
              headerBuilder: (BuildContext context, bool isExpanded) {
                return Text(isExpanded ? 'D' : 'C', key: const Key('secondKey'));
              },
              body: const SizedBox(height: 100.0),
              value: 1,
            ),
          ],
        ),
      ),
    ));

    final DecoratedBox decoratedBox = tester.widget(find.byType(DecoratedBox).last);
    final BoxDecoration boxDecoration = decoratedBox.decoration as BoxDecoration;

    // For the last DecoratedBox, we will have a Border.top with the provided dividerColor.
    expect(boxDecoration.border!.top.color, dividerColor);
  });

  testWidgets('elevation is propagated properly to MergeableMaterial', (WidgetTester tester) async {
    const double _elevation = 8;

    // Test for ExpansionPanelList.
    await tester.pumpWidget(const MaterialApp(
      home: SingleChildScrollView(
        child: SimpleExpansionPanelListTestWidget(
          elevation: _elevation,
        ),
      ),
    ));

    expect(tester.widget<MergeableMaterial>(find.byType(MergeableMaterial)).elevation, _elevation);

    // Test for ExpansionPanelList.radio.
    await tester.pumpWidget(MaterialApp(
      home: SingleChildScrollView(
        child: ExpansionPanelList.radio(
          elevation: _elevation,
          children: <ExpansionPanelRadio>[
            ExpansionPanelRadio(
              headerBuilder: (BuildContext context, bool isExpanded) {
                return Text(isExpanded ? 'B' : 'A', key: const Key('firstKey'));
              },
              body: const SizedBox(height: 100.0),
              value: 0,
            ),
            ExpansionPanelRadio(
              headerBuilder: (BuildContext context, bool isExpanded) {
                return Text(isExpanded ? 'D' : 'C', key: const Key('secondKey'));
              },
              body: const SizedBox(height: 100.0),
              value: 1,
            ),
          ],
        ),
      ),
    ));

    expect(tester.widget<MergeableMaterial>(find.byType(MergeableMaterial)).elevation, _elevation);
  });

  testWidgets('Using a value non defined value throws assertion error', (WidgetTester tester) async {

    // It should throw an AssertionError since, 19 is not defined in kElevationToShadow.
    await tester.pumpWidget(const MaterialApp(
      home: SingleChildScrollView(
        child: SimpleExpansionPanelListTestWidget(
          elevation: 19,
        ),
      ),
    ));

    final dynamic exception = tester.takeException();
    expect(exception, isAssertionError);
    expect((exception as AssertionError).toString(), contains(
      'Invalid value for elevation. See the kElevationToShadow constant for'
      ' possible elevation values.',
    ));
  });

  testWidgets('ExpansionPanel.panelColor test', (WidgetTester tester) async {
    const Color firstPanelColor = Colors.red;
    const Color secondPanelColor = Colors.brown;

    await tester.pumpWidget(
      MaterialApp(
        home: SingleChildScrollView(
          child: ExpansionPanelList(
            expansionCallback: (int _index, bool _isExpanded) {},
            children: <ExpansionPanel>[
              ExpansionPanel(
                backgroundColor: firstPanelColor,
                headerBuilder: (BuildContext context, bool isExpanded) {
                  return const Text('A');
                },
                body: const SizedBox(height: 100.0),
              ),
              ExpansionPanel(
                backgroundColor: secondPanelColor,
                headerBuilder: (BuildContext context, bool isExpanded) {
                  return const Text('B');
                },
                body: const SizedBox(height: 100.0),
              ),
            ],
          ),
        ),
      ),
    );

    final MergeableMaterial mergeableMaterial = tester.widget(find.byType(MergeableMaterial));

    expect((mergeableMaterial.children.first as MaterialSlice).color, firstPanelColor);
    expect((mergeableMaterial.children.last as MaterialSlice).color, secondPanelColor);
  });

  testWidgets('ExpansionPanelRadio.backgroundColor test', (WidgetTester tester) async {
    const Color firstPanelColor = Colors.red;
    const Color secondPanelColor = Colors.brown;

    await tester.pumpWidget(MaterialApp(
      home: SingleChildScrollView(
        child: ExpansionPanelList.radio(
          children: <ExpansionPanelRadio>[
            ExpansionPanelRadio(
              backgroundColor: firstPanelColor,
              headerBuilder: (BuildContext context, bool isExpanded) {
                return const Text('A');
              },
              body: const SizedBox(height: 100.0),
              value: 0,
            ),
            ExpansionPanelRadio(
              backgroundColor: secondPanelColor,
              headerBuilder: (BuildContext context, bool isExpanded) {
                return const Text('B');
              },
              body: const SizedBox(height: 100.0),
              value: 1,
            ),
          ],
        ),
      ),
    ));

    final MergeableMaterial mergeableMaterial = tester.widget(find.byType(MergeableMaterial));

    expect((mergeableMaterial.children.first as MaterialSlice).color, firstPanelColor);
    expect((mergeableMaterial.children.last as MaterialSlice).color, secondPanelColor);
  });
}
