// Copyright (c) 2009, Google Inc.
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//     * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//     * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#include "config.h"
#include "bindings/core/dart/DartApplicationLoader.h"

#include "core/FetchInitiatorTypeNames.h"
#include "bindings/core/dart/DartDOMWrapper.h"
#include "bindings/core/dart/DartInspectorTimeline.h"
#include "bindings/core/dart/DartScriptDebugServer.h"
#include "bindings/core/dart/DartUtilities.h"
#if defined(ENABLE_DART_NATIVE_EXTENSIONS)
#include "bindings/core/dart/shared_lib/DartNativeExtensions.h"
#endif
#include "bindings/core/v8/ScriptSourceCode.h"
#include "core/dom/Document.h"
#include "core/dom/Element.h"
#include "core/dom/ScriptLoader.h"
#include "core/dom/ScriptLoaderClient.h"
#include "core/fetch/CachedMetadata.h"
#include "core/fetch/FetchRequest.h"
#include "core/fetch/ResourceClient.h"
#include "core/fetch/ResourceFetcher.h"
#include "core/fetch/ScriptResource.h"
#include "core/frame/LocalDOMWindow.h"
#include "core/frame/LocalFrame.h"
#include "core/html/HTMLScriptElement.h"
#include "core/inspector/ScriptCallStack.h"
#include "core/svg/SVGScriptElement.h"

#include <dart_api.h>
#include <dart_mirrors_api.h>

