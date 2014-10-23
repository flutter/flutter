/*
 * Copyright (C) 2012 Nokia Corporation and/or its subsidiary(-ies)
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
#include "core/css/CSSBorderImage.h"

namespace blink {

PassRefPtrWillBeRawPtr<CSSValueList> createBorderImageValue(PassRefPtrWillBeRawPtr<CSSValue> image, PassRefPtrWillBeRawPtr<CSSValue> imageSlice,
    PassRefPtrWillBeRawPtr<CSSValue> borderSlice, PassRefPtrWillBeRawPtr<CSSValue> outset, PassRefPtrWillBeRawPtr<CSSValue> repeat)
{
    RefPtrWillBeRawPtr<CSSValueList> list = CSSValueList::createSpaceSeparated();
    if (image)
        list->append(image);

    if (borderSlice || outset) {
        RefPtrWillBeRawPtr<CSSValueList> listSlash = CSSValueList::createSlashSeparated();
        if (imageSlice)
            listSlash->append(imageSlice);

        if (borderSlice)
            listSlash->append(borderSlice);

        if (outset)
            listSlash->append(outset);

        list->append(listSlash);
    } else if (imageSlice)
        list->append(imageSlice);
    if (repeat)
        list->append(repeat);
    return list.release();
}

} // namespace blink
