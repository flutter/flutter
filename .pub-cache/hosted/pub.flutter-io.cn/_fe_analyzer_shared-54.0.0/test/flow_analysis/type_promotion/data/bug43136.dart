// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

List<int Function()> f(List<num> nums) {
  List<int Function()> result = [];
  for (var n in nums) {
    if (n is int) {
      result.add(() => /*int*/ n);
    }
  }
  return result;
}
