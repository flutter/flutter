// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;

import '../analyze.dart';
import '../utils.dart';
import 'common.dart';

typedef AsyncVoidCallback = Future<void> Function();

Future<String> capture(AsyncVoidCallback callback, {bool shouldHaveErrors = false}) async {
  final buffer = StringBuffer();
  final PrintCallback oldPrint = print;
  try {
    print = (Object? line) {
      buffer.writeln(line);
    };
    await callback();
    expect(
      hasError,
      shouldHaveErrors,
      reason: buffer.isEmpty
          ? '(No output to report.)'
          : hasError
          ? 'Unexpected errors:\n$buffer'
          : 'Unexpected success:\n$buffer',
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
  final dartName = Platform.isWindows ? 'dart.exe' : 'dart';
  final String dartPath = path.canonicalize(
    path.join('..', '..', 'bin', 'cache', 'dart-sdk', 'bin', dartName),
  );

  test('matchesErrorsInFile matcher basic test', () async {
    final String result = await capture(() async {
      foundError(<String>[
        'meta.dart:5: error #1',
        'meta.dart:5: error #2',
        'meta.dart:6: error #3',
        '',
        'Error summary',
      ]);
    }, shouldHaveErrors: true);
    final fixture = File(path.join(testRootPath, 'packages', 'foo', 'meta.dart'));
    expect(result, matchesErrorsInFile(fixture, endsWith: <String>['', 'Error summary']));
  });

  test('analyze.dart - verifyNoMissingLicense', () async {
    final String result = await capture(
      () => verifyNoMissingLicense(testRootPath, checkMinimums: false),
      shouldHaveErrors: true,
    );
    final String file = 'test/analyze-test-input/root/packages/foo/foo.dart'.replaceAll(
      '/',
      Platform.isWindows ? r'\' : '/',
    );
    expect(
      result,
      '╔═╡ERROR #1╞════════════════════════════════════════════════════════════════════\n'
      '║ The following file does not have the right license header for dart files:\n'
      '║   $file\n'
      '║ The expected license header is:\n'
      '║ // Copyright 2014 The Flutter Authors. All rights reserved.\n'
      '║ // Use of this source code is governed by a BSD-style license that can be\n'
      '║ // found in the LICENSE file.\n'
      '║ ...followed by a blank line.\n'
      '╚═══════════════════════════════════════════════════════════════════════════════\n',
    );
  });

  test('analyze.dart - verifyNoTrailingSpaces', () async {
    final String result = await capture(
      () => verifyNoTrailingSpaces(testRootPath, minimumMatches: 2),
      shouldHaveErrors: true,
    );
    final String lines = <String>[
      '║ test/analyze-test-input/root/packages/foo/spaces.txt:5: trailing U+0020 space character',
      '║ test/analyze-test-input/root/packages/foo/spaces.txt:9: trailing blank line',
    ].map((String line) => line.replaceAll('/', Platform.isWindows ? r'\' : '/')).join('\n');
    expect(
      result,
      '╔═╡ERROR #1╞════════════════════════════════════════════════════════════════════\n'
      '$lines\n'
      '╚═══════════════════════════════════════════════════════════════════════════════\n',
    );
  });

  test('analyze.dart - verifyNoBinaries - positive', () async {
    final String result = await capture(
      () => verifyNoBinaries(
        testRootPath,
        legacyBinaries: <Hash256>{const Hash256(0x39A050CD69434936, 0, 0, 0)},
      ),
      shouldHaveErrors: !Platform.isWindows,
    );
    if (!Platform.isWindows) {
      expect(
        result,
        '╔═╡ERROR #1╞════════════════════════════════════════════════════════════════════\n'
        '║ test/analyze-test-input/root/packages/foo/serviceaccount.enc:0: file is not valid UTF-8\n'
        '║ All files in this repository must be UTF-8. In particular, images and other binaries\n'
        '║ must not be checked into this repository. This is because we are very sensitive to the\n'
        '║ size of the repository as it is distributed to all our developers. If you have a binary\n'
        '║ to which you need access, you should consider how to fetch it from another repository;\n'
        '║ for example, the "assets-for-api-docs" repository is used for images in API docs.\n'
        '║ To add assets to flutter_tools templates, see the instructions in the wiki:\n'
        '║ https://github.com/flutter/flutter/blob/main/docs/tool/Managing-template-image-assets.md\n'
        '╚═══════════════════════════════════════════════════════════════════════════════\n',
      );
    }
  });

  test('analyze.dart - verifyInternationalizations - comparison fails', () async {
    final String result = await capture(
      () => verifyInternationalizations(testRootPath, dartPath),
      shouldHaveErrors: true,
    );
    final String genLocalizationsScript = path.join(
      'dev',
      'tools',
      'localization',
      'bin',
      'gen_localizations.dart',
    );
    expect(result, contains('$dartName $genLocalizationsScript --cupertino'));
    expect(result, contains('$dartName $genLocalizationsScript --material'));
    final String generatedFile = path.join(
      testRootPath,
      'packages',
      'flutter_localizations',
      'lib',
      'src',
      'l10n',
      'generated_material_localizations.dart',
    );
    expect(
      result,
      contains(
        'The contents of $generatedFile are different from that produced by gen_localizations.',
      ),
    );
    expect(
      result,
      contains(r'Did you forget to run gen_localizations.dart after updating a .arb file?'),
    );
  });

  test('analyze.dart - verifyNoBinaries - negative', () async {
    await capture(
      () => verifyNoBinaries(
        testRootPath,
        legacyBinaries: <Hash256>{
          const Hash256(
            0xA8100AE6AA1940D0,
            0xB663BB31CD466142,
            0xEBBDBD5187131B92,
            0xD93818987832EB89,
          ), // sha256("\xff")
          const Hash256(0x155644D3F13D98BF, 0, 0, 0),
        },
      ),
    );
  });

  test('analyze.dart - help flag', () async {
    final String result = await capture(() async {
      await run(<String>['-h']);
    });
    expect(result, contains('Usage: dart dev/bots/analyze.dart [arguments]'));
    expect(result, contains('Options:'));
    expect(result, contains('Available rules:'));
  });

  test('analyze.dart - --only flag', () async {
    final executed = <String>[];
    final dummyValidations = <Validation>[
      Validation('rule1', 'Rule 1', () async {
        executed.add('rule1');
      }),
      Validation('rule2', 'Rule 2', () async {
        executed.add('rule2');
      }),
    ];

    await capture(() async {
      await run(<String>['--only=rule1'], validationsForTesting: dummyValidations);
    });

    expect(executed, <String>['rule1']);
  });

  test('analyze.dart - --skip flag', () async {
    final executed = <String>[];
    final dummyValidations = <Validation>[
      Validation('rule1', 'Rule 1', () async {
        executed.add('rule1');
      }),
      Validation('rule2', 'Rule 2', () async {
        executed.add('rule2');
      }),
    ];

    await capture(() async {
      await run(<String>['--skip=rule1'], validationsForTesting: dummyValidations);
    });

    expect(executed, <String>['rule2']);
  });

  test('analyze.dart - --only and --skip mutually exclusive', () async {
    final dummyValidations = <Validation>[Validation('rule1', 'Rule 1', () async {})];

    final String result = await capture(() async {
      await run(<String>['--only=rule1', '--skip=rule1'], validationsForTesting: dummyValidations);
    }, shouldHaveErrors: true);

    expect(result, contains('Cannot use both --only and --skip at the same time.'));
  });

  test('analyze.dart - invalid rule name', () async {
    final dummyValidations = <Validation>[Validation('rule1', 'Rule 1', () async {})];

    final String result = await capture(() async {
      await run(<String>['--only=invalid'], validationsForTesting: dummyValidations);
    }, shouldHaveErrors: true);

    expect(result, contains('Unknown rule "invalid" passed to --only.'));
  });

  test('analyze.dart - --only flag with multiple comma-separated values', () async {
    final executed = <String>[];
    final dummyValidations = <Validation>[
      Validation('rule1', 'Rule 1', () async {
        executed.add('rule1');
      }),
      Validation('rule2', 'Rule 2', () async {
        executed.add('rule2');
      }),
      Validation('rule3', 'Rule 3', () async {
        executed.add('rule3');
      }),
    ];

    await capture(() async {
      await run(<String>['--only=rule1,rule3'], validationsForTesting: dummyValidations);
    });

    expect(executed, <String>['rule1', 'rule3']);
  });

  test('analyze.dart - --skip flag with multiple comma-separated values', () async {
    final executed = <String>[];
    final dummyValidations = <Validation>[
      Validation('rule1', 'Rule 1', () async {
        executed.add('rule1');
      }),
      Validation('rule2', 'Rule 2', () async {
        executed.add('rule2');
      }),
      Validation('rule3', 'Rule 3', () async {
        executed.add('rule3');
      }),
    ];

    await capture(() async {
      await run(<String>['--skip=rule1,rule3'], validationsForTesting: dummyValidations);
    });

    expect(executed, <String>['rule2']);
  });

  test('analyze.dart - --only flag passed multiple times errors', () async {
    final dummyValidations = <Validation>[Validation('rule1', 'Rule 1', () async {})];

    final String result = await capture(() async {
      await run(<String>['--only=rule1', '--only=rule1'], validationsForTesting: dummyValidations);
    }, shouldHaveErrors: true);

    expect(result, contains('The --only argument must not be used more than once.'));
  });

  test('analyze.dart - --skip flag passed multiple times errors', () async {
    final dummyValidations = <Validation>[Validation('rule1', 'Rule 1', () async {})];

    final String result = await capture(() async {
      await run(<String>['--skip=rule1', '--skip=rule1'], validationsForTesting: dummyValidations);
    }, shouldHaveErrors: true);

    expect(result, contains('The --skip argument must not be used more than once.'));
  });
}
