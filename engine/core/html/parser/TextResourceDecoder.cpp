// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/html/parser/TextResourceDecoder.h"

#include "sky/engine/wtf/text/TextCodec.h"
#include "sky/engine/wtf/text/TextEncodingRegistry.h"

namespace blink {

TextResourceDecoder::TextResourceDecoder()
    : m_sawError(false)
{
}

TextResourceDecoder::~TextResourceDecoder()
{
}

const WTF::TextEncoding& TextResourceDecoder::encoding() const
{
    return WTF::UTF8Encoding();
}

String TextResourceDecoder::decode(const char* data, size_t len)
{
    if (!m_codec)
        m_codec = newTextCodec(encoding());
    return m_codec->decode(data, len, WTF::DoNotFlush, false, m_sawError);
}

String TextResourceDecoder::flush()
{
    if (!m_codec)
        m_codec = newTextCodec(encoding());

    String result = m_codec->decode(0, 0, WTF::FetchEOF, false, m_sawError);
    m_codec.clear();
    return result;
}

}
