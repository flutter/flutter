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
#include "bindings/core/dart/DartController.h"

#if OS(ANDROID)
#include <sys/system_properties.h>
#endif


#include "core/HTMLNames.h"
#include "bindings/common/ScheduledAction.h"
#include "bindings/core/dart/DartApplicationLoader.h"
#include "bindings/core/dart/DartDOMData.h"
#include "bindings/core/dart/DartDOMWrapper.h"
#include "bindings/core/dart/DartDocument.h"
#include "bindings/core/dart/DartGCController.h"
#include "bindings/core/dart/DartInspectorTimeline.h"
#include "bindings/core/dart/DartIsolateDestructionObserver.h"
#include "bindings/core/dart/DartJsInterop.h"
#include "bindings/core/dart/DartNativeUtilities.h"
#include "bindings/core/dart/DartScriptDebugServer.h"
#include "bindings/core/dart/DartScriptState.h"
#include "bindings/core/dart/DartService.h"
#include "bindings/core/dart/DartUtilities.h"
#include "bindings/core/dart/DartWindow.h"
#include "bindings/core/dart/ThreadSafeDartIsolateWrapper.h"
#include "bindings/core/v8/ScriptController.h"
#include "bindings/core/v8/V8Binding.h"
#include "core/dom/Document.h"
#include "core/dom/ExecutionContext.h"
#include "core/dom/ExecutionContextTask.h"
#include "core/dom/MutationObserver.h"
#include "core/dom/NodeList.h"
#include "core/dom/ScriptLoader.h"
#include "core/frame/DOMTimer.h"
#include "core/frame/LocalDOMWindow.h"
#include "core/frame/LocalFrame.h"
#include "core/frame/Settings.h"
#include "core/html/HTMLDocument.h"
#include "core/html/HTMLLinkElement.h"
#include "core/html/HTMLScriptElement.h"
#include "core/page/Page.h"
#include "core/storage/StorageNamespace.h"
#include "core/svg/SVGScriptElement.h"
#include "modules/indexeddb/IDBPendingTransactionMonitor.h"
#include "public/platform/Platform.h"

#include <ctype.h>

#include <dart_api.h>
#include <dart_debugger_api.h>

