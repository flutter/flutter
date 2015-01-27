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

#ifndef DartUtilities_h
#define DartUtilities_h

#if OS(ANDROID)
#include <sys/system_properties.h>
#endif


#include "bindings/common/ScriptPromise.h"
#include "bindings/core/v8/Dictionary.h"
#include "bindings/core/dart/DartDOMData.h"
#include "bindings/core/dart/DartScriptValue.h"
#include "bindings/core/dart/DartStringCache.h"
#include "bindings/core/v8/SerializedScriptValue.h"
#include "bindings/core/v8/V8RecursionScope.h"
#include "bindings/core/v8/V8ScriptState.h"
#include "bindings/dart/DartWebkitClassIds.h"
#include "core/dom/DOMStringList.h"
#include "core/dom/MessagePort.h"
#include "core/inspector/ScriptCallFrame.h"
#include "modules/mediastream/MediaStreamTrack.h"
#include "platform/heap/Heap.h"

#include "wtf/ArrayBufferView.h"
#include "wtf/Float32Array.h"
#include "wtf/HashMap.h"
#include "wtf/ListHashSet.h"
#include "wtf/Uint8Array.h"
#include "wtf/text/WTFString.h"
#include <dart_api.h>
#include <dart_debugger_api.h>

namespace WTF {
class ArrayBuffer;
class Uint8ClampedArray;
}

namespace blink {

class Dictionary;
class Frame;
class SQLValue;
class ScriptArguments;
class ScriptCallStack;
class ExecutionContext;
class SerializedScriptValue;

class DartStringPeer {
public:
    explicit DartStringPeer(PassRefPtr<StringImpl> stringImpl)
        : m_plainString(stringImpl), m_atomicString(), m_atomicCached(false)
    {
    }

    explicit DartStringPeer(StringImpl* stringImpl)
        : m_plainString(stringImpl), m_atomicString(), m_atomicCached(false)
    {
    }

    const String& toString() const { return m_plainString; }
    const AtomicString& toAtomicString()
    {
        if (m_atomicCached)
            return m_atomicString;
        return toAtomicStringSlow();
    }
    const AtomicString& toAtomicStringSlow()
    {
        if (!m_plainString.isNull()) {
            m_atomicString = AtomicString(m_plainString);
            ASSERT(!m_atomicString.isNull());
        }
        m_atomicCached = true;
        return m_atomicString;
    }
    static DartStringPeer* nullString();
    static DartStringPeer* emptyString();

private:
    DartStringPeer() : m_plainString(), m_atomicString()
    {
    }

    String m_plainString;
    AtomicString m_atomicString;
    bool m_atomicCached;
};

class DartStringAdapter {
public:
    explicit DartStringAdapter(DartStringPeer* stringPeer) : m_stringPeer(stringPeer)
    {
        ASSERT(stringPeer);
    }

    operator String() const { return m_stringPeer->toString(); }
    operator AtomicString() const { return m_stringPeer->toAtomicString(); }

private:
    DartStringPeer* m_stringPeer;
};

class DartApiScope {
public:
    DartApiScope() { Dart_EnterScope(); }
    ~DartApiScope() { Dart_ExitScope(); }
};

class DartUtilities {
public:
    static Dart_Handle stringImplToDartString(StringImpl*);
    static Dart_Handle stringToDartString(const String&);
    static Dart_Handle stringToDartString(const AtomicString&);
    static Dart_Handle safeStringImplToDartString(StringImpl*);
    static Dart_Handle safeStringToDartString(const String&);
    static Dart_Handle safeStringToDartString(const AtomicString&);

    static Dart_Handle errorToException(Dart_Handle error)
    {
        ASSERT(Dart_IsError(error));
        if (Dart_ErrorHasException(error))
            return Dart_ErrorGetException(error);
        return Dart_NewStringFromCString(Dart_GetError(error));
    }

    static bool checkResult(Dart_Handle result, Dart_Handle& exception)
    {
        if (!Dart_IsError(result))
            return true;

        exception = errorToException(result);
        return false;
    }

    static void extractListElements(Dart_Handle list, Dart_Handle& exception, Vector<Dart_Handle>& elements);
    static Dart_Handle toList(const Vector<Dart_Handle>& elements, Dart_Handle& exception);

    static void extractMapElements(Dart_Handle map, Dart_Handle& exception, HashMap<String, Dart_Handle>& elements);

    static int64_t toInteger(Dart_Handle, Dart_Handle& exception);
    static String toString(Dart_Handle);
    static void toMessagePortArray(Dart_Handle, MessagePortArray&, ArrayBufferArray&, Dart_Handle& exception);
    static PassRefPtr<SerializedScriptValue> toSerializedScriptValue(Dart_Handle, MessagePortArray*, ArrayBufferArray*, Dart_Handle& exception);
    static SQLValue toSQLValue(Dart_Handle, Dart_Handle& exception);
    template <class T, class Convertor>
    static void toVector(Convertor convertor, Dart_Handle object, Vector<T>& result, Dart_Handle& exception)
    {
        ASSERT(Dart_IsList(object));
        ASSERT(result.isEmpty());

        Vector<Dart_Handle> handles;
        DartUtilities::extractListElements(object, exception, handles);
        if (exception)
            return;

        for (unsigned i = 0; i < handles.size(); ++i) {
            result.append(convertor(handles[i], exception));
            if (exception)
                return;
        }
    }
    template <class T, class Convertor>
    static void toVector(Convertor convertor, Dart_Handle object, HeapVector<Member<T> >& result, Dart_Handle& exception)
    {
        ASSERT(Dart_IsList(object));
        ASSERT(result.isEmpty());

        Vector<Dart_Handle> handles;
        DartUtilities::extractListElements(object, exception, handles);
        if (exception)
            return;

        for (unsigned i = 0; i < handles.size(); ++i) {
            result.append(convertor(handles[i], exception));
            if (exception)
                return;
        }
    }

    template <class T>
    struct TypeConvertor { };

    template <class T>
    static void toNativeVector(Dart_Handle object, Vector<T>& result, Dart_Handle& exception)
    {
        toVector(TypeConvertor<T>(), object, result, exception);
    }
    template <class T>
    static void toNativeVector(Dart_NativeArguments args, int idx, Vector<T>& result, Dart_Handle& exception)
    {
        Dart_Handle object = Dart_GetNativeArgument(args, idx);
        toVector(TypeConvertor<T>(), object, result, exception);
    }

