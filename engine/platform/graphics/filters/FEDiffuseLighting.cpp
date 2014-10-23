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

#include "config.h"
#include "platform/graphics/filters/FEDiffuseLighting.h"

#include "platform/graphics/filters/LightSource.h"
#include "platform/text/TextStream.h"

namespace blink {

FEDiffuseLighting::FEDiffuseLighting(Filter* filter, const Color& lightingColor, float surfaceScale,
    float diffuseConstant, float kernelUnitLengthX, float kernelUnitLengthY, PassRefPtr<LightSource> lightSource)
    : FELighting(filter, DiffuseLighting, lightingColor, surfaceScale, diffuseConstant, 0, 0, kernelUnitLengthX, kernelUnitLengthY, lightSource)
{
}

PassRefPtr<FEDiffuseLighting> FEDiffuseLighting::create(Filter* filter, const Color& lightingColor,
    float surfaceScale, float diffuseConstant, float kernelUnitLengthX,
    float kernelUnitLengthY, PassRefPtr<LightSource> lightSource)
{
    return adoptRef(new FEDiffuseLighting(filter, lightingColor, surfaceScale, diffuseConstant, kernelUnitLengthX, kernelUnitLengthY, lightSource));
}

FEDiffuseLighting::~FEDiffuseLighting()
{
}

Color FEDiffuseLighting::lightingColor() const
{
    return m_lightingColor;
}

bool FEDiffuseLighting::setLightingColor(const Color& lightingColor)
{
    if (m_lightingColor == lightingColor)
        return false;
    m_lightingColor = lightingColor;
    return true;
}

float FEDiffuseLighting::surfaceScale() const
{
    return m_surfaceScale;
}

bool FEDiffuseLighting::setSurfaceScale(float surfaceScale)
{
    if (m_surfaceScale == surfaceScale)
        return false;
    m_surfaceScale = surfaceScale;
    return true;
}

float FEDiffuseLighting::diffuseConstant() const
{
    return m_diffuseConstant;
}

bool FEDiffuseLighting::setDiffuseConstant(float diffuseConstant)
{
    diffuseConstant = std::max(diffuseConstant, 0.0f);
    if (m_diffuseConstant == diffuseConstant)
        return false;
    m_diffuseConstant = diffuseConstant;
    return true;
}

float FEDiffuseLighting::kernelUnitLengthX() const
{
    return m_kernelUnitLengthX;
}

bool FEDiffuseLighting::setKernelUnitLengthX(float kernelUnitLengthX)
{
    if (m_kernelUnitLengthX == kernelUnitLengthX)
        return false;
    m_kernelUnitLengthX = kernelUnitLengthX;
    return true;
}

float FEDiffuseLighting::kernelUnitLengthY() const
{
    return m_kernelUnitLengthY;
}

bool FEDiffuseLighting::setKernelUnitLengthY(float kernelUnitLengthY)
{
    if (m_kernelUnitLengthY == kernelUnitLengthY)
        return false;
    m_kernelUnitLengthY = kernelUnitLengthY;
    return true;
}

const LightSource* FEDiffuseLighting::lightSource() const
{
    return m_lightSource.get();
}

void FEDiffuseLighting::setLightSource(PassRefPtr<LightSource> lightSource)
{
    m_lightSource = lightSource;
}

TextStream& FEDiffuseLighting::externalRepresentation(TextStream& ts, int indent) const
{
    writeIndent(ts, indent);
    ts << "[feDiffuseLighting";
    FilterEffect::externalRepresentation(ts);
    ts << " surfaceScale=\"" << m_surfaceScale << "\" "
       << "diffuseConstant=\"" << m_diffuseConstant << "\" "
       << "kernelUnitLength=\"" << m_kernelUnitLengthX << ", " << m_kernelUnitLengthY << "\"]\n";
    inputEffect(0)->externalRepresentation(ts, indent + 1);
    return ts;
}

} // namespace blink
