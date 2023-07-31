// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/testing/id_testing.dart' as id;

main() async {
  await id.updateAllTests(idTests);
}

const List<String> idTests = <String>[
  'pkg/analyzer/test/id_tests/assigned_variables_test.dart',
  'pkg/analyzer/test/id_tests/constant_test.dart',
  'pkg/analyzer/test/id_tests/definite_assignment_test.dart',
  'pkg/analyzer/test/id_tests/definite_unassignment_test.dart',
  'pkg/analyzer/test/id_tests/inheritance_test.dart',
  'pkg/analyzer/test/id_tests/nullability_test.dart',
  'pkg/analyzer/test/id_tests/reachability_test.dart',
  'pkg/analyzer/test/id_tests/type_promotion_test.dart',
  'pkg/analyzer/test/id_tests/why_not_promoted_test.dart',
];
