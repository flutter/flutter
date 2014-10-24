// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MediaValuesDynamic_h
#define MediaValuesDynamic_h

#include "core/css/MediaValues.h"

namespace blink {

class Document;

class MediaValuesDynamic final : public MediaValues {
public:
    static PassRefPtr<MediaValues> create(Document&);
    static PassRefPtr<MediaValues> create(LocalFrame*);
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
    virtual const String mediaType() const override;
    virtual Document* document() const override;
    virtual bool hasValues() const override;

protected:
    MediaValuesDynamic(LocalFrame*);

    // This raw ptr is safe, as MediaValues would not outlive MediaQueryEvaluator, and
    // MediaQueryEvaluator is reset on |Document::detach|.
    // FIXME: Oilpan: This raw ptr should be changed to a Member when LocalFrame is migrated to the heap.
    LocalFrame* m_frame;
};

} // namespace

#endif // MediaValuesDynamic_h
