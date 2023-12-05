// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

@JS('URL')
@staticInterop
class URL {
  external factory URL(
    String url, [
    String base,
  ]);

  external static String createObjectURL(JSObject obj);
  external static void revokeObjectURL(String url);
  external static bool canParse(
    String url, [
    String base,
  ]);
}

extension URLExtension on URL {
  external String toJSON();
  external set href(String value);
  external String get href;
  external String get origin;
  external set protocol(String value);
  external String get protocol;
  external set username(String value);
  external String get username;
  external set password(String value);
  external String get password;
  external set host(String value);
  external String get host;
  external set hostname(String value);
  external String get hostname;
  external set port(String value);
  external String get port;
  external set pathname(String value);
  external String get pathname;
  external set search(String value);
  external String get search;
  external URLSearchParams get searchParams;
  external set hash(String value);
  external String get hash;
}

@JS('URLSearchParams')
@staticInterop
class URLSearchParams {
  external factory URLSearchParams([JSAny init]);
}

extension URLSearchParamsExtension on URLSearchParams {
  external void append(
    String name,
    String value,
  );
  external void delete(
    String name, [
    String value,
  ]);
  external String? get(String name);
  external JSArray getAll(String name);
  external bool has(
    String name, [
    String value,
  ]);
  external void set(
    String name,
    String value,
  );
  external void sort();
  external int get size;
}
