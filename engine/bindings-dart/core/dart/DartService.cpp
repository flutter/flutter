// Copyright (c) 2013, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "config.h"

#include "bindings/core/dart/DartService.h"

#include "bindings/core/dart/DartApplicationLoader.h"
#include "bindings/core/dart/DartController.h"
#include "bindings/core/dart/DartDocument.h"
#include "bindings/core/dart/DartUtilities.h"
#include "bindings/core/dart/DartWindow.h"


namespace blink {

// Dartium VM Service embedder glue script source.
static const char* kScriptChars = "\n"
"library vmservice_dartium;\n"
"\n"
"import 'dart:isolate';\n"
"import 'dart:vmservice';\n"
"\n"
"\n"
"// The receive port that service request messages are delivered on.\n"
"SendPort requestPort;\n"
"\n"
"// The native method that is called to post the response back to DevTools.\n"
"void postResponse(String response, int cookie) native \"VMService_PostResponse\";\n"
"\n"
"/// Dartium Service receives messages through the requestPort and posts\n"
"/// responses via postResponse. It has a single persistent client.\n"
"class DartiumClient extends Client {\n"
"  DartiumClient(port, service) : super(service) {\n"
"    port.listen((message) {\n"
"      if (message == null) {\n"
"        return;\n"
"      }\n"
"      if (message is! List) {\n"
"        return;\n"
"      }\n"
"      if (message.length != 2) {\n"
"        return;\n"
"      }\n"
"      if (message[0] is! String) {\n"
"        return;\n"
"      }\n"
"      var uri = Uri.parse(message[0]);\n"
"      var cookie = message[1];\n"
"      onMessage(cookie, new Message.fromUri(uri));\n"
"    });\n"
"  }\n"
"\n"
"  void post(var seq, String response) {\n"
"    postResponse(response, seq);\n"
"  }\n"
"\n"
"  dynamic toJson() {\n"
"    var map = super.toJson();\n"
"    map['type'] = 'DartiumClient';\n"
"  }\n"
"}\n"
"\n"
"\n"
"vmservice_dartium_main() {\n"
"  // Get VMService.\n"
"  var service = new VMService();\n"
"  var receivePort = new ReceivePort();\n"
"  requestPort = receivePort.sendPort;\n"
"  new DartiumClient(receivePort, service);\n"
"}\n";


#define SHUTDOWN_ON_ERROR(handle)                      \
    if (Dart_IsError(handle)) {                        \
        m_errorMsg = strdup(Dart_GetError(handle));    \
        Dart_ExitScope();                              \
        Dart_ShutdownIsolate();                        \
        return false;                                  \
    }

const char* DartService::m_errorMsg = 0;
Dart_Isolate DartService::m_isolate = 0;

bool DartService::Start(Document* document)
{
    if (m_isolate) {
        // Already started.
        return true;
    }
    ASSERT(!Dart_CurrentIsolate());
    Dart_Isolate isolate = Dart_GetServiceIsolate(document);
    if (!isolate) {
        m_errorMsg = "Could not get service isolate from VM.";
        return false;
    }
    Dart_EnterIsolate(isolate);
    Dart_EnterScope();
    Dart_Handle result;
    Dart_Handle library = LoadScript();
    SHUTDOWN_ON_ERROR(library);
    // Expect a library.
    ASSERT(Dart_IsLibrary(library));
    library = Dart_RootLibrary();
    result = Dart_SetNativeResolver(library, NativeResolver, 0);
    SHUTDOWN_ON_ERROR(result);
    result = Dart_Invoke(library, Dart_NewStringFromCString("vmservice_dartium_main"), 0, 0);
    SHUTDOWN_ON_ERROR(result);
    Dart_ExitScope();
    Dart_ExitIsolate();
    m_isolate = isolate;
    return true;
}


const char* DartService::GetErrorMessage()
{
    return m_errorMsg ? m_errorMsg : "No error.";
}


DartServiceRequest::DartServiceRequest(const String& request) : m_request(request)
{
}

DartServiceRequest::~DartServiceRequest()
{
}


// The format of the message is:
// [request string, address of DartServiceRequest].
static Dart_Handle MakeServiceRequestMessage(DartServiceRequest* request)
{
    intptr_t requestAddress = reinterpret_cast<intptr_t>(request);
    int64_t requestAddress64 = static_cast<int64_t>(requestAddress);
    Dart_Handle ALLOW_UNUSED result;
    Dart_Handle list = Dart_NewList(2);
    ASSERT(!Dart_IsError(list));
    Dart_Handle requestHandle = DartUtilities::stringToDartString(request->GetRequestString());
    ASSERT(!Dart_IsError(requestHandle));
    Dart_Handle addressHandle = Dart_NewInteger(requestAddress64);
    ASSERT(!Dart_IsError(addressHandle));
    result = Dart_ListSetAt(list, 0, requestHandle);
    ASSERT(!Dart_IsError(result));
    result = Dart_ListSetAt(list, 1, addressHandle);
    ASSERT(!Dart_IsError(result));
    return list;
}


void DartService::MakeServiceRequest(DartServiceRequest* request)
{
    ASSERT(m_isolate);
    // TODO(johnmccutchan): Once the VM service is no longer a DOM isolate,
    // we must be careful about entering the isolate.
    DartIsolateScope isolateScope(m_isolate);
    DartApiScope apiScope;
    Dart_Handle message = MakeServiceRequestMessage(request);
    if (Dart_IsError(message)) {
        return;
    }
    Dart_Handle library = Dart_RootLibrary();
    if (Dart_IsError(library)) {
        return;
    }
    Dart_Handle requestPortFieldName = Dart_NewStringFromCString("requestPort");
    Dart_Handle requestPort = Dart_GetField(library, requestPortFieldName);
    if (Dart_IsError(requestPort)) {
        return;
    }
    Dart_Port portId;
    Dart_Handle result = Dart_SendPortGetId(requestPort, &portId);
    if (Dart_IsError(result)) {
        return;
    }
    Dart_Post(portId, message);
}


Dart_Handle DartService::LoadScript()
{
    Dart_Handle url = Dart_NewStringFromCString("dart:vmservice_dartium");
    ASSERT(!Dart_IsError(url));
    intptr_t length = strlen(kScriptChars);
    Dart_Handle source = Dart_NewStringFromUTF8(reinterpret_cast<const uint8_t*>(kScriptChars), length);
    ASSERT(!Dart_IsError(source));
    Dart_Handle library = Dart_LoadScript(url, source, 0, 0);
    ASSERT(!Dart_IsError(library));
    Dart_Handle loadingFinalized = Dart_FinalizeLoading(true);
    if (Dart_IsError(loadingFinalized)) {
        return loadingFinalized;
    }
    return library;
}


static void PostResponse(Dart_NativeArguments args)
{
    Dart_Handle ALLOW_UNUSED result;
    Dart_Handle response = Dart_GetNativeArgument(args, 0);
    ASSERT(!Dart_IsError(response));
    Dart_Handle cookie = Dart_GetNativeArgument(args, 1);
    ASSERT(!Dart_IsError(cookie));
    int64_t requestAddress64 = 0;
    result = Dart_IntegerToInt64(cookie, &requestAddress64);
    ASSERT(!Dart_IsError(result));
    ASSERT(requestAddress64);
    intptr_t requestAddress = static_cast<intptr_t>(requestAddress64);
    ASSERT(requestAddress);
    DartServiceRequest* request = reinterpret_cast<DartServiceRequest*>(requestAddress);
    const char* responseString = 0;
    result = Dart_StringToCString(response, &responseString);
    ASSERT(!Dart_IsError(result));
    ASSERT(responseString);
    request->ResponseReady(responseString);
}


struct VmServiceNativeEntry {
    const char* name;
    int numArguments;
    Dart_NativeFunction function;
};


static VmServiceNativeEntry VmServiceNativeEntries[] = {
    {"VMService_PostResponse", 2, PostResponse}
};


Dart_NativeFunction DartService::NativeResolver(Dart_Handle name, int numArguments, bool* autoScopeSetup)
{
    const char* functionName = 0;
    Dart_Handle ALLOW_UNUSED result = Dart_StringToCString(name, &functionName);
    ASSERT(!Dart_IsError(result));
    ASSERT(functionName);
    ASSERT(autoScopeSetup);
    *autoScopeSetup = true;
    intptr_t n = sizeof(VmServiceNativeEntries) / sizeof(VmServiceNativeEntries[0]);
    for (intptr_t i = 0; i < n; i++) {
        VmServiceNativeEntry entry = VmServiceNativeEntries[i];
        if (!strcmp(functionName, entry.name) && (numArguments == entry.numArguments)) {
            return entry.function;
        }
    }
    return 0;
}

}
