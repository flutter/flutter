/*
 * Copyright (C) 2004, 2005, 2006, 2007 Nikolas Zimmermann <zimmermann@kde.org>
 * Copyright (C) 2004, 2005 Rob Buis <buis@kde.org>
 * Copyright (C) 2005 Eric Seidel <eric@webkit.org>
 * Copyright (C) 2010 Zoltan Herczeg <zherczeg@webkit.org>
 * Copyright (C) 2011 University of Szeged
 * Copyright (C) 2011 Renata Hodovan <reni@webkit.org>
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY UNIVERSITY OF SZEGED ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL UNIVERSITY OF SZEGED OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "platform/graphics/filters/PointLightSource.h"

#include "platform/text/TextStream.h"

namespace blink {

void PointLightSource::initPaintingData(PaintingData&) const
{
}

void PointLightSource::updatePaintingData(PaintingData& paintingData, int x, int y, float z) const
{
    paintingData.lightVector.setX(m_position.x() - x);
    paintingData.lightVector.setY(m_position.y() - y);
    paintingData.lightVector.setZ(m_position.z() - z);
    paintingData.lightVectorLength = paintingData.lightVector.length();
}

bool PointLightSource::setPosition(const FloatPoint3D& position)
{
    if (m_position == position)
        return false;
    m_position = position;
    return true;
}

static TextStream& operator<<(TextStream& ts, const FloatPoint3D& p)
{
    ts << "x=" << p.x() << " y=" << p.y() << " z=" << p.z();
    return ts;
}

TextStream& PointLightSource::externalRepresentation(TextStream& ts) const
{
    ts << "[type=POINT-LIGHT] ";
    ts << "[position=\"" << position() << "\"]";
    return ts;
}

}; // namespace blink