namespace blink {

static void copyValue(Dart_Handle source, const char* fieldName,
    Dart_Handle targetLibrary, const char* targetClass, const char* targetField)
{
    Dart_Handle value = Dart_GetField(source, Dart_NewStringFromCString(fieldName));
    ASSERT(!Dart_IsError(value));

    Dart_Handle target = targetClass ? Dart_GetType(targetLibrary, Dart_NewStringFromCString(targetClass), 0, 0) : targetLibrary;
    ASSERT(!Dart_IsError(target));

    Dart_SetField(target, Dart_NewStringFromCString(targetField), value);
}

static void messageNotifyCallback(Dart_Isolate);

extern Dart_NativeFunction blinkSnapshotResolver(Dart_Handle name, int argumentCount, bool* autoSetupScope);

static void throwDomDisabled(Dart_NativeArguments)
{
    DartApiScope apiScope;
    Dart_ThrowException(Dart_NewStringFromCString("DOM access is not enabled in this isolate"));
}

Dart_NativeFunction pureIsolateResolver(Dart_Handle name, int argumentCount, bool* autoSetupScope)
{
    return throwDomDisabled;
}

const uint8_t* pureIsolateSymbolizer(Dart_NativeFunction nf)
{
    return 0;
}

void DartController::weakCallback(void* isolateCallbackData, Dart_WeakPersistentHandle handle, void* peer)
{
    // This weak handle has no peer associated with it, it is used to temporarily make
    // weak handles strong during GC.
    ASSERT(!peer);
    DartDOMData* domData = reinterpret_cast<DartDOMData*>(isolateCallbackData);
    domData->setReachableWeakHandle(0);
}

Dart_Isolate DartController::createIsolate(const char* scriptURL, const char* entryPoint, Document* document, bool isDOMEnabled, bool isDebuggerEnabled, char** errorMessage)
{
    DART_START_TIMER();
    const uint8_t* snapshot = DartUtilities::fullSnapshot(document->frame());
    DartDOMData* domData = new DartDOMData(document, scriptURL, isDOMEnabled);
    Dart_Isolate isolate = Dart_CreateIsolate(scriptURL, entryPoint, snapshot, domData, errorMessage);
    if (!isolate) {
        delete domData;
        return 0;
    }
    DART_RECORD_TIMER("    createIsolate after Dart_CreateIsolate call");

    DartApiScope apiScope;

    domData->setThreadSafeIsolateWrapper(ThreadSafeDartIsolateWrapper::create());

    Dart_Handle blink = Dart_LookupLibrary(Dart_NewStringFromCString("dart:_blink"));
    ASSERT(!Dart_IsError(blink));
    // FIXME: this should be blinkSnapshotResolver
    Dart_SetNativeResolver(blink, isDOMEnabled ? domIsolateHtmlResolver : pureIsolateResolver, isDOMEnabled ? domIsolateHtmlSymbolizer : pureIsolateSymbolizer);
    domData->setBlinkLibrary(Dart_NewPersistentHandle(blink));

    // Fix the html library.
    Dart_Handle html = Dart_LookupLibrary(Dart_NewStringFromCString("dart:html"));
    ASSERT(!Dart_IsError(html));
    domData->setHtmlLibrary(Dart_NewPersistentHandle(html));

    Dart_Handle js = Dart_LookupLibrary(Dart_NewStringFromCString("dart:js"));
    ASSERT(!Dart_IsError(js));
    Dart_SetNativeResolver(js, isDOMEnabled ? JsInterop::resolver : pureIsolateResolver, 0);
    domData->setJsLibrary(Dart_NewPersistentHandle(js));

    Dart_Handle core = Dart_LookupLibrary(Dart_NewStringFromCString("dart:core"));
    ASSERT(!Dart_IsError(core));

    domData->setSvgLibrary(0);

    Dart_Handle functionType = Dart_GetType(core, Dart_NewStringFromCString("Function"), 0, 0);
    ASSERT(!Dart_IsError(functionType));
    domData->setFunctionType(Dart_NewPersistentHandle(functionType));

    domData->setCurrentException(Dart_NewPersistentHandle(Dart_Null()));

    // Setup configuration closures
    char forwardingProp[DartUtilities::PROP_VALUE_MAX_LEN];
    int propLen = DartUtilities::getProp("DART_FORWARDING_PRINT",
        forwardingProp, DartUtilities::PROP_VALUE_MAX_LEN);
    bool forwardPrint = propLen > 0;
    const char * const printClosure = forwardPrint ?
        "_forwardingPrintClosure" :
        (isDOMEnabled ?  "_printClosure" : "_pureIsolatePrintClosure");
    Dart_Handle asyncLib = Dart_LookupLibrary(Dart_NewStringFromCString("dart:async"));
    ASSERT(!Dart_IsError(asyncLib));
    Dart_Handle internalLib = Dart_LookupLibrary(Dart_NewStringFromCString("dart:_internal"));
    ASSERT(!Dart_IsError(internalLib));
    copyValue(html, printClosure, internalLib, 0, "_printClosure");
    copyValue(html, isDOMEnabled ? "_timerFactoryClosure" : "_pureIsolateTimerFactoryClosure", asyncLib, "_TimerFactory", "_factory");
    if (isDOMEnabled) {
        copyValue(html, "_scheduleImmediateClosure", asyncLib, "_ScheduleImmediate", "_closure");
    } else {
        // Use the VM implementation (from dart:isolate) for scheduleImmediate.
        Dart_Handle isolateLibrary = Dart_LookupLibrary(Dart_NewStringFromCString("dart:isolate"));
        ASSERT(!Dart_IsError(isolateLibrary));

        Dart_Handle value = Dart_Invoke(isolateLibrary, Dart_NewStringFromCString("_getIsolateScheduleImmediateClosure"), 0, 0);
        ASSERT(!Dart_IsError(value));

        Dart_Handle target = Dart_GetType(asyncLib, Dart_NewStringFromCString("_ScheduleImmediate"), 0, 0);
        ASSERT(!Dart_IsError(target));

        Dart_SetField(target, Dart_NewStringFromCString("_closure"), value);
    }
    copyValue(html, isDOMEnabled ? "_uriBaseClosure" : "_pureIsolateUriBaseClosure", core, 0, "_uriBaseClosure");

    if (isDOMEnabled) {
        // We need a weak handle to an always reachable object in order to temporarily make
        // weak handles strong during GC, see the corresponding logic in DartGCController.
        // We use the always reachable boolean 'True' object for this.
        domData->setReachableWeakHandle(Dart_NewWeakPersistentHandle(Dart_True(), 0, 0, DartController::weakCallback));
        Dart_SetMessageNotifyCallback(&messageNotifyCallback);
        Dart_SetGcCallbacks(&DartGCController::prologueCallback, &DartGCController::epilogueCallback);

        if (isDebuggerEnabled) {
            DART_RECORD_TIMER("    createIsolate before debug setup");
            DartScriptDebugServer::shared().registerIsolate(isolate, document->page());
            DART_RECORD_TIMER("    createIsolate after debug setup");
        }
    }
    DART_RECORD_TIMER("    createIsolate done %.3f ms");

    return isolate;
}

Dart_Isolate DartController::createDOMEnabledIsolate(const String& scriptURL, const String& entryPoint, Document* document)
{
    DART_START_TIMER();
    ASSERT(!Dart_CurrentIsolate());

    // FIXME: proper error reporting.
    char* errorMessage = 0;
    Dart_Isolate newIsolate = createIsolate(scriptURL.utf8().data(), entryPoint.utf8().data(), document, true, true, &errorMessage);
    ASSERT(newIsolate);
    m_isolates.append(newIsolate);
    DART_RECORD_TIMER("  createDOMEnabledIsolate took");
    return newIsolate;
}

void DartController::shutdownIsolate(Dart_Isolate isolate)
{
    DartDOMData* domData = DartDOMData::current();
    ASSERT(domData->isDOMEnabled());
    // If the following assert triggers, we have hit dartbug.com/14183
    // FIXME: keep the isolate alive until the recursion level is 0.
    ASSERT(!*(domData->recursion()));
    DartScriptDebugServer::shared().unregisterIsolate(isolate, m_frame->page());
    DartIsolateDestructionObservers* observers = domData->isolateDestructionObservers();
    for (DartIsolateDestructionObservers::iterator it = observers->begin(); it != observers->end(); ++it)
        (*it)->isolateDestroyed();
    Dart_ShutdownIsolate();
    delete domData;
}

DartController::DartController(LocalFrame* frame)
    : m_frame(frame)
    , m_npObjectMap()
{
    // The DartController's constructor must be called in the LocalFrame's
    // constructor, so it can properly maintain the unit of related
    // browsing contexts.
}

DartController::~DartController()
{
    clearWindowShell();
}

void DartController::clearWindowShell()
{
    DART_START_TIMER();
    initVMIfNeeded();
    DART_RECORD_TIMER("clearWindowShell::initVM took");
    m_documentsWithDart.clear();
    if (m_loader) {
        m_loader = nullptr;
    }

    // Due to synchronous dispatch, we may be in an isolate corresponding to another frame.
    // If so, exit here but re-enter before returning.
    Dart_Isolate currentIsolate = Dart_CurrentIsolate();
    if (currentIsolate)
        Dart_ExitIsolate();

    Vector<Dart_Isolate>::iterator iterator;
    for (iterator = m_isolates.begin(); iterator != m_isolates.end(); ++iterator) {
        Dart_Isolate isolate = *iterator;
        Dart_EnterIsolate(isolate);
        shutdownIsolate(isolate);
    }
    m_isolates.clear();

    DartScriptDebugServer::shared().clearWindowShell(m_frame->page());

    for (ScriptStatesMap::iterator it = m_scriptStates.begin(); it != m_scriptStates.end(); ++it) {
        LibraryIdMap* libraryIdMap = it->value;
        delete libraryIdMap;
    }
    m_scriptStates.clear();

    // Restore previous isolate.
    if (currentIsolate)
        Dart_EnterIsolate(currentIsolate);
}

void DartController::clearScriptObjects()
{
    // FIXME(dartbug.com/18427): Clear plugin / NP objects.
}

class MessageNotifyTask : public ExecutionContextTask {
public:
    explicit MessageNotifyTask(PassRefPtr<ThreadSafeDartIsolateWrapper> destinationIsolate)
        : m_destinationIsolate(destinationIsolate)
    { }

