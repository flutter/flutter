// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MediaValuesDynamic_h
#define MediaValuesDynamic_h

#include "core/css/MediaValues.h"

namespace blink {

class Document;

class MediaValuesDynamic FINAL : public MediaValues {
public:
    static PassRefPtr<MediaValues> create(Document&);
    static PassRefPtr<MediaValues> create(LocalFrame*);
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
    virtual const String mediaType() const OVERRIDE;
    virtual Document* document() const OVERRIDE;
    virtual bool hasValues() const OVERRIDE;

protected:
    MediaValuesDynamic(LocalFrame*);

    // This raw ptr is safe, as MediaValues would not outlive MediaQueryEvaluator, and
    // MediaQueryEvaluator is reset on |Document::detach|.
    // FIXME: Oilpan: This raw ptr should be changed to a Member when LocalFrame is migrated to the heap.
    LocalFrame* m_frame;
};

} // namespace

#endif // MediaValuesDynamic_h
