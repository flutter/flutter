// Copyright (C) 2020 Potix Corporation. All Rights Reserved
// History: 2020/11/10 12:30 PM
// Author: jumperchen<jumperchen@potix.com>
@JS()
library js_map;

import 'package:js/js.dart';

@JS('Array')
class JsArray {
  external factory JsArray();
  external int push(element);
  external dynamic pop();
  external int get length;
}

@JS('self')
// ignore: always_declare_return_types
external get self;
