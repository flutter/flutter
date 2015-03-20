// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// WARNING: Do not edit - generated code.
part of dart.sky;

abstract class DOMTokenList extends NativeFieldWrapperClass2 {
    // Constructors

    // Attributes
    int get length native "DOMTokenList_length_Getter";

    // Methods
    String item(int index) native "DOMTokenList_item_Callback";
    bool contains(String token) native "DOMTokenList_contains_Callback";
    void add(String tokens) native "DOMTokenList_add_Callback";
    void remove(String tokens) native "DOMTokenList_remove_Callback";
    bool toggle(String token) native "DOMTokenList_toggle_Callback";
    void clear() native "DOMTokenList_clear_Callback";
    String toString() native "DOMTokenList_toString_Callback";

    // Operators
}
