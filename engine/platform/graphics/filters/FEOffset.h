/*
 * Copyright (C) 2004, 2005, 2006, 2007 Nikolas Zimmermann <zimmermann@kde.org>
 * Copyright (C) 2004, 2005 Rob Buis <buis@kde.org>
 * Copyright (C) 2005 Eric Seidel <eric@webkit.org>
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

#ifndef FEOffset_h
#define FEOffset_h

#include "platform/graphics/filters/Filter.h"
#include "platform/graphics/filters/FilterEffect.h"

namespace blink {

class PLATFORM_EXPORT FEOffset : public FilterEffect {
public:
    static PassRefPtr<FEOffset> create(Filter*, float dx, float dy);

    float dx() const;
    void setDx(float);

    float dy() const;
    void setDy(float);

    virtual FloatRect mapRect(const FloatRect&, bool forward = true) override final;

    virtual TextStream& externalRepresentation(TextStream&, int indention) const override;

    virtual PassRefPtr<SkImageFilter> createImageFilter(SkiaImageFilterBuilder*) override;

private:
    FEOffset(Filter*, float dx, float dy);

    virtual void applySoftware() override;

    float m_dx;
    float m_dy;
};

} // namespace blink

#endif // FEOffset_h
