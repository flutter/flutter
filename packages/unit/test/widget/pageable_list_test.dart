// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

const Size pageSize = const Size(800.0, 600.0);
const List<int> pages = const <int>[0, 1, 2, 3, 4, 5];
int currentPage = null;
bool itemsWrap = false;

Widget buildPage(BuildContext context, int page, int index) {
  return new Container(
    key: new ValueKey<int>(page),
    width: pageSize.width,
    height: pageSize.height,
    child: new Text(page.toString())
  );
}

Widget buildFrame() {
  // The test framework forces the frame (and so the PageableList)
  // to be 800x600. The pageSize constant reflects this.
  return new PageableList<int>(
    items: pages,
    itemBuilder: buildPage,
    itemsWrap: itemsWrap,
    itemExtent: pageSize.width,
    scrollDirection: ScrollDirection.horizontal,
    onPageChanged: (int page) { currentPage = page; }
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
  // PageableList with itemsWrap: false

  test('Scroll left from page 0 to page 1', () {
    testWidgets((WidgetTester tester) {
      currentPage = null;
      itemsWrap = false;
      tester.pumpWidget(buildFrame());
      expect(currentPage, isNull);
      pageLeft(tester);
      expect(currentPage, equals(1));
    });
  });

  test('Scroll right from page 1 to page 0', () {
    testWidgets((WidgetTester tester) {
      itemsWrap = false;
      tester.pumpWidget(buildFrame());
      expect(currentPage, equals(1));
      pageRight(tester);
      expect(currentPage, equals(0));
    });
  });

  test('Scroll right from page 0 does nothing (underscroll)', () {
    testWidgets((WidgetTester tester) {
      itemsWrap = false;
      tester.pumpWidget(buildFrame());
      expect(currentPage, equals(0));
      pageRight(tester);
      expect(currentPage, equals(0));
    });
  });

  // PageableList with itemsWrap: true

  test('Scroll left page 0 to page 1, itemsWrap: true', () {
    testWidgets((WidgetTester tester) {
      tester.pumpWidget(new Container());
      currentPage = null;
      itemsWrap = true;
      tester.pumpWidget(buildFrame());
      expect(currentPage, isNull);
      pageLeft(tester);
      expect(currentPage, equals(1));
    });
  });

  test('Scroll right from page 1 to page 0, itemsWrap: true', () {
    testWidgets((WidgetTester tester) {
      tester.pumpWidget(buildFrame());
      expect(currentPage, equals(1));
      pageRight(tester);
      expect(currentPage, equals(0));
    });
  });

  test('Scroll right from page 0 to page 5, itemsWrap: true (underscroll)', () {
    testWidgets((WidgetTester tester) {
      tester.pumpWidget(buildFrame());
      expect(currentPage, equals(0));
      pageRight(tester);
      expect(currentPage, equals(5));
    });
  });
}