namespace blink {

// FIXME(vsm): Define this in a central place.
static const unsigned dartTypeID = 0xDAADDAAD;

PassRefPtr<DartScriptInfo> DartScriptInfo::create(PassRefPtr<Element> scriptElement)
{
    RefPtr<DartScriptInfo> scriptInfo = adoptRef(new DartScriptInfo(scriptElement));
    if (scriptInfo->loader())
        return scriptInfo;
    return nullptr;
}

String DartScriptInfo::sourceAttributeValue() const
{
    return m_client->sourceAttributeValue();
}

String DartScriptInfo::typeAttributeValue() const
{
    return m_client->typeAttributeValue();
}

String DartScriptInfo::scriptContent()
{
    return m_loader->scriptContent();
}

void DartScriptInfo::dispatchErrorEvent()
{
    m_loader->dispatchErrorEvent();
}

WTF::OrdinalNumber DartScriptInfo::startLineNumber()
{
    return m_loader->startLineNumber();
}

ScriptLoader* DartScriptInfo::loader()
{
    return m_loader;
}

Document* DartScriptInfo::ownerDocument()
{
    return m_element->ownerDocument();
}

String DartScriptInfo::url()
{
    String scriptURL = sourceAttributeValue();
    KURL ownerURL = ownerDocument()->url();
    return scriptURL.isEmpty() ? ownerURL : KURL(ownerURL, scriptURL);
}

DartScriptInfo::DartScriptInfo(PassRefPtr<Element> element)
{
    m_element = element;
    if (m_element->document().isHTMLDocument()) {
        HTMLScriptElement* scriptElement = static_cast<HTMLScriptElement*>(m_element.get());
        m_loader = scriptElement->loader();
        m_client = static_cast<ScriptLoaderClient*>(scriptElement);
    } else if (m_element->document().isSVGDocument()) {
        SVGScriptElement* scriptElement = static_cast<SVGScriptElement*>(m_element.get());
        m_loader = scriptElement->loader();
        m_client = static_cast<ScriptLoaderClient*>(scriptElement);
    } else {
        // Invalid script element.
        m_loader = 0;
        m_client = 0;
        m_element = nullptr;
    }
}

void DartApplicationLoader::Callback::reportError(const String& error, const String& url)
{
    m_originDocument->logExceptionToConsole(error + ": " + url, url, 0, 0, nullptr);
    if (m_scriptInfo)
        m_scriptInfo->loader()->dispatchErrorEvent();
}

ResourcePtr<ScriptResource> DartApplicationLoader::Callback::requestScript(FetchRequest& request)
{
    return m_originDocument->fetcher()->fetchScript(request);
}

Document* DartApplicationLoader::Callback::document()
{
    return m_scriptInfo ? m_scriptInfo->ownerDocument() : m_originDocument;
}

DartApplicationLoader::DartApplicationLoader(
    Document* document,
    bool domEnabled)
    : m_isolate(0)
    , m_originDocument(document)
    , m_loadCallback(nullptr)
    , m_domEnabled(domEnabled)
    , m_cacheable(false)
    , m_state(Uninitialized)
    , m_snapshotMode(SnapshotOff)
{
    ASSERT(m_originDocument);

    DEFINE_STATIC_LOCAL(String, setting, (getenv("DART_SNAPSHOT_MODE")));
    if (!setting.isNull()) {
        if (setting == "all")
            m_snapshotMode = SnapshotAll;
        else if (setting == "off")
            m_snapshotMode = SnapshotOff;
        else if (setting == "single")
            m_snapshotMode = SnapshotSingle;
        else
            DartUtilities::reportProblem(m_originDocument, String("Invalid DART_SNAPSHOT_MODE: ") + setting);
    }
}

void DartApplicationLoader::addRequest(PassRefPtr<DartScriptInfo> scriptInfo)
{
    // FIXME(vsm): Temporary support to load extra Dart libraries via HTML imports before we encounter the main
    // script. In the future, this should map to deferred loading.
    RELEASE_ASSERT(m_state == Uninitialized);
    m_htmlImportedScripts.append(scriptInfo);
}

void DartApplicationLoader::initialize(Dart_Isolate isolate, const String& scriptUrl, PassRefPtr<Callback> loadCallback)
{
    RELEASE_ASSERT(m_state == Uninitialized && !m_isolate);
    m_isolate = isolate;
    m_loadCallback = loadCallback;

    Document* document = m_loadCallback->document();
    m_scriptUrl = KURL(document->baseURL(), scriptUrl);
    m_scriptUrlString = m_scriptUrl.string();

    RELEASE_ASSERT(m_isolate == isolate);
    Dart_EnterIsolate(isolate);

    // Associate application loader with current isolate, so we can retrieve it in libraryTagHandlerCallback.
    DartDOMData::current()->setApplicationLoader(this);
    Dart_Handle ALLOW_UNUSED result = Dart_SetLibraryTagHandler(&libraryTagHandlerCallback);
    ASSERT(!Dart_IsError(result));

    // FIXME: Stay in isolate for processing below.
    Dart_ExitIsolate();
    m_state = Initialized;
}

void DartApplicationLoader::processRequests(Dart_Isolate isolate, const ScriptSourceCode& sourceCode, PassRefPtr<Callback> loadCallback)
{
    DART_START_TIMER();
    const String& scriptUrl = sourceCode.url();
    initialize(isolate, scriptUrl, loadCallback);
    DART_RECORD_TIMER("  DartApplicationLoader::initialize took");

    m_state = Fetching;

    // Check for cached snapshot.
    ScriptResource* scriptResource = sourceCode.resource();
    if (scriptResource && m_snapshotMode != SnapshotOff) {
        // This is cacheable if there is a resource we can cache the snapshot on.
        m_cacheable = true;
        CachedMetadata* cachedMetadata = scriptResource->cachedMetadata(dartTypeID);
        if (cachedMetadata) {
            loadScriptFromSnapshot(sourceCode.url(), reinterpret_cast<const uint8_t*>(cachedMetadata->data()), cachedMetadata->size());
            return;
        }
    }

    // Set up root library for main DOM isolate.
    {
        DartIsolateScope isolateScope(m_isolate);
        DartApiScope apiScope;

        ASSERT(Dart_IsNull(Dart_RootLibrary()));

        Document* document = m_loadCallback->document();
        const String& source = sourceCode.source();
        int lineNumber = sourceCode.startLine();

        // Use zero-based counting instead of one-based.
        lineNumber = (lineNumber <= 0) ? 0 : lineNumber - 1;

        String canonical = KURL(document->url(), scriptUrl).string();
        m_pendingLibraries.add(canonical);
        process(canonical, source, lineNumber);
        RELEASE_ASSERT(m_state >= Loading);
    }

    // FIXME(vsm): This will go away.
    // Load HTML imported dart scripts.
    while (!m_htmlImportedScripts.isEmpty()) {
        RefPtr<DartScriptInfo> script = m_htmlImportedScripts.takeFirst();
        const String& src = script->sourceAttributeValue();
        const String& url = script->url();
        if (src.isEmpty()) {
            // Inline script.
            ASSERT(!m_pendingLibraries.contains(url));
            m_pendingLibraries.add(url);
            intptr_t lineOffset = script->startLineNumber().zeroBasedInt();
            // Blink gives generated script tags an invalid start line.
            if (lineOffset < 0)
                lineOffset = 0;
            process(script->url(), script->scriptContent(), lineOffset);
        } else {
            // Canonicalize the src attribute url.
            String canonical = KURL(script->ownerDocument()->url(), src).string();

            // Check if this was loaded by an earlier script.
            {
                DartIsolateScope isolateScope(m_isolate);
                DartApiScope apiScope;
                Dart_Handle library = Dart_LookupLibrary(DartUtilities::safeStringToDartString(canonical));
                if (!Dart_IsError(library))
                    continue;
            }

            // Request if we don't have the script or haven't already requested it.
            if (!m_pendingLibraries.contains(canonical)) {
                m_pendingLibraries.add(canonical);
                fetchScriptResource(canonical);
            }
        }
    }

    // FIXME(vsm): Once m_htmlImportedScripts goes away, we should be able to delete this.
    // Processing HTML imports may be made the app ready without running.
    RELEASE_ASSERT(m_state == Error || m_state >= Loading);
    if (ready() && m_state == Loading) {
        m_state = Ready;
        // All dependences are in.
        m_loadCallback->ready();
    }

    DART_RECORD_TIMER("  DartApplicationLoader::processRequests took");
}

void DartApplicationLoader::processSingleRequest(Dart_Isolate isolate, const String& scriptUrl, PassRefPtr<Callback> loadCallback)
{
    initialize(isolate, scriptUrl, loadCallback);
    m_pendingLibraries.add(scriptUrl);
    m_state = Fetching;
    fetchScriptResource(scriptUrl);
}

void DartApplicationLoader::load(PassRefPtr<DartErrorEventDispatcher> errorEventDispatcher)
{
    RELEASE_ASSERT(m_state == Ready || m_state == DeferredReady);

    m_errorEventDispatcher = errorEventDispatcher;

    DartIsolateScope isolateScope(m_isolate);
    DartApiScope dartApiScope;
    bool completeFutures = false;

    // Finalize classes and complete futures if there are any deferred loads.
    if (m_state == DeferredReady) {
        // We have already invoked the entry point on the main script URL at
        // this point we will start running dart code again.
        m_state = Running;
        completeFutures = true;
    } else {
        RELEASE_ASSERT(m_state == Ready);
    }

    {
        V8Scope v8scope(DartDOMData::current());
        Dart_Handle result = Dart_FinalizeLoading(completeFutures);
        if (Dart_IsError(result)) {
            reportDartError(result);
            return;
        }
    }
    // Invoke the entry point on the main script URL if it has not yet been
    // invoked.
    if (m_state == Ready) {
        // Call the entry point on the main script URL.
        callEntryPoint();
    }
}

void DartApplicationLoader::loadScriptFromSnapshot(const String& url, const uint8_t* snapshot, intptr_t snapshotSize)
{
    DART_START_TIMER();
    RELEASE_ASSERT(m_state == Fetching);

    Timeline timeline(m_originDocument->frame(), String("loadSnapshot@") + m_scriptUrlString);
    m_scriptUrlString = url;
    DartIsolateScope isolateScope(m_isolate);
    DartApiScope apiScope;
    Dart_Handle result = Dart_LoadScriptFromSnapshot(snapshot, snapshotSize);
    if (Dart_IsError(result)) {
        reportDartError(result);
        return;
    }

    m_state = Ready;
    m_loadCallback->ready();
    DART_RECORD_TIMER("  DartApplicationLoader::loadScriptFromSnapshot took");
}

void DartApplicationLoader::callEntryPoint()
{
    RELEASE_ASSERT(m_state == Ready);

    Timeline timeline(m_originDocument->frame(), String("callEntryPoint@") + m_scriptUrlString);

    if (m_cacheable) {
        // Snapshot single-script applications.
        ResourceFetcher* loader = m_originDocument->fetcher();
        FetchRequest request(m_originDocument->completeURL(m_scriptUrlString), FetchInitiatorTypeNames::document);
        ResourcePtr<ScriptResource> scriptResource = loader->fetchScript(request);

        // Check if already snapshotted.
        if (scriptResource && !scriptResource->cachedMetadata(dartTypeID)) {
            uint8_t* buffer;
            intptr_t size;
            Dart_Handle result = Dart_CreateScriptSnapshot(&buffer, &size);
            if (Dart_IsError(result)) {
                reportDartError(result);
                // FIXME: exiting early might be not the best option if error is due to snapshot
                // creation proper (and not due to compilation), even though it's unlikely.
                // Consider other options like Dart_CompileAll.
                return;
            }

            Vector<uint8_t>* snapshot = DartDOMData::current()->applicationSnapshot();
            ASSERT(snapshot->isEmpty());
            snapshot->append(buffer, size);

            // Write the snapshot.
            scriptResource->setCachedMetadata(dartTypeID, reinterpret_cast<const char*>(buffer), size);
        }
    }

    if (m_domEnabled) {
        Timeline timeline(m_originDocument->frame(), String("notifyDebugServer@") + m_scriptUrlString);
        DartScriptDebugServer::shared().isolateLoaded();
    }

    m_state = Running;
    if (m_domEnabled) {
        V8Scope v8scope(DartDOMData::current());
        Dart_Handle mainLibrary = topLevelLibrary();

        // Trampoline to invoke main.
        // FIXME: Use the page library instead. To do this, we need to import each script tag's library into the page
        // with a unique prefix to ensure a secondary script doesn't define a main.
        String trampolineUrl = m_scriptUrlString + "$trampoline";
        Dart_Handle trampoline = Dart_LoadLibrary(DartUtilities::safeStringToDartString(trampolineUrl), Dart_NewStringFromCString(""), 0, 0);
        Dart_LibraryImportLibrary(trampoline, mainLibrary, Dart_Null());

        Dart_Handle result = Dart_FinalizeLoading(false);
        if (Dart_IsError(result)) {
            DartUtilities::reportProblem(m_originDocument, result, m_scriptUrlString);
        }

        // FIXME: Settle on proper behavior here. We have not determined exactly when
        // or how often we'll call the entry point.
        Dart_Handle entryPoint = Dart_NewStringFromCString("main");
        Dart_Handle main = Dart_LookupFunction(trampoline, entryPoint);
        if (!Dart_IsNull(main)) {
            // FIXME: Avoid relooking up main.
            Dart_Handle result = Dart_Invoke(trampoline, entryPoint, 0, 0);
            if (Dart_IsError(result)) {
                DartUtilities::reportProblem(m_originDocument, result, m_scriptUrlString);
            }
        }
    }
}

void DartApplicationLoader::validateUrlLoaded(const String& url)
{
    RELEASE_ASSERT(m_state == Running);

    DartIsolateScope isolateScope(m_isolate);
    DartApiScope apiScope;

    Dart_Handle library = Dart_LookupLibrary(DartUtilities::safeStringToDartString(url));
    if (!Dart_IsNull(library)) {
        DartUtilities::reportProblem(m_originDocument, "URL must be imported by main Dart script: " + url);
    }
}

Dart_Handle DartApplicationLoader::topLevelLibrary()
{
    Dart_Handle library = Dart_LookupLibrary(DartUtilities::safeStringToDartString(m_scriptUrlString));
    ASSERT(!Dart_IsError(library));
    return library;
}

void DartApplicationLoader::findDependences(const String& url, const String& source, intptr_t lineNumber)
{
    ASSERT(m_pendingLibraries.contains(url) || m_pendingSource.contains(url));

    DartIsolateScope isolateScope(m_isolate);
    DartApiScope dartApiScope;

    if (m_pendingLibraries.contains(url)) {
        processLibrary(url, source, lineNumber);
    } else {
        ASSERT(m_pendingSource.contains(url));
        processSource(url, source, lineNumber);
    }
}

void DartApplicationLoader::processLibrary(const String& url, const String& source, intptr_t lineNumber)
{
    ASSERT(m_pendingLibraries.contains(url));

    Dart_Handle result;
    if (m_state == Fetching) {
        // A spawned isolate.
        m_state = Loading;
        result = Dart_LoadScript(DartUtilities::safeStringToDartString(url), DartUtilities::convertSourceString(source), lineNumber, 0);
    } else {
        result = Dart_LoadLibrary(DartUtilities::safeStringToDartString(url), DartUtilities::convertSourceString(source), lineNumber, 0);
    }
    if (Dart_IsError(result))
        reportError(result, url);

    m_pendingLibraries.remove(url);
}

void DartApplicationLoader::processSource(const String& url, const String& source, intptr_t lineNumber)
{
    ASSERT(m_pendingSource.contains(url));
    HandleSet* importers = m_pendingSource.take(url);
    for (HandleSet::iterator i = importers->begin(); i != importers->end(); ++i) {
        Dart_Handle persistent = *i;
        Dart_Handle library = Dart_HandleFromPersistent(persistent);
        Dart_DeletePersistentHandle(persistent);

        Dart_Handle result = Dart_LoadSource(library, DartUtilities::safeStringToDartString(url), DartUtilities::convertSourceString(source), lineNumber, 0);
        if (Dart_IsError(result))
            reportError(result, url);
    }
    delete importers;
}

void DartApplicationLoader::process(const String& url, const String& source, intptr_t lineNumber)
{
    if (m_state == Error)
        return;

    if (url != m_scriptUrlString && m_snapshotMode != SnapshotAll)
        m_cacheable = false;

    RELEASE_ASSERT(m_state == Fetching || m_state == Loading || m_state == DeferredLoading);
    findDependences(url, source, lineNumber);
    RELEASE_ASSERT(m_state == Error || m_state == Loading || m_state == DeferredLoading);

    if (ready()) {
        m_state = (m_state == Loading) ? Ready : DeferredReady;
        // All dependences are in.
        m_loadCallback->ready();
    }
}

Dart_Handle DartApplicationLoader::libraryTagHandlerCallback(Dart_LibraryTag tag, Dart_Handle library, Dart_Handle urlHandle)
{
    ASSERT(Dart_CurrentIsolate());
    ASSERT(Dart_IsLibrary(library));

    const String url = DartUtilities::toString(urlHandle);

    if (tag == Dart_kCanonicalizeUrl) {
        // If a dart application calls spawnUri, the DartVM will call this
        // libraryTagHandler to canonicalize the url.
        // DartDOMData::current()->scriptLoader() may be 0 at this point.
        return DartUtilities::canonicalizeUrl(library, urlHandle, url);
    }

    if (url.startsWith("dart:")) {
        // All supported system URLs are already built-in and shouldn't get to this point.
        return Dart_NewApiError("The requested built-in library is not available on Dartium.");
    }

    RefPtr<DartApplicationLoader> loader = DartDOMData::current()->applicationLoader();
    ASSERT(loader);
    // We can only handle requests in one of the following states.
    if (loader->m_state == Error)
        return Dart_NewApiError("The isolate is in an invalid state.");
    RELEASE_ASSERT(loader->m_state == Fetching || loader->m_state == Loading || loader->m_state == Running || loader->m_state == DeferredLoading);


    // Fetch non-system URLs.
    if (tag == Dart_kImportTag) {
        if (loader->m_pendingLibraries.contains(url))
            return Dart_True();
#if defined(ENABLE_DART_NATIVE_EXTENSIONS)
        if (url.startsWith("dart-ext:")) {
            return DartNativeExtensions::loadExtension(url, library);
        }
#endif
        loader->m_pendingLibraries.add(url);
    } else if (tag == Dart_kSourceTag) {
        Dart_PersistentHandle importer = Dart_NewPersistentHandle(library);
        HandleSet* importers;
        if (loader->m_pendingSource.contains(url)) {
            // We have already requested this url. It is a part of more than one library.
            importers = loader->m_pendingSource.get(url);
            importers->append(importer);
            return Dart_True();
        }
        importers = new HandleSet();
        loader->m_pendingSource.add(url, importers);
        importers->append(importer);
    } else {
        ASSERT_NOT_REACHED();
    }

    // If the isolate is running, this is part of a deferred load request.
    if (loader->m_state == Running)
        loader->m_state = DeferredLoading;
    loader->fetchScriptResource(url);
    return Dart_True();
}

class ScriptLoadedCallback : public ResourceClient {
public:
    ScriptLoadedCallback(String url, PassRefPtr<DartApplicationLoader> loader, ResourcePtr<ScriptResource> scriptResource)
        : m_url(url)
        , m_loader(loader)
        , m_scriptResource(scriptResource)
    {
    }

