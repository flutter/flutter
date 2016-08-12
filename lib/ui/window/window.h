// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_WINDOW_WINDOW_H_
#define FLUTTER_LIB_UI_WINDOW_WINDOW_H_

#include "lib/ftl/time/time_point.h"
#include "lib/tonic/dart_persistent_value.h"
#include "flutter/services/engine/sky_engine.mojom.h"
#include "flutter/services/pointer/pointer.mojom.h"

namespace tonic {
class DartLibraryNatives;
}  // namespace tonic

namespace blink {
class Scene;

class WindowClient {
 public:
  virtual void ScheduleFrame() = 0;
  virtual void FlushRealTimeEvents() = 0;
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
  void UpdateWindowMetrics(const sky::ViewportMetricsPtr& metrics);
  void UpdateLocale(const std::string& language_code,
                    const std::string& country_code);
  void DispatchPointerPacket(const pointer::PointerPacketPtr& packet);
  void BeginFrame(ftl::TimePoint frameTime);

  void PushRoute(const std::string& route);
  void PopRoute();

  void OnAppLifecycleStateChanged(sky::AppLifecycleState state);

  static void RegisterNatives(tonic::DartLibraryNatives* natives);

 private:
  WindowClient* client_;
  tonic::DartPersistentValue library_;
};

}  // namespace blink

#endif  // FLUTTER_LIB_UI_WINDOW_WINDOW_H_
