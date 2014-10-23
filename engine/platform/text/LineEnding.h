/*
 * Copyright (C) 2005, 2006, 2008 Apple Inc. All rights reserved.
 * Copyright (C) 2010 Google Inc. All rights reserved.
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

#ifndef LineEnding_h
#define LineEnding_h

#include "platform/PlatformExport.h"
#include "wtf/Forward.h"
#include "wtf/Vector.h"

namespace blink {

// Normalize all line-endings in the given string to CRLF.
PLATFORM_EXPORT CString normalizeLineEndingsToCRLF(const CString& from);

// Normalize all line-endings in the given string to CR and append the result to the given buffer.
PLATFORM_EXPORT void normalizeLineEndingsToCR(const CString& from, Vector<char>& result);

// Normalize all line-endings in the given string to LF and append the result to the given buffer.
PLATFORM_EXPORT void normalizeLineEndingsToLF(const CString& from, Vector<char>& result);

// Normalize all line-endings in the given string to the native line-endings and append the result to the given buffer.
// (Normalize to CRLF on Windows and normalize to LF on all other platforms.)
PLATFORM_EXPORT void normalizeLineEndingsToNative(const CString& from, Vector<char>& result);

} // namespace blink

#endif // LineEnding_h
