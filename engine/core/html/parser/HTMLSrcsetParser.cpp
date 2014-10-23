/*
 * Copyright (C) 2013 Apple Inc. All rights reserved.
 * Copyright (C) 2013 Google Inc. All rights reserved.
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
#include "core/html/parser/HTMLSrcsetParser.h"

#include "core/html/parser/HTMLParserIdioms.h"
#include "platform/ParsingUtilities.h"
#include "platform/RuntimeEnabledFeatures.h"

namespace blink {

static bool compareByDensity(const ImageCandidate& first, const ImageCandidate& second)
{
    return first.density() < second.density();
}

enum DescriptorTokenizerState {
    Start,
    InParenthesis,
    AfterToken,
};

struct DescriptorToken {
    unsigned start;
    unsigned length;

    DescriptorToken(unsigned start, unsigned length)
        : start(start)
        , length(length)
    {
    }

    unsigned lastIndex()
    {
        return start + length - 1;
    }

    template<typename CharType>
    int toInt(const CharType* attribute, bool& isValid)
    {
        return charactersToIntStrict(attribute + start, length - 1, &isValid);
    }

    template<typename CharType>
    float toFloat(const CharType* attribute, bool& isValid)
    {
        return charactersToFloat(attribute + start, length - 1, &isValid);
    }
};

template<typename CharType>
static void appendDescriptorAndReset(const CharType* attributeStart, const CharType*& descriptorStart, const CharType* position, Vector<DescriptorToken>& descriptors)
{
    if (position > descriptorStart)
        descriptors.append(DescriptorToken(descriptorStart - attributeStart, position - descriptorStart));
    descriptorStart = 0;
}

// The following is called appendCharacter to match the spec's terminology.
template<typename CharType>
static void appendCharacter(const CharType* descriptorStart, const CharType* position)
{
    // Since we don't copy the tokens, this just set the point where the descriptor tokens start.
    if (!descriptorStart)
        descriptorStart = position;
}

template<typename CharType>
static bool isEOF(const CharType* position, const CharType* end)
{
    return position >= end;
}

template<typename CharType>
static void tokenizeDescriptors(const CharType* attributeStart,
    const CharType*& position,
    const CharType* attributeEnd,
    Vector<DescriptorToken>& descriptors)
{
    DescriptorTokenizerState state = Start;
    const CharType* descriptorsStart = position;
    const CharType* currentDescriptorStart = descriptorsStart;
    while (true) {
        switch (state) {
        case Start:
            if (isEOF(position, attributeEnd)) {
                appendDescriptorAndReset(attributeStart, currentDescriptorStart, attributeEnd, descriptors);
                return;
            }
            if (isComma(*position)) {
                appendDescriptorAndReset(attributeStart, currentDescriptorStart, position, descriptors);
                ++position;
                return;
            }
            if (isHTMLSpace(*position)) {
                appendDescriptorAndReset(attributeStart, currentDescriptorStart, position, descriptors);
                currentDescriptorStart = position + 1;
                state = AfterToken;
            } else if (*position == '(') {
                appendCharacter(currentDescriptorStart, position);
                state = InParenthesis;
            } else {
                appendCharacter(currentDescriptorStart, position);
            }
            break;
        case InParenthesis:
            if (isEOF(position, attributeEnd)) {
                appendDescriptorAndReset(attributeStart, currentDescriptorStart, attributeEnd, descriptors);
                return;
            }
            if (*position == ')') {
                appendCharacter(currentDescriptorStart, position);
                state = Start;
            } else {
                appendCharacter(currentDescriptorStart, position);
            }
            break;
        case AfterToken:
            if (isEOF(position, attributeEnd))
                return;
            if (!isHTMLSpace(*position)) {
                state = Start;
                currentDescriptorStart = position;
                --position;
            }
            break;
        }
        ++position;
    }
}

template<typename CharType>
static bool parseDescriptors(const CharType* attribute, Vector<DescriptorToken>& descriptors, DescriptorParsingResult& result)
{
    for (Vector<DescriptorToken>::iterator it = descriptors.begin(); it != descriptors.end(); ++it) {
        if (it->length == 0)
            continue;
        CharType c = attribute[it->lastIndex()];
        bool isValid = false;
        if (RuntimeEnabledFeatures::pictureSizesEnabled() && c == 'w') {
            if (result.hasDensity() || result.hasWidth())
                return false;
            int resourceWidth = it->toInt(attribute, isValid);
            if (!isValid || resourceWidth <= 0)
                return false;
            result.setResourceWidth(resourceWidth);
        } else if (RuntimeEnabledFeatures::pictureSizesEnabled() && c == 'h') {
            // This is here only for future compat purposes.
            // The value of the 'h' descriptor is not used.
            if (result.hasDensity() || result.hasHeight())
                return false;
            int resourceHeight = it->toInt(attribute, isValid);
            if (!isValid || resourceHeight <= 0)
                return false;
            result.setResourceHeight(resourceHeight);
        } else if (c == 'x') {
            if (result.hasDensity() || result.hasHeight() || result.hasWidth())
                return false;
            float density = it->toFloat(attribute, isValid);
            if (!isValid || density < 0)
                return false;
            result.setDensity(density);
        }
    }
    return true;
}

static bool parseDescriptors(const String& attribute, Vector<DescriptorToken>& descriptors, DescriptorParsingResult& result)
{
    // FIXME: See if StringView can't be extended to replace DescriptorToken here.
    if (attribute.is8Bit()) {
        return parseDescriptors(attribute.characters8(), descriptors, result);
    }
    return parseDescriptors(attribute.characters16(), descriptors, result);
}

// http://picture.responsiveimages.org/#parse-srcset-attr
template<typename CharType>
static void parseImageCandidatesFromSrcsetAttribute(const String& attribute, const CharType* attributeStart, unsigned length, Vector<ImageCandidate>& imageCandidates)
{
    const CharType* position = attributeStart;
    const CharType* attributeEnd = position + length;

    while (position < attributeEnd) {
        // 4. Splitting loop: Collect a sequence of characters that are space characters or U+002C COMMA characters.
        skipWhile<CharType, isHTMLSpaceOrComma<CharType> >(position, attributeEnd);
        if (position == attributeEnd) {
            // Contrary to spec language - descriptor parsing happens on each candidate, so when we reach the attributeEnd, we can exit.
            break;
        }
        const CharType* imageURLStart = position;
        // 6. Collect a sequence of characters that are not space characters, and let that be url.

        skipUntil<CharType, isHTMLSpace<CharType> >(position, attributeEnd);
        const CharType* imageURLEnd = position;

        DescriptorParsingResult result;

        // 8. If url ends with a U+002C COMMA character (,)
        if (isComma(*(position - 1))) {
            // Remove all trailing U+002C COMMA characters from url.
            imageURLEnd = position - 1;
            reverseSkipWhile<CharType, isComma>(imageURLEnd, imageURLStart);
            ++imageURLEnd;
            // If url is empty, then jump to the step labeled splitting loop.
            if (imageURLStart == imageURLEnd)
                continue;
        } else {
            // Advancing position here (contrary to spec) to avoid an useless extra state machine step.
            // Filed a spec bug: https://github.com/ResponsiveImagesCG/picture-element/issues/189
            ++position;
            Vector<DescriptorToken> descriptorTokens;
            tokenizeDescriptors(attributeStart, position, attributeEnd, descriptorTokens);
            // Contrary to spec language - descriptor parsing happens on each candidate.
            // This is a black-box equivalent, to avoid storing descriptor lists for each candidate.
            if (!parseDescriptors(attribute, descriptorTokens, result))
                continue;
        }

        ASSERT(imageURLEnd > attributeStart);
        unsigned imageURLStartingPosition = imageURLStart - attributeStart;
        ASSERT(imageURLEnd > imageURLStart);
        unsigned imageURLLength = imageURLEnd - imageURLStart;
        imageCandidates.append(ImageCandidate(attribute, imageURLStartingPosition, imageURLLength, result, ImageCandidate::SrcsetOrigin));
        // 11. Return to the step labeled splitting loop.
    }
}

static void parseImageCandidatesFromSrcsetAttribute(const String& attribute, Vector<ImageCandidate>& imageCandidates)
{
    if (attribute.isNull())
        return;

    if (attribute.is8Bit())
        parseImageCandidatesFromSrcsetAttribute<LChar>(attribute, attribute.characters8(), attribute.length(), imageCandidates);
    else
        parseImageCandidatesFromSrcsetAttribute<UChar>(attribute, attribute.characters16(), attribute.length(), imageCandidates);
}

static ImageCandidate pickBestImageCandidate(float deviceScaleFactor, unsigned sourceSize, Vector<ImageCandidate>& imageCandidates)
{
    const float defaultDensityValue = 1.0;
    bool ignoreSrc = false;
    if (imageCandidates.isEmpty())
        return ImageCandidate();

    // http://picture.responsiveimages.org/#normalize-source-densities
    for (Vector<ImageCandidate>::iterator it = imageCandidates.begin(); it != imageCandidates.end(); ++it) {
        if (it->resourceWidth() > 0) {
            it->setDensity((float)it->resourceWidth() / (float)sourceSize);
            ignoreSrc = true;
        } else if (it->density() < 0) {
            it->setDensity(defaultDensityValue);
        }
    }

    std::stable_sort(imageCandidates.begin(), imageCandidates.end(), compareByDensity);

    unsigned i;
    for (i = 0; i < imageCandidates.size() - 1; ++i) {
        if ((imageCandidates[i].density() >= deviceScaleFactor) && (!ignoreSrc || !imageCandidates[i].srcOrigin()))
            break;
    }

    if (imageCandidates[i].srcOrigin() && ignoreSrc) {
        ASSERT(i > 0);
        --i;
    }
    float winningDensity = imageCandidates[i].density();

    unsigned winner = i;
    // 16. If an entry b in candidates has the same associated ... pixel density as an earlier entry a in candidates,
    // then remove entry b
    while ((i > 0) && (imageCandidates[--i].density() == winningDensity))
        winner = i;

    return imageCandidates[winner];
}

ImageCandidate bestFitSourceForSrcsetAttribute(float deviceScaleFactor, unsigned sourceSize, const String& srcsetAttribute)
{
    Vector<ImageCandidate> imageCandidates;

    parseImageCandidatesFromSrcsetAttribute(srcsetAttribute, imageCandidates);

    return pickBestImageCandidate(deviceScaleFactor, sourceSize, imageCandidates);
}

ImageCandidate bestFitSourceForImageAttributes(float deviceScaleFactor, unsigned sourceSize, const String& srcAttribute, const String& srcsetAttribute)
{
    if (srcsetAttribute.isNull()) {
        if (srcAttribute.isNull())
            return ImageCandidate();
        return ImageCandidate(srcAttribute, 0, srcAttribute.length(), DescriptorParsingResult(), ImageCandidate::SrcOrigin);
    }

    Vector<ImageCandidate> imageCandidates;

    parseImageCandidatesFromSrcsetAttribute(srcsetAttribute, imageCandidates);

    if (!srcAttribute.isEmpty())
        imageCandidates.append(ImageCandidate(srcAttribute, 0, srcAttribute.length(), DescriptorParsingResult(), ImageCandidate::SrcOrigin));

    return pickBestImageCandidate(deviceScaleFactor, sourceSize, imageCandidates);
}

String bestFitSourceForImageAttributes(float deviceScaleFactor, unsigned sourceSize, const String& srcAttribute, ImageCandidate& srcsetImageCandidate)
{
    if (srcsetImageCandidate.isEmpty())
        return srcAttribute;

    Vector<ImageCandidate> imageCandidates;
    imageCandidates.append(srcsetImageCandidate);

    if (!srcAttribute.isEmpty())
        imageCandidates.append(ImageCandidate(srcAttribute, 0, srcAttribute.length(), DescriptorParsingResult(), ImageCandidate::SrcOrigin));

    return pickBestImageCandidate(deviceScaleFactor, sourceSize, imageCandidates).toString();
}

}
