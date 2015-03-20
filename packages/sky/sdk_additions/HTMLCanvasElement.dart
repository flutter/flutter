// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// WARNING: Do not edit - generated code.
part of dart.sky;

abstract class HTMLCanvasElement extends HTMLElement {
    // Constructors

    // Attributes
    int get width native "HTMLCanvasElement_width_Getter";
    void set width(int value) native "HTMLCanvasElement_width_Setter";
    int get height native "HTMLCanvasElement_height_Getter";
    void set height(int value) native "HTMLCanvasElement_height_Setter";

    // Methods
    String toDataURL([String type = ""]) native "HTMLCanvasElement_toDataURL_Callback";
    CanvasRenderingContext2D getContext(String contextId) native "HTMLCanvasElement_getContext_Callback";

    // Operators
}
