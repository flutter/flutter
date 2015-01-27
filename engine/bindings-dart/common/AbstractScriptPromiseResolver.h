// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef AbstractScriptPromiseResolver_h
#define AbstractScriptPromiseResolver_h

#include "bindings/common/ScriptPromise.h"
#include "bindings/common/ScriptState.h"
#include "bindings/core/v8/ScopedPersistent.h"
#include "bindings/core/v8/V8Binding.h"
#include "core/dom/ActiveDOMObject.h"
#include "core/dom/ExecutionContext.h"
#include "platform/Timer.h"
#include "wtf/RefCounted.h"
#include "wtf/Vector.h"
#include <v8.h>

namespace blink {

class BatteryManager;
class Blob;
class Cache;
class Credential;
class CryptoKey;
class DOMError;
class DOMException;
class ExecutionContext;
class FontFace;
class FontFaceSet;
class ImageBitmap;
class MIDIAccess;
class MediaKeySession;
class MediaKeys;
class PushRegistration;
class Response;
class ServiceWorker;
class ServiceWorkerClient;
class ServiceWorkerRegistration;
class StorageInfo;

// Do not add bool to this list, as it becomes the implicit conversion for types
// that are missing from this list. Use ScriptState::createBoolean instead.
#define PROMISE_RESOLUTION_TYPES_LIST(V)                          \
    V(AtomicString)                                               \
    V(BatteryManager*)                                            \
    V(Credential*)                                                \
    V(CryptoKey*)                                                 \
    V(MediaKeys*)                                                 \
    V(MIDIAccess*)                                                \
    V(PassRefPtr<ArrayBuffer>)                                    \
    V(PassRefPtr<BatteryManager>)                                 \
    V(PassRefPtr<Cache>)                                          \
    V(PassRefPtr<MediaKeySession>)                                \
    V(PassRefPtr<Response>)                                       \
    V(PassRefPtrWillBeRawPtr<Blob>)                               \
    V(PassRefPtrWillBeRawPtr<DOMError>)                           \
    V(PassRefPtrWillBeRawPtr<DOMException>)                       \
    V(PassRefPtrWillBeRawPtr<FontFace>)                           \
    V(PassRefPtrWillBeRawPtr<FontFaceSet>)                        \
    V(PassRefPtrWillBeRawPtr<ImageBitmap>)                        \
    V(PassRefPtrWillBeRawPtr<MIDIAccess>)                         \
    V(PassRefPtrWillBeRawPtr<ServiceWorker>)                      \
    V(PassRefPtrWillBeRawPtr<ServiceWorkerRegistration>)          \
    V(PushRegistration*)                                          \
    V(ScriptValue)                                                \
    V(ServiceWorker*)                                             \
    V(StorageInfo*)                                               \
    V(String)                                                     \
    V(WillBeHeapVector<RefPtrWillBeMember<ServiceWorkerClient> >) \
    V(Vector<String>)                                             \
    V(V8UndefinedType)                                            \
    V(WillBeHeapVector<RefPtrWillBeMember<FontFace> >)            \
    V(const char*)                                                \
    V(v8::Handle<v8::Value>)                                      \


// This class wraps v8::Promise::Resolver and provides the following
// functionalities.
//  - A ScriptPromiseResolver retains a ScriptState. A caller
//    can call resolve or reject from outside of a V8 context.
//  - This class is an ActiveDOMObject and keeps track of the associated
//    ExecutionContext state. When the ExecutionContext is suspended,
//    resolve or reject will be delayed. When it is stopped, resolve or reject
//    will be ignored.
class AbstractScriptPromiseResolver {
    WTF_MAKE_NONCOPYABLE(AbstractScriptPromiseResolver);
public:
    virtual ~AbstractScriptPromiseResolver() { }

    // Note that an empty ScriptPromise will be returned after resolve or
    // reject is called.
    virtual PassRefPtr<AbstractScriptPromise> promise() = 0;

    virtual void resolve() = 0;
    virtual void reject() = 0;

#define DECLARE_RESOLUTION_METHODS(type) \
    virtual void resolve(type) = 0; \
    virtual void reject(type) = 0;
PROMISE_RESOLUTION_TYPES_LIST(DECLARE_RESOLUTION_METHODS);
#undef DECLARE_RESOLUTION_METHODS

    // Once this function is called this resolver stays alive while the
    // promise is pending and the associated ExecutionContext isn't stopped.
    virtual void keepAliveWhilePending() = 0;

    virtual ScriptState* scriptState() = 0;
    virtual ScriptState* scriptState() const = 0;

    // Forwarded ActiveDOMObject implementation.
    virtual void suspend() = 0;
    virtual void resume() = 0;
    virtual void stop() = 0;

protected:
    // You need to call suspendIfNeeded after the construction because
    // this is an ActiveDOMObject.
    AbstractScriptPromiseResolver() { }
};

} // namespace blink

#endif // #ifndef AbstractScriptPromiseResolver_h
