// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// ignore: sdk_version_set_literal
const Set set0 = /*cfe.Set<dynamic>()*/ {};

// TODO(johnniwinther): This seems like an odd offset for the constant. It
// should probably be at the start of the type arguments.
// ignore: sdk_version_set_literal
const set1 = <int> /*cfe.Set<int>()*/ {};

// ignore: sdk_version_set_literal
const Set<int> set2 = /*cfe.Set<int>()*/ {};

// ignore: sdk_version_set_literal
const set3 = /*cfe.Set<int>(Int(42))*/ {42};

// ignore: sdk_version_set_literal
const set4 = /*cfe.Set<int>(Int(42),Int(87))*/ {42, 87};

main() {
  print(/*analyzer.Set<dynamic>*()*/ /*cfe|dart2js.Set<dynamic>()*/ set0);
  print(
      /*analyzer.Set<int*>*()*/ /*cfe.Set<int>()*/ /*dart2js.Set<int*>()*/ set1);
  print(
      /*analyzer.Set<int*>*()*/ /*cfe.Set<int>()*/ /*dart2js.Set<int*>()*/ set2);
  print(
      /*analyzer.Set<int*>*(Int(42))*/ /*cfe.Set<int>(Int(42))*/ /*dart2js.Set<int*>(Int(42))*/ set3);
  print(
      /*analyzer.Set<int*>*(Int(42),Int(87))*/ /*cfe.Set<int>(Int(42),Int(87))*/ /*dart2js.Set<int*>(Int(42),Int(87))*/ set4);
}
