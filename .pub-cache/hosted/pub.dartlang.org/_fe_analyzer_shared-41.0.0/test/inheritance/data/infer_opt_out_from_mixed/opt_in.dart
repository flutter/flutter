// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: nnbd=true*/

/*class: Nnbd:Nnbd,Object*/
abstract class Nnbd {
  /*member: Nnbd.mandatory:void Function(int)*/
  void mandatory(int param);
  /*member: Nnbd.optional:void Function(int?)*/
  void optional(int? param);
}
