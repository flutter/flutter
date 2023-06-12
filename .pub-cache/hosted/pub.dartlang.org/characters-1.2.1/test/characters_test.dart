// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:math";

import "package:characters/characters.dart";
import "package:test/test.dart";

import "src/unicode_tests.dart";
import "src/various_tests.dart";

late Random random;

void main([List<String>? args]) {
  // Ensure random seed is part of every test failure message,
  // and that it can be reapplied for testing.
  var seed = (args != null && args.isNotEmpty)
      ? int.parse(args[0])
      : Random().nextInt(0x3FFFFFFF);
  random = Random(seed);
  group("[Random Seed: $seed]", tests);
  group("characters", () {
    test("operations", () {
      var flag = "\u{1F1E9}\u{1F1F0}"; // Regional Indicators "DK".
      var string = "Hi $flag!";
      expect(string.length, 8);
      var cs = gc(string);
      expect(cs.length, 5);
      expect(cs.toList(), ["H", "i", " ", flag, "!"]);
      expect(cs.skip(2).toString(), " $flag!");
      expect(cs.skipLast(2).toString(), "Hi ");
      expect(cs.take(2).toString(), "Hi");
      expect(cs.takeLast(2).toString(), "$flag!");
      expect(cs.getRange(1, 4).toString(), "i $flag");
      expect(cs.characterAt(1).toString(), "i");
      expect(cs.characterAt(3).toString(), flag);

      expect(cs.contains("\u{1F1E9}"), false);
      expect(cs.contains(flag), true);
      expect(cs.contains("$flag!"), false);
      expect(cs.containsAll(gc("$flag!")), true);

      expect(cs.takeWhile((x) => x != " ").toString(), "Hi");
      expect(cs.takeLastWhile((x) => x != " ").toString(), "$flag!");
      expect(cs.skipWhile((x) => x != " ").toString(), " $flag!");
      expect(cs.skipLastWhile((x) => x != " ").toString(), "Hi ");

      expect(cs.findFirst(gc(""))!.moveBack(), false);
      expect(cs.findFirst(gc(flag))!.current, flag);
      expect(cs.findLast(gc(flag))!.current, flag);
      expect(cs.iterator.moveNext(), true);
      expect(cs.iterator.moveBack(), false);
      expect((cs.iterator..moveNext()).current, "H");
      expect(cs.iteratorAtEnd.moveNext(), false);
      expect(cs.iteratorAtEnd.moveBack(), true);
      expect((cs.iteratorAtEnd..moveBack()).current, "!");
    });

    testParts(gc("a"), gc("b"), gc("c"), gc("d"), gc("e"));

    // Composite pictogram example, from https://en.wikipedia.org/wiki/Zero-width_joiner.
    var flag = "\u{1f3f3}"; // U+1F3F3, Flag, waving. Category Pictogram.
    var white = "\ufe0f"; // U+FE0F, Variant selector 16. Category Extend.
    var zwj = "\u200d"; // U+200D, ZWJ
    var rainbow = "\u{1f308}"; // U+1F308, Rainbow. Category Pictogram

    testParts(gc("$flag$white$zwj$rainbow"), gc("$flag$white"), gc(rainbow),
        gc("$flag$zwj$rainbow"), gc("!"));
  });

  group("CharacterRange", () {
    test("new", () {
      var range = CharacterRange("abc");
      expect(range.isEmpty, true);
      expect(range.moveNext(), true);
      expect(range.current, "a");
    });
    group("new.at", () {
      test("simple", () {
        var range = CharacterRange.at("abc", 0);
        expect(range.isEmpty, true);
        expect(range.moveNext(), true);
        expect(range.current, "a");

        range = CharacterRange.at("abc", 1);
        expect(range.isEmpty, true);
        expect(range.moveNext(), true);
        expect(range.current, "b");

        range = CharacterRange.at("abc", 1, 2);
        expect(range.isEmpty, false);
        expect(range.current, "b");
        expect(range.moveNext(), true);

        range = CharacterRange.at("abc", 0, 3);
        expect(range.isEmpty, false);
        expect(range.current, "abc");
        expect(range.moveNext(), false);
      });
      test("complicated", () {
        // Composite pictogram example, from https://en.wikipedia.org/wiki/Zero-width_joiner.
        var flag = "\u{1f3f3}"; // U+1F3F3, Flag, waving. Category Pictogram.
        var white = "\ufe0f"; // U+FE0F, Variant selector 16. Category Extend.
        var zwj = "\u200d"; // U+200D, ZWJ
        var rainbow = "\u{1f308}"; // U+1F308, Rainbow. Category Pictogram

        var rbflag = "$flag$white$zwj$rainbow";
        var string = "-$rbflag-";
        var range = CharacterRange.at(string, 1);
        expect(range.isEmpty, true);
        expect(range.moveNext(), true);
        expect(range.current, rbflag);

        range = range = CharacterRange.at(string, 2);
        expect(range.isEmpty, false);
        expect(range.current, rbflag);

        range = range = CharacterRange.at(string, 0, 2);
        expect(range.isEmpty, false);
        expect(range.current, "-$rbflag");

        range = range = CharacterRange.at(string, 0, 2);
        expect(range.isEmpty, false);
        expect(range.current, "-$rbflag");

        range = range = CharacterRange.at(string, 2, "-$rbflag".length - 1);
        expect(range.isEmpty, false);
        expect(range.current, rbflag);
        expect(range.stringBeforeLength, 1);

        range = range = CharacterRange.at(string, 0, string.length);
        expect(range.isEmpty, false);
        expect(range.current, string);
      });
    });
  });
}

