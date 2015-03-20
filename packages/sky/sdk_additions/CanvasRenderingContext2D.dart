// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// WARNING: Do not edit - generated code.
part of dart.sky;

abstract class CanvasRenderingContext2D extends NativeFieldWrapperClass2 {
    // Constructors

    // Attributes
    HTMLCanvasElement get canvas native "CanvasRenderingContext2D_canvas_Getter";
    bool get imageSmoothingEnabled native "CanvasRenderingContext2D_imageSmoothingEnabled_Getter";
    void set imageSmoothingEnabled(bool value) native "CanvasRenderingContext2D_imageSmoothingEnabled_Setter";
    String get strokeColor native "CanvasRenderingContext2D_strokeColor_Getter";
    void set strokeColor(String value) native "CanvasRenderingContext2D_strokeColor_Setter";
    String get fillColor native "CanvasRenderingContext2D_fillColor_Getter";
    void set fillColor(String value) native "CanvasRenderingContext2D_fillColor_Setter";
    double get shadowOffsetX native "CanvasRenderingContext2D_shadowOffsetX_Getter";
    void set shadowOffsetX(double value) native "CanvasRenderingContext2D_shadowOffsetX_Setter";
    double get shadowOffsetY native "CanvasRenderingContext2D_shadowOffsetY_Getter";
    void set shadowOffsetY(double value) native "CanvasRenderingContext2D_shadowOffsetY_Setter";
    double get shadowBlur native "CanvasRenderingContext2D_shadowBlur_Getter";
    void set shadowBlur(double value) native "CanvasRenderingContext2D_shadowBlur_Setter";
    String get shadowColor native "CanvasRenderingContext2D_shadowColor_Getter";
    void set shadowColor(String value) native "CanvasRenderingContext2D_shadowColor_Setter";
    double get lineWidth native "CanvasRenderingContext2D_lineWidth_Getter";
    void set lineWidth(double value) native "CanvasRenderingContext2D_lineWidth_Setter";
    String get lineCap native "CanvasRenderingContext2D_lineCap_Getter";
    void set lineCap(String value) native "CanvasRenderingContext2D_lineCap_Setter";
    String get lineJoin native "CanvasRenderingContext2D_lineJoin_Getter";
    void set lineJoin(String value) native "CanvasRenderingContext2D_lineJoin_Setter";
    double get miterLimit native "CanvasRenderingContext2D_miterLimit_Getter";
    void set miterLimit(double value) native "CanvasRenderingContext2D_miterLimit_Setter";
    double get lineDashOffset native "CanvasRenderingContext2D_lineDashOffset_Getter";
    void set lineDashOffset(double value) native "CanvasRenderingContext2D_lineDashOffset_Setter";
    String get font native "CanvasRenderingContext2D_font_Getter";
    void set font(String value) native "CanvasRenderingContext2D_font_Setter";
    String get textAlign native "CanvasRenderingContext2D_textAlign_Getter";
    void set textAlign(String value) native "CanvasRenderingContext2D_textAlign_Setter";
    String get textBaseline native "CanvasRenderingContext2D_textBaseline_Getter";
    void set textBaseline(String value) native "CanvasRenderingContext2D_textBaseline_Setter";
    String get direction native "CanvasRenderingContext2D_direction_Getter";
    void set direction(String value) native "CanvasRenderingContext2D_direction_Setter";

