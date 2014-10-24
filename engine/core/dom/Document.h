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

#ifndef Document_h
#define Document_h

#include "bindings/core/v8/ExceptionStatePlaceholder.h"
#include "bindings/core/v8/ScriptValue.h"
#include "core/animation/AnimationClock.h"
#include "core/animation/CompositorPendingAnimations.h"
#include "core/dom/ContainerNode.h"
#include "core/dom/DocumentInit.h"
#include "core/dom/DocumentLifecycle.h"
#include "core/dom/DocumentSupplementable.h"
#include "core/dom/ExecutionContext.h"
#include "core/dom/MutationObserver.h"
#include "core/dom/TextLinkColors.h"
#include "core/dom/TreeScope.h"
#include "core/dom/UserActionElementSet.h"
#include "core/dom/ViewportDescription.h"
#include "core/dom/custom/CustomElement.h"
#include "core/fetch/ResourceClient.h"
#include "core/loader/DocumentLoadTiming.h"
#include "core/page/FocusType.h"
#include "core/page/PageVisibilityState.h"
#include "platform/Length.h"
#include "platform/Timer.h"
#include "platform/heap/Handle.h"
#include "platform/weborigin/KURL.h"
#include "platform/weborigin/ReferrerPolicy.h"
#include "wtf/HashSet.h"
#include "wtf/OwnPtr.h"
#include "wtf/PassOwnPtr.h"
#include "wtf/PassRefPtr.h"
#include "wtf/WeakPtr.h"
#include "wtf/text/TextEncoding.h"

namespace blink {

class AnimationTimeline;
class Attr;
class CSSStyleDeclaration;
class CSSStyleSheet;
class CanvasRenderingContext2D;
class Comment;
class ConsoleMessage;
class CustomElementMicrotaskRunQueue;
class CustomElementRegistrationContext;
class DOMImplementation;
class DocumentFragment;
class DocumentLifecycleNotifier;
class DocumentLoadTiming;
class DocumentMarkerController;
class DocumentParser;
class Element;
class ElementDataCache;
class Event;
class EventFactoryBase;
class EventListener;
template <typename EventType>
class EventWithHitTestResults;
class ExceptionState;
class FloatQuad;
class FloatRect;
class Frame;
class FrameHost;
class FrameView;
class HTMLCanvasElement;
class HTMLDocumentParser;
class HTMLElement;
class HTMLImport;
class HTMLImportLoader;
class HTMLImportsController;
class HTMLLinkElement;
class HTMLScriptElement;
class HitTestRequest;
class LayoutPoint;
class Locale;
class LocalDOMWindow;
class LocalFrame;
class Location;
class MediaQueryListListener;
class MediaQueryMatcher;
class Page;
class PlatformMouseEvent;
class QualifiedName;
class Range;
class RenderView;
class RequestAnimationFrameCallback;
class ResourceFetcher;
class ScriptRunner;
class ScriptedAnimationController;
class SegmentedString;
class SelectorQueryCache;
class SerializedScriptValue;
class Settings;
class StyleEngine;
class StyleResolver;
class StyleSheet;
class StyleSheetList;
class Text;
class Touch;
class TouchList;
class WebGLRenderingContext;

struct AnnotatedRegionValue;

typedef EventWithHitTestResults<PlatformMouseEvent> MouseEventWithHitTestResults;
typedef int ExceptionCode;

enum StyleResolverUpdateMode {
    // Discards the StyleResolver and rebuilds it.
    FullStyleUpdate,
    // Attempts to use StyleInvalidationAnalysis to avoid discarding the entire StyleResolver.
    AnalyzedStyleUpdate
};

enum DocumentClass {
    DefaultDocumentClass = 0,
    HTMLDocumentClass = 1,
    MediaDocumentClass = 1 << 4,
};

typedef unsigned char DocumentClassFlags;

class Document;

class DocumentVisibilityObserver : public WillBeGarbageCollectedMixin {
public:
    DocumentVisibilityObserver(Document&);
    virtual ~DocumentVisibilityObserver();

    virtual void didChangeVisibilityState(PageVisibilityState) = 0;

    // Classes that inherit Node and DocumentVisibilityObserver must have a
    // virtual override of Node::didMoveToNewDocument that calls
    // DocumentVisibilityObserver::setDocument
    void setObservedDocument(Document&);

protected:
    virtual void trace(Visitor*);

private:
    void registerObserver(Document&);
    void unregisterObserver();

