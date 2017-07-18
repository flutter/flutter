// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/compositing/scene_host.h"

#include "lib/tonic/dart_args.h"
#include "lib/tonic/dart_binding_macros.h"
#include "lib/tonic/dart_library_natives.h"

namespace blink {

static void SceneHost_constructor(Dart_NativeArguments args) {
  DartCallConstructor(&SceneHost::create, args);
}

IMPLEMENT_WRAPPERTYPEINFO(ui, SceneHost);

#define FOR_EACH_BINDING(V) V(SceneHost, dispose)

FOR_EACH_BINDING(DART_NATIVE_CALLBACK)

void SceneHost::RegisterNatives(tonic::DartLibraryNatives* natives) {
  natives->Register({{"SceneHost_constructor", SceneHost_constructor, 2, true},
                     FOR_EACH_BINDING(DART_REGISTER_NATIVE)});
}

ftl::RefPtr<SceneHost> SceneHost::create(int export_token_handle) {
  return ftl::MakeRefCounted<SceneHost>(export_token_handle);
}

SceneHost::SceneHost(int export_token_handle) {
#if defined(OS_FUCHSIA)
  export_node_ = ftl::MakeRefCounted<flow::ExportNode>(export_token_handle);
#endif
}

SceneHost::~SceneHost() {}

void SceneHost::dispose() {
  ClearDartWrapper();
}

}  // namespace blink
