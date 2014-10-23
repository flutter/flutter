/*
 * Copyright (C) 2006 Eric Seidel (eric@webkit.org)
 * Copyright (C) 2008, 2009, 2010, 2011, 2012 Apple Inc. All rights reserved.
 * Copyright (C) 2010 Nokia Corporation and/or its subsidiary(-ies).
 * Copyright (C) 2012 Samsung Electronics. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE COMPUTER, INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE COMPUTER, INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef EmptyClients_h
#define EmptyClients_h

#include "core/editing/UndoStep.h"
#include "core/loader/FrameLoaderClient.h"
#include "core/page/ChromeClient.h"
#include "core/page/ContextMenuClient.h"
#include "core/page/EditorClient.h"
#include "core/page/FocusType.h"
#include "core/page/Page.h"
#include "core/page/SpellCheckerClient.h"
#include "platform/geometry/FloatRect.h"
#include "platform/network/ResourceError.h"
#include "platform/text/TextCheckerClient.h"
#include "public/platform/WebScreenInfo.h"
#include "wtf/Forward.h"
#include <v8.h>

/*
 This file holds empty Client stubs for use by WebCore.
 Viewless element needs to create a dummy Page->LocalFrame->FrameView tree for use in parsing or executing JavaScript.
 This tree depends heavily on Clients (usually provided by WebKit classes).

 This file was first created for SVGImage as it had no way to access the current Page (nor should it,
 since Images are not tied to a page).
 See http://bugs.webkit.org/show_bug.cgi?id=5971 for the original discussion about this file.

 Ideally, whenever you change a Client class, you should add a stub here.
 Brittle, yes.  Unfortunate, yes.  Hopefully temporary.
*/

namespace blink {

class EmptyChromeClient : public ChromeClient {
    WTF_MAKE_FAST_ALLOCATED;
public:
    virtual ~EmptyChromeClient() { }
    virtual void chromeDestroyed() OVERRIDE { }

    virtual void* webView() const OVERRIDE { return 0; }
    virtual void setWindowRect(const FloatRect&) OVERRIDE { }
    virtual FloatRect windowRect() OVERRIDE { return FloatRect(); }

    virtual FloatRect pageRect() OVERRIDE { return FloatRect(); }

    virtual void focus() OVERRIDE { }

    virtual bool canTakeFocus(FocusType) OVERRIDE { return false; }
    virtual void takeFocus(FocusType) OVERRIDE { }

    virtual void focusedNodeChanged(Node*) OVERRIDE { }
    virtual void focusedFrameChanged(LocalFrame*) OVERRIDE { }
    virtual void show(NavigationPolicy) OVERRIDE { }

    virtual bool shouldReportDetailedMessageForSource(const String&) OVERRIDE { return false; }
    virtual void addMessageToConsole(LocalFrame*, MessageSource, MessageLevel, const String&, unsigned, const String&, const String&) OVERRIDE { }

    virtual bool tabsToLinks() OVERRIDE { return false; }

    virtual void invalidateContentsAndRootView(const IntRect&) OVERRIDE { }
    virtual void invalidateContentsForSlowScroll(const IntRect&) OVERRIDE { }
    virtual void scheduleAnimation() OVERRIDE { }

    virtual IntRect rootViewToScreen(const IntRect& r) const OVERRIDE { return r; }
    virtual blink::WebScreenInfo screenInfo() const OVERRIDE { return blink::WebScreenInfo(); }

    virtual void mouseDidMoveOverElement(const HitTestResult&, unsigned) OVERRIDE { }

    virtual void setToolTip(const String&, TextDirection) OVERRIDE { }

    virtual void setCursor(const Cursor&) OVERRIDE { }

    virtual void attachRootGraphicsLayer(GraphicsLayer*) OVERRIDE { }

    virtual void needTouchEvents(bool) OVERRIDE { }
    virtual void setTouchAction(TouchAction touchAction) OVERRIDE { };

    virtual bool paintCustomOverhangArea(GraphicsContext*, const IntRect&, const IntRect&, const IntRect&) OVERRIDE { return false; }
    virtual String acceptLanguages() OVERRIDE;
};

class EmptyFrameLoaderClient : public FrameLoaderClient {
    WTF_MAKE_NONCOPYABLE(EmptyFrameLoaderClient); WTF_MAKE_FAST_ALLOCATED;
public:
    EmptyFrameLoaderClient() { }
    virtual ~EmptyFrameLoaderClient() {  }

    virtual void detachedFromParent() OVERRIDE { }

