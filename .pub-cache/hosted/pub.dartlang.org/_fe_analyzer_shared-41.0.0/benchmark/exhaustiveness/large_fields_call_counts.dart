// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/exhaustiveness/exhaustive.dart';
import 'package:_fe_analyzer_shared/src/exhaustiveness/profile.dart' as profile;
import 'package:_fe_analyzer_shared/src/exhaustiveness/space.dart';
import 'package:_fe_analyzer_shared/src/exhaustiveness/static_type.dart';

import '../../test/exhaustiveness/utils.dart';

void main() {
  profile.enabled = true;

  //   (A)
  //   /|\
  //  B C D
  var a = StaticType('A', isSealed: true);
  var b = StaticType('B', inherits: [a]);
  var c = StaticType('C', inherits: [a]);
  var d = StaticType('D', inherits: [a]);
  var t = StaticType('T', fields: {'w': a, 'x': a, 'y': a, 'z': a});

  expectExhaustiveOnlyAll(t, [
    {'w': b, 'x': b, 'y': b, 'z': b},
    {'w': b, 'x': b, 'y': b, 'z': c},
    {'w': b, 'x': b, 'y': b, 'z': d},
    {'w': b, 'x': b, 'y': c, 'z': b},
    {'w': b, 'x': b, 'y': c, 'z': c},
    {'w': b, 'x': b, 'y': c, 'z': d},
    {'w': b, 'x': b, 'y': d, 'z': b},
    {'w': b, 'x': b, 'y': d, 'z': c},
    {'w': b, 'x': b, 'y': d, 'z': d},
    {'w': b, 'x': c, 'y': b, 'z': b},
    {'w': b, 'x': c, 'y': b, 'z': c},
    {'w': b, 'x': c, 'y': b, 'z': d},
    {'w': b, 'x': c, 'y': c, 'z': b},
    {'w': b, 'x': c, 'y': c, 'z': c},
    {'w': b, 'x': c, 'y': c, 'z': d},
    {'w': b, 'x': c, 'y': d, 'z': b},
    {'w': b, 'x': c, 'y': d, 'z': c},
    {'w': b, 'x': c, 'y': d, 'z': d},
    {'w': b, 'x': d, 'y': b, 'z': b},
    {'w': b, 'x': d, 'y': b, 'z': c},
    {'w': b, 'x': d, 'y': b, 'z': d},
    {'w': b, 'x': d, 'y': c, 'z': b},
    {'w': b, 'x': d, 'y': c, 'z': c},
    {'w': b, 'x': d, 'y': c, 'z': d},
    {'w': b, 'x': d, 'y': d, 'z': b},
    {'w': b, 'x': d, 'y': d, 'z': c},
    {'w': b, 'x': d, 'y': d, 'z': d},
    {'w': c, 'x': b, 'y': b, 'z': b},
    {'w': c, 'x': b, 'y': b, 'z': c},
    {'w': c, 'x': b, 'y': b, 'z': d},
    {'w': c, 'x': b, 'y': c, 'z': b},
    {'w': c, 'x': b, 'y': c, 'z': c},
    {'w': c, 'x': b, 'y': c, 'z': d},
    {'w': c, 'x': b, 'y': d, 'z': b},
    {'w': c, 'x': b, 'y': d, 'z': c},
    {'w': c, 'x': b, 'y': d, 'z': d},
    {'w': c, 'x': c, 'y': b, 'z': b},
    {'w': c, 'x': c, 'y': b, 'z': c},
    {'w': c, 'x': c, 'y': b, 'z': d},
    {'w': c, 'x': c, 'y': c, 'z': b},
    {'w': c, 'x': c, 'y': c, 'z': c},
    {'w': c, 'x': c, 'y': c, 'z': d},
    {'w': c, 'x': c, 'y': d, 'z': b},
    {'w': c, 'x': c, 'y': d, 'z': c},
    {'w': c, 'x': c, 'y': d, 'z': d},
    {'w': c, 'x': d, 'y': b, 'z': b},
    {'w': c, 'x': d, 'y': b, 'z': c},
    {'w': c, 'x': d, 'y': b, 'z': d},
    {'w': c, 'x': d, 'y': c, 'z': b},
    {'w': c, 'x': d, 'y': c, 'z': c},
    {'w': c, 'x': d, 'y': c, 'z': d},
    {'w': c, 'x': d, 'y': d, 'z': b},
    {'w': c, 'x': d, 'y': d, 'z': c},
    {'w': c, 'x': d, 'y': d, 'z': d},
    {'w': d, 'x': b, 'y': b, 'z': b},
    {'w': d, 'x': b, 'y': b, 'z': c},
    {'w': d, 'x': b, 'y': b, 'z': d},
    {'w': d, 'x': b, 'y': c, 'z': b},
    {'w': d, 'x': b, 'y': c, 'z': c},
    {'w': d, 'x': b, 'y': c, 'z': d},
    {'w': d, 'x': b, 'y': d, 'z': b},
    {'w': d, 'x': b, 'y': d, 'z': c},
    {'w': d, 'x': b, 'y': d, 'z': d},
    {'w': d, 'x': c, 'y': b, 'z': b},
    {'w': d, 'x': c, 'y': b, 'z': c},
    {'w': d, 'x': c, 'y': b, 'z': d},
    {'w': d, 'x': c, 'y': c, 'z': b},
    {'w': d, 'x': c, 'y': c, 'z': c},
    {'w': d, 'x': c, 'y': c, 'z': d},
    {'w': d, 'x': c, 'y': d, 'z': b},
    {'w': d, 'x': c, 'y': d, 'z': c},
    {'w': d, 'x': c, 'y': d, 'z': d},
    {'w': d, 'x': d, 'y': b, 'z': b},
    {'w': d, 'x': d, 'y': b, 'z': c},
    {'w': d, 'x': d, 'y': b, 'z': d},
    {'w': d, 'x': d, 'y': c, 'z': b},
    {'w': d, 'x': d, 'y': c, 'z': c},
    {'w': d, 'x': d, 'y': c, 'z': d},
    {'w': d, 'x': d, 'y': d, 'z': b},
    {'w': d, 'x': d, 'y': d, 'z': c},
    {'w': d, 'x': d, 'y': d, 'z': d},
  ]);
}

/// Test that [cases] are exhaustive over [type] if and only if all cases are
/// included and that all subsets of the cases are not exhaustive.
void expectExhaustiveOnlyAll(StaticType type, List<Object> cases) {
  var spaces = parseSpaces(cases);
  profile.reset();
  print(isExhaustive(Space(type), spaces));
  profile.log();
}
