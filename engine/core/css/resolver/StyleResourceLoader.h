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

#ifndef StyleResourceLoader_h
#define StyleResourceLoader_h

#include "wtf/OwnPtr.h"
#include "wtf/PassRefPtr.h"

namespace blink {

class ElementStyleResources;
class RenderStyle;
class ResourceFetcher;
class ShapeValue;
class StyleImage;
class StylePendingImage;

// Manages loading of resources, requested by the stylesheets.
// Expects the same lifetime as StyleResolver, because
// it expects ResourceFetcher to never change.
class StyleResourceLoader {
WTF_MAKE_NONCOPYABLE(StyleResourceLoader);
public:
    explicit StyleResourceLoader(ResourceFetcher*);

    void loadPendingResources(RenderStyle*, ElementStyleResources&);

private:
    PassRefPtr<StyleImage> loadPendingImage(StylePendingImage*, float deviceScaleFactor);
    void loadPendingImages(RenderStyle*, ElementStyleResources&);

    ResourceFetcher* m_fetcher;
};

} // namespace blink

#endif // StyleResourceLoader_h
