import 'dart:typed_data';

import 'package:sqflite_common/src/env_utils.dart';

/// Don't throw exception yet. will be done in the future.
var checkThrowException = false;

var _debugCheckPrinted = <String, bool>{};

void _checkArg(dynamic arg) {
  if ((arg is! String) && (arg is! num) && (arg is! Uint8List)) {
    // Big int ok on the web only
    if (kSqfliteIsWeb) {
      if (arg is BigInt) {
        return;
      }
    }
    final type = arg.runtimeType.toString();

    final text = '''
*** WARNING ***

Invalid argument $arg with type $type.
Only num, String and Uint8List are supported. See https://github.com/tekartik/sqflite/blob/master/sqflite/doc/supported_types.md for details

This will throw an exception in the future. For now it is displayed once per type.

    ''';
    if (checkThrowException) {
      throw ArgumentError(text);
    } else {
      final printed = _debugCheckPrinted[type] ?? false;
      if (!printed) {
        _debugCheckPrinted[type] = true;
        print(text);
      }
    }
  }
}

/// Check the value is valid. test for non null only;
void checkNonNullValue(dynamic value) {
  if (isDebug) {
    _checkArg(value);
  }
}

/// Check whether the args are valid in raw statement. null is supported here
void checkRawArgs(List<dynamic>? args) {
  if (isDebug && args != null) {
    for (var arg in args) {
      if (arg != null) {
        _checkArg(arg);
      }
    }
  }
}

/// Check whether the where args are valid. null is not supported here.
void checkWhereArgs(List<dynamic>? args) {
  if (isDebug && args != null) {
    for (var arg in args) {
      _checkArg(arg);
    }
  }
}