    virtual void performTask(ExecutionContext* context)
    {
        if (!m_destinationIsolate->isIsolateAlive())
            return;

        DartIsolateScope scope(m_destinationIsolate->isolate());
        DartApiScope apiScope;

        DartDOMData* domData = DartDOMData::current();
        // FIXME(dartbug.com/20303): we cannot safely initialize a V8 scope
        // for the observatory isolate as it is not associated with a fully
        // initialized document.
        if (domData->isObservatoryFakeDartDOMData()) {
            Dart_Handle result = Dart_HandleMessage();
            if (Dart_IsError(result))
                DartUtilities::reportProblem(context, result);
        } else {
            V8Scope v8scope(domData);
            Dart_Handle result = Dart_HandleMessage();
            if (Dart_IsError(result))
                DartUtilities::reportProblem(context, result);
        }
    }

private:
    RefPtr<ThreadSafeDartIsolateWrapper> m_destinationIsolate;
};

static void messageNotifyCallback(Dart_Isolate destinationIsolate)
{
    DartDOMData* domData = static_cast<DartDOMData*>(Dart_IsolateData(destinationIsolate));
    ASSERT(domData->isDOMEnabled());
    ExecutionContext* destinationContext = domData->scriptExecutionContext();
    destinationContext->postTask(adoptPtr(new MessageNotifyTask(domData->threadSafeIsolateWrapper())));
}

class SpawnUriErrorEventDispatcher : public DartErrorEventDispatcher {
public:
    // TODO(antonm): this is used to dispatch DOM error event. Most probably we need
    // nothing like that for spawnDomUri, but need to double check.
    void dispatchErrorEvent() { }
};

class DartSpawnUriCallback : public DartApplicationLoader::Callback {
public:
    DartSpawnUriCallback(Dart_Isolate isolate, PassRefPtr<DartApplicationLoader> loader, const String& url, Document* originDocument)
        : Callback(originDocument)
        , m_isolate(isolate)
        , m_loader(loader)
        , m_url(url)
    {
    }

