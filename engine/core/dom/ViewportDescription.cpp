/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2001 Dirk Mueller (mueller@kde.org)
 *           (C) 2006 Alexey Proskuryakov (ap@webkit.org)
 * Copyright (C) 2004, 2005, 2006, 2007, 2008, 2011 Apple Inc. All rights reserved.
 * Copyright (C) 2008 Torch Mobile Inc. All rights reserved. (http://www.torchmobile.com/)
 * Copyright (C) 2010 Nokia Corporation and/or its subsidiary(-ies)
 * Copyright (C) 2012-2013 Intel Corporation. All rights reserved.
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
 *
 */

#include "config.h"
#include "core/dom/ViewportDescription.h"

#include "core/dom/Document.h"
#include "core/frame/FrameHost.h"
#include "core/frame/FrameView.h"
#include "core/frame/LocalFrame.h"
#include "core/frame/Settings.h"
#include "platform/weborigin/KURL.h"
#include "public/platform/Platform.h"

namespace blink {

float ViewportDescription::resolveViewportLength(const Length& length, const FloatSize& initialViewportSize, Direction direction)
{
    if (length.isAuto())
        return ViewportDescription::ValueAuto;

    if (length.isFixed())
        return length.getFloatValue();

    if (length.type() == ExtendToZoom)
        return ViewportDescription::ValueExtendToZoom;

    if (length.type() == Percent && direction == Horizontal)
        return initialViewportSize.width() * length.getFloatValue() / 100.0f;

    if (length.type() == Percent && direction == Vertical)
        return initialViewportSize.height() * length.getFloatValue() / 100.0f;

    if (length.type() == DeviceWidth)
        return initialViewportSize.width();

    if (length.type() == DeviceHeight)
        return initialViewportSize.height();

    ASSERT_NOT_REACHED();
    return ViewportDescription::ValueAuto;
}

void ViewportDescription::reportMobilePageStats(const LocalFrame* mainFrame) const
{
#if OS(ANDROID)
    enum ViewportUMAType {
        NoViewportTag,
        DeviceWidth,
        ConstantWidth,
        MetaWidthOther,
        MetaHandheldFriendly,
        MetaMobileOptimized,
        XhtmlMobileProfile,
        TypeCount
    };

    if (!mainFrame || !mainFrame->host() || !mainFrame->view() || !mainFrame->document())
        return;

    // Avoid chrome:// pages like the new-tab page (on Android new tab is non-http).
    if (!mainFrame->document()->url().protocolIsInHTTPFamily())
        return;

    if (!isSpecifiedByAuthor()) {
        Platform::current()->histogramEnumeration("Viewport.MetaTagType", NoViewportTag, TypeCount);
        return;
    }

    if (isMetaViewportType()) {
        if (maxWidth.type() == blink::Fixed) {
            Platform::current()->histogramEnumeration("Viewport.MetaTagType", ConstantWidth, TypeCount);

            if (mainFrame->view()) {
                // To get an idea of how "far" the viewport is from the device's ideal width, we
                // report the zoom level that we'd need to be at for the entire page to be visible.
                int viewportWidth = maxWidth.intValue();
                int windowWidth = mainFrame->view()->frameRect().width();
                int overviewZoomPercent = 100 * windowWidth / static_cast<float>(viewportWidth);
                Platform::current()->histogramSparse("Viewport.OverviewZoom", overviewZoomPercent);
            }

        } else if (maxWidth.type() == blink::DeviceWidth || maxWidth.type() == blink::ExtendToZoom) {
            Platform::current()->histogramEnumeration("Viewport.MetaTagType", DeviceWidth, TypeCount);
        } else {
            // Overflow bucket for cases we may be unaware of.
            Platform::current()->histogramEnumeration("Viewport.MetaTagType", MetaWidthOther, TypeCount);
        }
    } else if (type == ViewportDescription::HandheldFriendlyMeta) {
        Platform::current()->histogramEnumeration("Viewport.MetaTagType", MetaHandheldFriendly, TypeCount);
    } else if (type == ViewportDescription::MobileOptimizedMeta) {
        Platform::current()->histogramEnumeration("Viewport.MetaTagType", MobileOptimizedMeta, TypeCount);
    }
#endif
}

} // namespace blink
