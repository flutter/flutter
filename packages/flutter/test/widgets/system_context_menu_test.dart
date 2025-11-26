// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../system_context_menu_utils.dart';

void main() {
  final TestWidgetsFlutterBinding binding = TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'asserts when built on an unsupported device',
    (WidgetTester tester) async {
      final controller = TextEditingController(text: 'one two three');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        // By default, MediaQueryData.supportsShowingSystemContextMenu is false.
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TextField(
                controller: controller,
                contextMenuBuilder: (BuildContext context, EditableTextState editableTextState) {
                  return SystemContextMenu.editableText(editableTextState: editableTextState);
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TextField));
      final EditableTextState state = tester.state<EditableTextState>(find.byType(EditableText));
      expect(state.showToolbar(), true);
      await tester.pump();

      expect(tester.takeException(), isAssertionError);
    },
    skip: kIsWeb, // [intended]
    variant: TargetPlatformVariant.all(),
  );

  testWidgets(
    'asserts when built on web',
    (WidgetTester tester) async {
      // Disable the browser context menu so that contextMenuBuilder will be used.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.contextMenu,
        (MethodCall call) {
          // Just complete successfully, so that BrowserContextMenu thinks that
          // the engine successfully received its call.
          return Future<void>.value();
        },
      );
      await BrowserContextMenu.disableContextMenu();
      addTearDown(() async {
        await BrowserContextMenu.enableContextMenu();
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.contextMenu,
          null,
        );
      });

      final controller = TextEditingController(text: 'one two three');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        // By default, MediaQueryData.supportsShowingSystemContextMenu is false.
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TextField(
                controller: controller,
                contextMenuBuilder: (BuildContext context, EditableTextState editableTextState) {
                  return SystemContextMenu.editableText(editableTextState: editableTextState);
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TextField));
      final EditableTextState state = tester.state<EditableTextState>(find.byType(EditableText));
      expect(state.showToolbar(), true);
      await tester.pump();

      expect(tester.takeException(), isAssertionError);
    },
    skip: !kIsWeb, // [intended]
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'can be shown and hidden like a normal context menu',
    (WidgetTester tester) async {
      final controller = TextEditingController(text: 'one two three');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        Builder(
          builder: (BuildContext context) {
            final MediaQueryData mediaQueryData = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQueryData.copyWith(supportsShowingSystemContextMenu: true),
              child: MaterialApp(
                home: Scaffold(
                  body: Center(
                    child: TextField(
                      controller: controller,
                      contextMenuBuilder:
                          (BuildContext context, EditableTextState editableTextState) {
                            return SystemContextMenu.editableText(
                              editableTextState: editableTextState,
                            );
                          },
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );

      expect(find.byType(SystemContextMenu), findsNothing);

      await tester.tap(find.byType(TextField));
      final EditableTextState state = tester.state<EditableTextState>(find.byType(EditableText));
      expect(state.showToolbar(), true);
      await tester.pump();
      expect(find.byType(SystemContextMenu), findsOneWidget);

      state.hideToolbar();
      await tester.pump();
      expect(find.byType(SystemContextMenu), findsNothing);
    },
    skip: kIsWeb, // [intended]
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'can customize the menu items',
    (WidgetTester tester) async {
      final itemsReceived = <List<IOSSystemContextMenuItemData>>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'ContextMenu.showSystemContextMenu':
              final arguments = methodCall.arguments as Map<String, dynamic>;
              final untypedItems = arguments['items'] as List<dynamic>;
              final List<IOSSystemContextMenuItemData> lastItems = untypedItems.map((
                dynamic value,
              ) {
                final itemJson = value as Map<String, dynamic>;
                return systemContextMenuItemDataFromJson(itemJson);
              }).toList();
              itemsReceived.add(lastItems);
          }
          return;
        },
      );
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
      });

      const items1 = <IOSSystemContextMenuItem>[
        IOSSystemContextMenuItemCopy(),
        IOSSystemContextMenuItemShare(title: 'My Share Title'),
        IOSSystemContextMenuItemLiveText(),
      ];
      final controller = TextEditingController(text: 'one two three');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        Builder(
          builder: (BuildContext context) {
            final MediaQueryData mediaQueryData = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQueryData.copyWith(supportsShowingSystemContextMenu: true),
              child: MaterialApp(
                home: Scaffold(
                  body: Center(
                    child: TextField(
                      controller: controller,
                      contextMenuBuilder:
                          (BuildContext context, EditableTextState editableTextState) {
                            return SystemContextMenu.editableText(
                              editableTextState: editableTextState,
                              items: items1,
                            );
                          },
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );

      expect(find.byType(SystemContextMenu), findsNothing);
      expect(itemsReceived, hasLength(0));

      await tester.tap(find.byType(TextField));
      final EditableTextState state = tester.state<EditableTextState>(find.byType(EditableText));
      expect(state.showToolbar(), true);
      await tester.pump();
      expect(find.byType(SystemContextMenu), findsOneWidget);

      expect(itemsReceived, hasLength(1));
      expect(itemsReceived.last, hasLength(items1.length));
      expect(itemsReceived.last[0], equals(const IOSSystemContextMenuItemDataCopy()));
      expect(
        itemsReceived.last[1],
        equals(const IOSSystemContextMenuItemDataShare(title: 'My Share Title')),
      );
      expect(itemsReceived.last[2], equals(const IOSSystemContextMenuItemDataLiveText()));

      state.hideToolbar();
      await tester.pump();
      expect(find.byType(SystemContextMenu), findsNothing);
    },
    skip: kIsWeb, // [intended]
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    "passing empty items builds the widget but doesn't show the system context menu",
    (WidgetTester tester) async {
      final itemsReceived = <List<IOSSystemContextMenuItemData>>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'ContextMenu.showSystemContextMenu':
              final arguments = methodCall.arguments as Map<String, dynamic>;
              final untypedItems = arguments['items'] as List<dynamic>;
              final List<IOSSystemContextMenuItemData> lastItems = untypedItems.map((
                dynamic value,
              ) {
                final itemJson = value as Map<String, dynamic>;
                return systemContextMenuItemDataFromJson(itemJson);
              }).toList();
              itemsReceived.add(lastItems);
          }
          return;
        },
      );
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
      });

      const items1 = <IOSSystemContextMenuItem>[];
      final controller = TextEditingController(text: 'one two three');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        Builder(
          builder: (BuildContext context) {
            final MediaQueryData mediaQueryData = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQueryData.copyWith(supportsShowingSystemContextMenu: true),
              child: MaterialApp(
                home: Scaffold(
                  body: Center(
                    child: TextField(
                      controller: controller,
                      contextMenuBuilder:
                          (BuildContext context, EditableTextState editableTextState) {
                            return SystemContextMenu.editableText(
                              editableTextState: editableTextState,
                              items: items1,
                            );
                          },
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );

      expect(tester.takeException(), isNull);

      expect(find.byType(SystemContextMenu), findsNothing);
      expect(itemsReceived, hasLength(0));

      await tester.tap(find.byType(TextField));
      final EditableTextState state = tester.state<EditableTextState>(find.byType(EditableText));
      expect(state.showToolbar(), true);
      expect(tester.takeException(), isNull);

      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(SystemContextMenu), findsOneWidget);
      expect(itemsReceived, hasLength(0));
    },
    skip: kIsWeb, // [intended]
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'items receive a default title',
    (WidgetTester tester) async {
      final itemsReceived = <List<IOSSystemContextMenuItemData>>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'ContextMenu.showSystemContextMenu':
              final arguments = methodCall.arguments as Map<String, dynamic>;
              final untypedItems = arguments['items'] as List<dynamic>;
              final List<IOSSystemContextMenuItemData> lastItems = untypedItems.map((
                dynamic value,
              ) {
                final itemJson = value as Map<String, dynamic>;
                return systemContextMenuItemDataFromJson(itemJson);
              }).toList();
              itemsReceived.add(lastItems);
          }
          return;
        },
      );
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
      });

      const items1 = <IOSSystemContextMenuItem>[
        // Copy gets no title, it's set by the platform.
        IOSSystemContextMenuItemCopy(),
        // Share could take a title, but if not, it gets a localized default.
        IOSSystemContextMenuItemShare(),
      ];
      final controller = TextEditingController(text: 'one two three');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        Builder(
          builder: (BuildContext context) {
            final MediaQueryData mediaQueryData = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQueryData.copyWith(supportsShowingSystemContextMenu: true),
              child: MaterialApp(
                home: Scaffold(
                  body: Center(
                    child: TextField(
                      controller: controller,
                      contextMenuBuilder:
                          (BuildContext context, EditableTextState editableTextState) {
                            return SystemContextMenu.editableText(
                              editableTextState: editableTextState,
                              items: items1,
                            );
                          },
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );

      expect(find.byType(SystemContextMenu), findsNothing);
      expect(itemsReceived, hasLength(0));

      await tester.tap(find.byType(TextField));
      final EditableTextState state = tester.state<EditableTextState>(find.byType(EditableText));
      expect(state.showToolbar(), true);
      await tester.pump();
      expect(find.byType(SystemContextMenu), findsOneWidget);

      expect(itemsReceived, hasLength(1));
      expect(itemsReceived.last, hasLength(items1.length));
      expect(itemsReceived.last[0], equals(const IOSSystemContextMenuItemDataCopy()));
      const WidgetsLocalizations localizations = DefaultWidgetsLocalizations();
      expect(
        itemsReceived.last[1],
        equals(IOSSystemContextMenuItemDataShare(title: localizations.shareButtonLabel)),
      );

      state.hideToolbar();
      await tester.pump();
      expect(find.byType(SystemContextMenu), findsNothing);
    },
    skip: kIsWeb, // [intended]
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'can be updated.',
    (WidgetTester tester) async {
      final targetRects = <Map<String, double>>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'ContextMenu.showSystemContextMenu') {
            final arguments = methodCall.arguments as Map<String, dynamic>;
            final untypedTargetRect = arguments['targetRect'] as Map<String, dynamic>;
            final Map<String, double> lastTargetRect = untypedTargetRect.map((
              String key,
              dynamic value,
            ) {
              return MapEntry<String, double>(key, value as double);
            });
            targetRects.add(lastTargetRect);
          }
          return;
        },
      );
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
      });

      final controller = TextEditingController(text: 'one two three');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        Builder(
          builder: (BuildContext context) {
            final MediaQueryData mediaQueryData = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQueryData.copyWith(supportsShowingSystemContextMenu: true),
              child: MaterialApp(
                home: Scaffold(
                  body: Center(
                    child: TextField(
                      controller: controller,
                      contextMenuBuilder:
                          (BuildContext context, EditableTextState editableTextState) {
                            return SystemContextMenu.editableText(
                              editableTextState: editableTextState,
                            );
                          },
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );

      expect(targetRects, isEmpty);

      await tester.tap(find.byType(TextField));
      final EditableTextState state = tester.state<EditableTextState>(find.byType(EditableText));
      expect(state.showToolbar(), true);
      await tester.pump();

      expect(targetRects, hasLength(1));
      expect(targetRects.last, containsPair('width', 0.0));

      controller.selection = const TextSelection(baseOffset: 4, extentOffset: 7);
      await tester.pumpAndSettle();

      expect(targetRects, hasLength(2));
      expect(targetRects.last['width'], greaterThan(0.0));
    },
    skip: kIsWeb, // [intended]
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'can be rebuilt',
    (WidgetTester tester) async {
      final controller = TextEditingController(text: 'one two three');
      addTearDown(controller.dispose);
      late StateSetter setState;
      await tester.pumpWidget(
        Builder(
          builder: (BuildContext context) {
            final MediaQueryData mediaQueryData = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQueryData.copyWith(supportsShowingSystemContextMenu: true),
              child: MaterialApp(
                home: Scaffold(
                  body: Center(
                    child: StatefulBuilder(
                      builder: (BuildContext context, StateSetter localSetState) {
                        setState = localSetState;
                        return TextField(
                          controller: controller,
                          contextMenuBuilder:
                              (BuildContext context, EditableTextState editableTextState) {
                                return SystemContextMenu.editableText(
                                  editableTextState: editableTextState,
                                );
                              },
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );

      await tester.tap(find.byType(TextField));
      final EditableTextState state = tester.state<EditableTextState>(find.byType(EditableText));
      expect(state.showToolbar(), true);
      await tester.pump();

      setState(() {});
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    },
    skip: kIsWeb, // [intended]
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'can handle multiple instances',
    (WidgetTester tester) async {
      final controller1 = TextEditingController(text: 'one two three');
      addTearDown(controller1.dispose);
      final controller2 = TextEditingController(text: 'four five six');
      addTearDown(controller2.dispose);
      final GlobalKey field1Key = GlobalKey();
      final GlobalKey field2Key = GlobalKey();
      final GlobalKey menu1Key = GlobalKey();
      final GlobalKey menu2Key = GlobalKey();
      await tester.pumpWidget(
        Builder(
          builder: (BuildContext context) {
            final MediaQueryData mediaQueryData = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQueryData.copyWith(supportsShowingSystemContextMenu: true),
              child: MaterialApp(
                home: Scaffold(
                  body: Center(
                    child: Column(
                      children: <Widget>[
                        TextField(
                          key: field1Key,
                          controller: controller1,
                          contextMenuBuilder:
                              (BuildContext context, EditableTextState editableTextState) {
                                return SystemContextMenu.editableText(
                                  key: menu1Key,
                                  editableTextState: editableTextState,
                                );
                              },
                        ),
                        TextField(
                          key: field2Key,
                          controller: controller2,
                          contextMenuBuilder:
                              (BuildContext context, EditableTextState editableTextState) {
                                return SystemContextMenu.editableText(
                                  key: menu2Key,
                                  editableTextState: editableTextState,
                                );
                              },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );

      expect(find.byType(SystemContextMenu), findsNothing);

      await tester.tap(find.byKey(field1Key));
      final EditableTextState state1 = tester.state<EditableTextState>(
        find.descendant(of: find.byKey(field1Key), matching: find.byType(EditableText)),
      );
      expect(state1.showToolbar(), true);
      await tester.pump();
      expect(find.byKey(menu1Key), findsOneWidget);
      expect(find.byKey(menu2Key), findsNothing);

      // In a real app, this message is sent by iOS when the user taps anywhere
      // outside of the system context menu.
      final ByteData? messageBytes = const JSONMessageCodec().encodeMessage(<String, dynamic>{
        'method': 'ContextMenu.onDismissSystemContextMenu',
      });
      await binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/platform',
        messageBytes,
        (ByteData? data) {},
      );
      await tester.pump();
      expect(find.byType(SystemContextMenu), findsNothing);

      await tester.tap(find.byKey(field2Key));
      final EditableTextState state2 = tester.state<EditableTextState>(
        find.descendant(of: find.byKey(field2Key), matching: find.byType(EditableText)),
      );
      expect(state2.showToolbar(), true);
      await tester.pump();
      expect(find.byKey(menu1Key), findsNothing);
      expect(find.byKey(menu2Key), findsOneWidget);
    },
    skip: kIsWeb, // [intended]
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  test(
    'can get the IOSSystemContextMenuItemData representation of an IOSSystemContextMenuItemCopy',
    () {
      const item = IOSSystemContextMenuItemCopy();
      const WidgetsLocalizations localizations = DefaultWidgetsLocalizations();
      expect(item.getData(localizations), const IOSSystemContextMenuItemDataCopy());
    },
  );

  test(
    'can get the IOSSystemContextMenuItemData representation of an IOSSystemContextMenuItemCut',
    () {
      const item = IOSSystemContextMenuItemCut();
      const WidgetsLocalizations localizations = DefaultWidgetsLocalizations();
      expect(item.getData(localizations), const IOSSystemContextMenuItemDataCut());
    },
  );

  test(
    'can get the IOSSystemContextMenuItemData representation of an IOSSystemContextMenuItemPaste',
    () {
      const item = IOSSystemContextMenuItemPaste();
      const WidgetsLocalizations localizations = DefaultWidgetsLocalizations();
      expect(item.getData(localizations), const IOSSystemContextMenuItemDataPaste());
    },
  );

  test(
    'can get the IOSSystemContextMenuItemData representation of an IOSSystemContextMenuItemSelectAll',
    () {
      const item = IOSSystemContextMenuItemSelectAll();
      const WidgetsLocalizations localizations = DefaultWidgetsLocalizations();
      expect(item.getData(localizations), const IOSSystemContextMenuItemDataSelectAll());
    },
  );

  test(
    'can get the IOSSystemContextMenuItemData representation of an IOSSystemContextMenuItemLookUp',
    () {
      const item = IOSSystemContextMenuItemLookUp();
      const WidgetsLocalizations localizations = DefaultWidgetsLocalizations();
      expect(
        item.getData(localizations),
        IOSSystemContextMenuItemDataLookUp(title: localizations.lookUpButtonLabel),
      );
    },
  );

  test(
    'can get the IOSSystemContextMenuItemData representation of an IOSSystemContextMenuItemSearchWeb',
    () {
      const item = IOSSystemContextMenuItemSearchWeb();
      const WidgetsLocalizations localizations = DefaultWidgetsLocalizations();
      expect(
        item.getData(localizations),
        IOSSystemContextMenuItemDataSearchWeb(title: localizations.searchWebButtonLabel),
      );
    },
  );

  test(
    'can get the IOSSystemContextMenuItemData representation of an IOSSystemContextMenuItemShare',
    () {
      const item = IOSSystemContextMenuItemShare();
      const WidgetsLocalizations localizations = DefaultWidgetsLocalizations();
      expect(
        item.getData(localizations),
        IOSSystemContextMenuItemDataShare(title: localizations.shareButtonLabel),
      );
    },
  );

  test(
    'can get the IOSSystemContextMenuItemData representation of an IOSSystemContextMenuItemLiveText',
    () {
      const item = IOSSystemContextMenuItemLiveText();
      const WidgetsLocalizations localizations = DefaultWidgetsLocalizations();
      final IOSSystemContextMenuItemData data = item.getData(localizations);
      expect(data, isA<IOSSystemContextMenuItemDataLiveText>());
    },
  );

  test('systemContextMenuItemDataFromJson handles Live Text', () {
    final json = <String, dynamic>{'type': 'captureTextFromCamera'};
    final IOSSystemContextMenuItemData item = systemContextMenuItemDataFromJson(json);
    expect(item, isA<IOSSystemContextMenuItemDataLiveText>());
  });

  // Regression test for https://github.com/flutter/flutter/issues/169696.
  test('IOSSystemContextMenuItemLookUp debugFillProperties', () {
    const title = 'my title';
    const item = IOSSystemContextMenuItemLookUp(title: title);
    final List<DiagnosticsNode> diagnosticsNodes = item.toDiagnosticsNode().getProperties();
    expect(diagnosticsNodes, hasLength(1));
    expect(diagnosticsNodes.first.name, 'title');
    expect(diagnosticsNodes.first.value, title);
  });

  // Regression test for https://github.com/flutter/flutter/issues/169696.
  test('IOSSystemContextMenuItemSearchWeb debugFillProperties', () {
    const title = 'my title';
    const item = IOSSystemContextMenuItemSearchWeb(title: title);
    final List<DiagnosticsNode> diagnosticsNodes = item.toDiagnosticsNode().getProperties();
    expect(diagnosticsNodes, hasLength(1));
    expect(diagnosticsNodes.first.name, 'title');
    expect(diagnosticsNodes.first.value, title);
  });

  // Regression test for https://github.com/flutter/flutter/issues/169696.
  test('IOSSystemContextMenuItemShare debugFillProperties', () {
    const title = 'my title';
    const item = IOSSystemContextMenuItemShare(title: title);
    final List<DiagnosticsNode> diagnosticsNodes = item.toDiagnosticsNode().getProperties();
    expect(diagnosticsNodes, hasLength(1));
    expect(diagnosticsNodes.first.name, 'title');
    expect(diagnosticsNodes.first.value, title);
  });

  testWidgets(
    'when supportsShowingSystemContextMenu is false, isSupported is false',
    (WidgetTester tester) async {
      final controller = TextEditingController(text: 'one two three');
      addTearDown(controller.dispose);
      late BuildContext buildContext;
      await tester.pumpWidget(
        Builder(
          builder: (BuildContext context) {
            final MediaQueryData mediaQueryData = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQueryData.copyWith(supportsShowingSystemContextMenu: false),
              child: MaterialApp(
                home: Scaffold(
                  body: Builder(
                    builder: (BuildContext context) {
                      buildContext = context;
                      return TextField(
                        controller: controller,
                        contextMenuBuilder:
                            (BuildContext context, EditableTextState editableTextState) {
                              return SystemContextMenu.editableText(
                                editableTextState: editableTextState,
                              );
                            },
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      );

      expect(SystemContextMenu.isSupported(buildContext), isFalse);
    },
    skip: kIsWeb, // [intended] SystemContextMenu is not supported on web.
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'when supportsShowingSystemContextMenu is true and the platform is iOS, isSupported is true',
    (WidgetTester tester) async {
      final controller = TextEditingController(text: 'one two three');
      addTearDown(controller.dispose);
      late BuildContext buildContext;
      await tester.pumpWidget(
        Builder(
          builder: (BuildContext context) {
            final MediaQueryData mediaQueryData = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQueryData.copyWith(supportsShowingSystemContextMenu: true),
              child: MaterialApp(
                home: Scaffold(
                  body: Builder(
                    builder: (BuildContext context) {
                      buildContext = context;
                      return TextField(
                        controller: controller,
                        contextMenuBuilder:
                            (BuildContext context, EditableTextState editableTextState) {
                              return SystemContextMenu.editableText(
                                editableTextState: editableTextState,
                              );
                            },
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      );

      expect(SystemContextMenu.isSupported(buildContext), switch (defaultTargetPlatform) {
        TargetPlatform.iOS => isTrue,
        _ => isFalse,
      });
    },
    skip: kIsWeb, // [intended] SystemContextMenu is not supported on web.
    variant: TargetPlatformVariant.all(),
  );

  for (final readOnly in <bool>[true, false]) {
    testWidgets(
      'read only fields do not support the system context menu',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          Builder(
            builder: (BuildContext context) {
              final MediaQueryData mediaQueryData = MediaQuery.of(context);
              return MediaQuery(
                data: mediaQueryData.copyWith(supportsShowingSystemContextMenu: true),
                child: MaterialApp(
                  home: Scaffold(body: TextField(readOnly: readOnly)),
                ),
              );
            },
          ),
        );

        final EditableTextState editableTextState = tester.state(find.byType(EditableText));
        expect(SystemContextMenu.isSupportedByField(editableTextState), switch (readOnly) {
          true => isFalse,
          false => isTrue,
        });
      },
      skip: kIsWeb, // [intended] SystemContextMenu is not supported on web.
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );
  }

  // Regression test for https://github.com/flutter/flutter/issues/170521.
  testWidgets(
    'when supportsShowingSystemContextMenu is false, SystemContextMenu throws',
    (WidgetTester tester) async {
      final controller = TextEditingController(text: 'one two three');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        Builder(
          builder: (BuildContext context) {
            final MediaQueryData mediaQueryData = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQueryData.copyWith(supportsShowingSystemContextMenu: false),
              child: MaterialApp(
                home: Scaffold(
                  body: Center(
                    child: TextField(
                      controller: controller,
                      contextMenuBuilder:
                          (BuildContext context, EditableTextState editableTextState) {
                            return SystemContextMenu.editableText(
                              editableTextState: editableTextState,
                            );
                          },
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );

      expect(find.byType(SystemContextMenu), findsNothing);

      await tester.tap(find.byType(TextField));
      final EditableTextState state = tester.state<EditableTextState>(find.byType(EditableText));
      expect(state.showToolbar(), true);
      await tester.pump();

      expect(tester.takeException(), isAssertionError);
    },
    skip: kIsWeb, // [intended] SystemContextMenu is not supported on web.
  );

  testWidgets(
    'can use custom menu items',
    (WidgetTester tester) async {
      var customAction1Called = false;
      var customAction2Called = false;
      final itemsReceived = <List<IOSSystemContextMenuItemData>>[];

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'ContextMenu.showSystemContextMenu':
              final arguments = methodCall.arguments as Map<String, dynamic>;
              final untypedItems = arguments['items'] as List<dynamic>;
              final List<IOSSystemContextMenuItemData> lastItems = untypedItems.map((
                dynamic value,
              ) {
                final itemJson = value as Map<String, dynamic>;
                return systemContextMenuItemDataFromJson(itemJson);
              }).toList();
              itemsReceived.add(lastItems);
          }
          return;
        },
      );
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
      });

      final items = <IOSSystemContextMenuItem>[
        const IOSSystemContextMenuItemCopy(),
        IOSSystemContextMenuItemCustom(
          title: 'Custom Action 1',
          onPressed: () {
            customAction1Called = true;
          },
        ),
        IOSSystemContextMenuItemCustom(
          title: 'Custom Action 2',
          onPressed: () {
            customAction2Called = true;
          },
        ),
      ];

      final controller = TextEditingController(text: 'test text');
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        Builder(
          builder: (BuildContext context) {
            final MediaQueryData mediaQueryData = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQueryData.copyWith(supportsShowingSystemContextMenu: true),
              child: MaterialApp(
                home: Scaffold(
                  body: Center(
                    child: TextField(
                      controller: controller,
                      contextMenuBuilder:
                          (BuildContext context, EditableTextState editableTextState) {
                            return SystemContextMenu.editableText(
                              editableTextState: editableTextState,
                              items: items,
                            );
                          },
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );

      await tester.tap(find.byType(TextField));
      final EditableTextState state = tester.state<EditableTextState>(find.byType(EditableText));
      expect(state.showToolbar(), true);
      await tester.pump();

      expect(find.byType(SystemContextMenu), findsOneWidget);
      expect(itemsReceived, hasLength(1));
      expect(itemsReceived.last, hasLength(3));

      expect(itemsReceived.last[0], equals(const IOSSystemContextMenuItemDataCopy()));
      expect(itemsReceived.last[1], isA<IOSSystemContextMenuItemDataCustom>());
      expect(
        (itemsReceived.last[1] as IOSSystemContextMenuItemDataCustom).title,
        'Custom Action 1',
      );
      expect(itemsReceived.last[2], isA<IOSSystemContextMenuItemDataCustom>());
      expect(
        (itemsReceived.last[2] as IOSSystemContextMenuItemDataCustom).title,
        'Custom Action 2',
      );

      final customItem1 = items[1] as IOSSystemContextMenuItemCustom;
      final customItem2 = items[2] as IOSSystemContextMenuItemCustom;

      ByteData? message = const JSONMethodCodec().encodeMethodCall(
        MethodCall('ContextMenu.onPerformCustomAction', <dynamic>[
          0,
          customItem1.hashCode.toString(),
        ]),
      );
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/platform',
        message,
        (_) {},
      );
      expect(customAction1Called, isTrue);
      expect(customAction2Called, isFalse);

      message = const JSONMethodCodec().encodeMethodCall(
        MethodCall('ContextMenu.onPerformCustomAction', <dynamic>[
          0,
          customItem2.hashCode.toString(),
        ]),
      );
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/platform',
        message,
        (_) {},
      );
      expect(customAction2Called, isTrue);

      state.hideToolbar();
      await tester.pump();
      expect(find.byType(SystemContextMenu), findsNothing);
    },
    skip: kIsWeb, // [intended]
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'system context menu auto-closes after custom action',
    (WidgetTester tester) async {
      var customActionCalled = false;
      final controller = TextEditingController(text: 'test text');
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        Builder(
          builder: (BuildContext context) {
            final MediaQueryData mediaQueryData = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQueryData.copyWith(supportsShowingSystemContextMenu: true),
              child: MaterialApp(
                home: Scaffold(
                  body: Center(
                    child: TextField(
                      controller: controller,
                      contextMenuBuilder:
                          (BuildContext context, EditableTextState editableTextState) {
                            return SystemContextMenu.editableText(
                              editableTextState: editableTextState,
                              items: <IOSSystemContextMenuItem>[
                                IOSSystemContextMenuItemCustom(
                                  title: 'Test Action',
                                  onPressed: () {
                                    customActionCalled = true;
                                  },
                                ),
                              ],
                            );
                          },
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );

      await tester.tap(find.byType(TextField));
      final EditableTextState state = tester.state<EditableTextState>(find.byType(EditableText));
      expect(state.showToolbar(), true);
      await tester.pump();

      expect(find.byType(SystemContextMenu), findsOneWidget);

      final SystemContextMenu menu = tester.widget<SystemContextMenu>(
        find.byType(SystemContextMenu),
      );
      final item = menu.items[0] as IOSSystemContextMenuItemCustom;

      final ByteData message = const JSONMethodCodec().encodeMethodCall(
        MethodCall('ContextMenu.onPerformCustomAction', <dynamic>[0, item.hashCode.toString()]),
      );
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/platform',
        message,
        (_) {},
      );

      expect(customActionCalled, isTrue);

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
    skip: kIsWeb, // [intended]
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'can trigger custom menu action through platform channel message',
    (WidgetTester tester) async {
      final controller = TextEditingController(text: 'one two three');
      addTearDown(controller.dispose);

      var customActionCalled = false;
      final items = <IOSSystemContextMenuItem>[
        const IOSSystemContextMenuItemCut(),
        IOSSystemContextMenuItemCustom(
          title: 'Test Action',
          onPressed: () {
            customActionCalled = true;
          },
        ),
      ];

      await tester.pumpWidget(
        Builder(
          builder: (BuildContext context) {
            final MediaQueryData mediaQueryData = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQueryData.copyWith(supportsShowingSystemContextMenu: true),
              child: MaterialApp(
                home: Scaffold(
                  body: Center(
                    child: TextField(
                      controller: controller,
                      contextMenuBuilder:
                          (BuildContext context, EditableTextState editableTextState) {
                            return SystemContextMenu.editableText(
                              editableTextState: editableTextState,
                              items: items,
                            );
                          },
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );

      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      const selection = TextSelection(baseOffset: 0, extentOffset: 3);
      controller.selection = selection;

      await tester.longPress(find.byType(TextField));
      await tester.pumpAndSettle();

      expect(find.byType(SystemContextMenu), findsOneWidget);

      final customItem = items[1] as IOSSystemContextMenuItemCustom;
      final callbackId = customItem.hashCode.toString();

      final ByteData message = const JSONMethodCodec().encodeMethodCall(
        MethodCall('ContextMenu.onPerformCustomAction', <dynamic>[0, callbackId]),
      );
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/platform',
        message,
        (_) {},
      );

      expect(customActionCalled, isTrue);

      // Verify menu closes after custom action.
      // Simulate platform dismiss message for consistency.
      final ByteData? dismissMessage = const JSONMessageCodec().encodeMessage(<String, dynamic>{
        'method': 'ContextMenu.onDismissSystemContextMenu',
      });
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/platform',
        dismissMessage,
        (_) {},
      );
      await tester.pump();
      expect(find.byType(SystemContextMenu), findsNothing);
    },
    skip: kIsWeb, // [intended]
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'two TextFields can have different custom SystemContextMenu items',
    (WidgetTester tester) async {
      var field1ActionCalled = false;
      var field2ActionCalled = false;

      final controller1 = TextEditingController(text: 'Field 1 text');
      final controller2 = TextEditingController(text: 'Field 2 text');
      addTearDown(() {
        controller1.dispose();
        controller2.dispose();
      });

      await tester.pumpWidget(
        Builder(
          builder: (BuildContext context) {
            final MediaQueryData mediaQueryData = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQueryData.copyWith(supportsShowingSystemContextMenu: true),
              child: MaterialApp(
                home: Scaffold(
                  body: Column(
                    children: <Widget>[
                      TextField(
                        controller: controller1,
                        contextMenuBuilder:
                            (BuildContext context, EditableTextState editableTextState) {
                              return SystemContextMenu.editableText(
                                editableTextState: editableTextState,
                                items: <IOSSystemContextMenuItem>[
                                  IOSSystemContextMenuItemCustom(
                                    title: 'Field 1 Action',
                                    onPressed: () {
                                      field1ActionCalled = true;
                                    },
                                  ),
                                ],
                              );
                            },
                      ),
                      TextField(
                        controller: controller2,
                        contextMenuBuilder:
                            (BuildContext context, EditableTextState editableTextState) {
                              return SystemContextMenu.editableText(
                                editableTextState: editableTextState,
                                items: <IOSSystemContextMenuItem>[
                                  IOSSystemContextMenuItemCustom(
                                    title: 'Field 2 Action',
                                    onPressed: () {
                                      field2ActionCalled = true;
                                    },
                                  ),
                                ],
                              );
                            },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );

      await tester.longPress(find.byType(TextField).first);
      await tester.pump();
      expect(find.byType(SystemContextMenu), findsOneWidget);

      final SystemContextMenu menu1 = tester.widget<SystemContextMenu>(
        find.byType(SystemContextMenu),
      );
      final item1 = menu1.items[0] as IOSSystemContextMenuItemCustom;

      ByteData message = const JSONMethodCodec().encodeMethodCall(
        MethodCall('ContextMenu.onPerformCustomAction', <dynamic>[0, item1.hashCode.toString()]),
      );
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/platform',
        message,
        (_) {},
      );

      expect(field1ActionCalled, isTrue);
      expect(field2ActionCalled, isFalse);

      final ByteData? messageBytes1 = const JSONMessageCodec().encodeMessage(<String, dynamic>{
        'method': 'ContextMenu.onDismissSystemContextMenu',
      });
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/platform',
        messageBytes1,
        (_) {},
      );
      await tester.pump();

      field1ActionCalled = false;

      await tester.longPress(find.byType(TextField).last);
      await tester.pump();
      expect(find.byType(SystemContextMenu), findsOneWidget);

      final SystemContextMenu menu2 = tester.widget<SystemContextMenu>(
        find.byType(SystemContextMenu),
      );
      final item2 = menu2.items[0] as IOSSystemContextMenuItemCustom;

      message = const JSONMethodCodec().encodeMethodCall(
        MethodCall('ContextMenu.onPerformCustomAction', <dynamic>[0, item2.hashCode.toString()]),
      );
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/platform',
        message,
        (_) {},
      );

      expect(field1ActionCalled, isFalse);
      expect(field2ActionCalled, isTrue);

      final ByteData? messageBytes2 = const JSONMessageCodec().encodeMessage(<String, dynamic>{
        'method': 'ContextMenu.onDismissSystemContextMenu',
      });
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/platform',
        messageBytes2,
        (_) {},
      );
      await tester.pump();

      expect(find.byType(SystemContextMenu), findsNothing);
    },
    skip: kIsWeb, // [intended]
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
}
