// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// WARNING: Do not edit - generated code.
part of dart.sky;

abstract class UIEvent extends Event {
    // Constructors

    // Attributes
    Window get view native "UIEvent_view_Getter";
    int get detail native "UIEvent_detail_Getter";
    int get layerX native "UIEvent_layerX_Getter";
    int get layerY native "UIEvent_layerY_Getter";
    int get pageX native "UIEvent_pageX_Getter";
    int get pageY native "UIEvent_pageY_Getter";
    int get keyCode native "UIEvent_keyCode_Getter";
    int get charCode native "UIEvent_charCode_Getter";
    int get which native "UIEvent_which_Getter";

    // Methods
    void initUIEvent([String type = "", bool canBubble = false, bool cancelable = false, Window view = null, int detail = 0]) native "UIEvent_initUIEvent_Callback";

    // Operators
}
