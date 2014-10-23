/*
 * Copyright (C) 2003, 2006 Apple Computer, Inc.  All rights reserved.
 * Copyright (C) 2005 Nokia.  All rights reserved.
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

#include "config.h"
#include "platform/geometry/FloatSize.h"

#include "platform/FloatConversion.h"
#include "platform/geometry/IntSize.h"
#include "platform/geometry/LayoutSize.h"
#include <limits>
#include <math.h>

namespace blink {

FloatSize::FloatSize(const LayoutSize& size)
    : m_width(size.width().toFloat())
    , m_height(size.height().toFloat())
{
}

float FloatSize::diagonalLength() const
{
    return sqrtf(diagonalLengthSquared());
}

bool FloatSize::isZero() const
{
    return fabs(m_width) < std::numeric_limits<float>::epsilon() && fabs(m_height) < std::numeric_limits<float>::epsilon();
}

bool FloatSize::isExpressibleAsIntSize() const
{
    return isWithinIntRange(m_width) && isWithinIntRange(m_height);
}

FloatSize FloatSize::narrowPrecision(double width, double height)
{
    return FloatSize(narrowPrecisionToFloat(width), narrowPrecisionToFloat(height));
}

}
