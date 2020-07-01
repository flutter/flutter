// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_COMPOSITING_SCENE_HOST_H_
#define FLUTTER_LIB_UI_COMPOSITING_SCENE_HOST_H_

#include <lib/ui/scenic/cpp/id.h>
#include <stdint.h>
#include <zircon/types.h>
#include "third_party/tonic/dart_library_natives.h"
#include "third_party/tonic/dart_persistent_value.h"

#include "dart-pkg/zircon/sdk_ext/handle.h"
#include "flutter/fml/memory/ref_counted.h"
#include "flutter/fml/task_runner.h"
#include "flutter/lib/ui/dart_wrapper.h"

namespace flutter {

class SceneHost : public RefCountedDartWrappable<SceneHost> {
  DEFINE_WRAPPERTYPEINFO();
  FML_FRIEND_MAKE_REF_COUNTED(SceneHost);

 public:
  static void RegisterNatives(tonic::DartLibraryNatives* natives);
  static fml::RefPtr<SceneHost> Create(
      fml::RefPtr<zircon::dart::Handle> viewHolderToken,
      Dart_Handle viewConnectedCallback,
      Dart_Handle viewDisconnectedCallback,
      Dart_Handle viewStateChangedCallback);
  static void OnViewConnected(scenic::ResourceId id);
  static void OnViewDisconnected(scenic::ResourceId id);
  static void OnViewStateChanged(scenic::ResourceId id, bool state);

  ~SceneHost() override;

  zx_koid_t id() const { return koid_; }

  // These are visible to Dart.
  void dispose();
  void setProperties(double width,
                     double height,
                     double insetTop,
                     double insetRight,
                     double insetBottom,
                     double insetLeft,
                     bool focusable);

 private:
  SceneHost(fml::RefPtr<zircon::dart::Handle> viewHolderToken,
            Dart_Handle viewConnectedCallback,
            Dart_Handle viewDisconnectedCallback,
            Dart_Handle viewStateChangedCallback);

  fml::RefPtr<fml::TaskRunner> raster_task_runner_;
  tonic::DartPersistentValue view_connected_callback_;
  tonic::DartPersistentValue view_disconnected_callback_;
  tonic::DartPersistentValue view_state_changed_callback_;
  std::string isolate_service_id_;
  zx_koid_t koid_ = ZX_KOID_INVALID;
};

}  // namespace flutter

#endif  // FLUTTER_LIB_UI_COMPOSITING_SCENE_HOST_H_