    template <class T>
    static void toNativeVector(Dart_Handle object, HeapVector<Member<T> >& result, Dart_Handle& exception)
    {
        toVector(TypeConvertor<T>(), object, result, exception);
    }
    template <class T>
    static void toNativeVector(Dart_NativeArguments args, int idx, HeapVector<Member<T> >& result, Dart_Handle& exception)
    {
        Dart_Handle object = Dart_GetNativeArgument(args, idx);
        toVector(TypeConvertor<T>(), object, result, exception);
    }

    static Dart_Handle listHashSetToDartList(ListHashSet<String> set, Dart_Handle& exception)
    {
        Dart_Handle result = Dart_NewList(set.size());
        if (!DartUtilities::checkResult(result, exception))
            return Dart_Null();

        ListHashSet<String>::const_iterator end = set.end();
        int index = 0;
        for (ListHashSet<String>::const_iterator it = set.begin(); it != end; ++it, ++index)
            Dart_ListSetAt(result, index, DartUtilities::stringToDartString(*it));
        return result;
    }

    static Dictionary dartToDictionary(Dart_Handle, Dart_Handle& exception);
    static Dictionary dartToDictionaryWithNullCheck(Dart_Handle, Dart_Handle& exception);
    static Dictionary dartToDictionary(Dart_NativeArguments args, int idx, Dart_Handle& exception);
    static Dictionary dartToDictionaryWithNullCheck(Dart_NativeArguments args, int idx, Dart_Handle& exception);

    static LocalDOMWindow* domWindowForCurrentIsolate();
    static LocalDOMWindow* enteredDomWindowForCurrentIsolate()
    {
        // FIXME: Add check to enforce this is the right window.
        return domWindowForCurrentIsolate();
    }

    static LocalDOMWindow* callingDomWindowForCurrentIsolate()
    {
        // FIXME: Add check to enforce this is the right window.
        return domWindowForCurrentIsolate();
    }

    static V8ScriptState* v8ScriptStateForCurrentIsolate();

    static ExecutionContext* scriptExecutionContext();
    // FIXMEDART: Should have a variant that takes a Dart_NativeArguments to avoid TLS.
    static DartScriptState* currentScriptState();

    static bool processingUserGesture();

    static PassRefPtr<ScriptArguments> createScriptArguments(Dart_Handle argument, Dart_Handle& exception);

    static PassRefPtr<ScriptCallStack> createScriptCallStack();
    static ScriptCallFrame getTopFrame(Dart_StackTrace, Dart_Handle& exception);
    static ScriptCallFrame toScriptCallFrame(Dart_ActivationFrame, Dart_Handle& exception);

    static const uint8_t* fullSnapshot(LocalFrame*);

    static Dart_Handle canonicalizeUrl(Dart_Handle library, Dart_Handle urlHandle, String url);

    static void reportProblem(ExecutionContext*, const String&, int line = 0, int col = 0);
    static void reportProblem(ExecutionContext*, Dart_Handle);
    static void reportProblem(ExecutionContext*, Dart_Handle, const String& sourceURL);

    static Dart_Handle toDartCoreException(const String &className, const String& message);

    static Dart_Handle coreArgumentErrorException(const String& message);

    static Dart_Handle invalidNumberOfArgumentsException()
    {
        return Dart_NewStringFromCString("Invalid number of arguments");
    }

    static Dart_Handle conditionalFunctionalityException()
    {
        return Dart_NewStringFromCString("Ooops, this functionality is not enabled in this browser");
    }

    static Dart_Handle notImplementedException(const char* fileName, int lineNumber);

    static Dart_Handle internalErrorException(const char* msg)
    {
        // FIXME: wrap into proper type.
        return Dart_NewStringFromCString(msg);
    }

    static Dart_Handle newResolvedPromise(Dart_Handle value);
    static Dart_Handle newSmashedPromise(Dart_Handle error);
    static Dart_Handle newResolver();
    static Dart_Handle newArgumentError(const String& message);

    static Dart_Handle invokeUtilsMethod(const char* methodName, int argCount, Dart_Handle* args);

    static Dart_Handle convertSourceString(const String& source)
    {
        // FIXME: Decide whether to externalize this here.
        const CString utf8encoded = source.utf8();
        return Dart_NewStringFromUTF8(
            reinterpret_cast<const uint8_t*>(utf8encoded.data()),
            utf8encoded.length());
    }

