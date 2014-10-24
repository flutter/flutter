/*
 * Copyright (C) 2008 Apple Inc. All Rights Reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef CSSMatrix_h
#define CSSMatrix_h

#include "bindings/core/v8/ScriptWrappable.h"
#include "platform/transforms/TransformationMatrix.h"
#include "wtf/RefCounted.h"
#include "wtf/text/WTFString.h"

namespace blink {

class ExceptionState;

class CSSMatrix final : public RefCountedWillBeGarbageCollected<CSSMatrix>, public ScriptWrappable {
    DEFINE_WRAPPERTYPEINFO();
public:
    static PassRefPtrWillBeRawPtr<CSSMatrix> create(const TransformationMatrix& m)
    {
        return adoptRefWillBeNoop(new CSSMatrix(m));
    }
    static PassRefPtrWillBeRawPtr<CSSMatrix> create(const String& s, ExceptionState& exceptionState)
    {
        return adoptRefWillBeNoop(new CSSMatrix(s, exceptionState));
    }

    double a() const { return m_matrix.a(); }
    double b() const { return m_matrix.b(); }
    double c() const { return m_matrix.c(); }
    double d() const { return m_matrix.d(); }
    double e() const { return m_matrix.e(); }
    double f() const { return m_matrix.f(); }

    void setA(double f) { m_matrix.setA(f); }
    void setB(double f) { m_matrix.setB(f); }
    void setC(double f) { m_matrix.setC(f); }
    void setD(double f) { m_matrix.setD(f); }
    void setE(double f) { m_matrix.setE(f); }
    void setF(double f) { m_matrix.setF(f); }

    double m11() const { return m_matrix.m11(); }
    double m12() const { return m_matrix.m12(); }
    double m13() const { return m_matrix.m13(); }
    double m14() const { return m_matrix.m14(); }
    double m21() const { return m_matrix.m21(); }
    double m22() const { return m_matrix.m22(); }
    double m23() const { return m_matrix.m23(); }
    double m24() const { return m_matrix.m24(); }
    double m31() const { return m_matrix.m31(); }
    double m32() const { return m_matrix.m32(); }
    double m33() const { return m_matrix.m33(); }
    double m34() const { return m_matrix.m34(); }
    double m41() const { return m_matrix.m41(); }
    double m42() const { return m_matrix.m42(); }
    double m43() const { return m_matrix.m43(); }
    double m44() const { return m_matrix.m44(); }

    void setM11(double f) { m_matrix.setM11(f); }
    void setM12(double f) { m_matrix.setM12(f); }
    void setM13(double f) { m_matrix.setM13(f); }
    void setM14(double f) { m_matrix.setM14(f); }
    void setM21(double f) { m_matrix.setM21(f); }
    void setM22(double f) { m_matrix.setM22(f); }
    void setM23(double f) { m_matrix.setM23(f); }
    void setM24(double f) { m_matrix.setM24(f); }
    void setM31(double f) { m_matrix.setM31(f); }
    void setM32(double f) { m_matrix.setM32(f); }
    void setM33(double f) { m_matrix.setM33(f); }
    void setM34(double f) { m_matrix.setM34(f); }
    void setM41(double f) { m_matrix.setM41(f); }
    void setM42(double f) { m_matrix.setM42(f); }
    void setM43(double f) { m_matrix.setM43(f); }
    void setM44(double f) { m_matrix.setM44(f); }

    void setMatrixValue(const String&, ExceptionState&);

    // The following math function return a new matrix with the
    // specified operation applied. The this value is not modified.

    // Multiply this matrix by secondMatrix, on the right (result = this * secondMatrix)
    PassRefPtrWillBeRawPtr<CSSMatrix> multiply(CSSMatrix* secondMatrix) const;

    // Return the inverse of this matrix. Throw an exception if the matrix is not invertible
    PassRefPtrWillBeRawPtr<CSSMatrix> inverse(ExceptionState&) const;

    // Return this matrix translated by the passed values.
    // Passing a NaN will use a value of 0. This allows the 3D form to used for 2D operations
    // Operation is performed as though the this matrix is multiplied by a matrix with
    // the translation values on the left (result = translation(x,y,z) * this)
    PassRefPtrWillBeRawPtr<CSSMatrix> translate(double x, double y, double z) const;

    // Returns this matrix scaled by the passed values.
    // Passing scaleX or scaleZ as NaN uses a value of 1, but passing scaleY of NaN
    // makes it the same as scaleX. This allows the 3D form to used for 2D operations
    // Operation is performed as though the this matrix is multiplied by a matrix with
    // the scale values on the left (result = scale(x,y,z) * this)
    PassRefPtrWillBeRawPtr<CSSMatrix> scale(double scaleX, double scaleY, double scaleZ) const;

    // Returns this matrix rotated by the passed values.
    // If rotY and rotZ are NaN, rotate about Z (rotX=0, rotateY=0, rotateZ=rotX).
    // Otherwise use a rotation value of 0 for any passed NaN.
    // Operation is performed as though the this matrix is multiplied by a matrix with
    // the rotation values on the left (result = rotation(x,y,z) * this)
    PassRefPtrWillBeRawPtr<CSSMatrix> rotate(double rotX, double rotY, double rotZ) const;

    // Returns this matrix rotated about the passed axis by the passed angle.
    // Passing a NaN will use a value of 0. If the axis is (0,0,0) use a value
    // Operation is performed as though the this matrix is multiplied by a matrix with
    // the rotation values on the left (result = rotation(x,y,z,angle) * this)
    PassRefPtrWillBeRawPtr<CSSMatrix> rotateAxisAngle(double x, double y, double z, double angle) const;

    // Return this matrix skewed along the X axis by the passed values.
    // Passing a NaN will use a value of 0.
    // Operation is performed as though the this matrix is multiplied by a matrix with
    // the skew values on the left (result = skewX(angle) * this)
    PassRefPtrWillBeRawPtr<CSSMatrix> skewX(double angle) const;

    // Return this matrix skewed along the Y axis by the passed values.
    // Passing a NaN will use a value of 0.
    // Operation is performed as though the this matrix is multiplied by a matrix with
    // the skew values on the left (result = skewY(angle) * this)
    PassRefPtrWillBeRawPtr<CSSMatrix> skewY(double angle) const;

    const TransformationMatrix& transform() const { return m_matrix; }

    String toString() const;

    void trace(Visitor*) { }

protected:
    CSSMatrix(const TransformationMatrix&);
    CSSMatrix(const String&, ExceptionState&);

    TransformationMatrix m_matrix;
};

} // namespace blink

#endif // CSSMatrix_h
