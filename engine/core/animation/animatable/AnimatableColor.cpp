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

#include "config.h"
#include "core/animation/animatable/AnimatableColor.h"

#include "platform/animation/AnimationUtilities.h"
#include "wtf/MathExtras.h"

namespace {

double square(double x)
{
    return x * x;
}

} // namespace

namespace blink {

AnimatableColorImpl::AnimatableColorImpl(float red, float green, float blue, float alpha)
    : m_alpha(clampTo(alpha, 0.0f, 1.0f))
    , m_red(clampTo(red, 0.0f, 1.0f))
    , m_green(clampTo(green, 0.0f, 1.0f))
    , m_blue(clampTo(blue, 0.0f, 1.0f))
{
}

AnimatableColorImpl::AnimatableColorImpl(Color color)
    : m_alpha(color.alpha() / 255.0f)
    , m_red(color.red() / 255.0f * m_alpha)
    , m_green(color.green() / 255.0f * m_alpha)
    , m_blue(color.blue() / 255.0f * m_alpha)
{
}

Color AnimatableColorImpl::toColor() const
{
    if (!m_alpha)
        return Color::transparent;
    return Color(m_red / m_alpha, m_green / m_alpha, m_blue / m_alpha, m_alpha);
}

AnimatableColorImpl AnimatableColorImpl::interpolateTo(const AnimatableColorImpl& to, double fraction) const
{
    return AnimatableColorImpl(blend(m_red, to.m_red, fraction),
        blend(m_green, to.m_green, fraction),
        blend(m_blue, to.m_blue, fraction),
        blend(m_alpha, to.m_alpha, fraction));
}

bool AnimatableColorImpl::operator==(const AnimatableColorImpl& other) const
{
    return m_red == other.m_red
        && m_green == other.m_green
        && m_blue == other.m_blue
        && m_alpha == other.m_alpha;
}

double AnimatableColorImpl::distanceTo(const AnimatableColorImpl& other) const
{
    return sqrt(square(m_red - other.m_red)
        + square(m_green - other.m_green)
        + square(m_blue - other.m_blue)
        + square(m_alpha - other.m_alpha));
}

PassRefPtrWillBeRawPtr<AnimatableColor> AnimatableColor::create(const AnimatableColorImpl& color, const AnimatableColorImpl& visitedLinkColor)
{
    return adoptRefWillBeNoop(new AnimatableColor(color, visitedLinkColor));
}

PassRefPtrWillBeRawPtr<AnimatableValue> AnimatableColor::interpolateTo(const AnimatableValue* value, double fraction) const
{
    const AnimatableColor* color = toAnimatableColor(value);
    return create(m_color.interpolateTo(color->m_color, fraction),
        m_visitedLinkColor.interpolateTo(color->m_visitedLinkColor, fraction));
}

bool AnimatableColor::equalTo(const AnimatableValue* value) const
{
    const AnimatableColor* color = toAnimatableColor(value);
    return m_color == color->m_color && m_visitedLinkColor == color->m_visitedLinkColor;
}

double AnimatableColor::distanceTo(const AnimatableValue* value) const
{
    const AnimatableColor* color = toAnimatableColor(value);
    return m_color.distanceTo(color->m_color);
}

} // namespace blink