    RawPtrWillBeMember<Document> m_document;
};

class Document : public ContainerNode, public TreeScope, public ExecutionContext, public ExecutionContextClient
    , public DocumentSupplementable, public LifecycleContext<Document>, public ResourceClient {
    DEFINE_WRAPPERTYPEINFO();
    WILL_BE_USING_GARBAGE_COLLECTED_MIXIN(Document);
public:
    static PassRefPtrWillBeRawPtr<Document> create(const DocumentInit& initializer = DocumentInit())
    {
        return adoptRefWillBeNoop(new Document(initializer));
    }
    virtual ~Document();

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

    // DOM methods & attributes for Document

    bool shouldOverrideLegacyDescription(ViewportDescription::Type);
    void setViewportDescription(const ViewportDescription&);
    const ViewportDescription& viewportDescription() const { return m_viewportDescription; }
    Length viewportDefaultMinWidth() const { return m_viewportDefaultMinWidth; }

    void setReferrerPolicy(ReferrerPolicy);
    ReferrerPolicy referrerPolicy() const { return m_referrerPolicy; }

    String outgoingReferrer();

    DOMImplementation& implementation();

    Element* documentElement() const
    {
        return m_documentElement.get();
    }

    Location* location() const;

    PassRefPtrWillBeRawPtr<Element> createElement(const AtomicString& name, ExceptionState&);
    PassRefPtrWillBeRawPtr<DocumentFragment> createDocumentFragment();
    PassRefPtrWillBeRawPtr<Text> createTextNode(const String& data);
    PassRefPtrWillBeRawPtr<Node> importNode(Node* importedNode, bool deep, ExceptionState&);
    PassRefPtrWillBeRawPtr<Element> createElement(const QualifiedName&, bool createdByParser);

    Element* elementFromPoint(int x, int y) const;
    PassRefPtrWillBeRawPtr<Range> caretRangeFromPoint(int x, int y);

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

    PassRefPtrWillBeRawPtr<Node> adoptNode(PassRefPtrWillBeRawPtr<Node> source, ExceptionState&);

    bool isHTMLDocument() const { return m_documentClasses & HTMLDocumentClass; }

    struct TransitionElementData {
        String scope;
        String selector;
        String markup;
    };
    void getTransitionElementData(Vector<TransitionElementData>&);

    StyleResolver* styleResolver() const;
    StyleResolver& ensureStyleResolver() const;

    bool isRenderingReady() const { return haveImportsLoaded(); }
    bool isScriptExecutionReady() const { return isRenderingReady(); }

    // This is a DOM function.
    StyleSheetList* styleSheets();

    StyleEngine* styleEngine() { return m_styleEngine.get(); }

    // Called when one or more stylesheets in the document may have been added, removed, or changed.
    void styleResolverChanged(StyleResolverUpdateMode = FullStyleUpdate);
    void styleResolverMayHaveChanged();

    // FIXME: Switch all callers of styleResolverChanged to these or better ones and then make them
    // do something smarter.
    void removedStyleSheet(StyleSheet*, StyleResolverUpdateMode = FullStyleUpdate);
    void addedStyleSheet(StyleSheet*) { styleResolverChanged(); }
    void modifiedStyleSheet(StyleSheet*, StyleResolverUpdateMode = FullStyleUpdate);
    void changedSelectorWatch() { styleResolverChanged(); }

    void evaluateMediaQueryList();

    void setStateForNewFormElements(const Vector<String>&);

    FrameView* view() const; // can be null
    LocalFrame* frame() const { return m_frame; } // can be null
    FrameHost* frameHost() const; // can be null
    Page* page() const; // can be null
    Settings* settings() const; // can be null

    float devicePixelRatio() const;

    PassRefPtrWillBeRawPtr<Range> createRange();

    // Special support for editing
    PassRefPtrWillBeRawPtr<Text> createEditingTextNode(const String&);

    void setupFontBuilder(RenderStyle* documentStyle);

    bool needsRenderTreeUpdate() const;
    void updateRenderTreeIfNeeded() { updateRenderTree(NoChange); }
    void updateRenderTreeForNodeIfNeeded(Node*);
    void updateLayout();
    enum RunPostLayoutTasks {
        RunPostLayoutTasksAsyhnchronously,
        RunPostLayoutTasksSynchronously,
    };
    void updateLayoutIgnorePendingStylesheets(RunPostLayoutTasks = RunPostLayoutTasksAsyhnchronously);
    PassRefPtr<RenderStyle> styleForElementIgnoringPendingStylesheets(Element*);

    void updateDistributionForNodeIfNeeded(Node*);

    ResourceFetcher* fetcher() { return m_fetcher.get(); }

    virtual void attach(const AttachContext& = AttachContext()) override;
    virtual void detach(const AttachContext& = AttachContext()) override;
    void prepareForDestruction();

    // If you have a Document, use renderView() instead which is faster.
    void renderer() const WTF_DELETED_FUNCTION;

    RenderView* renderView() const { return m_renderView; }

    DocumentLoadTiming* timing() const;

    void startParsing();
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

    ScriptValue exports() const { return m_exports; }
    void setExports(ScriptValue exports) { m_exports = exports; }

    // To understand how these concepts relate to one another, please see the
    // comments surrounding their declaration.
    const KURL& baseURL() const { return m_baseURL; }

    KURL completeURL(const String&) const;

    CSSStyleSheet& elementSheet();

    virtual PassRefPtrWillBeRawPtr<DocumentParser> createParser();
    DocumentParser* parser() const { return m_parser.get(); }
    HTMLDocumentParser* scriptableDocumentParser() const;

    enum ReadyState {
        Loading,
        Interactive,
        Complete
    };
    void setReadyState(ReadyState);
    bool isLoadCompleted();

    void setParsing(bool);
    bool parsing() const { return m_isParsing; }

    bool shouldScheduleLayout() const;
    int elapsedTime() const;

    TextLinkColors& textLinkColors() { return m_textLinkColors; }

    MouseEventWithHitTestResults prepareMouseEvent(const HitTestRequest&, const LayoutPoint&, const PlatformMouseEvent&);

    bool setFocusedElement(PassRefPtrWillBeRawPtr<Element>, FocusType = FocusTypeNone);
    Element* focusedElement() const { return m_focusedElement.get(); }
    UserActionElementSet& userActionElements()  { return m_userActionElements; }
    const UserActionElementSet& userActionElements() const { return m_userActionElements; }
    void setNeedsFocusedElementCheck();
    void setAutofocusElement(Element*);
    Element* autofocusElement() const { return m_autofocusElement.get(); }

    void setActiveHoverElement(PassRefPtrWillBeRawPtr<Element>);
    Element* activeHoverElement() const { return m_activeHoverElement.get(); }

    void removeFocusedElementOfSubtree(Node*, bool amongChildrenOnly = false);
    void hoveredNodeDetached(Node*);
    void activeChainNodeDetached(Node*);

    void updateHoverActiveState(const HitTestRequest&, Element*, const PlatformMouseEvent* = 0);

    void scheduleRenderTreeUpdateIfNeeded();
    bool hasPendingForcedStyleRecalc() const;

    void attachRange(Range*);
    void detachRange(Range*);

    void updateRangesAfterChildrenChanged(ContainerNode*);
    void updateRangesAfterNodeMovedToAnotherDocument(const Node&);
    // nodeChildrenWillBeRemoved is used when removing all node children at once.
    void nodeChildrenWillBeRemoved(ContainerNode&);
    // nodeWillBeRemoved is only safe when removing one node at a time.
    void nodeWillBeRemoved(Node&);
    bool canReplaceChild(const Node& newChild, const Node& oldChild) const;

    void didInsertText(Node*, unsigned offset, unsigned length);
    void didRemoveText(Node*, unsigned offset, unsigned length);
    void didMergeTextNodes(Text& oldNode, unsigned offset);
    void didSplitTextNode(Text& oldNode);

    void clearDOMWindow() { m_domWindow = nullptr; }
    LocalDOMWindow* domWindow() const { return m_domWindow; }

    static void registerEventFactory(PassOwnPtr<EventFactoryBase>);
    static PassRefPtrWillBeRawPtr<Event> createEvent(const String& eventType, ExceptionState&);

    // keep track of what types of event listeners are registered, so we don't
    // dispatch events unnecessarily
    enum ListenerType {
        DOMSUBTREEMODIFIED_LISTENER          = 1,
        DOMNODEINSERTED_LISTENER             = 1 << 1,
        DOMNODEREMOVED_LISTENER              = 1 << 2,
        DOMNODEREMOVEDFROMDOCUMENT_LISTENER  = 1 << 3,
        DOMNODEINSERTEDINTODOCUMENT_LISTENER = 1 << 4,
        DOMCHARACTERDATAMODIFIED_LISTENER    = 1 << 5,
        OVERFLOWCHANGED_LISTENER             = 1 << 6,
        ANIMATIONEND_LISTENER                = 1 << 7,
        ANIMATIONSTART_LISTENER              = 1 << 8,
        ANIMATIONITERATION_LISTENER          = 1 << 9,
        TRANSITIONEND_LISTENER               = 1 << 10,
        SCROLL_LISTENER                      = 1 << 12
        // 4 bits remaining
    };

    bool hasListenerType(ListenerType listenerType) const { return (m_listenerTypes & listenerType); }
    void addListenerTypeIfNeeded(const AtomicString& eventType);

    bool hasMutationObserversOfType(MutationObserver::MutationType type) const
    {
        return m_mutationObserverTypes & type;
    }
    bool hasMutationObservers() const { return m_mutationObserverTypes; }
    void addMutationObserverTypes(MutationObserverOptions types) { m_mutationObserverTypes |= types; }

    /**
     * Handles a HTTP header equivalent set by a meta tag using <meta http-equiv="..." content="...">. This is called
     * when a meta tag is encountered during document parsing, and also when a script dynamically changes or adds a meta
     * tag. This enables scripts to use meta tags to perform refreshes and set expiry dates in addition to them being
     * specified in a HTML file.
     *
     * @param equiv The http header name (value of the meta tag's "equiv" attribute)
     * @param content The header value (value of the meta tag's "content" attribute)
     * @param inDocumentHeadElement Is the element in the document's <head> element?
     */
    void processHttpEquiv(const AtomicString& equiv, const AtomicString& content, bool inDocumentHeadElement);
    void updateViewportDescription();
    void processReferrerPolicy(const String& policy);

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

    // Decide which element is to define the viewport's overflow policy. If |rootStyle| is set, use
    // that as the style for the root element, rather than obtaining it on our own. The reason for
    // this is that style may not have been associated with the elements yet - in which case it may
    // have been calculated on the fly (without associating it with the actual element) somewhere.
    Element* viewportDefiningElement(RenderStyle* rootStyle = 0) const;

    DocumentMarkerController& markers() const { return *m_markers; }

    bool directionSetOnDocumentElement() const { return m_directionSetOnDocumentElement; }
    bool writingModeSetOnDocumentElement() const { return m_writingModeSetOnDocumentElement; }
    void setDirectionSetOnDocumentElement(bool b) { m_directionSetOnDocumentElement = b; }
    void setWritingModeSetOnDocumentElement(bool b) { m_writingModeSetOnDocumentElement = b; }

    bool execCommand(const String& command, bool userInterface = false, const String& value = String());
    bool queryCommandEnabled(const String& command);
    bool queryCommandIndeterm(const String& command);
    bool queryCommandState(const String& command);
    bool queryCommandSupported(const String& command);
    String queryCommandValue(const String& command);

    KURL openSearchDescriptionURL();

    Document& topDocument() const;
    WeakPtrWillBeRawPtr<Document> contextDocument();

    HTMLScriptElement* currentScript() const { return !m_currentScriptStack.isEmpty() ? m_currentScriptStack.last().get() : 0; }
    void pushCurrentScript(PassRefPtrWillBeRawPtr<HTMLScriptElement>);
    void popCurrentScript();

    enum PendingSheetLayout { NoLayoutWithPendingSheets, DidLayoutWithPendingSheets, IgnoreLayoutWithPendingSheets };

    bool didLayoutWithPendingStylesheets() const { return m_pendingSheetLayout == DidLayoutWithPendingSheets; }
    bool ignoreLayoutWithPendingStylesheets() const { return m_pendingSheetLayout == IgnoreLayoutWithPendingSheets; }

    bool hasNodesWithPlaceholderStyle() const { return m_hasNodesWithPlaceholderStyle; }
    void setHasNodesWithPlaceholderStyle() { m_hasNodesWithPlaceholderStyle = true; }

    // Extension for manipulating canvas drawing contexts for use in CSS
    void getCSSCanvasContext(const String& type, const String& name, int width, int height, RefPtrWillBeRawPtr<CanvasRenderingContext2D>&, RefPtrWillBeRawPtr<WebGLRenderingContext>&);
    HTMLCanvasElement& getCSSCanvasElement(const String& name);

    void finishedParsing();

    const WTF::TextEncoding& encoding() const { return WTF::UTF8Encoding(); }

    virtual void removeAllEventListeners() override final;

    bool allowExecutingScripts(Node*);

    void statePopped(PassRefPtr<SerializedScriptValue>);

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
    void enqueueScrollEventForNode(Node*);
    void enqueueAnimationFrameEvent(PassRefPtrWillBeRawPtr<Event>);
    // Only one event for a target/event type combination will be dispatched per frame.
    void enqueueUniqueAnimationFrameEvent(PassRefPtrWillBeRawPtr<Event>);
    void enqueueMediaQueryChangeListeners(WillBeHeapVector<RefPtrWillBeMember<MediaQueryListListener> >&);

    // Used to allow element that loads data without going through a FrameLoader to delay the 'load' event.
    void incrementLoadEventDelayCount() { ++m_loadEventDelayCount; }
    void decrementLoadEventDelayCount();
    void checkLoadEventSoon();
    bool isDelayingLoadEvent();

    PassRefPtrWillBeRawPtr<Touch> createTouch(LocalDOMWindow*, EventTarget*, int identifier, double pageX, double pageY, double screenX, double screenY, double radiusX, double radiusY, float rotationAngle, float force) const;
    PassRefPtrWillBeRawPtr<TouchList> createTouchList(WillBeHeapVector<RefPtrWillBeMember<Touch> >&) const;

    int requestAnimationFrame(PassOwnPtrWillBeRawPtr<RequestAnimationFrameCallback>);
    void cancelAnimationFrame(int id);
    void serviceScriptedAnimations(double monotonicAnimationStartTime);

    virtual EventTarget* errorEventTarget() override final;
    virtual void logExceptionToConsole(const String& errorMessage, int scriptId, const String& sourceURL, int lineNumber, int columnNumber, PassRefPtrWillBeRawPtr<ScriptCallStack>) override final;

    IntSize initialViewportSize() const;

    PassRefPtrWillBeRawPtr<Element> createElement(const AtomicString& localName, const AtomicString& typeExtension, ExceptionState&);
    ScriptValue registerElement(ScriptState*, const AtomicString& name, ExceptionState&);
    ScriptValue registerElement(ScriptState*, const AtomicString& name, const Dictionary& options, ExceptionState&, CustomElement::NameSet validNames = CustomElement::StandardNames);
    CustomElementRegistrationContext* registrationContext() { return m_registrationContext.get(); }
    CustomElementMicrotaskRunQueue* customElementMicrotaskRunQueue();

    void setImportsController(HTMLImportsController*);
    HTMLImportsController* importsController() const { return m_importsController; }
    HTMLImportLoader* importLoader() const;
    HTMLImport* import() const;

    bool haveImportsLoaded() const;
    void didLoadAllImports();

    void adjustFloatQuadsForScrollAndAbsoluteZoom(Vector<FloatQuad>&, RenderObject&);
    void adjustFloatRectForScrollAndAbsoluteZoom(FloatRect&, RenderObject&);

    bool hasActiveParser();
    unsigned activeParserCount() { return m_activeParserCount; }
    void incrementActiveParserCount() { ++m_activeParserCount; }
    void decrementActiveParserCount();

    ElementDataCache* elementDataCache() { return m_elementDataCache.get(); }

    void didLoadAllScriptBlockingResources();
    void didRemoveAllPendingStylesheet();
    void clearStyleResolver();

    bool inStyleRecalc() const { return m_lifecycle.state() == DocumentLifecycle::InStyleRecalc; }

    // Return a Locale for the default locale if the argument is null or empty.
    Locale& getCachedLocale(const AtomicString& locale = nullAtom);

    AnimationClock& animationClock() { return m_animationClock; }
    AnimationTimeline& timeline() const { return *m_timeline; }
    CompositorPendingAnimations& compositorPendingAnimations() { return m_compositorPendingAnimations; }

    // A non-null m_templateDocumentHost implies that |this| was created by ensureTemplateDocument().
    bool isTemplateDocument() const { return !!m_templateDocumentHost; }
    Document& ensureTemplateDocument();
    Document* templateDocumentHost() { return m_templateDocumentHost; }

    virtual void addMessage(PassRefPtrWillBeRawPtr<ConsoleMessage>) override final;

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

    void registerVisibilityObserver(DocumentVisibilityObserver*);
    void unregisterVisibilityObserver(DocumentVisibilityObserver*);

    void updateStyleInvalidationIfNeeded();

    virtual void trace(Visitor*) override;

    void didRecalculateStyleForElement() { ++m_styleRecalcElementCounter; }

    virtual v8::Handle<v8::Object> wrap(v8::Handle<v8::Object> creationContext, v8::Isolate*) override;

protected:
    Document(const DocumentInit&, DocumentClassFlags = DefaultDocumentClass);

#if !ENABLE(OILPAN)
    virtual void dispose() override;
#endif

    PassRefPtrWillBeRawPtr<Document> cloneDocumentWithoutChildren();

    bool importContainerNodeChildren(ContainerNode* oldContainerNode, PassRefPtrWillBeRawPtr<ContainerNode> newContainerNode, ExceptionState&);

private:
    friend class Node;

    bool isDocumentFragment() const WTF_DELETED_FUNCTION; // This will catch anyone doing an unnecessary check.
    bool isDocumentNode() const WTF_DELETED_FUNCTION; // This will catch anyone doing an unnecessary check.
    bool isElementNode() const WTF_DELETED_FUNCTION; // This will catch anyone doing an unnecessary check.

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

    void clearWeakMembers(Visitor*);

    virtual bool isDocument() const override final { return true; }

    virtual void childrenChanged(const ChildrenChange&) override;

    virtual String nodeName() const override final;
    virtual NodeType nodeType() const override final;
    virtual bool childTypeAllowed(NodeType) const override final;
    virtual PassRefPtrWillBeRawPtr<Node> cloneNode(bool deep = true) override final;

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

    void executeScriptsWaitingForResourcesTimerFired(Timer<Document>*);

    void loadEventDelayTimerFired(Timer<Document>*);

    PageVisibilityState pageVisibilityState() const;

    // Note that dispatching a window load event may cause the LocalDOMWindow to be detached from
    // the LocalFrame, so callers should take a reference to the LocalDOMWindow (which owns us) to
    // prevent the Document from getting blown away from underneath them.
    void dispatchWindowLoadEvent();

    void addListenerType(ListenerType listenerType) { m_listenerTypes |= listenerType; }

    void clearFocusedElementSoon();
    void clearFocusedElementTimerFired(Timer<Document>*);
    void focusAutofocusElementTimerFired(Timer<Document>*);

    void processHttpEquivRefresh(const AtomicString& content);

    void setHoverNode(PassRefPtrWillBeRawPtr<Node>);
    Node* hoverNode() const { return m_hoverNode.get(); }

    typedef HashSet<OwnPtr<EventFactoryBase> > EventFactorySet;
    static EventFactorySet& eventFactories();

    DocumentLifecycle m_lifecycle;

    bool m_hasNodesWithPlaceholderStyle;
    bool m_evaluateMediaQueriesOnStyleRecalc;

    // If we do ignore the pending stylesheet count, then we need to add a boolean
    // to track that this happened so that we can do a full repaint when the stylesheets
    // do eventually load.
    PendingSheetLayout m_pendingSheetLayout;

    LocalFrame* m_frame;
    RawPtrWillBeMember<LocalDOMWindow> m_domWindow;
    // FIXME: oilpan: when we get rid of the transition types change the
    // HTMLImportsController to not be a DocumentSupplement since it is
    // redundant with oilpan.
    RawPtrWillBeMember<HTMLImportsController> m_importsController;

    RefPtrWillBeMember<ResourceFetcher> m_fetcher;
    RefPtrWillBeMember<DocumentParser> m_parser;
    unsigned m_activeParserCount;

    // Document URLs.
    KURL m_url; // Document.URL: The URL from which this document was retrieved.
    KURL m_baseURL; // Node.baseURI: The URL to use when resolving relative URLs.

    // Mime-type of the document in case it was cloned or created by XHR.
    AtomicString m_mimeType;

    OwnPtrWillBeMember<DOMImplementation> m_implementation;

    RefPtrWillBeMember<CSSStyleSheet> m_elemSheet;

    Timer<Document> m_executeScriptsWaitingForResourcesTimer;

    bool m_hasAutofocused;
    Timer<Document> m_clearFocusedElementTimer;
    Timer<Document> m_focusAutofocusElementTimer;
    RefPtrWillBeMember<Element> m_autofocusElement;
    RefPtrWillBeMember<Element> m_focusedElement;
    RefPtrWillBeMember<Node> m_hoverNode;
    RefPtrWillBeMember<Element> m_activeHoverElement;
    RefPtrWillBeMember<Element> m_documentElement;
    UserActionElementSet m_userActionElements;

    typedef WillBeHeapHashSet<RawPtrWillBeWeakMember<Range> > AttachedRangeSet;
    AttachedRangeSet m_ranges;

    unsigned short m_listenerTypes;

    MutationObserverOptions m_mutationObserverTypes;

    OwnPtrWillBeMember<StyleEngine> m_styleEngine;
    RefPtrWillBeMember<StyleSheetList> m_styleSheetList;

    TextLinkColors m_textLinkColors;

    ScriptValue m_exports;

    ReadyState m_readyState;
    bool m_isParsing;

    bool m_containsValidityStyleRules;

    String m_title;
    String m_rawTitle;
    RefPtrWillBeMember<Element> m_titleElement;

    OwnPtrWillBeMember<DocumentMarkerController> m_markers;

    LoadEventProgress m_loadEventProgress;

    double m_startTime;

    WillBeHeapVector<RefPtrWillBeMember<HTMLScriptElement> > m_currentScriptStack;

    AtomicString m_contentLanguage;

    WillBeHeapHashMap<String, RefPtrWillBeMember<HTMLCanvasElement> > m_cssCanvasElements;

    OwnPtr<SelectorQueryCache> m_selectorQueryCache;

    DocumentClassFlags m_documentClasses;

    RenderView* m_renderView;

#if !ENABLE(OILPAN)
    WeakPtrFactory<Document> m_weakFactory;
#endif
    WeakPtrWillBeWeakMember<Document> m_contextDocument;

    int m_loadEventDelayCount;
    Timer<Document> m_loadEventDelayTimer;

    ViewportDescription m_viewportDescription;
    ViewportDescription m_legacyViewportDescription;
    Length m_viewportDefaultMinWidth;

    bool m_didSetReferrerPolicy;
    ReferrerPolicy m_referrerPolicy;

    bool m_directionSetOnDocumentElement;
    bool m_writingModeSetOnDocumentElement;

    RefPtrWillBeMember<MediaQueryMatcher> m_mediaQueryMatcher;

    RefPtrWillBeMember<ScriptedAnimationController> m_scriptedAnimationController;

    RefPtrWillBeMember<CustomElementRegistrationContext> m_registrationContext;
    RefPtrWillBeMember<CustomElementMicrotaskRunQueue> m_customElementMicrotaskRunQueue;

    void elementDataCacheClearTimerFired(Timer<Document>*);
    Timer<Document> m_elementDataCacheClearTimer;

    OwnPtrWillBeMember<ElementDataCache> m_elementDataCache;

    typedef HashMap<AtomicString, OwnPtr<Locale> > LocaleIdentifierToLocaleMap;
    LocaleIdentifierToLocaleMap m_localeCache;

    AnimationClock m_animationClock;
    RefPtrWillBeMember<AnimationTimeline> m_timeline;
    CompositorPendingAnimations m_compositorPendingAnimations;

    RefPtrWillBeMember<Document> m_templateDocument;
    // With Oilpan the templateDocument and the templateDocumentHost
    // live and die together. Without Oilpan, the templateDocumentHost
    // is a manually managed backpointer from m_templateDocument.
    RawPtrWillBeMember<Document> m_templateDocumentHost;

    bool m_hasViewportUnits;

    typedef WillBeHeapHashSet<RawPtrWillBeWeakMember<DocumentVisibilityObserver> > DocumentVisibilityObserverSet;
    DocumentVisibilityObserverSet m_visibilityObservers;

    int m_styleRecalcElementCounter;
    mutable DocumentLoadTiming m_documentLoadTiming;
};

inline bool Document::shouldOverrideLegacyDescription(ViewportDescription::Type origin)
{
    // The different (legacy) meta tags have different priorities based on the type
    // regardless of which order they appear in the DOM. The priority is given by the
    // ViewportDescription::Type enum.
    return origin >= m_legacyViewportDescription.type;
}

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

Node* eventTargetNodeForDocument(Document*);

} // namespace blink

#ifndef NDEBUG
// Outside the WebCore namespace for ease of invocation from gdb.
void showLiveDocumentInstances();
#endif

#endif // Document_h
