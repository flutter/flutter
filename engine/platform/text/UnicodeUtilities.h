/*
 * Copyright (C) 2004, 2006, 2009 Apple Inc. All rights reserved.
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

#ifndef UnicodeUtilities_h
#define UnicodeUtilities_h

#include "platform/PlatformExport.h"
#include "wtf/Vector.h"
#include "wtf/text/WTFString.h"
#include "wtf/unicode/Unicode.h"

namespace blink {

PLATFORM_EXPORT bool isSeparator(UChar32);
PLATFORM_EXPORT bool isKanaLetter(UChar character);
PLATFORM_EXPORT bool containsKanaLetters(const String&);
PLATFORM_EXPORT void normalizeCharactersIntoNFCForm(const UChar* characters, unsigned length, Vector<UChar>& buffer);
PLATFORM_EXPORT void foldQuoteMarksAndSoftHyphens(UChar* data, size_t length);
PLATFORM_EXPORT void foldQuoteMarksAndSoftHyphens(String&);
PLATFORM_EXPORT bool checkOnlyKanaLettersInStrings(const UChar* firstData, unsigned firstLength, const UChar* secondData, unsigned secondLength);
PLATFORM_EXPORT bool checkKanaStringsEqual(const UChar* firstData, unsigned firstLength, const UChar* secondData, unsigned secondLength);

} // namespace blink

#endif // UnicodeUtilities_h
