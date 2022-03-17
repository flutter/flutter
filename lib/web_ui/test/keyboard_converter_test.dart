// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart' show isTest;
import 'package:quiver/testing/async.dart';
import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

const int kLocationStandard = 0;
const int kLocationLeft = 1;
const int kLocationRight = 2;
const int kLocationNumpad = 3;

final int kPhysicalKeyA = kWebToPhysicalKey['KeyA']!;
final int kPhysicalKeyE = kWebToPhysicalKey['KeyE']!;
final int kPhysicalKeyU = kWebToPhysicalKey['KeyU']!;
final int kPhysicalDigit1 = kWebToPhysicalKey['Digit1']!;
final int kPhysicalNumpad1 = kWebToPhysicalKey['Numpad1']!;
final int kPhysicalShiftLeft = kWebToPhysicalKey['ShiftLeft']!;
final int kPhysicalShiftRight = kWebToPhysicalKey['ShiftRight']!;
final int kPhysicalMetaLeft = kWebToPhysicalKey['MetaLeft']!;
final int kPhysicalTab = kWebToPhysicalKey['Tab']!;
final int kPhysicalCapsLock = kWebToPhysicalKey['CapsLock']!;
final int kPhysicalScrollLock = kWebToPhysicalKey['ScrollLock']!;
// A web-specific physical key when code is empty.
const int kPhysicalEmptyCode = 0x1700000000;

const int kLogicalKeyA = 0x00000000061;
const int kLogicalKeyU = 0x00000000075;
const int kLogicalDigit1 = 0x00000000031;
final int kLogicalNumpad1 = kWebLogicalLocationMap['1']![kLocationNumpad]!;
final int kLogicalShiftLeft = kWebLogicalLocationMap['Shift']![kLocationLeft]!;
final int kLogicalShiftRight = kWebLogicalLocationMap['Shift']![kLocationRight]!;
final int kLogicalCtrlLeft = kWebLogicalLocationMap['Control']![kLocationLeft]!;
final int kLogicalAltLeft = kWebLogicalLocationMap['Alt']![kLocationLeft]!;
final int kLogicalMetaLeft = kWebLogicalLocationMap['Meta']![kLocationLeft]!;
const int kLogicalTab = 0x0000000009;
final int kLogicalCapsLock = kWebToLogicalKey['CapsLock']!;
final int kLogicalScrollLock = kWebToLogicalKey['ScrollLock']!;

