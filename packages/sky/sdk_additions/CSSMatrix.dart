// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// WARNING: Do not edit - generated code.
part of dart.sky;

class CSSMatrix extends NativeFieldWrapperClass2 {
    // Constructors
    void _constructor(String cssValue) native "CSSMatrix_constructorCallback";
    CSSMatrix([String cssValue = ""]) { _constructor(cssValue); }

    // Attributes
    double get a native "CSSMatrix_a_Getter";
    void set a(double value) native "CSSMatrix_a_Setter";
    double get b native "CSSMatrix_b_Getter";
    void set b(double value) native "CSSMatrix_b_Setter";
    double get c native "CSSMatrix_c_Getter";
    void set c(double value) native "CSSMatrix_c_Setter";
    double get d native "CSSMatrix_d_Getter";
    void set d(double value) native "CSSMatrix_d_Setter";
    double get e native "CSSMatrix_e_Getter";
    void set e(double value) native "CSSMatrix_e_Setter";
    double get f native "CSSMatrix_f_Getter";
    void set f(double value) native "CSSMatrix_f_Setter";
    double get m11 native "CSSMatrix_m11_Getter";
    void set m11(double value) native "CSSMatrix_m11_Setter";
    double get m12 native "CSSMatrix_m12_Getter";
    void set m12(double value) native "CSSMatrix_m12_Setter";
    double get m13 native "CSSMatrix_m13_Getter";
    void set m13(double value) native "CSSMatrix_m13_Setter";
    double get m14 native "CSSMatrix_m14_Getter";
    void set m14(double value) native "CSSMatrix_m14_Setter";
    double get m21 native "CSSMatrix_m21_Getter";
    void set m21(double value) native "CSSMatrix_m21_Setter";
    double get m22 native "CSSMatrix_m22_Getter";
    void set m22(double value) native "CSSMatrix_m22_Setter";
    double get m23 native "CSSMatrix_m23_Getter";
    void set m23(double value) native "CSSMatrix_m23_Setter";
    double get m24 native "CSSMatrix_m24_Getter";
    void set m24(double value) native "CSSMatrix_m24_Setter";
    double get m31 native "CSSMatrix_m31_Getter";
    void set m31(double value) native "CSSMatrix_m31_Setter";
    double get m32 native "CSSMatrix_m32_Getter";
    void set m32(double value) native "CSSMatrix_m32_Setter";
    double get m33 native "CSSMatrix_m33_Getter";
    void set m33(double value) native "CSSMatrix_m33_Setter";
    double get m34 native "CSSMatrix_m34_Getter";
    void set m34(double value) native "CSSMatrix_m34_Setter";
    double get m41 native "CSSMatrix_m41_Getter";
    void set m41(double value) native "CSSMatrix_m41_Setter";
    double get m42 native "CSSMatrix_m42_Getter";
    void set m42(double value) native "CSSMatrix_m42_Setter";
    double get m43 native "CSSMatrix_m43_Getter";
    void set m43(double value) native "CSSMatrix_m43_Setter";
    double get m44 native "CSSMatrix_m44_Getter";
    void set m44(double value) native "CSSMatrix_m44_Setter";

    // Methods
    void setMatrixValue([String string = ""]) native "CSSMatrix_setMatrixValue_Callback";
    CSSMatrix multiply([CSSMatrix secondMatrix = null]) native "CSSMatrix_multiply_Callback";
    CSSMatrix inverse() native "CSSMatrix_inverse_Callback";
    CSSMatrix translate([double x = 0.0, double y = 0.0, double z = 0.0]) native "CSSMatrix_translate_Callback";
    CSSMatrix scale([double scaleX = 0.0, double scaleY = 0.0, double scaleZ = 0.0]) native "CSSMatrix_scale_Callback";
    CSSMatrix rotate([double rotX = 0.0, double rotY = 0.0, double rotZ = 0.0]) native "CSSMatrix_rotate_Callback";
    CSSMatrix rotateAxisAngle([double x = 0.0, double y = 0.0, double z = 0.0, double angle = 0.0]) native "CSSMatrix_rotateAxisAngle_Callback";
    CSSMatrix skewX([double angle = 0.0]) native "CSSMatrix_skewX_Callback";
    CSSMatrix skewY([double angle = 0.0]) native "CSSMatrix_skewY_Callback";

    // Operators
}
