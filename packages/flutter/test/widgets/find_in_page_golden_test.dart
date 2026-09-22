// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _loadRealFonts() async {
  // Resolve the Flutter root directory to load real Roboto and MaterialIcons
  // fonts when generating local golden PNGs.
  final String? flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot == null) {
    return;
  }
  final String fontDir = '$flutterRoot/bin/cache/artifacts/material_fonts';

  final FontLoader robotoLoader = FontLoader('Roboto');
  final File robotoRegular = File('$fontDir/Roboto-Regular.ttf');
  final File robotoBold = File('$fontDir/Roboto-Bold.ttf');
  final File robotoMedium = File('$fontDir/Roboto-Medium.ttf');
  if (robotoRegular.existsSync()) {
    robotoLoader.addFont(
      Future<ByteData>.value(ByteData.sublistView(robotoRegular.readAsBytesSync())),
    );
  }
  if (robotoBold.existsSync()) {
    robotoLoader.addFont(
      Future<ByteData>.value(ByteData.sublistView(robotoBold.readAsBytesSync())),
    );
  }
  if (robotoMedium.existsSync()) {
    robotoLoader.addFont(
      Future<ByteData>.value(ByteData.sublistView(robotoMedium.readAsBytesSync())),
    );
  }
  await robotoLoader.load();

  final File materialIcons = File('$fontDir/MaterialIcons-Regular.otf');
  if (materialIcons.existsSync()) {
    final FontLoader iconLoader = FontLoader('MaterialIcons');
    iconLoader.addFont(
      Future<ByteData>.value(ByteData.sublistView(materialIcons.readAsBytesSync())),
    );
    await iconLoader.load();
  }
}

