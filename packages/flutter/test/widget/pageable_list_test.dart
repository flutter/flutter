// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

Size pageSize = new Size(600.0, 300.0);
const List<int> defaultPages = const <int>[0, 1, 2, 3, 4, 5];
final List<GlobalKey> globalKeys = defaultPages.map((_) => new GlobalKey()).toList();
int currentPage;

Widget buildPage(int page) {
  return new Container(
    key: globalKeys[page],
    width: pageSize.width,
    height: pageSize.height,
    child: new Text(page.toString())
  );
}

Widget buildFrame({
  bool itemsWrap: false,
  ViewportAnchor scrollAnchor: ViewportAnchor.start,
  List<int> pages: defaultPages
}) {
  final PageableList list = new PageableList(
    children: pages.map(buildPage),
    itemsWrap: itemsWrap,
    scrollDirection: Axis.horizontal,
    scrollAnchor: scrollAnchor,
    onPageChanged: (int page) { currentPage = page; }
  );

  // The test framework forces the frame to be 800x600, so we need to create
  // an outer container where we can change the size.
  return new Center(
    child: new Container(
      width: pageSize.width, height: pageSize.height, child: list)
  );
}

void page(WidgetTester tester, Offset offset) {
  String itemText = currentPage != null ? currentPage.toString() : '0';
  tester.scroll(find.text(itemText), offset);
  // One frame to start the animation, a second to complete it.
  tester.pump();
  tester.pump(const Duration(seconds: 1));
}

void pageLeft(WidgetTester tester) {
  page(tester, new Offset(-pageSize.width, 0.0));
}

void pageRight(WidgetTester tester) {
  page(tester, new Offset(pageSize.width, 0.0));
}

