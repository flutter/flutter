// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// WARNING: Do not edit - generated code.
part of dart.sky;

class Document extends ParentNode {
    // Constructors
    void _constructor() native "Document_constructorCallback";
    Document() { _constructor(); }

    // Attributes
    String get baseURI native "Document_baseURI_Getter";
    Window get defaultView native "Document_defaultView_Getter";
    String get contentType native "Document_contentType_Getter";
    String get dir native "Document_dir_Getter";
    void set dir(String value) native "Document_dir_Setter";
    String get title native "Document_title_Getter";
    void set title(String value) native "Document_title_Setter";
    String get referrer native "Document_referrer_Getter";
    String get URL native "Document_URL_Getter";
    Location get location native "Document_location_Getter";
    String get readyState native "Document_readyState_Getter";
    Element get activeElement native "Document_activeElement_Getter";
    String get visibilityState native "Document_visibilityState_Getter";
    bool get hidden native "Document_hidden_Getter";
    HTMLScriptElement get currentScript native "Document_currentScript_Getter";
    AnimationTimeline get timeline native "Document_timeline_Getter";
    FontFaceSet get fonts native "Document_fonts_Getter";

    // Methods
    Element createElement(String tagName) native "Document_createElement_Callback";
    DocumentFragment createDocumentFragment() native "Document_createDocumentFragment_Callback";
    Node importNode(Node node, {bool deep : false}) native "Document_importNode_Callback";
    Element getElementById(String elementId) native "Document_getElementById_Callback";
    Node adoptNode(Node node) native "Document_adoptNode_Callback";
    Range createRange() native "Document_createRange_Callback";
    Element elementFromPoint([int x = 0, int y = 0]) native "Document_elementFromPoint_Callback";
    Range caretRangeFromPoint([int x = 0, int y = 0]) native "Document_caretRangeFromPoint_Callback";
    Selection getSelection() native "Document_getSelection_Callback";
    bool hasFocus() native "Document_hasFocus_Callback";
    void registerElement(String name, dynamic type) native "Document_registerElement_Callback";

    // Operators
}
