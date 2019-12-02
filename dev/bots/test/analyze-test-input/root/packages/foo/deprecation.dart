// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@Deprecated(
  'This is the reason and what you should use instead. '
  'This feature was deprecated after v1.2.3.'
)
void test1() { }

@Deprecated(
  'Missing space ->.'
  'This feature was deprecated after v1.2.3.'
)
void test2() { }

@Deprecated(
  'bad grammar. '
  'This feature was deprecated after v1.2.3.'
)
void test3() { }

@Deprecated(
  'Also bad grammar '
  'This feature was deprecated after v1.2.3.'
)
void test4() { }

@deprecated // no message
void test5() { }

@Deprecated('Not the right syntax. This feature was deprecated after v1.2.3.')
void test6() { }

@Deprecated(
  'Missing the version line. '
)
void test7() { }

@Deprecated(
  'This feature was deprecated after v1.2.3.'
)
void test8() { }

@Deprecated(
  'Not the right syntax. '
  'This feature was deprecated after v1.2.3.'
) void test9() { }

@Deprecated(
 'Not the right syntax. '
 'This feature was deprecated after v1.2.3.'
)
void test10() { }

@Deprecated(
  'URLs are not required. '
  'This feature was deprecated after v2.0.0.'
)
void test11() { }
