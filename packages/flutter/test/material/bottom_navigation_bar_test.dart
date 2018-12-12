// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';
import '../widgets/semantics_tester.dart';

void main() {
  testWidgets('BottomNavigationBar callback test', (WidgetTester tester) async {
    int mutatedIndex;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.ac_unit),
                title: Text('AC')
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.access_alarm),
                title: Text('Alarm')
              )
            ],
            onTap: (int index) {
              mutatedIndex = index;
            }
          )
        )
      )
    );

    await tester.tap(find.text('Alarm'));

    expect(mutatedIndex, 1);
  });

  testWidgets('BottomNavigationBar content test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.ac_unit),
                title: Text('AC')
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.access_alarm),
                title: Text('Alarm')
              )
            ]
          )
        )
      )
    );

    final RenderBox box = tester.renderObject(find.byType(BottomNavigationBar));
    expect(box.size.height, kBottomNavigationBarHeight);
    expect(find.text('AC'), findsOneWidget);
    expect(find.text('Alarm'), findsOneWidget);
  });

  testWidgets('BottomNavigationBar adds bottom padding to height', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(padding: EdgeInsets.only(bottom: 40.0)),
          child: Scaffold(
            bottomNavigationBar: BottomNavigationBar(
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.ac_unit),
                  title: Text('AC')
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.access_alarm),
                  title: Text('Alarm')
                )
              ]
            )
          )
        )
      )
    );

    const double labelBottomMargin = 8.0; // _kBottomMargin in implementation.
    const double additionalPadding = 40.0 - labelBottomMargin;
    const double expectedHeight = kBottomNavigationBarHeight + additionalPadding;
    expect(tester.getSize(find.byType(BottomNavigationBar)).height, expectedHeight);
  });

  testWidgets('BottomNavigationBar action size test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.shifting,
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.ac_unit),
                title: Text('AC')
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.access_alarm),
                title: Text('Alarm')
              )
            ]
          )
        )
      )
    );

    Iterable<RenderBox> actions = tester.renderObjectList(find.byType(InkResponse));
    expect(actions.length, 2);
    expect(actions.elementAt(0).size.width, 480.0);
    expect(actions.elementAt(1).size.width, 320.0);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: 1,
            type: BottomNavigationBarType.shifting,
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.ac_unit),
                title: Text('AC')
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.access_alarm),
                title: Text('Alarm')
              )
            ]
          )
        )
      )
    );

    await tester.pump(const Duration(milliseconds: 200));

    actions = tester.renderObjectList(find.byType(InkResponse));
    expect(actions.length, 2);
    expect(actions.elementAt(0).size.width, 320.0);
    expect(actions.elementAt(1).size.width, 480.0);
  });

  testWidgets('BottomNavigationBar multiple taps test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.shifting,
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.ac_unit),
                title: Text('AC')
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.access_alarm),
                title: Text('Alarm')
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.access_time),
                title: Text('Time')
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.add),
                title: Text('Add')
              )
            ]
          )
        )
      )
    );

    // We want to make sure that the last label does not get displaced,
    // irrespective of how many taps happen on the first N - 1 labels and how
    // they grow.

    Iterable<RenderBox> actions = tester.renderObjectList(find.byType(InkResponse));
    final Offset originalOrigin = actions.elementAt(3).localToGlobal(Offset.zero);

    await tester.tap(find.text('AC'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    actions = tester.renderObjectList(find.byType(InkResponse));
    expect(actions.elementAt(3).localToGlobal(Offset.zero), equals(originalOrigin));

    await tester.tap(find.text('Alarm'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    actions = tester.renderObjectList(find.byType(InkResponse));
    expect(actions.elementAt(3).localToGlobal(Offset.zero), equals(originalOrigin));

    await tester.tap(find.text('Time'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    actions = tester.renderObjectList(find.byType(InkResponse));
    expect(actions.elementAt(3).localToGlobal(Offset.zero), equals(originalOrigin));
  });

  testWidgets('BottomNavigationBar inherits shadowed app theme for shifting navbar', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.light),
        home: Theme(
          data: ThemeData(brightness: Brightness.dark),
          child: Scaffold(
            bottomNavigationBar: BottomNavigationBar(
              type: BottomNavigationBarType.shifting,
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.ac_unit),
                  title: Text('AC')
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.access_alarm),
                  title: Text('Alarm')
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.access_time),
                  title: Text('Time')
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.add),
                  title: Text('Add')
                )
              ]
            )
          )
        )
      )
    );

    await tester.tap(find.text('Alarm'));
    await tester.pump(const Duration(seconds: 1));
    expect(Theme.of(tester.element(find.text('Alarm'))).brightness, equals(Brightness.dark));
  });

  testWidgets('BottomNavigationBar inherits shadowed app theme for fixed navbar', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.light),
        home: Theme(
          data: ThemeData(brightness: Brightness.dark),
          child: Scaffold(
            bottomNavigationBar: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.ac_unit),
                  title: Text('AC')
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.access_alarm),
                  title: Text('Alarm')
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.access_time),
                  title: Text('Time')
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.add),
                  title: Text('Add')
                )
              ]
            )
          )
        )
      )
    );

    await tester.tap(find.text('Alarm'));
    await tester.pump(const Duration(seconds: 1));
    expect(Theme.of(tester.element(find.text('Alarm'))).brightness, equals(Brightness.dark));
  });

  testWidgets('BottomNavigationBar iconSize test', (WidgetTester tester) async {
    double builderIconSize;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BottomNavigationBar(
            iconSize: 12.0,
            items: <BottomNavigationBarItem>[
              const BottomNavigationBarItem(
                title: Text('A'),
                icon: Icon(Icons.ac_unit),
              ),
              BottomNavigationBarItem(
                title: const Text('B'),
                icon: Builder(
                  builder: (BuildContext context) {
                    builderIconSize = IconTheme.of(context).size;
                    return SizedBox(
                      width: builderIconSize,
                      height: builderIconSize,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final RenderBox box = tester.renderObject(find.byType(Icon));
    expect(box.size.width, equals(12.0));
    expect(box.size.height, equals(12.0));
    expect(builderIconSize, 12.0);
  });


  testWidgets('BottomNavigationBar responds to textScaleFactor', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                title: Text('A'),
                icon: Icon(Icons.ac_unit),
              ),
              BottomNavigationBarItem(
                title: Text('B'),
                icon: Icon(Icons.battery_alert),
              ),
            ],
          ),
        ),
      ),
    );

    final RenderBox defaultBox = tester.renderObject(find.byType(BottomNavigationBar));
    expect(defaultBox.size.height, equals(kBottomNavigationBarHeight));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.shifting,
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                title: Text('A'),
                icon: Icon(Icons.ac_unit),
              ),
              BottomNavigationBarItem(
                title: Text('B'),
                icon: Icon(Icons.battery_alert),
              ),
            ],
          ),
        ),
      ),
    );

    final RenderBox shiftingBox = tester.renderObject(find.byType(BottomNavigationBar));
    expect(shiftingBox.size.height, equals(kBottomNavigationBarHeight));

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaleFactor: 2.0),
          child: Scaffold(
            bottomNavigationBar: BottomNavigationBar(
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  title: Text('A'),
                  icon: Icon(Icons.ac_unit),
                ),
                BottomNavigationBarItem(
                  title: Text('B'),
                  icon: Icon(Icons.battery_alert),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final RenderBox box = tester.renderObject(find.byType(BottomNavigationBar));
    expect(box.size.height, equals(68.0));
  });

  testWidgets('BottomNavigationBar limits width of tiles with long titles', (WidgetTester tester) async {
    final Text longTextA = Text(''.padLeft(100, 'A'));
    final Text longTextB = Text(''.padLeft(100, 'B'));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BottomNavigationBar(
            items: <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                title: longTextA,
                icon: const Icon(Icons.ac_unit),
              ),
              BottomNavigationBarItem(
                title: longTextB,
                icon: const Icon(Icons.battery_alert),
              ),
            ],
          ),
        ),
      ),
    );

    final RenderBox box = tester.renderObject(find.byType(BottomNavigationBar));
    expect(box.size.height, equals(kBottomNavigationBarHeight));

    final RenderBox itemBoxA = tester.renderObject(find.text(longTextA.data));
    expect(itemBoxA.size, equals(const Size(400.0, 14.0)));
    final RenderBox itemBoxB = tester.renderObject(find.text(longTextB.data));
    expect(itemBoxB.size, equals(const Size(400.0, 14.0)));
  });

  testWidgets('BottomNavigationBar paints circles', (WidgetTester tester) async {
    await tester.pumpWidget(
      boilerplate(
        textDirection: TextDirection.ltr,
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              title: Text('A'),
              icon: Icon(Icons.ac_unit),
            ),
            BottomNavigationBarItem(
              title: Text('B'),
              icon: Icon(Icons.battery_alert),
            ),
          ],
        ),
      ),
    );

    final RenderBox box = tester.renderObject(find.byType(BottomNavigationBar));
    expect(box, isNot(paints..circle()));

    await tester.tap(find.text('A'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    expect(box, paints..circle(x: 200.0));

    await tester.tap(find.text('B'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    expect(box, paints..circle(x: 200.0)..translate(x: 400.0)..circle(x: 200.0));

    // Now we flip the directionality and verify that the circles switch positions.
    await tester.pumpWidget(
      boilerplate(
        textDirection: TextDirection.rtl,
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              title: Text('A'),
              icon: Icon(Icons.ac_unit),
            ),
            BottomNavigationBarItem(
              title: Text('B'),
              icon: Icon(Icons.battery_alert),
            ),
          ],
        ),
      ),
    );

    expect(box, paints..translate()..save()..translate(x: 400.0)..circle(x: 200.0)..restore()..circle(x: 200.0));

    await tester.tap(find.text('A'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    expect(
        box,
        paints
          ..translate(x: 0.0, y: 0.0)
          ..save()
          ..translate(x: 400.0)
          ..circle(x: 200.0)
          ..restore()
          ..circle(x: 200.0)
          ..translate(x: 400.0)
          ..circle(x: 200.0)
    );
  });

  testWidgets('BottomNavigationBar inactiveIcon shown', (WidgetTester tester) async {
    const Key filled = Key('filled');
    const Key stroked = Key('stroked');
    int selectedItem = 0;

    await tester.pumpWidget(
      boilerplate(
        textDirection: TextDirection.ltr,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: selectedItem,
          items:  const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              activeIcon: Icon(Icons.favorite, key: filled),
              icon: Icon(Icons.favorite_border, key: stroked),
              title: Text('Favorite'),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.access_alarm),
              title: Text('Alarm'),
            ),
          ],
        ),
      ),
    );

    expect(find.byKey(filled), findsOneWidget);
    expect(find.byKey(stroked), findsNothing);
    selectedItem = 1;

    await tester.pumpWidget(
      boilerplate(
        textDirection: TextDirection.ltr,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: selectedItem,
          items:  const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              activeIcon: Icon(Icons.favorite, key: filled),
              icon: Icon(Icons.favorite_border, key: stroked),
              title: Text('Favorite'),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.access_alarm),
              title: Text('Alarm'),
            ),
          ],
        ),
      ),
    );

    expect(find.byKey(filled), findsNothing);
    expect(find.byKey(stroked), findsOneWidget);
  });

  testWidgets('BottomNavigationBar.fixed semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      boilerplate(
        textDirection: TextDirection.ltr,
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.ac_unit),
              title: Text('AC'),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.access_alarm),
              title: Text('Alarm'),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.hot_tub),
              title: Text('Hot Tub'),
            ),
          ],
        ),
      ),
    );

    final TestSemantics expected = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics(
          children: <TestSemantics>[
            TestSemantics(
              children: <TestSemantics>[
                TestSemantics(
                  flags: <SemanticsFlag>[
                    SemanticsFlag.isSelected,
                    SemanticsFlag.isHeader,
                  ],
                  actions: <SemanticsAction>[SemanticsAction.tap],
                  label: 'AC\nTab 1 of 3',
                  textDirection: TextDirection.ltr,
                ),
                TestSemantics(
                  flags: <SemanticsFlag>[
                    SemanticsFlag.isHeader,
                  ],
                  actions: <SemanticsAction>[SemanticsAction.tap],
                  label: 'Alarm\nTab 2 of 3',
                  textDirection: TextDirection.ltr,
                ),
                TestSemantics(
                  flags: <SemanticsFlag>[
                    SemanticsFlag.isHeader,
                  ],
                  actions: <SemanticsAction>[SemanticsAction.tap],
                  label: 'Hot Tub\nTab 3 of 3',
                  textDirection: TextDirection.ltr,
                ),
              ],
            ),
          ],
        ),
      ],
    );
    expect(semantics, hasSemantics(expected, ignoreId: true, ignoreTransform: true, ignoreRect: true));

    semantics.dispose();
  });

  testWidgets('BottomNavigationBar.shifting semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      boilerplate(
        textDirection: TextDirection.ltr,
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.shifting,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.ac_unit),
              title: Text('AC'),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.access_alarm),
              title: Text('Alarm'),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.hot_tub),
              title: Text('Hot Tub'),
            ),
          ],
        ),
      ),
    );

    final TestSemantics expected = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics(
          children: <TestSemantics>[
            TestSemantics(
              children: <TestSemantics>[
                TestSemantics(
                  flags: <SemanticsFlag>[
                    SemanticsFlag.isSelected,
                    SemanticsFlag.isHeader,
                  ],
                  actions: <SemanticsAction>[SemanticsAction.tap],
                  label: 'AC\nTab 1 of 3',
                  textDirection: TextDirection.ltr,
                ),
                TestSemantics(
                  flags: <SemanticsFlag>[
                    SemanticsFlag.isHeader,
                  ],
                  actions: <SemanticsAction>[SemanticsAction.tap],
                  label: 'Alarm\nTab 2 of 3',
                  textDirection: TextDirection.ltr,
                ),
                TestSemantics(
                  flags: <SemanticsFlag>[
                    SemanticsFlag.isHeader,
                  ],
                  actions: <SemanticsAction>[SemanticsAction.tap],
                  label: 'Hot Tub\nTab 3 of 3',
                  textDirection: TextDirection.ltr,
                ),
              ],
            ),
          ],
        ),
      ],
    );
    expect(semantics, hasSemantics(expected, ignoreId: true, ignoreTransform: true, ignoreRect: true));

    semantics.dispose();
  });

  testWidgets('BottomNavigationBar handles items.length changes', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/10322

    Widget buildFrame(int itemCount) {
      return MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: 0,
            items: List<BottomNavigationBarItem>.generate(itemCount, (int itemIndex) {
              return BottomNavigationBarItem(
                icon: const Icon(Icons.android),
                title: Text('item $itemIndex'),
              );
            }),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildFrame(3));
    expect(find.text('item 0'), findsOneWidget);
    expect(find.text('item 1'), findsOneWidget);
    expect(find.text('item 2'), findsOneWidget);
    expect(find.text('item 3'), findsNothing);

    await tester.pumpWidget(buildFrame(4));
    expect(find.text('item 0'), findsOneWidget);
    expect(find.text('item 1'), findsOneWidget);
    expect(find.text('item 2'), findsOneWidget);
    expect(find.text('item 3'), findsOneWidget);

    await tester.pumpWidget(buildFrame(2));
    expect(find.text('item 0'), findsOneWidget);
    expect(find.text('item 1'), findsOneWidget);
    expect(find.text('item 2'), findsNothing);
    expect(find.text('item 3'), findsNothing);
  });

  testWidgets('BottomNavigationBar change backgroundColor test', (WidgetTester tester) async {
    // Regression test for: https://github.com/flutter/flutter/issues/19653

    Color _backgroundColor = Colors.red;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Scaffold(
              body: Center(
                child: RaisedButton(
                  child: const Text('green'),
                  onPressed: () {
                    setState(() {
                      _backgroundColor = Colors.green;
                    });
                  },
                ),
              ),
              bottomNavigationBar: BottomNavigationBar(
                type: BottomNavigationBarType.shifting,
                items: <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                    title: const Text('Page 1'),
                    backgroundColor: _backgroundColor,
                    icon: const Icon(Icons.dashboard),
                  ),
                  BottomNavigationBarItem(
                    title: const Text('Page 2'),
                    backgroundColor: _backgroundColor,
                    icon: const Icon(Icons.menu),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );

    final Finder backgroundMaterial = find.descendant(
      of: find.byType(BottomNavigationBar),
      matching: find.byWidgetPredicate((Widget w) {
        if (w is Material)
          return w.type == MaterialType.canvas;
        return false;
      }),
    );

    expect(_backgroundColor, Colors.red);
    expect(tester.widget<Material>(backgroundMaterial).color, Colors.red);
    await tester.tap(find.text('green'));
    await tester.pumpAndSettle();
    expect(_backgroundColor, Colors.green);
    expect(tester.widget<Material>(backgroundMaterial).color, Colors.green);
  });

  testWidgets('BottomNavigationBar shifting backgroundColor with transition', (WidgetTester tester) async {
    // Regression test for: https://github.com/flutter/flutter/issues/22226

    int _currentIndex = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Scaffold(
              bottomNavigationBar: RepaintBoundary(
                child: BottomNavigationBar(
                  type: BottomNavigationBarType.shifting,
                  currentIndex: _currentIndex,
                  onTap: (int index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  items: const <BottomNavigationBarItem>[
                    BottomNavigationBarItem(
                      title: Text('Red'),
                      backgroundColor: Colors.red,
                      icon: Icon(Icons.dashboard),
                    ),
                    BottomNavigationBarItem(
                      title: Text('Green'),
                      backgroundColor: Colors.green,
                      icon: Icon(Icons.menu),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Green'));

    for (int pump = 0; pump < 8; pump++) {
      await tester.pump(const Duration(milliseconds: 30));
      await expectLater(
        find.byType(BottomNavigationBar),
        matchesGoldenFile('bottom_navigation_bar.shifting_transition.$pump.png'),
	      skip: !Platform.isLinux,
      );
    }
  });

  testWidgets('BottomNavigationBar item title should not be nullable',
      (WidgetTester tester) async {
    expect(() {
      MaterialApp(
          home: Scaffold(
              bottomNavigationBar: BottomNavigationBar(
                  type: BottomNavigationBarType.shifting,
                  items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.ac_unit),
              title: Text('AC'),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.access_alarm),
            )
          ])));
    }, throwsA(isInstanceOf<AssertionError>()));
  });
}

Widget boilerplate({ Widget bottomNavigationBar, @required TextDirection textDirection }) {
  assert(textDirection != null);
  return Localizations(
    locale: const Locale('en', 'US'),
    delegates: const <LocalizationsDelegate<dynamic>>[
      DefaultMaterialLocalizations.delegate,
      DefaultWidgetsLocalizations.delegate,
    ],
    child: Directionality(
      textDirection: textDirection,
      child: MediaQuery(
        data: const MediaQueryData(),
        child: Material(
          child: Scaffold(
            bottomNavigationBar: bottomNavigationBar,
          ),
        ),
      ),
    ),
  );
}
