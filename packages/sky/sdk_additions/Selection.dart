// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// WARNING: Do not edit - generated code.
part of dart.sky;

abstract class Selection extends NativeFieldWrapperClass2 {
    // Constructors

    // Attributes
    Node get anchorNode native "Selection_anchorNode_Getter";
    int get anchorOffset native "Selection_anchorOffset_Getter";
    Node get focusNode native "Selection_focusNode_Getter";
    int get focusOffset native "Selection_focusOffset_Getter";
    bool get isCollapsed native "Selection_isCollapsed_Getter";
    int get rangeCount native "Selection_rangeCount_Getter";
    Node get baseNode native "Selection_baseNode_Getter";
    int get baseOffset native "Selection_baseOffset_Getter";
    Node get extentNode native "Selection_extentNode_Getter";
    int get extentOffset native "Selection_extentOffset_Getter";
    String get type native "Selection_type_Getter";

    // Methods
    void collapse(Node node, [int offset = 0]) native "Selection_collapse_Callback";
    void collapseToStart() native "Selection_collapseToStart_Callback";
    void collapseToEnd() native "Selection_collapseToEnd_Callback";
    void extend(Node node, [int offset = 0]) native "Selection_extend_Callback";
    void selectAllChildren([Node node = null]) native "Selection_selectAllChildren_Callback";
    void deleteFromDocument() native "Selection_deleteFromDocument_Callback";
    Range getRangeAt([int index = 0]) native "Selection_getRangeAt_Callback";
    void addRange([Range range = null]) native "Selection_addRange_Callback";
    void removeAllRanges() native "Selection_removeAllRanges_Callback";
    bool containsNode([Node node = null, bool allowPartial = false]) native "Selection_containsNode_Callback";
    void modify([String alter = "", String direction = "", String granularity = ""]) native "Selection_modify_Callback";
    void setBaseAndExtent([Node baseNode = null, int baseOffset = 0, Node extentNode = null, int extentOffset = 0]) native "Selection_setBaseAndExtent_Callback";
    void setPosition(Node node, [int offset = 0]) native "Selection_setPosition_Callback";
    void empty() native "Selection_empty_Callback";

    // Operators
}