void tests() {
  test("empty", () {
    expectGC(gc(""), []);
  });
  group("gc-ASCII", () {
    for (var text in [
      "",
      "A",
      "123456abcdefab",
    ]) {
      test('"$text"', () {
        expectGC(gc(text), charsOf(text));
      });
    }
    test("CR+NL", () {
      expectGC(gc("a\r\nb"), ["a", "\r\n", "b"]);
      expectGC(gc("a\n\rb"), ["a", "\n", "\r", "b"]);
    });
  });
  group("Non-ASCII single-code point", () {
    for (var text in [
      "à la mode",
      "rødgrød-æble-ål",
    ]) {
      test('"$text"', () {
        expectGC(gc(text), charsOf(text));
      });
    }
  });
  group("Combining marks", () {
    var text = "a\u0300 la mode";
    test('"$text"', () {
      expectGC(gc(text), ["a\u0300", " ", "l", "a", " ", "m", "o", "d", "e"]);
    });
    var text2 = "æble-a\u030Al";
    test('"$text2"', () {
      expectGC(gc(text2), ["æ", "b", "l", "e", "-", "a\u030A", "l"]);
    });
  });

  group("Regional Indicators", () {
    test('"🇦🇩🇰🇾🇪🇸"', () {
      // Andorra, Cayman Islands, Spain.
      expectGC(gc("🇦🇩🇰🇾🇪🇸"), ["🇦🇩", "🇰🇾", "🇪🇸"]);
    });
    test('"X🇦🇩🇰🇾🇪🇸"', () {
      // Other, Andorra, Cayman Islands, Spain.
      expectGC(gc("X🇦🇩🇰🇾🇪🇸"), ["X", "🇦🇩", "🇰🇾", "🇪🇸"]);
    });
    test('"🇩🇰🇾🇪🇸"', () {
      // Denmark, Yemen, unmatched S.
      expectGC(gc("🇩🇰🇾🇪🇸"), ["🇩🇰", "🇾🇪", "🇸"]);
    });
    test('"X🇩🇰🇾🇪🇸"', () {
      // Other, Denmark, Yemen, unmatched S.
      expectGC(gc("X🇩🇰🇾🇪🇸"), ["X", "🇩🇰", "🇾🇪", "🇸"]);
    });
  });

  group("Hangul", () {
    // Individual characters found on Wikipedia. Not expected to make sense.
    test('"읍쌍된밟"', () {
      expectGC(gc("읍쌍된밟"), ["읍", "쌍", "된", "밟"]);
    });
  });

  group("Unicode test", () {
    for (var gcs in splitTests) {
      test("[${testDescription(gcs)}]", () {
        expectGC(gc(gcs.join()), gcs);
      });
    }
  });

  group("Emoji test", () {
    for (var gcs in emojis) {
      test("[${testDescription(gcs)}]", () {
        expectGC(gc(gcs.join()), gcs);
      });
    }
  });

  group("Zalgo test", () {
    for (var gcs in zalgo) {
      test("[${testDescription(gcs)}]", () {
        expectGC(gc(gcs.join()), gcs);
      });
    }
  });
}

