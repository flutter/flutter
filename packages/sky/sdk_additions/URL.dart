// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// WARNING: Do not edit - generated code.
part of dart.sky;

class URL extends NativeFieldWrapperClass2 {
    // Constructors
    void _constructor(String url, String base) native "URL_constructorCallback";
    URL(String url, String base) { _constructor(url, base); }

    // Attributes
    String get href native "URL_href_Getter";
    void set href(String value) native "URL_href_Setter";
    String get origin native "URL_origin_Getter";
    String get protocol native "URL_protocol_Getter";
    void set protocol(String value) native "URL_protocol_Setter";
    String get username native "URL_username_Getter";
    void set username(String value) native "URL_username_Setter";
    String get password native "URL_password_Getter";
    void set password(String value) native "URL_password_Setter";
    String get host native "URL_host_Getter";
    void set host(String value) native "URL_host_Setter";
    String get hostname native "URL_hostname_Getter";
    void set hostname(String value) native "URL_hostname_Setter";
    String get port native "URL_port_Getter";
    void set port(String value) native "URL_port_Setter";
    String get pathname native "URL_pathname_Getter";
    void set pathname(String value) native "URL_pathname_Setter";
    String get search native "URL_search_Getter";
    void set search(String value) native "URL_search_Setter";
    String get hash native "URL_hash_Getter";
    void set hash(String value) native "URL_hash_Setter";

    // Methods
    String toString() native "URL_toString_Callback";

    // Operators
}
