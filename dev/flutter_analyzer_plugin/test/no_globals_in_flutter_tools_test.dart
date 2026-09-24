// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:analyzer_testing/package_config_file_builder.dart';
import 'package:flutter_analyzer_plugin/src/rules/no_globals_in_flutter_tools.dart';
import 'package:test/test.dart';

import '../tool/update_migrated_files.dart';

class NoGlobalsInFlutterToolsRestrictedFileTest extends AnalysisRuleTest {
  @override
  void setUp() {
    Registry.ruleRegistry.registerWarningRule(
      NoGlobalsInFlutterTools(<String>{
        'lib/src/commands/restricted.dart',
        'test/commands.shard/hermetic/restricted_test.dart',
      }),
    );
    super.setUp();

    newFile('$testPackageLibPath/globals.dart', 'const int fs = 1;');
    newFile('$testPackageLibPath/other.dart', 'const int other = 1;');
    newFile('$testPackageRootPath/lib/src/globals.dart', 'const int fs = 1;');
    newPackage('flutter_tools').addFile('lib/src/globals.dart', 'const int fs = 1;');
    newPackage('other_pkg').addFile('lib/globals.dart', 'const int fs = 1;');
    newPackage('other_pkg').addFile('lib/src/globals.dart', 'const int fs = 1;');
    writeTestPackageConfig(PackageConfigFileBuilder());
  }

  @override
  String get analysisRule => NoGlobalsInFlutterTools.code.name;

  @override
  String get testPackageRootPath => '$workspaceRootPath/packages/flutter_tools';

  @override
  String get testPackageLibPath => '$testPackageRootPath/lib/src/commands';

  @override
  String get testFileName => 'restricted.dart';

  // ignore: non_constant_identifier_names
  Future<void> test_relative_globals_import() async {
    const source = '''
import 'globals.dart';

void main() {
  const int x = fs;
}
''';
    await assertDiagnostics(source, [lint(7, 14)]);
  }

  // ignore: non_constant_identifier_names
  Future<void> test_relative_globals_import_with_prefix() async {
    const source = '''
import 'globals.dart' as globals;

void main() {
  const int x = globals.fs;
}
''';
    await assertDiagnostics(source, [lint(7, 14)]);
  }

  // ignore: non_constant_identifier_names
  Future<void> test_relative_parent_globals_import() async {
    const source = '''
import '../globals.dart';

void main() {
  const int x = fs;
}
''';
    await assertDiagnostics(source, [lint(7, 17)]);
  }

  // ignore: non_constant_identifier_names
  Future<void> test_relative_parent_globals_import_with_prefix() async {
    const source = '''
import '../globals.dart' as globals;

void main() {
  const int x = globals.fs;
}
''';
    await assertDiagnostics(source, [lint(7, 17)]);
  }

  // ignore: non_constant_identifier_names
  Future<void> test_unrelated_import_with_globals_prefix() async {
    const source = '''
import 'other.dart' as globals;

void main() {
  const int x = globals.other;
}
''';
    await assertNoDiagnostics(source);
  }

  // ignore: non_constant_identifier_names
  Future<void> test_globals_import_with_custom_prefix() async {
    const source = '''
import 'globals.dart' as g;

void main() {
  const int x = g.fs;
}
''';
    await assertDiagnostics(source, [lint(7, 14)]);
  }

  // ignore: non_constant_identifier_names
  Future<void> test_package_globals_import() async {
    const source = '''
import 'package:flutter_tools/src/globals.dart';

void main() {
  const int x = fs;
}
''';
    await assertDiagnostics(source, [lint(7, 40)]);
  }

  // ignore: non_constant_identifier_names
  Future<void> test_allowed_other_import() async {
    const source = '''
import 'other.dart';

void main() {
  const int x = other;
}
''';
    await assertNoDiagnostics(source);
  }

  // ignore: non_constant_identifier_names
  Future<void> test_third_party_package_globals_import_ignored() async {
    const source = '''
import 'package:other_pkg/globals.dart';
import 'package:other_pkg/src/globals.dart' as other_src;

void main() {
  const int x = fs;
  const int y = other_src.fs;
}
''';
    await assertNoDiagnostics(source);
  }
}

class NoGlobalsInFlutterToolsUnrestrictedFileTest extends AnalysisRuleTest {
  @override
  void setUp() {
    Registry.ruleRegistry.registerWarningRule(
      NoGlobalsInFlutterTools(<String>{'lib/src/commands/restricted.dart'}),
    );
    super.setUp();

    newFile('$testPackageLibPath/globals.dart', 'const int fs = 1;');
    writeTestPackageConfig(PackageConfigFileBuilder());
  }

  @override
  String get analysisRule => NoGlobalsInFlutterTools.code.name;

  @override
  String get testPackageRootPath => '$workspaceRootPath/packages/flutter_tools';