    // Methods
    void save() native "CanvasRenderingContext2D_save_Callback";
    void restore() native "CanvasRenderingContext2D_restore_Callback";
    void scale(double x, double y) native "CanvasRenderingContext2D_scale_Callback";
    void rotate(double angle) native "CanvasRenderingContext2D_rotate_Callback";
    void translate(double x, double y) native "CanvasRenderingContext2D_translate_Callback";
    void transform(double a, double b, double c, double d, double e, double f) native "CanvasRenderingContext2D_transform_Callback";
    void setTransform(double a, double b, double c, double d, double e, double f) native "CanvasRenderingContext2D_setTransform_Callback";
    void resetTransform() native "CanvasRenderingContext2D_resetTransform_Callback";
    CanvasGradient createLinearGradient(double x0, double y0, double x1, double y1) native "CanvasRenderingContext2D_createLinearGradient_Callback";
    CanvasGradient createRadialGradient(double x0, double y0, double r0, double x1, double y1, double r1) native "CanvasRenderingContext2D_createRadialGradient_Callback";
    CanvasPattern createPattern(HTMLCanvasElement canvas, String repetitionType) native "CanvasRenderingContext2D_createPattern_Callback";
    void clearRect(double x, double y, double width, double height) native "CanvasRenderingContext2D_clearRect_Callback";
    void fillRect(double x, double y, double width, double height) native "CanvasRenderingContext2D_fillRect_Callback";
    void strokeRect(double x, double y, double width, double height) native "CanvasRenderingContext2D_strokeRect_Callback";
    void beginPath() native "CanvasRenderingContext2D_beginPath_Callback";
    void fill([String winding = ""]) native "CanvasRenderingContext2D_fill_Callback";
    void stroke() native "CanvasRenderingContext2D_stroke_Callback";
    void drawFocusIfNeeded(Element element) native "CanvasRenderingContext2D_drawFocusIfNeeded_Callback";
    void clip([String winding = ""]) native "CanvasRenderingContext2D_clip_Callback";
    bool isPointInPath(double x, double y, [String winding = ""]) native "CanvasRenderingContext2D_isPointInPath_Callback";
    bool isPointInStroke(double x, double y) native "CanvasRenderingContext2D_isPointInStroke_Callback";
    void fillText(String text, double x, double y, [double maxWidth = 0.0]) native "CanvasRenderingContext2D_fillText_Callback";
    void strokeText(String text, double x, double y, [double maxWidth = 0.0]) native "CanvasRenderingContext2D_strokeText_Callback";
    TextMetrics measureText(String text) native "CanvasRenderingContext2D_measureText_Callback";
    void drawImage(HTMLImageElement image, double x, double y) native "CanvasRenderingContext2D_drawImage_Callback";
    ImageData createImageData(ImageData imagedata) native "CanvasRenderingContext2D_createImageData_Callback";
    ImageData getImageData(double sx, double sy, double sw, double sh) native "CanvasRenderingContext2D_getImageData_Callback";
    void putImageData(ImageData imagedata, double dx, double dy) native "CanvasRenderingContext2D_putImageData_Callback";
    bool isContextLost() native "CanvasRenderingContext2D_isContextLost_Callback";
    Canvas2DContextAttributes getContextAttributes() native "CanvasRenderingContext2D_getContextAttributes_Callback";
    void setLineWidth(double width) native "CanvasRenderingContext2D_setLineWidth_Callback";
    void setLineCap(String cap) native "CanvasRenderingContext2D_setLineCap_Callback";
    void setLineJoin(String join) native "CanvasRenderingContext2D_setLineJoin_Callback";
    void setMiterLimit(double limit) native "CanvasRenderingContext2D_setMiterLimit_Callback";
    void clearShadow() native "CanvasRenderingContext2D_clearShadow_Callback";
    void setStrokeColor(String color, [double alpha = 0.0]) native "CanvasRenderingContext2D_setStrokeColor_Callback";
    void setFillColor(String color, [double alpha = 0.0]) native "CanvasRenderingContext2D_setFillColor_Callback";
    void drawImageFromRect(HTMLImageElement image, [double sx = 0.0, double sy = 0.0, double sw = 0.0, double sh = 0.0, double dx = 0.0, double dy = 0.0, double dw = 0.0, double dh = 0.0, String compositeOperation = ""]) native "CanvasRenderingContext2D_drawImageFromRect_Callback";
    void setShadow(double width, double height, double blur, [String color = "", double alpha = 0.0]) native "CanvasRenderingContext2D_setShadow_Callback";
    void closePath() native "CanvasRenderingContext2D_closePath_Callback";
    void moveTo(double x, double y) native "CanvasRenderingContext2D_moveTo_Callback";
    void lineTo(double x, double y) native "CanvasRenderingContext2D_lineTo_Callback";
    void quadraticCurveTo(double cpx, double cpy, double x, double y) native "CanvasRenderingContext2D_quadraticCurveTo_Callback";
    void bezierCurveTo(double cp1x, double cp1y, double cp2x, double cp2y, double x, double y) native "CanvasRenderingContext2D_bezierCurveTo_Callback";
    void arcTo(double x1, double y1, double x2, double y2, double radius) native "CanvasRenderingContext2D_arcTo_Callback";
    void rect(double x, double y, double width, double height) native "CanvasRenderingContext2D_rect_Callback";
    void arc(double x, double y, double radius, double startAngle, double endAngle, [bool anticlockwise = false]) native "CanvasRenderingContext2D_arc_Callback";
    void ellipse(double x, double y, double radiusX, double radiusY, double rotation, double startAngle, double endAngle, [bool anticlockwise = false]) native "CanvasRenderingContext2D_ellipse_Callback";

    // Operators
}
