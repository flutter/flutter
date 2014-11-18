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

#include "config.h"

#include "core/inspector/ContentSearchUtils.h"

#include "bindings/core/v8/ScriptRegexp.h"
#include "wtf/Vector.h"
#include "wtf/text/StringBuilder.h"

namespace blink {
namespace ContentSearchUtils {

namespace {
// This should be kept the same as the one in front-end/utilities.js
static const char regexSpecialCharacters[] = "[](){}+-*.,?\\^$|";
}

static String createSearchRegexSource(const String& text)
{
    StringBuilder result;
    String specials(regexSpecialCharacters);

    for (unsigned i = 0; i < text.length(); i++) {
        if (specials.find(text[i]) != kNotFound)
            result.append('\\');
        result.append(text[i]);
    }

    return result.toString();
}

static Vector<pair<int, String> > getScriptRegexpMatchesByLines(const ScriptRegexp* regex, const String& text)
{
    Vector<pair<int, String> > result;
    if (text.isEmpty())
        return result;

    OwnPtr<Vector<unsigned> > endings(lineEndings(text));
    unsigned size = endings->size();
    unsigned start = 0;
    for (unsigned lineNumber = 0; lineNumber < size; ++lineNumber) {
        unsigned lineEnd = endings->at(lineNumber);
        String line = text.substring(start, lineEnd - start);
        if (line.endsWith('\r'))
            line = line.left(line.length() - 1);

        int matchLength;
        if (regex->match(line, 0, &matchLength) != -1)
            result.append(pair<int, String>(lineNumber, line));

        start = lineEnd + 1;
    }
    return result;
}

static PassRefPtr<TypeBuilder::Page::SearchMatch> buildObjectForSearchMatch(int lineNumber, const String& lineContent)
{
    return TypeBuilder::Page::SearchMatch::create()
        .setLineNumber(lineNumber)
        .setLineContent(lineContent)
        .release();
}

PassOwnPtr<ScriptRegexp> createSearchRegex(const String& query, bool caseSensitive, bool isRegex)
{
    String regexSource = isRegex ? query : createSearchRegexSource(query);
    return adoptPtr(new ScriptRegexp(regexSource, caseSensitive ? TextCaseSensitive : TextCaseInsensitive));
}

PassRefPtr<TypeBuilder::Array<TypeBuilder::Page::SearchMatch> > searchInTextByLines(const String& text, const String& query, const bool caseSensitive, const bool isRegex)
{
    RefPtr<TypeBuilder::Array<TypeBuilder::Page::SearchMatch> > result = TypeBuilder::Array<TypeBuilder::Page::SearchMatch>::create();

    OwnPtr<ScriptRegexp> regex = ContentSearchUtils::createSearchRegex(query, caseSensitive, isRegex);
    Vector<pair<int, String> > matches = getScriptRegexpMatchesByLines(regex.get(), text);

    for (Vector<pair<int, String> >::const_iterator it = matches.begin(); it != matches.end(); ++it)
        result->addItem(buildObjectForSearchMatch(it->first, it->second));

    return result;
}

static String findMagicComment(const String& content, const String& name, MagicCommentType commentType, bool* deprecated = 0)
{
    ASSERT(name.find("=") == kNotFound);
    if (deprecated)
        *deprecated = false;

    unsigned length = content.length();
    unsigned nameLength = name.length();

    size_t pos = length;
    size_t equalSignPos = 0;
    size_t closingCommentPos = 0;
    while (true) {
        pos = content.reverseFind(name, pos);
        if (pos == kNotFound)
            return String();

        // Check for a /\/[\/*][@#][ \t]/ regexp (length of 4) before found name.
        if (pos < 4)
            return String();
        pos -= 4;
        if (content[pos] != '/')
            continue;
        if ((content[pos + 1] != '/' || commentType != JavaScriptMagicComment)
            && (content[pos + 1] != '*' || commentType != CSSMagicComment))
            continue;
        if (content[pos + 2] != '#' && content[pos + 2] != '@')
            continue;
        if (content[pos + 3] != ' ' && content[pos + 3] != '\t')
            continue;
        equalSignPos = pos + 4 + nameLength;
        if (equalSignPos < length && content[equalSignPos] != '=')
            continue;
        if (commentType == CSSMagicComment) {
            closingCommentPos = content.find("*/", equalSignPos + 1);
            if (closingCommentPos == kNotFound)
                return String();
        }

        break;
    }

    if (deprecated && content[pos + 2] == '@')
        *deprecated = true;

    ASSERT(equalSignPos);
    ASSERT(commentType != CSSMagicComment || closingCommentPos);
    size_t urlPos = equalSignPos + 1;
    String match = commentType == CSSMagicComment
        ? content.substring(urlPos, closingCommentPos - urlPos)
        : content.substring(urlPos);

    size_t newLine = match.find("\n");
    if (newLine != kNotFound)
        match = match.substring(0, newLine);
    match = match.stripWhiteSpace();

    String disallowedChars("\"' \t");
    for (unsigned i = 0; i < match.length(); ++i) {
        if (disallowedChars.find(match[i]) != kNotFound)
            return "";
    }

    return match;
}

String findSourceURL(const String& content, MagicCommentType commentType, bool* deprecated)
{
    return findMagicComment(content, "sourceURL", commentType, deprecated);
}

String findSourceMapURL(const String& content, MagicCommentType commentType, bool* deprecated)
{
    return findMagicComment(content, "sourceMappingURL", commentType, deprecated);
}

} // namespace ContentSearchUtils
} // namespace blink