Widget _buildMultiWidgetTestBench({
  required FindInPageController findController,
  required ScrollController listScrollController,
  bool enableSelection = false,
}) {
  const TextStyle baseRoboto = TextStyle(fontFamily: 'Roboto');
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B57D0)),
    ),
    home: CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): findController.open,
        const SingleActivator(LogicalKeyboardKey.keyF, meta: true): findController.open,
      },
      child: FindInPageScope(
        enableSelection: enableSelection,
        enableFind: true,
        controller: findController,
        child: SelectionArea(
          child: Scaffold(
            backgroundColor: const Color(0xFFF8FAFD),
            appBar: AppBar(
              backgroundColor: const Color(0xFF0B57D0),
              foregroundColor: Colors.white,
              title: const Text(
                'Flutter Find-in-Page (Cmd+F) — Multi-Widget Showcase',
                style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w700, fontSize: 17),
              ),
            ),
            body: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // 1. RichText / Card with inline WidgetSpan
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: Color(0xFFD3E3FD)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                      child: Text.rich(
                        TextSpan(
                          style: baseRoboto.copyWith(fontSize: 14, color: const Color(0xFF1F1F1F)),
                          children: <InlineSpan>[
                            const TextSpan(
                              text: 'Hero Banner: ',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const TextSpan(
                              text: 'Wrap any screen in SelectionArea to unlock app-level ',
                            ),
                            const TextSpan(
                              text: 'Flutter',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0B57D0),
                              ),
                            ),
                            const TextSpan(text: ' search across '),
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F0FE),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFF0B57D0)),
                                ),
                                child: const Text(
                                  'Inline WidgetSpan: Flutter Chip',
                                  style: TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0B57D0),
                                  ),
                                ),
                              ),
                            ),
                            const TextSpan(text: ' and docs at flutter.dev/to/find-in-page.'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // 2. 3-Column Metric Cards Row
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _MetricCard(
                          title: 'Engine Layer',
                          subtitle: 'Flutter Impeller Canvas',
                          detail: 'Paints highlights inside RenderParagraph',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MetricCard(
                          title: 'Widgets Layer',
                          subtitle: 'Flutter SelectableRegion',
                          detail: 'Find-only mode keeps native button cursors',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MetricCard(
                          title: 'Platform Shortcuts',
                          subtitle: 'Flutter Web & Desktop',
                          detail: 'Cmd+F, Ctrl+F, F3, Shift+F3, and Escape',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // 3. Interactive Controls Row (Buttons & Chips)
                  Row(
                    children: <Widget>[
                      FilledButton(onPressed: () {}, child: const Text('Deploy Flutter App')),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: () {},
                        child: const Text('Run Flutter Golden Suite'),
                      ),
                      const SizedBox(width: 10),
                      const Chip(
                        label: Text('Status: flutter-ready'),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // 4. Clipped Scrollable ListView
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFC4C7C5)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: ListView(
                          controller: listScrollController,
                          padding: const EdgeInsets.all(10),
                          children: const <Widget>[
                            _LogRow(
                              index: 1,
                              text: 'Row 1: Visible viewport item — Flutter RenderParagraph painting active.',
                            ),
                            _LogRow(
                              index: 2,
                              text: 'Row 2: Visible viewport item — Passive yellow (#66FFEB3B) under glyphs.',
                            ),
                            _LogRow(
                              index: 3,
                              text: 'Row 3: Visible viewport item — Flutter SelectionRegistrar tree order.',
                            ),
                            _LogRow(
                              index: 4,
                              text: 'Row 4: Initially below fold — Scrollable viewport clip boundary test.',
                            ),
                            _LogRow(
                              index: 5,
                              text: 'Row 5: Viewport edge — Nested SliverViewport offset calculation.',
                            ),
                            _LogRow(
                              index: 6,
                              text:
                                  'Row 6: Below fold — ClipRRect hides off-screen highlight rects.',
                            ),
                            _LogRow(
                              index: 7,
                              text:
                                  'Row 7: Below fold — Scrollable cacheExtent pre-indexes matches.',
                            ),
                            _LogRow(
                              index: 8,
                              text: 'Row 8: Off-screen match — Flutter showOnScreen auto-scrolled here!',
                            ),
                            _LogRow(
                              index: 9,
                              text: 'Row 9: Off-screen match — Final flutter.dev verification row.',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.title, required this.subtitle, required this.detail});

  final String title;
  final String subtitle;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDADCE0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF5F6368),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F1F1F),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              detail,
              style: const TextStyle(fontFamily: 'Roboto', fontSize: 11, color: Color(0xFF444746)),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogRow extends StatelessWidget {
  const _LogRow({required this.index, required this.text});

  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 6.0),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F3F4),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '#$index',
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF3C4043),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontFamily: 'Roboto', fontSize: 13, color: Color(0xFF1F1F1F)),
            ),
          ),
        ],
      ),
    );
  }
}

