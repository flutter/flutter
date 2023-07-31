// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum Enum { a, b, c }

void exhaustiveSwitch(Enum e) {
  /*
   fields={hashCode:int,index:int,runtimeType:Type},
   subtypes={Enum.a,Enum.b,Enum.c},
   type=Enum
  */
  switch (e) {
    /*space=Enum.a*/
    case Enum.a:
      print('a');
      break;
    /*space=Enum.b*/
    case Enum.b:
      print('b');
      break;
    /*space=Enum.c*/
    case Enum.c:
      print('c');
      break;
  }
}

const a1 = Enum.a;
const b1 = Enum.b;
const c1 = Enum.c;

void exhaustiveSwitchAliasedBefore(Enum e) {
  /*
   fields={hashCode:int,index:int,runtimeType:Type},
   subtypes={Enum.a,Enum.b,Enum.c},
   type=Enum
  */
  switch (e) {
    /*space=Enum.a*/
    case a1:
      print('a');
      break;
    /*space=Enum.b*/
    case b1:
      print('b');
      break;
    /*space=Enum.c*/
    case c1:
      print('c');
      break;
  }
}

void exhaustiveSwitchAliasedAfter(Enum e) {
  /*
   fields={hashCode:int,index:int,runtimeType:Type},
   subtypes={Enum.a,Enum.b,Enum.c},
   type=Enum
  */
  switch (e) {
    /*space=Enum.a*/
    case a2:
      print('a');
      break;
    /*space=Enum.b*/
    case b2:
      print('b');
      break;
    /*space=Enum.c*/
    case c2:
      print('c');
      break;
  }
}

const a2 = Enum.a;
const b2 = Enum.b;
const c2 = Enum.c;

void nonExhaustiveSwitch1(Enum e) {
  /*
   error=non-exhaustive:Enum.c,
   fields={hashCode:int,index:int,runtimeType:Type},
   subtypes={Enum.a,Enum.b,Enum.c},
   type=Enum
  */
  switch (e) {
    /*space=Enum.a*/
    case Enum.a:
      print('a');
      break;
    /*space=Enum.b*/
    case Enum.b:
      print('b');
      break;
  }
}

void nonExhaustiveSwitch2(Enum e) {
  /*
   error=non-exhaustive:Enum.b,
   fields={hashCode:int,index:int,runtimeType:Type},
   subtypes={Enum.a,Enum.b,Enum.c},
   type=Enum
  */
  switch (e) {
    /*space=Enum.a*/
    case Enum.a:
      print('a');
      break;
    /*space=Enum.c*/
    case Enum.c:
      print('c');
      break;
  }
}

void nonExhaustiveSwitch3(Enum e) {
  /*
   error=non-exhaustive:Enum.a,
   fields={hashCode:int,index:int,runtimeType:Type},
   subtypes={Enum.a,Enum.b,Enum.c},
   type=Enum
  */
  switch (e) {
    /*space=Enum.b*/
    case Enum.b:
      print('b');
      break;
    /*space=Enum.c*/
    case Enum.c:
      print('c');
      break;
  }
}

void nonExhaustiveSwitch4(Enum e) {
  /*
   error=non-exhaustive:Enum.a,
   fields={hashCode:int,index:int,runtimeType:Type},
   subtypes={Enum.a,Enum.b,Enum.c},
   type=Enum
  */
  switch (e) {
    /*space=Enum.b*/
    case Enum.b:
      print('b');
      break;
  }
}

void nonExhaustiveSwitchWithDefault(Enum e) {
  /*
   error=non-exhaustive:Enum.a,
   fields={hashCode:int,index:int,runtimeType:Type},
   subtypes={Enum.a,Enum.b,Enum.c},
   type=Enum
  */
  switch (e) {
    /*space=Enum.b*/
    case Enum.b:
      print('b');
      break;
    default:
      print('a|c');
      break;
  }
}

void exhaustiveNullableSwitch(Enum? e) {
  /*
   fields={},
   subtypes={Enum,Null},
   type=Enum?
  */
  switch (e) {
    /*space=Enum.a*/
    case Enum.a:
      print('a');
      break;
    /*space=Enum.b*/
    case Enum.b:
      print('b');
      break;
    /*space=Enum.c*/
    case Enum.c:
      print('c');
      break;
    /*space=Null*/
    case null:
      print('null');
      break;
  }
}