    virtual void notifyFinished(Resource* cachedResource)
    {
        ASSERT(cachedResource->type() == Resource::Script);
        ASSERT(cachedResource == m_scriptResource.get());
        ASSERT(WTF::isMainThread());

        if (cachedResource->errorOccurred()) {
            m_loader->reportError(String("An error occurred loading file"), m_url);
        } else if (cachedResource->wasCanceled()) {
            // FIXME: shall we let VM know, so it can inform application some of its
            // resources cannot be loaded?
            m_loader->reportError(String("File request cancelled"), m_url);
        } else {
            ScriptSourceCode sourceCode(m_scriptResource.get());

            // Use the original url associated with the Script so that
            // redirects do not break the DartScriptLoader.
            // FIXME: is this the correct behavior? This functionality is
            // very convenient when you want the source file to act as if
            // it was from the original location but that isn't always
            // what the user expects.
            m_loader->process(m_url, sourceCode.source(), 0);
        }

        m_scriptResource->removeClient(this);
        delete this;
    }

private:
    String m_url;
    RefPtr<DartApplicationLoader> m_loader;
    ResourcePtr<ScriptResource> m_scriptResource;
};

static String resolveUrl(String mainLibraryURL, const String& url)
{
    if (!url.startsWith("package:") || url.startsWith("package://"))
        return url;

    String packageRoot;
    String packageUrl;
    if (const char* packageRootOverride = getenv("DART_PACKAGE_ROOT")) {
        // Resolve with respect to the override. Append a
        // slash to ensure that resolution is against this
        // path and not its parent.
        packageRoot = String(packageRootOverride) + "/";
        // Strip the 'package:' prefix.
        packageUrl = url.substring(8);
    } else {
        // Resolve with respect to the entry point's URL. Note, the
        // trailing file name in the entry point URL (e.g.,
        // 'rootpath/mainapp.dart') is stripped by the KURL
        // constructor below.
        packageRoot = mainLibraryURL;
        packageUrl = String("packages/") + url.substring(8);
    }
    return KURL(KURL(KURL(), packageRoot), packageUrl).string();
}

void DartApplicationLoader::fetchScriptResource(const String& url)
{
    // Request loading of script dependencies.
    FetchRequest request(m_loadCallback->completeURL(resolveUrl(m_scriptUrl, url)),
        FetchInitiatorTypeNames::document, "utf8");
    // FIXME: what about charset for this script, maybe use charset of initial script tag?
    ResourcePtr<ScriptResource> scriptResource = m_loadCallback->requestScript(request);
    if (scriptResource) {
        scriptResource->addClient(new ScriptLoadedCallback(m_loadCallback->completeURL(url), this, scriptResource));
    } else {
        m_loadCallback->reportError(String("File request error"), url);
    }
}

// FIXME(vsm): Merge these functions below. We need to be careful about where the error is dispatched.
void DartApplicationLoader::scriptLoadError(String failedUrl)
{
    if (m_state < Running)
        m_state = Error;
    // FIXME: try to dig out line number, -1 for now.
    if (failedUrl.startsWith(String("dart:"))) {
        m_originDocument->logExceptionToConsole(String("The built-in library '") + failedUrl + String("' is not available on Dartium."), m_scriptUrlString, -1, 0, nullptr);
    } else {
        m_originDocument->logExceptionToConsole(String("Failed to load a file ") + failedUrl, m_scriptUrlString, -1, 0, nullptr);
    }
    RELEASE_ASSERT(m_errorEventDispatcher);
    m_errorEventDispatcher->dispatchErrorEvent();
}

void DartApplicationLoader::reportDartError(Dart_Handle error)
{
    if (m_state < Running)
        m_state = Error;
    DartUtilities::reportProblem(m_originDocument, error, m_scriptUrlString);
}

void DartApplicationLoader::reportError(Dart_Handle error, const String& url)
{
    reportError(Dart_GetError(error), url);
}

void DartApplicationLoader::reportError(const String& error, const String& url)
{
    if (m_state < Running)
        m_state = Error;
    m_loadCallback->reportError(error, url);
}


}
