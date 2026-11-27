// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart' hide TypeMatcher, isInstanceOf;

import 'atspi.dart';

/// The name of the app on the AT-SPI desktop, which is the GApplication ID.
const String kApplicationName = 'io.flutter.linux_semantics_testing.linux_semantics_testing';

/// How long to wait for the AT-SPI tree to update.
const Duration kTimeout = Duration(seconds: 10);

void main() {
  late FlutterDriver driver;
  late AtspiClient atspi;
  late AtspiAccessible content;

  setUpAll(() async {
    driver = await FlutterDriver.connect();
    atspi = await AtspiClient.connect();
    final AtspiAccessible application = await atspi.waitForApplication(kApplicationName);

    // The Flutter content is embedded in the GTK window using an ATK
    // socket/plug. The socket is the first accessible not provided by GTK and
    // contains the plug, which contains the Flutter root semantics node. The
    // tree above the root node depends on the GTK version and theme so is not
    // checked.
    final AtspiAccessible? socket = await application.find(
      (AtspiAccessible accessible) async =>
          accessible != application && !(await accessible.getAttributes()).containsKey('toolkit'),
    );
    if (socket == null) {
      fail('Flutter socket not found in AT-SPI tree');
    }
    final AtspiAccessible plug = (await socket.getChildren()).single;
    content = (await plug.getChildren()).single;
  });

  tearDownAll(() async {
    await atspi.close();
    await driver.close();
  });

  // Returns true if the Flutter content contains an accessible with [name].
  Future<bool> hasNode(String name) async =>
      await content.find((AtspiAccessible a) async => await a.getName() == name) != null;

  // Shows [page] with its initial state and waits for the accessible with
  // [name] to appear.
  Future<void> showPage(String page, String name) async {
    await driver.requestData('show:');
    await waitFor(() => hasNode('Ready'));
    await driver.requestData('show:$page');
    await waitFor(() => hasNode(name));
  }

  group('button', () {
    setUp(() => showPage('button', 'Increment'));

    test('properties', timeout: Timeout.none, () async {
      final AtspiAccessible button = await content.findByRole('button', name: 'Increment');
      expect(
        await button.getStates(),
        containsAll(<String>['enabled', 'focusable', 'sensitive', 'showing', 'visible']),
      );
      expect(await button.getActionNames(), contains('Tap'));
    });

    test('disabled', timeout: Timeout.none, () async {
      final AtspiAccessible button = await content.findByRole('button', name: 'Disabled');
      expect(await button.getStates(), isNot(anyOf(contains('enabled'), contains('focusable'))));
      expect(await button.getActionNames(), isNot(contains('Tap')));
    });

    test('press', timeout: Timeout.none, () async {
      final AtspiAccessible button = await content.findByRole('button', name: 'Increment');
      expect(await hasNode('Pressed 0 times'), isTrue);
      await button.doAction('Tap');
      await waitFor(() => hasNode('Pressed 1 times'));
    });
  });

  group('checkbox', () {
    setUp(() => showPage('checkbox', 'Check me'));

    test('properties', timeout: Timeout.none, () async {
      final AtspiAccessible checkbox = await content.findByRole('check box', name: 'Check me');
      final Set<String> states = await checkbox.getStates();
      expect(states, containsAll(<String>['checkable', 'enabled', 'focusable']));
      expect(states, isNot(contains('checked')));
      expect(await checkbox.getActionNames(), contains('Tap'));
    });

    test('toggle', timeout: Timeout.none, () async {
      final AtspiAccessible checkbox = await content.findByRole('check box', name: 'Check me');
      await atspi.registerEvent('object:state-changed');
      final Future<AtspiEvent> checkedEvent = atspi
          .events('Object')
          .firstWhere((AtspiEvent e) => e.source == checkbox && e.detail == 'checked')
          .timeout(kTimeout);
      await checkbox.doAction('Tap');
      await checkedEvent;
      expect(await checkbox.getStates(), contains('checked'));
    });
  });

  group('slider', () {
    setUp(() => showPage('slider', 'Volume'));

    test('properties', timeout: Timeout.none, () async {
      final AtspiAccessible slider = await content.findByRole('slider', name: 'Volume');
      expect(await slider.getStates(), containsAll(<String>['enabled', 'focusable']));
      expect(await slider.getActionNames(), containsAll(<String>['Increase', 'Decrease']));
    });

    test('increase', timeout: Timeout.none, () async {
      final AtspiAccessible slider = await content.findByRole('slider', name: 'Volume');
      await slider.doAction('Increase');
      await waitFor(() => hasNode('Volume is 60'));
    });

    test(
      'value',
      timeout: Timeout.none,
      skip: 'The AT-SPI Value interface is not implemented', // https://github.com/flutter/flutter/issues/194638
      () async {
        final AtspiAccessible slider = await content.findByRole('slider', name: 'Volume');
        expect(await slider.getMinimumValue(), 0);
        expect(await slider.getMaximumValue(), 100);
        expect(await slider.getCurrentValue(), 50);
        await slider.setCurrentValue(80);
        await waitFor(() async => await slider.getCurrentValue() == 80);
      },
    );
  });

  group('text_field', () {
    setUp(() => showPage('text_field', 'Name'));

    test('properties', timeout: Timeout.none, () async {
      final AtspiAccessible textField = await content.findByRole('text', name: 'Name');
      final Set<String> states = await textField.getStates();
      expect(states, containsAll(<String>['editable', 'enabled', 'focusable']));
      expect(states, isNot(contains('focused')));
      expect(await textField.getText(), isEmpty);
    });

    test('edit', timeout: Timeout.none, () async {
      final AtspiAccessible textField = await content.findByRole('text', name: 'Name');

      // Text can only be set once the field has focus.
      await textField.doAction('Tap');
      await waitFor(() async => (await textField.getStates()).contains('focused'));
      await textField.setTextContents('Hello');
      await waitFor(() async => await textField.getText() == 'Hello');
    });
  });

  group('semantics', () {
    setUp(() => showPage('semantics', 'Settings'));

    test('header', timeout: Timeout.none, () async {
      await content.findByRole('heading', name: 'Settings');
    });

    test('link', timeout: Timeout.none, () async {
      final AtspiAccessible link = await content.findByRole('link', name: 'Help');
      await link.doAction('Tap');
      await waitFor(() => hasNode('Last action: link'));
    });

    test('image', timeout: Timeout.none, () async {
      await content.findByRole('image', name: 'Flutter logo');
    });

    test('actions', timeout: Timeout.none, () async {
      final AtspiAccessible button = await content.findByRole('button', name: 'Custom button');
      expect(await button.getActionNames(), containsAll(<String>['Tap', 'LongPress', 'Dismiss']));
      await button.doAction('LongPress');
      await waitFor(() => hasNode('Last action: long press'));
      await button.doAction('Dismiss');
      await waitFor(() => hasNode('Last action: dismiss'));
    });

    test('toggled', timeout: Timeout.none, () async {
      final AtspiAccessible toggle = await content.findByRole('toggle button', name: 'Wi-Fi');
      expect(await toggle.getStates(), containsAll(<String>['checkable', 'checked']));
    });

    test('selected', timeout: Timeout.none, () async {
      final AtspiAccessible item = await content.findByName('Selected item');
      expect(await item.getStates(), contains('selected'));
    });

    test('read only', timeout: Timeout.none, () async {
      final AtspiAccessible item = await content.findByName('Read only');
      expect(await item.getStates(), contains('read-only'));
    });

    test(
      'hint',
      timeout: Timeout.none,
      skip: 'Hints are not exposed', // https://github.com/flutter/flutter/issues/192782
      () async {
        final AtspiAccessible item = await content.findByName('Upload');
        expect(await item.getDescription(), 'Uploads the file');
      },
    );

    test('merged', timeout: Timeout.none, () async {
      await content.findByName('Merged\nlabel');
    });

    test('excluded', timeout: Timeout.none, () async {
      expect(await hasNode('Excluded'), isFalse);
    });
  });
}

/// Polls [condition] until it returns true.
Future<void> waitFor(Future<bool> Function() condition) async {
  final DateTime end = DateTime.now().add(kTimeout);
  while (!await condition()) {
    if (DateTime.now().isAfter(end)) {
      fail('Timed out waiting for condition');
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
}
