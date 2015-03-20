// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// WARNING: Do not edit - generated code.
part of dart.sky;

abstract class EventTarget extends NativeFieldWrapperClass2 {
    // Constructors

    // Attributes

    // Methods
    void addEventListener(String type, EventListener listener, [bool useCapture = false]) native "EventTarget_addEventListener_Callback";
    void removeEventListener(String type, EventListener listener, [bool useCapture = false]) native "EventTarget_removeEventListener_Callback";
    bool dispatchEvent(Event event) native "EventTarget_dispatchEvent_Callback";

    // Operators
}
