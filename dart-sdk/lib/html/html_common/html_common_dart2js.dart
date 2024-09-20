// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library html_common;

import 'dart:async';
import 'dart:collection';
import 'dart:html';
import 'dart:_internal' show WhereIterable;
import 'dart:web_gl' as gl;
import 'dart:typed_data';
import 'dart:_native_typed_data';
import 'dart:_js_helper' show Creates, Returns, convertDartClosureToJS;
import 'dart:_foreign_helper' show JS;
import 'dart:_interceptors' show Interceptor, JSExtendableArray, JSObject;

import 'dart:js_util' show promiseToFuture;
export 'dart:js_util' show promiseToFuture;

import 'dart:_metadata';
export 'dart:_metadata';

part 'css_class_set.dart';
part 'conversions.dart';
part 'conversions_dart2js.dart';
part 'device.dart';
part 'filtered_element_list.dart';
part 'lists.dart';
