/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2003, 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2011 Apple Inc. All rights reserved.
 * Copyright (C) 2013 Google Inc. All rights reserved.
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

#include "sky/engine/core/css/resolver/ElementStyleResources.h"

#include "sky/engine/core/css/CSSGradientValue.h"
#include "sky/engine/core/rendering/style/StyleGeneratedImage.h"
#include "sky/engine/core/rendering/style/StyleImage.h"
#include "sky/engine/core/rendering/style/StylePendingImage.h"
#include "sky/engine/platform/graphics/filters/FilterOperation.h"

namespace blink {

ElementStyleResources::ElementStyleResources()
    : m_deviceScaleFactor(1)
{
}

PassRefPtr<StyleImage> ElementStyleResources::styleImage(Document& document, const TextLinkColors& textLinkColors, Color currentColor, CSSPropertyID property, CSSValue* value)
{
    if (value->isImageGeneratorValue()) {
        if (value->isGradientValue())
            return generatedOrPendingFromValue(property, toCSSGradientValue(value)->gradientWithStylesResolved(textLinkColors, currentColor).get());
        return generatedOrPendingFromValue(property, toCSSImageGeneratorValue(value));
    }

    return nullptr;
}

PassRefPtr<StyleImage> ElementStyleResources::generatedOrPendingFromValue(CSSPropertyID property, CSSImageGeneratorValue* value)
{
    if (value->isPending()) {
        m_pendingImageProperties.set(property, value);
        return StylePendingImage::create(value);
    }
    return StyleGeneratedImage::create(value);
}

void ElementStyleResources::clearPendingImageProperties()
{
    m_pendingImageProperties.clear();
}

}
