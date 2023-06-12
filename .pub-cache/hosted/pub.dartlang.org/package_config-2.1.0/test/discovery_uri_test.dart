// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
library package_config.discovery_test;

import 'package:test/test.dart';
import 'package:package_config/package_config.dart';

import 'src/util.dart';

const packagesFile = '''
# A comment
foo:file:///dart/packages/foo/
bar:/dart/packages/bar/
baz:packages/baz/
''';

const packageConfigFile = '''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "foo",
      "rootUri": "file:///dart/packages/foo/"
    },
    {
      "name": "bar",
      "rootUri": "/dart/packages/bar/"
    },
    {
      "name": "baz",
      "rootUri": "../packages/baz/"
    }
  ],
  "extra": [42]
}
''';

void validatePackagesFile(PackageConfig resolver, Uri directory) {
  expect(resolver, isNotNull);
  expect(resolver.resolve(pkg('foo', 'bar/baz')),
      equals(Uri.parse('file:///dart/packages/foo/bar/baz')));
  expect(resolver.resolve(pkg('bar', 'baz/qux')),
      equals(directory.resolve('/dart/packages/bar/baz/qux')));
  expect(resolver.resolve(pkg('baz', 'qux/foo')),
      equals(directory.resolve('packages/baz/qux/foo')));
  expect([for (var p in resolver.packages) p.name],
      unorderedEquals(['foo', 'bar', 'baz']));
}

