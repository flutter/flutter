import 'dart:io';

import 'package:dcli/dcli.dart' hide equals, PubSpec;
import 'package:dcli_core/dcli_core.dart' as core;
import 'package:pubspec/pubspec.dart';
import 'package:pubspec/src/platform.dart';
import 'package:test/test.dart';

main() {
  test('platforms ', () async {
    var pubspecString = '''name: my_test_lib
version: 0.1.0
description: for testing
dependencies: 
  meta: ^1.0.0
platforms: 
  linux: 
  windows: 
  macos: 
''';
    var p = PubSpec.fromYamlString(pubspecString);
    var platform = p.platforms['linux']!;
    expect(platform, TypeMatcher<Platform>());
    expect(platform.name, equals('linux'));

    platform = p.platforms['windows']!;
    expect(platform, TypeMatcher<Platform>());
    expect(platform.name, equals('windows'));

    platform = p.platforms['macos']!;
    expect(platform, TypeMatcher<Platform>());
    expect(platform.name, equals('macos'));

    expect(p.platforms.keys, unorderedEquals(['linux', 'windows', 'macos']));

    await core.withTempDir((pathToPubspec) async {
      await p.save(Directory(pathToPubspec));

      var content =
          read(join(pathToPubspec, 'pubspec.yaml')).toParagraph() + '\n';
      expect(content, equals(pubspecString));
    });
  });
}
