// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_COMPOSITING_SCENE_HOST_H_
#define FLUTTER_LIB_UI_COMPOSITING_SCENE_HOST_H_

#include <dart-pkg/zircon/sdk_ext/handle.h>
#include <lib/ui/scenic/cpp/id.h>
#include <stdint.h>
#include <third_party/tonic/dart_library_natives.h>
#include <third_party/tonic/dart_persistent_value.h>
#include <zircon/types.h>

#include "flutter/fml/memory/ref_counted.h"
#include "flutter/fml/task_runner.h"
#include "flutter/lib/ui/dart_wrapper.h"

namespace blink {

class SceneHost : public RefCountedDartWrappable<SceneHost> {
  DEFINE_WRAPPERTYPEINFO();
  FML_FRIEND_MAKE_REF_COUNTED(SceneHost);

 public:
  ~SceneHost() override;

  static void RegisterNatives(tonic::DartLibraryNatives* natives);
  static fml::RefPtr<SceneHost> Create(
      fml::RefPtr<zircon::dart::Handle> exportTokenHandle);
  static fml::RefPtr<SceneHost> CreateViewHolder(
      fml::RefPtr<zircon::dart::Handle> viewHolderTokenHandle,
      Dart_Handle viewConnectedCallback,
      Dart_Handle viewDisconnectedCallback,
      Dart_Handle viewStateChangedCallback);
  static void OnViewConnected(scenic::ResourceId id);
  static void OnViewDisconnected(scenic::ResourceId id);
  static void OnViewStateChanged(scenic::ResourceId id, bool state);

  zx_koid_t id() const { return id_; }
  bool use_view_holder() const { return use_view_holder_; }

  void setProperties(double width,
                     double height,
                     double insetTop,
                     double insetRight,
                     double insetBottom,
                     double insetLeft,
                     bool focusable);
  void dispose();

 private:
  explicit SceneHost(fml::RefPtr<zircon::dart::Handle> exportTokenHandle);
  SceneHost(fml::RefPtr<zircon::dart::Handle> viewHolderTokenHandle,
            Dart_Handle viewConnectedCallback,
            Dart_Handle viewDisconnectedCallback,
            Dart_Handle viewStateChangedCallback);

  fml::RefPtr<fml::TaskRunner> gpu_task_runner_;
  std::unique_ptr<tonic::DartPersistentValue> view_connected_callback_;
  std::unique_ptr<tonic::DartPersistentValue> view_disconnected_callback_;
  std::unique_ptr<tonic::DartPersistentValue> view_state_changed_callback_;
  zx_koid_t id_ = ZX_KOID_INVALID;
  bool use_view_holder_ = false;
};

}  // namespace blink

#endif  // FLUTTER_LIB_UI_COMPOSITING_SCENE_HOST_H_
