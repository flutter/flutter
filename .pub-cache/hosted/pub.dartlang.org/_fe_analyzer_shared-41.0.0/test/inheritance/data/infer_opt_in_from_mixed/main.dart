// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: nnbd=true*/

import 'opt_out.dart';

/*class: Nnbd:Nnbd,Object*/
abstract class Nnbd {
  /*member: Nnbd.mandatory:void Function(int)*/
  void mandatory(int param);
  /*member: Nnbd.optional:void Function(int?)*/
  void optional(int? param);
}

/*class: Both1:Both1,Legacy,Nnbd,Object*/
/*cfe|cfe:builder.member: Both1.==:bool* Function(dynamic)*/
class Both1 implements Legacy, Nnbd {
  /*member: Both1.mandatory:void Function(int)*/
  void mandatory(param) {}
  /*member: Both1.optional:void Function(int?)*/
  void optional(param) {}
}

/*class: Both2:Both2,Legacy,Nnbd,Object*/
/*cfe|cfe:builder.member: Both2.==:bool* Function(dynamic)*/
class Both2 implements Nnbd, Legacy {
  /*member: Both2.mandatory:void Function(int)*/
  void mandatory(param) {}
  /*member: Both2.optional:void Function(int?)*/
  void optional(param) {}
}