void nonExhaustiveNullableSwitch1(Enum? e) {
  /*
   error=non-exhaustive:Null,
   fields={},
   subtypes={Enum,Null},
   type=Enum?
  */
  switch (e) {
    /*space=Enum.a*/
    case Enum.a:
      print('a');
      break;
    /*space=Enum.b*/
    case Enum.b:
      print('b');
      break;
    /*space=Enum.c*/
    case Enum.c:
      print('c');
      break;
  }
}

void nonExhaustiveNullableSwitch2(Enum? e) {
  /*
   error=non-exhaustive:Enum.b,
   fields={},
   subtypes={Enum,Null},
   type=Enum?
  */
  switch (e) {
    /*space=Enum.a*/
    case Enum.a:
      print('a');
      break;
    /*space=Enum.c*/
    case Enum.c:
      print('c');
      break;
    /*space=Null*/
    case null:
      print('null');
      break;
  }
}

void unreachableCase1(Enum e) {
  /*cfe.
   error=unreachable,
   fields={hashCode:int,index:int,runtimeType:Type},
   subtypes={Enum.a,Enum.b,Enum.c},
   type=Enum
  */
  /*analyzer.
   fields={hashCode:int,index:int,runtimeType:Type},
   subtypes={Enum.a,Enum.b,Enum.c},
   type=Enum
  */
  switch (e) {
    /*space=Enum.a*/
    case Enum.a:
      print('a1');
      break;
    /*space=Enum.b*/
    case Enum.b:
      print('b');
      break;
    /*cfe.space=Enum.a*/
    /*analyzer.
     error=unreachable,
     space=Enum.a
    */
    case Enum.a:
      print('a2');
      break;
    /*space=Enum.c*/
    case Enum.c:
      print('c');
      break;
  }
}

void unreachableCase2(Enum e) {
  /*cfe.
   error=unreachable,
   fields={hashCode:int,index:int,runtimeType:Type},
   subtypes={Enum.a,Enum.b,Enum.c},
   type=Enum
  */
  /*analyzer.
   error=non-exhaustive:Enum.c,
   fields={hashCode:int,index:int,runtimeType:Type},
   subtypes={Enum.a,Enum.b,Enum.c},
   type=Enum
  */
  switch (e) {
    /*space=Enum.a*/
    case Enum.a:
      print('a1');
      break;
    /*space=Enum.b*/
    case Enum.b:
      print('b');
      break;
    /*cfe.space=Enum.a*/
    /*analyzer.
     error=unreachable,
     space=Enum.a
    */
    case Enum.a:
      print('a2');
      break;
  }
}

void unreachableCase3(Enum e) {
  // TODO(johnniwinther): Should we avoid the unreachable error here?
  /*
   fields={hashCode:int,index:int,runtimeType:Type},
   subtypes={Enum.a,Enum.b,Enum.c},
   type=Enum
  */
  switch (e) {
    /*space=Enum.a*/
    case Enum.a:
      print('a');
      break;
    /*space=Enum.b*/
    case Enum.b:
      print('b');
      break;
    /*space=Enum.c*/
    case Enum.c:
      print('c');
      break;
    /*space=Null*/
    case null: // Unreachable
      print('null');
      break;
  }
}

void unreachableCase4(Enum? e) {
  /*cfe.
   error=unreachable,
   fields={},
   subtypes={Enum,Null},
   type=Enum?
  */
  /*analyzer.
   fields={},
   subtypes={Enum,Null},
   type=Enum?
  */
  switch (e) {
    /*space=Enum.a*/
    case Enum.a:
      print('a');
      break;
    /*space=Enum.b*/
    case Enum.b:
      print('b');
      break;
    /*space=Enum.c*/
    case Enum.c:
      print('c');
      break;
    /*space=Null*/
    case null:
      print('null1');
      break;
    /*cfe.space=Null*/
    /*analyzer.
     error=unreachable,
     space=Null
    */
    case null:
      print('null2');
      break;
  }
}

void unreachableCase5(Enum e) {
  /*cfe.
   error=unreachable,
   fields={hashCode:int,index:int,runtimeType:Type},
   subtypes={Enum.a,Enum.b,Enum.c},
   type=Enum
  */
  /*analyzer.
   fields={hashCode:int,index:int,runtimeType:Type},
   subtypes={Enum.a,Enum.b,Enum.c},
   type=Enum
  */
  switch (e) {
    /*space=Enum.a*/
    case Enum.a:
      print('a1');
      break;
    /*space=Enum.b*/
    case Enum.b:
    /*cfe.space=Enum.a*/
    /*analyzer.
     error=unreachable,
     space=Enum.a
    */
    case Enum.a:
    /*space=Enum.c*/
    case Enum.c:
      print('c');
      break;
  }
}
