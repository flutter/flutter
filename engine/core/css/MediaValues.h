// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MediaValues_h
#define MediaValues_h

#include "core/css/CSSPrimitiveValue.h"
#include "core/css/PointerProperties.h"
#include "wtf/RefCounted.h"
#include "wtf/RefPtr.h"

namespace blink {

class Document;
class CSSPrimitiveValue;
class LocalFrame;

class MediaValues : public RefCounted<MediaValues> {
public:

    enum MediaValuesMode {
        CachingMode,
        DynamicMode
    };

    virtual ~MediaValues() { }

    static PassRefPtr<MediaValues> createDynamicIfFrameExists(LocalFrame*);
    virtual PassRefPtr<MediaValues> copy() const = 0;
    virtual bool isSafeToSendToAnotherThread() const = 0;

    static bool computeLengthImpl(double value, CSSPrimitiveValue::UnitType, unsigned defaultFontSize, unsigned viewportWidth, unsigned viewportHeight, double& result);
    template<typename T>
    static bool computeLength(double value, CSSPrimitiveValue::UnitType type, unsigned defaultFontSize, unsigned viewportWidth, unsigned viewportHeight, T& result)
    {
        double tempResult;
        if (!computeLengthImpl(value, type, defaultFontSize, viewportWidth, viewportHeight, tempResult))
            return false;
        result = roundForImpreciseConversion<T>(tempResult);
        return true;
    }
    virtual bool computeLength(double value, CSSPrimitiveValue::UnitType, int& result) const = 0;
    virtual bool computeLength(double value, CSSPrimitiveValue::UnitType, double& result) const = 0;

    virtual int viewportWidth() const = 0;
    virtual int viewportHeight() const = 0;
    virtual int deviceWidth() const = 0;
    virtual int deviceHeight() const = 0;
    virtual float devicePixelRatio() const = 0;
    virtual int colorBitsPerComponent() const = 0;
    virtual int monochromeBitsPerComponent() const = 0;
    virtual PointerType primaryPointerType() const = 0;
    virtual int availablePointerTypes() const = 0;
    virtual HoverType primaryHoverType() const = 0;
    virtual int availableHoverTypes() const = 0;
    virtual bool threeDEnabled() const = 0;
    virtual const String mediaType() const = 0;
    virtual bool strictMode() const = 0;
    virtual Document* document() const = 0;
    virtual bool hasValues() const = 0;

protected:
    int calculateViewportWidth(LocalFrame*) const;
    int calculateViewportHeight(LocalFrame*) const;
    int calculateDeviceWidth(LocalFrame*) const;
    int calculateDeviceHeight(LocalFrame*) const;
    bool calculateStrictMode(LocalFrame*) const;
    float calculateDevicePixelRatio(LocalFrame*) const;
    int calculateColorBitsPerComponent(LocalFrame*) const;
    int calculateMonochromeBitsPerComponent(LocalFrame*) const;
    int calculateDefaultFontSize(LocalFrame*) const;
    const String calculateMediaType(LocalFrame*) const;
    bool calculateThreeDEnabled(LocalFrame*) const;
    PointerType calculatePrimaryPointerType(LocalFrame*) const;
    int calculateAvailablePointerTypes(LocalFrame*) const;
    HoverType calculatePrimaryHoverType(LocalFrame*) const;
    int calculateAvailableHoverTypes(LocalFrame*) const;
    static LocalFrame* frameFrom(Document&);

};

} // namespace

#endif // MediaValues_h
