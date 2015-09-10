// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_TEXT_PARAGRAPHBUILDER_H_
#define SKY_ENGINE_CORE_TEXT_PARAGRAPHBUILDER_H_

#include "sky/engine/core/text/Paragraph.h"
#include "sky/engine/core/text/ParagraphStyle.h"
#include "sky/engine/core/text/TextStyle.h"
#include "sky/engine/tonic/dart_wrappable.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/RefCounted.h"

namespace blink {

class ParagraphBuilder : public RefCounted<ParagraphBuilder>, public DartWrappable {
    DEFINE_WRAPPERTYPEINFO();
public:
    static PassRefPtr<ParagraphBuilder> create() {
      return adoptRef(new ParagraphBuilder());
    }

    ~ParagraphBuilder() override;

    void pushStyle(TextStyle* style);
    void pop();

    void addText(const String& text);

    PassRefPtr<Paragraph> build(ParagraphStyle* style);

private:
    explicit ParagraphBuilder();

    OwnPtr<RenderView> m_renderView;

    RefPtr<RenderStyle> m_parentStyle;
    RenderParagraph* m_renderParagraph;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_TEXT_PARAGRAPHBUILDER_H_
