// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart._js_names;

import 'dart:_js_embedded_names' show MANGLED_GLOBAL_NAMES;

import 'dart:_foreign_helper' show JS, JS_EMBEDDED_GLOBAL;

/// Returns the (global) unminified version of [name], or (usual case) `null` if
/// the name is not known.
///
/// The generated app contains a small table that translates a few minified
/// names to their unminified text.  This is used to return unminified names in
/// some parts of Type.toString. Historically a much more comprehensive and
/// large table was generated to support 'dart:mirrors', but 'dart:mirrors' is
/// no longer supported on the web platforms, in part due to the size of tables
/// like this. The names included are chosen by the emitter, but limited to a
/// few primitives and `List`.
String? unmangleGlobalNameIfPreservedAnyways(String name) {
  var names = JS_EMBEDDED_GLOBAL('', MANGLED_GLOBAL_NAMES);
  return JS('String|Null', '#[#]', names, name);
}

/// Unused in dart2js, only here to allow compilation of the shared dart:rti
/// library.
Object getSpecializedTestTag(String name) => name;
