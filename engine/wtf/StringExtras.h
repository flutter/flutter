/*
 * Copyright (C) 2006, 2010 Apple Inc. All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE COMPUTER, INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE COMPUTER, INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef WTF_StringExtras_h
#define WTF_StringExtras_h

#if OS(POSIX)
#define HAVE_STRINGS_H 1
#endif

#if !defined(HAVE_STRNSTR)
#if OS(MACOSX) || (OS(FREEBSD) && !defined(__GLIBC__))
#define HAVE_STRNSTR 1
#endif
#endif

#include <stdarg.h>
#include <stdio.h>
#include <string.h>

#if HAVE(STRINGS_H)
#include <strings.h>
#endif

#if COMPILER(MSVC)
// FIXME: why a COMPILER check instead of OS? also, these should be HAVE checks

inline int snprintf(char* buffer, size_t count, const char* format, ...)
{
    int result;
    va_list args;
    va_start(args, format);
    result = _vsnprintf(buffer, count, format, args);
    va_end(args);

    // In the case where the string entirely filled the buffer, _vsnprintf will not
    // null-terminate it, but snprintf must.
    if (count > 0)
        buffer[count - 1] = '\0';

    return result;
}

inline double wtf_vsnprintf(char* buffer, size_t count, const char* format, va_list args)
{
    int result = _vsnprintf(buffer, count, format, args);

    // In the case where the string entirely filled the buffer, _vsnprintf will not
    // null-terminate it, but vsnprintf must.
    if (count > 0)
        buffer[count - 1] = '\0';

    return result;
}

// Work around a difference in Microsoft's implementation of vsnprintf, where
// vsnprintf does not null terminate the buffer. WebKit can rely on the null termination.
#define vsnprintf(buffer, count, format, args) wtf_vsnprintf(buffer, count, format, args)

inline int strncasecmp(const char* s1, const char* s2, size_t len)
{
    return _strnicmp(s1, s2, len);
}

inline int strcasecmp(const char* s1, const char* s2)
{
    return _stricmp(s1, s2);
}

#endif

#if !HAVE(STRNSTR)

inline char* strnstr(const char* buffer, const char* target, size_t bufferLength)
{
    size_t targetLength = strlen(target);
    if (targetLength == 0)
        return const_cast<char*>(buffer);
    for (const char* start = buffer; *start && start + targetLength <= buffer + bufferLength; start++) {
        if (*start == *target && strncmp(start + 1, target + 1, targetLength - 1) == 0)
            return const_cast<char*>(start);
    }
    return 0;
}

#endif

#endif // WTF_StringExtras_h
