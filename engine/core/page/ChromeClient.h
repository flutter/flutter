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

#ifndef SKY_ENGINE_CORE_PAGE_CHROMECLIENT_H_
#define SKY_ENGINE_CORE_PAGE_CHROMECLIENT_H_

#include "sky/engine/core/frame/ConsoleTypes.h"
#include "sky/engine/core/inspector/ConsoleAPITypes.h"
#include "sky/engine/core/page/FocusType.h"
#include "sky/engine/platform/Cursor.h"
#include "sky/engine/public/platform/WebScreenInfo.h"
#include "sky/engine/wtf/Forward.h"

namespace blink {

class Element;
class FloatRect;
class IntRect;
class LocalFrame;
class Node;

struct DateTimeChooserParameters;
struct GraphicsDeviceAdapter;

class ChromeClient {
public:
    virtual void setWindowRect(const FloatRect&) = 0;
    virtual FloatRect windowRect() = 0;

    virtual void focus() = 0;
    virtual bool canTakeFocus(FocusType) = 0;
    virtual void takeFocus(FocusType) = 0;
    virtual void focusedNodeChanged(Node*) = 0;
    virtual void focusedFrameChanged(LocalFrame*) = 0;

    virtual bool shouldReportDetailedMessageForSource(const String& source) = 0;
    virtual void addMessageToConsole(LocalFrame*, MessageSource, MessageLevel, const String& message, unsigned lineNumber, const String& sourceID, const String& stackTrace) = 0;

    virtual void* webView() const = 0;

    // Methods used by HostWindow.
    virtual IntRect rootViewToScreen(const IntRect&) const = 0;
    virtual blink::WebScreenInfo screenInfo() const = 0;
    virtual void scheduleVisualUpdate() = 0;
    // End methods used by HostWindow.

    virtual void setCursor(const Cursor&) = 0;

    virtual String acceptLanguages() = 0;

protected:
    virtual ~ChromeClient() { }
};

}
#endif  // SKY_ENGINE_CORE_PAGE_CHROMECLIENT_H_
