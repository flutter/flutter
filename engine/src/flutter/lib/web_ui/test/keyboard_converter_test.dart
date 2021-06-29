// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:quiver/testing/async.dart';
import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine/keyboard_binding.dart';
import 'package:ui/ui.dart' as ui;
import 'package:meta/meta.dart' show isTest;

const int kLocationLeft = 1;
const int kLocationRight = 2;
const int kLocationNumpad = 3;

const int kPhysicalKeyA = 0x00070004;
const int kPhysicalKeyE = 0x00070008;
const int kPhysicalKeyU = 0x00070018;
const int kPhysicalDigit1 = 0x0007001e;
const int kPhysicalNumpad1 = 0x00070059;
const int kPhysicalShiftLeft = 0x000700e1;
const int kPhysicalShiftRight = 0x000700e5;
const int kPhysicalMetaLeft = 0x000700e3;
const int kPhysicalTab = 0x0007002b;
const int kPhysicalCapsLock = 0x00070039;
const int kPhysicalScrollLock = 0x00070047;

const int kLogicalKeyA = 0x00000000061;
const int kLogicalKeyU = 0x00000000075;
const int kLogicalDigit1 = 0x00000000031;
const int kLogicalNumpad1 = 0x00200000031;
const int kLogicalShiftLeft = 0x030000010d;
const int kLogicalShiftRight = 0x040000010d;
const int kLogicalMetaLeft = 0x0300000109;
const int kLogicalTab = 0x0000000009;
const int kLogicalCapsLock = 0x00000000104;
const int kLogicalScrollLock = 0x0000000010c;