    static DartStringAdapter dartToString(Dart_Handle object, Dart_Handle& exception)
    {
        intptr_t charsize = 0;
        intptr_t strlength = 0;
        void* peer = 0;
        Dart_Handle result = Dart_StringGetProperties(object, &charsize, &strlength, &peer);
        if (peer) {
            return DartStringAdapter(reinterpret_cast<DartStringPeer*>(peer));
        }
        if (Dart_IsError(result)) {
            exception = Dart_NewStringFromCString("String Expected");
            return DartStringAdapter(DartStringPeer::nullString());
        }
        return dartToStringImpl(object, exception, true);
    }
    static DartStringAdapter dartToString(Dart_NativeArguments args, int index, Dart_Handle& exception, bool autoDartScope = true)
    {
        void* peer = 0;
        Dart_Handle object = Dart_GetNativeStringArgument(args, index, &peer);
        if (peer) {
            return DartStringAdapter(reinterpret_cast<DartStringPeer*>(peer));
        }
        if (Dart_IsError(object)) {
            exception = Dart_NewStringFromCString("String Expected");
            return DartStringAdapter(DartStringPeer::nullString());
        }
        return dartToStringImpl(object, exception, autoDartScope);
    }
    static DartStringAdapter dartToStringWithNullCheck(Dart_NativeArguments args, int index, Dart_Handle& exception, bool autoDartScope = true)
    {
        void* peer = 0;
        Dart_Handle object = Dart_GetNativeStringArgument(args, index, &peer);
        if (peer) {
            return DartStringAdapter(reinterpret_cast<DartStringPeer*>(peer));
        }
        if (Dart_IsNull(object)) {
            return DartStringAdapter(DartStringPeer::nullString());
        }
        return dartToString(args, index, exception, autoDartScope);
    }
    static DartStringAdapter dartToStringWithEmptyCheck(Dart_NativeArguments args, int index, Dart_Handle& exception, bool autoDartScope = true)
    {
        void* peer = 0;
        Dart_Handle object = Dart_GetNativeStringArgument(args, index, &peer);
        if (peer) {
            return DartStringAdapter(reinterpret_cast<DartStringPeer*>(peer));
        }
        if (Dart_IsNull(object)) {
            return DartStringAdapter(DartStringPeer::emptyString());
        }
        return dartToString(args, index, exception, autoDartScope);
    }
    static Dart_Handle stringToDart(const AtomicString& value)
    {
        DartDOMData* domData = DartDOMData::current();
        StringImpl* stringImpl = value.impl();
        if (!stringImpl) {
            return domData->emptyString();
        }
        return Dart_HandleFromWeakPersistent(domData->stringCache().get(stringImpl));
    }
    static Dart_Handle stringToDart(const String& value)
    {
        DartDOMData* domData = DartDOMData::current();
        StringImpl* stringImpl = value.impl();
        if (!stringImpl) {
            return domData->emptyString();
        }
        return Dart_HandleFromWeakPersistent(domData->stringCache().get(stringImpl));
    }
    template <class StringClass>
    static Dart_Handle stringToDartWithNullCheck(const StringClass& value)
    {
        if (value.isNull())
            return Dart_Null();
        return stringToDart(value);
    }
    static void setDartUnsignedReturnValue(Dart_NativeArguments args, unsigned value)
    {
        Dart_SetIntegerReturnValue(args, value);
    }
    static void setDartUnsignedLongLongReturnValue(Dart_NativeArguments args, unsigned long long value)
    {
        // FIXME: WebIDL unsigned long long is guaranteed to fit into 64-bit unsigned,
        // so we need a dart API for constructing an integer from uint64_t.
        ASSERT(value <= 0x7fffffffffffffffLL);
        Dart_SetIntegerReturnValue(args, static_cast<int64_t>(value));
    }
    static void setDartIntegerReturnValue(Dart_NativeArguments args, int64_t value)
    {
        Dart_SetIntegerReturnValue(args, value);
    }
    static void setDartStringReturnValue(Dart_NativeArguments args, const AtomicString& value, bool autoDartScope = true)
    {
        DartDOMData* domData = static_cast<DartDOMData*>(Dart_GetNativeIsolateData(args));
        StringImpl* stringImpl = value.impl();
        if (!stringImpl) {
            Dart_SetReturnValue(args, domData->emptyString());
        } else {
            Dart_SetWeakHandleReturnValue(args, domData->stringCache().get(value.impl(), autoDartScope));
        }
    }
    static void setDartStringReturnValue(Dart_NativeArguments args, const String& value, bool autoDartScope = true)
    {
        DartDOMData* domData = static_cast<DartDOMData*>(Dart_GetNativeIsolateData(args));
        StringImpl* stringImpl = value.impl();
        if (!stringImpl) {
            Dart_SetReturnValue(args, domData->emptyString());
        } else {
            Dart_SetWeakHandleReturnValue(args, domData->stringCache().get(value.impl(), autoDartScope));
        }
    }
    static void setDartStringReturnValueWithNullCheck(
        Dart_NativeArguments args, const AtomicString& value, bool autoDartScope = true)
    {
        if (value.isNull()) {
            Dart_SetReturnValue(args, Dart_Null());
        } else {
            setDartStringReturnValue(args, value, autoDartScope);
        }
    }
    static void setDartStringReturnValueWithNullCheck(Dart_NativeArguments args, const String& value, bool autoDartScope = true)
    {
        if (value.isNull()) {
            Dart_SetReturnValue(args, Dart_Null());
        } else {
            setDartStringReturnValue(args, value, autoDartScope);
        }
    }

    // ScalarValueString helpers. ScalarValueString is identical to DOMString
    // except that "convert a DOMString to a sequence of Unicode characters".

    static DartStringAdapter dartToScalarValueString(Dart_Handle object, Dart_Handle& exception)
    {
        intptr_t charsize = 0;
        intptr_t strlength = 0;
        void* peer = 0;
        Dart_Handle result = Dart_StringGetProperties(object, &charsize, &strlength, &peer);
        if (peer) {
            return DartStringAdapter(reinterpret_cast<DartStringPeer*>(peer));
        }
        if (Dart_IsError(result)) {
            exception = Dart_NewStringFromCString("String Expected");
            return DartStringAdapter(DartStringPeer::nullString());
        }
        // TODO(terry): Need to implement similar code to replace with UTF-16
        //              with valid unicode. See V8Bindings.h implementation.
        return dartToStringImpl(object, exception, true);
    }
    static DartStringAdapter dartToScalarValueString(Dart_NativeArguments args, int index, Dart_Handle& exception, bool autoDartScope = true)
    {
        void* peer = 0;
        Dart_Handle object = Dart_GetNativeStringArgument(args, index, &peer);
        if (peer) {
            return DartStringAdapter(reinterpret_cast<DartStringPeer*>(peer));
        }
        if (Dart_IsError(object)) {
            exception = Dart_NewStringFromCString("String Expected");
            return DartStringAdapter(DartStringPeer::nullString());
        }
        // TODO(terry): Need to implement similar code to replace with UTF-16
        //              with valid unicode. See V8Bindings.h implementation.
        return dartToStringImpl(object, exception, autoDartScope);
    }
    static DartStringAdapter dartToScalarValueStringWithNullCheck(Dart_NativeArguments args, int index, Dart_Handle& exception, bool autoDartScope = true)
    {
        void* peer = 0;
        Dart_Handle object = Dart_GetNativeStringArgument(args, index, &peer);
        if (peer) {
            return DartStringAdapter(reinterpret_cast<DartStringPeer*>(peer));
        }
        if (Dart_IsNull(object)) {
            return DartStringAdapter(DartStringPeer::nullString());
        }
        return dartToScalarValueString(args, index, exception, autoDartScope);
    }
    static void setDartScalarValueStringReturnValue(Dart_NativeArguments args, const AtomicString& value, bool autoDartScope = true)
    {
        DartDOMData* domData = static_cast<DartDOMData*>(Dart_GetNativeIsolateData(args));
        StringImpl* stringImpl = value.impl();
        if (!stringImpl) {
            Dart_SetReturnValue(args, domData->emptyString());
        } else {
            // TODO(terry): Need to implement similar code to replace with UTF-16
            //              with valid unicode. See V8Bindings.h implementation.
        }
    }
    static void setDartScalarValueStringReturnValue(Dart_NativeArguments args, const String& value, bool autoDartScope = true)
    {
        DartDOMData* domData = static_cast<DartDOMData*>(Dart_GetNativeIsolateData(args));
        StringImpl* stringImpl = value.impl();
        if (!stringImpl) {
            Dart_SetReturnValue(args, domData->emptyString());
        } else {
            // TODO(terry): Need to implement similar code to replace with UTF-16
            //              with valid unicode. See V8Bindings.h implementation.
        }
    }
    static void setDartScalarValueStringReturnValueWithNullCheck(
        Dart_NativeArguments args, const AtomicString& value, bool autoDartScope = true)
    {
        if (value.isNull()) {
            Dart_SetReturnValue(args, Dart_Null());
        } else {
            setDartScalarValueStringReturnValue(args, value, autoDartScope);
        }
    }
    static void setDartScalarValueStringReturnValueWithNullCheck(Dart_NativeArguments args, const String& value, bool autoDartScope = true)
    {
        if (value.isNull()) {
            Dart_SetReturnValue(args, Dart_Null());
        } else {
            setDartScalarValueStringReturnValue(args, value, autoDartScope);
        }
    }

