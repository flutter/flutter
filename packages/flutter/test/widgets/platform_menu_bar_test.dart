// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/foundation/diagnostics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeMenuChannel fakeMenuChannel;
  late PlatformMenuDelegate originalDelegate;
  late DefaultPlatformMenuDelegate delegate;
  final selected = <String>[];
  final opened = <String>[];
  final closed = <String>[];

  void onSelected(String item) {
    selected.add(item);
  }

  void onOpen(String item) {
    opened.add(item);
  }

  void onClose(String item) {
    closed.add(item);
  }

  setUp(() {
    fakeMenuChannel = _FakeMenuChannel((MethodCall call) async {});
    delegate = DefaultPlatformMenuDelegate(channel: fakeMenuChannel);
    originalDelegate = WidgetsBinding.instance.platformMenuDelegate;
    WidgetsBinding.instance.platformMenuDelegate = delegate;
    selected.clear();
    opened.clear();
    closed.clear();
  });

  tearDown(() {
    WidgetsBinding.instance.platformMenuDelegate = originalDelegate;
  });

  group('PlatformMenuBar', () {
    group('basic menu structure is transmitted to platform', () {
      testWidgets('using onSelected', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Material(
              child: PlatformMenuBar(
                menus: _createTestMenus(
                  onSelected: onSelected,
                  onOpen: onOpen,
                  onClose: onClose,
                  shortcuts: <String, MenuSerializableShortcut>{
                    _subSubMenu10[0].label: const SingleActivator(
                      LogicalKeyboardKey.keyA,
                      control: true,
                    ),
                    _subSubMenu10[1].label: const SingleActivator(
                      LogicalKeyboardKey.keyB,
                      shift: true,
                    ),
                    _subSubMenu10[2].label: const SingleActivator(
                      LogicalKeyboardKey.keyC,
                      alt: true,
                    ),
                    _subSubMenu10[3].label: const SingleActivator(
                      LogicalKeyboardKey.keyD,
                      meta: true,
                    ),
                  },
                ),
                child: const Center(child: Text('Body')),
              ),
            ),
          ),
        );

        expect(fakeMenuChannel.outgoingCalls.last.method, equals('Menu.setMenus'));
        expect(fakeMenuChannel.outgoingCalls.last.arguments, equals(_expectedStructure));
      });

      testWidgets('using onSelectedIntent', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Material(
              child: PlatformMenuBar(
                menus: _createTestMenus(
                  onSelectedIntent: const DoNothingIntent(),
                  onOpen: onOpen,
                  onClose: onClose,
                  shortcuts: <String, MenuSerializableShortcut>{
                    _subSubMenu10[0].label: const SingleActivator(
                      LogicalKeyboardKey.keyA,
                      control: true,
                    ),
                    _subSubMenu10[1].label: const SingleActivator(
                      LogicalKeyboardKey.keyB,
                      shift: true,
                    ),
                    _subSubMenu10[2].label: const SingleActivator(
                      LogicalKeyboardKey.keyC,
                      alt: true,
                    ),
                    _subSubMenu10[3].label: const SingleActivator(
                      LogicalKeyboardKey.keyD,
                      meta: true,
                    ),
                  },
                ),
                child: const Center(child: Text('Body')),
              ),
            ),
          ),
        );

        expect(fakeMenuChannel.outgoingCalls.last.method, equals('Menu.setMenus'));
        expect(fakeMenuChannel.outgoingCalls.last.arguments, equals(_expectedStructure));
      });
    });

    testWidgets(
      'asserts when more than one has locked the delegate',
      experimentalLeakTesting: LeakTesting.settings
          .withIgnoredAll(), // leaking by design because of exception
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Material(
              child: PlatformMenuBar(
                menus: <PlatformMenuItem>[],
                child: PlatformMenuBar(menus: <PlatformMenuItem>[], child: SizedBox()),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isA<AssertionError>());
      },
    );

    testWidgets('diagnostics', (WidgetTester tester) async {
      const item = PlatformMenuItem(
        label: 'label2',
        tooltip: 'tooltip2',
        shortcut: SingleActivator(LogicalKeyboardKey.keyA),
      );
      const menuBar = PlatformMenuBar(menus: <PlatformMenuItem>[item], child: SizedBox());

      await tester.pumpWidget(const MaterialApp(home: Material(child: menuBar)));
      await tester.pump();

      expect(
        menuBar.toStringDeep(),
        equalsIgnoringHashCodes(
          'PlatformMenuBar#00000\n'
          ' └─PlatformMenuItem#00000(label2)\n'
          '     label: "label2"\n'
          '     tooltip: "tooltip2"\n'
          '     shortcut: SingleActivator#00000(keys: Key A)\n'
          '     DISABLED\n',
        ),
      );
    });
  });

  group('MenuBarItem', () {
    testWidgets('diagnostics', (WidgetTester tester) async {
      const childItem = PlatformMenuItem(label: 'label');
      const item = PlatformMenu(label: 'label', menus: <PlatformMenuItem>[childItem]);

      final builder = DiagnosticPropertiesBuilder();
      item.debugFillProperties(builder);

      final List<String> description = builder.properties
          .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
          .map((DiagnosticsNode node) => node.toString())
          .toList();

      expect(description, <String>['label: "label"']);
    });
  });

  group('ShortcutSerialization', () {
    testWidgets('character constructor', (WidgetTester tester) async {
      final serialization = ShortcutSerialization.character('?');
      expect(
        serialization.toChannelRepresentation(),
        equals(<String, Object?>{'shortcutCharacter': '?', 'shortcutModifiers': 0}),
      );
      final serializationWithModifiers = ShortcutSerialization.character(
        '?',
        alt: true,
        control: true,
        meta: true,
      );
      expect(
        serializationWithModifiers.toChannelRepresentation(),
        equals(<String, Object?>{'shortcutCharacter': '?', 'shortcutModifiers': 13}),
      );
    });

    testWidgets('modifier constructor', (WidgetTester tester) async {
      final serialization = ShortcutSerialization.modifier(LogicalKeyboardKey.home);
      expect(
        serialization.toChannelRepresentation(),
        equals(<String, Object?>{
          'shortcutTrigger': LogicalKeyboardKey.home.keyId,
          'shortcutModifiers': 0,
        }),
      );
      final serializationWithModifiers = ShortcutSerialization.modifier(
        LogicalKeyboardKey.home,
        alt: true,
        control: true,
        meta: true,
        shift: true,
      );
      expect(
        serializationWithModifiers.toChannelRepresentation(),
        equals(<String, Object?>{
          'shortcutTrigger': LogicalKeyboardKey.home.keyId,
          'shortcutModifiers': 15,
        }),
      );
    });
  });
}

