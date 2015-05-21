// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_PUBLIC_SKY_SKY_VIEW_H_
#define SKY_ENGINE_PUBLIC_SKY_SKY_VIEW_H_

#include <memory>
#include "base/memory/weak_ptr.h"
#include "base/time/time.h"
#include "skia/ext/refptr.h"
#include "sky/engine/public/platform/WebCommon.h"
#include "sky/engine/public/platform/WebURL.h"
#include "sky/engine/public/platform/sky_display_metrics.h"
#include "third_party/skia/include/core/SkPicture.h"

namespace blink {
class DartController;
class SkyViewClient;
class WebInputEvent;

class SkyView {
 public:
  static std::unique_ptr<SkyView> Create(SkyViewClient* client);
  ~SkyView();

  void SetDisplayMetrics(const SkyDisplayMetrics& metrics);
  void Load(const WebURL& url);

  void BeginFrame(base::TimeTicks frame_time);
  skia::RefPtr<SkPicture> Paint();
  bool HandleInputEvent(const WebInputEvent& event);

 private:
  explicit SkyView(SkyViewClient* client);

  void ScheduleFrame();

  class Data;

  SkyViewClient* client_;
  SkyDisplayMetrics display_metrics_;
  std::unique_ptr<DartController> dart_controller_;
  std::unique_ptr<Data> data_;

  base::WeakPtrFactory<SkyView> weak_factory_;

  DISALLOW_COPY_AND_ASSIGN(SkyView);
};

} // namespace blink

#endif  // SKY_ENGINE_PUBLIC_SKY_SKY_VIEW_H_
