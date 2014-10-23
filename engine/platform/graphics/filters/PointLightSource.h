/*
 * Copyright (C) 2008 Alex Mathews <possessedpenguinbob@gmail.com>
 * Copyright (C) 2004, 2005, 2006, 2007 Nikolas Zimmermann <zimmermann@kde.org>
 * Copyright (C) 2004, 2005 Rob Buis <buis@kde.org>
 * Copyright (C) 2005 Eric Seidel <eric@webkit.org>
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

#ifndef PointLightSource_h
#define PointLightSource_h

#include "platform/graphics/filters/LightSource.h"

namespace blink {

class PLATFORM_EXPORT PointLightSource : public LightSource {
public:
    static PassRefPtr<PointLightSource> create(const FloatPoint3D& position)
    {
        return adoptRef(new PointLightSource(position));
    }

    virtual PassRefPtr<LightSource> create(const FloatPoint3D& scale, const FloatSize& offset) const OVERRIDE
    {
        FloatPoint3D position(m_position.x() * scale.x() - offset.width(), m_position.y() * scale.y() - offset.height(), m_position.z() * scale.z());
        return adoptRef(new PointLightSource(position));
    }

    const FloatPoint3D& position() const { return m_position; }
    virtual bool setPosition(const FloatPoint3D&) OVERRIDE;

    virtual void initPaintingData(PaintingData&) const OVERRIDE;
    virtual void updatePaintingData(PaintingData&, int x, int y, float z) const OVERRIDE;

    virtual TextStream& externalRepresentation(TextStream&) const OVERRIDE;

private:
    PointLightSource(const FloatPoint3D& position)
        : LightSource(LS_POINT)
        , m_position(position)
    {
    }

    FloatPoint3D m_position;
};

} // namespace blink

#endif // PointLightSource_h
