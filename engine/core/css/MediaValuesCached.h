// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MediaValuesCached_h
#define MediaValuesCached_h

#include "core/css/MediaValues.h"

namespace blink {

class MediaValuesCached final : public MediaValues {
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
    virtual PassRefPtr<MediaValues> copy() const override;
    virtual bool isSafeToSendToAnotherThread() const override;
    virtual bool computeLength(double value, CSSPrimitiveValue::UnitType, int& result) const override;
    virtual bool computeLength(double value, CSSPrimitiveValue::UnitType, double& result) const override;

    virtual int viewportWidth() const override;
    virtual int viewportHeight() const override;
    virtual int deviceWidth() const override;
    virtual int deviceHeight() const override;
    virtual float devicePixelRatio() const override;
    virtual int colorBitsPerComponent() const override;
    virtual int monochromeBitsPerComponent() const override;
    virtual PointerType primaryPointerType() const override;
    virtual int availablePointerTypes() const override;
    virtual HoverType primaryHoverType() const override;
    virtual int availableHoverTypes() const override;
    virtual bool threeDEnabled() const override;
    virtual bool strictMode() const override;
    virtual Document* document() const override;
    virtual bool hasValues() const override;
    virtual const String mediaType() const override;

protected:
    MediaValuesCached();
    MediaValuesCached(LocalFrame*);
    MediaValuesCached(const MediaValuesCachedData&);

    MediaValuesCachedData m_data;
};

} // namespace

#endif // MediaValuesCached_h