typedef _MenuItem = ({String label, String? tooltip});

const List<_MenuItem> _mainMenu = <_MenuItem>[
  (label: 'Menu 0', tooltip: 'Menu 0 Tooltip'),
  (label: 'Menu 1', tooltip: null),
  (label: 'Menu 2', tooltip: 'Menu 2 Tooltip'),
  (label: 'Menu 3', tooltip: null),
];

const List<_MenuItem> _subMenu0 = <_MenuItem>[
  (label: 'Sub Menu 00', tooltip: 'Sub Menu 00 Tooltip'),
];

const List<_MenuItem> _subMenu1 = <_MenuItem>[
  (label: 'Sub Menu 10', tooltip: 'Sub Menu 10 Tooltip'),
  (label: 'Sub Menu 11', tooltip: null),
  (label: 'Sub Menu 12', tooltip: 'Sub Menu 12 Tooltip'),
];

const List<_MenuItem> _subSubMenu10 = <_MenuItem>[
  (label: 'Sub Sub Menu 110', tooltip: null),
  (label: 'Sub Sub Menu 111', tooltip: 'Sub Sub Menu 111 Tooltip'),
  (label: 'Sub Sub Menu 112', tooltip: null),
  (label: 'Sub Sub Menu 113', tooltip: 'Sub Sub Menu 113 Tooltip'),
];

const List<_MenuItem> _subMenu2 = <_MenuItem>[(label: 'Sub Menu 20', tooltip: null)];

