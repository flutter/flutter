/*
 * Copyright (c) 2006, 2007, 2008, Google Inc. All rights reserved.
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
#include "public/platform/Platform.h"

#include "SkTypeface.h"
#include "platform/LayoutTestSupport.h"
#include "platform/RuntimeEnabledFeatures.h"
#include "platform/fonts/FontPlatformData.h"
#include "platform/graphics/GraphicsContext.h"
#include "public/platform/linux/WebFontRenderStyle.h"
#include "public/platform/linux/WebSandboxSupport.h"

namespace blink {

static SkPaint::Hinting skiaHinting = SkPaint::kNormal_Hinting;
static bool useSkiaAutoHint = true;
static bool useSkiaBitmaps = true;
static bool useSkiaAntiAlias = true;
static bool useSkiaSubpixelRendering = false;

void FontPlatformData::setHinting(SkPaint::Hinting hinting)
{
    skiaHinting = hinting;
}

void FontPlatformData::setAutoHint(bool useAutoHint)
{
    useSkiaAutoHint = useAutoHint;
}

void FontPlatformData::setUseBitmaps(bool useBitmaps)
{
    useSkiaBitmaps = useBitmaps;
}

void FontPlatformData::setAntiAlias(bool useAntiAlias)
{
    useSkiaAntiAlias = useAntiAlias;
}

void FontPlatformData::setSubpixelRendering(bool useSubpixelRendering)
{
    useSkiaSubpixelRendering = useSubpixelRendering;
}

void FontPlatformData::setupPaint(SkPaint* paint, GraphicsContext* context)
    const
{
    paint->setAntiAlias(m_style.useAntiAlias);
    paint->setHinting(static_cast<SkPaint::Hinting>(m_style.hintStyle));
    paint->setEmbeddedBitmapText(m_style.useBitmaps);
    paint->setAutohinted(m_style.useAutoHint);
    if (m_style.useAntiAlias)
        paint->setLCDRenderText(m_style.useSubpixelRendering);

    // Do not enable subpixel text on low-dpi if full hinting is requested.
    bool useSubpixelText = RuntimeEnabledFeatures::subpixelFontScalingEnabled()
        && (paint->getHinting() != SkPaint::kFull_Hinting
            || (context && context->deviceScaleFactor() > 1.0f));

    // TestRunner specifically toggles the subpixel positioning flag.
    if (useSubpixelText && !LayoutTestSupport::isRunningLayoutTest())
        paint->setSubpixelText(true);
    else
        paint->setSubpixelText(m_style.useSubpixelPositioning);

    const float ts = m_textSize >= 0 ? m_textSize : 12;
    paint->setTextSize(SkFloatToScalar(ts));
    paint->setTypeface(m_typeface.get());
    paint->setFakeBoldText(m_syntheticBold);
    paint->setTextSkewX(m_syntheticItalic ? -SK_Scalar1 / 4 : 0);
}

void FontPlatformData::querySystemForRenderStyle(bool useSkiaSubpixelPositioning)
{
    WebFontRenderStyle style;
#if OS(ANDROID)
    style.setDefaults();
#else
    // If the font name is missing (i.e. probably a web font) or the sandbox is disabled, use the system defaults.
    if (!m_family.length() || !Platform::current()->sandboxSupport()) {
        style.setDefaults();
    } else {
        const int sizeAndStyle = (((int)m_textSize) << 2) | (m_typeface->style() & 3);
        Platform::current()->sandboxSupport()->getRenderStyleForStrike(m_family.data(), sizeAndStyle, &style);
    }
#endif
    style.toFontRenderStyle(&m_style);

    // Fix FontRenderStyle::NoPreference to actual styles.
    if (m_style.useAntiAlias == FontRenderStyle::NoPreference)
        m_style.useAntiAlias = useSkiaAntiAlias;

    if (!m_style.useHinting)
        m_style.hintStyle = SkPaint::kNo_Hinting;
    else if (m_style.useHinting == FontRenderStyle::NoPreference)
        m_style.hintStyle = skiaHinting;

    if (m_style.useBitmaps == FontRenderStyle::NoPreference)
        m_style.useBitmaps = useSkiaBitmaps;
    if (m_style.useAutoHint == FontRenderStyle::NoPreference)
        m_style.useAutoHint = useSkiaAutoHint;
    if (m_style.useAntiAlias == FontRenderStyle::NoPreference)
        m_style.useAntiAlias = useSkiaAntiAlias;
    if (m_style.useSubpixelRendering == FontRenderStyle::NoPreference)
        m_style.useSubpixelRendering = useSkiaSubpixelRendering;

    // TestRunner specifically toggles the subpixel positioning flag.
    if (m_style.useSubpixelPositioning == FontRenderStyle::NoPreference
        || LayoutTestSupport::isRunningLayoutTest())
        m_style.useSubpixelPositioning = useSkiaSubpixelPositioning;
}

bool FontPlatformData::defaultUseSubpixelPositioning()
{
    return FontDescription::subpixelPositioning();
}

} // namespace blink
