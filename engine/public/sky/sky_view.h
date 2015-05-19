// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_PUBLIC_SKY_SKY_VIEW_H_
#define SKY_ENGINE_PUBLIC_SKY_SKY_VIEW_H_

#include <memory>
#include "skia/ext/refptr.h"
#include "sky/engine/public/platform/WebCommon.h"
#include "sky/engine/public/platform/WebURL.h"
#include "sky/engine/public/sky/sky_display_metrics.h"
#include "third_party/skia/include/core/SkPicture.h"

namespace blink {
class DartController;
class WebInputEvent;

class SkyView {
 public:
  static std::unique_ptr<SkyView> Create();
  ~SkyView();

  void SetDisplayMetrics(const SkyDisplayMetrics& metrics);
  void Load(const WebURL& url);
  skia::RefPtr<SkPicture> Paint();
  bool HandleInputEvent(const WebInputEvent& event);

 private:
  SkyView();

  std::unique_ptr<DartController> dart_controller_;

  DISALLOW_COPY_AND_ASSIGN(SkyView);
};

} // namespace blink

#endif  // SKY_ENGINE_PUBLIC_SKY_SKY_VIEW_H_
