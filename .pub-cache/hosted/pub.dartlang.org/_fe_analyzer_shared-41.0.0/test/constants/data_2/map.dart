// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

const map0 = /*cfe.Map<dynamic,dynamic>()*/ {};

// TODO(johnniwinther): This seems like an odd offset for the constant. It
// should probably be at the start of the type arguments.
const map1 = <String, int> /*cfe.Map<String,int>()*/ {};

const Map<String, int> map2 = /*cfe.Map<String,int>()*/ {};

const map3 = /*cfe.Map<String,int>(String(foo):Int(42))*/ {'foo': 42};

const map4 = /*cfe.Map<String,int>(String(foo):Int(42),String(bar):Int(87))*/
    {'foo': 42, 'bar': 87};

main() {
  print(
      /*analyzer.Map<dynamic, dynamic>*()*/ /*cfe|dart2js.Map<dynamic,dynamic>()*/ map0);
  print(
      /*analyzer.Map<String*, int*>*()*/ /*cfe.Map<String,int>()*/ /*dart2js.Map<String*,int*>()*/ map1);
  print(
      /*analyzer.Map<String*, int*>*()*/ /*cfe.Map<String,int>()*/ /*dart2js.Map<String*,int*>()*/ map2);
  print(
      /*analyzer.Map<String*, int*>*(String(foo):Int(42))*/ /*cfe.Map<String,int>(String(foo):Int(42))*/ /*dart2js.Map<String*,int*>(String(foo):Int(42))*/ map3);
  print(
      /*analyzer.Map<String*, int*>*(String(foo):Int(42),String(bar):Int(87))*/ /*cfe.Map<String,int>(String(foo):Int(42),String(bar):Int(87))*/ /*dart2js.Map<String*,int*>(String(foo):Int(42),String(bar):Int(87))*/ map4);
}
