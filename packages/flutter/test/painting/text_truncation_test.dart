// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

String _apply(String text, List<TextElision> elisions) {
  final buffer = StringBuffer();
  var start = 0;
  for (final elision in elisions) {
    buffer
      ..write(text.substring(start, elision.range.start))
      ..write(elision.replacement);
    start = elision.range.end;
  }
  buffer.write(text.substring(start));
  return buffer.toString();
}

List<String> _allLevels(TextTruncation truncation, String text) {
  return <String>[
    for (int level = 0; level <= truncation.maxLevel(text); level += 1)
      _apply(text, truncation.elide(text, level)),
  ];
}

void main() {
  group('TextOverflow', () {
    test('built-ins behave like the former enum values', () {
      expect(TextOverflow.values, const <TextOverflow>[
        TextOverflow.clip,
        TextOverflow.fade,
        TextOverflow.ellipsis,
        TextOverflow.visible,
      ]);
      for (var i = 0; i < TextOverflow.values.length; i += 1) {
        expect(TextOverflow.values[i].index, i);
        expect(TextOverflow.values[i].truncation, isNull);
      }
      expect(TextOverflow.values.map((TextOverflow o) => o.name), <String>[
        'clip',
        'fade',
        'ellipsis',
        'visible',
      ]);
      expect(TextOverflow.clip.toString(), 'TextOverflow.clip');
      expect(TextOverflow.fade.toString(), 'TextOverflow.fade');
      expect(TextOverflow.ellipsis.toString(), 'TextOverflow.ellipsis');
      expect(TextOverflow.visible.toString(), 'TextOverflow.visible');
      expect(identical(TextOverflow.clip, TextOverflow.clip), isTrue);
      expect(TextOverflow.clip, isNot(TextOverflow.ellipsis));
    });

    test('truncate', () {
      const overflow = TextOverflow.truncate(TextTruncation.middle());
      expect(overflow.name, 'truncate');
      expect(overflow.index, 4);
      expect(overflow.truncation, const TextTruncation.middle());
      expect(overflow.toString(), 'TextOverflow.truncate(TextTruncation.middle())');
      expect(TextOverflow.values, isNot(contains(overflow)));
    });

    test('truncate equality and hashCode', () {
      // ignore: prefer_const_constructors, testing non-const equality.
      final nonConst = TextOverflow.truncate(TextTruncation.end());
      const constant = TextOverflow.truncate(TextTruncation.end());
      expect(nonConst, constant);
      expect(nonConst.hashCode, constant.hashCode);
      expect(constant, isNot(const TextOverflow.truncate(TextTruncation.start())));
      expect(constant, isNot(const TextOverflow.truncate(TextTruncation.end(ellipsis: '...'))));
      expect(constant, isNot(TextOverflow.clip));
    });

    test('can be matched with constant and object patterns', () {
      String describe(TextOverflow overflow) {
        return switch (overflow) {
          TextOverflow.clip => 'clip',
          TextOverflow.fade => 'fade',
          TextOverflow.ellipsis => 'ellipsis',
          TextOverflow.visible => 'visible',
          TextOverflow(truncation: final TextTruncation truncation?) => 'truncate $truncation',
          _ => 'unknown',
        };
      }

      expect(describe(TextOverflow.clip), 'clip');
      expect(describe(TextOverflow.fade), 'fade');
      expect(describe(TextOverflow.ellipsis), 'ellipsis');
      expect(describe(TextOverflow.visible), 'visible');
      expect(
        describe(const TextOverflow.truncate(TextTruncation.start())),
        'truncate TextTruncation.start()',
      );
    });
  });

  group('TextElision', () {
    test('defaults to an ellipsis', () {
      const elision = TextElision(TextRange(start: 1, end: 3));
      expect(elision.replacement, '\u2026');
    });

    test('equality, hashCode, and toString', () {
      const a = TextElision(TextRange(start: 1, end: 3));
      // ignore: prefer_const_constructors, testing non-const equality.
      final b = TextElision(const TextRange(start: 1, end: 3));
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(const TextElision(TextRange(start: 1, end: 4))));
      expect(a, isNot(const TextElision(TextRange(start: 1, end: 3), '...')));
      expect(a.toString(), 'TextElision(TextRange(start: 1, end: 3), "\u2026")');
    });
  });

  group('TextTruncation built-ins', () {
    test('end', () {
      const truncation = TextTruncation.end();
      expect(truncation.maxLevel('abcde'), 5);
      expect(truncation.elide('abcde', 0), isEmpty);
      expect(truncation.elide('abcde', 2), const <TextElision>[
        TextElision(TextRange(start: 3, end: 5)),
      ]);
      expect(_allLevels(truncation, 'abcde'), <String>['abcde', 'abcd…', 'abc…', 'ab…', 'a…', '…']);
    });

    test('start', () {
      const truncation = TextTruncation.start();
      expect(truncation.maxLevel('abcde'), 5);
      expect(truncation.elide('abcde', 0), isEmpty);
      expect(truncation.elide('abcde', 2), const <TextElision>[
        TextElision(TextRange(start: 0, end: 2)),
      ]);
      expect(_allLevels(truncation, 'abcde'), <String>['abcde', '…bcde', '…cde', '…de', '…e', '…']);
    });

    test('middle', () {
      const truncation = TextTruncation.middle();
      expect(truncation.maxLevel('abcdef'), 6);
      expect(truncation.elide('abcdef', 0), isEmpty);
      expect(_allLevels(truncation, 'abcdef'), <String>[
        'abcdef',
        'abc…ef',
        'ab…ef',
        'ab…f',
        'a…f',
        'a…',
        '…',
      ]);
    });

    test('custom ellipsis', () {
      const truncation = TextTruncation.end(ellipsis: '...');
      expect(_apply('abcde', truncation.elide('abcde', 2)), 'abc...');
      expect(truncation.toString(), 'TextTruncation.end(ellipsis: "...")');
    });

    test('levels count grapheme clusters', () {
      // A ZWJ family emoji, a flag, and a letter with a combining accent. Each
      // is a single grapheme cluster made of multiple UTF-16 code units.
      const family = '\u{1F468}\u200D\u{1F469}\u200D\u{1F467}';
      const flag = '\u{1F1FA}\u{1F1F8}';
      const accented = 'e\u0301';
      const text = 'a$family$flag${accented}b';
      for (final truncation in const <TextTruncation>[
        TextTruncation.end(),
        TextTruncation.start(),
        TextTruncation.middle(),
      ]) {
        expect(truncation.maxLevel(text), 5, reason: '$truncation');
      }
      expect(_allLevels(const TextTruncation.end(), text), <String>[
        text,
        'a$family$flag$accented…',
        'a$family$flag…',
        'a$family…',
        'a…',
        '…',
      ]);
      expect(_allLevels(const TextTruncation.start(), text), <String>[
        text,
        '…$family$flag${accented}b',
        '…$flag${accented}b',
        '…${accented}b',
        '…b',
        '…',
      ]);
      expect(_allLevels(const TextTruncation.middle(), text), <String>[
        text,
        'a$family…${accented}b',
        'a$family…b',
        'a…b',
        'a…',
        '…',
      ]);
    });

    test('empty text', () {
      for (final truncation in const <TextTruncation>[
        TextTruncation.end(),
        TextTruncation.start(),
        TextTruncation.middle(),
      ]) {
        expect(truncation.maxLevel(''), 0);
        expect(truncation.elide('', 0), isEmpty);
      }
    });

    test('levels above maxLevel are clamped', () {
      expect(const TextTruncation.end().elide('abc', 10), const <TextElision>[
        TextElision(TextRange(start: 0, end: 3)),
      ]);
    });

    test('equality, hashCode, and toString', () {
      // ignore: prefer_const_constructors, testing non-const equality.
      final nonConst = TextTruncation.middle();
      expect(nonConst, const TextTruncation.middle());
      expect(nonConst.hashCode, const TextTruncation.middle().hashCode);
      expect(const TextTruncation.middle(), isNot(const TextTruncation.end()));
      expect(const TextTruncation.end(), isNot(const TextTruncation.start()));
      expect(const TextTruncation.end(), isNot(const TextTruncation.end(ellipsis: '...')));
      expect(const TextTruncation.end().toString(), 'TextTruncation.end()');
      expect(const TextTruncation.start().toString(), 'TextTruncation.start()');
      expect(const TextTruncation.middle().toString(), 'TextTruncation.middle()');
    });
  });
}
