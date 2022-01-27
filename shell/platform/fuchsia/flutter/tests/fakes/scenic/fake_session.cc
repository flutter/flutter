// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "fake_session.h"

#include <zircon/types.h>

#include <algorithm>  // For remove_if
#include <iterator>   // For make_move_iterator
#include <memory>

#include "flutter/fml/logging.h"
#include "flutter/shell/platform/fuchsia/flutter/tests/fakes/scenic/fake_resources.h"
#include "fuchsia/images/cpp/fidl.h"

namespace flutter_runner::testing {
namespace {

template <typename T>
constexpr bool is_node_v = std::is_same_v<T, FakeEntityNodeState> ||
                           std::is_same_v<T, FakeOpacityNodeState> ||
                           std::is_same_v<T, FakeShapeNodeState> ||
                           std::is_same_v<T, FakeViewHolderState>;

template <typename T>
bool ResourceIs(const FakeResourceState& resource) {
  return std::holds_alternative<T>(resource.state);
}

bool ResourceIsNode(const FakeResourceState& resource) {
  return ResourceIs<FakeEntityNodeState>(resource) ||
         ResourceIs<FakeOpacityNodeState>(resource) ||
         ResourceIs<FakeShapeNodeState>(resource) ||
         ResourceIs<FakeViewHolderState>(resource);
}

zx_koid_t GetKoid(zx_handle_t handle) {
  if (handle == ZX_HANDLE_INVALID) {
    return ZX_KOID_INVALID;
  }

  zx_info_handle_basic_t info;
  zx_status_t status = zx_object_get_info(handle, ZX_INFO_HANDLE_BASIC, &info,
                                          sizeof(info), nullptr, nullptr);
  return status == ZX_OK ? info.koid : ZX_KOID_INVALID;
}

}  // namespace

FakeSession::FakeSession() : binding_(this) {}

FakeSession::SessionAndListenerClientPair FakeSession::Bind(
    async_dispatcher_t* dispatcher) {
  FML_CHECK(!listener_.is_bound());
  FML_CHECK(!binding_.is_bound());

  fidl::InterfaceHandle<fuchsia::ui::scenic::Session> session;
  auto listener_request = listener_.NewRequest(dispatcher);
  binding_.Bind(session.NewRequest(), dispatcher);

  return std::make_pair(std::move(session), std::move(listener_request));
}

void FakeSession::SetPresentHandler(PresentHandler present_handler) {
  present_handler_ = std::move(present_handler);
}

void FakeSession::SetPresent2Handler(Present2Handler present2_handler) {
  present2_handler_ = std::move(present2_handler);
}

void FakeSession::SetRequestPresentationTimesHandler(
    RequestPresentationTimesHandler request_presentation_times_handler) {
  request_presentation_times_handler_ =
      std::move(request_presentation_times_handler);
}

void FakeSession::FireOnFramePresentedEvent(
    fuchsia::scenic::scheduling::FramePresentedInfo frame_presented_info) {
  FML_CHECK(is_bound());

  binding_.events().OnFramePresented(std::move(frame_presented_info));
}

void FakeSession::DisconnectSession() {
  // Unbind the channels and drop them on the floor, simulating Scenic behavior.
  binding_.Unbind();
  listener_.Unbind();
}

void FakeSession::NotImplemented_(const std::string& name) {
  FML_LOG(FATAL) << "FakeSession does not implement " << name;
}

void FakeSession::Enqueue(std::vector<fuchsia::ui::scenic::Command> cmds) {
  // Append `cmds` to the end of the command queue, preferring to move elements
  // when possible.
  command_queue_.insert(command_queue_.end(),
                        std::make_move_iterator(cmds.begin()),
                        std::make_move_iterator(cmds.end()));
}

void FakeSession::Present(uint64_t presentation_time,
                          std::vector<zx::event> acquire_fences,
                          std::vector<zx::event> release_fences,
                          PresentCallback callback) {
  ApplyCommands();

  PresentHandler present_handler =
      present_handler_ ? present_handler_ : [](auto... args) -> auto{
    return fuchsia::images::PresentationInfo{};
  };

  auto present_info = present_handler_(
      presentation_time, std::move(acquire_fences), std::move(release_fences));
  if (callback) {
    callback(std::move(present_info));
  }
}

void FakeSession::Present2(fuchsia::ui::scenic::Present2Args args,
                           Present2Callback callback) {
  ApplyCommands();

  Present2Handler present2_handler =
      present2_handler_ ? present2_handler_ : [](auto args) -> auto{
    return fuchsia::scenic::scheduling::FuturePresentationTimes{
        .future_presentations = {},
        .remaining_presents_in_flight_allowed = 1,
    };
  };

  auto future_presentation_times = present2_handler(std::move(args));
  if (callback) {
    callback(std::move(future_presentation_times));
  }
}

void FakeSession::RequestPresentationTimes(
    int64_t requested_prediction_span,
    RequestPresentationTimesCallback callback) {
  RequestPresentationTimesHandler request_presentation_times_handler =
      request_presentation_times_handler_ ? request_presentation_times_handler_
                                          : [](auto args) -> auto{
    return fuchsia::scenic::scheduling::FuturePresentationTimes{
        .future_presentations = {},
        .remaining_presents_in_flight_allowed = 1,
    };
  };

  auto future_presentation_times =
      request_presentation_times_handler(requested_prediction_span);
  if (callback) {
    callback(std::move(future_presentation_times));
  }
}

void FakeSession::RegisterBufferCollection(
    uint32_t buffer_id,
    fidl::InterfaceHandle<fuchsia::sysmem::BufferCollectionToken> token) {
  zx_koid_t token_koid = GetKoid(token.channel().get());
  auto [_, buffer_success] =
      scene_graph_.buffer_collection_map.emplace(std::make_pair(
          buffer_id,
          StateT::HandleT<
              fidl::InterfaceHandle<fuchsia::sysmem::BufferCollectionToken>>{
              std::move(token), token_koid}));
  FML_CHECK(buffer_success);
}

void FakeSession::DeregisterBufferCollection(uint32_t buffer_id) {
  size_t erased = scene_graph_.buffer_collection_map.erase(buffer_id);
  FML_CHECK(erased == 1);
}

void FakeSession::SetDebugName(std::string debug_name) {
  debug_name_ = std::move(debug_name);
}

std::shared_ptr<FakeResourceState> FakeSession::GetResource(FakeResourceId id) {
  FML_CHECK(id != kInvalidFakeResourceId);
  auto resource_it = scene_graph_.resource_map.find(id);
  FML_CHECK(resource_it != scene_graph_.resource_map.end());
  auto resource_ptr = resource_it->second;
  FML_CHECK(resource_ptr);

  return resource_ptr;
}

void FakeSession::AddResource(FakeResourceState&& resource) {
  const FakeResourceId resource_id = resource.id;
  FML_CHECK(resource_id != kInvalidFakeResourceId);

  // Track the view id if the resource is a view.
  if (ResourceIs<FakeViewState>(resource)) {
    // If there was already a View in the scene graph, scenic prints a warning
    // here but doesn't update the "root view" and allows the Session to
    // continue.  See also: fxbug.dev/24450
    if (scene_graph_.root_view_id == kInvalidFakeResourceId) {
      scene_graph_.root_view_id = resource_id;
    }
  }

  // Add to initial spot in parents map.
  auto resource_ptr = std::make_shared<FakeResourceState>(
      std::forward<FakeResourceState>(resource));
  if (ResourceIsNode(*resource_ptr)) {
    auto [_, parents_success] = parents_map_.emplace(std::make_pair(
        resource_ptr.get(),
        std::make_pair(std::weak_ptr<FakeResourceState>(resource_ptr),
                       std::weak_ptr<FakeResourceState>())));
    FML_CHECK(parents_success);
  }

  // Add to initial spot in labels map.
  auto empty_label_it = scene_graph_.label_map.find("");
  if (empty_label_it == scene_graph_.label_map.end()) {
    auto [emplace_it, empty_label_success] = scene_graph_.label_map.emplace(
        std::make_pair("", std::vector<std::weak_ptr<FakeResourceState>>()));
    FML_CHECK(empty_label_success);
    empty_label_it = emplace_it;
  }
  empty_label_it->second.emplace_back(resource_ptr);

  // Add to resource map.
  auto [__, resource_success] = scene_graph_.resource_map.emplace(
      std::make_pair(resource_id, std::move(resource_ptr)));
  FML_CHECK(resource_success);
}

void FakeSession::DetachResourceFromParent(
    std::shared_ptr<FakeResourceState> resource_ptr,
    std::shared_ptr<FakeResourceState> new_parent_ptr) {
  FML_CHECK(resource_ptr);

  // Remove reference from the parent's `children` array.
  auto parent_it = parents_map_.find(resource_ptr.get());
  FML_CHECK(parent_it != parents_map_.end());
  if (auto parent_ptr = parent_it->second.second.lock()) {
    std::visit(
        [&resource_ptr](auto&& state) {
          using T = std::decay_t<decltype(state)>;
          if constexpr (is_node_v<T>) {
            auto erase_it =
                std::remove_if(state.node_state.children.begin(),
                               state.node_state.children.end(),
                               [&resource_ptr](const auto& resource) {
                                 return resource == resource_ptr;
                               });
            FML_CHECK(erase_it != state.node_state.children.end());
            state.node_state.children.erase(erase_it);
          } else if constexpr (std::is_same_v<T, FakeViewState>) {
            auto erase_it =
                std::remove_if(state.children.begin(), state.children.end(),
                               [&resource_ptr](const auto& resource) {
                                 return resource == resource_ptr;
                               });
            FML_CHECK(erase_it != state.children.end());
            state.children.erase(erase_it);
          } else {
            FML_CHECK(false);
          }
        },
        parent_ptr->state);
  }

  // Fix up the parent ptr.
  if (new_parent_ptr) {
    parent_it->second.second = new_parent_ptr;
  } else {
    parent_it->second.second = std::weak_ptr<FakeResourceState>();
  }
}

void FakeSession::PruneDeletedResourceRefs() {
  // Remove expired resources from the parents map.
  for (auto parent_it = parents_map_.begin(), parent_end = parents_map_.end();
       parent_it != parent_end;) {
    if (parent_it->second.first.expired()) {
      parent_it = parents_map_.erase(parent_it);
    } else {
      ++parent_it;
    }
  }

  // Remove expired resurces from the labels map.
  for (auto scene_it = scene_graph_.label_map.begin(),
            scene_end = scene_graph_.label_map.end();
       scene_it != scene_end;) {
    auto erase_it = std::remove_if(
        scene_it->second.begin(), scene_it->second.end(),
        [](const auto& weak_resource) { return weak_resource.expired(); });
    if (erase_it != scene_it->second.end()) {
      scene_it->second.erase(erase_it);
    }

    if (scene_it->second.empty()) {
      scene_it = scene_graph_.label_map.erase(scene_it);
    } else {
      ++scene_it;
    }
  }
}

void FakeSession::ApplyCommands() {
  while (!command_queue_.empty()) {
    auto scenic_command = std::move(command_queue_.front());
    command_queue_.pop_front();

    if (!scenic_command.is_gfx()) {
      FML_LOG(FATAL) << "FakeSession: Unexpected non-gfx command (type "
                     << scenic_command.Which() << ")";
      continue;
    }

    auto& command = scenic_command.gfx();
    switch (command.Which()) {
      case fuchsia::ui::gfx::Command::Tag::kCreateResource:
        ApplyCreateResourceCmd(std::move(command.create_resource()));
        break;
      case fuchsia::ui::gfx::Command::Tag::kReleaseResource:
        ApplyReleaseResourceCmd(std::move(command.release_resource()));
        break;
      case fuchsia::ui::gfx::Command::Tag::kAddChild:
        ApplyAddChildCmd(std::move(command.add_child()));
        break;
      case fuchsia::ui::gfx::Command::Tag::kDetach:
        ApplyDetachCmd(std::move(command.detach()));
        break;
      case fuchsia::ui::gfx::Command::Tag::kDetachChildren:
        ApplyDetachChildrenCmd(std::move(command.detach_children()));
        break;
      case fuchsia::ui::gfx::Command::Tag::kSetTranslation:
        ApplySetTranslationCmd(std::move(command.set_translation()));
        break;
      case fuchsia::ui::gfx::Command::Tag::kSetScale:
        ApplySetScaleCmd(std::move(command.set_scale()));
        break;
      case fuchsia::ui::gfx::Command::Tag::kSetRotation:
        ApplySetRotationCmd(std::move(command.set_rotation()));
        break;
      case fuchsia::ui::gfx::Command::Tag::kSetAnchor:
        ApplySetAnchorCmd(std::move(command.set_anchor()));
        break;
      case fuchsia::ui::gfx::Command::Tag::kSetOpacity:
        ApplySetOpacityCmd(command.set_opacity());
        break;
      case fuchsia::ui::gfx::Command::Tag::kSetShape:
        ApplySetShapeCmd(std::move(command.set_shape()));
        break;
      case fuchsia::ui::gfx::Command::Tag::kSetMaterial:
        ApplySetMaterialCmd(std::move(command.set_material()));
        break;
      case ::fuchsia::ui::gfx::Command::Tag::kSetClipPlanes:
        ApplySetClipPlanesCmd(std::move(command.set_clip_planes()));
        break;
      case fuchsia::ui::gfx::Command::Tag::kSetHitTestBehavior:
        ApplySetHitTestBehaviorCmd(std::move(command.set_hit_test_behavior()));
        break;
      case fuchsia::ui::gfx::Command::Tag::kSetSemanticVisibility:
        ApplySetSemanticVisibilityCmd(
            std::move(command.set_semantic_visibility()));
        break;
      case fuchsia::ui::gfx::Command::Tag::kSetViewProperties:
        ApplySetViewPropertiesCmd(std::move(command.set_view_properties()));
        break;
      case fuchsia::ui::gfx::Command::Tag::kSetTexture:
        ApplySetTextureCmd(std::move(command.set_texture()));
        break;
      case fuchsia::ui::gfx::Command::Tag::kSetColor:
        ApplySetColorCmd(std::move(command.set_color()));
        break;
      case fuchsia::ui::gfx::Command::Tag::kSetEventMask:
        ApplySetEventMaskCmd(std::move(command.set_event_mask()));
        break;
      case fuchsia::ui::gfx::Command::Tag::kSetLabel:
        ApplySetLabelCmd(std::move(command.set_label()));
        break;
      case fuchsia::ui::gfx::Command::Tag::kSetEnableViewDebugBounds:
        ApplySetEnableViewDebugBoundsCmd(
            std::move(command.set_enable_view_debug_bounds()));
        break;
      case fuchsia::ui::gfx::Command::Tag::kSetViewHolderBoundsColor:
        ApplySetViewHolderBoundsColorCmd(
            std::move(command.set_view_holder_bounds_color()));
        break;
      case fuchsia::ui::gfx::Command::Tag::kExportResource:
        NotImplemented_("ExportResourceCmd");
        break;
      case fuchsia::ui::gfx::Command::Tag::kImportResource:
        NotImplemented_("ImportResourceCmd");
        break;
      case fuchsia::ui::gfx::Command::Tag::kSetTag:
        NotImplemented_("SetTagCmd");
        break;
      case fuchsia::ui::gfx::Command::Tag::kSetSize:
        NotImplemented_("SetSizeCmd");
        break;
      case fuchsia::ui::gfx::Command::Tag::kSendSizeChangeHintHack:
        NotImplemented_("SendSizeChangedHintHackCmd");
        break;
      case fuchsia::ui::gfx::Command::Tag::kAddPart:
        NotImplemented_("AddPartCmd");
        break;
      case fuchsia::ui::gfx::Command::Tag::kSetClip:
        NotImplemented_("SetClipCmd");
        break;
      case fuchsia::ui::gfx::Command::Tag::kSetCamera:
        NotImplemented_("SetCameraCmd");
        break;
      case fuchsia::ui::gfx::Command::Tag::kSetCameraTransform:
        NotImplemented_("SetCameraTransformCmd");
        break;
      case fuchsia::ui::gfx::Command::Tag::kSetCameraProjection:
        NotImplemented_("SetCameraProjectionCmd");
        break;
      case fuchsia::ui::gfx::Command::Tag::kSetStereoCameraProjection:
        NotImplemented_("SetStereoCameraProjectionCmd");
        break;
      case fuchsia::ui::gfx::Command::Tag::kSetCameraClipSpaceTransform:
        NotImplemented_("SetCameraClipSpaceTransformCmd");
        break;
      case fuchsia::ui::gfx::Command::Tag::kSetCameraPoseBuffer:
        NotImplemented_("SetCameraPoseBufferCmd");
        break;
      case fuchsia::ui::gfx::Command::Tag::kSetLightColor:
        NotImplemented_("SetLightColorCmd");
        break;
      case fuchsia::ui::gfx::Command::Tag::kSetLightDirection:
        NotImplemented_("SetLightDirectionCmd");
        break;
      case fuchsia::ui::gfx::Command::Tag::kSetPointLightPosition:
        NotImplemented_("SetPointLightPositionCmd");
        break;
      case fuchsia::ui::gfx::Command::Tag::kSetPointLightFalloff:
        NotImplemented_("SetPointLightFalloffCmd");
        break;
      case fuchsia::ui::gfx::Command::Tag::kAddLight:
        NotImplemented_("AddLightCmd");
        break;
      case fuchsia::ui::gfx::Command::Tag::kScene_AddAmbientLight:
        NotImplemented_("Scene_AddAmbientLightCmd");
        break;
      case fuchsia::ui::gfx::Command::Tag::kScene_AddDirectionalLight:
        NotImplemented_("Scene_AddDirectionalLightCmd");
        break;
      case fuchsia::ui::gfx::Command::Tag::kScene_AddPointLight:
        NotImplemented_("Scene_AddPointLightCmd");
        break;
      case fuchsia::ui::gfx::Command::Tag::kDetachLight:
        NotImplemented_("DetachLightCmd");
        break;
      case fuchsia::ui::gfx::Command::Tag::kDetachLights:
        NotImplemented_("DetachLightsCmd");
        break;
      case fuchsia::ui::gfx::Command::Tag::kBindMeshBuffers:
        NotImplemented_("BindMeshBuffersCmd");
        break;
      case fuchsia::ui::gfx::Command::Tag::kAddLayer:
        NotImplemented_("AddLayerCmd");
        break;
      case fuchsia::ui::gfx::Command::Tag::kRemoveLayer:
        NotImplemented_("RemoveLayerCmd");
        break;
      case fuchsia::ui::gfx::Command::Tag::kRemoveAllLayers:
        NotImplemented_("RemoveAllLayersCmd");
        break;
      case fuchsia::ui::gfx::Command::Tag::kSetLayerStack:
        NotImplemented_("SetLayerStackCmd");
        break;
      case fuchsia::ui::gfx::Command::Tag::kSetRenderer:
        NotImplemented_("SetRendererCmd");
        break;
      case fuchsia::ui::gfx::Command::Tag::kSetRendererParam:
        NotImplemented_("SetRendererParamCmd");
        break;
      case fuchsia::ui::gfx::Command::Tag::kSetDisableClipping:
        NotImplemented_("SetDisableClippingCmd");
        break;
      case fuchsia::ui::gfx::Command::Tag::kSetImportFocus:
        NotImplemented_("SetImportFocusCmd");
        break;
      case fuchsia::ui::gfx::Command::Tag::kTakeSnapshotCmd:
        NotImplemented_("TakeSnapshotCmd");
        break;
      case fuchsia::ui::gfx::Command::Tag::kSetDisplayColorConversion:
        NotImplemented_("SetDisplayColorConversionCmd");
        break;
      case fuchsia::ui::gfx::Command::Tag::kSetDisplayRotation:
        NotImplemented_("SetDisplayRotationCmd");
        break;
      case fuchsia::ui::gfx::Command::Tag::kSetDisplayMinimumRgb:
        NotImplemented_("SetDisplayMinimumRgbCmd");
        break;
      case fuchsia::ui::gfx::Command::Tag::Invalid:
        FML_LOG(FATAL) << "FakeSession found Invalid gfx command";
        break;
    }
  }

  // Clean up resource refs after processing commands.
  PruneDeletedResourceRefs();
}

void FakeSession::ApplyCreateResourceCmd(
    fuchsia::ui::gfx::CreateResourceCmd command) {
  const FakeResourceId resource_id = command.id;
  FML_CHECK(resource_id != 0);

  switch (command.resource.Which()) {
    case fuchsia::ui::gfx::ResourceArgs::Tag::kMemory:
      ApplyCreateMemory(resource_id, std::move(command.resource.memory()));
      break;
    case fuchsia::ui::gfx::ResourceArgs::Tag::kImage:
      ApplyCreateImage(resource_id, std::move(command.resource.image()));
      break;
    case fuchsia::ui::gfx::ResourceArgs::Tag::kImage2:
      ApplyCreateImage2(resource_id, std::move(command.resource.image2()));
      break;
    case fuchsia::ui::gfx::ResourceArgs::Tag::kImage3:
      ApplyCreateImage3(resource_id, std::move(command.resource.image3()));
      break;
    case fuchsia::ui::gfx::ResourceArgs::Tag::kImagePipe2:
      ApplyCreateImagePipe2(resource_id,
                            std::move(command.resource.image_pipe2()));
      break;
    case fuchsia::ui::gfx::ResourceArgs::Tag::kRectangle:
      ApplyCreateRectangle(resource_id,
                           std::move(command.resource.rectangle()));
      break;
    case fuchsia::ui::gfx::ResourceArgs::Tag::kRoundedRectangle:
      ApplyCreateRoundedRectangle(
          resource_id, std::move(command.resource.rounded_rectangle()));
      break;
    case fuchsia::ui::gfx::ResourceArgs::Tag::kCircle:
      ApplyCreateCircle(resource_id, std::move(command.resource.circle()));
      break;
    case fuchsia::ui::gfx::ResourceArgs::Tag::kMaterial:
      ApplyCreateMaterial(resource_id, std::move(command.resource.material()));
      break;
    case fuchsia::ui::gfx::ResourceArgs::Tag::kView:
      ApplyCreateView(resource_id, std::move(command.resource.view()));
      break;
    case fuchsia::ui::gfx::ResourceArgs::Tag::kView3:
      ApplyCreateView(resource_id, std::move(command.resource.view3()));
      break;
    case fuchsia::ui::gfx::ResourceArgs::Tag::kViewHolder:
      ApplyCreateViewHolder(resource_id,
                            std::move(command.resource.view_holder()));
      break;
    case fuchsia::ui::gfx::ResourceArgs::Tag::kOpacityNode:
      ApplyCreateOpacityNode(resource_id, command.resource.opacity_node());
      break;
    case fuchsia::ui::gfx::ResourceArgs::Tag::kEntityNode:
      ApplyCreateEntityNode(resource_id,
                            std::move(command.resource.entity_node()));
      break;
    case fuchsia::ui::gfx::ResourceArgs::Tag::kShapeNode:
      ApplyCreateShapeNode(resource_id,
                           std::move(command.resource.shape_node()));
      break;
    case fuchsia::ui::gfx::ResourceArgs::Tag::kBuffer:
      NotImplemented_("CreateBufferResource");
      break;
    case fuchsia::ui::gfx::ResourceArgs::Tag::kScene:
      NotImplemented_("CreateSceneResource");
      break;
    case fuchsia::ui::gfx::ResourceArgs::Tag::kCamera:
      NotImplemented_("CreateCameraResource");
      break;
    case fuchsia::ui::gfx::ResourceArgs::Tag::kStereoCamera:
      NotImplemented_("CreateStereoCameraResource");
      break;
    case fuchsia::ui::gfx::ResourceArgs::Tag::kRenderer:
      NotImplemented_("CreateRendererResource");
      break;
    case fuchsia::ui::gfx::ResourceArgs::Tag::kAmbientLight:
      NotImplemented_("CreateAmbientLightResource");
      break;
    case fuchsia::ui::gfx::ResourceArgs::Tag::kDirectionalLight:
      NotImplemented_("CreateDirectionalLightResource");
      break;
    case fuchsia::ui::gfx::ResourceArgs::Tag::kPointLight:
      NotImplemented_("CreatePointLightResource");
      break;
    case fuchsia::ui::gfx::ResourceArgs::Tag::kMesh:
      NotImplemented_("CreateMeshResource");
      break;
    case fuchsia::ui::gfx::ResourceArgs::Tag::kClipNode:
      NotImplemented_("CreateClipNodeResource");
      break;
    case fuchsia::ui::gfx::ResourceArgs::Tag::kCompositor:
      NotImplemented_("CreateCompositorResource");
      break;
    case fuchsia::ui::gfx::ResourceArgs::Tag::kDisplayCompositor:
      NotImplemented_("CreateDisplayCompositorResource");
      break;
    case fuchsia::ui::gfx::ResourceArgs::Tag::kLayerStack:
      NotImplemented_("CreateLayerStackResource");
      break;
    case fuchsia::ui::gfx::ResourceArgs::Tag::kLayer:
      NotImplemented_("CreateLayerResource");
      break;
    case fuchsia::ui::gfx::ResourceArgs::Tag::kVariable:
      NotImplemented_("CreateVariableResource");
      break;
    case fuchsia::ui::gfx::ResourceArgs::Tag::Invalid:
      FML_LOG(FATAL) << "FakeSession found Invalid CreateResource command";
      break;
    default:
      FML_UNREACHABLE();
  }
}

void FakeSession::ApplyReleaseResourceCmd(
    fuchsia::ui::gfx::ReleaseResourceCmd command) {
  auto resource_ptr = GetResource(command.id);
  if (ResourceIs<FakeViewState>(*resource_ptr)) {
    FML_CHECK(scene_graph_.root_view_id == resource_ptr->id);
    scene_graph_.root_view_id = kInvalidFakeResourceId;
  }

  scene_graph_.resource_map.erase(command.id);
}

void FakeSession::ApplyAddChildCmd(fuchsia::ui::gfx::AddChildCmd command) {
  auto parent_node_ptr = GetResource(command.node_id);
  FML_CHECK(ResourceIsNode(*parent_node_ptr) ||
            ResourceIs<FakeViewState>(*parent_node_ptr));

  auto child_node_ptr = GetResource(command.child_id);
  FML_CHECK(ResourceIsNode(*child_node_ptr));

  // Add the Node as a child of the new parent.
  std::visit(
      [&child_node_ptr](auto&& state) {
        using T = std::decay_t<decltype(state)>;
        if constexpr (is_node_v<T>) {
          state.node_state.children.emplace_back(child_node_ptr);
        } else if constexpr (std::is_same_v<T, FakeViewState>) {
          state.children.emplace_back(child_node_ptr);
        } else {
          FML_CHECK(false);
        }
      },
      parent_node_ptr->state);

  // Remove the Node as a child of the old parent and fix up the parent ptr.
  DetachResourceFromParent(child_node_ptr, parent_node_ptr);
}

void FakeSession::ApplyDetachCmd(fuchsia::ui::gfx::DetachCmd command) {
  auto resource_ptr = GetResource(command.id);
  FML_CHECK(ResourceIsNode(*resource_ptr));

  DetachResourceFromParent(std::move(resource_ptr));
}

void FakeSession::ApplyDetachChildrenCmd(
    fuchsia::ui::gfx::DetachChildrenCmd command) {
  auto resource_ptr = GetResource(command.node_id);
  FML_CHECK(ResourceIsNode(*resource_ptr));

  std::visit(
      [this](auto&& state) {
        using T = std::decay_t<decltype(state)>;
        if constexpr (is_node_v<T>) {
          for (auto& child : state.node_state.children) {
            DetachResourceFromParent(child);
          }
          state.node_state.children.clear();
        } else {
          FML_CHECK(false);
        }
      },
      resource_ptr->state);
}

void FakeSession::ApplySetTranslationCmd(
    fuchsia::ui::gfx::SetTranslationCmd command) {
  auto resource_ptr = GetResource(command.id);
  FML_CHECK(ResourceIsNode(*resource_ptr));

  const std::array<float, 3> translation = {
      command.value.value.x, command.value.value.y, command.value.value.z};
  std::visit(
      [&translation](auto&& state) {
        using T = std::decay_t<decltype(state)>;
        if constexpr (is_node_v<T>) {
          state.node_state.translation_vector = translation;
        } else {
          FML_CHECK(false);
        }
      },
      resource_ptr->state);
}

void FakeSession::ApplySetScaleCmd(fuchsia::ui::gfx::SetScaleCmd command) {
  auto resource_ptr = GetResource(command.id);
  FML_CHECK(ResourceIsNode(*resource_ptr));

  const std::array<float, 3> scale = {
      command.value.value.x, command.value.value.y, command.value.value.z};
  std::visit(
      [&scale](auto&& state) {
        using T = std::decay_t<decltype(state)>;
        if constexpr (is_node_v<T>) {
          state.node_state.scale_vector = scale;
        } else {
          FML_CHECK(false);
        }
      },
      resource_ptr->state);
}

void FakeSession::ApplySetRotationCmd(
    fuchsia::ui::gfx::SetRotationCmd command) {
  auto resource_ptr = GetResource(command.id);
  FML_CHECK(ResourceIsNode(*resource_ptr));

  const std::array<float, 4> rotation = {
      command.value.value.x, command.value.value.y, command.value.value.z,
      command.value.value.w};
  std::visit(
      [&rotation](auto&& state) {
        using T = std::decay_t<decltype(state)>;
        if constexpr (is_node_v<T>) {
          state.node_state.rotation_quaternion = rotation;
        } else {
          FML_CHECK(false);
        }
      },
      resource_ptr->state);
}

void FakeSession::ApplySetAnchorCmd(fuchsia::ui::gfx::SetAnchorCmd command) {
  auto resource_ptr = GetResource(command.id);
  FML_CHECK(ResourceIsNode(*resource_ptr));

  const std::array<float, 3> anchor = {
      command.value.value.x, command.value.value.y, command.value.value.z};
  std::visit(
      [&anchor](auto&& state) {
        using T = std::decay_t<decltype(state)>;
        if constexpr (is_node_v<T>) {
          state.node_state.anchor_vector = anchor;
        } else {
          FML_CHECK(false);
        }
      },
      resource_ptr->state);
}

void FakeSession::ApplySetOpacityCmd(fuchsia::ui::gfx::SetOpacityCmd command) {
  auto resource_ptr = GetResource(command.node_id);
  FML_CHECK(ResourceIs<FakeOpacityNodeState>(*resource_ptr));

  const bool opacity = command.opacity;
  std::visit(
      [opacity](auto&& state) {
        using T = std::decay_t<decltype(state)>;
        if constexpr (std::is_same_v<T, FakeOpacityNodeState>) {
          state.opacity = opacity;
        } else {
          FML_CHECK(false);
        }
      },
      resource_ptr->state);
}

void FakeSession::ApplySetShapeCmd(fuchsia::ui::gfx::SetShapeCmd command) {
  auto shape_node_ptr = GetResource(command.node_id);
  FML_CHECK(ResourceIs<FakeShapeNodeState>(*shape_node_ptr));
  auto* shape_node_state =
      std::get_if<FakeShapeNodeState>(&shape_node_ptr->state);
  FML_CHECK(shape_node_state != nullptr);
  auto shape_ptr = GetResource(command.shape_id);
  FML_CHECK(ResourceIs<FakeShapeState>(*shape_ptr));

  shape_node_state->shape = shape_ptr;
}

void FakeSession::ApplySetMaterialCmd(
    fuchsia::ui::gfx::SetMaterialCmd command) {
  auto shape_node_ptr = GetResource(command.node_id);
  FML_CHECK(ResourceIs<FakeShapeNodeState>(*shape_node_ptr));
  auto* shape_node_state =
      std::get_if<FakeShapeNodeState>(&shape_node_ptr->state);
  FML_CHECK(shape_node_state != nullptr);
  auto material_ptr = GetResource(command.material_id);
  FML_CHECK(ResourceIs<FakeMaterialState>(*material_ptr));

  shape_node_state->material = material_ptr;
}

void FakeSession::ApplySetClipPlanesCmd(
    fuchsia::ui::gfx::SetClipPlanesCmd command) {
  auto node_ptr = GetResource(command.node_id);
  FML_CHECK(ResourceIs<FakeEntityNodeState>(*node_ptr));

  std::vector<FakeEntityNodeState::ClipPlane> clip_planes;
  for (auto& clip_plane : command.clip_planes) {
    clip_planes.emplace_back(FakeEntityNodeState::ClipPlane{
        .dir = {clip_plane.dir.x, clip_plane.dir.y, clip_plane.dir.z},
        .dist = clip_plane.dist,
    });
  }
  std::visit(
      [clip_planes = std::move(clip_planes)](auto&& state) {
        using T = std::decay_t<decltype(state)>;
        if constexpr (std::is_same_v<T, FakeEntityNodeState>) {
          state.clip_planes = std::move(clip_planes);
        } else {
          FML_CHECK(false);
        }
      },
      node_ptr->state);
}

void FakeSession::ApplySetViewPropertiesCmd(
    fuchsia::ui::gfx::SetViewPropertiesCmd command) {
  auto view_holder_ptr = GetResource(command.view_holder_id);
  FML_CHECK(ResourceIs<FakeViewHolderState>(*view_holder_ptr));
  auto* view_holder_state =
      std::get_if<FakeViewHolderState>(&view_holder_ptr->state);
  FML_CHECK(view_holder_state != nullptr);

  view_holder_state->properties = command.properties;
}

void FakeSession::ApplySetHitTestBehaviorCmd(
    fuchsia::ui::gfx::SetHitTestBehaviorCmd command) {
  auto node_ptr = GetResource(command.node_id);
  FML_CHECK(ResourceIsNode(*node_ptr));

  const bool hit_testable =
      command.hit_test_behavior == fuchsia::ui::gfx::HitTestBehavior::kDefault;
  std::visit(
      [hit_testable](auto&& state) {
        using T = std::decay_t<decltype(state)>;
        if constexpr (is_node_v<T>) {
          state.node_state.hit_testable = hit_testable;
        } else {
          FML_CHECK(false);
        }
      },
      node_ptr->state);
}

void FakeSession::ApplySetSemanticVisibilityCmd(
    fuchsia::ui::gfx::SetSemanticVisibilityCmd command) {
  auto node_ptr = GetResource(command.node_id);
  FML_CHECK(ResourceIsNode(*node_ptr));

  const bool semantic_visibility = command.visible;
  std::visit(
      [semantic_visibility](auto&& state) {
        using T = std::decay_t<decltype(state)>;
        if constexpr (is_node_v<T>) {
          state.node_state.semantically_visible = semantic_visibility;
        } else {
          FML_CHECK(false);
        }
      },
      node_ptr->state);
}

void FakeSession::ApplySetTextureCmd(fuchsia::ui::gfx::SetTextureCmd command) {
  auto material_ptr = GetResource(command.material_id);
  FML_CHECK(ResourceIs<FakeMaterialState>(*material_ptr));
  auto* material_state = std::get_if<FakeMaterialState>(&material_ptr->state);
  FML_CHECK(material_state != nullptr);
  auto image_ptr = GetResource(command.texture_id);
  FML_CHECK(ResourceIs<FakeImageState>(*image_ptr));

  material_state->image = image_ptr;
}

void FakeSession::ApplySetColorCmd(fuchsia::ui::gfx::SetColorCmd command) {
  auto material_ptr = GetResource(command.material_id);
  FML_CHECK(ResourceIs<FakeMaterialState>(*material_ptr));
  auto* material_state = std::get_if<FakeMaterialState>(&material_ptr->state);
  FML_CHECK(material_state != nullptr);

  material_state->color = {(command.color.value.red * 1.f) / 255.f,
                           (command.color.value.green * 1.f) / 255.f,
                           (command.color.value.blue * 1.f) / 255.f,
                           (command.color.value.alpha * 1.f) / 255.f};
}

void FakeSession::ApplySetEventMaskCmd(
    fuchsia::ui::gfx::SetEventMaskCmd command) {
  auto resource_ptr = GetResource(command.id);

  resource_ptr->event_mask = command.event_mask;
}

void FakeSession::ApplySetLabelCmd(fuchsia::ui::gfx::SetLabelCmd command) {
  auto resource_ptr = GetResource(command.id);

  // Erase from old spot in the labels map.
  auto current_label_it = scene_graph_.label_map.find(resource_ptr->label);
  FML_CHECK(current_label_it != scene_graph_.label_map.end());
  auto current_erase_it = std::remove_if(
      current_label_it->second.begin(), current_label_it->second.end(),
      [&resource_ptr](const auto& weak_resource) {
        return resource_ptr == weak_resource.lock();
      });
  FML_CHECK(current_erase_it != current_label_it->second.end());
  current_label_it->second.erase(current_erase_it);

  // Add to new spot in labels map.
  auto new_label_it = scene_graph_.label_map.find(command.label);
  if (new_label_it == scene_graph_.label_map.end()) {
    auto [emplace_it, current_label_success] =
        scene_graph_.label_map.emplace(std::make_pair(
            command.label, std::vector<std::weak_ptr<FakeResourceState>>()));
    FML_CHECK(current_label_success);
    new_label_it = emplace_it;
  }
  new_label_it->second.emplace_back(resource_ptr);

  resource_ptr->label = std::move(command.label);
}

void FakeSession::ApplySetEnableViewDebugBoundsCmd(
    fuchsia::ui::gfx::SetEnableDebugViewBoundsCmd command) {
  auto view_ptr = GetResource(command.view_id);
  FML_CHECK(ResourceIs<FakeViewState>(*view_ptr));
  auto* view_state = std::get_if<FakeViewState>(&view_ptr->state);
  FML_CHECK(view_state != nullptr);

  view_state->enable_debug_bounds = command.enable;
}

void FakeSession::ApplySetViewHolderBoundsColorCmd(
    fuchsia::ui::gfx::SetViewHolderBoundsColorCmd command) {
  auto view_holder_ptr = GetResource(command.view_holder_id);
  FML_CHECK(ResourceIs<FakeViewHolderState>(*view_holder_ptr));
  auto* view_holder_state =
      std::get_if<FakeViewHolderState>(&view_holder_ptr->state);
  FML_CHECK(view_holder_state != nullptr);

  view_holder_state->bounds_color = {command.color.value.red,
                                     command.color.value.green,
                                     command.color.value.blue, 1.f};
}

void FakeSession::ApplyCreateMemory(FakeResourceId id,
                                    fuchsia::ui::gfx::MemoryArgs args) {
  zx_koid_t vmo_koid = GetKoid(args.vmo.get());
  AddResource(
      {.id = id,
       .state = FakeMemoryState{
           .vmo = {std::move(args.vmo), vmo_koid},
           .allocation_size = args.allocation_size,
           .is_device_memory = (args.memory_type ==
                                fuchsia::images::MemoryType::VK_DEVICE_MEMORY),
       }});
}

void FakeSession::ApplyCreateImage(FakeResourceId id,
                                   fuchsia::ui::gfx::ImageArgs args) {
  AddResource({.id = id,
               .state = FakeImageState{
                   .image_def =
                       FakeImageState::ImageDef{
                           .info = std::move(args.info),
                           .memory_offset = args.memory_offset,
                       },
               }});

  // Hook up the memory resource to the image
  auto image_ptr = GetResource(id);
  FML_CHECK(ResourceIs<FakeImageState>(*image_ptr));
  auto* image_state = std::get_if<FakeImageState>(&image_ptr->state);
  FML_CHECK(image_state != nullptr);
  auto memory_ptr = GetResource(args.memory_id);
  FML_CHECK(ResourceIs<FakeMemoryState>(*memory_ptr));

  image_state->memory = memory_ptr;
}

void FakeSession::ApplyCreateImage2(FakeResourceId id,
                                    fuchsia::ui::gfx::ImageArgs2 args) {
  AddResource(
      {.id = id,
       .state = FakeImageState{
           .image_def =
               FakeImageState::Image2Def{
                   .buffer_collection_id = args.buffer_collection_id,
                   .buffer_collection_index = args.buffer_collection_index,
                   .width = args.width,
                   .height = args.height,
               },
       }});
}

void FakeSession::ApplyCreateImage3(FakeResourceId id,
                                    fuchsia::ui::gfx::ImageArgs3 args) {
  zx_koid_t import_token_koid = GetKoid(args.import_token.value.get());
  AddResource(
      {.id = id,
       .state = FakeImageState{
           .image_def =
               FakeImageState::Image3Def{
                   .import_token = {std::move(args.import_token),
                                    import_token_koid},
                   .buffer_collection_index = args.buffer_collection_index,
                   .width = args.width,
                   .height = args.height,
               },
       }});
}

void FakeSession::ApplyCreateImagePipe2(FakeResourceId id,
                                        fuchsia::ui::gfx::ImagePipe2Args args) {
  zx_koid_t image_pipe_request_koid =
      GetKoid(args.image_pipe_request.channel().get());
  AddResource(
      {.id = id,
       .state = FakeImageState{
           .image_def =
               FakeImageState::ImagePipe2Def{
                   .image_pipe_request = {std::move(args.image_pipe_request),
                                          image_pipe_request_koid},
               },
       }});
}

void FakeSession::ApplyCreateRectangle(FakeResourceId id,
                                       fuchsia::ui::gfx::RectangleArgs args) {
  FML_CHECK(args.width.is_vector1());
  FML_CHECK(args.height.is_vector1());

  AddResource({.id = id,
               .state = FakeShapeState{
                   .shape_def =
                       FakeShapeState::RectangleDef{
                           .width = args.width.vector1(),
                           .height = args.height.vector1(),
                       },
               }});
}

void FakeSession::ApplyCreateRoundedRectangle(
    FakeResourceId id,
    fuchsia::ui::gfx::RoundedRectangleArgs args) {
  FML_CHECK(args.width.is_vector1());
  FML_CHECK(args.height.is_vector1());
  FML_CHECK(args.top_left_radius.is_vector1());
  FML_CHECK(args.top_right_radius.is_vector1());
  FML_CHECK(args.bottom_right_radius.is_vector1());
  FML_CHECK(args.bottom_left_radius.is_vector1());

  AddResource(
      {.id = id,
       .state = FakeShapeState{
           .shape_def =
               FakeShapeState::RoundedRectangleDef{
                   .width = args.width.vector1(),
                   .height = args.height.vector1(),
                   .top_left_radius = args.top_left_radius.vector1(),
                   .top_right_radius = args.top_right_radius.vector1(),
                   .bottom_right_radius = args.bottom_right_radius.vector1(),
                   .bottom_left_radius = args.bottom_left_radius.vector1(),
               },
       }});
}

void FakeSession::ApplyCreateCircle(FakeResourceId id,
                                    fuchsia::ui::gfx::CircleArgs args) {
  FML_CHECK(args.radius.is_vector1());

  AddResource({.id = id,
               .state = FakeShapeState{
                   .shape_def =
                       FakeShapeState::CircleDef{
                           .radius = args.radius.vector1(),
                       },
               }});
}

void FakeSession::ApplyCreateMaterial(FakeResourceId id,
                                      fuchsia::ui::gfx::MaterialArgs args) {
  AddResource({
      .id = id,
      .state = FakeMaterialState{},
  });
}

void FakeSession::ApplyCreateView(FakeResourceId id,
                                  fuchsia::ui::gfx::ViewArgs args) {
  FML_CHECK(scene_graph_.root_view_id == kInvalidFakeResourceId);

  zx_koid_t token_koid = GetKoid(args.token.value.get());
  AddResource({.id = id,
               .state = FakeViewState{
                   .token = {std::move(args.token), token_koid},
                   .debug_name = std::string(args.debug_name->c_str(),
                                             args.debug_name->length()),
               }});
}

void FakeSession::ApplyCreateView(FakeResourceId id,
                                  fuchsia::ui::gfx::ViewArgs3 args) {
  zx_koid_t token_koid = GetKoid(args.token.value.get());
  zx_koid_t control_ref_koid = GetKoid(args.control_ref.reference.get());
  zx_koid_t view_ref_koid = GetKoid(args.view_ref.reference.get());
  AddResource(
      {.id = id,
       .state = FakeViewState{
           .token = {std::move(args.token), token_koid},
           .control_ref = {std::move(args.control_ref), control_ref_koid},
           .view_ref = {std::move(args.view_ref), view_ref_koid},
           .debug_name =
               std::string(args.debug_name->c_str(), args.debug_name->length()),
       }});
}

void FakeSession::ApplyCreateViewHolder(FakeResourceId id,
                                        fuchsia::ui::gfx::ViewHolderArgs args) {
  zx_koid_t token_koid = GetKoid(args.token.value.get());
  AddResource({
      .id = id,
      .state =
          FakeViewHolderState{
              .token = {std::move(args.token), token_koid},
              .debug_name = std::string(args.debug_name->c_str(),
                                        args.debug_name->length()),
          },
  });
}

void FakeSession::ApplyCreateEntityNode(FakeResourceId id,
                                        fuchsia::ui::gfx::EntityNodeArgs args) {
  AddResource({
      .id = id,
      .state = FakeEntityNodeState{},
  });
}

void FakeSession::ApplyCreateOpacityNode(
    FakeResourceId id,
    fuchsia::ui::gfx::OpacityNodeArgsHACK args) {
  AddResource({
      .id = id,
      .state = FakeOpacityNodeState{},
  });
}

void FakeSession::ApplyCreateShapeNode(FakeResourceId id,
                                       fuchsia::ui::gfx::ShapeNodeArgs args) {
  AddResource({
      .id = id,
      .state = FakeShapeNodeState{},
  });
}

}  // namespace flutter_runner::testing
