/*
 * Copyright (C) 1999 Antti Koivisto (koivisto@kde.org)
 * Copyright (C) 2004, 2005, 2006, 2007, 2008, 2009, 2010 Apple Inc. All rights reserved.
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
#include "core/rendering/style/ContentData.h"

#include "core/rendering/RenderImage.h"
#include "core/rendering/RenderImageResource.h"
#include "core/rendering/RenderImageResourceStyleImage.h"
#include "core/rendering/style/RenderStyle.h"

namespace blink {

PassOwnPtr<ContentData> ContentData::create(PassRefPtr<StyleImage> image)
{
    return adoptPtr(new ImageContentData(image));
}

PassOwnPtr<ContentData> ContentData::create(const String& text)
{
    return adoptPtr(new TextContentData(text));
}

PassOwnPtr<ContentData> ContentData::clone() const
{
    OwnPtr<ContentData> result = cloneInternal();

    ContentData* lastNewData = result.get();
    for (const ContentData* contentData = next(); contentData; contentData = contentData->next()) {
        OwnPtr<ContentData> newData = contentData->cloneInternal();
        lastNewData->setNext(newData.release());
        lastNewData = lastNewData->next();
    }

    return result.release();
}

RenderObject* ImageContentData::createRenderer(Document& doc, RenderStyle* pseudoStyle) const
{
    return 0;
}

RenderObject* TextContentData::createRenderer(Document& doc, RenderStyle* pseudoStyle) const
{
    return 0;
}

} // namespace blink