    ~DartSpawnUriCallback() { }

    virtual void initialize() = 0;
    virtual bool domEnabled() = 0;

    void ready()
    {
        RefPtr<SpawnUriErrorEventDispatcher> errorEventDispatcher = adoptRef(new SpawnUriErrorEventDispatcher());

        m_loader->load(errorEventDispatcher);
        initialize();
    }

protected:
    Dart_Isolate m_isolate;
    RefPtr<DartApplicationLoader> m_loader;
    String m_url;
};

class DartSpawnBackgroundUriCallback : public DartSpawnUriCallback {
public:
    DartSpawnBackgroundUriCallback(Dart_Isolate isolate, PassRefPtr<DartApplicationLoader> loader, const String& url, Document* originDocument)
        : DartSpawnUriCallback(isolate, loader, url, originDocument)
    {
    }

    void initialize()
    {
        // The VM initiates background isolates.
        Dart_IsolateMakeRunnable(m_isolate);
    }

    bool domEnabled() { return false; }
};

class DartSpawnDomUriCallback : public DartSpawnUriCallback {
public:
    DartSpawnDomUriCallback(Dart_Isolate isolate, PassRefPtr<DartApplicationLoader> loader, const String& url, Document* originDocument)
        : DartSpawnUriCallback(isolate, loader, url, originDocument)
    {
    }

    void initialize()
    {
        // The browser initiates DOM isolates directly.
    }