void main() {
  setUpAll(() async {
    goldenFileComparator = LocalFileComparator(
      Uri.file(
        '/usr/local/google/home/kevmoo/github/_flutter-find-in-page/packages/flutter/test/widgets/find_in_page_golden_test.dart',
      ),
    );
    await _loadRealFonts();
  });

  group('Find-in-Page (Cmd+F / Ctrl+F) Behavioral & Paint Tests', () {
    testWidgets(
      'Find-Only mode (enableSelection: false, enableFind: true) preserves button cursors and supports Cmd+F',
      (WidgetTester tester) async {
        final FindInPageController findController = FindInPageController();
        final ScrollController scrollController = ScrollController();
        addTearDown(findController.dispose);
        addTearDown(scrollController.dispose);

        await tester.binding.setSurfaceSize(const Size(860, 600));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          _buildMultiWidgetTestBench(
            findController: findController,
            listScrollController: scrollController,
            enableSelection: false,
          ),
        );
        await tester.pumpAndSettle();

        // Verify that in Find-Only mode (enableSelection: false), plain Text widgets
        // do NOT force SystemMouseCursors.text.
        final TestGesture mouseGesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouseGesture.addPointer(location: Offset.zero);
        addTearDown(mouseGesture.removePointer);
        await tester.pump();
        await mouseGesture.moveTo(tester.getCenter(find.text('Engine Layer')));
        await tester.pump();
        expect(
          RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
          isNot(SystemMouseCursors.text),
        );

        // Press Ctrl+F to invoke FindInPageIntent.
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pumpAndSettle();

        expect(findController.isOpen, isTrue);
        expect(find.byType(SelectableRegionFindBar), findsOneWidget);

        // Set query to "flutter" (case-insensitive) and verify matches across all widget types,
        // while the FindBar itself is excluded via SelectionContainer.disabled.
        findController.query = 'flutter';
        await tester.pumpAndSettle();

        expect(findController.matchCount, 14);
        expect(findController.activeMatchIndex, 0);
        expect(find.text('1 / 14', findRichText: true), findsOneWidget);
      },
    );

    testWidgets(
      'Separate Text widgets do not false-match across boundaries, while Text.rich spans match seamlessly',
      (WidgetTester tester) async {
        final FindInPageController findController = FindInPageController();
        addTearDown(findController.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: FindInPageScope(
              enableSelection: false,
              enableFind: true,
              controller: findController,
              child: const SelectionArea(
                child: Scaffold(
                  body: Column(
                    children: <Widget>[
                      Row(children: <Widget>[Text('Hel'), Text('lo')]),
                      Text.rich(
                        TextSpan(
                          children: <InlineSpan>[
                            TextSpan(text: 'Hel'),
                            TextSpan(text: 'lo'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        findController.open(initialQuery: 'Hello');
        await tester.pumpAndSettle();

        // Only the Text.rich span should match "Hello"; the two separate Text('Hel') + Text('lo')
        // leaf Selectables must NOT concatenate into a false cross-cell match.
        expect(findController.matchCount, 1);
        expect(findController.activeMatch?.text, 'Hello');
      },
    );
  });

  group('Find-in-Page Multi-Widget Visual Goldens', () {
    testWidgets(
      'renders passive yellow (#66FFEB3B) and active orange (#CCFF9800) highlights across multi-widget tree and auto-scrolls viewport',
      (WidgetTester tester) async {
        final FindInPageController findController = FindInPageController();
        final ScrollController scrollController = ScrollController();
        addTearDown(findController.dispose);
        addTearDown(scrollController.dispose);

        await tester.binding.setSurfaceSize(const Size(860, 600));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          _buildMultiWidgetTestBench(
            findController: findController,
            listScrollController: scrollController,
            enableSelection: false,
          ),
        );
        await tester.pumpAndSettle();

        // 1. Open Find-in-Page with query "flutter" (case-insensitive)
        findController.open(initialQuery: 'flutter');
        await tester.pumpAndSettle();

        expect(findController.matchCount, 14);
        expect(findController.activeMatchIndex, 0);
        expect(scrollController.offset, 0.0);

        if (autoUpdateGoldenFiles) {
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile('goldens/find_in_page_multi_widget_initial.png'),
          );
        }

        // 2. Step forward to Match #13 (index 12, inside Row 6 at the bottom of the ListView)
        // and verify that RenderObject.showOnScreen automatically scrolls the ListView!
        for (int i = 0; i < 12; i++) {
          findController.nextMatch();
        }
        await tester.pumpAndSettle();

        expect(findController.activeMatchIndex, 12);
        expect(scrollController.offset, greaterThan(40.0));

        if (autoUpdateGoldenFiles) {
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile('goldens/find_in_page_multi_widget_scrolled.png'),
          );
        }

        // 3. Enable Case-Sensitivity ("Aa") so only lowercase "flutter" matches
        findController.caseSensitive = true;
        findController.nextMatch();
        await tester.pumpAndSettle();

        expect(findController.matchCount, 3);
        expect(findController.activeMatchIndex, 0);

        if (autoUpdateGoldenFiles) {
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile('goldens/find_in_page_multi_widget_case_sensitive.png'),
          );
        }
      },
    );
  });
}
