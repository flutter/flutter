/*
 * Copyright (C) 2006, 2007, 2008, 2009, 2010, 2011 Apple Inc. All rights reserved.
 * Copyright (C) 2008 Nokia Corporation and/or its subsidiary(-ies)
 * Copyright (C) 2008, 2009 Torch Mobile Inc. All rights reserved. (http://www.torchmobile.com/)
 * Copyright (C) 2008 Alp Toker <alp@atoker.com>
 * Copyright (C) Research In Motion Limited 2009. All rights reserved.
 * Copyright (C) 2011 Kris Jordan <krisjordan@gmail.com>
 * Copyright (C) 2011 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 * 3.  Neither the name of Apple Computer, Inc. ("Apple") nor the names of
 *     its contributors may be used to endorse or promote products derived
 *     from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE AND ITS CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "core/loader/FrameLoader.h"

#include "bindings/core/v8/DOMWrapperWorld.h"
#include "bindings/core/v8/ScriptController.h"
#include "bindings/core/v8/SerializedScriptValue.h"
#include "core/dom/Document.h"
#include "core/dom/Element.h"
#include "core/editing/Editor.h"
#include "core/editing/UndoStack.h"
#include "core/events/PageTransitionEvent.h"
#include "core/fetch/FetchContext.h"
#include "core/fetch/ResourceFetcher.h"
#include "core/fetch/ResourceLoader.h"
#include "core/frame/LocalDOMWindow.h"
#include "core/frame/FrameHost.h"
#include "core/frame/FrameView.h"
#include "core/frame/LocalFrame.h"
#include "core/html/parser/HTMLDocumentParser.h"
#include "core/html/parser/HTMLParserIdioms.h"
#include "core/inspector/ConsoleMessage.h"
#include "core/loader/DocumentLoadTiming.h"
#include "core/loader/FrameFetchContext.h"
#include "core/loader/FrameLoaderClient.h"
#include "core/loader/UniqueIdentifier.h"
#include "core/page/Chrome.h"
#include "core/page/ChromeClient.h"
#include "core/page/EventHandler.h"
#include "core/page/Page.h"
#include "core/frame/Settings.h"
#include "core/page/scrolling/ScrollingCoordinator.h"
#include "platform/Logging.h"
#include "platform/UserGestureIndicator.h"
#include "platform/geometry/FloatRect.h"
#include "platform/network/HTTPParsers.h"
#include "platform/network/ResourceRequest.h"
#include "platform/scroll/ScrollAnimator.h"
#include "platform/weborigin/SecurityPolicy.h"
#include "public/platform/WebURLRequest.h"
#include "wtf/TemporaryChange.h"
#include "wtf/text/CString.h"
#include "wtf/text/WTFString.h"

using blink::WebURLRequest;

namespace blink {

FrameLoader::FrameLoader(LocalFrame* frame)
    : m_frame(frame)
    , m_fetchContext(FrameFetchContext::create(frame))
    , m_inStopAllLoaders(false)
{
}

FrameLoader::~FrameLoader()
{
}

void FrameLoader::stopLoading()
{
    if (!m_frame->document() || !m_frame->document()->parsing())
        return;

    finishedParsing();
    m_frame->document()->setParsing(false);
}

bool FrameLoader::closeURL()
{
    // Should only send the pagehide event here if the current document exists.
    if (m_frame->document())
        m_frame->document()->dispatchUnloadEvents();
    stopLoading();

    if (Page* page = m_frame->page())
        page->undoStack().didUnloadFrame(*m_frame);
    return true;
}

void FrameLoader::clear()
{
    m_frame->editor().clear();
    m_frame->document()->cancelParsing();
    m_frame->document()->prepareForDestruction();
    m_frame->document()->removeFocusedElementOfSubtree(m_frame->document());

    m_frame->selection().prepareForDestruction();
    m_frame->eventHandler().clear();
    if (m_frame->view())
        m_frame->view()->clear();
}

void FrameLoader::finishedParsing()
{
    // This can be called from the LocalFrame's destructor, in which case we shouldn't protect ourselves
    // because doing so will cause us to re-enter the destructor when protector goes out of scope.
    // Null-checking the FrameView indicates whether or not we're in the destructor.
    RefPtr<LocalFrame> protector = m_frame->view() ? m_frame : 0;

    m_frame->document()->checkCompleted();

    // Check if the scrollbars are really needed for the content.
    // If not, remove them, relayout, and repaint.
    if (m_frame->view())
        m_frame->view()->restoreScrollbar();
}

void FrameLoader::reportLocalLoadFailed(LocalFrame* frame, const String& url)
{
    // FIXME(sky): Move this to Frame?
    ASSERT(!url.isEmpty());
    if (!frame)
        return;

    frame->document()->addConsoleMessage(ConsoleMessage::create(SecurityMessageSource, ErrorMessageLevel, "Not allowed to load local resource: " + url));
}

void FrameLoader::stopAllLoaders()
{
    if (m_frame->document()->pageDismissalEventBeingDispatched() != Document::NoDismissal)
        return;

    // If this method is called from within this method, infinite recursion can occur (3442218). Avoid this.
    if (m_inStopAllLoaders)
        return;

    // Calling stopLoading() on the provisional document loader can blow away
    // the frame from underneath.
    RefPtr<LocalFrame> protect(m_frame);

    m_inStopAllLoaders = true;

    // Attempt to stop the frame if the document loader is loading, or if it is done loading but
    // still  parsing. Failure to do so can cause a world leak.
    if (m_frame->document()->parsing())
        stopLoading();

    m_frame->document()->fetcher()->stopFetching();

    m_inStopAllLoaders = false;
}

} // namespace blink
