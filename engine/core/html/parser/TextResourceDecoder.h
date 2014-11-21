// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_HTML_PARSER_TEXTRESOURCEDECODER_H_
#define SKY_ENGINE_CORE_HTML_PARSER_TEXTRESOURCEDECODER_H_

#include "sky/engine/wtf/RefCounted.h"
#include "sky/engine/wtf/text/TextEncoding.h"

namespace blink {

class TextResourceDecoder {
public:
    static PassOwnPtr<TextResourceDecoder> create()
    {
        return adoptPtr(new TextResourceDecoder());
    }
    ~TextResourceDecoder();

    const WTF::TextEncoding& encoding() const;
    String decode(const char* data, size_t length);
    String flush();

private:
    TextResourceDecoder();

    bool m_sawError;
    OwnPtr<TextCodec> m_codec;
};

}

#endif  // SKY_ENGINE_CORE_HTML_PARSER_TEXTRESOURCEDECODER_H_
