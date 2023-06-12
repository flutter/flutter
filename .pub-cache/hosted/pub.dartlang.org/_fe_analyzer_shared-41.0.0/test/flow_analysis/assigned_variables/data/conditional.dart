// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that conditional (`?:`) expressions are annotated with the
// variables written in their "then" branches.  This is needed for legacy type
// promotion, to ensure that an assignment in the "then" branch defeats
// promotion.

/*member: then:declared={a, b, c, d, e}, read={a, c, e}, assigned={b, d}*/
then(bool a, bool b, bool c, bool d, bool e) {
  a /*read={c}, assigned={b}*/ ? b = c : d = e;
}