  @override
  String get testPackageLibPath => '$testPackageRootPath/lib/src/commands';

  @override
  String get testFileName => 'unrestricted.dart';

  // ignore: non_constant_identifier_names
  Future<void> test_unrestricted_file_can_import_globals() async {
    const source = '''
import 'globals.dart';

void main() {
  const int x = fs;
}
''';
    await assertNoDiagnostics(source);
  }
}

class NoGlobalsInFlutterToolsOtherPackageTest extends AnalysisRuleTest {
  @override
  void setUp() {
    Registry.ruleRegistry.registerWarningRule(
      NoGlobalsInFlutterTools(<String>{'lib/src/commands/restricted.dart'}),
    );
    super.setUp();

    newFile('$testPackageLibPath/globals.dart', 'const int fs = 1;');
    writeTestPackageConfig(PackageConfigFileBuilder());
  }

  @override
  String get analysisRule => NoGlobalsInFlutterTools.code.name;

  @override
  String get testPackageRootPath => '$workspaceRootPath/packages/other_pkg';

  @override
  String get testPackageLibPath => '$testPackageRootPath/lib/src/commands';

  @override
  String get testFileName => 'restricted.dart';

  // ignore: non_constant_identifier_names
  Future<void> test_other_package_ignores_rule() async {
    const source = '''
import 'globals.dart';

void main() {
  const int x = fs;
}
''';
    await assertNoDiagnostics(source);
  }
}

class NoGlobalsInFlutterToolsDefaultPathsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    Registry.ruleRegistry.registerWarningRule(NoGlobalsInFlutterTools());
    super.setUp();

    newFile('$testPackageLibPath/globals.dart', 'const int fs = 1;');
    writeTestPackageConfig(PackageConfigFileBuilder());
  }

  @override
  String get analysisRule => NoGlobalsInFlutterTools.code.name;

  @override
  String get testPackageRootPath => '$workspaceRootPath/packages/flutter_tools';

  @override
  String get testPackageLibPath => '$testPackageRootPath/lib/src/commands';

  @override
  String get testFileName => 'clean.dart';

  // ignore: non_constant_identifier_names
  Future<void> test_clean_command_restricted_by_default() async {
    const source = '''
import 'globals.dart';

void main() {
  const int x = fs;
}
''';
    await assertDiagnostics(source, [lint(7, 14)]);
  }
}

class NoGlobalsInFlutterToolsDefaultTestPathTest extends AnalysisRuleTest {
  @override
  void setUp() {
    Registry.ruleRegistry.registerWarningRule(NoGlobalsInFlutterTools());
    super.setUp();

    newFile('$testPackageLibPath/globals.dart', 'const int fs = 1;');
    writeTestPackageConfig(PackageConfigFileBuilder());
  }

  @override
  String get analysisRule => NoGlobalsInFlutterTools.code.name;

  @override
  String get testPackageRootPath => '$workspaceRootPath/packages/flutter_tools';

  @override
  String get testPackageLibPath => '$testPackageRootPath/test/commands.shard/hermetic';

  @override
  String get testFileName => 'clean_test.dart';

  // ignore: non_constant_identifier_names
  Future<void> test_clean_test_restricted_by_default() async {
    const source = '''
import 'globals.dart';

void main() {
  const int x = fs;
}
''';
    await assertDiagnostics(source, [lint(7, 14)]);
  }
}

class NoGlobalsInFlutterToolsWindowsRestrictedPathTest extends AnalysisRuleTest {
  @override
  void setUp() {
    Registry.ruleRegistry.registerWarningRule(
      NoGlobalsInFlutterTools(<String>{r'lib\src\commands\restricted.dart'}),
    );
    super.setUp();

    newFile('$testPackageLibPath/globals.dart', 'const int fs = 1;');
    writeTestPackageConfig(PackageConfigFileBuilder());
  }

  @override
  String get analysisRule => NoGlobalsInFlutterTools.code.name;

  @override
  String get testPackageRootPath => '$workspaceRootPath/packages/flutter_tools';

  @override
  String get testPackageLibPath => '$testPackageRootPath/lib/src/commands';

  @override
  String get testFileName => 'restricted.dart';

  // ignore: non_constant_identifier_names
  Future<void> test_windows_restricted_path_normalizes() async {
    const source = '''
import 'globals.dart';

void main() {
  const int x = fs;
}
''';
    await assertDiagnostics(source, [lint(7, 14)]);
  }
}

