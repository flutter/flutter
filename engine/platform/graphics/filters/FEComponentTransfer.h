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

#ifndef FEComponentTransfer_h
#define FEComponentTransfer_h

#include "platform/graphics/filters/Filter.h"
#include "platform/graphics/filters/FilterEffect.h"
#include "wtf/Vector.h"

namespace blink {

enum ComponentTransferType {
    FECOMPONENTTRANSFER_TYPE_UNKNOWN  = 0,
    FECOMPONENTTRANSFER_TYPE_IDENTITY = 1,
    FECOMPONENTTRANSFER_TYPE_TABLE    = 2,
    FECOMPONENTTRANSFER_TYPE_DISCRETE = 3,
    FECOMPONENTTRANSFER_TYPE_LINEAR   = 4,
    FECOMPONENTTRANSFER_TYPE_GAMMA    = 5
};

struct ComponentTransferFunction {
    ComponentTransferFunction()
        : type(FECOMPONENTTRANSFER_TYPE_UNKNOWN)
        , slope(0)
        , intercept(0)
        , amplitude(0)
        , exponent(0)
        , offset(0)
    {
    }

    ComponentTransferType type;

    float slope;
    float intercept;
    float amplitude;
    float exponent;
    float offset;

    Vector<float> tableValues;
};

class PLATFORM_EXPORT FEComponentTransfer : public FilterEffect {
public:
    static PassRefPtr<FEComponentTransfer> create(Filter*, const ComponentTransferFunction& redFunc, const ComponentTransferFunction& greenFunc,
        const ComponentTransferFunction& blueFunc, const ComponentTransferFunction& alphaFunc);

    ComponentTransferFunction redFunction() const;
    void setRedFunction(const ComponentTransferFunction&);

    ComponentTransferFunction greenFunction() const;
    void setGreenFunction(const ComponentTransferFunction&);

    ComponentTransferFunction blueFunction() const;
    void setBlueFunction(const ComponentTransferFunction&);

    ComponentTransferFunction alphaFunction() const;
    void setAlphaFunction(const ComponentTransferFunction&);

    virtual PassRefPtr<SkImageFilter> createImageFilter(SkiaImageFilterBuilder*) override;

    virtual TextStream& externalRepresentation(TextStream&, int indention) const override;

private:
    FEComponentTransfer(Filter*, const ComponentTransferFunction& redFunc, const ComponentTransferFunction& greenFunc,
        const ComponentTransferFunction& blueFunc, const ComponentTransferFunction& alphaFunc);

    virtual void applySoftware() override;

    virtual bool affectsTransparentPixels() override;

    void getValues(unsigned char rValues[256], unsigned char gValues[256], unsigned char bValues[256], unsigned char aValues[256]);

    ComponentTransferFunction m_redFunc;
    ComponentTransferFunction m_greenFunc;
    ComponentTransferFunction m_blueFunc;
    ComponentTransferFunction m_alphaFunc;
};

} // namespace blink

#endif // FEComponentTransfer_h
