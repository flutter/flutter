// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "fake_resources.h"

#include "flutter/fml/logging.h"

namespace flutter_runner::testing {
namespace {

using FakeResourceCache =
    std::unordered_map<FakeResourceState*, std::shared_ptr<FakeResource>>;

std::shared_ptr<FakeResource> ResourceFromState(
    const std::shared_ptr<FakeResourceState>& resource,
    FakeResourceCache& cache);
std::vector<std::shared_ptr<FakeResource>> ResourcesFromStates(
    const std::vector<std::shared_ptr<FakeResourceState>>& resources,
    FakeResourceCache& cache);

FakeNode NodeFromState(FakeNodeState* node, FakeResourceCache& cache) {
  FML_CHECK(node);

  return FakeNode{
      .children = ResourcesFromStates(node->children, cache),
      .rotation_quaternion = node->rotation_quaternion,
      .scale_vector = node->scale_vector,
      .translation_vector = node->translation_vector,
      .anchor_vector = node->anchor_vector,
      .hit_testable = node->hit_testable,
      .semantically_visible = node->semantically_visible,
  };
}

FakeEntityNode EntityNodeFromState(FakeEntityNodeState* entity_node,
                                   FakeResourceCache& cache) {
  FML_CHECK(entity_node);

  // Convert clip planes.
  std::vector<FakeEntityNode::ClipPlane> clip_planes;
  for (auto& clip_plane : entity_node->clip_planes) {
    clip_planes.emplace_back(FakeEntityNode::ClipPlane{
        .dir = clip_plane.dir,
        .dist = clip_plane.dist,
    });
  }

  return FakeEntityNode{
      .node_state = NodeFromState(&entity_node->node_state, cache),
      .clip_planes = std::move(clip_planes),
  };
}

FakeOpacityNode OpacityNodeFromState(FakeOpacityNodeState* opacity_node,
                                     FakeResourceCache& cache) {
  FML_CHECK(opacity_node);

  return FakeOpacityNode{
      .node_state = NodeFromState(&opacity_node->node_state, cache),
      .opacity = opacity_node->opacity,
  };
}

FakeShapeNode ShapeNodeFromState(FakeShapeNodeState* shape_node,
                                 FakeResourceCache& cache) {
  FML_CHECK(shape_node);

  return FakeShapeNode{
      .node_state = NodeFromState(&shape_node->node_state, cache),
      .shape = ResourceFromState(shape_node->shape, cache),
      .material = ResourceFromState(shape_node->material, cache),
  };
}

FakeView ViewFromState(FakeViewState* view, FakeResourceCache& cache) {
  FML_CHECK(view);

  return FakeView{
      .token = view->token.koid,
      .control_ref = view->control_ref.koid,
      .view_ref = view->view_ref.koid,
      .debug_name = view->debug_name,
      .children = ResourcesFromStates(view->children, cache),
      .enable_debug_bounds = view->enable_debug_bounds,
  };
}

FakeViewHolder ViewHolderFromState(FakeViewHolderState* view_holder,
                                   FakeResourceCache& cache) {
  FML_CHECK(view_holder);

  return FakeViewHolder{
      .token = view_holder->token.koid,
      .debug_name = view_holder->debug_name,
      .properties = view_holder->properties,
      .bounds_color = view_holder->bounds_color,
  };
}

FakeShape ShapeFromState(FakeShapeState* shape, FakeResourceCache& cache) {
  FML_CHECK(shape);

  auto snapshot = FakeShape{};
  std::visit(
      [&snapshot](auto&& shape_def) {
        using T = std::decay_t<decltype(shape_def)>;
        if constexpr (std::is_same_v<T, FakeShapeState::CircleDef>) {
          snapshot.shape_def = FakeShape::CircleDef{
              .radius = shape_def.radius,
          };
        } else if constexpr (std::is_same_v<T, FakeShapeState::RectangleDef>) {
          snapshot.shape_def = FakeShape::RectangleDef{
              .width = shape_def.width,
              .height = shape_def.height,
          };
        } else if constexpr (std::is_same_v<
                                 T, FakeShapeState::RoundedRectangleDef>) {
          snapshot.shape_def = FakeShape::RoundedRectangleDef{
              .width = shape_def.width,
              .height = shape_def.height,
              .top_left_radius = shape_def.top_left_radius,
              .top_right_radius = shape_def.top_right_radius,
              .bottom_right_radius = shape_def.bottom_right_radius,
              .bottom_left_radius = shape_def.bottom_left_radius,
          };
        } else {
          FML_CHECK(false);
        }
      },
      shape->shape_def);

  return snapshot;
}

FakeMaterial MaterialFromState(FakeMaterialState* material,
                               FakeResourceCache& cache) {
  FML_CHECK(material);

  return FakeMaterial{
      .image = ResourceFromState(material->image, cache),
      .color = material->color,
  };
}

FakeImage ImageFromState(FakeImageState* image, FakeResourceCache& cache) {
  FML_CHECK(image);

  auto snapshot = FakeImage{
      .memory = ResourceFromState(image->memory, cache),
  };
  std::visit(
      [&snapshot](auto&& image_def) {
        using T = std::decay_t<decltype(image_def)>;
        if constexpr (std::is_same_v<T, FakeImageState::ImageDef>) {
          snapshot.image_def = FakeImage::ImageDef{
              .info = image_def.info,
              .memory_offset = image_def.memory_offset,
          };
        } else if constexpr (std::is_same_v<T, FakeImageState::Image2Def>) {
          snapshot.image_def = FakeImage::Image2Def{
              .buffer_collection_id = image_def.buffer_collection_id,
              .buffer_collection_index = image_def.buffer_collection_index,
              .width = image_def.width,
              .height = image_def.height,
          };
        } else if constexpr (std::is_same_v<T, FakeImageState::Image3Def>) {
          snapshot.image_def = FakeImage::Image3Def{
              .import_token = image_def.import_token.koid,
              .buffer_collection_index = image_def.buffer_collection_index,
              .width = image_def.width,
              .height = image_def.height,
          };
        } else if constexpr (std::is_same_v<T, FakeImageState::ImagePipe2Def>) {
          snapshot.image_def = FakeImage::ImagePipe2Def{
              .image_pipe_request = image_def.image_pipe_request.koid,
          };
        } else {
          FML_CHECK(false);
        }
      },
      image->image_def);

  return snapshot;
}

FakeMemory MemoryFromState(FakeMemoryState* memory, FakeResourceCache& cache) {
  FML_CHECK(memory);

  return FakeMemory{
      .vmo = memory->vmo.koid,
      .allocation_size = memory->allocation_size,
      .is_device_memory = memory->is_device_memory,
  };
}

std::shared_ptr<FakeResource> ResourceFromState(
    const std::shared_ptr<FakeResourceState>& resource,
    FakeResourceCache& cache) {
  if (!resource) {
    return std::shared_ptr<FakeResource>();
  }

  // Try to hit the cache first...
  auto cache_it = cache.find(resource.get());
  if (cache_it != cache.end()) {
    return cache_it->second;
  }

  // Otherwise create a brand-new snapshot.
  std::shared_ptr<FakeResource> snapshot =
      std::make_shared<FakeResource>(FakeResource{
          .id = resource->id,
          .label = resource->label,
          .event_mask = resource->event_mask,
      });
  std::visit(
      [&snapshot, &resource, &cache](auto&& state) {
        using T = std::decay_t<decltype(state)>;
        if constexpr (std::is_same_v<T, FakeEntityNodeState>) {
          snapshot->state = EntityNodeFromState(
              std::get_if<FakeEntityNodeState>(&resource->state), cache);
        } else if constexpr (std::is_same_v<T, FakeOpacityNodeState>) {
          snapshot->state = OpacityNodeFromState(
              std::get_if<FakeOpacityNodeState>(&resource->state), cache);
        } else if constexpr (std::is_same_v<T, FakeShapeNodeState>) {
          snapshot->state = ShapeNodeFromState(
              std::get_if<FakeShapeNodeState>(&resource->state), cache);
        } else if constexpr (std::is_same_v<T, FakeViewState>) {
          snapshot->state = ViewFromState(
              std::get_if<FakeViewState>(&resource->state), cache);
        } else if constexpr (std::is_same_v<T, FakeViewHolderState>) {
          snapshot->state = ViewHolderFromState(
              std::get_if<FakeViewHolderState>(&resource->state), cache);
        } else if constexpr (std::is_same_v<T, FakeShapeState>) {
          snapshot->state = ShapeFromState(
              std::get_if<FakeShapeState>(&resource->state), cache);
        } else if constexpr (std::is_same_v<T, FakeMaterialState>) {
          snapshot->state = MaterialFromState(
              std::get_if<FakeMaterialState>(&resource->state), cache);
        } else if constexpr (std::is_same_v<T, FakeImageState>) {
          snapshot->state = ImageFromState(
              std::get_if<FakeImageState>(&resource->state), cache);
        } else if constexpr (std::is_same_v<T, FakeMemoryState>) {
          snapshot->state = MemoryFromState(
              std::get_if<FakeMemoryState>(&resource->state), cache);
        } else {
          FML_CHECK(false);
        }
      },
      resource->state);
  auto [_, cache_success] =
      cache.emplace(std::make_pair(resource.get(), snapshot));
  FML_CHECK(cache_success);

  return snapshot;
}

std::vector<std::shared_ptr<FakeResource>> ResourcesFromStates(
    const std::vector<std::shared_ptr<FakeResourceState>>& resources,
    FakeResourceCache& cache) {
  std::vector<std::shared_ptr<FakeResource>> snapshots;

  for (auto& resource : resources) {
    snapshots.emplace_back(ResourceFromState(resource, cache));
  }
  return snapshots;
}

}  // namespace

FakeSceneGraph SceneGraphFromState(const FakeSceneGraphState& state) {
  FakeResourceCache resource_cache;
  FakeSceneGraph scene_graph;

  // Snapshot all buffer collections.
  for (auto& buffer_collection : state.buffer_collection_map) {
    scene_graph.buffer_collection_map.emplace(
        std::make_pair(buffer_collection.first, buffer_collection.second.koid));
  }

  // Snapshot resources in the map recursively.
  for (auto& resource : state.resource_map) {
    scene_graph.resource_map.emplace(std::make_pair(
        resource.first, ResourceFromState(resource.second, resource_cache)));
  }

  // Snapshot labels in the map.
  for (auto& label_resources : state.label_map) {
    auto [label_iter, label_success] =
        scene_graph.label_map.emplace(std::make_pair(
            label_resources.first, std::vector<std::weak_ptr<FakeResource>>()));
    FML_CHECK(label_success);
    auto& snapshot_label_resources = label_iter->second;

    for (auto& resource : label_resources.second) {
      auto resource_ptr = resource.lock();
      FML_CHECK(resource_ptr);

      snapshot_label_resources.emplace_back(
          ResourceFromState(resource_ptr, resource_cache));
    }
  }

  // Snapshot the view id.
  scene_graph.root_view_id = state.root_view_id;

  return scene_graph;
}

}  // namespace flutter_runner::testing
