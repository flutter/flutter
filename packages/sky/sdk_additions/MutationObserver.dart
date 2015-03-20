// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// WARNING: Do not edit - generated code.
part of dart.sky;

abstract class MutationObserver extends NativeFieldWrapperClass2 {
    // Constructors

    // Attributes

    // Methods
    void observe(Node target) native "MutationObserver_observe_Callback";
    List<MutationRecord> takeRecords() native "MutationObserver_takeRecords_Callback";
    void disconnect() native "MutationObserver_disconnect_Callback";

    // Operators
}
