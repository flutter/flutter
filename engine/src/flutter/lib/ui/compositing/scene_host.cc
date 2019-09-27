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

namespace {

using SceneHostBindings = std::unordered_map<zx_koid_t, flutter::SceneHost*>;

FML_THREAD_LOCAL fml::ThreadLocalUniquePtr<SceneHostBindings>
    tls_scene_host_bindings;

void SceneHost_constructor(Dart_NativeArguments args) {
  // This UI thread / Isolate contains at least 1 SceneHost.  Initialize the
  // per-Isolate bindings.
  if (tls_scene_host_bindings.get() == nullptr) {
    tls_scene_host_bindings.reset(new SceneHostBindings());
  }

  tonic::DartCallConstructor(&flutter::SceneHost::Create, args);
}

flutter::SceneHost* GetSceneHost(scenic::ResourceId id) {
  auto* bindings = tls_scene_host_bindings.get();
  FML_DCHECK(bindings);

  auto binding = bindings->find(id);
  if (binding != bindings->end()) {
    return binding->second;
  }

  return nullptr;
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

#define FOR_EACH_BINDING(V)   \
  V(SceneHost, dispose)       \
  V(SceneHost, setProperties) \
  V(SceneHost, setOpacity)

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
  auto* scene_host = GetSceneHost(id);

  if (scene_host && !scene_host->view_connected_callback_.is_empty()) {
    InvokeDartClosure(scene_host->view_connected_callback_);
  }
}

void SceneHost::OnViewDisconnected(scenic::ResourceId id) {
  auto* scene_host = GetSceneHost(id);

  if (scene_host && !scene_host->view_disconnected_callback_.is_empty()) {
    InvokeDartClosure(scene_host->view_disconnected_callback_);
  }
}

void SceneHost::OnViewStateChanged(scenic::ResourceId id, bool state) {
  auto* scene_host = GetSceneHost(id);

  if (scene_host && !scene_host->view_state_changed_callback_.is_empty()) {
    InvokeDartFunction(scene_host->view_state_changed_callback_, state);
  }
}

SceneHost::SceneHost(fml::RefPtr<zircon::dart::Handle> viewHolderToken,
                     Dart_Handle viewConnectedCallback,
                     Dart_Handle viewDisconnectedCallback,
                     Dart_Handle viewStateChangedCallback)
    : gpu_task_runner_(
          UIDartState::Current()->GetTaskRunners().GetGPUTaskRunner()),
      koid_(GetKoid(viewHolderToken->handle())) {
  auto dart_state = UIDartState::Current();

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
  // resource is created and given an id by the GPU thread.
  auto bind_callback = [scene_host = this](scenic::ResourceId id) {
    auto* bindings = tls_scene_host_bindings.get();
    FML_DCHECK(bindings);
    FML_DCHECK(bindings->find(id) == bindings->end());

    bindings->emplace(std::make_pair(id, scene_host));
  };

  // Pass the raw handle to the GPU thead; destroying a |zircon::dart::Handle|
  // on that thread can cause a race condition.
  gpu_task_runner_->PostTask(
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
  auto* bindings = tls_scene_host_bindings.get();
  FML_DCHECK(bindings);
  bindings->erase(koid_);

  gpu_task_runner_->PostTask(
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
  gpu_task_runner_->PostTask([id = koid_, width, height, insetTop, insetRight,
                              insetBottom, insetLeft, focusable]() {
    auto* view_holder = flutter::ViewHolder::FromId(id);
    FML_DCHECK(view_holder);

    view_holder->SetProperties(width, height, insetTop, insetRight, insetBottom,
                               insetLeft, focusable);
  });
}

void SceneHost::setOpacity(double opacity) {
  gpu_task_runner_->PostTask([id = koid_, opacity]() {
    auto* view_holder = flutter::ViewHolder::FromId(id);
    FML_DCHECK(view_holder);

    view_holder->SetOpacity(opacity);
  });
}

}  // namespace flutter
