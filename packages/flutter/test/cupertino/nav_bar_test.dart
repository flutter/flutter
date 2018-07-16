// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../widgets/semantics_tester.dart';

int count = 0;

void main() {
  testWidgets('Middle still in center with asymmetrical actions', (WidgetTester tester) async {
    await tester.pumpWidget(
      new CupertinoApp(
        home: const CupertinoNavigationBar(
          leading: const CupertinoButton(child: const Text('Something'), onPressed: null,),
          middle: const Text('Title'),
        ),
      ),
    );

    // Expect the middle of the title to be exactly in the middle of the screen.
    expect(tester.getCenter(find.text('Title')).dx, 400.0);
  });

  testWidgets('Middle still in center with back button', (WidgetTester tester) async {
    await tester.pumpWidget(
      new CupertinoApp(
        home: const CupertinoNavigationBar(
          middle: const Text('Title'),
        ),
      ),
    );

    tester.state<NavigatorState>(find.byType(Navigator)).push(new CupertinoPageRoute<void>(
      builder: (BuildContext context) {
        return const CupertinoNavigationBar(
          middle: const Text('Page 2'),
        );
      },
    ));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Expect the middle of the title to be exactly in the middle of the screen.
    expect(tester.getCenter(find.text('Page 2')).dx, 400.0);
  });

  testWidgets('Opaque background does not add blur effects', (WidgetTester tester) async {
    await tester.pumpWidget(
      new CupertinoApp(
        home: const CupertinoNavigationBar(
          middle: const Text('Title'),
          backgroundColor: const Color(0xFFE5E5E5),
        ),
      ),
    );
    expect(find.byType(BackdropFilter), findsNothing);
  });

  testWidgets('Non-opaque background adds blur effects', (WidgetTester tester) async {
    await tester.pumpWidget(
      new CupertinoApp(
        home: const CupertinoNavigationBar(
          middle: const Text('Title'),
        ),
      ),
    );
    expect(find.byType(BackdropFilter), findsOneWidget);
  });

  testWidgets('Can specify custom padding', (WidgetTester tester) async {
    final Key middleBox = new GlobalKey();
    await tester.pumpWidget(
      new CupertinoApp(
        home: new Align(
          alignment: Alignment.topCenter,
          child: new CupertinoNavigationBar(
            leading: const CupertinoButton(child: const Text('Cheetah'), onPressed: null),
            // Let the box take all the vertical space to test vertical padding but let
            // the nav bar position it horizontally.
            middle: new Align(
              key: middleBox,
              alignment: Alignment.center,
              widthFactor: 1.0,
              child: const Text('Title')
            ),
            trailing: const CupertinoButton(child: const Text('Puma'), onPressed: null),
            padding: const EdgeInsetsDirectional.only(
              start: 10.0,
              end: 20.0,
              top: 3.0,
              bottom: 4.0,
            ),
          ),
        ),
      ),
    );

    expect(tester.getRect(find.byKey(middleBox)).top, 3.0);
    // 44 is the standard height of the nav bar.
    expect(
      tester.getRect(find.byKey(middleBox)).bottom,
      // 44 is the standard height of the nav bar.
      44.0 - 4.0,
    );

    expect(tester.getTopLeft(find.widgetWithText(CupertinoButton, 'Cheetah')).dx, 10.0);
    expect(tester.getTopRight(find.widgetWithText(CupertinoButton, 'Puma')).dx, 800.0 - 20.0);

    // Title is still exactly centered.
    expect(tester.getCenter(find.text('Title')).dx, 400.0);
  });

  testWidgets('Padding works in RTL', (WidgetTester tester) async {
    await tester.pumpWidget(
      new CupertinoApp(
        home: const Directionality(
          textDirection: TextDirection.rtl,
          child: const Align(
            alignment: Alignment.topCenter,
            child: const CupertinoNavigationBar(
              leading: const CupertinoButton(child: const Text('Cheetah'), onPressed: null),
              // Let the box take all the vertical space to test vertical padding but let
              // the nav bar position it horizontally.
              middle: const Text('Title'),
              trailing: const CupertinoButton(child: const Text('Puma'), onPressed: null),
              padding: const EdgeInsetsDirectional.only(
                start: 10.0,
                end: 20.0,
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.getTopRight(find.widgetWithText(CupertinoButton, 'Cheetah')).dx, 800.0 - 10.0);
    expect(tester.getTopLeft(find.widgetWithText(CupertinoButton, 'Puma')).dx, 20.0);

    // Title is still exactly centered.
    expect(tester.getCenter(find.text('Title')).dx, 400.0);
  });

  testWidgets('Verify styles of each slot', (WidgetTester tester) async {
    count = 0x000000;
    await tester.pumpWidget(
      new CupertinoApp(
        home: const CupertinoNavigationBar(
          leading: const _ExpectStyles(color: const Color(0xFF001122), index: 0x000001),
          middle: const _ExpectStyles(color: const Color(0xFF000000), letterSpacing: -0.08, index: 0x000100),
          trailing: const _ExpectStyles(color: const Color(0xFF001122), index: 0x010000),
          actionsForegroundColor: const Color(0xFF001122),
        ),
      ),
    );
    expect(count, 0x010101);
  });

  testWidgets('No slivers with no large titles', (WidgetTester tester) async {
    await tester.pumpWidget(
      new CupertinoApp(
        home: const CupertinoPageScaffold(
          navigationBar: const CupertinoNavigationBar(
            middle: const Text('Title'),
          ),
          child: const Center(),
        ),
      ),
    );

    expect(find.byType(SliverPersistentHeader), findsNothing);
  });

  testWidgets('Media padding is applied to CupertinoSliverNavigationBar', (WidgetTester tester) async {
    final ScrollController scrollController = new ScrollController();
    final Key leadingKey = new GlobalKey();
    final Key middleKey = new GlobalKey();
    final Key trailingKey = new GlobalKey();
    final Key titleKey = new GlobalKey();
    await tester.pumpWidget(
      new CupertinoApp(
        home: new MediaQuery(
          data: const MediaQueryData(
            padding: const EdgeInsets.only(
              top: 10.0,
              left: 20.0,
              bottom: 30.0,
              right: 40.0,
            ),
          ),
          child: new CupertinoPageScaffold(
            child: new CustomScrollView(
              controller: scrollController,
              slivers: <Widget>[
                new CupertinoSliverNavigationBar(
                  leading: new Placeholder(key: leadingKey),
                  middle: new Placeholder(key: middleKey),
                  largeTitle: new Text('Large Title', key: titleKey),
                  trailing: new Placeholder(key: trailingKey),
                ),
                new SliverToBoxAdapter(
                  child: new Container(
                    height: 1200.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Media padding applied to leading (T,L), middle (T), trailing (T, R).
    expect(tester.getTopLeft(find.byKey(leadingKey)), const Offset(16.0 + 20.0, 10.0));
    expect(tester.getRect(find.byKey(middleKey)).top, 10.0);
    expect(tester.getTopRight(find.byKey(trailingKey)), const Offset(800.0 - 16.0 - 40.0, 10.0));

    // Top and left padding is applied to large title.
    expect(tester.getTopLeft(find.byKey(titleKey)), const Offset(16.0 + 20.0, 54.0 + 10.0));
  });

  testWidgets('Large title nav bar scrolls', (WidgetTester tester) async {
    final ScrollController scrollController = new ScrollController();
    await tester.pumpWidget(
      new CupertinoApp(
        home: new CupertinoPageScaffold(
          child: new CustomScrollView(
            controller: scrollController,
            slivers: <Widget>[
              const CupertinoSliverNavigationBar(
                largeTitle: const Text('Title'),
              ),
              new SliverToBoxAdapter(
                child: new Container(
                  height: 1200.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(scrollController.offset, 0.0);
    expect(tester.getTopLeft(find.byType(NavigationToolbar)).dy, 0.0);
    expect(tester.getSize(find.byType(NavigationToolbar)).height, 44.0);

    expect(find.text('Title'), findsNWidgets(2)); // Though only one is visible.

    List<Element> titles = tester.elementList(find.text('Title'))
        .toList()
        ..sort((Element a, Element b) {
          final RenderParagraph aParagraph = a.renderObject;
          final RenderParagraph bParagraph = b.renderObject;
          return aParagraph.text.style.fontSize.compareTo(bParagraph.text.style.fontSize);
        });

    Iterable<double> opacities = titles.map((Element element) {
      final RenderAnimatedOpacity renderOpacity = element.ancestorRenderObjectOfType(const TypeMatcher<RenderAnimatedOpacity>());
      return renderOpacity.opacity.value;
    });

    expect(opacities, <double> [
        0.0, // Initially the smaller font title is invisible.
        1.0, // The larger font title is visible.
    ]);

    expect(tester.getTopLeft(find.widgetWithText(OverflowBox, 'Title')).dy, 44.0);
    expect(tester.getSize(find.widgetWithText(OverflowBox, 'Title')).height, 52.0);

    scrollController.jumpTo(600.0);
    await tester.pump(); // Once to trigger the opacity animation.
    await tester.pump(const Duration(milliseconds: 300));

    titles = tester.elementList(find.text('Title'))
        .toList()
        ..sort((Element a, Element b) {
          final RenderParagraph aParagraph = a.renderObject;
          final RenderParagraph bParagraph = b.renderObject;
          return aParagraph.text.style.fontSize.compareTo(bParagraph.text.style.fontSize);
        });

    opacities = titles.map((Element element) {
      final RenderAnimatedOpacity renderOpacity = element.ancestorRenderObjectOfType(const TypeMatcher<RenderAnimatedOpacity>());
      return renderOpacity.opacity.value;
    });

    expect(opacities, <double> [
        1.0, // Smaller font title now visible
        0.0, // Larger font title invisible.
    ]);

    // The persistent toolbar doesn't move or change size.
    expect(tester.getTopLeft(find.byType(NavigationToolbar)).dy, 0.0);
    expect(tester.getSize(find.byType(NavigationToolbar)).height, 44.0);

    expect(tester.getTopLeft(find.widgetWithText(OverflowBox, 'Title')).dy, 44.0);
    // The OverflowBox is squished with the text in it.
    expect(tester.getSize(find.widgetWithText(OverflowBox, 'Title')).height, 0.0);
  });

  testWidgets('Small title can be overridden', (WidgetTester tester) async {
    final ScrollController scrollController = new ScrollController();
    await tester.pumpWidget(
      new CupertinoApp(
        home: new CupertinoPageScaffold(
          child: new CustomScrollView(
            controller: scrollController,
            slivers: <Widget>[
              const CupertinoSliverNavigationBar(
                middle: const Text('Different title'),
                largeTitle: const Text('Title'),
              ),
              new SliverToBoxAdapter(
                child: new Container(
                  height: 1200.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(scrollController.offset, 0.0);
    expect(tester.getTopLeft(find.byType(NavigationToolbar)).dy, 0.0);
    expect(tester.getSize(find.byType(NavigationToolbar)).height, 44.0);

    expect(find.text('Title'), findsOneWidget);
    expect(find.text('Different title'), findsOneWidget);

    RenderAnimatedOpacity largeTitleOpacity =
        tester.element(find.text('Title')).ancestorRenderObjectOfType(const TypeMatcher<RenderAnimatedOpacity>());
    // Large title initially visible.
    expect(
      largeTitleOpacity.opacity.value,
      1.0
    );
    // Middle widget not even wrapped with RenderOpacity, i.e. is always visible.
    expect(
      tester.element(find.text('Different title')).ancestorRenderObjectOfType(const TypeMatcher<RenderOpacity>()),
      isNull,
    );

    expect(tester.getBottomLeft(find.text('Title')).dy, 44.0 + 52.0 - 8.0); // Static part + extension - padding.

    scrollController.jumpTo(600.0);
    await tester.pump(); // Once to trigger the opacity animation.
    await tester.pump(const Duration(milliseconds: 300));

    largeTitleOpacity =
        tester.element(find.text('Title')).ancestorRenderObjectOfType(const TypeMatcher<RenderAnimatedOpacity>());
    // Large title no longer visible.
    expect(
      largeTitleOpacity.opacity.value,
      0.0
    );

    // The persistent toolbar doesn't move or change size.
    expect(tester.getTopLeft(find.byType(NavigationToolbar)).dy, 0.0);
    expect(tester.getSize(find.byType(NavigationToolbar)).height, 44.0);

    expect(tester.getBottomLeft(find.text('Title')).dy, 44.0 - 8.0); // Extension gone, (static part - padding) left.
  });

  testWidgets('Auto back/close button', (WidgetTester tester) async {
    await tester.pumpWidget(
      new CupertinoApp(
        home: const CupertinoNavigationBar(
          middle: const Text('Home page'),
        ),
      ),
    );

    expect(find.byType(CupertinoButton), findsNothing);

    tester.state<NavigatorState>(find.byType(Navigator)).push(new CupertinoPageRoute<void>(
      builder: (BuildContext context) {
        return const CupertinoNavigationBar(
          middle: const Text('Page 2'),
        );
      },
    ));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(CupertinoButton), findsOneWidget);
    expect(find.byType(Icon), findsOneWidget);

    tester.state<NavigatorState>(find.byType(Navigator)).push(new CupertinoPageRoute<void>(
      fullscreenDialog: true,
      builder: (BuildContext context) {
        return const CupertinoNavigationBar(
          middle: const Text('Dialog page'),
        );
      },
    ));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(CupertinoButton), findsNWidgets(2));
    expect(find.text('Close'), findsOneWidget);

    // Test popping goes back correctly.
    await tester.tap(find.text('Close'));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Page 2'), findsOneWidget);

    await tester.tap(find.byType(Icon));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Home page'), findsOneWidget);
  });

  testWidgets('Border should be displayed by default', (WidgetTester tester) async {
    await tester.pumpWidget(
      new CupertinoApp(
        home: const CupertinoNavigationBar(
          middle: const Text('Title'),
        ),
      ),
    );

    final DecoratedBox decoratedBox = tester.widgetList(find.descendant(
      of: find.byType(CupertinoNavigationBar),
      matching: find.byType(DecoratedBox),
    )).first;
    expect(decoratedBox.decoration.runtimeType, BoxDecoration);

    final BoxDecoration decoration = decoratedBox.decoration;
    expect(decoration.border, isNotNull);

    final BorderSide side = decoration.border.bottom;
    expect(side, isNotNull);
  });

  testWidgets('Overrides border color', (WidgetTester tester) async {
    await tester.pumpWidget(
      new CupertinoApp(
        home: const CupertinoNavigationBar(
          middle: const Text('Title'),
          border: const Border(
            bottom: const BorderSide(
              color: const Color(0xFFAABBCC),
              width: 0.0,
            ),
          ),
        ),
      ),
    );

    final DecoratedBox decoratedBox = tester.widgetList(find.descendant(
      of: find.byType(CupertinoNavigationBar),
      matching: find.byType(DecoratedBox),
    )).first;
    expect(decoratedBox.decoration.runtimeType, BoxDecoration);

    final BoxDecoration decoration = decoratedBox.decoration;
    expect(decoration.border, isNotNull);

    final BorderSide side = decoration.border.bottom;
    expect(side, isNotNull);
    expect(side.color, const Color(0xFFAABBCC));
  });

  testWidgets('Border should not be displayed when null', (WidgetTester tester) async {
    await tester.pumpWidget(
      new CupertinoApp(
        home: const CupertinoNavigationBar(
          middle: const Text('Title'),
          border: null,
        ),
      ),
    );

    final DecoratedBox decoratedBox = tester.widgetList(find.descendant(
      of: find.byType(CupertinoNavigationBar),
      matching: find.byType(DecoratedBox),
    )).first;
    expect(decoratedBox.decoration.runtimeType, BoxDecoration);

    final BoxDecoration decoration = decoratedBox.decoration;
    expect(decoration.border, isNull);
  });

  testWidgets(
      'Border is displayed by default in sliver nav bar',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      new CupertinoApp(
        home: new CupertinoPageScaffold(
          child: new CustomScrollView(
            slivers: const <Widget>[
              const CupertinoSliverNavigationBar(
                largeTitle: const Text('Large Title'),
              ),
            ],
          ),
        ),
      ),
    );

    final DecoratedBox decoratedBox = tester.widgetList(find.descendant(
      of: find.byType(CupertinoSliverNavigationBar),
      matching: find.byType(DecoratedBox),
    )).first;
    expect(decoratedBox.decoration.runtimeType, BoxDecoration);

    final BoxDecoration decoration = decoratedBox.decoration;
    expect(decoration.border, isNotNull);

    final BorderSide bottom = decoration.border.bottom;
    expect(bottom, isNotNull);
  });

  testWidgets(
      'Border is not displayed when null in sliver nav bar',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      new CupertinoApp(
        home: new CupertinoPageScaffold(
          child: new CustomScrollView(
            slivers: const <Widget>[
              const CupertinoSliverNavigationBar(
                largeTitle: const Text('Large Title'),
                border: null,
              ),
            ],
          ),
        ),
      ),
    );

    final DecoratedBox decoratedBox = tester.widgetList(find.descendant(
      of: find.byType(CupertinoSliverNavigationBar),
      matching: find.byType(DecoratedBox),
    )).first;
    expect(decoratedBox.decoration.runtimeType, BoxDecoration);

    final BoxDecoration decoration = decoratedBox.decoration;
    expect(decoration.border, isNull);
  });

  testWidgets('CupertinoSliverNavigationBar has semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    await tester.pumpWidget(new CupertinoApp(
      home: new CupertinoPageScaffold(
        child: new CustomScrollView(
          slivers: const <Widget>[
            const CupertinoSliverNavigationBar(
              largeTitle: const Text('Large Title'),
              border: null,
            ),
          ],
        ),
      ),
    ));

    expect(semantics.nodesWith(
      label: 'Large Title',
      flags: <SemanticsFlag>[SemanticsFlag.isHeader],
      textDirection: TextDirection.ltr,
    ), hasLength(1));

    semantics.dispose();
  });

  testWidgets('CupertinoNavigationBar has semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    await tester.pumpWidget(new CupertinoApp(
      home: new CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: const Text('Fixed Title'),
        ),
        child: new Container(),
      ),
    ));

    expect(semantics.nodesWith(
      label: 'Fixed Title',
      flags: <SemanticsFlag>[SemanticsFlag.isHeader],
      textDirection: TextDirection.ltr,
    ), hasLength(1));

    semantics.dispose();
  });

  testWidgets(
      'Border can be overridden in sliver nav bar',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      new CupertinoApp(
        home: new CupertinoPageScaffold(
          child: new CustomScrollView(
            slivers: const <Widget>[
              const CupertinoSliverNavigationBar(
                largeTitle: const Text('Large Title'),
                border: const Border(
                  bottom: const BorderSide(
                    color: const Color(0xFFAABBCC),
                    width: 0.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final DecoratedBox decoratedBox = tester.widgetList(find.descendant(
      of: find.byType(CupertinoSliverNavigationBar),
      matching: find.byType(DecoratedBox),
    )).first;
    expect(decoratedBox.decoration.runtimeType, BoxDecoration);

    final BoxDecoration decoration = decoratedBox.decoration;
    expect(decoration.border, isNotNull);

    final BorderSide top = decoration.border.top;
    expect(top, isNotNull);
    expect(top, BorderSide.none);
    final BorderSide bottom = decoration.border.bottom;
    expect(bottom, isNotNull);
    expect(bottom.color, const Color(0xFFAABBCC));
  });

  testWidgets(
    'Standard title golden',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        new CupertinoApp(
          home: const RepaintBoundary(
            child: const CupertinoPageScaffold(
              navigationBar: const CupertinoNavigationBar(
                middle: const Text('Bling bling'),
              ),
              child: const Center(),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(RepaintBoundary).last,
        matchesGoldenFile('nav_bar_test.standard_title.1.png'),
      );
    },
    // TODO(xster): remove once https://github.com/flutter/flutter/issues/17483
    // is fixed.
    skip: !Platform.isLinux,
  );

  testWidgets(
    'Large title golden',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        new CupertinoApp(
          home: new RepaintBoundary(
            child: new CupertinoPageScaffold(
              child: new CustomScrollView(
                slivers: <Widget>[
                  const CupertinoSliverNavigationBar(
                    largeTitle: const Text('Bling bling'),
                  ),
                  new SliverToBoxAdapter(
                    child: new Container(
                      height: 1200.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(RepaintBoundary).last,
        matchesGoldenFile('nav_bar_test.large_title.1.png'),
      );
    },
    // TODO(xster): remove once https://github.com/flutter/flutter/issues/17483
    // is fixed.
    skip: !Platform.isLinux,
   );


  testWidgets('NavBar draws a light system bar for a dark background', (WidgetTester tester) async {
    await tester.pumpWidget(
      new WidgetsApp(
        color: const Color(0xFFFFFFFF),
        onGenerateRoute: (RouteSettings settings) {
          return new CupertinoPageRoute<void>(
            settings: settings,
            builder: (BuildContext context) {
              return const CupertinoNavigationBar(
                middle: const Text('Test'),
                backgroundColor: const Color(0xFF000000),
              );
            },
          );
        },
      ),
    );
    expect(SystemChrome.latestStyle, SystemUiOverlayStyle.light);
  });

  testWidgets('NavBar draws a dark system bar for a light background', (WidgetTester tester) async {
    await tester.pumpWidget(
      new WidgetsApp(
        color: const Color(0xFFFFFFFF),
        onGenerateRoute: (RouteSettings settings) {
          return new CupertinoPageRoute<void>(
            settings: settings,
            builder: (BuildContext context) {
              return const CupertinoNavigationBar(
                middle: const Text('Test'),
                backgroundColor: const Color(0xFFFFFFFF),
              );
            },
          );
        },
      ),
    );
    expect(SystemChrome.latestStyle, SystemUiOverlayStyle.dark);
  });
}

class _ExpectStyles extends StatelessWidget {
  const _ExpectStyles({ this.color, this.letterSpacing, this.index });

  final Color color;
  final double letterSpacing;
  final int index;

  @override
  Widget build(BuildContext context) {
    final TextStyle style = DefaultTextStyle.of(context).style;
    expect(style.color, color);
    expect(style.fontSize, 17.0);
    expect(style.letterSpacing, letterSpacing ?? -0.24);
    count += index;
    return new Container();
  }
}
