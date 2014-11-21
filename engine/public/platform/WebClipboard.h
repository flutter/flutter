/*
 * Copyright (C) 2009 Google Inc. All rights reserved.
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

#ifndef SKY_ENGINE_PUBLIC_PLATFORM_WEBCLIPBOARD_H_
#define SKY_ENGINE_PUBLIC_PLATFORM_WEBCLIPBOARD_H_

#include "sky/engine/public/platform/WebCommon.h"
#include "sky/engine/public/platform/WebData.h"
#include "sky/engine/public/platform/WebImage.h"
#include "sky/engine/public/platform/WebString.h"
#include "sky/engine/public/platform/WebURL.h"
#include "sky/engine/public/platform/WebVector.h"

namespace blink {

class WebImage;
class WebURL;

class WebClipboard {
public:
    enum Format {
        FormatPlainText,
        FormatHTML,
        FormatBookmark,
        FormatSmartPaste
    };

    enum Buffer {
        BufferStandard,
        // Used on platforms like the X Window System that treat selection
        // as a type of clipboard.
        BufferSelection,
    };

    // Returns an identifier which can be used to determine whether the data
    // contained within the clipboard has changed.
    virtual uint64_t sequenceNumber(Buffer) { return 0; }

    virtual bool isFormatAvailable(Format, Buffer) { return false; }

    virtual WebVector<WebString> readAvailableTypes(
        Buffer, bool* containsFilenames) { return WebVector<WebString>(); }
    virtual WebString readPlainText(Buffer) { return WebString(); }
    // fragmentStart and fragmentEnd are indexes into the returned markup that
    // indicate the start and end of the fragment if the returned markup
    // contains additional context. If there is no additional context,
    // fragmentStart will be zero and fragmentEnd will be the same as the length
    // of the returned markup.
    virtual WebString readHTML(
        Buffer buffer, WebURL* pageURL, unsigned* fragmentStart,
        unsigned* fragmentEnd) { return WebString(); }
    virtual WebData readImage(Buffer) { return WebData(); }
    virtual WebString readCustomData(
        Buffer, const WebString& type) { return WebString(); }

    virtual void writePlainText(const WebString&) { }
    virtual void writeHTML(
        const WebString& htmlText, const WebURL&,
        const WebString& plainText, bool writeSmartPaste) { }
    virtual void writeImage(
        const WebImage&, const WebURL&, const WebString& title) { }

protected:
    ~WebClipboard() { }
};

} // namespace blink

#endif  // SKY_ENGINE_PUBLIC_PLATFORM_WEBCLIPBOARD_H_