    // ByteString helpers. Converts a value to a String, throwing if any code
    // unit is outside 0-255.

    static DartStringAdapter dartToByteString(Dart_Handle object, Dart_Handle& exception)
    {
        intptr_t charsize = 0;
        intptr_t strlength = 0;
        void* peer = 0;
        Dart_Handle result = Dart_StringGetProperties(object, &charsize, &strlength, &peer);
        if (peer) {
            return DartStringAdapter(reinterpret_cast<DartStringPeer*>(peer));
        }
        if (Dart_IsError(result)) {
            exception = Dart_NewStringFromCString("String Expected");
            return DartStringAdapter(DartStringPeer::nullString());
        }
        // TODO(terry): Need to implement similar code to toByteString see
        //              bindings/core/v8/V8Bindings.h for implementation.
        return dartToStringImpl(object, exception, true);
    }
    static DartStringAdapter dartToByteString(Dart_NativeArguments args, int index, Dart_Handle& exception, bool autoDartScope = true)
    {
        void* peer = 0;
        Dart_Handle object = Dart_GetNativeStringArgument(args, index, &peer);
        if (peer) {
            return DartStringAdapter(reinterpret_cast<DartStringPeer*>(peer));
        }
        if (Dart_IsError(object)) {
            exception = Dart_NewStringFromCString("String Expected");
            return DartStringAdapter(DartStringPeer::nullString());
        }
        // TODO(terry): Need to implement similar code to toByteString see
        //              bindings/core/v8/V8Bindings.h for implementation.
        return dartToStringImpl(object, exception, autoDartScope);
    }
    static DartStringAdapter dartToByteStringWithNullCheck(Dart_NativeArguments args, int index, Dart_Handle& exception, bool autoDartScope = true)
    {
        void* peer = 0;
        Dart_Handle object = Dart_GetNativeStringArgument(args, index, &peer);
        if (peer) {
            return DartStringAdapter(reinterpret_cast<DartStringPeer*>(peer));
        }
        if (Dart_IsNull(object)) {
            return DartStringAdapter(DartStringPeer::nullString());
        }
        // TODO(terry): Need to implement similar code to toByteString see
        //              bindings/core/v8/V8Bindings.h for implementation.
        return dartToScalarValueString(args, index, exception, autoDartScope);
    }
    static void setDartByteStringReturnValue(Dart_NativeArguments args, const AtomicString& value, bool autoDartScope = true)
    {
        DartDOMData* domData = static_cast<DartDOMData*>(Dart_GetNativeIsolateData(args));
        StringImpl* stringImpl = value.impl();
        if (!stringImpl) {
            Dart_SetReturnValue(args, domData->emptyString());
        } else {
            // TODO(terry): Need to implement similar code to toByteString see
            //              bindings/core/v8/V8Bindings.h for implementation.
        }
    }
    static void setDartByteStringReturnValue(Dart_NativeArguments args, const String& value, bool autoDartScope = true)
    {
        DartDOMData* domData = static_cast<DartDOMData*>(Dart_GetNativeIsolateData(args));
        StringImpl* stringImpl = value.impl();
        if (!stringImpl) {
            Dart_SetReturnValue(args, domData->emptyString());
        } else {
            // TODO(terry): Need to implement similar code to toByteString see
            //              bindings/core/v8/V8Bindings.h for implementation.
        }
    }
    static void setDartByteStringReturnValueWithNullCheck(
        Dart_NativeArguments args, const AtomicString& value, bool autoDartScope = true)
    {
        if (value.isNull()) {
            Dart_SetReturnValue(args, Dart_Null());
        } else {
            setDartByteStringReturnValue(args, value, autoDartScope);
        }
    }
    static void setDartByteStringReturnValueWithNullCheck(Dart_NativeArguments args, const String& value, bool autoDartScope = true)
    {
        if (value.isNull()) {
            Dart_SetReturnValue(args, Dart_Null());
        } else {
            setDartByteStringReturnValue(args, value, autoDartScope);
        }
    }

    static bool dartToBool(Dart_Handle, Dart_Handle& exception);
    static bool dartToBoolWithNullCheck(Dart_Handle object, Dart_Handle& exception)
    {
        // dartToBool converts Null to false
        return dartToBool(object, exception);
    }
    static bool dartToBool(Dart_NativeArguments args, int index, Dart_Handle& exception)
    {
        // FIXME: There is currently no difference between doing the null check and not.
        // If this is the desired semantics, we should stop generating these. If not,
        // we should make this version throw an error.
        return dartToBoolWithNullCheck(args, index, exception);
    }
    static bool dartToBoolWithNullCheck(Dart_NativeArguments args, int index, Dart_Handle& exception)
    {
        // Dart_GetNativeBooleanArgument converts null to false
        bool value;
        Dart_Handle result = Dart_GetNativeBooleanArgument(args, index, &value);
        if (Dart_IsError(result)) {
            exception = Dart_NewStringFromCString(Dart_GetError(result));
            return false;
        }
        return value;
    }
    static Dart_Handle boolToDart(bool value)
    {
        return Dart_NewBoolean(value);
    }

