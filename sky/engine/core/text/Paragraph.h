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

namespace blink {

class Paragraph : public RefCounted<Paragraph>, public DartWrappable {
    DEFINE_WRAPPERTYPEINFO();
public:
    static PassRefPtr<Paragraph> create() {
      return adoptRef(new Paragraph());
    }

    ~Paragraph() override;

    double minWidth() const { return m_minWidth; }
    void setMinWidth(double value) { m_minWidth = value; }

    double maxWidth() const { return m_maxWidth; }
    void setMaxWidth(double value) { m_maxWidth = value; }

    double minHeight() const { return m_minHeight; }
    void setMinHeight(double value) { m_minHeight = value; }

    double maxHeight() const { return m_maxHeight; }
    void setMaxHeight(double value) { m_maxHeight = value; }

    double width();
    double height();
    double minIntrinsicWidth();
    double maxIntrinsicWidth();
    double alphabeticBaseline();
    double ideographicBaseline();

    void layout();
    void paint(Canvas* canvas, const Offset& offset);

private:
    double m_minWidth;
    double m_maxWidth;
    double m_minHeight;
    double m_maxHeight;

    explicit Paragraph();
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_TEXT_PARAGRAPH_H_
