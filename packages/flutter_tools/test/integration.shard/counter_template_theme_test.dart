// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/io.dart';

import '../src/common.dart';
import 'test_utils.dart';

const _projectName = 'counter_app';
const _mainRelativePath = 'lib/main.dart';
const _themeModeTestFileName = 'counter_theme_mode_test.dart';

const _themeModeWidgetTestSource = '''
import 'package:counter_app/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('Counter app starts with ThemeMode.system and supports dark mode', (
    WidgetTester tester,
  ) async {
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    tester.platformDispatcher.platformBrightnessTestValue = .light;
    await tester.pumpWidget(const MyApp());

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.themeMode, ThemeMode.system);
    expect(materialApp.theme?.brightness, Brightness.light);
    expect(materialApp.darkTheme?.brightness, Brightness.dark);
    expect(
      materialApp.theme?.colorScheme,
      ColorScheme.fromSeed(seedColor: Colors.deepPurple),
    );
    expect(
      materialApp.darkTheme?.colorScheme,
      ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: .dark),
    );

    BuildContext homeContext = tester.element(find.byType(MyHomePage));
    expect(Theme.of(homeContext).brightness, Brightness.light);
    await expectLater(tester, meetsGuideline(textContrastGuideline));

    tester.platformDispatcher.platformBrightnessTestValue = .dark;
    await tester.pumpAndSettle();

    homeContext = tester.element(find.byType(MyHomePage));
    expect(Theme.of(homeContext).brightness, Brightness.dark);
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  });
}
''';

void main() {
  // Regression test for https://github.com/flutter/flutter/issues/195412.
  testWithoutContext(
    'default counter app template configures darkTheme and starts with ThemeMode.system',
    () async {
      final Directory tempDir = createResolvedTempDirectorySync('counter_template_theme_test.');
      addTearDown(() => tryToDelete(tempDir));

      final Directory projectDir = tempDir.childDirectory(_projectName);
      final commonFlutterArgs = <String>[
        '--suppress-analytics',
        '--no-version-check',
        ...getLocalEngineArguments(),
      ];

      final ProcessResult createResult = await processManager.run(<String>[
        flutterBin,
        ...commonFlutterArgs,
        'create',
        '--offline',
        '--project-name',
        _projectName,
        projectDir.path,
      ]);
      expect(createResult, const ProcessResultMatcher());

      final String dartBin = fileSystem.path.join(
        getFlutterRoot(),
        'bin',
        'cache',
        'dart-sdk',
        'bin',
        platform.isWindows ? 'dart.exe' : 'dart',
      );
      final ProcessResult formatResult = await processManager.run(<String>[
        dartBin,
        'format',
        '--output=none',
        '--set-exit-if-changed',
        _mainRelativePath,
      ], workingDirectory: projectDir.path);
      expect(formatResult, const ProcessResultMatcher());

      writeFile(
        fileSystem.path.join(projectDir.path, 'test', _themeModeTestFileName),
        _themeModeWidgetTestSource,
      );

      final ProcessResult analyzeResult = await processManager.run(<String>[
        flutterBin,
        ...commonFlutterArgs,
        'analyze',
      ], workingDirectory: projectDir.path);
      expect(analyzeResult, const ProcessResultMatcher());

      final ProcessResult testResult = await processManager.run(<String>[
        flutterBin,
        ...commonFlutterArgs,
        'test',
        '--no-color',
      ], workingDirectory: projectDir.path);
      expect(testResult, const ProcessResultMatcher());

      final String mainSource = projectDir.childFile(_mainRelativePath).readAsStringSync();
      expect(mainSource, contains('themeMode: .system,'));
    },
  );
}