    static int dartToInt(Dart_Handle, Dart_Handle& exception);
    static int dartToInt(Dart_NativeArguments args, int index, Dart_Handle& exception)
    {
        int64_t value;
        Dart_Handle result = Dart_GetNativeIntegerArgument(args, index, &value);
        if (Dart_IsError(result)) {
            exception = Dart_NewStringFromCString(Dart_GetError(result));
            return 0;
        }
        if (value < INT_MIN || value > INT_MAX) {
            exception = Dart_NewStringFromCString("value out of range");
            return 0;
        }
        return value;
    }
    static Dart_Handle intToDart(int64_t value)
    {
        return Dart_NewInteger(value);
    }

    static unsigned dartToUnsigned(Dart_Handle, Dart_Handle& exception);
    static unsigned dartToUnsigned(Dart_NativeArguments args, int index, Dart_Handle& exception)
    {
        int64_t value;
        Dart_Handle result = Dart_GetNativeIntegerArgument(args, index, &value);
        if (Dart_IsError(result)) {
            exception = Dart_NewStringFromCString(Dart_GetError(result));
            return 0;
        }
        if (value < 0 || value > UINT_MAX) {
            exception = Dart_NewStringFromCString("value out of range");
            return 0;
        }
        return value;
    }
    static Dart_Handle unsignedToDart(unsigned value)
    {
        return Dart_NewInteger(value);
    }

    static long long dartToLongLong(Dart_Handle, Dart_Handle& exception);
    static long long dartToLongLong(Dart_NativeArguments args, int index, Dart_Handle& exception)
    {
        int64_t value;
        Dart_Handle result = Dart_GetNativeIntegerArgument(args, index, &value);
        if (Dart_IsError(result)) {
            exception = Dart_NewStringFromCString(Dart_GetError(result));
            return 0;
        }
        return value;
    }
    static Dart_Handle longLongToDart(long long value)
    {
        return Dart_NewInteger(value);
    }

    static unsigned long long dartToUnsignedLongLong(Dart_Handle, Dart_Handle& exception);
    static unsigned long long dartToUnsignedLongLong(Dart_NativeArguments args, int index, Dart_Handle& exception)
    {
        int64_t value;
        Dart_Handle result = Dart_GetNativeIntegerArgument(args, index, &value);
        if (Dart_IsError(result)) {
            exception = Dart_NewStringFromCString(Dart_GetError(result));
            return 0;
        }
        if (value < 0) {
            exception = Dart_NewStringFromCString("value out of range");
            return 0;
        }
        return value;
    }
    static Dart_Handle unsignedLongLongToDart(unsigned long long value)
    {
        // FIXME: WebIDL unsigned long long is guaranteed to fit into 64-bit unsigned,
        // so we need a dart API for constructing an integer from uint64_t.
        ASSERT(value <= 0x7fffffffffffffffLL);
        return Dart_NewInteger(static_cast<int64_t>(value));
    }

    static double dartToDouble(Dart_Handle, Dart_Handle& exception);
    static double dartToDouble(Dart_NativeArguments args, int index, Dart_Handle& exception)
    {
        double value;
        Dart_Handle result = Dart_GetNativeDoubleArgument(args, index, &value);
        if (Dart_IsError(result)) {
            exception = Dart_NewStringFromCString(Dart_GetError(result));
            return 0;
        }
        return value;
    }
    static Dart_Handle doubleToDart(double value)
    {
        return Dart_NewDouble(value);
    }

    static Dart_Handle numberToDart(double value);

    static intptr_t libraryHandleToLibraryId(Dart_Handle library);

    static ScriptValue dartToScriptValue(Dart_Handle);
    static ScriptValue dartToScriptValue(Dart_NativeArguments args, int index)
    {
        Dart_Handle object = Dart_GetNativeArgument(args, index);
        return dartToScriptValue(object);
    }
    // NOTE: consider revisiting this once situation w/ optional arguments checks
    // in dart:html is clearer.
    // The implementation below will convert null to undefined script value. Which
    // is exactly what is desired if actual value wasn't specified at call site,
    // but is most probably wrong if null was explicitly provided. On more positive
    // side indexed db are converted to Dart null anyway, so it might be tricky
    // to observe from user code.
    static ScriptValue dartToScriptValueWithNullCheck(Dart_Handle handle)
    {
        if (Dart_IsNull(handle)) {
            V8ScriptState* scriptState = v8ScriptStateForCurrentIsolate();
            return ScriptValue(scriptState, v8::Undefined(scriptState->isolate()));
        }
        return dartToScriptValue(handle);
    }
    static ScriptValue dartToScriptValueWithNullCheck(Dart_NativeArguments args, int index)
    {
        Dart_Handle object = Dart_GetNativeArgument(args, index);
        return dartToScriptValueWithNullCheck(object);
    }
    static Dart_Handle scriptValueToDart(const ScriptValue&);
    static Dart_Handle scriptPromiseToDart(const ScriptPromise&);

    static PassRefPtr<SerializedScriptValue> dartToSerializedScriptValue(Dart_Handle, Dart_Handle& exception);
    static Dart_Handle serializedScriptValueToDart(PassRefPtr<SerializedScriptValue>);

    static Dart_Handle dateToDart(double);
    static double dartToDate(Dart_Handle, Dart_Handle&);
    static double dartToDate(Dart_NativeArguments args, int idx, Dart_Handle&);
    static bool isDateTime(DartDOMData*, Dart_Handle);
    static bool isTypeSubclassOf(Dart_Handle type, Dart_Handle library, const char* typeName);
    static Dart_Handle getAndValidateNativeType(Dart_Handle type, const String& tagName);
    static bool objectIsType(Dart_Handle, Dart_Handle type);

    static bool isFunction(DartDOMData*, Dart_Handle);

