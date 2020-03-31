// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/compositing/scene_host.h"

#include <lib/ui/scenic/cpp/view_token_pair.h>
#include <lib/zx/eventpair.h>
#include <third_party/tonic/dart_args.h>
#include <third_party/tonic/dart_binding_macros.h>
#include <third_party/tonic/logging/dart_invoke.h>

#include "flutter/flow/view_holder.h"
#include "flutter/fml/thread_local.h"
#include "flutter/lib/ui/ui_dart_state.h"
#include "third_party/dart/runtime/include/dart_api.h"

namespace {

struct SceneHostBindingKey {
  std::string isolate_service_id;
  zx_koid_t koid;

  SceneHostBindingKey(const zx_koid_t koid,
                      const std::string isolate_service_id) {
    this->koid = koid;
    this->isolate_service_id = isolate_service_id;
  }

  bool operator==(const SceneHostBindingKey& other) const {
    return isolate_service_id == other.isolate_service_id && koid == other.koid;
  }
};

struct SceneHostBindingKeyHasher {
  std::size_t operator()(const SceneHostBindingKey& key) const {
    std::size_t koid_hash = std::hash<zx_koid_t>()(key.koid);
    std::size_t isolate_hash = std::hash<std::string>()(key.isolate_service_id);
    return koid_hash ^ isolate_hash;
  }
};

using SceneHostBindings = std::unordered_map<SceneHostBindingKey,
                                             flutter::SceneHost*,
                                             SceneHostBindingKeyHasher>;

static SceneHostBindings scene_host_bindings;

void SceneHost_constructor(Dart_NativeArguments args) {
  tonic::DartCallConstructor(&flutter::SceneHost::Create, args);
}

flutter::SceneHost* GetSceneHost(scenic::ResourceId id,
                                 std::string isolate_service_id) {
  auto binding =
      scene_host_bindings.find(SceneHostBindingKey(id, isolate_service_id));
  if (binding == scene_host_bindings.end()) {
    return nullptr;
  } else {
    return binding->second;
  }
}

flutter::SceneHost* GetSceneHostForCurrentIsolate(scenic::ResourceId id) {
  auto isolate = Dart_CurrentIsolate();
  if (!isolate) {
    return nullptr;
  } else {
    std::string isolate_service_id = Dart_IsolateServiceId(isolate);
    return GetSceneHost(id, isolate_service_id);
  }
}

void InvokeDartClosure(const tonic::DartPersistentValue& closure) {
  auto dart_state = closure.dart_state().lock();
  if (!dart_state) {
    return;
  }

  tonic::DartState::Scope scope(dart_state);
  auto dart_handle = closure.value();

  FML_DCHECK(dart_handle && !Dart_IsNull(dart_handle) &&
             Dart_IsClosure(dart_handle));
  tonic::DartInvoke(dart_handle, {});
}

template <typename T>
void InvokeDartFunction(const tonic::DartPersistentValue& function, T& arg) {
  auto dart_state = function.dart_state().lock();
  if (!dart_state) {
    return;
  }

  tonic::DartState::Scope scope(dart_state);
  auto dart_handle = function.value();

  FML_DCHECK(dart_handle && !Dart_IsNull(dart_handle) &&
             Dart_IsClosure(dart_handle));
  tonic::DartInvoke(dart_handle, {tonic::ToDart(arg)});
}

zx_koid_t GetKoid(zx_handle_t handle) {
  zx_info_handle_basic_t info;
  zx_status_t status = zx_object_get_info(handle, ZX_INFO_HANDLE_BASIC, &info,
                                          sizeof(info), nullptr, nullptr);
  return status == ZX_OK ? info.koid : ZX_KOID_INVALID;
}

}  // namespace

