// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: nnbd=false*/

// @dart=2.6

/*class: Class1:Class1,Object*/
class Class1 {
  /*member: Class1.hashCode:int**/
  /*member: Class1.noSuchMethod:dynamic Function(Invocation*)**/
  /*member: Class1.toString:String* Function()**/

  /*member: Class1.==:bool* Function(dynamic)**/
  operator ==(other) => true;
}

/*class: Class2a:Class2a,Object*/
abstract class Class2a {
  /*member: Class2a.hashCode:int**/
  /*member: Class2a.noSuchMethod:dynamic Function(Invocation*)**/
  /*member: Class2a.toString:String* Function()**/

  /*member: Class2a.==:bool* Function(Object*)**/
  bool operator ==(Object other);
}

/*class: Class2b:Class2a,Class2b,Object*/
class Class2b extends Class2a {
  /*member: Class2b.hashCode:int**/
  /*member: Class2b.noSuchMethod:dynamic Function(Invocation*)**/
  /*member: Class2b.toString:String* Function()**/
  /*member: Class2b.==:bool* Function(Object*)**/
}

/*class: Class3a:Class3a,Object*/
/*member: Class3a.hashCode:int**/
class Class3a {
  /*member: Class3a.noSuchMethod:dynamic Function(Invocation*)**/
  /*member: Class3a.toString:String* Function()**/
  /*cfe|cfe:builder.member: Class3a.==:bool* Function(dynamic)**/
/*analyzer.member: Class3a.==:bool* Function(Object*)**/
}

/*class: Class3b:Class3a,Class3b,Object*/
abstract class Class3b extends Class3a {
  /*member: Class3b.hashCode:int**/
  /*member: Class3b.noSuchMethod:dynamic Function(Invocation*)**/
  /*member: Class3b.toString:String* Function()**/

  /*member: Class3b.==:bool* Function(Object*)**/
  bool operator ==(Object other);
}

/*class: Class3c:Class3a,Class3b,Class3c,Object*/
class Class3c extends Class3b {
  /*member: Class3c.hashCode:int**/
  /*member: Class3c.noSuchMethod:dynamic Function(Invocation*)**/
  /*member: Class3c.toString:String* Function()**/
  /*member: Class3c.==:bool* Function(Object*)**/
}

/*class: Foo:Foo,Object*/
class Foo extends /*error: TypeNotFound*/ Unresolved {
  /*member: Foo.hashCode:int**/
  /*member: Foo.noSuchMethod:dynamic Function(Invocation*)**/
  /*member: Foo.toString:String* Function()**/
  /*cfe|cfe:builder.member: Foo.==:bool* Function(dynamic)**/
/*analyzer.member: Foo.==:bool* Function(Object*)**/
}

/*class: A:A,Object*/
abstract class A {
  /*member: A.hashCode:int**/
  /*member: A.noSuchMethod:dynamic Function(Invocation*)**/
  /*cfe|cfe:builder.member: A.==:bool* Function(dynamic)**/

  /*analyzer.member: A.==:bool* Function(Object*)**/

  /*member: A.toString:String* Function({bool* withNullability})**/
  String toString({bool withNullability = false}) {
    return '';
  }
}

/*class: B:A,B,Object*/
abstract class B implements A {
  /*member: B.hashCode:int**/
  /*member: B.toString:String* Function({bool* withNullability})**/
  /*cfe|cfe:builder.member: B.==:bool* Function(dynamic)**/

  /*analyzer.member: B.==:bool* Function(Object*)**/

  /*member: B.noSuchMethod:dynamic Function(Invocation*)**/
  noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

// From language_2/mixin/bound_test:

/*class: AbstractExpression:AbstractExpression,Object*/
abstract class AbstractExpression {
  /*member: AbstractExpression.hashCode:int**/
  /*member: AbstractExpression.toString:String* Function()**/
  /*member: AbstractExpression.noSuchMethod:dynamic Function(Invocation*)**/
  /*cfe|cfe:builder.member: AbstractExpression.==:bool* Function(dynamic)**/
/*analyzer.member: AbstractExpression.==:bool* Function(Object*)**/
}

/*class: ExpressionWithEval:ExpressionWithEval,Object*/
abstract class ExpressionWithEval {
  /*member: ExpressionWithEval.hashCode:int**/
  /*member: ExpressionWithEval.toString:String* Function()**/
  /*member: ExpressionWithEval.noSuchMethod:dynamic Function(Invocation*)**/
  /*cfe|cfe:builder.member: ExpressionWithEval.==:bool* Function(dynamic)**/

  /*analyzer.member: ExpressionWithEval.==:bool* Function(Object*)**/

  /*member: ExpressionWithEval.eval:int**/
  int get eval;
}

/*class: ExpressionWithStringConversion:ExpressionWithStringConversion,Object*/
abstract class ExpressionWithStringConversion {
  /*member: ExpressionWithStringConversion.hashCode:int**/
  /*member: ExpressionWithStringConversion.noSuchMethod:dynamic Function(Invocation*)**/
  /*cfe|cfe:builder.member: ExpressionWithStringConversion.==:bool* Function(dynamic)**/

  /*analyzer.member: ExpressionWithStringConversion.==:bool* Function(Object*)**/

