// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: beforeSplitStatement:doesNotComplete*/
void beforeSplitStatement(bool b, int i) {
  return;
  /*unreachable*/
  do /*unreachable*/ {} while (/*unreachable*/ b);

  /*unreachable*/
  for (;;) /*unreachable*/ {}

  /*unreachable*/
  /*cfe.iterator: unreachable*/
  /*cfe.current: unreachable*/
  /*cfe.moveNext: unreachable*/
  for (var _ in /*unreachable*/ [])
  /*unreachable*/ {}

  /*unreachable*/
  if (/*unreachable*/ b)
  /*unreachable*/ {}

  /*unreachable*/
  switch (/*unreachable*/ i) {
  }

  /*unreachable*/
  try /*unreachable*/ {} finally
  /*unreachable*/ {}

  /*unreachable*/
  while (/*unreachable*/ b)
  /*unreachable*/ {}
}
