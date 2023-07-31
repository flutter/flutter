// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: nnbd=true*/

/*class: NULLABLE:NULLABLE,Object*/
class NULLABLE {
  /*member: NULLABLE.i:int?*/
  /*member: NULLABLE.i=:int?*/
  int? i;
}

/*class: NONNULLABLE:NONNULLABLE,Object*/
class NONNULLABLE {
  /*member: NONNULLABLE.i:int*/
  /*member: NONNULLABLE.i=:int*/
  int i = 1;
}
