# Guard against divide-by-zero in unit coverage calculation and fix XCResult warning grammar

**Status:** Fixed

## What this contains (simple words)
- A tiny grammar fix in `XCResult` warning messages.
- A guard against divide-by-zero in `packages/flutter_tools/tool/unit_coverage.dart` so empty libraries show `0.00%` instead of causing errors.

---

## XCResult grammar fix (short)
File: `packages/flutter_tools/lib/src/ios/xcresult.dart`

Summary: changed the warning text from "it was failed to be parsed" to "it failed to be parsed" so logs read clearly.

Before:
```dart
warnings.add(
  '(XCResult) The `url` exists but it was failed to be parsed. url: $urlValue',
);
```

After:
```dart
warnings.add(
  '(XCResult) The `url` exists but it failed to be parsed. url: $urlValue',
);
```

---

## Unit coverage divide-by-zero guard (short)
File: `packages/flutter_tools/tool/unit_coverage.dart`

Summary: treat libraries with zero recorded lines as `0%` so no division-by-zero happens and sorting/overall calculations work.

Fix example used:
```dart
final double leftPercent = left.totalLines == 0 ? 0 : left.testedLines / left.totalLines;
final double rightPercent = right.totalLines == 0 ? 0 : right.testedLines / right.totalLines;
```

Per-library display and overall percent now show `0.00%` when denominators are zero.

---

## Commits and tests
- Fix commit: `5933b1ee2ee` (author: Hackersbs)
- Tests added: `b15293217be` — unit tests for empty libraries and overall calculations
- All tests passed locally; `dart analyze` reported no issues for the grammar change.

---

If you want a different short title, tell me the exact words and I'll rename the file accordingly.
