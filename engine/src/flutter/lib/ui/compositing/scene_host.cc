// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/compositing/scene_host.h"

#include <lib/fsl/handles/object_info.h>
#include <lib/ui/scenic/cpp/view_token_pair.h>
#include <lib/zx/eventpair.h>
#include <third_party/tonic/dart_args.h>
#include <third_party/tonic/dart_binding_macros.h>
#include <third_party/tonic/logging/dart_invoke.h>

#include "flutter/flow/export_node.h"
#include "flutter/flow/view_holder.h"
#include "flutter/fml/thread_local.h"
#include "flutter/lib/ui/ui_dart_state.h"

namespace {

using SceneHostBindings = std::unordered_map<zx_koid_t, blink::SceneHost*>;

FML_THREAD_LOCAL fml::ThreadLocal tls_scene_host_bindings([](intptr_t value) {
  delete reinterpret_cast<SceneHostBindings*>(value);
});

void SceneHost_constructor(Dart_NativeArguments args) {
  tonic::DartCallConstructor(&blink::SceneHost::Create, args);
}

void SceneHost_constructorViewHolderToken(Dart_NativeArguments args) {
  // This UI thread / Isolate contains at least 1 SceneHost.  Initialize the
  // per-Isolate bindings.
  if (tls_scene_host_bindings.Get() == 0) {
    tls_scene_host_bindings.Set(
        reinterpret_cast<intptr_t>(new SceneHostBindings()));
  }

  tonic::DartCallConstructor(&blink::SceneHost::CreateViewHolder, args);
}

blink::SceneHost* GetSceneHost(scenic::ResourceId id) {
  auto* bindings =
      reinterpret_cast<SceneHostBindings*>(tls_scene_host_bindings.Get());
  FML_DCHECK(bindings);

  auto binding = bindings->find(id);
  if (binding != bindings->end()) {
    return binding->second;
  }

  return nullptr;
}

void InvokeDartClosure(tonic::DartPersistentValue* closure) {
  if (closure) {
    std::shared_ptr<tonic::DartState> dart_state = closure->dart_state().lock();
    if (!dart_state) {
      return;
    }

    tonic::DartState::Scope scope(dart_state);
    tonic::DartInvoke(closure->value(), {});
  }
}

template <typename T>
void InvokeDartFunction(tonic::DartPersistentValue* function, T& arg) {
  if (function) {
    std::shared_ptr<tonic::DartState> dart_state =
        function->dart_state().lock();
    if (!dart_state) {
      return;
    }

    tonic::DartState::Scope scope(dart_state);
    tonic::DartInvoke(function->value(), {tonic::ToDart(arg)});
  }
}

}  // namespace

