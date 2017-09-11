// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_COMPOSITING_SCENE_HOST_H_
#define FLUTTER_LIB_UI_COMPOSITING_SCENE_HOST_H_

#include <stdint.h>

#include "lib/tonic/dart_wrappable.h"

#if defined(OS_FUCHSIA)
#include "flutter/flow/export_node.h"
#endif

namespace tonic {
class DartLibraryNatives;
}  // namespace tonic

namespace blink {

class SceneHost : public fxl::RefCountedThreadSafe<SceneHost>,
                  public tonic::DartWrappable {
  DEFINE_WRAPPERTYPEINFO();
  FRIEND_MAKE_REF_COUNTED(SceneHost);

 public:
#if defined(OS_FUCHSIA)
  static fxl::RefPtr<SceneHost> create(
      fxl::RefPtr<zircon::dart::Handle> export_token_handle);
#else
  static fxl::RefPtr<SceneHost> create(Dart_Handle export_token_handle);
#endif

  ~SceneHost() override;

#if defined(OS_FUCHSIA)
  const fxl::RefPtr<flow::ExportNodeHolder>& export_node_holder() const {
    return export_node_holder_;
  }
#endif

  void dispose();

  static void RegisterNatives(tonic::DartLibraryNatives* natives);

 private:
#if defined(OS_FUCHSIA)
  fxl::RefPtr<flow::ExportNodeHolder> export_node_holder_;
#endif

#if defined(OS_FUCHSIA)
  explicit SceneHost(fxl::RefPtr<zircon::dart::Handle> export_token_handle);
#else
  explicit SceneHost(Dart_Handle export_token_handle);
#endif
};

}  // namespace blink

#endif  // FLUTTER_LIB_UI_COMPOSITING_SCENE_HOST_H_
