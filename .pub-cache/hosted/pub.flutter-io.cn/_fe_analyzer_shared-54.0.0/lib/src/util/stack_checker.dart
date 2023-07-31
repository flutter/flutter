// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';
import '../messages/codes.dart';
import 'value_kind.dart';

mixin StackChecker {
  /// Used to report an internal error encountered in the stack listener.
  Never internalProblem(Message message, int charOffset, Uri uri);

  /// Checks that [value] matches the expected [kind].
  ///
  /// Use this in assert statements like
  ///
  ///     assert(checkStackValue(uri, fileOffset, ValueKind.Token, value));
  ///
  /// to document and validate the expected value kind.
  bool checkStackValue(
      Uri uri, int? fileOffset, ValueKind kind, Object? value) {
    if (!kind.check(value)) {
      String message = 'Unexpected value `${value}` (${value.runtimeType}). '
          'Expected ${kind}.';
      if (fileOffset != null) {
        // If offset is available report and internal problem to show the
        // parsed code in the output.
        throw internalProblem(
            new Message(const Code<String>('Internal error'),
                problemMessage: message),
            fileOffset,
            uri);
      } else {
        throw message;
      }
    }
    return true;
  }

  /// Returns the size of the stack.
  int get stackHeight;

  /// Returns the [index]th element on the stack from the top, i.e. the top of
  /// the stack has index 0.
  Object? lookupStack(int index);

  /// Checks that [base] is a valid base stack height for a call to
  /// [checkStackStateForAssert].
  ///
  /// This can be used to initialize a stack base for subsequent calls to
  /// [checkStackStateForAssert]. For instance:
  ///
  ///      int? stackBase;
  ///      // Set up the current stack height as the stack base.
  ///      assert(checkStackBaseState(
  ///          uri, fileOffset, stackBase = stackHeight));
  ///      ...
  ///      // Check that the stack is empty, relative to the stack base.
  ///      assert(checkStackState(
  ///          uri, fileOffset, [], base: stackBase));
  ///
  /// or
  ///
  ///      int? stackBase;
  ///      // Assert that the current stack height is at least 4 and set
  ///      // the stack height - 4 up as the stack base.
  ///      assert(checkStackBaseState(
  ///          uri, fileOffset, stackBase = stackHeight - 4));
  ///      ...
  ///      // Check that the stack contains a single `Foo` element, relative to
  ///      // the stack base.
  ///      assert(checkStackState(
  ///          uri, fileOffset, [ValuesKind.Foo], base: stackBase));
  ///
  bool checkStackBaseStateForAssert(Uri uri, int? fileOffset, int base) {
    if (base < 0) {
      _throwProblem(
          uri,
          fileOffset,
          "Too few elements on stack. "
          "Expected ${stackHeight - base}, found $stackHeight.");
    }
    return true;
  }

  /// Checks the top of the current stack against [kinds]. If a mismatch is
  /// found, a top of the current stack is print along with the expected [kinds]
  /// marking the frames that don't match, and throws an exception.
  ///
  /// If [base] provided, it is used as the reference stack base height at
  /// which the [kinds] are expected to occur. This allows for checking that
  /// the stack is empty wrt. the stack base height.
  ///
  /// Use this in assert statements like
  ///
  ///     assert(checkStackState(
  ///         uri, fileOffset, [ValueKind.Integer, ValueKind.StringOrNull]))
  ///
  /// to document the expected stack and get earlier errors on unexpected stack
  /// content.
  bool checkStackStateForAssert(Uri uri, int? fileOffset, List<ValueKind> kinds,
      {int? base}) {
    String? heightError;
    String? kindError;
    bool success = true;
    int stackShift = 0;
    if (base != null) {
      int relativeStackHeight = stackHeight - base;
      if (relativeStackHeight < kinds.length) {
        heightError = "Too few elements on stack. "
            "Expected ${kinds.length}, found $relativeStackHeight.";
        success = false;
      } else if (relativeStackHeight > kinds.length) {
        heightError = "Too many elements on stack. "
            "Expected ${kinds.length}, found $relativeStackHeight.";
        success = false;
      }
      // Shift the stack lookup indices so that [kinds] are checked relative
      // to the stack base instead of relative to the top of the stack.
      stackShift = relativeStackHeight - kinds.length;
    } else {
      if (stackHeight < kinds.length) {
        heightError = "Too few elements on stack. "
            "Expected ${kinds.length}, found $stackHeight.";
        success = false;
      }
    }
    for (int kindIndex = 0; kindIndex < kinds.length; kindIndex++) {
      ValueKind kind = kinds[kindIndex];
      int stackOffset = kindIndex + stackShift;
      if (0 <= stackOffset && stackOffset < stackHeight) {
        Object? value = lookupStack(stackOffset);
        if (!kind.check(value)) {
          kindError = "Unexpected element kind(s).";
          success = false;
        }
      } else {
        success = false;
      }
    }
    if (!success) {
      StringBuffer sb = new StringBuffer();
      if (heightError != null) {
        sb.writeln(' $heightError');
      }
      if (kindError != null) {
        sb.writeln(' $kindError');
      }

      String safeToString(Object? object) {
        try {
          return '$object'.replaceAll('\r', '').replaceAll('\n', '');
        } catch (e) {
          // Judgments fail on toString.
          return object.runtimeType.toString();
        }
      }

      String padLeft(Object object, int length) {
        String text = safeToString(object);
        if (text.length < length) {
          return ' ' * (length - text.length) + text;
        }
        return text;
      }

      String padRight(Object object, int length) {
        String text = safeToString(object);
        if (text.length < length) {
          return text + ' ' * (length - text.length);
        }
        return text;
      }

      // Compute kind/stack frame information for all expected values plus 3 more
      // stack elements if available.

      int startIndex = min(-stackShift, 0);
      int endIndex = max(kinds.length + stackShift, stackHeight);

      for (int kindIndex = startIndex; kindIndex < endIndex + 3; kindIndex++) {
        int stackOffset = kindIndex + stackShift;
        if (stackOffset >= stackHeight && kindIndex > kinds.length) {
          // No more stack elements nor kinds to display.
          break;
        }
        if (kindIndex == kinds.length && base != null) {
          // Show where the stack base is in the stack. Elements printed above
          // this line are the checked/expected stack.
          sb.write('>');
        } else {
          sb.write(' ');
        }
        if (stackOffset >= 0) {
          sb.write(padLeft(stackOffset, 3));
        } else {
          sb.write(padLeft('*', 3));
        }
        sb.write(': ');
        ValueKind? kind;
        if (kindIndex < 0) {
          sb.write(padRight('', 60));
        } else if (kindIndex < kinds.length) {
          kind = kinds[kindIndex];
          sb.write(padRight(kind, 60));
        } else {
          sb.write(padRight('---', 60));
        }
        if (0 <= stackOffset && stackOffset < stackHeight) {
          Object? value = lookupStack(stackOffset);
          if (kind == null || kind.check(value)) {
            sb.write(' ');
          } else {
            sb.write('*');
          }
          sb.write(safeToString(value));
          sb.write(' (${value.runtimeType})');
        } else {
          if (kind == null) {
            sb.write(' ');
          } else {
            sb.write('*');
          }
          sb.write('---');
        }
        sb.writeln();
      }

      _throwProblem(uri, fileOffset, sb.toString());
    }
    return success;
  }

  Never _throwProblem(Uri uri, int? fileOffset, String text) {
    String message = '$runtimeType failure\n$text';
    if (fileOffset != null) {
      // If offset is available report and internal problem to show the
      // parsed code in the output.
      throw internalProblem(
          new Message(const Code<String>('Internal error'),
              problemMessage: message),
          fileOffset,
          uri);
    } else {
      throw message;
    }
  }
}
