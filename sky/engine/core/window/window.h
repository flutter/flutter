// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_WINDOW_WINDOW_H_
#define SKY_ENGINE_CORE_WINDOW_WINDOW_H_

#include "base/time/time.h"
#include "sky/engine/tonic/dart_persistent_value.h"
#include "sky/engine/wtf/text/WTFString.h"
#include "sky/services/engine/sky_engine.mojom.h"
#include "sky/services/pointer/pointer.mojom.h"

namespace blink {
class Scene;
struct SkyDisplayMetrics;
class DartLibraryNatives;

class WindowClient {
 public:
  virtual void ScheduleFrame() = 0;
  virtual void Render(Scene* scene) = 0;

 protected:
  virtual ~WindowClient();
};

class Window {
 public:
  explicit Window(WindowClient* client);
  ~Window();

  WindowClient* client() const { return client_; }

  void DidCreateIsolate();
  void UpdateWindowMetrics(const SkyDisplayMetrics& metrics);
  void UpdateLocale(const std::string& language_code,
                    const std::string& country_code);
  void DispatchPointerPacket(const pointer::PointerPacketPtr& packet);
  void BeginFrame(base::TimeTicks frameTime);

  void PushRoute(const std::string& route);
  void PopRoute();

  void OnAppLifecycleStateChanged(sky::AppLifecycleState state);

  static void RegisterNatives(DartLibraryNatives* natives);

 private:
  WindowClient* client_;
  DartPersistentValue library_;
};

}  // namespace blink

#endif  // SKY_ENGINE_CORE_WINDOW_WINDOW_H_
