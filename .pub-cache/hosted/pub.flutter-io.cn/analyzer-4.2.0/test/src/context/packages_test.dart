// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PackagesTest);
  });
}

@reflectiveTest
class PackagesTest with ResourceProviderMixin {
  void setUp() {
    newFile('/test/lib/test.dart', '');
  }

  void test_findPackagesFrom_missing() {
    var packages = findPackagesFrom(
      resourceProvider,
      getFile('/test/lib/a.dart'),
    );

    expect(packages.packages, isEmpty);
  }

  test_packageForPath() {
    var packages = Packages(
      {
        'aaa': Package(
          name: 'aaa',
          rootFolder: getFolder('/home/aaa'),
          libFolder: getFolder('/home/aaa/lib'),
          languageVersion: Version.parse('2.7.0'),
        ),
        'bbb': Package(
          name: 'bbb',
          rootFolder: getFolder('/home/aaa/bbb'),
          libFolder: getFolder('/home/aaa/bbb/lib'),
          languageVersion: Version.parse('2.7.0'),
        ),
        'ccc': Package(
          name: 'ccc',
          rootFolder: getFolder('/home/ccc'),
          libFolder: getFolder('/home/ccc/lib'),
          languageVersion: Version.parse('2.7.0'),
        ),
      },
    );

    void check(String posixPath, String? expectedPackageName) {
      var path = convertPath(posixPath);
      var package = packages.packageForPath(path);
      expect(package?.name, expectedPackageName);
    }

    check('/home/aaa/lib/a.dart', 'aaa');
    check('/home/aaa/bbb/lib/b.dart', 'bbb');
    check('/home/ccc/lib/c.dart', 'ccc');
    check('/home/ddd/lib/d.dart', null);
  }

  test_parsePackageConfigJsonFile() {
    var file = newFile('/test/.dart_tool/package_config.json', '''
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
      "languageVersion": "2.3"
    },
    {
      "name": "bbb",
      "rootUri": "${toUriStr('/packages/bbb')}",
      "packageUri": "lib/"
    }
  ]
}
''');
    var packages = parsePackageConfigJsonFile(resourceProvider, file);

    _assertPackage(
      packages,
      name: 'test',
      expectedLibPath: '/test/lib',
      expectedVersion: Version(2, 6, 0),
    );

    _assertPackage(
      packages,
      name: 'aaa',
      expectedLibPath: '/packages/aaa/lib',
      expectedVersion: Version(2, 3, 0),
    );

    _assertPackage(
      packages,
      name: 'bbb',
      expectedLibPath: '/packages/bbb/lib',
      expectedVersion: null,
    );
  }

  test_parsePackagesFile_packageConfig() {
    final file = newFile('/test/.dart_tool/package_config.json', '''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "aaa",
      "rootUri": "${toUriStr('/packages/aaa')}",
      "packageUri": "lib/",
      "languageVersion": "2.3"
    }
  ]
}
''');

    var packages = parsePackageConfigJsonFile(resourceProvider, file);

    _assertPackage(
      packages,
      name: 'aaa',
      expectedLibPath: '/packages/aaa/lib',
      expectedVersion: Version(2, 3, 0),
    );
  }

  void _assertPackage(
    Packages packages, {
    required String name,
    required String expectedLibPath,
    required Version? expectedVersion,
  }) {
    var package = packages[name]!;
    expect(package.name, name);
    expect(package.libFolder.path, convertPath(expectedLibPath));
    expect(package.languageVersion, expectedVersion);
  }
}