    static Dart_Handle arrayBufferToDart(WTF::ArrayBuffer*);
    static Dart_Handle arrayBufferToDart(PassRefPtr<WTF::ArrayBuffer> value)
    {
        return arrayBufferToDart(value.get());
    }

    static Dart_Handle arrayBufferViewToDart(WTF::ArrayBufferView*);

    // FIXME: For typed data views in the VM heap, this currently creates
    // a new array buffer object with a copy of the data and loses the
    // connection to the dart object.
    static Dart_Handle arrayBufferViewToDart(PassRefPtr<WTF::ArrayBufferView> value)
    {
        return arrayBufferViewToDart(value.get());
    }

    static PassRefPtr<WTF::ArrayBuffer> dartToArrayBuffer(Dart_Handle array, Dart_Handle& exception);
    static PassRefPtr<WTF::ArrayBuffer> dartToArrayBufferWithNullCheck(Dart_Handle array, Dart_Handle& exception)
    {
        return Dart_IsNull(array) ? nullptr : dartToArrayBuffer(array, exception);
    }
    static PassRefPtr<WTF::ArrayBuffer> dartToArrayBuffer(Dart_NativeArguments args, int index, Dart_Handle& exception)
    {
        Dart_Handle object = Dart_GetNativeArgument(args, index);
        return dartToArrayBuffer(object, exception);
    }
    static PassRefPtr<WTF::ArrayBuffer> dartToArrayBufferWithNullCheck(Dart_NativeArguments args, int idx, Dart_Handle& excp)
    {
        Dart_Handle object = Dart_GetNativeArgument(args, idx);
        return dartToArrayBufferWithNullCheck(object, excp);
    }

    // FIXME: For typed data objects in the VM heap, this currently creates
    // a new array buffer object with a copy of the data and loses the
    // connection to the dart object.
    static PassRefPtr<WTF::ArrayBuffer> dartToExternalizedArrayBuffer(Dart_Handle, Dart_Handle&);

    static PassRefPtr<WTF::ArrayBufferView> dartToArrayBufferView(Dart_Handle, Dart_Handle&);
    static PassRefPtr<WTF::ArrayBufferView> dartToArrayBufferViewWithNullCheck(Dart_Handle array, Dart_Handle& exception)
    {
        return Dart_IsNull(array) ? nullptr : dartToArrayBufferView(array, exception);
    }
    static PassRefPtr<WTF::ArrayBufferView> dartToArrayBufferView(Dart_NativeArguments args, int idx, Dart_Handle& exception)
    {
        Dart_Handle object = Dart_GetNativeArgument(args, idx);
        return dartToArrayBufferView(object, exception);
    }
    static PassRefPtr<WTF::ArrayBufferView> dartToArrayBufferViewWithNullCheck(Dart_NativeArguments args, int idx, Dart_Handle& exception)
    {
        Dart_Handle object = Dart_GetNativeArgument(args, idx);
        return dartToArrayBufferViewWithNullCheck(object, exception);
    }

    static PassRefPtr<WTF::ArrayBufferView> dartToExternalizedArrayBufferView(Dart_Handle, Dart_Handle&);

    static PassRefPtr<WTF::Int8Array> dartToInt8Array(Dart_Handle, Dart_Handle&);
    static PassRefPtr<WTF::Int8Array> dartToInt8ArrayWithNullCheck(Dart_Handle, Dart_Handle&);
    static PassRefPtr<WTF::Int8Array> dartToInt8Array(Dart_NativeArguments args, int idx, Dart_Handle& exception);
    static PassRefPtr<WTF::Int8Array> dartToInt8ArrayWithNullCheck(Dart_NativeArguments args, int idx, Dart_Handle& exception);
    static PassRefPtr<WTF::Int32Array> dartToInt32Array(Dart_Handle, Dart_Handle&);
    static PassRefPtr<WTF::Int32Array> dartToInt32ArrayWithNullCheck(Dart_Handle, Dart_Handle&);
    static PassRefPtr<WTF::Int32Array> dartToInt32Array(Dart_NativeArguments args, int idx, Dart_Handle& exception);
    static PassRefPtr<WTF::Int32Array> dartToInt32ArrayWithNullCheck(Dart_NativeArguments args, int idx, Dart_Handle& exception);
    static PassRefPtr<WTF::Uint8Array> dartToUint8Array(Dart_Handle, Dart_Handle&);
    static PassRefPtr<WTF::Uint8Array> dartToUint8ArrayWithNullCheck(Dart_Handle, Dart_Handle&);
    static PassRefPtr<WTF::Uint8Array> dartToUint8Array(Dart_NativeArguments args, int idx, Dart_Handle& exception);
    static PassRefPtr<WTF::Uint8Array> dartToUint8ArrayWithNullCheck(Dart_NativeArguments args, int idx, Dart_Handle& exception);
    static PassRefPtr<WTF::Uint8ClampedArray> dartToUint8ClampedArray(Dart_Handle, Dart_Handle&);
    static PassRefPtr<WTF::Uint8ClampedArray> dartToUint8ClampedArrayWithNullCheck(Dart_Handle, Dart_Handle&);
    static PassRefPtr<WTF::Uint8ClampedArray> dartToUint8ClampedArray(Dart_NativeArguments args, int idx, Dart_Handle& exception);
    static PassRefPtr<WTF::Uint8ClampedArray> dartToUint8ClampedArrayWithNullCheck(Dart_NativeArguments args, int idx, Dart_Handle& exception);
    static PassRefPtr<WTF::Float32Array> dartToFloat32Array(Dart_Handle, Dart_Handle&);
    static PassRefPtr<WTF::Float32Array> dartToFloat32ArrayWithNullCheck(Dart_Handle, Dart_Handle&);
    static PassRefPtr<WTF::Float32Array> dartToFloat32Array(Dart_NativeArguments args, int idx, Dart_Handle& exception);
    static PassRefPtr<WTF::Float32Array> dartToFloat32ArrayWithNullCheck(Dart_NativeArguments args, int idx, Dart_Handle& exception);

    static bool isUint8Array(Dart_Handle);
    static bool isUint8ClampedArray(Dart_Handle);

