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

#ifndef WebSettings_h
#define WebSettings_h

#include "../platform/WebCommon.h"
#include "../platform/WebSize.h"
#include <unicode/uscript.h>

namespace blink {

class WebString;
class WebURL;

// WebSettings is owned by the WebView and allows code to modify the settings for
// the WebView's page without any knowledge of WebCore itself.  For the most part,
// these functions have a 1:1 mapping with the methods in WebCore/page/Settings.h.
class WebSettings {
public:
    enum EditingBehavior {
        EditingBehaviorMac,
        EditingBehaviorWin,
        EditingBehaviorUnix,
        EditingBehaviorAndroid
    };

    enum V8CacheOptions {
        V8CacheOptionsOff,
        V8CacheOptionsParse,
        V8CacheOptionsCode
    };

    // Bit field values to tell Blink what kind of pointer/hover types are
    // available on the system. These must match the enums in
    // core/css/PointerProperties.h and their equality is compile-time asserted
    // in WebSettingsImpl.cpp.
    enum PointerType {
        PointerTypeNone = 1,
        PointerTypeCoarse = 2,
        PointerTypeFine = 4
    };

    enum HoverType {
        HoverTypeNone = 1,
        // Indicates that the primary pointing system can hover, but it requires
        // a significant action on the user’s part. e.g. hover on “long press”.
        HoverTypeOnDemand = 2,
        HoverTypeHover = 4
    };

    virtual bool mainFrameResizesAreOrientationChanges() const = 0;
    virtual int availablePointerTypes() const = 0;
    virtual PointerType primaryPointerType() const = 0;
    virtual int availableHoverTypes() const = 0;
    virtual HoverType primaryHoverType() const = 0;
    virtual bool shrinksViewportContentToFit() const = 0;
    virtual void setAccelerated2dCanvasEnabled(bool) = 0;
    virtual void setAccelerated2dCanvasMSAASampleCount(int) = 0;
    virtual void setPreferCompositingToLCDTextEnabled(bool) = 0;
    // Not implemented yet, see http://crbug.com/178119
    virtual void setAcceleratedCompositingForTransitionEnabled(bool) { };
    // If set to true, allows frames with an https origin to display passive
    // contents at an insecure URL. Otherwise, disallows it. The
    // FrameLoaderClient set to the frame may override the value set by this
    // method.
    virtual void setAntialiased2dCanvasEnabled(bool) = 0;
    virtual void setAsynchronousSpellCheckingEnabled(bool) = 0;
    virtual void setContainerCullingEnabled(bool) = 0;
    virtual void setCursiveFontFamily(const WebString&, UScriptCode = USCRIPT_COMMON) = 0;
    virtual void setDOMPasteAllowed(bool) = 0;
    virtual void setDefaultFixedFontSize(int) = 0;
    virtual void setDefaultFontSize(int) = 0;
    virtual void setDefaultTextEncodingName(const WebString&) = 0;
    virtual void setDefaultVideoPosterURL(const WebString&) = 0;
    void setDeferred2dCanvasEnabled(bool) { } // temporary stub
    virtual void setDeferredFiltersEnabled(bool) = 0;
    virtual void setDeferredImageDecodingEnabled(bool) = 0;
    virtual void setDeviceSupportsMouse(bool) = 0;
    virtual void setDeviceSupportsTouch(bool) = 0;
    virtual void setDoubleTapToZoomEnabled(bool) = 0;
    virtual void setDownloadableBinaryFontsEnabled(bool) = 0;
    virtual void setEnableTouchAdjustment(bool) = 0;
    virtual void setExperimentalWebGLEnabled(bool) = 0;
    virtual void setFantasyFontFamily(const WebString&, UScriptCode = USCRIPT_COMMON) = 0;
    virtual void setFixedFontFamily(const WebString&, UScriptCode = USCRIPT_COMMON) = 0;
    virtual void setForceZeroLayoutHeight(bool) = 0;
    virtual void setImagesEnabled(bool) = 0;
    virtual void setJavaScriptCanAccessClipboard(bool) = 0;
    virtual void setLoadsImagesAutomatically(bool) = 0;
    virtual void setLoadWithOverviewMode(bool) = 0;
    virtual void setMainFrameClipsContent(bool) = 0;
    virtual void setMainFrameResizesAreOrientationChanges(bool) = 0;
    virtual void setMaxTouchPoints(int) = 0;
    virtual void setMediaControlsOverlayPlayButtonEnabled(bool) = 0;
    virtual void setMediaPlaybackRequiresUserGesture(bool) = 0;
    virtual void setMinimumAccelerated2dCanvasSize(int) = 0;
    virtual void setOpenGLMultisamplingEnabled(bool) = 0;
    virtual void setPerTilePaintingEnabled(bool) = 0;
    virtual void setPictographFontFamily(const WebString&, UScriptCode = USCRIPT_COMMON) = 0;
    virtual void setAvailablePointerTypes(int) = 0;
    virtual void setPrimaryPointerType(PointerType) = 0;
    virtual void setAvailableHoverTypes(int) = 0;
    virtual void setPrimaryHoverType(HoverType) = 0;
    virtual void setRenderVSyncNotificationEnabled(bool) = 0;
    virtual void setSansSerifFontFamily(const WebString&, UScriptCode = USCRIPT_COMMON) = 0;
    virtual void setSelectionIncludesAltImageText(bool) = 0;
    virtual void setSerifFontFamily(const WebString&, UScriptCode = USCRIPT_COMMON) = 0;
    virtual void setShouldClearDocumentBackground(bool) = 0;
    virtual void setShouldRespectImageOrientation(bool) = 0;
    virtual void setShowFPSCounter(bool) = 0;
    virtual void setShowPaintRects(bool) = 0;
    virtual void setShrinksViewportContentToFit(bool) = 0;
    virtual void setSmartInsertDeleteEnabled(bool) = 0;
    virtual void setStandardFontFamily(const WebString&, UScriptCode = USCRIPT_COMMON) = 0;
    virtual void setSupportDeprecatedTargetDensityDPI(bool) = 0;
    virtual void setTextAreasAreResizable(bool) = 0;
    virtual void setTouchEditingEnabled(bool) = 0;
    virtual void setUnifiedTextCheckerEnabled(bool) = 0;
    virtual void setUseSolidColorScrollbars(bool) = 0;
    virtual void setUseWideViewport(bool) = 0;
    virtual void setV8CacheOptions(V8CacheOptions) = 0;
    virtual void setWebGLErrorsToConsoleEnabled(bool) = 0;

protected:
    ~WebSettings() { }
};

} // namespace blink

#endif
