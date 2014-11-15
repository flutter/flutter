/*
 * Copyright (C) 2009 Google Inc. All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef V8StringResource_h
#define V8StringResource_h

#include "v8/include/v8.h"
#include "wtf/text/AtomicString.h"
#include "wtf/text/WTFString.h"
#include "wtf/Threading.h"

namespace blink {

class ExternalStringVisitor;

// WebCoreStringResource is a helper class for v8ExternalString. It is used
// to manage the life-cycle of the underlying buffer of the external string.
class WebCoreStringResourceBase {
public:
    explicit WebCoreStringResourceBase(const String& string)
        : m_plainString(string)
    {
#if ENABLE(ASSERT)
        m_threadId = WTF::currentThread();
#endif
        ASSERT(!string.isNull());
        v8::Isolate::GetCurrent()->AdjustAmountOfExternalAllocatedMemory(memoryConsumption(string));
    }

    explicit WebCoreStringResourceBase(const AtomicString& string)
        : m_plainString(string.string())
        , m_atomicString(string)
    {
#if ENABLE(ASSERT)
        m_threadId = WTF::currentThread();
#endif
        ASSERT(!string.isNull());
        v8::Isolate::GetCurrent()->AdjustAmountOfExternalAllocatedMemory(memoryConsumption(string));
    }

    virtual ~WebCoreStringResourceBase()
    {
#if ENABLE(ASSERT)
        ASSERT(m_threadId == WTF::currentThread());
#endif
        int reducedExternalMemory = -memoryConsumption(m_plainString);
        if (m_plainString.impl() != m_atomicString.impl() && !m_atomicString.isNull())
            reducedExternalMemory -= memoryConsumption(m_atomicString.string());
        v8::Isolate::GetCurrent()->AdjustAmountOfExternalAllocatedMemory(reducedExternalMemory);
    }

    const String& webcoreString() { return m_plainString; }

    const AtomicString& atomicString()
    {
#if ENABLE(ASSERT)
        ASSERT(m_threadId == WTF::currentThread());
#endif
        if (m_atomicString.isNull()) {
            m_atomicString = AtomicString(m_plainString);
            ASSERT(!m_atomicString.isNull());
            if (m_plainString.impl() != m_atomicString.impl())
                v8::Isolate::GetCurrent()->AdjustAmountOfExternalAllocatedMemory(memoryConsumption(m_atomicString.string()));
        }
        return m_atomicString;
    }

protected:
    // A shallow copy of the string. Keeps the string buffer alive until the V8 engine garbage collects it.
    String m_plainString;
    // If this string is atomic or has been made atomic earlier the
    // atomic string is held here. In the case where the string starts
    // off non-atomic and becomes atomic later it is necessary to keep
    // the original string alive because v8 may keep derived pointers
    // into that string.
    AtomicString m_atomicString;

private:
    static int memoryConsumption(const String& string)
    {
        return string.length() * (string.is8Bit() ? sizeof(LChar) : sizeof(UChar));
    }
#if ENABLE(ASSERT)
    WTF::ThreadIdentifier m_threadId;
#endif
};

class WebCoreStringResource16 final : public WebCoreStringResourceBase, public v8::String::ExternalStringResource {
public:
    explicit WebCoreStringResource16(const String& string)
        : WebCoreStringResourceBase(string)
    {
        ASSERT(!string.is8Bit());
    }

    explicit WebCoreStringResource16(const AtomicString& string)
        : WebCoreStringResourceBase(string)
    {
        ASSERT(!string.is8Bit());
    }

    virtual size_t length() const override { return m_plainString.impl()->length(); }
    virtual const uint16_t* data() const override
    {
        return reinterpret_cast<const uint16_t*>(m_plainString.impl()->characters16());
    }
};

class WebCoreStringResource8 final : public WebCoreStringResourceBase, public v8::String::ExternalOneByteStringResource {
public:
    explicit WebCoreStringResource8(const String& string)
        : WebCoreStringResourceBase(string)
    {
        ASSERT(string.is8Bit());
    }

    explicit WebCoreStringResource8(const AtomicString& string)
        : WebCoreStringResourceBase(string)
    {
        ASSERT(string.is8Bit());
    }

    virtual size_t length() const override { return m_plainString.impl()->length(); }
    virtual const char* data() const override
    {
        return reinterpret_cast<const char*>(m_plainString.impl()->characters8());
    }
};

enum ExternalMode {
    Externalize,
    DoNotExternalize
};

template <typename StringType>
StringType v8StringToWebCoreString(v8::Handle<v8::String>, ExternalMode);
String int32ToWebCoreString(int value);

// V8StringResource is an adapter class that converts V8 values to Strings
// or AtomicStrings as appropriate, using multiple typecast operators.
enum V8StringResourceMode {
    DefaultMode,
    TreatNullAsEmptyString,
    TreatNullAsNullString,
    TreatNullAndUndefinedAsNullString
};

template <V8StringResourceMode Mode = DefaultMode>
class V8StringResource {
public:
    V8StringResource()
        : m_mode(Externalize)
    {
    }

    V8StringResource(v8::Handle<v8::Value> object)
        : m_v8Object(object)
        , m_mode(Externalize)
    {
    }

    void operator=(v8::Handle<v8::Value> object)
    {
        m_v8Object = object;
    }

    void operator=(const String& string)
    {
        setString(string);
    }

    void operator=(std::nullptr_t)
    {
        setString(String());
    }

    bool prepare()
    {
        if (m_v8Object.IsEmpty())
            return true;

        if (!isValid()) {
            setString(fallbackString());
            return true;
        }

        if (LIKELY(m_v8Object->IsString()))
            return true;

        if (LIKELY(m_v8Object->IsInt32())) {
            setString(int32ToWebCoreString(m_v8Object->Int32Value()));
            return true;
        }

        m_mode = DoNotExternalize;
        v8::TryCatch block;
        m_v8Object = m_v8Object->ToString();
        // Handle the case where an exception is thrown as part of invoking toString on the object.
        if (block.HasCaught()) {
            block.ReThrow();
            return false;
        }
        return true;
    }
    operator String() const { return toString<String>(); }
    operator AtomicString() const { return toString<AtomicString>(); }

private:
    bool isValid() const;
    String fallbackString() const;

    void setString(const String& string)
    {
        m_string = string;
        m_v8Object.Clear(); // To signal that String is ready.
    }

    template <class StringType>
    StringType toString() const
    {
        if (LIKELY(!m_v8Object.IsEmpty()))
            return v8StringToWebCoreString<StringType>(const_cast<v8::Handle<v8::Value>*>(&m_v8Object)->As<v8::String>(), m_mode);

        return StringType(m_string);
    }

    v8::Handle<v8::Value> m_v8Object;
    ExternalMode m_mode;
    String m_string;
};

template<> inline bool V8StringResource<DefaultMode>::isValid() const
{
    return true;
}

template<> inline String V8StringResource<DefaultMode>::fallbackString() const
{
    ASSERT_NOT_REACHED();
    return String();
}

template<> inline bool V8StringResource<TreatNullAsEmptyString>::isValid() const
{
    return !m_v8Object->IsNull();
}

template<> inline String V8StringResource<TreatNullAsEmptyString>::fallbackString() const
{
    return emptyString();
}

template<> inline bool V8StringResource<TreatNullAsNullString>::isValid() const
{
    return !m_v8Object->IsNull();
}

template<> inline String V8StringResource<TreatNullAsNullString>::fallbackString() const
{
    return String();
}

template<> inline bool V8StringResource<TreatNullAndUndefinedAsNullString>::isValid() const
{
    return !m_v8Object->IsNull() && !m_v8Object->IsUndefined();
}

template<> inline String V8StringResource<TreatNullAndUndefinedAsNullString>::fallbackString() const
{
    return String();
}

} // namespace blink

#endif // V8StringResource_h
