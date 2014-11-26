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

#ifndef SKY_ENGINE_WEB_WEBSETTINGSIMPL_H_
#define SKY_ENGINE_WEB_WEBSETTINGSIMPL_H_

#include "sky/engine/public/web/WebSettings.h"

namespace blink {

class Settings;

class WebSettingsImpl final : public WebSettings {
public:
    explicit WebSettingsImpl(Settings*);
    virtual ~WebSettingsImpl() { }

    virtual bool mainFrameResizesAreOrientationChanges() const override;
    virtual bool shrinksViewportContentToFit() const override;
    virtual int availablePointerTypes() const override;
    virtual PointerType primaryPointerType() const override;
    virtual int availableHoverTypes() const override;
    virtual HoverType primaryHoverType() const override;
    virtual void setAccelerated2dCanvasEnabled(bool) override;
    virtual void setAccelerated2dCanvasMSAASampleCount(int) override;
    virtual void setPreferCompositingToLCDTextEnabled(bool) override;
    virtual void setAntialiased2dCanvasEnabled(bool) override;
    virtual void setAsynchronousSpellCheckingEnabled(bool) override;
    virtual void setContainerCullingEnabled(bool) override;
    virtual void setCursiveFontFamily(const WebString&, UScriptCode = USCRIPT_COMMON) override;
    virtual void setDOMPasteAllowed(bool) override;
    virtual void setDefaultFixedFontSize(int) override;
    virtual void setDefaultFontSize(int) override;
    virtual void setDefaultTextEncodingName(const WebString&) override;
    virtual void setDefaultVideoPosterURL(const WebString&) override;
    virtual void setDeferredFiltersEnabled(bool) override;
    virtual void setDeferredImageDecodingEnabled(bool) override;
    virtual void setDeviceSupportsMouse(bool) override;

    // FIXME: Remove once the pointer/hover features are converted to use the
    // new APIs (e.g. setPrimaryPointerType) on the chromium side
    virtual void setDeviceSupportsTouch(bool) override;

    virtual void setDownloadableBinaryFontsEnabled(bool) override;
    virtual void setEnableTouchAdjustment(bool) override;
    virtual void setExperimentalWebGLEnabled(bool) override;
    virtual void setFantasyFontFamily(const WebString&, UScriptCode = USCRIPT_COMMON) override;
    virtual void setFixedFontFamily(const WebString&, UScriptCode = USCRIPT_COMMON) override;
    virtual void setForceZeroLayoutHeight(bool) override;
    virtual void setImagesEnabled(bool) override;
    virtual void setJavaScriptCanAccessClipboard(bool) override;
    virtual void setLoadsImagesAutomatically(bool) override;
    virtual void setLoadWithOverviewMode(bool) override;
    virtual void setMainFrameClipsContent(bool) override;
    virtual void setMainFrameResizesAreOrientationChanges(bool) override;
    virtual void setMaxTouchPoints(int) override;
    virtual void setMediaControlsOverlayPlayButtonEnabled(bool) override;
    virtual void setMediaPlaybackRequiresUserGesture(bool) override;
    virtual void setMinimumAccelerated2dCanvasSize(int) override;
    virtual void setOpenGLMultisamplingEnabled(bool) override;
    virtual void setPerTilePaintingEnabled(bool) override;
    virtual void setPictographFontFamily(const WebString&, UScriptCode = USCRIPT_COMMON) override;
    virtual void setAvailablePointerTypes(int) override;
    virtual void setPrimaryPointerType(PointerType) override;
    virtual void setAvailableHoverTypes(int) override;
    virtual void setPrimaryHoverType(HoverType) override;
    virtual void setRenderVSyncNotificationEnabled(bool) override;
    virtual void setSansSerifFontFamily(const WebString&, UScriptCode = USCRIPT_COMMON) override;
    virtual void setSelectionIncludesAltImageText(bool) override;
    virtual void setSerifFontFamily(const WebString&, UScriptCode = USCRIPT_COMMON) override;
    virtual void setShouldClearDocumentBackground(bool) override;
    virtual void setShouldRespectImageOrientation(bool) override;
    virtual void setShowFPSCounter(bool) override;
    virtual void setShowPaintRects(bool) override;
    virtual void setShrinksViewportContentToFit(bool) override;
    virtual void setSmartInsertDeleteEnabled(bool) override;
    virtual void setStandardFontFamily(const WebString&, UScriptCode = USCRIPT_COMMON) override;
    virtual void setSupportDeprecatedTargetDensityDPI(bool) override;
    virtual void setTouchEditingEnabled(bool) override;
    virtual void setUnifiedTextCheckerEnabled(bool) override;
    virtual void setUseSolidColorScrollbars(bool) override;
    virtual void setUseWideViewport(bool) override;
    virtual void setV8CacheOptions(V8CacheOptions) override;
    virtual void setWebGLErrorsToConsoleEnabled(bool) override;

    bool showFPSCounter() const { return m_showFPSCounter; }
    bool showPaintRects() const { return m_showPaintRects; }
    bool renderVSyncNotificationEnabled() const { return m_renderVSyncNotificationEnabled; }
    bool perTilePaintingEnabled() const { return m_perTilePaintingEnabled; }
    bool supportDeprecatedTargetDensityDPI() const { return m_supportDeprecatedTargetDensityDPI; }

    void setMockGestureTapHighlightsEnabled(bool);
    bool mockGestureTapHighlightsEnabled() const;

private:
    Settings* m_settings;
    bool m_showFPSCounter;
    bool m_showPaintRects;
    bool m_renderVSyncNotificationEnabled;
    bool m_deferredImageDecodingEnabled;
    bool m_perTilePaintingEnabled;
    bool m_supportDeprecatedTargetDensityDPI;
    bool m_shrinksViewportContentToFit;
    bool m_mainFrameResizesAreOrientationChanges;
};

} // namespace blink

#endif  // SKY_ENGINE_WEB_WEBSETTINGSIMPL_H_
