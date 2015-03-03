library fn;

import 'dart:async';
import 'dart:collection';
import 'dart:sky' as sky;
import 'reflect.dart' as reflect;

part 'component.dart';
part 'node.dart';
part 'style.dart';

bool _checkedMode;

bool debugWarnings() {
  void testFn(double i) {}

  if (_checkedMode == null) {
    _checkedMode = false;
    try {
      testFn('not a double');
    } catch (ex) {
      _checkedMode = true;
    }
  }

  return _checkedMode;
}
