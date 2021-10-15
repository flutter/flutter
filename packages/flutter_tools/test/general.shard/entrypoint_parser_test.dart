// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/entrypoint_parser.dart';

import '../src/common.dart';

void main() {

  testWithoutContext('Parses top level arrow functions annotated with vm:entry-point (single quotes)', () {
    const String mainDartContent = '''
@pragma('vm:entry-point')
void main() => run(interactive: true);

@pragma('vm:entry-point')
void dream() => run(interactive: false);
''';

    final Map<String, String> entrypoints = getDartEntrypoints(mainDartContent);
    expect(entrypoints.isEmpty, isFalse);
    expect(entrypoints,
      equals(
        <String, String>{
          'main': "('vm:entry-point')",
          'dream': "('vm:entry-point')",
        },
      ),
    );
  });

  testWithoutContext('Parses top level arrow functions annotated with vm:entry-point (double quotes)', () {
    const String mainDartContent = '''
@pragma("vm:entry-point")
void main() => run(interactive: true);

@pragma("vm:entry-point")
void dream() => run(interactive: false);
''';

    final Map<String, String> entrypoints = getDartEntrypoints(mainDartContent);
    expect(entrypoints.isEmpty, isFalse);
    expect(entrypoints,
      equals(
        <String, String>{
          'main': '("vm:entry-point")',
          'dream': '("vm:entry-point")',
        },
      ),
    );
  });

  testWithoutContext('Parses top level standard functions annotated with vm:entry-point', () {
    const String mainDartContent = '''
@pragma('vm:entry-point')
void main() {
  run(interactive: true);
}

@pragma('vm:entry-point')
void dream() {
  run(interactive: false);
}
''';

    final Map<String, String> entrypoints = getDartEntrypoints(mainDartContent);
    expect(entrypoints.isEmpty, isFalse);
    expect(entrypoints,
      equals(
        <String, String>{
          'main': "('vm:entry-point')",
          'dream': "('vm:entry-point')",
        },
      ),
    );
  });

  testWithoutContext('Parses top level functions annotated with vm:entry-point arguments', () {
    const String mainDartContent = '''
@pragma('vm:entry-point', !kReleaseMode)
void main() {
  run(interactive: true);
}

@pragma('vm:entry-point')
void dream() {
  run(interactive: false);
}
''';

    final Map<String, String> entrypoints = getDartEntrypoints(mainDartContent);
    expect(entrypoints.isEmpty, isFalse);
    expect(entrypoints, equals(
        <String, String>{
          'main': "('vm:entry-point', !kReleaseMode)",
          'dream': "('vm:entry-point')",
        },
      ),
    );
  });

  testWithoutContext('Does not parse nested functions annotated with vm:entry-point', () {
    const String mainDartContent = '''
class Foo {
  @pragma('vm:entry-point')
  void main() => run(interactive: true);
}
''';
    final Map<String, String> entrypoints = getDartEntrypoints(mainDartContent);
    expect(entrypoints.isEmpty, isTrue);
  });


  testWithoutContext('Parses main function even if it is not annotated with vm:entry-point', () {
    const String mainDartContent = '''
void main() => run(interactive: true);
''';

    final Map<String, String> entrypoints = getDartEntrypoints(mainDartContent);
    expect(entrypoints.isEmpty, isFalse);
    expect(entrypoints, equals(<String, String>{'main': "('vm:entry-point')"}));
  });

  testWithoutContext('Ignores comments', () {
    const String mainDartContent = '''
// void main() => run(interactive: true);

// @pragma('vm:entry-point')
void dream() => run(interactive: false);
''';

    final Map<String, String> entrypoints = getDartEntrypoints(mainDartContent);
    expect(entrypoints.isEmpty, isTrue);
  });

}
