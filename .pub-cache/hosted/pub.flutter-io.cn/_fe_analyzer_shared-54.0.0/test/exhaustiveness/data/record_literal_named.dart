// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum Enum {a, b}

void exhaustiveSwitch(({Enum a, bool b}) r) {
  /*
   fields={a:Enum,b:bool},
   type=({Enum a, bool b})
  */switch (r) {
    /*space=(a: Enum.a, b: false)*/case (a: Enum.a, b: false):
      print('(a, false)');
      break;
    /*space=(a: Enum.b, b: false)*/case (a: Enum.b, b: false):
      print('(b, false)');
      break;
    /*space=(a: Enum.a, b: true)*/case (a: Enum.a, b: true):
      print('(a, true)');
      break;
    /*space=(a: Enum.b, b: true)*/case (a: Enum.b, b: true):
      print('(b, true)');
      break;
  }
}

void nonExhaustiveSwitch1(({Enum a, bool b}) r) {
  /*
   error=non-exhaustive:({Enum a, bool b})(a: Enum.b, b: false),
   fields={a:Enum,b:bool},
   type=({Enum a, bool b})
  */switch (r) {
    /*space=(a: Enum.a, b: false)*/case (a: Enum.a, b: false):
      print('(a, false)');
      break;
    /*space=(a: Enum.a, b: true)*/case (a: Enum.a, b: true):
      print('(a, true)');
      break;
    /*space=(a: Enum.b, b: true)*/case (a: Enum.b, b: true):
      print('(b, true)');
      break;
  }
}

void nonExhaustiveSwitch2(({Enum a, bool b}) r) {
  /*
   error=non-exhaustive:({Enum a, bool b})(a: Enum.a, b: false),
   fields={a:Enum,b:bool},
   type=({Enum a, bool b})
  */switch (r) {
    /*space=(a: Enum.b, b: false)*/case (a: Enum.b, b: false):
      print('(b, false)');
      break;
    /*space=(a: Enum.a, b: true)*/case (a: Enum.a, b: true):
      print('(a, true)');
      break;
    /*space=(a: Enum.b, b: true)*/case (a: Enum.b, b: true):
      print('(b, true)');
      break;
  }
}

void nonExhaustiveSwitchWithDefault(({Enum a, bool b}) r) {
  /*
   error=non-exhaustive:({Enum a, bool b})(a: Enum.a, b: true),
   fields={a:Enum,b:bool},
   type=({Enum a, bool b})
  */switch (r) {
    /*space=(a: Enum.a, b: false)*/case (a: Enum.a, b: false):
      print('(a, false)');
      break;
    default:
      print('default');
      break;
  }
}

void exhaustiveNullableSwitch(({Enum a, bool b})? r) {
  /*
   fields={},
   subtypes={({Enum a, bool b}),Null},
   type=({Enum a, bool b})?
  */switch (r) {
    /*space=(a: Enum.a, b: false)*/case (a: Enum.a, b: false):
      print('(a, false)');
      break;
    /*space=(a: Enum.b, b: false)*/case (a: Enum.b, b: false):
      print('(b, false)');
      break;
    /*space=(a: Enum.a, b: true)*/case (a: Enum.a, b: true):
      print('(a, true)');
      break;
    /*space=(a: Enum.b, b: true)*/case (a: Enum.b, b: true):
      print('(b, true)');
      break;
    /*space=Null*/case null:
      print('null');
      break;
  }
}

void nonExhaustiveNullableSwitch1(({Enum a, bool b})? r) {
  /*
   error=non-exhaustive:Null,
   fields={},
   subtypes={({Enum a, bool b}),Null},
   type=({Enum a, bool b})?
  */switch (r) {
    /*space=(a: Enum.a, b: false)*/case (a: Enum.a, b: false):
      print('(a, false)');
      break;
    /*space=(a: Enum.b, b: false)*/case (a: Enum.b, b: false):
      print('(b, false)');
      break;
    /*space=(a: Enum.a, b: true)*/case (a: Enum.a, b: true):
      print('(a, true)');
      break;
    /*space=(a: Enum.b, b: true)*/case (a: Enum.b, b: true):
      print('(b, true)');
      break;
  }
}

void nonExhaustiveNullableSwitch2(({Enum a, bool b})? r) {
  /*
   error=non-exhaustive:({Enum a, bool b})(a: Enum.b, b: false),
   fields={},
   subtypes={({Enum a, bool b}),Null},
   type=({Enum a, bool b})?
  */switch (r) {
    /*space=(a: Enum.a, b: false)*/case (a: Enum.a, b: false):
      print('(a, false)');
      break;
    /*space=(a: Enum.a, b: true)*/case (a: Enum.a, b: true):
      print('(a, true)');
      break;
    /*space=(a: Enum.b, b: true)*/case (a: Enum.b, b: true):
      print('(b, true)');
      break;
    /*space=Null*/case null:
      print('null');
      break;
  }
}

void unreachableCase1(({Enum a, bool b}) r) {
  /*cfe.
   error=unreachable,
   fields={a:Enum,b:bool},
   type=({Enum a, bool b})
  *//*analyzer.
   fields={a:Enum,b:bool},
   type=({Enum a, bool b})
  */switch (r) {
    /*space=(a: Enum.a, b: false)*/case (a: Enum.a, b: false):
      print('(a, false) #1');
      break;
    /*space=(a: Enum.b, b: false)*/case (a: Enum.b, b: false):
      print('(b, false)');
      break;
    /*space=(a: Enum.a, b: true)*/case (a: Enum.a, b: true):
      print('(a, true)');
      break;
    /*space=(a: Enum.b, b: true)*/case (a: Enum.b, b: true):
      print('(b, true)');
      break;
    /*cfe.space=(a: Enum.a, b: false)*//*analyzer.
     error=unreachable,
     space=(a: Enum.a, b: false)
    */case (a: Enum.a, b: false):
      print('(a, false) #2');
      break;
  }
}

void unreachableCase2(({Enum a, bool b}) r) {
  // TODO(johnniwinther): Should we avoid the unreachable error here?
  /*
   fields={a:Enum,b:bool},
   type=({Enum a, bool b})
  */switch (r) {
    /*space=(a: Enum.a, b: false)*/case (a: Enum.a, b: false):
      print('(a, false)');
      break;
    /*space=(a: Enum.b, b: false)*/case (a: Enum.b, b: false):
      print('(b, false)');
      break;
    /*space=(a: Enum.a, b: true)*/case (a: Enum.a, b: true):
      print('(a, true)');
      break;
    /*space=(a: Enum.b, b: true)*/case (a: Enum.b, b: true):
      print('(b, true)');
      break;
    /*space=Null*/case null:
      print('null');
      break;
  }
}

void unreachableCase3(({Enum a, bool b})? r) {
  /*cfe.
   error=unreachable,
   fields={},
   subtypes={({Enum a, bool b}),Null},
   type=({Enum a, bool b})?
  *//*analyzer.
   fields={},
   subtypes={({Enum a, bool b}),Null},
   type=({Enum a, bool b})?
  */switch (r) {
    /*space=(a: Enum.a, b: false)*/case (a: Enum.a, b: false):
      print('(a, false)');
      break;
    /*space=(a: Enum.b, b: false)*/case (a: Enum.b, b: false):
      print('(b, false)');
      break;
    /*space=(a: Enum.a, b: true)*/case (a: Enum.a, b: true):
      print('(a, true)');
      break;
    /*space=(a: Enum.b, b: true)*/case (a: Enum.b, b: true):
      print('(b, true)');
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