typedef VoidCallback = void Function();

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  test('KeyData.toString', () {
    expect(const ui.KeyData(
      type: ui.KeyEventType.down,
      physical: 0x700e5,
      logical: 0x61,
      character: 'A',
      timeStamp: Duration.zero,
      synthesized: false,
    ).toString(), 'KeyData(type: down, physical: 0x700e5, logical: 0x61 (Unicode), character: "A" (0x41))');

    expect(const ui.KeyData(
      type: ui.KeyEventType.up,
      physical: 0x700e6,
      logical: 0x100000061,
      character: '\n',
      timeStamp: Duration.zero,
      synthesized: true,
    ).toString(), r'KeyData(type: up, physical: 0x700e6, logical: 0x100000061 (Unprintable), character: "\n" (0x0a), synthesized)');

    expect(const ui.KeyData(
      type: ui.KeyEventType.repeat,
      physical: 0x700e7,
      logical: 0x9900000071,
      character: null,
      timeStamp: Duration.zero,
      synthesized: false,
    ).toString(), 'KeyData(type: repeat, physical: 0x700e7, logical: 0x9900000071, character: <none>)');
  });

  test('Single key press, repeat, and release', () {
    final List<ui.KeyData> keyDataList = <ui.KeyData>[];
    final KeyboardConverter converter = KeyboardConverter((ui.KeyData key) {
      keyDataList.add(key);
      // Only handle down events
      return key.type == ui.KeyEventType.down;
    });
    bool preventedDefault = false;
    void onPreventDefault() { preventedDefault = true; }

    converter.handleEvent(keyDownEvent('KeyA', 'a')
      ..timeStamp = 1
      ..onPreventDefault = onPreventDefault
    );
    expectKeyData(keyDataList.last,
      timeStamp: const Duration(milliseconds: 1),
      type: ui.KeyEventType.down,
      physical: kPhysicalKeyA,
      logical: kLogicalKeyA,
      character: 'a',
    );
    expect(preventedDefault, isTrue);
    preventedDefault = false;

    converter.handleEvent(keyRepeatedDownEvent('KeyA', 'a')
      ..timeStamp = 1.5
      ..onPreventDefault = onPreventDefault
    );
    expectKeyData(keyDataList.last,
      timeStamp: const Duration(milliseconds: 1, microseconds: 500),
      type: ui.KeyEventType.repeat,
      physical: kPhysicalKeyA,
      logical: kLogicalKeyA,
      character: 'a',
    );
    expect(preventedDefault, isFalse);

    converter.handleEvent(keyRepeatedDownEvent('KeyA', 'a')
      ..timeStamp = 1500
      ..onPreventDefault = onPreventDefault
    );
    expectKeyData(keyDataList.last,
      timeStamp: const Duration(seconds: 1, milliseconds: 500),
      type: ui.KeyEventType.repeat,
      physical: kPhysicalKeyA,
      logical: kLogicalKeyA,
      character: 'a',
    );
    expect(preventedDefault, isFalse);

    converter.handleEvent(keyUpEvent('KeyA', 'a')
      ..timeStamp = 2000.5
      ..onPreventDefault = onPreventDefault
    );
    expectKeyData(keyDataList.last,
      timeStamp: const Duration(seconds: 2, microseconds: 500),
      type: ui.KeyEventType.up,
      physical: kPhysicalKeyA,
      logical: kLogicalKeyA,
      character: null,
    );
    expect(preventedDefault, isFalse);
  });

  test('Release modifier during a repeated sequence', () {
    final List<ui.KeyData> keyDataList = <ui.KeyData>[];
    final KeyboardConverter converter = KeyboardConverter((ui.KeyData key) {
      keyDataList.add(key);
      // Only handle down events
      return key.type == ui.KeyEventType.down;
    });
    bool preventedDefault = false;
    void onPreventDefault() { preventedDefault = true; }

    converter.handleEvent(keyDownEvent('ShiftLeft', 'Shift', kShift, kLocationLeft)
      ..onPreventDefault = onPreventDefault
    );
    expectKeyData(keyDataList.last,
      type: ui.KeyEventType.down,
      physical: kPhysicalShiftLeft,
      logical: kLogicalShiftLeft,
      character: null,
    );
    expect(preventedDefault, isTrue);
    preventedDefault = false;

    converter.handleEvent(keyDownEvent('KeyA', 'A', kShift)
      ..onPreventDefault = onPreventDefault
    );
    expectKeyData(keyDataList.last,
      type: ui.KeyEventType.down,
      physical: kPhysicalKeyA,
      logical: kLogicalKeyA,
      character: 'A',
    );
    expect(preventedDefault, isTrue);
    preventedDefault = false;

    converter.handleEvent(keyRepeatedDownEvent('KeyA', 'A', kShift)
      ..onPreventDefault = onPreventDefault
    );
    expectKeyData(keyDataList.last,
      type: ui.KeyEventType.repeat,
      physical: kPhysicalKeyA,
      logical: kLogicalKeyA,
      character: 'A',
    );
    expect(preventedDefault, isFalse);

    converter.handleEvent(keyUpEvent('ShiftLeft', 'Shift', 0, kLocationLeft)
      ..onPreventDefault = onPreventDefault
    );
    expectKeyData(keyDataList.last,
      type: ui.KeyEventType.up,
      physical: kPhysicalShiftLeft,
      logical: kLogicalShiftLeft,
      character: null,
    );
    expect(preventedDefault, isFalse);

    converter.handleEvent(keyRepeatedDownEvent('KeyA', 'a')
      ..onPreventDefault = onPreventDefault
    );
    expectKeyData(keyDataList.last,
      type: ui.KeyEventType.repeat,
      physical: kPhysicalKeyA,
      logical: kLogicalKeyA,
      character: 'a',
    );
    expect(preventedDefault, isFalse);

    converter.handleEvent(keyRepeatedDownEvent('KeyA', 'a')
      ..onPreventDefault = onPreventDefault
    );
    expectKeyData(keyDataList.last,
      type: ui.KeyEventType.repeat,
      physical: kPhysicalKeyA,
      logical: kLogicalKeyA,
      character: 'a',
    );
    expect(preventedDefault, isFalse);

    converter.handleEvent(keyUpEvent('KeyA', 'a'));
    expectKeyData(keyDataList.last,
      type: ui.KeyEventType.up,
      physical: kPhysicalKeyA,
      logical: kLogicalKeyA,
      character: null,
    );
    expect(preventedDefault, isFalse);
  });

  test('Distinguish between left and right modifiers', () {
    final List<ui.KeyData> keyDataList = <ui.KeyData>[];
    final KeyboardConverter converter = KeyboardConverter((ui.KeyData key) {
      keyDataList.add(key);
      return true;
    });

    converter.handleEvent(keyDownEvent('ShiftLeft', 'Shift', kShift, kLocationLeft));
    expectKeyData(keyDataList.last,
      type: ui.KeyEventType.down,
      physical: kPhysicalShiftLeft,
      logical: kLogicalShiftLeft,
      character: null,
    );

    converter.handleEvent(keyDownEvent('ShiftRight', 'Shift', kShift, kLocationRight));
    expectKeyData(keyDataList.last,
      type: ui.KeyEventType.down,
      physical: kPhysicalShiftRight,
      logical: kLogicalShiftRight,
      character: null,
    );

    converter.handleEvent(keyUpEvent('ShiftLeft', 'Shift', kShift, kLocationLeft));
    expectKeyData(keyDataList.last,
      type: ui.KeyEventType.up,
      physical: kPhysicalShiftLeft,
      logical: kLogicalShiftLeft,
      character: null,
    );

    converter.handleEvent(keyUpEvent('ShiftRight', 'Shift', 0, kLocationRight));
    expectKeyData(keyDataList.last,
      type: ui.KeyEventType.up,
      physical: kPhysicalShiftRight,
      logical: kLogicalShiftRight,
      character: null,
    );
  });

  test('Treat modifiers at standard locations as if at left', () {
    final List<ui.KeyData> keyDataList = <ui.KeyData>[];
    final KeyboardConverter converter = KeyboardConverter((ui.KeyData key) {
      keyDataList.add(key);
      return true;
    });

    converter.handleEvent(keyDownEvent('', 'Shift', kShift, kLocationStandard));
    expectKeyData(keyDataList.last,
      type: ui.KeyEventType.down,
      physical: kPhysicalEmptyCode,
      logical: kLogicalShiftLeft,
      character: null,
    );

    converter.handleEvent(keyUpEvent('', 'Shift', kShift, kLocationStandard));
    expectKeyData(keyDataList.last,
      type: ui.KeyEventType.up,
      physical: kPhysicalEmptyCode,
      logical: kLogicalShiftLeft,
      character: null,
    );

    converter.handleEvent(keyDownEvent('', 'Control', kCtrl, kLocationStandard));
    expectKeyData(keyDataList.last,
      type: ui.KeyEventType.down,
      physical: kPhysicalEmptyCode,
      logical: kLogicalCtrlLeft,
      character: null,
    );

    converter.handleEvent(keyUpEvent('', 'Control', kCtrl, kLocationStandard));
    expectKeyData(keyDataList.last,
      type: ui.KeyEventType.up,
      physical: kPhysicalEmptyCode,
      logical: kLogicalCtrlLeft,
      character: null,
    );

    converter.handleEvent(keyDownEvent('', 'Alt', kAlt, kLocationStandard));
    expectKeyData(keyDataList.last,
      type: ui.KeyEventType.down,
      physical: kPhysicalEmptyCode,
      logical: kLogicalAltLeft,
      character: null,
    );

    converter.handleEvent(keyUpEvent('', 'Alt', kAlt, kLocationStandard));
    expectKeyData(keyDataList.last,
      type: ui.KeyEventType.up,
      physical: kPhysicalEmptyCode,
      logical: kLogicalAltLeft,
      character: null,
    );

    converter.handleEvent(keyDownEvent('', 'Meta', kMeta, kLocationStandard));
    expectKeyData(keyDataList.last,
      type: ui.KeyEventType.down,
      physical: kPhysicalEmptyCode,
      logical: kLogicalMetaLeft,
      character: null,
    );

    converter.handleEvent(keyUpEvent('', 'Meta', kMeta, kLocationStandard));
    expectKeyData(keyDataList.last,
      type: ui.KeyEventType.up,
      physical: kPhysicalEmptyCode,
      logical: kLogicalMetaLeft,
      character: null,
    );
  });

  test('Distinguish between normal and numpad digits', () {
    final List<ui.KeyData> keyDataList = <ui.KeyData>[];
    final KeyboardConverter converter = KeyboardConverter((ui.KeyData key) {
      keyDataList.add(key);
      return true;
    });

    converter.handleEvent(keyDownEvent('Digit1', '1', 0, 0));
    expectKeyData(keyDataList.last,
      type: ui.KeyEventType.down,
      physical: kPhysicalDigit1,
      logical: kLogicalDigit1,
      character: '1',
    );

    converter.handleEvent(keyDownEvent('Numpad1', '1', 0, kLocationNumpad));
    expectKeyData(keyDataList.last,
      type: ui.KeyEventType.down,
      physical: kPhysicalNumpad1,
      logical: kLogicalNumpad1,
      character: '1',
    );

    converter.handleEvent(keyUpEvent('Digit1', '1', 0, 0));
    expectKeyData(keyDataList.last,
      type: ui.KeyEventType.up,
      physical: kPhysicalDigit1,
      logical: kLogicalDigit1,
      character: null,
    );

    converter.handleEvent(keyUpEvent('Numpad1', '1', 0, kLocationNumpad));
    expectKeyData(keyDataList.last,
      type: ui.KeyEventType.up,
      physical: kPhysicalNumpad1,
      logical: kLogicalNumpad1,
      character: null,
    );
  });

  test('Dead keys are distinguishable', () {
    final List<ui.KeyData> keyDataList = <ui.KeyData>[];
    final KeyboardConverter converter = KeyboardConverter((ui.KeyData key) {
      keyDataList.add(key);
      return true;
    });

    // The absolute values of the following logical keys are not guaranteed.
    const int kLogicalAltE = 0x1740070008;
    const int kLogicalAltU = 0x1740070018;
    const int kLogicalAltShiftE = 0x1760070008;
    // The values must be distinguishable.
    expect(kLogicalAltE, isNot(equals(kLogicalAltU)));
    expect(kLogicalAltE, isNot(equals(kLogicalAltShiftE)));

    converter.handleEvent(keyDownEvent('AltLeft', 'Alt', kAlt, kLocationLeft));

    converter.handleEvent(keyDownEvent('KeyE', 'Dead', kAlt));
    expectKeyData(keyDataList.last,
      type: ui.KeyEventType.down,
      physical: kPhysicalKeyE,
      logical: kLogicalAltE,
      character: null,
    );

    converter.handleEvent(keyUpEvent('KeyE', 'Dead', kAlt));
    expectKeyData(keyDataList.last,
      type: ui.KeyEventType.up,
      physical: kPhysicalKeyE,
      logical: kLogicalAltE,
      character: null,
    );

    converter.handleEvent(keyDownEvent('KeyU', 'Dead', kAlt));
    expectKeyData(keyDataList.last,
      type: ui.KeyEventType.down,
      physical: kPhysicalKeyU,
      logical: kLogicalAltU,
      character: null,
    );

    converter.handleEvent(keyUpEvent('KeyU', 'Dead', kAlt));
    expectKeyData(keyDataList.last,
      type: ui.KeyEventType.up,
      physical: kPhysicalKeyU,
      logical: kLogicalAltU,
      character: null,
    );

    converter.handleEvent(keyDownEvent('ShiftLeft', 'Shift', kAlt | kShift, kLocationLeft));

    // This does not actually produce a Dead key on macOS (US layout); just for
    // testing.
    converter.handleEvent(keyDownEvent('KeyE', 'Dead', kAlt | kShift));
    expectKeyData(keyDataList.last,
      type: ui.KeyEventType.down,
      physical: kPhysicalKeyE,
      logical: kLogicalAltShiftE,
      character: null,
    );

    converter.handleEvent(keyUpEvent('AltLeft', 'Alt', kShift, kLocationLeft));

    converter.handleEvent(keyUpEvent('KeyE', 'e', kShift));
    expectKeyData(keyDataList.last,
      type: ui.KeyEventType.up,
      physical: kPhysicalKeyE,
      logical: kLogicalAltShiftE,
      character: null,
    );

    converter.handleEvent(keyUpEvent('ShiftLeft', 'Shift', 0, kLocationLeft));
  });

  test('Duplicate down is preceded with synthesized up', () {
    final List<ui.KeyData> keyDataList = <ui.KeyData>[];
    final KeyboardConverter converter = KeyboardConverter((ui.KeyData key) {
      keyDataList.add(key);
      return true;
    });
    bool preventedDefault = false;
    void onPreventDefault() { preventedDefault = true; }

    converter.handleEvent(keyDownEvent('ShiftLeft', 'Shift', kShift, kLocationLeft)
      ..onPreventDefault = onPreventDefault
    );
    expect(preventedDefault, isTrue);
    preventedDefault = false;
    // A KeyUp of ShiftLeft is missed.

    keyDataList.clear();
    converter.handleEvent(keyDownEvent('ShiftLeft', 'Shift', kShift, kLocationLeft)
      ..onPreventDefault = onPreventDefault
    );
    expect(keyDataList, hasLength(2));
    expectKeyData(keyDataList.first,
      type: ui.KeyEventType.up,
      physical: kPhysicalShiftLeft,
      logical: kLogicalShiftLeft,
      character: null,
      synthesized: true,
    );
    expectKeyData(keyDataList.last,
      type: ui.KeyEventType.down,
      physical: kPhysicalShiftLeft,
      logical: kLogicalShiftLeft,
      character: null,
    );
    expect(preventedDefault, isTrue);

    keyDataList.clear();
    converter.handleEvent(keyUpEvent('ShiftLeft', 'Shift', 0, kLocationLeft)
      ..onPreventDefault = onPreventDefault
    );
    expect(keyDataList, hasLength(1));
    expectKeyData(keyDataList.last,
      type: ui.KeyEventType.up,
      physical: kPhysicalShiftLeft,
      logical: kLogicalShiftLeft,
      character: null,
    );
    expect(preventedDefault, isTrue);
  });

  test('Duplicate ups are skipped', () {
    final List<ui.KeyData> keyDataList = <ui.KeyData>[];
    final KeyboardConverter converter = KeyboardConverter((ui.KeyData key) {
      keyDataList.add(key);
      return true;
    });
    bool preventedDefault = false;
    void onPreventDefault() { preventedDefault = true; }

    // A KeyDown of ShiftRight is missed due to loss of focus.
    converter.handleEvent(keyUpEvent('ShiftRight', 'Shift', 0, kLocationRight)
      ..onPreventDefault = onPreventDefault
    );
    expect(keyDataList, hasLength(1));
    expect(keyDataList[0].physical, 0);
    expect(keyDataList[0].logical, 0);
    expect(preventedDefault, isTrue);
  });

  test('Conflict from multiple keyboards do not crash', () {
    final List<ui.KeyData> keyDataList = <ui.KeyData>[];
    final KeyboardConverter converter = KeyboardConverter((ui.KeyData key) {
      keyDataList.add(key);
      return true;
    });

    // Same layout
    converter.handleEvent(keyDownEvent('KeyA', 'a'));
    converter.handleEvent(keyDownEvent('KeyA', 'a'));
    converter.handleEvent(keyUpEvent('KeyA', 'a'));
    converter.handleEvent(keyUpEvent('KeyA', 'a'));

    // Different layout
    converter.handleEvent(keyDownEvent('KeyA', 'a'));
    converter.handleEvent(keyDownEvent('KeyA', 'u'));
    converter.handleEvent(keyUpEvent('KeyA', 'u'));
    converter.handleEvent(keyUpEvent('KeyA', 'a'));

    // Passes if there's no crash, and states are reset after everything is released.
    keyDataList.clear();
    converter.handleEvent(keyDownEvent('KeyA', 'a'));
    expectKeyData(keyDataList.last,
      type: ui.KeyEventType.down,
      physical: kPhysicalKeyA,
      logical: kLogicalKeyA,
      character: 'a',
    );

    converter.handleEvent(keyDownEvent('KeyU', 'u'));
    expectKeyData(keyDataList.last,
      type: ui.KeyEventType.down,
      physical: kPhysicalKeyU,
      logical: kLogicalKeyU,
      character: 'u',
    );
  });

  testFakeAsync('CapsLock down synthesizes an immediate cancel on macOS', (FakeAsync async) {
    final List<ui.KeyData> keyDataList = <ui.KeyData>[];
    final KeyboardConverter converter = KeyboardConverter((ui.KeyData key) {
      keyDataList.add(key);
      return true;
    }, onMacOs: true);
    bool preventedDefault = false;
    void onPreventDefault() { preventedDefault = true; }

    // A KeyDown of ShiftRight is missed due to loss of focus.
    converter.handleEvent(keyDownEvent('CapsLock', 'CapsLock')
      ..onPreventDefault = onPreventDefault
    );
    expect(keyDataList, hasLength(1));
    expectKeyData(keyDataList.last,
      type: ui.KeyEventType.down,
      physical: kPhysicalCapsLock,
      logical: kLogicalCapsLock,
      character: null,
    );
    expect(preventedDefault, isTrue);
    keyDataList.clear();
    preventedDefault = false;

    async.elapse(const Duration(microseconds: 1));
    expect(keyDataList, hasLength(1));
    expectKeyData(keyDataList.last,
      type: ui.KeyEventType.up,
      physical: kPhysicalCapsLock,
      logical: kLogicalCapsLock,
      character: null,
      synthesized: true,
    );
    expect(preventedDefault, isFalse);
    keyDataList.clear();

    converter.handleEvent(keyUpEvent('CapsLock', 'CapsLock')
      ..onPreventDefault = onPreventDefault
    );
    expect(keyDataList, hasLength(1));
    expectKeyData(keyDataList.last,
      type: ui.KeyEventType.down,
      physical: kPhysicalCapsLock,
      logical: kLogicalCapsLock,
      character: null,
    );
    expect(preventedDefault, isTrue);
    keyDataList.clear();
    preventedDefault = false;

    async.elapse(const Duration(microseconds: 1));
    expect(keyDataList, hasLength(1));
    expectKeyData(keyDataList.last,
      type: ui.KeyEventType.up,
      physical: kPhysicalCapsLock,
      logical: kLogicalCapsLock,
      character: null,
      synthesized: true,
    );
    expect(preventedDefault, isFalse);
    keyDataList.clear();

    // Another key down works
    converter.handleEvent(keyDownEvent('CapsLock', 'CapsLock'));
    expect(keyDataList, hasLength(1));
    expectKeyData(keyDataList.last,
      type: ui.KeyEventType.down,
      physical: kPhysicalCapsLock,
      logical: kLogicalCapsLock,
      character: null,
    );
    keyDataList.clear();


    // Schedules are canceled after disposal
    converter.dispose();
    async.elapse(const Duration(seconds: 10));
    expect(keyDataList, isEmpty);
  });

  testFakeAsync('CapsLock behaves normally on non-macOS', (FakeAsync async) {
    final List<ui.KeyData> keyDataList = <ui.KeyData>[];
    final KeyboardConverter converter = KeyboardConverter((ui.KeyData key) {
      keyDataList.add(key);
      return true;
    }, onMacOs: false);

    converter.handleEvent(keyDownEvent('CapsLock', 'CapsLock'));
    expect(keyDataList, hasLength(1));
    expectKeyData(keyDataList.last,
      type: ui.KeyEventType.down,
      physical: kPhysicalCapsLock,
      logical: kLogicalCapsLock,
      character: null,
    );
    keyDataList.clear();

    async.elapse(const Duration(seconds: 10));
    expect(keyDataList, isEmpty);

    converter.handleEvent(keyUpEvent('CapsLock', 'CapsLock'));
    expect(keyDataList, hasLength(1));
    expectKeyData(keyDataList.last,
      type: ui.KeyEventType.up,
      physical: kPhysicalCapsLock,
      logical: kLogicalCapsLock,
      character: null,
    );
    keyDataList.clear();

    async.elapse(const Duration(seconds: 10));
    expect(keyDataList, isEmpty);

    converter.handleEvent(keyDownEvent('CapsLock', 'CapsLock'));
    expectKeyData(keyDataList.last,
      type: ui.KeyEventType.down,
      physical: kPhysicalCapsLock,
      logical: kLogicalCapsLock,
      character: null,
    );

    converter.handleEvent(keyUpEvent('CapsLock', 'CapsLock'));
    expectKeyData(keyDataList.last,
      type: ui.KeyEventType.up,
      physical: kPhysicalCapsLock,
      logical: kLogicalCapsLock,
      character: null,
    );
  });

  testFakeAsync('Key guards: key down events are guarded on macOS', (FakeAsync async) {
    final List<ui.KeyData> keyDataList = <ui.KeyData>[];
    final KeyboardConverter converter = KeyboardConverter((ui.KeyData key) {
      keyDataList.add(key);
      return true;
    }, onMacOs: true);

    converter.handleEvent(keyDownEvent('MetaLeft', 'Meta', kMeta, kLocationLeft)..timeStamp = 100);
    async.elapse(const Duration(milliseconds: 100));

    converter.handleEvent(keyDownEvent('KeyA', 'a', kMeta)..timeStamp = 200);
    expectKeyData(keyDataList.last,
      timeStamp: const Duration(milliseconds: 200),
      type: ui.KeyEventType.down,
      physical: kPhysicalKeyA,
      logical: kLogicalKeyA,
      character: 'a',
    );
    keyDataList.clear();

    // Keyup of KeyA is omitted due to being a shortcut.

    async.elapse(const Duration(milliseconds: 2500));
    expectKeyData(keyDataList.last,
      timeStamp: const Duration(milliseconds: 2200),
      type: ui.KeyEventType.up,
      physical: kPhysicalKeyA,
      logical: kLogicalKeyA,
      character: null,
      synthesized: true,
    );
    keyDataList.clear();

    converter.handleEvent(keyUpEvent('MetaLeft', 'Meta', 0, kLocationLeft)..timeStamp = 2700);
    expectKeyData(keyDataList.last,
      timeStamp: const Duration(milliseconds: 2700),
      type: ui.KeyEventType.up,
      physical: kPhysicalMetaLeft,
      logical: kLogicalMetaLeft,
      character: null,
    );
    async.elapse(const Duration(milliseconds: 100));

    // Key A states are cleared
    converter.handleEvent(keyDownEvent('KeyA', 'a')..timeStamp = 2800);
    expectKeyData(keyDataList.last,
      timeStamp: const Duration(milliseconds: 2800),
      type: ui.KeyEventType.down,
      physical: kPhysicalKeyA,
      logical: kLogicalKeyA,
      character: 'a',
    );
    async.elapse(const Duration(milliseconds: 100));

    converter.handleEvent(keyUpEvent('KeyA', 'a')..timeStamp = 2900);
    expectKeyData(keyDataList.last,
      timeStamp: const Duration(milliseconds: 2900),
      type: ui.KeyEventType.up,
      physical: kPhysicalKeyA,
      logical: kLogicalKeyA,
      character: null,
    );
  });

  testFakeAsync('Key guards: key repeated down events refreshes guards', (FakeAsync async) {
    final List<ui.KeyData> keyDataList = <ui.KeyData>[];
    final KeyboardConverter converter = KeyboardConverter((ui.KeyData key) {
      keyDataList.add(key);
      return true;
    }, onMacOs: true);

    converter.handleEvent(keyDownEvent('MetaLeft', 'Meta', kMeta, kLocationLeft)..timeStamp = 100);
    async.elapse(const Duration(milliseconds: 100));

    converter.handleEvent(keyDownEvent('KeyA', 'a', kMeta)..timeStamp = 200);
    async.elapse(const Duration(milliseconds: 400));

    converter.handleEvent(keyRepeatedDownEvent('KeyA', 'a', kMeta)..timeStamp = 600);
    async.elapse(const Duration(milliseconds: 50));
    converter.handleEvent(keyRepeatedDownEvent('KeyA', 'a', kMeta)..timeStamp = 650);
    async.elapse(const Duration(milliseconds: 50));
    converter.handleEvent(keyRepeatedDownEvent('KeyA', 'a', kMeta)..timeStamp = 700);

    // Keyup of KeyA is omitted due to being a shortcut.

    async.elapse(const Duration(milliseconds: 2000));
    expectKeyData(keyDataList.last,
      timeStamp: const Duration(milliseconds: 2700),
      type: ui.KeyEventType.up,
      physical: kPhysicalKeyA,
      logical: kLogicalKeyA,
      character: null,
      synthesized: true,
    );
    keyDataList.clear();

    converter.handleEvent(keyUpEvent('MetaLeft', 'Meta', 0, kLocationLeft)..timeStamp = 3200);
    expectKeyData(keyDataList.last,
      timeStamp: const Duration(milliseconds: 3200),
      type: ui.KeyEventType.up,
      physical: kPhysicalMetaLeft,
      logical: kLogicalMetaLeft,
      character: null,
    );
    async.elapse(const Duration(milliseconds: 100));

    // Key A states are cleared
    converter.handleEvent(keyDownEvent('KeyA', 'a')..timeStamp = 3300);
    expectKeyData(keyDataList.last,
      timeStamp: const Duration(milliseconds: 3300),
      type: ui.KeyEventType.down,
      physical: kPhysicalKeyA,
      logical: kLogicalKeyA,
      character: 'a',
    );
    async.elapse(const Duration(milliseconds: 100));

    converter.handleEvent(keyUpEvent('KeyA', 'a')..timeStamp = 3400);
    expectKeyData(keyDataList.last,
      timeStamp: const Duration(milliseconds: 3400),
      type: ui.KeyEventType.up,
      physical: kPhysicalKeyA,
      logical: kLogicalKeyA,
      character: null,
    );
  });

  testFakeAsync('Key guards: cleared by keyups', (FakeAsync async) {
    final List<ui.KeyData> keyDataList = <ui.KeyData>[];
    final KeyboardConverter converter = KeyboardConverter((ui.KeyData key) {
      keyDataList.add(key);
      return true;
    });

    converter.handleEvent(keyDownEvent('MetaLeft', 'Meta', kMeta, kLocationLeft)..timeStamp = 100);
    async.elapse(const Duration(milliseconds: 100));

    converter.handleEvent(keyDownEvent('KeyA', 'a', kCtrl)..timeStamp = 200);
    expectKeyData(keyDataList.last,
      timeStamp: const Duration(milliseconds: 200),
      type: ui.KeyEventType.down,
      physical: kPhysicalKeyA,
      logical: kLogicalKeyA,
      character: 'a',
    );
    keyDataList.clear();
    async.elapse(const Duration(milliseconds: 500));

    converter.handleEvent(keyUpEvent('MetaLeft', 'Meta', 0, kLocationLeft)..timeStamp = 700);
    async.elapse(const Duration(milliseconds: 100));

    converter.handleEvent(keyUpEvent('KeyA', 'a')..timeStamp = 800);
    expectKeyData(keyDataList.last,
      timeStamp: const Duration(milliseconds: 800),
      type: ui.KeyEventType.up,
      physical: kPhysicalKeyA,
      logical: kLogicalKeyA,
      character: null,
    );
    keyDataList.clear();
    async.elapse(const Duration(milliseconds: 2000));
    expect(keyDataList, isEmpty);

    // Key A states are cleared
    converter.handleEvent(keyDownEvent('KeyA', 'a')..timeStamp = 2800);
    expectKeyData(keyDataList.last,
      timeStamp: const Duration(milliseconds: 2800),
      type: ui.KeyEventType.down,
      physical: kPhysicalKeyA,
      logical: kLogicalKeyA,
      character: 'a',
    );
    async.elapse(const Duration(milliseconds: 100));

    converter.handleEvent(keyUpEvent('KeyA', 'a')..timeStamp = 2900);
    expectKeyData(keyDataList.last,
      timeStamp: const Duration(milliseconds: 2900),
      type: ui.KeyEventType.up,
      physical: kPhysicalKeyA,
      logical: kLogicalKeyA,
      character: null,
    );
  });

  testFakeAsync('Key guards: key down events are not guarded on non-macOS', (FakeAsync async) {
    final List<ui.KeyData> keyDataList = <ui.KeyData>[];
    final KeyboardConverter converter = KeyboardConverter((ui.KeyData key) {
      keyDataList.add(key);
      return true;
    }, onMacOs: false);

    converter.handleEvent(keyDownEvent('MetaLeft', 'Meta', kMeta, kLocationLeft)..timeStamp = 100);
    async.elapse(const Duration(milliseconds: 100));

    converter.handleEvent(keyDownEvent('KeyA', 'a', kMeta)..timeStamp = 200);
    expectKeyData(keyDataList.last,
      timeStamp: const Duration(milliseconds: 200),
      type: ui.KeyEventType.down,
      physical: kPhysicalKeyA,
      logical: kLogicalKeyA,
      character: 'a',
    );
    keyDataList.clear();

    async.elapse(const Duration(milliseconds: 2500));
    expect(keyDataList, isEmpty);
  });

  testFakeAsync('Lock flags of other keys', (FakeAsync async) {
    final List<ui.KeyData> keyDataList = <ui.KeyData>[];
    final KeyboardConverter converter = KeyboardConverter((ui.KeyData key) {
      keyDataList.add(key);
      return true;
    }, onMacOs: false);

    converter.handleEvent(keyDownEvent('ScrollLock', 'ScrollLock'));
    expect(keyDataList, hasLength(1));
    expectKeyData(keyDataList.last,
      type: ui.KeyEventType.down,
      physical: kPhysicalScrollLock,
      logical: kLogicalScrollLock,
      character: null,
    );
    keyDataList.clear();

    async.elapse(const Duration(seconds: 10));
    expect(keyDataList, isEmpty);

    converter.handleEvent(keyUpEvent('ScrollLock', 'ScrollLock'));
    expect(keyDataList, hasLength(1));
    expectKeyData(keyDataList.last,
      type: ui.KeyEventType.up,
      physical: kPhysicalScrollLock,
      logical: kLogicalScrollLock,
      character: null,
    );
    keyDataList.clear();

    converter.handleEvent(keyDownEvent('ScrollLock', 'ScrollLock'));
    expectKeyData(keyDataList.last,
      type: ui.KeyEventType.down,
      physical: kPhysicalScrollLock,
      logical: kLogicalScrollLock,
      character: null,
    );

    converter.handleEvent(keyUpEvent('ScrollLock', 'ScrollLock'));
    expectKeyData(keyDataList.last,
      type: ui.KeyEventType.up,
      physical: kPhysicalScrollLock,
      logical: kLogicalScrollLock,
      character: null,
    );
  });

  test('Deduce modifier key up from modifier field', () {
    final List<ui.KeyData> keyDataList = <ui.KeyData>[];
    final KeyboardConverter converter = KeyboardConverter((ui.KeyData key) {
      keyDataList.add(key);
      return true;
    }, onMacOs: false);

    converter.handleEvent(keyDownEvent('ShiftRight', 'Shift', kShift, kLocationRight));
    expectKeyData(keyDataList.last,
      type: ui.KeyEventType.down,
      physical: kPhysicalShiftRight,
      logical: kLogicalShiftRight,
      character: null,
    );

    converter.handleEvent(keyDownEvent('ShiftLeft', 'Shift', kShift, kLocationLeft));
    expectKeyData(keyDataList.last,
      type: ui.KeyEventType.down,
      physical: kPhysicalShiftLeft,
      logical: kLogicalShiftLeft,
      character: null,
    );
    keyDataList.clear();

    // The release of the shift keys are omitted

    converter.handleEvent(keyDownEvent('KeyA', 'a'));
    expect(keyDataList, hasLength(3));
    expectKeyData(keyDataList[0],
      type: ui.KeyEventType.up,
      physical: kPhysicalShiftLeft,
      logical: kLogicalShiftLeft,
      character: null,
      synthesized: true,
    );
    expectKeyData(keyDataList[1],
      type: ui.KeyEventType.up,
      physical: kPhysicalShiftRight,
      logical: kLogicalShiftRight,
      character: null,
      synthesized: true,
    );
    expectKeyData(keyDataList.last,
      type: ui.KeyEventType.down,
      physical: kPhysicalKeyA,
      logical: kLogicalKeyA,
      character: 'a',
    );
  });

  // Regression test for https://github.com/flutter/flutter/issues/99297.
  //
  // On Linux Chrome, when holding ShiftLeft and pressing MetaLeft (Win key),
  // the MetaLeft down event has metaKey true, while the Meta up event has
  // metaKey false. This violates the definition of metaKey, and does not happen
  // in nearly any other cases for any other keys.
  test('Ignore inconsistent modifier flag of the current modifier', () {
    final List<ui.KeyData> keyDataList = <ui.KeyData>[];
    final KeyboardConverter converter = KeyboardConverter((ui.KeyData key) {
      keyDataList.add(key);
      return true;
    }, onMacOs: false);

    converter.handleEvent(keyDownEvent('ShiftLeft', 'Shift', kShift, kLocationLeft));
    expectKeyData(keyDataList.last,
      type: ui.KeyEventType.down,
      physical: kPhysicalShiftLeft,
      logical: kLogicalShiftLeft,
      character: null,
    );
    keyDataList.clear();

    converter.handleEvent(keyDownEvent('MetaLeft', 'Meta', kShift /* No kMeta here! */, kLocationLeft));
    // Only a MetaLeft down event, no synthesized MetaLeft up events.
    expect(keyDataList, hasLength(1));
    expectKeyData(keyDataList.first,
      type: ui.KeyEventType.down,
      physical: kPhysicalMetaLeft,
      logical: kLogicalMetaLeft,
      character: null,
    );
    keyDataList.clear();

    converter.handleEvent(keyUpEvent('MetaLeft', 'Meta', kShift | kMeta /* Yes, kMeta here! */, kLocationLeft));
    // Only a MetaLeft down event, no synthesized MetaLeft up events.
    expect(keyDataList, hasLength(1));
    expectKeyData(keyDataList.first,
      type: ui.KeyEventType.up,
      physical: kPhysicalMetaLeft,
      logical: kLogicalMetaLeft,
      character: null,
    );
    keyDataList.clear();

    converter.handleEvent(keyUpEvent('ShiftLeft', 'Shift', 0, kLocationLeft));
    expectKeyData(keyDataList.last,
      type: ui.KeyEventType.up,
      physical: kPhysicalShiftLeft,
      logical: kLogicalShiftLeft,
      character: null,
    );
    keyDataList.clear();
  });
}

