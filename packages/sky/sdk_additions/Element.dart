// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// WARNING: Do not edit - generated code.
part of dart.sky;

class Element extends ParentNode {
    // Constructors
    void _constructor() native "Element_constructorCallback";
    Element() { _constructor(); }

    // Attributes
    String get tagName native "Element_tagName_Getter";
    ShadowRoot get shadowRoot native "Element_shadowRoot_Getter";
    CSSStyleDeclaration get style native "Element_style_Getter";
    int get tabIndex native "Element_tabIndex_Getter";
    void set tabIndex(int value) native "Element_tabIndex_Setter";
    DOMTokenList get classList native "Element_classList_Getter";
    int get offsetLeft native "Element_offsetLeft_Getter";
    int get offsetTop native "Element_offsetTop_Getter";
    int get offsetWidth native "Element_offsetWidth_Getter";
    int get offsetHeight native "Element_offsetHeight_Getter";
    Element get offsetParent native "Element_offsetParent_Getter";
    int get clientLeft native "Element_clientLeft_Getter";
    int get clientTop native "Element_clientTop_Getter";
    int get clientWidth native "Element_clientWidth_Getter";
    int get clientHeight native "Element_clientHeight_Getter";

    // Methods
    bool hasAttribute(String name) native "Element_hasAttribute_Callback";
    String getAttribute(String name) native "Element_getAttribute_Callback";
    void setAttribute(String name, [String value = ""]) native "Element_setAttribute_Callback";
    void removeAttribute(String name) native "Element_removeAttribute_Callback";
    List<Attr> getAttributes() native "Element_getAttributes_Callback";
    void requestPaint(PaintingCallback callback) native "Element_requestPaint_Callback";
    bool matches(String selectors) native "Element_matches_Callback";
    void focus() native "Element_focus_Callback";
    void blur() native "Element_blur_Callback";
    ShadowRoot ensureShadowRoot() native "Element_ensureShadowRoot_Callback";
    ClientRect getBoundingClientRect() native "Element_getBoundingClientRect_Callback";
    List<AnimationPlayer> getAnimationPlayers() native "Element_getAnimationPlayers_Callback";

    // Operators
}
