/*
 * Copyright (C) 2006, 2007, 2008, 2009, 2010, 2011, 2012 Apple, Inc. All rights reserved.
 * Copyright (C) 2010 Nokia Corporation and/or its subsidiary(-ies).
 * Copyright (C) 2012 Samsung Electronics. All rights reserved.
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

#ifndef ChromeClient_h
#define ChromeClient_h

#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/frame/ConsoleTypes.h"
#include "sky/engine/core/inspector/ConsoleAPITypes.h"
#include "sky/engine/core/loader/NavigationPolicy.h"
#include "sky/engine/core/page/FocusType.h"
#include "sky/engine/core/rendering/style/RenderStyleConstants.h"
#include "sky/engine/platform/Cursor.h"
#include "sky/engine/platform/HostWindow.h"
#include "sky/engine/platform/scroll/ScrollTypes.h"
#include "sky/engine/wtf/Forward.h"
#include "sky/engine/wtf/PassOwnPtr.h"
#include "sky/engine/wtf/Vector.h"

namespace blink {

class ColorChooser;
class ColorChooserClient;
class DateTimeChooser;
class DateTimeChooserClient;
class Element;
class FloatRect;
class Frame;
class GraphicsContext;
class GraphicsLayer;
class GraphicsLayerFactory;
class HitTestResult;
class IntRect;
class LocalFrame;
class Node;
class Page;
class Widget;

struct DateTimeChooserParameters;
struct GraphicsDeviceAdapter;

class ChromeClient {
public:
    virtual void chromeDestroyed() = 0;

    virtual void setWindowRect(const FloatRect&) = 0;
    virtual FloatRect windowRect() = 0;

    virtual FloatRect pageRect() = 0;

    virtual void focus() = 0;

    virtual bool canTakeFocus(FocusType) = 0;
    virtual void takeFocus(FocusType) = 0;

    virtual void focusedNodeChanged(Node*) = 0;

    virtual void focusedFrameChanged(LocalFrame*) = 0;

    virtual void show(NavigationPolicy) = 0;

    virtual bool shouldReportDetailedMessageForSource(const String& source) = 0;
    virtual void addMessageToConsole(LocalFrame*, MessageSource, MessageLevel, const String& message, unsigned lineNumber, const String& sourceID, const String& stackTrace) = 0;

    virtual bool tabsToLinks() = 0;

    virtual void* webView() const = 0;

    // Methods used by HostWindow.
    virtual void invalidateContentsAndRootView(const IntRect&) = 0;
    virtual void invalidateContentsForSlowScroll(const IntRect&) = 0;
    virtual IntRect rootViewToScreen(const IntRect&) const = 0;
    virtual blink::WebScreenInfo screenInfo() const = 0;
    virtual void setCursor(const Cursor&) = 0;
    virtual void scheduleAnimation() = 0;
    // End methods used by HostWindow.

    virtual void layoutUpdated(LocalFrame*) const { }

    virtual void mouseDidMoveOverElement(const HitTestResult&, unsigned modifierFlags) = 0;

    virtual void setToolTip(const String&, TextDirection) = 0;

    // Allows ports to customize the type of graphics layers created by this page.
    virtual GraphicsLayerFactory* graphicsLayerFactory() const { return 0; }

    // Pass 0 as the GraphicsLayer to detatch the root layer.
    virtual void attachRootGraphicsLayer(GraphicsLayer*) = 0;

    virtual void clearCompositedSelectionBounds() { }

    virtual void setTouchAction(TouchAction) = 0;

    virtual String acceptLanguages() = 0;

    enum DialogType {
        AlertDialog = 0,
        ConfirmDialog = 1,
        PromptDialog = 2,
        HTMLDialog = 3
    };

    virtual FloatSize minimumWindowSize() const { return FloatSize(100, 100); };

    virtual bool isChromeClientImpl() const { return false; }

    // FIXME: Remove this method once we have input routing in the browser
    // process. See http://crbug.com/339659.
    virtual void forwardInputEvent(blink::Frame*, blink::Event*) { }

    // Input mehtod editor related functions.
    virtual void willSetInputMethodState() { }
    virtual void didUpdateTextOfFocusedElementByNonUserInput() { }
    virtual void showImeIfNeeded() { }

protected:
    virtual ~ChromeClient() { }
};

}
#endif // ChromeClient_h
