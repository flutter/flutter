// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum Enum {a, b}

void exhaustiveSwitch1((Enum, bool) r) {
  /*
   fields={$1:Enum,$2:bool},
   type=(Enum, bool)
  */switch (r) {
    /*space=($1: Enum.a, $2: bool)*/case (Enum.a, var b):
      print('(a, *)');
      break;
    /*space=($1: Enum.b, $2: bool)*/case (Enum.b, bool b):
      print('(b, *)');
      break;
  }
}

void exhaustiveSwitch2((Enum, bool) r) {
  /*
   fields={$1:Enum,$2:bool},
   type=(Enum, bool)
  */switch (r) {
    /*space=($1: Enum.a, $2: true)*/case (Enum.a, true):
      print('(a, false)');
      break;
    /*space=($1: Enum, $2: bool)*/case (Enum a, bool b):
      print('(*, *)');
      break;
  }
}

void nonExhaustiveSwitch1((Enum, bool) r) {
  /*
   error=non-exhaustive:(Enum, bool)($1: Enum.b, $2: false),
   fields={$1:Enum,$2:bool},
   type=(Enum, bool)
  */switch (r) {
    /*space=($1: Enum.a, $2: bool)*/case (Enum.a, var b):
      print('(a, *)');
      break;
    /*space=($1: Enum.b, $2: true)*/case (Enum.b, true):
      print('(b, true)');
      break;
  }
}

void nonExhaustiveSwitch2((Enum, bool) r) {
  /*
   error=non-exhaustive:(Enum, bool)($1: Enum.b, $2: true),
   fields={$1:Enum,$2:bool},
   type=(Enum, bool)
  */switch (r) {
    /*space=($1: Enum, $2: false)*/case (var a, false):
      print('(*, false)');
      break;
    /*space=($1: Enum.a, $2: true)*/case (Enum.a, true):
      print('(a, true)');
      break;
  }
}

void nonExhaustiveSwitch3((Enum, bool) r) {
  /*
   error=non-exhaustive:(Enum, bool)($1: Enum.b, $2: true),
   fields={$1:Enum,$2:bool},
   type=(Enum, bool)
  */switch (r) {
    /*space=($1: Enum, $2: false)*/case (Enum a, false):
      print('(*, false)');
      break;
    /*space=($1: Enum.a, $2: true)*/case (Enum.a, true):
      print('(a, true)');
      break;
  }
}

void nonExhaustiveSwitchWithDefault((Enum, bool) r) {
  /*
   error=non-exhaustive:(Enum, bool)($1: Enum.b, $2: true),
   fields={$1:Enum,$2:bool},
   type=(Enum, bool)
  */switch (r) {
    /*space=($1: Enum.a, $2: bool)*/case (Enum.a, var b):
      print('(a, *)');
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
    /*space=($1: Enum.a, $2: bool)*/case (Enum.a, var b):
      print('(a, *)');
      break;
    /*space=($1: Enum.b, $2: bool)*/case (Enum.b, bool b):
      print('(b, *)');
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
    /*space=($1: Enum, $2: bool)*/case (Enum a, bool b):
      print('(*, *)');
      break;
  }
}

void nonExhaustiveNullableSwitch2((Enum, bool)? r) {
  /*
   error=non-exhaustive:(Enum, bool)($1: Enum.a, $2: true),
   fields={},
   subtypes={(Enum, bool),Null},
   type=(Enum, bool)?
  */switch (r) {
    /*space=($1: Enum, $2: false)*/case (Enum a, false):
      print('(*, false)');
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
    /*cfe.space=($1: Enum, $2: bool)*//*analyzer.
     error=unreachable,
     space=($1: Enum, $2: bool)
    */case (Enum a, bool b):
      print('(*, *)');
      break;
  }
}

void unreachableCase2((Enum, bool) r) {
  // TODO(johnniwinther): Should we avoid the unreachable error here?
  /*
   fields={$1:Enum,$2:bool},
   type=(Enum, bool)
  */switch (r) {
    /*space=($1: Enum, $2: bool)*/case (Enum a, bool b):
      print('(*, *)');
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
    /*space=($1: Enum, $2: bool)*/case (var a, var b):
      print('(*, *)');
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
