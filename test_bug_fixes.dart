/// Test file to verify Bug #1 and Bug #4 fixes
///
/// Bug #1: Grammatical error in xcresult.dart warning message
/// - Original: "it was failed to be parsed"
/// - Fixed: "it failed to be parsed"
///
/// Bug #4: Divide by zero in unit_coverage.dart
/// - The Coverage.percentage getter now checks if totalLines == 0

import 'dart:io';

void main() {
  print('🔍 Testing Bug Fixes...\n');

  testBug1GrammarFix();
  testBug4DivideByZeroFix();

  print('\n✅ All tests passed!');
}

/// Test Bug #1: Verify grammar fix in xcresult warning message
void testBug1GrammarFix() {
  print('📝 Bug #1: Grammar Fix Test');

  // Read the xcresult.dart file
  final File xcresultFile = File(
    'packages/flutter_tools/lib/src/ios/xcresult.dart'
  );

  if (!xcresultFile.existsSync()) {
    print('❌ xcresult.dart file not found');
    exit(1);
  }

  final String content = xcresultFile.readAsStringSync();

  // Check that the CORRECT grammar is present
  if (content.contains('it failed to be parsed')) {
    print('✅ Found correct grammar: "it failed to be parsed"');
  } else {
    print('❌ Correct grammar NOT found');
    exit(1);
  }

  // Check that the OLD (incorrect) grammar is NOT present
  if (!content.contains('it was failed to be parsed')) {
    print('✅ Old incorrect grammar removed: "it was failed to be parsed"');
  } else {
    print('❌ Old incorrect grammar still present');
    exit(1);
  }

  print('✓ Bug #1 test passed\n');
}

/// Test Bug #4: Verify divide-by-zero protection in unit_coverage.dart
void testBug4DivideByZeroFix() {
  print('🔢 Bug #4: Divide by Zero Fix Test');

  // Read the unit_coverage.dart file
  final File coverageFile = File(
    'packages/flutter_tools/tool/unit_coverage.dart'
  );

  if (!coverageFile.existsSync()) {
    print('❌ unit_coverage.dart file not found');
    exit(1);
  }

  final String content = coverageFile.readAsStringSync();

  // Check that the divide-by-zero protection is present
  if (content.contains('totalLines == 0 ? 0.0 : testedLines / totalLines')) {
    print('✅ Found divide-by-zero protection in percentage getter');
  } else if (content.contains('totalLines == 0')) {
    print('✅ Found zero-check in percentage calculation');
  } else {
    print('❌ Divide-by-zero protection NOT found');
    exit(1);
  }

  // Verify the getter logic
  if (content.contains('double get percentage =>')) {
    print('✅ Percentage property is correctly defined as getter');
  } else {
    print('❌ Percentage property not found');
    exit(1);
  }

  print('✓ Bug #4 test passed\n');
}
