/*
 * Copyright (C) 2012 Apple Inc. All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef PrintStream_h
#define PrintStream_h

#include <stdarg.h>
#include "wtf/FastAllocBase.h"
#include "wtf/Noncopyable.h"
#include "wtf/StdLibExtras.h"
#include "wtf/WTFExport.h"

namespace WTF {

class CString;
class String;

class WTF_EXPORT PrintStream {
    WTF_MAKE_FAST_ALLOCATED; WTF_MAKE_NONCOPYABLE(PrintStream);
public:
    PrintStream();
    virtual ~PrintStream();

    void printf(const char* format, ...) WTF_ATTRIBUTE_PRINTF(2, 3);
    virtual void vprintf(const char* format, va_list) WTF_ATTRIBUTE_PRINTF(2, 0) = 0;

    // Typically a no-op for many subclasses of PrintStream, this is a hint that
    // the implementation should flush its buffers if it had not done so already.
    virtual void flush();

    template<typename T>
    void print(const T& value)
    {
        printInternal(*this, value);
    }

    template<typename T1, typename T2>
    void print(const T1& value1, const T2& value2)
    {
        print(value1);
        print(value2);
    }

    template<typename T1, typename T2, typename T3>
    void print(const T1& value1, const T2& value2, const T3& value3)
    {
        print(value1);
        print(value2);
        print(value3);
    }

    template<typename T1, typename T2, typename T3, typename T4>
    void print(const T1& value1, const T2& value2, const T3& value3, const T4& value4)
    {
        print(value1);
        print(value2);
        print(value3);
        print(value4);
    }

    template<typename T1, typename T2, typename T3, typename T4, typename T5>
    void print(const T1& value1, const T2& value2, const T3& value3, const T4& value4, const T5& value5)
    {
        print(value1);
        print(value2);
        print(value3);
        print(value4);
        print(value5);
    }

    template<typename T1, typename T2, typename T3, typename T4, typename T5, typename T6>
    void print(const T1& value1, const T2& value2, const T3& value3, const T4& value4, const T5& value5, const T6& value6)
    {
        print(value1);
        print(value2);
        print(value3);
        print(value4);
        print(value5);
        print(value6);
    }

    template<typename T1, typename T2, typename T3, typename T4, typename T5, typename T6, typename T7>
    void print(const T1& value1, const T2& value2, const T3& value3, const T4& value4, const T5& value5, const T6& value6, const T7& value7)
    {
        print(value1);
        print(value2);
        print(value3);
        print(value4);
        print(value5);
        print(value6);
        print(value7);
    }

    template<typename T1, typename T2, typename T3, typename T4, typename T5, typename T6, typename T7, typename T8>
    void print(const T1& value1, const T2& value2, const T3& value3, const T4& value4, const T5& value5, const T6& value6, const T7& value7, const T8& value8)
    {
        print(value1);
        print(value2);
        print(value3);
        print(value4);
        print(value5);
        print(value6);
        print(value7);
        print(value8);
    }

    template<typename T1, typename T2, typename T3, typename T4, typename T5, typename T6, typename T7, typename T8, typename T9>
    void print(const T1& value1, const T2& value2, const T3& value3, const T4& value4, const T5& value5, const T6& value6, const T7& value7, const T8& value8, const T9& value9)
    {
        print(value1);
        print(value2);
        print(value3);
        print(value4);
        print(value5);
        print(value6);
        print(value7);
        print(value8);
        print(value9);
    }

    template<typename T1, typename T2, typename T3, typename T4, typename T5, typename T6, typename T7, typename T8, typename T9, typename T10>
    void print(const T1& value1, const T2& value2, const T3& value3, const T4& value4, const T5& value5, const T6& value6, const T7& value7, const T8& value8, const T9& value9, const T10& value10)
    {
        print(value1);
        print(value2);
        print(value3);
        print(value4);
        print(value5);
        print(value6);
        print(value7);
        print(value8);
        print(value9);
        print(value10);
    }

    template<typename T1, typename T2, typename T3, typename T4, typename T5, typename T6, typename T7, typename T8, typename T9, typename T10, typename T11>
    void print(const T1& value1, const T2& value2, const T3& value3, const T4& value4, const T5& value5, const T6& value6, const T7& value7, const T8& value8, const T9& value9, const T10& value10, const T11& value11)
    {
        print(value1);
        print(value2);
        print(value3);
        print(value4);
        print(value5);
        print(value6);
        print(value7);
        print(value8);
        print(value9);
        print(value10);
        print(value11);
    }

    template<typename T1, typename T2, typename T3, typename T4, typename T5, typename T6, typename T7, typename T8, typename T9, typename T10, typename T11, typename T12>
    void print(const T1& value1, const T2& value2, const T3& value3, const T4& value4, const T5& value5, const T6& value6, const T7& value7, const T8& value8, const T9& value9, const T10& value10, const T11& value11, const T12& value12)
    {
        print(value1);
        print(value2);
        print(value3);
        print(value4);
        print(value5);
        print(value6);
        print(value7);
        print(value8);
        print(value9);
        print(value10);
        print(value11);
        print(value12);
    }

    template<typename T1, typename T2, typename T3, typename T4, typename T5, typename T6, typename T7, typename T8, typename T9, typename T10, typename T11, typename T12, typename T13>
    void print(const T1& value1, const T2& value2, const T3& value3, const T4& value4, const T5& value5, const T6& value6, const T7& value7, const T8& value8, const T9& value9, const T10& value10, const T11& value11, const T12& value12, const T13& value13)
    {
        print(value1);
        print(value2);
        print(value3);
        print(value4);
        print(value5);
        print(value6);
        print(value7);
        print(value8);
        print(value9);
        print(value10);
        print(value11);
        print(value12);
        print(value13);
    }
};

WTF_EXPORT void printInternal(PrintStream&, const char*);
WTF_EXPORT void printInternal(PrintStream&, const CString&);
WTF_EXPORT void printInternal(PrintStream&, const String&);
inline void printInternal(PrintStream& out, char* value) { printInternal(out, static_cast<const char*>(value)); }
inline void printInternal(PrintStream& out, CString& value) { printInternal(out, static_cast<const CString&>(value)); }
inline void printInternal(PrintStream& out, String& value) { printInternal(out, static_cast<const String&>(value)); }
WTF_EXPORT void printInternal(PrintStream&, bool);
WTF_EXPORT void printInternal(PrintStream&, int);
WTF_EXPORT void printInternal(PrintStream&, unsigned);
WTF_EXPORT void printInternal(PrintStream&, long);
WTF_EXPORT void printInternal(PrintStream&, unsigned long);
WTF_EXPORT void printInternal(PrintStream&, long long);
WTF_EXPORT void printInternal(PrintStream&, unsigned long long);
WTF_EXPORT void printInternal(PrintStream&, float);
WTF_EXPORT void printInternal(PrintStream&, double);

template<typename T>
void printInternal(PrintStream& out, const T& value)
{
    value.dump(out);
}

#define MAKE_PRINT_ADAPTOR(Name, Type, function) \
    class Name {                                 \
    public:                                      \
        Name(const Type& value)                  \
            : m_value(value)                     \
        {                                        \
        }                                        \
        void dump(PrintStream& out) const        \
        {                                        \
            function(out, m_value);              \
        }                                        \
    private:                                     \
        Type m_value;                            \
    }

#define MAKE_PRINT_METHOD_ADAPTOR(Name, Type, method) \
    class Name {                                 \
    public:                                      \
        Name(const Type& value)                  \
            : m_value(value)                     \
        {                                        \
        }                                        \
        void dump(PrintStream& out) const        \
        {                                        \
            m_value.method(out);                 \
        }                                        \
    private:                                     \
        const Type& m_value;                     \
    }

#define MAKE_PRINT_METHOD(Type, dumpMethod, method) \
    MAKE_PRINT_METHOD_ADAPTOR(DumperFor_##method, Type, dumpMethod);    \
    DumperFor_##method method() const { return DumperFor_##method(*this); }

// Use an adaptor-based dumper for characters to avoid situations where
// you've "compressed" an integer to a character and it ends up printing
// as ASCII when you wanted it to print as a number.
void dumpCharacter(PrintStream&, char);
MAKE_PRINT_ADAPTOR(CharacterDump, char, dumpCharacter);

template<typename T>
class PointerDump {
public:
    PointerDump(const T* ptr)
        : m_ptr(ptr)
    {
    }

    void dump(PrintStream& out) const
    {
        if (m_ptr)
            printInternal(out, *m_ptr);
        else
            out.print("(null)");
    }
private:
    const T* m_ptr;
};

template<typename T>
PointerDump<T> pointerDump(const T* ptr) { return PointerDump<T>(ptr); }

} // namespace WTF

using WTF::CharacterDump;
using WTF::PointerDump;
using WTF::PrintStream;
using WTF::pointerDump;

#endif // PrintStream_h