    bool domEnabled() { return true; }
};

Dart_Isolate DartController::createServiceIsolateCallback(void* callbackData, char** error)
{
    // FIXME(dartbug.com/20303): we create an empty document for the service
    // isolate that is never GCed so that its lifecycle is not dependent on
    // pages. One we support service isolates we can remove this hack.
    Document* document = HTMLDocument::create().leakRef();

    Dart_Isolate serviceIsolate = DartController::createIsolate("dart:vmservice_dartium", "main", document, true, false, error);
    DartDOMData* domData = DartDOMData::current();
    domData->setIsObservatoryFakeDartDOMData(true);
    Dart_ExitIsolate();
    return serviceIsolate;
}


Dart_Isolate DartController::createPureIsolateCallback(const char* scriptURL, const char* entryPoint, const char* packageRoot, void* data, char** errorMsg)
{
    bool isSpawnUri = scriptURL ? true : false;

    if (isSpawnUri && !WTF::isMainThread()) {
        // FIXME(14463): We need to forward this request to the main thread to fetch the URI.
        *errorMsg = strdup("spawnUri is not yet supported on background isolates.");
        return 0;
    }

    DartDOMData* parentDOMData = static_cast<DartDOMData*>(data);
    ExecutionContext* context = parentDOMData->scriptExecutionContext();

    if (parentDOMData->isDOMEnabled() && !isSpawnUri) {
        // spawnFunction is not allowed from a DOM enabled isolate.
        // This triggers an exception in the caller.
        *errorMsg = strdup("spawnFunction is not supported from a dom-enabled isolate. Please use spawnUri instead.");
        return 0;
    }
    if (!isSpawnUri) {
        scriptURL = parentDOMData->scriptURL();
    }

    ASSERT(context->isDocument());
    Document* document = static_cast<Document*>(context);

    Dart_Isolate isolate = createIsolate(scriptURL, entryPoint, document, false, true, errorMsg);

    if (!isolate) {
        // This triggers an exception in the caller.
        *errorMsg = strdup("Isolate spawn failed.");
        return 0;
    }

    // FIXME: If a spawnFunction, we should not need to request resources again. But, it's not clear
    // we need this callback in the first place for spawnFunction.

    // We need to request the sources asynchronously.
    RefPtr<DartApplicationLoader> loader = DartApplicationLoader::create(document, false);
    RefPtr<DartSpawnUriCallback> callback = adoptRef(new DartSpawnBackgroundUriCallback(isolate, loader, scriptURL, document));
    Dart_ExitIsolate();
    loader->processSingleRequest(isolate, scriptURL, callback);

    return isolate;
}

static char* skipWhiteSpace(char* p)
{
    for (; *p != '\0' && isspace(*p); p++) { }
    return p;
}

static char* skipBlackSpace(char* p)
{
    for (; *p != '\0' && !isspace(*p); p++) { }
    return p;
}

static void setDartFlags(const char* str)
{
    if (!str) {
        Dart_SetVMFlags(0, 0);
        return;
    }

    size_t length = strlen(str);
    char* copy = new char[length + 1];
    memmove(copy, str, length);
    copy[length] = '\0';

    // Strip leading white space.
    char* start = skipWhiteSpace(copy);

    // Count the number of 'arguments'.
    int argc = 0;
    for (char* p = start; *p != '\0'; argc++) {
        p = skipBlackSpace(p);
        p = skipWhiteSpace(p);
    }

    // Allocate argument array.
    const char** argv = new const char*[argc];

    // Split the flags string into arguments.
    argc = 0;
    for (char* p = start; *p != '\0'; argc++) {
        argv[argc] = p;
        p = skipBlackSpace(p);
        if (*p != '\0')
            *p++ = '\0'; // 0-terminate argument
        p = skipWhiteSpace(p);
    }

    // Set the flags.
    Dart_SetVMFlags(argc, argv);

    delete[] argv;
    delete[] copy;
}

namespace {

#if OS(LINUX)

static void* openFileCallback(const char* name, bool write)
{
    return fopen(name, write ? "w" : "r");
}

static void readFileCallback(const uint8_t** data, intptr_t* fileLength, void* stream)
{
    if (!stream) {
        *data = 0;
        *fileLength = 0;
    } else {
        FILE* file = reinterpret_cast<FILE*>(stream);

        // Get the file size.
        fseek(file, 0, SEEK_END);
        *fileLength = ftell(file);
        rewind(file);

        // Allocate data buffer.
        *data = new uint8_t[*fileLength];
        *fileLength = fread(const_cast<uint8_t*>(*data), 1, *fileLength, file);
    }
}

static void writeFileCallback(const void* data, intptr_t length, void* file)
{
    fwrite(data, 1, length, reinterpret_cast<FILE*>(file));
}

static void closeFileCallback(void* file)
{
    fclose(reinterpret_cast<FILE*>(file));
}

#else

static Dart_FileOpenCallback openFileCallback = 0;
static Dart_FileReadCallback readFileCallback = 0;
static Dart_FileWriteCallback writeFileCallback = 0;
static Dart_FileCloseCallback closeFileCallback = 0;

#endif // OS(LINUX)

}

static bool generateEntropy(uint8_t* buffer, intptr_t length)
{
    if (blink::Platform::current()) {
        blink::Platform::current()->cryptographicallyRandomValues(buffer, length);
        return true;
    }
    return false;
}

void DartController::initVMIfNeeded()
{
    static bool hasBeenInitialized = false;
    if (hasBeenInitialized)
        return;

    char flagsProp[DartUtilities::PROP_VALUE_MAX_LEN];
    int propLen = DartUtilities::getProp(
        "DART_FLAGS", flagsProp, DartUtilities::PROP_VALUE_MAX_LEN);
    if (propLen > 0) {
        setDartFlags(flagsProp);
    } else {
        setDartFlags(0);
    }

    // FIXME(antonm): implement proper unhandled exception callback.
    Dart_Initialize(&createPureIsolateCallback, 0, 0, 0, openFileCallback, readFileCallback, writeFileCallback, closeFileCallback, generateEntropy, createServiceIsolateCallback);
    hasBeenInitialized = true;
}

static bool checkForExpiration()
{
    const time_t ExpirationTimeSecsSinceEpoch =
#include "bindings/dart/ExpirationTimeSecsSinceEpoch.time_t"
    ;
    const char* override = getenv("DARTIUM_EXPIRATION_TIME");
    time_t expiration;
    if (override) {
        expiration = static_cast<time_t>(String(override).toInt64());
    } else {
        expiration = ExpirationTimeSecsSinceEpoch;
    }
    const time_t now = time(0);
    double diff = difftime(now, expiration);
    if (diff > 0) {
        fprintf(stderr, "[dartToStderr]: Dartium build has expired\n");
        return true;
    }

    return false;
}

class DartDomLoadCallback : public DartApplicationLoader::Callback {
public:
    DartDomLoadCallback(DartController* controller, const String& url, Dart_Isolate domIsolate, Document* originDocument, PassRefPtr<DartScriptInfo> info)
        : Callback(originDocument, info)
        , m_controller(controller)
        , m_url(url)
        , m_isolate(domIsolate)
    {
    }

