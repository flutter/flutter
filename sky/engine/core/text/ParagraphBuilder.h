// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_TEXT_PARAGRAPHBUILDER_H_
#define SKY_ENGINE_CORE_TEXT_PARAGRAPHBUILDER_H_

#include "sky/engine/core/text/Paragraph.h"
#include "sky/engine/tonic/dart_wrappable.h"
#include "sky/engine/tonic/int32_list.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/RefCounted.h"

namespace blink {
class DartLibraryNatives;

class ParagraphBuilder : public RefCounted<ParagraphBuilder>, public DartWrappable {
    DEFINE_WRAPPERTYPEINFO();
public:
    static PassRefPtr<ParagraphBuilder> create() {
      return adoptRef(new ParagraphBuilder());
    }

    ~ParagraphBuilder() override;

    void pushStyle(Int32List& encoded, const String& fontFamily, double fontSize, double letterSpacing, double wordSpacing, double lineHeight);
    void pop();

    void addText(const String& text);

    PassRefPtr<Paragraph> build(Int32List& encoded, double lineHeight);

    static void RegisterNatives(DartLibraryNatives* natives);

private:
    explicit ParagraphBuilder();

    void createRenderView();

    OwnPtr<RenderView> m_renderView;
    RenderObject* m_renderParagraph;
    RenderObject* m_currentRenderObject;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_TEXT_PARAGRAPHBUILDER_H_
