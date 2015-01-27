// Copyright (c) 2013, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef DartService_h
#define DartService_h

#include "wtf/text/WTFString.h"

#include <dart_api.h>
#include <dart_native_api.h>

namespace blink {

class Document;

class DartServiceRequest {
public:
    DartServiceRequest(const String& request);
    virtual ~DartServiceRequest();

    // Override this method and it will be called when
    // the response has been received from the VM service.
    virtual void ResponseReady(const char* response) = 0;

    const String& GetRequestString() { return m_request; };
private:
    String m_request;
};

class DartService {
public:
    // Returns false if service could not be started.
    static bool Start(Document*);
    // Error message if startup failed.
    static const char* GetErrorMessage();
    static void MakeServiceRequest(DartServiceRequest*);
    static bool IsRunning() { return m_isolate; }

private:
    static Dart_Handle LoadScript();
    static Dart_NativeFunction NativeResolver(Dart_Handle name, int numArguments, bool* autoScopeSetup);
    static Dart_Isolate m_isolate;
    static const char* m_errorMsg;
    friend class DartServiceInternal;
};

}

#endif // DartService_h
