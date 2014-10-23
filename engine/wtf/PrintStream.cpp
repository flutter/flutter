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

#include "config.h"
#include "PrintStream.h"

#include <stdio.h>
#include "wtf/text/CString.h"
#include "wtf/text/WTFString.h"

namespace WTF {

PrintStream::PrintStream() { }
PrintStream::~PrintStream() { } // Force the vtable to be in this module

void PrintStream::printf(const char* format, ...)
{
    va_list argList;
    va_start(argList, format);
    vprintf(format, argList);
    va_end(argList);
}

void PrintStream::flush()
{
}

void printInternal(PrintStream& out, const char* string)
{
    out.printf("%s", string);
}

void printInternal(PrintStream& out, const CString& string)
{
    out.print(string.data());
}

void printInternal(PrintStream& out, const String& string)
{
    out.print(string.utf8());
}

void printInternal(PrintStream& out, bool value)
{
    if (value)
        out.print("true");
    else
        out.print("false");
}

void printInternal(PrintStream& out, int value)
{
    out.printf("%d", value);
}

void printInternal(PrintStream& out, unsigned value)
{
    out.printf("%u", value);
}

void printInternal(PrintStream& out, long value)
{
    out.printf("%ld", value);
}

void printInternal(PrintStream& out, unsigned long value)
{
    out.printf("%lu", value);
}

void printInternal(PrintStream& out, long long value)
{
    out.printf("%lld", value);
}

void printInternal(PrintStream& out, unsigned long long value)
{
    out.printf("%llu", value);
}

void printInternal(PrintStream& out, float value)
{
    out.print(static_cast<double>(value));
}

void printInternal(PrintStream& out, double value)
{
    out.printf("%lf", value);
}

void dumpCharacter(PrintStream& out, char value)
{
    out.printf("%c", value);
}

} // namespace WTF

