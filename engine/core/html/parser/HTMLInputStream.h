// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_HTML_PARSER_HTMLINPUTSTREAM_H_
#define SKY_ENGINE_CORE_HTML_PARSER_HTMLINPUTSTREAM_H_

#include "sky/engine/core/html/parser/InputStreamPreprocessor.h"
#include "sky/engine/platform/text/SegmentedString.h"

namespace blink {

class HTMLInputStream {
    WTF_MAKE_NONCOPYABLE(HTMLInputStream);
public:
    HTMLInputStream() { }

    void appendToEnd(const SegmentedString& string)
    {
        m_string.append(string);
    }

    void markEndOfFile()
    {
        m_string.append(SegmentedString(String(&kEndOfFileMarker, 1)));
        m_string.close();
    }

    SegmentedString& current() { return m_string; }
    const SegmentedString& current() const { return m_string; }

private:
    SegmentedString m_string;
};

}

#endif  // SKY_ENGINE_CORE_HTML_PARSER_HTMLINPUTSTREAM_H_
