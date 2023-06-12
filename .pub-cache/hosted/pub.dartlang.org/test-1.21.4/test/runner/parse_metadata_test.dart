// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
import 'package:test/test.dart';
import 'package:test_api/src/backend/platform_selector.dart';
import 'package:test_api/src/backend/runtime.dart';
import 'package:test_api/src/backend/suite_platform.dart';
import 'package:test_core/src/runner/parse_metadata.dart';

final _path = 'test.dart';

void main() {
  test('returns empty metadata for an empty file', () {
    var metadata = parseMetadata(_path, '', {});
    expect(metadata.testOn, equals(PlatformSelector.all));
    expect(metadata.timeout.scaleFactor, equals(1));
  });

  test('ignores irrelevant annotations', () {
    var metadata =
        parseMetadata(_path, '@Fblthp\n@Fblthp.foo\nlibrary foo;', {});
    expect(metadata.testOn, equals(PlatformSelector.all));
  });

  test('parses a prefixed annotation', () {
    var metadata = parseMetadata(
        _path,
        "@foo.TestOn('vm')\n"
        "import 'package:test/test.dart' as foo;",
        {});
    expect(metadata.testOn.evaluate(SuitePlatform(Runtime.vm)), isTrue);
    expect(metadata.testOn.evaluate(SuitePlatform(Runtime.chrome)), isFalse);
  });

  group('@TestOn:', () {
    test('parses a valid annotation', () {
      var metadata = parseMetadata(_path, "@TestOn('vm')\nlibrary foo;", {});
      expect(metadata.testOn.evaluate(SuitePlatform(Runtime.vm)), isTrue);
      expect(metadata.testOn.evaluate(SuitePlatform(Runtime.chrome)), isFalse);
    });

    test('ignores a constructor named TestOn', () {
      var metadata =
          parseMetadata(_path, "@foo.TestOn('foo')\nlibrary foo;", {});
      expect(metadata.testOn, equals(PlatformSelector.all));
    });

    group('throws an error for', () {
      test('multiple @TestOns', () {
        expect(
            () => parseMetadata(
                _path, "@TestOn('foo')\n@TestOn('bar')\nlibrary foo;", {}),
            throwsFormatException);
      });
    });
  });

  group('@Timeout:', () {
    test('parses a valid duration annotation', () {
      var metadata = parseMetadata(_path, '''
@Timeout(const Duration(
    hours: 1,
    minutes: 2,
    seconds: 3,
    milliseconds: 4,
    microseconds: 5))

library foo;
''', {});
      expect(
          metadata.timeout.duration,
          equals(Duration(
              hours: 1,
              minutes: 2,
              seconds: 3,
              milliseconds: 4,
              microseconds: 5)));
    });

    test('parses a valid duration omitting const', () {
      var metadata = parseMetadata(_path, '''
@Timeout(Duration(
    hours: 1,
    minutes: 2,
    seconds: 3,
    milliseconds: 4,
    microseconds: 5))

library foo;
''', {});
      expect(
          metadata.timeout.duration,
          equals(Duration(
              hours: 1,
              minutes: 2,
              seconds: 3,
              milliseconds: 4,
              microseconds: 5)));
    });

    test('parses a valid duration with an import prefix', () {
      var metadata = parseMetadata(_path, '''
@Timeout(core.Duration(
    hours: 1,
    minutes: 2,
    seconds: 3,
    milliseconds: 4,
    microseconds: 5))
import 'dart:core' as core;
''', {});
      expect(
          metadata.timeout.duration,
          equals(Duration(
              hours: 1,
              minutes: 2,
              seconds: 3,
              milliseconds: 4,
              microseconds: 5)));
    });

    test('parses a valid int factor annotation', () {
      var metadata = parseMetadata(_path, '''
@Timeout.factor(1)

library foo;
''', {});
      expect(metadata.timeout.scaleFactor, equals(1));
    });

    test('parses a valid int factor annotation with an import prefix', () {
      var metadata = parseMetadata(_path, '''
@test.Timeout.factor(1)
import 'package:test/test.dart' as test;
''', {});
      expect(metadata.timeout.scaleFactor, equals(1));
    });

    test('parses a valid double factor annotation', () {
      var metadata = parseMetadata(_path, '''
@Timeout.factor(0.5)

library foo;
''', {});
      expect(metadata.timeout.scaleFactor, equals(0.5));
    });

    test('parses a valid Timeout.none annotation', () {
      var metadata = parseMetadata(_path, '''
@Timeout.none

library foo;
''', {});
      expect(metadata.timeout, same(Timeout.none));
    });

    test('ignores a constructor named Timeout', () {
      var metadata =
          parseMetadata(_path, "@foo.Timeout('foo')\nlibrary foo;", {});
      expect(metadata.timeout.scaleFactor, equals(1));
    });

    group('throws an error for', () {
      test('multiple @Timeouts', () {
        expect(
            () => parseMetadata(_path,
                '@Timeout.factor(1)\n@Timeout.factor(2)\nlibrary foo;', {}),
            throwsFormatException);
      });
    });
  });

  group('@Skip:', () {
    test('parses a valid annotation', () {
      var metadata = parseMetadata(_path, '@Skip()\nlibrary foo;', {});
      expect(metadata.skip, isTrue);
      expect(metadata.skipReason, isNull);
    });

    test('parses a valid annotation with a reason', () {
      var metadata = parseMetadata(_path, "@Skip('reason')\nlibrary foo;", {});
      expect(metadata.skip, isTrue);
      expect(metadata.skipReason, equals('reason'));
    });

    test('ignores a constructor named Skip', () {
      var metadata = parseMetadata(_path, "@foo.Skip('foo')\nlibrary foo;", {});
      expect(metadata.skip, isFalse);
    });

    group('throws an error for', () {
      test('multiple @Skips', () {
        expect(
            () => parseMetadata(
                _path, "@Skip('foo')\n@Skip('bar')\nlibrary foo;", {}),
            throwsFormatException);
      });
    });
  });

  group('@Tags:', () {
    test('parses a valid annotation', () {
      var metadata = parseMetadata(_path, "@Tags(['a'])\nlibrary foo;", {});
      expect(metadata.tags, equals(['a']));
    });

    test('ignores a constructor named Tags', () {
      var metadata = parseMetadata(_path, "@foo.Tags(['a'])\nlibrary foo;", {});
      expect(metadata.tags, isEmpty);
    });

    group('throws an error for', () {
      test('multiple @Tags', () {
        expect(
            () => parseMetadata(
                _path, "@Tags(['a'])\n@Tags(['b'])\nlibrary foo;", {}),
            throwsFormatException);
      });

      test('String interpolation', () {
        expect(
            () => parseMetadata(
                _path, "@Tags(['\$a'])\nlibrary foo;\nconst a = 'a';", {}),
            throwsFormatException);
      });
    });
  });

  group('@OnPlatform:', () {
    test('parses a valid annotation', () {
      var metadata = parseMetadata(_path, '''
@OnPlatform({
  'chrome': Timeout.factor(2),
  'vm': [Skip(), Timeout.factor(3)]
})
library foo;''', {});

      var key = metadata.onPlatform.keys.first;
      expect(key.evaluate(SuitePlatform(Runtime.chrome)), isTrue);
      expect(key.evaluate(SuitePlatform(Runtime.vm)), isFalse);
      var value = metadata.onPlatform.values.first;
      expect(value.timeout.scaleFactor, equals(2));

      key = metadata.onPlatform.keys.last;
      expect(key.evaluate(SuitePlatform(Runtime.vm)), isTrue);
      expect(key.evaluate(SuitePlatform(Runtime.chrome)), isFalse);
      value = metadata.onPlatform.values.last;
      expect(value.skip, isTrue);
      expect(value.timeout.scaleFactor, equals(3));
    });

    test('parses a valid annotation with an import prefix', () {
      var metadata = parseMetadata(_path, '''
@test.OnPlatform({
  'chrome': test.Timeout.factor(2),
  'vm': [test.Skip(), test.Timeout.factor(3)]
})
import 'package:test/test.dart' as test;
''', {});

      var key = metadata.onPlatform.keys.first;
      expect(key.evaluate(SuitePlatform(Runtime.chrome)), isTrue);
      expect(key.evaluate(SuitePlatform(Runtime.vm)), isFalse);
      var value = metadata.onPlatform.values.first;
      expect(value.timeout.scaleFactor, equals(2));

      key = metadata.onPlatform.keys.last;
      expect(key.evaluate(SuitePlatform(Runtime.vm)), isTrue);
      expect(key.evaluate(SuitePlatform(Runtime.chrome)), isFalse);
      value = metadata.onPlatform.values.last;
      expect(value.skip, isTrue);
      expect(value.timeout.scaleFactor, equals(3));
    });

    test('ignores a constructor named OnPlatform', () {
      var metadata =
          parseMetadata(_path, "@foo.OnPlatform('foo')\nlibrary foo;", {});
      expect(metadata.testOn, equals(PlatformSelector.all));
    });

    group('throws an error for', () {
      test('a map with a unparseable key', () {
        expect(
            () => parseMetadata(
                _path, "@OnPlatform({'invalid': Skip()})\nlibrary foo;", {}),
            throwsFormatException);
      });

      test('a map with an invalid value', () {
        expect(
            () => parseMetadata(_path,
                "@OnPlatform({'vm': const TestOn('vm')})\nlibrary foo;", {}),
            throwsFormatException);
      });

      test('a map with an invalid value in a list', () {
        expect(
            () => parseMetadata(_path,
                "@OnPlatform({'vm': [const TestOn('vm')]})\nlibrary foo;", {}),
            throwsFormatException);
      });

      test('multiple @OnPlatforms', () {
        expect(
            () => parseMetadata(
                _path, '@OnPlatform({})\n@OnPlatform({})\nlibrary foo;', {}),
            throwsFormatException);
      });
    });
  });
}
