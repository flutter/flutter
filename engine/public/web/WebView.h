/*
 * Copyright (C) 2009, 2010, 2011, 2012 Google Inc. All rights reserved.
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

#ifndef WebView_h
#define WebView_h

#include "../platform/WebColor.h"
#include "../platform/WebString.h"
#include "../platform/WebVector.h"
#include "WebDragOperation.h"
#include "WebPageVisibilityState.h"
#include "WebWidget.h"

namespace blink {

class WebFrame;
class WebFrameClient;
class WebGraphicsContext3D;
class WebHitTestResult;
class WebNode;
class WebPageOverlay;
class WebRange;
class WebSettings;
class WebSpellCheckClient;
class WebString;
class WebViewClient;
struct WebActiveWheelFlingParameters;
struct WebMediaPlayerAction;
struct WebPoint;
struct WebFloatPoint;

class WebView : public WebWidget {
public:
    BLINK_EXPORT static const double textSizeMultiplierRatio;
    BLINK_EXPORT static const double minTextSizeMultiplier;
    BLINK_EXPORT static const double maxTextSizeMultiplier;

    // Initialization ------------------------------------------------------

    // Creates a WebView that is NOT yet initialized. You will need to
    // call setMainFrame to finish the initialization. It is valid
    // to pass a null client pointer.
    BLINK_EXPORT static WebView* create(WebViewClient*);

    // After creating a WebView, you should immediately call this method.
    // You can optionally modify the settings before calling this method.
    // This WebFrame will receive events for the main frame and must not
    // be null.
    virtual void setMainFrame(WebFrame*) = 0;

    // Initializes the various client interfaces.
    virtual void setSpellCheckClient(WebSpellCheckClient*) = 0;

    // Options -------------------------------------------------------------

    // The returned pointer is valid for the lifetime of the WebView.
    virtual WebSettings* settings() = 0;

    // Corresponds to the encoding of the main frame.  Setting the page
    // encoding may cause the main frame to reload.
    virtual WebString pageEncoding() const = 0;
    virtual void setPageEncoding(const WebString&) = 0;

    // Makes the WebView transparent.  This is useful if you want to have
    // some custom background rendered behind it.
    virtual bool isTransparent() const = 0;
    virtual void setIsTransparent(bool) = 0;

    // Sets the base color used for this WebView's background. This is in effect
    // the default background color used for pages with no background-color
    // style in effect, or used as the alpha-blended basis for any pages with
    // translucent background-color style. (For pages with opaque
    // background-color style, this property is effectively ignored).
    // Setting this takes effect for the currently loaded page, if any, and
    // persists across subsequent navigations. Defaults to white prior to the
    // first call to this method.
    virtual void setBaseBackgroundColor(WebColor) = 0;

    // Controls whether pressing Tab key advances focus to links.
    virtual bool tabsToLinks() const = 0;
    virtual void setTabsToLinks(bool) = 0;

    // Method that controls whether pressing Tab key cycles through page
    // elements or inserts a '\t' char in the focused text area.
    virtual bool tabKeyCyclesThroughElements() const = 0;
    virtual void setTabKeyCyclesThroughElements(bool) = 0;

    // Controls the WebView's active state, which may affect the rendering
    // of elements on the page (i.e., tinting of input elements).
    virtual bool isActive() const = 0;
    virtual void setIsActive(bool) = 0;

    // Allows disabling domain relaxation.
    virtual void setDomainRelaxationForbidden(bool, const WebString& scheme) = 0;

    // Marks the WebView as being opened by a DOM call. This is relevant
    // for whether window.close() may be called.
    virtual void setOpenedByDOM() = 0;


    // Frames --------------------------------------------------------------

    virtual WebFrame* mainFrame() = 0;

    // Focus ---------------------------------------------------------------

    virtual WebFrame* focusedFrame() = 0;
    virtual void setFocusedFrame(WebFrame*) = 0;

    // Focus the first (last if reverse is true) focusable node.
    virtual void setInitialFocus(bool reverse) = 0;

    // Clears the focused element (and selection if a text field is focused)
    // to ensure that a text field on the page is not eating keystrokes we
    // send it.
    virtual void clearFocusedElement() = 0;

    // Scrolls the node currently in focus into |rect|, where |rect| is in
    // window space.
    virtual void scrollFocusedNodeIntoRect(const WebRect&) { }

    // Advance the focus of the WebView forward to the next element or to the
    // previous element in the tab sequence (if reverse is true).
    virtual void advanceFocus(bool reverse) { }

    // Animate a scale into the specified find-in-page rect.
    virtual void zoomToFindInPageRect(const WebRect&) = 0;

    // Animate a scale into the specified rect where multiple targets were
    // found from previous tap gesture.
    // Returns false if it doesn't do any zooming.
    virtual bool zoomToMultipleTargetsRect(const WebRect&) = 0;


    // Zoom ----------------------------------------------------------------

    // Returns the current zoom level.  0 is "original size", and each increment
    // above or below represents zooming 20% larger or smaller to default limits
    // of 300% and 50% of original size, respectively.  Only plugins use
    // non whole-numbers, since they might choose to have specific zoom level so
    // that fixed-width content is fit-to-page-width, for example.
    virtual double zoomLevel() = 0;

    // Changes the zoom level to the specified level, clamping at the limits
    // noted above, and returns the current zoom level after applying the
    // change.
    virtual double setZoomLevel(double) = 0;

    // Updates the zoom limits for this view.
    virtual void zoomLimitsChanged(double minimumZoomLevel,
                                   double maximumZoomLevel) = 0;

    // Helper functions to convert between zoom level and zoom factor.  zoom
    // factor is zoom percent / 100, so 300% = 3.0.
    BLINK_EXPORT static double zoomLevelToZoomFactor(double zoomLevel);
    BLINK_EXPORT static double zoomFactorToZoomLevel(double factor);

    // Returns the current text zoom factor, where 1.0 is the normal size, > 1.0
    // is scaled up and < 1.0 is scaled down.
    virtual float textZoomFactor() = 0;

    // Scales the text in the page by a factor of textZoomFactor.
    // Note: this has no effect on plugins.
    virtual float setTextZoomFactor(float) = 0;

    // TODO: Reevaluate if this is needed once all users are converted to using the
    // virtual viewport pinch model.
    // Temporary to keep old style pinch viewport working while we gradually bring up
    // virtual viewport pinch.
    virtual void setMainFrameScrollOffset(const WebPoint& origin) = 0;

    // Sets the offset of the pinch-to-zoom viewport within the main frame, in
    // partial CSS pixels. The offset will be clamped so the pinch viewport
    // stays within the frame's bounds.
    virtual void setPinchViewportOffset(const WebFloatPoint&) = 0;

    // Gets the pinch viewport's current offset within the page's main frame,
    // in partial CSS pixels.
    virtual WebFloatPoint pinchViewportOffset() const = 0;

    // Reset any saved values for the scroll and scale state.
    virtual void resetScrollAndScaleState() = 0;

    // Returns the "preferred" contents size, defined as the preferred minimum width of the main document's contents
    // and the minimum height required to display the main document without scrollbars.
    // The returned size has the page zoom factor applied.
    virtual WebSize contentsPreferredMinimumSize() = 0;

    // The ratio of the current device's screen DPI to the target device's screen DPI.
    virtual float deviceScaleFactor() const = 0;

    // Sets the ratio as computed by computePageScaleConstraints.
    virtual void setDeviceScaleFactor(float) = 0;


    // Fixed Layout --------------------------------------------------------

    // Locks main frame's layout size to specified size. Passing WebSize(0, 0)
    // removes the lock.
    virtual void setFixedLayoutSize(const WebSize&) = 0;


    // Media ---------------------------------------------------------------

    // Performs the specified media player action on the node at the given location.
    virtual void performMediaPlayerAction(
        const WebMediaPlayerAction&, const WebPoint& location) = 0;


    // Data exchange -------------------------------------------------------

    // Do a hit test at given point and return the HitTestResult.
    virtual WebHitTestResult hitTestResultAt(const WebPoint&) = 0;

    // Copy to the clipboard the image located at a particular point in the
    // WebView (if there is such an image)
    virtual void copyImageAt(const WebPoint&) = 0;

    // Save as the image located at a particular point in the
    // WebView (if there is such an image)
    virtual void saveImageAt(const WebPoint&) = 0;

    // Notfies the WebView that the system drag and drop operation has ended.
    virtual void dragSourceSystemDragEnded() = 0;

    // Retrieves a list of spelling markers.
    virtual void spellingMarkers(WebVector<uint32_t>* markers) = 0;
    virtual void removeSpellingMarkersUnderWords(const WebVector<WebString>& words) = 0;


    // Developer tools -----------------------------------------------------

    // Set an override of device scale factor passed from WebView to
    // compositor. Pass zero to cancel override. This is used to implement
    // device metrics emulation.
    virtual void setCompositorDeviceScaleFactorOverride(float) = 0;

    // Set offset and scale on the root composited layer. This is used
    // to implement device metrics emulation.
    virtual void setRootLayerTransform(const WebSize& offset, float scale) = 0;

    // Context menu --------------------------------------------------------

    virtual void performCustomContextMenuAction(unsigned action) = 0;

    // Shows a context menu for the currently focused element.
    virtual void showContextMenu() = 0;


    // SmartClip support ---------------------------------------------------
    virtual void extractSmartClipData(WebRect initRect, WebString& text, WebString& html, WebRect& resultRect) = 0;

    // Custom colors -------------------------------------------------------

    virtual void setSelectionColors(unsigned activeBackgroundColor,
                                    unsigned activeForegroundColor,
                                    unsigned inactiveBackgroundColor,
                                    unsigned inactiveForegroundColor) = 0;

    // Called to inform the WebView that a wheel fling animation was started externally (for instance
    // by the compositor) but must be completed by the WebView.
    virtual void transferActiveWheelFlingAnimation(const WebActiveWheelFlingParameters&) = 0;

    // Cancels an active fling, returning true if a fling was active.
    virtual bool endActiveFlingAnimation() = 0;

    virtual void setShowPaintRects(bool) = 0;
    virtual void setShowFPSCounter(bool) = 0;
    virtual void setContinuousPaintingEnabled(bool) = 0;
    virtual void setShowScrollBottleneckRects(bool) = 0;

    // Compute the bounds of the root element of the current selection and fills
    // the out-parameter on success. |bounds| coordinates will be relative to
    // the contents window and will take into account the current scale level.
    virtual void getSelectionRootBounds(WebRect& bounds) const = 0;

    // Visibility -----------------------------------------------------------

    // Sets the visibility of the WebView.
    virtual void setVisibilityState(WebPageVisibilityState visibilityState,
                                    bool isInitialState) { }

    // PageOverlay ----------------------------------------------------------

    // Adds/removes page overlay to this WebView. These functions change the
    // graphical appearance of the WebView. WebPageOverlay paints the
    // contents of the page overlay. It also provides an z-order number for
    // the page overlay. The z-order number defines the paint order the page
    // overlays. Page overlays with larger z-order number will be painted after
    // page overlays with smaller z-order number. That is, they appear above
    // the page overlays with smaller z-order number. If two page overlays have
    // the same z-order number, the later added one will be on top.
    virtual void addPageOverlay(WebPageOverlay*, int /*z-order*/) = 0;
    virtual void removePageOverlay(WebPageOverlay*) = 0;


    // i18n -----------------------------------------------------------------

    // Inform the WebView that the accept languages have changed.
    // If the WebView wants to get the accept languages value, it will have
    // to call the WebViewClient::acceptLanguages().
    virtual void acceptLanguagesChanged() = 0;

    // Testing functionality for TestRunner ---------------------------------

protected:
    ~WebView() {}
};

} // namespace blink

#endif
