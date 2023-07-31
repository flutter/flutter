// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum Enum {a, b}

sealed class A {
  final Enum a;
  bool get b;
  A(this.a);
}

class B extends A {
  final bool b;
  B(super.a, this.b);
}

void exhaustiveSwitch1(A r) {
  /*
   fields={a:Enum,b:bool,hashCode:int,runtimeType:Type},
   subtypes={B},
   type=A
  */switch (r) {
    /*space=A(a: Enum.a, b: false)*/case A(a: Enum.a, b: false):
      print('A(a, false)');
      break;
    /*space=A(a: Enum.b, b: false)*/case A(a: Enum.b, b: false):
      print('A(b, false)');
      break;
    /*space=A(a: Enum.a, b: true)*/case A(a: Enum.a, b: true):
      print('A(a, true)');
      break;
    /*space=A(a: Enum.b, b: true)*/case A(a: Enum.b, b: true):
      print('A(b, true)');
      break;
  }
}

void exhaustiveSwitch2(A r) {
      /*
       fields={a:Enum,b:bool,hashCode:int,runtimeType:Type},
       subtypes={B},
       type=A
      */switch (r) {
    /*space=A(a: Enum.a, b: false)*/case A(a: Enum.a, b: false):
      print('A(a, false)');
      break;
    /*space=A(a: Enum.a, b: true)*/case A(a: Enum.a, b: true):
      print('A(a, true)');
      break;
    /*space=A(a: Enum.b, b: false)*/case A(a: Enum.b, b: false):
      print('A(b, false)');
      break;
    /*space=A(a: Enum.b, b: true)*/case A(a: Enum.b, b: true):
      print('A(b, true)');
      break;
  }
}

void nonExhaustiveSwitch1(A r) {
  /*
   error=non-exhaustive:B(a: Enum.b, b: false),
   fields={a:Enum,b:bool,hashCode:int,runtimeType:Type},
   subtypes={B},
   type=A
  */switch (r) {
    /*space=A(a: Enum.a, b: false)*/case A(a: Enum.a, b: false):
      print('A(a, false)');
      break;
    /*space=A(a: Enum.a, b: true)*/case A(a: Enum.a, b: true):
      print('A(a, true)');
      break;
    /*space=A(a: Enum.b, b: true)*/case A(a: Enum.b, b: true):
      print('A(b, true)');
      break;
  }
}

void nonExhaustiveSwitch2(A r) {
  /*
   error=non-exhaustive:B(a: Enum.a, b: false),
   fields={a:Enum,b:bool,hashCode:int,runtimeType:Type},
   subtypes={B},
   type=A
  */switch (r) {
    /*space=A(a: Enum.b, b: false)*/case A(a: Enum.b, b: false):
      print('A(b, false)');
      break;
    /*space=A(a: Enum.a, b: true)*/case A(a: Enum.a, b: true):
      print('A(a, true)');
      break;
    /*space=A(a: Enum.b, b: true)*/case A(a: Enum.b, b: true):
      print('A(b, true)');
      break;
  }
}

void nonExhaustiveSwitchWithDefault(A r) {
  /*
   error=non-exhaustive:B(a: Enum.a, b: true),
   fields={a:Enum,b:bool,hashCode:int,runtimeType:Type},
   subtypes={B},
   type=A
  */switch (r) {
    /*space=A(a: Enum.a, b: false)*/case A(a: Enum.a, b: false):
      print('A(a, false)');
      break;
    default:
      print('default');
      break;
  }
}

void exhaustiveNullableSwitch(A? r) {
  /*
   fields={},
   subtypes={A,Null},
   type=A?
  */switch (r) {
    /*space=A(a: Enum.a, b: false)*/case A(a: Enum.a, b: false):
      print('A(a, false)');
      break;
    /*space=A(a: Enum.b, b: false)*/case A(a: Enum.b, b: false):
      print('A(b, false)');
      break;
    /*space=A(a: Enum.a, b: true)*/case A(a: Enum.a, b: true):
      print('A(a, true)');
      break;
    /*space=A(a: Enum.b, b: true)*/case A(a: Enum.b, b: true):
      print('A(b, true)');
      break;
    /*space=Null*/case null:
      print('null');
      break;
  }
}