    template<class ElementType, class TransformType, Dart_Handle transform(TransformType)>
    static Dart_Handle vectorToDart(const Vector<ElementType>& vector)
    {
        Dart_Handle list = Dart_NewList(vector.size());
        if (Dart_IsError(list))
            return list;
        for (size_t i = 0; i < vector.size(); i++) {
            Dart_Handle result = Dart_ListSetAt(list, i, transform(vector[i]));
            if (Dart_IsError(result))
                return result;
        }
        return list;
    }

    template<class ElementType, Dart_Handle transform(ElementType*)>
    static Dart_Handle vectorToDart(const HeapVector<Member<ElementType> >& vector)
    {
        Dart_Handle list = Dart_NewList(vector.size());
        if (Dart_IsError(list))
            return list;
        for (size_t i = 0; i < vector.size(); i++) {
            Dart_Handle result = Dart_ListSetAt(list, i, transform(vector[i]));
            if (Dart_IsError(result))
                return result;
        }
        return list;
    }

    static v8::Local<v8::Context> currentV8Context();


    enum {
#if OS(ANDROID)
        PROP_VALUE_MAX_LEN = PROP_VALUE_MAX
#else
        PROP_VALUE_MAX_LEN = 256
#endif
    };

    static int getProp(const char* name, char* value, int valueLen);

private:
    static DartStringAdapter dartToStringImpl(Dart_Handle, Dart_Handle& exception, bool autoDartScope = true);
    static DartStringPeer* toStringImpl(Dart_Handle, intptr_t charsize, intptr_t strlength);
};

class DartIsolateScope {
public:
    explicit DartIsolateScope(Dart_Isolate isolate)
    {
        m_isolate = isolate;
        m_previousIsolate = Dart_CurrentIsolate();
        if (m_previousIsolate != m_isolate) {
            if (m_previousIsolate)
                Dart_ExitIsolate();
            Dart_EnterIsolate(m_isolate);
        }
    }

