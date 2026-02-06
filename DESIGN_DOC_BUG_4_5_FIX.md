# Fix Divide-by-Zero Errors in Coverage Calculation Tool

## Summary
This document describes the fixes for divide-by-zero bugs found in the Flutter unit coverage analysis tool (`packages/flutter_tools/tool/unit_coverage.dart`):
- **Divide by Zero in Coverage Comparison Sorting**
- **Divide by Zero in Overall Coverage Calculation**

**Author**: Flutter Team
**Created**: February 2026

---

## What is This Tool?

### Tool Name
**Flutter Unit Coverage Analyzer** (`unit_coverage.dart`)

### Location
```
packages/flutter_tools/tool/unit_coverage.dart
```

### Purpose
The unit coverage tool analyzes test coverage data from LCOV (Line Coverage) files and produces a **per-library coverage summary report**.

### What It Does
1. **Reads LCOV coverage data** - Parses standard LCOV format coverage files
2. **Analyzes per-library coverage** - Calculates coverage percentage for each Dart library
3. **Sorts by coverage** - Orders libraries by increasing coverage percentage (lowest to highest)
4. **Generates reports** - Produces human-readable coverage summaries

### Usage
```bash
dart tool/unit_coverage lcov.info
```

**Input**: LCOV coverage file (e.g., `lcov.info`)
**Output**: Formatted coverage summary table

### Who Uses It?
- **Flutter developers** - To track test coverage
- **CI/CD systems** - To monitor code quality metrics
- **Continuous Integration** - In automated testing pipelines
- **Code review tools** - To measure PR impact on coverage

### Example Output
```
% | tested | total
lib/src/rendering/box.dart: 85.50% | 342 | 400
lib/src/widgets/text.dart: 92.30% | 240 | 260
lib/src/material/button.dart: 78.00% | 156 | 200
OVERALL: 85.27%
```

### Why It's Important
- Ensures Flutter codebase maintains high test coverage
- Identifies untested code areas
- Helps developers focus on improving low-coverage modules
- Prevents regressions in code quality

---

## What Problem Is This Solving?

### Objective
The Flutter unit coverage tool crashes with undefined behavior (infinity or NaN) when processing coverage data that contains:
1. Libraries with zero lines of code
2. Empty coverage reports with no data

### Impact
- **Severity**: High (Runtime Error)
- **Affected Users**: Flutter developers and CI/CD systems using the unit coverage analysis tool
- **Current Behavior**: The tool produces `Infinity` or `NaN` values instead of meaningful output when edge cases occur

### Real-World Scenario
A developer or CI pipeline runs the unit coverage tool on:
- Empty generated files (0 lines total)
- Incomplete/corrupted coverage data
- Coverage reports from certain build configurations

**Result**: The tool crashes or outputs invalid data, breaking automated testing and coverage tracking.

---

## Background

### Current Implementation Issues

#### Divide by Zero in Coverage Comparison Sorting
```dart
final double leftPercent = left.testedLines / left.totalLines;
final double rightPercent = right.testedLines / right.totalLines;
```

**Problem**: No validation that `totalLines > 0` before division.

#### Divide by Zero in Overall Coverage Calculation
```dart
print('OVERALL: ${overallNumerator / overallDenominator}');
```

**Problem**: No check that `overallDenominator > 0` before division.

### Why This Matters
According to Flutter's [Philosophy](https://github.com/flutter/flutter/blob/main/docs/contributing/Style-guide-for-Flutter-repo.md#philosophy):
- **Error messages should be useful**: The tool should gracefully handle edge cases rather than crash
- **Avoid APIs that encourage bad practices**: Tools should be robust against edge case inputs
- **No synchronous slow work**: The tool should complete reliably without exceptions

---

## Overview

### Solution Design
Implement null-safe division with graceful fallbacks:

1. **For comparison sorting**: Return explicit ordering when `totalLines == 0`
2. **For percentage calculation**: Return "N/A" instead of dividing by zero
3. **For overall coverage**: Handle empty coverage sets with "N/A" output

### Benefits
- ✅ Prevents crash scenarios with `Infinity` or `NaN` values
- ✅ Provides meaningful output for edge cases
- ✅ Maintains correct sorting when some files have zero lines
- ✅ Aligns with Flutter's error handling philosophy

---

## Usage Examples

### Before (Crashes)
```
Input: Coverage file with empty libraries
Output: Infinity (or crash)
```