void main() {
  test('PageableList with itemsWrap: false', () {
    testWidgets((WidgetTester tester) {
      currentPage = null;
      tester.pumpWidget(buildFrame());
      expect(currentPage, isNull);
      pageLeft(tester);
      expect(currentPage, equals(1));

      expect(tester, doesNotHaveWidget(find.text('0')));
      expect(tester, hasWidget(find.text('1')));
      expect(tester, doesNotHaveWidget(find.text('2')));
      expect(tester, doesNotHaveWidget(find.text('3')));
      expect(tester, doesNotHaveWidget(find.text('4')));
      expect(tester, doesNotHaveWidget(find.text('5')));

      pageRight(tester);
      expect(currentPage, equals(0));

      expect(tester, hasWidget(find.text('0')));
      expect(tester, doesNotHaveWidget(find.text('1')));
      expect(tester, doesNotHaveWidget(find.text('2')));
      expect(tester, doesNotHaveWidget(find.text('3')));
      expect(tester, doesNotHaveWidget(find.text('4')));
      expect(tester, doesNotHaveWidget(find.text('5')));

      pageRight(tester);
      expect(currentPage, equals(0));
    });
  });

  test('PageableList with end scroll anchor', () {
    testWidgets((WidgetTester tester) {
      currentPage = 5;
      tester.pumpWidget(buildFrame(scrollAnchor: ViewportAnchor.end));
      pageRight(tester);
      expect(currentPage, equals(4));

      expect(tester, doesNotHaveWidget(find.text('0')));
      expect(tester, doesNotHaveWidget(find.text('1')));
      expect(tester, doesNotHaveWidget(find.text('2')));
      expect(tester, doesNotHaveWidget(find.text('3')));
      expect(tester, hasWidget(find.text('4')));
      expect(tester, doesNotHaveWidget(find.text('5')));

      pageLeft(tester);
      expect(currentPage, equals(5));

      expect(tester, doesNotHaveWidget(find.text('0')));
      expect(tester, doesNotHaveWidget(find.text('1')));
      expect(tester, doesNotHaveWidget(find.text('2')));
      expect(tester, doesNotHaveWidget(find.text('3')));
      expect(tester, doesNotHaveWidget(find.text('4')));
      expect(tester, hasWidget(find.text('5')));

      pageLeft(tester);
      expect(currentPage, equals(5));

      expect(tester, doesNotHaveWidget(find.text('0')));
      expect(tester, doesNotHaveWidget(find.text('1')));
      expect(tester, doesNotHaveWidget(find.text('2')));
      expect(tester, doesNotHaveWidget(find.text('3')));
      expect(tester, doesNotHaveWidget(find.text('4')));
      expect(tester, hasWidget(find.text('5')));
    });
  });

  test('PageableList with itemsWrap: true', () {
    testWidgets((WidgetTester tester) {
      currentPage = null;
      tester.pumpWidget(buildFrame(itemsWrap: true));
      expect(currentPage, isNull);
      pageLeft(tester);
      expect(currentPage, equals(1));
      pageRight(tester);
      expect(currentPage, equals(0));
      pageRight(tester);
      expect(currentPage, equals(5));
    });
  });

  test('PageableList with end and itemsWrap: true', () {
    testWidgets((WidgetTester tester) {
      currentPage = 5;
      tester.pumpWidget(buildFrame(itemsWrap: true, scrollAnchor: ViewportAnchor.end));
      pageRight(tester);
      expect(currentPage, equals(4));

      expect(tester, doesNotHaveWidget(find.text('0')));
      expect(tester, doesNotHaveWidget(find.text('1')));
      expect(tester, doesNotHaveWidget(find.text('2')));
      expect(tester, doesNotHaveWidget(find.text('3')));
      expect(tester, hasWidget(find.text('4')));
      expect(tester, doesNotHaveWidget(find.text('5')));

      pageLeft(tester);
      expect(currentPage, equals(5));

      expect(tester, doesNotHaveWidget(find.text('0')));
      expect(tester, doesNotHaveWidget(find.text('1')));
      expect(tester, doesNotHaveWidget(find.text('2')));
      expect(tester, doesNotHaveWidget(find.text('3')));
      expect(tester, doesNotHaveWidget(find.text('4')));
      expect(tester, hasWidget(find.text('5')));

      pageLeft(tester);
      expect(currentPage, equals(0));

      expect(tester, hasWidget(find.text('0')));
      expect(tester, doesNotHaveWidget(find.text('1')));
      expect(tester, doesNotHaveWidget(find.text('2')));
      expect(tester, doesNotHaveWidget(find.text('3')));
      expect(tester, doesNotHaveWidget(find.text('4')));
      expect(tester, doesNotHaveWidget(find.text('5')));

      pageLeft(tester);
      expect(currentPage, equals(1));

      expect(tester, doesNotHaveWidget(find.text('0')));
      expect(tester, hasWidget(find.text('1')));
      expect(tester, doesNotHaveWidget(find.text('2')));
      expect(tester, doesNotHaveWidget(find.text('3')));
      expect(tester, doesNotHaveWidget(find.text('4')));
      expect(tester, doesNotHaveWidget(find.text('5')));
    });
  });

  test('PageableList with two items', () {
    testWidgets((WidgetTester tester) {
      currentPage = null;
      tester.pumpWidget(buildFrame(itemsWrap: true, pages: <int>[0, 1]));
      expect(currentPage, isNull);
      pageLeft(tester);
      expect(currentPage, equals(1));
      pageRight(tester);
      expect(currentPage, equals(0));
      pageRight(tester);
      expect(currentPage, equals(1));
    });
  });

  test('PageableList with one item', () {
    testWidgets((WidgetTester tester) {
      currentPage = null;
      tester.pumpWidget(buildFrame(itemsWrap: true, pages: <int>[0]));
      expect(currentPage, isNull);
      pageLeft(tester);
      expect(currentPage, equals(0));
      pageRight(tester);
      expect(currentPage, equals(0));
      pageRight(tester);
      expect(currentPage, equals(0));
    });
  });

  test('PageableList with no items', () {
    testWidgets((WidgetTester tester) {
      currentPage = null;
      tester.pumpWidget(buildFrame(itemsWrap: true, pages: <int>[]));
      expect(currentPage, isNull);
    });
  });

  test('PageableList resize parent', () {
    testWidgets((WidgetTester tester) {
      tester.pumpWidget(new Container());
      currentPage = null;

      tester.pumpWidget(buildFrame(itemsWrap: true));
      expect(currentPage, isNull);
      pageRight(tester);
      expect(currentPage, equals(5));

      RenderBox box = globalKeys[5].currentContext.findRenderObject();
      expect(box.size.width, equals(pageSize.width));
      expect(box.size.height, equals(pageSize.height));

      pageSize = new Size(pageSize.height, pageSize.width);
      tester.pumpWidget(buildFrame(itemsWrap: true));

      expect(tester, doesNotHaveWidget(find.text('0')));
      expect(tester, doesNotHaveWidget(find.text('1')));
      expect(tester, doesNotHaveWidget(find.text('2')));
      expect(tester, doesNotHaveWidget(find.text('3')));
      expect(tester, doesNotHaveWidget(find.text('4')));
      expect(tester, hasWidget(find.text('5')));

      box = globalKeys[5].currentContext.findRenderObject();
      expect(box.size.width, equals(pageSize.width));
      expect(box.size.height, equals(pageSize.height));
    });
  });
}
