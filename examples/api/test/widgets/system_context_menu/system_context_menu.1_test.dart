// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_api_samples/widgets/system_context_menu/system_context_menu.1.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'shows custom menu items in system context menu on iOS',
    (WidgetTester tester) async {
      final List<Map<String, dynamic>> itemsReceived = <Map<String, dynamic>>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'ContextMenu.showSystemContextMenu') {
            final Map<String, dynamic> arguments = methodCall.arguments as Map<String, dynamic>;
            final List<dynamic> items = arguments['items'] as List<dynamic>;
            itemsReceived.addAll(items.cast<Map<String, dynamic>>());
          }
          return null;
        },
      );
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
      });

      await tester.pumpWidget(
        Builder(
          builder: (BuildContext context) {
            final MediaQueryData mediaQueryData = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQueryData.copyWith(
                supportsShowingSystemContextMenu: defaultTargetPlatform == TargetPlatform.iOS,
              ),
              child: const example.SystemContextMenuExampleApp(),
            );
          },
        ),
      );

      final Finder textFinder = find.byType(EditableText);
      await tester.longPress(textFinder);
      tester.state<EditableTextState>(textFinder).showToolbar();
      await tester.pumpAndSettle();

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        expect(find.byType(SystemContextMenu), findsOneWidget);
        expect(find.byType(AdaptiveTextSelectionToolbar), findsNothing);
        expect(itemsReceived.length, greaterThanOrEqualTo(3));

        final List<Map<String, dynamic>> customItems = itemsReceived
            .where((Map<String, dynamic> item) => item['type'] == 'custom')
            .toList();

        expect(customItems.length, 3);
        expect(customItems[0]['title'], 'Clear Text');
        expect(customItems[1]['title'], 'Add Heart');
        expect(customItems[2]['title'], 'Uppercase');
      } else {
        expect(find.byType(AdaptiveTextSelectionToolbar), findsOneWidget);
        expect(find.byType(SystemContextMenu), findsNothing);
      }
    },
    variant: TargetPlatformVariant.all(),
    skip: kIsWeb, // [intended]
  );

  testWidgets(
    'custom menu actions work correctly',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        Builder(
          builder: (BuildContext context) {
            final MediaQueryData mediaQueryData = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQueryData.copyWith(supportsShowingSystemContextMenu: true),
              child: const example.SystemContextMenuExampleApp(),
            );
          },
        ),
      );

      final TextEditingController controller = tester
          .widget<TextField>(find.byType(TextField))
          .controller!;

      expect(controller.text, 'Long press to see custom menu items');

      final Finder textFinder = find.byType(EditableText);
      await tester.longPress(textFinder);
      tester.state<EditableTextState>(textFinder).showToolbar();
      await tester.pumpAndSettle();

      final SystemContextMenu contextMenu = tester.widget<SystemContextMenu>(
        find.byType(SystemContextMenu),
      );
      final List<IOSSystemContextMenuItem> items = contextMenu.items;
      final IOSSystemContextMenuItemCustom clearItem = items
          .whereType<IOSSystemContextMenuItemCustom>()
          .firstWhere((IOSSystemContextMenuItemCustom item) => item.title == 'Clear Text');

      clearItem.onPressed();
      await tester.pumpAndSettle();

      expect(controller.text, '');
      expect(find.text('Text cleared'), findsOneWidget);

      // iOS system menus auto-close after custom actions on real devices.
      // Simulate this by sending the platform dismiss message.
      final ByteData? messageBytes = const JSONMessageCodec().encodeMessage(<String, dynamic>{
        'method': 'ContextMenu.onDismissSystemContextMenu',
      });
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/platform',
        messageBytes,
        (_) {},
      );
      await tester.pump();

      expect(find.byType(SystemContextMenu), findsNothing);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    skip: kIsWeb, // [intended]
  );
}
