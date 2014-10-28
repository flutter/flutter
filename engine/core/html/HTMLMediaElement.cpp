/*
 * Copyright (C) 2007, 2008, 2009, 2010, 2011, 2012, 2013 Apple Inc. All rights reserved.
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

#include "config.h"
#include "core/html/HTMLMediaElement.h"

#include "bindings/core/v8/ExceptionMessages.h"
#include "bindings/core/v8/ExceptionState.h"
#include "bindings/core/v8/ExceptionStatePlaceholder.h"
#include "bindings/core/v8/ScriptController.h"
#include "core/HTMLNames.h"
#include "core/css/MediaList.h"
#include "core/dom/Attribute.h"
#include "core/dom/ElementTraversal.h"
#include "core/dom/ExceptionCode.h"
#include "core/events/Event.h"
#include "core/frame/LocalFrame.h"
#include "core/frame/Settings.h"
#include "core/frame/UseCounter.h"
#include "core/html/HTMLMediaSource.h"
#include "core/html/HTMLSourceElement.h"
#include "core/html/MediaError.h"
#include "core/html/MediaFragmentURIParser.h"
#include "core/html/TimeRanges.h"
#include "core/rendering/RenderVideo.h"
#include "core/rendering/RenderView.h"
#include "core/rendering/compositing/RenderLayerCompositor.h"
#include "platform/ContentType.h"
#include "platform/Language.h"
#include "platform/Logging.h"
#include "platform/MIMETypeFromURL.h"
#include "platform/MIMETypeRegistry.h"
#include "platform/NotImplemented.h"
#include "platform/RuntimeEnabledFeatures.h"
#include "platform/UserGestureIndicator.h"
#include "platform/graphics/GraphicsLayer.h"
#include "public/platform/Platform.h"
#include "wtf/CurrentTime.h"
#include "wtf/MathExtras.h"
#include "wtf/NonCopyingSort.h"
#include "wtf/Uint8Array.h"
#include "wtf/text/CString.h"
#include <limits>

using blink::WebMediaPlayer;
using blink::WebMimeRegistry;
using blink::WebMediaPlayerClient;

namespace blink {

#if !LOG_DISABLED
static String urlForLoggingMedia(const KURL& url)
{
    static const unsigned maximumURLLengthForLogging = 128;

    if (url.string().length() < maximumURLLengthForLogging)
        return url.string();
    return url.string().substring(0, maximumURLLengthForLogging) + "...";
}

static const char* boolString(bool val)
{
    return val ? "true" : "false";
}
#endif

#ifndef LOG_MEDIA_EVENTS
// Default to not logging events because so many are generated they can overwhelm the rest of
// the logging.
#define LOG_MEDIA_EVENTS 0
#endif

#ifndef LOG_CACHED_TIME_WARNINGS
// Default to not logging warnings about excessive drift in the cached media time because it adds a
// fair amount of overhead and logging.
#define LOG_CACHED_TIME_WARNINGS 0
#endif

typedef HashSet<RawPtr<HTMLMediaElement> > WeakMediaElementSet;
typedef HashMap<RawPtr<Document>, WeakMediaElementSet> DocumentElementSetMap;
static DocumentElementSetMap& documentToElementSetMap()
{
    DEFINE_STATIC_LOCAL(OwnPtr<DocumentElementSetMap>, map, (adoptPtr(new DocumentElementSetMap())));
    return *map;
}

static void addElementToDocumentMap(HTMLMediaElement* element, Document* document)
{
    DocumentElementSetMap& map = documentToElementSetMap();
    WeakMediaElementSet set = map.take(document);
    set.add(element);
    map.add(document, set);
}

static void removeElementFromDocumentMap(HTMLMediaElement* element, Document* document)
{
    DocumentElementSetMap& map = documentToElementSetMap();
    WeakMediaElementSet set = map.take(document);
    set.remove(element);
    if (!set.isEmpty())
        map.add(document, set);
}

static bool canLoadURL(const KURL& url, const ContentType& contentType, const String& keySystem)
{
    DEFINE_STATIC_LOCAL(const String, codecs, ("codecs"));

    String contentMIMEType = contentType.type().lower();
    String contentTypeCodecs = contentType.parameter(codecs);

    // If the MIME type is missing or is not meaningful, try to figure it out from the URL.
    if (contentMIMEType.isEmpty() || contentMIMEType == "application/octet-stream" || contentMIMEType == "text/plain") {
        if (url.protocolIsData())
            contentMIMEType = mimeTypeFromDataURL(url.string());
    }

    // If no MIME type is specified, always attempt to load.
    if (contentMIMEType.isEmpty())
        return true;

    // 4.8.10.3 MIME types - In the absence of a specification to the contrary, the MIME type "application/octet-stream"
    // when used with parameters, e.g. "application/octet-stream;codecs=theora", is a type that the user agent knows
    // it cannot render.
    if (contentMIMEType != "application/octet-stream" || contentTypeCodecs.isEmpty()) {
        WebMimeRegistry::SupportsType supported = blink::Platform::current()->mimeRegistry()->supportsMediaMIMEType(contentMIMEType, contentTypeCodecs, keySystem.lower());
        return supported > WebMimeRegistry::IsNotSupported;
    }

    return false;
}

WebMimeRegistry::SupportsType HTMLMediaElement::supportsType(const ContentType& contentType, const String& keySystem)
{
    DEFINE_STATIC_LOCAL(const String, codecs, ("codecs"));

    if (!RuntimeEnabledFeatures::mediaEnabled())
        return WebMimeRegistry::IsNotSupported;

    String type = contentType.type().lower();
    // The codecs string is not lower-cased because MP4 values are case sensitive
    // per http://tools.ietf.org/html/rfc4281#page-7.
    String typeCodecs = contentType.parameter(codecs);
    String system = keySystem.lower();

    if (type.isEmpty())
        return WebMimeRegistry::IsNotSupported;

    // 4.8.10.3 MIME types - The canPlayType(type) method must return the empty string if type is a type that the
    // user agent knows it cannot render or is the type "application/octet-stream"
    if (type == "application/octet-stream")
        return WebMimeRegistry::IsNotSupported;

    return blink::Platform::current()->mimeRegistry()->supportsMediaMIMEType(type, typeCodecs, system);
}

HTMLMediaElement::HTMLMediaElement(const QualifiedName& tagName, Document& document)
    : HTMLElement(tagName, document)
    , ActiveDOMObject(&document)
    , m_loadTimer(this, &HTMLMediaElement::loadTimerFired)
    , m_progressEventTimer(this, &HTMLMediaElement::progressEventTimerFired)
    , m_playbackProgressTimer(this, &HTMLMediaElement::playbackProgressTimerFired)
    , m_playedTimeRanges()
    , m_asyncEventQueue(GenericEventQueue::create(this))
    , m_playbackRate(1.0f)
    , m_defaultPlaybackRate(1.0f)
    , m_networkState(NETWORK_EMPTY)
    , m_readyState(HAVE_NOTHING)
    , m_readyStateMaximum(HAVE_NOTHING)
    , m_volume(1.0f)
    , m_lastSeekTime(0)
    , m_previousProgressTime(std::numeric_limits<double>::max())
    , m_duration(std::numeric_limits<double>::quiet_NaN())
    , m_lastTimeUpdateEventWallTime(0)
    , m_lastTimeUpdateEventMovieTime(std::numeric_limits<double>::max())
    , m_loadState(WaitingForSource)
    , m_deferredLoadState(NotDeferred)
    , m_deferredLoadTimer(this, &HTMLMediaElement::deferredLoadTimerFired)
    , m_webLayer(0)
    , m_preload(MediaPlayer::Auto)
    , m_displayMode(Unknown)
    , m_cachedTime(MediaPlayer::invalidTime())
    , m_fragmentStartTime(MediaPlayer::invalidTime())
    , m_fragmentEndTime(MediaPlayer::invalidTime())
    , m_pendingActionFlags(0)
    , m_userGestureRequiredForPlay(false)
    , m_playing(false)
    , m_shouldDelayLoadEvent(false)
    , m_haveFiredLoadedData(false)
    , m_active(true)
    , m_autoplaying(true)
    , m_muted(false)
    , m_paused(true)
    , m_seeking(false)
    , m_sentStalledEvent(false)
    , m_sentEndEvent(false)
    , m_pausedInternal(false)
    , m_closedCaptionsVisible(false)
    , m_completelyLoaded(false)
    , m_havePreparedToPlay(false)
    , m_processingPreferenceChange(false)
#if ENABLE(OILPAN)
    , m_isFinalizing(false)
    , m_closeMediaSourceWhenFinalizing(false)
#endif
{
    ASSERT(RuntimeEnabledFeatures::mediaEnabled());

    WTF_LOG(Media, "HTMLMediaElement::HTMLMediaElement");
    ScriptWrappable::init(this);

    if (document.settings() && document.settings()->mediaPlaybackRequiresUserGesture())
        m_userGestureRequiredForPlay = true;

    setHasCustomStyleCallbacks();
    addElementToDocumentMap(this, &document);
}

HTMLMediaElement::~HTMLMediaElement()
{
    WTF_LOG(Media, "HTMLMediaElement::~HTMLMediaElement");

#if ENABLE(OILPAN)
    // If the HTMLMediaElement dies with the document we are not
    // allowed to touch the document to adjust delay load event counts
    // because the document could have been already
    // destructed. However, if the HTMLMediaElement dies with the
    // document there is no need to change the delayed load counts
    // because no load event will fire anyway. If the document is
    // still alive we do have to decrement the load delay counts. We
    // determine if the document is alive via the ActiveDOMObject
    // which is a context lifecycle observer. If the Document has been
    // destructed ActiveDOMObject::executionContext() returns 0.
    if (ActiveDOMObject::executionContext())
        setShouldDelayLoadEvent(false);
#else
    // HTMLMediaElement and m_asyncEventQueue always become unreachable
    // together. So HTMLMediaElemenet and m_asyncEventQueue are destructed in
    // the same GC. We don't need to close it explicitly in Oilpan.
    m_asyncEventQueue->close();

    setShouldDelayLoadEvent(false);
#endif

#if ENABLE(OILPAN)
    if (m_closeMediaSourceWhenFinalizing)
        closeMediaSource();
#else
    closeMediaSource();

    removeElementFromDocumentMap(this, &document());
#endif

    // Destroying the player may cause a resource load to be canceled,
    // which could result in userCancelledLoad() being called back.
    // Setting m_completelyLoaded ensures that such a call will not cause
    // us to dispatch an abort event, which would result in a crash.
    // See http://crbug.com/233654 for more details.
    m_completelyLoaded = true;

    // With Oilpan load events on the Document are always delayed during
    // sweeping so we don't need to explicitly increment and decrement
    // load event delay counts.
#if !ENABLE(OILPAN)
    // Destroying the player may cause a resource load to be canceled,
    // which could result in Document::dispatchWindowLoadEvent() being
    // called via ResourceFetch::didLoadResource() then
    // FrameLoader::loadDone(). To prevent load event dispatching during
    // object destruction, we use Document::incrementLoadEventDelayCount().
    // See http://crbug.com/275223 for more details.
    document().incrementLoadEventDelayCount();
#endif

#if ENABLE(OILPAN)
    // Oilpan: the player must be released, but the player object
    // cannot safely access this player client any longer as parts of
    // it may have been finalized already (like the media element's
    // supplementable table.)  Handled for now by entering an
    // is-finalizing state, which is explicitly checked for if the
    // player tries to access the media element during shutdown.
    //
    // FIXME: Oilpan: move the media player to the heap instead and
    // avoid having to finalize it from here; this whole #if block
    // could then be removed (along with the state bit it depends on.)
    // crbug.com/378229
    m_isFinalizing = true;
#endif

    clearMediaPlayerAndAudioSourceProviderClientWithoutLocking();

#if !ENABLE(OILPAN)
    document().decrementLoadEventDelayCount();
#endif
}

#if ENABLE(OILPAN)
void HTMLMediaElement::setCloseMediaSourceWhenFinalizing()
{
    ASSERT(!m_closeMediaSourceWhenFinalizing);
    m_closeMediaSourceWhenFinalizing = true;
}
#endif

void HTMLMediaElement::didMoveToNewDocument(Document& oldDocument)
{
    WTF_LOG(Media, "HTMLMediaElement::didMoveToNewDocument");

    if (m_shouldDelayLoadEvent) {
        document().incrementLoadEventDelayCount();
        // Note: Keeping the load event delay count increment on oldDocument that was added
        // when m_shouldDelayLoadEvent was set so that destruction of m_player can not
        // cause load event dispatching in oldDocument.
    } else {
        // Incrementing the load event delay count so that destruction of m_player can not
        // cause load event dispatching in oldDocument.
        oldDocument.incrementLoadEventDelayCount();
    }

    removeElementFromDocumentMap(this, &oldDocument);
    addElementToDocumentMap(this, &document());

    // FIXME: This is a temporary fix to prevent this object from causing the
    // MediaPlayer to dereference LocalFrame and FrameLoader pointers from the
    // previous document. A proper fix would provide a mechanism to allow this
    // object to refresh the MediaPlayer's LocalFrame and FrameLoader references on
    // document changes so that playback can be resumed properly.
    userCancelledLoad();

    // Decrement the load event delay count on oldDocument now that m_player has been destroyed
    // and there is no risk of dispatching a load event from within the destructor.
    oldDocument.decrementLoadEventDelayCount();

    ActiveDOMObject::didMoveToNewExecutionContext(&document());
    HTMLElement::didMoveToNewDocument(oldDocument);
}

bool HTMLMediaElement::isMouseFocusable() const
{
    return false;
}

void HTMLMediaElement::parseAttribute(const QualifiedName& name, const AtomicString& value)
{
    if (name == HTMLNames::srcAttr) {
        // Trigger a reload, as long as the 'src' attribute is present.
        if (!value.isNull()) {
            clearMediaPlayer(LoadMediaResource);
            scheduleDelayedAction(LoadMediaResource);
        }
    } else if (name == HTMLNames::preloadAttr) {
        if (equalIgnoringCase(value, "none"))
            m_preload = MediaPlayer::None;
        else if (equalIgnoringCase(value, "metadata"))
            m_preload = MediaPlayer::MetaData;
        else {
            // The spec does not define an "invalid value default" but "auto" is suggested as the
            // "missing value default", so use it for everything except "none" and "metadata"
            m_preload = MediaPlayer::Auto;
        }

        // The attribute must be ignored if the autoplay attribute is present
        if (!autoplay() && m_player)
            setPlayerPreload();
    }

    HTMLElement::parseAttribute(name, value);
}

void HTMLMediaElement::finishParsingChildren()
{
    HTMLElement::finishParsingChildren();
}

bool HTMLMediaElement::rendererIsNeeded(const RenderStyle& style)
{
    // FIXME(sky): Can we delete this method?
    return false;
}

RenderObject* HTMLMediaElement::createRenderer(RenderStyle*)
{
    return new RenderMedia(this);
}

Node::InsertionNotificationRequest HTMLMediaElement::insertedInto(ContainerNode* insertionPoint)
{
    WTF_LOG(Media, "HTMLMediaElement::insertedInto");

    HTMLElement::insertedInto(insertionPoint);
    if (insertionPoint->inDocument()) {
        m_active = true;

        if (!getAttribute(HTMLNames::srcAttr).isEmpty() && m_networkState == NETWORK_EMPTY)
            scheduleDelayedAction(LoadMediaResource);
    }

    return InsertionShouldCallDidNotifySubtreeInsertions;
}

void HTMLMediaElement::didNotifySubtreeInsertionsToDocument()
{
}

void HTMLMediaElement::removedFrom(ContainerNode* insertionPoint)
{
    WTF_LOG(Media, "HTMLMediaElement::removedFrom");

    m_active = false;
    if (insertionPoint->inDocument() && insertionPoint->document().isActive()) {
        if (m_networkState > NETWORK_EMPTY)
            pause();
    }

    HTMLElement::removedFrom(insertionPoint);
}

void HTMLMediaElement::attach(const AttachContext& context)
{
    HTMLElement::attach(context);

    if (renderer())
        renderer()->updateFromElement();
}

void HTMLMediaElement::didRecalcStyle(StyleRecalcChange)
{
    if (renderer())
        renderer()->updateFromElement();
}

void HTMLMediaElement::scheduleDelayedAction(DelayedActionType actionType)
{
    WTF_LOG(Media, "HTMLMediaElement::scheduleDelayedAction");

    if ((actionType & LoadMediaResource) && !(m_pendingActionFlags & LoadMediaResource)) {
        prepareForLoad();
        m_pendingActionFlags |= LoadMediaResource;
    }

    if (!m_loadTimer.isActive())
        m_loadTimer.startOneShot(0, FROM_HERE);
}

void HTMLMediaElement::scheduleNextSourceChild()
{
    // Schedule the timer to try the next <source> element WITHOUT resetting state ala prepareForLoad.
    m_pendingActionFlags |= LoadMediaResource;
    m_loadTimer.startOneShot(0, FROM_HERE);
}

void HTMLMediaElement::scheduleEvent(const AtomicString& eventName)
{
    scheduleEvent(Event::createCancelable(eventName));
}

void HTMLMediaElement::scheduleEvent(PassRefPtr<Event> event)
{
#if LOG_MEDIA_EVENTS
    WTF_LOG(Media, "HTMLMediaElement::scheduleEvent - scheduling '%s'", event->type().ascii().data());
#endif
    m_asyncEventQueue->enqueueEvent(event);
}

void HTMLMediaElement::loadTimerFired(Timer<HTMLMediaElement>*)
{
    if (m_pendingActionFlags & LoadMediaResource) {
        if (m_loadState == LoadingFromSourceElement)
            loadNextSourceChild();
        else
            loadInternal();
    }

    m_pendingActionFlags = 0;
}

PassRefPtr<MediaError> HTMLMediaElement::error() const
{
    return m_error;
}

void HTMLMediaElement::setSrc(const AtomicString& url)
{
    setAttribute(HTMLNames::srcAttr, url);
}

HTMLMediaElement::NetworkState HTMLMediaElement::networkState() const
{
    return m_networkState;
}

String HTMLMediaElement::canPlayType(const String& mimeType, const String& keySystem) const
{
    if (!keySystem.isNull())
        UseCounter::count(document(), UseCounter::CanPlayTypeKeySystem);

    WebMimeRegistry::SupportsType support = supportsType(ContentType(mimeType), keySystem);
    String canPlay;

    // 4.8.10.3
    switch (support)
    {
        case WebMimeRegistry::IsNotSupported:
            canPlay = emptyString();
            break;
        case WebMimeRegistry::MayBeSupported:
            canPlay = "maybe";
            break;
        case WebMimeRegistry::IsSupported:
            canPlay = "probably";
            break;
    }

    WTF_LOG(Media, "HTMLMediaElement::canPlayType(%s, %s) -> %s", mimeType.utf8().data(), keySystem.utf8().data(), canPlay.utf8().data());

    return canPlay;
}

void HTMLMediaElement::load()
{
    WTF_LOG(Media, "HTMLMediaElement::load()");

    if (UserGestureIndicator::processingUserGesture())
        m_userGestureRequiredForPlay = false;

    prepareForLoad();
    loadInternal();
    prepareToPlay();
}

void HTMLMediaElement::prepareForLoad()
{
    WTF_LOG(Media, "HTMLMediaElement::prepareForLoad");

    // Perform the cleanup required for the resource load algorithm to run.
    stopPeriodicTimers();
    m_loadTimer.stop();
    cancelDeferredLoad();
    // FIXME: Figure out appropriate place to reset LoadTextTrackResource if necessary and set m_pendingActionFlags to 0 here.
    m_pendingActionFlags &= ~LoadMediaResource;
    m_sentEndEvent = false;
    m_sentStalledEvent = false;
    m_haveFiredLoadedData = false;
    m_completelyLoaded = false;
    m_havePreparedToPlay = false;
    m_displayMode = Unknown;

    // 1 - Abort any already-running instance of the resource selection algorithm for this element.
    m_loadState = WaitingForSource;
    m_currentSourceNode = nullptr;

    // 2 - If there are any tasks from the media element's media element event task source in
    // one of the task queues, then remove those tasks.
    cancelPendingEventsAndCallbacks();

    // 3 - If the media element's networkState is set to NETWORK_LOADING or NETWORK_IDLE, queue
    // a task to fire a simple event named abort at the media element.
    if (m_networkState == NETWORK_LOADING || m_networkState == NETWORK_IDLE)
        scheduleEvent(EventTypeNames::abort);

    createMediaPlayer();

    // 4 - If the media element's networkState is not set to NETWORK_EMPTY, then run these substeps
    if (m_networkState != NETWORK_EMPTY) {
        // 4.1 - Queue a task to fire a simple event named emptied at the media element.
        scheduleEvent(EventTypeNames::emptied);

        // 4.2 - If a fetching process is in progress for the media element, the user agent should stop it.
        m_networkState = NETWORK_EMPTY;

        // 4.3 - Forget the media element's media-resource-specific tracks.
        // FIXME(sky): We have no tracks.

        // 4.4 - If readyState is not set to HAVE_NOTHING, then set it to that state.
        m_readyState = HAVE_NOTHING;
        m_readyStateMaximum = HAVE_NOTHING;

        // 4.5 - If the paused attribute is false, then set it to true.
        m_paused = true;

        // 4.6 - If seeking is true, set it to false.
        m_seeking = false;

        // 4.7 - Set the current playback position to 0.
        //       Set the official playback position to 0.
        //       If this changed the official playback position, then queue a task to fire a simple event named timeupdate at the media element.
        // FIXME: Add support for firing this event.

        // 4.8 - Set the initial playback position to 0.
        // FIXME: Make this less subtle. The position only becomes 0 because the ready state is HAVE_NOTHING.
        invalidateCachedTime();

        // 4.9 - Set the timeline offset to Not-a-Number (NaN).
        // 4.10 - Update the duration attribute to Not-a-Number (NaN).
    }

    // 5 - Set the playbackRate attribute to the value of the defaultPlaybackRate attribute.
    setPlaybackRate(defaultPlaybackRate());

    // 6 - Set the error attribute to null and the autoplaying flag to true.
    m_error = nullptr;
    m_autoplaying = true;

    // 7 - Invoke the media element's resource selection algorithm.

    // 8 - Note: Playback of any previously playing media resource for this element stops.

    // The resource selection algorithm
    // 1 - Set the networkState to NETWORK_NO_SOURCE
    m_networkState = NETWORK_NO_SOURCE;

    // 2 - Asynchronously await a stable state.

    m_playedTimeRanges = TimeRanges::create();

    // FIXME: Investigate whether these can be moved into m_networkState != NETWORK_EMPTY block above
    // so they are closer to the relevant spec steps.
    m_lastSeekTime = 0;
    m_duration = std::numeric_limits<double>::quiet_NaN();

    // The spec doesn't say to block the load event until we actually run the asynchronous section
    // algorithm, but do it now because we won't start that until after the timer fires and the
    // event may have already fired by then.
    setShouldDelayLoadEvent(true);
}

void HTMLMediaElement::loadInternal()
{
    selectMediaResource();
}

void HTMLMediaElement::selectMediaResource()
{
    WTF_LOG(Media, "HTMLMediaElement::selectMediaResource");

    enum Mode { attribute, children };

    // 3 - If the media element has a src attribute, then let mode be attribute.
    Mode mode = attribute;
    if (!hasAttribute(HTMLNames::srcAttr)) {
        // Otherwise, if the media element does not have a src attribute but has a source
        // element child, then let mode be children and let candidate be the first such
        // source element child in tree order.
        if (HTMLSourceElement* element = Traversal<HTMLSourceElement>::firstChild(*this)) {
            mode = children;
            m_nextChildNodeToConsider = element;
            m_currentSourceNode = nullptr;
        } else {
            // Otherwise the media element has neither a src attribute nor a source element
            // child: set the networkState to NETWORK_EMPTY, and abort these steps; the
            // synchronous section ends.
            m_loadState = WaitingForSource;
            setShouldDelayLoadEvent(false);
            m_networkState = NETWORK_EMPTY;

            WTF_LOG(Media, "HTMLMediaElement::selectMediaResource, nothing to load");
            return;
        }
    }

    // 4 - Set the media element's delaying-the-load-event flag to true (this delays the load event),
    // and set its networkState to NETWORK_LOADING.
    setShouldDelayLoadEvent(true);
    m_networkState = NETWORK_LOADING;

    // 5 - Queue a task to fire a simple event named loadstart at the media element.
    scheduleEvent(EventTypeNames::loadstart);

    // 6 - If mode is attribute, then run these substeps
    if (mode == attribute) {
        m_loadState = LoadingFromSrcAttr;

        // If the src attribute's value is the empty string ... jump down to the failed step below
        KURL mediaURL = getNonEmptyURLAttribute(HTMLNames::srcAttr);
        if (mediaURL.isEmpty()) {
            mediaLoadingFailed(WebMediaPlayer::NetworkStateFormatError);
            WTF_LOG(Media, "HTMLMediaElement::selectMediaResource, empty 'src'");
            return;
        }

        if (!isSafeToLoadURL(mediaURL, Complain)) {
            mediaLoadingFailed(WebMediaPlayer::NetworkStateFormatError);
            return;
        }

        // No type or key system information is available when the url comes
        // from the 'src' attribute so MediaPlayer
        // will have to pick a media engine based on the file extension.
        ContentType contentType((String()));
        loadResource(mediaURL, contentType, String());
        WTF_LOG(Media, "HTMLMediaElement::selectMediaResource, using 'src' attribute url");
        return;
    }

    // Otherwise, the source elements will be used
    loadNextSourceChild();
}

void HTMLMediaElement::loadNextSourceChild()
{
    ContentType contentType((String()));
    String keySystem;
    KURL mediaURL = selectNextSourceChild(&contentType, &keySystem, Complain);
    if (!mediaURL.isValid()) {
        waitForSourceChange();
        return;
    }

    // Recreate the media player for the new url
    createMediaPlayer();

    m_loadState = LoadingFromSourceElement;
    loadResource(mediaURL, contentType, keySystem);
}

void HTMLMediaElement::loadResource(const KURL& url, ContentType& contentType, const String& keySystem)
{
    ASSERT(isSafeToLoadURL(url, Complain));

    WTF_LOG(Media, "HTMLMediaElement::loadResource(%s, %s, %s)", urlForLoggingMedia(url).utf8().data(), contentType.raw().utf8().data(), keySystem.utf8().data());

    LocalFrame* frame = document().frame();
    if (!frame) {
        mediaLoadingFailed(WebMediaPlayer::NetworkStateFormatError);
        return;
    }

    // The resource fetch algorithm
    m_networkState = NETWORK_LOADING;

    // Set m_currentSrc *before* changing to the cache url, the fact that we are loading from the app
    // cache is an internal detail not exposed through the media element API.
    m_currentSrc = url;

    WTF_LOG(Media, "HTMLMediaElement::loadResource - m_currentSrc -> %s", urlForLoggingMedia(m_currentSrc).utf8().data());

    startProgressEventTimer();

    // Reset display mode to force a recalculation of what to show because we are resetting the player.
    setDisplayMode(Unknown);

    if (!autoplay())
        setPlayerPreload();

    if (hasAttribute(HTMLNames::mutedAttr))
        m_muted = true;
    updateVolume();

    ASSERT(!m_mediaSource);

    bool attemptLoad = true;

    if (attemptLoad && canLoadURL(url, contentType, keySystem)) {
        ASSERT(!webMediaPlayer());

        if (!m_havePreparedToPlay && !autoplay() && m_preload == MediaPlayer::None) {
            WTF_LOG(Media, "HTMLMediaElement::loadResource : Delaying load because preload == 'none'");
            deferLoad();
        } else {
            startPlayerLoad();
        }
    } else {
        mediaLoadingFailed(WebMediaPlayer::NetworkStateFormatError);
    }

    // If there is no poster to display, allow the media engine to render video frames as soon as
    // they are available.
    updateDisplayState();

    if (renderer())
        renderer()->updateFromElement();
}

void HTMLMediaElement::startPlayerLoad()
{
    // Filter out user:pass as those two URL components aren't
    // considered for media resource fetches (including for the CORS
    // use-credentials mode.) That behavior aligns with Gecko, with IE
    // being more restrictive and not allowing fetches to such URLs.
    //
    // Spec reference: http://whatwg.org/c/#concept-media-load-resource
    //
    // FIXME: when the HTML spec switches to specifying resource
    // fetches in terms of Fetch (http://fetch.spec.whatwg.org), and
    // along with that potentially also specifying a setting for its
    // 'authentication flag' to control how user:pass embedded in a
    // media resource URL should be treated, then update the handling
    // here to match.
    KURL requestURL = m_currentSrc;
    if (!requestURL.user().isEmpty())
        requestURL.setUser(String());
    if (!requestURL.pass().isEmpty())
        requestURL.setPass(String());

    m_player->load(loadType(), requestURL, corsMode());
}

void HTMLMediaElement::setPlayerPreload()
{
    m_player->setPreload(m_preload);

    if (loadIsDeferred() && m_preload != MediaPlayer::None)
        startDeferredLoad();
}

bool HTMLMediaElement::loadIsDeferred() const
{
    return m_deferredLoadState != NotDeferred;
}

void HTMLMediaElement::deferLoad()
{
    // This implements the "optional" step 3 from the resource fetch algorithm.
    ASSERT(!m_deferredLoadTimer.isActive());
    ASSERT(m_deferredLoadState == NotDeferred);
    // 1. Set the networkState to NETWORK_IDLE.
    // 2. Queue a task to fire a simple event named suspend at the element.
    changeNetworkStateFromLoadingToIdle();
    // 3. Queue a task to set the element's delaying-the-load-event
    // flag to false. This stops delaying the load event.
    m_deferredLoadTimer.startOneShot(0, FROM_HERE);
    // 4. Wait for the task to be run.
    m_deferredLoadState = WaitingForStopDelayingLoadEventTask;
    // Continued in executeDeferredLoad().
}

void HTMLMediaElement::cancelDeferredLoad()
{
    m_deferredLoadTimer.stop();
    m_deferredLoadState = NotDeferred;
}

void HTMLMediaElement::executeDeferredLoad()
{
    ASSERT(m_deferredLoadState >= WaitingForTrigger);

    // resource fetch algorithm step 3 - continued from deferLoad().

    // 5. Wait for an implementation-defined event (e.g. the user requesting that the media element begin playback).
    // This is assumed to be whatever 'event' ended up calling this method.
    cancelDeferredLoad();
    // 6. Set the element's delaying-the-load-event flag back to true (this
    // delays the load event again, in case it hasn't been fired yet).
    setShouldDelayLoadEvent(true);
    // 7. Set the networkState to NETWORK_LOADING.
    m_networkState = NETWORK_LOADING;

    startProgressEventTimer();

    startPlayerLoad();
}

void HTMLMediaElement::startDeferredLoad()
{
    if (m_deferredLoadState == WaitingForTrigger) {
        executeDeferredLoad();
        return;
    }
    ASSERT(m_deferredLoadState == WaitingForStopDelayingLoadEventTask);
    m_deferredLoadState = ExecuteOnStopDelayingLoadEventTask;
}

void HTMLMediaElement::deferredLoadTimerFired(Timer<HTMLMediaElement>*)
{
    setShouldDelayLoadEvent(false);

    if (m_deferredLoadState == ExecuteOnStopDelayingLoadEventTask) {
        executeDeferredLoad();
        return;
    }
    ASSERT(m_deferredLoadState == WaitingForStopDelayingLoadEventTask);
    m_deferredLoadState = WaitingForTrigger;
}

WebMediaPlayer::LoadType HTMLMediaElement::loadType() const
{
    if (m_mediaSource)
        return WebMediaPlayer::LoadTypeMediaSource;

    return WebMediaPlayer::LoadTypeURL;
}

bool HTMLMediaElement::isSafeToLoadURL(const KURL& url, InvalidURLAction actionIfInvalid)
{
    if (!url.isValid()) {
        WTF_LOG(Media, "HTMLMediaElement::isSafeToLoadURL(%s) -> FALSE because url is invalid", urlForLoggingMedia(url).utf8().data());
        return false;
    }

    return true;
}

void HTMLMediaElement::startProgressEventTimer()
{
    if (m_progressEventTimer.isActive())
        return;

    m_previousProgressTime = WTF::currentTime();
    // 350ms is not magic, it is in the spec!
    m_progressEventTimer.startRepeating(0.350, FROM_HERE);
}

void HTMLMediaElement::waitForSourceChange()
{
    WTF_LOG(Media, "HTMLMediaElement::waitForSourceChange");

    stopPeriodicTimers();
    m_loadState = WaitingForSource;

    // 6.17 - Waiting: Set the element's networkState attribute to the NETWORK_NO_SOURCE value
    m_networkState = NETWORK_NO_SOURCE;

    // 6.18 - Set the element's delaying-the-load-event flag to false. This stops delaying the load event.
    setShouldDelayLoadEvent(false);

    updateDisplayState();

    if (renderer())
        renderer()->updateFromElement();
}

void HTMLMediaElement::noneSupported()
{
    WTF_LOG(Media, "HTMLMediaElement::noneSupported");

    stopPeriodicTimers();
    m_loadState = WaitingForSource;
    m_currentSourceNode = nullptr;

    // 4.8.10.5
    // 6 - Reaching this step indicates that the media resource failed to load or that the given
    // URL could not be resolved. In one atomic operation, run the following steps:

    // 6.1 - Set the error attribute to a new MediaError object whose code attribute is set to
    // MEDIA_ERR_SRC_NOT_SUPPORTED.
    m_error = MediaError::create(MediaError::MEDIA_ERR_SRC_NOT_SUPPORTED);

    // 6.2 - Forget the media element's media-resource-specific text tracks.
    // FIXME(sky): We have no tracks.

    // 6.3 - Set the element's networkState attribute to the NETWORK_NO_SOURCE value.
    m_networkState = NETWORK_NO_SOURCE;

    // 7 - Queue a task to fire a simple event named error at the media element.
    scheduleEvent(EventTypeNames::error);

    closeMediaSource();

    // 8 - Set the element's delaying-the-load-event flag to false. This stops delaying the load event.
    setShouldDelayLoadEvent(false);

    // 9 - Abort these steps. Until the load() method is invoked or the src attribute is changed,
    // the element won't attempt to load another resource.

    updateDisplayState();

    if (renderer())
        renderer()->updateFromElement();
}

void HTMLMediaElement::mediaEngineError(PassRefPtr<MediaError> err)
{
    ASSERT(m_readyState >= HAVE_METADATA);
    WTF_LOG(Media, "HTMLMediaElement::mediaEngineError(%d)", static_cast<int>(err->code()));

    // 1 - The user agent should cancel the fetching process.
    stopPeriodicTimers();
    m_loadState = WaitingForSource;

    // 2 - Set the error attribute to a new MediaError object whose code attribute is
    // set to MEDIA_ERR_NETWORK/MEDIA_ERR_DECODE.
    m_error = err;

    // 3 - Queue a task to fire a simple event named error at the media element.
    scheduleEvent(EventTypeNames::error);

    // 4 - Set the element's networkState attribute to the NETWORK_IDLE value.
    m_networkState = NETWORK_IDLE;

    // 5 - Set the element's delaying-the-load-event flag to false. This stops delaying the load event.
    setShouldDelayLoadEvent(false);

    // 6 - Abort the overall resource selection algorithm.
    m_currentSourceNode = nullptr;
}

void HTMLMediaElement::cancelPendingEventsAndCallbacks()
{
    WTF_LOG(Media, "HTMLMediaElement::cancelPendingEventsAndCallbacks");
    m_asyncEventQueue->cancelAllEvents();

    for (HTMLSourceElement* source = Traversal<HTMLSourceElement>::firstChild(*this); source; source = Traversal<HTMLSourceElement>::nextSibling(*source))
        source->cancelPendingErrorEvent();
}

void HTMLMediaElement::mediaPlayerNetworkStateChanged()
{
    setNetworkState(webMediaPlayer()->networkState());
}

void HTMLMediaElement::mediaLoadingFailed(WebMediaPlayer::NetworkState error)
{
    stopPeriodicTimers();

    // If we failed while trying to load a <source> element, the movie was never parsed, and there are more
    // <source> children, schedule the next one
    if (m_readyState < HAVE_METADATA && m_loadState == LoadingFromSourceElement) {

        // resource selection algorithm
        // Step 9.Otherwise.9 - Failed with elements: Queue a task, using the DOM manipulation task source, to fire a simple event named error at the candidate element.
        if (m_currentSourceNode)
            m_currentSourceNode->scheduleErrorEvent();
        else
            WTF_LOG(Media, "HTMLMediaElement::setNetworkState - error event not sent, <source> was removed");

        // 9.Otherwise.10 - Asynchronously await a stable state. The synchronous section consists of all the remaining steps of this algorithm until the algorithm says the synchronous section has ended.

        // 9.Otherwise.11 - Forget the media element's media-resource-specific tracks.
        // FIXME(sky): We have no tracks.

        if (havePotentialSourceChild()) {
            WTF_LOG(Media, "HTMLMediaElement::setNetworkState - scheduling next <source>");
            scheduleNextSourceChild();
        } else {
            WTF_LOG(Media, "HTMLMediaElement::setNetworkState - no more <source> elements, waiting");
            waitForSourceChange();
        }

        return;
    }

    if (error == WebMediaPlayer::NetworkStateNetworkError && m_readyState >= HAVE_METADATA)
        mediaEngineError(MediaError::create(MediaError::MEDIA_ERR_NETWORK));
    else if (error == WebMediaPlayer::NetworkStateDecodeError)
        mediaEngineError(MediaError::create(MediaError::MEDIA_ERR_DECODE));
    else if ((error == WebMediaPlayer::NetworkStateFormatError
        || error == WebMediaPlayer::NetworkStateNetworkError)
        && m_loadState == LoadingFromSrcAttr)
        noneSupported();

    updateDisplayState();
}

void HTMLMediaElement::setNetworkState(WebMediaPlayer::NetworkState state)
{
    WTF_LOG(Media, "HTMLMediaElement::setNetworkState(%d) - current state is %d", static_cast<int>(state), static_cast<int>(m_networkState));

    if (state == WebMediaPlayer::NetworkStateEmpty) {
        // Just update the cached state and leave, we can't do anything.
        m_networkState = NETWORK_EMPTY;
        return;
    }

    if (state == WebMediaPlayer::NetworkStateFormatError
        || state == WebMediaPlayer::NetworkStateNetworkError
        || state == WebMediaPlayer::NetworkStateDecodeError) {
        mediaLoadingFailed(state);
        return;
    }

    if (state == WebMediaPlayer::NetworkStateIdle) {
        if (m_networkState > NETWORK_IDLE) {
            changeNetworkStateFromLoadingToIdle();
            setShouldDelayLoadEvent(false);
        } else {
            m_networkState = NETWORK_IDLE;
        }
    }

    if (state == WebMediaPlayer::NetworkStateLoading) {
        if (m_networkState < NETWORK_LOADING || m_networkState == NETWORK_NO_SOURCE)
            startProgressEventTimer();
        m_networkState = NETWORK_LOADING;
    }

    if (state == WebMediaPlayer::NetworkStateLoaded) {
        if (m_networkState != NETWORK_IDLE)
            changeNetworkStateFromLoadingToIdle();
        m_completelyLoaded = true;
    }
}

void HTMLMediaElement::changeNetworkStateFromLoadingToIdle()
{
    ASSERT(m_player);
    m_progressEventTimer.stop();

    // Schedule one last progress event so we guarantee that at least one is fired
    // for files that load very quickly.
    if (webMediaPlayer() && webMediaPlayer()->didLoadingProgress())
        scheduleEvent(EventTypeNames::progress);
    scheduleEvent(EventTypeNames::suspend);
    m_networkState = NETWORK_IDLE;
}

void HTMLMediaElement::mediaPlayerReadyStateChanged()
{
    setReadyState(static_cast<ReadyState>(webMediaPlayer()->readyState()));
}

void HTMLMediaElement::setReadyState(ReadyState state)
{
    WTF_LOG(Media, "HTMLMediaElement::setReadyState(%d) - current state is %d,", static_cast<int>(state), static_cast<int>(m_readyState));

    // Set "wasPotentiallyPlaying" BEFORE updating m_readyState, potentiallyPlaying() uses it
    bool wasPotentiallyPlaying = potentiallyPlaying();

    ReadyState oldState = m_readyState;
    ReadyState newState = state;

    if (newState == oldState)
        return;

    m_readyState = newState;

    if (oldState > m_readyStateMaximum)
        m_readyStateMaximum = oldState;

    if (m_networkState == NETWORK_EMPTY)
        return;

    if (m_seeking) {
        // 4.8.10.9, step 9 note: If the media element was potentially playing immediately before
        // it started seeking, but seeking caused its readyState attribute to change to a value
        // lower than HAVE_FUTURE_DATA, then a waiting will be fired at the element.
        if (wasPotentiallyPlaying && m_readyState < HAVE_FUTURE_DATA)
            scheduleEvent(EventTypeNames::waiting);

        // 4.8.10.9 steps 12-14
        if (m_readyState >= HAVE_CURRENT_DATA)
            finishSeek();
    } else {
        if (wasPotentiallyPlaying && m_readyState < HAVE_FUTURE_DATA) {
            // 4.8.10.8
            scheduleTimeupdateEvent(false);
            scheduleEvent(EventTypeNames::waiting);
        }
    }

    if (m_readyState >= HAVE_METADATA && oldState < HAVE_METADATA) {
        prepareMediaFragmentURI();

        m_duration = duration();
        scheduleEvent(EventTypeNames::durationchange);

        if (isHTMLVideoElement())
            scheduleEvent(EventTypeNames::resize);
        scheduleEvent(EventTypeNames::loadedmetadata);
        if (renderer())
            renderer()->updateFromElement();
    }

    bool shouldUpdateDisplayState = false;

    if (m_readyState >= HAVE_CURRENT_DATA && oldState < HAVE_CURRENT_DATA && !m_haveFiredLoadedData) {
        m_haveFiredLoadedData = true;
        shouldUpdateDisplayState = true;
        scheduleEvent(EventTypeNames::loadeddata);
        setShouldDelayLoadEvent(false);
        applyMediaFragmentURI();
    }

    bool isPotentiallyPlaying = potentiallyPlaying();
    if (m_readyState == HAVE_FUTURE_DATA && oldState <= HAVE_CURRENT_DATA) {
        scheduleEvent(EventTypeNames::canplay);
        if (isPotentiallyPlaying)
            scheduleEvent(EventTypeNames::playing);
        shouldUpdateDisplayState = true;
    }

    if (m_readyState == HAVE_ENOUGH_DATA && oldState < HAVE_ENOUGH_DATA) {
        if (oldState <= HAVE_CURRENT_DATA) {
            scheduleEvent(EventTypeNames::canplay);
            if (isPotentiallyPlaying)
                scheduleEvent(EventTypeNames::playing);
        }

        if (m_autoplaying && m_paused && autoplay() && !m_userGestureRequiredForPlay) {
            m_paused = false;
            invalidateCachedTime();
            scheduleEvent(EventTypeNames::play);
            scheduleEvent(EventTypeNames::playing);
        }

        scheduleEvent(EventTypeNames::canplaythrough);

        shouldUpdateDisplayState = true;
    }

    if (shouldUpdateDisplayState)
        updateDisplayState();

    updatePlayState();
}

void HTMLMediaElement::progressEventTimerFired(Timer<HTMLMediaElement>*)
{
    ASSERT(m_player);
    if (m_networkState != NETWORK_LOADING)
        return;

    double time = WTF::currentTime();
    double timedelta = time - m_previousProgressTime;

    if (webMediaPlayer() && webMediaPlayer()->didLoadingProgress()) {
        scheduleEvent(EventTypeNames::progress);
        m_previousProgressTime = time;
        m_sentStalledEvent = false;
        if (renderer())
            renderer()->updateFromElement();
    } else if (timedelta > 3.0 && !m_sentStalledEvent) {
        scheduleEvent(EventTypeNames::stalled);
        m_sentStalledEvent = true;
        setShouldDelayLoadEvent(false);
    }
}

void HTMLMediaElement::addPlayedRange(double start, double end)
{
    WTF_LOG(Media, "HTMLMediaElement::addPlayedRange(%f, %f)", start, end);
    if (!m_playedTimeRanges)
        m_playedTimeRanges = TimeRanges::create();
    m_playedTimeRanges->add(start, end);
}

bool HTMLMediaElement::supportsSave() const
{
    return webMediaPlayer() && webMediaPlayer()->supportsSave();
}

void HTMLMediaElement::prepareToPlay()
{
    WTF_LOG(Media, "HTMLMediaElement::prepareToPlay(%p)", this);
    if (m_havePreparedToPlay)
        return;
    m_havePreparedToPlay = true;

    if (loadIsDeferred())
        startDeferredLoad();
}

void HTMLMediaElement::seek(double time, ExceptionState& exceptionState)
{
    WTF_LOG(Media, "HTMLMediaElement::seek(%f)", time);

    // 4.8.10.9 Seeking

    // 1 - If the media element's readyState is HAVE_NOTHING, then raise an InvalidStateError exception.
    if (m_readyState == HAVE_NOTHING) {
        exceptionState.throwDOMException(InvalidStateError, "The element's readyState is HAVE_NOTHING.");
        return;
    }

    // If the media engine has been told to postpone loading data, let it go ahead now.
    if (m_preload < MediaPlayer::Auto && m_readyState < HAVE_FUTURE_DATA)
        prepareToPlay();

    // Get the current time before setting m_seeking, m_lastSeekTime is returned once it is set.
    refreshCachedTime();
    double now = currentTime();

    // 2 - If the element's seeking IDL attribute is true, then another instance of this algorithm is
    // already running. Abort that other instance of the algorithm without waiting for the step that
    // it is running to complete.
    // Nothing specific to be done here.

    // 3 - Set the seeking IDL attribute to true.
    // The flag will be cleared when the engine tells us the time has actually changed.
    bool previousSeekStillPending = m_seeking;
    m_seeking = true;

    // 5 - If the new playback position is later than the end of the media resource, then let it be the end
    // of the media resource instead.
    time = std::min(time, duration());

    // 6 - If the new playback position is less than the earliest possible position, let it be that position instead.
    time = std::max(time, 0.0);

    // Ask the media engine for the time value in the movie's time scale before comparing with current time. This
    // is necessary because if the seek time is not equal to currentTime but the delta is less than the movie's
    // time scale, we will ask the media engine to "seek" to the current movie time, which may be a noop and
    // not generate a timechanged callback. This means m_seeking will never be cleared and we will never
    // fire a 'seeked' event.
    double mediaTime = webMediaPlayer()->mediaTimeForTimeValue(time);
    if (time != mediaTime) {
        WTF_LOG(Media, "HTMLMediaElement::seek(%f) - media timeline equivalent is %f", time, mediaTime);
        time = mediaTime;
    }

    // 7 - If the (possibly now changed) new playback position is not in one of the ranges given in the
    // seekable attribute, then let it be the position in one of the ranges given in the seekable attribute
    // that is the nearest to the new playback position. ... If there are no ranges given in the seekable
    // attribute then set the seeking IDL attribute to false and abort these steps.
    RefPtr<TimeRanges> seekableRanges = seekable();

    // Short circuit seeking to the current time by just firing the events if no seek is required.
    // Don't skip calling the media engine if we are in poster mode because a seek should always
    // cancel poster display.
    bool noSeekRequired = !seekableRanges->length() || (time == now && displayMode() != Poster);

    if (noSeekRequired) {
        if (time == now) {
            scheduleEvent(EventTypeNames::seeking);
            if (previousSeekStillPending)
                return;
            // FIXME: There must be a stable state before timeupdate+seeked are dispatched and seeking
            // is reset to false. See http://crbug.com/266631
            scheduleTimeupdateEvent(false);
            scheduleEvent(EventTypeNames::seeked);
        }
        m_seeking = false;
        return;
    }
    time = seekableRanges->nearest(time);

    if (m_playing) {
        if (m_lastSeekTime < now)
            addPlayedRange(m_lastSeekTime, now);
    }
    m_lastSeekTime = time;
    m_sentEndEvent = false;

    // 8 - Queue a task to fire a simple event named seeking at the element.
    scheduleEvent(EventTypeNames::seeking);

    // 9 - Set the current playback position to the given new playback position
    webMediaPlayer()->seek(time);

    // 10-14 are handled, if necessary, when the engine signals a readystate change or otherwise
    // satisfies seek completion and signals a time change.
}

void HTMLMediaElement::finishSeek()
{
    WTF_LOG(Media, "HTMLMediaElement::finishSeek");

    // 4.8.10.9 Seeking completion
    // 12 - Set the seeking IDL attribute to false.
    m_seeking = false;

    // 13 - Queue a task to fire a simple event named timeupdate at the element.
    scheduleTimeupdateEvent(false);

    // 14 - Queue a task to fire a simple event named seeked at the element.
    scheduleEvent(EventTypeNames::seeked);

    setDisplayMode(Video);
}

HTMLMediaElement::ReadyState HTMLMediaElement::readyState() const
{
    return m_readyState;
}

bool HTMLMediaElement::hasAudio() const
{
    return webMediaPlayer() && webMediaPlayer()->hasAudio();
}

bool HTMLMediaElement::seeking() const
{
    return m_seeking;
}

void HTMLMediaElement::refreshCachedTime() const
{
    if (!webMediaPlayer() || m_readyState < HAVE_METADATA)
        return;

    m_cachedTime = webMediaPlayer()->currentTime();
}

void HTMLMediaElement::invalidateCachedTime()
{
    WTF_LOG(Media, "HTMLMediaElement::invalidateCachedTime");
    m_cachedTime = MediaPlayer::invalidTime();
}

// playback state
double HTMLMediaElement::currentTime() const
{
    if (m_readyState == HAVE_NOTHING)
        return 0;

    if (m_seeking) {
        WTF_LOG(Media, "HTMLMediaElement::currentTime - seeking, returning %f", m_lastSeekTime);
        return m_lastSeekTime;
    }

    if (m_cachedTime != MediaPlayer::invalidTime() && m_paused) {
#if LOG_CACHED_TIME_WARNINGS
        static const double minCachedDeltaForWarning = 0.01;
        double delta = m_cachedTime - webMediaPlayer()->currentTime();
        if (delta > minCachedDeltaForWarning)
            WTF_LOG(Media, "HTMLMediaElement::currentTime - WARNING, cached time is %f seconds off of media time when paused", delta);
#endif
        return m_cachedTime;
    }

    refreshCachedTime();

    return m_cachedTime;
}

void HTMLMediaElement::setCurrentTime(double time, ExceptionState& exceptionState)
{
    seek(time, exceptionState);
}

double HTMLMediaElement::duration() const
{
    // FIXME: remove m_player check once we figure out how m_player is going
    // out of sync with readystate. m_player is cleared but readystate is not set
    // to HAVE_NOTHING
    if (!m_player || m_readyState < HAVE_METADATA)
        return std::numeric_limits<double>::quiet_NaN();

    // FIXME: Refactor so m_duration is kept current (in both MSE and
    // non-MSE cases) once we have transitioned from HAVE_NOTHING ->
    // HAVE_METADATA. Currently, m_duration may be out of date for at least MSE
    // case because MediaSource and SourceBuffer do not notify the element
    // directly upon duration changes caused by endOfStream, remove, or append
    // operations; rather the notification is triggered by the WebMediaPlayer
    // implementation observing that the underlying engine has updated duration
    // and notifying the element to consult its MediaSource for current
    // duration. See http://crbug.com/266644

    if (m_mediaSource)
        return m_mediaSource->duration();

    return webMediaPlayer()->duration();
}

bool HTMLMediaElement::paused() const
{
    return m_paused;
}

double HTMLMediaElement::defaultPlaybackRate() const
{
    return m_defaultPlaybackRate;
}

void HTMLMediaElement::setDefaultPlaybackRate(double rate)
{
    if (m_defaultPlaybackRate == rate)
        return;

    m_defaultPlaybackRate = rate;
    scheduleEvent(EventTypeNames::ratechange);
}

double HTMLMediaElement::playbackRate() const
{
    return m_playbackRate;
}

void HTMLMediaElement::setPlaybackRate(double rate)
{
    WTF_LOG(Media, "HTMLMediaElement::setPlaybackRate(%f)", rate);

    if (m_playbackRate != rate) {
        m_playbackRate = rate;
        invalidateCachedTime();
        scheduleEvent(EventTypeNames::ratechange);
    }

    updatePlaybackRate();
}

double HTMLMediaElement::effectivePlaybackRate() const
{
    return m_playbackRate;
}

HTMLMediaElement::DirectionOfPlayback HTMLMediaElement::directionOfPlayback() const
{
    return m_playbackRate >= 0 ? Forward : Backward;
}

void HTMLMediaElement::updatePlaybackRate()
{
    double effectiveRate = effectivePlaybackRate();
    if (m_player && potentiallyPlaying())
        webMediaPlayer()->setRate(effectiveRate);
}

bool HTMLMediaElement::ended() const
{
    // 4.8.10.8 Playing the media resource
    // The ended attribute must return true if the media element has ended
    // playback and the direction of playback is forwards, and false otherwise.
    return endedPlayback() && directionOfPlayback() == Forward;
}

bool HTMLMediaElement::autoplay() const
{
    return hasAttribute(HTMLNames::autoplayAttr);
}

String HTMLMediaElement::preload() const
{
    switch (m_preload) {
    case MediaPlayer::None:
        return "none";
        break;
    case MediaPlayer::MetaData:
        return "metadata";
        break;
    case MediaPlayer::Auto:
        return "auto";
        break;
    }

    ASSERT_NOT_REACHED();
    return String();
}

void HTMLMediaElement::setPreload(const AtomicString& preload)
{
    WTF_LOG(Media, "HTMLMediaElement::setPreload(%s)", preload.utf8().data());
    setAttribute(HTMLNames::preloadAttr, preload);
}

void HTMLMediaElement::play()
{
    WTF_LOG(Media, "HTMLMediaElement::play()");

    if (m_userGestureRequiredForPlay && !UserGestureIndicator::processingUserGesture())
        return;
    if (UserGestureIndicator::processingUserGesture())
        m_userGestureRequiredForPlay = false;

    playInternal();
}

void HTMLMediaElement::playInternal()
{
    WTF_LOG(Media, "HTMLMediaElement::playInternal");

    // 4.8.10.9. Playing the media resource
    if (!m_player || m_networkState == NETWORK_EMPTY)
        scheduleDelayedAction(LoadMediaResource);

    if (endedPlayback())
        seek(0, IGNORE_EXCEPTION);

    if (m_paused) {
        m_paused = false;
        invalidateCachedTime();
        scheduleEvent(EventTypeNames::play);

        if (m_readyState <= HAVE_CURRENT_DATA)
            scheduleEvent(EventTypeNames::waiting);
        else if (m_readyState >= HAVE_FUTURE_DATA)
            scheduleEvent(EventTypeNames::playing);
    }
    m_autoplaying = false;

    updatePlayState();
}

void HTMLMediaElement::pause()
{
    WTF_LOG(Media, "HTMLMediaElement::pause()");

    if (!m_player || m_networkState == NETWORK_EMPTY)
        scheduleDelayedAction(LoadMediaResource);

    m_autoplaying = false;

    if (!m_paused) {
        m_paused = true;
        scheduleTimeupdateEvent(false);
        scheduleEvent(EventTypeNames::pause);
    }

    updatePlayState();
}

void HTMLMediaElement::closeMediaSource()
{
    if (!m_mediaSource)
        return;

    m_mediaSource->close();
    m_mediaSource = nullptr;
}

bool HTMLMediaElement::loop() const
{
    return hasAttribute(HTMLNames::loopAttr);
}

void HTMLMediaElement::setLoop(bool b)
{
    WTF_LOG(Media, "HTMLMediaElement::setLoop(%s)", boolString(b));
    setBooleanAttribute(HTMLNames::loopAttr, b);
}

double HTMLMediaElement::volume() const
{
    return m_volume;
}

void HTMLMediaElement::setVolume(double vol, ExceptionState& exceptionState)
{
    WTF_LOG(Media, "HTMLMediaElement::setVolume(%f)", vol);

    if (m_volume == vol)
        return;

    if (vol < 0.0f || vol > 1.0f) {
        exceptionState.throwDOMException(IndexSizeError, ExceptionMessages::indexOutsideRange("volume", vol, 0.0, ExceptionMessages::InclusiveBound, 1.0, ExceptionMessages::InclusiveBound));
        return;
    }

    m_volume = vol;
    updateVolume();
    scheduleEvent(EventTypeNames::volumechange);
}

bool HTMLMediaElement::muted() const
{
    return m_muted;
}

void HTMLMediaElement::setMuted(bool muted)
{
    WTF_LOG(Media, "HTMLMediaElement::setMuted(%s)", boolString(muted));

    if (m_muted == muted)
        return;

    m_muted = muted;

    updateVolume();

    scheduleEvent(EventTypeNames::volumechange);
}

void HTMLMediaElement::updateVolume()
{
    if (webMediaPlayer())
        webMediaPlayer()->setVolume(effectiveMediaVolume());
}

double HTMLMediaElement::effectiveMediaVolume() const
{
    if (m_muted)
        return 0;

    return m_volume;
}

// The spec says to fire periodic timeupdate events (those sent while playing) every
// "15 to 250ms", we choose the slowest frequency
static const double maxTimeupdateEventFrequency = 0.25;

void HTMLMediaElement::startPlaybackProgressTimer()
{
    if (m_playbackProgressTimer.isActive())
        return;

    m_previousProgressTime = WTF::currentTime();
    m_playbackProgressTimer.startRepeating(maxTimeupdateEventFrequency, FROM_HERE);
}

void HTMLMediaElement::playbackProgressTimerFired(Timer<HTMLMediaElement>*)
{
    ASSERT(m_player);

    if (m_fragmentEndTime != MediaPlayer::invalidTime() && currentTime() >= m_fragmentEndTime && directionOfPlayback() == Forward) {
        m_fragmentEndTime = MediaPlayer::invalidTime();
        if (!m_paused) {
            UseCounter::count(document(), UseCounter::HTMLMediaElementPauseAtFragmentEnd);
            // changes paused to true and fires a simple event named pause at the media element.
            pause();
        }
    }

    if (!m_seeking)
        scheduleTimeupdateEvent(true);
}

void HTMLMediaElement::scheduleTimeupdateEvent(bool periodicEvent)
{
    double now = WTF::currentTime();
    double timedelta = now - m_lastTimeUpdateEventWallTime;

    // throttle the periodic events
    if (periodicEvent && timedelta < maxTimeupdateEventFrequency)
        return;

    // Some media engines make multiple "time changed" callbacks at the same time, but we only want one
    // event at a given time so filter here
    double movieTime = currentTime();
    if (movieTime != m_lastTimeUpdateEventMovieTime) {
        scheduleEvent(EventTypeNames::timeupdate);
        m_lastTimeUpdateEventWallTime = now;
        m_lastTimeUpdateEventMovieTime = movieTime;
    }
}

bool HTMLMediaElement::togglePlayStateWillPlay() const
{
    return paused();
}

void HTMLMediaElement::togglePlayState()
{
    if (paused())
        play();
    else
        pause();
}

bool HTMLMediaElement::havePotentialSourceChild()
{
    // Stash the current <source> node and next nodes so we can restore them after checking
    // to see there is another potential.
    RefPtr<HTMLSourceElement> currentSourceNode = m_currentSourceNode;
    RefPtr<Node> nextNode = m_nextChildNodeToConsider;

    KURL nextURL = selectNextSourceChild(0, 0, DoNothing);

    m_currentSourceNode = currentSourceNode;
    m_nextChildNodeToConsider = nextNode;

    return nextURL.isValid();
}

KURL HTMLMediaElement::selectNextSourceChild(ContentType* contentType, String* keySystem, InvalidURLAction actionIfInvalid)
{
#if !LOG_DISABLED
    // Don't log if this was just called to find out if there are any valid <source> elements.
    bool shouldLog = actionIfInvalid != DoNothing;
    if (shouldLog)
        WTF_LOG(Media, "HTMLMediaElement::selectNextSourceChild");
#endif

    if (!m_nextChildNodeToConsider) {
#if !LOG_DISABLED
        if (shouldLog)
            WTF_LOG(Media, "HTMLMediaElement::selectNextSourceChild -> 0x0000, \"\"");
#endif
        return KURL();
    }

    KURL mediaURL;
    Node* node;
    HTMLSourceElement* source = 0;
    String type;
    String system;
    bool lookingForStartNode = m_nextChildNodeToConsider;
    bool canUseSourceElement = false;

    NodeVector potentialSourceNodes;
    getChildNodes(*this, potentialSourceNodes);

    for (unsigned i = 0; !canUseSourceElement && i < potentialSourceNodes.size(); ++i) {
        node = potentialSourceNodes[i].get();
        if (lookingForStartNode && m_nextChildNodeToConsider != node)
            continue;
        lookingForStartNode = false;

        if (!isHTMLSourceElement(*node))
            continue;
        if (node->parentNode() != this)
            continue;

        source = toHTMLSourceElement(node);

        // If candidate does not have a src attribute, or if its src attribute's value is the empty string ... jump down to the failed step below
        mediaURL = source->getNonEmptyURLAttribute(HTMLNames::srcAttr);
#if !LOG_DISABLED
        if (shouldLog)
            WTF_LOG(Media, "HTMLMediaElement::selectNextSourceChild - 'src' is %s", urlForLoggingMedia(mediaURL).utf8().data());
#endif
        if (mediaURL.isEmpty())
            goto check_again;

        type = source->type();
        // FIXME(82965): Add support for keySystem in <source> and set system from source.
        if (type.isEmpty() && mediaURL.protocolIsData())
            type = mimeTypeFromDataURL(mediaURL);
        if (!type.isEmpty() || !system.isEmpty()) {
#if !LOG_DISABLED
            if (shouldLog)
                WTF_LOG(Media, "HTMLMediaElement::selectNextSourceChild - 'type' is '%s' - key system is '%s'", type.utf8().data(), system.utf8().data());
#endif
            if (!supportsType(ContentType(type), system))
                goto check_again;
        }

        // Is it safe to load this url?
        if (!isSafeToLoadURL(mediaURL, actionIfInvalid))
            goto check_again;

        // Making it this far means the <source> looks reasonable.
        canUseSourceElement = true;

check_again:
        if (!canUseSourceElement && actionIfInvalid == Complain && source)
            source->scheduleErrorEvent();
    }

    if (canUseSourceElement) {
        if (contentType)
            *contentType = ContentType(type);
        if (keySystem)
            *keySystem = system;
        m_currentSourceNode = source;
        m_nextChildNodeToConsider = source->nextSibling();
    } else {
        m_currentSourceNode = nullptr;
        m_nextChildNodeToConsider = nullptr;
    }

#if !LOG_DISABLED
    if (shouldLog)
        WTF_LOG(Media, "HTMLMediaElement::selectNextSourceChild -> %p, %s", m_currentSourceNode.get(), canUseSourceElement ? urlForLoggingMedia(mediaURL).utf8().data() : "");
#endif
    return canUseSourceElement ? mediaURL : KURL();
}

void HTMLMediaElement::sourceWasAdded(HTMLSourceElement* source)
{
    WTF_LOG(Media, "HTMLMediaElement::sourceWasAdded(%p)", source);

#if !LOG_DISABLED
    KURL url = source->getNonEmptyURLAttribute(HTMLNames::srcAttr);
    WTF_LOG(Media, "HTMLMediaElement::sourceWasAdded - 'src' is %s", urlForLoggingMedia(url).utf8().data());
#endif

    // We should only consider a <source> element when there is not src attribute at all.
    if (hasAttribute(HTMLNames::srcAttr))
        return;

    // 4.8.8 - If a source element is inserted as a child of a media element that has no src
    // attribute and whose networkState has the value NETWORK_EMPTY, the user agent must invoke
    // the media element's resource selection algorithm.
    if (networkState() == HTMLMediaElement::NETWORK_EMPTY) {
        scheduleDelayedAction(LoadMediaResource);
        m_nextChildNodeToConsider = source;
        return;
    }

    if (m_currentSourceNode && source == m_currentSourceNode->nextSibling()) {
        WTF_LOG(Media, "HTMLMediaElement::sourceWasAdded - <source> inserted immediately after current source");
        m_nextChildNodeToConsider = source;
        return;
    }

    if (m_nextChildNodeToConsider)
        return;

    if (m_loadState != WaitingForSource)
        return;

    // 4.8.9.5, resource selection algorithm, source elements section:
    // 21. Wait until the node after pointer is a node other than the end of the list. (This step might wait forever.)
    // 22. Asynchronously await a stable state...
    // 23. Set the element's delaying-the-load-event flag back to true (this delays the load event again, in case
    // it hasn't been fired yet).
    setShouldDelayLoadEvent(true);

    // 24. Set the networkState back to NETWORK_LOADING.
    m_networkState = NETWORK_LOADING;

    // 25. Jump back to the find next candidate step above.
    m_nextChildNodeToConsider = source;
    scheduleNextSourceChild();
}

void HTMLMediaElement::sourceWasRemoved(HTMLSourceElement* source)
{
    WTF_LOG(Media, "HTMLMediaElement::sourceWasRemoved(%p)", source);

#if !LOG_DISABLED
    KURL url = source->getNonEmptyURLAttribute(HTMLNames::srcAttr);
    WTF_LOG(Media, "HTMLMediaElement::sourceWasRemoved - 'src' is %s", urlForLoggingMedia(url).utf8().data());
#endif

    if (source != m_currentSourceNode && source != m_nextChildNodeToConsider)
        return;

    if (source == m_nextChildNodeToConsider) {
        if (m_currentSourceNode)
            m_nextChildNodeToConsider = m_currentSourceNode->nextSibling();
        WTF_LOG(Media, "HTMLMediaElement::sourceRemoved - m_nextChildNodeToConsider set to %p", m_nextChildNodeToConsider.get());
    } else if (source == m_currentSourceNode) {
        // Clear the current source node pointer, but don't change the movie as the spec says:
        // 4.8.8 - Dynamically modifying a source element and its attribute when the element is already
        // inserted in a video or audio element will have no effect.
        m_currentSourceNode = nullptr;
        WTF_LOG(Media, "HTMLMediaElement::sourceRemoved - m_currentSourceNode set to 0");
    }
}

void HTMLMediaElement::mediaPlayerTimeChanged()
{
    WTF_LOG(Media, "HTMLMediaElement::mediaPlayerTimeChanged");

    invalidateCachedTime();

    // 4.8.10.9 steps 12-14. Needed if no ReadyState change is associated with the seek.
    if (m_seeking && m_readyState >= HAVE_CURRENT_DATA && !webMediaPlayer()->seeking())
        finishSeek();

    // Always call scheduleTimeupdateEvent when the media engine reports a time discontinuity,
    // it will only queue a 'timeupdate' event if we haven't already posted one at the current
    // movie time.
    scheduleTimeupdateEvent(false);

    double now = currentTime();
    double dur = duration();

    // When the current playback position reaches the end of the media resource when the direction of
    // playback is forwards, then the user agent must follow these steps:
    if (!std::isnan(dur) && dur && now >= dur && directionOfPlayback() == Forward) {
        // If the media element has a loop attribute specified and does not have a current media controller,
        if (loop()) {
            m_sentEndEvent = false;
            //  then seek to the earliest possible position of the media resource and abort these steps.
            seek(0, IGNORE_EXCEPTION);
        } else {
            // If the media element does not have a current media controller, and the media element
            // has still ended playback, and the direction of playback is still forwards, and paused
            // is false,
            if (!m_paused) {
                // changes paused to true and fires a simple event named pause at the media element.
                m_paused = true;
                scheduleEvent(EventTypeNames::pause);
            }
            // Queue a task to fire a simple event named ended at the media element.
            if (!m_sentEndEvent) {
                m_sentEndEvent = true;
                scheduleEvent(EventTypeNames::ended);
            }
        }
    }
    else
        m_sentEndEvent = false;

    updatePlayState();
}

void HTMLMediaElement::mediaPlayerDurationChanged()
{
    WTF_LOG(Media, "HTMLMediaElement::mediaPlayerDurationChanged");
    // FIXME: Change MediaPlayerClient & WebMediaPlayer to convey
    // the currentTime when the duration change occured. The current
    // WebMediaPlayer implementations always clamp currentTime() to
    // duration() so the requestSeek condition here is always false.
    durationChanged(duration(), currentTime() > duration());
}

void HTMLMediaElement::durationChanged(double duration, bool requestSeek)
{
    WTF_LOG(Media, "HTMLMediaElement::durationChanged(%f, %d)", duration, requestSeek);

    // Abort if duration unchanged.
    if (m_duration == duration)
        return;

    WTF_LOG(Media, "HTMLMediaElement::durationChanged : %f -> %f", m_duration, duration);
    m_duration = duration;
    scheduleEvent(EventTypeNames::durationchange);

    if (renderer())
        renderer()->updateFromElement();

    if (requestSeek)
        seek(duration, IGNORE_EXCEPTION);
}

void HTMLMediaElement::mediaPlayerPlaybackStateChanged()
{
    WTF_LOG(Media, "HTMLMediaElement::mediaPlayerPlaybackStateChanged");

    if (!m_player || m_pausedInternal)
        return;

    if (webMediaPlayer()->paused())
        pause();
    else
        playInternal();
}

void HTMLMediaElement::mediaPlayerRequestFullscreen()
{
    // FIXME(sky): How do we go full screen now?
}

void HTMLMediaElement::mediaPlayerRequestSeek(double time)
{
    setCurrentTime(time, IGNORE_EXCEPTION);
}

// MediaPlayerPresentation methods
void HTMLMediaElement::mediaPlayerRepaint()
{
    if (m_webLayer)
        m_webLayer->invalidate();

    updateDisplayState();
    if (renderer())
        renderer()->setShouldDoFullPaintInvalidation(true);
}

void HTMLMediaElement::mediaPlayerSizeChanged()
{
    WTF_LOG(Media, "HTMLMediaElement::mediaPlayerSizeChanged");

    ASSERT(hasVideo()); // "resize" makes no sense absent video.
    if (m_readyState > HAVE_NOTHING && isHTMLVideoElement())
        scheduleEvent(EventTypeNames::resize);

    if (renderer())
        renderer()->updateFromElement();
}

PassRefPtr<TimeRanges> HTMLMediaElement::buffered() const
{
    if (m_mediaSource)
        return m_mediaSource->buffered();

    if (!webMediaPlayer())
        return TimeRanges::create();

    return TimeRanges::create(webMediaPlayer()->buffered());
}

PassRefPtr<TimeRanges> HTMLMediaElement::played()
{
    if (m_playing) {
        double time = currentTime();
        if (time > m_lastSeekTime)
            addPlayedRange(m_lastSeekTime, time);
    }

    if (!m_playedTimeRanges)
        m_playedTimeRanges = TimeRanges::create();

    return m_playedTimeRanges->copy();
}

PassRefPtr<TimeRanges> HTMLMediaElement::seekable() const
{
    if (webMediaPlayer()) {
        double maxTimeSeekable = webMediaPlayer()->maxTimeSeekable();
        if (maxTimeSeekable)
            return TimeRanges::create(0, maxTimeSeekable);
    }
    return TimeRanges::create();
}

bool HTMLMediaElement::potentiallyPlaying() const
{
    // "pausedToBuffer" means the media engine's rate is 0, but only because it had to stop playing
    // when it ran out of buffered data. A movie is this state is "potentially playing", modulo the
    // checks in couldPlayIfEnoughData().
    bool pausedToBuffer = m_readyStateMaximum >= HAVE_FUTURE_DATA && m_readyState < HAVE_FUTURE_DATA;
    return (pausedToBuffer || m_readyState >= HAVE_FUTURE_DATA) && couldPlayIfEnoughData();
}

bool HTMLMediaElement::couldPlayIfEnoughData() const
{
    return !paused() && !endedPlayback() && !stoppedDueToErrors();
}

bool HTMLMediaElement::endedPlayback() const
{
    double dur = duration();
    if (!m_player || std::isnan(dur))
        return false;

    // 4.8.10.8 Playing the media resource

    // A media element is said to have ended playback when the element's
    // readyState attribute is HAVE_METADATA or greater,
    if (m_readyState < HAVE_METADATA)
        return false;

    // and the current playback position is the end of the media resource and the direction
    // of playback is forwards, Either the media element does not have a loop attribute specified,
    // or the media element has a current media controller.
    double now = currentTime();
    if (directionOfPlayback() == Forward)
        return dur > 0 && now >= dur && !loop();

    // or the current playback position is the earliest possible position and the direction
    // of playback is backwards
    ASSERT(directionOfPlayback() == Backward);
    return now <= 0;
}

bool HTMLMediaElement::stoppedDueToErrors() const
{
    if (m_readyState >= HAVE_METADATA && m_error) {
        RefPtr<TimeRanges> seekableRanges = seekable();
        if (!seekableRanges->contain(currentTime()))
            return true;
    }

    return false;
}

void HTMLMediaElement::updatePlayState()
{
    if (!m_player)
        return;

    bool isPlaying = webMediaPlayer() && !webMediaPlayer()->paused();
    if (m_pausedInternal) {
        if (isPlaying)
            webMediaPlayer()->pause();
        refreshCachedTime();
        m_playbackProgressTimer.stop();
        return;
    }

    bool shouldBePlaying = potentiallyPlaying();

    WTF_LOG(Media, "HTMLMediaElement::updatePlayState - shouldBePlaying = %s, isPlaying = %s",
        boolString(shouldBePlaying), boolString(isPlaying));

    if (shouldBePlaying) {
        setDisplayMode(Video);
        invalidateCachedTime();

        if (!isPlaying) {
            // Set rate, muted before calling play in case they were set before the media engine was setup.
            // The media engine should just stash the rate and muted values since it isn't already playing.
            webMediaPlayer()->setRate(effectivePlaybackRate());
            updateVolume();
            webMediaPlayer()->play();
        }

        startPlaybackProgressTimer();
        m_playing = true;

    } else { // Should not be playing right now
        if (isPlaying)
            webMediaPlayer()->pause();
        refreshCachedTime();

        m_playbackProgressTimer.stop();
        m_playing = false;
        double time = currentTime();
        if (time > m_lastSeekTime)
            addPlayedRange(m_lastSeekTime, time);

        if (couldPlayIfEnoughData())
            prepareToPlay();
    }

    if (renderer())
        renderer()->updateFromElement();
}

void HTMLMediaElement::setPausedInternal(bool b)
{
    m_pausedInternal = b;
    updatePlayState();
}

void HTMLMediaElement::stopPeriodicTimers()
{
    m_progressEventTimer.stop();
    m_playbackProgressTimer.stop();
}

void HTMLMediaElement::userCancelledLoad()
{
    WTF_LOG(Media, "HTMLMediaElement::userCancelledLoad");

    // If the media data fetching process is aborted by the user:

    // 1 - The user agent should cancel the fetching process.
    clearMediaPlayer(-1);

    if (m_networkState == NETWORK_EMPTY || m_completelyLoaded)
        return;

    // 2 - Set the error attribute to a new MediaError object whose code attribute is set to MEDIA_ERR_ABORTED.
    m_error = MediaError::create(MediaError::MEDIA_ERR_ABORTED);

    // 3 - Queue a task to fire a simple event named error at the media element.
    scheduleEvent(EventTypeNames::abort);

    closeMediaSource();

    // 4 - If the media element's readyState attribute has a value equal to HAVE_NOTHING, set the
    // element's networkState attribute to the NETWORK_EMPTY value and queue a task to fire a
    // simple event named emptied at the element. Otherwise, set the element's networkState
    // attribute to the NETWORK_IDLE value.
    if (m_readyState == HAVE_NOTHING) {
        m_networkState = NETWORK_EMPTY;
        scheduleEvent(EventTypeNames::emptied);
    }
    else
        m_networkState = NETWORK_IDLE;

    // 5 - Set the element's delaying-the-load-event flag to false. This stops delaying the load event.
    setShouldDelayLoadEvent(false);

    // 6 - Abort the overall resource selection algorithm.
    m_currentSourceNode = nullptr;

    // Reset m_readyState since m_player is gone.
    m_readyState = HAVE_NOTHING;
    invalidateCachedTime();
}

void HTMLMediaElement::clearMediaPlayerAndAudioSourceProviderClientWithoutLocking()
{
    m_player.clear();
}

void HTMLMediaElement::clearMediaPlayer(int flags)
{
    closeMediaSource();

    cancelDeferredLoad();
    clearMediaPlayerAndAudioSourceProviderClientWithoutLocking();

    stopPeriodicTimers();
    m_loadTimer.stop();

    m_pendingActionFlags &= ~flags;
    m_loadState = WaitingForSource;
}

void HTMLMediaElement::stop()
{
    WTF_LOG(Media, "HTMLMediaElement::stop");

    m_active = false;
    userCancelledLoad();

    // Stop the playback without generating events
    m_playing = false;
    setPausedInternal(true);

    if (renderer())
        renderer()->updateFromElement();

    stopPeriodicTimers();
    cancelPendingEventsAndCallbacks();

    m_asyncEventQueue->close();
}

bool HTMLMediaElement::hasPendingActivity() const
{
    return (hasAudio() && isPlaying()) || m_asyncEventQueue->hasPendingEvents();
}

void HTMLMediaElement::contextDestroyed()
{
    ActiveDOMObject::contextDestroyed();
}

bool HTMLMediaElement::isFullscreen() const
{
    // FIXME(sky): How does video go full screen now?
    return false;
}

void HTMLMediaElement::enterFullscreen()
{
}

void HTMLMediaElement::exitFullscreen()
{
}

blink::WebLayer* HTMLMediaElement::platformLayer() const
{
    return m_webLayer;
}

bool HTMLMediaElement::isURLAttribute(const Attribute& attribute) const
{
    return attribute.name() == HTMLNames::srcAttr || HTMLElement::isURLAttribute(attribute);
}

void HTMLMediaElement::setShouldDelayLoadEvent(bool shouldDelay)
{
    if (m_shouldDelayLoadEvent == shouldDelay)
        return;

    WTF_LOG(Media, "HTMLMediaElement::setShouldDelayLoadEvent(%s)", boolString(shouldDelay));

    m_shouldDelayLoadEvent = shouldDelay;
    if (shouldDelay)
        document().incrementLoadEventDelayCount();
    else
        document().decrementLoadEventDelayCount();
}

void* HTMLMediaElement::preDispatchEventHandler(Event* event)
{
    return 0;
}

void HTMLMediaElement::createMediaPlayer()
{
    closeMediaSource();
    m_player = MediaPlayer::create(this);
}

const AtomicString& HTMLMediaElement::mediaGroup() const
{
    return getAttribute(HTMLNames::mediagroupAttr);
}

bool HTMLMediaElement::isBlocked() const
{
    // A media element is a blocked media element if its readyState attribute is in the
    // HAVE_NOTHING state, the HAVE_METADATA state, or the HAVE_CURRENT_DATA state,
    // or if the element has paused for user interaction or paused for in-band content.
    if (m_readyState <= HAVE_CURRENT_DATA)
        return true;

    return false;
}

void HTMLMediaElement::prepareMediaFragmentURI()
{
    MediaFragmentURIParser fragmentParser(m_currentSrc);
    double dur = duration();

    double start = fragmentParser.startTime();
    if (start != MediaFragmentURIParser::invalidTimeValue() && start > 0) {
        m_fragmentStartTime = start;
        if (m_fragmentStartTime > dur)
            m_fragmentStartTime = dur;
    } else
        m_fragmentStartTime = MediaPlayer::invalidTime();

    double end = fragmentParser.endTime();
    if (end != MediaFragmentURIParser::invalidTimeValue() && end > 0 && end > m_fragmentStartTime) {
        m_fragmentEndTime = end;
        if (m_fragmentEndTime > dur)
            m_fragmentEndTime = dur;
    } else
        m_fragmentEndTime = MediaPlayer::invalidTime();

    if (m_fragmentStartTime != MediaPlayer::invalidTime() && m_readyState < HAVE_FUTURE_DATA)
        prepareToPlay();
}

void HTMLMediaElement::applyMediaFragmentURI()
{
    if (m_fragmentStartTime != MediaPlayer::invalidTime()) {
        m_sentEndEvent = false;
        UseCounter::count(document(), UseCounter::HTMLMediaElementSeekToFragmentStart);
        seek(m_fragmentStartTime, IGNORE_EXCEPTION);
    }
}

WebMediaPlayer::CORSMode HTMLMediaElement::corsMode() const
{
    const AtomicString& crossOriginMode = getAttribute(HTMLNames::crossoriginAttr);
    if (crossOriginMode.isNull())
        return WebMediaPlayer::CORSModeUnspecified;
    if (equalIgnoringCase(crossOriginMode, "use-credentials"))
        return WebMediaPlayer::CORSModeUseCredentials;
    return WebMediaPlayer::CORSModeAnonymous;
}

void HTMLMediaElement::mediaPlayerSetWebLayer(blink::WebLayer* webLayer)
{
    if (webLayer == m_webLayer)
        return;

    // If either of the layers is null we need to enable or disable compositing. This is done by triggering a style recalc.
    if (!m_webLayer || !webLayer)
        setNeedsCompositingUpdate();

    if (m_webLayer)
        GraphicsLayer::unregisterContentsLayer(m_webLayer);
    m_webLayer = webLayer;
    if (m_webLayer) {
        GraphicsLayer::registerContentsLayer(m_webLayer);
    }
}

void HTMLMediaElement::mediaPlayerMediaSourceOpened(blink::WebMediaSource* webMediaSource)
{
    m_mediaSource->setWebMediaSourceAndOpen(adoptPtr(webMediaSource));
}

bool HTMLMediaElement::isInteractiveContent() const
{
    return hasAttribute(HTMLNames::controlsAttr);
}

void HTMLMediaElement::defaultEventHandler(Event* event)
{
    HTMLElement::defaultEventHandler(event);
}

}