    void ready()
    {
        m_controller->scheduleScriptExecution(m_url, m_isolate, scriptInfo());
    }

private:
    DartController* m_controller;
    String m_url;
    Dart_Isolate m_isolate;
};

class DartScriptRunner : public EventListener {
public:
    static PassRefPtr<DartScriptRunner> create(const String& url, Dart_Isolate isolate, PassRefPtr<DartScriptInfo> info)
    {
        return adoptRef(new DartScriptRunner(url, isolate, info));
    }

    virtual void handleEvent(ExecutionContext* context, Event*)
    {
        ASSERT(context->isDocument());
        Document* document = static_cast<Document*>(context);

        // this gets removed below, so protect it while handler runs.
        RefPtr<DartScriptRunner> protect(this);
        document->domWindow()->removeEventListener(AtomicString("DOMContentLoaded"), this, false);

        DartController::retrieve(context)->loadAndRunScript(m_url, m_isolate, m_info);
    }

    virtual bool operator==(const EventListener& other)
    {
        return this == &other;
    }

private:
    DartScriptRunner(const String& url, Dart_Isolate isolate, PassRefPtr<DartScriptInfo> info)
        : EventListener(EventListener::NativeEventListenerType)
        , m_url(url)
        , m_isolate(isolate)
        , m_info(info)
    {
    }

