// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// WARNING: Do not edit - generated code.
part of dart.sky;

abstract class ParentNode extends Node {
    // Constructors

    // Attributes
    Node get firstChild native "ParentNode_firstChild_Getter";
    Node get lastChild native "ParentNode_lastChild_Getter";
    Element get firstElementChild native "ParentNode_firstElementChild_Getter";
    Element get lastElementChild native "ParentNode_lastElementChild_Getter";

    // Methods
    List<Node> getChildNodes() native "ParentNode_getChildNodes_Callback";
    List<Element> getChildElements() native "ParentNode_getChildElements_Callback";
    void append(List<Node> nodes) native "ParentNode_append_Callback";
    Node appendChild(Node node) native "ParentNode_appendChild_Callback";
    void prepend(List<Node> nodes) native "ParentNode_prepend_Callback";
    Node prependChild(Node node) native "ParentNode_prependChild_Callback";
    void removeChildren() native "ParentNode_removeChildren_Callback";
    Node setChild(Node node) native "ParentNode_setChild_Callback";
    void setChildren(List<Node> nodes) native "ParentNode_setChildren_Callback";
    Element querySelector(String selectors) native "ParentNode_querySelector_Callback";
    List<Element> querySelectorAll(String selectors) native "ParentNode_querySelectorAll_Callback";

    // Operators
}
