// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// The following test cases contradict rule LB25, so we are replacing them
// with correct expectations.
const Map<String, String> _replacements = <String, String>{
  '× 007D ÷ 0025 ÷	#  × [0.3] RIGHT CURLY BRACKET (CL) ÷ [999.0] PERCENT SIGN (PO) ÷ [0.3]':
      '× 007D × 0025 ÷	#  × [0.3] RIGHT CURLY BRACKET (CL) × [999.0] PERCENT SIGN (PO) ÷ [0.3]',
  '× 007D × 0308 ÷ 0025 ÷	#  × [0.3] RIGHT CURLY BRACKET (CL) × [9.0] COMBINING DIAERESIS (CM1_CM) ÷ [999.0] PERCENT SIGN (PO) ÷ [0.3]':
      '× 007D × 0308 × 0025 ÷	#  × [0.3] RIGHT CURLY BRACKET (CL) × [9.0] COMBINING DIAERESIS (CM1_CM) × [999.0] PERCENT SIGN (PO) ÷ [0.3]',
  '× 007D ÷ 0024 ÷	#  × [0.3] RIGHT CURLY BRACKET (CL) ÷ [999.0] DOLLAR SIGN (PR) ÷ [0.3]':
      '× 007D × 0024 ÷	#  × [0.3] RIGHT CURLY BRACKET (CL) × [999.0] DOLLAR SIGN (PR) ÷ [0.3]',
  '× 007D × 0308 ÷ 0024 ÷	#  × [0.3] RIGHT CURLY BRACKET (CL) × [9.0] COMBINING DIAERESIS (CM1_CM) ÷ [999.0] DOLLAR SIGN (PR) ÷ [0.3]':
      '× 007D × 0308 × 0024 ÷	#  × [0.3] RIGHT CURLY BRACKET (CL) × [9.0] COMBINING DIAERESIS (CM1_CM) × [999.0] DOLLAR SIGN (PR) ÷ [0.3]',
  '× 002C ÷ 0030 ÷	#  × [0.3] COMMA (IS) ÷ [999.0] DIGIT ZERO (NU) ÷ [0.3]':
      '× 002C × 0030 ÷	#  × [0.3] COMMA (IS) × [999.0] DIGIT ZERO (NU) ÷ [0.3]',
  '× 002C × 0308 ÷ 0030 ÷	#  × [0.3] COMMA (IS) × [9.0] COMBINING DIAERESIS (CM1_CM) ÷ [999.0] DIGIT ZERO (NU) ÷ [0.3]':
      '× 002C × 0308 × 0030 ÷	#  × [0.3] COMMA (IS) × [9.0] COMBINING DIAERESIS (CM1_CM) × [999.0] DIGIT ZERO (NU) ÷ [0.3]',
  '× 0025 ÷ 2329 ÷	#  × [0.3] PERCENT SIGN (PO) ÷ [999.0] LEFT-POINTING ANGLE BRACKET (OP) ÷ [0.3]':
      '× 0025 × 2329 ÷	#  × [0.3] PERCENT SIGN (PO) × [999.0] LEFT-POINTING ANGLE BRACKET (OP) ÷ [0.3]',
  '× 0025 × 0308 ÷ 2329 ÷	#  × [0.3] PERCENT SIGN (PO) × [9.0] COMBINING DIAERESIS (CM1_CM) ÷ [999.0] LEFT-POINTING ANGLE BRACKET (OP) ÷ [0.3]':
      '× 0025 × 0308 × 2329 ÷	#  × [0.3] PERCENT SIGN (PO) × [9.0] COMBINING DIAERESIS (CM1_CM) × [999.0] LEFT-POINTING ANGLE BRACKET (OP) ÷ [0.3]',
  '× 0025 ÷ 0028 ÷	#  × [0.3] PERCENT SIGN (PO) ÷ [999.0] LEFT PARENTHESIS (OP_OP30) ÷ [0.3]':
      '× 0025 × 0028 ÷	#  × [0.3] PERCENT SIGN (PO) × [999.0] LEFT PARENTHESIS (OP_OP30) ÷ [0.3]',
  '× 0025 × 0308 ÷ 0028 ÷	#  × [0.3] PERCENT SIGN (PO) × [9.0] COMBINING DIAERESIS (CM1_CM) ÷ [999.0] LEFT PARENTHESIS (OP_OP30) ÷ [0.3]':
      '× 0025 × 0308 × 0028 ÷	#  × [0.3] PERCENT SIGN (PO) × [9.0] COMBINING DIAERESIS (CM1_CM) × [999.0] LEFT PARENTHESIS (OP_OP30) ÷ [0.3]',
  '× 0024 ÷ 2329 ÷	#  × [0.3] DOLLAR SIGN (PR) ÷ [999.0] LEFT-POINTING ANGLE BRACKET (OP) ÷ [0.3]':
      '× 0024 × 2329 ÷	#  × [0.3] DOLLAR SIGN (PR) × [999.0] LEFT-POINTING ANGLE BRACKET (OP) ÷ [0.3]',
  '× 0024 × 0308 ÷ 2329 ÷	#  × [0.3] DOLLAR SIGN (PR) × [9.0] COMBINING DIAERESIS (CM1_CM) ÷ [999.0] LEFT-POINTING ANGLE BRACKET (OP) ÷ [0.3]':
      '× 0024 × 0308 × 2329 ÷	#  × [0.3] DOLLAR SIGN (PR) × [9.0] COMBINING DIAERESIS (CM1_CM) × [999.0] LEFT-POINTING ANGLE BRACKET (OP) ÷ [0.3]',
  '× 0024 ÷ 0028 ÷	#  × [0.3] DOLLAR SIGN (PR) ÷ [999.0] LEFT PARENTHESIS (OP_OP30) ÷ [0.3]':
      '× 0024 × 0028 ÷	#  × [0.3] DOLLAR SIGN (PR) × [999.0] LEFT PARENTHESIS (OP_OP30) ÷ [0.3]',
  '× 0024 × 0308 ÷ 0028 ÷	#  × [0.3] DOLLAR SIGN (PR) × [9.0] COMBINING DIAERESIS (CM1_CM) ÷ [999.0] LEFT PARENTHESIS (OP_OP30) ÷ [0.3]':
      '× 0024 × 0308 × 0028 ÷	#  × [0.3] DOLLAR SIGN (PR) × [9.0] COMBINING DIAERESIS (CM1_CM) × [999.0] LEFT PARENTHESIS (OP_OP30) ÷ [0.3]',
  '× 002F ÷ 0030 ÷	#  × [0.3] SOLIDUS (SY) ÷ [999.0] DIGIT ZERO (NU) ÷ [0.3]':
      '× 002F × 0030 ÷	#  × [0.3] SOLIDUS (SY) × [999.0] DIGIT ZERO (NU) ÷ [0.3]',
  '× 002F × 0308 ÷ 0030 ÷	#  × [0.3] SOLIDUS (SY) × [9.0] COMBINING DIAERESIS (CM1_CM) ÷ [999.0] DIGIT ZERO (NU) ÷ [0.3]':
      '× 002F × 0308 × 0030 ÷	#  × [0.3] SOLIDUS (SY) × [9.0] COMBINING DIAERESIS (CM1_CM) × [999.0] DIGIT ZERO (NU) ÷ [0.3]',
  '× 0029 ÷ 0025 ÷	#  × [0.3] RIGHT PARENTHESIS (CP_CP30) ÷ [999.0] PERCENT SIGN (PO) ÷ [0.3]':
      '× 0029 × 0025 ÷	#  × [0.3] RIGHT PARENTHESIS (CP_CP30) × [999.0] PERCENT SIGN (PO) ÷ [0.3]',
  '× 0029 × 0308 ÷ 0025 ÷	#  × [0.3] RIGHT PARENTHESIS (CP_CP30) × [9.0] COMBINING DIAERESIS (CM1_CM) ÷ [999.0] PERCENT SIGN (PO) ÷ [0.3]':
      '× 0029 × 0308 × 0025 ÷	#  × [0.3] RIGHT PARENTHESIS (CP_CP30) × [9.0] COMBINING DIAERESIS (CM1_CM) × [999.0] PERCENT SIGN (PO) ÷ [0.3]',
  '× 0029 ÷ 0024 ÷	#  × [0.3] RIGHT PARENTHESIS (CP_CP30) ÷ [999.0] DOLLAR SIGN (PR) ÷ [0.3]':
      '× 0029 × 0024 ÷	#  × [0.3] RIGHT PARENTHESIS (CP_CP30) × [999.0] DOLLAR SIGN (PR) ÷ [0.3]',
  '× 0029 × 0308 ÷ 0024 ÷	#  × [0.3] RIGHT PARENTHESIS (CP_CP30) × [9.0] COMBINING DIAERESIS (CM1_CM) ÷ [999.0] DOLLAR SIGN (PR) ÷ [0.3]':
      '× 0029 × 0308 × 0024 ÷	#  × [0.3] RIGHT PARENTHESIS (CP_CP30) × [9.0] COMBINING DIAERESIS (CM1_CM) × [999.0] DOLLAR SIGN (PR) ÷ [0.3]',
  '× 0065 × 0071 × 0075 × 0061 × 006C × 0073 × 0020 × 002E ÷ 0033 × 0035 × 0020 ÷ 0063 × 0065 × 006E × 0074 × 0073 ÷	#  × [0.3] LATIN SMALL LETTER E (AL) × [28.0] LATIN SMALL LETTER Q (AL) × [28.0] LATIN SMALL LETTER U (AL) × [28.0] LATIN SMALL LETTER A (AL) × [28.0] LATIN SMALL LETTER L (AL) × [28.0] LATIN SMALL LETTER S (AL) × [7.01] SPACE (SP) × [13.02] FULL STOP (IS) ÷ [999.0] DIGIT THREE (NU) × [25.03] DIGIT FIVE (NU) × [7.01] SPACE (SP) ÷ [18.0] LATIN SMALL LETTER C (AL) × [28.0] LATIN SMALL LETTER E (AL) × [28.0] LATIN SMALL LETTER N (AL) × [28.0] LATIN SMALL LETTER T (AL) × [28.0] LATIN SMALL LETTER S (AL) ÷ [0.3]':
      '× 0065 × 0071 × 0075 × 0061 × 006C × 0073 × 0020 × 002E × 0033 × 0035 × 0020 ÷ 0063 × 0065 × 006E × 0074 × 0073 ÷	#  × [0.3] LATIN SMALL LETTER E (AL) × [28.0] LATIN SMALL LETTER Q (AL) × [28.0] LATIN SMALL LETTER U (AL) × [28.0] LATIN SMALL LETTER A (AL) × [28.0] LATIN SMALL LETTER L (AL) × [28.0] LATIN SMALL LETTER S (AL) × [7.01] SPACE (SP) × [13.02] FULL STOP (IS) × [999.0] DIGIT THREE (NU) × [25.03] DIGIT FIVE (NU) × [7.01] SPACE (SP) ÷ [18.0] LATIN SMALL LETTER C (AL) × [28.0] LATIN SMALL LETTER E (AL) × [28.0] LATIN SMALL LETTER N (AL) × [28.0] LATIN SMALL LETTER T (AL) × [28.0] LATIN SMALL LETTER S (AL) ÷ [0.3]',
  '× 0063 × 006F × 0064 × 0065 × 005C ÷ 0028 × 0073 × 005C × 0029 ÷	#  × [0.3] LATIN SMALL LETTER C (AL) × [28.0] LATIN SMALL LETTER O (AL) × [28.0] LATIN SMALL LETTER D (AL) × [28.0] LATIN SMALL LETTER E (AL) × [24.03] REVERSE SOLIDUS (PR) ÷ [999.0] LEFT PARENTHESIS (OP_OP30) × [14.0] LATIN SMALL LETTER S (AL) × [24.03] REVERSE SOLIDUS (PR) × [13.02] RIGHT PARENTHESIS (CP_CP30) ÷ [0.3]':
      '× 0063 × 006F × 0064 × 0065 × 005C × 0028 × 0073 × 005C × 0029 ÷	#  × [0.3] LATIN SMALL LETTER C (AL) × [28.0] LATIN SMALL LETTER O (AL) × [28.0] LATIN SMALL LETTER D (AL) × [28.0] LATIN SMALL LETTER E (AL) × [24.03] REVERSE SOLIDUS (PR) × [999.0] LEFT PARENTHESIS (OP_OP30) × [14.0] LATIN SMALL LETTER S (AL) × [24.03] REVERSE SOLIDUS (PR) × [13.02] RIGHT PARENTHESIS (CP_CP30) ÷ [0.3]',
  '× 0063 × 006F × 0064 × 0065 × 005C ÷ 007B × 0073 × 005C × 007D ÷	#  × [0.3] LATIN SMALL LETTER C (AL) × [28.0] LATIN SMALL LETTER O (AL) × [28.0] LATIN SMALL LETTER D (AL) × [28.0] LATIN SMALL LETTER E (AL) × [24.03] REVERSE SOLIDUS (PR) ÷ [999.0] LEFT CURLY BRACKET (OP_OP30) × [14.0] LATIN SMALL LETTER S (AL) × [24.03] REVERSE SOLIDUS (PR) × [13.02] RIGHT CURLY BRACKET (CL) ÷ [0.3]':
      '× 0063 × 006F × 0064 × 0065 × 005C × 007B × 0073 × 005C × 007D ÷	#  × [0.3] LATIN SMALL LETTER C (AL) × [28.0] LATIN SMALL LETTER O (AL) × [28.0] LATIN SMALL LETTER D (AL) × [28.0] LATIN SMALL LETTER E (AL) × [24.03] REVERSE SOLIDUS (PR) × [999.0] LEFT CURLY BRACKET (OP_OP30) × [14.0] LATIN SMALL LETTER S (AL) × [24.03] REVERSE SOLIDUS (PR) × [13.02] RIGHT CURLY BRACKET (CL) ÷ [0.3]',
  '× 0061 × 002E ÷ 0032 × 0020 ÷	#  × [0.3] LATIN SMALL LETTER A (AL) × [13.02] FULL STOP (IS) ÷ [999.0] DIGIT TWO (NU) × [7.01] SPACE (SP) ÷ [0.3]':
      '× 0061 × 002E × 0032 × 0020 ÷	#  × [0.3] LATIN SMALL LETTER A (AL) × [13.02] FULL STOP (IS) × [999.0] DIGIT TWO (NU) × [7.01] SPACE (SP) ÷ [0.3]',
  '× 0061 × 002E ÷ 0032 × 0020 ÷ 0915 ÷	#  × [0.3] LATIN SMALL LETTER A (AL) × [13.02] FULL STOP (IS) ÷ [999.0] DIGIT TWO (NU) × [7.01] SPACE (SP) ÷ [18.0] DEVANAGARI LETTER KA (AL) ÷ [0.3]':
      '× 0061 × 002E × 0032 × 0020 ÷ 0915 ÷	#  × [0.3] LATIN SMALL LETTER A (AL) × [13.02] FULL STOP (IS) × [999.0] DIGIT TWO (NU) × [7.01] SPACE (SP) ÷ [18.0] DEVANAGARI LETTER KA (AL) ÷ [0.3]',
  '× 0061 × 002E ÷ 0032 × 0020 ÷ 672C ÷	#  × [0.3] LATIN SMALL LETTER A (AL) × [13.02] FULL STOP (IS) ÷ [999.0] DIGIT TWO (NU) × [7.01] SPACE (SP) ÷ [18.0] CJK UNIFIED IDEOGRAPH-672C (ID) ÷ [0.3]':
      '× 0061 × 002E × 0032 × 0020 ÷ 672C ÷	#  × [0.3] LATIN SMALL LETTER A (AL) × [13.02] FULL STOP (IS) × [999.0] DIGIT TWO (NU) × [7.01] SPACE (SP) ÷ [18.0] CJK UNIFIED IDEOGRAPH-672C (ID) ÷ [0.3]',
  '× 0061 × 002E ÷ 0032 × 3000 ÷ 672C ÷	#  × [0.3] LATIN SMALL LETTER A (AL) × [13.02] FULL STOP (IS) ÷ [999.0] DIGIT TWO (NU) × [21.01] IDEOGRAPHIC SPACE (BA) ÷ [999.0] CJK UNIFIED IDEOGRAPH-672C (ID) ÷ [0.3]':
      '× 0061 × 002E × 0032 × 3000 ÷ 672C ÷	#  × [0.3] LATIN SMALL LETTER A (AL) × [13.02] FULL STOP (IS) × [999.0] DIGIT TWO (NU) × [21.01] IDEOGRAPHIC SPACE (BA) ÷ [999.0] CJK UNIFIED IDEOGRAPH-672C (ID) ÷ [0.3]',
  '× 0061 × 002E ÷ 0032 × 3000 ÷ 307E ÷	#  × [0.3] LATIN SMALL LETTER A (AL) × [13.02] FULL STOP (IS) ÷ [999.0] DIGIT TWO (NU) × [21.01] IDEOGRAPHIC SPACE (BA) ÷ [999.0] HIRAGANA LETTER MA (ID) ÷ [0.3]':
      '× 0061 × 002E × 0032 × 3000 ÷ 307E ÷	#  × [0.3] LATIN SMALL LETTER A (AL) × [13.02] FULL STOP (IS) × [999.0] DIGIT TWO (NU) × [21.01] IDEOGRAPHIC SPACE (BA) ÷ [999.0] HIRAGANA LETTER MA (ID) ÷ [0.3]',
  '× 0061 × 002E ÷ 0032 × 3000 ÷ 0033 ÷	#  × [0.3] LATIN SMALL LETTER A (AL) × [13.02] FULL STOP (IS) ÷ [999.0] DIGIT TWO (NU) × [21.01] IDEOGRAPHIC SPACE (BA) ÷ [999.0] DIGIT THREE (NU) ÷ [0.3]':
      '× 0061 × 002E × 0032 × 3000 ÷ 0033 ÷	#  × [0.3] LATIN SMALL LETTER A (AL) × [13.02] FULL STOP (IS) × [999.0] DIGIT TWO (NU) × [21.01] IDEOGRAPHIC SPACE (BA) ÷ [999.0] DIGIT THREE (NU) ÷ [0.3]',
  '× 0041 × 002E ÷ 0031 × 0020 ÷ BABB ÷	#  × [0.3] LATIN CAPITAL LETTER A (AL) × [13.02] FULL STOP (IS) ÷ [999.0] DIGIT ONE (NU) × [7.01] SPACE (SP) ÷ [18.0] HANGUL SYLLABLE MOS (H3) ÷ [0.3]':
      '× 0041 × 002E × 0031 × 0020 ÷ BABB ÷	#  × [0.3] LATIN CAPITAL LETTER A (AL) × [13.02] FULL STOP (IS) × [999.0] DIGIT ONE (NU) × [7.01] SPACE (SP) ÷ [18.0] HANGUL SYLLABLE MOS (H3) ÷ [0.3]',
  '× BD24 ÷ C5B4 × 002E × 0020 ÷ 0041 × 002E ÷ 0032 × 0020 ÷ BCFC ÷	#  × [0.3] HANGUL SYLLABLE BWASS (H3) ÷ [999.0] HANGUL SYLLABLE EO (H2) × [13.02] FULL STOP (IS) × [7.01] SPACE (SP) ÷ [18.0] LATIN CAPITAL LETTER A (AL) × [13.02] FULL STOP (IS) ÷ [999.0] DIGIT TWO (NU) × [7.01] SPACE (SP) ÷ [18.0] HANGUL SYLLABLE BOL (H3) ÷ [0.3]':
      '× BD24 ÷ C5B4 × 002E × 0020 ÷ 0041 × 002E × 0032 × 0020 ÷ BCFC ÷	#  × [0.3] HANGUL SYLLABLE BWASS (H3) ÷ [999.0] HANGUL SYLLABLE EO (H2) × [13.02] FULL STOP (IS) × [7.01] SPACE (SP) ÷ [18.0] LATIN CAPITAL LETTER A (AL) × [13.02] FULL STOP (IS) × [999.0] DIGIT TWO (NU) × [7.01] SPACE (SP) ÷ [18.0] HANGUL SYLLABLE BOL (H3) ÷ [0.3]',
  '× BD10 ÷ C694 × 002E × 0020 ÷ 0041 × 002E ÷ 0033 × 0020 ÷ BABB ÷	#  × [0.3] HANGUL SYLLABLE BWA (H2) ÷ [999.0] HANGUL SYLLABLE YO (H2) × [13.02] FULL STOP (IS) × [7.01] SPACE (SP) ÷ [18.0] LATIN CAPITAL LETTER A (AL) × [13.02] FULL STOP (IS) ÷ [999.0] DIGIT THREE (NU) × [7.01] SPACE (SP) ÷ [18.0] HANGUL SYLLABLE MOS (H3) ÷ [0.3]':
      '× BD10 ÷ C694 × 002E × 0020 ÷ 0041 × 002E × 0033 × 0020 ÷ BABB ÷	#  × [0.3] HANGUL SYLLABLE BWA (H2) ÷ [999.0] HANGUL SYLLABLE YO (H2) × [13.02] FULL STOP (IS) × [7.01] SPACE (SP) ÷ [18.0] LATIN CAPITAL LETTER A (AL) × [13.02] FULL STOP (IS) × [999.0] DIGIT THREE (NU) × [7.01] SPACE (SP) ÷ [18.0] HANGUL SYLLABLE MOS (H3) ÷ [0.3]',
  '× C694 × 002E × 0020 ÷ 0041 × 002E ÷ 0034 × 0020 ÷ BABB ÷	#  × [0.3] HANGUL SYLLABLE YO (H2) × [13.02] FULL STOP (IS) × [7.01] SPACE (SP) ÷ [18.0] LATIN CAPITAL LETTER A (AL) × [13.02] FULL STOP (IS) ÷ [999.0] DIGIT FOUR (NU) × [7.01] SPACE (SP) ÷ [18.0] HANGUL SYLLABLE MOS (H3) ÷ [0.3]':
      '× C694 × 002E × 0020 ÷ 0041 × 002E × 0034 × 0020 ÷ BABB ÷	#  × [0.3] HANGUL SYLLABLE YO (H2) × [13.02] FULL STOP (IS) × [7.01] SPACE (SP) ÷ [18.0] LATIN CAPITAL LETTER A (AL) × [13.02] FULL STOP (IS) × [999.0] DIGIT FOUR (NU) × [7.01] SPACE (SP) ÷ [18.0] HANGUL SYLLABLE MOS (H3) ÷ [0.3]',
  '× 0061 × 002E ÷ 0032 × 3000 ÷ 300C ÷	#  × [0.3] LATIN SMALL LETTER A (AL) × [13.02] FULL STOP (IS) ÷ [999.0] DIGIT TWO (NU) × [21.01] IDEOGRAPHIC SPACE (BA) ÷ [999.0] LEFT CORNER BRACKET (OP) ÷ [0.3]':
      '× 0061 × 002E × 0032 × 3000 ÷ 300C ÷	#  × [0.3] LATIN SMALL LETTER A (AL) × [13.02] FULL STOP (IS) × [999.0] DIGIT TWO (NU) × [21.01] IDEOGRAPHIC SPACE (BA) ÷ [999.0] LEFT CORNER BRACKET (OP) ÷ [0.3]',
};

