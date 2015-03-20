// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// WARNING: Do not edit - generated code.
part of dart.sky;

abstract class HashChangeEvent extends Event {
    // Constructors

    // Attributes
    String get oldURL native "HashChangeEvent_oldURL_Getter";
    String get newURL native "HashChangeEvent_newURL_Getter";

    // Methods
    void initHashChangeEvent([String type = "", bool canBubble = false, bool cancelable = false, String oldURL = "", String newURL = ""]) native "HashChangeEvent_initHashChangeEvent_Callback";

    // Operators
}
