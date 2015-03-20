// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// WARNING: Do not edit - generated code.
part of dart.sky;

abstract class FontFaceSet extends EventTarget {
    // Constructors

    // Attributes
    int get size native "FontFaceSet_size_Getter";
    String get status native "FontFaceSet_status_Getter";

    // Methods
    bool check(String font, [String text = ""]) native "FontFaceSet_check_Callback";
    void add(FontFace fontFace) native "FontFaceSet_add_Callback";
    void clear() native "FontFaceSet_clear_Callback";
    bool delete(FontFace fontFace) native "FontFaceSet_delete_Callback";
    bool has(FontFace fontFace) native "FontFaceSet_has_Callback";

    // Operators
}
