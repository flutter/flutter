// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// WARNING: Do not edit - generated code.
part of dart.sky;

class Path2D extends NativeFieldWrapperClass2 {
    // Constructors
    void _constructor() native "Path2D_constructorCallback";
    Path2D() { _constructor(); }

    // Attributes

    // Methods
    void closePath() native "Path2D_closePath_Callback";
    void moveTo(double x, double y) native "Path2D_moveTo_Callback";
    void lineTo(double x, double y) native "Path2D_lineTo_Callback";
    void quadraticCurveTo(double cpx, double cpy, double x, double y) native "Path2D_quadraticCurveTo_Callback";
    void bezierCurveTo(double cp1x, double cp1y, double cp2x, double cp2y, double x, double y) native "Path2D_bezierCurveTo_Callback";
    void arcTo(double x1, double y1, double x2, double y2, double radius) native "Path2D_arcTo_Callback";
    void rect(double x, double y, double width, double height) native "Path2D_rect_Callback";
    void arc(double x, double y, double radius, double startAngle, double endAngle, [bool anticlockwise = false]) native "Path2D_arc_Callback";
    void ellipse(double x, double y, double radiusX, double radiusY, double rotation, double startAngle, double endAngle, [bool anticlockwise = false]) native "Path2D_ellipse_Callback";

    // Operators
}
