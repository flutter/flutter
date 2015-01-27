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

#ifndef DartDOMWrapper_h
#define DartDOMWrapper_h

#include "bindings/common/ScriptValue.h"
#include "bindings/core/v8/Dictionary.h"
#include "bindings/core/dart/DartDOMData.h"
#include "bindings/core/dart/DartExceptionState.h"
#include "bindings/core/dart/DartUtilities.h"
#include "bindings/core/v8/SerializedScriptValue.h"
#include "bindings/dart/DartWebkitClassIds.h"
#include "core/dom/ExceptionCode.h"

#include "wtf/PassRefPtr.h"
#include "wtf/RefPtr.h"
#include "wtf/text/AtomicString.h"
#include "wtf/text/WTFString.h"
#include <dart_api.h>

namespace blink {

template<typename HTMLElement>
class DartCustomElementWrapper;
class HTMLElement;

template<class BindingsClass>
struct DartDOMWrapperTraits;

class DartDOMWrapper {
public:
    enum NativeFieldIndices {
        NativeImplementationIndex = 0,
        NativeTypeIndex = 1,
        NativeFieldCount
    };

    template <class BindingsClass>
    static Dart_WeakPersistentHandle lookupWrapper(DartDOMData* domData, typename BindingsClass::NativeType* domObject)
    {
        typedef DartDOMWrapperTraits<BindingsClass> Traits;
        ASSERT(domObject);
        ASSERT(domData);
        if (ScriptWrappable::wrapperCanBeStoredInObject(domObject)) {
            Dart_WeakPersistentHandle wrapper = (Dart_WeakPersistentHandle)(ScriptWrappable::fromObject(domObject)->getDartWrapper(domData));
            return wrapper;
        }
        return Traits::MapTraits::domMap(domData)->get(domObject);
    }

    template <class BindingsClass>
    static Dart_Handle createWrapper(DartDOMData* domData, typename BindingsClass::NativeType* domObject)
    {
        return createWrapper<BindingsClass>(
            domData,
            domObject,
            BindingsClass::dartClassId);
    }

    template <class BindingsClass>
    static Dart_Handle createWrapper(
        DartDOMData* domData, typename BindingsClass::NativeType* domObject,
        intptr_t cid)
    {
        ASSERT(domData);
        ASSERT(domObject);
        Dart_PersistentHandle type = dartClass(domData, cid);
        ASSERT(!Dart_IsError(type));
        intptr_t nativeFields[NativeFieldCount];
        nativeFields[NativeImplementationIndex] = reinterpret_cast<intptr_t>(domObject);
        nativeFields[NativeTypeIndex] = cid;
        Dart_Handle wrapper = Dart_AllocateWithNativeFields(type, NativeFieldCount, nativeFields);
        if (Dart_IsError(wrapper)) {
            return wrapper;
        }
        associateWrapper<BindingsClass>(domData, domObject, wrapper);
        return wrapper;
    }

    template<class BindingsClass>
    static Dart_Handle vectorToDart(const Vector< RefPtr<typename BindingsClass::NativeType> >& vector)
    {
        return DartUtilities::vectorToDart<RefPtr<typename BindingsClass::NativeType>, PassRefPtr<typename BindingsClass::NativeType>, BindingsClass::toDart>(vector);
    }

    template<class BindingsClass>
    static Dart_Handle vectorToDart(const HeapVector< Member<typename BindingsClass::NativeType> >& vector)
    {
        return DartUtilities::vectorToDart<typename BindingsClass::NativeType, BindingsClass::toDart>(vector);
    }

    static Dart_Handle vectorToDart(const Vector<float>& vector)
    {
        // If this is hot, consider using a Float32List instead.
        return DartUtilities::vectorToDart<float, double, DartUtilities::doubleToDart>(vector);
    }

    static Dart_Handle vectorToDart(const Vector<double>& vector)
    {
        // If this is hot, consider using a Float32List instead.
        return DartUtilities::vectorToDart<double, double, DartUtilities::doubleToDart>(vector);
    }

    static Dart_Handle vectorToDart(const Vector<unsigned>& vector)
    {
        // If this is hot, consider using a typed array instead.
        return DartUtilities::vectorToDart<unsigned, unsigned, DartUtilities::unsignedToDart>(vector);
    }

    static Dart_Handle vectorToDart(const Vector<String>& vector)
    {
        return DartUtilities::vectorToDart<String, const String&, DartUtilities::stringToDart>(vector);
    }

