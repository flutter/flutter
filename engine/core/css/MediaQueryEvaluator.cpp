/*
 * CSS Media Query Evaluator
 *
 * Copyright (C) 2006 Kimmo Kinnunen <kimmo.t.kinnunen@nokia.com>.
 * Copyright (C) 2013 Apple Inc. All rights reserved.
 * Copyright (C) 2013 Intel Corporation. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE COMPUTER, INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "core/css/MediaQueryEvaluator.h"

#include "core/CSSValueKeywords.h"
#include "core/MediaFeatureNames.h"
#include "core/MediaFeatures.h"
#include "core/MediaTypeNames.h"
#include "core/css/CSSAspectRatioValue.h"
#include "core/css/CSSHelper.h"
#include "core/css/CSSPrimitiveValue.h"
#include "core/css/CSSToLengthConversionData.h"
#include "core/css/MediaList.h"
#include "core/css/MediaQuery.h"
#include "core/css/MediaValuesDynamic.h"
#include "core/css/PointerProperties.h"
#include "core/css/resolver/MediaQueryResult.h"
#include "core/dom/NodeRenderStyle.h"
#include "core/frame/FrameHost.h"
#include "core/frame/FrameView.h"
#include "core/frame/LocalFrame.h"
#include "core/frame/Settings.h"
#include "core/frame/UseCounter.h"
#include "core/rendering/RenderView.h"
#include "core/rendering/compositing/RenderLayerCompositor.h"
#include "core/rendering/style/RenderStyle.h"
#include "platform/PlatformScreen.h"
#include "platform/RuntimeEnabledFeatures.h"
#include "platform/geometry/FloatRect.h"
#include "wtf/HashMap.h"

namespace blink {

using namespace MediaFeatureNames;

enum MediaFeaturePrefix { MinPrefix, MaxPrefix, NoPrefix };

typedef bool (*EvalFunc)(const MediaQueryExpValue&, MediaFeaturePrefix, const MediaValues&);
typedef HashMap<StringImpl*, EvalFunc> FunctionMap;
static FunctionMap* gFunctionMap;

MediaQueryEvaluator::MediaQueryEvaluator(bool mediaFeatureResult)
    : m_expectedResult(mediaFeatureResult)
{
}

MediaQueryEvaluator::MediaQueryEvaluator(const char* acceptedMediaType, bool mediaFeatureResult)
    : m_mediaType(acceptedMediaType)
    , m_expectedResult(mediaFeatureResult)
{
}

MediaQueryEvaluator::MediaQueryEvaluator(LocalFrame* frame)
    : m_expectedResult(false) // Doesn't matter when we have m_frame and m_style.
    , m_mediaValues(MediaValues::createDynamicIfFrameExists(frame))
{
}

MediaQueryEvaluator::MediaQueryEvaluator(const MediaValues& mediaValues)
    : m_expectedResult(false) // Doesn't matter when we have mediaValues.
    , m_mediaValues(mediaValues.copy())
{
}

MediaQueryEvaluator::~MediaQueryEvaluator()
{
}

const String MediaQueryEvaluator::mediaType() const
{
    // If a static mediaType was given by the constructor, we use it here.
    if (!m_mediaType.isEmpty())
        return m_mediaType;
    // Otherwise, we get one from mediaValues (which may be dynamic or cached).
    if (m_mediaValues)
        return m_mediaValues->mediaType();
    return nullAtom;
}

bool MediaQueryEvaluator::mediaTypeMatch(const String& mediaTypeToMatch) const
{
    return mediaTypeToMatch.isEmpty()
        || equalIgnoringCase(mediaTypeToMatch, MediaTypeNames::all)
        || equalIgnoringCase(mediaTypeToMatch, mediaType());
}

static bool applyRestrictor(MediaQuery::Restrictor r, bool value)
{
    return r == MediaQuery::Not ? !value : value;
}

bool MediaQueryEvaluator::eval(const MediaQuery* query, MediaQueryResultList* viewportDependentMediaQueryResults) const
{
    if (!mediaTypeMatch(query->mediaType()))
        return applyRestrictor(query->restrictor(), false);

    const ExpressionHeapVector& expressions = query->expressions();
    // Iterate through expressions, stop if any of them eval to false (AND semantics).
    size_t i = 0;
    for (; i < expressions.size(); ++i) {
        bool exprResult = eval(expressions.at(i).get());
        if (viewportDependentMediaQueryResults && expressions.at(i)->isViewportDependent())
            viewportDependentMediaQueryResults->append(adoptRefWillBeNoop(new MediaQueryResult(*expressions.at(i), exprResult)));
        if (!exprResult)
            break;
    }

    // Assume true if we are at the end of the list, otherwise assume false.
    return applyRestrictor(query->restrictor(), expressions.size() == i);
}

bool MediaQueryEvaluator::eval(const MediaQuerySet* querySet, MediaQueryResultList* viewportDependentMediaQueryResults) const
{
    if (!querySet)
        return true;

    const WillBeHeapVector<OwnPtrWillBeMember<MediaQuery> >& queries = querySet->queryVector();
    if (!queries.size())
        return true; // Empty query list evaluates to true.

    // Iterate over queries, stop if any of them eval to true (OR semantics).
    bool result = false;
    for (size_t i = 0; i < queries.size() && !result; ++i)
        result = eval(queries[i].get(), viewportDependentMediaQueryResults);

    return result;
}

template<typename T>
bool compareValue(T a, T b, MediaFeaturePrefix op)
{
    switch (op) {
    case MinPrefix:
        return a >= b;
    case MaxPrefix:
        return a <= b;
    case NoPrefix:
        return a == b;
    }
    return false;
}

static bool compareAspectRatioValue(const MediaQueryExpValue& value, int width, int height, MediaFeaturePrefix op)
{
    if (value.isRatio)
        return compareValue(width * static_cast<int>(value.denominator), height * static_cast<int>(value.numerator), op);

    return false;
}

static bool numberValue(const MediaQueryExpValue& value, float& result)
{
    if (value.isValue && value.unit == CSSPrimitiveValue::CSS_NUMBER) {
        result = value.value;
        return true;
    }
    return false;
}

static bool colorMediaFeatureEval(const MediaQueryExpValue& value, MediaFeaturePrefix op, const MediaValues& mediaValues)
{
    float number;
    int bitsPerComponent = mediaValues.colorBitsPerComponent();
    if (value.isValid())
        return numberValue(value, number) && compareValue(bitsPerComponent, static_cast<int>(number), op);

    return bitsPerComponent != 0;
}

static bool colorIndexMediaFeatureEval(const MediaQueryExpValue& value, MediaFeaturePrefix op, const MediaValues&)
{
    // FIXME: We currently assume that we do not support indexed displays, as it is unknown
    // how to retrieve the information if the display mode is indexed. This matches Firefox.
    if (!value.isValid())
        return false;

    // Acording to spec, if the device does not use a color lookup table, the value is zero.
    float number;
    return numberValue(value, number) && compareValue(0, static_cast<int>(number), op);
}

static bool monochromeMediaFeatureEval(const MediaQueryExpValue& value, MediaFeaturePrefix op, const MediaValues& mediaValues)
{
    if (!mediaValues.monochromeBitsPerComponent()) {
        if (value.isValid()) {
            float number;
            return numberValue(value, number) && compareValue(0, static_cast<int>(number), op);
        }
        return false;
    }

    return colorMediaFeatureEval(value, op, mediaValues);
}

static bool orientationMediaFeatureEval(const MediaQueryExpValue& value, MediaFeaturePrefix, const MediaValues& mediaValues)
{
    int width = mediaValues.viewportWidth();
    int height = mediaValues.viewportHeight();

    if (value.isID) {
        if (width > height) // Square viewport is portrait.
            return CSSValueLandscape == value.id;
        return CSSValuePortrait == value.id;
    }

    // Expression (orientation) evaluates to true if width and height >= 0.
    return height >= 0 && width >= 0;
}

static bool aspectRatioMediaFeatureEval(const MediaQueryExpValue& value, MediaFeaturePrefix op, const MediaValues& mediaValues)
{
    if (value.isValid())
        return compareAspectRatioValue(value, mediaValues.viewportWidth(), mediaValues.viewportHeight(), op);

    // ({,min-,max-}aspect-ratio)
    // assume if we have a device, its aspect ratio is non-zero.
    return true;
}

static bool deviceAspectRatioMediaFeatureEval(const MediaQueryExpValue& value, MediaFeaturePrefix op, const MediaValues& mediaValues)
{
    if (value.isValid())
        return compareAspectRatioValue(value, mediaValues.deviceWidth(), mediaValues.deviceHeight(), op);

    // ({,min-,max-}device-aspect-ratio)
    // assume if we have a device, its aspect ratio is non-zero.
    return true;
}

static bool evalResolution(const MediaQueryExpValue& value, MediaFeaturePrefix op, const MediaValues& mediaValues)
{
    // According to MQ4, only 'screen', 'print' and 'speech' may match.
    // FIXME: What should speech match? https://www.w3.org/Style/CSS/Tracker/issues/348
    float actualResolution = 0;

    // This checks the actual media type applied to the document, and we know
    // this method only got called if this media type matches the one defined
    // in the query. Thus, if if the document's media type is "print", the
    // media type of the query will either be "print" or "all".
    if (equalIgnoringCase(mediaValues.mediaType(), MediaTypeNames::screen)) {
        actualResolution = clampTo<float>(mediaValues.devicePixelRatio());
    } else if (equalIgnoringCase(mediaValues.mediaType(), MediaTypeNames::print)) {
        // The resolution of images while printing should not depend on the DPI
        // of the screen. Until we support proper ways of querying this info
        // we use 300px which is considered minimum for current printers.
        actualResolution = 300 / cssPixelsPerInch;
    }

    if (!value.isValid())
        return !!actualResolution;

    if (!value.isValue)
        return false;

    if (value.unit == CSSPrimitiveValue::CSS_NUMBER)
        return compareValue(actualResolution, clampTo<float>(value.value), op);

    if (!CSSPrimitiveValue::isResolution(value.unit))
        return false;

    double canonicalFactor = CSSPrimitiveValue::conversionToCanonicalUnitsScaleFactor(value.unit);
    double dppxFactor = CSSPrimitiveValue::conversionToCanonicalUnitsScaleFactor(CSSPrimitiveValue::CSS_DPPX);
    float valueInDppx = clampTo<float>(value.value * (canonicalFactor / dppxFactor));
    if (CSSPrimitiveValue::isDotsPerCentimeter(value.unit)) {
        // To match DPCM to DPPX values, we limit to 2 decimal points.
        // The http://dev.w3.org/csswg/css3-values/#absolute-lengths recommends
        // "that the pixel unit refer to the whole number of device pixels that best
        // approximates the reference pixel". With that in mind, allowing 2 decimal
        // point precision seems appropriate.
        return compareValue(
            floorf(0.5 + 100 * actualResolution) / 100,
            floorf(0.5 + 100 * valueInDppx) / 100, op);
    }

    return compareValue(actualResolution, valueInDppx, op);
}

static bool devicePixelRatioMediaFeatureEval(const MediaQueryExpValue& value, MediaFeaturePrefix op, const MediaValues& mediaValues)
{
    UseCounter::count(mediaValues.document(), UseCounter::PrefixedDevicePixelRatioMediaFeature);

    return (!value.isValid() || value.unit == CSSPrimitiveValue::CSS_NUMBER) && evalResolution(value, op, mediaValues);
}

static bool resolutionMediaFeatureEval(const MediaQueryExpValue& value, MediaFeaturePrefix op, const MediaValues& MediaValues)
{
    return (!value.isValid() || CSSPrimitiveValue::isResolution(value.unit)) && evalResolution(value, op, MediaValues);
}

static bool gridMediaFeatureEval(const MediaQueryExpValue& value, MediaFeaturePrefix op, const MediaValues&)
{
    // if output device is bitmap, grid: 0 == true
    // assume we have bitmap device
    float number;
    if (value.isValid() && numberValue(value, number))
        return compareValue(static_cast<int>(number), 0, op);
    return false;
}

static bool computeLength(const MediaQueryExpValue& value, const MediaValues& mediaValues, int& result)
{
    if (!value.isValue)
        return false;

    if (value.unit == CSSPrimitiveValue::CSS_NUMBER) {
        result = clampTo<int>(value.value);
        return !mediaValues.strictMode() || !result;
    }

    if (CSSPrimitiveValue::isLength(value.unit))
        return mediaValues.computeLength(value.value, value.unit, result);
    return false;
}

static bool deviceHeightMediaFeatureEval(const MediaQueryExpValue& value, MediaFeaturePrefix op, const MediaValues& mediaValues)
{
    if (value.isValid()) {
        int length;
        return computeLength(value, mediaValues, length) && compareValue(static_cast<int>(mediaValues.deviceHeight()), length, op);
    }
    // ({,min-,max-}device-height)
    // assume if we have a device, assume non-zero
    return true;
}

static bool deviceWidthMediaFeatureEval(const MediaQueryExpValue& value, MediaFeaturePrefix op, const MediaValues& mediaValues)
{
    if (value.isValid()) {
        int length;
        return computeLength(value, mediaValues, length) && compareValue(static_cast<int>(mediaValues.deviceWidth()), length, op);
    }
    // ({,min-,max-}device-width)
    // assume if we have a device, assume non-zero
    return true;
}

static bool heightMediaFeatureEval(const MediaQueryExpValue& value, MediaFeaturePrefix op, const MediaValues& mediaValues)
{
    int height = mediaValues.viewportHeight();
    if (value.isValid()) {
        int length;
        return computeLength(value, mediaValues, length) && compareValue(height, length, op);
    }

    return height;
}

static bool widthMediaFeatureEval(const MediaQueryExpValue& value, MediaFeaturePrefix op, const MediaValues& mediaValues)
{
    int width = mediaValues.viewportWidth();
    if (value.isValid()) {
        int length;
        return computeLength(value, mediaValues, length) && compareValue(width, length, op);
    }

    return width;
}

// Rest of the functions are trampolines which set the prefix according to the media feature expression used.

static bool minColorMediaFeatureEval(const MediaQueryExpValue& value, MediaFeaturePrefix, const MediaValues& mediaValues)
{
    return colorMediaFeatureEval(value, MinPrefix, mediaValues);
}

static bool maxColorMediaFeatureEval(const MediaQueryExpValue& value, MediaFeaturePrefix, const MediaValues& mediaValues)
{
    return colorMediaFeatureEval(value, MaxPrefix, mediaValues);
}

static bool minColorIndexMediaFeatureEval(const MediaQueryExpValue& value, MediaFeaturePrefix, const MediaValues& mediaValues)
{
    return colorIndexMediaFeatureEval(value, MinPrefix, mediaValues);
}

static bool maxColorIndexMediaFeatureEval(const MediaQueryExpValue& value, MediaFeaturePrefix, const MediaValues& mediaValues)
{
    return colorIndexMediaFeatureEval(value, MaxPrefix, mediaValues);
}

static bool minMonochromeMediaFeatureEval(const MediaQueryExpValue& value, MediaFeaturePrefix, const MediaValues& mediaValues)
{
    return monochromeMediaFeatureEval(value, MinPrefix, mediaValues);
}

static bool maxMonochromeMediaFeatureEval(const MediaQueryExpValue& value, MediaFeaturePrefix, const MediaValues& mediaValues)
{
    return monochromeMediaFeatureEval(value, MaxPrefix, mediaValues);
}

static bool minAspectRatioMediaFeatureEval(const MediaQueryExpValue& value, MediaFeaturePrefix, const MediaValues& mediaValues)
{
    return aspectRatioMediaFeatureEval(value, MinPrefix, mediaValues);
}

static bool maxAspectRatioMediaFeatureEval(const MediaQueryExpValue& value, MediaFeaturePrefix, const MediaValues& mediaValues)
{
    return aspectRatioMediaFeatureEval(value, MaxPrefix, mediaValues);
}

static bool minDeviceAspectRatioMediaFeatureEval(const MediaQueryExpValue& value, MediaFeaturePrefix, const MediaValues& mediaValues)
{
    return deviceAspectRatioMediaFeatureEval(value, MinPrefix, mediaValues);
}

static bool maxDeviceAspectRatioMediaFeatureEval(const MediaQueryExpValue& value, MediaFeaturePrefix, const MediaValues& mediaValues)
{
    return deviceAspectRatioMediaFeatureEval(value, MaxPrefix, mediaValues);
}

static bool minDevicePixelRatioMediaFeatureEval(const MediaQueryExpValue& value, MediaFeaturePrefix, const MediaValues& mediaValues)
{
    UseCounter::count(mediaValues.document(), UseCounter::PrefixedMinDevicePixelRatioMediaFeature);

    return devicePixelRatioMediaFeatureEval(value, MinPrefix, mediaValues);
}

static bool maxDevicePixelRatioMediaFeatureEval(const MediaQueryExpValue& value, MediaFeaturePrefix, const MediaValues& mediaValues)
{
    UseCounter::count(mediaValues.document(), UseCounter::PrefixedMaxDevicePixelRatioMediaFeature);

    return devicePixelRatioMediaFeatureEval(value, MaxPrefix, mediaValues);
}

static bool minHeightMediaFeatureEval(const MediaQueryExpValue& value, MediaFeaturePrefix, const MediaValues& mediaValues)
{
    return heightMediaFeatureEval(value, MinPrefix, mediaValues);
}

static bool maxHeightMediaFeatureEval(const MediaQueryExpValue& value, MediaFeaturePrefix, const MediaValues& mediaValues)
{
    return heightMediaFeatureEval(value, MaxPrefix, mediaValues);
}

static bool minWidthMediaFeatureEval(const MediaQueryExpValue& value, MediaFeaturePrefix, const MediaValues& mediaValues)
{
    return widthMediaFeatureEval(value, MinPrefix, mediaValues);
}

static bool maxWidthMediaFeatureEval(const MediaQueryExpValue& value, MediaFeaturePrefix, const MediaValues& mediaValues)
{
    return widthMediaFeatureEval(value, MaxPrefix, mediaValues);
}

static bool minDeviceHeightMediaFeatureEval(const MediaQueryExpValue& value, MediaFeaturePrefix, const MediaValues& mediaValues)
{
    return deviceHeightMediaFeatureEval(value, MinPrefix, mediaValues);
}

static bool maxDeviceHeightMediaFeatureEval(const MediaQueryExpValue& value, MediaFeaturePrefix, const MediaValues& mediaValues)
{
    return deviceHeightMediaFeatureEval(value, MaxPrefix, mediaValues);
}

static bool minDeviceWidthMediaFeatureEval(const MediaQueryExpValue& value, MediaFeaturePrefix, const MediaValues& mediaValues)
{
    return deviceWidthMediaFeatureEval(value, MinPrefix, mediaValues);
}

static bool maxDeviceWidthMediaFeatureEval(const MediaQueryExpValue& value, MediaFeaturePrefix, const MediaValues& mediaValues)
{
    return deviceWidthMediaFeatureEval(value, MaxPrefix, mediaValues);
}

static bool minResolutionMediaFeatureEval(const MediaQueryExpValue& value, MediaFeaturePrefix, const MediaValues& mediaValues)
{
    return resolutionMediaFeatureEval(value, MinPrefix, mediaValues);
}

static bool maxResolutionMediaFeatureEval(const MediaQueryExpValue& value, MediaFeaturePrefix, const MediaValues& mediaValues)
{
    return resolutionMediaFeatureEval(value, MaxPrefix, mediaValues);
}

static bool transform3dMediaFeatureEval(const MediaQueryExpValue& value, MediaFeaturePrefix op, const MediaValues& mediaValues)
{
    UseCounter::count(mediaValues.document(), UseCounter::PrefixedTransform3dMediaFeature);

    bool returnValueIfNoParameter;
    int have3dRendering;

    bool threeDEnabled = mediaValues.threeDEnabled();

    returnValueIfNoParameter = threeDEnabled;
    have3dRendering = threeDEnabled ? 1 : 0;

    if (value.isValid()) {
        float number;
        return numberValue(value, number) && compareValue(have3dRendering, static_cast<int>(number), op);
    }
    return returnValueIfNoParameter;
}

static bool hoverMediaFeatureEval(const MediaQueryExpValue& value, MediaFeaturePrefix, const MediaValues& mediaValues)
{
    HoverType hover = mediaValues.primaryHoverType();

    if (RuntimeEnabledFeatures::hoverMediaQueryKeywordsEnabled()) {
        if (!value.isValid())
            return hover != HoverTypeNone;

        if (!value.isID)
            return false;

        return (hover == HoverTypeNone && value.id == CSSValueNone)
            || (hover == HoverTypeOnDemand && value.id == CSSValueOnDemand)
            || (hover == HoverTypeHover && value.id == CSSValueHover);
    } else {
        float number = 1;
        if (value.isValid()) {
            if (!numberValue(value, number))
                return false;
        }

        return (hover == HoverTypeNone && !number)
            || (hover == HoverTypeOnDemand && !number)
            || (hover == HoverTypeHover && number == 1);
    }
}

static bool anyHoverMediaFeatureEval(const MediaQueryExpValue& value, MediaFeaturePrefix, const MediaValues& mediaValues)
{
    if (!RuntimeEnabledFeatures::anyPointerMediaQueriesEnabled())
        return false;

    int availableHoverTypes = mediaValues.availableHoverTypes();

    if (!value.isValid())
        return availableHoverTypes & ~HoverTypeNone;

    if (!value.isID)
        return false;

    switch (value.id) {
    case CSSValueNone:
        return availableHoverTypes & HoverTypeNone;
    case CSSValueOnDemand:
        return availableHoverTypes & HoverTypeOnDemand;
    case CSSValueHover:
        return availableHoverTypes & HoverTypeHover;
    default:
        ASSERT_NOT_REACHED();
        return false;
    }
}

static bool pointerMediaFeatureEval(const MediaQueryExpValue& value, MediaFeaturePrefix, const MediaValues& mediaValues)
{
    PointerType pointer = mediaValues.primaryPointerType();

    if (!value.isValid())
        return pointer != PointerTypeNone;

    if (!value.isID)
        return false;

    return (pointer == PointerTypeNone && value.id == CSSValueNone)
        || (pointer == PointerTypeCoarse && value.id == CSSValueCoarse)
        || (pointer == PointerTypeFine && value.id == CSSValueFine);
}

static bool anyPointerMediaFeatureEval(const MediaQueryExpValue& value, MediaFeaturePrefix, const MediaValues& mediaValues)
{
    if (!RuntimeEnabledFeatures::anyPointerMediaQueriesEnabled())
        return false;

    int availablePointers = mediaValues.availablePointerTypes();

    if (!value.isValid())
        return availablePointers & ~PointerTypeNone;

    if (!value.isID)
        return false;

    switch (value.id) {
    case CSSValueCoarse:
        return availablePointers & PointerTypeCoarse;
    case CSSValueFine:
        return availablePointers & PointerTypeFine;
    case CSSValueNone:
        return availablePointers & PointerTypeNone;
    default:
        ASSERT_NOT_REACHED();
        return false;
    }
}

static bool scanMediaFeatureEval(const MediaQueryExpValue& value, MediaFeaturePrefix, const MediaValues& mediaValues)
{
    // Scan only applies to 'tv' media.
    if (!equalIgnoringCase(mediaValues.mediaType(), MediaTypeNames::tv))
        return false;

    if (!value.isValid())
        return true;

    if (!value.isID)
        return false;

    // If a platform interface supplies progressive/interlace info for TVs in the
    // future, it needs to be handled here. For now, assume a modern TV with
    // progressive display.
    return (value.id == CSSValueProgressive);
}

static void createFunctionMap()
{
    // Create the table.
    gFunctionMap = new FunctionMap;
#define ADD_TO_FUNCTIONMAP(name)  \
    gFunctionMap->set(name##MediaFeature.impl(), name##MediaFeatureEval);
    CSS_MEDIAQUERY_NAMES_FOR_EACH_MEDIAFEATURE(ADD_TO_FUNCTIONMAP);
#undef ADD_TO_FUNCTIONMAP
}

bool MediaQueryEvaluator::eval(const MediaQueryExp* expr) const
{
    if (!m_mediaValues || !m_mediaValues->hasValues())
        return m_expectedResult;

    if (!gFunctionMap)
        createFunctionMap();

    // Call the media feature evaluation function. Assume no prefix and let
    // trampoline functions override the prefix if prefix is used.
    EvalFunc func = gFunctionMap->get(expr->mediaFeature().impl());
    if (func)
        return func(expr->expValue(), NoPrefix, *m_mediaValues);

    return false;
}

} // namespace