class MockKeyboardEvent implements FlutterHtmlKeyboardEvent {
  MockKeyboardEvent({
    required this.type,
    required this.code,
    required this.key,
    this.timeStamp = 0,
    this.repeat = false,
    this.altKey = false,
    this.ctrlKey = false,
    this.shiftKey = false,
    this.metaKey = false,
    this.location = 0,
    this.onPreventDefault,
  });

  @override
  String type;

  @override
  String? code;

  @override
  String? key;

  @override
  bool? repeat;

  @override
  num? timeStamp;

  @override
  bool altKey;

  @override
  bool ctrlKey;

  @override
  bool shiftKey;

  @override
  bool metaKey;

  @override
  int? location;

  @override
  bool getModifierState(String key) => modifierState.contains(key);
  final Set<String> modifierState = <String>{};

  @override
  void preventDefault() { onPreventDefault?.call(); }
  VoidCallback? onPreventDefault;
}

// Flags used for the `modifiers` argument of `key***Event` functions.
const int kAlt = 0x1;
const int kCtrl = 0x2;
const int kShift = 0x4;
const int kMeta = 0x8;

// Utility functions to make code more concise.
//
// To add timeStamp or onPreventDefault, use syntax like `..timeStamp = `.
MockKeyboardEvent keyDownEvent(String code, String key, [int modifiers = 0, int location = 0]) {
  return MockKeyboardEvent(
    type: 'keydown',
    code: code,
    key: key,
    altKey: modifiers & kAlt != 0,
    ctrlKey: modifiers & kCtrl != 0,
    shiftKey: modifiers & kShift != 0,
    metaKey: modifiers & kMeta != 0,
    location: location,
  );
}

