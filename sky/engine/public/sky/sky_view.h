// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_PUBLIC_SKY_SKY_VIEW_H_
#define SKY_ENGINE_PUBLIC_SKY_SKY_VIEW_H_

#include <memory>

#include "base/memory/weak_ptr.h"
#include "base/time/time.h"
#include "mojo/public/cpp/system/data_pipe.h"
#include "mojo/services/network/interfaces/url_loader.mojom.h"
#include "sky/compositor/layer_tree.h"
#include "sky/engine/core/window/window.h"
#include "sky/engine/public/platform/WebCommon.h"
#include "sky/engine/public/platform/WebString.h"
#include "sky/engine/public/platform/sky_display_metrics.h"
#include "sky/engine/wtf/OwnPtr.h"
#include "sky/engine/wtf/RefPtr.h"
#include "sky/engine/wtf/text/WTFString.h"
#include "sky/services/engine/sky_engine.mojom.h"
#include "sky/services/pointer/pointer.mojom.h"
#include "third_party/skia/include/core/SkPicture.h"

namespace blink {
class DartController;
class DartLibraryProvider;
class Scene;
class SkyViewClient;
class View;
class WebInputEvent;
class Window;

class SkyView : public WindowClient {
 public:
  static std::unique_ptr<SkyView> Create(SkyViewClient* client);
  ~SkyView();

  const SkyDisplayMetrics& display_metrics() const { return display_metrics_; }
  void SetDisplayMetrics(const SkyDisplayMetrics& metrics);
  void SetLocale(const std::string& language_code,
		 const std::string& country_code);
  void PushRoute(const std::string& route);
  void PopRoute();

  std::unique_ptr<sky::compositor::LayerTree> BeginFrame(
      base::TimeTicks frame_time);

  void CreateView(const String& name);

  void RunFromLibrary(const WebString& name,
                      DartLibraryProvider* library_provider);
  void RunFromPrecompiledSnapshot();
  void RunFromSnapshot(const WebString& name,
                       mojo::ScopedDataPipeConsumerHandle snapshot);

  void HandlePointerPacket(const pointer::PointerPacketPtr& packet);

  void OnAppLifecycleStateChanged(sky::AppLifecycleState state);

 private:
  explicit SkyView(SkyViewClient* client);

  Window* GetWindow();

  void ScheduleFrame() override;
  void Render(Scene* scene) override;

  SkyViewClient* client_;
  SkyDisplayMetrics display_metrics_;
  std::string language_code_;
  std::string country_code_;
  std::unique_ptr<DartController> dart_controller_;
  std::unique_ptr<sky::compositor::LayerTree> layer_tree_;

  base::WeakPtrFactory<SkyView> weak_factory_;

  DISALLOW_COPY_AND_ASSIGN(SkyView);
};

} // namespace blink

#endif  // SKY_ENGINE_PUBLIC_SKY_SKY_VIEW_H_
