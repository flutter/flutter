// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_page_tester.dart';

void main() {
  Future<void> buildPages(
    List<Page<void>> pages,
    WidgetTester tester, {
    GlobalKey<NavigatorState>? navKey,
    required List<Page<void>> removedPage,
  }) {
    return tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData.fromView(tester.view),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Navigator(key: navKey, pages: pages, onDidRemovePage: removedPage.add),
        ),
      ),
    );
  }

  testWidgets('Page API will not call onDidRemovePage', (WidgetTester tester) async {
    final removedPages = <Page<void>>[];

    const page = TestPage<void>(key: ValueKey<String>('page'), child: Text('page'));
    const page1 = TestPage<void>(key: ValueKey<String>('page1'), child: Text('page1'));
    const page2 = TestPage<void>(key: ValueKey<String>('page2'), child: Text('page2'));
    const page3 = TestPage<void>(key: ValueKey<String>('page3'), child: Text('page3'));
    const page4 = TestPage<void>(key: ValueKey<String>('page4'), child: Text('page4'));
    const page5 = TestPage<void>(key: ValueKey<String>('page5'), child: Text('page5'));
    const page6 = TestPage<void>(key: ValueKey<String>('page6'), child: Text('page6'));
    await buildPages(<Page<void>>[page], tester, removedPage: removedPages);

    expect(find.text('page'), findsOneWidget);

    await buildPages(<Page<void>>[page, page1, page2, page3], tester, removedPage: removedPages);
    await buildPages(<Page<void>>[page, page4, page5, page6], tester, removedPage: removedPages);
    await tester.pumpAndSettle();
    expect(find.text('page6'), findsOneWidget);
    expect(removedPages, isEmpty);

    await buildPages(<Page<void>>[page, page4, page5], tester, removedPage: removedPages);
    await tester.pumpAndSettle();
    expect(find.text('page5'), findsOneWidget);
    expect(removedPages, isEmpty);

    await buildPages(<Page<void>>[page], tester, removedPage: removedPages);
    await tester.pumpAndSettle();
    expect(find.text('page'), findsOneWidget);
    expect(removedPages, isEmpty);
  });

  testWidgets('pop calls onDidRemovePage', (WidgetTester tester) async {
    final key = GlobalKey<NavigatorState>();
    final removedPage = <Page<void>>[];

    const page = TestPage<void>(key: ValueKey<String>('page'), child: Text('page'));
    const page1 = TestPage<void>(key: ValueKey<String>('page1'), child: Text('page1'));
    await buildPages(<Page<void>>[page, page1], tester, removedPage: removedPage, navKey: key);

    expect(find.text('page1'), findsOneWidget);

    key.currentState!.pop();

    // The page is removed from the pages list immediately to stop the pages
    // list from going out-of-sync if the widget is rebuilt during the
    // animation.
    await tester.pump();
    expect(removedPage, <Page<void>>[page1]);

    await tester.pumpAndSettle();
    expect(find.text('page'), findsOneWidget);
    expect(removedPage, <Page<void>>[page1]);
  });

  testWidgets('pushReplacement calls onDidRemovePage', (WidgetTester tester) async {
    final key = GlobalKey<NavigatorState>();
    final removedPage = <Page<void>>[];

    const page = TestPage<void>(key: ValueKey<String>('page'), child: Text('page'));
    const page1 = TestPage<void>(key: ValueKey<String>('page1'), child: Text('page1'));
    await buildPages(<Page<void>>[page, page1], tester, removedPage: removedPage, navKey: key);

    expect(find.text('page1'), findsOneWidget);

    key.currentState!.pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, _, _) => const Text('new page'),
        transitionsBuilder: (_, _, _, child) => child,
      ),
    );

    // The page is removed from the pages list immediately to stop the pages
    // list from going out-of-sync if the widget is rebuilt during the
    // animation.
    await tester.pump();
    expect(removedPage, <Page<void>>[page1]);

    await tester.pumpAndSettle();
    expect(find.text('new page'), findsOneWidget);
    expect(removedPage, <Page<void>>[page1]);
  });
}
