// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io' as io;

import 'package:test/test.dart';

import '../bin/merge_changelog.dart' as merge_changelog;

const String _preamble = '''
Header text.

<!--
INTERNAL NOTE
-->

''';

void main() {
  test('preserves older minor hotfixes on master when stable promotes a new minor', () {
    const master =
        '$_preamble'
        '## Flutter 3.47 Changes\n\n'
        '### [3.47.9](https://github.com/flutter/flutter/releases/tag/3.47.9)\n'
        '- [flutter/194570](https://github.com/flutter/flutter/issues/194570) Fix MAX_PATH crash.\n\n'
        '### [3.47.8](https://github.com/flutter/flutter/releases/tag/3.47.8)\n'
        '#### Security advisory GHSA-frr6-h895-5pxp:\n'
        '- [dart/568000](https://dart-review.googlesource.com/c/sdk/+/568000) BoringSSL update.\n\n'
        '### [3.47.7](https://github.com/flutter/flutter/releases/tag/3.47.7)\n'
        '- [flutter/182604](https://github.com/flutter/flutter/issues/182604) Fix OverlayPortal.\n';

    const stable =
        '$_preamble'
        '## Flutter 3.50 Changes\n\n'
        '### [3.50.1](https://github.com/flutter/flutter/releases/tag/3.50.1)\n'
        '- [flutter/196412](https://github.com/flutter/flutter/issues/196412) Fix Gradle buildType.\n\n'
        '### [3.50.0](https://github.com/flutter/flutter/releases/tag/3.50.0)\n\n'
        "Learn about what's new in 3.50.\n\n\n"
        '## Flutter 3.47 Changes\n\n'
        '### [3.47.7](https://github.com/flutter/flutter/releases/tag/3.47.7)\n'
        '- [flutter/182604](https://github.com/flutter/flutter/issues/182604) Fix OverlayPortal.\n';

    final String merged = merge_changelog.mergeChangelogs(master, stable);
    expect(merged, contains('### [3.50.1]'));
    expect(merged, contains('### [3.50.0]'));
    expect(merged, contains('### [3.47.9]'));
    expect(merged, contains('### [3.47.8]'));
    expect(merged, contains('GHSA-frr6-h895-5pxp'));
    expect(merged, contains('### [3.47.7]'));
    expect(
      merged.indexOf('## Flutter 3.50 Changes'),
      lessThan(merged.indexOf('## Flutter 3.47 Changes')),
    );
    expect(merged.indexOf('### [3.47.9]'), lessThan(merged.indexOf('### [3.47.8]')));
    expect(merged.indexOf('### [3.47.8]'), lessThan(merged.indexOf('### [3.47.7]')));

    // Re-running with the same stable input is a no-op.
    expect(merge_changelog.mergeChangelogs(merged, stable), equals(merged));

    // Subsequent dot release (3.50.2) + wording edit in 3.50.1 updates cleanly without duplicating bullets.
    final String stable3502 = stable
        .replaceFirst(
          '## Flutter 3.50 Changes\n\n### [3.50.1]',
          '## Flutter 3.50 Changes\n\n'
              '### [3.50.2](https://github.com/flutter/flutter/releases/tag/3.50.2)\n'
              '- [flutter/199999](https://github.com/flutter/flutter/issues/199999) Fix 3.50.2 issue.\n\n'
              '### [3.50.1]',
        )
        .replaceFirst('Fix Gradle buildType.', 'Fix Android Gradle buildType.');

    final String merged3502 = merge_changelog.mergeChangelogs(merged, stable3502);
    expect(merged3502, contains('### [3.50.2]'));
    expect(merged3502, contains('Fix Android Gradle buildType.'));
    expect(merged3502, isNot(contains('Fix Gradle buildType.')));
    expect(merged3502, contains('### [3.47.9]'));
    expect(merged3502, contains('### [3.47.8]'));
  });

  test('orders disjoint and multi-digit patches numerically in descending semver order', () {
    const master =
        '$_preamble'
        '## Flutter 3.47 Changes\n\n'
        '### [3.47.9](https://github.com/flutter/flutter/releases/tag/3.47.9)\n'
        '- Patch 9.\n\n'
        '### [3.47.2](https://github.com/flutter/flutter/releases/tag/3.47.2)\n'
        '- Patch 2.\n';

    const stable =
        '$_preamble'
        '## Flutter 3.47 Changes\n\n'
        '### [3.47.10](https://github.com/flutter/flutter/releases/tag/3.47.10)\n'
        '- Patch 10.\n\n'
        '### [3.47.8](https://github.com/flutter/flutter/releases/tag/3.47.8)\n'
        '- Patch 8.\n';

    final String merged = merge_changelog.mergeChangelogs(master, stable);
    expect(merged.indexOf('### [3.47.10]'), lessThan(merged.indexOf('### [3.47.9]')));
    expect(merged.indexOf('### [3.47.9]'), lessThan(merged.indexOf('### [3.47.8]')));
    expect(merged.indexOf('### [3.47.8]'), lessThan(merged.indexOf('### [3.47.2]')));
  });

  test('rejects malformed H1, H2, H4 semver, and duplicate patch headings', () {
    const good =
        '$_preamble## Flutter 3.50 Changes\n\n### [3.50.0](https://example.com)\n- Initial.\n';
    const badH2 = '$_preamble## [3.50.1](https://example.com)\n- Typo H2 instead of H3.\n';
    const badH1 = '$_preamble# [3.50.1](https://example.com)\n- Typo H1.\n';
    const badH4 =
        '$_preamble## Flutter 3.50 Changes\n\n#### [3.50.1](https://example.com)\n- Typo H4.\n';
    const dupPatch =
        '$_preamble## Flutter 3.47 Changes\n\n'
        '### [3.47.5](https://example.com)\n- First.\n\n'
        '### [3.47.5](https://example.com)\n- Duplicate.\n';

    for (final bad in <String>[badH2, badH1, badH4]) {
      expect(
        () => merge_changelog.mergeChangelogs(good, bad),
        throwsA(
          isA<FormatException>().having(
            (FormatException e) => e.message,
            'message',
            contains('Unexpected heading'),
          ),
        ),
      );
    }

    expect(
      () => merge_changelog.mergeChangelogs(good, dupPatch),
      throwsA(
        isA<FormatException>().having(
          (FormatException e) => e.message,
          'message',
          contains('Duplicate patch heading'),
        ),
      ),
    );
  });

  test('does not revert master wording when premature stable cut lags behind master', () {
    const master =
        '$_preamble'
        '## Flutter 3.44 Changes\n\n'
        '### [3.44.7](https://example.com)\n- Patch 7.\n\n'
        '### [3.44.5](https://example.com)\n- Fixed URL issues/188718.\n';

    const staleStable =
        '$_preamble'
        '## Flutter 3.44 Changes\n\n'
        '### [3.44.5](https://example.com)\n- Old broken URL issues/186100.\n';

    final String merged = merge_changelog.mergeChangelogs(master, staleStable);
    expect(merged, equals(master));
  });

  test('handles missing trailing EOF newlines and ignores headings in fences and comments', () {
    const masterNoEofNewline =
        '$_preamble'
        '## Flutter 3.47 Changes\n\n'
        '### [3.47.9](https://example.com)\n'
        '- Fix example:\n'
        '```markdown\n'
        '## Not a minor section\n'
        '### [9.9.9](https://example.com)\n'
        '```\n'
        '<!--\n'
        '## Flutter 1.0 Changes\n'
        '### [1.0.0](https://example.com)\n'
        '-->\n'
        '- Final bullet without trailing newline.';

    const stable =
        '$_preamble'
        '## Flutter 3.50 Changes\n\n'
        '### [3.50.0](https://example.com)\n- Initial.\n\n'
        '## Flutter 3.44 Changes\n\n'
        '### [3.44.0](https://example.com)\n- Older.';

    final String merged = merge_changelog.mergeChangelogs(masterNoEofNewline, stable);
    expect(merged, contains('- Final bullet without trailing newline.\n## Flutter 3.44 Changes'));
    expect(merged, contains('### [9.9.9]'));
    expect(merge_changelog.mergeChangelogs(merged, stable), equals(merged));
  });

  test('normalizes CRLF inputs and writes LF output without stray CR characters', () {
    final String masterCrlf =
        '\uFEFF$_preamble'
                '## Flutter 3.47 Changes\n\n'
                '### [3.47.9](https://github.com/flutter/flutter/releases/tag/3.47.9)\n'
                '- Patch 9.\n'
            .replaceAll('\n', '\r\n');
    final String stableCrlf =
        '$_preamble'
                '## Flutter 3.47 Changes\n\n'
                '### [3.47.8](https://github.com/flutter/flutter/releases/tag/3.47.8)\n'
                '- Patch 8.\n'
            .replaceAll('\n', '\r\n');

    final String merged = merge_changelog.mergeChangelogs(masterCrlf, stableCrlf);
    expect(merged, isNot(contains('\r')));
    expect(merged, isNot(startsWith('\uFEFF')));
    expect(merged.indexOf('### [3.47.9]'), lessThan(merged.indexOf('### [3.47.8]')));

    final io.Directory tmpDir = io.Directory.systemTemp.createTempSync('merge_changelog_test.');
    addTearDown(() => tmpDir.deleteSync(recursive: true));

    final masterFile = io.File('${tmpDir.path}/master.md')
      ..writeAsBytesSync(utf8.encode(masterCrlf));
    final stableFile = io.File('${tmpDir.path}/stable.md')
      ..writeAsBytesSync(utf8.encode(stableCrlf));

    final int exitCode = merge_changelog.run(<String>[masterFile.path, stableFile.path]);
    expect(exitCode, 0);
    expect(masterFile.readAsBytesSync(), isNot(contains(0x0D)));

    final errBuffer = StringBuffer();
    expect(merge_changelog.run(const <String>[], errSink: errBuffer), 2);
    expect(errBuffer.toString(), contains('Usage:'));
  });
}
