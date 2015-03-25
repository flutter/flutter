/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2001 Dirk Mueller (mueller@kde.org)
 *           (C) 2006 Alexey Proskuryakov (ap@webkit.org)
 * Copyright (C) 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2012 Apple Inc. All rights reserved.
 * Copyright (C) 2008, 2009 Torch Mobile Inc. All rights reserved. (http://www.torchmobile.com/)
 * Copyright (C) 2010 Nokia Corporation and/or its subsidiary(-ies)
 * Copyright (C) 2011 Google Inc. All rights reserved.
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
 *
 */

#ifndef SKY_ENGINE_CORE_DOM_DOCUMENT_H_
#define SKY_ENGINE_CORE_DOM_DOCUMENT_H_

#include "sky/engine/tonic/dart_value.h"
#include "sky/engine/bindings/exception_state_placeholder.h"
#include "sky/engine/core/animation/AnimationClock.h"
#include "sky/engine/core/animation/PendingAnimations.h"
#include "sky/engine/core/dom/ContainerNode.h"
#include "sky/engine/core/dom/DocumentInit.h"
#include "sky/engine/core/dom/DocumentLifecycle.h"
#include "sky/engine/core/dom/DocumentSupplementable.h"
#include "sky/engine/core/dom/ExecutionContext.h"
#include "sky/engine/core/dom/MutationObserver.h"
#include "sky/engine/core/dom/TextLinkColors.h"
#include "sky/engine/core/dom/TreeScope.h"
#include "sky/engine/core/dom/UserActionElementSet.h"
#include "sky/engine/core/fetch/ResourceClient.h"
#include "sky/engine/core/loader/DocumentLoadTiming.h"
#include "sky/engine/core/page/FocusType.h"
#include "sky/engine/core/page/PageVisibilityState.h"
#include "sky/engine/platform/Length.h"
#include "sky/engine/platform/Timer.h"
#include "sky/engine/platform/heap/Handle.h"
#include "sky/engine/platform/weborigin/KURL.h"
#include "sky/engine/platform/weborigin/ReferrerPolicy.h"
#include "sky/engine/wtf/HashSet.h"
#include "sky/engine/wtf/OwnPtr.h"
#include "sky/engine/wtf/PassOwnPtr.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/WeakPtr.h"
#include "sky/engine/wtf/text/TextEncoding.h"
#include "sky/engine/wtf/text/TextPosition.h"

namespace blink {

class AbstractModule;
class AnimationTimeline;
class Attr;
class CSSStyleDeclaration;
class CSSStyleSheet;
class Comment;
class ConsoleMessage;
class DocumentFragment;
class DocumentLifecycleNotifier;
class DocumentLoadTiming;
class DocumentMarkerController;
class DocumentParser;
class Element;
class ElementDataCache;
class Event;
class EventListener;
class ExceptionState;
class FloatQuad;
class FloatRect;
class Frame;
class FrameHost;
class FrameView;
class HTMLDocumentParser;
class HTMLElement;
class HTMLImport;
class HTMLImportLoader;
class HTMLImportsController;
class HTMLScriptElement;
class HitTestRequest;
class LayoutPoint;
class LocalDOMWindow;
class LocalFrame;
class Location;
class MediaQueryListListener;
class MediaQueryMatcher;
class CustomElementRegistry;
class Page;
class QualifiedName;
class Range;
class RenderView;
class RequestAnimationFrameCallback;
class ResourceFetcher;
class ScriptRunner;
class ScriptedAnimationController;
class SegmentedString;
class SelectorQueryCache;
class Settings;
class StyleEngine;
class StyleResolver;
class Text;

struct AnnotatedRegionValue;

typedef int ExceptionCode;

class Document;

class Document : public ContainerNode, public TreeScope, public ExecutionContext, public ExecutionContextClient
    , public DocumentSupplementable, public LifecycleContext<Document>, public ResourceClient {
    DEFINE_WRAPPERTYPEINFO();
public:
    static PassRefPtr<Document> create(const DocumentInit& initializer = DocumentInit())
    {
        return adoptRef(new Document(initializer));
    }
    virtual ~Document();

    // Called by JS.
    static PassRefPtr<Document> create(Document&);

    MediaQueryMatcher& mediaQueryMatcher();

    void mediaQueryAffectingValueChanged();

#if !ENABLE(OILPAN)
    using ContainerNode::ref;
    using ContainerNode::deref;
#endif
    using ExecutionContextClient::addConsoleMessage;
    using TreeScope::getElementById;

    virtual bool canContainRangeEndPoint() const override { return true; }

    SelectorQueryCache& selectorQueryCache();

    // Focus Management.
    Element* activeElement() const;
    bool hasFocus() const;

    AbstractModule* module() const { return m_module; }
    void setModule(AbstractModule* module) { m_module = module; }

    // DOM methods & attributes for Document

    Length viewportDefaultMinWidth() const { return m_viewportDefaultMinWidth; }

    ReferrerPolicy referrerPolicy() const { return m_referrerPolicy; }

    String outgoingReferrer();

    Location* location() const;

    PassRefPtr<Element> createElement(const AtomicString& name, ExceptionState&);
    PassRefPtr<DocumentFragment> createDocumentFragment();
    PassRefPtr<Node> importNode(Node* importedNode, bool deep, ExceptionState&);
    PassRefPtr<Element> createElement(const QualifiedName&, bool createdByParser);

    Element* elementFromPoint(int x, int y) const;
    PassRefPtr<Range> caretRangeFromPoint(int x, int y);

    String readyState() const;

    AtomicString inputEncoding() const { return Document::encodingName(); }
    AtomicString charset() const { return Document::encodingName(); }
    AtomicString characterSet() const { return Document::encodingName(); }

    AtomicString encodingName() const;

    AtomicString contentType() const; // DOM 4 document.contentType

    const AtomicString& contentLanguage() const { return m_contentLanguage; }
    void setContentLanguage(const AtomicString&);

    KURL baseURI() const;

    String visibilityState() const;
    bool hidden() const;
    void didChangeVisibilityState();

    PassRefPtr<Node> adoptNode(PassRefPtr<Node> source, ExceptionState&);

    struct TransitionElementData {
        String scope;
        String selector;
        String markup;
    };
    void getTransitionElementData(Vector<TransitionElementData>&);

    StyleResolver& styleResolver() const;

    StyleEngine* styleEngine() { return m_styleEngine.get(); }

    // Called when one or more stylesheets in the document may have been added, removed, or changed.
    void styleResolverChanged();

    void evaluateMediaQueryList();

    void setStateForNewFormElements(const Vector<String>&);

    FrameView* view() const; // can be null
    LocalFrame* frame() const { return m_frame; } // can be null
    FrameHost* frameHost() const; // can be null
    Page* page() const; // can be null
    Settings* settings() const; // can be null

    float devicePixelRatio() const;

    PassRefPtr<Range> createRange();

    // Special support for editing
    PassRefPtr<Text> createEditingTextNode(const String&);

    void setupFontBuilder(RenderStyle* documentStyle);

    bool needsRenderTreeUpdate() const;
    void updateRenderTreeIfNeeded() { updateRenderTree(NoChange); }
    void updateRenderTreeForNodeIfNeeded(Node*);
    void updateLayout();

    void updateDistributionForNodeIfNeeded(Node*);

    ResourceFetcher* fetcher() { return m_fetcher.get(); }

    virtual void attach(const AttachContext& = AttachContext()) override;
    virtual void detach(const AttachContext& = AttachContext()) override;
    void prepareForDestruction();

    // If you have a Document, use renderView() instead which is faster.
    void renderer() const = delete;

    RenderView* renderView() const { return m_renderView; }

    DocumentLoadTiming* timing() const;

    DocumentParser* startParsing();
    void cancelParsing();

    // close() is the DOM API document.close()
    void close(ExceptionState& = ASSERT_NO_EXCEPTION);
    // In some situations (see the code), we ignore document.close().
    // explicitClose() bypass these checks and actually tries to close the
    // input stream.
    void explicitClose();
    // implicitClose() actually does the work of closing the input stream.
    void implicitClose();
    void checkCompleted();

    void dispatchUnloadEvents();

    enum PageDismissalType {
        NoDismissal = 0,
        PageHideDismissal = 2,
        UnloadDismissal = 3
    };
    PageDismissalType pageDismissalEventBeingDispatched() const;

    const KURL& url() const { return m_url; }
    void setURL(const KURL&);

    // To understand how these concepts relate to one another, please see the
    // comments surrounding their declaration.
    const KURL& baseURL() const { return m_baseURL; }

    KURL completeURL(const String&) const;

    CSSStyleSheet& elementSheet();

    TextPosition parserPosition() const;

    enum ReadyState {
        Loading,
        Interactive,
        Complete
    };
    void setReadyState(ReadyState);
    bool isLoadCompleted();

    void setParsing(bool);
    bool parsing() const { return m_isParsing; }

    int elapsedTime() const;

    TextLinkColors& textLinkColors() { return m_textLinkColors; }

    bool setFocusedElement(PassRefPtr<Element>, FocusType = FocusTypeNone);
    Element* focusedElement() const { return m_focusedElement.get(); }
    UserActionElementSet& userActionElements()  { return m_userActionElements; }
    const UserActionElementSet& userActionElements() const { return m_userActionElements; }
    void setNeedsFocusedElementCheck();

    void setActiveHoverElement(PassRefPtr<Element>);
    Element* activeHoverElement() const { return m_activeHoverElement.get(); }

    void removeFocusedElementOfSubtree(Node*, bool amongChildrenOnly = false);
    void hoveredNodeDetached(Node*);
    void activeChainNodeDetached(Node*);

    void scheduleVisualUpdate();

    void scheduleRenderTreeUpdateIfNeeded();

    void attachRange(Range*);
    void detachRange(Range*);

    void updateRangesAfterChildrenChanged(ContainerNode*);
    void updateRangesAfterNodeMovedToAnotherDocument(const Node&);
    // nodeChildrenWillBeRemoved is used when removing all node children at once.
    void nodeChildrenWillBeRemoved(ContainerNode&);
    // nodeWillBeRemoved is only safe when removing one node at a time.
    void nodeWillBeRemoved(Node&);

    void didInsertText(Node*, unsigned offset, unsigned length);
    void didRemoveText(Node*, unsigned offset, unsigned length);
    void didMergeTextNodes(Text& oldNode, unsigned offset);
    void didSplitTextNode(Text& oldNode);

    void clearDOMWindow() { m_domWindow = nullptr; }
    LocalDOMWindow* domWindow() const { return m_domWindow; }

    // keep track of what types of event listeners are registered, so we don't
    // dispatch events unnecessarily
    enum ListenerType {
        DOMSUBTREEMODIFIED_LISTENER          = 1,
        DOMNODEINSERTED_LISTENER             = 1 << 1,
        DOMNODEREMOVED_LISTENER              = 1 << 2,
        DOMNODEREMOVEDFROMDOCUMENT_LISTENER  = 1 << 3,
        DOMNODEINSERTEDINTODOCUMENT_LISTENER = 1 << 4,
        DOMCHARACTERDATAMODIFIED_LISTENER    = 1 << 5,
        ANIMATIONEND_LISTENER                = 1 << 6,
        ANIMATIONSTART_LISTENER              = 1 << 7,
        ANIMATIONITERATION_LISTENER          = 1 << 8,
        TRANSITIONEND_LISTENER               = 1 << 9,
    };

    bool hasListenerType(ListenerType listenerType) const { return (m_listenerTypes & listenerType); }
    void addListenerTypeIfNeeded(const AtomicString& eventType);

    bool hasMutationObserversOfType(MutationObserver::MutationType type) const
    {
        return m_mutationObserverTypes & type;
    }
    bool hasMutationObservers() const { return m_mutationObserverTypes; }
    void addMutationObserverTypes(MutationObserverOptions types) { m_mutationObserverTypes |= types; }

    String title() const { return m_title; }
    void setTitle(const String&);

    Element* titleElement() const { return m_titleElement.get(); }
    void setTitleElement(Element*);
    void removeTitle(Element* titleElement);

    const AtomicString& dir();
    void setDir(const AtomicString&);

    const AtomicString& referrer() const;

    String domain() const;
    void setDomain(const String& newDomain, ExceptionState&);

    // The following implements the rule from HTML 4 for what valid names are.
    // To get this right for all the XML cases, we probably have to improve this or move it
    // and make it sensitive to the type of document.
    static bool isValidName(const String&);

    // The following breaks a qualified name into a prefix and a local name.
    // It also does a validity check, and returns false if the qualified name
    // is invalid.  It also sets ExceptionCode when name is invalid.
    static bool parseQualifiedName(const AtomicString& qualifiedName, AtomicString& prefix, AtomicString& localName, ExceptionState&);

    DocumentMarkerController& markers() const { return *m_markers; }

    KURL openSearchDescriptionURL();

    Document& topDocument() const;
    WeakPtr<Document> contextDocument();

    HTMLScriptElement* currentScript() const { return !m_currentScriptStack.isEmpty() ? m_currentScriptStack.last().get() : 0; }
    void pushCurrentScript(PassRefPtr<HTMLScriptElement>);
    void popCurrentScript();

    void finishedParsing();

    const WTF::TextEncoding& encoding() const { return WTF::UTF8Encoding(); }

    virtual void removeAllEventListeners() override final;

    bool allowExecutingScripts(Node*);

    enum LoadEventProgress {
        LoadEventNotRun,
        LoadEventTried,
        LoadEventInProgress,
        LoadEventCompleted,
        PageHideInProgress,
        UnloadEventInProgress,
        UnloadEventHandled
    };
    bool loadEventStillNeeded() const { return m_loadEventProgress == LoadEventNotRun; }
    bool processingLoadEvent() const { return m_loadEventProgress == LoadEventInProgress; }
    bool loadEventFinished() const { return m_loadEventProgress >= LoadEventCompleted; }
    bool unloadStarted() const { return m_loadEventProgress >= PageHideInProgress; }

    virtual bool isContextThread() const override final;

    bool containsValidityStyleRules() const { return m_containsValidityStyleRules; }
    void setContainsValidityStyleRules() { m_containsValidityStyleRules = true; }

    void enqueueResizeEvent();
    void enqueueAnimationFrameEvent(PassRefPtr<Event>);
    // Only one event for a target/event type combination will be dispatched per frame.
    void enqueueUniqueAnimationFrameEvent(PassRefPtr<Event>);
    void enqueueMediaQueryChangeListeners(Vector<RefPtr<MediaQueryListListener> >&);

    // Used to allow element that loads data without going through a FrameLoader to delay the 'load' event.
    void incrementLoadEventDelayCount() { ++m_loadEventDelayCount; }
    void decrementLoadEventDelayCount();
    void checkLoadEventSoon();
    bool isDelayingLoadEvent();

    int requestAnimationFrame(PassOwnPtr<RequestAnimationFrameCallback>);
    void cancelAnimationFrame(int id);
    void serviceScriptedAnimations(double monotonicAnimationStartTime);

    virtual EventTarget* errorEventTarget() override final;
    virtual void logExceptionToConsole(const String& errorMessage, int scriptId, const String& sourceURL, int lineNumber, int columnNumber, PassRefPtr<ScriptCallStack>) override final;

    IntSize initialViewportSize() const;

    void registerElement(const AtomicString& name, PassRefPtr<DartValue> type, ExceptionState&);
    CustomElementRegistry& elementRegistry() const { return *m_elementRegistry; }

    void setImportsController(HTMLImportsController*);
    HTMLImportsController* importsController() const { return m_importsController; }
    HTMLImportsController& ensureImportsController();
    HTMLImportLoader* importLoader() const;
    HTMLImport* import() const;

    bool haveImportsLoaded() const;
    void didLoadAllImports();

    unsigned activeParserCount() { return m_activeParserCount; }
    void incrementActiveParserCount() { ++m_activeParserCount; }
    void decrementActiveParserCount();

    ElementDataCache* elementDataCache() { return m_elementDataCache.get(); }

    void didLoadAllParserBlockingResources();

    bool inStyleRecalc() const { return m_lifecycle.state() == DocumentLifecycle::InStyleRecalc; }

    AnimationClock& animationClock() { return m_animationClock; }
    AnimationTimeline& timeline() const { return *m_timeline; }
    PendingAnimations& pendingAnimations() { return m_pendingAnimations; }

    // A non-null m_templateDocumentHost implies that |this| was created by ensureTemplateDocument().
    bool isTemplateDocument() const { return !!m_templateDocumentHost; }
    Document& ensureTemplateDocument();
    Document* templateDocumentHost() { return m_templateDocumentHost; }

    virtual void addMessage(PassRefPtr<ConsoleMessage>) override final;

    virtual LocalDOMWindow* executingWindow() override final;
    LocalFrame* executingFrame();

    DocumentLifecycleNotifier& lifecycleNotifier();
    DocumentLifecycle& lifecycle() { return m_lifecycle; }
    bool isActive() const { return m_lifecycle.isActive(); }
    bool isStopped() const { return m_lifecycle.state() == DocumentLifecycle::Stopped; }
    bool isDisposed() const { return m_lifecycle.state() == DocumentLifecycle::Disposed; }

    enum HttpRefreshType {
        HttpRefreshFromHeader,
        HttpRefreshFromMetaTag
    };
    void maybeHandleHttpRefresh(const String&, HttpRefreshType);

    PassOwnPtr<LifecycleNotifier<Document> > createLifecycleNotifier();

    void setHasViewportUnits() { m_hasViewportUnits = true; }
    bool hasViewportUnits() const { return m_hasViewportUnits; }
    void notifyResizeForViewportUnits();

    void didRecalculateStyleForElement() { ++m_styleRecalcElementCounter; }

protected:
    explicit Document(const DocumentInit&);

#if !ENABLE(OILPAN)
    virtual void dispose() override;
#endif

    PassRefPtr<Document> cloneDocumentWithoutChildren();

    bool importContainerNodeChildren(ContainerNode* oldContainerNode, PassRefPtr<ContainerNode> newContainerNode, ExceptionState&);

private:
    friend class Node;

    bool isDocumentFragment() const = delete; // This will catch anyone doing an unnecessary check.
    bool isDocumentNode() const = delete; // This will catch anyone doing an unnecessary check.
    bool isElementNode() const = delete; // This will catch anyone doing an unnecessary check.

    ScriptedAnimationController& ensureScriptedAnimationController();
    virtual EventQueue* eventQueue() const override final;

    // FIXME: Rename the StyleRecalc state to RenderTreeUpdate.
    bool hasPendingStyleRecalc() const { return m_lifecycle.state() == DocumentLifecycle::VisualUpdatePending; }

    bool shouldScheduleRenderTreeUpdate() const;
    void scheduleRenderTreeUpdate();

    bool needsFullRenderTreeUpdate() const;

    bool dirtyElementsForLayerUpdate();
    void updateDistributionIfNeeded();
    void evaluateMediaQueryListIfNeeded();

    void updateRenderTree(StyleRecalcChange);
    void updateStyle(StyleRecalcChange);

    void detachParser();

    virtual bool isDocument() const override final { return true; }

    virtual String nodeName() const override final;
    virtual NodeType nodeType() const override final;
    virtual PassRefPtr<Node> cloneNode(bool deep = true) override final;

#if !ENABLE(OILPAN)
    virtual void refExecutionContext() override final { ref(); }
    virtual void derefExecutionContext() override final { deref(); }
#endif

    virtual const KURL& virtualURL() const override final; // Same as url(), but needed for ExecutionContext to implement it without a performance loss for direct calls.
    virtual KURL virtualCompleteURL(const String&) const override final; // Same as completeURL() for the same reason as above.

    virtual void reportBlockedScriptExecutionToInspector(const String& directiveText) override final;

    virtual double timerAlignmentInterval() const override final;

    void updateTitle(const String&);
    void updateBaseURL();

    void resumeParserWaitingForResourcesTimerFired(Timer<Document>*);

    void loadEventDelayTimerFired(Timer<Document>*);

    PageVisibilityState pageVisibilityState() const;

    // Note that dispatching a window load event may cause the LocalDOMWindow to be detached from
    // the LocalFrame, so callers should take a reference to the LocalDOMWindow (which owns us) to
    // prevent the Document from getting blown away from underneath them.
    void dispatchWindowLoadEvent();

    void addListenerType(ListenerType listenerType) { m_listenerTypes |= listenerType; }

    void clearFocusedElementSoon();
    void clearFocusedElementTimerFired(Timer<Document>*);

    void setHoverNode(PassRefPtr<Node>);
    Node* hoverNode() const { return m_hoverNode.get(); }

    DocumentLifecycle m_lifecycle;

    AbstractModule* m_module;

    bool m_evaluateMediaQueriesOnStyleRecalc;

    LocalFrame* m_frame;
    RawPtr<LocalDOMWindow> m_domWindow;
    // FIXME: oilpan: when we get rid of the transition types change the
    // HTMLImportsController to not be a DocumentSupplement since it is
    // redundant with oilpan.
    RawPtr<HTMLImportsController> m_importsController;

    RefPtr<ResourceFetcher> m_fetcher;
    RefPtr<DocumentParser> m_parser;
    unsigned m_activeParserCount;

    // Document URLs.
    KURL m_url; // Document.URL: The URL from which this document was retrieved.
    KURL m_baseURL; // Node.baseURI: The URL to use when resolving relative URLs.

    // Mime-type of the document in case it was cloned or created by XHR.
    AtomicString m_mimeType;

    RefPtr<CSSStyleSheet> m_elemSheet;

    Timer<Document> m_resumeParserWaitingForResourcesTimer;

    Timer<Document> m_clearFocusedElementTimer;
    RefPtr<Element> m_focusedElement;
    RefPtr<Node> m_hoverNode;
    RefPtr<Element> m_activeHoverElement;
    UserActionElementSet m_userActionElements;

    typedef HashSet<RawPtr<Range> > AttachedRangeSet;
    AttachedRangeSet m_ranges;

    unsigned short m_listenerTypes;

    MutationObserverOptions m_mutationObserverTypes;

    OwnPtr<StyleEngine> m_styleEngine;

    TextLinkColors m_textLinkColors;

    ReadyState m_readyState;
    bool m_isParsing;

    bool m_containsValidityStyleRules;

    String m_title;
    String m_rawTitle;
    RefPtr<Element> m_titleElement;

    OwnPtr<DocumentMarkerController> m_markers;

    LoadEventProgress m_loadEventProgress;

    double m_startTime;

    Vector<RefPtr<HTMLScriptElement> > m_currentScriptStack;

    AtomicString m_contentLanguage;

    OwnPtr<SelectorQueryCache> m_selectorQueryCache;

    RenderView* m_renderView;

#if !ENABLE(OILPAN)
    WeakPtrFactory<Document> m_weakFactory;
#endif
    WeakPtr<Document> m_contextDocument;

    int m_loadEventDelayCount;
    Timer<Document> m_loadEventDelayTimer;

    Length m_viewportDefaultMinWidth;

    bool m_didSetReferrerPolicy;
    ReferrerPolicy m_referrerPolicy;

    RefPtr<MediaQueryMatcher> m_mediaQueryMatcher;

    RefPtr<ScriptedAnimationController> m_scriptedAnimationController;

    RefPtr<CustomElementRegistry> m_elementRegistry;

    void elementDataCacheClearTimerFired(Timer<Document>*);
    Timer<Document> m_elementDataCacheClearTimer;

    OwnPtr<ElementDataCache> m_elementDataCache;

    AnimationClock m_animationClock;
    RefPtr<AnimationTimeline> m_timeline;
    PendingAnimations m_pendingAnimations;

    RefPtr<Document> m_templateDocument;
    // With Oilpan the templateDocument and the templateDocumentHost
    // live and die together. Without Oilpan, the templateDocumentHost
    // is a manually managed backpointer from m_templateDocument.
    RawPtr<Document> m_templateDocumentHost;

    bool m_hasViewportUnits;

    int m_styleRecalcElementCounter;
    mutable DocumentLoadTiming m_documentLoadTiming;
};

inline void Document::scheduleRenderTreeUpdateIfNeeded()
{
    // Inline early out to avoid the function calls below.
    if (hasPendingStyleRecalc())
        return;
    if (shouldScheduleRenderTreeUpdate() && needsRenderTreeUpdate())
        scheduleRenderTreeUpdate();
}

DEFINE_TYPE_CASTS(Document, ExecutionContextClient, client, client->isDocument(), client.isDocument());
DEFINE_TYPE_CASTS(Document, ExecutionContext, context, context->isDocument(), context.isDocument());
DEFINE_NODE_TYPE_CASTS(Document, isDocumentNode());

#define DEFINE_DOCUMENT_TYPE_CASTS(thisType) \
    DEFINE_TYPE_CASTS(thisType, Document, document, document->is##thisType(), document.is##thisType())

// This is needed to avoid ambiguous overloads with the Node and TreeScope versions.
DEFINE_COMPARISON_OPERATORS_WITH_REFERENCES(Document)

// Put these methods here, because they require the Document definition, but we really want to inline them.

inline bool Node::isDocumentNode() const
{
    return this == document();
}

} // namespace blink

#ifndef NDEBUG
// Outside the WebCore namespace for ease of invocation from gdb.
void showLiveDocumentInstances();
#endif

#endif  // SKY_ENGINE_CORE_DOM_DOCUMENT_H_