namespace flutter {

IMPLEMENT_WRAPPERTYPEINFO(ui, SceneHost);

#define FOR_EACH_BINDING(V) \
  V(SceneHost, dispose)     \
  V(SceneHost, setProperties)

FOR_EACH_BINDING(DART_NATIVE_CALLBACK)

void SceneHost::RegisterNatives(tonic::DartLibraryNatives* natives) {
  natives->Register({{"SceneHost_constructor", SceneHost_constructor, 5, true},
                     FOR_EACH_BINDING(DART_REGISTER_NATIVE)});
}

fml::RefPtr<SceneHost> SceneHost::Create(
    fml::RefPtr<zircon::dart::Handle> viewHolderToken,
    Dart_Handle viewConnectedCallback,
    Dart_Handle viewDisconnectedCallback,
    Dart_Handle viewStateChangedCallback) {
  return fml::MakeRefCounted<SceneHost>(viewHolderToken, viewConnectedCallback,
                                        viewDisconnectedCallback,
                                        viewStateChangedCallback);
}

void SceneHost::OnViewConnected(scenic::ResourceId id) {
  auto* scene_host = GetSceneHostForCurrentIsolate(id);

  if (scene_host && !scene_host->view_connected_callback_.is_empty()) {
    InvokeDartClosure(scene_host->view_connected_callback_);
  }
}

void SceneHost::OnViewDisconnected(scenic::ResourceId id) {
  auto* scene_host = GetSceneHostForCurrentIsolate(id);

  if (scene_host && !scene_host->view_disconnected_callback_.is_empty()) {
    InvokeDartClosure(scene_host->view_disconnected_callback_);
  }
}

void SceneHost::OnViewStateChanged(scenic::ResourceId id, bool state) {
  auto* scene_host = GetSceneHostForCurrentIsolate(id);

  if (scene_host && !scene_host->view_state_changed_callback_.is_empty()) {
    InvokeDartFunction(scene_host->view_state_changed_callback_, state);
  }
}

SceneHost::SceneHost(fml::RefPtr<zircon::dart::Handle> viewHolderToken,
                     Dart_Handle viewConnectedCallback,
                     Dart_Handle viewDisconnectedCallback,
                     Dart_Handle viewStateChangedCallback)
    : raster_task_runner_(
          UIDartState::Current()->GetTaskRunners().GetRasterTaskRunner()),
      koid_(GetKoid(viewHolderToken->handle())) {
  auto dart_state = UIDartState::Current();
  isolate_service_id_ = Dart_IsolateServiceId(Dart_CurrentIsolate());

  // Initialize callbacks it they are non-null in Dart.
  if (!Dart_IsNull(viewConnectedCallback)) {
    view_connected_callback_.Set(dart_state, viewConnectedCallback);
  }
  if (!Dart_IsNull(viewDisconnectedCallback)) {
    view_disconnected_callback_.Set(dart_state, viewDisconnectedCallback);
  }
  if (!Dart_IsNull(viewStateChangedCallback)) {
    view_state_changed_callback_.Set(dart_state, viewStateChangedCallback);
  }

  // This callback will be posted as a task  when the |scenic::ViewHolder|
  // resource is created and given an id by the raster thread.
  auto bind_callback = [scene_host = this,
                        isolate_service_id =
                            isolate_service_id_](scenic::ResourceId id) {
    const auto key = SceneHostBindingKey(id, isolate_service_id);
    scene_host_bindings.emplace(std::make_pair(key, scene_host));
  };

  // Pass the raw handle to the raster thread; destroying a
  // |zircon::dart::Handle| on that thread can cause a race condition.
  raster_task_runner_->PostTask(
      [id = koid_,
       ui_task_runner =
           UIDartState::Current()->GetTaskRunners().GetUITaskRunner(),
       raw_handle = viewHolderToken->ReleaseHandle(), bind_callback]() {
        flutter::ViewHolder::Create(
            id, std::move(ui_task_runner),
            scenic::ToViewHolderToken(zx::eventpair(raw_handle)),
            std::move(bind_callback));
      });
}

SceneHost::~SceneHost() {
  scene_host_bindings.erase(SceneHostBindingKey(koid_, isolate_service_id_));

  raster_task_runner_->PostTask(
      [id = koid_]() { flutter::ViewHolder::Destroy(id); });
}

void SceneHost::dispose() {
  ClearDartWrapper();
}

void SceneHost::setProperties(double width,
                              double height,
                              double insetTop,
                              double insetRight,
                              double insetBottom,
                              double insetLeft,
                              bool focusable) {
  raster_task_runner_->PostTask([id = koid_, width, height, insetTop,
                                 insetRight, insetBottom, insetLeft,
                                 focusable]() {
    auto* view_holder = flutter::ViewHolder::FromId(id);
    FML_DCHECK(view_holder);

    view_holder->SetProperties(width, height, insetTop, insetRight, insetBottom,
                               insetLeft, focusable);
  });
}

}  // namespace flutter
