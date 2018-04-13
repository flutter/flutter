// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_TEXT_PARAGRAPH_H_
#define FLUTTER_LIB_UI_TEXT_PARAGRAPH_H_

#include "flutter/fml/message_loop.h"
#include "flutter/lib/ui/painting/canvas.h"
#include "flutter/lib/ui/text/paragraph_impl.h"
#include "flutter/lib/ui/text/paragraph_impl_blink.h"
#include "flutter/lib/ui/text/paragraph_impl_txt.h"
#include "flutter/lib/ui/text/text_box.h"
#include "flutter/sky/engine/core/rendering/RenderView.h"
#include "flutter/sky/engine/wtf/PassOwnPtr.h"
#include "flutter/third_party/txt/src/txt/paragraph.h"
#include "lib/tonic/dart_wrappable.h"

namespace tonic {
class DartLibraryNatives;
}  // namespace tonic

namespace blink {

class Paragraph : public fxl::RefCountedThreadSafe<Paragraph>,
                  public tonic::DartWrappable {
  DEFINE_WRAPPERTYPEINFO();
  FRIEND_MAKE_REF_COUNTED(Paragraph);

 public:
  static fxl::RefPtr<Paragraph> Create(PassOwnPtr<RenderView> renderView) {
    return fxl::MakeRefCounted<Paragraph>(renderView);
  }

  static fxl::RefPtr<Paragraph> Create(
      std::unique_ptr<txt::Paragraph> paragraph) {
    return fxl::MakeRefCounted<Paragraph>(std::move(paragraph));
  }

  ~Paragraph() override;

  double width();
  double height();
  double minIntrinsicWidth();
  double maxIntrinsicWidth();
  double alphabeticBaseline();
  double ideographicBaseline();
  bool didExceedMaxLines();

  void layout(double width);
  void paint(Canvas* canvas, double x, double y);

  std::vector<TextBox> getRectsForRange(unsigned start, unsigned end);
  Dart_Handle getPositionForOffset(double dx, double dy);
  Dart_Handle getWordBoundary(unsigned offset);

  RenderView* renderView() const { return m_renderView.get(); }

  virtual size_t GetAllocationSize() override;

  static void RegisterNatives(tonic::DartLibraryNatives* natives);

 private:
  std::unique_ptr<ParagraphImpl> m_paragraphImpl;

  explicit Paragraph(PassOwnPtr<RenderView> renderView);

  explicit Paragraph(std::unique_ptr<txt::Paragraph> paragraph);

  // TODO: This can be removed when the render view association for the legacy
  // runtime is removed.
  fxl::RefPtr<fxl::TaskRunner> destruction_task_runner_ =
      UIDartState::Current()->GetTaskRunners().GetUITaskRunner();
  OwnPtr<RenderView> m_renderView;
};

}  // namespace blink

#endif  // FLUTTER_LIB_UI_TEXT_PARAGRAPH_H_
