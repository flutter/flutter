import 'dart:bogus';

import '../resources/third_party/unittest/unittest.dart';
import '../resources/unit.dart';

void main() {
  initUnit();

  test("shouldn't crash on a bogus import (see line 1)", () { });
}