List<PlatformMenuItem> _createTestMenus({
  void Function(String)? onSelected,
  Intent? onSelectedIntent,
  void Function(String)? onOpen,
  void Function(String)? onClose,
  Map<String, MenuSerializableShortcut> shortcuts = const <String, MenuSerializableShortcut>{},
}) {
  final result = <PlatformMenuItem>[
    PlatformMenu(
      label: _mainMenu[0].label,
      tooltip: _mainMenu[0].tooltip,
      onOpen: onOpen != null ? () => onOpen(_mainMenu[0].label) : null,
      onClose: onClose != null ? () => onClose(_mainMenu[0].label) : null,
      menus: <PlatformMenuItem>[
        PlatformMenuItem(
          label: _subMenu0[0].label,
          tooltip: _subMenu0[0].tooltip,
          onSelected: onSelected != null ? () => onSelected(_subMenu0[0].label) : null,
          onSelectedIntent: onSelectedIntent,
          shortcut: shortcuts[_subMenu0[0].label],
        ),
      ],
    ),
    PlatformMenu(
      label: _mainMenu[1].label,
      tooltip: _mainMenu[1].tooltip,
      onOpen: onOpen != null ? () => onOpen(_mainMenu[1].label) : null,
      onClose: onClose != null ? () => onClose(_mainMenu[1].label) : null,
      menus: <PlatformMenuItem>[
        PlatformMenuItemGroup(
          members: <PlatformMenuItem>[
            PlatformMenuItem(
              label: _subMenu1[0].label,
              tooltip: _subMenu1[0].tooltip,
              onSelected: onSelected != null ? () => onSelected(_subMenu1[0].label) : null,
              onSelectedIntent: onSelectedIntent,
              shortcut: shortcuts[_subMenu1[0].label],
            ),
          ],
        ),
        PlatformMenu(
          label: _subMenu1[1].label,
          tooltip: _subMenu1[1].tooltip,
          onOpen: onOpen != null ? () => onOpen(_subMenu1[1].label) : null,
          onClose: onClose != null ? () => onClose(_subMenu1[1].label) : null,
          menus: <PlatformMenuItem>[
            PlatformMenuItemGroup(
              members: <PlatformMenuItem>[
                PlatformMenuItem(
                  label: _subSubMenu10[0].label,
                  tooltip: _subSubMenu10[0].tooltip,
                  onSelected: onSelected != null ? () => onSelected(_subSubMenu10[0].label) : null,
                  onSelectedIntent: onSelectedIntent,
                  shortcut: shortcuts[_subSubMenu10[0].label],
                ),
              ],
            ),
            PlatformMenuItemGroup(
              members: <PlatformMenuItem>[
                PlatformMenuItem(
                  label: _subSubMenu10[1].label,
                  tooltip: _subSubMenu10[1].tooltip,
                  onSelected: onSelected != null ? () => onSelected(_subSubMenu10[1].label) : null,
                  onSelectedIntent: onSelectedIntent,
                  shortcut: shortcuts[_subSubMenu10[1].label],
                ),
              ],
            ),
            PlatformMenuItem(
              label: _subSubMenu10[2].label,
              tooltip: _subSubMenu10[2].tooltip,
              onSelected: onSelected != null ? () => onSelected(_subSubMenu10[2].label) : null,
              onSelectedIntent: onSelectedIntent,
              shortcut: shortcuts[_subSubMenu10[2].label],
            ),
            PlatformMenuItemGroup(
              members: <PlatformMenuItem>[
                PlatformMenuItem(
                  label: _subSubMenu10[3].label,
                  tooltip: _subSubMenu10[3].tooltip,
                  onSelected: onSelected != null ? () => onSelected(_subSubMenu10[3].label) : null,
                  onSelectedIntent: onSelectedIntent,
                  shortcut: shortcuts[_subSubMenu10[3].label],
                ),
              ],
            ),
          ],
        ),
        PlatformMenuItem(
          label: _subMenu1[2].label,
          tooltip: _subMenu1[2].tooltip,
          onSelected: onSelected != null ? () => onSelected(_subMenu1[2].label) : null,
          onSelectedIntent: onSelectedIntent,
          shortcut: shortcuts[_subMenu1[2].label],
        ),
      ],
    ),
    PlatformMenu(
      label: _mainMenu[2].label,
      tooltip: _mainMenu[2].tooltip,
      onOpen: onOpen != null ? () => onOpen(_mainMenu[2].label) : null,
      onClose: onClose != null ? () => onClose(_mainMenu[2].label) : null,
      menus: <PlatformMenuItem>[
        PlatformMenuItem(
          // Always disabled.
          label: _subMenu2[0].label,
          tooltip: _subMenu2[0].tooltip,
          shortcut: shortcuts[_subMenu2[0].label],
        ),
      ],
    ),
    // Disabled menu
    PlatformMenu(
      label: _mainMenu[3].label,
      tooltip: _mainMenu[3].tooltip,
      onOpen: onOpen != null ? () => onOpen(_mainMenu[3].label) : null,
      onClose: onClose != null ? () => onClose(_mainMenu[3].label) : null,
      menus: <PlatformMenuItem>[],
    ),
  ];
  return result;
}

