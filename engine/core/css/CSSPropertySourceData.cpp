/*
 * Copyright (c) 2010 Google Inc. All rights reserved.
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

#include "config.h"

#include "core/css/CSSPropertySourceData.h"

#include "wtf/StaticConstructors.h"
#include "wtf/text/StringBuilder.h"
#include "wtf/text/StringHash.h"

namespace blink {

SourceRange::SourceRange()
    : start(0)
    , end(0)
{
}

SourceRange::SourceRange(unsigned start, unsigned end)
    : start(start)
    , end(end)
{
}

unsigned SourceRange::length() const
{
    return end - start;
}

CSSPropertySourceData::CSSPropertySourceData(const String& name, const String& value, bool important, bool disabled, bool parsedOk, const SourceRange& range)
    : name(name)
    , value(value)
    , important(important)
    , disabled(disabled)
    , parsedOk(parsedOk)
    , range(range)
{
}

CSSPropertySourceData::CSSPropertySourceData(const CSSPropertySourceData& other)
    : name(other.name)
    , value(other.value)
    , important(other.important)
    , disabled(other.disabled)
    , parsedOk(other.parsedOk)
    , range(other.range)
{
}

CSSPropertySourceData::CSSPropertySourceData()
    : name("")
    , value("")
    , important(false)
    , disabled(false)
    , parsedOk(false)
    , range(SourceRange(0, 0))
{
}

String CSSPropertySourceData::toString() const
{
    DEFINE_STATIC_LOCAL(String, emptyValue, ("e"));
    if (!name && value == emptyValue)
        return String();

    StringBuilder result;
    if (disabled)
        result.appendLiteral("/* ");
    result.append(name);
    result.appendLiteral(": ");
    result.append(value);
    if (important)
        result.appendLiteral(" !important");
    result.append(';');
    if (disabled)
        result.appendLiteral(" */");
    return result.toString();
}

unsigned CSSPropertySourceData::hash() const
{
    return StringHash::hash(name) + 3 * StringHash::hash(value) + 7 * important + 13 * parsedOk + 31;
}

void CSSRuleSourceData::trace(Visitor* visitor)
{
    visitor->trace(ruleHeaderRange);
    visitor->trace(ruleBodyRange);
    visitor->trace(selectorRanges);
    visitor->trace(styleSourceData);
    visitor->trace(childRules);
}

} // namespace blink
