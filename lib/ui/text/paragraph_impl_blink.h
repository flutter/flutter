// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_TEXT_PARAGRAPH_IMPL_BLINK_H_
#define FLUTTER_LIB_UI_TEXT_PARAGRAPH_IMPL_BLINK_H_

#include "flutter/fml/message_loop.h"
#include "flutter/lib/ui/painting/canvas.h"
#include "flutter/lib/ui/text/paragraph_impl.h"
#include "flutter/lib/ui/text/text_box.h"
#include "flutter/sky/engine/core/rendering/RenderView.h"
#include "flutter/third_party/txt/src/txt/paragraph.h"

namespace blink {

class ParagraphImplBlink : public ParagraphImpl {
 public:
  ~ParagraphImplBlink() override;

  explicit ParagraphImplBlink(PassOwnPtr<RenderView> renderView);

  double width() override;
  double height() override;
  double minIntrinsicWidth() override;
  double maxIntrinsicWidth() override;
  double alphabeticBaseline() override;
  double ideographicBaseline() override;
  bool didExceedMaxLines() override;

  void layout(double width) override;
  void paint(Canvas* canvas, double x, double y) override;

  std::vector<TextBox> getRectsForRange(unsigned start, unsigned end) override;
  Dart_Handle getPositionForOffset(double dx, double dy) override;
  Dart_Handle getWordBoundary(unsigned offset) override;

  RenderView* renderView() const { return m_renderView.get(); }

 private:
  RenderBox* firstChildBox() const { return m_renderView->firstChildBox(); }

  int absoluteOffsetForPosition(const PositionWithAffinity& position);

  // TODO: This can be removed when the render view association for the legacy
  // runtime is removed.
  fxl::RefPtr<fxl::TaskRunner> destruction_task_runner_ =
      UIDartState::Current()->GetTaskRunners().GetUITaskRunner();
  OwnPtr<RenderView> m_renderView;
};

}  // namespace blink

#endif  // FLUTTER_LIB_UI_TEXT_PARAGRAPH_IMPL_BLINK_H_