const Map<String, Object?> _expectedStructure = <String, Object?>{
  '0': <Map<String, Object?>>[
    <String, Object?>{
      'id': 2,
      'label': 'Menu 0',
      'tooltip': 'Menu 0 Tooltip',
      'enabled': true,
      'children': <Map<String, Object?>>[
        <String, Object?>{
          'id': 1,
          'label': 'Sub Menu 00',
          'tooltip': 'Sub Menu 00 Tooltip',
          'enabled': true,
        },
      ],
    },
    <String, Object?>{
      'id': 18,
      'label': 'Menu 1',
      'enabled': true,
      'children': <Map<String, Object?>>[
        <String, Object?>{
          'id': 4,
          'label': 'Sub Menu 10',
          'tooltip': 'Sub Menu 10 Tooltip',
          'enabled': true,
        },
        <String, Object?>{'id': 5, 'isDivider': true},
        <String, Object?>{
          'id': 16,
          'label': 'Sub Menu 11',
          'enabled': true,
          'children': <Map<String, Object?>>[
            <String, Object?>{
              'id': 7,
              'label': 'Sub Sub Menu 110',
              'enabled': true,
              'shortcutTrigger': 97,
              'shortcutModifiers': 8,
            },
            <String, Object?>{'id': 8, 'isDivider': true},
            <String, Object?>{
              'id': 10,
              'label': 'Sub Sub Menu 111',
              'tooltip': 'Sub Sub Menu 111 Tooltip',
              'enabled': true,
              'shortcutTrigger': 98,
              'shortcutModifiers': 2,
            },
            <String, Object?>{'id': 11, 'isDivider': true},
            <String, Object?>{
              'id': 12,
              'label': 'Sub Sub Menu 112',
              'enabled': true,
              'shortcutTrigger': 99,
              'shortcutModifiers': 4,
            },
            <String, Object?>{'id': 13, 'isDivider': true},
            <String, Object?>{
              'id': 14,
              'label': 'Sub Sub Menu 113',
              'tooltip': 'Sub Sub Menu 113 Tooltip',
              'enabled': true,
              'shortcutTrigger': 100,
              'shortcutModifiers': 1,
            },
          ],
        },
        <String, Object?>{
          'id': 17,
          'label': 'Sub Menu 12',
          'tooltip': 'Sub Menu 12 Tooltip',
          'enabled': true,
        },
      ],
    },
    <String, Object?>{
      'id': 20,
      'label': 'Menu 2',
      'tooltip': 'Menu 2 Tooltip',
      'enabled': true,
      'children': <Map<String, Object?>>[
        <String, Object?>{'id': 19, 'label': 'Sub Menu 20', 'enabled': false},
      ],
    },
    <String, Object?>{
      'id': 21,
      'label': 'Menu 3',
      'enabled': false,
      'children': <Map<String, Object?>>[],
    },
  ],
};

class _FakeMenuChannel implements MethodChannel {
  _FakeMenuChannel(this.outgoing);

  Future<dynamic> Function(MethodCall) outgoing;
  Future<void> Function(MethodCall)? incoming;

  List<MethodCall> outgoingCalls = <MethodCall>[];

  @override
  BinaryMessenger get binaryMessenger => throw UnimplementedError();

  @override
  MethodCodec get codec => const StandardMethodCodec();

  @override
  Future<List<T>> invokeListMethod<T>(String method, [dynamic arguments]) =>
      throw UnimplementedError();

  @override
  Future<Map<K, V>> invokeMapMethod<K, V>(String method, [dynamic arguments]) =>
      throw UnimplementedError();

  @override
  Future<T> invokeMethod<T>(String method, [dynamic arguments]) async {
    final call = MethodCall(method, arguments);
    outgoingCalls.add(call);
    return await outgoing(call) as T;
  }

  @override
  String get name => 'flutter/menu';

  @override
  void setMethodCallHandler(Future<void> Function(MethodCall call)? handler) => incoming = handler;
}
