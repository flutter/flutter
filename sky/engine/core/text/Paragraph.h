// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_TEXT_PARAGRAPH_H_
#define SKY_ENGINE_CORE_TEXT_PARAGRAPH_H_

#include "sky/engine/tonic/dart_wrappable.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/ThreadSafeRefCounted.h"
#include "sky/engine/core/painting/Canvas.h"
#include "sky/engine/core/painting/Offset.h"
#include "sky/engine/core/rendering/RenderView.h"
#include "sky/engine/core/text/TextBox.h"

namespace blink {
class DartLibraryNatives;

class Paragraph : public ThreadSafeRefCounted<Paragraph>, public DartWrappable {
    DEFINE_WRAPPERTYPEINFO();
public:
    static PassRefPtr<Paragraph> create(PassOwnPtr<RenderView> renderView) {
      return adoptRef(new Paragraph(renderView));
    }

    ~Paragraph() override;

    double width();
    double height();
    double minIntrinsicWidth();
    double maxIntrinsicWidth();
    double alphabeticBaseline();
    double ideographicBaseline();

    void layout(double width);
    void paint(Canvas* canvas, double x, double y);

    std::vector<TextBox> getRectsForRange(unsigned start, unsigned end);
    Dart_Handle getPositionForOffset(const Offset& offset);

    RenderView* renderView() const { return m_renderView.get(); }

    static void RegisterNatives(DartLibraryNatives* natives);

private:
    RenderBox* firstChildBox() const { return m_renderView->firstChildBox(); }

    int absoluteOffsetForPosition(const PositionWithAffinity& position);

    explicit Paragraph(PassOwnPtr<RenderView> renderView);

    OwnPtr<RenderView> m_renderView;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_TEXT_PARAGRAPH_H_