  /*member: ExpressionWithStringConversion.toString:String* Function()**/
  String toString();
}

/*class: Expression:AbstractExpression,Expression,ExpressionWithEval,ExpressionWithStringConversion,Object*/
/*member: Expression.toString:String* Function()**/
/*member: Expression.eval:int**/
/*member: Expression.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: Expression.==:bool* Function(dynamic)**/
/*analyzer.member: Expression.==:bool* Function(Object*)**/
/*member: Expression.hashCode:int**/
abstract class Expression = AbstractExpression
    with ExpressionWithEval, ExpressionWithStringConversion;

// From co19_2/Mixins/Mixin_Application/superinterfaces_t01:

/*class: A2:A2,Object*/
abstract class A2 {
  /*member: A2.hashCode:int**/
  /*member: A2.toString:String* Function()**/
  /*member: A2.noSuchMethod:dynamic Function(Invocation*)**/
  /*cfe|cfe:builder.member: A2.==:bool* Function(dynamic)**/

  /*analyzer.member: A2.==:bool* Function(Object*)**/

  /*member: A2.a:int**/
  int get a;
}

/*class: B2:B2,Object*/
abstract class B2 {
  /*member: B2.hashCode:int**/
  /*member: B2.toString:String* Function()**/
  /*member: B2.noSuchMethod:dynamic Function(Invocation*)**/
  /*cfe|cfe:builder.member: B2.==:bool* Function(dynamic)**/

  /*analyzer.member: B2.==:bool* Function(Object*)**/

  /*member: B2.b:int**/
  int get b;
}

/*class: M2:A2,B2,M2,Object*/
abstract class M2 implements A2, B2 {
  /*member: M2.hashCode:int**/
  /*member: M2.b:int**/
  /*member: M2.a:int**/
  /*member: M2.toString:String* Function()**/
  /*member: M2.noSuchMethod:dynamic Function(Invocation*)**/
  /*cfe|cfe:builder.member: M2.==:bool* Function(dynamic)**/
/*analyzer.member: M2.==:bool* Function(Object*)**/
}

/*class: S2:Object,S2*/
/*member: S2.hashCode:int**/
class S2 {
  /*member: S2.toString:String* Function()**/
  /*member: S2.noSuchMethod:dynamic Function(Invocation*)**/
  /*cfe|cfe:builder.member: S2.==:bool* Function(dynamic)**/
/*analyzer.member: S2.==:bool* Function(Object*)**/
}

/*class: C2:A2,B2,C2,M2,Object,S2*/
/*member: C2.hashCode:int**/
class /*error: MissingImplementationNotAbstract*/ C2 extends S2 with M2 {
  /*member: C2.b:int**/
  /*member: C2.a:int**/
  /*member: C2.toString:String* Function()**/
  /*member: C2.noSuchMethod:dynamic Function(Invocation*)**/
  /*cfe|cfe:builder.member: C2.==:bool* Function(dynamic)**/
/*analyzer.member: C2.==:bool* Function(Object*)**/
}

/*class: SuperClass:Object,SuperClass*/
class SuperClass {
  /*member: SuperClass.toString:String* Function()**/
  /*member: SuperClass.noSuchMethod:dynamic Function(Invocation*)**/
  /*member: SuperClass.hashCode:int**/
  /*cfe|cfe:builder.member: SuperClass.==:bool* Function(dynamic)**/
/*analyzer.member: SuperClass.==:bool* Function(Object*)**/
}

/*class: Interface1:Interface1,Object*/
class Interface1 {
  /*member: Interface1.toString:String* Function()**/
  /*member: Interface1.noSuchMethod:dynamic Function(Invocation*)**/
  /*member: Interface1.hashCode:int**/
  /*cfe|cfe:builder.member: Interface1.==:bool* Function(dynamic)**/
/*analyzer.member: Interface1.==:bool* Function(Object*)**/
}

/*class: Interface2:Interface1,Interface2,Object*/
class Interface2 extends Interface1 {
  /*member: Interface2.toString:String* Function()**/
  /*member: Interface2.noSuchMethod:dynamic Function(Invocation*)**/
  /*member: Interface2.hashCode:int**/
  /*cfe|cfe:builder.member: Interface2.==:bool* Function(dynamic)**/
/*analyzer.member: Interface2.==:bool* Function(Object*)**/
}

/*class: SubClass1:Object,SubClass1,SuperClass*/
class SubClass1 implements SuperClass {
  /*member: SubClass1.toString:String* Function()**/
  /*member: SubClass1.noSuchMethod:dynamic Function(Invocation*)**/
  /*member: SubClass1.hashCode:int**/
  get hashCode => 0;

  /*member: SubClass1.==:bool* Function(dynamic)**/
  operator ==(var other) => false;
}

/*class: SubClass2:Interface1,Interface2,Object,SubClass2,SuperClass*/
class SubClass2 extends SuperClass implements Interface2 {
  /*member: SubClass2.toString:String* Function()**/
  /*member: SubClass2.noSuchMethod:dynamic Function(Invocation*)**/
  /*member: SubClass2.hashCode:int**/
  get hashCode => 0;

  /*member: SubClass2.==:bool* Function(dynamic)**/
  operator ==(var other) => false;
}