/// Parses raw test data into a list of [TestCase] objects.
List<TestCase> parseRawTestData(String rawTestData) {
  return rawTestData
      .split('\n')
      .where(isValidTestCase)
      .map(_checkReplacement)
      .map(_parse)
      .toList();
}

bool isValidTestCase(String line) {
  return line.startsWith('×');
}

String _checkReplacement(String line) {
  String replacement = _replacements[line] ?? line;
  // Special case for rule LB13 to allow line breaks after spaces.
  if (replacement.contains('SPACE (SP) × [13.')) {
    replacement = replacement
        .replaceAll('0020 ×', '0020 ÷')
        .replaceFirst('SPACE (SP) × [13.', 'SPACE (SP) ÷ [13.');
  }
  // Special case for rule LB14 to allow line breaks after spaces.
  if (replacement.contains('SPACE (SP) × [14.')) {
    replacement = replacement
        .replaceAll('0020 ×', '0020 ÷')
        .replaceAll('SPACE (SP) × [14.', 'SPACE (SP) ÷ [14.');
  }
  // Special case for rule LB15 to allow line breaks after spaces.
  if (replacement.contains('SPACE (SP) × [15.')) {
    replacement = replacement
        .replaceAll('0020 ×', '0020 ÷')
        .replaceAll('SPACE (SP) × [15.', 'SPACE (SP) ÷ [15.');
  }
  return replacement;
}

