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
int currentPage = null;
bool itemsWrap = false;

Widget buildPage(BuildContext context, int page, int index) {
  return new Container(
    key: globalKeys[page],
    width: pageSize.width,
    height: pageSize.height,
    child: new Text(page.toString())
  );
}

Widget buildFrame({ List<int> pages: defaultPages }) {
  final list = new PageableList<int>(
    items: pages,
    itemBuilder: buildPage,
    itemsWrap: itemsWrap,
    scrollDirection: ScrollDirection.horizontal,
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
  tester.scroll(tester.findText(itemText), offset);
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
      itemsWrap = false;
      tester.pumpWidget(buildFrame());
      expect(currentPage, isNull);
      pageLeft(tester);
      expect(currentPage, equals(1));

      expect(tester.findText('0'), isNull);
      expect(tester.findText('1'), isNotNull);
      expect(tester.findText('2'), isNull);
      expect(tester.findText('3'), isNull);
      expect(tester.findText('4'), isNull);
      expect(tester.findText('5'), isNull);

      pageRight(tester);
      expect(currentPage, equals(0));

      expect(tester.findText('0'), isNotNull);
      expect(tester.findText('1'), isNull);
      expect(tester.findText('2'), isNull);
      expect(tester.findText('3'), isNull);
      expect(tester.findText('4'), isNull);
      expect(tester.findText('5'), isNull);

      pageRight(tester);
      expect(currentPage, equals(0));
    });
  });

  test('PageableList with itemsWrap: true', () {
    testWidgets((WidgetTester tester) {
      currentPage = null;
      itemsWrap = true;
      tester.pumpWidget(buildFrame());
      expect(currentPage, isNull);
      pageLeft(tester);
      expect(currentPage, equals(1));
      pageRight(tester);
      expect(currentPage, equals(0));
      pageRight(tester);
      expect(currentPage, equals(5));
    });
  });

  test('PageableList with two items', () {
    testWidgets((WidgetTester tester) {
      currentPage = null;
      itemsWrap = true;
      tester.pumpWidget(buildFrame(pages: <int>[0, 1]));
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
      itemsWrap = true;
      tester.pumpWidget(buildFrame(pages: <int>[0]));
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
      itemsWrap = true;
      tester.pumpWidget(buildFrame(pages: null));
      expect(currentPage, isNull);
    });
  });

  test('PageableList resize parent', () {
    testWidgets((WidgetTester tester) {
      tester.pumpWidget(new Container());
      currentPage = null;
      itemsWrap = true;

      tester.pumpWidget(buildFrame());
      expect(currentPage, isNull);
      pageRight(tester);
      expect(currentPage, equals(5));

      RenderBox box = globalKeys[5].currentContext.findRenderObject();
      expect(box.size.width, equals(pageSize.width));
      expect(box.size.height, equals(pageSize.height));

      pageSize = new Size(pageSize.height, pageSize.width);
      tester.pumpWidget(buildFrame());

      expect(tester.findText('0'), isNull);
      expect(tester.findText('1'), isNull);
      expect(tester.findText('2'), isNull);
      expect(tester.findText('3'), isNull);
      expect(tester.findText('4'), isNull);
      expect(tester.findText('5'), isNotNull);

      box = globalKeys[5].currentContext.findRenderObject();
      expect(box.size.width, equals(pageSize.width));
      expect(box.size.height, equals(pageSize.height));
    });
  });
}