class NoGlobalsInFlutterToolsVerificationTest {
  // ignore: non_constant_identifier_names
  void test_all_migrated_files_included_in_defaultRestrictedPaths() {
    final Directory toolsDir = findFlutterToolsDirectory();
    final Set<String> migratedFiles = findMigratedFiles(toolsDir);
    final Set<String> missing = migratedFiles.difference(
      NoGlobalsInFlutterTools.defaultRestrictedPaths,
    );
    final Set<String> extra = NoGlobalsInFlutterTools.defaultRestrictedPaths.difference(
      migratedFiles,
    );

    if (missing.isNotEmpty) {
      throw StateError(
        'The following files in flutter_tools do not import globals.dart but are missing from '
        'NoGlobalsInFlutterTools.defaultRestrictedPaths:\n'
        '${missing.take(10).join('\n')}${missing.length > 10 ? '\n...and ${missing.length - 10} more' : ''}\n\n'
        'Run `dart dev/flutter_analyzer_plugin/tool/update_migrated_files.dart` to update the set.',
      );
    }
    if (extra.isNotEmpty) {
      throw StateError(
        'The following files in NoGlobalsInFlutterTools.defaultRestrictedPaths actually import globals.dart:\n'
        '${extra.take(10).join('\n')}${extra.length > 10 ? '\n...and ${extra.length - 10} more' : ''}\n\n'
        'Run `dart dev/flutter_analyzer_plugin/tool/update_migrated_files.dart` to update the set.',
      );
    }
  }
}

void main() {
  group('NoGlobalsInFlutterToolsRestrictedFileTest', () {
    late NoGlobalsInFlutterToolsRestrictedFileTest testSuite;

    setUp(() {
      testSuite = NoGlobalsInFlutterToolsRestrictedFileTest()..setUp();
    });

    tearDown(() => testSuite.tearDown());

    test('relative globals import', () => testSuite.test_relative_globals_import());
    test(
      'relative globals import with prefix',
      () => testSuite.test_relative_globals_import_with_prefix(),
    );
    test('relative parent globals import', () => testSuite.test_relative_parent_globals_import());
    test(
      'relative parent globals import with prefix',
      () => testSuite.test_relative_parent_globals_import_with_prefix(),
    );
    test(
      'unrelated import with globals prefix',
      () => testSuite.test_unrelated_import_with_globals_prefix(),
    );
    test(
      'globals import with custom prefix',
      () => testSuite.test_globals_import_with_custom_prefix(),
    );
    test('package globals import', () => testSuite.test_package_globals_import());
    test('allowed other import', () => testSuite.test_allowed_other_import());
    test(
      'third party package globals import ignored',
      () => testSuite.test_third_party_package_globals_import_ignored(),
    );
  });

  group('NoGlobalsInFlutterToolsUnrestrictedFileTest', () {
    late NoGlobalsInFlutterToolsUnrestrictedFileTest testSuite;

    setUp(() {
      testSuite = NoGlobalsInFlutterToolsUnrestrictedFileTest()..setUp();
    });

    tearDown(() => testSuite.tearDown());

    test(
      'unrestricted file can import globals',
      () => testSuite.test_unrestricted_file_can_import_globals(),
    );
  });

  group('NoGlobalsInFlutterToolsOtherPackageTest', () {
    late NoGlobalsInFlutterToolsOtherPackageTest testSuite;

    setUp(() {
      testSuite = NoGlobalsInFlutterToolsOtherPackageTest()..setUp();
    });

    tearDown(() => testSuite.tearDown());

    test('other package ignores rule', () => testSuite.test_other_package_ignores_rule());
  });

  group('NoGlobalsInFlutterToolsDefaultPathsTest', () {
    late NoGlobalsInFlutterToolsDefaultPathsTest testSuite;

    setUp(() {
      testSuite = NoGlobalsInFlutterToolsDefaultPathsTest()..setUp();
    });

    tearDown(() => testSuite.tearDown());

    test(
      'clean command restricted by default',
      () => testSuite.test_clean_command_restricted_by_default(),
    );
  });

  group('NoGlobalsInFlutterToolsDefaultTestPathTest', () {
    late NoGlobalsInFlutterToolsDefaultTestPathTest testSuite;

    setUp(() {
      testSuite = NoGlobalsInFlutterToolsDefaultTestPathTest()..setUp();
    });

    tearDown(() => testSuite.tearDown());

    test(
      'clean test restricted by default',
      () => testSuite.test_clean_test_restricted_by_default(),
    );
  });

  group('NoGlobalsInFlutterToolsWindowsRestrictedPathTest', () {
    late NoGlobalsInFlutterToolsWindowsRestrictedPathTest testSuite;

    setUp(() {
      testSuite = NoGlobalsInFlutterToolsWindowsRestrictedPathTest()..setUp();
    });

    tearDown(() => testSuite.tearDown());

    test(
      'windows restricted path normalizes',
      () => testSuite.test_windows_restricted_path_normalizes(),
    );
  });

  test('all migrated files included in defaultRestrictedPaths', () {
    NoGlobalsInFlutterToolsVerificationTest()
        .test_all_migrated_files_included_in_defaultRestrictedPaths();
  });
}