typedef VoidCallback = void Function();

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  test('Single key press, repeat, and release', () {
    final List<ui.KeyData> keyDataList = <ui.KeyData>[];
    final KeyboardConverter converter = KeyboardConverter((ui.KeyData key) {
      keyDataList.add(key);
      // Only handle down events
      return key.type == ui.KeyEventType.down;
    });
    bool preventedDefault = false;
    final onPreventDefault = () { preventedDefault = true; };

    converter.handleEvent(keyDownEvent('KeyA', 'a')
      ..timeStamp = 1
      ..onPreventDefault = onPreventDefault
    );
    expectKeyData(keyDataList.last,
      timeStamp: Duration(milliseconds: 1),
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
      timeStamp: Duration(milliseconds: 1, microseconds: 500),
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
      timeStamp: Duration(seconds: 1, milliseconds: 500),
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
      timeStamp: Duration(seconds: 2, microseconds: 500),
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
    final onPreventDefault = () { preventedDefault = true; };

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
    const int kLogicalAltE = 0x410800070008;
    const int kLogicalAltU = 0x410800070018;
    const int kLogicalAltShiftE = 0x610800070008;
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

  test('Duplicate down is ignored', () {
    final List<ui.KeyData> keyDataList = <ui.KeyData>[];
    final KeyboardConverter converter = KeyboardConverter((ui.KeyData key) {
      keyDataList.add(key);
      return true;
    });
    bool preventedDefault = false;
    final onPreventDefault = () { preventedDefault = true; };

    converter.handleEvent(keyDownEvent('ShiftLeft', 'Shift', kShift, kLocationLeft)
      ..onPreventDefault = onPreventDefault
    );
    expect(preventedDefault, isTrue);
    preventedDefault = false;
    // A KeyUp of ShiftLeft is missed due to loss of focus.

    keyDataList.clear();
    converter.handleEvent(keyDownEvent('ShiftLeft', 'Shift', kShift, kLocationLeft)
      ..onPreventDefault = onPreventDefault
    );
    expect(keyDataList, isEmpty);
    expect(preventedDefault, isFalse);

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
    final onPreventDefault = () { preventedDefault = true; };

    // A KeyDown of ShiftRight is missed due to loss of focus.
    converter.handleEvent(keyUpEvent('ShiftRight', 'Shift', 0, kLocationRight)
      ..onPreventDefault = onPreventDefault
    );
    expect(keyDataList, isEmpty);
    expect(preventedDefault, isFalse);
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
    final onPreventDefault = () { preventedDefault = true; };

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

    async.elapse(Duration(microseconds: 1));
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

    async.elapse(Duration(microseconds: 1));
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
    async.elapse(Duration(seconds: 10));
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

    async.elapse(Duration(seconds: 10));
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

    async.elapse(Duration(seconds: 10));
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

  testFakeAsync('Key guards: key down events are guarded', (FakeAsync async) {
    final List<ui.KeyData> keyDataList = <ui.KeyData>[];
    final KeyboardConverter converter = KeyboardConverter((ui.KeyData key) {
      keyDataList.add(key);
      return true;
    });

    converter.handleEvent(keyDownEvent('MetaLeft', 'Meta', kMeta, kLocationLeft)..timeStamp = 100);
    async.elapse(Duration(milliseconds: 100));

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

    async.elapse(Duration(milliseconds: 2500));
    expectKeyData(keyDataList.last,
      timeStamp: const Duration(milliseconds: 1200),
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
    async.elapse(Duration(milliseconds: 100));

    // Key A states are cleared
    converter.handleEvent(keyDownEvent('KeyA', 'a')..timeStamp = 2800);
    expectKeyData(keyDataList.last,
      timeStamp: const Duration(milliseconds: 2800),
      type: ui.KeyEventType.down,
      physical: kPhysicalKeyA,
      logical: kLogicalKeyA,
      character: 'a',
    );
    async.elapse(Duration(milliseconds: 100));

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
    });

    converter.handleEvent(keyDownEvent('MetaLeft', 'Meta', kMeta, kLocationLeft)..timeStamp = 100);
    async.elapse(Duration(milliseconds: 100));

    converter.handleEvent(keyDownEvent('KeyA', 'a', kMeta)..timeStamp = 200);
    async.elapse(Duration(milliseconds: 400));

    converter.handleEvent(keyRepeatedDownEvent('KeyA', 'a', kMeta)..timeStamp = 600);
    async.elapse(Duration(milliseconds: 50));
    converter.handleEvent(keyRepeatedDownEvent('KeyA', 'a', kMeta)..timeStamp = 650);
    async.elapse(Duration(milliseconds: 50));
    converter.handleEvent(keyRepeatedDownEvent('KeyA', 'a', kMeta)..timeStamp = 700);

    // Keyup of KeyA is omitted due to being a shortcut.

    async.elapse(Duration(milliseconds: 2500));
    expectKeyData(keyDataList.last,
      timeStamp: const Duration(milliseconds: 1700),
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
    async.elapse(Duration(milliseconds: 100));

    // Key A states are cleared
    converter.handleEvent(keyDownEvent('KeyA', 'a')..timeStamp = 3300);
    expectKeyData(keyDataList.last,
      timeStamp: const Duration(milliseconds: 3300),
      type: ui.KeyEventType.down,
      physical: kPhysicalKeyA,
      logical: kLogicalKeyA,
      character: 'a',
    );
    async.elapse(Duration(milliseconds: 100));

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
    async.elapse(Duration(milliseconds: 100));

    converter.handleEvent(keyDownEvent('KeyA', 'a', kCtrl)..timeStamp = 200);
    expectKeyData(keyDataList.last,
      timeStamp: const Duration(milliseconds: 200),
      type: ui.KeyEventType.down,
      physical: kPhysicalKeyA,
      logical: kLogicalKeyA,
      character: 'a',
    );
    keyDataList.clear();
    async.elapse(Duration(milliseconds: 500));

    converter.handleEvent(keyUpEvent('MetaLeft', 'Meta', 0, kLocationLeft)..timeStamp = 700);
    async.elapse(Duration(milliseconds: 100));

    converter.handleEvent(keyUpEvent('KeyA', 'a')..timeStamp = 800);
    expectKeyData(keyDataList.last,
      timeStamp: const Duration(milliseconds: 800),
      type: ui.KeyEventType.up,
      physical: kPhysicalKeyA,
      logical: kLogicalKeyA,
      character: null,
    );
    keyDataList.clear();
    async.elapse(Duration(milliseconds: 2000));
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
    async.elapse(Duration(milliseconds: 100));

    converter.handleEvent(keyUpEvent('KeyA', 'a')..timeStamp = 2900);
    expectKeyData(keyDataList.last,
      timeStamp: const Duration(milliseconds: 2900),
      type: ui.KeyEventType.up,
      physical: kPhysicalKeyA,
      logical: kLogicalKeyA,
      character: null,
    );
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

    async.elapse(Duration(seconds: 10));
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

  String type;
  String? code;
  String? key;
  bool? repeat;
  num? timeStamp;
  bool altKey;
  bool ctrlKey;
  bool shiftKey;
  bool metaKey;
  int? location;

  bool getModifierState(String key) => modifierState.contains(key);
  final Set<String> modifierState = <String>{};

  void preventDefault() { onPreventDefault?.call(); }
  VoidCallback? onPreventDefault;
}

// Flags used for the `modifiers` argument of `key***Event` functions.
const kAlt = 0x1;
const kCtrl = 0x2;
const kShift = 0x4;
const kMeta = 0x8;

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
const kCapsLock = 0x1;
const kNumlLock = 0x2;
const kScrollLock = 0x4;

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
