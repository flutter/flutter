/*
 * Copyright (C) 2009 Google Inc. All rights reserved.
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

#include "sky/engine/config.h"
#include "sky/engine/web/WebSettingsImpl.h"

#include "sky/engine/core/frame/Settings.h"
#include "sky/engine/platform/graphics/DeferredImageDecoder.h"

#include "sky/engine/public/platform/WebString.h"
#include "sky/engine/public/platform/WebURL.h"

namespace blink {

WebSettingsImpl::WebSettingsImpl(Settings* settings)
    : m_settings(settings)
    , m_showPaintRects(false)
    , m_renderVSyncNotificationEnabled(false)
    , m_deferredImageDecodingEnabled(false)
    , m_supportDeprecatedTargetDensityDPI(false)
    , m_shrinksViewportContentToFit(false)
    , m_mainFrameResizesAreOrientationChanges(false)
{
    ASSERT(settings);
}

void WebSettingsImpl::setStandardFontFamily(const WebString& font, UScriptCode script)
{
    if (m_settings->genericFontFamilySettings().updateStandard(font, script))
        m_settings->notifyGenericFontFamilyChange();
}

void WebSettingsImpl::setFixedFontFamily(const WebString& font, UScriptCode script)
{
    if (m_settings->genericFontFamilySettings().updateFixed(font, script))
        m_settings->notifyGenericFontFamilyChange();
}

void WebSettingsImpl::setForceZeroLayoutHeight(bool enabled)
{
    m_settings->setForceZeroLayoutHeight(enabled);
}

void WebSettingsImpl::setSerifFontFamily(const WebString& font, UScriptCode script)
{
    if (m_settings->genericFontFamilySettings().updateSerif(font, script))
        m_settings->notifyGenericFontFamilyChange();
}

void WebSettingsImpl::setSansSerifFontFamily(const WebString& font, UScriptCode script)
{
    if (m_settings->genericFontFamilySettings().updateSansSerif(font, script))
        m_settings->notifyGenericFontFamilyChange();
}

void WebSettingsImpl::setCursiveFontFamily(const WebString& font, UScriptCode script)
{
    if (m_settings->genericFontFamilySettings().updateCursive(font, script))
        m_settings->notifyGenericFontFamilyChange();
}

void WebSettingsImpl::setFantasyFontFamily(const WebString& font, UScriptCode script)
{
    if (m_settings->genericFontFamilySettings().updateFantasy(font, script))
        m_settings->notifyGenericFontFamilyChange();
}

void WebSettingsImpl::setPictographFontFamily(const WebString& font, UScriptCode script)
{
    if (m_settings->genericFontFamilySettings().updatePictograph(font, script))
        m_settings->notifyGenericFontFamilyChange();
}

void WebSettingsImpl::setDefaultFontSize(int size)
{
    m_settings->setDefaultFontSize(size);
}

void WebSettingsImpl::setDefaultFixedFontSize(int size)
{
    m_settings->setDefaultFixedFontSize(size);
}

void WebSettingsImpl::setDefaultVideoPosterURL(const WebString& url)
{
    m_settings->setDefaultVideoPosterURL(url);
}

void WebSettingsImpl::setDeviceSupportsTouch(bool deviceSupportsTouch)
{
    m_settings->setDeviceSupportsTouch(deviceSupportsTouch);

    // FIXME: Until the embedder is converted to using the new APIs, set them
    // here to keep the media queries working unchanged.
    if (deviceSupportsTouch) {
        m_settings->setPrimaryPointerType(blink::PointerTypeCoarse);
        m_settings->setPrimaryHoverType(blink::HoverTypeOnDemand);
    } else {
        m_settings->setPrimaryPointerType(blink::PointerTypeNone);
        m_settings->setPrimaryHoverType(blink::HoverTypeNone);
    }
}

void WebSettingsImpl::setDeviceSupportsMouse(bool deviceSupportsMouse)
{
    m_settings->setDeviceSupportsMouse(deviceSupportsMouse);
}

void WebSettingsImpl::setDefaultTextEncodingName(const WebString& encoding)
{
    m_settings->setDefaultTextEncodingName((String)encoding);
}

void WebSettingsImpl::setSupportDeprecatedTargetDensityDPI(bool supportDeprecatedTargetDensityDPI)
{
    m_supportDeprecatedTargetDensityDPI = supportDeprecatedTargetDensityDPI;
}

void WebSettingsImpl::setLoadsImagesAutomatically(bool loadsImagesAutomatically)
{
    m_settings->setLoadsImagesAutomatically(loadsImagesAutomatically);
}

void WebSettingsImpl::setImagesEnabled(bool enabled)
{
    m_settings->setImagesEnabled(enabled);
}

void WebSettingsImpl::setLoadWithOverviewMode(bool enabled)
{
    m_settings->setLoadWithOverviewMode(enabled);
}

void WebSettingsImpl::setAvailablePointerTypes(int pointers)
{
    m_settings->setAvailablePointerTypes(pointers);
}

void WebSettingsImpl::setPrimaryPointerType(PointerType pointer)
{
    m_settings->setPrimaryPointerType(static_cast<blink::PointerType>(pointer));
}

void WebSettingsImpl::setAvailableHoverTypes(int types)
{
    m_settings->setAvailableHoverTypes(types);
}

void WebSettingsImpl::setPrimaryHoverType(HoverType type)
{
    m_settings->setPrimaryHoverType(static_cast<blink::HoverType>(type));
}

void WebSettingsImpl::setDOMPasteAllowed(bool enabled)
{
    m_settings->setDOMPasteAllowed(enabled);
}

void WebSettingsImpl::setShrinksViewportContentToFit(bool shrinkViewportContent)
{
    m_shrinksViewportContentToFit = shrinkViewportContent;
}

void WebSettingsImpl::setUseWideViewport(bool useWideViewport)
{
    m_settings->setUseWideViewport(useWideViewport);
}

void WebSettingsImpl::setDownloadableBinaryFontsEnabled(bool enabled)
{
    m_settings->setDownloadableBinaryFontsEnabled(enabled);
}

void WebSettingsImpl::setJavaScriptCanAccessClipboard(bool enabled)
{
    m_settings->setJavaScriptCanAccessClipboard(enabled);
}

void WebSettingsImpl::setMainFrameClipsContent(bool enabled)
{
    m_settings->setMainFrameClipsContent(enabled);
}

void WebSettingsImpl::setTouchEditingEnabled(bool enabled)
{
    m_settings->setTouchEditingEnabled(enabled);
}

void WebSettingsImpl::setExperimentalWebGLEnabled(bool enabled)
{
    m_settings->setWebGLEnabled(enabled);
}

void WebSettingsImpl::setOpenGLMultisamplingEnabled(bool enabled)
{
    m_settings->setOpenGLMultisamplingEnabled(enabled);
}

void WebSettingsImpl::setRenderVSyncNotificationEnabled(bool enabled)
{
    m_renderVSyncNotificationEnabled = enabled;
}

void WebSettingsImpl::setWebGLErrorsToConsoleEnabled(bool enabled)
{
    m_settings->setWebGLErrorsToConsoleEnabled(enabled);
}

void WebSettingsImpl::setShowPaintRects(bool show)
{
    m_showPaintRects = show;
}

void WebSettingsImpl::setMockGestureTapHighlightsEnabled(bool enabled)
{
    m_settings->setMockGestureTapHighlightsEnabled(enabled);
}

void WebSettingsImpl::setAccelerated2dCanvasEnabled(bool enabled)
{
    m_settings->setAccelerated2dCanvasEnabled(enabled);
}

void WebSettingsImpl::setAccelerated2dCanvasMSAASampleCount(int count)
{
    m_settings->setAccelerated2dCanvasMSAASampleCount(count);
}

void WebSettingsImpl::setAntialiased2dCanvasEnabled(bool enabled)
{
    m_settings->setAntialiased2dCanvasEnabled(enabled);
}

void WebSettingsImpl::setContainerCullingEnabled(bool enabled)
{
    m_settings->setContainerCullingEnabled(enabled);
}

void WebSettingsImpl::setDeferredImageDecodingEnabled(bool enabled)
{
    DeferredImageDecoder::setEnabled(enabled);
    m_deferredImageDecodingEnabled = enabled;
}

void WebSettingsImpl::setMinimumAccelerated2dCanvasSize(int numPixels)
{
    m_settings->setMinimumAccelerated2dCanvasSize(numPixels);
}

void WebSettingsImpl::setAsynchronousSpellCheckingEnabled(bool enabled)
{
    m_settings->setAsynchronousSpellCheckingEnabled(enabled);
}

void WebSettingsImpl::setUnifiedTextCheckerEnabled(bool enabled)
{
    m_settings->setUnifiedTextCheckerEnabled(enabled);
}

void WebSettingsImpl::setPerTilePaintingEnabled(bool enabled)
{
    m_perTilePaintingEnabled = enabled;
}

void WebSettingsImpl::setShouldClearDocumentBackground(bool enabled)
{
    m_settings->setShouldClearDocumentBackground(enabled);
}

int WebSettingsImpl::availablePointerTypes() const
{
    return m_settings->availablePointerTypes();
}

WebSettings::PointerType WebSettingsImpl::primaryPointerType() const
{
    return static_cast<PointerType>(m_settings->primaryPointerType());
}

int WebSettingsImpl::availableHoverTypes() const
{
    return m_settings->availableHoverTypes();
}

WebSettings::HoverType WebSettingsImpl::primaryHoverType() const
{
    return static_cast<HoverType>(m_settings->primaryHoverType());
}

bool WebSettingsImpl::mockGestureTapHighlightsEnabled() const
{
    return m_settings->mockGestureTapHighlightsEnabled();
}

bool WebSettingsImpl::mainFrameResizesAreOrientationChanges() const
{
    return m_mainFrameResizesAreOrientationChanges;
}

bool WebSettingsImpl::shrinksViewportContentToFit() const
{
    return m_shrinksViewportContentToFit;
}

void WebSettingsImpl::setShouldRespectImageOrientation(bool enabled)
{
    m_settings->setShouldRespectImageOrientation(enabled);
}

void WebSettingsImpl::setMediaControlsOverlayPlayButtonEnabled(bool enabled)
{
}

void WebSettingsImpl::setSelectionIncludesAltImageText(bool enabled)
{
    m_settings->setSelectionIncludesAltImageText(enabled);
}

void WebSettingsImpl::setSmartInsertDeleteEnabled(bool enabled)
{
    m_settings->setSmartInsertDeleteEnabled(enabled);
}

void WebSettingsImpl::setMainFrameResizesAreOrientationChanges(bool enabled)
{
    m_mainFrameResizesAreOrientationChanges = enabled;
}

} // namespace blink
