// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/core/css/MediaValues.h"

#include "sky/engine/core/css/CSSHelper.h"
#include "sky/engine/core/css/MediaValuesCached.h"
#include "sky/engine/core/css/MediaValuesDynamic.h"
#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/dom/Element.h"
#include "sky/engine/core/frame/FrameHost.h"
#include "sky/engine/core/frame/FrameView.h"
#include "sky/engine/core/frame/LocalFrame.h"
#include "sky/engine/core/frame/Settings.h"
#include "sky/engine/core/html/imports/HTMLImportsController.h"
#include "sky/engine/core/page/Page.h"
#include "sky/engine/core/rendering/RenderObject.h"
#include "sky/engine/core/rendering/RenderView.h"
#include "sky/engine/core/rendering/style/RenderStyle.h"
#include "sky/engine/platform/PlatformScreen.h"

namespace blink {

PassRefPtr<MediaValues> MediaValues::createDynamicIfFrameExists(LocalFrame* frame)
{
    if (frame)
        return MediaValuesDynamic::create(frame);
    return MediaValuesCached::create();
}

int MediaValues::calculateViewportWidth(LocalFrame* frame) const
{
    ASSERT(frame && frame->view() && frame->document());
    return frame->view()->layoutSize(IncludeScrollbars).width();
}

int MediaValues::calculateViewportHeight(LocalFrame* frame) const
{
    ASSERT(frame && frame->view() && frame->document());
    return frame->view()->layoutSize(IncludeScrollbars).height();
}

int MediaValues::calculateDeviceWidth(LocalFrame* frame) const
{
    ASSERT(frame && frame->view() && frame->settings() && frame->host());
    int deviceWidth = static_cast<int>(screenRect(frame->view()).width());
    return deviceWidth;
}

int MediaValues::calculateDeviceHeight(LocalFrame* frame) const
{
    ASSERT(frame && frame->view() && frame->settings() && frame->host());
    int deviceHeight = static_cast<int>(screenRect(frame->view()).height());
    return deviceHeight;
}

bool MediaValues::calculateStrictMode(LocalFrame* frame) const
{
    ASSERT(frame && frame->document());
    return true;
}

float MediaValues::calculateDevicePixelRatio(LocalFrame* frame) const
{
    return frame->devicePixelRatio();
}

int MediaValues::calculateColorBitsPerComponent(LocalFrame* frame) const
{
    ASSERT(frame);
    if (screenIsMonochrome(frame->view()))
        return 0;
    return screenDepthPerComponent(frame->view());
}

int MediaValues::calculateMonochromeBitsPerComponent(LocalFrame* frame) const
{
    ASSERT(frame);
    if (!screenIsMonochrome(frame->view()))
        return 0;
    return screenDepthPerComponent(frame->view());
}

int MediaValues::calculateDefaultFontSize(LocalFrame* frame) const
{
    return frame->host()->settings().defaultFontSize();
}

const String MediaValues::calculateMediaType(LocalFrame* frame) const
{
    ASSERT(frame);
    if (!frame->view())
        return emptyAtom;
    return frame->view()->mediaType();
}

bool MediaValues::calculateThreeDEnabled(LocalFrame* frame) const
{
    // FIXME(sky): Remove
    return false;
}

PointerType MediaValues::calculatePrimaryPointerType(LocalFrame* frame) const
{
    ASSERT(frame && frame->settings());
    return frame->settings()->primaryPointerType();
}

int MediaValues::calculateAvailablePointerTypes(LocalFrame* frame) const
{
    ASSERT(frame && frame->settings());
    return frame->settings()->availablePointerTypes();
}

HoverType MediaValues::calculatePrimaryHoverType(LocalFrame* frame) const
{
    ASSERT(frame && frame->settings());
    return frame->settings()->primaryHoverType();
}

int MediaValues::calculateAvailableHoverTypes(LocalFrame* frame) const
{
    ASSERT(frame && frame->settings());
    return frame->settings()->availableHoverTypes();
}

bool MediaValues::computeLengthImpl(double value, CSSPrimitiveValue::UnitType type, unsigned defaultFontSize, unsigned viewportWidth, unsigned viewportHeight, double& result)
{
    // The logic in this function is duplicated from CSSPrimitiveValue::computeLengthDouble
    // because MediaValues::computeLength needs nearly identical logic, but we haven't found a way to make
    // CSSPrimitiveValue::computeLengthDouble more generic (to solve both cases) without hurting performance.

    // FIXME - Unite the logic here with CSSPrimitiveValue in a performant way.
    double factor = 0;
    switch (type) {
    case CSSPrimitiveValue::CSS_EMS:
    case CSSPrimitiveValue::CSS_REMS:
        factor = defaultFontSize;
        break;
    case CSSPrimitiveValue::CSS_PX:
        factor = 1;
        break;
    case CSSPrimitiveValue::CSS_EXS:
        // FIXME: We have a bug right now where the zoom will be applied twice to EX units.
        // FIXME: We don't seem to be able to cache fontMetrics related values.
        // Trying to access them is triggering some sort of microtask. Serving the spec's default instead.
        factor = defaultFontSize / 2.0;
        break;
    case CSSPrimitiveValue::CSS_CHS:
        // FIXME: We don't seem to be able to cache fontMetrics related values.
        // Trying to access them is triggering some sort of microtask. Serving the (future) spec default instead.
        factor = defaultFontSize / 2.0;
        break;
    case CSSPrimitiveValue::CSS_VW:
        factor = viewportWidth / 100.0;
        break;
    case CSSPrimitiveValue::CSS_VH:
        factor = viewportHeight / 100.0;
        break;
    case CSSPrimitiveValue::CSS_VMIN:
        factor = std::min(viewportWidth, viewportHeight) / 100.0;
        break;
    case CSSPrimitiveValue::CSS_VMAX:
        factor = std::max(viewportWidth, viewportHeight) / 100.0;
        break;
    case CSSPrimitiveValue::CSS_CM:
        factor = cssPixelsPerCentimeter;
        break;
    case CSSPrimitiveValue::CSS_MM:
        factor = cssPixelsPerMillimeter;
        break;
    case CSSPrimitiveValue::CSS_IN:
        factor = cssPixelsPerInch;
        break;
    case CSSPrimitiveValue::CSS_PT:
        factor = cssPixelsPerPoint;
        break;
    case CSSPrimitiveValue::CSS_PC:
        factor = cssPixelsPerPica;
        break;
    default:
        return false;
    }

    ASSERT(factor > 0);
    result = value * factor;
    return true;
}

LocalFrame* MediaValues::frameFrom(Document& document)
{
    Document* executingDocument = document.importsController() ? document.importsController()->master() : &document;
    ASSERT(executingDocument);
    return executingDocument->frame();
}

} // namespace
