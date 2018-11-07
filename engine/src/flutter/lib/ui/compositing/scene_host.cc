// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/compositing/scene_host.h"

#include "flutter/lib/ui/ui_dart_state.h"
#include "third_party/tonic/dart_args.h"
#include "third_party/tonic/dart_binding_macros.h"
#include "third_party/tonic/dart_library_natives.h"

#ifdef OS_FUCHSIA
#include "dart-pkg/zircon/sdk_ext/handle.h"
#endif

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

#if defined(OS_FUCHSIA)
fml::RefPtr<SceneHost> SceneHost::create(
    fml::RefPtr<zircon::dart::Handle> export_token_handle) {
  return fml::MakeRefCounted<SceneHost>(export_token_handle);
}

SceneHost::SceneHost(fml::RefPtr<zircon::dart::Handle> export_token_handle) {
  export_node_holder_ = fml::MakeRefCounted<flow::ExportNodeHolder>(
      blink::UIDartState::Current()->GetTaskRunners().GetGPUTaskRunner(),
      export_token_handle);
}
#else
fml::RefPtr<SceneHost> SceneHost::create(Dart_Handle export_token_handle) {
  return fml::MakeRefCounted<SceneHost>(export_token_handle);
}

SceneHost::SceneHost(Dart_Handle export_token_handle) {}
#endif

SceneHost::~SceneHost() {}

void SceneHost::dispose() {
  ClearDartWrapper();
}

}  // namespace blink