void nonExhaustiveNullableSwitch1(A? r) {
  /*
   error=non-exhaustive:Null,
   fields={},
   subtypes={A,Null},
   type=A?
  */switch (r) {
    /*space=A(a: Enum.a, b: false)*/case A(a: Enum.a, b: false):
      print('A(a, false)');
      break;
    /*space=A(a: Enum.b, b: false)*/case A(a: Enum.b, b: false):
      print('A(b, false)');
      break;
    /*space=A(a: Enum.a, b: true)*/case A(a: Enum.a, b: true):
      print('A(a, true)');
      break;
    /*space=A(a: Enum.b, b: true)*/case A(a: Enum.b, b: true):
      print('A(b, true)');
      break;
  }
}

void nonExhaustiveNullableSwitch2(A? r) {
  /*
   error=non-exhaustive:B(a: Enum.b, b: false),
   fields={},
   subtypes={A,Null},
   type=A?
  */switch (r) {
    /*space=A(a: Enum.a, b: false)*/case A(a: Enum.a, b: false):
      print('A(a, false)');
      break;
    /*space=A(a: Enum.a, b: true)*/case A(a: Enum.a, b: true):
      print('A(a, true)');
      break;
    /*space=A(a: Enum.b, b: true)*/case A(a: Enum.b, b: true):
      print('A(b, true)');
      break;
    /*space=Null*/case null:
      print('null');
      break;
  }
}

void unreachableCase1(A r) {
  /*cfe.
   error=unreachable,
   fields={a:Enum,b:bool,hashCode:int,runtimeType:Type},
   subtypes={B},
   type=A
  *//*analyzer.
   fields={a:Enum,b:bool,hashCode:int,runtimeType:Type},
   subtypes={B},
   type=A
  */switch (r) {
    /*space=A(a: Enum.a, b: false)*/case A(a: Enum.a, b: false):
      print('A(a, false) #1');
      break;
    /*space=A(a: Enum.b, b: false)*/case A(a: Enum.b, b: false):
      print('A(b, false)');
      break;
    /*space=A(a: Enum.a, b: true)*/case A(a: Enum.a, b: true):
      print('A(a, true)');
      break;
    /*space=A(a: Enum.b, b: true)*/case A(a: Enum.b, b: true):
      print('A(b, true)');
      break;
    /*cfe.space=A(a: Enum.a, b: false)*//*analyzer.
     error=unreachable,
     space=A(a: Enum.a, b: false)
    */case A(a: Enum.a, b: false):
      print('(a, false) #2');
      break;
  }
}

void unreachableCase2(A r) {
  // TODO(johnniwinther): Should we avoid the unreachable error here?
  /*
   fields={a:Enum,b:bool,hashCode:int,runtimeType:Type},
   subtypes={B},
   type=A
  */switch (r) {
    /*space=A(a: Enum.a, b: false)*/case A(a: Enum.a, b: false):
      print('A(a, false)');
      break;
    /*space=A(a: Enum.b, b: false)*/case A(a: Enum.b, b: false):
      print('A(b, false)');
      break;
    /*space=A(a: Enum.a, b: true)*/case A(a: Enum.a, b: true):
      print('A(a, true)');
      break;
    /*space=A(a: Enum.b, b: true)*/case A(a: Enum.b, b: true):
      print('A(b, true)');
      break;
    /*space=Null*/case null:
      print('null');
      break;
  }
}

void unreachableCase3(A? r) {
  /*cfe.
   error=unreachable,
   fields={},
   subtypes={A,Null},
   type=A?
  *//*analyzer.
   fields={},
   subtypes={A,Null},
   type=A?
  */switch (r) {
    /*space=A(a: Enum.a, b: false)*/case A(a: Enum.a, b: false):
      print('A(a, false)');
      break;
    /*space=A(a: Enum.b, b: false)*/case A(a: Enum.b, b: false):
      print('A(b, false)');
      break;
    /*space=A(a: Enum.a, b: true)*/case A(a: Enum.a, b: true):
      print('A(a, true)');
      break;
    /*space=A(a: Enum.b, b: true)*/case A(a: Enum.b, b: true):
      print('A(b, true)');
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
