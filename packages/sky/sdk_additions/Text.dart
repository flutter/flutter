// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// WARNING: Do not edit - generated code.
part of dart.sky;

class Text extends CharacterData {
    // Constructors
    void _constructor(String data) native "Text_constructorCallback";
    Text([String data = ""]) { _constructor(data); }

    // Attributes

    // Methods
    Text splitText(int offset) native "Text_splitText_Callback";
    List<Node> getDestinationInsertionPoints() native "Text_getDestinationInsertionPoints_Callback";

    // Operators
}
