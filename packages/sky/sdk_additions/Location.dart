// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// WARNING: Do not edit - generated code.
part of dart.sky;

abstract class Location extends NativeFieldWrapperClass2 {
    // Constructors

    // Attributes
    String get href native "Location_href_Getter";
    void set href(String value) native "Location_href_Setter";
    String get protocol native "Location_protocol_Getter";
    void set protocol(String value) native "Location_protocol_Setter";
    String get host native "Location_host_Getter";
    void set host(String value) native "Location_host_Setter";
    String get hostname native "Location_hostname_Getter";
    void set hostname(String value) native "Location_hostname_Setter";
    String get port native "Location_port_Getter";
    void set port(String value) native "Location_port_Setter";
    String get pathname native "Location_pathname_Getter";
    void set pathname(String value) native "Location_pathname_Setter";
    String get search native "Location_search_Getter";
    void set search(String value) native "Location_search_Setter";
    String get hash native "Location_hash_Getter";
    void set hash(String value) native "Location_hash_Setter";
    String get origin native "Location_origin_Getter";

    // Methods
    void assign(String url) native "Location_assign_Callback";
    void replace(String url) native "Location_replace_Callback";
    void reload() native "Location_reload_Callback";

    // Operators
}
