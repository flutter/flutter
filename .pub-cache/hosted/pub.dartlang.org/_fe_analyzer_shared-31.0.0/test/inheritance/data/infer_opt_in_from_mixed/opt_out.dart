// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: nnbd=false*/

// @dart = 2.5

/*class: Legacy:Legacy,Object*/
/*cfe|cfe:builder.member: Legacy.toString:String* Function()**/
/*cfe|cfe:builder.member: Legacy.runtimeType:Type**/
/*cfe|cfe:builder.member: Legacy._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: Legacy._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: Legacy.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: Legacy._identityHashCode:int**/
/*cfe|cfe:builder.member: Legacy.hashCode:int**/
/*cfe|cfe:builder.member: Legacy._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: Legacy._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: Legacy.==:bool* Function(dynamic)**/
abstract class Legacy {
  /*member: Legacy.mandatory:void Function(int*)**/
  void mandatory(int param);
  /*member: Legacy.optional:void Function(int*)**/
  void optional(int param);
}
