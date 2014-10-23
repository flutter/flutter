// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MediaValuesCached_h
#define MediaValuesCached_h

#include "core/css/MediaValues.h"

namespace blink {

class MediaValuesCached FINAL : public MediaValues {
public:
    struct MediaValuesCachedData {
        // Members variables must be thread safe, since they're copied to the parser thread
        int viewportWidth;
        int viewportHeight;
        int deviceWidth;
        int deviceHeight;
        float devicePixelRatio;
        int colorBitsPerComponent;
        int monochromeBitsPerComponent;
        PointerType primaryPointerType;
        int availablePointerTypes;
        HoverType primaryHoverType;
        int availableHoverTypes;
        int defaultFontSize;
        bool threeDEnabled;
        bool strictMode;
        String mediaType;

        MediaValuesCachedData()
            : viewportWidth(0)
            , viewportHeight(0)
            , deviceWidth(0)
            , deviceHeight(0)
            , devicePixelRatio(1.0)
            , colorBitsPerComponent(24)
            , monochromeBitsPerComponent(0)
            , primaryPointerType(PointerTypeNone)
            , availablePointerTypes(PointerTypeNone)
            , primaryHoverType(HoverTypeNone)
            , availableHoverTypes(HoverTypeNone)
            , defaultFontSize(16)
            , threeDEnabled(false)
            , strictMode(true)
        {
        }
    };

    static PassRefPtr<MediaValues> create();
    static PassRefPtr<MediaValues> create(Document&);
    static PassRefPtr<MediaValues> create(LocalFrame*);
    static PassRefPtr<MediaValues> create(MediaValuesCachedData&);
    virtual PassRefPtr<MediaValues> copy() const OVERRIDE;
    virtual bool isSafeToSendToAnotherThread() const OVERRIDE;
    virtual bool computeLength(double value, CSSPrimitiveValue::UnitType, int& result) const OVERRIDE;
    virtual bool computeLength(double value, CSSPrimitiveValue::UnitType, double& result) const OVERRIDE;

    virtual int viewportWidth() const OVERRIDE;
    virtual int viewportHeight() const OVERRIDE;
    virtual int deviceWidth() const OVERRIDE;
    virtual int deviceHeight() const OVERRIDE;
    virtual float devicePixelRatio() const OVERRIDE;
    virtual int colorBitsPerComponent() const OVERRIDE;
    virtual int monochromeBitsPerComponent() const OVERRIDE;
    virtual PointerType primaryPointerType() const OVERRIDE;
    virtual int availablePointerTypes() const OVERRIDE;
    virtual HoverType primaryHoverType() const OVERRIDE;
    virtual int availableHoverTypes() const OVERRIDE;
    virtual bool threeDEnabled() const OVERRIDE;
    virtual bool strictMode() const OVERRIDE;
    virtual Document* document() const OVERRIDE;
    virtual bool hasValues() const OVERRIDE;
    virtual const String mediaType() const OVERRIDE;

protected:
    MediaValuesCached();
    MediaValuesCached(LocalFrame*);
    MediaValuesCached(const MediaValuesCachedData&);

    MediaValuesCachedData m_data;
};

} // namespace

#endif // MediaValuesCached_h
