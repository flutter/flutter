// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;

import '../analyze.dart';
import '../analyze_framework_code.dart';
import '../utils.dart';
import 'common.dart';

typedef AsyncVoidCallback = Future<void> Function();

Future<String> capture(AsyncVoidCallback callback, { bool shouldHaveErrors = false }) async {
  final StringBuffer buffer = StringBuffer();
  final PrintCallback oldPrint = print;
  try {
    print = (Object? line) {
      buffer.writeln(line);
    };
    await callback();
    expect(
      hasError,
      shouldHaveErrors,
      reason: buffer.isEmpty ? '(No output to report.)' : hasError ? 'Unexpected errors:\n$buffer' : 'Unexpected success:\n$buffer',
    );
  } finally {
    print = oldPrint;
    resetErrorStatus();
  }
  if (stdout.supportsAnsiEscapes) {
    // Remove ANSI escapes when this test is running on a terminal.
    return buffer.toString().replaceAll(RegExp(r'(\x9B|\x1B\[)[0-?]{1,3}[ -/]*[@-~]'), '');
  } else {
    return buffer.toString();
  }
}

void main() {
  final String testRootPath = path.join('test', 'analyze-test-input', 'root');
  final String dartName = Platform.isWindows ? 'dart.exe' : 'dart';
  final String dartPath = path.canonicalize(path.join('..', '..', 'bin', 'cache', 'dart-sdk', 'bin', dartName));

  test('analyze.dart - verifyDeprecations', () async {
    final String result = await capture(() => verifyDeprecations(testRootPath, minimumMatches: 2), shouldHaveErrors: true);
    final String lines = <String>[
        '║ test/analyze-test-input/root/packages/foo/deprecation.dart:12: Deprecation notice does not match required pattern. There might be a missing space character at the end of the line.',
        '║ test/analyze-test-input/root/packages/foo/deprecation.dart:18: Deprecation notice should be a grammatically correct sentence and start with a capital letter; see style guide: STYLE_GUIDE_URL',
        '║ test/analyze-test-input/root/packages/foo/deprecation.dart:25: Deprecation notice should be a grammatically correct sentence and end with a period; notice appears to be "Also bad grammar".',
        '║ test/analyze-test-input/root/packages/foo/deprecation.dart:29: Deprecation notice does not match required pattern.',
        '║ test/analyze-test-input/root/packages/foo/deprecation.dart:32: Deprecation notice does not match required pattern.',
        '║ test/analyze-test-input/root/packages/foo/deprecation.dart:37: Deprecation notice does not match required pattern. It might be missing the line saying "This feature was deprecated after...".',
        '║ test/analyze-test-input/root/packages/foo/deprecation.dart:41: Deprecation notice does not match required pattern. There might not be an explanatory message.',
        '║ test/analyze-test-input/root/packages/foo/deprecation.dart:48: End of deprecation notice does not match required pattern.',
        '║ test/analyze-test-input/root/packages/foo/deprecation.dart:51: Unexpected deprecation notice indent.',
        '║ test/analyze-test-input/root/packages/foo/deprecation.dart:70: Deprecation notice does not accurately indicate a beta branch version number; please see RELEASES_URL to find the latest beta build version number.',
        '║ test/analyze-test-input/root/packages/foo/deprecation.dart:76: Deprecation notice does not accurately indicate a beta branch version number; please see RELEASES_URL to find the latest beta build version number.',
        '║ test/analyze-test-input/root/packages/foo/deprecation.dart:99: Deprecation notice does not match required pattern. You might have used double quotes (") for the string instead of single quotes (\').',
      ]
      .map((String line) {
        return line
          .replaceAll('/', Platform.isWindows ? r'\' : '/')
          .replaceAll('STYLE_GUIDE_URL', 'https://github.com/flutter/flutter/wiki/Style-guide-for-Flutter-repo')
          .replaceAll('RELEASES_URL', 'https://flutter.dev/docs/development/tools/sdk/releases');
      })
      .join('\n');
    expect(result,
      '╔═╡ERROR╞═══════════════════════════════════════════════════════════════════════\n'
      '$lines\n'
      '║ See: https://github.com/flutter/flutter/wiki/Tree-hygiene#handling-breaking-changes\n'
      '╚═══════════════════════════════════════════════════════════════════════════════\n'
    );
  });

  test('analyze.dart - verifyGoldenTags', () async {
    final List<String> result = (await capture(() => verifyGoldenTags(testRootPath, minimumMatches: 6), shouldHaveErrors: true)).split('\n');
    const String noTag = "Files containing golden tests must be tagged using @Tags(<String>['reduced-test-set']) "
                         'at the top of the file before import statements.';
    const String missingTag = "Files containing golden tests must be tagged with 'reduced-test-set'.";
    final List<String> lines = <String>[
        '║ test/analyze-test-input/root/packages/foo/golden_missing_tag.dart: $missingTag',
        '║ test/analyze-test-input/root/packages/foo/golden_no_tag.dart: $noTag',
      ]
      .map((String line) => line.replaceAll('/', Platform.isWindows ? r'\' : '/'))
      .toList();
    expect(result.length, 4 + lines.length, reason: 'output had unexpected number of lines:\n${result.join('\n')}');
    expect(result[0], '╔═╡ERROR╞═══════════════════════════════════════════════════════════════════════');
    expect(result.getRange(1, result.length - 3).toSet(), lines.toSet());
    expect(result[result.length - 3], '║ See: https://github.com/flutter/flutter/wiki/Writing-a-golden-file-test-for-package:flutter');
    expect(result[result.length - 2], '╚═══════════════════════════════════════════════════════════════════════════════');
    expect(result[result.length - 1], ''); // trailing newline
  });

  test('analyze.dart - verifyNoMissingLicense', () async {
    final String result = await capture(() => verifyNoMissingLicense(testRootPath, checkMinimums: false), shouldHaveErrors: true);
    final String file = 'test/analyze-test-input/root/packages/foo/foo.dart'
      .replaceAll('/', Platform.isWindows ? r'\' : '/');
    expect(result,
      '╔═╡ERROR╞═══════════════════════════════════════════════════════════════════════\n'
      '║ The following file does not have the right license header for dart files:\n'
      '║   $file\n'
      '║ The expected license header is:\n'
      '║ // Copyright 2014 The Flutter Authors. All rights reserved.\n'
      '║ // Use of this source code is governed by a BSD-style license that can be\n'
      '║ // found in the LICENSE file.\n'
      '║ ...followed by a blank line.\n'
      '╚═══════════════════════════════════════════════════════════════════════════════\n'
    );
  });

  test('analyze.dart - verifyNoTrailingSpaces', () async {
    final String result = await capture(() => verifyNoTrailingSpaces(testRootPath, minimumMatches: 2), shouldHaveErrors: true);
    final String lines = <String>[
        '║ test/analyze-test-input/root/packages/foo/spaces.txt:5: trailing U+0020 space character',
        '║ test/analyze-test-input/root/packages/foo/spaces.txt:9: trailing blank line',
      ]
      .map((String line) => line.replaceAll('/', Platform.isWindows ? r'\' : '/'))
      .join('\n');
    expect(result,
      '╔═╡ERROR╞═══════════════════════════════════════════════════════════════════════\n'
      '$lines\n'
      '╚═══════════════════════════════════════════════════════════════════════════════\n'
    );
  });

  test('analyze.dart - verifySpacesAfterFlowControlStatements', () async {
    final String result = await capture(() => verifySpacesAfterFlowControlStatements(testRootPath, minimumMatches: 2), shouldHaveErrors: true);
    final String lines = <String>[
        '║ test/analyze-test-input/root/packages/foo/spaces_after_flow.dart:11: no space after flow control statement',
        '║ test/analyze-test-input/root/packages/foo/spaces_after_flow.dart:18: no space after flow control statement',
        '║ test/analyze-test-input/root/packages/foo/spaces_after_flow.dart:25: no space after flow control statement',
        '║ test/analyze-test-input/root/packages/foo/spaces_after_flow.dart:29: no space after flow control statement',
        '║ test/analyze-test-input/root/packages/foo/spaces_after_flow.dart:35: no space after flow control statement',
      ]
      .map((String line) => line.replaceAll('/', Platform.isWindows ? r'\' : '/'))
      .join('\n');
    expect(result,
      '╔═╡ERROR╞═══════════════════════════════════════════════════════════════════════\n'
      '$lines\n'
      '╚═══════════════════════════════════════════════════════════════════════════════\n'
    );
  });

  test('analyze.dart - verifyNoBinaries - positive', () async {
    final String result = await capture(() => verifyNoBinaries(
      testRootPath,
      legacyBinaries: <Hash256>{const Hash256(0x39A050CD69434936, 0, 0, 0)},
    ), shouldHaveErrors: !Platform.isWindows);
    if (!Platform.isWindows) {
      expect(result,
        '╔═╡ERROR╞═══════════════════════════════════════════════════════════════════════\n'
        '║ test/analyze-test-input/root/packages/foo/serviceaccount.enc:0: file is not valid UTF-8\n'
        '║ All files in this repository must be UTF-8. In particular, images and other binaries\n'
        '║ must not be checked into this repository. This is because we are very sensitive to the\n'
        '║ size of the repository as it is distributed to all our developers. If you have a binary\n'
        '║ to which you need access, you should consider how to fetch it from another repository;\n'
        '║ for example, the "assets-for-api-docs" repository is used for images in API docs.\n'
        '║ To add assets to flutter_tools templates, see the instructions in the wiki:\n'
        '║ https://github.com/flutter/flutter/wiki/Managing-template-image-assets\n'
        '╚═══════════════════════════════════════════════════════════════════════════════\n'
      );
    }
  });

  test('analyze.dart - verifyInternationalizations - comparison fails', () async {
    final String result = await capture(() => verifyInternationalizations(testRootPath, dartPath), shouldHaveErrors: true);
    final String genLocalizationsScript = path.join('dev', 'tools', 'localization', 'bin', 'gen_localizations.dart');
    expect(result,
        contains('$dartName $genLocalizationsScript --cupertino'));
    expect(result,
        contains('$dartName $genLocalizationsScript --material'));
    final String generatedFile = path.join(testRootPath, 'packages', 'flutter_localizations',
        'lib', 'src', 'l10n', 'generated_material_localizations.dart');
    expect(result,
        contains('The contents of $generatedFile are different from that produced by gen_localizations.'));
    expect(result,
        contains(r'Did you forget to run gen_localizations.dart after updating a .arb file?'));
  });

  test('analyze.dart - verifyNoBinaries - negative', () async {
    await capture(() => verifyNoBinaries(
      testRootPath,
      legacyBinaries: <Hash256>{
        const Hash256(0xA8100AE6AA1940D0, 0xB663BB31CD466142, 0xEBBDBD5187131B92, 0xD93818987832EB89), // sha256("\xff")
        const Hash256(0x155644D3F13D98BF, 0, 0, 0),
      },
    ));
  });

  test('analyze.dart - verifyNullInitializedDebugExpensiveFields', () async {
    final String result = await capture(() => verifyNullInitializedDebugExpensiveFields(
      testRootPath,
      minimumMatches: 1,
    ), shouldHaveErrors: true);

    expect(result, contains(':15'));
    expect(result, isNot(contains(':12')));
  });

  test('analyze.dart - verifyTabooDocumentation', () async {
    final String result = await capture(() => verifyTabooDocumentation(
      testRootPath,
      minimumMatches: 1,
    ), shouldHaveErrors: true);

    expect(result, isNot(contains(':19')));
    expect(result, contains(':20'));
    expect(result, contains(':21'));
  });

  test('analyze.dart - clampDouble', () async {
    final String result = await capture(() => runVerifiersInResolvedDirectory(
      testRootPath,
      <ResolvedUnitVerifier>[verifyNoDoubleClamp],
    ), shouldHaveErrors: true);
    final String lines = <String>[
        '║ packages/flutter/lib/bar.dart:35: input.clamp(0.0, 2)',
        '║ packages/flutter/lib/bar.dart:36: input.toDouble().clamp(0, 2)',
        '║ packages/flutter/lib/bar.dart:40: nullableInt?.clamp(0, 2.0)',
        '║ packages/flutter/lib/bar.dart:41: nullableDouble?.clamp(0, 2)',
        '║ packages/flutter/lib/bar.dart:44: nullableInt?.clamp',
        '║ packages/flutter/lib/bar.dart:45: nullableDouble?.clamp',
        '║ ',
        '║ For performance reasons, we use a custom "clampDouble" function instead of using "double.clamp".',
        '║ For non-double uses of "clamp", use "// ignore_clamp_double_lint" on the line to silence this message.',
      ]
      .map((String line) => line.replaceAll('/', Platform.isWindows ? r'\' : '/'))
      .join('\n');
    expect(result,
      '╔═╡ERROR╞═══════════════════════════════════════════════════════════════════════\n\n'
      '$lines\n'
      '╚═══════════════════════════════════════════════════════════════════════════════\n'
    );
  });

  test('analyze.dart - debugAssert', () async {
    final String result = await capture(() => runVerifiersInResolvedDirectory(
      testRootPath,
      <ResolvedUnitVerifier>[verifyDebugAssertAccess],
    ), shouldHaveErrors: true);

    final String badAnnotations = <String>[
      '║ Overriding a framework class member that was not annotated with @_debugAssert and marking the override @_debugAssert is not allowed.',
      '║ A framework method/getter/setter not marked as debug-only itself cannot have a debug-only override.',
      '║ ',
      '║ packages/flutter/lib/debug_only_access.dart: class member BaseClass.value is not annotated wtih @_debugAssert, but its override MixinOnBaseClass.value is.',
      '║ packages/flutter/lib/debug_only_access.dart: class member BaseClass.~ is not annotated wtih @_debugAssert, but its override MixinOnBaseClass.~ is.',
      '║ packages/flutter/lib/debug_only_access.dart: class member BaseClass.run is not annotated wtih @_debugAssert, but its override ClassWithBadAnnotation1.run is.',
      '║ packages/flutter/lib/debug_only_access.dart: class member BaseClass.run is not annotated wtih @_debugAssert, but its override ClassWithBadAnnotation2.run is.',
      '║ ',
      '║ Consider either removing the @_debugAssert annotation, or adding the annotation to the class member that is being overridden instead.',
    ]
    .map((String line) => line.replaceAll('/', Platform.isWindows ? r'\' : '/'))
    .join('\n');

    final String badAccesses = <String>[
      '║ Framework symbols annotated with @_debugAssert should not be accessed outside of asserts.\n',
      '║ \n',
      '║ packages/flutter/lib/debug_only_constructors.dart:10: ClassFromDebugLibWithNamedConstructor.constructor accessed outside of an assert.\n',
      '║ packages/flutter/lib/debug_only_constructors.dart:41: _DebugOnlyClass2.new accessed outside of an assert.\n',
      '║ packages/flutter/lib/debug_only_constructors.dart:43: _DebugOnlyClass3.named accessed outside of an assert.\n',
      '║ packages/flutter/lib/debug_only_constructors.dart:55: ProductionClass31.new accessed outside of an assert.\n',
      '║ packages/flutter/lib/debug_only_constructors.dart:56: ProductionClass31.new accessed outside of an assert.\n',
      '║ packages/flutter/lib/debug_only_constructors.dart:57: ProductionClass32.new accessed outside of an assert.\n',
      '║ packages/flutter/lib/debug_only_access.dart:15: globalVaraibleFromDebugLib accessed outside of an assert.\n',
      '║ packages/flutter/lib/debug_only_access.dart:15: globalVaraibleFromDebugLib= accessed outside of an assert.\n',
      '║ packages/flutter/lib/debug_only_access.dart:16: globalFunctionFromDebugLib accessed outside of an assert.\n',
      '║ packages/flutter/lib/debug_only_access.dart:17: globalFunctionFromDebugLib accessed outside of an assert.\n',
      '║ packages/flutter/lib/debug_only_access.dart:18: globalFunctionFromDebugLib accessed outside of an assert.\n',
      '║ packages/flutter/lib/debug_only_access.dart:19: MixinFromDebugLib.staticMethodFromDebugLib accessed outside of an assert.\n',
      '║ packages/flutter/lib/debug_only_access.dart:20: MixinFromDebugLib.staticMethodFromDebugLib accessed outside of an assert.\n',
      '║ packages/flutter/lib/debug_only_access.dart:21: MixinFromDebugLib.fieldFromDebugLib accessed outside of an assert.\n',
      '║ packages/flutter/lib/debug_only_access.dart:22: MixinFromDebugLib.fieldFromDebugLib accessed outside of an assert.\n',
      '║ packages/flutter/lib/debug_only_access.dart:23: MixinFromDebugLib.debugGetSet accessed outside of an assert.\n',
      '║ packages/flutter/lib/debug_only_access.dart:24: MixinFromDebugLib.debugGetSet accessed outside of an assert.\n',
      '║ packages/flutter/lib/debug_only_access.dart:25: MixinFromDebugLib.debugGetSet= accessed outside of an assert.\n',
      '║ packages/flutter/lib/debug_only_access.dart:26: MixinFromDebugLib.debugGetSet= accessed outside of an assert.\n',
      '║ packages/flutter/lib/debug_only_access.dart:27: MixinFromDebugLib.fieldFromDebugLib accessed outside of an assert.\n',
      '║ packages/flutter/lib/debug_only_access.dart:27: MixinFromDebugLib.fieldFromDebugLib= accessed outside of an assert.\n',
      '║ packages/flutter/lib/debug_only_access.dart:27: MixinFromDebugLib.debugGetSet accessed outside of an assert.\n',
      '║ packages/flutter/lib/debug_only_access.dart:28: MixinFromDebugLib.debugGetSet accessed outside of an assert.\n',
      '║ packages/flutter/lib/debug_only_access.dart:28: MixinFromDebugLib.debugGetSet= accessed outside of an assert.\n',
      '║ packages/flutter/lib/debug_only_access.dart:28: MixinFromDebugLib.debugGetSet accessed outside of an assert.\n',
      '║ packages/flutter/lib/debug_only_access.dart:29: MixinFromDebugLib.fieldFromDebugLib accessed outside of an assert.\n',
      '║ packages/flutter/lib/debug_only_access.dart:29: MixinFromDebugLib.fieldFromDebugLib= accessed outside of an assert.\n',
      '║ packages/flutter/lib/debug_only_access.dart:29: MixinFromDebugLib.debugGetSet accessed outside of an assert.\n',
      '║ packages/flutter/lib/debug_only_access.dart:30: MixinFromDebugLib.debugGetSet accessed outside of an assert.\n',
      '║ packages/flutter/lib/debug_only_access.dart:30: MixinFromDebugLib.debugGetSet= accessed outside of an assert.\n',
      '║ packages/flutter/lib/debug_only_access.dart:30: MixinFromDebugLib.debugGetSet accessed outside of an assert.\n',
      '║ packages/flutter/lib/debug_only_access.dart:31: MixinFromDebugLib.methodFromDebugLib accessed outside of an assert.\n',
      '║ packages/flutter/lib/debug_only_access.dart:32: debugOnlyExtensionMethod accessed outside of an assert.\n',
      '║ packages/flutter/lib/debug_only_access.dart:33: debugOnlyExtensionMethod accessed outside of an assert.\n',
      '║ packages/flutter/lib/debug_only_access.dart:34: DebugOnlyEnum.foo accessed outside of an assert.\n',
      '║ packages/flutter/lib/debug_only_access.dart:35: DebugOnlyEnum.values accessed outside of an assert.\n',
      '║ packages/flutter/lib/debug_only_access.dart:36: DebugOnlyMixinOnRegularEnum.debugOnlyMethod accessed outside of an assert.\n',
      '║ packages/flutter/lib/debug_only_access.dart:39: ProductionClassWithDebugOnlyMixin.+ accessed outside of an assert.\n',
      '║ packages/flutter/lib/debug_only_access.dart:40: ProductionClassWithDebugOnlyMixin.+ accessed outside of an assert.\n',
      '║ packages/flutter/lib/debug_only_access.dart:41: ProductionClassWithDebugOnlyMixin.+ accessed outside of an assert.\n',
      '║ packages/flutter/lib/debug_only_access.dart:42: ProductionClassWithDebugOnlyMixin.+ accessed outside of an assert.\n',
      '║ packages/flutter/lib/debug_only_access.dart:43: MixinFromDebugLib.~ accessed outside of an assert.\n',
      '║ packages/flutter/lib/debug_only_access.dart:44: MixinFromDebugLib.~ accessed outside of an assert.\n',
      '║ packages/flutter/lib/debug_only_access.dart:45: MixinFromDebugLib.[] accessed outside of an assert.\n',
      '║ packages/flutter/lib/debug_only_access.dart:45: MixinFromDebugLib.debugGetSet accessed outside of an assert.\n',
      '║ packages/flutter/lib/debug_only_access.dart:46: MixinFromDebugLib.[] accessed outside of an assert.\n',
      '║ packages/flutter/lib/debug_only_access.dart:46: MixinFromDebugLib.debugGetSet accessed outside of an assert.',
    ]
    .map((String line) => line.replaceAll('/', Platform.isWindows ? r'\' : '/'))
    .join();

    expect(result,
      '╔═╡ERROR╞═══════════════════════════════════════════════════════════════════════\n'
      '$badAnnotations\n'
      '╚═══════════════════════════════════════════════════════════════════════════════\n'
      '\n'
      '╔═╡ERROR╞═══════════════════════════════════════════════════════════════════════\n'
      '$badAccesses\n'
      '╚═══════════════════════════════════════════════════════════════════════════════\n'
    );
  });
}
