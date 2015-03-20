// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// WARNING: Do not edit - generated code.
part of dart.sky;

class Range extends NativeFieldWrapperClass2 {
    // Constructors
    void _constructor() native "Range_constructorCallback";
    Range() { _constructor(); }

    // Attributes
    Node get startContainer native "Range_startContainer_Getter";
    int get startOffset native "Range_startOffset_Getter";
    Node get endContainer native "Range_endContainer_Getter";
    int get endOffset native "Range_endOffset_Getter";
    bool get collapsed native "Range_collapsed_Getter";
    Node get commonAncestorContainer native "Range_commonAncestorContainer_Getter";

    // Methods
    void setStart(Node refNode, int offset) native "Range_setStart_Callback";
    void setEnd(Node refNode, int offset) native "Range_setEnd_Callback";
    void setStartBefore(Node refNode) native "Range_setStartBefore_Callback";
    void setStartAfter(Node refNode) native "Range_setStartAfter_Callback";
    void setEndBefore(Node refNode) native "Range_setEndBefore_Callback";
    void setEndAfter(Node refNode) native "Range_setEndAfter_Callback";
    void collapse([bool toStart = false]) native "Range_collapse_Callback";
    void selectNode(Node refNode) native "Range_selectNode_Callback";
    void selectNodeContents(Node refNode) native "Range_selectNodeContents_Callback";
    void deleteContents() native "Range_deleteContents_Callback";
    DocumentFragment extractContents() native "Range_extractContents_Callback";
    DocumentFragment cloneContents() native "Range_cloneContents_Callback";
    void insertNode(Node newNode) native "Range_insertNode_Callback";
    void surroundContents(Node newParent) native "Range_surroundContents_Callback";
    Range cloneRange() native "Range_cloneRange_Callback";
    void detach() native "Range_detach_Callback";
    bool isPointInRange(Node refNode, int offset) native "Range_isPointInRange_Callback";
    int comparePoint(Node refNode, int offset) native "Range_comparePoint_Callback";
    bool intersectsNode(Node refNode) native "Range_intersectsNode_Callback";
    ClientRectList getClientRects() native "Range_getClientRects_Callback";
    ClientRect getBoundingClientRect() native "Range_getBoundingClientRect_Callback";
    int compareNode([Node refNode = null]) native "Range_compareNode_Callback";
    void expand([String unit = ""]) native "Range_expand_Callback";

    // Operators
}
