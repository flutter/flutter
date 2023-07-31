// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

sealed class A {}
class B extends A {}
class C extends A {}
class D extends A {}

enum Enum {a, b}

void exhaustiveSwitch1(A a) {
  /*
   fields={hashCode:int,runtimeType:Type},
   subtypes={B,C,D},
   type=A
  */switch (a) {
    /*space=B*/case B b:
      print('B');
      break;
    /*space=C*/case C c:
      print('C');
      break;
    /*space=D*/case D d:
      print('D');
      break;
  }
}

void exhaustiveSwitch2(A a) {
  /*
   fields={hashCode:int,runtimeType:Type},
   subtypes={B,C,D},
   type=A
  */switch (a) {
    /*space=B*/case B b:
      print('B');
      break;
    /*space=A*/case A a:
      print('A');
      break;
  }
}

void nonExhaustiveSwitch1(A a) {
  /*
   error=non-exhaustive:D,
   fields={hashCode:int,runtimeType:Type},
   subtypes={B,C,D},
   type=A
  */switch (a) {
    /*space=B*/case B b:
      print('B');
      break;
    /*space=C*/case C c:
      print('C');
      break;
  }
}

void nonExhaustiveSwitch2(A a) {
  /*
   error=non-exhaustive:B,
   fields={hashCode:int,runtimeType:Type},
   subtypes={B,C,D},
   type=A
  */switch (a) {
    /*space=C*/case C c:
      print('C');
      break;
    /*space=D*/case D d:
      print('D');
      break;
  }
}

void nonExhaustiveSwitch3(A a) {
  /*
   error=non-exhaustive:C,
   fields={hashCode:int,runtimeType:Type},
   subtypes={B,C,D},
   type=A
  */switch (a) {
    /*space=B*/case B b:
      print('B');
      break;
    /*space=D*/case D d:
      print('D');
      break;
  }
}

void nonExhaustiveSwitchWithDefault(A a) {
  /*
   error=non-exhaustive:C,
   fields={hashCode:int,runtimeType:Type},
   subtypes={B,C,D},
   type=A
  */switch (a) {
    /*space=B*/case B b:
      print('B');
      break;
    default:
      print('default');
      break;
  }
}

void exhaustiveNullableSwitch(A? a) {
  /*
   fields={},
   subtypes={A,Null},
   type=A?
  */switch (a) {
    /*space=B*/case B b:
      print('B');
      break;
    /*space=C*/case C c:
      print('C');
      break;
    /*space=D*/case D d:
      print('D');
      break;
    /*space=Null*/case null:
      print('null');
      break;
  }
}

void nonExhaustiveNullableSwitch1(A? a) {
  /*
   error=non-exhaustive:Null,
   fields={},
   subtypes={A,Null},
   type=A?
  */switch (a) {
    /*space=A*/case A a:
      print('A');
      break;
  }
}

void nonExhaustiveNullableSwitch2(A? a) {
  /*
   error=non-exhaustive:D,
   fields={},
   subtypes={A,Null},
   type=A?
  */switch (a) {
    /*space=B*/case B b:
      print('B');
      break;
    /*space=C*/case C c:
      print('C');
      break;
    /*space=Null*/case null:
      print('null');
      break;
  }
}

void unreachableCase1(A a) {
  /*cfe.
   error=unreachable,
   fields={hashCode:int,runtimeType:Type},
   subtypes={B,C,D},
   type=A
  *//*analyzer.
   fields={hashCode:int,runtimeType:Type},
   subtypes={B,C,D},
   type=A
  */switch (a) {
    /*space=B*/case B b:
      print('B');
      break;
    /*space=C*/case C c:
      print('C');
      break;
    /*space=D*/case D d:
      print('D');
      break;
    /*cfe.space=A*//*analyzer.
     error=unreachable,
     space=A
    */case A a:
      print('A');
      break;
  }
}

void unreachableCase2(A a) {
  // TODO(johnniwinther): Should we avoid the unreachable error here?
  /*
   fields={hashCode:int,runtimeType:Type},
   subtypes={B,C,D},
   type=A
  */switch (a) {
    /*space=A*/case A a:
      print('A');
      break;
    /*space=Null*/case null:
      print('null');
      break;
  }
}

void unreachableCase3(A? a) {
  /*cfe.
   error=unreachable,
   fields={},
   subtypes={A,Null},
   type=A?
  *//*analyzer.
   fields={},
   subtypes={A,Null},
   type=A?
  */switch (a) {
    /*space=A*/case A a:
      print('A');
      break;
    /*space=Null*/case null:
      print('null #1');
      break;
    /*cfe.space=Null*//*analyzer.
     error=unreachable,
     space=Null
    */case null:
      print('null #2');
      break;
  }
}
