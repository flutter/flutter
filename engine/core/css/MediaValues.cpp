// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "core/css/MediaValues.h"

#include "core/css/CSSHelper.h"
#include "core/css/MediaValuesCached.h"
#include "core/css/MediaValuesDynamic.h"
#include "core/dom/Document.h"
#include "core/dom/Element.h"
#include "core/frame/FrameHost.h"
#include "core/frame/FrameView.h"
#include "core/frame/LocalFrame.h"
#include "core/frame/Settings.h"
#include "core/html/imports/HTMLImportsController.h"
#include "core/page/Page.h"
#include "core/rendering/RenderObject.h"
#include "core/rendering/RenderView.h"
#include "core/rendering/compositing/RenderLayerCompositor.h"
#include "core/rendering/style/RenderStyle.h"
#include "platform/PlatformScreen.h"

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
    int viewportWidth = frame->view()->layoutSize(IncludeScrollbars).width();
    return adjustForAbsoluteZoom(viewportWidth, frame->document()->renderView());
}

int MediaValues::calculateViewportHeight(LocalFrame* frame) const
{
    ASSERT(frame && frame->view() && frame->document());
    int viewportHeight = frame->view()->layoutSize(IncludeScrollbars).height();
    return adjustForAbsoluteZoom(viewportHeight, frame->document()->renderView());
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
    ASSERT(frame && frame->contentRenderer() && frame->contentRenderer()->compositor());
    bool threeDEnabled = false;
    if (RenderView* view = frame->contentRenderer())
        threeDEnabled = view->compositor()->hasAcceleratedCompositing();
    return threeDEnabled;
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