    template<class T>
    static Dart_Handle vectorToDartNullable(Nullable<T> vector)
    {
        if (vector.isNull())
            return Dart_Null();
        return vectorToDart(vector.get());
    }

    template<class BindingsClass>
    static Dart_Handle vectorToDartNullable(Nullable< Vector< RefPtr<typename BindingsClass::NativeType> > > vector)
    {
        if (vector.isNull())
            return Dart_Null();
        return vectorToDart<BindingsClass>(vector.get());
    }

    template <class BindingsClass>
    static typename BindingsClass::NativeType* unwrapDartWrapper(
        DartDOMData* domData, Dart_Handle wrapper, Dart_Handle& exception)
    {
        ASSERT(!exception);

        if (Dart_IsNull(wrapper))
            return 0;

        if (subtypeOf(wrapper, BindingsClass::dartClassId)) {
            void* nativePointer = readNativePointer(wrapper, NativeImplementationIndex);
            return static_cast<typename BindingsClass::NativeType*>(nativePointer);
        }
        const char* className = DartWebkitClassInfo[BindingsClass::dartClassId].jsName;
        String message = String("Invalid class: expected instance of ") +
            className;
        exception = DartUtilities::stringToDartString(message);
        return 0;
    }

    template <class BindingsClass>
    static typename BindingsClass::NativeType* unwrapDartWrapper(
        Dart_NativeArguments args, int index, Dart_Handle& exception)
    {
        ASSERT(!exception);
        intptr_t fieldValues[NativeFieldCount];
        Dart_Handle result = Dart_GetNativeFieldsOfArgument(args, index, NativeFieldCount, fieldValues);
        if (!Dart_IsError(result)) {
            void* wrapper = reinterpret_cast<void*>(fieldValues[NativeImplementationIndex]);
            if (!wrapper) {
                return 0;
            }
            intptr_t cid = fieldValues[NativeTypeIndex];
            if (subtypeOf(cid, BindingsClass::dartClassId)) {
                // FIXME(vsm): This is not safe if BindingsClass::NativeType is
                // not the primary parent.
                return static_cast<typename BindingsClass::NativeType*>(wrapper);
            }
        }
        const char* className = DartWebkitClassInfo[BindingsClass::dartClassId].jsName;
        String message = String("Invalid class: expected instance of ") + className;
        exception = DartUtilities::stringToDartString(message);
        return 0;
    }

    static bool subtypeOf(Dart_Handle wrapper, intptr_t basecid)
    {
        intptr_t cid = reinterpret_cast<intptr_t>(readNativePointer(wrapper, NativeTypeIndex));
        return subtypeOf(cid, basecid);
    }

    static bool subtypeOf(intptr_t cid, intptr_t basecid)
    {
        while (cid != -1) {
            if (cid == basecid) {
                return true;
            }
            ASSERT(cid < NumWebkitClassIds);
            cid = DartWebkitClassInfo[cid].base_class_id;
        }
        return false;
    }

    template <class BindingsClass>
    static bool instanceOf(DartDOMData* domData, Dart_Handle wrapper)
    {
        Dart_PersistentHandle type = dartClass(domData, BindingsClass::dartClassId);

        bool isInstanceOf = false;
        Dart_Handle ALLOW_UNUSED result = Dart_ObjectIsType(wrapper, type, &isInstanceOf);
        ASSERT(!Dart_IsError(result));
        return isInstanceOf;
    }

    template <class WebKitClass>
    static WebKitClass* receiver(Dart_NativeArguments args)
    {
        // Type of receiver is ensured by Dart VM runtime, so bypass additional checks.
        intptr_t value = 0;
        ASSERT(!NativeImplementationIndex);
        Dart_Handle ALLOW_UNUSED result = Dart_GetNativeReceiver(args, &value);
        ASSERT(!Dart_IsError(result));
        WebKitClass* const recv = reinterpret_cast<WebKitClass*>(value);
        ASSERT(recv); // Should never return 0.
        return recv;
    }

