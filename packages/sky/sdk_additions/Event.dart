// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// WARNING: Do not edit - generated code.
part of dart.sky;

class Event extends NativeFieldWrapperClass2 {
    // Constructors
    void _constructor(String type, bool bubbles, bool cancelable) native "Event_constructorCallback";
    Event({String type : "", bool bubbles : false, bool cancelable : false}) { _constructor(type, bubbles, cancelable); }

    // Attributes
    String get type native "Event_type_Getter";
    EventTarget get target native "Event_target_Getter";
    EventTarget get currentTarget native "Event_currentTarget_Getter";
    int get eventPhase native "Event_eventPhase_Getter";
    bool get bubbles native "Event_bubbles_Getter";
    bool get cancelable native "Event_cancelable_Getter";
    double get timeStamp native "Event_timeStamp_Getter";
    bool get defaultPrevented native "Event_defaultPrevented_Getter";
    EventTarget get srcElement native "Event_srcElement_Getter";
    bool get returnValue native "Event_returnValue_Getter";
    void set returnValue(bool value) native "Event_returnValue_Setter";
    bool get cancelBubble native "Event_cancelBubble_Getter";
    void set cancelBubble(bool value) native "Event_cancelBubble_Setter";
    NodeList get path native "Event_path_Getter";

    // Methods
    void stopPropagation() native "Event_stopPropagation_Callback";
    void preventDefault() native "Event_preventDefault_Callback";
    void stopImmediatePropagation() native "Event_stopImmediatePropagation_Callback";

    // Operators
}
