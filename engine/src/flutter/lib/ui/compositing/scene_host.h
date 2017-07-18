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

class SceneHost : public ftl::RefCountedThreadSafe<SceneHost>,
                  public tonic::DartWrappable {
  DEFINE_WRAPPERTYPEINFO();
  FRIEND_MAKE_REF_COUNTED(SceneHost);

 public:
  static ftl::RefPtr<SceneHost> create(int export_token_handle);

  ~SceneHost() override;

#if defined(OS_FUCHSIA)
  const ftl::RefPtr<flow::ExportNode>& exportNode() const {
    return export_node_;
  }
#endif

  void dispose();

  static void RegisterNatives(tonic::DartLibraryNatives* natives);

 private:
#if defined(OS_FUCHSIA)
  ftl::RefPtr<flow::ExportNode> export_node_;
#endif

  explicit SceneHost(int export_token_handle);
};

}  // namespace blink

#endif  // FLUTTER_LIB_UI_COMPOSITING_SCENE_HOST_H_