    String m_url;
    Dart_Isolate m_isolate;
    RefPtr<DartScriptInfo> m_info;
};

void DartController::scheduleScriptExecution(const String& url, Dart_Isolate isolate, PassRefPtr<DartScriptInfo> info)
{
    Document* document = frame()->document();
    if (document->readyState() == "loading")
        document->domWindow()->addEventListener(AtomicString("DOMContentLoaded"), DartScriptRunner::create(url, isolate, info), false);
    else
        loadAndRunScript(url, isolate, info);
}

void DartController::loadAndRunScript(const String& url, Dart_Isolate isolate, PassRefPtr<DartScriptInfo> info)
{
    DART_START_TIMER();
    RefPtr<DartScriptInfo> scriptInfo = info;
    Document* ALLOW_UNUSED document = frame()->document();

    // Invoke only if this is the main document.
    ASSERT(scriptInfo->ownerDocument() == document);

    ASSERT(m_loader);
    // Due to deferred loading we might already be running Dart code on
    // an isolate and the library tag handler callback could result in a call
    // to this code, we skip the Enter/Exit Isolate calls in that case.
    if (isolate == Dart_CurrentIsolate()) {
        m_loader->load(scriptInfo);
    } else {
        Dart_EnterIsolate(isolate);
        m_loader->load(scriptInfo);
        Dart_ExitIsolate();
    }

    DART_RECORD_TIMER("DartController::loadAndRunScript took");
}

void DartController::evaluate(const ScriptSourceCode& sourceCode, ScriptLoader* loader)
{
    if (checkForExpiration())
        return;

    DART_START_TIMER();
    initVMIfNeeded();
    DART_RECORD_TIMER("evaluate::initVM took");
    Document* document = frame()->document();
    RefPtr<Element> element(loader->element());

    RefPtr<DartScriptInfo> scriptInfo = DartScriptInfo::create(element);
    if (!scriptInfo) {
        DartUtilities::reportProblem(document, "Dart script must be in HTML or SVG document.");
        ASSERT_NOT_REACHED();
        return;
    }

    Document* owner = scriptInfo->ownerDocument();
    if (m_documentsWithDart.contains(owner)) {
        int line = scriptInfo->startLineNumber().zeroBasedInt();
        DartUtilities::reportProblem(owner, "Only one Dart script tag allowed per document", line);
        return;
    }
    m_documentsWithDart.add(owner);

    if (m_loader) {
        if (m_loader->running()) {
            // Main has already been invoked.
            String scriptURL = scriptInfo->sourceAttributeValue();

            // Enforce that no new code is loaded. We've already invoked main at this point.
            // Any referenced code must already be in the isolate.
            if (scriptURL.isEmpty()) {
                int line = scriptInfo->startLineNumber().zeroBasedInt();
                DartUtilities::reportProblem(document, "Inline Darts scripts not supported after main script is invoked.", line);
            } else {
                m_loader->validateUrlLoaded(scriptURL);
            }
            return;
        }
        if (m_loader->error()) {
            return;
        }
    }

    if (!m_loader) {
        m_loader = DartApplicationLoader::create(document, true);
    }

    DART_RECORD_TIMER("evaluate::prep for loading took");
    if (document == scriptInfo->ownerDocument()) {
        String url = scriptInfo->url();
        // FIXME: This should be the first DOM enabled isolate. There is a race condition
        // however - m_loader above won't catch this if it hasn't been set yet.
        // This problem goes away once we map each script to a separate isolate.
        if (!m_isolates.isEmpty())
            return;
        DART_RECORD_TIMER("evaluate before createIsolate");
        Dart_Isolate isolate = createDOMEnabledIsolate(url, "main", document);
        DART_RECORD_TIMER("evaluate after createIsolate");
        RefPtr<DartDomLoadCallback> callback = adoptRef(new DartDomLoadCallback(this, url, isolate, document, scriptInfo));
        Dart_ExitIsolate();
        m_loader->processRequests(isolate, sourceCode, callback);
        DART_RECORD_TIMER("evaluate process request took");
    } else {
        m_loader->addRequest(scriptInfo);
    }
    DART_RECORD_TIMER("evaluate took");
}

void DartController::bindToWindowObject(LocalFrame* frame, const String& key, NPObject* object)
{
    // FIXME: proper management of lifetime.
    m_npObjectMap.set(key, object);
}

NPObject* DartController::npObject(const String& key)
{
    return m_npObjectMap.get(key);
}

Dart_Handle DartController::callFunction(Dart_Handle function, int argc, Dart_Handle* argv)
{
    V8Scope v8scope(DartDOMData::current());

    // FIXME: Introduce Dart variant of V8GCController::checkMemoryUsage();

    if (V8RecursionScope::recursionLevel(v8::Isolate::GetCurrent()) >= kMaxRecursionDepth)
        return Dart_NewApiError("Maximum call stack size exceeded");

    // FIXME: implement InspectorInstrumentationCookie stuff a la v8.
    Dart_Handle result = Dart_InvokeClosure(function, argc, argv);

    // Handle fatal error in Dart VM a la v8.

    return result;
}

DartController* DartController::retrieve(LocalFrame* frame)
{
    if (!frame)
        return 0;
    return &frame->dart();
}

DartController* DartController::retrieve(ExecutionContext* context)
{
    if (!context || !context->isDocument())
        return 0;
    return retrieve(static_cast<Document*>(context)->frame());
}

void DartController::collectScriptStates(V8ScriptState* v8ScriptState, Vector<DartScriptState*>& result)
{
    if (m_isolates.isEmpty())
        return;

    v8::HandleScope handleScope(v8::Isolate::GetCurrent());
    v8::Handle<v8::Context> v8Context = v8ScriptState->context();

    Vector<Dart_Isolate>::iterator iterator;
    for (iterator = m_isolates.begin(); iterator != m_isolates.end(); ++iterator) {
        Dart_Isolate isolate = *iterator;
        collectScriptStatesForIsolate(isolate, v8Context, result);
    }
}

LibraryIdMap* DartController::libraryIdMapForIsolate(Dart_Isolate isolate)
{
    LibraryIdMap* libraryIdMap;
    ScriptStatesMap::iterator it = m_scriptStates.find(isolate);
    if (it == m_scriptStates.end()) {
        libraryIdMap = new LibraryIdMap();
        m_scriptStates.set(isolate, libraryIdMap);
    } else {
        libraryIdMap = it->value;
    }
    return libraryIdMap;
}

DartScriptState* DartController::lookupScriptState(Dart_Isolate isolate, v8::Handle<v8::Context> v8Context, intptr_t libraryId)
{
    return lookupScriptStateFromLibraryIdMap(isolate, v8Context, libraryIdMapForIsolate(isolate), libraryId);
}

DartScriptState* DartController::lookupScriptStateFromLibraryIdMap(Dart_Isolate isolate, v8::Handle<v8::Context> v8Context, LibraryIdMap* libraryIdMap, intptr_t libraryId)
{
    // -1 cannot be used as a HashMap key however library ids are
    // guaranteed to be non-negative so it is a non-issue.
    ASSERT(libraryId >= 0);
    // 0 cannot be used as a HashMap key so we add 1 to the library id to
    // create a valid key.
    intptr_t libraryIdKey = libraryId + 1;
    LibraryIdMap::iterator libraryIter = libraryIdMap->find(libraryIdKey);
    DartScriptState* scriptState;
    if (libraryIter == libraryIdMap->end()) {
        V8ScriptState* v8ScriptState = V8ScriptState::from(v8Context);
        RefPtr<DartScriptState> scriptStatePtr = DartScriptState::create(isolate, libraryId, v8ScriptState);
        libraryIdMap->set(libraryIdKey, scriptStatePtr);
        scriptState = scriptStatePtr.get();
    } else {
        scriptState = libraryIter->value.get();
        ASSERT(scriptState);
    }
    return scriptState;
}

void DartController::collectScriptStatesForIsolate(Dart_Isolate isolate, v8::Handle<v8::Context> v8Context, Vector<DartScriptState*>& result)
{
    if (!isolate)
        return;
    DartIsolateScope scope(isolate);
    DartApiScope apiScope;
    LibraryIdMap* libraryIdMap = libraryIdMapForIsolate(isolate);
    Dart_Handle libraryIdList = Dart_GetLibraryIds();

    intptr_t length = 0;
    Dart_Handle ALLOW_UNUSED valid = Dart_ListLength(libraryIdList, &length);
    ASSERT(!Dart_IsError(valid));


    for (intptr_t i = 0; i < length; i++) {
        Dart_Handle libraryIdHandle = Dart_ListGetAt(libraryIdList, i);
        Dart_Handle exception = 0;
        intptr_t libraryId = DartUtilities::toInteger(libraryIdHandle, exception);
        ASSERT(!exception);
        DartScriptState* scriptState = lookupScriptStateFromLibraryIdMap(isolate, v8Context, libraryIdMap, libraryId);
        result.append(scriptState);
    }
}

void DartController::spawnDomUri(const String& url)
{
    // Save caller isolate.
    Dart_Isolate caller = Dart_CurrentIsolate();
    ASSERT(caller);
    Dart_ExitIsolate();

    // Create DOM isolate.
    Document* document = frame()->document();
    Dart_Isolate isolate = createDOMEnabledIsolate(url, "main", document);

    // Fetch and start.
    RefPtr<DartApplicationLoader> loader = DartApplicationLoader::create(document, true);
    RefPtr<DartSpawnUriCallback> callback = adoptRef(new DartSpawnDomUriCallback(isolate, loader, url, document));
    Dart_ExitIsolate();
    loader->processSingleRequest(isolate, url, callback);

    // Restore caller isolate.
    Dart_EnterIsolate(caller);

    // FIXME: We need some way to return a Dart_Handle to the isolate we just created.
}

}
