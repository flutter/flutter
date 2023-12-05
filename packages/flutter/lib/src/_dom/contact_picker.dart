// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

// ignore_for_file: public_member_api_docs

import 'dart:js_interop';

typedef ContactProperty = String;

@JS('ContactAddress')
@staticInterop
class ContactAddress {}

extension ContactAddressExtension on ContactAddress {
  external JSObject toJSON();
  external String get city;
  external String get country;
  external String get dependentLocality;
  external String get organization;
  external String get phone;
  external String get postalCode;
  external String get recipient;
  external String get region;
  external String get sortingCode;
  external JSArray get addressLine;
}

@JS()
@staticInterop
@anonymous
class ContactInfo {
  external factory ContactInfo({
    JSArray address,
    JSArray email,
    JSArray icon,
    JSArray name,
    JSArray tel,
  });
}

extension ContactInfoExtension on ContactInfo {
  external set address(JSArray value);
  external JSArray get address;
  external set email(JSArray value);
  external JSArray get email;
  external set icon(JSArray value);
  external JSArray get icon;
  external set name(JSArray value);
  external JSArray get name;
  external set tel(JSArray value);
  external JSArray get tel;
}

@JS()
@staticInterop
@anonymous
class ContactsSelectOptions {
  external factory ContactsSelectOptions({bool multiple});
}

extension ContactsSelectOptionsExtension on ContactsSelectOptions {
  external set multiple(bool value);
  external bool get multiple;
}

@JS('ContactsManager')
@staticInterop
class ContactsManager {}

extension ContactsManagerExtension on ContactsManager {
  external JSPromise getProperties();
  external JSPromise select(
    JSArray properties, [
    ContactsSelectOptions options,
  ]);
}
