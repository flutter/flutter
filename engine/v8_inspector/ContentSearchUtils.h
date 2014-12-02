/*
 * Copyright (C) 2011 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 * 1. Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY GOOGLE INC. AND ITS CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL GOOGLE INC.
 * OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef SKY_ENGINE_V8_INSPECTOR_CONTENTSEARCHUTILS_H_
#define SKY_ENGINE_V8_INSPECTOR_CONTENTSEARCHUTILS_H_

#include "gen/v8_inspector/InspectorTypeBuilder.h"
#include "sky/engine/wtf/PassOwnPtr.h"
#include "sky/engine/wtf/text/TextPosition.h"
#include "sky/engine/wtf/text/WTFString.h"

namespace blink {

class ScriptRegexp;

namespace ContentSearchUtils {

enum MagicCommentType {
    JavaScriptMagicComment,
    CSSMagicComment
};

PassOwnPtr<ScriptRegexp> createSearchRegex(const String& query, bool caseSensitive, bool isRegex);
PassRefPtr<TypeBuilder::Array<TypeBuilder::Page::SearchMatch> > searchInTextByLines(const String& text, const String& query, const bool caseSensitive, const bool isRegex);

String findSourceURL(const String& content, MagicCommentType, bool* deprecated);
String findSourceMapURL(const String& content, MagicCommentType, bool* deprecated);

} // namespace ContentSearchUtils
} // namespace blink


#endif  // SKY_ENGINE_V8_INSPECTOR_CONTENTSEARCHUTILS_H_
