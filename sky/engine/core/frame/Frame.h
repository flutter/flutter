/*
 * Copyright (C) 1998, 1999 Torben Weis <weis@kde.org>
 *                     1999-2001 Lars Knoll <knoll@kde.org>
 *                     1999-2001 Antti Koivisto <koivisto@kde.org>
 *                     2000-2001 Simon Hausmann <hausmann@kde.org>
 *                     2000-2001 Dirk Mueller <mueller@kde.org>
 *                     2000 Stefan Schimanski <1Stein@gmx.de>
 * Copyright (C) 2004, 2005, 2006, 2007, 2008, 2009, 2010 Apple Inc. All rights reserved.
 * Copyright (C) 2008 Nokia Corporation and/or its subsidiary(-ies)
 * Copyright (C) 2008 Eric Seidel <eric@webkit.org>
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

#ifndef SKY_ENGINE_CORE_FRAME_FRAME_H_
#define SKY_ENGINE_CORE_FRAME_FRAME_H_

#include "sky/engine/wtf/Forward.h"
#include "sky/engine/wtf/RefCounted.h"
#include "sky/engine/wtf/RefPtr.h"

namespace blink {
class WebLayer;
}

namespace blink {

class ChromeClient;
class Document;
class FrameClient;
class FrameHost;
class LocalDOMWindow;
class Page;
class Settings;

class Frame : public RefCounted<Frame> {
public:
    virtual ~Frame();

    virtual void detach() = 0;
    void detachChildren();

    FrameClient* client() const;
    void clearClient();

    // NOTE: Page is moving out of Blink up into the browser process as
    // part of the site-isolation (out of process iframes) work.
    // FrameHost should be used instead where possible.
    Page* page() const;
    FrameHost* host() const; // Null when the frame is detached.

    // FIXME: LocalDOMWindow and Document should both be moved to LocalFrame
    // after RemoteFrame is complete enough to exist without them.
    virtual void setDOMWindow(PassRefPtr<LocalDOMWindow>);
    LocalDOMWindow* domWindow() const;

    Settings* settings() const; // can be null

protected:
    Frame(FrameClient*, FrameHost*);

    FrameHost* m_host;
    Document* m_document;

    RefPtr<LocalDOMWindow> m_domWindow;

private:
    FrameClient* m_client;
};

inline FrameClient* Frame::client() const
{
    return m_client;
}

inline void Frame::clearClient()
{
    m_client = 0;
}

inline LocalDOMWindow* Frame::domWindow() const
{
    return m_domWindow.get();
}

// Allow equality comparisons of Frames by reference or pointer, interchangeably.
DEFINE_COMPARISON_OPERATORS_WITH_REFERENCES_REFCOUNTED(Frame)

} // namespace blink

#endif  // SKY_ENGINE_CORE_FRAME_FRAME_H_
