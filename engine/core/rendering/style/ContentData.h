/*
 * Copyright (C) 2000 Lars Knoll (knoll@kde.org)
 *           (C) 2000 Antti Koivisto (koivisto@kde.org)
 *           (C) 2000 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2003, 2005, 2006, 2007, 2008, 2010 Apple Inc. All rights reserved.
 * Copyright (C) 2006 Graham Dennis (graham.dennis@gmail.com)
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

#ifndef ContentData_h
#define ContentData_h

#include "core/rendering/style/RenderStyleConstants.h"
#include "core/rendering/style/StyleImage.h"
#include "wtf/OwnPtr.h"
#include "wtf/PassOwnPtr.h"

namespace blink {

class Document;
class RenderObject;
class RenderStyle;

class ContentData {
    WTF_MAKE_FAST_ALLOCATED;
public:
    static PassOwnPtr<ContentData> create(PassRefPtr<StyleImage>);
    static PassOwnPtr<ContentData> create(const String&);

    virtual ~ContentData() { }

    virtual bool isImage() const { return false; }
    virtual bool isText() const { return false; }

    virtual RenderObject* createRenderer(Document&, RenderStyle*) const = 0;

    virtual PassOwnPtr<ContentData> clone() const;

    ContentData* next() const { return m_next.get(); }
    void setNext(PassOwnPtr<ContentData> next) { m_next = next; }

    virtual bool equals(const ContentData&) const = 0;

private:
    virtual PassOwnPtr<ContentData> cloneInternal() const = 0;

    OwnPtr<ContentData> m_next;
};

#define DEFINE_CONTENT_DATA_TYPE_CASTS(typeName) \
    DEFINE_TYPE_CASTS(typeName##ContentData, ContentData, content, content->is##typeName(), content.is##typeName())

class ImageContentData final : public ContentData {
    friend class ContentData;
public:
    const StyleImage* image() const { return m_image.get(); }
    StyleImage* image() { return m_image.get(); }
    void setImage(PassRefPtr<StyleImage> image) { m_image = image; }

    virtual bool isImage() const override { return true; }
    virtual RenderObject* createRenderer(Document&, RenderStyle*) const override;

    virtual bool equals(const ContentData& data) const override
    {
        if (!data.isImage())
            return false;
        return *static_cast<const ImageContentData&>(data).image() == *image();
    }

private:
    ImageContentData(PassRefPtr<StyleImage> image)
        : m_image(image)
    {
    }

    virtual PassOwnPtr<ContentData> cloneInternal() const override
    {
        RefPtr<StyleImage> image = const_cast<StyleImage*>(this->image());
        return create(image.release());
    }

    RefPtr<StyleImage> m_image;
};

DEFINE_CONTENT_DATA_TYPE_CASTS(Image);

class TextContentData final : public ContentData {
    friend class ContentData;
public:
    const String& text() const { return m_text; }
    void setText(const String& text) { m_text = text; }

    virtual bool isText() const override { return true; }
    virtual RenderObject* createRenderer(Document&, RenderStyle*) const override;

    virtual bool equals(const ContentData& data) const override
    {
        if (!data.isText())
            return false;
        return static_cast<const TextContentData&>(data).text() == text();
    }

private:
    TextContentData(const String& text)
        : m_text(text)
    {
    }

    virtual PassOwnPtr<ContentData> cloneInternal() const override { return create(text()); }

    String m_text;
};

DEFINE_CONTENT_DATA_TYPE_CASTS(Text);

inline bool operator==(const ContentData& a, const ContentData& b)
{
    return a.equals(b);
}

inline bool operator!=(const ContentData& a, const ContentData& b)
{
    return !(a == b);
}

} // namespace blink

#endif // ContentData_h
