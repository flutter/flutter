// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_catalog/expansion_tile_sample.dart' as expansion_tile_sample;
import 'package:sample_catalog/expansion_tile_sample.dart' show Entry;

void main() {
  testWidgets('expansion_tile sample smoke test', (WidgetTester tester) async {
    expansion_tile_sample.main();
    await tester.pump();

    // Initially only the top level EntryItems (the "chapters") are present.
    for (final Entry chapter in expansion_tile_sample.data) {
      expect(find.text(chapter.title), findsOneWidget);
      for (final Entry section in chapter.children) {
        expect(find.text(section.title), findsNothing);
        for (final Entry item in section.children)
          expect(find.text(item.title), findsNothing);
      }
    }

    Future<void> scrollUpOneEntry() async {
      await tester.dragFrom(const Offset(200.0, 200.0), const Offset(0.0, -88.00));
      await tester.pumpAndSettle();
    }

    Future<void> tapEntry(String title) async {
      await tester.tap(find.text(title));
      await tester.pumpAndSettle();
    }

    // Expand the chapters. Now the chapter and sections, but not the
    // items, should be present.
    for (final Entry chapter in expansion_tile_sample.data.reversed)
      await tapEntry(chapter.title);

    for (final Entry chapter in expansion_tile_sample.data) {
      expect(find.text(chapter.title), findsOneWidget);
      for (final Entry section in chapter.children) {
        expect(find.text(section.title), findsOneWidget);
        await scrollUpOneEntry();
        for (final Entry item in section.children)
          expect(find.text(item.title), findsNothing);
      }
      await scrollUpOneEntry();
    }

    // - scroll to the top -
    await tester.flingFrom(const Offset(200.0, 200.0), const Offset(0.0, 100.0), 5000.0);
    await tester.pumpAndSettle();

    // Expand the sections. Now Widgets for all three levels should be present.
    for (final Entry chapter in expansion_tile_sample.data) {
      for (final Entry section in chapter.children) {
        await tapEntry(section.title);
        await scrollUpOneEntry();
      }
      await scrollUpOneEntry();
    }

    // We're scrolled to the bottom so the very last item is visible.
    // Working in reverse order, so we don't need to do anymore scrolling,
    // check that everything is visible and close the sections and
    // chapters as we go up.
    for (final Entry chapter in expansion_tile_sample.data.reversed) {
      expect(find.text(chapter.title), findsOneWidget);
      for (final Entry section in chapter.children.reversed) {
        expect(find.text(section.title), findsOneWidget);
        for (final Entry item in section.children.reversed)
          expect(find.text(item.title), findsOneWidget);
        await tapEntry(section.title); // close the section
      }
      await tapEntry(chapter.title); // close the chapter
    }

    // Finally only the top level EntryItems (the "chapters") are present.
    for (final Entry chapter in expansion_tile_sample.data) {
      expect(find.text(chapter.title), findsOneWidget);
      for (final Entry section in chapter.children) {
        expect(find.text(section.title), findsNothing);
        for (final Entry item in section.children)
          expect(find.text(item.title), findsNothing);
      }
    }

  });
}
