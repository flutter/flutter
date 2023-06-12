// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.5

/*library: nnbd=false*/

import 'opt_in.dart';

/*class: LegacyClass1:Class1,LegacyClass1,Object*/
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
class LegacyClass1 extends Class1 {}

/*class: LegacyClass2:Class2<T*>,LegacyClass2<T*>,Object*/
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
class LegacyClass2<T> extends Class2<T> {}

/*class: LegacyClass3a:
 Class3<T*>,
 GenericInterface<T*>,
 LegacyClass3a<T*>,
 Object
*/
/*cfe|cfe:builder.member: LegacyClass3a.toString:String* Function()**/
/*cfe|cfe:builder.member: LegacyClass3a.runtimeType:Type**/
/*cfe|cfe:builder.member: LegacyClass3a._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass3a._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: LegacyClass3a.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: LegacyClass3a._identityHashCode:int**/
/*cfe|cfe:builder.member: LegacyClass3a.hashCode:int**/
/*cfe|cfe:builder.member: LegacyClass3a._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass3a._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass3a.==:bool* Function(dynamic)**/
class LegacyClass3a<T> extends Class3<T> {}

/*class: LegacyClass3b:
 Class3<T*>,
 GenericInterface<T*>,
 LegacyClass3b<T*>,
 Object
*/
/*cfe|cfe:builder.member: LegacyClass3b.toString:String* Function()**/
/*cfe|cfe:builder.member: LegacyClass3b.runtimeType:Type**/
/*cfe|cfe:builder.member: LegacyClass3b._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass3b._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: LegacyClass3b.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: LegacyClass3b._identityHashCode:int**/
/*cfe|cfe:builder.member: LegacyClass3b.hashCode:int**/
/*cfe|cfe:builder.member: LegacyClass3b._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass3b._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass3b.==:bool* Function(dynamic)**/
class LegacyClass3b<T> extends Class3<T> implements GenericInterface<T> {}

/*class: LegacyClass4a:Class4a,GenericInterface<num*>,LegacyClass4a,Object*/
/*cfe|cfe:builder.member: LegacyClass4a.toString:String* Function()**/
/*cfe|cfe:builder.member: LegacyClass4a.runtimeType:Type**/
/*cfe|cfe:builder.member: LegacyClass4a._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass4a._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: LegacyClass4a.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: LegacyClass4a._identityHashCode:int**/
/*cfe|cfe:builder.member: LegacyClass4a.hashCode:int**/
/*cfe|cfe:builder.member: LegacyClass4a._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass4a._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass4a.==:bool* Function(dynamic)**/
class LegacyClass4a extends Class4a {}

/*class: LegacyClass4b:GenericInterface<num*>,LegacyClass4b,Object*/
/*cfe|cfe:builder.member: LegacyClass4b.toString:String* Function()**/
/*cfe|cfe:builder.member: LegacyClass4b.runtimeType:Type**/
/*cfe|cfe:builder.member: LegacyClass4b._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass4b._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: LegacyClass4b.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: LegacyClass4b._identityHashCode:int**/
/*cfe|cfe:builder.member: LegacyClass4b.hashCode:int**/
/*cfe|cfe:builder.member: LegacyClass4b._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass4b._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass4b.==:bool* Function(dynamic)**/
class LegacyClass4b implements GenericInterface<num> {}

/*class: LegacyClass4c:Class4a,GenericInterface<num*>,LegacyClass4c,Object*/
/*cfe|cfe:builder.member: LegacyClass4c.toString:String* Function()**/
/*cfe|cfe:builder.member: LegacyClass4c.runtimeType:Type**/
/*cfe|cfe:builder.member: LegacyClass4c._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass4c._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: LegacyClass4c.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: LegacyClass4c._identityHashCode:int**/
/*cfe|cfe:builder.member: LegacyClass4c.hashCode:int**/
/*cfe|cfe:builder.member: LegacyClass4c._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass4c._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass4c.==:bool* Function(dynamic)**/
class LegacyClass4c extends Class4a implements GenericInterface<num> {}

/*class: LegacyClass4d:Class4a,Class4b,GenericInterface<num*>,LegacyClass4d,Object*/
/*cfe|cfe:builder.member: LegacyClass4d.toString:String* Function()**/
/*cfe|cfe:builder.member: LegacyClass4d.runtimeType:Type**/
/*cfe|cfe:builder.member: LegacyClass4d._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass4d._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: LegacyClass4d.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: LegacyClass4d._identityHashCode:int**/
/*cfe|cfe:builder.member: LegacyClass4d.hashCode:int**/
/*cfe|cfe:builder.member: LegacyClass4d._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass4d._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass4d.==:bool* Function(dynamic)**/
class LegacyClass4d implements Class4a, Class4b {}

class
/*cfe|cfe:builder.error: AmbiguousSupertypes*/
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
/*class: LegacyClass5:Class5,GenericInterface<dynamic>,LegacyClass5,Object*/
/*analyzer.error: CompileTimeErrorCode.CONFLICTING_GENERIC_INTERFACES*/
    LegacyClass5 extends Class5 implements GenericInterface<Object> {}

/*class: LegacyClass6a:
 Class3<T*>,
 GenericInterface<T*>,
 GenericSubInterface<T*>,
 LegacyClass6a<T*>,
 Object
*/
/*cfe|cfe:builder.member: LegacyClass6a.toString:String* Function()**/
/*cfe|cfe:builder.member: LegacyClass6a.runtimeType:Type**/
/*cfe|cfe:builder.member: LegacyClass6a._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass6a._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: LegacyClass6a.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: LegacyClass6a._identityHashCode:int**/
/*cfe|cfe:builder.member: LegacyClass6a.hashCode:int**/
/*cfe|cfe:builder.member: LegacyClass6a._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass6a._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass6a.==:bool* Function(dynamic)**/
class LegacyClass6a<T> extends Class3<T> implements GenericSubInterface<T> {}

/*class: LegacyClass6b:
 Class3<T*>,
 GenericInterface<T*>,
 GenericSubInterface<T*>,
 LegacyClass3a<T*>,
 LegacyClass6b<T*>,
 Object
*/
/*cfe|cfe:builder.member: LegacyClass6b.toString:String* Function()**/
/*cfe|cfe:builder.member: LegacyClass6b.runtimeType:Type**/
/*cfe|cfe:builder.member: LegacyClass6b._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass6b._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: LegacyClass6b.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: LegacyClass6b._identityHashCode:int**/
/*cfe|cfe:builder.member: LegacyClass6b.hashCode:int**/
/*cfe|cfe:builder.member: LegacyClass6b._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass6b._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: LegacyClass6b.==:bool* Function(dynamic)**/
class LegacyClass6b<T> extends LegacyClass3a<T>
    implements GenericSubInterface<T> {}
