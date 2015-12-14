// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:test/test.dart';

typedef void GestureArenaCallback(Object key);

const int primaryKey = 4;

class TestGestureArenaMember extends GestureArenaMember {
  bool acceptRan = false;
  void acceptGesture(Object key) {
    expect(key, equals(primaryKey));
    acceptRan = true;
  }
  bool rejectRan = false;
  void rejectGesture(Object key) {
    expect(key, equals(primaryKey));
    rejectRan = true;
  }
}

class GestureTester {
  GestureArena arena = new GestureArena();
  TestGestureArenaMember first = new TestGestureArenaMember();
  TestGestureArenaMember second = new TestGestureArenaMember();

  GestureArenaEntry firstEntry;
  void addFirst() {
    firstEntry = arena.add(primaryKey, first);
  }

  GestureArenaEntry secondEntry;
  void addSecond() {
    secondEntry = arena.add(primaryKey, second);
  }

  void expectNothing() {
    expect(first.acceptRan, isFalse);
    expect(first.rejectRan, isFalse);
    expect(second.acceptRan, isFalse);
    expect(second.rejectRan, isFalse);
  }

  void expectFirstWin() {
    expect(first.acceptRan, isTrue);
    expect(first.rejectRan, isFalse);
    expect(second.acceptRan, isFalse);
    expect(second.rejectRan, isTrue);
  }

  void expectSecondWin() {
    expect(first.acceptRan, isFalse);
    expect(first.rejectRan, isTrue);
    expect(second.acceptRan, isTrue);
    expect(second.rejectRan, isFalse);
  }
}

void main() {
  test('Should win by accepting', () {
    GestureTester tester = new GestureTester();
    tester.addFirst();
    tester.addSecond();
    tester.arena.close(primaryKey);
    tester.expectNothing();
    tester.firstEntry.resolve(GestureDisposition.accepted);
    tester.expectFirstWin();
  });

  test('Should win by sweep', () {
    GestureTester tester = new GestureTester();
    tester.addFirst();
    tester.addSecond();
    tester.arena.close(primaryKey);
    tester.expectNothing();
    tester.arena.sweep(primaryKey);
    tester.expectFirstWin();
  });

  test('Should win on release after hold sweep release', () {
    GestureTester tester = new GestureTester();
    tester.addFirst();
    tester.addSecond();
    tester.arena.close(primaryKey);
    tester.expectNothing();
    tester.arena.hold(primaryKey);
    tester.expectNothing();
    tester.arena.sweep(primaryKey);
    tester.expectNothing();
    tester.arena.release(primaryKey);
    tester.expectFirstWin();
  });

  test('Should win on sweep after hold release sweep', () {
    GestureTester tester = new GestureTester();
    tester.addFirst();
    tester.addSecond();
    tester.arena.close(primaryKey);
    tester.expectNothing();
    tester.arena.hold(primaryKey);
    tester.expectNothing();
    tester.arena.release(primaryKey);
    tester.expectNothing();
    tester.arena.sweep(primaryKey);
    tester.expectFirstWin();
  });

  test('Only first winner should win', () {
    GestureTester tester = new GestureTester();
    tester.addFirst();
    tester.addSecond();
    tester.arena.close(primaryKey);
    tester.expectNothing();
    tester.firstEntry.resolve(GestureDisposition.accepted);
    tester.secondEntry.resolve(GestureDisposition.accepted);
    tester.expectFirstWin();
  });

  test('Only first winner should win, regardless of order', () {
    GestureTester tester = new GestureTester();
    tester.addFirst();
    tester.addSecond();
    tester.arena.close(primaryKey);
    tester.expectNothing();
    tester.secondEntry.resolve(GestureDisposition.accepted);
    tester.firstEntry.resolve(GestureDisposition.accepted);
    tester.expectSecondWin();
  });

  test('Win before close is delayed to close', () {
    GestureTester tester = new GestureTester();
    tester.addFirst();
    tester.addSecond();
    tester.expectNothing();
    tester.firstEntry.resolve(GestureDisposition.accepted);
    tester.expectNothing();
    tester.arena.close(primaryKey);
    tester.expectFirstWin();
  });

  test('Win before close is delayed to close, and only first winner should win', () {
    GestureTester tester = new GestureTester();
    tester.addFirst();
    tester.addSecond();
    tester.expectNothing();
    tester.firstEntry.resolve(GestureDisposition.accepted);
    tester.secondEntry.resolve(GestureDisposition.accepted);
    tester.expectNothing();
    tester.arena.close(primaryKey);
    tester.expectFirstWin();
  });

  test('Win before close is delayed to close, and only first winner should win, regardless of order', () {
    GestureTester tester = new GestureTester();
    tester.addFirst();
    tester.addSecond();
    tester.expectNothing();
    tester.secondEntry.resolve(GestureDisposition.accepted);
    tester.firstEntry.resolve(GestureDisposition.accepted);
    tester.expectNothing();
    tester.arena.close(primaryKey);
    tester.expectSecondWin();
  });
}
