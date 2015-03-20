// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// WARNING: Do not edit - generated code.
part of dart.sky;

abstract class ShadowRoot extends DocumentFragment {
    // Constructors

    // Attributes
    Element get activeElement native "ShadowRoot_activeElement_Getter";
    Element get host native "ShadowRoot_host_Getter";

    // Methods
    Node cloneNode({bool deep : false}) native "ShadowRoot_cloneNode_Callback";
    Selection getSelection() native "ShadowRoot_getSelection_Callback";
    Element getElementById([String elementId = ""]) native "ShadowRoot_getElementById_Callback";
    Element elementFromPoint([int x = 0, int y = 0]) native "ShadowRoot_elementFromPoint_Callback";

    // Operators
}