    static EventTarget* receiverToEventTarget(Dart_NativeArguments args)
    {
        // If the receiver is an EventTarget, we cannot just do a static cast
        // from void* to EventTarget due to multiple inheritance.
        // Instead, we need to invoke toEventTarget on the dynamic type.
        intptr_t fieldValues[NativeFieldCount];
        Dart_Handle result = Dart_GetNativeFieldsOfArgument(args, 0, NativeFieldCount, fieldValues);
        if (!Dart_IsError(result)) {
            void* wrapper = reinterpret_cast<void*>(fieldValues[NativeImplementationIndex]);
            if (!wrapper) {
                ASSERT_NOT_REACHED();
                return 0;
            }
            intptr_t cid = fieldValues[NativeTypeIndex];
            ASSERT(subtypeOf(cid, EventTargetClassId));
            return DartWebkitClassInfo[cid].toEventTarget(wrapper);
        }
        ASSERT_NOT_REACHED();
        return 0;
    }

    template <class BindingsClass>
    static void returnToDart(Dart_NativeArguments args, typename BindingsClass::NativeType* domObject)
    {
        if (domObject) {
            DartDOMData* domData = static_cast<DartDOMData*>(Dart_GetNativeIsolateData(args));
            Dart_WeakPersistentHandle result = lookupWrapper<BindingsClass>(domData, domObject);
            if (result)
                Dart_SetWeakHandleReturnValue(args, result);
            else
                Dart_SetReturnValue(args, createWrapper<BindingsClass>(domData, domObject, BindingsClass::dartClassId));
        }
    }

    template <class BindingsClass>
    static void returnToDart(Dart_NativeArguments args, PassRefPtr<typename BindingsClass::NativeType> domObject)
    {
        returnToDart<BindingsClass>(args, domObject.get());
    }

    static int wrapperNativeFieldCount() { return NativeFieldCount; }

private:
    static Dart_PersistentHandle dartClass(DartDOMData*, intptr_t classIndex);

    static void writeNativePointer(Dart_Handle wrapper, void* pointer, intptr_t cid)
    {
        Dart_Handle ALLOW_UNUSED result = Dart_SetNativeInstanceField(
            wrapper, NativeImplementationIndex, reinterpret_cast<intptr_t>(pointer));
        ASSERT(!Dart_IsError(result));
        result = Dart_SetNativeInstanceField(wrapper, NativeTypeIndex, cid);
        ASSERT(!Dart_IsError(result));
    }

    static void* readNativePointer(Dart_Handle wrapper, int index)
    {
        intptr_t value;
        Dart_Handle result = Dart_GetNativeInstanceField(wrapper, index, &value);
        // FIXME: the fact that we return 0 on error rather than asserting is
        // somewhat of a hack. We currently make this method return 0 because
        // we reuse this method to verify that objects are actually native
        // Node objects rather than objects that implement the Node interface.
        if (Dart_IsError(result))
            return 0;
        return reinterpret_cast<void*>(value);
    }

    template <class BindingsClass>
    static void wrapperWeakCallback(void* isolateCallbackData, Dart_WeakPersistentHandle wrapper, void* blinkHandle)
    {
        typedef DartDOMWrapperTraits<BindingsClass> Traits;
        DartDOMData* domData = reinterpret_cast<DartDOMData*>(isolateCallbackData);
        typename BindingsClass::NativeType* domObject = Traits::GCTraits::read(blinkHandle);

        Dart_WeakPersistentHandle currentWrapper = 0;
        if (ScriptWrappable::wrapperCanBeStoredInObject(domObject)) {
            currentWrapper = (Dart_WeakPersistentHandle)(ScriptWrappable::fromObject(domObject)->getDartWrapper(domData));
        } else {
            currentWrapper = Traits::MapTraits::domMap(domData)->get(domObject);
        }

        // This could be an old wrapper which has been replaced with a custom element.
        if (currentWrapper != wrapper) {
#ifdef DEBUG
            DartApiScope scope;
            ASSERT(!Dart_IdentityEquals(Dart_HandleFromWeakPersistent(currentWrapper), Dart_HandleFromWeakPersistent(wrapper)));
#endif
            return;
        }

        if (currentWrapper) {
            if (ScriptWrappable::wrapperCanBeStoredInObject(domObject)) {
                ScriptWrappable::fromObject(domObject)->clearDartWrapper(domData);
            } else {
                Traits::MapTraits::domMap(domData)->remove(domObject);
            }
        }
        Traits::GCTraits::deref(blinkHandle);
    }