namespace blink {

IMPLEMENT_WRAPPERTYPEINFO(ui, SceneHost);

#define FOR_EACH_BINDING(V) \
  V(SceneHost, dispose)     \
  V(SceneHost, setProperties)

FOR_EACH_BINDING(DART_NATIVE_CALLBACK)

void SceneHost::RegisterNatives(tonic::DartLibraryNatives* natives) {
  natives->Register({{"SceneHost_constructor", SceneHost_constructor, 2, true},
                     FOR_EACH_BINDING(DART_REGISTER_NATIVE)});
  natives->Register({{"SceneHost_constructorViewHolderToken",
                      SceneHost_constructorViewHolderToken, 5, true},
                     FOR_EACH_BINDING(DART_REGISTER_NATIVE)});
}

fml::RefPtr<SceneHost> SceneHost::Create(
    fml::RefPtr<zircon::dart::Handle> exportTokenHandle) {
  return fml::MakeRefCounted<SceneHost>(exportTokenHandle);
}

fml::RefPtr<SceneHost> SceneHost::CreateViewHolder(
    fml::RefPtr<zircon::dart::Handle> viewHolderTokenHandle,
    Dart_Handle viewConnectedCallback,
    Dart_Handle viewDisconnectedCallback,
    Dart_Handle viewStateChangedCallback) {
  return fml::MakeRefCounted<SceneHost>(
      viewHolderTokenHandle, viewConnectedCallback, viewDisconnectedCallback,
      viewStateChangedCallback);
}

SceneHost::SceneHost(fml::RefPtr<zircon::dart::Handle> exportTokenHandle)
    : gpu_task_runner_(
          UIDartState::Current()->GetTaskRunners().GetGPUTaskRunner()),
      id_(fsl::GetKoid(exportTokenHandle->handle())),
      use_view_holder_(false) {
  gpu_task_runner_->PostTask(
      [id = id_, handle = std::move(exportTokenHandle)]() {
        auto export_token = zx::eventpair(handle->ReleaseHandle());
        flow::ExportNode::Create(id, std::move(export_token));
      });
}

SceneHost::SceneHost(fml::RefPtr<zircon::dart::Handle> viewHolderTokenHandle,
                     Dart_Handle viewConnectedCallback,
                     Dart_Handle viewDisconnectedCallback,
                     Dart_Handle viewStateChangedCallback)
    : gpu_task_runner_(
          UIDartState::Current()->GetTaskRunners().GetGPUTaskRunner()),
      id_(fsl::GetKoid(viewHolderTokenHandle->handle())),
      use_view_holder_(true) {
  if (Dart_IsClosure(viewConnectedCallback)) {
    view_connected_callback_ = std::make_unique<tonic::DartPersistentValue>(
        UIDartState::Current(), viewConnectedCallback);
  }
  if (Dart_IsClosure(viewDisconnectedCallback)) {
    view_disconnected_callback_ = std::make_unique<tonic::DartPersistentValue>(
        UIDartState::Current(), viewDisconnectedCallback);
  }
  if (Dart_IsClosure(viewConnectedCallback)) {
    view_state_changed_callback_ = std::make_unique<tonic::DartPersistentValue>(
        UIDartState::Current(), viewStateChangedCallback);
  }

  auto bind_callback = [scene_host = this](scenic::ResourceId id) {
    auto* bindings =
        reinterpret_cast<SceneHostBindings*>(tls_scene_host_bindings.Get());
    FML_DCHECK(bindings);
    FML_DCHECK(bindings->find(id) == bindings->end());

    bindings->emplace(std::make_pair(id, scene_host));
  };

  auto ui_task_runner =
      UIDartState::Current()->GetTaskRunners().GetUITaskRunner();
  gpu_task_runner_->PostTask([id = id_,
                              ui_task_runner = std::move(ui_task_runner),
                              handle = std::move(viewHolderTokenHandle),
                              bind_callback = std::move(bind_callback)]() {
    auto view_holder_token =
        scenic::ToViewHolderToken(zx::eventpair(handle->ReleaseHandle()));
    flow::ViewHolder::Create(id, std::move(ui_task_runner),
                             std::move(view_holder_token),
                             std::move(bind_callback));
  });
}

SceneHost::~SceneHost() {
  if (use_view_holder_) {
    auto* bindings =
        reinterpret_cast<SceneHostBindings*>(tls_scene_host_bindings.Get());
    FML_DCHECK(bindings);
    bindings->erase(id_);

    gpu_task_runner_->PostTask([id = id_]() { flow::ViewHolder::Destroy(id); });
  } else {
    gpu_task_runner_->PostTask([id = id_]() { flow::ExportNode::Destroy(id); });
  }
}

void SceneHost::OnViewConnected(scenic::ResourceId id) {
  auto* scene_host = GetSceneHost(id);

  if (scene_host) {
    InvokeDartClosure(scene_host->view_connected_callback_.get());
  }
}

void SceneHost::OnViewDisconnected(scenic::ResourceId id) {
  auto* scene_host = GetSceneHost(id);

  if (scene_host) {
    InvokeDartClosure(scene_host->view_disconnected_callback_.get());
  }
}

void SceneHost::OnViewStateChanged(scenic::ResourceId id, bool state) {
  auto* scene_host = GetSceneHost(id);

  if (scene_host) {
    InvokeDartFunction(scene_host->view_state_changed_callback_.get(), state);
  }
}

void SceneHost::setProperties(double width,
                              double height,
                              double insetTop,
                              double insetRight,
                              double insetBottom,
                              double insetLeft,
                              bool focusable) {
  FML_DCHECK(use_view_holder_);

  gpu_task_runner_->PostTask([id = id_, width, height, insetTop, insetRight,
                              insetBottom, insetLeft, focusable]() {
    auto* view_holder = flow::ViewHolder::FromId(id);
    FML_DCHECK(view_holder);

    view_holder->SetProperties(width, height, insetTop, insetRight, insetBottom,
                               insetLeft, focusable);
  });
}

void SceneHost::dispose() {
  ClearDartWrapper();
}

}  // namespace blink