    virtual void dispatchWillSendRequest(Document*, unsigned long, ResourceRequest&, const ResourceResponse&) OVERRIDE { }
    virtual void dispatchDidReceiveResponse(Document*, unsigned long, const ResourceResponse&) OVERRIDE { }
    virtual void dispatchDidFinishLoading(Document*, unsigned long) OVERRIDE { }
    virtual void dispatchDidLoadResourceFromMemoryCache(const ResourceRequest&, const ResourceResponse&) OVERRIDE { }

    virtual void dispatchDidHandleOnloadEvents() OVERRIDE { }
    virtual void dispatchWillClose() OVERRIDE { }
    virtual void dispatchDidReceiveTitle(const String&) OVERRIDE { }
    virtual void dispatchDidFailLoad(const ResourceError&) OVERRIDE { }

    virtual NavigationPolicy decidePolicyForNavigation(const ResourceRequest&, Document*, NavigationPolicy, bool isTransitionNavigation) OVERRIDE;

    virtual void didStartLoading(LoadStartType) OVERRIDE { }
    virtual void progressEstimateChanged(double) OVERRIDE { }
    virtual void didStopLoading() OVERRIDE { }

    virtual void loadURLExternally(const ResourceRequest&, NavigationPolicy, const String& = String()) OVERRIDE { }

    virtual void transitionToCommittedForNewPage() OVERRIDE { }

    virtual void selectorMatchChanged(const Vector<String>&, const Vector<String>&) OVERRIDE { }

    virtual void documentElementAvailable() OVERRIDE { }

    virtual void didCreateScriptContext(v8::Handle<v8::Context>, int extensionGroup, int worldId) OVERRIDE { }
    virtual void willReleaseScriptContext(v8::Handle<v8::Context>, int worldId) OVERRIDE { }
};

class EmptyTextCheckerClient : public TextCheckerClient {
public:
    ~EmptyTextCheckerClient() { }

    virtual bool shouldEraseMarkersAfterChangeSelection(TextCheckingType) const OVERRIDE { return true; }
    virtual void checkSpellingOfString(const String&, int*, int*) OVERRIDE { }
    virtual String getAutoCorrectSuggestionForMisspelledWord(const String&) OVERRIDE { return String(); }
    virtual void checkGrammarOfString(const String&, Vector<GrammarDetail>&, int*, int*) OVERRIDE { }
    virtual void requestCheckingOfString(PassRefPtr<TextCheckingRequest>) OVERRIDE;
};

class EmptySpellCheckerClient : public SpellCheckerClient {
    WTF_MAKE_NONCOPYABLE(EmptySpellCheckerClient); WTF_MAKE_FAST_ALLOCATED;
public:
    EmptySpellCheckerClient() { }
    virtual ~EmptySpellCheckerClient() { }

    virtual bool isContinuousSpellCheckingEnabled() OVERRIDE { return false; }
    virtual void toggleContinuousSpellChecking() OVERRIDE { }
    virtual bool isGrammarCheckingEnabled() OVERRIDE { return false; }

    virtual TextCheckerClient& textChecker() OVERRIDE { return m_textCheckerClient; }

    virtual void updateSpellingUIWithMisspelledWord(const String&) OVERRIDE { }
    virtual void showSpellingUI(bool) OVERRIDE { }
    virtual bool spellingUIIsShowing() OVERRIDE { return false; }

private:
    EmptyTextCheckerClient m_textCheckerClient;
};

class EmptyEditorClient FINAL : public EditorClient {
    WTF_MAKE_NONCOPYABLE(EmptyEditorClient); WTF_MAKE_FAST_ALLOCATED;
public:
    EmptyEditorClient() { }
    virtual ~EmptyEditorClient() { }

    virtual void respondToChangedContents() OVERRIDE { }
    virtual void respondToChangedSelection(LocalFrame*, SelectionType) OVERRIDE { }

    virtual bool canCopyCut(LocalFrame*, bool defaultValue) const OVERRIDE { return defaultValue; }
    virtual bool canPaste(LocalFrame*, bool defaultValue) const OVERRIDE { return defaultValue; }

    virtual bool handleKeyboardEvent() OVERRIDE { return false; }
};

class EmptyContextMenuClient FINAL : public ContextMenuClient {
    WTF_MAKE_NONCOPYABLE(EmptyContextMenuClient); WTF_MAKE_FAST_ALLOCATED;
public:
    EmptyContextMenuClient() { }
    virtual ~EmptyContextMenuClient() {  }
    virtual void showContextMenu(const ContextMenu*) OVERRIDE { }
    virtual void clearContextMenu() OVERRIDE { }
};

void fillWithEmptyClients(Page::PageClients&);

}

#endif // EmptyClients_h
