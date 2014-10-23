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
#include "platform/graphics/filters/FESpecularLighting.h"

#include "platform/graphics/filters/LightSource.h"
#include "platform/text/TextStream.h"

namespace blink {

FESpecularLighting::FESpecularLighting(Filter* filter, const Color& lightingColor, float surfaceScale,
    float specularConstant, float specularExponent, float kernelUnitLengthX,
    float kernelUnitLengthY, PassRefPtr<LightSource> lightSource)
    : FELighting(filter, SpecularLighting, lightingColor, surfaceScale, 0, specularConstant, specularExponent, kernelUnitLengthX, kernelUnitLengthY, lightSource)
{
}

PassRefPtr<FESpecularLighting> FESpecularLighting::create(Filter* filter, const Color& lightingColor,
    float surfaceScale, float specularConstant, float specularExponent,
    float kernelUnitLengthX, float kernelUnitLengthY, PassRefPtr<LightSource> lightSource)
{
    return adoptRef(new FESpecularLighting(filter, lightingColor, surfaceScale, specularConstant, specularExponent,
        kernelUnitLengthX, kernelUnitLengthY, lightSource));
}

FESpecularLighting::~FESpecularLighting()
{
}

Color FESpecularLighting::lightingColor() const
{
    return m_lightingColor;
}

bool FESpecularLighting::setLightingColor(const Color& lightingColor)
{
    if (m_lightingColor == lightingColor)
        return false;
    m_lightingColor = lightingColor;
    return true;
}

float FESpecularLighting::surfaceScale() const
{
    return m_surfaceScale;
}

bool FESpecularLighting::setSurfaceScale(float surfaceScale)
{
    if (m_surfaceScale == surfaceScale)
        return false;
    m_surfaceScale = surfaceScale;
    return true;
}

float FESpecularLighting::specularConstant() const
{
    return m_specularConstant;
}

bool FESpecularLighting::setSpecularConstant(float specularConstant)
{
    specularConstant = std::max(specularConstant, 0.0f);
    if (m_specularConstant == specularConstant)
        return false;
    m_specularConstant = specularConstant;
    return true;
}

float FESpecularLighting::specularExponent() const
{
    return m_specularExponent;
}

bool FESpecularLighting::setSpecularExponent(float specularExponent)
{
    specularExponent = std::min(std::max(specularExponent, 1.0f), 128.0f);
    if (m_specularExponent == specularExponent)
        return false;
    m_specularExponent = specularExponent;
    return true;
}

float FESpecularLighting::kernelUnitLengthX() const
{
    return m_kernelUnitLengthX;
}

bool FESpecularLighting::setKernelUnitLengthX(float kernelUnitLengthX)
{
    if (m_kernelUnitLengthX == kernelUnitLengthX)
        return false;
    m_kernelUnitLengthX = kernelUnitLengthX;
    return true;
}

float FESpecularLighting::kernelUnitLengthY() const
{
    return m_kernelUnitLengthY;
}

bool FESpecularLighting::setKernelUnitLengthY(float kernelUnitLengthY)
{
    if (m_kernelUnitLengthY == kernelUnitLengthY)
        return false;
    m_kernelUnitLengthY = kernelUnitLengthY;
    return true;
}

const LightSource* FESpecularLighting::lightSource() const
{
    return m_lightSource.get();
}

void FESpecularLighting::setLightSource(PassRefPtr<LightSource> lightSource)
{
    m_lightSource = lightSource;
}

TextStream& FESpecularLighting::externalRepresentation(TextStream& ts, int indent) const
{
    writeIndent(ts, indent);
    ts << "[feSpecularLighting";
    FilterEffect::externalRepresentation(ts);
    ts << " surfaceScale=\"" << m_surfaceScale << "\" "
       << "specualConstant=\"" << m_specularConstant << "\" "
       << "specularExponent=\"" << m_specularExponent << "\"]\n";
    inputEffect(0)->externalRepresentation(ts, indent + 1);
    return ts;
}

} // namespace blink
