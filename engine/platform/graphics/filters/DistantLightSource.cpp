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
#include "platform/graphics/filters/DistantLightSource.h"

#include "platform/text/TextStream.h"

namespace blink {

void DistantLightSource::initPaintingData(PaintingData& paintingData) const
{
    float azimuth = deg2rad(m_azimuth);
    float elevation = deg2rad(m_elevation);
    paintingData.lightVector.setX(cosf(azimuth) * cosf(elevation));
    paintingData.lightVector.setY(sinf(azimuth) * cosf(elevation));
    paintingData.lightVector.setZ(sinf(elevation));
    paintingData.lightVectorLength = 1;
}

void DistantLightSource::updatePaintingData(PaintingData&, int, int, float) const
{
}

bool DistantLightSource::setAzimuth(float azimuth)
{
    if (m_azimuth == azimuth)
        return false;
    m_azimuth = azimuth;
    return true;
}

bool DistantLightSource::setElevation(float elevation)
{
    if (m_elevation == elevation)
        return false;
    m_elevation = elevation;
    return true;
}

TextStream& DistantLightSource::externalRepresentation(TextStream& ts) const
{
    ts << "[type=DISTANT-LIGHT] ";
    ts << "[azimuth=\"" << azimuth() << "\"]";
    ts << "[elevation=\"" << elevation() << "\"]";
    return ts;
}

} // namespace blink
