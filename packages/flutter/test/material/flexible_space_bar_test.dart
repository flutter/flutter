// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../widgets/semantics_tester.dart';

void main() {
  testWidgets('FlexibleSpaceBar centers title on iOS', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: Scaffold(
          appBar: AppBar(
            flexibleSpace: const FlexibleSpaceBar(
              title: Text('X'),
            ),
          ),
        ),
      ),
    );

    final Finder title = find.text('X');
    Offset center = tester.getCenter(title);
    Size size = tester.getSize(title);
    expect(center.dx, lessThan(400.0 - size.width / 2.0));

    for (final TargetPlatform platform in <TargetPlatform>[ TargetPlatform.iOS, TargetPlatform.macOS ]) {
      // Clear the widget tree to avoid animating between platforms.
      await tester.pumpWidget(Container(key: UniqueKey()));

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: platform),
          home: Scaffold(
            appBar: AppBar(
              flexibleSpace: const FlexibleSpaceBar(
                title: Text('X'),
              ),
            ),
          ),
        ),
      );

      center = tester.getCenter(title);
      size = tester.getSize(title);
      expect(center.dx, greaterThan(400.0 - size.width / 2.0));
      expect(center.dx, lessThan(400.0 + size.width / 2.0));
    }
  });

  testWidgets('FlexibleSpaceBarSettings provides settings to a FlexibleSpaceBar', (WidgetTester tester) async {
    const double minExtent = 100.0;
    const double initExtent = 200.0;
    const double maxExtent = 300.0;
    const double alpha = 0.5;

    final FlexibleSpaceBarSettings customSettings = FlexibleSpaceBar.createSettings(
      currentExtent: initExtent,
      minExtent: minExtent,
      maxExtent: maxExtent,
      toolbarOpacity: alpha,
      child: AppBar(
        flexibleSpace: const FlexibleSpaceBar(
          title: Text('title'),
          background:  Text('X2'),
          collapseMode: CollapseMode.pin,
        ),
      ),
    ) as FlexibleSpaceBarSettings;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            primary: true,
            slivers: <Widget>[
              SliverPersistentHeader(
                floating: true,
                pinned: true,
                delegate: TestDelegate(settings: customSettings),
              ),
              SliverToBoxAdapter(
                child: Container(
                  height: 1200.0,
                  color: Colors.orange[400],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final RenderBox clipRect = tester.renderObject(find.byType(ClipRect).first);
    final Transform transform = tester.firstWidget(find.byType(Transform));

    // The current (200) is half way between the min (100) and max (300) and the
    // lerp values used to calculate the scale are 1 and 1.5, so we check for 1.25.
    expect(transform.transform.getMaxScaleOnAxis(), 1.25);

    // The space bar rect always starts fully expanded.
    expect(clipRect.size.height, maxExtent);

    final Element actionTextBox = tester.element(find.text('title'));
    final Text textWidget = actionTextBox.widget as Text;
    final DefaultTextStyle defaultTextStyle = DefaultTextStyle.of(actionTextBox);

    TextStyle effectiveStyle = textWidget.style;
    effectiveStyle = defaultTextStyle.style.merge(textWidget.style);
    expect(effectiveStyle.color.alpha, 128); // Which is alpha of .5

    // We drag up to fully collapse the space bar.
    await tester.drag(find.byType(Container).first, const Offset(0, -400.0));
    await tester.pumpAndSettle();

    expect(clipRect.size.height, minExtent);
  });

  testWidgets('Collpased FlexibleSpaceBar has correct semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    const double expandedHeight = 200;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: <Widget>[
              const SliverAppBar(
                pinned: true,
                expandedHeight: expandedHeight,
                title: Text('Title'),
                flexibleSpace: FlexibleSpaceBar(
                  background: Text('Expanded title'),
                ),
              ),
              SliverList(
                delegate: SliverChildListDelegate(
                  <Widget>[
                    for (int i = 0; i < 50; i++)
                      Container(
                        height: 200,
                        child: Center(child: Text('Item $i')),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    TestSemantics expectedSemantics = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          id: 1,
          rect: TestSemantics.fullScreen,
          children: <TestSemantics>[
            TestSemantics(
              id: 2,
              rect: TestSemantics.fullScreen,
              children: <TestSemantics>[
                TestSemantics(
                  id: 3,
                  rect: TestSemantics.fullScreen,
                  flags: <SemanticsFlag>[SemanticsFlag.scopesRoute],
                  children: <TestSemantics>[
                    TestSemantics(
                      id: 4,
                      rect: TestSemantics.fullScreen,
                      children: <TestSemantics>[
                        TestSemantics(
                          id: 9,
                          rect: const Rect.fromLTRB(0.0, 0.0, 800.0, expandedHeight),
                          children: <TestSemantics>[
                            TestSemantics(
                              id: 12,
                              rect: const Rect.fromLTRB(0.0, 0.0, 800.0, 200.0),
                              children: <TestSemantics>[
                                TestSemantics(
                                  id: 13,
                                  rect: const Rect.fromLTRB(0.0, 0.0, 100.0, 20.0),
                                  flags: <SemanticsFlag>[
                                    SemanticsFlag.isHeader,
                                    SemanticsFlag.namesRoute
                                  ],
                                  label: 'Title',
                                  textDirection: TextDirection.ltr,
                                ),
                              ],
                            ),
                            TestSemantics(
                              id: 10,
                              rect: const Rect.fromLTRB(0.0, 0.0, 800.0, 200.0),
                              children: <TestSemantics>[
                                TestSemantics(
                                  id: 11,
                                  rect: const Rect.fromLTRB(0.0, 0.0, 800.0, expandedHeight),
                                  label: 'Expanded title',
                                  textDirection: TextDirection.ltr,
                                ),
                              ],
                            ),
                          ],
                        ),
                        TestSemantics(
                          id: 14,
                          flags: <SemanticsFlag>[SemanticsFlag.hasImplicitScrolling],
                          rect: TestSemantics.fullScreen,
                          actions: <SemanticsAction>[SemanticsAction.scrollUp],
                          children: <TestSemantics>[
                            TestSemantics(
                              id: 5,
                              rect: const Rect.fromLTRB(0.0, 0.0, 800.0, 200.0),
                              label: 'Item 0',
                              textDirection: TextDirection.ltr,
                            ),
                            TestSemantics(
                              id: 6,
                              rect: const Rect.fromLTRB(0.0, 0.0, 800.0, 200.0),
                              label: 'Item 1',
                              textDirection: TextDirection.ltr,
                            ),
                            TestSemantics(
                              id: 7,
                              rect: const Rect.fromLTRB(0.0, 0.0, 800.0, 200.0),
                              flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                              label: 'Item 2',
                              textDirection: TextDirection.ltr,
                            ),
                            TestSemantics(
                              id: 8,
                              rect: const Rect.fromLTRB(0.0, 0.0, 800.0, 50.0),
                              flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                              label: 'Item 3',
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
    );

    expect(semantics, hasSemantics(expectedSemantics, ignoreTransform: true));

    // We drag up to fully collapse the space bar.
    await tester.drag(find.text('Item 1'), const Offset(0, -600.0));
    await tester.pumpAndSettle();

    expectedSemantics = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          id: 1,
          rect: TestSemantics.fullScreen,
          children: <TestSemantics>[
            TestSemantics(
              id: 2,
              rect: TestSemantics.fullScreen,
              children: <TestSemantics>[
                TestSemantics(
                  id: 3,
                  rect: TestSemantics.fullScreen,
                  flags: <SemanticsFlag>[SemanticsFlag.scopesRoute],
                  children: <TestSemantics>[
                    TestSemantics(
                      id: 4,
                      rect: TestSemantics.fullScreen,
                      children: <TestSemantics>[
                        TestSemantics(
                          id: 9,
                          // The app bar is collapsed.
                          rect: const Rect.fromLTRB(0.0, 0.0, 800.0, 56.0),
                          children: <TestSemantics>[
                            TestSemantics(
                              id: 12,
                              rect: const Rect.fromLTRB(0.0, 0.0, 800.0, 56.0),
                              children: <TestSemantics>[
                                TestSemantics(
                                  id: 13,
                                  rect: const Rect.fromLTRB(0.0, 0.0, 100.0, 20.0),
                                  flags: <SemanticsFlag>[
                                    SemanticsFlag.isHeader,
                                    SemanticsFlag.namesRoute
                                  ],
                                  label: 'Title',
                                  textDirection: TextDirection.ltr,
                                ),
                              ],
                            ),
                            // The flexible space bar still persists in the
                            // semantic tree even if it is collapsed.
                            TestSemantics(
                              id: 10,
                              rect: const Rect.fromLTRB(0.0, 0.0, 800.0, 56.0),
                              children: <TestSemantics>[
                                TestSemantics(
                                  id: 11,
                                  rect: const Rect.fromLTRB(0.0, 36.0, 800.0, 92.0),
                                  label: 'Expanded title',
                                  textDirection: TextDirection.ltr,
                                ),
                              ],
                            ),
                          ],
                        ),
                        TestSemantics(
                          id: 14,
                          flags: <SemanticsFlag>[SemanticsFlag.hasImplicitScrolling],
                          rect: TestSemantics.fullScreen,
                          actions: <SemanticsAction>[SemanticsAction.scrollUp, SemanticsAction.scrollDown],
                          children: <TestSemantics>[
                            TestSemantics(
                              id: 5,
                              rect: const Rect.fromLTRB(0.0, 150.0, 800.0, 200.0),
                              flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                              label: 'Item 0',
                              textDirection: TextDirection.ltr,
                            ),
                            TestSemantics(
                              id: 6,
                              rect: const Rect.fromLTRB(0.0, 0.0, 800.0, 200.0),
                              flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                              label: 'Item 1',
                              textDirection: TextDirection.ltr,
                            ),
                            TestSemantics(
                              id: 7,
                              rect: const Rect.fromLTRB(0.0, 56.0, 800.0, 200.0),
                              label: 'Item 2',
                              textDirection: TextDirection.ltr,
                            ),
                            TestSemantics(
                              id: 8,
                              rect: const Rect.fromLTRB(0.0, 0.0, 800.0, 200.0),
                              label: 'Item 3',
                              textDirection: TextDirection.ltr,
                            ),
                            TestSemantics(
                              id: 15,
                              rect: const Rect.fromLTRB(0.0, 0.0, 800.0, 200.0),
                              label: 'Item 4',
                              textDirection: TextDirection.ltr,
                            ),
                            TestSemantics(
                              id: 16,
                              rect: const Rect.fromLTRB(0.0, 0.0, 800.0, 200.0),
                              flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                              label: 'Item 5',
                              textDirection: TextDirection.ltr,
                            ),
                            TestSemantics(
                              id: 17,
                              rect: const Rect.fromLTRB(0.0, 0.0, 800.0, 50.0),
                              flags: <SemanticsFlag>[SemanticsFlag.isHidden],
                              label: 'Item 6',
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
    );

    expect(semantics, hasSemantics(expectedSemantics, ignoreTransform: true));

    semantics.dispose();
  });

  // This is a regression test for https://github.com/flutter/flutter/issues/14227
  testWidgets('FlexibleSpaceBar sets width constraints for the title', (WidgetTester tester) async {
    const double titleFontSize = 20.0;
    const double height = 300.0;
    double width;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) {
              width = MediaQuery.of(context).size.width;
              return CustomScrollView(
                slivers: <Widget>[
                  SliverAppBar(
                    expandedHeight: height,
                    pinned: true,
                    stretch: true,
                    flexibleSpace: FlexibleSpaceBar(
                      titlePadding: EdgeInsets.zero,
                      title: Text(
                        'X' * 2000,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: titleFontSize),
                      ),
                      centerTitle: false,
                    ),
                  ),
                ],
              );
            }
          ),
        ),
      ),
    );

    // The title is scaled and transformed to be 1.5 times bigger, when the
    // FlexibleSpaceBar is fully expanded, thus we expect the width to be
    // 1.5 times smaller than the full width. The height of the text is the same
    // as the font size, with 10 dps bottom margin.
    expect(
      tester.getRect(find.byType(Text)),
      Rect.fromLTRB(
        0,
        height - titleFontSize - 10,
        (width / 1.5).floorToDouble(),
        height - 10,
      ),
    );
  });

  testWidgets('FlexibleSpaceBar test titlePadding defaults', (WidgetTester tester) async {
    Widget buildFrame(TargetPlatform platform, bool centerTitle) {
      return MaterialApp(
        theme: ThemeData(platform: platform),
        home: Scaffold(
          appBar: AppBar(
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: centerTitle,
              title: const Text('X'),
            ),
          ),
        ),
      );
    }

    final Finder title = find.text('X');
    final Finder flexibleSpaceBar = find.byType(FlexibleSpaceBar);
    Offset getTitleBottomLeft() {
      return Offset(
        tester.getTopLeft(title).dx,
        tester.getBottomRight(flexibleSpaceBar).dy - tester.getBottomRight(title).dy,
      );
    }

    await tester.pumpWidget(buildFrame(TargetPlatform.android, null));
    expect(getTitleBottomLeft(), const Offset(72.0, 16.0));

    await tester.pumpWidget(buildFrame(TargetPlatform.android, true));
    expect(getTitleBottomLeft(), const Offset(390.0, 16.0));

    // Clear the widget tree to avoid animating between Android and iOS.
    await tester.pumpWidget(Container(key: UniqueKey()));

    await tester.pumpWidget(buildFrame(TargetPlatform.iOS, null));
    expect(getTitleBottomLeft(), const Offset(390.0, 16.0));

    await tester.pumpWidget(buildFrame(TargetPlatform.iOS, false));
    expect(getTitleBottomLeft(), const Offset(72.0, 16.0));

    // Clear the widget tree to avoid animating between iOS and macOS.
    await tester.pumpWidget(Container(key: UniqueKey()));

    await tester.pumpWidget(buildFrame(TargetPlatform.macOS, null));
    expect(getTitleBottomLeft(), const Offset(390.0, 16.0));

    await tester.pumpWidget(buildFrame(TargetPlatform.macOS, false));
    expect(getTitleBottomLeft(), const Offset(72.0, 16.0));

  });

  testWidgets('FlexibleSpaceBar test titlePadding override', (WidgetTester tester) async {
    Widget buildFrame(TargetPlatform platform, bool centerTitle) {
      return MaterialApp(
        theme: ThemeData(platform: platform),
        home: Scaffold(
          appBar: AppBar(
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: EdgeInsets.zero,
              centerTitle: centerTitle,
              title: const Text('X'),
            ),
          ),
        ),
      );
    }

    final Finder title = find.text('X');
    final Finder flexibleSpaceBar = find.byType(FlexibleSpaceBar);
    Offset getTitleBottomLeft() {
      return Offset(
        tester.getTopLeft(title).dx,
        tester.getBottomRight(flexibleSpaceBar).dy - tester.getBottomRight(title).dy,
      );
    }

    await tester.pumpWidget(buildFrame(TargetPlatform.android, null));
    expect(getTitleBottomLeft(), Offset.zero);

    await tester.pumpWidget(buildFrame(TargetPlatform.android, true));
    expect(getTitleBottomLeft(), const Offset(390.0, 0.0));

    // Clear the widget tree to avoid animating between platforms.
    await tester.pumpWidget(Container(key: UniqueKey()));

    await tester.pumpWidget(buildFrame(TargetPlatform.iOS, null));
    expect(getTitleBottomLeft(), const Offset(390.0, 0.0));

    await tester.pumpWidget(buildFrame(TargetPlatform.iOS, false));
    expect(getTitleBottomLeft(), Offset.zero);

    // Clear the widget tree to avoid animating between platforms.
    await tester.pumpWidget(Container(key: UniqueKey()));

    await tester.pumpWidget(buildFrame(TargetPlatform.macOS, null));
    expect(getTitleBottomLeft(), const Offset(390.0, 0.0));

    await tester.pumpWidget(buildFrame(TargetPlatform.macOS, false));
    expect(getTitleBottomLeft(), Offset.zero);

    // Clear the widget tree to avoid animating between platforms.
    await tester.pumpWidget(Container(key: UniqueKey()));

    await tester.pumpWidget(buildFrame(TargetPlatform.windows, null));
    expect(getTitleBottomLeft(), Offset.zero);

    await tester.pumpWidget(buildFrame(TargetPlatform.windows, true));
    expect(getTitleBottomLeft(), const Offset(390.0, 0.0));

    // Clear the widget tree to avoid animating between platforms.
    await tester.pumpWidget(Container(key: UniqueKey()));

    await tester.pumpWidget(buildFrame(TargetPlatform.linux, null));
    expect(getTitleBottomLeft(), Offset.zero);

    await tester.pumpWidget(buildFrame(TargetPlatform.linux, true));
    expect(getTitleBottomLeft(), const Offset(390.0, 0.0));
  });
}

class TestDelegate extends SliverPersistentHeaderDelegate {

  const TestDelegate({
    this.settings,
  });

  final FlexibleSpaceBarSettings settings;

  @override
  double get maxExtent => settings.maxExtent;

  @override
  double get minExtent => settings.minExtent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return settings;
  }

  @override
  bool shouldRebuild(TestDelegate oldDelegate) => false;
}
