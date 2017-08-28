// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_TEXT_PARAGRAPH_BUILDER_H_
#define FLUTTER_LIB_UI_TEXT_PARAGRAPH_BUILDER_H_

#include "flutter/lib/ui/text/paragraph.h"
#include "flutter/sky/engine/core/rendering/RenderObject.h"
#include "flutter/sky/engine/wtf/OwnPtr.h"
#include "flutter/third_party/txt/src/txt/paragraph_builder.h"
#include "lib/tonic/dart_wrappable.h"
#include "lib/tonic/typed_data/int32_list.h"

namespace tonic {
class DartLibraryNatives;
}  // namespace tonic

namespace blink {

class Paragraph;

class ParagraphBuilder : public ftl::RefCountedThreadSafe<ParagraphBuilder>,
                         public tonic::DartWrappable {
  DEFINE_WRAPPERTYPEINFO();
  FRIEND_MAKE_REF_COUNTED(ParagraphBuilder);

 public:
  static ftl::RefPtr<ParagraphBuilder> create(tonic::Int32List& encoded,
                                              const std::string& fontFamily,
                                              double fontSize,
                                              double lineHeight,
                                              const std::string& ellipsis);

  ~ParagraphBuilder() override;

  void pushStyle(tonic::Int32List& encoded,
                 const std::string& fontFamily,
                 double fontSize,
                 double letterSpacing,
                 double wordSpacing,
                 double height);

  void pop();

  void addText(const std::string& text);

  ftl::RefPtr<Paragraph> build();

  static void RegisterNatives(tonic::DartLibraryNatives* natives);

 private:
  explicit ParagraphBuilder(tonic::Int32List& encoded,
                            const std::string& fontFamily,
                            double fontSize,
                            double lineHeight,
                            const std::string& ellipsis);

  void createRenderView();

  OwnPtr<RenderView> m_renderView;
  RenderObject* m_renderParagraph;
  RenderObject* m_currentRenderObject;
  txt::ParagraphBuilder m_paragraphBuilder;
};

}  // namespace blink

#endif  // FLUTTER_LIB_UI_TEXT_PARAGRAPH_BUILDER_H_
