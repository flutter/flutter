// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';

const int primaryKey = 4;

class TestGestureArenaMember extends GestureArenaMember {
  bool acceptRan = false;

  @override
  void acceptGesture(int key) {
    expect(key, equals(primaryKey));
    acceptRan = true;
  }

  bool rejectRan = false;

  @override
  void rejectGesture(int key) {
    expect(key, equals(primaryKey));
    rejectRan = true;
  }
}

class GestureTester {
  GestureArenaManager arena = GestureArenaManager();
  TestGestureArenaMember first = TestGestureArenaMember();
  TestGestureArenaMember second = TestGestureArenaMember();

  late GestureArenaEntry firstEntry;
  void addFirst() {
    firstEntry = arena.add(primaryKey, first);
  }

  late GestureArenaEntry secondEntry;
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
    final tester = GestureTester();
    tester.addFirst();
    tester.addSecond();
    tester.arena.close(primaryKey);
    tester.expectNothing();
    tester.firstEntry.resolve(GestureDisposition.accepted);
    tester.expectFirstWin();
  });

  test('Should win by sweep', () {
    final tester = GestureTester();
    tester.addFirst();
    tester.addSecond();
    tester.arena.close(primaryKey);
    tester.expectNothing();
    tester.arena.sweep(primaryKey);
    tester.expectFirstWin();
  });

  test('Should win on release after hold sweep release', () {
    final tester = GestureTester();
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
    final tester = GestureTester();
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
    final tester = GestureTester();
    tester.addFirst();
    tester.addSecond();
    tester.arena.close(primaryKey);
    tester.expectNothing();
    tester.firstEntry.resolve(GestureDisposition.accepted);
    tester.secondEntry.resolve(GestureDisposition.accepted);
    tester.expectFirstWin();
  });

  test('Only first winner should win, regardless of order', () {
    final tester = GestureTester();
    tester.addFirst();
    tester.addSecond();
    tester.arena.close(primaryKey);
    tester.expectNothing();
    tester.secondEntry.resolve(GestureDisposition.accepted);
    tester.firstEntry.resolve(GestureDisposition.accepted);
    tester.expectSecondWin();
  });

  test('Win before close is delayed to close', () {
    final tester = GestureTester();
    tester.addFirst();
    tester.addSecond();
    tester.expectNothing();
    tester.firstEntry.resolve(GestureDisposition.accepted);
    tester.expectNothing();
    tester.arena.close(primaryKey);
    tester.expectFirstWin();
  });

  test('Win before close is delayed to close, and only first winner should win', () {
    final tester = GestureTester();
    tester.addFirst();
    tester.addSecond();
    tester.expectNothing();
    tester.firstEntry.resolve(GestureDisposition.accepted);
    tester.secondEntry.resolve(GestureDisposition.accepted);
    tester.expectNothing();
    tester.arena.close(primaryKey);
    tester.expectFirstWin();
  });

  test(
    'Win before close is delayed to close, and only first winner should win, regardless of order',
    () {
      final tester = GestureTester();
      tester.addFirst();
      tester.addSecond();
      tester.expectNothing();
      tester.secondEntry.resolve(GestureDisposition.accepted);
      tester.firstEntry.resolve(GestureDisposition.accepted);
      tester.expectNothing();
      tester.arena.close(primaryKey);
      tester.expectSecondWin();
    },
  );

  test('Eager winner should be cleared when the eager winner rejects while arena is still open', () {
    final GestureArenaManager arena = GestureArenaManager();
    final TestGestureArenaMember memberA = TestGestureArenaMember();
    final TestGestureArenaMember memberB = TestGestureArenaMember();
    final TestGestureArenaMember memberC = TestGestureArenaMember();

    final GestureArenaEntry entryA = arena.add(primaryKey, memberA);
    final GestureArenaEntry entryB = arena.add(primaryKey, memberB);
    final GestureArenaEntry entryC = arena.add(primaryKey, memberC);

    // A accepts while arena is open, becoming the eager winner.
    entryA.resolve(GestureDisposition.accepted);
    expect(memberA.acceptRan, isFalse); // Not yet resolved, arena still open.
    expect(memberA.rejectRan, isFalse);

    // A then gets rejected while arena is still open.
    // Without the fix: eagerWinner still points to A (stale reference).
    // With the fix: eagerWinner is cleared.
    entryA.resolve(GestureDisposition.rejected);
    expect(memberA.rejectRan, isTrue);
    expect(memberA.acceptRan, isFalse);

    // Close the arena. _tryToResolveArena sees members = [B, C].
    // Without the fix: eagerWinner (A) is non-null → _resolveInFavorOf(A)
    //   → A.acceptGesture() called again on an already-rejected member,
    //   → B and C incorrectly rejected. Assert fires in debug mode.
    // With the fix: eagerWinner is null, arena stays unresolved.
    arena.close(primaryKey);

    // Verify A was NOT incorrectly accepted again by a stale eager winner.
    expect(memberA.acceptRan, isFalse);
    // B and C should NOT have been prematurely rejected by stale eager winner.
    expect(memberB.rejectRan, isFalse);
    expect(memberC.rejectRan, isFalse);

    // Force resolution via sweep. B should win as the first remaining member.
    arena.sweep(primaryKey);
    expect(memberB.acceptRan, isTrue);
    expect(memberB.rejectRan, isFalse);
    expect(memberC.rejectRan, isTrue);
    expect(memberC.acceptRan, isFalse);
  });
}
