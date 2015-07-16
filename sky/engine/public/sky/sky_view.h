// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_PUBLIC_SKY_SKY_VIEW_H_
#define SKY_ENGINE_PUBLIC_SKY_SKY_VIEW_H_

#include <memory>

#include "base/memory/weak_ptr.h"
#include "base/time/time.h"
#include "mojo/public/cpp/system/data_pipe.h"
#include "mojo/services/network/public/interfaces/url_loader.mojom.h"
#include "skia/ext/refptr.h"
#include "sky/engine/public/platform/WebCommon.h"
#include "sky/engine/public/platform/WebURL.h"
#include "sky/engine/public/platform/sky_display_metrics.h"
#include "sky/engine/wtf/OwnPtr.h"
#include "sky/engine/wtf/RefPtr.h"
#include "sky/engine/wtf/text/WTFString.h"
#include "third_party/skia/include/core/SkPicture.h"

namespace blink {
class DartController;
class DartLibraryProvider;
class SkyViewClient;
class View;
class WebInputEvent;

class SkyView {
 public:
  static std::unique_ptr<SkyView> Create(SkyViewClient* client);
  ~SkyView();

  const SkyDisplayMetrics& display_metrics() const { return display_metrics_; }
  void SetDisplayMetrics(const SkyDisplayMetrics& metrics);
  void BeginFrame(base::TimeTicks frame_time);

  void RunFromLibrary(const WebString& name,
                      DartLibraryProvider* library_provider);
  void RunFromSnapshot(const WebString& name,
                       mojo::ScopedDataPipeConsumerHandle snapshot);

  skia::RefPtr<SkPicture> Paint();
  void HandleInputEvent(const WebInputEvent& event);

 private:
  explicit SkyView(SkyViewClient* client);

  void CreateView(const String& name);
  void ScheduleFrame();

  SkyViewClient* client_;
  SkyDisplayMetrics display_metrics_;
  RefPtr<View> view_;
  OwnPtr<DartController> dart_controller_;

  base::WeakPtrFactory<SkyView> weak_factory_;

  DISALLOW_COPY_AND_ASSIGN(SkyView);
};

} // namespace blink

#endif  // SKY_ENGINE_PUBLIC_SKY_SKY_VIEW_H_