void main() {
  group('findPackages', () {
    // Finds package_config.json if there.
    loaderTest('package_config.json', {
      '.packages': 'invalid .packages file',
      'script.dart': 'main(){}',
      'packages': {'shouldNotBeFound': {}},
      '.dart_tool': {
        'package_config.json': packageConfigFile,
      }
    }, (directory, loader) async {
      var config = (await findPackageConfigUri(directory, loader: loader))!;
      expect(config.version, 2); // Found package_config.json file.
      validatePackagesFile(config, directory);
    });

    // Finds .packages if no package_config.json.
    loaderTest('.packages', {
      '.packages': packagesFile,
      'script.dart': 'main(){}',
      'packages': {'shouldNotBeFound': {}}
    }, (directory, loader) async {
      var config = (await findPackageConfigUri(directory, loader: loader))!;
      expect(config.version, 1); // Found .packages file.
      validatePackagesFile(config, directory);
    });

    // Finds package_config.json in super-directory.
    loaderTest('package_config.json recursive', {
      '.packages': packagesFile,
      '.dart_tool': {
        'package_config.json': packageConfigFile,
      },
      'subdir': {
        'script.dart': 'main(){}',
      }
    }, (directory, loader) async {
      var config = (await findPackageConfigUri(directory.resolve('subdir/'),
          loader: loader))!;
      expect(config.version, 2);
      validatePackagesFile(config, directory);
    });

    // Finds .packages in super-directory.
    loaderTest('.packages recursive', {
      '.packages': packagesFile,
      'subdir': {'script.dart': 'main(){}'}
    }, (directory, loader) async {
      var config = (await findPackageConfigUri(directory.resolve('subdir/'),
          loader: loader))!;
      expect(config.version, 1);
      validatePackagesFile(config, directory);
    });

    // Does not find a packages/ directory, and returns null if nothing found.
    loaderTest('package directory packages not supported', {
      'packages': {
        'foo': {},
      }
    }, (Uri directory, loader) async {
      var config = await findPackageConfigUri(directory, loader: loader);
      expect(config, null);
    });

    loaderTest('invalid .packages', {
      '.packages': 'not a .packages file',
    }, (Uri directory, loader) {
      expect(() => findPackageConfigUri(directory, loader: loader),
          throwsA(TypeMatcher<FormatException>()));
    });

    loaderTest('invalid .packages as JSON', {
      '.packages': packageConfigFile,
    }, (Uri directory, loader) {
      expect(() => findPackageConfigUri(directory, loader: loader),
          throwsA(TypeMatcher<FormatException>()));
    });

    loaderTest('invalid .packages', {
      '.dart_tool': {
        'package_config.json': 'not a JSON file',
      }
    }, (Uri directory, loader) {
      expect(() => findPackageConfigUri(directory, loader: loader),
          throwsA(TypeMatcher<FormatException>()));
    });

    loaderTest('invalid .packages as INI', {
      '.dart_tool': {
        'package_config.json': packagesFile,
      }
    }, (Uri directory, loader) {
      expect(() => findPackageConfigUri(directory, loader: loader),
          throwsA(TypeMatcher<FormatException>()));
    });

    // Does not find .packages if no package_config.json and minVersion > 1.
    loaderTest('.packages ignored', {
      '.packages': packagesFile,
      'script.dart': 'main(){}'
    }, (directory, loader) async {
      var config = (await findPackageConfigUri(directory,
          minVersion: 2, loader: loader));
      expect(config, null);
    });

    // Finds package_config.json in super-directory, with .packages in
    // subdir and minVersion > 1.
    loaderTest('package_config.json recursive ignores .packages', {
      '.dart_tool': {
        'package_config.json': packageConfigFile,
      },
      'subdir': {
        '.packages': packagesFile,
        'script.dart': 'main(){}',
      }
    }, (directory, loader) async {
      var config = (await findPackageConfigUri(directory.resolve('subdir/'),
          minVersion: 2, loader: loader))!;
      expect(config.version, 2);
      validatePackagesFile(config, directory);
    });
  });

  group('loadPackageConfig', () {
    // Load a specific files
    group('package_config.json', () {
      var files = {
        '.packages': packagesFile,
        '.dart_tool': {
          'package_config.json': packageConfigFile,
        },
      };
      loaderTest('directly', files, (Uri directory, loader) async {
        var file = directory.resolve('.dart_tool/package_config.json');
        var config = await loadPackageConfigUri(file, loader: loader);
        expect(config.version, 2);
        validatePackagesFile(config, directory);
      });
      loaderTest('indirectly through .packages', files,
          (Uri directory, loader) async {
        var file = directory.resolve('.packages');
        var config = await loadPackageConfigUri(file, loader: loader);
        expect(config.version, 2);
        validatePackagesFile(config, directory);
      });
    });

    loaderTest('package_config.json non-default name', {
      '.packages': packagesFile,
      'subdir': {
        'pheldagriff': packageConfigFile,
      },
    }, (Uri directory, loader) async {
      var file = directory.resolve('subdir/pheldagriff');
      var config = await loadPackageConfigUri(file, loader: loader);
      expect(config.version, 2);
      validatePackagesFile(config, directory);
    });

    loaderTest('package_config.json named .packages', {
      'subdir': {
        '.packages': packageConfigFile,
      },
    }, (Uri directory, loader) async {
      var file = directory.resolve('subdir/.packages');
      var config = await loadPackageConfigUri(file, loader: loader);
      expect(config.version, 2);
      validatePackagesFile(config, directory);
    });

    loaderTest('.packages', {
      '.packages': packagesFile,
    }, (Uri directory, loader) async {
      var file = directory.resolve('.packages');
      var config = await loadPackageConfigUri(file, loader: loader);
      expect(config.version, 1);
      validatePackagesFile(config, directory);
    });

    loaderTest('.packages non-default name', {
      'pheldagriff': packagesFile,
    }, (Uri directory, loader) async {
      var file = directory.resolve('pheldagriff');
      var config = await loadPackageConfigUri(file, loader: loader);
      expect(config.version, 1);
      validatePackagesFile(config, directory);
    });

    loaderTest('no config found', {}, (Uri directory, loader) {
      var file = directory.resolve('anyname');
      expect(() => loadPackageConfigUri(file, loader: loader),
          throwsA(isA<ArgumentError>()));
    });

    loaderTest('no config found, handle error', {},
        (Uri directory, loader) async {
      var file = directory.resolve('anyname');
      var hadError = false;
      await loadPackageConfigUri(file,
          loader: loader,
          onError: expectAsync1((error) {
            hadError = true;
            expect(error, isA<ArgumentError>());
          }, max: -1));
      expect(hadError, true);
    });

    loaderTest('specified file syntax error', {
      'anyname': 'syntax error',
    }, (Uri directory, loader) {
      var file = directory.resolve('anyname');
      expect(() => loadPackageConfigUri(file, loader: loader),
          throwsFormatException);
    });

    loaderTest('specified file syntax onError', {
      'anyname': 'syntax error',
    }, (directory, loader) async {
      var file = directory.resolve('anyname');
      var hadError = false;
      await loadPackageConfigUri(file,
          loader: loader,
          onError: expectAsync1((error) {
            hadError = true;
            expect(error, isA<FormatException>());
          }, max: -1));
      expect(hadError, true);
    });

    // Don't look for package_config.json if original file not named .packages.
    loaderTest('specified file syntax error with alternative', {
      'anyname': 'syntax error',
      '.dart_tool': {
        'package_config.json': packageConfigFile,
      },
    }, (directory, loader) async {
      var file = directory.resolve('anyname');
      expect(() => loadPackageConfigUri(file, loader: loader),
          throwsFormatException);
    });

    // A file starting with `{` is a package_config.json file.
    loaderTest('file syntax error with {', {
      '.packages': '{syntax error',
    }, (directory, loader) async {
      var file = directory.resolve('.packages');
      var hadError = false;
      await loadPackageConfigUri(file,
          loader: loader,
          onError: expectAsync1((error) {
            hadError = true;
            expect(error, isA<FormatException>());
          }, max: -1));
      expect(hadError, true);
    });
  });
}
