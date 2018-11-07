// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_COMPOSITING_SCENE_HOST_H_
#define FLUTTER_LIB_UI_COMPOSITING_SCENE_HOST_H_

#include <stdint.h>

#include "flutter/fml/build_config.h"
#include "flutter/lib/ui/dart_wrapper.h"

#if defined(OS_FUCHSIA)
#include "flutter/flow/export_node.h"
#endif

namespace tonic {
class DartLibraryNatives;
}  // namespace tonic

namespace blink {

class SceneHost : public RefCountedDartWrappable<SceneHost> {
  DEFINE_WRAPPERTYPEINFO();
  FML_FRIEND_MAKE_REF_COUNTED(SceneHost);

 public:
#if defined(OS_FUCHSIA)
  static fml::RefPtr<SceneHost> create(
      fml::RefPtr<zircon::dart::Handle> export_token_handle);
#else
  static fml::RefPtr<SceneHost> create(Dart_Handle export_token_handle);
#endif

  ~SceneHost() override;

#if defined(OS_FUCHSIA)
  const fml::RefPtr<flow::ExportNodeHolder>& export_node_holder() const {
    return export_node_holder_;
  }
#endif

  void dispose();

  static void RegisterNatives(tonic::DartLibraryNatives* natives);

 private:
#if defined(OS_FUCHSIA)
  fml::RefPtr<flow::ExportNodeHolder> export_node_holder_;
#endif

#if defined(OS_FUCHSIA)
  explicit SceneHost(fml::RefPtr<zircon::dart::Handle> export_token_handle);
#else
  explicit SceneHost(Dart_Handle export_token_handle);
#endif
};

}  // namespace blink

#endif  // FLUTTER_LIB_UI_COMPOSITING_SCENE_HOST_H_
