// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_TEXT_PARAGRAPHBUILDER_H_
#define SKY_ENGINE_CORE_TEXT_PARAGRAPHBUILDER_H_

#include "base/memory/ref_counted.h"
#include "flutter/tonic/dart_wrappable.h"
#include "lib/tonic/typed_data/int32_list.h"
#include "sky/engine/core/text/Paragraph.h"

namespace blink {
class DartLibraryNatives;

class ParagraphBuilder : public base::RefCountedThreadSafe<ParagraphBuilder>,
                         public DartWrappable {
  DEFINE_WRAPPERTYPEINFO();

 public:
  static scoped_refptr<ParagraphBuilder> create() {
    return new ParagraphBuilder();
  }

  ~ParagraphBuilder() override;

  void pushStyle(tonic::Int32List& encoded,
                 const std::string& fontFamily,
                 double fontSize,
                 double letterSpacing,
                 double wordSpacing,
                 double height);
  void pop();

  void addText(const std::string& text);

  scoped_refptr<Paragraph> build(tonic::Int32List& encoded,
                                 const std::string& fontFamily,
                                 double fontSize,
                                 double lineHeight);

  static void RegisterNatives(DartLibraryNatives* natives);

 private:
  explicit ParagraphBuilder();

  void createRenderView();

  OwnPtr<RenderView> m_renderView;
  RenderObject* m_renderParagraph;
  RenderObject* m_currentRenderObject;
};

}  // namespace blink

#endif  // SKY_ENGINE_CORE_TEXT_PARAGRAPHBUILDER_H_
