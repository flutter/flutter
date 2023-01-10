// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/scene/scene_node.h"

#include <memory>
#include <sstream>

#include "flutter/assets/asset_manager.h"
#include "flutter/fml/make_copyable.h"
#include "flutter/fml/trace_event.h"
#include "flutter/lib/ui/dart_wrapper.h"
#include "flutter/lib/ui/painting/scene/scene_shader.h"
#include "flutter/lib/ui/ui_dart_state.h"
#include "flutter/lib/ui/window/platform_configuration.h"
#include "impeller/geometry/matrix.h"
#include "impeller/scene/animation/property_resolver.h"

#include "third_party/tonic/converter/dart_converter.h"
#include "third_party/tonic/dart_args.h"
#include "third_party/tonic/dart_binding_macros.h"
#include "third_party/tonic/dart_library_natives.h"

namespace flutter {

IMPLEMENT_WRAPPERTYPEINFO(ui, SceneNode);

void SceneNode::Create(Dart_Handle wrapper) {
  auto res = fml::MakeRefCounted<SceneNode>();
  res->AssociateWithDartWrapper(wrapper);
}

std::string SceneNode::initFromAsset(const std::string& asset_name,
                                     Dart_Handle completion_callback_handle) {
  FML_TRACE_EVENT("flutter", "SceneNode::initFromAsset", "asset", asset_name);

  if (!Dart_IsClosure(completion_callback_handle)) {
    return "Completion callback must be a function.";
  }

  auto dart_state = UIDartState::Current();
  if (!dart_state->IsImpellerEnabled()) {
    return "3D scenes require the Impeller rendering backend to be enabled.";
  }

  std::shared_ptr<AssetManager> asset_manager =
      dart_state->platform_configuration()->client()->GetAssetManager();
  std::unique_ptr<fml::Mapping> data = asset_manager->GetAsMapping(asset_name);
  if (data == nullptr) {
    return std::string("Asset '") + asset_name + std::string("' not found.");
  }

  auto& task_runners = dart_state->GetTaskRunners();

  std::promise<std::shared_ptr<impeller::Context>> context_promise;
  auto impeller_context_promise = context_promise.get_future();
  task_runners.GetIOTaskRunner()->PostTask(
      fml::MakeCopyable([promise = std::move(context_promise),
                         io_manager = dart_state->GetIOManager()]() mutable {
        promise.set_value(io_manager ? io_manager->GetImpellerContext()
                                     : nullptr);
      }));

  auto persistent_completion_callback =
      std::make_unique<tonic::DartPersistentValue>(dart_state,
                                                   completion_callback_handle);

  auto ui_task = fml::MakeCopyable(
      [this, callback = std::move(persistent_completion_callback)](
          std::shared_ptr<impeller::scene::Node> node) mutable {
        auto dart_state = callback->dart_state().lock();
        if (!dart_state) {
          // The root isolate could have died in the meantime.
          return;
        }
        tonic::DartState::Scope scope(dart_state);

        node_ = std::move(node);
        tonic::DartInvoke(callback->Get(), {Dart_TypeVoid()});

        // callback is associated with the Dart isolate and must be
        // deleted on the UI thread.
        callback.reset();
      });

  task_runners.GetRasterTaskRunner()->PostTask(
      fml::MakeCopyable([ui_task = std::move(ui_task), task_runners,
                         impeller_context = impeller_context_promise.get(),
                         data = std::move(data)]() {
        auto node = impeller::scene::Node::MakeFromFlatbuffer(
            *data, *impeller_context->GetResourceAllocator());

        task_runners.GetUITaskRunner()->PostTask(
            [ui_task, node = std::move(node)]() { ui_task(node); });
      }));

  return "";
}

void SceneNode::initFromTransform(const tonic::Float64List& matrix4) {
  node_ = std::make_shared<impeller::scene::Node>();
  node_->SetLocalTransform(
      impeller::Matrix(matrix4[0], matrix4[1], matrix4[2], matrix4[3],    //
                       matrix4[4], matrix4[5], matrix4[6], matrix4[7],    //
                       matrix4[8], matrix4[9], matrix4[10], matrix4[11],  //
                       matrix4[12], matrix4[13], matrix4[14], matrix4[15]));
}

void SceneNode::AddChild(Dart_Handle scene_node_handle) {
  if (!node_) {
    return;
  }
  auto* scene_node =
      tonic::DartConverter<SceneNode*>::FromDart(scene_node_handle);
  if (!scene_node) {
    return;
  }
  node_->AddChild(scene_node->node_);
  children_.push_back(fml::Ref(scene_node));
}

void SceneNode::SetTransform(const tonic::Float64List& matrix4) {
  // TODO(bdero): Implement mutation log.
}

void SceneNode::SetAnimationState(const std::string& animation_name,
                                  bool playing,
                                  double weight,
                                  double time_scale) {
  // TODO(bdero): Implement mutation log.
}

void SceneNode::SeekAnimation(const std::string& animation_name, double time) {
  // TODO(bdero): Implement mutation log.
}

SceneNode::SceneNode() = default;

SceneNode::~SceneNode() = default;

}  // namespace flutter
