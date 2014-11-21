/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef AnimatableValue_h
#define AnimatableValue_h

#include "sky/engine/core/css/CSSValue.h"
#include "sky/engine/platform/heap/Handle.h"
#include "sky/engine/wtf/RefCounted.h"

namespace blink {

class AnimatableValue : public RefCounted<AnimatableValue> {
public:
    virtual ~AnimatableValue() { }

    static const AnimatableValue* neutralValue();

    static PassRefPtr<AnimatableValue> interpolate(const AnimatableValue*, const AnimatableValue*, double fraction);
    static double distance(const AnimatableValue* from, const AnimatableValue* to);
    static bool usesDefaultInterpolation(const AnimatableValue* from, const AnimatableValue* to)
    {
        return !from->isSameType(to) || from->usesDefaultInterpolationWith(to);
    }

    bool equals(const AnimatableValue* value) const
    {
        return isSameType(value) && equalTo(value);
    }
    bool equals(const AnimatableValue& value) const
    {
        return equals(&value);
    }

    bool isClipPathOperation() const { return type() == TypeClipPathOperation; }
    bool isColor() const { return type() == TypeColor; }
    bool isDouble() const { return type() == TypeDouble; }
    bool isFilterOperations() const { return type() == TypeFilterOperations; }
    bool isImage() const { return type() == TypeImage; }
    bool isLength() const { return type() == TypeLength; }
    bool isLengthBox() const { return type() == TypeLengthBox; }
    bool isLengthBoxAndBool() const { return type() == TypeLengthBoxAndBool; }
    bool isLengthPoint() const { return type() == TypeLengthPoint; }
    bool isLengthPoint3D() const { return type() == TypeLengthPoint3D; }
    bool isLengthSize() const { return type() == TypeLengthSize; }
    bool isNeutral() const { return type() == TypeNeutral; }
    bool isRepeatable() const { return type() == TypeRepeatable; }
    bool isShadow() const { return type() == TypeShadow; }
    bool isShapeValue() const { return type() == TypeShapeValue; }
    bool isStrokeDasharrayList() const { return type() == TypeStrokeDasharrayList; }
    bool isTransform() const { return type() == TypeTransform; }
    bool isUnknown() const { return type() == TypeUnknown; }

    bool isSameType(const AnimatableValue* value) const
    {
        ASSERT(value);
        return value->type() == type();
    }

protected:
    enum AnimatableType {
        TypeClipPathOperation,
        TypeColor,
        TypeDouble,
        TypeFilterOperations,
        TypeImage,
        TypeLength,
        TypeLengthBox,
        TypeLengthBoxAndBool,
        TypeLengthPoint,
        TypeLengthPoint3D,
        TypeLengthSize,
        TypeNeutral,
        TypeRepeatable,
        TypeShadow,
        TypeShapeValue,
        TypeStrokeDasharrayList,
        TypeTransform,
        TypeUnknown,
    };

    virtual bool usesDefaultInterpolationWith(const AnimatableValue* value) const { return false; }
    virtual PassRefPtr<AnimatableValue> interpolateTo(const AnimatableValue*, double fraction) const = 0;
    static PassRefPtr<AnimatableValue> defaultInterpolateTo(const AnimatableValue* left, const AnimatableValue* right, double fraction) { return takeConstRef((fraction < 0.5) ? left : right); }

    template <class T>
    static PassRefPtr<T> takeConstRef(const T* value) { return PassRefPtr<T>(const_cast<T*>(value)); }

private:
    virtual AnimatableType type() const = 0;
    // Implementations can assume that the object being compared has the same type as the object this is called on
    virtual bool equalTo(const AnimatableValue*) const = 0;

    virtual double distanceTo(const AnimatableValue*) const;

    template <class Keyframe> friend class KeyframeEffectModel;
};

#define DEFINE_ANIMATABLE_VALUE_TYPE_CASTS(thisType, predicate) \
    DEFINE_TYPE_CASTS(thisType, AnimatableValue, value, value->predicate, value.predicate)

} // namespace blink

#endif // AnimatableValue_h
