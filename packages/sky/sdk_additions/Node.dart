// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// WARNING: Do not edit - generated code.
part of dart.sky;

abstract class Node extends EventTarget {
    // Constructors

    // Attributes
    ParentNode get owner native "Node_owner_Getter";
    ParentNode get parentNode native "Node_parentNode_Getter";
    Element get parentElement native "Node_parentElement_Getter";
    Node get nextSibling native "Node_nextSibling_Getter";
    Node get previousSibling native "Node_previousSibling_Getter";
    Element get nextElementSibling native "Node_nextElementSibling_Getter";
    Element get previousElementSibling native "Node_previousElementSibling_Getter";
    String get textContent native "Node_textContent_Getter";
    void set textContent(String value) native "Node_textContent_Setter";

    // Methods
    Node cloneNode({bool deep : false}) native "Node_cloneNode_Callback";
    void insertBefore(List<Node> nodes) native "Node_insertBefore_Callback";
    void insertAfter(List<Node> nodes) native "Node_insertAfter_Callback";
    void replaceWith(List<Node> nodes) native "Node_replaceWith_Callback";
    void remove() native "Node_remove_Callback";

    // Operators
}
