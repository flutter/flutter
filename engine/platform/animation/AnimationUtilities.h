/*
 * Copyright (C) 2011 Apple Inc.  All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE COMPUTER, INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE COMPUTER, INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef AnimationUtilities_h
#define AnimationUtilities_h

#include "platform/LayoutUnit.h"
#include "platform/PlatformExport.h"
#include "platform/geometry/FloatPoint.h"
#include "platform/geometry/IntPoint.h"
#include "wtf/MathExtras.h"
#include "wtf/TypeTraits.h"

namespace blink {

inline int blend(int from, int to, double progress)
{
    return lround(from + (to - from) * progress);
}

// For unsigned types.
template <typename T>
inline T blend(T from, T to, double progress)
{
    COMPILE_ASSERT(WTF::IsInteger<T>::value, BlendForUnsignedTypes);
    return clampTo<T>(round(to > from ? from + (to - from) * progress : from - (from - to) * progress));
}

inline double blend(double from, double to, double progress)
{
    return from + (to - from) * progress;
}

inline float blend(float from, float to, double progress)
{
    return static_cast<float>(from + (to - from) * progress);
}

inline LayoutUnit blend(LayoutUnit from, LayoutUnit to, double progress)
{
    return from + (to - from) * progress;
}

inline IntPoint blend(const IntPoint& from, const IntPoint& to, double progress)
{
    return IntPoint(blend(from.x(), to.x(), progress), blend(from.y(), to.y(), progress));
}

inline FloatPoint blend(const FloatPoint& from, const FloatPoint& to, double progress)
{
    return FloatPoint(blend(from.x(), to.x(), progress), blend(from.y(), to.y(), progress));
}

// Calculates the accuracy for evaluating a timing function for an animation with the specified duration.
inline double accuracyForDuration(double duration)
{
    return 1.0 / (200.0 * duration);
}

} // namespace blink

#endif // AnimationUtilities_h
