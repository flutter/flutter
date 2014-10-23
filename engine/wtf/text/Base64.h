/*
 * Copyright (C) 2006 Alexey Proskuryakov <ap@webkit.org>
 * Copyright (C) 2010 Patrick Gansterer <paroga@paroga.com>
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

#ifndef Base64_h
#define Base64_h

#include "wtf/Vector.h"
#include "wtf/WTFExport.h"
#include "wtf/text/CString.h"
#include "wtf/text/WTFString.h"

namespace WTF {

enum Base64EncodePolicy {
    Base64DoNotInsertLFs,
    Base64InsertLFs
};

enum Base64DecodePolicy {
    Base64DoNotValidatePadding,
    Base64ValidatePadding
};

WTF_EXPORT void base64Encode(const char*, unsigned, Vector<char>&, Base64EncodePolicy = Base64DoNotInsertLFs);
WTF_EXPORT void base64Encode(const Vector<char>&, Vector<char>&, Base64EncodePolicy = Base64DoNotInsertLFs);
WTF_EXPORT void base64Encode(const CString&, Vector<char>&, Base64EncodePolicy = Base64DoNotInsertLFs);
WTF_EXPORT String base64Encode(const char*, unsigned, Base64EncodePolicy = Base64DoNotInsertLFs);
WTF_EXPORT String base64Encode(const Vector<char>&, Base64EncodePolicy = Base64DoNotInsertLFs);
WTF_EXPORT String base64Encode(const CString&, Base64EncodePolicy = Base64DoNotInsertLFs);

WTF_EXPORT bool base64Decode(const String&, Vector<char>&, CharacterMatchFunctionPtr shouldIgnoreCharacter = 0, Base64DecodePolicy = Base64DoNotValidatePadding);
WTF_EXPORT bool base64Decode(const Vector<char>&, Vector<char>&, CharacterMatchFunctionPtr shouldIgnoreCharacter = 0, Base64DecodePolicy = Base64DoNotValidatePadding);
WTF_EXPORT bool base64Decode(const char*, unsigned, Vector<char>&, CharacterMatchFunctionPtr shouldIgnoreCharacter = 0, Base64DecodePolicy = Base64DoNotValidatePadding);
WTF_EXPORT bool base64Decode(const UChar*, unsigned, Vector<char>&, CharacterMatchFunctionPtr shouldIgnoreCharacter = 0, Base64DecodePolicy = Base64DoNotValidatePadding);

inline void base64Encode(const Vector<char>& in, Vector<char>& out, Base64EncodePolicy policy)
{
    base64Encode(in.data(), in.size(), out, policy);
}

inline void base64Encode(const CString& in, Vector<char>& out, Base64EncodePolicy policy)
{
    base64Encode(in.data(), in.length(), out, policy);
}

inline String base64Encode(const Vector<char>& in, Base64EncodePolicy policy)
{
    return base64Encode(in.data(), in.size(), policy);
}

inline String base64Encode(const CString& in, Base64EncodePolicy policy)
{
    return base64Encode(in.data(), in.length(), policy);
}

} // namespace WTF

using WTF::Base64EncodePolicy;
using WTF::Base64DoNotInsertLFs;
using WTF::Base64InsertLFs;
using WTF::Base64DecodePolicy;
using WTF::Base64DoNotValidatePadding;
using WTF::Base64ValidatePadding;
using WTF::base64Encode;
using WTF::base64Decode;

#endif // Base64_h
