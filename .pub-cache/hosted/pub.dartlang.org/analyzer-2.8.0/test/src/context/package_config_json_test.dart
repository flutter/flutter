// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/context/package_config_json.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PackageConfigJsonTest);
  });
}

@reflectiveTest
class PackageConfigJsonTest with ResourceProviderMixin {
  void assertPackage(
      PackageConfigJsonPackage actual, _ExpectedPackage expected) {
    expect(actual.name, expected.name);
    expect(actual.rootUri, toUri(expected.rootUriPath));
    expect(actual.packageUri, toUri(expected.packageUriPath));
    expect(actual.languageVersion, expected.languageVersion);
  }

  void setUp() {
    newFile('/test/lib/test.dart', content: '');
  }

  test_configVersion_2() {
    var config = _parse('''
{
  "configVersion": 2,
  "packages": []
}
''');
    expect(config.configVersion, 2);
    expect(config.packages, isEmpty);
  }

  test_configVersion_3() {
    _throwsFormatException('''
{
  "configVersion": 3,
  "packages": []
}
''', 'config version');
  }

  test_configVersion_missing() {
    _throwsFormatException('''
{
  "packages": []
}
''', 'configVersion');
  }

  test_configVersion_notInt() {
    _throwsFormatException('''
{
  "configVersion": "2",
  "packages": []
}
''', 'configVersion');
  }

  test_format_notMap() {
    _throwsFormatException('42', 'JSON object');
  }

  test_generated() {
    var config = _parse('''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "test",
      "rootUri": "../",
      "packageUri": "lib/",
      "languageVersion": "2.6"
    }
  ],
  "generated": "2019-12-10T18:29:14.336160Z",
  "generator": "pub",
  "generatorVersion": "2.8.0-edge.28b0f1839726c0743e25a2765c5322a24f6e2afa"
}
''');
    var generated = config.generated!;
    expect(generated.year, 2019);
    expect(generated.month, 12);
    expect(generated.day, 10);
    expect(generated.hour, 18);
    expect(generated.minute, 29);
    expect(generated.second, 14);

    expect(config.generator, 'pub');

    var generatorVersion = config.generatorVersion!;
    expect(generatorVersion.major, 2);
    expect(generatorVersion.minor, 8);
    expect(generatorVersion.patch, 0);
  }

  test_packages() {
    var config = _parse('''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "test",
      "rootUri": "../",
      "packageUri": "lib/",
      "languageVersion": "2.6"
    },
    {
      "name": "aaa",
      "rootUri": "${toUriStr('/packages/aaa')}",
      "packageUri": "lib/",
      "languageVersion": "2.0"
    },
    {
      "name": "bbb",
      "rootUri": "${toUriStr('/packages/bbb/lib')}",
      "languageVersion": "2.1"
    }
  ]
}
''');
    assertPackage(
      config.packages[0],
      _ExpectedPackage(
        name: 'test',
        rootUriPath: '/test/',
        packageUriPath: '/test/lib/',
        languageVersion: LanguageVersion(2, 6),
      ),
    );
    assertPackage(
      config.packages[1],
      _ExpectedPackage(
        name: 'aaa',
        rootUriPath: '/packages/aaa/',
        packageUriPath: '/packages/aaa/lib/',
        languageVersion: LanguageVersion(2, 0),
      ),
    );
    assertPackage(
      config.packages[2],
      _ExpectedPackage(
        name: 'bbb',
        rootUriPath: '/packages/bbb/lib/',
        packageUriPath: '/packages/bbb/lib/',
        languageVersion: LanguageVersion(2, 1),
      ),
    );
  }

  test_packages_languageVersion_default() {
    var config = _parse('''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "test",
      "rootUri": "../",
      "packageUri": "lib/"
    }
  ]
}
''');
    assertPackage(
      config.packages[0],
      _ExpectedPackage(
        name: 'test',
        rootUriPath: '/test/',
        packageUriPath: '/test/lib/',
        languageVersion: null,
      ),
    );
  }

  test_packages_languageVersion_invalidPrefix() {
    _throwsFormatException('''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "test",
      "rootUri": "../",
      "packageUri": "lib/",
      "languageVersion": " 2.6"
    }
  ]
}
''', 'languageVersion');
  }

  test_packages_languageVersion_invalidSuffix() {
    _throwsFormatException('''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "test",
      "rootUri": "../",
      "packageUri": "lib/",
      "languageVersion": "2.6 "
    }
  ]
}
''', 'languageVersion');
  }

  test_packages_missing() {
    _throwsFormatException('''
{
  "configVersion": 2
}
''', 'packages');
  }

  test_packages_packageUri_absolute() {
    _throwsFormatException('''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "test",
      "rootUri": "../",
      "packageUri": "${toUriStr('/test/lib')}",
      "languageVersion": "2.6"
    }
  ]
}
''', 'packageUri');
  }

  test_packages_packageUri_empty() {
    var config = _parse('''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "test",
      "rootUri": "../",
      "packageUri": ""
    }
  ]
}
''');
    assertPackage(
      config.packages[0],
      _ExpectedPackage(
        name: 'test',
        rootUriPath: '/test/',
        packageUriPath: '/test/',
        languageVersion: null,
      ),
    );
  }

  test_packages_packageUri_notInRootUri() {
    _throwsFormatException('''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "aaa",
      "rootUri": "${toUriStr('/packages/aaa')}",
      "packageUri": "..",
      "languageVersion": "2.6"
    }
  ]
}
''', 'packageUri');
  }

  test_packages_rootUri_doesNotEndWithSlash() {
    var config = _parse('''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "test",
      "rootUri": "..",
      "packageUri": "lib"
    }
  ]
}
''');
    assertPackage(
      config.packages[0],
      _ExpectedPackage(
        name: 'test',
        rootUriPath: '/test/',
        packageUriPath: '/test/lib/',
        languageVersion: null,
      ),
    );
  }

  PackageConfigJson _parse(String content) {
    var path = '/test/.dart_tool/package_config.json';
    newFile(path, content: content);

    var uri = toUri(path);
    return parsePackageConfigJson(uri, content);
  }

  void _throwsFormatException(String content, String expectedSubString) {
    try {
      _parse(content);
      fail('Expected to throw FormatException');
    } on FormatException catch (e) {
      expect(e.message, contains(expectedSubString));
    }
  }
}

class _ExpectedPackage {
  final String name;
  final String rootUriPath;
  final String packageUriPath;
  final LanguageVersion? languageVersion;

  _ExpectedPackage({
    required this.name,
    required this.rootUriPath,
    required this.packageUriPath,
    required this.languageVersion,
  });
}
