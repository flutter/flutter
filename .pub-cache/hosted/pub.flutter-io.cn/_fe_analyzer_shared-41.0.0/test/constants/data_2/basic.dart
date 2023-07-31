// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

const null0 = /*cfe.Null()*/ null;
const bool0 = /*cfe.Bool(true)*/ true;
const bool1 = /*cfe.Bool(false)*/ false;
const string0 = /*cfe.String(foo)*/ 'foo';
const int0 = /*cfe.Int(0)*/ 0;
const double0 = /*cfe.Double(0.5)*/ 0.5;
const symbol0 = /*cfe.Symbol(foo)*/ #foo;
const symbol1 = const /*cfe.Symbol(foo)*/ Symbol('foo');

main() {
  print(/*Null()*/ null0);
  print(/*Bool(true)*/ bool0);
  print(/*Bool(false)*/ bool1);
  print(/*String(foo)*/ string0);
  print(/*Int(0)*/ int0);
  print(/*Double(0.5)*/ double0);
  print(
      /*cfe|analyzer.Symbol(foo)*/
      /*dart2js.Instance(Symbol,{_name:String(foo))*/
      symbol0);
  print(
      /*cfe|analyzer.Symbol(foo)*/
      /*dart2js.Instance(Symbol,{_name:String(foo))*/
      symbol1);
}
