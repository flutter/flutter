// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dartdoc/dartdoc_directive_info.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DartdocDirectiveInfoTest);
  });
}

@reflectiveTest
class DartdocDirectiveInfoTest {
  DartdocDirectiveInfo info = DartdocDirectiveInfo();

  test_processDartdoc_animation_directive() {
    var result = info.processDartdoc('''
/// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_bounce_in.mp4}
''');
    expect(
        result.full,
        '[flutter.github.io/assets-for-api-docs/assets/animation/curve_bounce_in.mp4]'
        '(https://flutter.github.io/assets-for-api-docs/assets/animation/curve_bounce_in.mp4)');
  }

  test_processDartdoc_macro_defined() {
    info.extractTemplate('''
/**
 * {@template foo}
 * Body of the
 * template.
 * {@endtemplate}
 */''');
    var result = info.processDartdoc('''
/**
 * Before macro.
 * {@macro foo}
 * After macro.
 */''');
    expect(result.full, '''
Before macro.
Body of the
template.
After macro.''');
  }

  test_processDartdoc_macro_undefined() {
    var result = info.processDartdoc('''
/**
 * {@macro foo}
 */''');
    expect(result.full, '''
{@macro foo}''');
  }

  test_processDartdoc_multiple() {
    info.extractTemplate('''
/**
 * {@template foo}
 * First template.
 * {@endtemplate}
 */''');
    info.extractTemplate('''
/// {@template bar}
/// Second template.
/// {@endtemplate}''');
    var result = info.processDartdoc('''
/**
 * Before macro.
 * {@macro foo}
 * Between macros.
 * {@macro bar}
 * After macro.
 */''');
    expect(result.full, '''
Before macro.
First template.
Between macros.
Second template.
After macro.''');
  }

  test_processDartdoc_noMacro() {
    var result = info.processDartdoc('''
/**
 * Comment without a macro.
 */''');
    expect(result.full, '''
Comment without a macro.''');
  }

  test_processDartdoc_summary_different() {
    var result = info.processDartdoc('''
/// Comment without a macro.
///
/// Has content after summary.
''', includeSummary: true) as DocumentationWithSummary;
    expect(result.full, '''
Comment without a macro.

Has content after summary.''');
    expect(result.summary, '''
Comment without a macro.''');
  }

  test_processDartdoc_summary_same() {
    var result = info.processDartdoc('''
/// Comment without a macro.
''', includeSummary: true) as DocumentationWithSummary;
    expect(result.full, '''
Comment without a macro.''');
    expect(result.summary, '''
Comment without a macro.''');
  }

  test_processDartdoc_youtube_directive() {
    var result = info.processDartdoc('''
/// {@youtube 560 315 https://www.youtube.com/watch?v=2uaoEDOgk_I}
''');
    expect(result.full, '''
[www.youtube.com/watch?v=2uaoEDOgk_I](https://www.youtube.com/watch?v=2uaoEDOgk_I)''');
  }

  test_processDartdoc_youtube_malformed() {
    var result = info.processDartdoc('''
/// {@youtube 560x315 https://www.youtube.com/watch?v=2uaoEDOgk_I}
''');
    expect(result.full,
        '{@youtube 560x315 https://www.youtube.com/watch?v=2uaoEDOgk_I}');
  }
}
