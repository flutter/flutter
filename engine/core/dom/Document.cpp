/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2001 Dirk Mueller (mueller@kde.org)
 *           (C) 2006 Alexey Proskuryakov (ap@webkit.org)
 * Copyright (C) 2004, 2005, 2006, 2007, 2008, 2009, 2011, 2012 Apple Inc. All rights reserved.
 * Copyright (C) 2008, 2009 Torch Mobile Inc. All rights reserved. (http://www.torchmobile.com/)
 * Copyright (C) 2008, 2009, 2011, 2012 Google Inc. All rights reserved.
 * Copyright (C) 2010 Nokia Corporation and/or its subsidiary(-ies)
 * Copyright (C) Research In Motion Limited 2010-2011. All rights reserved.
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

#include "config.h"
#include "core/dom/Document.h"

#include "bindings/core/v8/CustomElementConstructorBuilder.h"
#include "bindings/core/v8/DOMDataStore.h"
#include "bindings/core/v8/Dictionary.h"
#include "bindings/core/v8/ExceptionMessages.h"
#include "bindings/core/v8/ExceptionState.h"
#include "bindings/core/v8/ExceptionStatePlaceholder.h"
#include "bindings/core/v8/ScriptController.h"
#include "bindings/core/v8/V8DOMWrapper.h"
#include "bindings/core/v8/WindowProxy.h"
#include "core/HTMLElementFactory.h"
#include "core/animation/AnimationTimeline.h"
#include "core/animation/DocumentAnimations.h"
#include "core/css/CSSFontSelector.h"
#include "core/css/CSSStyleDeclaration.h"
#include "core/css/CSSStyleSheet.h"
#include "core/css/MediaQueryMatcher.h"
#include "core/css/StylePropertySet.h"
#include "core/css/StyleSheetContents.h"
#include "core/css/StyleSheetList.h"
#include "core/css/invalidation/StyleInvalidator.h"
#include "core/css/parser/BisonCSSParser.h"
#include "core/css/resolver/FontBuilder.h"
#include "core/css/resolver/StyleResolver.h"
#include "core/css/resolver/StyleResolverStats.h"
#include "core/dom/Attr.h"
#include "core/dom/DOMImplementation.h"
#include "core/dom/DocumentFragment.h"
#include "core/dom/DocumentLifecycleNotifier.h"
#include "core/dom/DocumentLifecycleObserver.h"
#include "core/dom/DocumentMarkerController.h"
#include "core/dom/Element.h"
#include "core/dom/ElementDataCache.h"
#include "core/dom/ElementTraversal.h"
#include "core/dom/ExceptionCode.h"
#include "core/dom/MutationObserver.h"
#include "core/dom/NodeRareData.h"
#include "core/dom/NodeRenderStyle.h"
#include "core/dom/NodeRenderingTraversal.h"
#include "core/dom/NodeTraversal.h"
#include "core/dom/NodeWithIndex.h"
#include "core/dom/RequestAnimationFrameCallback.h"
#include "core/dom/ScriptedAnimationController.h"
#include "core/dom/SelectorQuery.h"
#include "core/dom/StaticNodeList.h"
#include "core/dom/StyleEngine.h"
#include "core/dom/Text.h"
#include "core/dom/TouchList.h"
#include "core/dom/custom/CustomElementMicrotaskRunQueue.h"
#include "core/dom/custom/CustomElementRegistrationContext.h"
#include "core/dom/shadow/ElementShadow.h"
#include "core/dom/shadow/ShadowRoot.h"
#include "core/editing/Editor.h"
#include "core/editing/FrameSelection.h"
#include "core/editing/SpellChecker.h"
#include "core/editing/markup.h"
#include "core/events/BeforeUnloadEvent.h"
#include "core/events/Event.h"
#include "core/events/EventFactory.h"
#include "core/events/EventListener.h"
#include "core/events/HashChangeEvent.h"
#include "core/events/PageTransitionEvent.h"
#include "core/events/ScopedEventQueue.h"
#include "core/fetch/ResourceFetcher.h"
#include "core/frame/EventHandlerRegistry.h"
#include "core/frame/FrameConsole.h"
#include "core/frame/FrameHost.h"
#include "core/frame/FrameView.h"
#include "core/frame/History.h"
#include "core/frame/LocalDOMWindow.h"
#include "core/frame/LocalFrame.h"
#include "core/frame/Settings.h"
#include "core/html/HTMLAnchorElement.h"
#include "core/html/HTMLCanvasElement.h"
#include "core/html/HTMLDocument.h"
#include "core/html/HTMLLinkElement.h"
#include "core/html/HTMLMetaElement.h"
#include "core/html/HTMLScriptElement.h"
#include "core/html/HTMLStyleElement.h"
#include "core/html/HTMLTemplateElement.h"
#include "core/html/HTMLTitleElement.h"
#include "core/html/canvas/CanvasRenderingContext.h"
#include "core/html/canvas/CanvasRenderingContext2D.h"
#include "core/html/canvas/WebGLRenderingContext.h"
#include "core/html/imports/HTMLImportChild.h"
#include "core/html/imports/HTMLImportTreeRoot.h"
#include "core/html/imports/HTMLImportLoader.h"
#include "core/html/imports/HTMLImportsController.h"
#include "core/html/parser/HTMLDocumentParser.h"
#include "core/html/parser/HTMLParserIdioms.h"
#include "core/html/parser/NestingLevelIncrementer.h"
#include "core/html/parser/TextResourceDecoder.h"
#include "core/inspector/ConsoleMessage.h"
#include "core/inspector/InspectorCounters.h"
#include "core/inspector/InspectorTraceEvents.h"
#include "core/inspector/ScriptCallStack.h"
#include "core/loader/FrameLoaderClient.h"
#include "core/loader/ImageLoader.h"
#include "core/page/Chrome.h"
#include "core/page/ChromeClient.h"
#include "core/page/EventHandler.h"
#include "core/page/EventWithHitTestResults.h"
#include "core/page/FocusController.h"
#include "core/page/Page.h"
#include "core/page/scrolling/ScrollingCoordinator.h"
#include "core/rendering/HitTestResult.h"
#include "core/rendering/RenderView.h"
#include "core/rendering/RenderWidget.h"
#include "core/rendering/compositing/RenderLayerCompositor.h"
#include "platform/DateComponents.h"
#include "platform/EventDispatchForbiddenScope.h"
#include "platform/Language.h"
#include "platform/Logging.h"
#include "platform/RuntimeEnabledFeatures.h"
#include "platform/ScriptForbiddenScope.h"
#include "platform/TraceEvent.h"
#include "platform/network/HTTPParsers.h"
#include "platform/scroll/Scrollbar.h"
#include "platform/text/PlatformLocale.h"
#include "platform/text/SegmentedString.h"
#include "platform/weborigin/SchemeRegistry.h"
#include "public/platform/Platform.h"
#include "wtf/CurrentTime.h"
#include "wtf/DateMath.h"
#include "wtf/HashFunctions.h"
#include "wtf/MainThread.h"
#include "wtf/StdLibExtras.h"
#include "wtf/TemporaryChange.h"
#include "wtf/text/StringBuffer.h"

using namespace WTF;
using namespace Unicode;

namespace blink {

// DOM Level 2 says (letters added):
//
// a) Name start characters must have one of the categories Ll, Lu, Lo, Lt, Nl.
// b) Name characters other than Name-start characters must have one of the categories Mc, Me, Mn, Lm, or Nd.
// c) Characters in the compatibility area (i.e. with character code greater than #xF900 and less than #xFFFE) are not allowed in XML names.
// d) Characters which have a font or compatibility decomposition (i.e. those with a "compatibility formatting tag" in field 5 of the database -- marked by field 5 beginning with a "<") are not allowed.
// e) The following characters are treated as name-start characters rather than name characters, because the property file classifies them as Alphabetic: [#x02BB-#x02C1], #x0559, #x06E5, #x06E6.
// f) Characters #x20DD-#x20E0 are excluded (in accordance with Unicode, section 5.14).
// g) Character #x00B7 is classified as an extender, because the property list so identifies it.
// h) Character #x0387 is added as a name character, because #x00B7 is its canonical equivalent.
// i) Characters ':' and '_' are allowed as name-start characters.
// j) Characters '-' and '.' are allowed as name characters.
//
// It also contains complete tables. If we decide it's better, we could include those instead of the following code.

static inline bool isValidNameStart(UChar32 c)
{
    // rule (e) above
    if ((c >= 0x02BB && c <= 0x02C1) || c == 0x559 || c == 0x6E5 || c == 0x6E6)
        return true;

    // rule (i) above
    if (c == ':' || c == '_')
        return true;

    // rules (a) and (f) above
    const uint32_t nameStartMask = Letter_Lowercase | Letter_Uppercase | Letter_Other | Letter_Titlecase | Number_Letter;
    if (!(Unicode::category(c) & nameStartMask))
        return false;

    // rule (c) above
    if (c >= 0xF900 && c < 0xFFFE)
        return false;

    // rule (d) above
    DecompositionType decompType = decompositionType(c);
    if (decompType == DecompositionFont || decompType == DecompositionCompat)
        return false;

    return true;
}

static inline bool isValidNamePart(UChar32 c)
{
    // rules (a), (e), and (i) above
    if (isValidNameStart(c))
        return true;

    // rules (g) and (h) above
    if (c == 0x00B7 || c == 0x0387)
        return true;

    // rule (j) above
    if (c == '-' || c == '.')
        return true;

    // rules (b) and (f) above
    const uint32_t otherNamePartMask = Mark_NonSpacing | Mark_Enclosing | Mark_SpacingCombining | Letter_Modifier | Number_DecimalDigit;
    if (!(Unicode::category(c) & otherNamePartMask))
        return false;

    // rule (c) above
    if (c >= 0xF900 && c < 0xFFFE)
        return false;

    // rule (d) above
    DecompositionType decompType = decompositionType(c);
    if (decompType == DecompositionFont || decompType == DecompositionCompat)
        return false;

    return true;
}

static Widget* widgetForElement(const Element& focusedElement)
{
    RenderObject* renderer = focusedElement.renderer();
    if (!renderer || !renderer->isWidget())
        return 0;
    return toRenderWidget(renderer)->widget();
}

static bool acceptsEditingFocus(const Element& element)
{
    ASSERT(element.hasEditableStyle());

    return element.document().frame() && element.rootEditableElement();
}

#ifndef NDEBUG
typedef WillBeHeapHashSet<RawPtrWillBeWeakMember<Document> > WeakDocumentSet;
static WeakDocumentSet& liveDocumentSet()
{
    DEFINE_STATIC_LOCAL(OwnPtrWillBePersistent<WeakDocumentSet>, set, (adoptPtrWillBeNoop(new WeakDocumentSet())));
    return *set;
}
#endif

DocumentVisibilityObserver::DocumentVisibilityObserver(Document& document)
    : m_document(nullptr)
{
    registerObserver(document);
}

DocumentVisibilityObserver::~DocumentVisibilityObserver()
{
#if !ENABLE(OILPAN)
    unregisterObserver();
#endif
}

void DocumentVisibilityObserver::trace(Visitor* visitor)
{
    visitor->trace(m_document);
}

void DocumentVisibilityObserver::unregisterObserver()
{
    if (m_document) {
        m_document->unregisterVisibilityObserver(this);
        m_document = nullptr;
    }
}

void DocumentVisibilityObserver::registerObserver(Document& document)
{
    ASSERT(!m_document);
    m_document = &document;
    if (m_document)
        m_document->registerVisibilityObserver(this);
}

void DocumentVisibilityObserver::setObservedDocument(Document& document)
{
    unregisterObserver();
    registerObserver(document);
}

Document::Document(const DocumentInit& initializer, DocumentClassFlags documentClasses)
    : ContainerNode(0, CreateDocument)
    , TreeScope(*this)
    , m_hasNodesWithPlaceholderStyle(false)
    , m_evaluateMediaQueriesOnStyleRecalc(false)
    , m_pendingSheetLayout(NoLayoutWithPendingSheets)
    , m_frame(initializer.frame())
    , m_domWindow(m_frame ? m_frame->domWindow() : 0)
    , m_importsController(initializer.importsController())
    , m_activeParserCount(0)
    , m_executeScriptsWaitingForResourcesTimer(this, &Document::executeScriptsWaitingForResourcesTimerFired)
    , m_hasAutofocused(false)
    , m_clearFocusedElementTimer(this, &Document::clearFocusedElementTimerFired)
    , m_focusAutofocusElementTimer(this, &Document::focusAutofocusElementTimerFired)
    , m_listenerTypes(0)
    , m_mutationObserverTypes(0)
    , m_readyState(Complete)
    , m_isParsing(false)
    , m_containsValidityStyleRules(false)
    , m_markers(adoptPtrWillBeNoop(new DocumentMarkerController))
    , m_loadEventProgress(LoadEventNotRun)
    , m_startTime(currentTime())
    , m_documentClasses(documentClasses)
    , m_renderView(0)
#if !ENABLE(OILPAN)
    , m_weakFactory(this)
#endif
    , m_contextDocument(initializer.contextDocument())
    , m_loadEventDelayCount(0)
    , m_loadEventDelayTimer(this, &Document::loadEventDelayTimerFired)
    , m_didSetReferrerPolicy(false)
    , m_referrerPolicy(ReferrerPolicyDefault)
    , m_directionSetOnDocumentElement(false)
    , m_writingModeSetOnDocumentElement(false)
    , m_registrationContext(initializer.registrationContext(this))
    , m_elementDataCacheClearTimer(this, &Document::elementDataCacheClearTimerFired)
    , m_timeline(AnimationTimeline::create(this))
    , m_templateDocumentHost(nullptr)
    , m_hasViewportUnits(false)
    , m_styleRecalcElementCounter(0)
{
    setClient(this);
    ScriptWrappable::init(this);

    m_fetcher = ResourceFetcher::create(this);

    // We depend on the url getting immediately set in subframes, but we
    // also depend on the url NOT getting immediately set in opened windows.
    // See fast/dom/early-frame-url.html
    // and fast/dom/location-new-window-no-crash.html, respectively.
    // FIXME: Can/should we unify this behavior?
    if (initializer.shouldSetURL())
        setURL(initializer.url());

    InspectorCounters::incrementCounter(InspectorCounters::DocumentCounter);

    m_lifecycle.advanceTo(DocumentLifecycle::Inactive);

    // Since CSSFontSelector requires Document::m_fetcher and StyleEngine owns
    // CSSFontSelector, need to initialize m_styleEngine after initializing
    // m_fetcher.
    m_styleEngine = StyleEngine::create(*this);

#ifndef NDEBUG
    liveDocumentSet().add(this);
#endif
}

Document::~Document()
{
    ASSERT(!renderView());
    ASSERT(!parentTreeScope());
#if !ENABLE(OILPAN)
    ASSERT(m_ranges.isEmpty());
    ASSERT(!hasGuardRefCount());
    // With Oilpan, either the document outlives the visibility observers
    // or the visibility observers and the document die in the same GC round.
    // When they die in the same GC round, the list of visibility observers
    // will not be empty on Document destruction.
    ASSERT(m_visibilityObservers.isEmpty());

    if (m_templateDocument)
        m_templateDocument->m_templateDocumentHost = nullptr; // balanced in ensureTemplateDocument().

    // FIXME: Oilpan: Not removing event listeners here also means that we do
    // not notify the inspector instrumentation that the event listeners are
    // gone. The Document and all the nodes in the document are gone, so maybe
    // that is OK?
    removeAllEventListenersRecursively();

    // Currently we believe that Document can never outlive the parser.
    // Although the Document may be replaced synchronously, DocumentParsers
    // generally keep at least one reference to an Element which would in turn
    // has a reference to the Document.  If you hit this ASSERT, then that
    // assumption is wrong.  DocumentParser::detach() should ensure that even
    // if the DocumentParser outlives the Document it won't cause badness.
    ASSERT(!m_parser || m_parser->refCount() == 1);
    detachParser();
#endif

#if !ENABLE(OILPAN)
    if (m_styleSheetList)
        m_styleSheetList->detachFromDocument();

    if (m_importsController)
        HTMLImportsController::removeFrom(*this);

    m_timeline->detachFromDocument();

    // We need to destroy CSSFontSelector before destroying m_fetcher.
    if (m_styleEngine)
        m_styleEngine->detachFromDocument();

    if (m_elemSheet)
        m_elemSheet->clearOwnerNode();

    m_fetcher.clear();

    // We must call clearRareData() here since a Document class inherits TreeScope
    // as well as Node. See a comment on TreeScope.h for the reason.
    if (hasRareData())
        clearRareData();

#ifndef NDEBUG
    liveDocumentSet().remove(this);
#endif
#endif

    setClient(0);

    InspectorCounters::decrementCounter(InspectorCounters::DocumentCounter);
}

#if !ENABLE(OILPAN)
void Document::dispose()
{
    ASSERT_WITH_SECURITY_IMPLICATION(!m_deletionHasBegun);

    // We must make sure not to be retaining any of our children through
    // these extra pointers or we will create a reference cycle.
    m_focusedElement = nullptr;
    m_hoverNode = nullptr;
    m_activeHoverElement = nullptr;
    m_titleElement = nullptr;
    m_documentElement = nullptr;
    m_userActionElements.documentDidRemoveLastRef();

    detachParser();

    m_registrationContext.clear();

    if (m_importsController)
        HTMLImportsController::removeFrom(*this);

    // removeDetachedChildren() doesn't always unregister IDs,
    // so tear down scope information upfront to avoid having stale references in the map.
    destroyTreeScopeData();

    removeDetachedChildren();

    m_markers->clear();

    m_cssCanvasElements.clear();

    // FIXME: consider using ActiveDOMObject.
    if (m_scriptedAnimationController)
        m_scriptedAnimationController->clearDocumentPointer();
    m_scriptedAnimationController.clear();

    m_lifecycle.advanceTo(DocumentLifecycle::Disposed);
    lifecycleNotifier().notifyDocumentWasDisposed();
}
#endif

SelectorQueryCache& Document::selectorQueryCache()
{
    if (!m_selectorQueryCache)
        m_selectorQueryCache = adoptPtr(new SelectorQueryCache());
    return *m_selectorQueryCache;
}

MediaQueryMatcher& Document::mediaQueryMatcher()
{
    if (!m_mediaQueryMatcher)
        m_mediaQueryMatcher = MediaQueryMatcher::create(*this);
    return *m_mediaQueryMatcher;
}

void Document::mediaQueryAffectingValueChanged()
{
    m_evaluateMediaQueriesOnStyleRecalc = true;
    styleEngine()->clearMediaQueryRuleSetStyleSheets();
}

DOMImplementation& Document::implementation()
{
    if (!m_implementation)
        m_implementation = DOMImplementation::create(*this);
    return *m_implementation;
}

Location* Document::location() const
{
    if (!frame())
        return 0;

    return &domWindow()->location();
}

void Document::childrenChanged(const ChildrenChange& change)
{
    ContainerNode::childrenChanged(change);
    m_documentElement = ElementTraversal::firstWithin(*this);
}

PassRefPtrWillBeRawPtr<Element> Document::createElement(const AtomicString& name, ExceptionState& exceptionState)
{
    if (!isValidName(name)) {
        exceptionState.throwDOMException(InvalidCharacterError, "The tag name provided ('" + name + "') is not a valid name.");
        return nullptr;
    }
    if (isHTMLDocument())
        return HTMLElementFactory::createHTMLElement(name, *this, false);

    return Element::create(QualifiedName(name), this);
}

PassRefPtrWillBeRawPtr<Element> Document::createElement(const AtomicString& localName, const AtomicString& typeExtension, ExceptionState& exceptionState)
{
    if (!isValidName(localName)) {
        exceptionState.throwDOMException(InvalidCharacterError, "The tag name provided ('" + localName + "') is not a valid name.");
        return nullptr;
    }

    RefPtrWillBeRawPtr<Element> element;

    if (CustomElement::isValidName(localName) && registrationContext()) {
        element = registrationContext()->createCustomTagElement(*this, QualifiedName(localName));
    } else {
        element = createElement(localName, exceptionState);
        if (exceptionState.hadException())
            return nullptr;
    }

    if (!typeExtension.isEmpty())
        CustomElementRegistrationContext::setIsAttributeAndTypeExtension(element.get(), typeExtension);

    return element.release();
}

ScriptValue Document::registerElement(ScriptState* scriptState, const AtomicString& name, ExceptionState& exceptionState)
{
    return registerElement(scriptState, name, Dictionary(), exceptionState);
}

ScriptValue Document::registerElement(ScriptState* scriptState, const AtomicString& name, const Dictionary& options, ExceptionState& exceptionState, CustomElement::NameSet validNames)
{
    if (!registrationContext()) {
        exceptionState.throwDOMException(NotSupportedError, "No element registration context is available.");
        return ScriptValue();
    }

    CustomElementConstructorBuilder constructorBuilder(scriptState, &options);
    registrationContext()->registerElement(this, &constructorBuilder, name, validNames, exceptionState);
    return constructorBuilder.bindingsReturnValue();
}

CustomElementMicrotaskRunQueue* Document::customElementMicrotaskRunQueue()
{
    if (!m_customElementMicrotaskRunQueue)
        m_customElementMicrotaskRunQueue = CustomElementMicrotaskRunQueue::create();
    return m_customElementMicrotaskRunQueue.get();
}

void Document::setImportsController(HTMLImportsController* controller)
{
    ASSERT(!m_importsController || !controller);
    m_importsController = controller;
}

HTMLImportLoader* Document::importLoader() const
{
    if (!m_importsController)
        return 0;
    return m_importsController->loaderFor(*this);
}

HTMLImport* Document::import() const
{
    if (!m_importsController)
        return 0;
    if (HTMLImportLoader* loader = importLoader())
        return loader->firstImport();
    return m_importsController->root();
}

bool Document::haveImportsLoaded() const
{
    if (!m_importsController)
        return true;
    return !m_importsController->shouldBlockScriptExecution(*this);
}

LocalDOMWindow* Document::executingWindow()
{
    if (LocalDOMWindow* owningWindow = domWindow())
        return owningWindow;
    if (HTMLImportsController* import = this->importsController())
        return import->master()->domWindow();
    return 0;
}

LocalFrame* Document::executingFrame()
{
    LocalDOMWindow* window = executingWindow();
    if (!window)
        return 0;
    return window->frame();
}

PassRefPtrWillBeRawPtr<DocumentFragment> Document::createDocumentFragment()
{
    return DocumentFragment::create(*this);
}

PassRefPtrWillBeRawPtr<Text> Document::createTextNode(const String& data)
{
    return Text::create(*this, data);
}

PassRefPtrWillBeRawPtr<Text> Document::createEditingTextNode(const String& text)
{
    return Text::createEditingText(*this, text);
}

bool Document::importContainerNodeChildren(ContainerNode* oldContainerNode, PassRefPtrWillBeRawPtr<ContainerNode> newContainerNode, ExceptionState& exceptionState)
{
    for (Node* oldChild = oldContainerNode->firstChild(); oldChild; oldChild = oldChild->nextSibling()) {
        RefPtrWillBeRawPtr<Node> newChild = importNode(oldChild, true, exceptionState);
        if (exceptionState.hadException())
            return false;
        newContainerNode->appendChild(newChild.release(), exceptionState);
        if (exceptionState.hadException())
            return false;
    }

    return true;
}

PassRefPtrWillBeRawPtr<Node> Document::importNode(Node* importedNode, bool deep, ExceptionState& exceptionState)
{
    switch (importedNode->nodeType()) {
    case TEXT_NODE:
        return createTextNode(importedNode->nodeValue());
    case ELEMENT_NODE: {
        Element* oldElement = toElement(importedNode);
        RefPtrWillBeRawPtr<Element> newElement = createElement(oldElement->tagQName(), false);

        newElement->cloneDataFromElement(*oldElement);

        if (deep) {
            if (!importContainerNodeChildren(oldElement, newElement, exceptionState))
                return nullptr;
            if (isHTMLTemplateElement(*oldElement)
                && !importContainerNodeChildren(toHTMLTemplateElement(oldElement)->content(), toHTMLTemplateElement(newElement)->content(), exceptionState))
                return nullptr;
        }

        return newElement.release();
    }
    case ATTRIBUTE_NODE:
        exceptionState.throwDOMException(NotSupportedError, "Cannot clone an Attr.");
        return nullptr;
    case DOCUMENT_FRAGMENT_NODE: {
        if (importedNode->isShadowRoot()) {
            // ShadowRoot nodes should not be explicitly importable.
            // Either they are imported along with their host node, or created implicitly.
            exceptionState.throwDOMException(NotSupportedError, "The node provided is a shadow root, which may not be imported.");
            return nullptr;
        }
        DocumentFragment* oldFragment = toDocumentFragment(importedNode);
        RefPtrWillBeRawPtr<DocumentFragment> newFragment = createDocumentFragment();
        if (deep && !importContainerNodeChildren(oldFragment, newFragment, exceptionState))
            return nullptr;

        return newFragment.release();
    }
    case DOCUMENT_NODE:
        exceptionState.throwDOMException(NotSupportedError, "The node provided is a document, which may not be imported.");
        return nullptr;
    }

    ASSERT_NOT_REACHED();
    return nullptr;
}

PassRefPtrWillBeRawPtr<Node> Document::adoptNode(PassRefPtrWillBeRawPtr<Node> source, ExceptionState& exceptionState)
{
    EventQueueScope scope;

    switch (source->nodeType()) {
    case DOCUMENT_NODE:
        exceptionState.throwDOMException(NotSupportedError, "The node provided is of type '" + source->nodeName() + "', which may not be adopted.");
        return nullptr;
    case ATTRIBUTE_NODE: {
        exceptionState.throwDOMException(NotSupportedError, "Cannot adopt Attr.");
        break;
    }
    default:
        if (source->isShadowRoot()) {
            // ShadowRoot cannot disconnect itself from the host node.
            exceptionState.throwDOMException(HierarchyRequestError, "The node provided is a shadow root, which may not be adopted.");
            return nullptr;
        }

        if (source->parentNode()) {
            source->parentNode()->removeChild(source.get(), exceptionState);
            if (exceptionState.hadException())
                return nullptr;
        }
    }

    this->adoptIfNeeded(*source);

    return source;
}

// FIXME: This should really be in a possible ElementFactory class
PassRefPtrWillBeRawPtr<Element> Document::createElement(const QualifiedName& qName, bool createdByParser)
{
    // FIXME(sky): This should only take a local name.
    return HTMLElementFactory::createHTMLElement(qName.localName(), *this, createdByParser);
}

String Document::readyState() const
{
    DEFINE_STATIC_LOCAL(const String, loading, ("loading"));
    DEFINE_STATIC_LOCAL(const String, interactive, ("interactive"));
    DEFINE_STATIC_LOCAL(const String, complete, ("complete"));

    switch (m_readyState) {
    case Loading:
        return loading;
    case Interactive:
        return interactive;
    case Complete:
        return complete;
    }

    ASSERT_NOT_REACHED();
    return String();
}

void Document::setReadyState(ReadyState readyState)
{
    if (readyState == m_readyState)
        return;
    m_readyState = readyState;
    dispatchEvent(Event::create(EventTypeNames::readystatechange));
}

bool Document::isLoadCompleted()
{
    return m_readyState == Complete;
}

AtomicString Document::encodingName() const
{
    // TextEncoding::name() returns a char*, no need to allocate a new
    // String for it each time.
    // FIXME: We should fix TextEncoding to speak AtomicString anyway.
    return AtomicString(encoding().name());
}

void Document::setContentLanguage(const AtomicString& language)
{
    if (m_contentLanguage == language)
        return;
    m_contentLanguage = language;

    // Document's style depends on the content language.
    setNeedsStyleRecalc(SubtreeStyleChange);
}

KURL Document::baseURI() const
{
    return m_baseURL;
}

AtomicString Document::contentType() const
{
    return AtomicString("text/html");
}

Element* Document::elementFromPoint(int x, int y) const
{
    if (!renderView())
        return 0;

    return TreeScope::elementFromPoint(x, y);
}

PassRefPtrWillBeRawPtr<Range> Document::caretRangeFromPoint(int x, int y)
{
    if (!renderView())
        return nullptr;
    HitTestResult result = hitTestInDocument(this, x, y);
    RenderObject* renderer = result.renderer();
    if (!renderer)
        return nullptr;

    Node* node = renderer->node();
    Node* shadowAncestorNode = ancestorInThisScope(node);
    if (shadowAncestorNode != node) {
        unsigned offset = shadowAncestorNode->nodeIndex();
        ContainerNode* container = shadowAncestorNode->parentNode();
        return Range::create(*this, container, offset, container, offset);
    }

    PositionWithAffinity positionWithAffinity = result.position();
    if (positionWithAffinity.position().isNull())
        return nullptr;

    Position rangeCompliantPosition = positionWithAffinity.position().parentAnchoredEquivalent();
    return Range::create(*this, rangeCompliantPosition, rangeCompliantPosition);
}

/*
 * Performs three operations:
 *  1. Convert control characters to spaces
 *  2. Trim leading and trailing spaces
 *  3. Collapse internal whitespace.
 */
template <typename CharacterType>
static inline String canonicalizedTitle(Document* document, const String& title)
{
    const CharacterType* characters = title.getCharacters<CharacterType>();
    unsigned length = title.length();
    unsigned i;

    StringBuffer<CharacterType> buffer(length);
    unsigned builderIndex = 0;

    // Skip leading spaces and leading characters that would convert to spaces
    for (i = 0; i < length; ++i) {
        CharacterType c = characters[i];
        if (!(c <= 0x20 || c == 0x7F))
            break;
    }

    if (i == length)
        return String();

    // Replace control characters with spaces, and backslashes with currency symbols, and collapse whitespace.
    bool previousCharWasWS = false;
    for (; i < length; ++i) {
        CharacterType c = characters[i];
        if (c <= 0x20 || c == 0x7F || (WTF::Unicode::category(c) & (WTF::Unicode::Separator_Line | WTF::Unicode::Separator_Paragraph))) {
            if (previousCharWasWS)
                continue;
            buffer[builderIndex++] = ' ';
            previousCharWasWS = true;
        } else {
            buffer[builderIndex++] = c;
            previousCharWasWS = false;
        }
    }

    // Strip trailing spaces
    while (builderIndex > 0) {
        --builderIndex;
        if (buffer[builderIndex] != ' ')
            break;
    }

    if (!builderIndex && buffer[builderIndex] == ' ')
        return String();

    buffer.shrink(builderIndex + 1);

    return String::adopt(buffer);
}

void Document::updateTitle(const String& title)
{
    if (m_rawTitle == title)
        return;

    m_rawTitle = title;

    String oldTitle = m_title;
    if (m_rawTitle.isEmpty())
        m_title = String();
    else if (m_rawTitle.is8Bit())
        m_title = canonicalizedTitle<LChar>(this, m_rawTitle);
    else
        m_title = canonicalizedTitle<UChar>(this, m_rawTitle);

    if (!m_frame || oldTitle == m_title)
        return;
    m_frame->loaderClient()->dispatchDidReceiveTitle(m_title);
}

void Document::setTitle(const String& title)
{
}

void Document::setTitleElement(Element* titleElement)
{
    // Only allow the first title element to change the title -- others have no effect.
    if (m_titleElement && m_titleElement != titleElement) {
        if (isHTMLDocument())
            m_titleElement = Traversal<HTMLTitleElement>::firstWithin(*this);
    } else {
        m_titleElement = titleElement;
    }

    if (isHTMLTitleElement(m_titleElement))
        updateTitle(toHTMLTitleElement(m_titleElement)->text());
}

void Document::removeTitle(Element* titleElement)
{
    if (m_titleElement != titleElement)
        return;

    m_titleElement = nullptr;

    // Update title based on first title element in the document, if one exists.
    if (isHTMLDocument()) {
        if (HTMLTitleElement* title = Traversal<HTMLTitleElement>::firstWithin(*this))
            setTitleElement(title);
    }

    if (!m_titleElement)
        updateTitle(String());
}

const AtomicString& Document::dir()
{
    return nullAtom;
}

void Document::setDir(const AtomicString& value)
{
}

PageVisibilityState Document::pageVisibilityState() const
{
    // The visibility of the document is inherited from the visibility of the
    // page. If there is no page associated with the document, we will assume
    // that the page is hidden, as specified by the spec:
    // http://dvcs.w3.org/hg/webperf/raw-file/tip/specs/PageVisibility/Overview.html#dom-document-hidden
    if (!m_frame || !m_frame->page())
        return PageVisibilityStateHidden;
    return m_frame->page()->visibilityState();
}

String Document::visibilityState() const
{
    return pageVisibilityStateString(pageVisibilityState());
}

bool Document::hidden() const
{
    return pageVisibilityState() != PageVisibilityStateVisible;
}

void Document::didChangeVisibilityState()
{
    dispatchEvent(Event::create(EventTypeNames::visibilitychange));
    // Also send out the deprecated version until it can be removed.
    dispatchEvent(Event::create(EventTypeNames::webkitvisibilitychange));

    PageVisibilityState state = pageVisibilityState();
    DocumentVisibilityObserverSet::const_iterator observerEnd = m_visibilityObservers.end();
    for (DocumentVisibilityObserverSet::const_iterator it = m_visibilityObservers.begin(); it != observerEnd; ++it)
        (*it)->didChangeVisibilityState(state);
}

void Document::registerVisibilityObserver(DocumentVisibilityObserver* observer)
{
    ASSERT(!m_visibilityObservers.contains(observer));
    m_visibilityObservers.add(observer);
}

void Document::unregisterVisibilityObserver(DocumentVisibilityObserver* observer)
{
    ASSERT(m_visibilityObservers.contains(observer));
    m_visibilityObservers.remove(observer);
}

String Document::nodeName() const
{
    return "#document";
}

Node::NodeType Document::nodeType() const
{
    return DOCUMENT_NODE;
}

void Document::setStateForNewFormElements(const Vector<String>& stateVector)
{
}

FrameView* Document::view() const
{
    return m_frame ? m_frame->view() : 0;
}

Page* Document::page() const
{
    return m_frame ? m_frame->page() : 0;
}

FrameHost* Document::frameHost() const
{
    return m_frame ? m_frame->host() : 0;
}

Settings* Document::settings() const
{
    return m_frame ? m_frame->settings() : 0;
}

PassRefPtrWillBeRawPtr<Range> Document::createRange()
{
    return Range::create(*this);
}

bool Document::needsRenderTreeUpdate() const
{
    if (!isActive() || !view())
        return false;
    if (needsFullRenderTreeUpdate())
        return true;
    if (childNeedsStyleRecalc())
        return true;
    if (childNeedsStyleInvalidation())
        return true;
    return false;
}

bool Document::needsFullRenderTreeUpdate() const
{
    if (!isActive() || !view())
        return false;
    if (needsStyleRecalc())
        return true;
    if (needsStyleInvalidation())
        return true;
    // FIXME: The childNeedsDistributionRecalc bit means either self or children, we should fix that.
    if (childNeedsDistributionRecalc())
        return true;
    if (DocumentAnimations::needsOutdatedAnimationPlayerUpdate(*this))
        return true;
    return false;
}

bool Document::shouldScheduleRenderTreeUpdate() const
{
    if (!isActive())
        return false;
    if (inStyleRecalc())
        return false;
    // InPreLayout will recalc style itself. There's no reason to schedule another recalc.
    if (m_lifecycle.state() == DocumentLifecycle::InPreLayout)
        return false;
    if (!shouldScheduleLayout())
        return false;
    return true;
}

void Document::scheduleRenderTreeUpdate()
{
    ASSERT(!hasPendingStyleRecalc());
    ASSERT(shouldScheduleRenderTreeUpdate());
    ASSERT(needsRenderTreeUpdate());

    page()->animator().scheduleVisualUpdate();
    m_lifecycle.ensureStateAtMost(DocumentLifecycle::VisualUpdatePending);

    TRACE_EVENT_INSTANT1(TRACE_DISABLED_BY_DEFAULT("devtools.timeline"), "ScheduleStyleRecalculation", "frame", frame());
    TRACE_EVENT_INSTANT1(TRACE_DISABLED_BY_DEFAULT("devtools.timeline.stack"), "CallStack", "stack", InspectorCallStackEvent::currentCallStack());
}

bool Document::hasPendingForcedStyleRecalc() const
{
    return hasPendingStyleRecalc() && !inStyleRecalc() && styleChangeType() >= SubtreeStyleChange;
}

void Document::updateDistributionIfNeeded()
{
    ScriptForbiddenScope forbidScript;

    if (!childNeedsDistributionRecalc())
        return;
    TRACE_EVENT0("blink", "Document::updateDistributionIfNeeded");
    recalcDistribution();
}

void Document::updateStyleInvalidationIfNeeded()
{
    ScriptForbiddenScope forbidScript;

    if (!isActive())
        return;
    if (!childNeedsStyleInvalidation())
        return;
    TRACE_EVENT0("blink", "Document::updateStyleInvalidationIfNeeded");
    ASSERT(styleResolver());

    styleResolver()->ruleFeatureSet().styleInvalidator().invalidate(*this);
}

void Document::updateDistributionForNodeIfNeeded(Node* node)
{
    ScriptForbiddenScope forbidScript;

    if (node->inDocument()) {
        updateDistributionIfNeeded();
        return;
    }
    Node* root = node;
    while (Node* host = root->shadowHost())
        root = host;
    while (Node* ancestor = root->parentOrShadowHostNode())
        root = ancestor;
    if (root->childNeedsDistributionRecalc())
        root->recalcDistribution();
}

void Document::setupFontBuilder(RenderStyle* documentStyle)
{
    FontBuilder fontBuilder;
    fontBuilder.initForStyleResolve(*this, documentStyle);
    RefPtrWillBeRawPtr<CSSFontSelector> selector = m_styleEngine->fontSelector();
    fontBuilder.createFontForDocument(selector, documentStyle);
}

void Document::updateRenderTree(StyleRecalcChange change)
{
    ASSERT(isMainThread());

    ScriptForbiddenScope forbidScript;

    if (!view() || !isActive())
        return;

    if (change != Force && !needsRenderTreeUpdate())
        return;

    if (inStyleRecalc())
        return;

    // Entering here from inside layout or paint would be catastrophic since recalcStyle can
    // tear down the render tree or (unfortunately) run script. Kill the whole renderer if
    // someone managed to get into here from inside layout or paint.
    RELEASE_ASSERT(!view()->isInPerformLayout());
    RELEASE_ASSERT(!view()->isPainting());

    // Script can run below in WidgetUpdates, so protect the LocalFrame.
    // FIXME: Can this still happen? How does script run inside
    // UpdateSuspendScope::performDeferredWidgetTreeOperations() ?
    RefPtr<LocalFrame> protect(m_frame);

    TRACE_EVENT_BEGIN0("blink", "Document::updateRenderTree");
    TRACE_EVENT_SCOPED_SAMPLING_STATE("blink", "UpdateRenderTree");

    // FIXME: Remove m_styleRecalcElementCounter, we should just use the accessCount() on the resolver.
    m_styleRecalcElementCounter = 0;
    TRACE_EVENT_BEGIN1(TRACE_DISABLED_BY_DEFAULT("devtools.timeline"), "RecalculateStyles", "frame", frame());
    TRACE_EVENT_INSTANT1(TRACE_DISABLED_BY_DEFAULT("devtools.timeline.stack"), "CallStack", "stack", InspectorCallStackEvent::currentCallStack());

    DocumentAnimations::updateOutdatedAnimationPlayersIfNeeded(*this);
    evaluateMediaQueryListIfNeeded();
    updateDistributionIfNeeded();
    updateStyleInvalidationIfNeeded();

    // FIXME: We should update style on our ancestor chain before proceeding
    // however doing so currently causes several tests to crash, as LocalFrame::setDocument calls Document::attach
    // before setting the LocalDOMWindow on the LocalFrame, or the SecurityOrigin on the document. The attach, in turn
    // resolves style (here) and then when we resolve style on the parent chain, we may end up
    // re-attaching our containing iframe, which when asked HTMLFrameElementBase::isURLAllowed
    // hits a null-dereference due to security code always assuming the document has a SecurityOrigin.

    if (m_elemSheet && m_elemSheet->contents()->usesRemUnits())
        m_styleEngine->setUsesRemUnit(true);

    updateStyle(change);

    // As a result of the style recalculation, the currently hovered element might have been
    // detached (for example, by setting display:none in the :hover style), schedule another mouseMove event
    // to check if any other elements ended up under the mouse pointer due to re-layout.
    if (hoverNode() && !hoverNode()->renderer() && frame())
        frame()->eventHandler().dispatchFakeMouseMoveEventSoon();

    if (m_focusedElement && !m_focusedElement->isFocusable())
        clearFocusedElementSoon();

    ASSERT(!m_timeline->hasOutdatedAnimationPlayer());

    TRACE_EVENT_END1(TRACE_DISABLED_BY_DEFAULT("devtools.timeline"), "RecalculateStyles", "elementCount", m_styleRecalcElementCounter);
    TRACE_EVENT_END1("blink", "Document::updateRenderTree", "elementCount", m_styleRecalcElementCounter);
}

void Document::updateStyle(StyleRecalcChange change)
{
    TRACE_EVENT0("blink", "Document::updateStyle");

    m_lifecycle.advanceTo(DocumentLifecycle::InStyleRecalc);

    if (styleChangeType() >= SubtreeStyleChange)
        change = Force;

    // FIXME: Cannot access the ensureStyleResolver() before calling styleForDocument below because
    // apparently the StyleResolver's constructor has side effects. We should fix it.
    // See printing/setPrinting.html, printing/width-overflow.html though they only fail on
    // mac when accessing the resolver by what appears to be a viewport size difference.

    if (change == Force) {
        m_hasNodesWithPlaceholderStyle = false;
        RefPtr<RenderStyle> documentStyle = StyleResolver::styleForDocument(*this);
        StyleRecalcChange localChange = RenderStyle::stylePropagationDiff(documentStyle.get(), renderView()->style());
        if (localChange != NoChange)
            renderView()->setStyle(documentStyle.release());
    }

    clearNeedsStyleRecalc();

    // Uncomment to enable printing of statistics about style sharing and the matched property cache.
    // Optionally pass StyleResolver::ReportSlowStats to print numbers that require crawling the
    // entire DOM (where collecting them is very slow).
    // FIXME: Expose this as a runtime flag.
    // ensureStyleResolver().enableStats(/*StyleResolver::ReportSlowStats*/);

    if (StyleResolverStats* stats = ensureStyleResolver().stats())
        stats->reset();

    if (Element* documentElement = this->documentElement()) {
        if (documentElement->shouldCallRecalcStyle(change))
            documentElement->recalcStyle(change);
    }

    ensureStyleResolver().printStats();

    view()->recalcOverflowAfterStyleChange();

    clearChildNeedsStyleRecalc();

    if (m_styleEngine->hasResolver()) {
        // Pseudo element removal and similar may only work with these flags still set. Reset them after the style recalc.
        StyleResolver& resolver = m_styleEngine->ensureResolver();
        resolver.clearStyleSharingList();
    }

    ASSERT(!needsStyleRecalc());
    ASSERT(!childNeedsStyleRecalc());
    ASSERT(inStyleRecalc());
    m_lifecycle.advanceTo(DocumentLifecycle::StyleClean);
}

void Document::updateRenderTreeForNodeIfNeeded(Node* node)
{
    bool needsRecalc = needsFullRenderTreeUpdate();

    for (const Node* ancestor = node; ancestor && !needsRecalc; ancestor = NodeRenderingTraversal::parent(ancestor))
        needsRecalc = ancestor->needsStyleRecalc() || ancestor->needsStyleInvalidation();

    if (needsRecalc)
        updateRenderTreeIfNeeded();
}

void Document::updateLayout()
{
    ASSERT(isMainThread());

    ScriptForbiddenScope forbidScript;

    RefPtr<FrameView> frameView = view();
    if (frameView && frameView->isInPerformLayout()) {
        // View layout should not be re-entrant.
        ASSERT_NOT_REACHED();
        return;
    }

    updateRenderTreeIfNeeded();

    if (!isActive())
        return;

    if (frameView->needsLayout())
        frameView->layout();

    if (lifecycle().state() < DocumentLifecycle::LayoutClean)
        lifecycle().advanceTo(DocumentLifecycle::LayoutClean);
}

void Document::setNeedsFocusedElementCheck()
{
    setNeedsStyleRecalc(LocalStyleChange);
}

void Document::clearFocusedElementSoon()
{
    if (!m_clearFocusedElementTimer.isActive())
        m_clearFocusedElementTimer.startOneShot(0, FROM_HERE);
}

void Document::clearFocusedElementTimerFired(Timer<Document>*)
{
    updateRenderTreeIfNeeded();
    m_clearFocusedElementTimer.stop();

    if (m_focusedElement && !m_focusedElement->isFocusable())
        m_focusedElement->blur();
}

// FIXME: This is a bad idea and needs to be removed eventually.
// Other browsers load stylesheets before they continue parsing the web page.
// Since we don't, we can run JavaScript code that needs answers before the
// stylesheets are loaded. Doing a layout ignoring the pending stylesheets
// lets us get reasonable answers. The long term solution to this problem is
// to instead suspend JavaScript execution.
void Document::updateLayoutIgnorePendingStylesheets(Document::RunPostLayoutTasks runPostLayoutTasks)
{
    StyleEngine::IgnoringPendingStylesheet ignoring(m_styleEngine.get());
    updateLayout();
    if (runPostLayoutTasks == RunPostLayoutTasksSynchronously && view())
        view()->flushAnyPendingPostLayoutTasks();
}

PassRefPtr<RenderStyle> Document::styleForElementIgnoringPendingStylesheets(Element* element)
{
    ASSERT_ARG(element, element->document() == this);
    StyleEngine::IgnoringPendingStylesheet ignoring(m_styleEngine.get());
    return ensureStyleResolver().styleForElement(element, element->parentNode() ? element->parentNode()->computedStyle() : 0);
}

StyleResolver* Document::styleResolver() const
{
    return m_styleEngine->resolver();
}

StyleResolver& Document::ensureStyleResolver() const
{
    return m_styleEngine->ensureResolver();
}

void Document::clearStyleResolver()
{
    m_styleEngine->clearResolver();
}

void Document::attach(const AttachContext& context)
{
    ASSERT(m_lifecycle.state() == DocumentLifecycle::Inactive);

    m_renderView = new RenderView(this);
    setRenderer(m_renderView);

    m_renderView->setIsInWindow(true);
    m_renderView->setStyle(StyleResolver::styleForDocument(*this));
    m_renderView->compositor()->setNeedsCompositingUpdate(CompositingUpdateAfterCompositingInputChange);

    ContainerNode::attach(context);

    m_lifecycle.advanceTo(DocumentLifecycle::StyleClean);
}

void Document::detach(const AttachContext& context)
{
    ASSERT(isActive());
    m_lifecycle.advanceTo(DocumentLifecycle::Stopping);

    if (page())
        page()->documentDetached(this);

    stopActiveDOMObjects();

    // FIXME: consider using ActiveDOMObject.
    if (m_scriptedAnimationController)
        m_scriptedAnimationController->clearDocumentPointer();
    m_scriptedAnimationController.clear();

    // FIXME: This shouldn't be needed once LocalDOMWindow becomes ExecutionContext.
    if (m_domWindow)
        m_domWindow->clearEventQueue();

    if (m_renderView)
        m_renderView->setIsInWindow(false);

    m_hoverNode = nullptr;
    m_focusedElement = nullptr;
    m_activeHoverElement = nullptr;
    m_autofocusElement = nullptr;

    m_renderView = 0;
    ContainerNode::detach(context);

    m_styleEngine->didDetach();

    frameHost()->eventHandlerRegistry().documentDetached(*this);

    // This is required, as our LocalFrame might delete itself as soon as it detaches
    // us. However, this violates Node::detach() semantics, as it's never
    // possible to re-attach. Eventually Document::detach() should be renamed,
    // or this setting of the frame to 0 could be made explicit in each of the
    // callers of Document::detach().
    m_frame = 0;

    if (m_mediaQueryMatcher)
        m_mediaQueryMatcher->documentDetached();

    lifecycleNotifier().notifyDocumentWasDetached();
    m_lifecycle.advanceTo(DocumentLifecycle::Stopped);
#if ENABLE(OILPAN)
    // Done with the window, explicitly clear to hasten its
    // destruction.
    clearDOMWindow();
#endif
}

void Document::prepareForDestruction()
{
    m_markers->prepareForDestruction();

    // The process of disconnecting descendant frames could have already detached us.
    if (!isActive())
        return;

    if (LocalDOMWindow* window = this->domWindow())
        window->willDetachDocumentFromFrame();
    detach();
}

void Document::removeAllEventListeners()
{
    ContainerNode::removeAllEventListeners();

    if (LocalDOMWindow* domWindow = this->domWindow())
        domWindow->removeAllEventListeners();
}

PassRefPtrWillBeRawPtr<DocumentParser> Document::createParser()
{
    // FIXME(sky): Should we pass true for report errors like the inspector did?
    return HTMLDocumentParser::create(toHTMLDocument(*this), false);
}

ScriptableDocumentParser* Document::scriptableDocumentParser() const
{
    return parser() ? parser()->asScriptableDocumentParser() : 0;
}

void Document::detachParser()
{
    if (!m_parser)
        return;
    m_parser->detach();
    m_parser.clear();
}

void Document::cancelParsing()
{
    if (!m_parser)
        return;

    // We have to clear the parser to avoid possibly triggering
    // the onload handler when closing as a side effect of a cancel-style
    // change, such as opening a new document or closing the window while
    // still parsing.
    detachParser();

    // FIXME(sky): Unclear if anything below this makes any sense.
    if (!m_frame) {
        m_loadEventProgress = LoadEventTried;
        return;
    }
    checkCompleted();
}

PassRefPtrWillBeRawPtr<DocumentParser> Document::startParsing()
{
    ASSERT(!m_parser);
    ASSERT(!m_isParsing);
    ASSERT(!firstChild());
    ASSERT(!m_focusedElement);

    m_parser = createParser();
    setParsing(true);
    setReadyState(Loading);
    return m_parser;
}

Element* Document::viewportDefiningElement(RenderStyle* rootStyle) const
{
    // If a BODY element sets non-visible overflow, it is to be propagated to the viewport, as long
    // as the following conditions are all met:
    // (1) The root element is HTML.
    // (2) It is the primary BODY element (we only assert for this, expecting callers to behave).
    // (3) The root element has visible overflow.
    // Otherwise it's the root element's properties that are to be propagated.
    Element* rootElement = documentElement();
    if (!rootElement)
        return 0;
    if (!rootStyle) {
        rootStyle = rootElement->renderStyle();
        if (!rootStyle)
            return 0;
    }
    return rootElement;
}

void Document::implicitClose()
{
    ASSERT(!inStyleRecalc());

    bool doload = !parsing() && m_parser && !processingLoadEvent();

    // If the load was blocked because of a pending location change and the location change triggers a same document
    // navigation, don't fire load events after the same document navigation completes (unless there's an explicit open).
    m_loadEventProgress = LoadEventTried;

    if (!doload)
        return;

    // The call to dispatchWindowLoadEvent can detach the LocalDOMWindow and cause it (and its
    // attached Document) to be destroyed.
    RefPtrWillBeRawPtr<LocalDOMWindow> protectedWindow(this->domWindow());

    m_loadEventProgress = LoadEventInProgress;

    // We have to clear the parser, in case someone document.write()s from the
    // onLoad event handler, as in Radar 3206524.
    detachParser();

    if (frame()) {
        ImageLoader::dispatchPendingLoadEvents();
        ImageLoader::dispatchPendingErrorEvents();
        HTMLLinkElement::dispatchPendingLoadEvents();
    }

    // JS running below could remove the frame or destroy the RenderView so we call
    // those two functions repeatedly and don't save them on the stack.

    if (protectedWindow)
        protectedWindow->documentWasClosed();

    if (frame())
        frame()->loaderClient()->dispatchDidHandleOnloadEvents();

    if (!frame()) {
        m_loadEventProgress = LoadEventCompleted;
        return;
    }

    // FIXME(sky): Could start frame if they are still paused here.
    m_loadEventProgress = LoadEventCompleted;
}

void Document::checkCompleted()
{
    if (isLoadCompleted())
        return;

    // Are we still parsing?
    if (parsing())
        return;

    // Still waiting imports?
    if (!haveImportsLoaded())
        return;

    // Still waiting for images/scripts?
    if (fetcher()->requestCount())
        return;

    // Still waiting for elements that don't go through a FrameLoader?
    if (isDelayingLoadEvent())
        return;

    // OK, completed.
    setReadyState(Complete);
    if (loadEventStillNeeded())
        implicitClose();
}

void Document::dispatchUnloadEvents()
{
    RefPtrWillBeRawPtr<Document> protect(this);
    if (m_parser)
        m_parser->stopParsing();

    if (m_loadEventProgress >= LoadEventTried && m_loadEventProgress <= UnloadEventInProgress) {
        if (m_loadEventProgress < PageHideInProgress) {
            m_loadEventProgress = PageHideInProgress;
            if (LocalDOMWindow* window = domWindow())
                window->dispatchEvent(PageTransitionEvent::create(EventTypeNames::pagehide, false), this);
            if (!m_frame)
                return;

            m_loadEventProgress = UnloadEventInProgress;
            RefPtrWillBeRawPtr<Event> unloadEvent(Event::create(EventTypeNames::unload));
            m_frame->domWindow()->dispatchEvent(unloadEvent, this);
        }
        m_loadEventProgress = UnloadEventHandled;
    }

    if (!m_frame)
        return;

    removeAllEventListenersRecursively();
}

Document::PageDismissalType Document::pageDismissalEventBeingDispatched() const
{
    if (m_loadEventProgress == BeforeUnloadEventInProgress)
        return BeforeUnloadDismissal;
    if (m_loadEventProgress == PageHideInProgress)
        return PageHideDismissal;
    if (m_loadEventProgress == UnloadEventInProgress)
        return UnloadDismissal;
    return NoDismissal;
}

void Document::setParsing(bool b)
{
    m_isParsing = b;

    if (m_isParsing && !m_elementDataCache)
        m_elementDataCache = ElementDataCache::create();
}

bool Document::shouldScheduleLayout() const
{
    // This function will only be called when FrameView thinks a layout is needed.
    // This enforces a couple extra rules.
    //
    //    (a) Only schedule a layout once the stylesheets are loaded.
    //    (b) Only schedule layout once we have a body element.
    if (!isActive())
        return false;

    if (isRenderingReady())
        return true;

    return false;
}

int Document::elapsedTime() const
{
    return static_cast<int>((currentTime() - m_startTime) * 1000);
}

const KURL& Document::virtualURL() const
{
    return m_url;
}

KURL Document::virtualCompleteURL(const String& url) const
{
    return completeURL(url);
}

double Document::timerAlignmentInterval() const
{
    Page* p = page();
    if (!p)
        return DOMTimer::visiblePageAlignmentInterval();
    return p->timerAlignmentInterval();
}

EventTarget* Document::errorEventTarget()
{
    return domWindow();
}

void Document::logExceptionToConsole(const String& errorMessage, int scriptId, const String& sourceURL, int lineNumber, int columnNumber, PassRefPtrWillBeRawPtr<ScriptCallStack> callStack)
{
    RefPtrWillBeRawPtr<ConsoleMessage> consoleMessage = ConsoleMessage::create(JSMessageSource, ErrorMessageLevel, errorMessage, sourceURL, lineNumber);
    consoleMessage->setScriptId(scriptId);
    consoleMessage->setCallStack(callStack);
    addMessage(consoleMessage.release());
}

void Document::setURL(const KURL& url)
{
    const KURL& newURL = url.isEmpty() ? blankURL() : url;
    if (newURL == m_url)
        return;

    m_url = newURL;
    updateBaseURL();
}

void Document::updateBaseURL()
{
    KURL oldBaseURL = m_baseURL;
    m_baseURL = m_url;

    if (!m_baseURL.isValid())
        m_baseURL = KURL();

    // FIXME(sky): remove?
    if (m_elemSheet) {
        // Element sheet is silly. It never contains anything.
        ASSERT(!m_elemSheet->contents()->ruleCount());
        bool usesRemUnits = m_elemSheet->contents()->usesRemUnits();
        m_elemSheet = CSSStyleSheet::createInline(this, m_baseURL);
        // FIXME: So we are not really the parser. The right fix is to eliminate the element sheet completely.
        m_elemSheet->contents()->parserSetUsesRemUnits(usesRemUnits);
    }
}

void Document::didLoadAllImports()
{
    if (!importLoader())
        styleResolverMayHaveChanged();
    didLoadAllScriptBlockingResources();
}

void Document::didRemoveAllPendingStylesheet()
{
    styleResolverMayHaveChanged();

    // Only imports on master documents can trigger rendering.
    if (HTMLImportLoader* import = importLoader())
        import->didRemoveAllPendingStylesheet();
    if (!haveImportsLoaded())
        return;
    didLoadAllScriptBlockingResources();
}

void Document::didLoadAllScriptBlockingResources()
{
    m_executeScriptsWaitingForResourcesTimer.startOneShot(0, FROM_HERE);

    if (frame())
        frame()->loaderClient()->didRemoveAllPendingStylesheet();
}

void Document::executeScriptsWaitingForResourcesTimerFired(Timer<Document>*)
{
    if (!isRenderingReady())
        return;
    if (ScriptableDocumentParser* parser = scriptableDocumentParser())
        parser->executeScriptsWaitingForResources();
}

CSSStyleSheet& Document::elementSheet()
{
    if (!m_elemSheet)
        m_elemSheet = CSSStyleSheet::createInline(this, m_baseURL);
    return *m_elemSheet;
}

void Document::processHttpEquiv(const AtomicString& equiv, const AtomicString& content, bool inDocumentHeadElement)
{
    ASSERT(!equiv.isNull() && !content.isNull());

    if (equalIgnoringCase(equiv, "refresh")) {
        processHttpEquivRefresh(content);
    } else if (equalIgnoringCase(equiv, "content-language")) {
        setContentLanguage(content);
    }
}

void Document::processHttpEquivRefresh(const AtomicString& content)
{
    maybeHandleHttpRefresh(content, HttpRefreshFromMetaTag);
}

void Document::maybeHandleHttpRefresh(const String& content, HttpRefreshType httpRefreshType)
{
    // FIXME(sky): remove
}

void Document::setViewportDescription(const ViewportDescription& viewportDescription)
{
    // The UA-defined min-width is used by the processing of legacy meta tags.
    if (!viewportDescription.isSpecifiedByAuthor())
        m_viewportDefaultMinWidth = viewportDescription.minWidth;

    if (viewportDescription.isLegacyViewportType()) {
        if (settings() && !settings()->viewportMetaEnabled())
            return;

        m_legacyViewportDescription = viewportDescription;

        // When no author style for @viewport is present, and a meta tag for defining
        // the viewport is, apply the meta tag viewport instead of the UA styles.
        if (m_viewportDescription.type == ViewportDescription::AuthorStyleSheet)
            return;
        m_viewportDescription = viewportDescription;
    } else {
        // If the legacy viewport tag has higher priority than the cascaded @viewport
        // descriptors, use the values from the legacy tag.
        if (!shouldOverrideLegacyDescription(viewportDescription.type))
            m_viewportDescription = m_legacyViewportDescription;
        else
            m_viewportDescription = viewportDescription;
    }

    updateViewportDescription();
}

void Document::updateViewportDescription()
{
    if (frame()) {
        frameHost()->chrome().dispatchViewportPropertiesDidChange(m_viewportDescription);
    }
}

void Document::processReferrerPolicy(const String& policy)
{
    ASSERT(!policy.isNull());

    if (equalIgnoringCase(policy, "never")) {
        setReferrerPolicy(ReferrerPolicyNever);
    } else if (equalIgnoringCase(policy, "always")) {
        setReferrerPolicy(ReferrerPolicyAlways);
    } else if (equalIgnoringCase(policy, "origin")) {
        setReferrerPolicy(ReferrerPolicyOrigin);
    } else if (equalIgnoringCase(policy, "default")) {
        setReferrerPolicy(ReferrerPolicyDefault);
    } else {
        addConsoleMessage(ConsoleMessage::create(RenderingMessageSource, ErrorMessageLevel, "Failed to set referrer policy: The value '" + policy + "' is not one of 'always', 'default', 'never', or 'origin'. Defaulting to 'never'."));
        setReferrerPolicy(ReferrerPolicyNever);
    }
}

void Document::setReferrerPolicy(ReferrerPolicy referrerPolicy)
{
    // FIXME: Can we adopt the CSP referrer policy merge algorithm? Or does the web rely on being able to modify the referrer policy in-flight?
    if (m_didSetReferrerPolicy)
        UseCounter::count(this, UseCounter::ResetReferrerPolicy);
    m_didSetReferrerPolicy = true;

    m_referrerPolicy = referrerPolicy;
}

String Document::outgoingReferrer()
{
    // See http://www.whatwg.org/specs/web-apps/current-work/#fetching-resources
    // for why we walk the parent chain for srcdoc documents.
    Document* referrerDocument = this;
    return referrerDocument->m_url.strippedForUseAsReferrer();
}

MouseEventWithHitTestResults Document::prepareMouseEvent(const HitTestRequest& request, const LayoutPoint& documentPoint, const PlatformMouseEvent& event)
{
    ASSERT(!renderView() || renderView()->isRenderView());

    // RenderView::hitTest causes a layout, and we don't want to hit that until the first
    // layout because until then, there is nothing shown on the screen - the user can't
    // have intentionally clicked on something belonging to this page. Furthermore,
    // mousemove events before the first layout should not lead to a premature layout()
    // happening, which could show a flash of white.
    // See also the similar code in EventHandler::hitTestResultAtPoint.
    if (!renderView() || !view() || !view()->didFirstLayout())
        return MouseEventWithHitTestResults(event, HitTestResult(LayoutPoint()));

    HitTestResult result(documentPoint);
    renderView()->hitTest(request, result);

    if (!request.readOnly())
        updateHoverActiveState(request, result.innerElement(), &event);

    return MouseEventWithHitTestResults(event, result);
}

// DOM Section 1.1.1
bool Document::childTypeAllowed(NodeType type) const
{
    switch (type) {
    case ATTRIBUTE_NODE:
    case DOCUMENT_FRAGMENT_NODE:
    case DOCUMENT_NODE:
    case TEXT_NODE:
        return false;
    case ELEMENT_NODE:
        // Documents may contain no more than one of each of these.
        // (One Element and one DocumentType.)
        for (Node* c = firstChild(); c; c = c->nextSibling())
            if (c->nodeType() == type)
                return false;
        return true;
    }
    return false;
}

bool Document::canReplaceChild(const Node& newChild, const Node& oldChild) const
{
    if (oldChild.nodeType() == newChild.nodeType())
        return true;

    int numElements = 0;

    // First, check how many doctypes and elements we have, not counting
    // the child we're about to remove.
    for (Node* c = firstChild(); c; c = c->nextSibling()) {
        if (c == oldChild)
            continue;

        switch (c->nodeType()) {
        case ELEMENT_NODE:
            numElements++;
            break;
        default:
            break;
        }
    }

    // Then, see how many doctypes and elements might be added by the new child.
    if (newChild.isDocumentFragment()) {
        for (Node* c = toDocumentFragment(newChild).firstChild(); c; c = c->nextSibling()) {
            switch (c->nodeType()) {
            case ATTRIBUTE_NODE:
            case DOCUMENT_FRAGMENT_NODE:
            case DOCUMENT_NODE:
            case TEXT_NODE:
                return false;
            case ELEMENT_NODE:
                numElements++;
                break;
            }
        }
    } else {
        switch (newChild.nodeType()) {
        case ATTRIBUTE_NODE:
        case DOCUMENT_FRAGMENT_NODE:
        case DOCUMENT_NODE:
        case TEXT_NODE:
            return false;
        case ELEMENT_NODE:
            numElements++;
            break;
        }
    }

    if (numElements > 1)
        return false;

    return true;
}

PassRefPtrWillBeRawPtr<Node> Document::cloneNode(bool deep)
{
    RefPtrWillBeRawPtr<Document> clone = cloneDocumentWithoutChildren();
    if (deep)
        cloneChildNodes(clone.get());
    return clone.release();
}

PassRefPtrWillBeRawPtr<Document> Document::cloneDocumentWithoutChildren()
{
    return create(DocumentInit(url()).withRegistrationContext(registrationContext()));
}

StyleSheetList* Document::styleSheets()
{
    if (!m_styleSheetList)
        m_styleSheetList = StyleSheetList::create(this);
    return m_styleSheetList.get();
}

void Document::evaluateMediaQueryListIfNeeded()
{
    if (!m_evaluateMediaQueriesOnStyleRecalc)
        return;
    evaluateMediaQueryList();
    m_evaluateMediaQueriesOnStyleRecalc = false;
}

void Document::evaluateMediaQueryList()
{
    if (m_mediaQueryMatcher)
        m_mediaQueryMatcher->mediaFeaturesChanged();
}

void Document::notifyResizeForViewportUnits()
{
    if (m_mediaQueryMatcher)
        m_mediaQueryMatcher->viewportChanged();
    if (!hasViewportUnits())
        return;
    ensureStyleResolver().notifyResizeForViewportUnits();
    setNeedsStyleRecalcForViewportUnits();
}

void Document::styleResolverChanged(StyleResolverUpdateMode updateMode)
{
    // styleResolverChanged() can be invoked during Document destruction.
    // We just skip that case.
    if (!m_styleEngine)
        return;

    m_styleEngine->resolverChanged(updateMode);

    if (didLayoutWithPendingStylesheets()) {
        // We need to manually repaint because we avoid doing all repaints in layout or style
        // recalc while sheets are still loading to avoid FOUC.
        m_pendingSheetLayout = IgnoreLayoutWithPendingSheets;

        ASSERT(renderView() || importsController());
        if (renderView())
            renderView()->invalidatePaintForViewAndCompositedLayers();
    }
}

void Document::styleResolverMayHaveChanged()
{
    styleResolverChanged(hasNodesWithPlaceholderStyle() ? FullStyleUpdate : AnalyzedStyleUpdate);
}

void Document::setHoverNode(PassRefPtrWillBeRawPtr<Node> newHoverNode)
{
    m_hoverNode = newHoverNode;
}

void Document::setActiveHoverElement(PassRefPtrWillBeRawPtr<Element> newActiveElement)
{
    if (!newActiveElement) {
        m_activeHoverElement.clear();
        return;
    }

    m_activeHoverElement = newActiveElement;
}

void Document::removeFocusedElementOfSubtree(Node* node, bool amongChildrenOnly)
{
    if (!m_focusedElement)
        return;

    // We can't be focused if we're not in the document.
    if (!node->inDocument())
        return;
    bool contains = node->containsIncludingShadowDOM(m_focusedElement.get());
    if (contains && (m_focusedElement != node || !amongChildrenOnly))
        setFocusedElement(nullptr);
}

void Document::hoveredNodeDetached(Node* node)
{
    if (!m_hoverNode)
        return;

    if (node != m_hoverNode && (!m_hoverNode->isTextNode() || node != NodeRenderingTraversal::parent(m_hoverNode.get())))
        return;

    m_hoverNode = NodeRenderingTraversal::parent(node);
    while (m_hoverNode && !m_hoverNode->renderer())
        m_hoverNode = NodeRenderingTraversal::parent(m_hoverNode.get());

    // If the mouse cursor is not visible, do not clear existing
    // hover effects on the ancestors of |node| and do not invoke
    // new hover effects on any other element.
    if (!page()->isCursorVisible())
        return;

    if (frame())
        frame()->eventHandler().scheduleHoverStateUpdate();
}

void Document::activeChainNodeDetached(Node* node)
{
    if (!m_activeHoverElement)
        return;

    if (node != m_activeHoverElement)
        return;

    Node* activeNode = NodeRenderingTraversal::parent(node);
    while (activeNode && activeNode->isElementNode() && !activeNode->renderer())
        activeNode = NodeRenderingTraversal::parent(activeNode);

    m_activeHoverElement = activeNode && activeNode->isElementNode() ? toElement(activeNode) : 0;
}

bool Document::setFocusedElement(PassRefPtrWillBeRawPtr<Element> prpNewFocusedElement, FocusType type)
{
    m_clearFocusedElementTimer.stop();

    RefPtrWillBeRawPtr<Element> newFocusedElement = prpNewFocusedElement;

    // Make sure newFocusedNode is actually in this document
    if (newFocusedElement && (newFocusedElement->document() != this))
        return true;

    if (m_focusedElement == newFocusedElement)
        return true;

    bool focusChangeBlocked = false;
    RefPtrWillBeRawPtr<Element> oldFocusedElement = m_focusedElement;
    m_focusedElement = nullptr;

    // Remove focus from the existing focus node (if any)
    if (oldFocusedElement) {
        ASSERT(!oldFocusedElement->inDetach());

        if (oldFocusedElement->active())
            oldFocusedElement->setActive(false);

        oldFocusedElement->setFocus(false);

        // Dispatch the blur event and let the node do any other blur related activities (important for text fields)
        // If page lost focus, blur event will have already been dispatched
        if (page() && (page()->focusController().isFocused())) {
            oldFocusedElement->dispatchBlurEvent(newFocusedElement.get());

            if (m_focusedElement) {
                // handler shifted focus
                focusChangeBlocked = true;
                newFocusedElement = nullptr;
            }

            oldFocusedElement->dispatchFocusOutEvent(EventTypeNames::focusout, newFocusedElement.get()); // DOM level 3 name for the bubbling blur event.
            // FIXME: We should remove firing DOMFocusOutEvent event when we are sure no content depends
            // on it, probably when <rdar://problem/8503958> is resolved.
            oldFocusedElement->dispatchFocusOutEvent(EventTypeNames::DOMFocusOut, newFocusedElement.get()); // DOM level 2 name for compatibility.

            if (m_focusedElement) {
                // handler shifted focus
                focusChangeBlocked = true;
                newFocusedElement = nullptr;
            }
        }

        if (view()) {
            Widget* oldWidget = widgetForElement(*oldFocusedElement);
            if (oldWidget)
                oldWidget->setFocus(false);
            else
                view()->setFocus(false);
        }
    }

    if (newFocusedElement && newFocusedElement->isFocusable()) {
        if (newFocusedElement->isRootEditableElement() && !acceptsEditingFocus(*newFocusedElement)) {
            // delegate blocks focus change
            focusChangeBlocked = true;
            goto SetFocusedElementDone;
        }
        // Set focus on the new node
        m_focusedElement = newFocusedElement;

        // Dispatch the focus event and let the node do any other focus related activities (important for text fields)
        // If page lost focus, event will be dispatched on page focus, don't duplicate
        if (page() && (page()->focusController().isFocused())) {
            m_focusedElement->dispatchFocusEvent(oldFocusedElement.get(), type);


            if (m_focusedElement != newFocusedElement) {
                // handler shifted focus
                focusChangeBlocked = true;
                goto SetFocusedElementDone;
            }

            m_focusedElement->dispatchFocusInEvent(EventTypeNames::focusin, oldFocusedElement.get()); // DOM level 3 bubbling focus event.

            if (m_focusedElement != newFocusedElement) {
                // handler shifted focus
                focusChangeBlocked = true;
                goto SetFocusedElementDone;
            }

            // FIXME: We should remove firing DOMFocusInEvent event when we are sure no content depends
            // on it, probably when <rdar://problem/8503958> is m.
            m_focusedElement->dispatchFocusInEvent(EventTypeNames::DOMFocusIn, oldFocusedElement.get()); // DOM level 2 for compatibility.

            if (m_focusedElement != newFocusedElement) {
                // handler shifted focus
                focusChangeBlocked = true;
                goto SetFocusedElementDone;
            }
        }

        m_focusedElement->setFocus(true);

        if (m_focusedElement->isRootEditableElement())
            frame()->spellChecker().didBeginEditing(m_focusedElement.get());

        // eww, I suck. set the qt focus correctly
        // ### find a better place in the code for this
        if (view()) {
            Widget* focusWidget = widgetForElement(*m_focusedElement);
            if (focusWidget) {
                // Make sure a widget has the right size before giving it focus.
                // Otherwise, we are testing edge cases of the Widget code.
                // Specifically, in WebCore this does not work well for text fields.
                updateLayout();
                // Re-get the widget in case updating the layout changed things.
                focusWidget = widgetForElement(*m_focusedElement);
            }
            if (focusWidget)
                focusWidget->setFocus(true);
            else
                view()->setFocus(true);
        }
    }

    if (!focusChangeBlocked && frameHost())
        frameHost()->chrome().focusedNodeChanged(m_focusedElement.get());

SetFocusedElementDone:
    updateRenderTreeIfNeeded();
    if (LocalFrame* frame = this->frame())
        frame->selection().didChangeFocus();
    return !focusChangeBlocked;
}

void Document::updateRangesAfterChildrenChanged(ContainerNode* container)
{
    if (!m_ranges.isEmpty()) {
        AttachedRangeSet::const_iterator end = m_ranges.end();
        for (AttachedRangeSet::const_iterator it = m_ranges.begin(); it != end; ++it)
            (*it)->nodeChildrenChanged(container);
    }
}

void Document::updateRangesAfterNodeMovedToAnotherDocument(const Node& node)
{
    ASSERT(node.document() != this);
    if (m_ranges.isEmpty())
        return;
    AttachedRangeSet ranges = m_ranges;
    AttachedRangeSet::const_iterator end = ranges.end();
    for (AttachedRangeSet::const_iterator it = ranges.begin(); it != end; ++it)
        (*it)->updateOwnerDocumentIfNeeded();
}

void Document::nodeChildrenWillBeRemoved(ContainerNode& container)
{
    EventDispatchForbiddenScope assertNoEventDispatch;
    if (!m_ranges.isEmpty()) {
        AttachedRangeSet::const_iterator end = m_ranges.end();
        for (AttachedRangeSet::const_iterator it = m_ranges.begin(); it != end; ++it)
            (*it)->nodeChildrenWillBeRemoved(container);
    }

    if (LocalFrame* frame = this->frame()) {
        for (Node* n = container.firstChild(); n; n = n->nextSibling()) {
            frame->eventHandler().nodeWillBeRemoved(*n);
            frame->selection().nodeWillBeRemoved(*n);
            frame->page()->dragCaretController().nodeWillBeRemoved(*n);
        }
    }
}

void Document::nodeWillBeRemoved(Node& n)
{
    if (!m_ranges.isEmpty()) {
        AttachedRangeSet::const_iterator rangesEnd = m_ranges.end();
        for (AttachedRangeSet::const_iterator it = m_ranges.begin(); it != rangesEnd; ++it)
            (*it)->nodeWillBeRemoved(n);
    }

    if (LocalFrame* frame = this->frame()) {
        frame->eventHandler().nodeWillBeRemoved(n);
        frame->selection().nodeWillBeRemoved(n);
        frame->page()->dragCaretController().nodeWillBeRemoved(n);
    }
}

void Document::didInsertText(Node* text, unsigned offset, unsigned length)
{
    if (!m_ranges.isEmpty()) {
        AttachedRangeSet::const_iterator end = m_ranges.end();
        for (AttachedRangeSet::const_iterator it = m_ranges.begin(); it != end; ++it)
            (*it)->didInsertText(text, offset, length);
    }

    // Update the markers for spelling and grammar checking.
    m_markers->shiftMarkers(text, offset, length);
}

void Document::didRemoveText(Node* text, unsigned offset, unsigned length)
{
    if (!m_ranges.isEmpty()) {
        AttachedRangeSet::const_iterator end = m_ranges.end();
        for (AttachedRangeSet::const_iterator it = m_ranges.begin(); it != end; ++it)
            (*it)->didRemoveText(text, offset, length);
    }

    // Update the markers for spelling and grammar checking.
    m_markers->removeMarkers(text, offset, length);
    m_markers->shiftMarkers(text, offset + length, 0 - length);
}

void Document::didMergeTextNodes(Text& oldNode, unsigned offset)
{
    if (!m_ranges.isEmpty()) {
        NodeWithIndex oldNodeWithIndex(oldNode);
        AttachedRangeSet::const_iterator end = m_ranges.end();
        for (AttachedRangeSet::const_iterator it = m_ranges.begin(); it != end; ++it)
            (*it)->didMergeTextNodes(oldNodeWithIndex, offset);
    }

    if (m_frame)
        m_frame->selection().didMergeTextNodes(oldNode, offset);

    // FIXME: This should update markers for spelling and grammar checking.
}

void Document::didSplitTextNode(Text& oldNode)
{
    if (!m_ranges.isEmpty()) {
        AttachedRangeSet::const_iterator end = m_ranges.end();
        for (AttachedRangeSet::const_iterator it = m_ranges.begin(); it != end; ++it)
            (*it)->didSplitTextNode(oldNode);
    }

    if (m_frame)
        m_frame->selection().didSplitTextNode(oldNode);

    // FIXME: This should update markers for spelling and grammar checking.
}

void Document::setWindowAttributeEventListener(const AtomicString& eventType, PassRefPtr<EventListener> listener)
{
    LocalDOMWindow* domWindow = this->domWindow();
    if (!domWindow)
        return;
    domWindow->setAttributeEventListener(eventType, listener);
}

EventListener* Document::getWindowAttributeEventListener(const AtomicString& eventType)
{
    LocalDOMWindow* domWindow = this->domWindow();
    if (!domWindow)
        return 0;
    return domWindow->getAttributeEventListener(eventType);
}

EventQueue* Document::eventQueue() const
{
    if (!m_domWindow)
        return 0;
    return m_domWindow->eventQueue();
}

void Document::enqueueAnimationFrameEvent(PassRefPtrWillBeRawPtr<Event> event)
{
    ensureScriptedAnimationController().enqueueEvent(event);
}

void Document::enqueueUniqueAnimationFrameEvent(PassRefPtrWillBeRawPtr<Event> event)
{
    ensureScriptedAnimationController().enqueuePerFrameEvent(event);
}

void Document::enqueueScrollEventForNode(Node* target)
{
    // Per the W3C CSSOM View Module only scroll events fired at the document should bubble.
    RefPtrWillBeRawPtr<Event> scrollEvent = target->isDocumentNode() ? Event::createBubble(EventTypeNames::scroll) : Event::create(EventTypeNames::scroll);
    scrollEvent->setTarget(target);
    ensureScriptedAnimationController().enqueuePerFrameEvent(scrollEvent.release());
}

void Document::enqueueResizeEvent()
{
    RefPtrWillBeRawPtr<Event> event = Event::create(EventTypeNames::resize);
    event->setTarget(domWindow());
    ensureScriptedAnimationController().enqueuePerFrameEvent(event.release());
}

void Document::enqueueMediaQueryChangeListeners(WillBeHeapVector<RefPtrWillBeMember<MediaQueryListListener> >& listeners)
{
    ensureScriptedAnimationController().enqueueMediaQueryChangeListeners(listeners);
}

Document::EventFactorySet& Document::eventFactories()
{
    DEFINE_STATIC_LOCAL(EventFactorySet, s_eventFactory, ());
    return s_eventFactory;
}

void Document::registerEventFactory(PassOwnPtr<EventFactoryBase> eventFactory)
{
    ASSERT(!eventFactories().contains(eventFactory.get()));
    eventFactories().add(eventFactory);
}

PassRefPtrWillBeRawPtr<Event> Document::createEvent(const String& eventType, ExceptionState& exceptionState)
{
    RefPtrWillBeRawPtr<Event> event = nullptr;
    for (EventFactorySet::const_iterator it = eventFactories().begin(); it != eventFactories().end(); ++it) {
        event = (*it)->create(eventType);
        if (event)
            return event.release();
    }
    exceptionState.throwDOMException(NotSupportedError, "The provided event type ('" + eventType + "') is invalid.");
    return nullptr;
}

void Document::addListenerTypeIfNeeded(const AtomicString& eventType)
{
    if (eventType == EventTypeNames::overflowchanged) {
        UseCounter::countDeprecation(*this, UseCounter::OverflowChangedEvent);
        addListenerType(OVERFLOWCHANGED_LISTENER);
    } else if (eventType == EventTypeNames::webkitAnimationStart || (RuntimeEnabledFeatures::cssAnimationUnprefixedEnabled() && eventType == EventTypeNames::animationstart)) {
        addListenerType(ANIMATIONSTART_LISTENER);
    } else if (eventType == EventTypeNames::webkitAnimationEnd || (RuntimeEnabledFeatures::cssAnimationUnprefixedEnabled() && eventType == EventTypeNames::animationend)) {
        addListenerType(ANIMATIONEND_LISTENER);
    } else if (eventType == EventTypeNames::webkitAnimationIteration || (RuntimeEnabledFeatures::cssAnimationUnprefixedEnabled() && eventType == EventTypeNames::animationiteration)) {
        addListenerType(ANIMATIONITERATION_LISTENER);
    } else if (eventType == EventTypeNames::webkitTransitionEnd || eventType == EventTypeNames::transitionend) {
        addListenerType(TRANSITIONEND_LISTENER);
    } else if (eventType == EventTypeNames::scroll) {
        addListenerType(SCROLL_LISTENER);
    }
}

const AtomicString& Document::referrer() const
{
    return nullAtom;
}

static bool isValidNameNonASCII(const LChar* characters, unsigned length)
{
    if (!isValidNameStart(characters[0]))
        return false;

    for (unsigned i = 1; i < length; ++i) {
        if (!isValidNamePart(characters[i]))
            return false;
    }

    return true;
}

static bool isValidNameNonASCII(const UChar* characters, unsigned length)
{
    unsigned i = 0;

    UChar32 c;
    U16_NEXT(characters, i, length, c)
    if (!isValidNameStart(c))
        return false;

    while (i < length) {
        U16_NEXT(characters, i, length, c)
        if (!isValidNamePart(c))
            return false;
    }

    return true;
}

template<typename CharType>
static inline bool isValidNameASCII(const CharType* characters, unsigned length)
{
    CharType c = characters[0];
    if (!(isASCIIAlpha(c) || c == ':' || c == '_'))
        return false;

    for (unsigned i = 1; i < length; ++i) {
        c = characters[i];
        if (!(isASCIIAlphanumeric(c) || c == ':' || c == '_' || c == '-' || c == '.'))
            return false;
    }

    return true;
}

bool Document::isValidName(const String& name)
{
    unsigned length = name.length();
    if (!length)
        return false;

    if (name.is8Bit()) {
        const LChar* characters = name.characters8();

        if (isValidNameASCII(characters, length))
            return true;

        return isValidNameNonASCII(characters, length);
    }

    const UChar* characters = name.characters16();

    if (isValidNameASCII(characters, length))
        return true;

    return isValidNameNonASCII(characters, length);
}

template<typename CharType>
static bool parseQualifiedNameInternal(const AtomicString& qualifiedName, const CharType* characters, unsigned length, AtomicString& prefix, AtomicString& localName, ExceptionState& exceptionState)
{
    bool nameStart = true;
    bool sawColon = false;
    int colonPos = 0;

    for (unsigned i = 0; i < length;) {
        UChar32 c;
        U16_NEXT(characters, i, length, c)
        if (c == ':') {
            if (sawColon) {
                exceptionState.throwDOMException(NamespaceError, "The qualified name provided ('" + qualifiedName + "') contains multiple colons.");
                return false; // multiple colons: not allowed
            }
            nameStart = true;
            sawColon = true;
            colonPos = i - 1;
        } else if (nameStart) {
            if (!isValidNameStart(c)) {
                StringBuilder message;
                message.appendLiteral("The qualified name provided ('");
                message.append(qualifiedName);
                message.appendLiteral("') contains the invalid name-start character '");
                message.append(c);
                message.appendLiteral("'.");
                exceptionState.throwDOMException(InvalidCharacterError, message.toString());
                return false;
            }
            nameStart = false;
        } else {
            if (!isValidNamePart(c)) {
                StringBuilder message;
                message.appendLiteral("The qualified name provided ('");
                message.append(qualifiedName);
                message.appendLiteral("') contains the invalid character '");
                message.append(c);
                message.appendLiteral("'.");
                exceptionState.throwDOMException(InvalidCharacterError, message.toString());
                return false;
            }
        }
    }

    if (!sawColon) {
        prefix = nullAtom;
        localName = qualifiedName;
    } else {
        prefix = AtomicString(characters, colonPos);
        if (prefix.isEmpty()) {
            exceptionState.throwDOMException(NamespaceError, "The qualified name provided ('" + qualifiedName + "') has an empty namespace prefix.");
            return false;
        }
        int prefixStart = colonPos + 1;
        localName = AtomicString(characters + prefixStart, length - prefixStart);
    }

    if (localName.isEmpty()) {
        exceptionState.throwDOMException(NamespaceError, "The qualified name provided ('" + qualifiedName + "') has an empty local name.");
        return false;
    }

    return true;
}

bool Document::parseQualifiedName(const AtomicString& qualifiedName, AtomicString& prefix, AtomicString& localName, ExceptionState& exceptionState)
{
    unsigned length = qualifiedName.length();

    if (!length) {
        exceptionState.throwDOMException(InvalidCharacterError, "The qualified name provided is empty.");
        return false;
    }

    if (qualifiedName.is8Bit())
        return parseQualifiedNameInternal(qualifiedName, qualifiedName.characters8(), length, prefix, localName, exceptionState);
    return parseQualifiedNameInternal(qualifiedName, qualifiedName.characters16(), length, prefix, localName, exceptionState);
}

KURL Document::completeURL(const String& url) const
{
    // Always return a null URL when passed a null string.
    // FIXME: Should we change the KURL constructor to have this behavior?
    // See also [CSS]StyleSheet::completeURL(const String&)
    if (url.isNull())
        return KURL();
    return KURL(m_baseURL, url);
}

// Support for Javascript execCommand, and related methods

static Editor::Command command(Document* document, const String& commandName, bool userInterface = false)
{
    LocalFrame* frame = document->frame();
    if (!frame || frame->document() != document)
        return Editor::Command();

    document->updateRenderTreeIfNeeded();
    return frame->editor().command(commandName, userInterface ? CommandFromDOMWithUserInterface : CommandFromDOM);
}

bool Document::execCommand(const String& commandName, bool userInterface, const String& value)
{
    // We don't allow recusrive |execCommand()| to protect against attack code.
    // Recursive call of |execCommand()| could be happened by moving iframe
    // with script triggered by insertion, e.g. <iframe src="javascript:...">
    // <iframe onload="...">. This usage is valid as of the specification
    // although, it isn't common use case, rather it is used as attack code.
    static bool inExecCommand = false;
    if (inExecCommand) {
        String message = "We don't execute document.execCommand() this time, because it is called recursively.";
        addConsoleMessage(ConsoleMessage::create(JSMessageSource, WarningMessageLevel, message));
        return false;
    }
    TemporaryChange<bool> executeScope(inExecCommand, true);

    // Postpone DOM mutation events, which can execute scripts and change
    // DOM tree against implementation assumption.
    EventQueueScope eventQueueScope;
    Editor::Command editorCommand = command(this, commandName, userInterface);
    Platform::current()->histogramSparse("WebCore.Document.execCommand", editorCommand.idForHistogram());
    return editorCommand.execute(value);
}

bool Document::queryCommandEnabled(const String& commandName)
{
    return command(this, commandName).isEnabled();
}

bool Document::queryCommandIndeterm(const String& commandName)
{
    return command(this, commandName).state() == MixedTriState;
}

bool Document::queryCommandState(const String& commandName)
{
    return command(this, commandName).state() == TrueTriState;
}

bool Document::queryCommandSupported(const String& commandName)
{
    return command(this, commandName).isSupported();
}

String Document::queryCommandValue(const String& commandName)
{
    return command(this, commandName).value();
}

KURL Document::openSearchDescriptionURL()
{
    return KURL();
}

void Document::pushCurrentScript(PassRefPtrWillBeRawPtr<HTMLScriptElement> newCurrentScript)
{
    ASSERT(newCurrentScript);
    m_currentScriptStack.append(newCurrentScript);
}

void Document::popCurrentScript()
{
    ASSERT(!m_currentScriptStack.isEmpty());
    m_currentScriptStack.removeLast();
}

Document& Document::topDocument() const
{
    Document* doc = const_cast<Document*>(this);
    ASSERT(doc);
    return *doc;
}

WeakPtrWillBeRawPtr<Document> Document::contextDocument()
{
    if (m_contextDocument)
        return m_contextDocument;
    if (m_frame) {
#if ENABLE(OILPAN)
        return this;
#else
        return m_weakFactory.createWeakPtr();
#endif
    }
    return WeakPtrWillBeRawPtr<Document>(nullptr);
}

void Document::finishedParsing()
{
    ASSERT(!scriptableDocumentParser() || !m_parser->isParsing());
    ASSERT(!scriptableDocumentParser() || m_readyState != Loading);
    setParsing(false);
    dispatchEvent(Event::createBubble(EventTypeNames::DOMContentLoaded));

    // The loader's finishedParsing() method may invoke script that causes this object to
    // be dereferenced (when this document is in an iframe and the onload causes the iframe's src to change).
    // Keep it alive until we are done.
    RefPtrWillBeRawPtr<Document> protect(this);

    if (RefPtr<LocalFrame> f = frame()) {
        checkCompleted();

        // Check if the scrollbars are really needed for the content.
        // If not, remove them, relayout, and repaint.
        if (m_frame->view())
            m_frame->view()->restoreScrollbar();

        TRACE_EVENT_INSTANT1(TRACE_DISABLED_BY_DEFAULT("devtools.timeline"), "MarkDOMContent", "data", InspectorMarkLoadEvent::data(f.get()));
    }

    // Schedule dropping of the ElementDataCache. We keep it alive for a while after parsing finishes
    // so that dynamically inserted content can also benefit from sharing optimizations.
    // Note that we don't refresh the timer on cache access since that could lead to huge caches being kept
    // alive indefinitely by something innocuous like JS setting .innerHTML repeatedly on a timer.
    m_elementDataCacheClearTimer.startOneShot(10, FROM_HERE);

    // Parser should have picked up all preloads by now
    m_fetcher->clearPreloads();

    if (HTMLImportLoader* import = importLoader())
        import->didFinishParsing();
}

void Document::elementDataCacheClearTimerFired(Timer<Document>*)
{
    m_elementDataCache.clear();
}

bool Document::allowExecutingScripts(Node* node)
{
    // FIXME: Eventually we'd like to evaluate scripts which are inserted into a
    // viewless document but this'll do for now.
    // See http://bugs.webkit.org/show_bug.cgi?id=5727
    LocalFrame* frame = executingFrame();
    if (!frame)
        return false;
    if (!node->document().executingFrame())
        return false;
    return true;
}

bool Document::isContextThread() const
{
    return isMainThread();
}

void Document::attachRange(Range* range)
{
    ASSERT(!m_ranges.contains(range));
    m_ranges.add(range);
}

void Document::detachRange(Range* range)
{
    // We don't ASSERT m_ranges.contains(range) to allow us to call this
    // unconditionally to fix: https://bugs.webkit.org/show_bug.cgi?id=26044
    m_ranges.remove(range);
}

void Document::getCSSCanvasContext(const String& type, const String& name, int width, int height, RefPtrWillBeRawPtr<CanvasRenderingContext2D>& context2d, RefPtrWillBeRawPtr<WebGLRenderingContext>& context3d)
{
    HTMLCanvasElement& element = getCSSCanvasElement(name);
    element.setSize(IntSize(width, height));
    CanvasRenderingContext* context = element.getContext(type);
    if (!context)
        return;

    if (context->is2d()) {
        context2d = toCanvasRenderingContext2D(context);
    } else if (context->is3d()) {
        context3d = toWebGLRenderingContext(context);
    }
}

HTMLCanvasElement& Document::getCSSCanvasElement(const String& name)
{
    RefPtrWillBeMember<HTMLCanvasElement>& element = m_cssCanvasElements.add(name, nullptr).storedValue->value;
    if (!element) {
        element = HTMLCanvasElement::create(*this);
        element->setAccelerationDisabled(true);
    }
    return *element;
}

void Document::reportBlockedScriptExecutionToInspector(const String& directiveText)
{
}

void Document::addMessage(PassRefPtrWillBeRawPtr<ConsoleMessage> consoleMessage)
{
    if (!m_frame)
        return;

    if (!consoleMessage->scriptState() && consoleMessage->url().isNull() && !consoleMessage->lineNumber()) {
        consoleMessage->setURL(url().string());
        if (parsing() && scriptableDocumentParser()) {
            ScriptableDocumentParser* parser = scriptableDocumentParser();
            if (!parser->isWaitingForScripts() && !parser->isExecutingScript())
                consoleMessage->setLineNumber(parser->lineNumber().oneBasedInt());
        }
    }
    m_frame->console().addMessage(consoleMessage);
}

void Document::decrementLoadEventDelayCount()
{
    ASSERT(m_loadEventDelayCount);
    --m_loadEventDelayCount;

    if (!m_loadEventDelayCount)
        checkLoadEventSoon();
}

void Document::checkLoadEventSoon()
{
    if (frame() && !m_loadEventDelayTimer.isActive())
        m_loadEventDelayTimer.startOneShot(0, FROM_HERE);
}

bool Document::isDelayingLoadEvent()
{
#if ENABLE(OILPAN)
    // Always delay load events until after garbage collection.
    // This way we don't have to explicitly delay load events via
    // incrementLoadEventDelayCount and decrementLoadEventDelayCount in
    // Node destructors.
    if (ThreadState::current()->isSweepInProgress()) {
        if (!m_loadEventDelayCount)
            checkLoadEventSoon();
        return true;
    }
#endif
    return m_loadEventDelayCount;
}


void Document::loadEventDelayTimerFired(Timer<Document>*)
{
    checkCompleted();
}

ScriptedAnimationController& Document::ensureScriptedAnimationController()
{
    if (!m_scriptedAnimationController) {
        m_scriptedAnimationController = ScriptedAnimationController::create(this);
        // We need to make sure that we don't start up the animation controller on a background tab, for example.
        if (!page())
            m_scriptedAnimationController->suspend();
    }
    return *m_scriptedAnimationController;
}

int Document::requestAnimationFrame(PassOwnPtrWillBeRawPtr<RequestAnimationFrameCallback> callback)
{
    return ensureScriptedAnimationController().registerCallback(callback);
}

void Document::cancelAnimationFrame(int id)
{
    if (!m_scriptedAnimationController)
        return;
    m_scriptedAnimationController->cancelCallback(id);
}

void Document::serviceScriptedAnimations(double monotonicAnimationStartTime)
{
    WTF_LOG(ScriptedAnimationController, "Document::serviceScriptedAnimations: controller = %d",
        m_scriptedAnimationController ? 1 : 0);
    if (!m_scriptedAnimationController)
        return;
    m_scriptedAnimationController->serviceScriptedAnimations(monotonicAnimationStartTime);
}

PassRefPtrWillBeRawPtr<Touch> Document::createTouch(LocalDOMWindow* window, EventTarget* target, int identifier, double pageX, double pageY, double screenX, double screenY, double radiusX, double radiusY, float rotationAngle, float force) const
{
    // Match behavior from when these types were integers, and avoid surprises from someone explicitly
    // passing Infinity/NaN.
    if (!std::isfinite(pageX))
        pageX = 0;
    if (!std::isfinite(pageY))
        pageY = 0;
    if (!std::isfinite(screenX))
        screenX = 0;
    if (!std::isfinite(screenY))
        screenY = 0;
    if (!std::isfinite(radiusX))
        radiusX = 0;
    if (!std::isfinite(radiusY))
        radiusY = 0;
    if (!std::isfinite(rotationAngle))
        rotationAngle = 0;
    if (!std::isfinite(force))
        force = 0;

    // FIXME: It's not clear from the documentation at
    // http://developer.apple.com/library/safari/#documentation/UserExperience/Reference/DocumentAdditionsReference/DocumentAdditions/DocumentAdditions.html
    // when this method should throw and nor is it by inspection of iOS behavior. It would be nice to verify any cases where it throws under iOS
    // and implement them here. See https://bugs.webkit.org/show_bug.cgi?id=47819
    LocalFrame* frame = window ? window->frame() : this->frame();
    return Touch::create(frame, target, identifier, FloatPoint(screenX, screenY), FloatPoint(pageX, pageY), FloatSize(radiusX, radiusY), rotationAngle, force);
}

PassRefPtrWillBeRawPtr<TouchList> Document::createTouchList(WillBeHeapVector<RefPtrWillBeMember<Touch> >& touches) const
{
    return TouchList::adopt(touches);
}

DocumentLoadTiming* Document::timing() const
{
    return &m_documentLoadTiming;
}

IntSize Document::initialViewportSize() const
{
    if (!view())
        return IntSize();
    return view()->unscaledVisibleContentSize(IncludeScrollbars);
}

Node* eventTargetNodeForDocument(Document* doc)
{
    if (!doc)
        return 0;
    Node* node = doc->focusedElement();
    if (!node)
        node = doc->documentElement();
    return node;
}

void Document::adjustFloatQuadsForScrollAndAbsoluteZoom(Vector<FloatQuad>& quads, RenderObject& renderer)
{
    if (!view())
        return;

    LayoutRect visibleContentRect = view()->visibleContentRect();
    for (size_t i = 0; i < quads.size(); ++i) {
        quads[i].move(-FloatSize(visibleContentRect.x().toFloat(), visibleContentRect.y().toFloat()));
        adjustFloatQuadForAbsoluteZoom(quads[i], renderer);
    }
}

void Document::adjustFloatRectForScrollAndAbsoluteZoom(FloatRect& rect, RenderObject& renderer)
{
    if (!view())
        return;

    LayoutRect visibleContentRect = view()->visibleContentRect();
    rect.move(-FloatSize(visibleContentRect.x().toFloat(), visibleContentRect.y().toFloat()));
    adjustFloatRectForAbsoluteZoom(rect, renderer);
}

bool Document::hasActiveParser()
{
    return m_activeParserCount || (m_parser && m_parser->processingData());
}

void Document::decrementActiveParserCount()
{
    --m_activeParserCount;
}

static RenderObject* nearestCommonHoverAncestor(RenderObject* obj1, RenderObject* obj2)
{
    if (!obj1 || !obj2)
        return 0;

    for (RenderObject* currObj1 = obj1; currObj1; currObj1 = currObj1->hoverAncestor()) {
        for (RenderObject* currObj2 = obj2; currObj2; currObj2 = currObj2->hoverAncestor()) {
            if (currObj1 == currObj2)
                return currObj1;
        }
    }

    return 0;
}

void Document::updateHoverActiveState(const HitTestRequest& request, Element* innerElement, const PlatformMouseEvent* event)
{
    ASSERT(!request.readOnly());

    if (request.active() && m_frame)
        m_frame->eventHandler().notifyElementActivated();

    Element* innerElementInDocument = innerElement;

    Element* oldActiveElement = activeHoverElement();
    if (oldActiveElement && !request.active()) {
        // The oldActiveElement renderer is null, dropped on :active by setting display: none,
        // for instance. We still need to clear the ActiveChain as the mouse is released.
        for (Node* node = oldActiveElement; node; node = NodeRenderingTraversal::parent(node)) {
            ASSERT(!node->isTextNode());
            node->setActive(false);
            m_userActionElements.setInActiveChain(node, false);
        }
        setActiveHoverElement(nullptr);
    } else {
        Element* newActiveElement = innerElementInDocument;
        if (!oldActiveElement && newActiveElement && !newActiveElement->isDisabledFormControl() && request.active() && !request.touchMove()) {
            // We are setting the :active chain and freezing it. If future moves happen, they
            // will need to reference this chain.
            for (Node* node = newActiveElement; node; node = NodeRenderingTraversal::parent(node)) {
                ASSERT(!node->isTextNode());
                m_userActionElements.setInActiveChain(node, true);
            }
            setActiveHoverElement(newActiveElement);
        }
    }
    // If the mouse has just been pressed, set :active on the chain. Those (and only those)
    // nodes should remain :active until the mouse is released.
    bool allowActiveChanges = !oldActiveElement && activeHoverElement();

    // If the mouse is down and if this is a mouse move event, we want to restrict changes in
    // :hover/:active to only apply to elements that are in the :active chain that we froze
    // at the time the mouse went down.
    bool mustBeInActiveChain = request.active() && request.move();

    RefPtrWillBeRawPtr<Node> oldHoverNode = hoverNode();

    // Check to see if the hovered node has changed.
    // If it hasn't, we do not need to do anything.
    Node* newHoverNode = innerElementInDocument;
    while (newHoverNode && !newHoverNode->renderer())
        newHoverNode = newHoverNode->parentOrShadowHostNode();

    // Update our current hover node.
    setHoverNode(newHoverNode);

    // We have two different objects. Fetch their renderers.
    RenderObject* oldHoverObj = oldHoverNode ? oldHoverNode->renderer() : 0;
    RenderObject* newHoverObj = newHoverNode ? newHoverNode->renderer() : 0;

    // Locate the common ancestor render object for the two renderers.
    RenderObject* ancestor = nearestCommonHoverAncestor(oldHoverObj, newHoverObj);
    RefPtrWillBeRawPtr<Node> ancestorNode(ancestor ? ancestor->node() : 0);

    WillBeHeapVector<RefPtrWillBeMember<Node>, 32> nodesToRemoveFromChain;
    WillBeHeapVector<RefPtrWillBeMember<Node>, 32> nodesToAddToChain;

    if (oldHoverObj != newHoverObj) {
        // If the old hovered node is not nil but it's renderer is, it was probably detached as part of the :hover style
        // (for instance by setting display:none in the :hover pseudo-class). In this case, the old hovered element (and its ancestors)
        // must be updated, to ensure it's normal style is re-applied.
        if (oldHoverNode && !oldHoverObj) {
            for (Node* node = oldHoverNode.get(); node; node = node->parentNode()) {
                if (!mustBeInActiveChain || (node->isElementNode() && toElement(node)->inActiveChain()))
                    nodesToRemoveFromChain.append(node);
            }

        }

        // The old hover path only needs to be cleared up to (and not including) the common ancestor;
        for (RenderObject* curr = oldHoverObj; curr && curr != ancestor; curr = curr->hoverAncestor()) {
            if (curr->node() && !curr->isText() && (!mustBeInActiveChain || curr->node()->inActiveChain()))
                nodesToRemoveFromChain.append(curr->node());
        }
    }

    // Now set the hover state for our new object up to the root.
    for (RenderObject* curr = newHoverObj; curr; curr = curr->hoverAncestor()) {
        if (curr->node() && !curr->isText() && (!mustBeInActiveChain || curr->node()->inActiveChain()))
            nodesToAddToChain.append(curr->node());
    }

    // mouseenter and mouseleave events do not bubble, so they are dispatched iff there is a capturing
    // event handler on an ancestor or a normal event handler on the element itself. This special
    // handling is necessary to avoid O(n^2) capturing event handler checks. We'll check the previously
    // hovered node's ancestor tree for 'mouseleave' handlers here, then check the newly hovered node's
    // ancestor tree for 'mouseenter' handlers after dispatching the 'mouseleave' events (as the handler
    // for 'mouseleave' might set a capturing 'mouseenter' handler, odd as that might be).
    bool ancestorHasCapturingMouseleaveListener = false;
    if (event && newHoverNode != oldHoverNode.get()) {
        for (Node* node = oldHoverNode.get(); node; node = node->parentOrShadowHostNode()) {
            if (node->hasCapturingEventListeners(EventTypeNames::mouseleave)) {
                ancestorHasCapturingMouseleaveListener = true;
                break;
            }
        }
    }

    size_t removeCount = nodesToRemoveFromChain.size();
    for (size_t i = 0; i < removeCount; ++i) {
        nodesToRemoveFromChain[i]->setHovered(false);
        if (event && (ancestorHasCapturingMouseleaveListener || nodesToRemoveFromChain[i]->hasEventListeners(EventTypeNames::mouseleave)))
            nodesToRemoveFromChain[i]->dispatchMouseEvent(*event, EventTypeNames::mouseleave, 0, newHoverNode);
    }

    bool ancestorHasCapturingMouseenterListener = false;
    if (event && newHoverNode != oldHoverNode.get()) {
        for (Node* node = newHoverNode; node; node = node->parentOrShadowHostNode()) {
            if (node->hasCapturingEventListeners(EventTypeNames::mouseenter)) {
                ancestorHasCapturingMouseenterListener = true;
                break;
            }
        }
    }

    bool sawCommonAncestor = false;
    size_t addCount = nodesToAddToChain.size();
    for (size_t i = 0; i < addCount; ++i) {
        // Elements past the common ancestor do not change hover state, but might change active state.
        if (ancestorNode && nodesToAddToChain[i] == ancestorNode)
            sawCommonAncestor = true;
        if (allowActiveChanges)
            nodesToAddToChain[i]->setActive(true);
        if (!sawCommonAncestor) {
            nodesToAddToChain[i]->setHovered(true);
            if (event && (ancestorHasCapturingMouseenterListener || nodesToAddToChain[i]->hasEventListeners(EventTypeNames::mouseenter)))
                nodesToAddToChain[i]->dispatchMouseEvent(*event, EventTypeNames::mouseenter, 0, oldHoverNode.get());
        }
    }
}

Locale& Document::getCachedLocale(const AtomicString& locale)
{
    AtomicString localeKey = locale;
    if (locale.isEmpty() || !RuntimeEnabledFeatures::langAttributeAwareFormControlUIEnabled())
        return Locale::defaultLocale();
    LocaleIdentifierToLocaleMap::AddResult result = m_localeCache.add(localeKey, nullptr);
    if (result.isNewEntry)
        result.storedValue->value = Locale::create(localeKey);
    return *(result.storedValue->value);
}

Document& Document::ensureTemplateDocument()
{
    if (isTemplateDocument())
        return *this;

    if (m_templateDocument)
        return *m_templateDocument;

    if (isHTMLDocument()) {
        DocumentInit init = DocumentInit::fromContext(contextDocument(), blankURL()).withNewRegistrationContext();
        m_templateDocument = HTMLDocument::create(init);
    } else {
        m_templateDocument = Document::create(DocumentInit(blankURL()));
    }

    m_templateDocument->m_templateDocumentHost = this; // balanced in dtor.

    return *m_templateDocument.get();
}

float Document::devicePixelRatio() const
{
    return m_frame ? m_frame->devicePixelRatio() : 1.0;
}

PassOwnPtr<LifecycleNotifier<Document> > Document::createLifecycleNotifier()
{
    return DocumentLifecycleNotifier::create(this);
}

DocumentLifecycleNotifier& Document::lifecycleNotifier()
{
    return static_cast<DocumentLifecycleNotifier&>(LifecycleContext<Document>::lifecycleNotifier());
}

void Document::removedStyleSheet(StyleSheet* sheet, StyleResolverUpdateMode updateMode)
{
    // If we're in document teardown, then we don't need this notification of our sheet's removal.
    // styleResolverChanged() is needed even when the document is inactive so that
    // imported docuements (which is inactive) notifies the change to the master document.
    if (isActive())
        styleEngine()->modifiedStyleSheet(sheet);
    styleResolverChanged(updateMode);
}

void Document::modifiedStyleSheet(StyleSheet* sheet, StyleResolverUpdateMode updateMode)
{
    // If we're in document teardown, then we don't need this notification of our sheet's removal.
    // styleResolverChanged() is needed even when the document is inactive so that
    // imported docuements (which is inactive) notifies the change to the master document.
    if (isActive())
        styleEngine()->modifiedStyleSheet(sheet);
    styleResolverChanged(updateMode);
}

void Document::focusAutofocusElementTimerFired(Timer<Document>*)
{
    if (RefPtrWillBeRawPtr<Element> element = autofocusElement()) {
        setAutofocusElement(nullptr);
        element->focus();
    }
}

void Document::setAutofocusElement(Element* element)
{
    if (!element) {
        m_autofocusElement = nullptr;
        return;
    }
    if (m_hasAutofocused)
        return;
    m_hasAutofocused = true;
    ASSERT(!m_autofocusElement);
    m_autofocusElement = element;
    if (!m_focusAutofocusElementTimer.isActive())
        m_focusAutofocusElementTimer.startOneShot(0, FROM_HERE);
}

Element* Document::activeElement() const
{
    if (Element* element = treeScope().adjustedFocusedElement())
        return element;
    return documentElement();
}

void Document::getTransitionElementData(Vector<TransitionElementData>& elementData)
{
}

bool Document::hasFocus() const
{
    Page* page = this->page();
    if (!page)
        return false;
    if (!page->focusController().isActive() || !page->focusController().isFocused())
        return false;
    Frame* focusedFrame = page->focusController().focusedFrame();
    return focusedFrame && focusedFrame == frame();
}

void Document::clearWeakMembers(Visitor* visitor)
{
}

v8::Handle<v8::Object> Document::wrap(v8::Handle<v8::Object> creationContext, v8::Isolate* isolate)
{
    ASSERT(!DOMDataStore::containsWrapperNonTemplate(this, isolate));

    const WrapperTypeInfo* wrapperType = wrapperTypeInfo();

    if (frame() && frame()->script().initializeMainWorld()) {
        // initializeMainWorld may have created a wrapper for the object, retry from the start.
        v8::Handle<v8::Object> wrapper = DOMDataStore::getWrapperNonTemplate(this, isolate);
        if (!wrapper.IsEmpty())
            return wrapper;
    }

    v8::Handle<v8::Object> wrapper = V8DOMWrapper::createWrapper(creationContext, wrapperType, toScriptWrappableBase(), isolate);
    if (UNLIKELY(wrapper.IsEmpty()))
        return wrapper;

    wrapperType->installConditionallyEnabledProperties(wrapper, isolate);
    V8DOMWrapper::associateObjectWithWrapperNonTemplate(this, wrapperType, wrapper, isolate);

    DOMWrapperWorld& world = DOMWrapperWorld::current(isolate);
    if (world.isMainWorld() && frame())
        frame()->script().windowProxy(world)->updateDocumentWrapper(wrapper);

    return wrapper;
}

void Document::trace(Visitor* visitor)
{
#if ENABLE(OILPAN)
    visitor->trace(m_importsController);
    visitor->trace(m_implementation);
    visitor->trace(m_autofocusElement);
    visitor->trace(m_focusedElement);
    visitor->trace(m_hoverNode);
    visitor->trace(m_activeHoverElement);
    visitor->trace(m_documentElement);
    visitor->trace(m_titleElement);
    visitor->trace(m_markers);
    visitor->trace(m_currentScriptStack);
    visitor->trace(m_cssCanvasElements);
    visitor->trace(m_elemSheet);
    visitor->trace(m_ranges);
    visitor->trace(m_styleEngine);
    visitor->trace(m_domWindow);
    visitor->trace(m_fetcher);
    visitor->trace(m_parser);
    visitor->trace(m_styleSheetList);
    visitor->trace(m_mediaQueryMatcher);
    visitor->trace(m_scriptedAnimationController);
    visitor->trace(m_registrationContext);
    visitor->trace(m_customElementMicrotaskRunQueue);
    visitor->trace(m_elementDataCache);
    visitor->trace(m_templateDocument);
    visitor->trace(m_templateDocumentHost);
    visitor->trace(m_visibilityObservers);
    visitor->trace(m_userActionElements);
    visitor->trace(m_timeline);
    visitor->trace(m_compositorPendingAnimations);
    visitor->trace(m_contextDocument);
    visitor->registerWeakMembers<Document, &Document::clearWeakMembers>(this);
#endif
    DocumentSupplementable::trace(visitor);
    TreeScope::trace(visitor);
    ContainerNode::trace(visitor);
    ExecutionContext::trace(visitor);
    LifecycleContext<Document>::trace(visitor);
}

} // namespace blink

#ifndef NDEBUG
using namespace blink;
void showLiveDocumentInstances()
{
    WeakDocumentSet& set = liveDocumentSet();
    fprintf(stderr, "There are %u documents currently alive:\n", set.size());
    for (WeakDocumentSet::const_iterator it = set.begin(); it != set.end(); ++it) {
        fprintf(stderr, "- Document %p URL: %s\n", *it, (*it)->url().string().utf8().data());
    }
}
#endif
