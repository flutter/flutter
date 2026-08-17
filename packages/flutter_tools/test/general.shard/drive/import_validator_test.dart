// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/drive/import_validator.dart';
import 'package:package_config/package_config.dart';

import '../../src/common.dart';

void main() {
  late MemoryFileSystem fileSystem;
  late BufferLogger logger;
  late PackageConfig packageConfig;
  const projectRoot = '/project';

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    logger = BufferLogger.test();
    packageConfig = PackageConfig(<Package>[
      Package('my_package', Uri.parse('file://$projectRoot/'), packageUriRoot: Uri.parse('lib/')),
    ]);
    fileSystem.directory(projectRoot).createSync();
  });

  DriverTestImportValidator createValidator() {
    return DriverTestImportValidator(
      fileSystem: fileSystem,
      packageConfig: packageConfig,
      projectRootPath: projectRoot,
      logger: logger,
    );
  }

  testWithoutContext('passes when there are no imports', () {
    final File file = fileSystem.file('$projectRoot/test_driver/my_test.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
void main() {}
''');
    final List<String> errors = createValidator().validate(file);
    expect(errors, isEmpty);
  });

  testWithoutContext('passes with allowed imports', () {
    final File file = fileSystem.file('$projectRoot/test_driver/my_test.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
import 'package:flutter_driver/flutter_driver.dart';
import 'package:path/path.dart';
void main() {}
''');
    final List<String> errors = createValidator().validate(file);
    expect(errors, isEmpty);
  });

  testWithoutContext('fails with direct forbidden import dart:ui', () {
    final File file = fileSystem.file('$projectRoot/test_driver/my_test.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
import 'dart:ui';
void main() {}
''');
    final List<String> errors = createValidator().validate(file);
    expect(errors, hasLength(1));
    expect(errors.first, contains('Forbidden import/export "dart:ui"'));
  });

  testWithoutContext('fails with direct forbidden import package:flutter/material.dart', () {
    final File file = fileSystem.file('$projectRoot/test_driver/my_test.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
import 'package:flutter/material.dart';
void main() {}
''');
    final List<String> errors = createValidator().validate(file);
    expect(errors, hasLength(1));
    expect(errors.first, contains('Forbidden import/export "package:flutter/material.dart"'));
  });

  testWithoutContext(
    'fails with direct forbidden import package:flutter_test/flutter_test.dart',
    () {
      final File file = fileSystem.file('$projectRoot/test_driver/my_test.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'package:flutter_test/flutter_test.dart';
void main() {}
''');
      final List<String> errors = createValidator().validate(file);
      expect(errors, hasLength(1));
      expect(
        errors.first,
        contains('Forbidden import/export "package:flutter_test/flutter_test.dart"'),
      );
    },
  );

  testWithoutContext('passes with relative import to safe file', () {
    final File file = fileSystem.file('$projectRoot/test_driver/my_test.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
import 'helper.dart';
void main() {}
''');
    fileSystem.file('$projectRoot/test_driver/helper.dart')
      ..createSync()
      ..writeAsStringSync('''
void help() {}
''');
    final List<String> errors = createValidator().validate(file);
    expect(errors, isEmpty);
  });

  testWithoutContext('fails with relative import to unsafe file', () {
    final File file = fileSystem.file('$projectRoot/test_driver/my_test.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
import 'helper.dart';
void main() {}
''');
    fileSystem.file('$projectRoot/test_driver/helper.dart')
      ..createSync()
      ..writeAsStringSync('''
import 'package:flutter/material.dart';
void help() {}
''');
    final List<String> errors = createValidator().validate(file);
    expect(errors, hasLength(1));
    expect(errors.first, contains('Forbidden import/export "package:flutter/material.dart"'));
    expect(errors.first, contains('helper.dart'));
  });

  testWithoutContext('passes with package import to safe file', () {
    final File file = fileSystem.file('$projectRoot/test_driver/my_test.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
import 'package:my_package/helper.dart';
void main() {}
''');
    fileSystem.file('$projectRoot/lib/helper.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
void help() {}
''');
    final List<String> errors = createValidator().validate(file);
    expect(errors, isEmpty);
  });

  testWithoutContext('fails with package import to unsafe file', () {
    final File file = fileSystem.file('$projectRoot/test_driver/my_test.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
import 'package:my_package/helper.dart';
void main() {}
''');
    fileSystem.file('$projectRoot/lib/helper.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
import 'package:flutter/material.dart';
void help() {}
''');
    final List<String> errors = createValidator().validate(file);
    expect(errors, hasLength(1));
    expect(errors.first, contains('Forbidden import/export "package:flutter/material.dart"'));
    expect(errors.first, contains('helper.dart'));
  });

  testWithoutContext('handles circular imports without infinite loop', () {
    final File file1 = fileSystem.file('$projectRoot/test_driver/file1.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
import 'file2.dart';
void main() {}
''');
    fileSystem.file('$projectRoot/test_driver/file2.dart')
      ..createSync()
      ..writeAsStringSync('''
import 'file1.dart';
void help() {}
''');
    final List<String> errors = createValidator().validate(file1);
    expect(errors, isEmpty);
  });

  testWithoutContext('ignores imports outside project root', () {
    final File file = fileSystem.file('$projectRoot/test_driver/my_test.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
import 'package:external_package/external.dart';
void main() {}
''');

    // Configure package config to point external_package outside project root
    packageConfig = PackageConfig(<Package>[
      Package('my_package', Uri.parse('file://$projectRoot/'), packageUriRoot: Uri.parse('lib/')),
      Package('external_package', Uri.parse('file:///outside/'), packageUriRoot: Uri.parse('lib/')),
    ]);

    // Create the external file with a forbidden import.
    // It should NOT be scanned because it is outside project root.
    fileSystem.file('/outside/lib/external.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
import 'package:flutter/material.dart';
''');

    final List<String> errors = createValidator().validate(file);
    expect(errors, isEmpty);
  });
}