final RegExp spaceRegex = RegExp(r'\s+');
final RegExp signRegex = RegExp(r'([×÷])\s+\[(\d+\.\d+)\]\s*');
final RegExp charRegex = RegExp(
  r'([A-Z0-9-]+(?:\s+[A-Z0-9-]+)*)\s+\(([A-Z0-9_]+)\)\s*',
  caseSensitive: false,
);
final RegExp charWithBracketsRegex = RegExp(
  r'(\<[A-Z0-9()-]+(?:\s+[A-Z0-9()-]+)*\>)\s+\(([A-Z0-9_]+)\)\s*',
  caseSensitive: false,
);

TestCase _parse(String line) {
  final int hashIndex = line.indexOf('#');
  final List<String> sequence =
      line.substring(0, hashIndex).trim().split(spaceRegex);
  final String explanation = line.substring(hashIndex + 1).trim();

  final List<Sign> signs = <Sign>[];
  final Match signMatch = signRegex.matchAsPrefix(explanation)!;
  signs.add(Sign._(code: signMatch.group(1)!, rule: signMatch.group(2)!));

  final List<Char> chars = <Char>[];

  int i = signMatch.group(0)!.length;
  while (i < explanation.length) {
    final Match charMatch = explanation[i] == '<'
        ? charWithBracketsRegex.matchAsPrefix(explanation, i)!
        : charRegex.matchAsPrefix(explanation, i)!;
    final int charCode = int.parse(sequence[2 * chars.length + 1], radix: 16);
    chars.add(Char._(
      code: charCode,
      name: charMatch.group(1)!,
      property: charMatch.group(2)!,
    ));
    i += charMatch.group(0)!.length;

    final Match signMatch = signRegex.matchAsPrefix(explanation, i)!;
    signs.add(Sign._(code: signMatch.group(1)!, rule: signMatch.group(2)!));
    i += signMatch.group(0)!.length;
  }
  return TestCase._(signs: signs, chars: chars, raw: line);
}

/// Represents a character in a test case.
///
/// The character has a code, name and a property that determines how it behaves
/// with regards to line breaks.
class Char {
  Char._({required this.code, required this.name, required this.property});

  final int code;
  final String name;
  final String property;

  /// Whether this character is a code point that gets encoded as a UTF-16
  /// surrogate pair.
  bool get isSurrogatePair => code > 0xFFFF;
}

/// Represents a sign between two characters in a test case.
///
/// The sign could either be "×" to indicate no line break, or "÷" to indicate
/// the existence of a line break opportunity.
class Sign {
  Sign._({required this.code, required this.rule});

  final String code;
  final String rule;

  bool get isBreakOpportunity => code == '÷';
}

/// Represents an entire test case.
///
/// A test case is a sequence of characters combined with signs between them.
/// The signs indicate where line break opportunities exist.
class TestCase {
  TestCase._({required this.signs, required this.chars, required this.raw});

  final List<Sign> signs;
  final List<Char> chars;
  final String raw;

  Iterable<int> get charCodes => chars.map((Char char) => char.code);

  /// Returns the text that this test case is covering.
  String toText() {
    return String.fromCharCodes(charCodes);
  }

  @override
  String toString() {
    return raw;
  }
}
