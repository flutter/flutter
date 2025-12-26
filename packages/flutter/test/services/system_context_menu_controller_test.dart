// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../system_context_menu_utils.dart';
import '../widgets/clipboard_utils.dart';
import 'text_input_utils.dart';

void main() {
  final TestWidgetsFlutterBinding binding = TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    final MockClipboard mockClipboard = MockClipboard();
    TestWidgetsFlutterBinding.ensureInitialized().defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      mockClipboard.handleMethodCall,
    );
    // Fill the clipboard so that the Paste option is available in the text
    // selection menu.
    await Clipboard.setData(const ClipboardData(text: 'Clipboard data'));
  });

  tearDown(() {
    TestWidgetsFlutterBinding.ensureInitialized().defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    );
  });

  test('showing and hiding one controller', () {
    // Create an active connection, which is required to show the system menu.
    final FakeTextInputClient client = FakeTextInputClient(const TextEditingValue(text: 'test1'));
    final TextInputConnection connection = TextInput.attach(client, client.configuration);
    addTearDown(() {
      connection.close();
    });

    final List<Map<String, double>> targetRects = <Map<String, double>>[];
    int hideCount = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'ContextMenu.showSystemContextMenu':
            final Map<String, dynamic> arguments = methodCall.arguments as Map<String, dynamic>;
            final Map<String, dynamic> untypedTargetRect =
                arguments['targetRect'] as Map<String, dynamic>;
            final Map<String, double> lastTargetRect = untypedTargetRect.map((
              String key,
              dynamic value,
            ) {
              return MapEntry<String, double>(key, value as double);
            });
            targetRects.add(lastTargetRect);
          case 'ContextMenu.hideSystemContextMenu':
            hideCount += 1;
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

    final SystemContextMenuController controller = SystemContextMenuController();
    addTearDown(() {
      controller.dispose();
    });

    expect(targetRects, isEmpty);
    expect(hideCount, 0);
    expect(controller.isVisible, isFalse);

    // Showing calls the platform.
    const Rect rect1 = Rect.fromLTWH(0.0, 0.0, 100.0, 100.0);
    final List<IOSSystemContextMenuItemData> items = <IOSSystemContextMenuItemData>[
      const IOSSystemContextMenuItemDataCopy(),
    ];
    controller.showWithItems(rect1, items);
    expect(targetRects, hasLength(1));
    expect(targetRects.last['x'], rect1.left);
    expect(targetRects.last['y'], rect1.top);
    expect(targetRects.last['width'], rect1.width);
    expect(targetRects.last['height'], rect1.height);

    // Showing the same thing again does nothing.
    controller.showWithItems(rect1, items);
    expect(controller.isVisible, isTrue);
    expect(targetRects, hasLength(1));

    // Showing a new rect calls the platform.
    const Rect rect2 = Rect.fromLTWH(1.0, 1.0, 200.0, 200.0);
    controller.showWithItems(rect2, items);
    expect(targetRects, hasLength(2));
    expect(targetRects.last['x'], rect2.left);
    expect(targetRects.last['y'], rect2.top);
    expect(targetRects.last['width'], rect2.width);
    expect(targetRects.last['height'], rect2.height);

    // Hiding calls the platform.
    controller.hide();
    expect(controller.isVisible, isFalse);
    expect(hideCount, 1);

    // Hiding again does nothing.
    controller.hide();
    expect(controller.isVisible, isFalse);
    expect(hideCount, 1);

    // Showing the last shown rect calls the platform.
    controller.showWithItems(rect2, items);
    expect(controller.isVisible, isTrue);
    expect(targetRects, hasLength(3));
    expect(targetRects.last['x'], rect2.left);
    expect(targetRects.last['y'], rect2.top);
    expect(targetRects.last['width'], rect2.width);
    expect(targetRects.last['height'], rect2.height);

    controller.hide();
    expect(controller.isVisible, isFalse);
    expect(hideCount, 2);
  });

  test('the system can hide the menu with handleSystemHide', () async {
    // Create an active connection, which is required to show the system menu.
    final FakeTextInputClient client = FakeTextInputClient(const TextEditingValue(text: 'test1'));
    final TextInputConnection connection = TextInput.attach(client, client.configuration);
    addTearDown(() {
      connection.close();
    });

    final List<Map<String, double>> targetRects = <Map<String, double>>[];
    int hideCount = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'ContextMenu.showSystemContextMenu':
            final Map<String, dynamic> arguments = methodCall.arguments as Map<String, dynamic>;
            final Map<String, dynamic> untypedTargetRect =
                arguments['targetRect'] as Map<String, dynamic>;
            final Map<String, double> lastTargetRect = untypedTargetRect.map((
              String key,
              dynamic value,
            ) {
              return MapEntry<String, double>(key, value as double);
            });
            targetRects.add(lastTargetRect);
          case 'ContextMenu.hideSystemContextMenu':
            hideCount += 1;
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

    int systemHideCount = 0;
    final SystemContextMenuController controller = SystemContextMenuController(
      onSystemHide: () {
        systemHideCount += 1;
      },
    );
    addTearDown(() {
      controller.dispose();
    });

    expect(controller.isVisible, isFalse);
    expect(targetRects, isEmpty);
    expect(hideCount, 0);
    expect(systemHideCount, 0);

    // Showing calls the platform.
    const Rect rect1 = Rect.fromLTWH(0.0, 0.0, 100.0, 100.0);
    final List<IOSSystemContextMenuItemData> items = <IOSSystemContextMenuItemData>[
      const IOSSystemContextMenuItemDataCopy(),
    ];
    controller.showWithItems(rect1, items);
    expect(controller.isVisible, isTrue);
    expect(targetRects, hasLength(1));
    expect(targetRects.last['x'], rect1.left);
    expect(targetRects.last['y'], rect1.top);
    expect(targetRects.last['width'], rect1.width);
    expect(targetRects.last['height'], rect1.height);

    // If the system hides the menu, onSystemHide is called.
    final ByteData? messageBytes = const JSONMessageCodec().encodeMessage(<String, dynamic>{
      'method': 'ContextMenu.onDismissSystemContextMenu',
    });
    await binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/platform',
      messageBytes,
      (ByteData? data) {},
    );
    expect(controller.isVisible, isFalse);
    expect(hideCount, 0);
    expect(systemHideCount, 1);

    // Hiding does not call the platform, since the menu was already hidden.
    controller.hide();
    expect(controller.isVisible, isFalse);
    expect(hideCount, 0);
  });

  test('showing a second controller while one is visible is an error', () {
    // Create an active connection, which is required to show the system menu.
    final FakeTextInputClient client = FakeTextInputClient(const TextEditingValue(text: 'test1'));
    final TextInputConnection connection = TextInput.attach(client, client.configuration);
    addTearDown(() {
      connection.close();
    });

    final SystemContextMenuController controller1 = SystemContextMenuController();
    addTearDown(() {
      controller1.dispose();
    });
    expect(controller1.isVisible, isFalse);
    const Rect rect1 = Rect.fromLTWH(0.0, 0.0, 100.0, 100.0);
    final List<IOSSystemContextMenuItemData> items = <IOSSystemContextMenuItemData>[
      const IOSSystemContextMenuItemDataCopy(),
    ];
    expect(() {
      controller1.showWithItems(rect1, items);
    }, isNot(throwsAssertionError));
    expect(controller1.isVisible, isTrue);

    final SystemContextMenuController controller2 = SystemContextMenuController();
    addTearDown(() {
      controller2.dispose();
    });
    expect(controller1.isVisible, isTrue);
    expect(controller2.isVisible, isFalse);
    const Rect rect2 = Rect.fromLTWH(1.0, 1.0, 200.0, 200.0);
    expect(() {
      controller2.showWithItems(rect2, items);
    }, throwsAssertionError);
    expect(controller1.isVisible, isTrue);
    expect(controller2.isVisible, isFalse);

    controller1.hide();
    expect(controller1.isVisible, isFalse);
    expect(controller2.isVisible, isFalse);
  });

  test('showing and hiding two controllers', () {
    // Create an active connection, which is required to show the system menu.
    final FakeTextInputClient client = FakeTextInputClient(const TextEditingValue(text: 'test1'));
    final TextInputConnection connection = TextInput.attach(client, client.configuration);
    addTearDown(() {
      connection.close();
    });

    final List<Map<String, double>> targetRects = <Map<String, double>>[];
    int hideCount = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'ContextMenu.showSystemContextMenu':
            final Map<String, dynamic> arguments = methodCall.arguments as Map<String, dynamic>;
            final Map<String, dynamic> untypedTargetRect =
                arguments['targetRect'] as Map<String, dynamic>;
            final Map<String, double> lastTargetRect = untypedTargetRect.map((
              String key,
              dynamic value,
            ) {
              return MapEntry<String, double>(key, value as double);
            });
            targetRects.add(lastTargetRect);
          case 'ContextMenu.hideSystemContextMenu':
            hideCount += 1;
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

    final SystemContextMenuController controller1 = SystemContextMenuController();
    addTearDown(() {
      controller1.dispose();
    });

    expect(controller1.isVisible, isFalse);
    expect(targetRects, isEmpty);
    expect(hideCount, 0);

    // Showing calls the platform.
    const Rect rect1 = Rect.fromLTWH(0.0, 0.0, 100.0, 100.0);
    final List<IOSSystemContextMenuItemData> items = <IOSSystemContextMenuItemData>[
      const IOSSystemContextMenuItemDataCopy(),
    ];
    controller1.showWithItems(rect1, items);
    expect(controller1.isVisible, isTrue);
    expect(targetRects, hasLength(1));
    expect(targetRects.last['x'], rect1.left);

    // Hiding calls the platform.
    controller1.hide();
    expect(controller1.isVisible, isFalse);
    expect(hideCount, 1);

    // Showing a new controller calls the platform.
    final SystemContextMenuController controller2 = SystemContextMenuController();
    addTearDown(() {
      controller2.dispose();
    });
    expect(controller2.isVisible, isFalse);
    const Rect rect2 = Rect.fromLTWH(1.0, 1.0, 200.0, 200.0);
    controller2.showWithItems(rect2, items);
    expect(controller1.isVisible, isFalse);
    expect(controller2.isVisible, isTrue);
    expect(targetRects, hasLength(2));
    expect(targetRects.last['x'], rect2.left);
    expect(targetRects.last['y'], rect2.top);
    expect(targetRects.last['width'], rect2.width);
    expect(targetRects.last['height'], rect2.height);

    // Hiding the old controller does nothing.
    controller1.hide();
    expect(controller1.isVisible, isFalse);
    expect(controller2.isVisible, isTrue);
    expect(hideCount, 1);

    // Hiding the new controller calls the platform.
    controller2.hide();
    expect(controller1.isVisible, isFalse);
    expect(controller2.isVisible, isFalse);
    expect(hideCount, 2);
  });

  test('showing a controller with custom items', () {
    // Create an active connection, which is required to show the system menu.
    final FakeTextInputClient client = FakeTextInputClient(const TextEditingValue(text: 'test1'));
    final TextInputConnection connection = TextInput.attach(client, client.configuration);
    addTearDown(() {
      connection.close();
    });

    final List<List<IOSSystemContextMenuItemData>> itemsReceived =
        <List<IOSSystemContextMenuItemData>>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'ContextMenu.showSystemContextMenu':
            final Map<String, dynamic> arguments = methodCall.arguments as Map<String, dynamic>;
            final List<dynamic> untypedItems = arguments['items'] as List<dynamic>;
            final List<IOSSystemContextMenuItemData> lastItems = untypedItems.map((dynamic value) {
              final Map<String, dynamic> itemJson = value as Map<String, dynamic>;
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

    final SystemContextMenuController controller = SystemContextMenuController();
    addTearDown(() {
      controller.dispose();
    });

    expect(controller.isVisible, isFalse);

    // Showing calls the platform.
    const Rect rect = Rect.fromLTWH(0.0, 0.0, 100.0, 100.0);
    final List<IOSSystemContextMenuItemData> items1 = <IOSSystemContextMenuItemData>[
      const IOSSystemContextMenuItemDataCut(),
      const IOSSystemContextMenuItemDataCopy(),
      const IOSSystemContextMenuItemDataPaste(),
      const IOSSystemContextMenuItemDataSelectAll(),
      const IOSSystemContextMenuItemDataSearchWeb(title: 'Special Search'),
      // TODO(justinmc): Support the "custom" item type.
      // https://github.com/flutter/flutter/issues/103163
    ];

    controller.showWithItems(rect, items1);
    expect(controller.isVisible, isTrue);
    expect(itemsReceived, hasLength(1));
    expect(itemsReceived.last, hasLength(items1.length));
    expect(itemsReceived.last, equals(items1));

    // Showing the same thing again does nothing.
    controller.showWithItems(rect, items1);
    expect(controller.isVisible, isTrue);
    expect(itemsReceived, hasLength(1));

    // Showing new items calls the platform.
    final List<IOSSystemContextMenuItemData> items2 = <IOSSystemContextMenuItemData>[
      const IOSSystemContextMenuItemDataCut(),
    ];
    controller.showWithItems(rect, items2);
    expect(controller.isVisible, isTrue);
    expect(itemsReceived, hasLength(2));
    expect(itemsReceived.last, hasLength(items2.length));
    expect(itemsReceived.last, equals(items2));

    controller.hide();
    expect(controller.isVisible, isFalse);
  });

  test('showing a controller with empty items', () {
    // Create an active connection, which is required to show the system menu.
    final FakeTextInputClient client = FakeTextInputClient(const TextEditingValue(text: 'test1'));
    final TextInputConnection connection = TextInput.attach(client, client.configuration);
    addTearDown(() {
      connection.close();
    });

    final List<List<IOSSystemContextMenuItemData>> itemsReceived =
        <List<IOSSystemContextMenuItemData>>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'ContextMenu.showSystemContextMenu':
            final Map<String, dynamic> arguments = methodCall.arguments as Map<String, dynamic>;
            final List<dynamic> untypedItems = arguments['items'] as List<dynamic>;
            final List<IOSSystemContextMenuItemData> lastItems = untypedItems.map((dynamic value) {
              final Map<String, dynamic> itemJson = value as Map<String, dynamic>;
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

    final SystemContextMenuController controller = SystemContextMenuController();
    addTearDown(() {
      controller.dispose();
    });

    expect(controller.isVisible, isFalse);

    const Rect rect = Rect.fromLTWH(0.0, 0.0, 100.0, 100.0);
    final List<IOSSystemContextMenuItemData> items = <IOSSystemContextMenuItemData>[];

    expect(() {
      controller.showWithItems(rect, items);
    }, throwsAssertionError);
    expect(controller.isVisible, isFalse);
    expect(itemsReceived, hasLength(0));
  });

  testWidgets('showing a controller for an EditableText', (WidgetTester tester) async {
    final TextEditingController textEditingController = TextEditingController(text: 'test');
    final FocusNode focusNode = FocusNode();
    final GlobalKey<EditableTextState> key = GlobalKey<EditableTextState>();
    late final WidgetsLocalizations localizations;
    addTearDown(() {
      textEditingController.dispose();
      focusNode.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 400,
            child: Builder(
              builder: (BuildContext context) {
                localizations = WidgetsLocalizations.of(context);
                return EditableText(
                  key: key,
                  maxLines: 10,
                  controller: textEditingController,
                  showSelectionHandles: true,
                  autofocus: true,
                  focusNode: focusNode,
                  style: Typography.material2018().black.titleMedium!,
                  cursorColor: Colors.blue,
                  backgroundCursorColor: Colors.grey,
                  keyboardType: TextInputType.text,
                  textAlign: TextAlign.right,
                  selectionControls: materialTextSelectionHandleControls,
                );
              },
            ),
          ),
        ),
      ),
    );

    final EditableTextState editableTextState = tester.state<EditableTextState>(
      find.byType(EditableText),
    );
    final List<IOSSystemContextMenuItem> defaultItems = SystemContextMenu.getDefaultItems(
      editableTextState,
    );
    expect(defaultItems, hasLength(2));
    expect(defaultItems[1], const IOSSystemContextMenuItemSelectAll());
    expect(defaultItems.first, const IOSSystemContextMenuItemPaste());

    final (startGlyphHeight: double startGlyphHeight, endGlyphHeight: double endGlyphHeight) =
        editableTextState.getGlyphHeights();
    final Rect anchor = TextSelectionToolbarAnchors.getSelectionRect(
      editableTextState.renderEditable,
      startGlyphHeight,
      endGlyphHeight,
      editableTextState.renderEditable.getEndpointsForSelection(
        editableTextState.textEditingValue.selection,
      ),
    );
    final List<IOSSystemContextMenuItemData> defaultItemDatas = defaultItems
        .map((IOSSystemContextMenuItem item) => item.getData(localizations))
        .toList();

    expect(defaultItemDatas, isNotEmpty);

    final SystemContextMenuController systemContextMenuController = SystemContextMenuController();
    addTearDown(() {
      systemContextMenuController.dispose();
    });

    expect(systemContextMenuController.isVisible, isFalse);
    systemContextMenuController.showWithItems(anchor, defaultItemDatas);
    expect(systemContextMenuController.isVisible, isTrue);
  });

  test('custom action callbacks are properly managed', () {
    final FakeTextInputClient client = FakeTextInputClient(const TextEditingValue(text: 'test'));
    final TextInputConnection connection = TextInput.attach(client, client.configuration);
    addTearDown(() {
      connection.close();
    });

    bool action1Called = false;
    bool action2Called = false;

    final SystemContextMenuController controller = SystemContextMenuController();
    addTearDown(() {
      controller.dispose();
    });

    final List<IOSSystemContextMenuItemData> items = <IOSSystemContextMenuItemData>[
      IOSSystemContextMenuItemDataCustom(
        title: 'Action 1',
        onPressed: () {
          action1Called = true;
        },
      ),
      IOSSystemContextMenuItemDataCustom(
        title: 'Action 2',
        onPressed: () {
          action2Called = true;
        },
      ),
    ];

    const Rect rect = Rect.fromLTWH(0.0, 0.0, 100.0, 100.0);
    controller.showWithItems(rect, items);

    expect(controller.isVisible, isTrue);

    // Get the actual callback IDs from the items.
    final String callbackId1 = (items[0] as IOSSystemContextMenuItemDataCustom).callbackId;
    final String callbackId2 = (items[1] as IOSSystemContextMenuItemDataCustom).callbackId;

    controller.handleCustomContextMenuAction(callbackId1);
    expect(action1Called, isTrue);
    expect(action2Called, isFalse);

    controller.handleCustomContextMenuAction(callbackId2);
    expect(action1Called, isTrue);
    expect(action2Called, isTrue);

    controller.hide();
    expect(controller.isVisible, isFalse);

    expect(() => controller.handleCustomContextMenuAction(callbackId1), throwsAssertionError);
  });

  test('multiple controllers handle callbacks independently', () {
    final FakeTextInputClient client1 = FakeTextInputClient(const TextEditingValue(text: 'test1'));
    final TextInputConnection connection1 = TextInput.attach(client1, client1.configuration);
    addTearDown(() {
      connection1.close();
    });

    bool controller1ActionCalled = false;
    bool controller2ActionCalled = false;

    final SystemContextMenuController controller1 = SystemContextMenuController();
    final SystemContextMenuController controller2 = SystemContextMenuController();
    addTearDown(() {
      controller1.dispose();
      controller2.dispose();
    });

    final List<IOSSystemContextMenuItemData> items1 = <IOSSystemContextMenuItemData>[
      IOSSystemContextMenuItemDataCustom(
        title: 'Controller 1 Action',
        onPressed: () {
          controller1ActionCalled = true;
        },
      ),
    ];

    final List<IOSSystemContextMenuItemData> items2 = <IOSSystemContextMenuItemData>[
      IOSSystemContextMenuItemDataCustom(
        title: 'Controller 2 Action',
        onPressed: () {
          controller2ActionCalled = true;
        },
      ),
    ];

    const Rect rect1 = Rect.fromLTWH(0.0, 0.0, 100.0, 100.0);
    const Rect rect2 = Rect.fromLTWH(100.0, 100.0, 100.0, 100.0);

    controller1.showWithItems(rect1, items1);
    expect(controller1.isVisible, isTrue);

    controller1.hide();
    expect(controller1.isVisible, isFalse);

    controller2.showWithItems(rect2, items2);
    expect(controller2.isVisible, isTrue);

    // Get the actual callback ID from the items.
    final String callbackId2 = (items2[0] as IOSSystemContextMenuItemDataCustom).callbackId;

    controller2.handleCustomContextMenuAction(callbackId2);
    expect(controller2ActionCalled, isTrue);
    expect(controller1ActionCalled, isFalse);

    // Get the actual callback ID from controller1's items.
    final String callbackId1 = (items1[0] as IOSSystemContextMenuItemDataCustom).callbackId;

    expect(() => controller1.handleCustomContextMenuAction(callbackId1), throwsAssertionError);
  });

  test('platform dismissal clears callbacks', () {
    final FakeTextInputClient client = FakeTextInputClient(const TextEditingValue(text: 'test'));
    final TextInputConnection connection = TextInput.attach(client, client.configuration);
    addTearDown(() {
      connection.close();
    });

    bool actionCalled = false;

    final SystemContextMenuController controller = SystemContextMenuController();
    addTearDown(() {
      controller.dispose();
    });

    final List<IOSSystemContextMenuItemData> items = <IOSSystemContextMenuItemData>[
      IOSSystemContextMenuItemDataCustom(
        title: 'Test Action',
        onPressed: () {
          actionCalled = true;
        },
      ),
    ];

    const Rect rect = Rect.fromLTWH(0.0, 0.0, 100.0, 100.0);
    controller.showWithItems(rect, items);
    expect(controller.isVisible, isTrue);

    controller.handleSystemHide();
    expect(controller.isVisible, isFalse);

    // Get the actual callback ID from the item.
    final String callbackId = (items[0] as IOSSystemContextMenuItemDataCustom).callbackId;

    expect(() => controller.handleCustomContextMenuAction(callbackId), throwsAssertionError);
    expect(actionCalled, isFalse);
  });

  test('calling handleCustomContextMenuAction with no systemContextMenuClient', () {
    // Don't create a controller or set any client.
    ServicesBinding.systemContextMenuClient = null;

    expect(() async {
      final ByteData message = const JSONMethodCodec().encodeMethodCall(
        const MethodCall('ContextMenu.onPerformCustomAction', <dynamic>[0, 'test-id']),
      );
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/platform',
        message,
        (_) {},
      );
    }, returnsNormally);
  });

  test('handleCustomContextMenuAction with non-existent callbackId', () {
    final FakeTextInputClient client = FakeTextInputClient(const TextEditingValue(text: 'test'));
    final TextInputConnection connection = TextInput.attach(client, client.configuration);
    addTearDown(() {
      connection.close();
    });

    final SystemContextMenuController controller = SystemContextMenuController();
    addTearDown(() {
      controller.dispose();
    });

    final List<IOSSystemContextMenuItemData> items = <IOSSystemContextMenuItemData>[
      IOSSystemContextMenuItemDataCustom(title: 'Test Action', onPressed: () {}),
    ];

    const Rect rect = Rect.fromLTWH(0.0, 0.0, 100.0, 100.0);
    controller.showWithItems(rect, items);
    expect(controller.isVisible, isTrue);

    expect(() => controller.handleCustomContextMenuAction('non-existent-id'), throwsAssertionError);
  });

  test('handleCustomContextMenuAction after hide clears callbacks', () {
    final FakeTextInputClient client = FakeTextInputClient(const TextEditingValue(text: 'test'));
    final TextInputConnection connection = TextInput.attach(client, client.configuration);
    addTearDown(() {
      connection.close();
    });

    bool actionCalled = false;

    final SystemContextMenuController controller = SystemContextMenuController();
    addTearDown(() {
      controller.dispose();
    });

    final List<IOSSystemContextMenuItemData> items = <IOSSystemContextMenuItemData>[
      IOSSystemContextMenuItemDataCustom(
        title: 'Test Action',
        onPressed: () {
          actionCalled = true;
        },
      ),
    ];

    const Rect rect = Rect.fromLTWH(0.0, 0.0, 100.0, 100.0);
    controller.showWithItems(rect, items);
    expect(controller.isVisible, isTrue);

    final String callbackId = (items[0] as IOSSystemContextMenuItemDataCustom).callbackId;

    // Test that it works before hiding.
    controller.handleCustomContextMenuAction(callbackId);
    expect(actionCalled, isTrue);
    actionCalled = false;

    controller.hide();
    expect(controller.isVisible, isFalse);

    expect(() => controller.handleCustomContextMenuAction(callbackId), throwsAssertionError);
    expect(actionCalled, isFalse);
  });

  test('showing new menu invalidates old menu callbacks', () {
    final FakeTextInputClient client = FakeTextInputClient(const TextEditingValue(text: 'test'));
    final TextInputConnection connection = TextInput.attach(client, client.configuration);
    addTearDown(() {
      connection.close();
    });

    bool oldActionCalled = false;
    bool newActionCalled = false;

    final SystemContextMenuController controller = SystemContextMenuController();
    addTearDown(() {
      controller.dispose();
    });

    // First menu with old action.
    final List<IOSSystemContextMenuItemData> oldItems = <IOSSystemContextMenuItemData>[
      IOSSystemContextMenuItemDataCustom(
        title: 'Old Action',
        onPressed: () {
          oldActionCalled = true;
        },
      ),
    ];

    const Rect rect1 = Rect.fromLTWH(0.0, 0.0, 100.0, 100.0);
    controller.showWithItems(rect1, oldItems);
    expect(controller.isVisible, isTrue);

    final String oldCallbackId = (oldItems[0] as IOSSystemContextMenuItemDataCustom).callbackId;

    // Show new menu with new action.
    final List<IOSSystemContextMenuItemData> newItems = <IOSSystemContextMenuItemData>[
      IOSSystemContextMenuItemDataCustom(
        title: 'New Action',
        onPressed: () {
          newActionCalled = true;
        },
      ),
    ];

    const Rect rect2 = Rect.fromLTWH(100.0, 100.0, 100.0, 100.0);
    controller.showWithItems(rect2, newItems);
    expect(controller.isVisible, isTrue);

    final String newCallbackId = (newItems[0] as IOSSystemContextMenuItemDataCustom).callbackId;

    // Old callback should not work.
    expect(() => controller.handleCustomContextMenuAction(oldCallbackId), throwsAssertionError);
    expect(oldActionCalled, isFalse);

    // New callback should work.
    controller.handleCustomContextMenuAction(newCallbackId);
    expect(newActionCalled, isTrue);
    expect(oldActionCalled, isFalse);
  });
}
