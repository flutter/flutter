// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../services/mocks_for_image_cache.dart';

void main() {
  testWidgets('Need at least 2 tabs', (WidgetTester tester) async {
    try {
      await tester.pumpWidget(new CupertinoTabBar(
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: const ImageIcon(const TestImageProvider(24, 24)),
            title: const Text('Tab 1'),
          ),
        ],
      ));
      fail('Should not be possible to create a tab bar with just one item');
    } on AssertionError {
      // Exception expected.
    }
  });

  testWidgets('Active and inactive colors', (WidgetTester tester) async {
    await tester.pumpWidget(new CupertinoTabBar(
      items: <BottomNavigationBarItem>[
        const BottomNavigationBarItem(
          icon: const ImageIcon(const TestImageProvider(24, 24)),
          title: const Text('Tab 1'),
        ),
        const BottomNavigationBarItem(
          icon: const ImageIcon(const TestImageProvider(24, 24)),
          title: const Text('Tab 2'),
        ),
      ],
      currentIndex: 1,
      activeColor: const Color(0xFF123456),
      inactiveColor: const Color(0xFF654321),
    ));

    final RichText actualInactive = tester.widget(find.descendant(
      of: find.text('Tab 1'),
      matching: find.byType(RichText),
    ));
    expect(actualInactive.text.style.color, const Color(0xFF654321));

    final RichText actualActive = tester.widget(find.descendant(
      of: find.text('Tab 2'),
      matching: find.byType(RichText),
    ));
    expect(actualActive.text.style.color, const Color(0xFF123456));
  });

  testWidgets('Opaque background does not add blur effects', (WidgetTester tester) async {
    await tester.pumpWidget(new CupertinoTabBar(
      items: <BottomNavigationBarItem>[
        const BottomNavigationBarItem(
          icon: const ImageIcon(const TestImageProvider(24, 24)),
          title: const Text('Tab 1'),
        ),
        const BottomNavigationBarItem(
          icon: const ImageIcon(const TestImageProvider(24, 24)),
          title: const Text('Tab 2'),
        ),
      ],
    ));

    expect(find.byType(BackdropFilter), findsOneWidget);

    await tester.pumpWidget(new CupertinoTabBar(
      items: <BottomNavigationBarItem>[
        const BottomNavigationBarItem(
          icon: const ImageIcon(const TestImageProvider(24, 24)),
          title: const Text('Tab 1'),
        ),
        const BottomNavigationBarItem(
          icon: const ImageIcon(const TestImageProvider(24, 24)),
          title: const Text('Tab 2'),
        ),
      ],
      backgroundColor: const Color(0xFFFFFFFF), // Opaque white.
    ));

    expect(find.byType(BackdropFilter), findsNothing);
  });

  testWidgets('Tap callback', (WidgetTester tester) async {
    int callbackTab;

    await tester.pumpWidget(new CupertinoTabBar(
      items: <BottomNavigationBarItem>[
        const BottomNavigationBarItem(
          icon: const ImageIcon(const TestImageProvider(24, 24)),
          title: const Text('Tab 1'),
        ),
        const BottomNavigationBarItem(
          icon: const ImageIcon(const TestImageProvider(24, 24)),
          title: const Text('Tab 2'),
        ),
      ],
      currentIndex: 1,
      onTap: (int tab) { callbackTab = tab; },
    ));

    await tester.tap(find.text('Tab 1'));
    expect(callbackTab, 0);
  });
}