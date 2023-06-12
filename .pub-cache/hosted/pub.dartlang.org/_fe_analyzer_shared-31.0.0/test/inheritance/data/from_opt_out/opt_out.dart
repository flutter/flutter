// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.5

/*library: nnbd=false*/

/*class: GenericInterface:GenericInterface<T*>,Object*/
/*cfe|cfe:builder.member: GenericInterface.toString:String* Function()**/
/*cfe|cfe:builder.member: GenericInterface.runtimeType:Type**/
/*cfe|cfe:builder.member: GenericInterface._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: GenericInterface._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: GenericInterface.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: GenericInterface._identityHashCode:int**/
/*cfe|cfe:builder.member: GenericInterface.hashCode:int**/
/*cfe|cfe:builder.member: GenericInterface._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: GenericInterface._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: GenericInterface.==:bool* Function(dynamic)**/
abstract class GenericInterface<T> {}

/*class: GenericSubInterface:
 GenericInterface<T*>,
 GenericSubInterface<T*>,
 Object
*/
/*cfe|cfe:builder.member: GenericSubInterface.toString:String* Function()**/
/*cfe|cfe:builder.member: GenericSubInterface.runtimeType:Type**/
/*cfe|cfe:builder.member: GenericSubInterface._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: GenericSubInterface._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: GenericSubInterface.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: GenericSubInterface._identityHashCode:int**/
/*cfe|cfe:builder.member: GenericSubInterface.hashCode:int**/
/*cfe|cfe:builder.member: GenericSubInterface._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: GenericSubInterface._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: GenericSubInterface.==:bool* Function(dynamic)**/
abstract class GenericSubInterface<T> implements GenericInterface<T> {}

/*class: LegacyClass1:LegacyClass1,Object*/
/*cfe|cfe:builder.member: LegacyClass1.toString:String* Function()**/
/*cfe|cfe:builder.member: LegacyClass1.runtimeType:Type**/
/*cfe|cfe:builder.member: LegacyClass1._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass1._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: LegacyClass1.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: LegacyClass1._identityHashCode:int**/
/*cfe|cfe:builder.member: LegacyClass1.hashCode:int**/
/*cfe|cfe:builder.member: LegacyClass1._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass1._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass1.==:bool* Function(dynamic)**/
class LegacyClass1 {}

/*class: LegacyClass2:LegacyClass2<T*>,Object*/
/*cfe|cfe:builder.member: LegacyClass2.toString:String* Function()**/
/*cfe|cfe:builder.member: LegacyClass2.runtimeType:Type**/
/*cfe|cfe:builder.member: LegacyClass2._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass2._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: LegacyClass2.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: LegacyClass2._identityHashCode:int**/
/*cfe|cfe:builder.member: LegacyClass2.hashCode:int**/
/*cfe|cfe:builder.member: LegacyClass2._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass2._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass2.==:bool* Function(dynamic)**/
class LegacyClass2<T> {}

/*class: LegacyClass3:GenericInterface<T*>,LegacyClass3<T*>,Object*/
/*cfe|cfe:builder.member: LegacyClass3.toString:String* Function()**/
/*cfe|cfe:builder.member: LegacyClass3.runtimeType:Type**/
/*cfe|cfe:builder.member: LegacyClass3._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass3._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: LegacyClass3.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: LegacyClass3._identityHashCode:int**/
/*cfe|cfe:builder.member: LegacyClass3.hashCode:int**/
/*cfe|cfe:builder.member: LegacyClass3._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass3._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass3.==:bool* Function(dynamic)**/
class LegacyClass3<T> implements GenericInterface<T> {}

/*class: LegacyClass4:GenericInterface<num*>,LegacyClass4,Object*/
/*cfe|cfe:builder.member: LegacyClass4.toString:String* Function()**/
/*cfe|cfe:builder.member: LegacyClass4.runtimeType:Type**/
/*cfe|cfe:builder.member: LegacyClass4._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass4._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: LegacyClass4.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: LegacyClass4._identityHashCode:int**/
/*cfe|cfe:builder.member: LegacyClass4.hashCode:int**/
/*cfe|cfe:builder.member: LegacyClass4._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass4._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass4.==:bool* Function(dynamic)**/
class LegacyClass4 implements GenericInterface<num> {}

/*class: LegacyClass5:
 GenericInterface<T*>,
 LegacyClass3<T*>,
 LegacyClass5<T*>,
 Object
*/
/*cfe|cfe:builder.member: LegacyClass5.toString:String* Function()**/
/*cfe|cfe:builder.member: LegacyClass5.runtimeType:Type**/
/*cfe|cfe:builder.member: LegacyClass5._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass5._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: LegacyClass5.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: LegacyClass5._identityHashCode:int**/
/*cfe|cfe:builder.member: LegacyClass5.hashCode:int**/
/*cfe|cfe:builder.member: LegacyClass5._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass5._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass5.==:bool* Function(dynamic)**/
class LegacyClass5<T> extends LegacyClass3<T> implements GenericInterface<T> {}

/*class: LegacyClass6:GenericInterface<T*>,LegacyClass3<T*>,LegacyClass6<T*>,Object*/
/*cfe|cfe:builder.member: LegacyClass6.toString:String* Function()**/
/*cfe|cfe:builder.member: LegacyClass6.runtimeType:Type**/
/*cfe|cfe:builder.member: LegacyClass6._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass6._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: LegacyClass6.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: LegacyClass6._identityHashCode:int**/
/*cfe|cfe:builder.member: LegacyClass6.hashCode:int**/
/*cfe|cfe:builder.member: LegacyClass6._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass6._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass6.==:bool* Function(dynamic)**/
class LegacyClass6<T> extends Object
    with LegacyClass3<T>
    implements GenericInterface<T> {}

/*class: LegacyClass7:
 GenericInterface<T*>,
 GenericSubInterface<T*>,
 LegacyClass3<T*>,
 LegacyClass7<T*>,
 Object
*/
/*cfe|cfe:builder.member: LegacyClass7.toString:String* Function()**/
/*cfe|cfe:builder.member: LegacyClass7.runtimeType:Type**/
/*cfe|cfe:builder.member: LegacyClass7._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass7._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: LegacyClass7.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: LegacyClass7._identityHashCode:int**/
/*cfe|cfe:builder.member: LegacyClass7.hashCode:int**/
/*cfe|cfe:builder.member: LegacyClass7._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass7._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass7.==:bool* Function(dynamic)**/
class LegacyClass7<T> extends LegacyClass3<T>
    implements GenericSubInterface<T> {}

/*class: LegacyClass8:GenericInterface<T*>,GenericSubInterface<T*>,LegacyClass3<T*>,LegacyClass8<T*>,Object*/
/*cfe|cfe:builder.member: LegacyClass8.toString:String* Function()**/
/*cfe|cfe:builder.member: LegacyClass8.runtimeType:Type**/
/*cfe|cfe:builder.member: LegacyClass8._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass8._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: LegacyClass8.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: LegacyClass8._identityHashCode:int**/
/*cfe|cfe:builder.member: LegacyClass8.hashCode:int**/
/*cfe|cfe:builder.member: LegacyClass8._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass8._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass8.==:bool* Function(dynamic)**/
class LegacyClass8<T> extends Object
    with LegacyClass3<T>
    implements GenericSubInterface<T> {}
