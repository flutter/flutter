/*
 * Copyright (C) 2012 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 * ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef WebTransformOperations_h
#define WebTransformOperations_h

class SkMatrix44;

#define WEB_TRANSFORM_OPERATIONS_IS_VIRTUAL 1

namespace blink {

class WebTransformOperations {
public:
    virtual ~WebTransformOperations() { }

    // Returns true if these operations can be blended. It will only return
    // false if we must resort to matrix interpolation, and matrix interpolation
    // fails (this can happen if either matrix cannot be decomposed).
    virtual bool canBlendWith(const WebTransformOperations& other) const = 0;

    virtual void appendTranslate(double x, double y, double z) = 0;
    virtual void appendRotate(double x, double y, double z, double degrees) = 0;
    virtual void appendScale(double x, double y, double z) = 0;
    virtual void appendSkew(double x, double y) = 0;
    virtual void appendPerspective(double depth) = 0;
    virtual void appendMatrix(const SkMatrix44&) = 0;
    virtual void appendIdentity() = 0;

    virtual bool isIdentity() const = 0;
};

} // namespace blink

#endif // WebTransformOperations_h