// Converts text with no multi-code-point grapheme clusters into
// list of grapheme clusters.
List<String> charsOf(String text) =>
    text.runes.map((r) => String.fromCharCode(r)).toList();

void expectGC(Characters actual, List<String> expected) {
  var text = expected.join();

  // Iterable operations.
  expect(actual.string, text);
  expect(actual.toString(), text);
  expect(actual.toList(), expected);
  expect(actual.length, expected.length);
  if (expected.isNotEmpty) {
    expect(actual.first, expected.first);
    expect(actual.last, expected.last);
  } else {
    expect(() => actual.first, throwsStateError);
    expect(() => actual.last, throwsStateError);
  }
  if (expected.length == 1) {
    expect(actual.single, expected.single);
  } else {
    expect(() => actual.single, throwsStateError);
  }
  expect(actual.isEmpty, expected.isEmpty);
  expect(actual.isNotEmpty, expected.isNotEmpty);
  expect(actual.contains(""), false);
  for (var char in expected) {
    expect(actual.contains(char), true);
  }
  for (var i = 1; i < expected.length; i++) {
    expect(actual.contains(expected[i - 1] + expected[i]), false);
  }
  expect(actual.skip(1).toList(), expected.skip(1).toList());
  expect(actual.take(1).toList(), expected.take(1).toList());
  expect(actual.skip(1).toString(), expected.skip(1).join());
  expect(actual.take(1).toString(), expected.take(1).join());
  expect(actual.getRange(1, 2).toString(), expected.take(2).skip(1).join());

  if (expected.isNotEmpty) {
    expect(actual.skipLast(1).toList(),
        expected.take(expected.length - 1).toList());
    expect(actual.takeLast(1).toList(),
        expected.skip(expected.length - 1).toList());
    expect(actual.skipLast(1).toString(),
        expected.take(expected.length - 1).join());
    expect(actual.takeLast(1).toString(),
        expected.skip(expected.length - 1).join());
  }
  bool isEven(String s) => s.length.isEven;

  expect(
      actual.skipWhile(isEven).toList(), expected.skipWhile(isEven).toList());
  expect(
      actual.takeWhile(isEven).toList(), expected.takeWhile(isEven).toList());
  expect(
      actual.skipWhile(isEven).toString(), expected.skipWhile(isEven).join());
  expect(
      actual.takeWhile(isEven).toString(), expected.takeWhile(isEven).join());

  expect(actual.skipLastWhile(isEven).toString(),
      expected.toList().reversed.skipWhile(isEven).toList().reversed.join());
  expect(actual.takeLastWhile(isEven).toString(),
      expected.toList().reversed.takeWhile(isEven).toList().reversed.join());

  expect(actual.where(isEven).toString(), expected.where(isEven).join());

  expect((actual + actual).toString(), actual.string + actual.string);

  // Iteration.
  var it = actual.iterator;
  expect(it.isEmpty, true);
  for (var i = 0; i < expected.length; i++) {
    expect(it.moveNext(), true);
    expect(it.current, expected[i]);

    expect(actual.elementAt(i), expected[i]);
    expect(actual.skip(i).first, expected[i]);
    expect(actual.characterAt(i).toString(), expected[i]);
    expect(actual.getRange(i, i + 1).toString(), expected[i]);
  }
  expect(it.moveNext(), false);
  for (var i = expected.length - 1; i >= 0; i--) {
    expect(it.moveBack(), true);
    expect(it.current, expected[i]);
  }
  expect(it.moveBack(), false);
  expect(it.isEmpty, true);

  // GraphemeClusters operations.
  expect(actual.toUpperCase().string, text.toUpperCase());
  expect(actual.toLowerCase().string, text.toLowerCase());

  expect(actual.string, text);

  expect(actual.containsAll(gc("")), true);
  expect(actual.containsAll(actual), true);
  if (expected.isNotEmpty) {
    var steps = min(5, expected.length);
    for (var s = 0; s <= steps; s++) {
      var i = expected.length * s ~/ steps;
      expect(actual.startsWith(gc(expected.sublist(0, i).join())), true);
      expect(actual.endsWith(gc(expected.sublist(i).join())), true);
      for (var t = s + 1; t <= steps; t++) {
        var j = expected.length * t ~/ steps;
        var slice = expected.sublist(i, j).join();
        var gcs = gc(slice);
        expect(actual.containsAll(gcs), true);
      }
    }
  }

  {
    // Random walk back and forth.
    var it = actual.iterator;
    var pos = -1;
    if (random.nextBool()) {
      pos = expected.length;
      it = actual.iteratorAtEnd;
    }
    var steps = 5 + random.nextInt(expected.length * 2 + 1);
    var lastMove = false;
    while (true) {
      var back = false;
      if (pos < 0) {
        expect(lastMove, false);
        expect(it.isEmpty, true);
      } else if (pos >= expected.length) {
        expect(lastMove, false);
        expect(it.isEmpty, true);
        back = true;
      } else {
        expect(lastMove, true);
        expect(it.current, expected[pos]);
        back = random.nextBool();
      }
      if (--steps < 0) break;
      if (back) {
        lastMove = it.moveBack();
        pos -= 1;
      } else {
        lastMove = it.moveNext();
        pos += 1;
      }
    }
  }
}

