// Copyright 2011, Google Inc.
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//    * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//    * Neither the name of Google Inc. nor the names of its
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

#ifndef DartApplicationLoader_h
#define DartApplicationLoader_h

#include "bindings/core/v8/ScriptSourceCode.h"
#include "core/dom/Document.h"
#include "core/html/HTMLScriptElement.h"
#include "core/html/VoidCallback.h"
#include <dart_api.h>
#include <wtf/HashMap.h>
#include <wtf/HashSet.h>
#include <wtf/text/StringHash.h>

namespace blink {

class FetchRequest;
class KURL;
class ScriptLoader;
class ScriptLoaderClient;
class ScriptResource;

class DartErrorEventDispatcher : public RefCounted<DartErrorEventDispatcher> {
public:
    virtual ~DartErrorEventDispatcher() { }
    virtual void dispatchErrorEvent() = 0;
};

// FIXME(vsm): We should be able to eliminate this class and reuse v8/ScriptSourceCode.
// Abstraction for HTMLScriptElement or SVGScriptElement.
class DartScriptInfo : public DartErrorEventDispatcher {
public:
    static PassRefPtr<DartScriptInfo> create(PassRefPtr<Element> scriptElement);

    String sourceAttributeValue() const;
    String typeAttributeValue() const;
    String scriptContent();
    void dispatchErrorEvent();
    WTF::OrdinalNumber startLineNumber();
    ScriptLoader* loader();
    Document* ownerDocument();
    String url();

    virtual ~DartScriptInfo() { }

protected:
    DartScriptInfo(PassRefPtr<Element>);

    // Note, the element keeps the corresponding ScriptLoader and ScriptLoaderClient alive.
    RefPtr<Element> m_element;
    ScriptLoader* m_loader;
    ScriptLoaderClient* m_client;
};

class DartApplicationLoader : public RefCounted<DartApplicationLoader> {
public:
    class Callback : public RefCounted<Callback> {
    public:
        Callback(Document* originDocument, PassRefPtr<DartScriptInfo> scriptInfo = nullptr)
            : m_originDocument(originDocument)
            , m_scriptInfo(scriptInfo) { }

        virtual ~Callback() { }

        virtual void ready() = 0;
        void reportError(const String& error, const String& url);

        KURL completeURL(const String& url) { return document()->completeURL(url); }
        ResourcePtr<ScriptResource> requestScript(FetchRequest&);

        Document* document();
        Document* originDocument() const { return m_originDocument; }
        PassRefPtr<DartScriptInfo> scriptInfo() const { return m_scriptInfo; }

    private:
        Document* m_originDocument;
        RefPtr<DartScriptInfo> m_scriptInfo;
    };

    static PassRefPtr<DartApplicationLoader> create(Document* document, bool domEnabled)
    {
        return adoptRef(new DartApplicationLoader(document, domEnabled));
    }

    void load(PassRefPtr<DartErrorEventDispatcher>);

    Document* document() { return m_originDocument; }

    void callEntryPoint();

    void validateUrlLoaded(const String& url);

    // Registers a request to be fetched later.
    void addRequest(PassRefPtr<DartScriptInfo>);

    // Fetches all pending requests and invokes callback when done.
    void processRequests(Dart_Isolate, const ScriptSourceCode&, PassRefPtr<Callback>);
    void processSingleRequest(Dart_Isolate, const String& url, PassRefPtr<Callback>);

    bool running() const { return m_state >= Running; }
    bool error() const { return m_state == Error; }

private:
    enum State {
        // The application failed to load.
        Error = -1,

        // The isolate is not set.
        Uninitialized = 0,

        // The isolate is initialized, but no user scripts have been requested or loaded.
        Initialized,

        // The isolate is not running. The main script has been requested, but not loaded.
        Fetching,

        // The isolate is not running as requests are in the process of loading.
        Loading,

        // The isolate is not running, but is ready to run. There are no outstanding requests.
        Ready,

        // The isolate is running. There no outstanding requests or deferred libraries.
        Running,

        // The isolate is running, but deferred requests are outstanding.
        DeferredLoading,

        // The isolate is running, but there are deferred requests ready to finalize.
        DeferredReady,
    };

    enum SnapshotMode {
        // Snapshots are disabled.
        SnapshotOff,

        // Snapshot only single resource cacheable apps.
        SnapshotSingle,

        // Snapshot everything (experimental).
        SnapshotAll,
    };

    typedef HashSet<String> UrlSet;
    typedef Vector<Dart_PersistentHandle> HandleSet;
    typedef HashMap<String, HandleSet*> UrlHandleMap;
    typedef Deque<RefPtr<DartScriptInfo> > ScriptList;

    DartApplicationLoader(Document*, bool domEnabled = true);

    void loadScriptFromSnapshot(const String& url, const uint8_t* snapshot, intptr_t snapshotSize);

    Dart_Handle topLevelLibrary();

    // FIXME(vsm): Do we need all of these?
    void scriptLoadError(String failedUrl);
    void reportDartError(Dart_Handle);
    void reportError(Dart_Handle error, const String& url);
    void reportError(const String& error, const String& url);

    void initialize(Dart_Isolate, const String& scriptUrl, PassRefPtr<Callback>);

    void process(const String& url, const String& source, intptr_t lineNumber);
    void fetchScriptResource(const String& url);

    // All dependences are available.
    bool ready() const { return m_pendingLibraries.isEmpty() && m_pendingSource.isEmpty() && m_htmlImportedScripts.isEmpty() && (m_state >= Loading); }

    void findDependences(const String& url, const String& source, intptr_t lineNumber);
    void processLibrary(const String& url, const String& source, intptr_t lineNumber);
    void processSource(const String& url, const String& source, intptr_t lineNumber);
    static Dart_Handle libraryTagHandlerCallback(Dart_LibraryTag, Dart_Handle library, Dart_Handle urlHandle);

    Dart_Isolate m_isolate;
    // Client must ensure that DartApplicationLoader doesn't outlive corresponding document.
    Document* m_originDocument;
    RefPtr<DartErrorEventDispatcher> m_errorEventDispatcher;
    RefPtr<Callback> m_loadCallback;
    bool m_domEnabled;
    bool m_cacheable;

    ScriptList m_htmlImportedScripts;
    UrlSet m_pendingLibraries;
    UrlHandleMap m_pendingSource;

    KURL m_scriptUrl;
    String m_scriptUrlString;

    State m_state;
    SnapshotMode m_snapshotMode;

    friend class DartService;
    friend class ScriptLoadedCallback;
};

}

#endif // DartApplicationLoader_h
