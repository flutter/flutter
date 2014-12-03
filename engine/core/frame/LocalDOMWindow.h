/*
 * Copyright (C) 2006, 2007, 2009, 2010 Apple Inc. All rights reserved.
 * Copyright (C) 2010 Nokia Corporation and/or its subsidiary(-ies)
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

#ifndef SKY_ENGINE_CORE_FRAME_LOCALDOMWINDOW_H_
#define SKY_ENGINE_CORE_FRAME_LOCALDOMWINDOW_H_

#include "sky/engine/bindings/core/v8/Dictionary.h"
#include "sky/engine/bindings/core/v8/SerializedScriptValue.h"
#include "sky/engine/core/events/EventTarget.h"
#include "sky/engine/core/frame/DOMWindowBase64.h"
#include "sky/engine/core/frame/FrameDestructionObserver.h"
#include "sky/engine/platform/LifecycleContext.h"
#include "sky/engine/platform/Supplementable.h"
#include "sky/engine/platform/heap/Handle.h"

#include "sky/engine/wtf/Forward.h"

namespace blink {

class Application;
class CSSRuleList;
class CSSStyleDeclaration;
class Console;
class DOMSelection;
class DOMURL;
class DOMWindowCSS;
class DOMWindowEventQueue;
class DOMWindowLifecycleNotifier;
class DOMWindowProperty;
class Database;
class DatabaseCallback;
class Document;
class DocumentInit;
class Element;
class EventListener;
class EventQueue;
class ExceptionState;
class FloatRect;
class FrameConsole;
class History;
class IDBFactory;
class LocalFrame;
class Location;
class MediaQueryList;
class Node;
class Page;
class RequestAnimationFrameCallback;
class ScheduledAction;
class Screen;
class ScriptCallStack;
class SerializedScriptValue;
class StyleMedia;

enum PageshowEventPersistence {
    PageshowEventNotPersisted = 0,
    PageshowEventPersisted = 1
};

enum SetLocationLocking { LockHistoryBasedOnGestureState, LockHistoryAndBackForwardList };

class LocalDOMWindow final : public RefCounted<LocalDOMWindow>, public EventTargetWithInlineData, public DOMWindowBase64, public FrameDestructionObserver, public Supplementable<LocalDOMWindow>, public LifecycleContext<LocalDOMWindow> {
    DEFINE_WRAPPERTYPEINFO();
    REFCOUNTED_EVENT_TARGET(LocalDOMWindow);
public:
    static PassRefPtr<LocalDOMWindow> create(LocalFrame& frame)
    {
        return adoptRef(new LocalDOMWindow(frame));
    }
    virtual ~LocalDOMWindow();

    PassRefPtr<Document> installNewDocument(const DocumentInit&);

    virtual const AtomicString& interfaceName() const override;
    virtual ExecutionContext* executionContext() const override;

    virtual LocalDOMWindow* toDOMWindow() override;

    void registerProperty(DOMWindowProperty*);
    void unregisterProperty(DOMWindowProperty*);

    void reset();

    PassRefPtr<MediaQueryList> matchMedia(const String&);

    unsigned pendingUnloadEventListeners() const;

    static FloatRect adjustWindowRect(LocalFrame&, const FloatRect& pendingChanges);

    // DOM Level 0

    Screen& screen() const;
    History& history() const;

    Location& location() const;
    void setLocation(const String& location, LocalDOMWindow* callingWindow, LocalDOMWindow* enteredWindow,
        SetLocationLocking = LockHistoryBasedOnGestureState);

    DOMSelection* getSelection();

    void focus(ExecutionContext* = 0);

    bool find(const String&, bool caseSensitive, bool backwards, bool wrap, bool wholeWord, bool searchInFrames, bool showDialog) const;

    int outerHeight() const;
    int outerWidth() const;
    int innerHeight() const;
    int innerWidth() const;
    int screenX() const;
    int screenY() const;
    int screenLeft() const { return screenX(); }
    int screenTop() const { return screenY(); }

    // FIXME(sky): keeping self for now since js-test.html uses it.
    LocalDOMWindow* window() const;
    LocalDOMWindow* self() const { return window(); }

    // DOM Level 2 AbstractView Interface

    Document* document() const;

    // CSSOM View Module

    StyleMedia& styleMedia() const;

    // DOM Level 2 Style Interface

    PassRefPtr<CSSStyleDeclaration> getComputedStyle(Element*, const String& pseudoElt) const;

    // WebKit extensions

    double devicePixelRatio() const;

    Console& console() const;
    FrameConsole* frameConsole() const;

    void printErrorMessage(const String&);

    void moveBy(float x, float y) const;
    void moveTo(float x, float y) const;

    void resizeBy(float x, float y) const;
    void resizeTo(float width, float height) const;

    // WebKit animation extensions
    int requestAnimationFrame(PassOwnPtr<RequestAnimationFrameCallback>);
    void cancelAnimationFrame(int id);

    DOMWindowCSS& css() const;

    // Events
    // EventTarget API
    virtual bool addEventListener(const AtomicString& eventType, PassRefPtr<EventListener>, bool useCapture = false) override;
    virtual bool removeEventListener(const AtomicString& eventType, PassRefPtr<EventListener>, bool useCapture = false) override;
    virtual void removeAllEventListeners() override;

    using EventTarget::dispatchEvent;
    bool dispatchEvent(PassRefPtr<Event> prpEvent, PassRefPtr<EventTarget> prpTarget);

    void dispatchLoadEvent();

    // This is the interface orientation in degrees. Some examples are:
    //  0 is straight up; -90 is when the device is rotated 90 clockwise;
    //  90 is when rotated counter clockwise.
    int orientation() const;

    void willDetachDocumentFromFrame();

    bool isInsecureScriptAccess(LocalDOMWindow& callingWindow, const String& urlString);

    PassOwnPtr<LifecycleNotifier<LocalDOMWindow> > createLifecycleNotifier();

    EventQueue* eventQueue() const;
    void enqueueWindowEvent(PassRefPtr<Event>);
    void enqueueDocumentEvent(PassRefPtr<Event>);
    void enqueuePageshowEvent(PageshowEventPersistence);
    void enqueueHashchangeEvent(const String& oldURL, const String& newURL);
    void enqueuePopstateEvent(PassRefPtr<SerializedScriptValue>);
    void dispatchWindowLoadEvent();
    void documentWasClosed();
    void statePopped(PassRefPtr<SerializedScriptValue>);

    // FIXME: This shouldn't be public once LocalDOMWindow becomes ExecutionContext.
    void clearEventQueue();

    void acceptLanguagesChanged();

protected:
    DOMWindowLifecycleNotifier& lifecycleNotifier();

private:
    explicit LocalDOMWindow(LocalFrame&);

    Page* page();

    virtual void frameDestroyed() override;
    virtual void willDetachFrameHost() override;

    void clearDocument();
    void resetDOMWindowProperties();
    void willDestroyDocumentInFrame();

    // FIXME: Oilpan: the need for this internal method will fall
    // away when EventTargets are no longer using refcounts and
    // window properties are also on the heap. Inline the minimal
    // do-not-broadcast handling then and remove the enum +
    // removeAllEventListenersInternal().
    enum BroadcastListenerRemoval {
        DoNotBroadcastListenerRemoval,
        DoBroadcastListenerRemoval
    };

    void removeAllEventListenersInternal(BroadcastListenerRemoval);

    RefPtr<Application> m_application;
    RefPtr<Document> m_document;

#if ENABLE(ASSERT)
    bool m_hasBeenReset;
#endif

    HashSet<DOMWindowProperty*> m_properties;

    mutable RefPtr<Screen> m_screen;
    mutable RefPtr<History> m_history;
    mutable RefPtr<Console> m_console;
    mutable RefPtr<Location> m_location;
    mutable RefPtr<StyleMedia> m_media;

    mutable RefPtr<DOMWindowCSS> m_css;

    RefPtr<DOMWindowEventQueue> m_eventQueue;
    RefPtr<SerializedScriptValue> m_pendingStateObject;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_FRAME_LOCALDOMWINDOW_H_
