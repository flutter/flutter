/*
 * Copyright (C) 2006, 2007, 2008, 2009 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "bindings/core/v8/V8Binding.h"

#include "bindings/core/v8/ScriptController.h"
#include "bindings/core/v8/V8AbstractEventListener.h"
#include "bindings/core/v8/V8BindingMacros.h"
#include "bindings/core/v8/V8Element.h"
#include "bindings/core/v8/V8ObjectConstructor.h"
#include "bindings/core/v8/V8Window.h"
#include "bindings/core/v8/WindowProxy.h"
#include "core/dom/Document.h"
#include "core/dom/Element.h"
#include "core/dom/QualifiedName.h"
#include "core/frame/LocalFrame.h"
#include "core/frame/Settings.h"
#include "core/inspector/BindingVisitors.h"
#include "core/inspector/InspectorTraceEvents.h"
#include "core/loader/FrameLoaderClient.h"
#include "platform/EventTracer.h"
#include "platform/JSONValues.h"
#include "wtf/ArrayBufferContents.h"
#include "wtf/MainThread.h"
#include "wtf/MathExtras.h"
#include "wtf/StdLibExtras.h"
#include "wtf/Threading.h"
#include "wtf/text/AtomicString.h"
#include "wtf/text/CString.h"
#include "wtf/text/StringBuffer.h"
#include "wtf/text/StringHash.h"
#include "wtf/text/WTFString.h"
#include "wtf/unicode/CharacterNames.h"
#include "wtf/unicode/Unicode.h"

namespace blink {

void setArityTypeError(ExceptionState& exceptionState, const char* valid, unsigned provided)
{
    exceptionState.throwTypeError(ExceptionMessages::invalidArity(valid, provided));
}

v8::Local<v8::Value> createMinimumArityTypeErrorForMethod(const char* method, const char* type, unsigned expected, unsigned provided, v8::Isolate* isolate)
{
    return V8ThrowException::createTypeError(ExceptionMessages::failedToExecute(method, type, ExceptionMessages::notEnoughArguments(expected, provided)), isolate);
}

v8::Local<v8::Value> createMinimumArityTypeErrorForConstructor(const char* type, unsigned expected, unsigned provided, v8::Isolate* isolate)
{
    return V8ThrowException::createTypeError(ExceptionMessages::failedToConstruct(type, ExceptionMessages::notEnoughArguments(expected, provided)), isolate);
}

void setMinimumArityTypeError(ExceptionState& exceptionState, unsigned expected, unsigned provided)
{
    exceptionState.throwTypeError(ExceptionMessages::notEnoughArguments(expected, provided));
}

class ArrayBufferAllocator : public v8::ArrayBuffer::Allocator {
    virtual void* Allocate(size_t size) override
    {
        void* data;
        WTF::ArrayBufferContents::allocateMemory(size, WTF::ArrayBufferContents::ZeroInitialize, data);
        return data;
    }

    virtual void* AllocateUninitialized(size_t size) override
    {
        void* data;
        WTF::ArrayBufferContents::allocateMemory(size, WTF::ArrayBufferContents::DontInitialize, data);
        return data;
    }

    virtual void Free(void* data, size_t size) override
    {
        WTF::ArrayBufferContents::freeMemory(data, size);
    }
};

v8::ArrayBuffer::Allocator* v8ArrayBufferAllocator()
{
    DEFINE_STATIC_LOCAL(ArrayBufferAllocator, arrayBufferAllocator, ());
    return &arrayBufferAllocator;
}

const int32_t kMaxInt32 = 0x7fffffff;
const int32_t kMinInt32 = -kMaxInt32 - 1;
const uint32_t kMaxUInt32 = 0xffffffff;
const int64_t kJSMaxInteger = 0x20000000000000LL - 1; // 2^53 - 1, maximum uniquely representable integer in ECMAScript.

static double enforceRange(double x, double minimum, double maximum, const char* typeName, ExceptionState& exceptionState)
{
    if (std::isnan(x) || std::isinf(x)) {
        exceptionState.throwTypeError("Value is" + String(std::isinf(x) ? " infinite and" : "") + " not of type '" + String(typeName) + "'.");
        return 0;
    }
    x = trunc(x);
    if (x < minimum || x > maximum) {
        exceptionState.throwTypeError("Value is outside the '" + String(typeName) + "' value range.");
        return 0;
    }
    return x;
}

template <typename T>
struct IntTypeLimits {
};

template <>
struct IntTypeLimits<int8_t> {
    static const int8_t minValue = -128;
    static const int8_t maxValue = 127;
    static const unsigned numberOfValues = 256; // 2^8
};

template <>
struct IntTypeLimits<uint8_t> {
    static const uint8_t maxValue = 255;
    static const unsigned numberOfValues = 256; // 2^8
};

template <>
struct IntTypeLimits<int16_t> {
    static const short minValue = -32768;
    static const short maxValue = 32767;
    static const unsigned numberOfValues = 65536; // 2^16
};

template <>
struct IntTypeLimits<uint16_t> {
    static const unsigned short maxValue = 65535;
    static const unsigned numberOfValues = 65536; // 2^16
};

template <typename T>
static inline T toSmallerInt(v8::Handle<v8::Value> value, IntegerConversionConfiguration configuration, const char* typeName, ExceptionState& exceptionState)
{
    typedef IntTypeLimits<T> LimitsTrait;

    // Fast case. The value is already a 32-bit integer in the right range.
    if (value->IsInt32()) {
        int32_t result = value->Int32Value();
        if (result >= LimitsTrait::minValue && result <= LimitsTrait::maxValue)
            return static_cast<T>(result);
        if (configuration == EnforceRange) {
            exceptionState.throwTypeError("Value is outside the '" + String(typeName) + "' value range.");
            return 0;
        }
        result %= LimitsTrait::numberOfValues;
        return static_cast<T>(result > LimitsTrait::maxValue ? result - LimitsTrait::numberOfValues : result);
    }

    // Can the value be converted to a number?
    TONATIVE_DEFAULT_EXCEPTIONSTATE(v8::Local<v8::Number>, numberObject, value->ToNumber(), exceptionState, 0);
    if (numberObject.IsEmpty()) {
        exceptionState.throwTypeError("Not convertible to a number value (of type '" + String(typeName) + "'.");
        return 0;
    }

    if (configuration == EnforceRange)
        return enforceRange(numberObject->Value(), LimitsTrait::minValue, LimitsTrait::maxValue, typeName, exceptionState);

    double numberValue = numberObject->Value();
    if (std::isnan(numberValue) || std::isinf(numberValue) || !numberValue)
        return 0;

    numberValue = numberValue < 0 ? -floor(fabs(numberValue)) : floor(fabs(numberValue));
    numberValue = fmod(numberValue, LimitsTrait::numberOfValues);

    return static_cast<T>(numberValue > LimitsTrait::maxValue ? numberValue - LimitsTrait::numberOfValues : numberValue);
}

template <typename T>
static inline T toSmallerUInt(v8::Handle<v8::Value> value, IntegerConversionConfiguration configuration, const char* typeName, ExceptionState& exceptionState)
{
    typedef IntTypeLimits<T> LimitsTrait;

    // Fast case. The value is a 32-bit signed integer - possibly positive?
    if (value->IsInt32()) {
        int32_t result = value->Int32Value();
        if (result >= 0 && result <= LimitsTrait::maxValue)
            return static_cast<T>(result);
        if (configuration == EnforceRange) {
            exceptionState.throwTypeError("Value is outside the '" + String(typeName) + "' value range.");
            return 0;
        }
        return static_cast<T>(result);
    }

    // Can the value be converted to a number?
    TONATIVE_DEFAULT_EXCEPTIONSTATE(v8::Local<v8::Number>, numberObject, value->ToNumber(), exceptionState, 0);
    if (numberObject.IsEmpty()) {
        exceptionState.throwTypeError("Not convertible to a number value (of type '" + String(typeName) + "'.");
        return 0;
    }

    if (configuration == EnforceRange)
        return enforceRange(numberObject->Value(), 0, LimitsTrait::maxValue, typeName, exceptionState);

    // Does the value convert to nan or to an infinity?
    double numberValue = numberObject->Value();
    if (std::isnan(numberValue) || std::isinf(numberValue) || !numberValue)
        return 0;

    if (configuration == Clamp)
        return clampTo<T>(numberObject->Value());

    numberValue = numberValue < 0 ? -floor(fabs(numberValue)) : floor(fabs(numberValue));
    return static_cast<T>(fmod(numberValue, LimitsTrait::numberOfValues));
}

int8_t toInt8(v8::Handle<v8::Value> value, IntegerConversionConfiguration configuration, ExceptionState& exceptionState)
{
    return toSmallerInt<int8_t>(value, configuration, "byte", exceptionState);
}

int8_t toInt8(v8::Handle<v8::Value> value)
{
    NonThrowableExceptionState exceptionState;
    return toInt8(value, NormalConversion, exceptionState);
}

uint8_t toUInt8(v8::Handle<v8::Value> value, IntegerConversionConfiguration configuration, ExceptionState& exceptionState)
{
    return toSmallerUInt<uint8_t>(value, configuration, "octet", exceptionState);
}

uint8_t toUInt8(v8::Handle<v8::Value> value)
{
    NonThrowableExceptionState exceptionState;
    return toUInt8(value, NormalConversion, exceptionState);
}

int16_t toInt16(v8::Handle<v8::Value> value, IntegerConversionConfiguration configuration, ExceptionState& exceptionState)
{
    return toSmallerInt<int16_t>(value, configuration, "short", exceptionState);
}

int16_t toInt16(v8::Handle<v8::Value> value)
{
    NonThrowableExceptionState exceptionState;
    return toInt16(value, NormalConversion, exceptionState);
}

uint16_t toUInt16(v8::Handle<v8::Value> value, IntegerConversionConfiguration configuration, ExceptionState& exceptionState)
{
    return toSmallerUInt<uint16_t>(value, configuration, "unsigned short", exceptionState);
}

uint16_t toUInt16(v8::Handle<v8::Value> value)
{
    NonThrowableExceptionState exceptionState;
    return toUInt16(value, NormalConversion, exceptionState);
}

int32_t toInt32(v8::Handle<v8::Value> value, IntegerConversionConfiguration configuration, ExceptionState& exceptionState)
{
    // Fast case. The value is already a 32-bit integer.
    if (value->IsInt32())
        return value->Int32Value();

    // Can the value be converted to a number?
    TONATIVE_DEFAULT_EXCEPTIONSTATE(v8::Local<v8::Number>, numberObject, value->ToNumber(), exceptionState, 0);
    if (numberObject.IsEmpty()) {
        exceptionState.throwTypeError("Not convertible to a number value (of type 'long'.)");
        return 0;
    }

    if (configuration == EnforceRange)
        return enforceRange(numberObject->Value(), kMinInt32, kMaxInt32, "long", exceptionState);

    // Does the value convert to nan or to an infinity?
    double numberValue = numberObject->Value();
    if (std::isnan(numberValue) || std::isinf(numberValue))
        return 0;

    if (configuration == Clamp)
        return clampTo<int32_t>(numberObject->Value());

    TONATIVE_DEFAULT_EXCEPTIONSTATE(int32_t, result, numberObject->Int32Value(), exceptionState, 0);
    return result;
}

int32_t toInt32(v8::Handle<v8::Value> value)
{
    NonThrowableExceptionState exceptionState;
    return toInt32(value, NormalConversion, exceptionState);
}

uint32_t toUInt32(v8::Handle<v8::Value> value, IntegerConversionConfiguration configuration, ExceptionState& exceptionState)
{
    // Fast case. The value is already a 32-bit unsigned integer.
    if (value->IsUint32())
        return value->Uint32Value();

    // Fast case. The value is a 32-bit signed integer - possibly positive?
    if (value->IsInt32()) {
        int32_t result = value->Int32Value();
        if (result >= 0)
            return result;
        if (configuration == EnforceRange) {
            exceptionState.throwTypeError("Value is outside the 'unsigned long' value range.");
            return 0;
        }
        return result;
    }

    // Can the value be converted to a number?
    TONATIVE_DEFAULT_EXCEPTIONSTATE(v8::Local<v8::Number>, numberObject, value->ToNumber(), exceptionState, 0);
    if (numberObject.IsEmpty()) {
        exceptionState.throwTypeError("Not convertible to a number value (of type 'unsigned long'.)");
        return 0;
    }

    if (configuration == EnforceRange)
        return enforceRange(numberObject->Value(), 0, kMaxUInt32, "unsigned long", exceptionState);

    // Does the value convert to nan or to an infinity?
    double numberValue = numberObject->Value();
    if (std::isnan(numberValue) || std::isinf(numberValue))
        return 0;

    if (configuration == Clamp)
        return clampTo<uint32_t>(numberObject->Value());

    TONATIVE_DEFAULT(uint32_t, result, numberObject->Uint32Value(), 0);
    return result;
}

uint32_t toUInt32(v8::Handle<v8::Value> value)
{
    NonThrowableExceptionState exceptionState;
    return toUInt32(value, NormalConversion, exceptionState);
}

int64_t toInt64(v8::Handle<v8::Value> value, IntegerConversionConfiguration configuration, ExceptionState& exceptionState)
{
    // Fast case. The value is a 32-bit integer.
    if (value->IsInt32())
        return value->Int32Value();

    // Can the value be converted to a number?
    TONATIVE_DEFAULT_EXCEPTIONSTATE(v8::Local<v8::Number>, numberObject, value->ToNumber(), exceptionState, 0);
    if (numberObject.IsEmpty()) {
        exceptionState.throwTypeError("Not convertible to a number value (of type 'long long'.)");
        return 0;
    }

    double x = numberObject->Value();

    if (configuration == EnforceRange)
        return enforceRange(x, -kJSMaxInteger, kJSMaxInteger, "long long", exceptionState);

    // Does the value convert to nan or to an infinity?
    if (std::isnan(x) || std::isinf(x))
        return 0;

    // NaNs and +/-Infinity should be 0, otherwise modulo 2^64.
    unsigned long long integer;
    doubleToInteger(x, integer);
    return integer;
}

int64_t toInt64(v8::Handle<v8::Value> value)
{
    NonThrowableExceptionState exceptionState;
    return toInt64(value, NormalConversion, exceptionState);
}

uint64_t toUInt64(v8::Handle<v8::Value> value, IntegerConversionConfiguration configuration, ExceptionState& exceptionState)
{
    // Fast case. The value is a 32-bit unsigned integer.
    if (value->IsUint32())
        return value->Uint32Value();

    // Fast case. The value is a 32-bit integer.
    if (value->IsInt32()) {
        int32_t result = value->Int32Value();
        if (result >= 0)
            return result;
        if (configuration == EnforceRange) {
            exceptionState.throwTypeError("Value is outside the 'unsigned long long' value range.");
            return 0;
        }
        return result;
    }

    // Can the value be converted to a number?
    TONATIVE_DEFAULT_EXCEPTIONSTATE(v8::Local<v8::Number>, numberObject, value->ToNumber(), exceptionState, 0);
    if (numberObject.IsEmpty()) {
        exceptionState.throwTypeError("Not convertible to a number value (of type 'unsigned long long'.)");
        return 0;
    }

    double x = numberObject->Value();

    if (configuration == EnforceRange)
        return enforceRange(x, 0, kJSMaxInteger, "unsigned long long", exceptionState);

    // Does the value convert to nan or to an infinity?
    if (std::isnan(x) || std::isinf(x))
        return 0;

    // NaNs and +/-Infinity should be 0, otherwise modulo 2^64.
    unsigned long long integer;
    doubleToInteger(x, integer);
    return integer;
}

uint64_t toUInt64(v8::Handle<v8::Value> value)
{
    NonThrowableExceptionState exceptionState;
    return toUInt64(value, NormalConversion, exceptionState);
}

float toFloat(v8::Handle<v8::Value> value, ExceptionState& exceptionState)
{
    TONATIVE_DEFAULT_EXCEPTIONSTATE(v8::Local<v8::Number>, numberObject, value->ToNumber(), exceptionState, 0);
    return numberObject->NumberValue();
}

String toByteString(v8::Handle<v8::Value> value, ExceptionState& exceptionState)
{
    // Handle null default value.
    if (value.IsEmpty())
        return String();

    // From the Web IDL spec: http://heycam.github.io/webidl/#es-ByteString
    if (value.IsEmpty())
        return String();

    // 1. Let x be ToString(v)
    TONATIVE_DEFAULT_EXCEPTIONSTATE(v8::Local<v8::String>, stringObject, value->ToString(), exceptionState, String());
    String x = toCoreString(stringObject);

    // 2. If the value of any element of x is greater than 255, then throw a TypeError.
    if (!x.containsOnlyLatin1()) {
        exceptionState.throwTypeError("Value is not a valid ByteString.");
        return String();
    }

    // 3. Return an IDL ByteString value whose length is the length of x, and where the
    // value of each element is the value of the corresponding element of x.
    // Blink: A ByteString is simply a String with a range constrained per the above, so
    // this is the identity operation.
    return x;
}

static bool hasUnmatchedSurrogates(const String& string)
{
    // By definition, 8-bit strings are confined to the Latin-1 code page and
    // have no surrogates, matched or otherwise.
    if (string.is8Bit())
        return false;

    const UChar* characters = string.characters16();
    const unsigned length = string.length();

    for (unsigned i = 0; i < length; ++i) {
        UChar c = characters[i];
        if (U16_IS_SINGLE(c))
            continue;
        if (U16_IS_TRAIL(c))
            return true;
        ASSERT(U16_IS_LEAD(c));
        if (i == length - 1)
            return true;
        UChar d = characters[i + 1];
        if (!U16_IS_TRAIL(d))
            return true;
        ++i;
    }
    return false;
}

// Replace unmatched surrogates with REPLACEMENT CHARACTER U+FFFD.
static String replaceUnmatchedSurrogates(const String& string)
{
    // This roughly implements http://heycam.github.io/webidl/#dfn-obtain-unicode
    // but since Blink strings are 16-bits internally, the output is simply
    // re-encoded to UTF-16.

    // The concept of surrogate pairs is explained at:
    // http://www.unicode.org/versions/Unicode6.2.0/ch03.pdf#G2630

    // Blink-specific optimization to avoid making an unnecessary copy.
    if (!hasUnmatchedSurrogates(string))
        return string;
    ASSERT(!string.is8Bit());

    // 1. Let S be the DOMString value.
    const UChar* s = string.characters16();

    // 2. Let n be the length of S.
    const unsigned n = string.length();

    // 3. Initialize i to 0.
    unsigned i = 0;

    // 4. Initialize U to be an empty sequence of Unicode characters.
    StringBuilder u;
    u.reserveCapacity(n);

    // 5. While i < n:
    while (i < n) {
        // 1. Let c be the code unit in S at index i.
        UChar c = s[i];
        // 2. Depending on the value of c:
        if (U16_IS_SINGLE(c)) {
            // c < 0xD800 or c > 0xDFFF
            // Append to U the Unicode character with code point c.
            u.append(c);
        } else if (U16_IS_TRAIL(c)) {
            // 0xDC00 <= c <= 0xDFFF
            // Append to U a U+FFFD REPLACEMENT CHARACTER.
            u.append(WTF::Unicode::replacementCharacter);
        } else {
            // 0xD800 <= c <= 0xDBFF
            ASSERT(U16_IS_LEAD(c));
            if (i == n - 1) {
                // 1. If i = n−1, then append to U a U+FFFD REPLACEMENT CHARACTER.
                u.append(WTF::Unicode::replacementCharacter);
            } else {
                // 2. Otherwise, i < n−1:
                ASSERT(i < n - 1);
                // ....1. Let d be the code unit in S at index i+1.
                UChar d = s[i + 1];
                if (U16_IS_TRAIL(d)) {
                    // 2. If 0xDC00 <= d <= 0xDFFF, then:
                    // ..1. Let a be c & 0x3FF.
                    // ..2. Let b be d & 0x3FF.
                    // ..3. Append to U the Unicode character with code point 2^16+2^10*a+b.
                    u.append(U16_GET_SUPPLEMENTARY(c, d));
                    // Blink: This is equivalent to u.append(c); u.append(d);
                    ++i;
                } else {
                    // 3. Otherwise, d < 0xDC00 or d > 0xDFFF. Append to U a U+FFFD REPLACEMENT CHARACTER.
                    u.append(WTF::Unicode::replacementCharacter);
                }
            }
        }
        // 3. Set i to i+1.
        ++i;
    }

    // 6. Return U.
    ASSERT(u.length() == string.length());
    return u.toString();
}

String toScalarValueString(v8::Handle<v8::Value> value, ExceptionState& exceptionState)
{
    // From the Encoding standard (with a TODO to move to Web IDL):
    // http://encoding.spec.whatwg.org/#type-scalarvaluestring
    if (value.IsEmpty())
        return String();
    TONATIVE_DEFAULT_EXCEPTIONSTATE(v8::Local<v8::String>, stringObject, value->ToString(), exceptionState, String());

    // ScalarValueString is identical to DOMString except that "convert a
    // DOMString to a sequence of Unicode characters" is used subsequently
    // when converting to an IDL value
    String x = toCoreString(stringObject);
    return replaceUnmatchedSurrogates(x);
}

LocalDOMWindow* toDOMWindow(v8::Handle<v8::Value> value, v8::Isolate* isolate)
{
    if (value.IsEmpty() || !value->IsObject())
        return 0;

    v8::Handle<v8::Object> windowWrapper = V8Window::findInstanceInPrototypeChain(v8::Handle<v8::Object>::Cast(value), isolate);
    if (!windowWrapper.IsEmpty())
        return V8Window::toNative(windowWrapper);
    return 0;
}

LocalDOMWindow* toDOMWindow(v8::Handle<v8::Context> context)
{
    if (context.IsEmpty())
        return 0;
    return toDOMWindow(context->Global(), context->GetIsolate());
}

LocalDOMWindow* enteredDOMWindow(v8::Isolate* isolate)
{
    LocalDOMWindow* window = toDOMWindow(isolate->GetEnteredContext());
    if (!window) {
        // We don't always have an entered DOM window, for example during microtask callbacks from V8
        // (where the entered context may be the DOM-in-JS context). In that case, we fall back
        // to the current context.
        window = currentDOMWindow(isolate);
        ASSERT(window);
    }
    return window;
}

LocalDOMWindow* currentDOMWindow(v8::Isolate* isolate)
{
    return toDOMWindow(isolate->GetCurrentContext());
}

LocalDOMWindow* callingDOMWindow(v8::Isolate* isolate)
{
    v8::Handle<v8::Context> context = isolate->GetCallingContext();
    if (context.IsEmpty()) {
        // Unfortunately, when processing script from a plug-in, we might not
        // have a calling context. In those cases, we fall back to the
        // entered context.
        context = isolate->GetEnteredContext();
    }
    return toDOMWindow(context);
}

ExecutionContext* toExecutionContext(v8::Handle<v8::Context> context)
{
    if (context.IsEmpty())
        return 0;
    v8::Handle<v8::Object> global = context->Global();
    v8::Handle<v8::Object> windowWrapper = V8Window::findInstanceInPrototypeChain(global, context->GetIsolate());
    if (!windowWrapper.IsEmpty())
        return V8Window::toNative(windowWrapper)->executionContext();
    // FIXME: Is this line of code reachable?
    return 0;
}

ExecutionContext* currentExecutionContext(v8::Isolate* isolate)
{
    return toExecutionContext(isolate->GetCurrentContext());
}

ExecutionContext* callingExecutionContext(v8::Isolate* isolate)
{
    v8::Handle<v8::Context> context = isolate->GetCallingContext();
    if (context.IsEmpty()) {
        // Unfortunately, when processing script from a plug-in, we might not
        // have a calling context. In those cases, we fall back to the
        // entered context.
        context = isolate->GetEnteredContext();
    }
    return toExecutionContext(context);
}

LocalFrame* toFrameIfNotDetached(v8::Handle<v8::Context> context)
{
    // FIXME(sky): remove.
    LocalDOMWindow* window = toDOMWindow(context);
    return window->frame();
}

v8::Local<v8::Context> toV8Context(ExecutionContext* context, DOMWrapperWorld& world)
{
    ASSERT(context);
    if (LocalFrame* frame = toDocument(context)->frame())
        return frame->script().windowProxy(world)->context();
    return v8::Local<v8::Context>();
}

v8::Local<v8::Context> toV8Context(LocalFrame* frame, DOMWrapperWorld& world)
{
    if (!frame)
        return v8::Local<v8::Context>();
    v8::Local<v8::Context> context = frame->script().windowProxy(world)->context();
    if (context.IsEmpty())
        return v8::Local<v8::Context>();
    LocalFrame* attachedFrame= toFrameIfNotDetached(context);
    return frame == attachedFrame ? context : v8::Local<v8::Context>();
}

void crashIfV8IsDead()
{
    if (v8::V8::IsDead()) {
        // FIXME: We temporarily deal with V8 internal error situations
        // such as out-of-memory by crashing the renderer.
        CRASH();
    }
}

v8::Handle<v8::Function> getBoundFunction(v8::Handle<v8::Function> function)
{
    v8::Handle<v8::Value> boundFunction = function->GetBoundFunction();
    return boundFunction->IsFunction() ? v8::Handle<v8::Function>::Cast(boundFunction) : function;
}

void addHiddenValueToArray(v8::Handle<v8::Object> object, v8::Local<v8::Value> value, int arrayIndex, v8::Isolate* isolate)
{
    v8::Local<v8::Value> arrayValue = object->GetInternalField(arrayIndex);
    if (arrayValue->IsNull() || arrayValue->IsUndefined()) {
        arrayValue = v8::Array::New(isolate);
        object->SetInternalField(arrayIndex, arrayValue);
    }

    v8::Local<v8::Array> array = v8::Local<v8::Array>::Cast(arrayValue);
    array->Set(v8::Integer::New(isolate, array->Length()), value);
}

void removeHiddenValueFromArray(v8::Handle<v8::Object> object, v8::Local<v8::Value> value, int arrayIndex, v8::Isolate* isolate)
{
    v8::Local<v8::Value> arrayValue = object->GetInternalField(arrayIndex);
    if (!arrayValue->IsArray())
        return;
    v8::Local<v8::Array> array = v8::Local<v8::Array>::Cast(arrayValue);
    for (int i = array->Length() - 1; i >= 0; --i) {
        v8::Local<v8::Value> item = array->Get(v8::Integer::New(isolate, i));
        if (item->StrictEquals(value)) {
            array->Delete(i);
            return;
        }
    }
}

void moveEventListenerToNewWrapper(v8::Handle<v8::Object> object, EventListener* oldValue, v8::Local<v8::Value> newValue, int arrayIndex, v8::Isolate* isolate)
{
    if (oldValue) {
        V8AbstractEventListener* oldListener = V8AbstractEventListener::cast(oldValue);
        if (oldListener) {
            v8::Local<v8::Object> oldListenerObject = oldListener->getExistingListenerObject();
            if (!oldListenerObject.IsEmpty())
                removeHiddenValueFromArray(object, oldListenerObject, arrayIndex, isolate);
        }
    }
    // Non-callable input is treated as null and ignored
    if (newValue->IsFunction())
        addHiddenValueToArray(object, newValue, arrayIndex, isolate);
}

v8::Isolate* toIsolate(ExecutionContext* context)
{
    if (context && context->isDocument())
        return V8PerIsolateData::mainThreadIsolate();
    return v8::Isolate::GetCurrent();
}

v8::Isolate* toIsolate(LocalFrame* frame)
{
    ASSERT(frame);
    return frame->script().isolate();
}

PassRefPtr<JSONValue> v8ToJSONValue(v8::Isolate* isolate, v8::Handle<v8::Value> value, int maxDepth)
{
    if (value.IsEmpty()) {
        ASSERT_NOT_REACHED();
        return nullptr;
    }

    if (!maxDepth)
        return nullptr;
    maxDepth--;

    if (value->IsNull() || value->IsUndefined())
        return JSONValue::null();
    if (value->IsBoolean())
        return JSONBasicValue::create(value->BooleanValue());
    if (value->IsNumber())
        return JSONBasicValue::create(value->NumberValue());
    if (value->IsString())
        return JSONString::create(toCoreString(value.As<v8::String>()));
    if (value->IsArray()) {
        v8::Handle<v8::Array> array = v8::Handle<v8::Array>::Cast(value);
        RefPtr<JSONArray> inspectorArray = JSONArray::create();
        uint32_t length = array->Length();
        for (uint32_t i = 0; i < length; i++) {
            v8::Local<v8::Value> value = array->Get(v8::Int32::New(isolate, i));
            RefPtr<JSONValue> element = v8ToJSONValue(isolate, value, maxDepth);
            if (!element)
                return nullptr;
            inspectorArray->pushValue(element);
        }
        return inspectorArray;
    }
    if (value->IsObject()) {
        RefPtr<JSONObject> jsonObject = JSONObject::create();
        v8::Handle<v8::Object> object = v8::Handle<v8::Object>::Cast(value);
        v8::Local<v8::Array> propertyNames = object->GetPropertyNames();
        uint32_t length = propertyNames->Length();
        for (uint32_t i = 0; i < length; i++) {
            v8::Local<v8::Value> name = propertyNames->Get(v8::Int32::New(isolate, i));
            // FIXME(yurys): v8::Object should support GetOwnPropertyNames
            if (name->IsString() && !object->HasRealNamedProperty(v8::Handle<v8::String>::Cast(name)))
                continue;
            RefPtr<JSONValue> propertyValue = v8ToJSONValue(isolate, object->Get(name), maxDepth);
            if (!propertyValue)
                return nullptr;
            TOSTRING_DEFAULT(V8StringResource<TreatNullAsNullString>, nameString, name, nullptr);
            jsonObject->setValue(nameString, propertyValue);
        }
        return jsonObject;
    }
    ASSERT_NOT_REACHED();
    return nullptr;
}

V8TestingScope::V8TestingScope(v8::Isolate* isolate)
    : m_handleScope(isolate)
    , m_contextScope(v8::Context::New(isolate))
    , m_scriptState(ScriptStateForTesting::create(isolate->GetCurrentContext(), DOMWrapperWorld::create()))
{
}

V8TestingScope::~V8TestingScope()
{
    m_scriptState->disposePerContextData();
}

ScriptState* V8TestingScope::scriptState() const
{
    return m_scriptState.get();
}

v8::Isolate* V8TestingScope::isolate() const
{
    return m_scriptState->isolate();
}

void GetDevToolsFunctionInfo(v8::Handle<v8::Function> function, v8::Isolate* isolate, int& scriptId, String& resourceName, int& lineNumber)
{
    v8::Handle<v8::Function> originalFunction = getBoundFunction(function);
    scriptId = originalFunction->ScriptId();
    v8::ScriptOrigin origin = originalFunction->GetScriptOrigin();
    if (!origin.ResourceName().IsEmpty()) {
        resourceName = NativeValueTraits<String>::nativeValue(origin.ResourceName(), isolate);
        lineNumber = originalFunction->GetScriptLineNumber() + 1;
    }
    if (resourceName.isEmpty()) {
        resourceName = "undefined";
        lineNumber = 1;
    }
}

PassRefPtr<TraceEvent::ConvertableToTraceFormat> devToolsTraceEventData(ExecutionContext* context, v8::Handle<v8::Function> function, v8::Isolate* isolate)
{
    int scriptId = 0;
    String resourceName;
    int lineNumber = 1;
    GetDevToolsFunctionInfo(function, isolate, scriptId, resourceName, lineNumber);
    return InspectorFunctionCallEvent::data(context, scriptId, resourceName, lineNumber);
}

} // namespace blink
