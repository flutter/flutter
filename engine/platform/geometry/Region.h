/*
 * Copyright (C) 2010, 2011 Apple Inc. All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef Region_h
#define Region_h

#include "platform/PlatformExport.h"
#include "platform/geometry/IntRect.h"
#include "wtf/Vector.h"

namespace blink {

class PLATFORM_EXPORT Region {
public:
    Region();
    Region(const IntRect&);

    IntRect bounds() const { return m_bounds; }
    bool isEmpty() const { return m_bounds.isEmpty(); }
    bool isRect() const { return m_shape.isRect(); }

    Vector<IntRect> rects() const;

    void unite(const Region&);
    void intersect(const Region&);
    void subtract(const Region&);

    void translate(const IntSize&);

    // Returns true if the query region is a subset of this region.
    bool contains(const Region&) const;

    bool contains(const IntPoint&) const;

    // Returns true if the query region intersects any part of this region.
    bool intersects(const Region&) const;

    unsigned totalArea() const;

#ifndef NDEBUG
    void dump() const;
#endif

private:
    struct Span {
        Span(int y, size_t segmentIndex)
            : y(y), segmentIndex(segmentIndex)
        {
        }

        int y;
        size_t segmentIndex;
    };

    class Shape {
    public:
        Shape();
        Shape(const IntRect&);
        Shape(size_t segmentsCapacity, size_t spansCapacity);

        IntRect bounds() const;
        bool isEmpty() const { return m_spans.isEmpty(); }
        bool isRect() const { return m_spans.size() <= 2 && m_segments.size() <= 2; }

        typedef const Span* SpanIterator;
        SpanIterator spansBegin() const;
        SpanIterator spansEnd() const;
        size_t spansSize() const { return m_spans.size(); }

        typedef const int* SegmentIterator;
        SegmentIterator segmentsBegin(SpanIterator) const;
        SegmentIterator segmentsEnd(SpanIterator) const;
        size_t segmentsSize() const { return m_segments.size(); }

        static Shape unionShapes(const Shape& shape1, const Shape& shape2);
        static Shape intersectShapes(const Shape& shape1, const Shape& shape2);
        static Shape subtractShapes(const Shape& shape1, const Shape& shape2);

        void translate(const IntSize&);
        void swap(Shape&);

        struct CompareContainsOperation;
        struct CompareIntersectsOperation;

        template<typename CompareOperation>
        static bool compareShapes(const Shape& shape1, const Shape& shape2);
        void trimCapacities();

#ifndef NDEBUG
        void dump() const;
#endif

    private:
        struct UnionOperation;
        struct IntersectOperation;
        struct SubtractOperation;

        template<typename Operation>
        static Shape shapeOperation(const Shape& shape1, const Shape& shape2);

        void appendSegment(int x);
        void appendSpan(int y);
        void appendSpan(int y, SegmentIterator begin, SegmentIterator end);
        void appendSpans(const Shape&, SpanIterator begin, SpanIterator end);

        bool canCoalesce(SegmentIterator begin, SegmentIterator end);

        Vector<int, 32> m_segments;
        Vector<Span, 16> m_spans;

        friend bool operator==(const Shape&, const Shape&);
    };

    IntRect m_bounds;
    Shape m_shape;

    friend bool operator==(const Region&, const Region&);
    friend bool operator==(const Shape&, const Shape&);
    friend bool operator==(const Span&, const Span&);
};

static inline Region intersect(const Region& a, const Region& b)
{
    Region result(a);
    result.intersect(b);

    return result;
}

static inline Region subtract(const Region& a, const Region& b)
{
    Region result(a);
    result.subtract(b);

    return result;
}

static inline Region translate(const Region& region, const IntSize& offset)
{
    Region result(region);
    result.translate(offset);

    return result;
}

inline bool operator==(const Region& a, const Region& b)
{
    return a.m_bounds == b.m_bounds && a.m_shape == b.m_shape;
}

inline bool operator==(const Region::Shape& a, const Region::Shape& b)
{
    return a.m_spans == b.m_spans && a.m_segments == b.m_segments;
}

inline bool operator==(const Region::Span& a, const Region::Span& b)
{
    return a.y == b.y && a.segmentIndex == b.segmentIndex;
}

} // namespace blink

#endif // Region_h
