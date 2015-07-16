/**
 * This file is part of the theme implementation for form controls in WebCore.
 *
 * Copyright (C) 2005, 2006, 2007, 2008, 2009, 2010, 2012 Apple Computer, Inc.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this library; see the file COPYING.LIB.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 */

#include "sky/engine/core/rendering/RenderTheme.h"

#include "gen/sky/core/CSSValueKeywords.h"
#include "gen/sky/platform/RuntimeEnabledFeatures.h"
#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/dom/shadow/ElementShadow.h"
#include "sky/engine/core/editing/FrameSelection.h"
#include "sky/engine/core/frame/LocalFrame.h"
#include "sky/engine/core/frame/Settings.h"
#include "sky/engine/core/html/parser/HTMLParserIdioms.h"
#include "sky/engine/core/page/FocusController.h"
#include "sky/engine/core/page/Page.h"
#include "sky/engine/core/rendering/PaintInfo.h"
#include "sky/engine/core/rendering/RenderView.h"
#include "sky/engine/core/rendering/style/RenderStyle.h"
#include "sky/engine/platform/FloatConversion.h"
#include "sky/engine/platform/fonts/FontSelector.h"
#include "sky/engine/platform/graphics/GraphicsContextStateSaver.h"
#include "sky/engine/platform/text/StringTruncator.h"
#include "sky/engine/public/platform/Platform.h"
#include "sky/engine/public/platform/WebFallbackThemeEngine.h"
#include "sky/engine/public/platform/WebRect.h"
#include "sky/engine/wtf/text/StringBuilder.h"

// The methods in this file are shared by all themes on every platform.

namespace blink {

RenderTheme::RenderTheme()
    : m_hasCustomFocusRingColor(false)
{
}

Color RenderTheme::activeSelectionBackgroundColor() const
{
    return platformActiveSelectionBackgroundColor().blendWithWhite();
}

Color RenderTheme::inactiveSelectionBackgroundColor() const
{
    return platformInactiveSelectionBackgroundColor().blendWithWhite();
}

Color RenderTheme::activeSelectionForegroundColor() const
{
    return platformActiveSelectionForegroundColor();
}

Color RenderTheme::inactiveSelectionForegroundColor() const
{
    return platformInactiveSelectionForegroundColor();
}

Color RenderTheme::platformActiveSelectionBackgroundColor() const
{
    // Use a blue color by default if the platform theme doesn't define anything.
    return Color(0, 0, 255);
}

Color RenderTheme::platformActiveSelectionForegroundColor() const
{
    // Use a white color by default if the platform theme doesn't define anything.
    return Color::white;
}

Color RenderTheme::platformInactiveSelectionBackgroundColor() const
{
    // Use a grey color by default if the platform theme doesn't define anything.
    // This color matches Firefox's inactive color.
    return Color(176, 176, 176);
}

Color RenderTheme::platformInactiveSelectionForegroundColor() const
{
    // Use a black color by default.
    return Color::black;
}

Color RenderTheme::systemColor(CSSValueID cssValueId) const
{
    // FIXME(sky): remove
    return Color();
}

void RenderTheme::setCustomFocusRingColor(const Color& c)
{
    m_customFocusRingColor = c;
    m_hasCustomFocusRingColor = true;
}

Color RenderTheme::focusRingColor() const
{
    return m_hasCustomFocusRingColor ? m_customFocusRingColor : theme().platformFocusRingColor();
}

void RenderTheme::systemFont(CSSValueID valueID, FontDescription& fontDescription) const
{
    DEFINE_STATIC_LOCAL(const AtomicString, defaultGUIFont, ("Arial", AtomicString::ConstructFromLiteral));

    fontDescription.firstFamily().setFamily(defaultGUIFont);
    fontDescription.setSpecifiedSize(12);
    fontDescription.setIsAbsoluteSize(true);
    fontDescription.setGenericFamily(FontDescription::NoFamily);
    fontDescription.setWeight(FontWeightNormal);
    fontDescription.setStyle(FontStyleNormal);
}

Color RenderTheme::tapHighlightColor()
{
    return theme().platformTapHighlightColor();
}

RenderTheme& RenderTheme::theme()
{
    DEFINE_STATIC_LOCAL(RenderTheme, renderTheme, ());
    return renderTheme;
}

} // namespace blink