    ~DartIsolateScope()
    {
        ASSERT(Dart_CurrentIsolate() == m_isolate);
        if (m_previousIsolate != m_isolate) {
            Dart_ExitIsolate();
            if (m_previousIsolate)
                Dart_EnterIsolate(m_previousIsolate);
        }
    }

private:
    Dart_Isolate m_isolate;
    Dart_Isolate m_previousIsolate;
};

class V8Scope {
public:
    explicit V8Scope(DartDOMData*, v8::Handle<v8::Context>);
    V8Scope(DartDOMData*);
    ~V8Scope();
private:
    v8::Isolate* m_v8Isolate;
    DartDOMData* m_dartDOMData;
    v8::HandleScope m_handleScope;
    v8::Context::Scope m_contextScope;
    V8RecursionScope m_recursionScope;
};

struct DartNativeEntry {
    Dart_NativeFunction nativeFunction;
    intptr_t argumentCount;
    const char* name;
};

template<>
struct DartUtilities::TypeConvertor<bool> {
    bool operator()(Dart_Handle object, Dart_Handle& exception)
    {
        return DartUtilities::dartToBool(object, exception);
    }
};


template<>
struct DartUtilities::TypeConvertor<float> {
    float operator()(Dart_Handle object, Dart_Handle& exception)
    {
        return static_cast<float>(DartUtilities::dartToDouble(object, exception));
    }
};


template<>
struct DartUtilities::TypeConvertor<double> {
    double operator()(Dart_Handle object, Dart_Handle& exception)
    {
        return DartUtilities::dartToDouble(object, exception);
    }
};


template<>
struct DartUtilities::TypeConvertor<int> {
    int operator()(Dart_Handle object, Dart_Handle& exception)
    {
        return DartUtilities::dartToInt(object, exception);
    }
};


template<>
struct DartUtilities::TypeConvertor<unsigned> {
    unsigned operator()(Dart_Handle object, Dart_Handle& exception)
    {
        return DartUtilities::dartToUnsigned(object, exception);
    }
};


template<>
struct DartUtilities::TypeConvertor<unsigned short> {
    unsigned short operator()(Dart_Handle object, Dart_Handle& exception)
    {
        return static_cast<unsigned short>(DartUtilities::dartToUnsigned(object, exception));
    }
};


template<>
struct DartUtilities::TypeConvertor<unsigned long> {
    unsigned long operator()(Dart_Handle object, Dart_Handle& exception)
    {
        return static_cast<unsigned long>(DartUtilities::dartToUnsignedLongLong(object, exception));
    }
};


template<>
struct DartUtilities::TypeConvertor<unsigned long long> {
    unsigned long long operator()(Dart_Handle object, Dart_Handle& exception)
    {
        return DartUtilities::dartToUnsignedLongLong(object, exception);
    }
};


template<typename T>
struct DartUtilities::TypeConvertor<Nullable<T>> {
    Nullable<T> operator()(Dart_Handle object, Dart_Handle& exception)
    {
        if (Dart_IsNull(object))
            return Nullable<T>();
        return Nullable<T>(TypeConvertor<T>()(object, exception));
    }
};


template<>
struct DartUtilities::TypeConvertor<String> {
    DartStringAdapter operator()(Dart_Handle object, Dart_Handle& exception)
    {
        return DartUtilities::dartToString(object, exception);
    }
};


template<>
struct DartUtilities::TypeConvertor<ScriptValue> {
    ScriptValue operator()(Dart_Handle object, Dart_Handle& exception)
    {
        return ScriptValue(DartScriptValue::create(currentScriptState(), object));
    }
};

template<>
struct DartUtilities::TypeConvertor<Dictionary> {
    Dictionary operator()(Dart_Handle object, Dart_Handle& exception)
    {
        return DartUtilities::dartToDictionary(object, exception);
    }
};


template<>
struct DartUtilities::TypeConvertor<MediaStreamTrack> {
    RawPtr<MediaStreamTrack> operator()(Dart_Handle object, Dart_Handle& exception)
    {
        // FIXME: proper implementation.
        return nullptr;
    }
};

template<typename T>
Dart_Handle toDartNoInline(T* impl, DartDOMData* domData);

template <typename T>
struct DartValueTraits {
    static Dart_Handle toDartValue(const T& value, DartDOMData* domData)
    {
        if (!WTF::getPtr(value))
            return Dart_Null();
        return toDartNoInline(WTF::getPtr(value), domData);
    }
};

template<>
struct DartValueTraits<String> {
    static inline Dart_Handle toDartValue(const String& value, DartDOMData* domData)
    {
        return DartUtilities::stringToDart(value);
    }
};

template<>
struct DartValueTraits<AtomicString> {
    static inline Dart_Handle toDartValue(const AtomicString& value, DartDOMData* domData)
    {
        return DartUtilities::stringToDart(value);
    }
};

template<size_t n>
struct DartValueTraits<char const[n]> {
    static inline Dart_Handle toDartValue(char const (&value)[n], DartDOMData* domData)
    {
        return DartUtilities::stringToDart(value);
    }
};

template<>
struct DartValueTraits<const char*> {
    static inline Dart_Handle toDartValue(const char* const& value, DartDOMData* domData)
    {
        // AtomicString?
        return DartUtilities::stringToDart((String)value);
    }
};

template<>
struct DartValueTraits<V8UndefinedType> {
    static inline Dart_Handle toDartValue(const V8UndefinedType& value, DartDOMData* domData)
    {
        return Dart_Null();
    }
};

template<>
struct DartValueTraits<V8NullType> {
    static inline Dart_Handle toDartValue(const V8NullType& value, DartDOMData* domData)
    {
        return Dart_Null();
    }
};

template<>
struct DartValueTraits<ScriptValue> {
    static inline Dart_Handle toDartValue(const ScriptValue& value, DartDOMData* domData)
    {
        return DartUtilities::scriptValueToDart(value);
    }
};

template<>
struct DartValueTraits<Dart_Handle> {
    static inline Dart_Handle toDartValue(const Dart_Handle& value, DartDOMData* domData)
    {
        return value;
    }
};

template<>
struct DartValueTraits<v8::Handle<v8::Value> > {
    static inline Dart_Handle toDartValue(const v8::Handle<v8::Value>& value, DartDOMData* domData)
    {
        Dart_Handle exception = 0;
        Dart_Handle result = V8Converter::toDart(value, exception);
        if (exception)
            return exception;
        return result;
    }
};

template<>
struct DartValueTraits<bool> {
    static inline Dart_Handle toDartValue(const bool& value, DartDOMData* domData)
    {
        return DartUtilities::boolToDart(value);
    }
};

template<>
struct DartValueTraits<int> {
    static inline Dart_Handle toDartValue(const int& value, DartDOMData* domData)
    {
        return DartUtilities::intToDart(value);
    }
};

template<>
struct DartValueTraits<long> {
    static inline Dart_Handle toDartValue(const long& value, DartDOMData* domData)
    {
        return DartUtilities::intToDart(value);
    }
};

template<>
struct DartValueTraits<unsigned> {
    static inline Dart_Handle toDartValue(const unsigned& value, DartDOMData* domData)
    {
        return DartUtilities::unsignedToDart(value);
    }
};

template<>
struct DartValueTraits<unsigned long> {
    static inline Dart_Handle toDartValue(const unsigned long& value, DartDOMData* domData)
    {
        return DartUtilities::unsignedToDart(value);
    }
};

template<>
struct DartValueTraits<float> {
    static inline Dart_Handle toDartValue(const float& value, DartDOMData* domData)
    {
        return DartUtilities::doubleToDart(value);
    }
};

template<>
struct DartValueTraits<double> {
    static inline Dart_Handle toDartValue(const double& value, DartDOMData* domData)
    {
        return DartUtilities::doubleToDart(value);
    }
};

template<>
struct DartValueTraits<PassRefPtr<ArrayBuffer> > {
    static inline Dart_Handle toDartValue(const PassRefPtr<ArrayBuffer>& value, DartDOMData* domData)
    {
        return DartUtilities::arrayBufferToDart(value);
    }
};

template<typename T, size_t inlineCapacity>
Dart_Handle dartArray(const Vector<T, inlineCapacity>& vector, DartDOMData* domData)
{
    Dart_Handle result = Dart_NewList(vector.size());
    int index = 0;
    typename Vector<T, inlineCapacity>::const_iterator end = vector.end();
    typedef DartValueTraits<T> TraitsType;
    for (typename Vector<T, inlineCapacity>::const_iterator iter = vector.begin(); iter != end; ++iter)
        Dart_ListSetAt(result, index, TraitsType::toDartValue(*iter, domData));
    return result;
}

template <typename T, size_t inlineCapacity, typename Allocator>
struct DartValueTraits<WTF::Vector<T, inlineCapacity, Allocator> > {
    static inline Dart_Handle toDartValue(const Vector<T, inlineCapacity, Allocator>& value, DartDOMData* domData)
    {
        return dartArray(value, domData);
    }
};

// Errors?
template<typename T, size_t inlineCapacity>
Dart_Handle dartArray(const HeapVector<T, inlineCapacity>& vector, DartDOMData* domData)
{
    Dart_Handle result = Dart_NewList(vector.size());
    int index = 0;
    typename HeapVector<T, inlineCapacity>::const_iterator end = vector.end();
    typedef DartValueTraits<T> TraitsType;
    for (typename HeapVector<T, inlineCapacity>::const_iterator iter = vector.begin(); iter != end; ++iter)
        Dart_ListSetAt(result, index, TraitsType::toDartValue(*iter, domData));
    return result;
}

template<typename T, size_t inlineCapacity>
struct DartValueTraits<HeapVector<T, inlineCapacity> > {
    static inline Dart_Handle toDartValue(const HeapVector<T, inlineCapacity>& value, DartDOMData* domData)
    {
        return dartArray(value, domData);
    }
};


#define DART_UNIMPLEMENTED_EXCEPTION() DartUtilities::notImplementedException(__FILE__, __LINE__)
#define DART_UNIMPLEMENTED() Dart_ThrowException(DART_UNIMPLEMENTED_EXCEPTION());

#if defined(DART_TIMER_SCOPE)
#define DART_START_TIMER()        \
    double timerStop, timerStart = currentTimeMS();
#define DART_RECORD_TIMER(msg)    \
    timerStop = currentTimeMS();  \
    fprintf(stdout, "%s %.3f ms\n", msg, (timerStop - timerStart));
#else
#define DART_START_TIMER()
#define DART_RECORD_TIMER(msg)
#endif

} // namespace blink

#endif // DartUtilities_h
