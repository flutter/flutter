// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// WARNING: Do not edit - generated code.
part of dart.sky;

abstract class CompositionEvent extends UIEvent {
    // Constructors

    // Attributes
    String get data native "CompositionEvent_data_Getter";
    int get activeSegmentStart native "CompositionEvent_activeSegmentStart_Getter";
    int get activeSegmentEnd native "CompositionEvent_activeSegmentEnd_Getter";

    // Methods
    List<int> getSegments() native "CompositionEvent_getSegments_Callback";
    void initCompositionEvent([String typeArg = "", bool canBubbleArg = false, bool cancelableArg = false, Window viewArg = null, String dataArg = ""]) native "CompositionEvent_initCompositionEvent_Callback";

    // Operators
}
