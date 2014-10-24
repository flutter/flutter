/*
 * Copyright (C) 2011 Apple Inc. All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE COMPUTER, INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE COMPUTER, INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef FilterOperation_h
#define FilterOperation_h

#include "platform/Length.h"
#include "platform/PlatformExport.h"
#include "platform/graphics/Color.h"
#include "platform/graphics/filters/Filter.h"
#include "platform/graphics/filters/ReferenceFilter.h"
#include "wtf/OwnPtr.h"
#include "wtf/PassOwnPtr.h"
#include "wtf/RefCounted.h"
#include "wtf/text/WTFString.h"

namespace blink {

// CSS Filters

class PLATFORM_EXPORT FilterOperation : public RefCounted<FilterOperation> {
public:
    enum OperationType {
        REFERENCE, // url(#somefilter)
        GRAYSCALE,
        SEPIA,
        SATURATE,
        HUE_ROTATE,
        INVERT,
        OPACITY,
        BRIGHTNESS,
        CONTRAST,
        BLUR,
        DROP_SHADOW,
        NONE
    };

    static bool canInterpolate(FilterOperation::OperationType type)
    {
        switch (type) {
        case GRAYSCALE:
        case SEPIA:
        case SATURATE:
        case HUE_ROTATE:
        case INVERT:
        case OPACITY:
        case BRIGHTNESS:
        case CONTRAST:
        case BLUR:
        case DROP_SHADOW:
            return true;
        case REFERENCE:
            return false;
        case NONE:
            break;
        }
        ASSERT_NOT_REACHED();
        return false;
    }

    virtual ~FilterOperation() { }

    static PassRefPtr<FilterOperation> blend(const FilterOperation* from, const FilterOperation* to, double progress);
    virtual bool operator==(const FilterOperation&) const = 0;
    bool operator!=(const FilterOperation& o) const { return !(*this == o); }

    OperationType type() const { return m_type; }
    virtual bool isSameType(const FilterOperation& o) const { return o.type() == m_type; }

    // True if the alpha channel of any pixel can change under this operation.
    virtual bool affectsOpacity() const { return false; }
    // True if the the value of one pixel can affect the value of another pixel under this operation, such as blur.
    virtual bool movesPixels() const { return false; }

protected:
    FilterOperation(OperationType type)
        : m_type(type)
    {
    }

    OperationType m_type;

private:
    virtual PassRefPtr<FilterOperation> blend(const FilterOperation* from, double progress) const = 0;
};

#define DEFINE_FILTER_OPERATION_TYPE_CASTS(thisType, operationType) \
    DEFINE_TYPE_CASTS(thisType, FilterOperation, op, op->type() == FilterOperation::operationType, op.type() == FilterOperation::operationType);

class PLATFORM_EXPORT ReferenceFilterOperation : public FilterOperation {
public:
    static PassRefPtr<ReferenceFilterOperation> create(const String& url, const AtomicString& fragment)
    {
        return adoptRef(new ReferenceFilterOperation(url, fragment));
    }

    virtual bool affectsOpacity() const override { return true; }
    virtual bool movesPixels() const override { return true; }

    const String& url() const { return m_url; }
    const AtomicString& fragment() const { return m_fragment; }

    ReferenceFilter* filter() const { return m_filter.get(); }
    void setFilter(PassRefPtr<ReferenceFilter> filter) { m_filter = filter; }

private:
    virtual PassRefPtr<FilterOperation> blend(const FilterOperation* from, double progress) const override
    {
        ASSERT_NOT_REACHED();
        return nullptr;
    }

    virtual bool operator==(const FilterOperation& o) const override
    {
        if (!isSameType(o))
            return false;
        const ReferenceFilterOperation* other = static_cast<const ReferenceFilterOperation*>(&o);
        return m_url == other->m_url;
    }

    ReferenceFilterOperation(const String& url, const AtomicString& fragment)
        : FilterOperation(REFERENCE)
        , m_url(url)
        , m_fragment(fragment)
    {
    }

    String m_url;
    AtomicString m_fragment;
    RefPtr<ReferenceFilter> m_filter;
};

DEFINE_FILTER_OPERATION_TYPE_CASTS(ReferenceFilterOperation, REFERENCE);

// GRAYSCALE, SEPIA, SATURATE and HUE_ROTATE are variations on a basic color matrix effect.
// For HUE_ROTATE, the angle of rotation is stored in m_amount.
class PLATFORM_EXPORT BasicColorMatrixFilterOperation : public FilterOperation {
public:
    static PassRefPtr<BasicColorMatrixFilterOperation> create(double amount, OperationType type)
    {
        return adoptRef(new BasicColorMatrixFilterOperation(amount, type));
    }

    double amount() const { return m_amount; }


private:
    virtual PassRefPtr<FilterOperation> blend(const FilterOperation* from, double progress) const override;
    virtual bool operator==(const FilterOperation& o) const override
    {
        if (!isSameType(o))
            return false;
        const BasicColorMatrixFilterOperation* other = static_cast<const BasicColorMatrixFilterOperation*>(&o);
        return m_amount == other->m_amount;
    }

    BasicColorMatrixFilterOperation(double amount, OperationType type)
        : FilterOperation(type)
        , m_amount(amount)
    {
    }

    double m_amount;
};

inline bool isBasicColorMatrixFilterOperation(const FilterOperation& operation)
{
    FilterOperation::OperationType type = operation.type();
    return type == FilterOperation::GRAYSCALE || type == FilterOperation::SEPIA || type == FilterOperation::SATURATE || type == FilterOperation::HUE_ROTATE;
}

DEFINE_TYPE_CASTS(BasicColorMatrixFilterOperation, FilterOperation, op, isBasicColorMatrixFilterOperation(*op), isBasicColorMatrixFilterOperation(op));

// INVERT, BRIGHTNESS, CONTRAST and OPACITY are variations on a basic component transfer effect.
class PLATFORM_EXPORT BasicComponentTransferFilterOperation : public FilterOperation {
public:
    static PassRefPtr<BasicComponentTransferFilterOperation> create(double amount, OperationType type)
    {
        return adoptRef(new BasicComponentTransferFilterOperation(amount, type));
    }

    double amount() const { return m_amount; }

    virtual bool affectsOpacity() const override { return m_type == OPACITY; }


private:
    virtual PassRefPtr<FilterOperation> blend(const FilterOperation* from, double progress) const override;
    virtual bool operator==(const FilterOperation& o) const override
    {
        if (!isSameType(o))
            return false;
        const BasicComponentTransferFilterOperation* other = static_cast<const BasicComponentTransferFilterOperation*>(&o);
        return m_amount == other->m_amount;
    }

    BasicComponentTransferFilterOperation(double amount, OperationType type)
        : FilterOperation(type)
        , m_amount(amount)
    {
    }

    double m_amount;
};

inline bool isBasicComponentTransferFilterOperation(const FilterOperation& operation)
{
    FilterOperation::OperationType type = operation.type();
    return type == FilterOperation::INVERT || type == FilterOperation::OPACITY || type == FilterOperation::BRIGHTNESS || type == FilterOperation::CONTRAST;
}

DEFINE_TYPE_CASTS(BasicComponentTransferFilterOperation, FilterOperation, op, isBasicComponentTransferFilterOperation(*op), isBasicComponentTransferFilterOperation(op));

class PLATFORM_EXPORT BlurFilterOperation : public FilterOperation {
public:
    static PassRefPtr<BlurFilterOperation> create(const Length& stdDeviation)
    {
        return adoptRef(new BlurFilterOperation(stdDeviation));
    }

    const Length& stdDeviation() const { return m_stdDeviation; }

    virtual bool affectsOpacity() const override { return true; }
    virtual bool movesPixels() const override { return true; }


private:
    virtual PassRefPtr<FilterOperation> blend(const FilterOperation* from, double progress) const override;
    virtual bool operator==(const FilterOperation& o) const override
    {
        if (!isSameType(o))
            return false;
        const BlurFilterOperation* other = static_cast<const BlurFilterOperation*>(&o);
        return m_stdDeviation == other->m_stdDeviation;
    }

    BlurFilterOperation(const Length& stdDeviation)
        : FilterOperation(BLUR)
        , m_stdDeviation(stdDeviation)
    {
    }

    Length m_stdDeviation;
};

DEFINE_FILTER_OPERATION_TYPE_CASTS(BlurFilterOperation, BLUR);

class PLATFORM_EXPORT DropShadowFilterOperation : public FilterOperation {
public:
    static PassRefPtr<DropShadowFilterOperation> create(const IntPoint& location, int stdDeviation, Color color)
    {
        return adoptRef(new DropShadowFilterOperation(location, stdDeviation, color));
    }

    int x() const { return m_location.x(); }
    int y() const { return m_location.y(); }
    IntPoint location() const { return m_location; }
    int stdDeviation() const { return m_stdDeviation; }
    Color color() const { return m_color; }

    virtual bool affectsOpacity() const override { return true; }
    virtual bool movesPixels() const override { return true; }


private:
    virtual PassRefPtr<FilterOperation> blend(const FilterOperation* from, double progress) const override;
    virtual bool operator==(const FilterOperation& o) const override
    {
        if (!isSameType(o))
            return false;
        const DropShadowFilterOperation* other = static_cast<const DropShadowFilterOperation*>(&o);
        return m_location == other->m_location && m_stdDeviation == other->m_stdDeviation && m_color == other->m_color;
    }

    DropShadowFilterOperation(const IntPoint& location, int stdDeviation, Color color)
        : FilterOperation(DROP_SHADOW)
        , m_location(location)
        , m_stdDeviation(stdDeviation)
        , m_color(color)
    {
    }

    IntPoint m_location; // FIXME: should location be in Lengths?
    int m_stdDeviation;
    Color m_color;
};

DEFINE_FILTER_OPERATION_TYPE_CASTS(DropShadowFilterOperation, DROP_SHADOW);

} // namespace blink


#endif // FilterOperation_h
