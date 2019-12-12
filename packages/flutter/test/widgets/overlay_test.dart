// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

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
                final Overlay overlay = context.findAncestorWidgetOfExactType<Overlay>();
                expect(overlay, isNotNull);
                expect(overlay.key, equals(overlayKey));
                return Container();
              },
            ),
          ],
        ),
      ),
    );
    expect(didBuild, isTrue);
    final RenderObject theater = overlayKey.currentContext.findRenderObject();

    expect(theater, hasAGoodToStringDeep);
    expect(
      theater.toStringDeep(minLevel: DiagnosticLevel.info),
      equalsIgnoringHashCodes(
        '_RenderTheatre#f5cf2\n'
            ' │ parentData: <none>\n'
            ' │ constraints: BoxConstraints(w=800.0, h=600.0)\n'
            ' │ size: Size(800.0, 600.0)\n'
            ' │\n'
            ' ├─onstage: RenderStack#39819\n'
            ' ╎ │ parentData: not positioned; offset=Offset(0.0, 0.0) (can use\n'
            ' ╎ │   size)\n'
            ' ╎ │ constraints: BoxConstraints(w=800.0, h=600.0)\n'
            ' ╎ │ size: Size(800.0, 600.0)\n'
            ' ╎ │ alignment: AlignmentDirectional.topStart\n'
            ' ╎ │ textDirection: ltr\n'
            ' ╎ │ fit: expand\n'
            ' ╎ │ overflow: clip\n'
            ' ╎ │\n'
            ' ╎ └─child 1: RenderLimitedBox#d1448\n'
            ' ╎   │ parentData: not positioned; offset=Offset(0.0, 0.0) (can use\n'
            ' ╎   │   size)\n'
            ' ╎   │ constraints: BoxConstraints(w=800.0, h=600.0)\n'
            ' ╎   │ size: Size(800.0, 600.0)\n'
            ' ╎   │ maxWidth: 0.0\n'
            ' ╎   │ maxHeight: 0.0\n'
            ' ╎   │\n'
            ' ╎   └─child: RenderConstrainedBox#e8b87\n'
            ' ╎       parentData: <none> (can use size)\n'
            ' ╎       constraints: BoxConstraints(w=800.0, h=600.0)\n'
            ' ╎       size: Size(800.0, 600.0)\n'
            ' ╎       additionalConstraints: BoxConstraints(biggest)\n'
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
    final RenderObject theater = overlayKey.currentContext.findRenderObject();

    expect(theater, hasAGoodToStringDeep);
    expect(
      theater.toStringDeep(minLevel: DiagnosticLevel.info),
      equalsIgnoringHashCodes(
        '_RenderTheatre#b22a8\n'
        ' │ parentData: <none>\n'
        ' │ constraints: BoxConstraints(w=800.0, h=600.0)\n'
        ' │ size: Size(800.0, 600.0)\n'
        ' │\n'
        ' ├─onstage: RenderStack#eab87\n'
        ' ╎ │ parentData: not positioned; offset=Offset(0.0, 0.0) (can use\n'
        ' ╎ │   size)\n'
        ' ╎ │ constraints: BoxConstraints(w=800.0, h=600.0)\n'
        ' ╎ │ size: Size(800.0, 600.0)\n'
        ' ╎ │ alignment: AlignmentDirectional.topStart\n'
        ' ╎ │ textDirection: ltr\n'
        ' ╎ │ fit: expand\n'
        ' ╎ │ overflow: clip\n'
        ' ╎ │\n'
        ' ╎ └─child 1: RenderLimitedBox#ca15b\n'
        ' ╎   │ parentData: not positioned; offset=Offset(0.0, 0.0) (can use\n'
        ' ╎   │   size)\n'
        ' ╎   │ constraints: BoxConstraints(w=800.0, h=600.0)\n'
        ' ╎   │ size: Size(800.0, 600.0)\n'
        ' ╎   │ maxWidth: 0.0\n'
        ' ╎   │ maxHeight: 0.0\n'
        ' ╎   │\n'
        ' ╎   └─child: RenderConstrainedBox#dffe5\n'
        ' ╎       parentData: <none> (can use size)\n'
        ' ╎       constraints: BoxConstraints(w=800.0, h=600.0)\n'
        ' ╎       size: Size(800.0, 600.0)\n'
        ' ╎       additionalConstraints: BoxConstraints(biggest)\n'
        ' ╎\n'
        ' ╎╌offstage 1: RenderLimitedBox#b6f09 NEEDS-LAYOUT NEEDS-PAINT\n'
        ' ╎ │ parentData: not positioned; offset=Offset(0.0, 0.0)\n'
        ' ╎ │ constraints: MISSING\n'
        ' ╎ │ size: MISSING\n'
        ' ╎ │ maxWidth: 0.0\n'
        ' ╎ │ maxHeight: 0.0\n'
        ' ╎ │\n'
        ' ╎ └─child: RenderConstrainedBox#5a057 NEEDS-LAYOUT NEEDS-PAINT\n'
        ' ╎     parentData: <none>\n'
        ' ╎     constraints: MISSING\n'
        ' ╎     size: MISSING\n'
        ' ╎     additionalConstraints: BoxConstraints(biggest)\n'
        ' ╎\n'
        ' └╌offstage 2: RenderLimitedBox#f689e NEEDS-LAYOUT NEEDS-PAINT\n'
        '   │ parentData: not positioned; offset=Offset(0.0, 0.0)\n'
        '   │ constraints: MISSING\n'
        '   │ size: MISSING\n'
        '   │ maxWidth: 0.0\n'
        '   │ maxHeight: 0.0\n'
        '   │\n'
        '   └─child: RenderConstrainedBox#c15f0 NEEDS-LAYOUT NEEDS-PAINT\n'
        '       parentData: <none>\n'
        '       constraints: MISSING\n'
        '       size: MISSING\n'
        '       additionalConstraints: BoxConstraints(biggest)\n'
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
    final OverlayState overlay = overlayKey.currentState;
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
    final OverlayState overlay = overlayKey.currentState;
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
    final OverlayState overlay = overlayKey.currentState;
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
    final OverlayState overlay = overlayKey.currentState;
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
    final OverlayState overlay = overlayKey.currentState;
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
    final OverlayState overlay = overlayKey.currentState;
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
    final OverlayState overlay = overlayKey.currentState;
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
    final OverlayState overlay = overlayKey.currentState;
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
    final OverlayState overlay = overlayKey.currentState;
    overlay.rearrange(rearranged, below: initialEntries[2]);
    await tester.pump();

    expect(buildOrder, <int>[3, 4, 1, 2, 0]);
  });

  testWidgets('OverlayState.of() called without Overlay being exist', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Builder(
          builder: (BuildContext context) {
            FlutterError error;
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
              expect(error.diagnostics[3], isInstanceOf<DiagnosticsProperty<Widget>>());
              expect(error.diagnostics[3].value, debugRequiredFor);
              expect(error.diagnostics[4], isInstanceOf<DiagnosticsProperty<Element>>());
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
    overlayKey.currentState.insert(newEntry);
    await tester.pumpAndSettle();

    expect(find.byKey(root), findsNothing);
    expect(find.byKey(top), findsOneWidget);
  });
}
