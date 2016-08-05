// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_TEXT_PARAGRAPHBUILDER_H_
#define SKY_ENGINE_CORE_TEXT_PARAGRAPHBUILDER_H_

#include "lib/tonic/dart_wrappable.h"
#include "lib/tonic/typed_data/int32_list.h"
#include "sky/engine/core/text/Paragraph.h"

namespace tonic {
class DartLibraryNatives;
}  // namespace tonic

namespace blink {

class ParagraphBuilder : public ftl::RefCountedThreadSafe<ParagraphBuilder>,
                         public tonic::DartWrappable {
  DEFINE_WRAPPERTYPEINFO();
  FRIEND_MAKE_REF_COUNTED(ParagraphBuilder);

 public:
  static ftl::RefPtr<ParagraphBuilder> create() {
    return ftl::MakeRefCounted<ParagraphBuilder>();
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

  ftl::RefPtr<Paragraph> build(tonic::Int32List& encoded,
                               const std::string& fontFamily,
                               double fontSize,
                               double lineHeight);

  static void RegisterNatives(tonic::DartLibraryNatives* natives);

 private:
  explicit ParagraphBuilder();

  void createRenderView();

  OwnPtr<RenderView> m_renderView;
  RenderObject* m_renderParagraph;
  RenderObject* m_currentRenderObject;
};

}  // namespace blink

#endif  // SKY_ENGINE_CORE_TEXT_PARAGRAPHBUILDER_H_