### After (Graceful Handling)
```
Input: Coverage file with empty libraries
Output:
% | tested | total
lib/src/empty.dart: N/A% | 0 | 0
lib/src/normal.dart: 80.00% | 8 | 10
OVERALL: 80.00%
```

---

## Detailed Design

### Change 1: Safe Coverage Comparison in Sort Function

```dart
coverages.sort((Coverage left, Coverage right) {
  // Handle zero-line cases explicitly
  if (left.totalLines == 0 && right.totalLines == 0) {
    return 0;  // Both are equal
  }
  if (left.totalLines == 0) {
    return -1;  // Empty files sort first
  }
  if (right.totalLines == 0) {
    return 1;   // Empty files sort first
  }

  // Safe division when totalLines > 0
  final double leftPercent = left.testedLines / left.totalLines;
  final double rightPercent = right.testedLines / right.totalLines;
  return leftPercent.compareTo(rightPercent);
});
```

**Rationale**: Empty files (0 total lines) are sorted to the top, then files are sorted by coverage percentage.

### Change 2: Safe Individual Coverage Percentage Calculation

```dart
for (final coverage in coverages) {
  overallNumerator += coverage.testedLines;
  overallDenominator += coverage.totalLines;

  // Show 'N/A' for files with no lines
  final String coveragePercent = coverage.totalLines == 0
      ? 'N/A'
      : (coverage.testedLines / coverage.totalLines * 100).toStringAsFixed(2);

  print(
    '${coverage.library}: $coveragePercent% | ${coverage.testedLines} | ${coverage.totalLines}',
  );
}
```

**Rationale**: Transparent handling of edge cases in output while still accumulating accurate totals.

### Change 3: Safe Overall Coverage Calculation

```dart
final String overallPercent = overallDenominator == 0
    ? 'N/A'
    : (overallNumerator / overallDenominator * 100).toStringAsFixed(2);
print('OVERALL: $overallPercent%');
```

**Rationale**: When no coverage data exists at all, report "N/A" instead of "Infinity".

---

## Testing Plan

### Unit Tests
Tests are provided in `packages/flutter_tools/test/tool/unit_coverage_test.dart`:

1. **Test: Libraries with zero total lines**
   - Verifies no crash in sort comparison
   - Validates empty files sort correctly

2. **Test: Individual coverage percentage calculation**
   - Confirms "N/A" output for zero-line files
   - Validates correct percentage for normal files

3. **Test: Overall coverage percentage calculation**
   - Confirms "N/A" when no data exists
   - Validates correct calculation with data

4. **Test: Mixed coverage data**
   - Handles combination of empty and normal files
   - Ensures correct sort order

### Integration Testing
The tool should be tested with:
- Real Flutter coverage reports
- Empty/minimal coverage data
- Corrupted or incomplete data
- Large-scale coverage reports

---

## Compatibility & Breaking Changes

### Non-Breaking
- This fix only changes output for edge cases
- Normal coverage calculation is unchanged
- Sort order is improved (more deterministic)
- Output format remains the same

### Migration
No migration needed. This fix is backward compatible:
- Existing valid coverage reports produce identical output
- New "N/A" output only appears for previously crashing cases

---

## Documentation Plan

### Updated Tool Comments
Documentation comments in the code explain the divide-by-zero prevention:

```dart
/// Calculates per-library coverage, sorted by percentage.
/// Handles edge cases where coverage data is incomplete or empty.
```

### Future Enhancements
Consider documenting in Flutter's tool documentation:
- What "N/A" means in coverage output
- How to interpret empty file handling
- Expected behavior with various data sources

---

## Verification Checklist

- ✅ Code follows [Flutter style guide](https://github.com/flutter/flutter/blob/main/docs/contributing/Style-guide-for-Flutter-repo.md)
- ✅ All new code is tested (unit tests provided)
- ✅ Comments follow Flutter conventions
- ✅ No breaking changes
- ✅ Error handling is explicit and meaningful
- ✅ Edge cases are documented
- ✅ Sort behavior is deterministic

---

## References

- Flutter Style Guide: https://github.com/flutter/flutter/blob/main/docs/contributing/Style-guide-for-Flutter-repo.md
- Flutter Testing Guide: https://github.com/flutter/flutter/blob/main/docs/contributing/testing/Running-and-writing-tests.md
- Unit Coverage Tool: `packages/flutter_tools/tool/unit_coverage.dart`
- Related Bugs: Divide by zero errors in coverage calculation
