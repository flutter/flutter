// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_TEXT_PARAGRAPH_H_
#define SKY_ENGINE_CORE_TEXT_PARAGRAPH_H_

#include "sky/engine/tonic/dart_wrappable.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/RefCounted.h"
#include "sky/engine/core/painting/Canvas.h"
#include "sky/engine/core/painting/Offset.h"
#include "sky/engine/core/rendering/RenderView.h"

namespace blink {

class Paragraph : public RefCounted<Paragraph>, public DartWrappable {
    DEFINE_WRAPPERTYPEINFO();
public:
    static PassRefPtr<Paragraph> create(PassOwnPtr<RenderView> renderView) {
      return adoptRef(new Paragraph(renderView));
    }

    ~Paragraph() override;

    LayoutUnit minWidth() const { return m_minWidth; }
    void setMinWidth(LayoutUnit width) { m_minWidth = width; }

    LayoutUnit maxWidth() const { return m_maxWidth; }
    void setMaxWidth(LayoutUnit width) { m_maxWidth = width; }

    LayoutUnit minHeight() const { return m_minHeight; }
    void setMinHeight(LayoutUnit height) { m_minHeight = height; }

    LayoutUnit maxHeight() const { return m_maxHeight; }
    void setMaxHeight(LayoutUnit height) { m_maxHeight = height; }

    double width();
    double height();
    double minIntrinsicWidth();
    double maxIntrinsicWidth();
    double alphabeticBaseline();
    double ideographicBaseline();

    void layout();
    void paint(Canvas* canvas, const Offset& offset);

    RenderView* renderView() const { return m_renderView.get(); }

private:
    RenderBox* firstChildBox() const { return m_renderView->firstChildBox(); }

    LayoutUnit m_minWidth;
    LayoutUnit m_maxWidth;
    LayoutUnit m_minHeight;
    LayoutUnit m_maxHeight;

    explicit Paragraph(PassOwnPtr<RenderView> renderView);

    OwnPtr<RenderView> m_renderView;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_TEXT_PARAGRAPH_H_
