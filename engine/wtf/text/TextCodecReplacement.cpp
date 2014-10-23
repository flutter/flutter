// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "wtf/text/TextCodecReplacement.h"

#include "wtf/PassOwnPtr.h"
#include "wtf/text/WTFString.h"
#include "wtf/unicode/CharacterNames.h"

namespace WTF {

TextCodecReplacement::TextCodecReplacement()
    : m_sentEOF(false)
{
}

void TextCodecReplacement::registerEncodingNames(EncodingNameRegistrar registrar)
{
    // The 'replacement' label itself should not be referenceable by
    // resources or script - it's a specification convenience - but much of
    // the wtf/text API asserts that an encoding name is a label for itself.
    // This is handled in TextEncoding by marking it as not valid.
    registrar("replacement", "replacement");

    registrar("csiso2022kr", "replacement");
    registrar("hz-gb-2312", "replacement");
    registrar("iso-2022-cn", "replacement");
    registrar("iso-2022-cn-ext", "replacement");
    registrar("iso-2022-kr", "replacement");
}

static PassOwnPtr<TextCodec> newStreamingTextDecoderReplacement(const TextEncoding&, const void*)
{
    return adoptPtr(new TextCodecReplacement);
}

void TextCodecReplacement::registerCodecs(TextCodecRegistrar registrar)
{
    registrar("replacement", newStreamingTextDecoderReplacement, 0);
}

String TextCodecReplacement::decode(const char*, size_t, FlushBehavior, bool, bool& sawError)
{
    sawError = true;
    if (m_sentEOF)
        return String();

    m_sentEOF = true;
    return String(&Unicode::replacementCharacter, 1);
}

} // namespace WTF
