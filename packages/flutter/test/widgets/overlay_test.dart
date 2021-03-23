// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

import 'semantics_tester.dart';

void main() {
  testWidgets('OverflowEntries context contains Overlay', (WidgetTester tester) async {
    final GlobalKey overlayKey = GlobalKey();
    bool didBuild = false;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          key: overlayKey,
          initialEntries: <OverlayEntry>[
            OverlayEntry(
              builder: (BuildContext context) {
                didBuild = true;
                final Overlay overlay = context.findAncestorWidgetOfExactType<Overlay>()!;
                expect(overlay.key, equals(overlayKey));
                return Container();
              },
            ),
            OverlayEntry(
              builder: (BuildContext context) => Container(),
            )
          ],
        ),
      ),
    );
    expect(didBuild, isTrue);
    final RenderObject theater = overlayKey.currentContext!.findRenderObject()!;

    expect(theater, hasAGoodToStringDeep);
    expect(
      theater.toStringDeep(minLevel: DiagnosticLevel.info),
      equalsIgnoringHashCodes(
        '_RenderTheatre#744c9\n'
        ' │ parentData: <none>\n'
        ' │ constraints: BoxConstraints(w=800.0, h=600.0)\n'
        ' │ size: Size(800.0, 600.0)\n'
        ' │ skipCount: 0\n'
        ' │ textDirection: ltr\n'
        ' │\n'
        ' ├─onstage 1: RenderLimitedBox#bb803\n'
        ' │ │ parentData: not positioned; offset=Offset(0.0, 0.0) (can use\n'
        ' │ │   size)\n'
        ' │ │ constraints: BoxConstraints(w=800.0, h=600.0)\n'
        ' │ │ size: Size(800.0, 600.0)\n'
        ' │ │ maxWidth: 0.0\n'
        ' │ │ maxHeight: 0.0\n'
        ' │ │\n'
        ' │ └─child: RenderConstrainedBox#62707\n'
        ' │     parentData: <none> (can use size)\n'
        ' │     constraints: BoxConstraints(w=800.0, h=600.0)\n'
        ' │     size: Size(800.0, 600.0)\n'
        ' │     additionalConstraints: BoxConstraints(biggest)\n'
        ' │\n'
        ' ├─onstage 2: RenderLimitedBox#af5f1\n'
        ' ╎ │ parentData: not positioned; offset=Offset(0.0, 0.0) (can use\n'
        ' ╎ │   size)\n'
        ' ╎ │ constraints: BoxConstraints(w=800.0, h=600.0)\n'
        ' ╎ │ size: Size(800.0, 600.0)\n'
        ' ╎ │ maxWidth: 0.0\n'
        ' ╎ │ maxHeight: 0.0\n'
        ' ╎ │\n'
        ' ╎ └─child: RenderConstrainedBox#69c48\n'
        ' ╎     parentData: <none> (can use size)\n'
        ' ╎     constraints: BoxConstraints(w=800.0, h=600.0)\n'
        ' ╎     size: Size(800.0, 600.0)\n'
        ' ╎     additionalConstraints: BoxConstraints(biggest)\n'
        ' ╎\n'
        ' └╌no offstage children\n'
      ),
    );
  });

  testWidgets('Offstage overlay', (WidgetTester tester) async {
    final GlobalKey overlayKey = GlobalKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          key: overlayKey,
          initialEntries: <OverlayEntry>[
            OverlayEntry(
              opaque: true,
              maintainState: true,
              builder: (BuildContext context) => Container(),
            ),
            OverlayEntry(
              opaque: true,
              maintainState: true,
              builder: (BuildContext context) => Container(),
            ),
            OverlayEntry(
              opaque: true,
              maintainState: true,
              builder: (BuildContext context) => Container(),
            ),
          ],
        ),
      ),
    );
    final RenderObject theater = overlayKey.currentContext!.findRenderObject()!;

    expect(theater, hasAGoodToStringDeep);
    expect(
      theater.toStringDeep(minLevel: DiagnosticLevel.info),
      equalsIgnoringHashCodes(
        '_RenderTheatre#385b3\n'
        ' │ parentData: <none>\n'
        ' │ constraints: BoxConstraints(w=800.0, h=600.0)\n'
        ' │ size: Size(800.0, 600.0)\n'
        ' │ skipCount: 2\n'
        ' │ textDirection: ltr\n'
        ' │\n'
        ' ├─onstage 1: RenderLimitedBox#0a77a\n'
        ' ╎ │ parentData: not positioned; offset=Offset(0.0, 0.0) (can use\n'
        ' ╎ │   size)\n'
        ' ╎ │ constraints: BoxConstraints(w=800.0, h=600.0)\n'
        ' ╎ │ size: Size(800.0, 600.0)\n'
        ' ╎ │ maxWidth: 0.0\n'
        ' ╎ │ maxHeight: 0.0\n'
        ' ╎ │\n'
        ' ╎ └─child: RenderConstrainedBox#21f3a\n'
        ' ╎     parentData: <none> (can use size)\n'
        ' ╎     constraints: BoxConstraints(w=800.0, h=600.0)\n'
        ' ╎     size: Size(800.0, 600.0)\n'
        ' ╎     additionalConstraints: BoxConstraints(biggest)\n'
        ' ╎\n'
        ' ╎╌offstage 1: RenderLimitedBox#62c8c NEEDS-LAYOUT NEEDS-PAINT\n'
        ' ╎ │ parentData: not positioned; offset=Offset(0.0, 0.0)\n'
        ' ╎ │ constraints: MISSING\n'
        ' ╎ │ size: MISSING\n'
        ' ╎ │ maxWidth: 0.0\n'
        ' ╎ │ maxHeight: 0.0\n'
        ' ╎ │\n'
        ' ╎ └─child: RenderConstrainedBox#425fa NEEDS-LAYOUT NEEDS-PAINT\n'
        ' ╎     parentData: <none>\n'
        ' ╎     constraints: MISSING\n'
        ' ╎     size: MISSING\n'
        ' ╎     additionalConstraints: BoxConstraints(biggest)\n'
        ' ╎\n'
        ' └╌offstage 2: RenderLimitedBox#03ae2 NEEDS-LAYOUT NEEDS-PAINT\n'
        '   │ parentData: not positioned; offset=Offset(0.0, 0.0)\n'
        '   │ constraints: MISSING\n'
        '   │ size: MISSING\n'
        '   │ maxWidth: 0.0\n'
        '   │ maxHeight: 0.0\n'
        '   │\n'
        '   └─child: RenderConstrainedBox#b4d48 NEEDS-LAYOUT NEEDS-PAINT\n'
        '       parentData: <none>\n'
        '       constraints: MISSING\n'
        '       size: MISSING\n'
        '       additionalConstraints: BoxConstraints(biggest)\n',
      ),
    );
  });

  testWidgets('insert top', (WidgetTester tester) async {
    final GlobalKey overlayKey = GlobalKey();
    final List<String> buildOrder = <String>[];
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          key: overlayKey,
          initialEntries: <OverlayEntry>[
            OverlayEntry(
              builder: (BuildContext context) {
                buildOrder.add('Base');
                return Container();
              },
            ),
          ],
        ),
      ),
    );

    expect(buildOrder, <String>['Base']);

    buildOrder.clear();
    final OverlayState overlay = overlayKey.currentState! as OverlayState;
    overlay.insert(
      OverlayEntry(
        builder: (BuildContext context) {
          buildOrder.add('New');
          return Container();
        }
      ),
    );
    await tester.pump();

    expect(buildOrder, <String>['Base', 'New']);
  });

  testWidgets('insert below', (WidgetTester tester) async {
    final GlobalKey overlayKey = GlobalKey();
    OverlayEntry base;
    final List<String> buildOrder = <String>[];
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          key: overlayKey,
          initialEntries: <OverlayEntry>[
            base = OverlayEntry(
              builder: (BuildContext context) {
                buildOrder.add('Base');
                return Container();
              },
            ),
          ],
        ),
      ),
    );

    expect(buildOrder, <String>['Base']);

    buildOrder.clear();
    final OverlayState overlay = overlayKey.currentState! as OverlayState;
    overlay.insert(
      OverlayEntry(
          builder: (BuildContext context) {
            buildOrder.add('New');
            return Container();
          }
      ),
      below: base,
    );
    await tester.pump();

    expect(buildOrder, <String>['New', 'Base']);
  });

  testWidgets('insert above', (WidgetTester tester) async {
    final GlobalKey overlayKey = GlobalKey();
    OverlayEntry base;
    final List<String> buildOrder = <String>[];
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          key: overlayKey,
          initialEntries: <OverlayEntry>[
            base = OverlayEntry(
              builder: (BuildContext context) {
                buildOrder.add('Base');
                return Container();
              },
            ),
            OverlayEntry(
              builder: (BuildContext context) {
                buildOrder.add('Top');
                return Container();
              },
            ),
          ],
        ),
      ),
    );

    expect(buildOrder, <String>['Base', 'Top']);

    buildOrder.clear();
    final OverlayState overlay = overlayKey.currentState! as OverlayState;
    overlay.insert(
      OverlayEntry(
          builder: (BuildContext context) {
            buildOrder.add('New');
            return Container();
          }
      ),
      above: base,
    );
    await tester.pump();

    expect(buildOrder, <String>['Base', 'New', 'Top']);
  });

  testWidgets('insertAll top', (WidgetTester tester) async {
    final GlobalKey overlayKey = GlobalKey();
    final List<String> buildOrder = <String>[];
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          key: overlayKey,
          initialEntries: <OverlayEntry>[
            OverlayEntry(
              builder: (BuildContext context) {
                buildOrder.add('Base');
                return Container();
              },
            ),
          ],
        ),
      ),
    );

    expect(buildOrder, <String>['Base']);

    final List<OverlayEntry> entries = <OverlayEntry>[
      OverlayEntry(
        builder: (BuildContext context) {
          buildOrder.add('New1');
          return Container();
        },
      ),
      OverlayEntry(
        builder: (BuildContext context) {
          buildOrder.add('New2');
          return Container();
        },
      ),
    ];

    buildOrder.clear();
    final OverlayState overlay = overlayKey.currentState! as OverlayState;
    overlay.insertAll(entries);
    await tester.pump();

    expect(buildOrder, <String>['Base', 'New1', 'New2']);
  });

  testWidgets('insertAll below', (WidgetTester tester) async {
    final GlobalKey overlayKey = GlobalKey();
    OverlayEntry base;
    final List<String> buildOrder = <String>[];
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          key: overlayKey,
          initialEntries: <OverlayEntry>[
            base = OverlayEntry(
              builder: (BuildContext context) {
                buildOrder.add('Base');
                return Container();
              },
            ),
          ],
        ),
      ),
    );

    expect(buildOrder, <String>['Base']);

    final List<OverlayEntry> entries = <OverlayEntry>[
      OverlayEntry(
        builder: (BuildContext context) {
          buildOrder.add('New1');
          return Container();
        },
      ),
      OverlayEntry(
        builder: (BuildContext context) {
          buildOrder.add('New2');
          return Container();
        },
      ),
    ];

    buildOrder.clear();
    final OverlayState overlay = overlayKey.currentState! as OverlayState;
    overlay.insertAll(entries, below: base);
    await tester.pump();

    expect(buildOrder, <String>['New1', 'New2','Base']);
  });

  testWidgets('insertAll above', (WidgetTester tester) async {
    final GlobalKey overlayKey = GlobalKey();
    final List<String> buildOrder = <String>[];
    OverlayEntry base;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          key: overlayKey,
          initialEntries: <OverlayEntry>[
            base = OverlayEntry(
              builder: (BuildContext context) {
                buildOrder.add('Base');
                return Container();
              },
            ),
            OverlayEntry(
              builder: (BuildContext context) {
                buildOrder.add('Top');
                return Container();
              },
            ),
          ],
        ),
      ),
    );

    expect(buildOrder, <String>['Base', 'Top']);

    final List<OverlayEntry> entries = <OverlayEntry>[
      OverlayEntry(
        builder: (BuildContext context) {
          buildOrder.add('New1');
          return Container();
        },
      ),
      OverlayEntry(
        builder: (BuildContext context) {
          buildOrder.add('New2');
          return Container();
        },
      ),
    ];

    buildOrder.clear();
    final OverlayState overlay = overlayKey.currentState! as OverlayState;
    overlay.insertAll(entries, above: base);
    await tester.pump();

    expect(buildOrder, <String>['Base', 'New1', 'New2', 'Top']);
  });

  testWidgets('rearrange', (WidgetTester tester) async {
    final GlobalKey overlayKey = GlobalKey();
    final List<int> buildOrder = <int>[];
    final List<OverlayEntry> initialEntries = <OverlayEntry>[
      OverlayEntry(
        builder: (BuildContext context) {
          buildOrder.add(0);
          return Container();
        },
      ),
      OverlayEntry(
        builder: (BuildContext context) {
          buildOrder.add(1);
          return Container();
        },
      ),
      OverlayEntry(
        builder: (BuildContext context) {
          buildOrder.add(2);
          return Container();
        },
      ),
      OverlayEntry(
        builder: (BuildContext context) {
          buildOrder.add(3);
          return Container();
        },
      ),
    ];

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          key: overlayKey,
          initialEntries: initialEntries,
        ),
      ),
    );

    expect(buildOrder, <int>[0, 1, 2, 3]);

    final List<OverlayEntry> rearranged = <OverlayEntry>[
      initialEntries[3],
      OverlayEntry(
        builder: (BuildContext context) {
          buildOrder.add(4);
          return Container();
        },
      ),
      initialEntries[2],
      // 1 intentionally missing, will end up on top
      initialEntries[0],
    ];

    buildOrder.clear();
    final OverlayState overlay = overlayKey.currentState! as OverlayState;
    overlay.rearrange(rearranged);
    await tester.pump();

    expect(buildOrder, <int>[3, 4, 2, 0, 1]);
  });

  testWidgets('rearrange above', (WidgetTester tester) async {
    final GlobalKey overlayKey = GlobalKey();
    final List<int> buildOrder = <int>[];
    final List<OverlayEntry> initialEntries = <OverlayEntry>[
      OverlayEntry(
        builder: (BuildContext context) {
          buildOrder.add(0);
          return Container();
        },
      ),
      OverlayEntry(
        builder: (BuildContext context) {
          buildOrder.add(1);
          return Container();
        },
      ),
      OverlayEntry(
        builder: (BuildContext context) {
          buildOrder.add(2);
          return Container();
        },
      ),
      OverlayEntry(
        builder: (BuildContext context) {
          buildOrder.add(3);
          return Container();
        },
      ),
    ];

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          key: overlayKey,
          initialEntries: initialEntries,
        ),
      ),
    );

    expect(buildOrder, <int>[0, 1, 2, 3]);

    final List<OverlayEntry> rearranged = <OverlayEntry>[
      initialEntries[3],
      OverlayEntry(
        builder: (BuildContext context) {
          buildOrder.add(4);
          return Container();
        },
      ),
      initialEntries[2],
      // 1 intentionally missing
      initialEntries[0],
    ];

    buildOrder.clear();
    final OverlayState overlay = overlayKey.currentState! as OverlayState;
    overlay.rearrange(rearranged, above: initialEntries[2]);
    await tester.pump();

    expect(buildOrder, <int>[3, 4, 2, 1, 0]);
  });

  testWidgets('rearrange below', (WidgetTester tester) async {
    final GlobalKey overlayKey = GlobalKey();
    final List<int> buildOrder = <int>[];
    final List<OverlayEntry> initialEntries = <OverlayEntry>[
      OverlayEntry(
        builder: (BuildContext context) {
          buildOrder.add(0);
          return Container();
        },
      ),
      OverlayEntry(
        builder: (BuildContext context) {
          buildOrder.add(1);
          return Container();
        },
      ),
      OverlayEntry(
        builder: (BuildContext context) {
          buildOrder.add(2);
          return Container();
        },
      ),
      OverlayEntry(
        builder: (BuildContext context) {
          buildOrder.add(3);
          return Container();
        },
      ),
    ];

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          key: overlayKey,
          initialEntries: initialEntries,
        ),
      ),
    );

    expect(buildOrder, <int>[0, 1, 2, 3]);

    final List<OverlayEntry> rearranged = <OverlayEntry>[
      initialEntries[3],
      OverlayEntry(
        builder: (BuildContext context) {
          buildOrder.add(4);
          return Container();
        },
      ),
      initialEntries[2],
      // 1 intentionally missing
      initialEntries[0],
    ];

    buildOrder.clear();
    final OverlayState overlay = overlayKey.currentState! as OverlayState;
    overlay.rearrange(rearranged, below: initialEntries[2]);
    await tester.pump();

    expect(buildOrder, <int>[3, 4, 1, 2, 0]);
  });

  testWidgets('debugVerifyInsertPosition', (WidgetTester tester) async {
    final GlobalKey overlayKey = GlobalKey();
    OverlayEntry base;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          key: overlayKey,
          initialEntries: <OverlayEntry>[
            base = OverlayEntry(
              builder: (BuildContext context) {
                return Container();
              },
            ),
          ],
        ),
      ),
    );

    final OverlayState overlay = overlayKey.currentState! as OverlayState;

    try {
      overlay.insert(
        OverlayEntry(builder: (BuildContext context) {
          return Container();
        }),
        above: OverlayEntry(
          builder: (BuildContext context) {
            return Container();
          },
        ),
        below: OverlayEntry(
          builder: (BuildContext context) {
            return Container();
          },
        ),
      );
    } on AssertionError catch (e) {
      expect(e.message, 'Only one of `above` and `below` may be specified.');
    }

    expect(() => overlay.insert(
      OverlayEntry(builder: (BuildContext context) {
        return Container();
      }),
      above: base,
    ), isNot(throwsAssertionError));

    try {
      overlay.insert(
        OverlayEntry(builder: (BuildContext context) {
          return Container();
        }),
        above: OverlayEntry(
          builder: (BuildContext context) {
            return Container();
          },
        ),
      );
    } on AssertionError catch (e) {
      expect(e.message, 'The provided entry used for `above` must be present in the Overlay.');
    }

    try {
      overlay.rearrange(<OverlayEntry>[base], above: OverlayEntry(
        builder: (BuildContext context) {
          return Container();
        },
      ));

    } on AssertionError catch (e) {
      expect(e.message, 'The provided entry used for `above` must be present in the Overlay and in the `newEntriesList`.');
    }

    await tester.pump();
  });

  testWidgets('OverlayState.of() called without Overlay being exist', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Builder(
          builder: (BuildContext context) {
            late FlutterError error;
            final Widget debugRequiredFor = Container();
            try {
              Overlay.of(context, debugRequiredFor: debugRequiredFor);
            } on FlutterError catch (e) {
              error = e;
            } finally {
              expect(error, isNotNull);
              expect(error.diagnostics.length, 5);
              expect(error.diagnostics[2].level, DiagnosticLevel.hint);
              expect(error.diagnostics[2].toStringDeep(), equalsIgnoringHashCodes(
                'The most common way to add an Overlay to an application is to\n'
                'include a MaterialApp or Navigator widget in the runApp() call.\n',
              ));
              expect(error.diagnostics[3], isA<DiagnosticsProperty<Widget>>());
              expect(error.diagnostics[3].value, debugRequiredFor);
              expect(error.diagnostics[4], isA<DiagnosticsProperty<Element>>());
              expect(error.toStringDeep(), equalsIgnoringHashCodes(
                'FlutterError\n'
                '   No Overlay widget found.\n'
                '   Container widgets require an Overlay widget ancestor for correct\n'
                '   operation.\n'
                '   The most common way to add an Overlay to an application is to\n'
                '   include a MaterialApp or Navigator widget in the runApp() call.\n'
                '   The specific widget that failed to find an overlay was:\n'
                '     Container\n'
                '   The context from which that widget was searching for an overlay\n'
                '   was:\n'
                '     Builder\n',
              ));
            }
            return Container();
          }
        ),
      ),
    );
  });

  testWidgets('OverlayEntry.opaque can be changed when OverlayEntry is not part of an Overlay (yet)', (WidgetTester tester) async {
    final GlobalKey<OverlayState> overlayKey = GlobalKey<OverlayState>();
    final Key root = UniqueKey();
    final Key top = UniqueKey();
    final OverlayEntry rootEntry = OverlayEntry(
      builder: (BuildContext context) {
        return Container(key: root);
      },
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          key: overlayKey,
          initialEntries: <OverlayEntry>[
            rootEntry,
          ],
        ),
      ),
    );

    expect(find.byKey(root), findsOneWidget);

    final OverlayEntry newEntry = OverlayEntry(
      builder: (BuildContext context) {
        return Container(key: top);
      },
    );
    expect(newEntry.opaque, isFalse);
    newEntry.opaque = true; // Does neither trigger an assert nor throw.
    expect(newEntry.opaque, isTrue);

    // The new opaqueness is honored when inserted into an overlay.
    overlayKey.currentState!.insert(newEntry);
    await tester.pumpAndSettle();

    expect(find.byKey(root), findsNothing);
    expect(find.byKey(top), findsOneWidget);
  });

  testWidgets('OverlayEntries do not rebuild when opaqueness changes', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/45797.

    final GlobalKey<OverlayState> overlayKey = GlobalKey<OverlayState>();
    final Key bottom = UniqueKey();
    final Key middle = UniqueKey();
    final Key top = UniqueKey();
    final Widget bottomWidget = StatefulTestWidget(key: bottom);
    final Widget middleWidget = StatefulTestWidget(key: middle);
    final Widget topWidget = StatefulTestWidget(key: top);

    final OverlayEntry bottomEntry = OverlayEntry(
      maintainState: true,
      builder: (BuildContext context) {
        return bottomWidget;
      },
    );
    final OverlayEntry middleEntry = OverlayEntry(
      maintainState: true,
      builder: (BuildContext context) {
        return middleWidget;
      },
    );
    final OverlayEntry topEntry = OverlayEntry(
      maintainState: true,
      builder: (BuildContext context) {
        return topWidget;
      },
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          key: overlayKey,
          initialEntries: <OverlayEntry>[
            bottomEntry,
            middleEntry,
            topEntry,
          ],
        ),
      ),
    );

    // All widgets are onstage.
    expect(tester.state<StatefulTestState>(find.byKey(bottom)).rebuildCount, 1);
    expect(tester.state<StatefulTestState>(find.byKey(middle)).rebuildCount, 1);
    expect(tester.state<StatefulTestState>(find.byKey(top)).rebuildCount, 1);

    middleEntry.opaque = true;
    await tester.pump();

    // Bottom widget is offstage and did not rebuild.
    expect(find.byKey(bottom), findsNothing);
    expect(tester.state<StatefulTestState>(find.byKey(bottom, skipOffstage: false)).rebuildCount, 1);
    expect(tester.state<StatefulTestState>(find.byKey(middle)).rebuildCount, 1);
    expect(tester.state<StatefulTestState>(find.byKey(top)).rebuildCount, 1);
  });

  testWidgets('OverlayEntries do not rebuild when opaque entry is added', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/45797.

    final GlobalKey<OverlayState> overlayKey = GlobalKey<OverlayState>();
    final Key bottom = UniqueKey();
    final Key middle = UniqueKey();
    final Key top = UniqueKey();
    final Widget bottomWidget = StatefulTestWidget(key: bottom);
    final Widget middleWidget = StatefulTestWidget(key: middle);
    final Widget topWidget = StatefulTestWidget(key: top);

    final OverlayEntry bottomEntry = OverlayEntry(
      maintainState: true,
      builder: (BuildContext context) {
        return bottomWidget;
      },
    );
    final OverlayEntry middleEntry = OverlayEntry(
      opaque: true,
      maintainState: true,
      builder: (BuildContext context) {
        return middleWidget;
      },
    );
    final OverlayEntry topEntry = OverlayEntry(
      maintainState: true,
      builder: (BuildContext context) {
        return topWidget;
      },
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          key: overlayKey,
          initialEntries: <OverlayEntry>[
            bottomEntry,
            topEntry,
          ],
        ),
      ),
    );

    // Both widgets are onstage.
    expect(tester.state<StatefulTestState>(find.byKey(bottom)).rebuildCount, 1);
    expect(tester.state<StatefulTestState>(find.byKey(top)).rebuildCount, 1);

    overlayKey.currentState!.rearrange(<OverlayEntry>[
      bottomEntry, middleEntry, topEntry,
    ]);
    await tester.pump();

    // Bottom widget is offstage and did not rebuild.
    expect(find.byKey(bottom), findsNothing);
    expect(tester.state<StatefulTestState>(find.byKey(bottom, skipOffstage: false)).rebuildCount, 1);
    expect(tester.state<StatefulTestState>(find.byKey(middle)).rebuildCount, 1);
    expect(tester.state<StatefulTestState>(find.byKey(top)).rebuildCount, 1);
  });

  testWidgets('entries below opaque entries are ignored for hit testing', (WidgetTester tester) async {
    final GlobalKey<OverlayState> overlayKey = GlobalKey<OverlayState>();
    int bottomTapCount = 0;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          key: overlayKey,
          initialEntries: <OverlayEntry>[
            OverlayEntry(
              maintainState: true,
              builder: (BuildContext context) {
                return GestureDetector(
                  onTap: () {
                    bottomTapCount++;
                  },
                );
              },
            ),
          ],
        ),
      ),
    );

    expect(bottomTapCount, 0);
    await tester.tap(find.byKey(overlayKey), warnIfMissed: false); // gesture detector is translucent; no hit is registered between it and the render view
    expect(bottomTapCount, 1);

    overlayKey.currentState!.insert(OverlayEntry(
      maintainState: true,
      opaque: true,
      builder: (BuildContext context) {
        return Container();
      },
    ));
    await tester.pump();

    // Bottom is offstage and does not receive tap events.
    expect(find.byType(GestureDetector), findsNothing);
    expect(find.byType(GestureDetector, skipOffstage: false), findsOneWidget);
    await tester.tap(find.byKey(overlayKey), warnIfMissed: false); // gesture detector is translucent; no hit is registered between it and the render view
    expect(bottomTapCount, 1);

    int topTapCount = 0;
    overlayKey.currentState!.insert(OverlayEntry(
      maintainState: true,
      opaque: true,
      builder: (BuildContext context) {
        return GestureDetector(
          onTap: () {
            topTapCount++;
          },
        );
      },
    ));
    await tester.pump();

    expect(topTapCount, 0);
    await tester.tap(find.byKey(overlayKey), warnIfMissed: false); // gesture detector is translucent; no hit is registered between it and the render view
    expect(topTapCount, 1);
    expect(bottomTapCount, 1);
  });

  testWidgets('Semantics of entries below opaque entries are ignored', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    final GlobalKey<OverlayState> overlayKey = GlobalKey<OverlayState>();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          key: overlayKey,
          initialEntries: <OverlayEntry>[
            OverlayEntry(
              maintainState: true,
              builder: (BuildContext context) {
                return const Text('bottom');
              },
            ),
            OverlayEntry(
              maintainState: true,
              opaque: true,
              builder: (BuildContext context) {
                return const Text('top');
              },
            ),
          ],
        ),
      ),
    );
    expect(find.text('bottom'), findsNothing);
    expect(find.text('bottom', skipOffstage: false), findsOneWidget);
    expect(find.text('top'), findsOneWidget);
    expect(semantics, includesNodeWith(label: 'top'));
    expect(semantics, isNot(includesNodeWith(label: 'bottom')));

    semantics.dispose();
  });

  testWidgets('Can use Positioned within OverlayEntry', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          initialEntries: <OverlayEntry>[
            OverlayEntry(
              builder: (BuildContext context) {
                return const Positioned(
                  left: 145,
                  top: 123,
                  child: Text('positioned child'),
                );
              },
            ),
          ],
        ),
      ),
    );

    expect(tester.getTopLeft(find.text('positioned child')), const Offset(145, 123));
  });

  testWidgets('Overlay can set and update clipBehavior', (WidgetTester tester) async {

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          initialEntries: <OverlayEntry>[
            OverlayEntry(
              builder: (BuildContext context) => Container(),
            ),
          ],
        ),
      ),
    );

    // By default, clipBehavior should be Clip.hardEdge
    final dynamic renderObject = tester.renderObject(find.byType(Overlay));
    expect(renderObject.clipBehavior, equals(Clip.hardEdge));

    for (final Clip clip in Clip.values) {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Overlay(
            initialEntries: <OverlayEntry>[
              OverlayEntry(
                builder: (BuildContext context) => Container(),
              ),
            ],
            clipBehavior: clip,
          ),
        ),
      );
      expect(renderObject.clipBehavior, clip);
    }
  });
}

class StatefulTestWidget extends StatefulWidget {
  const StatefulTestWidget({Key? key}) : super(key: key);

  @override
  State<StatefulTestWidget> createState() => StatefulTestState();
}

class StatefulTestState extends State<StatefulTestWidget> {
  int rebuildCount = 0;

  @override
  Widget build(BuildContext context) {
    rebuildCount += 1;
    return Container();
  }
}