    template <class BindingsClass>
    static void associateWrapper(
        DartDOMData* domData, typename BindingsClass::NativeType* domObject, Dart_Handle newInstance)
    {
        typedef DartDOMWrapperTraits<BindingsClass> Traits;
        void* blinkHandle = Traits::GCTraits::ref(domObject);
        // This is only used to inform the Dart garbage collector on how much external memory
        // is kept alive.
        intptr_t externalAllocationSize = sizeof(*domObject);

        Dart_WeakPersistentHandle wrapper = Dart_NewPrologueWeakPersistentHandle(
            newInstance, blinkHandle, externalAllocationSize, &wrapperWeakCallback<BindingsClass>);
        if (ScriptWrappable::wrapperCanBeStoredInObject(domObject)) {
            ScriptWrappable::fromObject(domObject)->setDartWrapper(domData, wrapper);
        } else {
            Traits::MapTraits::domMap(domData)->set(domObject, wrapper);
        }
    }

    template <class BindingsClass>
    static void disassociateWrapper(
        DartDOMData* domData, typename BindingsClass::NativeType* domObject, Dart_Handle oldInstance)
    {
        typedef DartDOMWrapperTraits<BindingsClass> Traits;

        if (ScriptWrappable::wrapperCanBeStoredInObject(domObject)) {
#ifdef DEBUG
            Dart_WeakPersistentHandle wrapper = (Dart_WeakPersistentHandle)(ScriptWrappable::fromObject(domObject)->getDartWrapper(domData));
            ASSERT(Dart_IdentityEquals(Dart_HandleFromWeakPersistent(wrapper), oldInstance));
#endif
            ScriptWrappable::fromObject(domObject)->clearDartWrapper(domData);
        } else {
#ifdef DEBUG
            Dart_WeakPersistentHandle wrapper = Traits::MapTraits::domMap(domData)->get(domObject);
            ASSERT(Dart_IdentityEquals(Dart_HandleFromWeakPersistent(wrapper), oldInstance));
#endif
            Traits::MapTraits::domMap(domData)->remove(domObject);
        }
    }

    friend class DartCustomElementConstructorBuilder;
    friend class DartCustomElementWrapper<HTMLElement>;
    friend class DartUtilities;
};

struct DartDOMWrapperMapTraits {
    static DartDOMObjectMap* domMap(DartDOMData* domData) { return domData->objectMap(); }
};

template<class BindingsClass, bool isGarbageCollected>
struct DartDOMWrapperGarbageCollectedTraits { };

template<class BindingsClass>
struct DartDOMWrapperGarbageCollectedTraits<BindingsClass, false> {
    static void* ref(typename BindingsClass::NativeType* domObject)
    {
        domObject->ref();
        return domObject;
    }

    static void deref(void* blinkHandle)
    {
        typename BindingsClass::NativeType* domObject = read(blinkHandle);
        domObject->deref();
    }

    static typename BindingsClass::NativeType* read(void* blinkHandle)
    {
        return static_cast<typename BindingsClass::NativeType*>(blinkHandle);
    }
};

template<class BindingsClass>
struct DartDOMWrapperGarbageCollectedTraits<BindingsClass, true> {
    static void* ref(typename BindingsClass::NativeType* domObject)
    {
        return new Persistent<typename BindingsClass::NativeType>(domObject);
    }

    static void deref(void* blinkHandle)
    {
        Persistent<typename BindingsClass::NativeType>* handle = static_cast<Persistent<typename BindingsClass::NativeType>*>(blinkHandle);
        delete handle;
    }

    static typename BindingsClass::NativeType* read(void* blinkHandle)
    {
        Persistent<typename BindingsClass::NativeType>* handle = static_cast<Persistent<typename BindingsClass::NativeType>*>(blinkHandle);
        return handle->get();
    }
};

template<class BindingsClass>
struct DartDOMWrapperTraits {
    typedef DartDOMWrapperMapTraits MapTraits;
    typedef DartDOMWrapperGarbageCollectedTraits<BindingsClass, BindingsClass::isGarbageCollected> GCTraits;
};

struct DartMessagePort;

template<>
struct DartDOMWrapperTraits<DartMessagePort> {
    struct MessagePortMapTraits {
        static DartMessagePortMap* domMap(DartDOMData* domData) { return domData->messagePortMap(); }
    };
    typedef MessagePortMapTraits MapTraits;
    typedef DartDOMWrapperGarbageCollectedTraits<DartMessagePort, false> GCTraits;
};

}

#endif // DartDOMWrapper_h