Characters gc(String string) => Characters(string);

void testParts(
    Characters a, Characters b, Characters c, Characters d, Characters e) {
  var cs = gc("$a$b$c$d$e");
  test("$cs", () {
    var it = cs.iterator;
    expect(it.isEmpty, true);
    expect(it.isNotEmpty, false);
    expect(it.current, "");

    // moveNext().
    expect(it.moveNext(), true);
    expect(it.isEmpty, false);
    expect(it.current, "$a");
    expect(it.moveNext(), true);
    expect(it.isEmpty, false);
    expect(it.current, "$b");
    expect(it.moveNext(), true);
    expect(it.isEmpty, false);
    expect(it.current, "$c");
    expect(it.moveNext(), true);
    expect(it.isEmpty, false);
    expect(it.current, "$d");
    expect(it.moveNext(), true);
    expect(it.isEmpty, false);
    expect(it.current, "$e");
    expect(it.moveNext(), false);
    expect(it.isEmpty, true);
    expect(it.current, "");

    // moveBack().
    expect(it.moveBack(), true);
    expect(it.isEmpty, false);
    expect(it.current, "$e");
    expect(it.moveBack(), true);
    expect(it.isEmpty, false);
    expect(it.current, "$d");
    expect(it.moveBack(), true);
    expect(it.isEmpty, false);
    expect(it.current, "$c");
    expect(it.moveBack(), true);
    expect(it.isEmpty, false);
    expect(it.current, "$b");
    expect(it.moveBack(), true);
    expect(it.isEmpty, false);
    expect(it.current, "$a");
    expect(it.moveBack(), false);
    expect(it.isEmpty, true);
    expect(it.current, "");

    // moveNext(int).
    expect(it.moveTo(c), true);
    expect(it.current, "$c");
    expect(it.moveTo(b), false);
    expect(it.moveTo(c), false);
    expect(it.current, "$c");
    expect(it.moveTo(d), true);
    expect(it.current, "$d");

    // moveBack(c).
    expect(it.moveBackTo(c), true);
    expect(it.current, "$c");
    expect(it.moveBackTo(d), false);
    expect(it.moveBackTo(c), false);
    expect(it.moveBackTo(a), true);
    expect(it.current, "$a");

    // moveNext(n)
    expect(it.moveBack(), false);

    expect(it.moveNext(2), true);
    expect(it.current, "$a$b");
    expect(it.moveNext(4), false);
    expect(it.current, "$c$d$e");
    expect(it.moveNext(0), true);
    expect(it.current, "");
    expect(it.moveNext(1), false);
    expect(it.current, "");

    // moveBack(n).
    expect(it.moveBack(2), true);
    expect(it.current, "$d$e");
    expect(it.moveBack(1), true);
    expect(it.current, "$c");
    expect(it.moveBack(3), false);
    expect(it.current, "$a$b");
    expect(it.moveBack(), false);

    // moveFirst.
    it.expandAll();
    expect(it.current, "$a$b$c$d$e");
    expect(it.collapseToFirst(b), true);
    expect(it.current, "$b");
    it.expandAll();
    expect(it.current, "$b$c$d$e");
    expect(it.collapseToFirst(a), false);
    expect(it.current, "$b$c$d$e");

    // moveBackTo
    it.expandBackAll();
    expect(it.current, "$a$b$c$d$e");
    expect(it.collapseToLast(c), true);
    expect(it.current, "$c");

    // includeNext/includePrevious
    expect(it.expandTo(e), true);
    expect(it.current, "$c$d$e");
    expect(it.expandTo(e), false);
    expect(it.expandBackTo(b), true);
    expect(it.current, "$b$c$d$e");
    expect(it.expandBackTo(b), false);
    expect(it.current, "$b$c$d$e");
    expect(it.collapseToFirst(c), true);
    expect(it.current, "$c");

    // includeUntilNext/expandBackUntil
    expect(it.expandBackUntil(a), true);
    expect(it.current, "$b$c");
    expect(it.expandBackUntil(a), true);
    expect(it.current, "$b$c");
    expect(it.expandUntil(e), true);
    expect(it.current, "$b$c$d");
    expect(it.expandUntil(e), true);
    expect(it.current, "$b$c$d");

    // dropFirst/dropLast
    expect(it.dropFirst(), true);
    expect(it.current, "$c$d");
    expect(it.dropLast(), true);
    expect(it.current, "$c");
    it.expandBackAll();
    it.expandAll();
    expect(it.current, "$a$b$c$d$e");
    expect(it.dropTo(b), true);
    expect(it.current, "$c$d$e");
    expect(it.dropBackTo(d), true);
    expect(it.current, "$c");

    it.expandBackAll();
    it.expandAll();
    expect(it.current, "$a$b$c$d$e");

    expect(it.dropUntil(b), true);
    expect(it.current, "$b$c$d$e");
    expect(it.dropBackUntil(d), true);
    expect(it.current, "$b$c$d");

    it.dropWhile((x) => x == b.string);
    expect(it.current, "$c$d");
    it.expandBackAll();
    expect(it.current, "$a$b$c$d");
    it.dropBackWhile((x) => x != b.string);
    expect(it.current, "$a$b");
    it.dropBackWhile((x) => false);
    expect(it.current, "$a$b");

    // include..While
    it.expandWhile((x) => false);
    expect(it.current, "$a$b");
    it.expandWhile((x) => x != e.string);
    expect(it.current, "$a$b$c$d");
    expect(it.collapseToFirst(c), true);
    expect(it.current, "$c");
    it.expandBackWhile((x) => false);
    expect(it.current, "$c");
    it.expandBackWhile((x) => x != a.string);
    expect(it.current, "$b$c");

    var cs2 = cs.replaceAll(c, gc(""));
    var cs3 = cs.replaceFirst(c, gc(""));
    var cs4 = cs.findFirst(c)!.replaceRange(gc("")).source;
    var cse = gc("$a$b$d$e");
    expect(cs2, cse);
    expect(cs3, cse);
    expect(cs4, cse);
    var cs5 = cs4.replaceAll(a, c);
    expect(cs5, gc("$c$b$d$e"));
    var cs6 = cs5.replaceAll(gc(""), a);
    expect(cs6, gc("$a$c$a$b$a$d$a$e$a"));
    var cs7 = cs6.replaceFirst(b, a);
    expect(cs7, gc("$a$c$a$a$a$d$a$e$a"));
    var cs8 = cs7.replaceFirst(e, a);
    expect(cs8, gc("$a$c$a$a$a$d$a$a$a"));
    var cs9 = cs8.replaceAll(a + a, b);
    expect(cs9, gc("$a$c$b$a$d$b$a"));
    it = cs9.iterator;
    it.moveTo(b + a);
    expect("$b$a", it.current);
    it.expandTo(b + a);
    expect("$b$a$d$b$a", it.current);
    var cs10 = it.replaceAll(b + a, e + e)!;
    expect(cs10.currentCharacters, e + e + d + e + e);
    expect(cs10.source, gc("$a$c$e$e$d$e$e"));
    var cs11 = it.replaceRange(e);
    expect(cs11.currentCharacters, e);
    expect(cs11.source, gc("$a$c$e"));

    var cs12 = gc("$a$b$a");
    expect(cs12.split(b), [a, a]);
    expect(cs12.split(a), [gc(""), b, gc("")]);
    expect(cs12.split(a, 2), [gc(""), gc("$b$a")]);

    expect(cs12.split(gc("")), [a, b, a]);
    expect(cs12.split(gc(""), 2), [a, gc("$b$a")]);

    expect(gc("").split(gc("")), [gc("")]);

    var cs13 = gc("$b$a$b$a$b$a");
    expect(cs13.split(b), [gc(""), a, a, a]);
    expect(cs13.split(b, 1), [cs13]);
    expect(cs13.split(b, 2), [gc(""), gc("$a$b$a$b$a")]);
    expect(cs13.split(b, 3), [gc(""), a, gc("$a$b$a")]);
    expect(cs13.split(b, 4), [gc(""), a, a, a]);
    expect(cs13.split(b, 5), [gc(""), a, a, a]);
    expect(cs13.split(b, 9999), [gc(""), a, a, a]);
    expect(cs13.split(b, 0), [gc(""), a, a, a]);
    expect(cs13.split(b, -1), [gc(""), a, a, a]);
    expect(cs13.split(b, -9999), [gc(""), a, a, a]);

    it = cs13.iterator..expandAll();
    expect(it.current, "$b$a$b$a$b$a");
    it.dropFirst();
    it.dropLast();
    expect(it.current, "$a$b$a$b");
    expect(it.split(a).map((range) => range.current), ["", "$b", "$b"]);
    expect(it.split(a, 2).map((range) => range.current), ["", "$b$a$b"]);
    // Each split is after an *a*.
    var first = true;
    for (var range in it.split(a)) {
      if (range.isEmpty) {
        // First range is empty.
        expect(first, true);
        first = false;
        continue;
      }
      // Later ranges are "b" that come after "a".
      expect(range.current, "$b");
      range.moveBack();
      expect(range.current, "$a");
    }

    expect(it.split(gc("")).map((range) => range.current),
        ["$a", "$b", "$a", "$b"]);

    expect(gc("").iterator.split(gc("")).map((range) => range.current), [""]);

    expect(cs.startsWith(gc("")), true);
    expect(cs.startsWith(a), true);
    expect(cs.startsWith(a + b), true);
    expect(cs.startsWith(gc("$a$b$c")), true);
    expect(cs.startsWith(gc("$a$b$c$d")), true);
    expect(cs.startsWith(gc("$a$b$c$d$e")), true);
    expect(cs.startsWith(b), false);
    expect(cs.startsWith(c), false);
    expect(cs.startsWith(d), false);
    expect(cs.startsWith(e), false);

    expect(cs.endsWith(gc("")), true);
    expect(cs.endsWith(e), true);
    expect(cs.endsWith(d + e), true);
    expect(cs.endsWith(gc("$c$d$e")), true);
    expect(cs.endsWith(gc("$b$c$d$e")), true);
    expect(cs.endsWith(gc("$a$b$c$d$e")), true);
    expect(cs.endsWith(d), false);
    expect(cs.endsWith(c), false);
    expect(cs.endsWith(b), false);
    expect(cs.endsWith(a), false);

    it = cs.findFirst(b + c)!;
    expect(it.startsWith(gc("")), true);
    expect(it.startsWith(b), true);
    expect(it.startsWith(b + c), true);
    expect(it.startsWith(a + b + c), false);
    expect(it.startsWith(b + c + d), false);
    expect(it.startsWith(a), false);

    expect(it.endsWith(gc("")), true);
    expect(it.endsWith(c), true);
    expect(it.endsWith(b + c), true);
    expect(it.endsWith(a + b + c), false);
    expect(it.endsWith(b + c + d), false);
    expect(it.endsWith(d), false);

    it.collapseToFirst(c);
    expect(it.isPrecededBy(gc("")), true);
    expect(it.isPrecededBy(b), true);
    expect(it.isPrecededBy(a + b), true);
    expect(it.isPrecededBy(a + b + c), false);
    expect(it.isPrecededBy(a), false);

    expect(it.isFollowedBy(gc("")), true);
    expect(it.isFollowedBy(d), true);
    expect(it.isFollowedBy(d + e), true);
    expect(it.isFollowedBy(c + d + e), false);
    expect(it.isFollowedBy(e), false);
  });
  test("replace methods", () {
    // Unicode grapheme breaking character classes,
    // represented by their first value.

    var pattern = gc("\t"); // A non-combining entry to be replaced.
    var non = gc("");

    var c = otr + cr + pattern + lf + pic + pattern + zwj + pic + otr;
    var r = c.replaceAll(pattern, non);
    expect(r, otr + cr + lf + pic + zwj + pic + otr);
    var ci = c.iterator..moveNextAll();
    var ri = ci.replaceAll(pattern, non)!;
    expect(ri.currentCharacters, otr + cr + lf + pic + zwj + pic + otr);
    ci.dropFirst();
    ci.dropLast();
    expect(ci.currentCharacters, cr + pattern + lf + pic + pattern + zwj + pic);
    expect(ci.currentCharacters.length, 7);
    ri = ci.replaceAll(pattern, non)!;
    expect(ri.currentCharacters, cr + lf + pic + zwj + pic);
    expect(ri.currentCharacters.length, 2);
    ci.dropFirst();
    ci.dropLast(5);
    expect(ci.currentCharacters, pattern);
    ri = ci.replaceAll(pattern, non)!;
    expect(ri.currentCharacters, cr + lf);
    ci.moveNext(2);
    ci.moveNext(1);
    expect(ci.currentCharacters, pattern);
    ri = ci.replaceAll(pattern, non)!;
    expect(ri.currentCharacters, pic + zwj + pic);

    c = otr + pic + ext + pattern + pic + ext + otr;
    expect(c.length, 5);
    ci = c.iterator..moveTo(pattern);
    expect(ci.currentCharacters, pattern);
    ri = ci.replaceAll(pattern, zwj)!;
    expect(ri.currentCharacters, pic + ext + zwj + pic + ext);

    c = reg + pattern + reg + reg;
    ci = c.iterator..moveTo(pattern);
    ri = ci.replaceRange(non);
    expect(ri.currentCharacters, reg + reg);
    expect(ri.moveNext(), true);
    expect(ri.currentCharacters, reg);
  });
}

/// Sample characters from each breaking algorithm category.
final Characters ctl = gc("\x00"); // Control, NUL.
final Characters cr = gc("\r"); // Carriage Return, CR.
final Characters lf = gc("\n"); // Newline, NL.
final Characters otr = gc(" "); // Other, Space.
final Characters ext = gc("\u0300"); // Extend, Combining Grave Accent.
final Characters spc = gc("\u0903"); // Spacing Mark, Devanagari Sign Visarga.
final Characters pre = gc("\u0600"); // Prepend, Arabic Number Sign.
final Characters zwj = gc("\u200d"); // Zero-Width Joiner.
final Characters pic = gc("\u00a9"); // Extended Pictographic, Copyright.
final Characters reg = gc("\u{1f1e6}"); // Regional Identifier "a".
final Characters hanl = gc("\u1100"); // Hangul L, Choseong Kiyeok.
final Characters hanv = gc("\u1160"); // Hangul V, Jungseong Filler.
final Characters hant = gc("\u11a8"); // Hangul T, Jongseong Kiyeok.
final Characters hanlv = gc("\uac00"); // Hangul LV, Syllable Ga.
final Characters hanlvt = gc("\uac01"); // Hangul LVT, Syllable Gag.