MockKeyboardEvent keyUpEvent(String code, String key, [int modifiers = 0, int location = 0]) {
  return MockKeyboardEvent(
    type: 'keyup',
    code: code,
    key: key,
    altKey: modifiers & kAlt != 0,
    ctrlKey: modifiers & kCtrl != 0,
    shiftKey: modifiers & kShift != 0,
    metaKey: modifiers & kMeta != 0,
    location: location,
  );
}

MockKeyboardEvent keyRepeatedDownEvent(String code, String key, [int modifiers = 0, int location = 0]) {
  return MockKeyboardEvent(
    type: 'keydown',
    code: code,
    key: key,
    altKey: modifiers & kAlt != 0,
    ctrlKey: modifiers & kCtrl != 0,
    shiftKey: modifiers & kShift != 0,
    metaKey: modifiers & kMeta != 0,
    repeat: true,
    location: location,
  );
}

// Flags used for the `activeLocks` argument of expectKeyData.
const int kCapsLock = 0x1;
const int kNumlLock = 0x2;
const int kScrollLock = 0x4;

void expectKeyData(
  ui.KeyData target, {
  required ui.KeyEventType type,
  required int physical,
  required int logical,
  required String? character,
  Duration? timeStamp,
  bool synthesized = false,
}) {
  expect(target.type, type);
  expect(target.physical, physical);
  expect(target.logical, logical);
  expect(target.character, character);
  expect(target.synthesized, synthesized);
  if (timeStamp != null)
    expect(target.timeStamp, equals(timeStamp));
}

typedef FakeAsyncTest = void Function(FakeAsync);

@isTest
void testFakeAsync(String description, FakeAsyncTest fn) {
  test(description, () {
    FakeAsync().run(fn);
  });
}
