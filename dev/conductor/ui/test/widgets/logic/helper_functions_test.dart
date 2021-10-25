// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_ui/logic/helper_functions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      'CherrypickStringtoArray function should convert possible cherrypick inputs to corresponding string array format.',
      () {
    const String cherrypick1 = 'a5a25cd702b062c24b2c67b8d30b5cb33e0ef6f0';
    const String cherrypick2 = '94d06a2e1d01a3b0c693b94d70c5e1df9d78d249';
    const String cherrypick3 = '768cd702b691584b2c67b8d30b5cb33e0ef6f0';

    expect(cherrypickStringtoArray(null), equals(<String>[]));
    expect(cherrypickStringtoArray(''), equals(<String>[]));
    expect(cherrypickStringtoArray(cherrypick1), equals(<String>[cherrypick1]));
    expect(cherrypickStringtoArray('$cherrypick1,$cherrypick2,$cherrypick3'),
        equals(<String>[cherrypick1, cherrypick2, cherrypick3]));

    expect(cherrypickStringtoArray('$cherrypick1,$cherrypick2,'), equals(<String>[cherrypick1, cherrypick2, '']));
  });
}
