// Copyright 2011, Google Inc.
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//    * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//    * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#include "config.h"
#include "bindings/core/dart/DartCSSRule.h"

#include "bindings/core/dart/DartCSSCharsetRule.h"
#include "bindings/core/dart/DartCSSFontFaceRule.h"
#include "bindings/core/dart/DartCSSImportRule.h"
#include "bindings/core/dart/DartCSSKeyframeRule.h"
#include "bindings/core/dart/DartCSSKeyframesRule.h"
#include "bindings/core/dart/DartCSSMediaRule.h"
#include "bindings/core/dart/DartCSSPageRule.h"
#include "bindings/core/dart/DartCSSStyleRule.h"
#include "bindings/core/dart/DartCSSSupportsRule.h"
#include "bindings/core/dart/DartCSSViewportRule.h"
#include "bindings/core/dart/DartWebKitCSSFilterRule.h"

namespace blink {

Dart_Handle DartCSSRule::createWrapper(DartDOMData* domData, CSSRule* impl)
{
    if (!impl)
        return Dart_Null();

    switch (impl->type()) {
    case CSSRule::UNKNOWN_RULE:
        // CSSUnknownRule.idl is explicitly excluded as it doesn't add anything
        // over CSSRule.idl (see WebCore.gyp/WebCore.gyp: 'bindings_idl_files').
        // -> Use the base class wrapper here.
        return DartDOMWrapper::createWrapper<DartCSSRule>(domData, impl);
    case CSSRule::STYLE_RULE:
        return DartCSSStyleRule::createWrapper(domData, static_cast<CSSStyleRule*>(impl));
    case CSSRule::CHARSET_RULE:
        return DartCSSCharsetRule::createWrapper(domData, static_cast<CSSCharsetRule*>(impl));
    case CSSRule::IMPORT_RULE:
        return DartCSSImportRule::createWrapper(domData, static_cast<CSSImportRule*>(impl));
    case CSSRule::MEDIA_RULE:
        return DartCSSMediaRule::createWrapper(domData, static_cast<CSSMediaRule*>(impl));
    case CSSRule::FONT_FACE_RULE:
        return DartCSSFontFaceRule::createWrapper(domData, static_cast<CSSFontFaceRule*>(impl));
    case CSSRule::PAGE_RULE:
        return DartCSSPageRule::createWrapper(domData, static_cast<CSSPageRule*>(impl));
    case CSSRule::KEYFRAME_RULE:
        return DartCSSKeyframeRule::createWrapper(domData, static_cast<CSSKeyframeRule*>(impl));
    case CSSRule::KEYFRAMES_RULE:
        return DartCSSKeyframesRule::createWrapper(domData, static_cast<CSSKeyframesRule*>(impl));
    case CSSRule::SUPPORTS_RULE:
        return DartCSSSupportsRule::createWrapper(domData, static_cast<CSSSupportsRule*>(impl));
    case CSSRule::VIEWPORT_RULE:
        return DartCSSViewportRule::createWrapper(domData, static_cast<CSSViewportRule*>(impl));
    case CSSRule::WEBKIT_FILTER_RULE:
        return DartWebKitCSSFilterRule::createWrapper(domData, static_cast<CSSFilterRule*>(impl));
    }
    return DartDOMWrapper::createWrapper<DartCSSRule>(domData, impl);
}

}
