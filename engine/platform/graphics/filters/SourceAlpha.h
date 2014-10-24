/*
 * Copyright (C) 2009 Dirk Schulze <krit@webkit.org>
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
 */

#ifndef SourceAlpha_h
#define SourceAlpha_h

#include "platform/graphics/filters/Filter.h"
#include "platform/graphics/filters/FilterEffect.h"

namespace blink {

class PLATFORM_EXPORT SourceAlpha : public FilterEffect {
public:
    static PassRefPtr<SourceAlpha> create(Filter*);

    static const AtomicString& effectName();

    virtual FloatRect determineAbsolutePaintRect(const FloatRect& requestedRect) override;

    virtual FilterEffectType filterEffectType() const override { return FilterEffectTypeSourceInput; }

    virtual TextStream& externalRepresentation(TextStream&, int indention) const override;
    virtual PassRefPtr<SkImageFilter> createImageFilter(SkiaImageFilterBuilder*) override;

private:
    SourceAlpha(Filter* filter)
        : FilterEffect(filter)
    {
    }

    virtual void applySoftware() override;
};

} // namespace blink

#endif // SourceAlpha_h
