// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum Enum {a, b}

void exhaustiveSwitch((Enum, bool) r) {
  /*
   fields={$1:Enum,$2:bool},
   type=(Enum, bool)
  */switch (r) {
    /*space=($1: Enum.a, $2: false)*/case (Enum.a, false):
      print('(a, false)');
      break;
    /*space=($1: Enum.b, $2: false)*/case (Enum.b, false):
      print('(b, false)');
      break;
    /*space=($1: Enum.a, $2: true)*/case (Enum.a, true):
      print('(a, true)');
      break;
    /*space=($1: Enum.b, $2: true)*/case (Enum.b, true):
      print('(b, true)');
      break;
  }
}

void nonExhaustiveSwitch1((Enum, bool) r) {
  /*
   error=non-exhaustive:(Enum, bool)($1: Enum.b, $2: false),
   fields={$1:Enum,$2:bool},
   type=(Enum, bool)
  */switch (r) {
    /*space=($1: Enum.a, $2: false)*/case (Enum.a, false):
      print('(a, false)');
      break;
    /*space=($1: Enum.a, $2: true)*/case (Enum.a, true):
      print('(a, true)');
      break;
    /*space=($1: Enum.b, $2: true)*/case (Enum.b, true):
      print('(b, true)');
      break;
  }
}

void nonExhaustiveSwitch2((Enum, bool) r) {
  /*
   error=non-exhaustive:(Enum, bool)($1: Enum.a, $2: false),
   fields={$1:Enum,$2:bool},
   type=(Enum, bool)
  */switch (r) {
    /*space=($1: Enum.b, $2: false)*/case (Enum.b, false):
      print('(b, false)');
      break;
    /*space=($1: Enum.a, $2: true)*/case (Enum.a, true):
      print('(a, true)');
      break;
    /*space=($1: Enum.b, $2: true)*/case (Enum.b, true):
      print('(b, true)');
      break;
  }
}

void nonExhaustiveSwitchWithDefault((Enum, bool) r) {
  /*
   error=non-exhaustive:(Enum, bool)($1: Enum.a, $2: true),
   fields={$1:Enum,$2:bool},
   type=(Enum, bool)
  */switch (r) {
    /*space=($1: Enum.a, $2: false)*/case (Enum.a, false):
      print('(a, false)');
      break;
    default:
      print('default');
      break;
  }
}

void exhaustiveNullableSwitch((Enum, bool)? r) {
  /*
   fields={},
   subtypes={(Enum, bool),Null},
   type=(Enum, bool)?
  */switch (r) {
    /*space=($1: Enum.a, $2: false)*/case (Enum.a, false):
      print('(a, false)');
      break;
    /*space=($1: Enum.b, $2: false)*/case (Enum.b, false):
      print('(b, false)');
      break;
    /*space=($1: Enum.a, $2: true)*/case (Enum.a, true):
      print('(a, true)');
      break;
    /*space=($1: Enum.b, $2: true)*/case (Enum.b, true):
      print('(b, true)');
      break;
    /*space=Null*/case null:
      print('null');
      break;
  }
}

void nonExhaustiveNullableSwitch1((Enum, bool)? r) {
  /*
   error=non-exhaustive:Null,
   fields={},
   subtypes={(Enum, bool),Null},
   type=(Enum, bool)?
  */switch (r) {
    /*space=($1: Enum.a, $2: false)*/case (Enum.a, false):
      print('(a, false)');
      break;
    /*space=($1: Enum.b, $2: false)*/case (Enum.b, false):
      print('(b, false)');
      break;
    /*space=($1: Enum.a, $2: true)*/case (Enum.a, true):
      print('(a, true)');
      break;
    /*space=($1: Enum.b, $2: true)*/case (Enum.b, true):
      print('(b, true)');
      break;
  }
}

void nonExhaustiveNullableSwitch2((Enum, bool)? r) {
  /*
   error=non-exhaustive:(Enum, bool)($1: Enum.b, $2: false),
   fields={},
   subtypes={(Enum, bool),Null},
   type=(Enum, bool)?
  */switch (r) {
    /*space=($1: Enum.a, $2: false)*/case (Enum.a, false):
      print('(a, false)');
      break;
    /*space=($1: Enum.a, $2: true)*/case (Enum.a, true):
      print('(a, true)');
      break;
    /*space=($1: Enum.b, $2: true)*/case (Enum.b, true):
      print('(b, true)');
      break;
    /*space=Null*/case null:
      print('null');
      break;
  }
}

void unreachableCase1((Enum, bool) r) {
  /*cfe.
   error=unreachable,
   fields={$1:Enum,$2:bool},
   type=(Enum, bool)
  *//*analyzer.
   fields={$1:Enum,$2:bool},
   type=(Enum, bool)
  */switch (r) {
    /*space=($1: Enum.a, $2: false)*/case (Enum.a, false):
      print('(a, false) #1');
      break;
    /*space=($1: Enum.b, $2: false)*/case (Enum.b, false):
      print('(b, false)');
      break;
    /*space=($1: Enum.a, $2: true)*/case (Enum.a, true):
      print('(a, true)');
      break;
    /*space=($1: Enum.b, $2: true)*/case (Enum.b, true):
      print('(b, true)');
      break;
    /*cfe.space=($1: Enum.a, $2: false)*//*analyzer.
     error=unreachable,
     space=($1: Enum.a, $2: false)
    */case (Enum.a, false):
      print('(a, false) #2');
      break;
  }
}

void unreachableCase2((Enum, bool) r) {
  // TODO(johnniwinther): Should we avoid the unreachable error here?
  /*
   fields={$1:Enum,$2:bool},
   type=(Enum, bool)
  */switch (r) {
    /*space=($1: Enum.a, $2: false)*/case (Enum.a, false):
      print('(a, false)');
      break;
    /*space=($1: Enum.b, $2: false)*/case (Enum.b, false):
      print('(b, false)');
      break;
    /*space=($1: Enum.a, $2: true)*/case (Enum.a, true):
      print('(a, true)');
      break;
    /*space=($1: Enum.b, $2: true)*/case (Enum.b, true):
      print('(b, true)');
      break;
    /*space=Null*/case null:
      print('null');
      break;
  }
}

void unreachableCase3((Enum, bool)? r) {
  /*cfe.
   error=unreachable,
   fields={},
   subtypes={(Enum, bool),Null},
   type=(Enum, bool)?
  *//*analyzer.
   fields={},
   subtypes={(Enum, bool),Null},
   type=(Enum, bool)?
  */switch (r) {
    /*space=($1: Enum.a, $2: false)*/case (Enum.a, false):
      print('(a, false)');
      break;
    /*space=($1: Enum.b, $2: false)*/case (Enum.b, false):
      print('(b, false)');
      break;
    /*space=($1: Enum.a, $2: true)*/case (Enum.a, true):
      print('(a, true)');
      break;
    /*space=($1: Enum.b, $2: true)*/case (Enum.b, true):
      print('(b, true)');
      break;
    /*space=Null*/case null:
      print('null1');
      break;
    /*cfe.space=Null*//*analyzer.
     error=unreachable,
     space=Null
    */case null:
      print('null2');
      break;
  }
}
