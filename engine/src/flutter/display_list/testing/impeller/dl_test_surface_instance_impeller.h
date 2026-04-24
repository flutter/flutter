// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_DISPLAY_LIST_TESTING_IMPELLER_DL_TEST_SURFACE_INSTANCE_IMPELLER_H_
#define FLUTTER_DISPLAY_LIST_TESTING_IMPELLER_DL_TEST_SURFACE_INSTANCE_IMPELLER_H_

#include "flutter/display_list/testing/dl_test_surface_provider.h"

#include "flutter/display_list/dl_builder.h"
#include "flutter/impeller/display_list/aiks_context.h"
#include "flutter/impeller/playground/playground_impl.h"
#include "flutter/impeller/renderer/surface.h"
#include "flutter/impeller/typographer/typographer_context.h"

namespace flutter {
namespace testing {

class DlSurfaceInstanceImpeller : public DlSurfaceInstance {
 public:
  explicit DlSurfaceInstanceImpeller(
      std::shared_ptr<impeller::Context> context,
      std::shared_ptr<impeller::Surface> surface);

  explicit DlSurfaceInstanceImpeller(
      std::shared_ptr<impeller::Context> context,
      std::shared_ptr<impeller::RenderTarget> surface);

  virtual ~DlSurfaceInstanceImpeller();

  // |DlSurfaceInstance|
  void Clear(const DlColor& color) override;

  // |DlSurfaceInstance|
  DlCanvas* GetCanvas() override;

  // |DlSurfaceInstance|
  void RenderDisplayList(const sk_sp<DisplayList>& display_list) override;

  // |DlSurfaceInstance|
  void FlushSubmitCpuSync() override;

  // |DlSurfaceInstance|
  bool SnapshotToFile(std::string& filename) const override;

  // |DlSurfaceInstance|
  int width() const override;

  // |DlSurfaceInstance|
  int height() const override;

 private:
  DisplayListBuilder builder_;
  std::shared_ptr<impeller::Context> context_;
  std::shared_ptr<impeller::Surface> surface_;
  std::shared_ptr<impeller::RenderTarget> target_holder_;
  impeller::AiksContext aiks_context_;

  inline const impeller::RenderTarget& GetRenderTarget() const;

  inline void Flush();

  void DoRenderDisplayList(const sk_sp<DisplayList>& display_list);

  static std::shared_ptr<impeller::TypographerContext> typographer_context_;
};

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_DISPLAY_LIST_TESTING_IMPELLER_DL_TEST_SURFACE_INSTANCE_IMPELLER_H_
