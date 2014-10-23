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

#include "config.h"
#include "core/css/resolver/StyleResourceLoader.h"

#include "core/CSSPropertyNames.h"
#include "core/css/CSSCursorImageValue.h"
#include "core/css/CSSImageValue.h"
#include "core/css/resolver/ElementStyleResources.h"
#include "core/fetch/ResourceFetcher.h"
#include "core/rendering/style/ContentData.h"
#include "core/rendering/style/FillLayer.h"
#include "core/rendering/style/RenderStyle.h"
#include "core/rendering/style/StyleFetchedImage.h"
#include "core/rendering/style/StyleFetchedImageSet.h"
#include "core/rendering/style/StyleGeneratedImage.h"
#include "core/rendering/style/StylePendingImage.h"

namespace blink {

StyleResourceLoader::StyleResourceLoader(ResourceFetcher* fetcher)
    : m_fetcher(fetcher)
{
}

static PassRefPtr<StyleImage> doLoadPendingImage(ResourceFetcher* fetcher, StylePendingImage* pendingImage, float deviceScaleFactor, const ResourceLoaderOptions& options)
{
    if (CSSImageValue* imageValue = pendingImage->cssImageValue())
        return imageValue->cachedImage(fetcher, options);

    if (CSSImageGeneratorValue* imageGeneratorValue
        = pendingImage->cssImageGeneratorValue()) {
        imageGeneratorValue->loadSubimages(fetcher);
        return StyleGeneratedImage::create(imageGeneratorValue);
    }

    if (CSSCursorImageValue* cursorImageValue
        = pendingImage->cssCursorImageValue())
        return cursorImageValue->cachedImage(fetcher, deviceScaleFactor);

    if (CSSImageSetValue* imageSetValue = pendingImage->cssImageSetValue())
        return imageSetValue->cachedImageSet(fetcher, deviceScaleFactor, options);

    return nullptr;
}

PassRefPtr<StyleImage> StyleResourceLoader::loadPendingImage(StylePendingImage* pendingImage, float deviceScaleFactor)
{
    return doLoadPendingImage(m_fetcher, pendingImage, deviceScaleFactor, ResourceFetcher::defaultResourceOptions());
}

void StyleResourceLoader::loadPendingShapeImage(RenderStyle* renderStyle, ShapeValue* shapeValue, float deviceScaleFactor)
{
    if (!shapeValue)
        return;

    StyleImage* image = shapeValue->image();
    if (!image || !image->isPendingImage())
        return;

    ResourceLoaderOptions options = ResourceFetcher::defaultResourceOptions();
    options.allowCredentials = DoNotAllowStoredCredentials;
    options.credentialsRequested  = ClientDidNotRequestCredentials;
    options.corsEnabled = IsCORSEnabled;

    shapeValue->setImage(doLoadPendingImage(m_fetcher, toStylePendingImage(image), deviceScaleFactor, options));
}

void StyleResourceLoader::loadPendingImages(RenderStyle* style, ElementStyleResources& elementStyleResources)
{
    if (elementStyleResources.pendingImageProperties().isEmpty())
        return;

    PendingImagePropertyMap::const_iterator::Keys end = elementStyleResources.pendingImageProperties().end().keys();
    for (PendingImagePropertyMap::const_iterator::Keys it = elementStyleResources.pendingImageProperties().begin().keys(); it != end; ++it) {
        CSSPropertyID currentProperty = *it;

        switch (currentProperty) {
        case CSSPropertyBackgroundImage: {
            for (FillLayer* backgroundLayer = &style->accessBackgroundLayers(); backgroundLayer; backgroundLayer = backgroundLayer->next()) {
                if (backgroundLayer->image() && backgroundLayer->image()->isPendingImage())
                    backgroundLayer->setImage(loadPendingImage(toStylePendingImage(backgroundLayer->image()), elementStyleResources.deviceScaleFactor()));
            }
            break;
        }
        case CSSPropertyContent: {
            for (ContentData* contentData = const_cast<ContentData*>(style->contentData()); contentData; contentData = contentData->next()) {
                if (contentData->isImage()) {
                    StyleImage* image = toImageContentData(contentData)->image();
                    if (image->isPendingImage()) {
                        RefPtr<StyleImage> loadedImage = loadPendingImage(toStylePendingImage(image), elementStyleResources.deviceScaleFactor());
                        if (loadedImage)
                            toImageContentData(contentData)->setImage(loadedImage.release());
                    }
                }
            }
            break;
        }
        case CSSPropertyCursor: {
            if (CursorList* cursorList = style->cursors()) {
                for (size_t i = 0; i < cursorList->size(); ++i) {
                    CursorData& currentCursor = cursorList->at(i);
                    if (StyleImage* image = currentCursor.image()) {
                        if (image->isPendingImage())
                            currentCursor.setImage(loadPendingImage(toStylePendingImage(image), elementStyleResources.deviceScaleFactor()));
                    }
                }
            }
            break;
        }
        case CSSPropertyListStyleImage: {
            if (style->listStyleImage() && style->listStyleImage()->isPendingImage())
                style->setListStyleImage(loadPendingImage(toStylePendingImage(style->listStyleImage()), elementStyleResources.deviceScaleFactor()));
            break;
        }
        case CSSPropertyBorderImageSource: {
            if (style->borderImageSource() && style->borderImageSource()->isPendingImage())
                style->setBorderImageSource(loadPendingImage(toStylePendingImage(style->borderImageSource()), elementStyleResources.deviceScaleFactor()));
            break;
        }
        case CSSPropertyWebkitMaskBoxImageSource: {
            if (style->maskBoxImageSource() && style->maskBoxImageSource()->isPendingImage())
                style->setMaskBoxImageSource(loadPendingImage(toStylePendingImage(style->maskBoxImageSource()), elementStyleResources.deviceScaleFactor()));
            break;
        }
        case CSSPropertyWebkitMaskImage: {
            for (FillLayer* maskLayer = &style->accessMaskLayers(); maskLayer; maskLayer = maskLayer->next()) {
                if (maskLayer->image() && maskLayer->image()->isPendingImage())
                    maskLayer->setImage(loadPendingImage(toStylePendingImage(maskLayer->image()), elementStyleResources.deviceScaleFactor()));
            }
            break;
        }
        case CSSPropertyShapeOutside:
            loadPendingShapeImage(style, style->shapeOutside(), elementStyleResources.deviceScaleFactor());
            break;
        default:
            ASSERT_NOT_REACHED();
        }
    }

    elementStyleResources.clearPendingImageProperties();
}

void StyleResourceLoader::loadPendingResources(RenderStyle* renderStyle, ElementStyleResources& elementStyleResources)
{
    // Start loading images referenced by this style.
    loadPendingImages(renderStyle, elementStyleResources);
}

}
