/*
 * (C) 1999-2003 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2004, 2006, 2010, 2012 Apple Inc. All rights reserved.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this library; see the file COPYING.LIB.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 */
#include "config.h"
#include "core/css/MediaList.h"

#include "bindings/core/v8/ExceptionState.h"
#include "core/MediaFeatureNames.h"
#include "core/css/parser/BisonCSSParser.h"
#include "core/css/CSSStyleSheet.h"
#include "core/css/MediaQuery.h"
#include "core/css/MediaQueryExp.h"
#include "core/css/parser/MediaQueryParser.h"
#include "core/dom/Document.h"
#include "core/frame/LocalDOMWindow.h"
#include "core/inspector/ConsoleMessage.h"
#include "wtf/text/StringBuilder.h"

namespace blink {

/* MediaList is used to store 3 types of media related entities which mean the same:
 *
 * Media Queries, Media Types and Media Descriptors.
 *
 * Media queries, as described in the Media Queries Level 3 specification, build on
 * the mechanism outlined in HTML4. The syntax of media queries fit into the media
 * type syntax reserved in HTML4. The media attribute of HTML4 also exists in XHTML
 * and generic XML. The same syntax can also be used inside the @media and @import
 * rules of CSS.
 *
 * However, the parsing rules for media queries are incompatible with those of HTML4
 * and are consistent with those of media queries used in CSS.
 *
 * HTML5 (at the moment of writing still work in progress) references the Media Queries
 * specification directly and thus updates the rules for HTML.
 *
 * CSS 2.1 Spec (http://www.w3.org/TR/CSS21/media.html)
 * CSS 3 Media Queries Spec (http://www.w3.org/TR/css3-mediaqueries/)
 */

MediaQuerySet::MediaQuerySet()
{
}

MediaQuerySet::MediaQuerySet(const MediaQuerySet& o)
    : m_queries(o.m_queries.size())
{
    for (unsigned i = 0; i < m_queries.size(); ++i)
        m_queries[i] = o.m_queries[i]->copy();
}

DEFINE_EMPTY_DESTRUCTOR_WILL_BE_REMOVED(MediaQuerySet)

PassRefPtrWillBeRawPtr<MediaQuerySet> MediaQuerySet::create(const String& mediaString)
{
    if (mediaString.isEmpty())
        return MediaQuerySet::create();

    if (RuntimeEnabledFeatures::mediaQueryParserEnabled())
        return MediaQueryParser::parseMediaQuerySet(mediaString);

    BisonCSSParser parser(strictCSSParserContext());
    return parser.parseMediaQueryList(mediaString);
}

PassRefPtrWillBeRawPtr<MediaQuerySet> MediaQuerySet::createOffMainThread(const String& mediaString)
{
    if (mediaString.isEmpty())
        return MediaQuerySet::create();

    return MediaQueryParser::parseMediaQuerySet(mediaString);
}

bool MediaQuerySet::set(const String& mediaString)
{
    RefPtrWillBeRawPtr<MediaQuerySet> result = create(mediaString);
    m_queries.swap(result->m_queries);
    return true;
}

bool MediaQuerySet::add(const String& queryString)
{
    // To "parse a media query" for a given string means to follow "the parse
    // a media query list" steps and return "null" if more than one media query
    // is returned, or else the returned media query.
    RefPtrWillBeRawPtr<MediaQuerySet> result = create(queryString);

    // Only continue if exactly one media query is found, as described above.
    if (result->m_queries.size() != 1)
        return true;

    OwnPtrWillBeRawPtr<MediaQuery> newQuery = result->m_queries[0].release();
    ASSERT(newQuery);

    // If comparing with any of the media queries in the collection of media
    // queries returns true terminate these steps.
    for (size_t i = 0; i < m_queries.size(); ++i) {
        MediaQuery* query = m_queries[i].get();
        if (*query == *newQuery)
            return true;
    }

    m_queries.append(newQuery.release());
    return true;
}

bool MediaQuerySet::remove(const String& queryStringToRemove)
{
    // To "parse a media query" for a given string means to follow "the parse
    // a media query list" steps and return "null" if more than one media query
    // is returned, or else the returned media query.
    RefPtrWillBeRawPtr<MediaQuerySet> result = create(queryStringToRemove);

    // Only continue if exactly one media query is found, as described above.
    if (result->m_queries.size() != 1)
        return true;

    OwnPtrWillBeRawPtr<MediaQuery> newQuery = result->m_queries[0].release();
    ASSERT(newQuery);

    // Remove any media query from the collection of media queries for which
    // comparing with the media query returns true.
    bool found = false;
    for (size_t i = 0; i < m_queries.size(); ++i) {
        MediaQuery* query = m_queries[i].get();
        if (*query == *newQuery) {
            m_queries.remove(i);
            --i;
            found = true;
        }
    }

    return found;
}

void MediaQuerySet::addMediaQuery(PassOwnPtrWillBeRawPtr<MediaQuery> mediaQuery)
{
    m_queries.append(mediaQuery);
}

String MediaQuerySet::mediaText() const
{
    StringBuilder text;

    bool first = true;
    for (size_t i = 0; i < m_queries.size(); ++i) {
        if (!first)
            text.appendLiteral(", ");
        else
            first = false;
        text.append(m_queries[i]->cssText());
    }
    return text.toString();
}

void MediaQuerySet::trace(Visitor* visitor)
{
    // We don't support tracing of vectors of OwnPtrs (ie. OwnPtr<Vector<OwnPtr<MediaQuery> > >).
    // Since this is a transitional object we are just ifdef'ing it out when oilpan is not enabled.
#if ENABLE(OILPAN)
    visitor->trace(m_queries);
#endif
}

MediaList::MediaList(MediaQuerySet* mediaQueries, CSSStyleSheet* parentSheet)
    : m_mediaQueries(mediaQueries)
    , m_parentStyleSheet(parentSheet)
    , m_parentRule(nullptr)
{
    ScriptWrappable::init(this);
}

MediaList::MediaList(MediaQuerySet* mediaQueries, CSSRule* parentRule)
    : m_mediaQueries(mediaQueries)
    , m_parentStyleSheet(nullptr)
    , m_parentRule(parentRule)
{
    ScriptWrappable::init(this);
}

MediaList::~MediaList()
{
}

void MediaList::setMediaText(const String& value)
{
    CSSStyleSheet::RuleMutationScope mutationScope(m_parentRule);

    m_mediaQueries->set(value);

    if (m_parentStyleSheet)
        m_parentStyleSheet->didMutate();
}

String MediaList::item(unsigned index) const
{
    const WillBeHeapVector<OwnPtrWillBeMember<MediaQuery> >& queries = m_mediaQueries->queryVector();
    if (index < queries.size())
        return queries[index]->cssText();
    return String();
}

void MediaList::deleteMedium(const String& medium, ExceptionState& exceptionState)
{
    CSSStyleSheet::RuleMutationScope mutationScope(m_parentRule);

    bool success = m_mediaQueries->remove(medium);
    if (!success) {
        exceptionState.throwDOMException(NotFoundError, "Failed to delete '" + medium + "'.");
        return;
    }
    if (m_parentStyleSheet)
        m_parentStyleSheet->didMutate();
}

void MediaList::appendMedium(const String& medium, ExceptionState& exceptionState)
{
    CSSStyleSheet::RuleMutationScope mutationScope(m_parentRule);

    bool success = m_mediaQueries->add(medium);
    if (!success) {
        exceptionState.throwDOMException(InvalidCharacterError, "The value provided ('" + medium + "') is not a valid medium.");
        return;
    }

    if (m_parentStyleSheet)
        m_parentStyleSheet->didMutate();
}

void MediaList::reattach(MediaQuerySet* mediaQueries)
{
    ASSERT(mediaQueries);
    m_mediaQueries = mediaQueries;
}

void MediaList::trace(Visitor* visitor)
{
    visitor->trace(m_mediaQueries);
    visitor->trace(m_parentStyleSheet);
    visitor->trace(m_parentRule);
}

static void addResolutionWarningMessageToConsole(Document* document, const String& serializedExpression, CSSPrimitiveValue::UnitType type)
{
    ASSERT(document);

    DEFINE_STATIC_LOCAL(String, mediaQueryMessage, ("Consider using 'dppx' units, as in CSS '%replacementUnits%' means dots-per-CSS-%lengthUnit%, not dots-per-physical-%lengthUnit%, so does not correspond to the actual '%replacementUnits%' of a screen. In media query expression: "));
    DEFINE_STATIC_LOCAL(String, mediaValueDPI, ("dpi"));
    DEFINE_STATIC_LOCAL(String, mediaValueDPCM, ("dpcm"));
    DEFINE_STATIC_LOCAL(String, lengthUnitInch, ("inch"));
    DEFINE_STATIC_LOCAL(String, lengthUnitCentimeter, ("centimeter"));

    StringBuilder message;
    if (CSSPrimitiveValue::isDotsPerInch(type))
        message.append(String(mediaQueryMessage).replace("%replacementUnits%", mediaValueDPI).replace("%lengthUnit%", lengthUnitInch));
    else if (CSSPrimitiveValue::isDotsPerCentimeter(type))
        message.append(String(mediaQueryMessage).replace("%replacementUnits%", mediaValueDPCM).replace("%lengthUnit%", lengthUnitCentimeter));
    else
        ASSERT_NOT_REACHED();

    message.append(serializedExpression);

    document->addConsoleMessage(ConsoleMessage::create(CSSMessageSource, DebugMessageLevel, message.toString()));
}

static inline bool isResolutionMediaFeature(const String& mediaFeature)
{
    return mediaFeature == MediaFeatureNames::resolutionMediaFeature
        || mediaFeature == MediaFeatureNames::maxResolutionMediaFeature
        || mediaFeature == MediaFeatureNames::minResolutionMediaFeature;
}

void reportMediaQueryWarningIfNeeded(Document* document, const MediaQuerySet* mediaQuerySet)
{
    if (!mediaQuerySet || !document)
        return;

    const WillBeHeapVector<OwnPtrWillBeMember<MediaQuery> >& mediaQueries = mediaQuerySet->queryVector();
    const size_t queryCount = mediaQueries.size();

    if (!queryCount)
        return;

    CSSPrimitiveValue::UnitType suspiciousType = CSSPrimitiveValue::CSS_UNKNOWN;
    bool dotsPerPixelUsed = false;
    for (size_t i = 0; i < queryCount; ++i) {
        const MediaQuery* query = mediaQueries[i].get();
        if (equalIgnoringCase(query->mediaType(), "print"))
            continue;

        const ExpressionHeapVector& expressions = query->expressions();
        for (size_t j = 0; j < expressions.size(); ++j) {
            const MediaQueryExp* expression = expressions.at(j).get();
            if (isResolutionMediaFeature(expression->mediaFeature())) {
                MediaQueryExpValue expValue = expression->expValue();
                if (expValue.isValue) {
                    if (CSSPrimitiveValue::isDotsPerPixel(expValue.unit))
                        dotsPerPixelUsed = true;
                    else if (CSSPrimitiveValue::isDotsPerInch(expValue.unit) || CSSPrimitiveValue::isDotsPerCentimeter(expValue.unit))
                        suspiciousType = expValue.unit;
                }
            }
        }
    }

    if (suspiciousType && !dotsPerPixelUsed)
        addResolutionWarningMessageToConsole(document, mediaQuerySet->mediaText(), suspiciousType);
}

}
