// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_DISPLAY_LIST_TESTING_SKIA_DL_TEST_SURFACE_INSTANCE_SKIA_H_
#define FLUTTER_DISPLAY_LIST_TESTING_SKIA_DL_TEST_SURFACE_INSTANCE_SKIA_H_

#include "flutter/display_list/testing/dl_test_surface_provider.h"

namespace flutter {
namespace testing {

class DlSurfaceInstanceSkiaBase : public DlSurfaceInstance {
 public:
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

  // |DlSurfaceInstance|
  sk_sp<SkSurface> sk_surface() override { return GetSurface(); }

 protected:
  explicit DlSurfaceInstanceSkiaBase();
  virtual ~DlSurfaceInstanceSkiaBase();

  virtual sk_sp<SkSurface> GetSurface() const = 0;

 private:
  DlSkCanvasAdapter adapter_;
};

class DlSurfaceInstanceSkia : public DlSurfaceInstanceSkiaBase {
 public:
  explicit DlSurfaceInstanceSkia(sk_sp<SkSurface> surface);
  ~DlSurfaceInstanceSkia();

 protected:
  sk_sp<SkSurface> GetSurface() const override;

 private:
  sk_sp<SkSurface> surface_;
};

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_DISPLAY_LIST_TESTING_SKIA_DL_TEST_SURFACE_INSTANCE_SKIA_H_
