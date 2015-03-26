// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// WARNING: Do not edit - generated code.
part of dart.sky;

abstract class Window extends EventTarget {
    // Constructors

    // Attributes
    Screen get screen native "Window_screen_Getter";
    Location get location native "Window_location_Getter";
    int get outerHeight native "Window_outerHeight_Getter";
    int get outerWidth native "Window_outerWidth_Getter";
    int get innerHeight native "Window_innerHeight_Getter";
    int get innerWidth native "Window_innerWidth_Getter";
    int get screenX native "Window_screenX_Getter";
    int get screenY native "Window_screenY_Getter";
    int get screenLeft native "Window_screenLeft_Getter";
    int get screenTop native "Window_screenTop_Getter";
    Window get window native "Window_window_Getter";
    Document get document native "Window_document_Getter";
    double get devicePixelRatio native "Window_devicePixelRatio_Getter";
    int get orientation native "Window_orientation_Getter";
    Tracing get tracing native "Window_tracing_Getter";

    // Methods
    Selection getSelection() native "Window_getSelection_Callback";
    void focus() native "Window_focus_Callback";
    void moveBy([double x = 0.0, double y = 0.0]) native "Window_moveBy_Callback";
    void moveTo([double x = 0.0, double y = 0.0]) native "Window_moveTo_Callback";
    void resizeBy([double x = 0.0, double y = 0.0]) native "Window_resizeBy_Callback";
    void resizeTo([double width = 0.0, double height = 0.0]) native "Window_resizeTo_Callback";
    MediaQueryList matchMedia(String query) native "Window_matchMedia_Callback";
    CSSStyleDeclaration getComputedStyle([Element element = null]) native "Window_getComputedStyle_Callback";
    int requestAnimationFrame(RequestAnimationFrameCallback callback) native "Window_requestAnimationFrame_Callback";
    void cancelAnimationFrame(int id) native "Window_cancelAnimationFrame_Callback";
    String btoa(String string) native "Window_btoa_Callback";
    String atob(String string) native "Window_atob_Callback";
    void clearTimeout([int handle = 0]) native "Window_clearTimeout_Callback";
    void clearInterval([int handle = 0]) native "Window_clearInterval_Callback";

    // Operators
}
